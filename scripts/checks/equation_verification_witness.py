#!/usr/bin/env python3
"""Check the equation-verification lane and the controls its gates have to refuse.

Two kinds of control run here.  Ledger fixtures go through the compiler's own
validator and each doctors one field the ledger could otherwise assert on its
own authority.  Witness controls call the truth-value gate directly with real
guide text, because the gate's job is to separate a printed judgment from text
that merely sits where one would be, and only manufactured input can show it
doing that.
"""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
CURRICULUM = ROOT / "scripts" / "curriculum"
FIXTURES = ROOT / "scripts" / "checks" / "fixtures"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(CURRICULUM))

import compile_action_mappings as compiler  # noqa: E402
import equation_verification as eqv  # noqa: E402


def coverage():
    rules = json.loads(compiler.DEFAULT_RULES.read_text(encoding="utf-8"))
    docs = compiler.read_teacher_guides(ROOT)
    explicit = compiler.read_explicit_mappings(ROOT)
    mappings = compiler.compile_rule_mappings(docs, rules, explicit)
    mappings += compiler.compile_scope_batches(
        rules, explicit, compiler.read_scope_titles(ROOT)
    )
    mappings = sorted(set(mappings))
    covered = {mapping.code for mapping in mappings} | set(explicit)
    attachments = {code: set(rows) for code, rows in explicit.items()}
    for mapping in mappings:
        attachments.setdefault(mapping.code, set()).add(
            (mapping.operation, mapping.kind)
        )
    return docs, covered, attachments


def witness_controls(docs) -> list[tuple[str, str]]:
    """Exercise the truth-value gate on real guide text, both ways."""
    fixture = json.loads(
        (FIXTURES / "equation_verification_witness_controls.json").read_text(
            encoding="utf-8"
        )
    )
    spans = {
        (span.code, span.position): span
        for span in compiler.extract_student_task_spans(docs)
    }
    span = spans[(fixture["lesson"], fixture["position"])]
    outcomes = []
    for control in fixture["controls"]:
        refusal = compiler.equation_witness_refusal(
            ROOT,
            span,
            fixture["source"],
            control["line"],
            control["excerpt"],
            control["judgment"],
        )
        expected = control["expected"]
        if expected is None:
            if refusal is not None:
                raise SystemExit(
                    f"witness control {control['id']} refused a real printed "
                    f"judgment: {refusal}"
                )
            outcomes.append((control["id"], "licensed"))
            continue
        if refusal != expected:
            raise SystemExit(
                f"witness control {control['id']} refused at the wrong gate: "
                f"{refusal!r} != {expected!r}"
            )
        outcomes.append((control["id"], refusal))
    return outcomes


def ledger_fixtures(docs, covered, attachments) -> list[tuple[str, str]]:
    refusals = []
    for path in sorted(FIXTURES.glob("equation_verification_*.json")):
        fixture = json.loads(path.read_text(encoding="utf-8"))
        if "expected_error" not in fixture:
            continue
        try:
            compiler.validate_equation_verifications(
                ROOT, docs, covered, attachments, path
            )
        except SystemExit as error:
            message = str(error)
            if fixture["expected_error"] not in message:
                raise SystemExit(
                    f"{path.name} failed at the wrong gate: {message}"
                ) from None
            refusals.append((path.name, message))
        else:
            raise SystemExit(f"{path.name} unexpectedly passed")
    return refusals


def main() -> int:
    docs, covered, attachments = coverage()
    rows = compiler.validate_equation_verifications(ROOT, docs, covered, attachments)
    ledger = json.loads(
        compiler.EQUATION_VERIFICATIONS.read_text(encoding="utf-8")
    )
    summary = ledger["summary"]
    lessons = {row["lesson"] for row in rows}
    grounded = sum(1 for row in rows if row["checker"].startswith("grounded_"))
    contexts = {}
    for row in rows:
        for entry in row["viability"]:
            contexts[entry.get("context", "unstated")] = contexts.get(
                entry.get("context", "unstated"), 0
            ) + 1
    for row in rows:
        if not row["reason_trace"]:
            raise SystemExit(
                f"equation verification {row['lesson']}/{row['position']} "
                "carries no reason trace"
            )
        if row["witness_class"] != eqv.WITNESS_CLASS:
            raise SystemExit(
                f"equation verification {row['lesson']}/{row['position']} "
                "lost its witness class"
            )
    print(
        f"equation verifications current: tasks={len(rows)} lessons={len(lessons)} "
        f"grounded_checker={grounded} "
        f"arithmetic_equality_checker={len(rows) - grounded}"
    )
    print(
        "ledger: "
        + " ".join(f"{key}={value}" for key, value in sorted(summary.items()))
    )
    print(
        "viability contexts over accepted tasks: "
        + " ".join(f"{key}={value}" for key, value in sorted(contexts.items()))
    )
    for identifier, outcome in witness_controls(docs):
        print(f"witness control {identifier}: {outcome}")
    for name, message in ledger_fixtures(docs, covered, attachments):
        print(f"manufactured control refused ({name}): {message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
