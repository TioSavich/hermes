#!/usr/bin/env python3
"""Stage 2 of the mechanical question-admission pipeline: the model pass.

Reads hermes/app/runtime/experiments/questions_admission/model_input.jsonl
(built by scripts/questions/build_admission_candidates.py) and asks a
node-local llama-server, gemma-4-26B-A4B-it_Q4_K_M, to read each question's
TEXT ALONE and answer a constrained choice -- never the stored label, the
region_type, the heading, the activity location, or the lesson code. The
model's reading is a second, independent warrant; agreement with the
deterministic heading rule is corroboration, not ground truth.

THE LEAKAGE BOUNDARY, enforced by code structure, not by discipline:

  build_prompt(row) takes only a model_input.jsonl row (id, lane, text, and
  the pilot/sentinel flags). It never imports pilot_key.jsonl and never
  will -- the file that carries a row's stored label
  (hermes/app/runtime/experiments/questions_admission/pilot_key.jsonl,
  written by stage 0) is read by exactly one function in this file,
  lane_pilot_decision(), and only after verdicts already exist. If you are
  adding a feature to this script and it wants pilot_key data inside
  build_prompt or judge_one, stop -- that is the boundary this design names,
  not a style preference.

THE IN-JOB PILOT AND THE PRE-FIXED VOID RULE: this script judges a
pre-fixed pilot slice per lane first (stage 0 flags the chosen rows
"pilot": true), computes modal-answer share and Cohen's kappa against
pilot_key.jsonl for that lane, and VOIDS the lane (writes pass_void.json,
skips its remaining rows) when modal share >= 0.95 (mode collapse) or kappa
< 0.20 (low signal) -- fixed thresholds, decided before this script ever
ran, not tuned after seeing the numbers. A voided lane is a finding, not a
failure: exit code is nonzero only when BOTH lanes void.

Usage on Big Red (inside judge.sbatch, llama-server already up):
  python3 scripts/bigred/questions_admission/judge.py --llama http://127.0.0.1:8088

Usage anywhere, no server needed, to inspect the exact prompts sent:
  python3 scripts/bigred/questions_admission/judge.py --dry-run
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import time
from collections import Counter
from pathlib import Path
from typing import Any

import requests

ROOT = Path(__file__).resolve().parents[3]
OUT_DIR = ROOT / "hermes/app/runtime/experiments/questions_admission"
DEFAULT_MODEL_INPUT = OUT_DIR / "model_input.jsonl"
DEFAULT_PILOT_KEY = OUT_DIR / "pilot_key.jsonl"
DEFAULT_VERDICTS = OUT_DIR / "verdicts.jsonl"
DEFAULT_PASS_VOID = OUT_DIR / "pass_void.json"

MODEL_NAME = "gemma-4-26B-A4B-it_Q4_K_M"
MAX_ATTEMPTS = 3
RETRY_SLEEP_S = 3
MODAL_SHARE_VOID_THRESHOLD = 0.95
KAPPA_VOID_THRESHOLD = 0.20
LABELS_CHOICES = {"assessing", "advancing", "cannot_tell"}
GUIDE_KINDS = {"teacher_question", "activity_title", "student_task_text", "not_a_question"}

# Verbatim from .superpowers/sdd/task-0820C-design.md section 3. Copied
# character-for-character, including the JSON-brace line: no IM section
# name ("Launch", "Synthesis", "Advancing Student Thinking") appears in
# either template, and neither template may gain a field codex was not
# told to add. Filled by str.replace, never str.format, so the literal
# "{" and "}" in the JSON-object lines never collide with format syntax.
LABELS_PROMPT_TEMPLATE = """You are labeling one teacher question from an elementary mathematics
curriculum.

Two labels exist:
- assessing: the question asks a student to explain or show what they did
  or what they currently think; it stays inside the student's existing work.
- advancing: the question presses beyond the student's current work toward
  the mathematical goal - to extend, connect, generalize, or take a next step.

Answer with ONLY a JSON object, no prose around it:
{"label": "assessing" | "advancing" | "cannot_tell"}

"cannot_tell" is an accepted answer when the text alone does not settle it.

QUESTION: {text}
"""

GUIDE_PROMPT_TEMPLATE = """You are reading one line extracted from a teacher lesson guide. Decide what
it is and, only if it is a question a teacher asks students, label its
function.

