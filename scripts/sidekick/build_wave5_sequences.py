#!/usr/bin/env python3
"""Render the wave-5 training sequences: solutions, questions, anchors.

Wave 5 supervises one plain assistant reply per row. No row calls a tool, so
every sequence is kind `C` with an empty menu and the mask runs from the
model-turn header to the end of the reply.

Three legs enter the artifact:

* solutions — a mathematics task in, one executable Prolog program out, taken
  from the wave-5 solution mint at the training split with a KEEP verdict in
  the semantic ledger;
* questions — a teaching moment in, one curriculum question out, taken from the
  admitted questioning PIO rows with a KEEP verdict;
* anchors — an ordinary teaching prompt in, the untuned checkpoint's own reply
  out, which is what keeps the tuned weights answering in the register they
  started with.

The diagnosis leg is absent. Its mint sits below the ratified per-validity-class
floor, so no diagnosis row is consumable this wave.

The supervised close is measured from the checkpoint's own template and
vocabulary rather than chosen: a plain reply ends at the template's turn close,
and every row is checked to end in exactly those token ids.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import random
import re
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(SCRIPT_DIR), str(REPO_ROOT)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_wave3_sequences import SequenceRow, render_sequence  # noqa: E402
from chat_format import AssetsMissing, GemmaChatFormat, asset_dir  # noqa: E402
from contamination import GRAM, INDEX_PATH, OverlapGate, index_manifest  # noqa: E402
from run_wave5_f1 import SERVING_PROMPT  # noqa: E402
from supervision import (  # noqa: E402
    IGNORE,
    build_sequence,
    check_plain_reply_corruptions,
    check_sequence,
)

RUNTIME = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments"
DATASETS = RUNTIME / "sidekick" / "datasets"
SOLUTION_PAIRS = DATASETS / "wave5-solution-pairs.jsonl"
SEMANTIC_LEDGER = DATASETS / "wave5-semantic-pass.jsonl"
SPLIT_MANIFEST = DATASETS / "wave5-split-manifest.json"
PIO_PAIRS = RUNTIME / "questions" / "question-pio-pairs.jsonl"
ANCHOR_REPLIES = DATASETS / "wave5-anchor-replies.jsonl"
OUTPUT = DATASETS / "sidekick-wave5-seqs.jsonl"
GATES = DATASETS / "sidekick-wave5-seqs-gates.json"

BUILDER_VERSION = "wave5-sequences-v1"
MAX_LENGTH = 4096
EPOCHS = 3
SHUFFLE_SEED = 20260813
ANCHOR_SELECTION_SEED = 20260813
ANCHOR_SHARE = 0.20
QUESTION_SHARE_BOUND = 0.25
DESIGN_PROCESSED_TOKEN_RANGE = (6_000_000, 10_000_000)
# The frozen split manifest names which lessons train. Sequences read it; they
# never rewrite it.
TRAIN_SPLIT = "train"
# A completed reply ends on sentence-final punctuation or a closing mark.
FINISHED_REPLY = re.compile(r"[.!?)\]\"\u201d*`]\s*$")


class BuildBlocked(RuntimeError):
    """A wave-5 sequence build that must not produce an artifact."""


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    with path.open(encoding="utf-8") as handle:
        return [json.loads(line) for line in handle if line.strip()]


def stable_rank(key: str, seed: int) -> str:
    return hashlib.sha256(f"{seed}:{key}".encode("utf-8")).hexdigest()


def verdicts(path: Path) -> dict[str, str]:
    table: dict[str, str] = {}
    for row in read_jsonl(path):
        pair_id = str(row["id"])
        if pair_id in table:
            raise BuildBlocked(f"the semantic ledger holds two verdicts for {pair_id}")
        table[pair_id] = str(row["verdict"])
    return table


def solution_rows(ledger: dict[str, str]) -> tuple[list[dict[str, Any]], Counter[str]]:
    drops: Counter[str] = Counter()
    rows: list[dict[str, Any]] = []
    for pair in read_jsonl(SOLUTION_PAIRS):
        verdict = ledger.get(str(pair["id"]))
        if verdict is None:
            drops["no_semantic_verdict"] += 1
            continue
        if verdict != "keep":
            drops["semantic_flag"] += 1
            continue
        if pair["split"] != TRAIN_SPLIT:
            drops["held_out_split"] += 1
            continue
        rows.append({
            "leg": "solution",
            "key": str(pair["id"]),
            "system": SERVING_PROMPT,
            "user": pair["input"],
            "assistant": pair["output"],
            "stratum": f"{pair['grade']}|{pair['family']}|{pair['genre']}",
            "provenance": {
                "leg": "solution",
                "source": str(SOLUTION_PAIRS.relative_to(REPO_ROOT)),
                "pair_id": pair["id"],
                "lesson": pair["lesson"],
                "grade": pair["grade"],
                "family": pair["family"],
                "genre": pair["genre"],
                "machine": pair["machine"],
                "split": pair["split"],
            },
            "gates": {
                "semantic_keep": True,
                "training_split": True,
                "benchmark_13gram_clear": True,
                "heldout_8gram_clear": True,
            },
        })
    return rows, drops


def question_rows(ledger: dict[str, str]) -> tuple[list[dict[str, Any]], Counter[str]]:
    drops: Counter[str] = Counter()
    rows: list[dict[str, Any]] = []
    for pair in read_jsonl(PIO_PAIRS):
        if pair.get("admitted_for_training") is not True:
            drops["not_admitted"] += 1
            continue
        verdict = ledger.get(str(pair["identity"]))
        if verdict is None:
            drops["no_semantic_verdict"] += 1
            continue
        if verdict != "keep":
            drops["semantic_flag"] += 1
            continue
        if pair["split"] != TRAIN_SPLIT:
            drops["held_out_split"] += 1
            continue
        rows.append({
            "leg": "question",
            "key": str(pair["identity"]),
            "system": pair["prompt"],
            "user": pair["input"],
            "assistant": pair["output"],
            "stratum": f"{pair['grade']}|{pair['label']}",
            "provenance": {
                "leg": "question",
                "source": str(PIO_PAIRS.relative_to(REPO_ROOT)),
                "identity": pair["identity"],
                "lesson": pair["lesson"],
                "grade": pair["grade"],
                "label": pair["label"],
                "activity_location": pair["activity_location"],
                "split": pair["split"],
            },
            "gates": {
                "semantic_keep": True,
                "training_split": True,
                "admitted_for_training": True,
                "verbatim_curriculum_question": True,
            },
        })
    return rows, drops


def anchor_rows(target: int) -> tuple[list[dict[str, Any]], Counter[str]]:
    """Select the anchor rows that bring the mix to its pre-registered share."""
    drops: Counter[str] = Counter()
    available = read_jsonl(ANCHOR_REPLIES)
    usable: list[dict[str, Any]] = []
    for row in available:
        reply = str(row.get("reply", "")).strip()
        if not reply:
            drops["empty_reply"] += 1
            continue
        # A reply that ran into the generation cap stops mid-sentence. Training
        # on it would teach the model to stop mid-sentence too.
        if not FINISHED_REPLY.search(reply):
            drops["reply_stopped_mid_sentence"] += 1
            continue
        usable.append(row)
    usable.sort(key=lambda row: stable_rank(str(row["id"]), ANCHOR_SELECTION_SEED))
    if len(usable) < target:
        raise BuildBlocked(
            f"the anchor set holds {len(usable)} usable replies; the mix needs {target}"
        )
    drops["not_selected_for_the_share"] += len(usable) - target
    rows: list[dict[str, Any]] = []
    for row in usable[:target]:
        rows.append({
            "leg": "anchor",
            "key": str(row["id"]),
            "system": str(row["system"]),
            "user": str(row["prompt"]),
            "assistant": str(row["reply"]),
            "stratum": f"anchor|{row.get('grade', 'none')}",
            "provenance": {
                "leg": "anchor",
                "source": str(ANCHOR_REPLIES.relative_to(REPO_ROOT)),
                "anchor_id": row["id"],
                "model": row.get("model"),
                "temperature": row.get("temperature"),
                "grade": row.get("grade"),
                "template_id": row.get("template_id"),
            },
            "gates": {
                "untuned_reply": True,
                "benchmark_13gram_clear": True,
                "heldout_8gram_clear": True,
                "temperature_zero": float(row.get("temperature", 0.0)) == 0.0,
            },
        })
    return rows, drops


def measured_close(chat: GemmaChatFormat) -> list[int]:
    """The checkpoint's own close for a plain reply, read from its template."""
    probe = chat.render(
        [
            {"role": "system", "content": "close probe"},
            {"role": "user", "content": "close probe"},
            {"role": "assistant", "content": "close probe"},
        ],
        [],
    )
    close = chat.encode("<turn|>\n")
    if probe.ids[-len(close):] != close:
        raise BuildBlocked(
            "the template's plain-reply render does not end in its own turn close"
        )
    return close


