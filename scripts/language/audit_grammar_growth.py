#!/usr/bin/env python3
"""Re-run and disposition the consultation loop's 22 reparse failures."""

from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from probe_task_statements import REPO, reader_receipts


RUN_ID = "20260814T052134Z-c16d1624e7"
AUDIT = REPO / "hermes/app/runtime/experiments/language/consultation_audit.jsonl"
OUTPUT = REPO / "hermes/app/runtime/experiments/language/grammar_growth_dispositions.json"
ALLOWED_FACT_FUNCTORS = {
    "quantity",
    "conversion",
    "relation",
    "asks",
    "discrete_kinds",
}

# These reasons are referee dispositions over the frozen specimens. They do
# not drive the parser and cannot turn a refusal into an admission.
REFUSAL_REASONS = {
    "c-a394f877167db1eff28f": "instructional_future_not_asserted_quantity",
    "c-8275a1c012cb2e6637ff": "lesson_purpose_narration_not_task_facts",
    "c-998ec37d62a61e9d22fd": "lesson_purpose_narration_not_task_facts",
    "c-b7bc5c3c632b94834800": "lesson_purpose_narration_not_task_facts",
    "c-5e68ae2ba224cf43aff5": "comparison_question_without_quantity_referents",
    "c-c1703a51da423b271cea": "comparison_question_without_quantity_referents",
    "c-15283f47817abfca70e5": "comparison_question_without_quantity_referents",
    "c-f6b4cd5da87153351bff": "comparison_question_without_quantity_referents",
    "c-d8c93de13001bcc1618d": "comparison_question_without_quantity_referents",
    "c-2df5d8de1ba27328a83d": "procedure_limit_not_observed_quantity",
    "c-33d0dcadf8b3483bf8d8": "modified_equal_group_shape_thinly_attested",
    "c-17c4d88288c161969d38": "instruction_to_remove_not_asserted_state_change",
    "c-a9c07964b59ea497f2f3": "lesson_purpose_narration_not_task_facts",
    "c-f373c6428fbe532c45f5": "instruction_to_remove_not_asserted_state_change",
    "c-9f89dd22d898210edac9": "quoted_intention_not_referent_quantity_problem",
    "c-880301a406907176bf2c": "malformed_layout_fragment",
    "c-591926d1b765dd12aad0": "nested_hand_of_cards_shape_thinly_attested",
    "c-cbe1592d0df7277092d5": "gameplay_stop_condition_not_quantity_assertion",
    "c-25e5bab05bd6c3f1560e": "malformed_spliced_fragment",
    "c-4368aece6961c45451c0": "procedural_compound_change_without_named_referent",
    "c-d9ca2e8fb19bed037cdf": "nested_multi_factor_group_shape_not_single_conversion",
    "c-1cabef39e622e665d0a6": "malformed_sample_response_fragment",
}


def run_rows() -> list[dict[str, object]]:
    rows = [json.loads(line) for line in AUDIT.read_text(encoding="utf-8").splitlines()]
    specimens = [
        row
        for row in rows
        if row.get("rejection_reason") == "deterministic_reparse_failed"
        and (row.get("run_id") or row.get("residue", {}).get("run_id")) == RUN_ID
    ]
    if len(specimens) != 22:
        raise ValueError(f"expected 22 reparse failures for {RUN_ID}, found {len(specimens)}")
    ids = {str(row["audit_id"]) for row in specimens}
    if ids != set(REFUSAL_REASONS):
        raise ValueError("frozen specimen IDs do not match the referee disposition map")

    verdicts = reader_receipts([str(row["sentence"]) for row in specimens])
    output: list[dict[str, object]] = []
    for ordinal, (row, verdict) in enumerate(zip(specimens, verdicts), start=1):
        facts = [str(fact) for fact in verdict["facts"]]
        for fact in facts:
            functor = fact.split("(", 1)[0]
            if functor not in ALLOWED_FACT_FUNCTORS:
                raise ValueError(f"out-of-contract fact in {row['audit_id']}: {fact}")
        parsed = bool(verdict["parsed"])
        output.append(
            {
                "ordinal": ordinal,
                "audit_id": row["audit_id"],
                "sentence": row["sentence"],
                "source": row.get("source") or row.get("residue", {}).get("source"),
                "disposition": "parses_now" if parsed else "still_refuses",
                "facts": facts,
                "reason": None if parsed else REFUSAL_REASONS[str(row["audit_id"])],
            }
        )
    return output


def main() -> int:
    rows = run_rows()
    dispositions = Counter(str(row["disposition"]) for row in rows)
    reasons = Counter(str(row["reason"]) for row in rows if row["reason"])
    receipt = {
        "role": "frozen_consultation_reparse_failure_disposition",
        "run_id": RUN_ID,
        "source": str(AUDIT.relative_to(REPO)),
        "totals": dict(sorted(dispositions.items())),
        "refusal_reasons": dict(sorted(reasons.items())),
        "allowed_fact_functors": sorted(ALLOWED_FACT_FUNCTORS),
        "specimens": rows,
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(receipt["totals"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
