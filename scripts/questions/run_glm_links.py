#!/usr/bin/env python3
"""Run the glm-5.2 linking pass over the question corpus, then verify.

Budget, checkpoints, and the starvation-leak law are the operating rules: a
non-ok response is logged and retried or skipped, never parsed, because
glm-5.2 reasoning can land in content with finish_reason length and read as
an answer. Every batch's raw response is kept, so a rerun resumes instead of
repaying for work already done.
"""
from __future__ import annotations

import argparse
import collections
import importlib.util
import json
import random
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))

from glm_batches import build_batch, parse_reply  # noqa: E402
from linker import (  # noqa: E402
    RUNTIME, TraceRunner, load_menu, load_patterns, load_row_map,
    lesson_pattern_numbers, registry_family_of, sorts_by_asymmetry, verify,
)
from question_corpus import build_sentences, load_records, mineable  # noqa: E402

LEDGER = RUNTIME / "glm_call_ledger.json"
BUDGET = 400
MODEL = "glm-5.2"
# Measured on this task: the service ignores reasoning_effort and thinking
# controls, and glm-5.2 spends roughly 1,700 completion tokens of reasoning per
# question whatever the prompt size. An eight-question batch therefore needs a
# budget near 18,000 or the reply truncates before a single character lands.
MAX_TOKENS = 18000


def call_glm(llm, messages: list[dict], *, api_key: str, api_url: str,
             ssl_ctx, timeout: int, max_tokens: int = MAX_TOKENS, retries: int = 3):
    """One REALLMS call with a bounded reasoning budget.

    The request body carries a parameter the shared client does not send, so
    the request is built here; the reply still goes through the shared parser,
    which owns the outcome law this pass obeys.
    """
    payload = {"model": MODEL, "messages": messages, "max_tokens": max_tokens}
    body = json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    last_error = ""
    for attempt in range(1, retries + 1):
        request = urllib.request.Request(api_url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=timeout, context=ssl_ctx) as response:
                data = json.loads(response.read().decode("utf-8"))
            return llm.parse_chat_completion(data)
        except urllib.error.HTTPError as error:
            last_error = f"HTTP {error.code}"
            if error.code not in llm.RETRYABLE_HTTP_CODES or attempt == retries:
                return llm.ReallmsResult(outcome="http_error", error=last_error,
                                         status_code=error.code, attempts=attempt)
            if error.code == 429:
                # A shared service saying slow down. Five-second backoff is not
                # slowing down; another lane is on the same endpoint tonight.
                time.sleep(60 * attempt)
                continue
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError) as error:
            last_error = f"{type(error).__name__}: {error}"
            if attempt == retries:
                return llm.ReallmsResult(outcome="transport_error", error=last_error,
                                         attempts=attempt, retryable=True)
        time.sleep(5 * attempt)
    return llm.ReallmsResult(outcome="transport_error", error=last_error, attempts=retries)


def load_llm():
    spec = importlib.util.spec_from_file_location("hermes_llm", ROOT / "hermes" / "app" / "llm.py")
    module = importlib.util.module_from_spec(spec)
    assert spec.loader
    spec.loader.exec_module(module)
    return module


def read_ledger() -> dict:
    if LEDGER.is_file():
        return json.loads(LEDGER.read_text(encoding="utf-8"))
    return {"calls": 0, "budget": BUDGET, "runs": []}


def write_ledger(ledger: dict) -> None:
    LEDGER.write_text(json.dumps(ledger, indent=1, sort_keys=True) + "\n", encoding="utf-8")


def statements_by_lesson(rows: list[dict]) -> dict[str, list[str]]:
    table: dict[str, list[str]] = collections.defaultdict(list)
    for row in rows:
        statement = " ".join(str(row.get("statement", "")).split())
        if statement and statement not in table[row["lesson"]]:
            table[row["lesson"]].append(statement)
    return table


def length_band(text: str) -> str:
    words = len(text.split())
    if words <= 6:
        return "short"
    if words <= 12:
        return "medium"
    return "long"


def stratified(candidates: list, size: int, seed: int = 20260812) -> list:
    """Grade x authored move label x question length, filled round robin."""
    buckets: dict[tuple[str, str, str], list] = collections.defaultdict(list)
    for sentence in candidates:
        buckets[(sentence.grade, sentence.record_type, length_band(sentence.text))].append(sentence)
    rng = random.Random(seed)
    for bucket in buckets.values():
        rng.shuffle(bucket)
    chosen: list = []
    keys = sorted(buckets)
    while len(chosen) < size and any(buckets[key] for key in keys):
        for key in keys:
            if buckets[key] and len(chosen) < size:
                chosen.append(buckets[key].pop())
    return chosen


def batches(sentences: list, size: int) -> list[list]:
    by_lesson: dict[str, list] = collections.defaultdict(list)
    for sentence in sentences:
        by_lesson[sentence.lesson].append(sentence)
    ordered: list = []
    for lesson in sorted(by_lesson):
        ordered.extend(sorted(by_lesson[lesson], key=lambda s: (s.record_index, s.sentence_index)))
    return [ordered[start:start + size] for start in range(0, len(ordered), size)]


