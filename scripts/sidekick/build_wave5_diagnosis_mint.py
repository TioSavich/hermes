#!/usr/bin/env python3
"""Census Wave 5 partners and mint fresh-execution diagnosis programs."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(SCRIPT_DIR), str(REPO_ROOT)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_wave5_solution_mint import (  # noqa: E402
    ProgramRunner, load_g8_rows, prolog_value, stable_rank,
)
from contamination import (  # noqa: E402
    INDEX_PATH, REGISTER_LEXICON_PATH, OverlapGate, load_register_lexicon,
    provenance_hits, register_aware_split_overlap,
)

DATASETS = REPO_ROOT / "hermes/app/runtime/experiments/sidekick/datasets"
SOLUTION_PAIRS = DATASETS / "wave5-solution-pairs.jsonl"
SOLUTION_REPORT = DATASETS / "wave5-solution-mint-report.json"
SPLIT_MANIFEST = DATASETS / "wave5-split-manifest.json"
ROW_MAP = REPO_ROOT / "curriculum/im/generated/wave5_row_machine_map.jsonl"
VALIDITY = REPO_ROOT / "knowledge/strategies/deformation_validity.pl"
PUSU = REPO_ROOT / "data/learningcommons/derived/pusu_pass.json"
TOKENIZER = REPO_ROOT / "hermes/app/runtime/experiments/sidekick/gemma4-e2b-assets/tokenizer.json"
RUNNER = SCRIPT_DIR / "wave5_diagnosis_runner.pl"
TOKEN_HELPER = SCRIPT_DIR / "wave5_token_count.py"

CENSUS = DATASETS / "wave5-partner-census.json"
PAIRS = DATASETS / "wave5-diagnosis-pairs.jsonl"
REPORT = DATASETS / "wave5-diagnosis-mint-report.json"
BUILDER_VERSION = "wave5-diagnosis-mint-v3-g8-capability-census"
OUTPUT_WHITESPACE_BOUND = 256
SMOKE_SEED = 20260815
REGISTER_GATE_BASELINES = {
    "pre_repair_pairs": 1635,
    "post_repair_strict_pairs": 969,
}

FAMILY_OPERATION = {
    "add": "addition",
    "subtract": "subtraction",
    "multiply": "multiplication",
    "divide": "division",
    "add_fractions": "fraction",
    "subtract_fractions": "fraction",
    "unit_fraction": "fraction",
    "decimal_add": "decimal",
    "decimal_compare": "decimal",
    "convert_measurement": "measurement",
    "compare_rectangle_areas": "geometry",
    "construct_rectangle_with_area": "geometry",
    "rectangle_missing_side_from_area": "geometry",
    "rectangle_missing_side_from_perimeter": "geometry",
    "rectangle_perimeter": "geometry",
    "rectangle_side_lengths_for_area": "geometry",
    "unit_cube_volume": "geometry",
}


def canonical_bytes(value: Any, *, pretty: bool = False) -> bytes:
    if pretty:
        return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode()
    return (json.dumps(value, ensure_ascii=False, sort_keys=True,
                       separators=(",", ":")) + "\n").encode()


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()
            if line.strip()]


class DiagnosisRunner:
    def __init__(self) -> None:
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(RUNNER)], cwd=REPO_ROOT, text=True,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            bufsize=1,
        )

    def ask(self, request: dict[str, Any]) -> dict[str, Any]:
        assert self.process.stdin is not None and self.process.stdout is not None
        self.process.stdin.write(json.dumps(request, ensure_ascii=False, sort_keys=True) + "\n")
        self.process.stdin.flush()
        line = self.process.stdout.readline()
        if not line:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"diagnosis runner stopped: {stderr}")
        return json.loads(line)

    def close(self) -> None:
        if self.process.stdin and self.process.poll() is None:
            self.process.stdin.write('{"mode":"stop"}\n')
            self.process.stdin.flush()
            self.process.stdin.close()
        self.process.wait(timeout=10)
        if self.process.returncode:
            stderr = self.process.stderr.read() if self.process.stderr else ""
            raise RuntimeError(f"diagnosis runner failed: {stderr}")


def candidate_request(pair: dict[str, Any], row: dict[str, Any], operation: str,
                      contrast: str) -> dict[str, Any]:
    return {
        "mode": "candidate",
        "operation": operation,
        "productive_machine": pair["machine"],
        "contrast_machine": contrast,
        "input": row["input"],
    }


def select_partner(runner: DiagnosisRunner, pair: dict[str, Any], row: dict[str, Any],
                   operation: str, candidates: list[str], validity: str,
                   require_context: bool = False) -> tuple[str | None, dict[str, Any] | None]:
    for machine in candidates:
        result = runner.ask(candidate_request(pair, row, operation, machine))
        if not result.get("ok") or result.get("validity") != validity:
            continue
        if require_context and "viability_context:not_emitted" in result["verdict"]:
            continue
        return machine, result
    return None, None


def facts_from_solution(program: str) -> list[str]:
    return [line for line in program.splitlines() if line.startswith("quantity(")]


def diagnosis_program(pair: dict[str, Any], row: dict[str, Any], operation: str,
                      contrast: str, observed: str, verdict: str) -> str:
    facts = facts_from_solution(pair["output"])
    facts.append(f"observed_answer({observed}).")
    facts.append(
        "test(V) :- observed_answer(O),"
        "wave5_diagnosis_route:receipt_contrast_verdict("
        f"{operation},{pair['machine']},{contrast},{prolog_value(row['input'])},O,V)."
    )
    facts.append(verdict + ".")
    return "\n".join(facts)


def diagnosis_input(pair: dict[str, Any], contrast: str, observed: str) -> str:
    return (f"{pair['input']} Observed answer: {observed}. "
            f"Candidate strategy: {contrast}.")


def distribution(values: list[int]) -> dict[str, int | float]:
    ordered = sorted(values)
    if not ordered:
        return {"count": 0, "min": 0, "p50": 0, "p95": 0, "p99": 0,
                "max": 0, "mean": 0.0}
    def percentile(p: float) -> int:
        return ordered[max(0, math.ceil(p * len(ordered)) - 1)]
    return {
        "count": len(ordered), "min": ordered[0], "p50": percentile(0.50),
        "p95": percentile(0.95), "p99": percentile(0.99), "max": ordered[-1],
        "mean": round(sum(ordered) / len(ordered), 3),
    }


def model_token_counts(texts: list[str]) -> list[int]:
    if not TOKENIZER.is_file():
        raise RuntimeError(f"local E2B tokenizer is missing: {TOKENIZER}")
    command = ["/usr/bin/arch", "-arm64", "/usr/local/bin/python3",
               str(TOKEN_HELPER), str(TOKENIZER)]
    process = subprocess.Popen(command, cwd=REPO_ROOT, text=True,
                               stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
    payload = "".join(json.dumps(text, ensure_ascii=False) + "\n" for text in texts)
    stdout, stderr = process.communicate(payload, timeout=120)
    if process.returncode:
        raise RuntimeError(f"local E2B tokenizer failed: {stderr}")
    counts = [int(line) for line in stdout.splitlines() if line.strip()]
    if len(counts) != len(texts):
        raise RuntimeError(f"token count mismatch: {len(counts)} != {len(texts)}")
    return counts


def measurements(solution: list[dict[str, Any]], diagnosis: list[dict[str, Any]]) -> dict[str, Any]:
    groups = {"solution": solution, "diagnosis": diagnosis,
              "combined": [*solution, *diagnosis]}
    result: dict[str, Any] = {
        "tokenizer": str(TOKENIZER.relative_to(REPO_ROOT)),
        "tokenizer_sha256": file_sha(TOKENIZER),
        "model_tokenizer_available": True,
    }
    for name, pairs in groups.items():
        inputs = [pair["input"] for pair in pairs]
        outputs = [pair["output"] for pair in pairs]
        result[name] = {
            "input": {
                "whitespace_tokens": distribution([len(text.split()) for text in inputs]),
                "model_tokens": distribution(model_token_counts(inputs)),
                "characters": distribution([len(text) for text in inputs]),
            },
            "output": {
                "whitespace_tokens": distribution([len(text.split()) for text in outputs]),
                "model_tokens": distribution(model_token_counts(outputs)),
                "characters": distribution([len(text) for text in outputs]),
            },
        }
    return result


def stratified_smoke(pairs: list[dict[str, Any]], size_per_class: int = 20) -> list[dict[str, Any]]:
    grouped: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
    for pair in pairs:
        grouped[pair["validity_class"]].append(pair)
    selected: list[dict[str, Any]] = []
    for validity in sorted(grouped):
        rows = sorted(grouped[validity],
                      key=lambda pair: stable_rank(pair["id"], SMOKE_SEED))
        if len(rows) < size_per_class:
            raise RuntimeError(f"smoke class {validity} has only {len(rows)} pairs")
        selected.extend(rows[:size_per_class])
    return selected


def reprove(runner: DiagnosisRunner, pair: dict[str, Any]) -> dict[str, Any]:
    return runner.ask({"mode": "program", "program": pair["output"],
                       "expected_verdict": pair["verdict"]})


def batch_reprove(pairs: list[dict[str, Any]], chunk_size: int = 200) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    for start in range(0, len(pairs), chunk_size):
        runner = DiagnosisRunner()
        try:
            results.extend(reprove(runner, pair)
                           for pair in pairs[start:start + chunk_size])
        finally:
            runner.close()
    return results


def build() -> dict[Path, bytes]:
    solution_pairs = load_jsonl(SOLUTION_PAIRS)
    solution_report = json.loads(SOLUTION_REPORT.read_text(encoding="utf-8"))
    upstream_register_pair_ids = set(
        solution_report["heldout_gate"]["register_pair_ids"]
    )
    row_map = {row["id"]: row for row in load_jsonl(ROW_MAP)}
    split_manifest = json.loads(SPLIT_MANIFEST.read_text(encoding="utf-8"))
    register_artifact, register_grams = load_register_lexicon()
    register_sha256 = file_sha(REGISTER_LEXICON_PATH)
    source_heldout_text = {
        pair["id"]: pair["input"] for pair in solution_pairs
        if pair["split"] == "held_out"
    }
    source_training_text = {
        pair["id"]: pair["input"] for pair in solution_pairs
        if pair["split"] == "train"
    }
    source_overlap = register_aware_split_overlap(
        source_heldout_text, source_training_text, register_grams
    )
    source_strict_shared = source_overlap["strict"]
    source_register_shared = source_overlap["register"]
    source_blocking_shared = source_overlap["blocking"]
    source_strict_touching = {hit["right"] for hit in source_strict_shared}
    source_blocking_touching = {hit["right"] for hit in source_blocking_shared}
    if source_blocking_touching:
        solution_pairs = [
            pair for pair in solution_pairs if pair["id"] not in source_blocking_touching
        ]
    g8_solution_pairs = [pair for pair in solution_pairs if pair["grade"] == "8"]
    scene_solution_pairs = [pair for pair in solution_pairs
                            if "admission_exception" in pair["provenance"]]
    k7_solution_pairs = [pair for pair in solution_pairs
                         if pair["grade"] != "8"
                         and "admission_exception" not in pair["provenance"]]
    pusu = json.loads(PUSU.read_text(encoding="utf-8"))
    pusu_separating = sum(c.get("status") == "separates"
                          for row in pusu["rows"] for c in row.get("contrasts", []))
    pusu_routed = sum(bool(c.get("goal"))
                      for row in pusu["rows"] for c in row.get("contrasts", []))

    runner = DiagnosisRunner()
    try:
        inventory_response = runner.ask({"mode": "inventory"})
        if inventory_response.get("deformation_validity_rows") != 259:
            raise RuntimeError("ratified deformation-validity row count changed")
        inventory = inventory_response["machines"]
        machine_by_key = {(row["operation"], row["machine"]): row for row in inventory}
        candidates_by_operation: defaultdict[str, dict[str, list[str]]] = defaultdict(
            lambda: {"deformation": [], "inefficient": []})
        for row in inventory:
            if row["invalid_steps"]:
                candidates_by_operation[row["operation"]]["deformation"].append(row["machine"])
            if row["inefficient_steps"]:
                candidates_by_operation[row["operation"]]["inefficient"].append(row["machine"])
        for groups in candidates_by_operation.values():
            groups["deformation"].sort()
            groups["inefficient"].sort()

        family_rows: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
        row_census: list[dict[str, Any]] = []
        complete: list[dict[str, Any]] = []
        for pair in k7_solution_pairs:
            family_rows[pair["family"]].append(pair)
            row = row_map[pair["id"]]
            operation = FAMILY_OPERATION[pair["family"]]
            groups = candidates_by_operation[operation]
            deformation, deformation_result = select_partner(
                runner, pair, row, operation, groups["deformation"], "incorrect")
            inefficient, inefficient_result = select_partner(
                runner, pair, row, operation, groups["inefficient"],
                "correct_but_inefficient", require_context=True)
            census_row = {
                "id": pair["id"], "lesson": pair["lesson"],
                "family": pair["family"], "operation": operation,
                "productive_machine": pair["machine"],
                "productive_available": (operation, pair["machine"]) in machine_by_key,
                "deformation_partner": deformation,
                "inefficient_partner": inefficient,
                "complete_three_variant": bool(deformation and inefficient),
            }
            row_census.append(census_row)
            if deformation and inefficient:
                complete.append({"pair": pair, "row": row, "operation": operation,
                                 "deformation": (deformation, deformation_result),
                                 "inefficient": (inefficient, inefficient_result)})

        family_census: list[dict[str, Any]] = []
        for family in sorted(family_rows):
            pairs = family_rows[family]
            operation = FAMILY_OPERATION[family]
            rows = [row for row in row_census if row["family"] == family]
            productive_machines = sorted({pair["machine"] for pair in pairs})
            productive_store = []
            for machine in productive_machines:
                store = machine_by_key.get((operation, machine))
                productive_store.append({
                    "machine": machine,
                    "typology_contract_present": store is not None,
                    "static_rows": store["static_rows"] if store else 0,
                    "observed_rows": store["observed_rows"] if store else 0,
                })
            family_census.append({
                "family": family, "operation": operation,
                "solution_rows": len(pairs),
                "productive": productive_store,
                "deformation_candidate_machines": candidates_by_operation[operation]["deformation"],
                "inefficient_candidate_machines": candidates_by_operation[operation]["inefficient"],
                "productive_available_rows": sum(r["productive_available"] for r in rows),
                "deformation_available_rows": sum(bool(r["deformation_partner"]) for r in rows),
                "inefficient_available_rows": sum(bool(r["inefficient_partner"]) for r in rows),
                "complete_three_variant_rows": sum(r["complete_three_variant"] for r in rows),
            })

        g8_selected, _ = load_g8_rows()
        g8_pair_ids = {pair["id"] for pair in g8_solution_pairs}
        g8_correct_rows = [row for row in g8_selected
                           if row["execution"]["outcome"] == "correct"]
        g8_pilot_rows = [row for row in g8_correct_rows
                         if row["route"] != "extant_machine"]
        g8_extant_rows = [row for row in g8_correct_rows
                          if row["route"] == "extant_machine"]
        g8_rows: list[dict[str, Any]] = []
        g8_runner = ProgramRunner()
        try:
            for mapped in g8_pilot_rows:
                module = Path(mapped["module"]).stem
                productive = g8_runner.ask({
                    "mode": "g8_solution", "module": module,
                    "doing": mapped["machine"], "input": mapped["input"],
                })
                deformation = g8_runner.ask({
                    "mode": "g8_partner", "module": module,
                    "doing": mapped["machine"], "variant": "deformation",
                    "input": mapped["input"],
                })
                inefficient = g8_runner.ask({
                    "mode": "g8_partner", "module": module,
                    "doing": mapped["machine"], "variant": "correct_but_inefficient",
                    "input": mapped["input"],
                })
                deformation_count = deformation["available_count"]
                inefficient_count = inefficient["available_count"]
                productive_count = productive["available_count"]
                if productive_count != 1:
                    raise RuntimeError(f"fresh G8 productive census failed: {mapped['id']}")
                g8_rows.append({
                    "id": mapped["id"], "lesson": mapped["lesson"],
                    "family": mapped["family"], "module": module,
                    "productive_machine": mapped["machine"],
                    "productive_available": bool(productive_count),
                    "productive_results": productive["results"],
                    "deformation_partner_count": deformation_count,
                    "deformation_results": deformation["results"],
                    "inefficient_partner_count": inefficient_count,
                    "inefficient_results": inefficient["results"],
                    "complete_three_variant": bool(deformation_count and inefficient_count),
                    "solution_pair_admitted": mapped["id"] in g8_pair_ids,
                    "execution": "fresh_headless_pilot_run",
                })
        finally:
            g8_runner.close()
        g8_complete = [row for row in g8_rows if row["complete_three_variant"]]
        if g8_complete:
            raise RuntimeError("G8 complete triples appeared but are not wired to verdict minting")

        # Census discovery and mint execution use distinct fresh processes.
        # Restart the mint runner periodically so large enumerated traces do
        # not make later receipt behavior depend on an earlier row.
        runner.close()
        runner = DiagnosisRunner()
        overlap = OverlapGate()
        exclusions = Counter({"benchmark_13gram_input": 0,
                              "benchmark_13gram_output": 0,
                              "output_whitespace_bound": 0})
        exclusion_ids: defaultdict[str, list[str]] = defaultdict(list)
        diagnosis_candidates: list[dict[str, Any]] = []
        for item_index, item in enumerate(complete):
            if item_index and item_index % 100 == 0:
                runner.close()
                runner = DiagnosisRunner()
            pair, row, operation = item["pair"], item["row"], item["operation"]
            variants = [
                ("productive_trace", pair["machine"], runner.ask(
                    candidate_request(pair, row, operation, pair["machine"]))),
                ("candidate_deformation", item["deformation"][0], runner.ask(
                    candidate_request(pair, row, operation, item["deformation"][0]))),
                ("correct_but_inefficient", item["inefficient"][0], runner.ask(
                    candidate_request(pair, row, operation, item["inefficient"][0]))),
            ]
            for validity_class, contrast, executed in variants:
                if not executed or not executed.get("ok"):
                    raise RuntimeError(f"fresh verdict mint refused {pair['id']}:{contrast}")
                observed, verdict = executed["observed_answer"], executed["verdict"]
                output = diagnosis_program(pair, row, operation, contrast, observed, verdict)
                input_text = diagnosis_input(pair, contrast, observed)
                identity = f"{pair['id']}:{validity_class}:{contrast}"
                if overlap.hits(input_text):
                    exclusions["benchmark_13gram_input"] += 1
                    exclusion_ids["benchmark_13gram_input"].append(identity)
                    continue
                if overlap.hits(output):
                    exclusions["benchmark_13gram_output"] += 1
                    exclusion_ids["benchmark_13gram_output"].append(identity)
                    continue
                if len(output.split()) > OUTPUT_WHITESPACE_BOUND:
                    exclusions["output_whitespace_bound"] += 1
                    exclusion_ids["output_whitespace_bound"].append(identity)
                    continue
                provenance = {
                    "source_pair": str(SOLUTION_PAIRS.relative_to(REPO_ROOT)),
                    "source_pair_id": pair["id"],
                    "source_row_map": str(ROW_MAP.relative_to(REPO_ROOT)),
                    "source_row_evidence_sha256": row["evidence_sha256"],
                    "builder": BUILDER_VERSION,
                    "contrast_route": "wave5_diagnosis_route:receipt_contrast_verdict/6",
                    "verdict_source": "fresh_headless_execution",
                    "lesson_split_version": split_manifest["version"],
                    "lesson_split_assignment_sha256": split_manifest["assignment_sha256"],
                    "contamination_index": str(INDEX_PATH.relative_to(REPO_ROOT)),
                    "contamination_index_sha256": file_sha(INDEX_PATH),
                    "register_lexicon": str(REGISTER_LEXICON_PATH.relative_to(REPO_ROOT)),
                    "register_lexicon_sha256": register_sha256,
                }
                if provenance_hits(provenance):
                    raise RuntimeError(f"forbidden provenance on {identity}")
                diagnosis_candidates.append({
                    "id": identity, "source_id": pair["id"],
                    "lesson": pair["lesson"], "grade": pair["grade"],
                    "family": pair["family"], "genre": pair["genre"],
                    "split": pair["split"], "operation": operation,
                    "productive_machine": pair["machine"],
                    "contrast_machine": contrast,
                    "validity_class": validity_class,
                    "observed_answer": observed, "input": input_text,
                    "output": output, "verdict": verdict,
                    "provenance": provenance,
                })

        strict_pair_count = 3 * sum(
            item["pair"]["id"] not in upstream_register_pair_ids for item in complete
        )
        if strict_pair_count != REGISTER_GATE_BASELINES["post_repair_strict_pairs"]:
            raise RuntimeError(
                "post-repair diagnosis strict-gate baseline changed: "
                f"expected {REGISTER_GATE_BASELINES['post_repair_strict_pairs']}, "
                f"observed {strict_pair_count}"
            )

        candidate_pool = len(complete) * 3
        if len(diagnosis_candidates) + sum(exclusions.values()) != candidate_pool:
            raise RuntimeError("diagnosis candidate pool did not reconcile")

        first_proof = len(diagnosis_candidates)
        runner.close()
        reproof_results = batch_reprove(diagnosis_candidates)
        reproof_pass = sum(bool(row.get("parsed") and row.get("ran") and
                                row.get("verdict_match")) for row in reproof_results)
        if reproof_pass != len(diagnosis_candidates):
            failures = [diagnosis_candidates[i]["id"] for i, row in enumerate(reproof_results)
                        if not row.get("verdict_match")]
            raise RuntimeError(f"full verdict re-proof failed: {failures[:10]}")

        smoke_pairs = stratified_smoke(diagnosis_candidates)
        smoke_results = batch_reprove(smoke_pairs, chunk_size=60)
        smoke = {
            "sample_size": len(smoke_pairs),
            "by_validity_class": dict(sorted(Counter(
                pair["validity_class"] for pair in smoke_pairs).items())),
            "parsed": sum(bool(row.get("parsed")) for row in smoke_results),
            "ran": sum(bool(row.get("ran")) for row in smoke_results),
            "verdict_match": sum(bool(row.get("verdict_match")) for row in smoke_results),
        }
        if (smoke["parsed"], smoke["ran"], smoke["verdict_match"]) != (60, 60, 60):
            raise RuntimeError(f"stratified diagnosis smoke failed: {smoke}")
    finally:
        runner.close()

    class_counts = Counter(pair["validity_class"] for pair in diagnosis_candidates)
    minimum_pairs_per_class = 500
    class_floor_passed = all(
        class_counts[validity] >= minimum_pairs_per_class
        for validity in (
            "productive_trace", "candidate_deformation", "correct_but_inefficient"
        )
    )
    class_floor_shortfall = {
        validity: max(0, minimum_pairs_per_class - class_counts[validity])
        for validity in (
            "productive_trace", "candidate_deformation", "correct_but_inefficient"
        )
    }
    class_shares = {key: round(value / max(1, len(diagnosis_candidates)), 6)
                    for key, value in sorted(class_counts.items())}
    token_measurements = measurements(solution_pairs, diagnosis_candidates)
    ambiguity: defaultdict[tuple[str, str], set[str]] = defaultdict(set)
    for pair in diagnosis_candidates:
        ambiguity[(pair["split"], pair["input"])].add(pair["output"])
    differing = sum(len(outputs) > 1 for outputs in ambiguity.values())
    if differing:
        raise RuntimeError(f"diagnosis input ambiguity: {differing} differing-output groups")

    census_artifact = {
        "builder_version": BUILDER_VERSION,
        "ground": {
            "deformation_validity_rows": 259,
            "deformation_validity_sha256": file_sha(VALIDITY),
            "pusu_separating_contrasts": pusu_separating,
            "pusu_routed_contrasts": pusu_routed,
            "pusu_sha256": file_sha(PUSU),
            "solution_pairs": len(solution_pairs),
            "k7_registry_solution_pairs_censused": len(k7_solution_pairs),
            "g8_pilot_solution_pairs_censused": len(g8_solution_pairs),
            "scene_exception_solution_pairs_not_forced_into_registry_census": len(scene_solution_pairs),
            "solution_pairs_sha256": file_sha(SOLUTION_PAIRS),
        },
        "selection_law": "lexical machine order within operation after typology, verified input contract, and required deformation-validity mode",
        "families": family_census,
        "rows": row_census,
        "complete_three_variant_rows": len(complete),
        "g8_pilot_capability": {
            "routed_distinct_rows": len(g8_selected),
            "routed_correct_rows": len(g8_correct_rows),
            "pilot_rows_censused": len(g8_rows),
            "extant_correct_rows_outside_pilot_census": len(g8_extant_rows),
            "admitted_g8_solution_pairs": len(g8_solution_pairs),
            "admitted_pilot_rows": sum(row["solution_pair_admitted"] for row in g8_rows),
            "productive_available_rows": sum(row["productive_available"] for row in g8_rows),
            "deformation_available_rows": sum(bool(row["deformation_partner_count"]) for row in g8_rows),
            "inefficient_available_rows": sum(bool(row["inefficient_partner_count"]) for row in g8_rows),
            "partial_triples": sum(bool(row["deformation_partner_count"]) and not row["inefficient_partner_count"] for row in g8_rows),
            "complete_three_variant_rows": len(g8_complete),
            "diagnosis_pairs_minted": len(g8_complete) * 3,
            "floor_gap_closed_per_class": len(g8_complete),
            "rows": g8_rows,
        },
        "projected_class_balance": {
            "productive_trace": len(complete),
            "candidate_deformation": len(complete),
            "correct_but_inefficient": len(complete),
        },
    }
    pair_bytes = b"".join(canonical_bytes(pair) for pair in diagnosis_candidates)
    census_bytes = canonical_bytes(census_artifact, pretty=True)
    report = {
        "builder_version": BUILDER_VERSION,
        "census": str(CENSUS.relative_to(REPO_ROOT)),
        "candidate_pool": candidate_pool,
        "exclusion_counts": dict(sorted(exclusions.items())),
        "exclusion_ids": {key: value for key, value in sorted(exclusion_ids.items())},
        "minted_pairs": len(diagnosis_candidates),
        "split_counts": dict(sorted(Counter(pair["split"] for pair in diagnosis_candidates).items())),
        "class_balance": {"counts": dict(sorted(class_counts.items())),
                          "shares": class_shares},
        "proposed_fail_hard_floor": {
            "minimum_pairs_per_class": minimum_pairs_per_class,
            "minimum_share_per_class": 0.30,
            "law": "a shortfall requires more minting or a narrower claim",
            "passed": class_floor_passed,
            "shortfall_by_class": class_floor_shortfall,
        },
        "g8_pilot_capability": census_artifact["g8_pilot_capability"],
        "output_whitespace_bound": OUTPUT_WHITESPACE_BOUND,
        "proposed_diagnosis_form_bound": {
            "whitespace_output_tokens": OUTPUT_WHITESPACE_BOUND,
            "provisional_model_output_tokens": 256,
            "training_time_model_token_fix": "deferred_to_s5_g7_accounting",
        },
        "token_measurements": token_measurements,
        "input_ambiguity": {"differing_output_groups": differing,
                            "passed": differing == 0},
        "fresh_execution": {
            "mint_first_pass": first_proof,
            "full_second_pass": len(reproof_results),
            "full_second_pass_verdict_match": reproof_pass,
            "cap_seconds_per_program": 3,
        },
        "smoke": smoke,
        "benchmark_13gram": {
            "index": str(INDEX_PATH.relative_to(REPO_ROOT)),
            "index_sha256": file_sha(INDEX_PATH),
            "inputs_and_outputs_checked": candidate_pool * 2,
        },
        "heldout_gate": {
            "gram": 8,
            "law": "exclude train pairs only for held-out 8-grams absent from the register lexicon",
            "boundary": "S1 source pairs before S2 partner expansion",
            "heldout_pairs": len(source_heldout_text),
            "training_pairs_checked": len(source_training_text),
            "strict_shared_gram_hits": len(source_strict_shared),
            "strict_source_pairs": len(source_strict_touching),
            "register_shared_gram_hits": len(source_register_shared),
            "blocking_shared_gram_hits": len(source_blocking_shared),
            "source_pairs_blocked": len(source_blocking_touching),
            "upstream_strict_train_pair_ids": len(
                solution_report["heldout_gate"]["strict_pair_ids"]
            ),
            "upstream_register_exempted_train_pair_ids": len(upstream_register_pair_ids),
            "strict_examples": source_strict_shared[:10],
            "blocking_examples": source_blocking_shared[:10],
            "count_comparison": {
                "pre_repair_pairs": REGISTER_GATE_BASELINES["pre_repair_pairs"],
                "post_repair_strict_pairs": strict_pair_count,
                "post_repair_register_aware_pairs": len(diagnosis_candidates),
            },
            "register_lexicon": str(REGISTER_LEXICON_PATH.relative_to(REPO_ROOT)),
            "register_lexicon_sha256": register_sha256,
            "register_lexicon_size": register_artifact["register_grams"],
        },
        "artifacts": {
            str(CENSUS.relative_to(REPO_ROOT)): hashlib.sha256(census_bytes).hexdigest(),
            str(PAIRS.relative_to(REPO_ROOT)): hashlib.sha256(pair_bytes).hexdigest(),
        },
    }
    return {CENSUS: census_bytes, PAIRS: pair_bytes,
            REPORT: canonical_bytes(report, pretty=True)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="rebuild and require byte-identical artifacts")
    args = parser.parse_args()
    try:
        outputs = build()
    except (RuntimeError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    if args.check:
        stale = [str(path) for path, data in outputs.items()
                 if not path.is_file() or path.read_bytes() != data]
        if stale:
            print("stale Wave 5 diagnosis artifacts: " + ", ".join(stale), file=sys.stderr)
            return 1
        print(f"PASS Wave 5 diagnosis double-build is byte-identical: {len(outputs)} artifacts")
        return 0
    for path, data in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    report = json.loads(outputs[REPORT])
    print(json.dumps({key: report[key] for key in (
        "candidate_pool", "exclusion_counts", "minted_pairs", "split_counts",
        "class_balance", "fresh_execution", "smoke")}, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
