#!/usr/bin/env python3
"""Run the deterministic portion of the two-pass discourse pipeline.

The script intentionally emits an unavailable-stage record if the separately
maintained deontic layer is not present.  It never substitutes a heuristic for
posture, referent, or uptake reading.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT = REPO_ROOT / "scripts/research/talkmoves_rerun_out/lesson_run/tm_0007_lesson_report.json"
DEFAULT_LEDGER_DIR = DEFAULT_REPORT.parent


def _load_by_path(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _claim_key(claim: dict[str, Any]) -> str:
    return json.dumps({"shape": claim.get("shape"), "args": claim.get("args")}, sort_keys=True)


def compare_ledgers(reader: list[dict[str, Any]], ledgers: list[list[dict[str, Any]]]) -> dict[str, Any]:
    """Compare claim shapes/arguments, preserving model verdicts for audit."""
    model = {_claim_key(c): c for ledger in ledgers for c in ledger if c.get("kind", "claim") == "claim"}
    compiled = {_claim_key(c): c for c in reader}
    both = sorted(set(model) & set(compiled))
    model_only = sorted(set(model) - set(compiled))
    reader_only = sorted(set(compiled) - set(model))
    return {
        "claims_found_by_both": len(both), "model_only": len(model_only), "reader_only": len(reader_only),
        "both": [{"reader": compiled[key], "model_verdict": model[key].get("verdict"),
                  "model_id": model[key].get("id")} for key in both],
        "model_only_claims": [{"claim": model[key], "verdict": model[key].get("verdict")} for key in model_only],
        "reader_only_claims": compiled_values(reader_only, compiled),
    }


def compiled_values(keys: list[str], compiled: dict[str, dict[str, Any]]) -> list[dict[str, Any]]:
    return [compiled[key] for key in keys]


def deontic_stage(two_pass, numbered: str, extractions: list[dict[str, Any]]) -> dict[str, Any]:
    """Use the existing layer exactly when it is available in this checkout."""
    path = REPO_ROOT / "scripts/pml_deontic_scoreboard_layer.py"
    if not path.is_file():
        return {"status": "unavailable", "reason": f"required layer absent: {path.relative_to(REPO_ROOT)}"}
    try:
        layer = _load_by_path("deontic_layer", path)
        from hermes.app.worker import PersistentPrologWorker
        worker = PersistentPrologWorker()
        try:
            matcher = layer.worker_commitment_matcher(worker)
            events = two_pass.deontic_events_from_two_pass([], extractions, numbered, matcher=matcher)
        finally:
            worker.close()
        return {"status": "complete", "events": len(events),
                "per_speaker": layer.deontic_scoreboard_layer(events),
                "pooled_classroom": layer.deontic_scoreboard_layer(two_pass.pool_events_cross_speaker(events))}
    except Exception as exc:  # reports an integration seam; no invented board
        return {"status": "unavailable", "reason": f"deontic layer failed: {type(exc).__name__}: {exc}"}


def run(report_path: Path, ledger_dir: Path) -> dict[str, Any]:
    if str(REPO_ROOT) not in sys.path:
        sys.path.insert(0, str(REPO_ROOT))
    reader = _load_by_path("deterministic_claim_reader", REPO_ROOT / "scripts/research/deterministic_claim_reader.py")
    two_pass = _load_by_path("talkmoves_two_pass", REPO_ROOT / "scripts/talkmoves_two_pass.py")
    source = json.loads(report_path.read_text(encoding="utf-8"))
    numbered = source["report"]["transcript"]
    compiled = reader.read_numbered_transcript(numbered)
    adjudicated = two_pass.adjudicate_claims(compiled)
    mask = two_pass.mask_transcript(numbered, adjudicated)
    ledgers = [json.loads((ledger_dir / name).read_text(encoding="utf-8")) for name in
               ("tm_0007_lesson_extractions.json", "tm_0007_baseline_extractions.json")]
    return {
        "source": str(report_path.relative_to(REPO_ROOT)), "numbered_transcript": numbered,
        "claims": adjudicated, "mask": mask, "verdict_arcs": two_pass.verdict_arcs(adjudicated),
        "claims_tension": two_pass.claims_tension(adjudicated, numbered),
        "deontic": deontic_stage(two_pass, numbered, adjudicated),
        "teacher_report": {"postures": "posture reading requires a reader; this run had none",
                           "referents": "referent judgments require a reader; this run had none",
                           "uptake_fates": "uptake fate judgments require a reader; this run had none"},
        "model_comparison": compare_ledgers(adjudicated, ledgers),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--ledger-dir", type=Path, default=DEFAULT_LEDGER_DIR)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    result = run(args.report, args.ledger_dir)
    args.out.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