def normalize_link(raw: dict, sentence, patterns: dict, menu: dict) -> tuple[dict | None, str]:
    """Hold the model to the menus. An off-menu choice is a refusal, not a link."""
    lesson_patterns = {item["pattern_id"] for item in patterns["lesson_patterns"].get(sentence.lesson, [])}
    pattern_ids = raw.get("pattern_ids") or []
    if isinstance(pattern_ids, str):
        pattern_ids = [pattern_ids]
    pattern_ids = [item for item in pattern_ids if item in lesson_patterns]
    move_type = str(raw.get("move_type", "")).strip().casefold()
    if move_type not in {"assessing", "advancing", "general"}:
        return None, "move_type_off_menu"
    if move_type == "general":
        return None, "model_called_it_general"
    if not pattern_ids:
        return None, "no_pattern_from_this_lesson"
    pattern_id = sorted(pattern_ids)[0]
    entry = patterns["patterns"][pattern_id]
    machine = raw.get("machine") or entry["witness_machine"]
    family = registry_family_of(machine, menu)
    if family == "unregistered":
        return None, "machine_off_menu"
    context = str(raw.get("context", "")).strip().casefold()
    if context not in {"productive", "misconception"}:
        context = "productive"
    effect_kind = str(raw.get("effect", "")).strip().casefold()
    if effect_kind not in {"narrows", "raises", "articulates"}:
        return None, "effect_off_menu"
    target = raw.get("effect_target")
    if effect_kind == "narrows":
        candidates = [item["kind"] for item in menu.get(family, []) if item["polarity"] == "deformation"]
        value = [target] if isinstance(target, str) and target in candidates else candidates[:6]
    elif effect_kind == "raises":
        value = target if isinstance(target, str) and target in lesson_patterns else f"representation_of({pattern_id})"
    else:
        value = f"constraint_of({pattern_id})"
    slot_map = raw.get("slot_map") if isinstance(raw.get("slot_map"), dict) else {}
    return {
        "proposer": "glm-5.2",
        "pattern_ids": [pattern_id],
        "machine": machine,
        "registry_family": family,
        "context_polarity": context,
        "move_type": move_type,
        "effect": {"kind": effect_kind, "value": value},
        "slot_map": {str(key): str(item) for key, item in slot_map.items()},
        "rationale": str(raw.get("rationale", ""))[:280],
    }, "kept"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("pilot", "scale"), required=True)
    parser.add_argument("--size", type=int, default=100, help="pilot: questions to sample")
    parser.add_argument("--batch-size", type=int, default=8)
    parser.add_argument("--workers", type=int, default=3,
                        help="concurrent REALLMS calls; another lane shares the service")
    parser.add_argument("--timeout", type=int, default=1500)
    parser.add_argument("--max-tokens", type=int, default=MAX_TOKENS)
    parser.add_argument("--max-calls", type=int, default=0, help="cap this run")
    parser.add_argument("--verify-only", action="store_true",
                        help="re-read the checkpoint and re-verify; make no calls")
    arguments = parser.parse_args()

    tag = arguments.mode
    checkpoint = RUNTIME / f"glm_{tag}_responses.jsonl"
    links_path = RUNTIME / f"glm_{tag}_links.jsonl"
    quarantine_path = RUNTIME / f"glm_{tag}_quarantine.jsonl"
    report_path = RUNTIME / f"glm_{tag}_report.json"

    records = load_records()
    sentences, prefiltered = build_sentences(records)
    patterns = load_patterns()
    menu = load_menu()
    rows = load_row_map()
    numbers = lesson_pattern_numbers(rows, patterns)
    statements = statements_by_lesson(rows)
    lessons_with_patterns = set(patterns["lesson_patterns"])

    routing = collections.Counter()
    candidates = []
    for sentence in sentences:
        if sentence.peer_work:
            routing["requires_peer_work"] += 1
        elif not mineable(sentence):
            routing["general_move_candidate"] += 1
        elif sentence.lesson not in lessons_with_patterns:
            routing["lesson_without_patterns"] += 1
        else:
            routing["mineable_in_mapped_lesson"] += 1
            candidates.append(sentence)

    if arguments.mode == "pilot":
        selected = stratified(candidates, arguments.size)
    else:
        pilot_ids = set()
        pilot_file = RUNTIME / "glm_pilot_responses.jsonl"
        if pilot_file.is_file():
            for line in pilot_file.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    pilot_ids.update(json.loads(line).get("identities", []))
        selected = [sentence for sentence in candidates if sentence.identity not in pilot_ids]

    by_identity = {sentence.identity: sentence for sentence in sentences}
    planned = batches(selected, arguments.batch_size)

    # A non-ok call is not work done. Its row stays in the checkpoint for the
    # record, but the batch is retried rather than silently dropped from the
    # pilot it was sampled into.
    done: dict[str, dict] = {}
    for line in (checkpoint.read_text(encoding="utf-8").splitlines() if checkpoint.is_file() else []):
        if line.strip():
            row = json.loads(line)
            if row["outcome"] == "ok" or row["batch_key"] not in done:
                done[row["batch_key"]] = row
    completed = {key for key, row in done.items() if row["outcome"] == "ok"}

    ledger = read_ledger()
    llm = load_llm()
    llm.load_dotenv(ROOT)
    api_url = llm.resolve_api_url()
    api_key = llm.require_api_key()
    ssl_ctx = llm.build_ssl_context()

    outcomes = collections.Counter()
    pending: list[list] = []
    for batch in planned if not arguments.verify_only else []:
        key = "|".join(sentence.identity for sentence in batch)
        if key in completed:
            outcomes["resumed"] += 1
            continue
        if ledger["calls"] + len(pending) >= BUDGET:
            outcomes["budget_exhausted"] += 1
            break
        if arguments.max_calls and len(pending) >= arguments.max_calls:
            outcomes["run_cap_reached"] += 1
            break
        pending.append(batch)

    def one_call(batch: list) -> dict:
        messages = build_batch(batch, patterns, menu, statements, registry_family_of)
        started = time.time()
        result = call_glm(llm, messages, api_key=api_key, api_url=api_url,
                          ssl_ctx=ssl_ctx, timeout=arguments.timeout,
                          max_tokens=arguments.max_tokens)
        return {
            "batch_key": "|".join(sentence.identity for sentence in batch),
            "identities": [sentence.identity for sentence in batch],
            "outcome": result.outcome,
            "finish_reason": result.finish_reason,
            "usage": result.usage,
            "elapsed_s": round(time.time() - started, 2),
            # The starvation-leak law: content is kept for the record but only
            # read when the transport called the call ok.
            "content": result.content if result.ok else "",
            "error": result.error,
        }

    calls_this_run = 0
    if pending:
        with checkpoint.open("a", encoding="utf-8") as sink:
            with ThreadPoolExecutor(max_workers=arguments.workers) as pool:
                for row in pool.map(one_call, pending):
                    calls_this_run += 1
                    ledger["calls"] += 1
                    outcomes[row["outcome"]] += 1
                    sink.write(json.dumps(row, ensure_ascii=False) + "\n")
                    sink.flush()
                    done[row["batch_key"]] = row
                    write_ledger(ledger)

    ledger.setdefault("runs", []).append({
        "mode": arguments.mode, "calls": calls_this_run,
        "outcomes": dict(outcomes), "batch_size": arguments.batch_size,
    })
    write_ledger(ledger)

    runner = TraceRunner()
    verified_rows: list[dict] = []
    quarantined: list[dict] = []
    failures = collections.Counter()
    normalization = collections.Counter()
    answered = set()
    try:
        for row in done.values():
            if row["outcome"] != "ok" or not row["content"]:
                continue
            links = parse_reply(row["content"])
            if links is None:
                normalization["unparseable_reply"] += 1
                continue
            for raw in links:
                identity = str(raw.get("id", "")).strip()
                sentence = by_identity.get(identity)
                if sentence is None or identity not in row["identities"]:
                    normalization["id_not_in_batch"] += 1
                    continue
                if identity in answered:
                    normalization["duplicate_id"] += 1
                    continue
                answered.add(identity)
                link, reason = normalize_link(raw, sentence, patterns, menu)
                normalization[reason] += 1
                if link is None:
                    continue
                outcome = verify(link, sentence, patterns, numbers, runner)
                stored = {**sentence.to_dict(), **link, "verification": outcome}
                if outcome["verified"]:
                    verified_rows.append(stored)
                else:
                    quarantined.append(stored)
                    for name in outcome["failed"]:
                        failures[name] += 1
    finally:
        runner.close()

    links_path.write_text(
        "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in verified_rows),
        encoding="utf-8")
    quarantine_path.write_text(
        "".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in quarantined),
        encoding="utf-8")

    sorting = sum(1 for row in verified_rows if sorts_by_asymmetry(row))
    report = {
        "mode": arguments.mode,
        "prefilter_exclusions": prefiltered,
        "routing": dict(routing),
        "questions_offered": len(selected),
        "batches_planned": len(planned),
        "calls_this_run": calls_this_run,
        "calls_total": ledger["calls"],
        "budget": BUDGET,
        "transport_outcomes": dict(outcomes),
        "normalization": dict(normalization),
        "answered_questions": len(answered),
        "verified": len(verified_rows),
        "quarantined": len(quarantined),
        "failed_check_counts": dict(failures),
        "verified_by_move_type": dict(collections.Counter(row["move_type"] for row in verified_rows)),
        "verified_by_effect": dict(collections.Counter(row["effect"]["kind"] for row in verified_rows)),
        "verified_by_context": dict(collections.Counter(row["context_polarity"] for row in verified_rows)),
        "verified_by_grade": dict(collections.Counter(row["grade"] for row in verified_rows)),
        "sorts_by_asymmetry": sorting,
        "asymmetry_share": round(sorting / len(verified_rows), 4) if verified_rows else None,
        "links_path": str(links_path),
        "quarantine_path": str(quarantine_path),
    }
    report_path.write_text(json.dumps(report, indent=1, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