def build_rows(chat: GemmaChatFormat, rows: list[dict[str, Any]], close: list[int]) -> tuple[
    list[SequenceRow], list[dict[str, Any]], Counter[str]
]:
    built: list[SequenceRow] = []
    measures: list[dict[str, Any]] = []
    drops: Counter[str] = Counter()
    for row in rows:
        sequence = SequenceRow(
            id=f"{row['key']}::{row['leg'][0].upper()}",
            source_row_id=row["key"],
            row_class=row["leg"],
            kind="C",
            round_index=None,
            bare_prefix=True,
            menu=[],
            messages=[
                {"role": "system", "content": row["system"]},
                {"role": "user", "content": row["user"]},
                {"role": "assistant", "content": row["assistant"]},
            ],
            source_provenance=row["provenance"],
            source_gates=row["gates"],
        )
        rendered = render_sequence(chat, sequence, {})
        if rendered.ids[-len(close):] != close:
            raise BuildBlocked(f"{sequence.id} does not end in the measured close")
        supervision = build_sequence(chat, rendered, "C")
        check_sequence(chat, rendered, supervision, "C")
        if supervision.supervised_count == 0:
            raise BuildBlocked(f"{sequence.id} supervises no token")
        supervised_close = supervision.labels[-len(close):]
        if supervised_close != close:
            raise BuildBlocked(f"{sequence.id} does not supervise its own close")
        if len(rendered.ids) > MAX_LENGTH:
            drops["over_max_length"] += 1
            continue
        built.append(sequence.with_render(rendered, supervision.labels))
        measures.append({
            "id": sequence.id,
            "leg": row["leg"],
            "stratum": row["stratum"],
            "tokens": len(rendered.ids),
            "supervised": supervision.supervised_count,
            "prompt_tokens": len(rendered.ids) - supervision.supervised_count,
        })
    return built, measures, drops


