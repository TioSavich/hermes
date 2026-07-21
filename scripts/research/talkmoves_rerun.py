#!/usr/bin/env python3
"""Rerun the TalkMoves two-pass chain for the pilot-3 transcript trio.

The source corpus and pilot-3 run live in the read-only formalization
checkout.  This driver only reads them.  A live run writes its local artifacts
under the ignored output directory; ``--dry-run`` only validates and prints
the complete plan, so it is safe in a network-restricted environment.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
from collections import Counter
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[2]
SIBLING_ROOT = Path("/Users/tio/Documents/GitHub/umedcta-formalization")
TALKMOVES_ROOT = SIBLING_ROOT / "data/external/talkmoves"
MANIFEST = TALKMOVES_ROOT / "manifests/talkmoves_blind_manifest.json"
PILOT_DIR = TALKMOVES_ROOT / "scored/two-pass-pilot-3"
DEFAULT_IDS = ("tm_0112", "tm_0249", "tm_0468")
DEFAULT_OUT = REPO_ROOT / "scripts/research/talkmoves_rerun_out"
PASS1_PROMPT = REPO_ROOT / "docs/research/2026-07-01-talkmoves-pass1-math-prompt.md"
PASS2_PROMPT = REPO_ROOT / "docs/research/2026-07-01-talkmoves-pass2-posture-prompt.md"


def load_module(name: str, path: Path) -> Any:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {name}: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_inputs(ids: tuple[str, ...]) -> dict[str, dict[str, Path]]:
    if not MANIFEST.exists():
        raise FileNotFoundError(f"blind-corpus manifest is absent: {MANIFEST}")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    rows = {str(row.get("transcript_id")): row
            for row in manifest.get("transcripts", [])}
    inputs: dict[str, dict[str, Path]] = {}
    for transcript_id in ids:
        row = rows.get(transcript_id)
        if row is None:
            raise ValueError(f"{transcript_id} is absent from {MANIFEST}")
        transcript = TALKMOVES_ROOT / str(row.get("markdown_path", ""))
        old_extractions = PILOT_DIR / f"{transcript_id}_extractions.json"
        old_pass1 = PILOT_DIR / f"{transcript_id}_pass1_request.txt"
        old_pass2 = PILOT_DIR / f"{transcript_id}_pass2_hard_mask_request.txt"
        required = (transcript, old_extractions, old_pass1, old_pass2,
                    PILOT_DIR / f"{transcript_id}_pass2_hard_mask.json")
        missing = [str(path) for path in required if not path.is_file()]
        if missing:
            raise FileNotFoundError("required pilot-3 input is absent: " + "; ".join(missing))
        inputs[transcript_id] = {
            "transcript": transcript,
            "old_extractions": old_extractions,
            "old_pass1": old_pass1,
            "old_pass2": old_pass2,
            "old_readings": PILOT_DIR / f"{transcript_id}_pass2_hard_mask.json",
        }
    return inputs


def json_block(reply: str, heading: str) -> dict[str, Any]:
    start = reply.find("{", max(reply.find(heading), 0))
    if start < 0:
        raise ValueError(f"model reply contains no {heading} object")
    try:
        value = json.loads(reply[start:reply.rfind("}") + 1])
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid {heading} JSON: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"{heading} must be a JSON object")
    return value


def claim_key(claim: dict[str, Any]) -> str:
    """A stable claim identity independent of model-local ids and surface case."""
    return json.dumps({
        "utterance_id": str(claim.get("utterance_id", "")).lower(),
        "shape": claim.get("shape"),
        "args": claim.get("args", {}),
    }, sort_keys=True, separators=(",", ":"), default=str)


def posture_counts(readings: list[dict[str, Any]]) -> dict[str, Counter[str]]:
    counts = {field: Counter() for field in ("force", "mode", "operator", "polarity")}
    for reading in readings:
        pml = reading.get("pml", {})
        if not isinstance(pml, dict):
            continue
        for field, bucket in counts.items():
            value = pml.get(field)
            if value is not None:
                bucket[str(value)] += 1
    return counts


def markdown_table(headers: list[str], rows: list[list[str]]) -> list[str]:
    out = ["| " + " | ".join(headers) + " |",
           "| " + " | ".join("---" for _ in headers) + " |"]
    out.extend("| " + " | ".join(row) + " |" for row in rows)
    return out


def table_cell(value: Any) -> str:
    """Keep verbatim text legible without allowing it to break a Markdown row."""
    return str(value).replace("|", r"\\|").replace("\n", " ")


def render_claims(transcript_id: str, extractions: list[dict[str, Any]],
                  numbered: str) -> str:
    speakers = {}
    for line in numbered.splitlines():
        parts = line.split(maxsplit=2)
        if len(parts) == 3 and parts[0].startswith("U") and ":" in parts[2]:
            speakers[parts[0].lower()] = parts[2].split(":", 1)[0]
    rows = []
    for claim in extractions:
        if claim.get("kind", "claim") != "claim":
            continue
        utterance = str(claim.get("utterance_id", "")).lower()
        detail = claim.get("adjudication", {})
        grounds = json.dumps(detail, indent=2, sort_keys=True, ensure_ascii=False)
        typed = json.dumps({"shape": claim.get("shape"), "args": claim.get("args", {}),
                            "term": claim.get("term")}, sort_keys=True, ensure_ascii=False)
        rows.append([f"`{table_cell(claim.get('id', '?'))}`",
                     table_cell(claim.get("surface", "")),
                     f"{table_cell(speakers.get(utterance, '?'))} + `{utterance}`",
                     f"`{table_cell(typed)}`", table_cell(claim.get("verdict", "unchecked")),
                     f"`{table_cell(grounds)}`"])
    heading = [f"# {transcript_id}: mathematical claim checks", "",
               "Each surface below is verbatim model-proposed text; the checker grounds are the complete detail returned by `math_claim_checker`.", ""]
    if not rows:
        return "\n".join(heading + ["No mathematical claims were extracted.", ""])
    return "\n".join(heading + markdown_table(
        ["ID", "Claim surface (verbatim)", "Speaker + utterance", "Typed shape and Prolog term", "Verdict", "Checker grounds"], rows) + [""])


def compare_claims(old: list[dict[str, Any]], new: list[dict[str, Any]]) -> tuple[list[str], list[str], list[str]]:
    old_by = {claim_key(c): c for c in old if c.get("kind", "claim") == "claim"}
    new_by = {claim_key(c): c for c in new if c.get("kind", "claim") == "claim"}
    added = [new_by[key] for key in sorted(new_by.keys() - old_by.keys())]
    dropped = [old_by[key] for key in sorted(old_by.keys() - new_by.keys())]
    changed = [(old_by[key], new_by[key]) for key in sorted(old_by.keys() & new_by.keys())
               if old_by[key].get("verdict") != new_by[key].get("verdict")]
    display = lambda c: f"`{c.get('utterance_id', '?')}` {c.get('surface', '')} ({c.get('verdict', 'unchecked')})"
    return ([display(c) for c in added], [display(c) for c in dropped],
            [f"`{a.get('utterance_id', '?')}` {a.get('surface', '')}: {a.get('verdict')} -> {b.get('verdict')}" for a, b in changed])


def run_live(inputs: dict[str, dict[str, Path]], out_dir: Path, model: str) -> dict[str, dict[str, Any]]:
    two_pass = load_module("hermes_talkmoves_two_pass_rerun", REPO_ROOT / "scripts/talkmoves_two_pass.py")
    scorer = two_pass._load_scorer()
    scorer.load_dotenv(REPO_ROOT)
    previous_model = os.environ.get("REALLMS_MODEL")
    os.environ["REALLMS_MODEL"] = model
    results: dict[str, dict[str, Any]] = {}
    try:
        for transcript_id, paths in inputs.items():
            raw = paths["transcript"].read_text(encoding="utf-8")
            blinded, _aliases = two_pass.blind_transcript(raw)
            if not blinded.strip():
                raise ValueError(f"{transcript_id}: no blinded speaker lines")
            numbered, _ = scorer.number_transcript(blinded)
            pass1_request = two_pass.build_pass1_user_content(transcript_id, numbered)
            reply1 = scorer.call_api(PASS1_PROMPT.read_text(encoding="utf-8"), pass1_request,
                                     retries=2, timeout=240)
            math = json_block(reply1, "## MATH_JSON")
            extractions = two_pass.adjudicate_claims(math.get("claims", []))
            mask = two_pass.mask_transcript(numbered, extractions)
            pass2_request = two_pass.build_pass2_user_content(transcript_id, mask, variant="hard_mask")
            reply2 = scorer.call_api(PASS2_PROMPT.read_text(encoding="utf-8"), pass2_request,
                                     retries=2, timeout=240)
            posture = json_block(reply2, "## PML_JSON")
            readings = posture.get("readings", [])
            report = two_pass.teacher_report(transcript_id, extractions, readings, numbered, mask_result=mask)
            payload = {"transcript_id": transcript_id, "model": model, "report": report,
                       "pass1": math, "pass2": posture, "mask": mask}
            (out_dir / f"{transcript_id}_report.json").write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            (out_dir / f"{transcript_id}_pass1_reply.md").write_text(reply1, encoding="utf-8")
            (out_dir / f"{transcript_id}_pass2_reply.md").write_text(reply2, encoding="utf-8")
            (out_dir / f"{transcript_id}_claims.md").write_text(render_claims(transcript_id, extractions, numbered), encoding="utf-8")
            results[transcript_id] = {"extractions": extractions, "readings": readings,
                                      "report": report, "pass1_request": pass1_request,
                                      "pass2_request": pass2_request}
    finally:
        if previous_model is None:
            os.environ.pop("REALLMS_MODEL", None)
        else:
            os.environ["REALLMS_MODEL"] = previous_model
    return results


def write_comparison(inputs: dict[str, dict[str, Path]], results: dict[str, dict[str, Any]], out_dir: Path) -> None:
    lines = ["# Rerun versus pilot-3", "",
             "The rerun uses the current Hermes two-pass chain. Claim differences use utterance id, typed shape, and arguments as identity; surfaces remain in the claim ledgers for audit.", ""]
    ranks = []
    request_drift = {"pass1": 0, "pass2": 0}
    for transcript_id, result in results.items():
        old_claims = json.loads(inputs[transcript_id]["old_extractions"].read_text(encoding="utf-8"))
        old_readings = json.loads(inputs[transcript_id]["old_readings"].read_text(encoding="utf-8")).get("readings", [])
        request_drift["pass1"] += int(inputs[transcript_id]["old_pass1"].read_text(encoding="utf-8") != result["pass1_request"])
        request_drift["pass2"] += int(inputs[transcript_id]["old_pass2"].read_text(encoding="utf-8") != result["pass2_request"])
        added, dropped, changed = compare_claims(old_claims, result["extractions"])
        lines.extend([f"## {transcript_id}", "", f"- Claims added: {len(added)}" + (" — " + "; ".join(added) if added else ""),
                      f"- Claims dropped: {len(dropped)}" + (" — " + "; ".join(dropped) if dropped else ""),
                      f"- Verdicts changed: {len(changed)}" + (" — " + "; ".join(changed) if changed else ""), ""])
        old_counts, new_counts = posture_counts(old_readings), posture_counts(result["readings"])
        lines.append("Posture-reading deltas:")
        rows = []
        for field in ("force", "mode", "operator", "polarity"):
            for value in sorted(set(old_counts[field]) | set(new_counts[field])):
                before, after = old_counts[field][value], new_counts[field][value]
                rows.append([field, value, str(before), str(after), f"{after - before:+d}"])
        lines.extend(markdown_table(["Field", "Value", "Pilot-3", "Rerun", "Delta"], rows or [["-", "-", "0", "0", "+0"]]))
        lines.append("")
        checkable = sum(c.get("verdict") in {"holds", "refuted"} for c in result["extractions"])
        repairs = len(result["report"].get("repair_arcs", []))
        tensions = len(result["report"].get("tensions", []))
        operators = len({str(r.get("pml", {}).get("operator")) for r in result["readings"] if r.get("pml", {}).get("operator")})
        total = 3 * checkable + 2 * repairs + 2 * tensions + operators
        ranks.append((total, transcript_id, checkable, repairs, tensions, operators))
    lines.extend(["## Method notes", "",
                  "The current chain uses its live pass-1 and pass-2 prompt files, local cache and registry state, and the present math-claim checker. The pilot-3 request artifacts were compared against the requests generated here: "
                  f"{request_drift['pass1']}/{len(results)} pass-1 and {request_drift['pass2']}/{len(results)} pass-2 requests differ. Prompt or chain drift can change extraction and posture counts, so these are rerun-to-pilot differences rather than an accuracy claim.", "",
                  "## Juiciness ranking", ""])
    ranks.sort(reverse=True)
    lines.extend(markdown_table(["Rank", "Transcript", "Score", "Checked holds/refuted", "Repair arcs", "Cross-speaker tensions", "PML operators"],
                                [[str(i), tid, str(score), str(checkable), str(repairs), str(tensions), str(operators)]
                                 for i, (score, tid, checkable, repairs, tensions, operators) in enumerate(ranks, 1)]))
    winner = ranks[0]
    lines.extend(["", f"{winner[1]} is the strongest short-paper case because it has the highest transparent composite score ({winner[0]}) across checkable claims, repair arcs, cross-speaker tensions, and operator range.",
                  "Its report and claim ledger keep the mathematical adjudications and the interpretive PML reading distinct, so a paper can examine their coupling without treating either as a verdict on the discussion.", ""])
    (out_dir / "rerun_vs_pilot3.md").write_text("\n".join(lines), encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--model", default="gemma-4-31B-it")
    parser.add_argument("--only", default=",".join(DEFAULT_IDS), help="comma-separated pilot transcript ids")
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--dry-run", action="store_true", help="validate inputs and print a no-network plan")
    args = parser.parse_args(argv)
    ids = tuple(item.strip() for item in args.only.split(",") if item.strip())
    if not ids:
        raise SystemExit("--only must name at least one transcript")
    unknown = sorted(set(ids) - set(DEFAULT_IDS))
    if unknown:
        raise SystemExit("this pilot-3 driver accepts only: " + ", ".join(DEFAULT_IDS))
    for prompt in (PASS1_PROMPT, PASS2_PROMPT):
        if not prompt.is_file():
            raise FileNotFoundError(f"required live prompt is absent: {prompt}")
    inputs = load_inputs(ids)
    if args.dry_run:
        print(f"dry-run: model={args.model}; no network calls; no output writes")
        print(f"prompts: {PASS1_PROMPT}\n         {PASS2_PROMPT}")
        for transcript_id, paths in inputs.items():
            print(f"{transcript_id}: transcript={paths['transcript']} pilot={paths['old_extractions']}")
        print(f"live outputs: {args.out}")
        return 0
    args.out.mkdir(parents=True, exist_ok=True)
    results = run_live(inputs, args.out, args.model)
    write_comparison(inputs, results, args.out)
    print(f"rerun complete: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
