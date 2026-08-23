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
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
CURRICULUM = ROOT / "scripts" / "curriculum"
FIXTURES = ROOT / "scripts" / "checks" / "fixtures"
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(CURRICULUM))

import compile_action_mappings as compiler  # noqa: E402
import equation_verification as eqv  # noqa: E402


FORMAL_CORE_CONTROLS = (
    FIXTURES / "equation_verification_formal_core_controls.json"
)


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


def _formal_core_claim(control: dict) -> str:
    """The literal or compact repeated-step claim carried by one control."""
    claim = control.get("claim")
    if isinstance(claim, str):
        return claim
    repeat = control.get("repeat_claim")
    if not isinstance(repeat, dict):
        raise SystemExit(
            f"formal-core control {control.get('id')!r} has no claim"
        )
    repetitions = repeat.get("left_repetitions")
    step = repeat.get("left_step")
    if (
        not isinstance(repetitions, int)
        or isinstance(repetitions, bool)
        or repetitions < 0
        or not isinstance(step, str)
    ):
        raise SystemExit(
            f"formal-core control {control.get('id')!r} has malformed repetition"
        )
    steps = ", ".join([step] * repetitions)
    return (
        "equation_sides("
        f"grounded_counting_bound({int(repeat['bound'])}), "
        f"side({int(repeat['left_start'])}, [{steps}]), "
        f"side({int(repeat['right_start'])}, []))"
    )