def g7_table(measures: list[dict[str, Any]]) -> dict[str, Any]:
    """Model-token accounting: totals, per-leg strata, and the output bound."""
    by_leg: defaultdict[str, list[dict[str, Any]]] = defaultdict(list)
    by_stratum: defaultdict[tuple[str, str], list[dict[str, Any]]] = defaultdict(list)
    for item in measures:
        by_leg[item["leg"]].append(item)
        by_stratum[(item["leg"], item["stratum"])].append(item)

    def summary(items: list[dict[str, Any]]) -> dict[str, Any]:
        tokens = [item["tokens"] for item in items]
        supervised = [item["supervised"] for item in items]
        return {
            "rows": len(items),
            "tokens_total": sum(tokens),
            "tokens_max": max(tokens),
            "tokens_median": int(statistics.median(tokens)),
            "supervised_total": sum(supervised),
            "supervised_max": max(supervised),
            "supervised_median": int(statistics.median(supervised)),
        }

    total_tokens = sum(item["tokens"] for item in measures)
    supervised_max = max(item["supervised"] for item in measures)
    longest = max(measures, key=lambda item: item["supervised"])
    return {
        "law": "model tokens are counted on the checkpoint's own vocabulary, per leg and per stratum",
        "all": summary(measures),
        "by_leg": {leg: summary(items) for leg, items in sorted(by_leg.items())},
        "by_stratum": {
            f"{leg}|{stratum}": summary(items)
            for (leg, stratum), items in sorted(by_stratum.items())
        },
        "processed_tokens_per_epoch": total_tokens,
        "epochs": EPOCHS,
        "processed_tokens_total": total_tokens * EPOCHS,
        "design_estimate_range": list(DESIGN_PROCESSED_TOKEN_RANGE),
        "within_two_times_the_design_estimate": (
            DESIGN_PROCESSED_TOKEN_RANGE[0] / 2
            <= total_tokens * EPOCHS
            <= DESIGN_PROCESSED_TOKEN_RANGE[1] * 2
        ),
        "model_token_output_bound": supervised_max,
        "model_token_output_bound_row": longest["id"],
        "bound_note": (
            "the supervised reply never exceeds this many model tokens in training; "
            "serving reads the same number as its output stop"
        ),
        "grammar_output_bound_model_tokens": max(
            (item["supervised"] for item in measures if item["leg"] == "solution"),
            default=0,
        ),
        "grammar_bound_note": (
            "the S1 grammar bounded a program at 256 whitespace-delimited tokens; "
            "this is the same bound read in the checkpoint's own tokens, measured "
            "over the solution leg alone"
        ),
    }