kind:
- teacher_question: a question the teacher poses to students during the lesson
- activity_title: the name of a game or activity (these may end in a
  question mark)
- student_task_text: text from the student-facing task, not a teacher's
  question
- not_a_question: not interrogative

label (only when kind is teacher_question):
- assessing: the question asks a student to explain or show what they did
  or what they currently think; it stays inside the student's existing work.
- advancing: the question presses beyond the student's current work toward
  the mathematical goal - to extend, connect, generalize, or take a next step.

Answer with ONLY a JSON object, no prose around it:
{"kind": "...", "label": "assessing" | "advancing" | "cannot_tell" | null}

TEXT: {text}
"""

LABELS_PROMPT_SHA = hashlib.sha256(LABELS_PROMPT_TEMPLATE.encode("utf-8")).hexdigest()
GUIDE_PROMPT_SHA = hashlib.sha256(GUIDE_PROMPT_TEMPLATE.encode("utf-8")).hexdigest()
PROMPT_SHAS = {"labels": LABELS_PROMPT_SHA, "guide": GUIDE_PROMPT_SHA}


# ---------------------------------------------------------------------------
# The prompt builder. Reads ONLY `row`. Never touches pilot_key.jsonl.
# ---------------------------------------------------------------------------

def build_prompt(row: dict[str, Any]) -> str:
    template = LABELS_PROMPT_TEMPLATE if row["lane"] == "labels" else GUIDE_PROMPT_TEMPLATE
    return template.replace("{text}", row["text"])


# ---------------------------------------------------------------------------
# Model I/O and reply parsing
# ---------------------------------------------------------------------------

def call_model(llama: str, prompt: str, max_tokens: int) -> str | None:
    try:
        response = requests.post(
            llama + "/v1/chat/completions",
            json={
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0,
                "max_tokens": max_tokens,
            },
            timeout=120,
        )
        response.raise_for_status()
        return response.json()["choices"][0]["message"]["content"].strip()
    except (requests.RequestException, KeyError, ValueError):
        return None


def extract_json_object(raw: str | None) -> dict[str, Any] | None:
    if raw is None:
        return None
    start, end = raw.find("{"), raw.rfind("}")
    if start < 0 or end <= start:
        return None
    try:
        parsed = json.loads(raw[start:end + 1])
    except json.JSONDecodeError:
        return None
    return parsed if isinstance(parsed, dict) else None


def parse_labels_reply(raw: str | None) -> tuple[str | None, None, bool]:
    obj = extract_json_object(raw)
    if obj is None:
        return None, None, False
    label = obj.get("label")
    if label not in LABELS_CHOICES:
        return None, None, False
    return label, None, True


def parse_guide_reply(raw: str | None) -> tuple[str | None, str | None, bool]:
    obj = extract_json_object(raw)
    if obj is None:
        return None, None, False
    kind = obj.get("kind")
    if kind not in GUIDE_KINDS:
        return None, None, False
    if kind != "teacher_question":
        return None, kind, True
    label = obj.get("label")
    if label not in LABELS_CHOICES:
        return None, None, False
    return label, kind, True


def judge_one(row: dict[str, Any], args: argparse.Namespace) -> dict[str, Any]:
    prompt = build_prompt(row)
    parser = parse_labels_reply if row["lane"] == "labels" else parse_guide_reply
    raw = None
    for _attempt in range(MAX_ATTEMPTS):
        started = time.monotonic()
        raw = call_model(args.llama, prompt, args.max_tokens)
        latency_s = time.monotonic() - started
        verdict, kind, ok = parser(raw)
        if ok:
            return {
                "id": row["id"], "lane": row["lane"], "verdict": verdict,
                "kind": kind, "prompt_sha": PROMPT_SHAS[row["lane"]],
                "model": args.model, "job": args.job, "date": args.date,
                "latency_s": round(latency_s, 3), "raw": raw,
            }
        time.sleep(RETRY_SLEEP_S)
    return {
        "id": row["id"], "lane": row["lane"], "verdict": "model_unparseable",
        "kind": None, "prompt_sha": PROMPT_SHAS[row["lane"]],
        "model": args.model, "job": args.job, "date": args.date,
        "latency_s": 0.0, "raw": raw,
    }


# ---------------------------------------------------------------------------
# The pilot-decision function. The ONLY function in this file that reads
# pilot_key.jsonl, and only after verdicts already exist.
# ---------------------------------------------------------------------------

def cohens_kappa(pairs: list[tuple[str, str]]) -> float | None:
    n = len(pairs)
    if n == 0:
        return None
    categories = sorted({value for pair in pairs for value in pair})
    if len(categories) < 2:
        return None
    observed = sum(1 for a, b in pairs if a == b) / n
    rater_a = Counter(a for a, _ in pairs)
    rater_b = Counter(b for _, b in pairs)
    expected = sum((rater_a[c] / n) * (rater_b[c] / n) for c in categories)
    if expected >= 1.0:
        return 1.0 if observed >= 1.0 else 0.0
    return (observed - expected) / (1 - expected)


def modal_share(values: list[str]) -> tuple[float, str | None]:
    if not values:
        return 0.0, None
    counts = Counter(values)
    answer, count = counts.most_common(1)[0]
    return count / len(values), answer


def lane_pilot_decision(
    lane: str,
    pilot_rows: list[dict[str, Any]],
    verdicts_by_id: dict[str, dict[str, Any]],
    pilot_key_by_id: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    """Compute modal-answer share and kappa for one lane's pilot slice.

    This is the ONLY place in this file pilot_key_by_id is read. It runs
    after the pilot rows are already judged, never before, and never
    inside build_prompt/judge_one.
    """
    pairs: list[tuple[str, str]] = []
    verdict_values: list[str] = []
    for row in pilot_rows:
        verdict_record = verdicts_by_id.get(row["id"])
        if verdict_record is None or verdict_record["verdict"] not in LABELS_CHOICES:
            continue
        key_record = pilot_key_by_id.get(row["id"])
        if key_record is None:
            continue
        pairs.append((key_record["stored_label"], verdict_record["verdict"]))
        verdict_values.append(verdict_record["verdict"])

    share, answer = modal_share(verdict_values)
    kappa = cohens_kappa(pairs)
    void, reason = False, None
    if share >= MODAL_SHARE_VOID_THRESHOLD:
        void, reason = True, "mode_collapse"
    elif kappa is None or kappa < KAPPA_VOID_THRESHOLD:
        void, reason = True, "low_signal"
    return {
        "lane": lane, "void": void, "reason": reason, "n": len(pairs),
        "modal_share": round(share, 4), "modal_answer": answer,
        "kappa": None if kappa is None else round(kappa, 4),
    }


def write_pass_void(path: Path, voided_decisions: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "lanes": [
            {
                "lane": decision["lane"], "reason": decision["reason"],
                "n": decision["n"], "modal_share": decision["modal_share"],
                "modal_answer": decision["modal_answer"], "kappa": decision["kappa"],
            }
            for decision in voided_decisions
        ]
    }
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# I/O helpers
# ---------------------------------------------------------------------------

def load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    return rows


def load_verdicts_by_id(path: Path) -> dict[str, dict[str, Any]]:
    return {row["id"]: row for row in load_jsonl(path)}


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def dry_run(rows: list[dict[str, Any]]) -> None:
    """Format and print example prompts without a server.

    Proves the leakage boundary by inspection: every printed prompt is
    built from a model_input.jsonl row alone, and that row never carries a
    stored label, region_type, heading, activity_location, or lesson code
    for build_prompt to leak even if it tried.
    """
    picks = [
        ("labels", next((r for r in rows if r["lane"] == "labels" and not r.get("sentinel")), None)),
        ("guide", next((r for r in rows if r["lane"] == "guide"), None)),
        ("sentinel (rides the labels prompt)", next((r for r in rows if r.get("sentinel")), None)),
    ]
    for name, row in picks:
        if row is None:
            print(f"=== {name}: no row available in this model_input.jsonl ===\n")
            continue
        prompt = build_prompt(row)
        print(f"=== {name} lane -- row id {row['id']} ===")
        print(f"row keys sent to build_prompt: {sorted(row.keys())}")
        print(prompt)
        print(f"--- prompt_sha256: {PROMPT_SHAS[row['lane']]} ---\n")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model-input", type=Path, default=DEFAULT_MODEL_INPUT)
    parser.add_argument("--pilot-key", type=Path, default=DEFAULT_PILOT_KEY)
    parser.add_argument("--verdicts", type=Path, default=DEFAULT_VERDICTS)
    parser.add_argument("--pass-void", type=Path, default=DEFAULT_PASS_VOID)
    parser.add_argument("--llama", default="http://127.0.0.1:8088")
    parser.add_argument("--model", default=MODEL_NAME)
    parser.add_argument("--job", default=os.environ.get("SLURM_JOB_ID", "unknown"))
    parser.add_argument("--date", default=dt.date.today().isoformat())
    parser.add_argument("--max-tokens", type=int, default=120)
    parser.add_argument("--dry-run", action="store_true",
                         help="format and print example prompts; no server call")
    args = parser.parse_args()

    rows = load_jsonl(args.model_input)
    if not rows:
        raise SystemExit(f"no rows in {args.model_input} -- run stage 0 first")

    if args.dry_run:
        dry_run(rows)
        return 0

    labels_rows = [r for r in rows if r["lane"] == "labels" and not r.get("sentinel")]
    guide_rows = [r for r in rows if r["lane"] == "guide"]
    sentinel_rows = [r for r in rows if r.get("sentinel")]
    labels_pilot = [r for r in labels_rows if r.get("pilot")]
    guide_pilot = [r for r in guide_rows if r.get("pilot")]

    done_ids = {row["id"] for row in load_jsonl(args.verdicts)}
    args.verdicts.parent.mkdir(parents=True, exist_ok=True)
    handle = args.verdicts.open("a", encoding="utf-8")

    def run_batch(batch: list[dict[str, Any]], label: str) -> None:
        for index, row in enumerate(batch):
            if row["id"] in done_ids:
                continue
            record = judge_one(row, args)
            handle.write(json.dumps(record, ensure_ascii=False) + "\n")
            handle.flush()
            done_ids.add(row["id"])
            print(
                f"[judge] {label} {index + 1}/{len(batch)} {row['id']} "
                f"-> {record['verdict']}",
                flush=True,
            )

    # Phase 1: pilot rows (both lanes) plus the five sentinels, judged
    # before any void decision -- sentinels ride the labels batch here
    # regardless of what either lane's pilot decides.
    run_batch(labels_pilot, "labels-pilot")
    run_batch(sentinel_rows, "sentinel")
    run_batch(guide_pilot, "guide-pilot")
    handle.flush()

    # Phase 2: decide, per lane, from the pilot verdicts just recorded.
    verdicts_by_id = load_verdicts_by_id(args.verdicts)
    pilot_key_by_id = {row["id"]: row for row in load_jsonl(args.pilot_key)}
    labels_decision = lane_pilot_decision("labels", labels_pilot, verdicts_by_id, pilot_key_by_id)
    guide_decision = lane_pilot_decision("guide", guide_pilot, verdicts_by_id, pilot_key_by_id)
    print(f"[judge] pilot decision labels: {json.dumps(labels_decision)}", flush=True)
    print(f"[judge] pilot decision guide: {json.dumps(guide_decision)}", flush=True)

    voided = [decision for decision in (labels_decision, guide_decision) if decision["void"]]
    if voided:
        write_pass_void(args.pass_void, voided)
        print(f"[judge] pass_void.json written: {[d['lane'] for d in voided]}", flush=True)

    # Phase 3: continue through the full lane only where the pilot did not
    # void it. Pilot verdicts are reused, never re-asked.
    if not labels_decision["void"]:
        pilot_ids = {row["id"] for row in labels_pilot}
        run_batch([row for row in labels_rows if row["id"] not in pilot_ids], "labels-full")
    if not guide_decision["void"]:
        pilot_ids = {row["id"] for row in guide_pilot}
        run_batch([row for row in guide_rows if row["id"] not in pilot_ids], "guide-full")

    handle.close()
    if labels_decision["void"] and guide_decision["void"]:
        print(
            "[judge] BOTH LANES VOID -- the independent reading adds no "
            "warrant here; every model-dependent row holds as pass_void. "
            "This is the cheapest falsifier firing, not a crash.",
            flush=True,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