def formal_core_controls() -> list[tuple[str, str]]:
    """Run the precedence and resource controls through their standing paths."""
    fixture = json.loads(FORMAL_CORE_CONTROLS.read_text(encoding="utf-8"))
    if fixture.get("schema") != "equation_sides_formal_core_controls_v1":
        raise SystemExit(
            f"unexpected formal-core fixture schema: {fixture.get('schema')!r}"
        )

    outcomes: list[tuple[str, str]] = []
    compiler_claims = []
    for control in fixture.get("compiler_cases", []):
        claim, family, route = eqv._claim_term(control["lhs"], control["rhs"])
        expected = (
            control["expected_claim"],
            control["expected_family"],
            control["expected_route"],
        )
        if (claim, family, route) != expected:
            raise SystemExit(
                f"formal-core compiler control {control['id']} drifted: "
                f"{(claim, family, route)!r} != {expected!r}"
            )
        compiler_claims.append((control["id"], claim))
    compiler_results = {
        row["id"]: row
        for row in eqv._run_driver(ROOT, compiler_claims, [])
        if row.get("kind") == "claim"
    }
    for control in fixture.get("compiler_cases", []):
        result = compiler_results.get(control["id"])
        if result is None or result.get("verdict") != control["expected_verdict"]:
            raise SystemExit(
                f"formal-core compiler control {control['id']} returned "
                f"{result!r}"
            )
        outcomes.append(
            (
                control["id"],
                f"licensed {result['verdict']} via {result['checker']}",
            )
        )

    checker_refusals = fixture.get("checker_refusals", [])
    checker_licenses = fixture.get("checker_licenses", [])
    checker_controls = checker_refusals + checker_licenses
    driver = r"""
:- use_module(hermes(math_claim_checker), [ check_math_claim/2 ]).

main :-
    forall(control(Id, Claim), check_control(Id, Claim)),
    halt.

check_control(Id, Claim) :-
    (   catch(check_math_claim(Claim, Dict0), Error,
              ( message_to_string(Error, Message),
                Dict0 = _{status:"threw", reason:Message} ))
    ->  Dict = Dict0
    ;   Dict = _{status:"failed", reason:"check_math_claim/2 failed"}
    ),
    dict_string(Dict, status, Status),
    dict_string(Dict, reason, Reason),
    dict_string(Dict, verdict, Verdict),
    dict_string(Dict, checker, Checker),
    format("CONTROL\t~s\t~s\t~s\t~s\t~s~n",
           [Id, Status, Reason, Verdict, Checker]).

dict_string(Dict, Key, Value) :-
    (   get_dict(Key, Dict, Raw)
    ->  ( string(Raw) -> Value = Raw ; term_string(Raw, Value) )
    ;   Value = ""
    ).
"""
    for control in checker_controls:
        driver += (
            f"control({json.dumps(control['id'])}, "
            f"{_formal_core_claim(control)}).\n"
        )
    with tempfile.TemporaryDirectory(prefix="equation-sides-controls-") as workspace:
        driver_path = pathlib.Path(workspace) / "controls.pl"
        driver_path.write_text(driver, encoding="utf-8")
        result = subprocess.run(
            [
                "swipl", "-q", "-l", "paths.pl", "-s", str(driver_path),
                "-g", "main", "-t", "halt",
            ],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
    if result.returncode:
        raise SystemExit(
            "formal-core checker controls failed:\n"
            + (result.stderr or result.stdout).strip()[-4000:]
        )
    checker_results: dict[str, dict[str, str]] = {}
    for line in result.stdout.splitlines():
        if not line.startswith("CONTROL\t"):
            continue
        _, identifier, status, reason, verdict, checker = line.split("\t", 5)
        checker_results[identifier] = {
            "status": status,
            "reason": reason,
            "verdict": verdict,
            "checker": checker,
        }
    for control in checker_refusals:
        outcome = checker_results.get(control["id"])
        if outcome is None:
            raise SystemExit(
                f"formal-core checker control {control['id']} emitted no result"
            )
        if outcome["status"] != control["expected_status"]:
            raise SystemExit(
                f"formal-core checker control {control['id']} returned status "
                f"{outcome['status']!r}, expected "
                f"{control['expected_status']!r}: {outcome['reason']}"
            )
        if control["expected_reason_fragment"] not in outcome["reason"]:
            raise SystemExit(
                f"formal-core checker control {control['id']} returned the "
                f"wrong reason: {outcome['reason']!r}"
            )
        outcomes.append(
            (
                control["id"],
                f"refused {outcome['status']}: {outcome['reason']}",
            )
        )
    for control in checker_licenses:
        outcome = checker_results.get(control["id"])
        if outcome is None:
            raise SystemExit(
                f"formal-core checker control {control['id']} emitted no result"
            )
        actual = (
            outcome["status"],
            outcome["verdict"],
            outcome["checker"],
        )
        expected = (
            control["expected_status"],
            control["expected_verdict"],
            control["expected_checker"],
        )
        if actual != expected:
            raise SystemExit(
                f"formal-core checker control {control['id']} drifted: "
                f"{actual!r} != {expected!r}; reason={outcome['reason']!r}"
            )
        outcomes.append(
            (
                control["id"],
                f"licensed {outcome['verdict']} via {outcome['checker']}",
            )
        )
    return outcomes


DOCLING_GUIDES = compiler.MIDDLE_GUIDE_ROOT


def validate_tracked_ledger() -> tuple[int, int]:
    ledger = json.loads(compiler.EQUATION_VERIFICATIONS.read_text(encoding="utf-8"))
    if ledger.get("schema") != "lesson_equation_verifications_v1":
        raise SystemExit("tracked equation ledger has an unexpected schema")
    spans = ledger.get("spans")
    summary = ledger.get("summary")
    if not isinstance(spans, list) or not isinstance(summary, dict):
        raise SystemExit("tracked equation ledger has malformed spans or summary")
    accepted = [
        row
        for span in spans
        for row in span.get("rows", [])
        if row.get("accepted") is True
    ]
    if summary.get("routine_spans") != len(spans):
        raise SystemExit("tracked equation ledger routine-span denominator drifted")
    if summary.get("accepted_equations") != len(accepted):
        raise SystemExit("tracked equation ledger accepted-equation denominator drifted")
    for row in accepted:
        if not row.get("reason_trace") or not row.get("witness_source"):
            raise SystemExit("tracked accepted equation lacks a reason trace or witness source")
    return len(spans), len(accepted)


def main() -> int:
    if not DOCLING_GUIDES.is_dir():
        spans, accepted = validate_tracked_ledger()
        controls = formal_core_controls()
        if not controls:
            raise SystemExit("formal-core controls returned no receipts")
        print(
            "SKIP equation-verification guide witnesses: "
            "hermes/app/runtime/experiments/gemma4_tutor/docling/full-output/"
            "TeacherLessonGuides absent locally (docling full-output); "
            f"tracked ledger schema, {spans} spans, {accepted} accepted reason traces, "
            f"and {len(controls)} formal-core controls verified"
        )
        return 0
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
    for identifier, outcome in formal_core_controls():
        print(f"formal-core control {identifier}: {outcome}")
    for name, message in ledger_fixtures(docs, covered, attachments):
        print(f"manufactured control refused ({name}): {message}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