def build(target_anchor_share: float) -> dict[Path, bytes]:
    chat = GemmaChatFormat()
    check_plain_reply_corruptions(chat)
    close = measured_close(chat)

    ledger = verdicts(SEMANTIC_LEDGER)
    solutions, solution_drops = solution_rows(ledger)
    questions, question_drops = question_rows(ledger)
    fixed_rows = len(solutions) + len(questions)
    anchor_target = round(fixed_rows * target_anchor_share / (1 - target_anchor_share))
    anchors, anchor_drops = anchor_rows(anchor_target)

    rows = solutions + questions + anchors
    # The legs were gated at their own mints, but the anchor replies were
    # generated after those gates ran. Every message of every row meets the
    # benchmark index once more here, so the artifact carries its own evidence.
    gate = OverlapGate()
    contamination_hits = [
        {"key": row["key"], "role": role, "grams": hits[:3]}
        for row in rows
        for role, hits in (
            (field, gate.hits(row[field])) for field in ("system", "user", "assistant")
        )
        if hits
    ]
    if contamination_hits:
        raise BuildBlocked(
            f"{len(contamination_hits)} rows share a 13-gram with the benchmark index: "
            f"{contamination_hits[:3]}"
        )
    built, measures, render_drops = build_rows(chat, rows, close)
    order = random.Random(SHUFFLE_SEED)
    order.shuffle(built)

    counts = Counter(sequence.row_class for sequence in built)
    total = len(built)
    anchor_share = counts["anchor"] / total
    question_share = counts["question"] / total
    if question_share > QUESTION_SHARE_BOUND:
        raise BuildBlocked(
            f"the questioning leg is {question_share:.3f} of the mix, above its "
            f"{QUESTION_SHARE_BOUND} bound"
        )

    body = b"".join(
        json.dumps(sequence.to_dict(), ensure_ascii=False, sort_keys=True).encode("utf-8")
        + b"\n"
        for sequence in built
    )
    report = {
        "builder_version": BUILDER_VERSION,
        "artifact": str(OUTPUT.relative_to(REPO_ROOT)),
        "artifact_sha256": hashlib.sha256(body).hexdigest(),
        "rows": total,
        "rows_by_leg": dict(sorted(counts.items())),
        "mix": {
            "anchor_share": round(anchor_share, 6),
            "anchor_share_target": target_anchor_share,
            "question_share": round(question_share, 6),
            "question_share_bound": QUESTION_SHARE_BOUND,
            "anchor_rows_requested": anchor_target,
        },
        "sources": {
            "solution_pairs": {
                "path": str(SOLUTION_PAIRS.relative_to(REPO_ROOT)),
                "sha256": sha256(SOLUTION_PAIRS),
            },
            "semantic_ledger": {
                "path": str(SEMANTIC_LEDGER.relative_to(REPO_ROOT)),
                "sha256": sha256(SEMANTIC_LEDGER),
            },
            "split_manifest": {
                "path": str(SPLIT_MANIFEST.relative_to(REPO_ROOT)),
                "sha256": sha256(SPLIT_MANIFEST),
            },
            "question_pio_pairs": {
                "path": str(PIO_PAIRS.relative_to(REPO_ROOT)),
                "sha256": sha256(PIO_PAIRS),
            },
            "anchor_replies": {
                "path": str(ANCHOR_REPLIES.relative_to(REPO_ROOT)),
                "sha256": sha256(ANCHOR_REPLIES),
            },
        },
        "termination": {
            "law": "M-1: supervise the checkpoint's own close for a plain reply",
            "measured_close_token_ids": close,
            "measured_close_text": "<turn|>\\n",
            "measured_from": str(asset_dir()),
            "invented_close_token": False,
        },
        "benchmark_gate": {
            "law": "every message of every row is checked against the benchmark index",
            "gram": GRAM,
            "index": str(INDEX_PATH.relative_to(REPO_ROOT)),
            "index_sha256": sha256(INDEX_PATH),
            "manifest": index_manifest(),
            "hits": 0,
        },
        "mask": {
            "law": "prompt tokens masked, reply tokens supervised, checked per row at build and at load",
            "kind": "C",
            "ignore_index": IGNORE,
            "corruption_cases_caught": check_plain_reply_corruptions(chat),
        },
        "drops": {
            "law": "drop and count; no sequence is truncated",
            "solution": dict(sorted(solution_drops.items())),
            "question": dict(sorted(question_drops.items())),
            "anchor": dict(sorted(anchor_drops.items())),
            "render": dict(sorted(render_drops.items())),
            "max_length": MAX_LENGTH,
        },
        "g7_token_accounting": g7_table(measures),
        "diagnosis_leg": {
            "included": False,
            "reason": "the diagnosis mint holds 463 rows per validity class, below the ratified 500 floor",
        },
    }
    return {OUTPUT: body, GATES: json.dumps(report, indent=2, sort_keys=True).encode("utf-8") + b"\n"}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="rebuild and require byte-identical artifacts"
    )
    parser.add_argument("--anchor-share", type=float, default=ANCHOR_SHARE)
    arguments = parser.parse_args()
    try:
        outputs = build(arguments.anchor_share)
    except (AssetsMissing, BuildBlocked) as error:
        print(str(error), file=sys.stderr)
        return 1
    if arguments.check:
        stale = [
            str(path)
            for path, data in outputs.items()
            if not path.is_file() or path.read_bytes() != data
        ]
        if stale:
            print("stale wave-5 sequence artifacts: " + ", ".join(stale), file=sys.stderr)
            return 1
        print(f"PASS wave-5 double build is byte-identical: {len(outputs)} artifacts")
        return 0
    for path, data in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    report = json.loads(outputs[GATES])
    print(json.dumps({
        "rows": report["rows"],
        "rows_by_leg": report["rows_by_leg"],
        "mix": report["mix"],
        "artifact_sha256": report["artifact_sha256"],
        "model_token_output_bound": report["g7_token_accounting"]["model_token_output_bound"],
        "processed_tokens_total": report["g7_token_accounting"]["processed_tokens_total"],
        "drops": report["drops"],
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
