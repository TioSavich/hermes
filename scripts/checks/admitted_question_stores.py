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
from scripts.curriculum import structure_to_task_rows as anchoring  # noqa: E402
from scripts.research import extract_lesson_context as context  # noqa: E402


CANDIDATES = ROOT / "hermes/app/runtime/experiments/questions_admission/candidates.jsonl"
VERDICTS = ROOT / "curriculum/im/generated/questions_admission_verdicts.jsonl"

EXPECTED_STATUS = {
    "labels": Counter({"mechanically_admitted": 6479, "mechanically_held": 2648}),
    "guide": Counter({"mechanically_admitted": 2615, "mechanically_held": 1}),
}
EXPECTED_HELD = {
    "labels": Counter({
        "duplicate_span": 18,
        "malformed_text": 69,
        "not_interrogative": 2561,
    }),
    "guide": Counter({"malformed_text": 1}),
}
EXPECTED_VOID = {
    "labels": {"n": 279, "modal_share": 0.6559, "kappa": 0.0212},
    "guide": {"n": 47, "modal_share": 0.8298, "kappa": -0.0338},
}


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
    check_void_history(load_jsonl(CANDIDATES), load_jsonl(VERDICTS))
    assert warrants == Counter({"printed_region": 8081, "im_author_heading": 1013})
    assert sum(EXPECTED_STATUS[lane]["mechanically_admitted"] for lane in EXPECTED_STATUS) == 9094
    assert sum(sum(counts.values()) for counts in EXPECTED_STATUS.values()) == 11743
    assert all(
        not row["held_reason"].startswith("pass_void")
        for row in labels + guide
        if row["status"] == "mechanically_held"
    )
    print(
        "PASS admitted question stores: 9094 of 11743 rows admitted; "
        "1013 im_author_heading and 8081 printed_region warrants; "
        "held rows are form holds"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
