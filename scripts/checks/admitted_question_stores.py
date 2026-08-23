#!/usr/bin/env python3
"""Check emitted question-admission stores, spans, counts, and warrants."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.bigred.questions_admission import judge  # noqa: E402
from scripts.counts_baseline_lib import baseline_value  # noqa: E402
from scripts.curriculum import structure_to_task_rows as anchoring  # noqa: E402
from scripts.research import extract_lesson_context as context  # noqa: E402


CANDIDATES = ROOT / "hermes/app/runtime/experiments/questions_admission/candidates.jsonl"
VERDICTS = ROOT / "curriculum/im/generated/questions_admission_verdicts.jsonl"

EXPECTED_STATUS = {
    "labels": Counter({"mechanically_admitted": 6822, "mechanically_held": 2305}),
    "guide": Counter({"mechanically_admitted": 2615, "mechanically_held": 1}),
}
EXPECTED_HELD = {
    "labels": Counter({
        # 2026-08-22 admission pass: malformed_text and duplicate_span are
        # extinct in this lane. IM's mixed quotation typography admits; a
        # span that cuts a quotation short holds span_truncates_quote; a
        # span recorded under two region types admits its re-derived winner
        # and holds the rest under region_conflict_rederived (the argument
        # names the winner; two rows sit in narrative text with no heading
        # to read and carry no argument).
        "not_interrogative": 2294,
        "span_truncates_quote": 1,
        "region_conflict_rederived(launch)": 6,
        "region_conflict_rederived(activity_synthesis)": 2,
        "region_conflict_rederived": 2,
    }),
    "guide": Counter({"malformed_text": 1}),
}
EXPECTED_VOID = {
    "labels": {"n": 279, "modal_share": 0.6559, "kappa": 0.0212},
    "guide": {"n": 47, "modal_share": 0.8298, "kappa": -0.0338},
}
EXPECTED_AUTHOR_HEADING = baseline_value("questions.im_author_heading")
EXPECTED_PRINTED_REGION = baseline_value("questions.printed_region")
EXPECTED_ADMITTED = baseline_value("questions.admitted")
EXPECTED_TOTAL = baseline_value("questions.total")


def load_jsonl(path: Path) -> list[dict]:
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def check_emitter() -> None:
    completed = subprocess.run(
        ["python3", "scripts/questions/emit_admitted_question_stores.py", "--check"],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    assert completed.returncode == 0, completed.stderr or completed.stdout


def check_counts(labels: list[dict], guide: list[dict]) -> None:
    lanes = {"labels": labels, "guide": guide}
    for lane, rows in lanes.items():
        status = Counter(row["status"] for row in rows)
        assert status == EXPECTED_STATUS[lane], (lane, status)
        held = Counter(
            row["held_reason"]
            for row in rows
            if row["status"] == "mechanically_held"
        )
        assert held == EXPECTED_HELD[lane], (lane, held)


def check_spans(labels: list[dict], guide: list[dict]) -> Counter:
    admitted_labels = [row for row in labels if row["status"] == "mechanically_admitted"]
    for row in admitted_labels:
        source = ROOT / row["source"]
        assert hashlib.sha256(source.read_bytes()).hexdigest() == row["source_sha256"]
        content = source.read_text(encoding="utf-8", errors="replace")
        assert anchoring.find_verbatim(content, row["text"]) == (
            row["char_start"], row["char_end"]
        )
        if row["warrant"] == "im_author_heading":
            assert row["label"] == "advancing"
            assert row["label_origin"] == "author_heading"
            assert row["origin_title"] == row["heading"] == "Advancing Student Thinking"
            assert row["region_identity"] == "none"
        else:
            assert row["warrant"] == "printed_region"
            assert row["label_origin"] == "machine_classification"
            assert row["label"] == row["region_identity"] == row["region_type"]

    admitted_guide = [row for row in guide if row["status"] == "mechanically_admitted"]
    skipped = 0
    for row in admitted_guide:
        source = ROOT / row["source"]
        if not source.is_file():
            skipped += 1
            continue
        assert hashlib.sha256(source.read_bytes()).hexdigest() == row["doc_sha256"]
        lines = source.read_text(encoding="utf-8").split("\n")
        cited = lines[row["line_start"] - 1 : row["line_end"]]
        assert context.cited_span_contains(row["text"], cited)
        assert row["warrant"] == "printed_region"
        assert row["label_origin"] == "machine_classification"
        assert row["label"] == row["region_identity"] == row["activity_location"]
    if skipped:
        print(
            "SKIP admitted guide span/sha re-derivation: "
            f"{skipped} local docling source(s) absent"
        )
    return Counter(row["warrant"] for row in admitted_labels + admitted_guide)


def check_void_history(candidates: list[dict], verdicts: list[dict]) -> None:
    candidate_by_id = {row["id"]: row for row in candidates}
    for lane in ("labels", "guide"):
        pairs: list[tuple[str, str]] = []
        answers: list[str] = []
        for verdict in verdicts:
            if verdict["lane"] != lane or verdict["verdict"] not in judge.LABELS_CHOICES:
                continue
            candidate = candidate_by_id.get(verdict["id"])
            if candidate is None:
                continue  # L17 sentinels are not admission candidates.
            stored = candidate["anchor"]["stored_label"]
            pairs.append((stored, verdict["verdict"]))
            answers.append(verdict["verdict"])
        modal_share, _answer = judge.modal_share(answers)
        kappa = judge.cohens_kappa(pairs)
        measured = {
            "n": len(pairs),
            "modal_share": round(modal_share, 4),
            "kappa": None if kappa is None else round(kappa, 4),
        }
        assert measured == EXPECTED_VOID[lane], (lane, measured)
        assert modal_share < judge.MODAL_SHARE_VOID_THRESHOLD
        assert kappa is None or kappa < judge.KAPPA_VOID_THRESHOLD


def main() -> int:
    check_emitter()
    labels, guide = context.admission_store_rows()
    check_counts(labels, guide)
    warrants = check_spans(labels, guide)
    if CANDIDATES.is_file():
        check_void_history(load_jsonl(CANDIDATES), load_jsonl(VERDICTS))
    else:
        # Same absence class as the guide-lane docling skip above: the
        # stage-0 candidates file is gitignored and local-only.
        print(
            "SKIP void-history re-derivation: "
            f"{CANDIDATES.relative_to(ROOT)} absent locally "
            "(gitignored stage-0 artifact)"
        )
    assert warrants == Counter({
        "printed_region": EXPECTED_PRINTED_REGION,
        "im_author_heading": EXPECTED_AUTHOR_HEADING,
    })
    assert sum(
        EXPECTED_STATUS[lane]["mechanically_admitted"] for lane in EXPECTED_STATUS
    ) == EXPECTED_ADMITTED
    assert sum(sum(counts.values()) for counts in EXPECTED_STATUS.values()) == EXPECTED_TOTAL
    assert all(
        not row["held_reason"].startswith("pass_void")
        for row in labels + guide
        if row["status"] == "mechanically_held"
    )
    print(
        f"PASS admitted question stores: {EXPECTED_ADMITTED} of {EXPECTED_TOTAL} rows admitted; "
        f"{EXPECTED_AUTHOR_HEADING} im_author_heading and "
        f"{EXPECTED_PRINTED_REGION} printed_region warrants; "
        "held rows are form holds"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
