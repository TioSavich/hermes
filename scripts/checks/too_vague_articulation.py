#!/usr/bin/env python3
"""Offline regression checks for the typed too-vague articulation harness."""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
HARNESS_PATH = ROOT / "scripts" / "research" / "too_vague_articulation.py"


def load_harness():
    spec = importlib.util.spec_from_file_location("task114_articulation", HARNESS_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {HARNESS_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


HARNESS = load_harness()
ROW_ID = 999
ROLES = ["fraction", "target_quantity", "activity_context"]
BUNDLE = HARNESS.Bundle(
    ROW_ID,
    "fraction",
    "a fraction of a number can be found only when supporting partitioning activity is present",
    "synthetic citation",
    "synthetic regression fixture",
    [],
    [],
    [],
    ROLES,
)
TYPED_INPUT = (
    "case([fraction(fraction(1,2)), target_quantity(8), "
    "activity_context(primary)])"
)
CONTRAST_INPUT = (
    "case([fraction(fraction(3,4)), target_quantity(12), "
    "activity_context(contrast)])"
)


def candidate(
    kind: str,
    typed_expected: str,
    contrast_expected: str,
    *,
    mode: str = "value",
    support: str = "educated_guess",
    roles: list[str] | None = None,
    rule: str | None = None,
    final_period: bool = True,
) -> str:
    declared = roles if roles is not None else ROLES
    rule = rule or f"""\
churn_candidate:articulation_{ROW_ID}(
    case([fraction(_Fraction), target_quantity(_Target), activity_context(Context)]),
    Result) :-
    ( Context == primary
    -> Result = {typed_expected}
    ;  Result = {contrast_expected}
    )"""
    period = "." if final_period else ""
    return f"""\
% SUPPORT: {support}
test_harness:articulation_candidate(
    db_row({ROW_ID}), fraction, articulation_{ROW_ID}, {kind},
    churn_candidate:articulation_{ROW_ID},
    [{", ".join(declared)}],
    probe({TYPED_INPUT}, {typed_expected}),
    probe({CONTRAST_INPUT}, {contrast_expected}),
    {mode}).
{rule}{period}
"""


def gate(draft: str):
    return HARNESS.gate_with_local_syntax_retry(BUNDLE, draft)[0]


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def check_candidate_kinds_and_probes() -> None:
    cases = {
        "transformation": ("transformed(first_value)", "transformed(contrast_value)"),
        "relational_judgment": ("judgment(equivalent)", "judgment(not_equivalent)"),
        "precondition": (
            "precondition(met)",
            "precondition(unmet(partitioning_activity))",
        ),
        "representation_constraint": (
            "representation_constraint(required(area_model))",
            "representation_constraint(forbidden(area_model))",
        ),
        "abstention": (
            "abstains(missing_partitioning_activity)",
            "proceeds(computed_fraction)",
        ),
    }
    for kind, (typed, contrast) in cases.items():
        result = gate(candidate(kind, typed, contrast))
        require(result.loads_and_terminates, f"{kind} did not load and terminate")
        require(
            result.reproduces_documented_behavior,
            f"{kind} did not pass both typed probes: {result.reason}",
        )
        require(result.candidate_kind == kind, f"{kind} was not retained")

    same_probe = candidate(
        "precondition", "precondition(met)", "precondition(met)"
    ).replace(CONTRAST_INPUT, TYPED_INPUT)
    result = gate(same_probe)
    require(
        not result.reproduces_documented_behavior
        and result.gate_stage == "contrast_probe",
        "identical typed and contrast probes were accepted",
    )


def check_explicit_abstention() -> None:
    failure_rule = f"""\
churn_candidate:articulation_{ROW_ID}(
    case([fraction(_Fraction), target_quantity(_Target), activity_context(_Context)]),
    _Result) :-
    fail"""
    result = gate(candidate(
        "abstention",
        "abstains(missing_partitioning_activity)",
        "proceeds(computed_fraction)",
        rule=failure_rule,
    ))
    require(
        result.loads_and_terminates
        and not result.reproduces_documented_behavior
        and "explicit typed result" in result.reason,
        "plain failure was not separated from an explicit abstains(Reason) result",
    )

    echo_rule = f"""\
churn_candidate:articulation_{ROW_ID}(Input, Input)"""
    result = gate(candidate(
        "abstention",
        "abstains(missing_partitioning_activity)",
        "proceeds(computed_fraction)",
        rule=echo_rule,
    ))
    require(
        not result.reproduces_documented_behavior,
        "an echoed abstention input was accepted",
    )


def check_source_roles() -> None:
    inferred = HARNESS.source_relevant_roles(BUNDLE.documented_error)
    require(
        inferred == ROLES,
        "fraction-of-a-number roles did not include fraction, target, and activity",
    )
    result = gate(candidate(
        "precondition",
        "precondition(met)",
        "precondition(unmet(partitioning_activity))",
        roles=["fraction", "activity_context"],
    ))
    require(
        not result.reproduces_documented_behavior and result.gate_stage == "roles",
        "a candidate missing target_quantity was accepted",
    )

    short_head = f"""\
churn_candidate:articulation_{ROW_ID}(
    case([fraction(_Fraction), target_quantity(_Target)]),
    precondition(met))"""
    result = gate(candidate(
        "precondition",
        "precondition(met)",
        "precondition(unmet(partitioning_activity))",
        rule=short_head,
    ))
    require(
        not result.reproduces_documented_behavior and result.gate_stage == "roles",
        "a rule head omitting activity_context was accepted",
    )


def check_arithmetic_results() -> None:
    result = gate(candidate(
        "transformation",
        "transformed(fraction(3-1,5+5))",
        "transformed(fraction(4-1,6+6))",
    ))
    require(
        not result.reproduces_documented_behavior
        and result.gate_stage == "result_evaluation",
        "unevaluated arithmetic inside value results was accepted",
    )

    result = gate(candidate(
        "transformation",
        "constructed_expression(3-1)",
        "constructed_expression(4+2)",
        mode="symbolic_expression",
    ))
    require(
        result.reproduces_documented_behavior,
        f"explicit symbolic-expression construction was rejected: {result.reason}",
    )


def check_support_labels() -> None:
    require(
        HARNESS.support_level("% SUPPORT: source_articulation\n") == "SOURCE-ARTICULATION",
        "known source-articulation label changed",
    )
    require(
        HARNESS.support_level("% SUPPORT: conjectural_new_class\n") == "UNLABELLED",
        "an unknown support label became a new support class",
    )
    require(
        HARNESS.support_level("no support marker") == "UNLABELLED",
        "a missing support label was not UNLABELLED",
    )


def check_split_gate_outcomes() -> None:
    mismatched_rule = f"""\
churn_candidate:articulation_{ROW_ID}(
    case([fraction(_Fraction), target_quantity(_Target), activity_context(_Context)]),
    transformed(other_value))"""
    result = gate(candidate(
        "transformation",
        "transformed(first_value)",
        "transformed(contrast_value)",
        rule=mismatched_rule,
    ))
    require(result.loads_and_terminates, "a terminating mismatch was marked non-terminating")
    require(
        not result.reproduces_documented_behavior
        and result.gate_stage == "typed_semantics",
        "documented behavior passed without matching both typed probes",
    )


def check_local_syntax_retry_only() -> None:
    syntax_draft = candidate(
        "transformation",
        "transformed(first_value)",
        "transformed(contrast_value)",
        final_period=False,
    )
    with mock.patch.object(HARNESS, "call_live", side_effect=AssertionError("API call")):
        with mock.patch.object(HARNESS, "typed_gate", wraps=HARNESS.typed_gate) as typed:
            result, repaired = HARNESS.gate_with_local_syntax_retry(BUNDLE, syntax_draft)
    require(result.syntax_repaired, "repairable syntax did not receive a local retry")
    require(result.reproduces_documented_behavior, f"syntax repair failed: {result.reason}")
    require(typed.call_count == 2, "syntax repair did not perform exactly one local retry")
    require(repaired.rstrip().endswith("."), "syntax repair changed no punctuation")

    semantic_draft = candidate(
        "transformation",
        "transformed(first_value)",
        "transformed(contrast_value)",
        rule=f"""\
churn_candidate:articulation_{ROW_ID}(
    case([fraction(_Fraction), target_quantity(_Target), activity_context(_Context)]),
    transformed(other_value))""",
    )
    with mock.patch.object(HARNESS, "call_live", side_effect=AssertionError("API call")):
        with mock.patch.object(HARNESS, "typed_gate", wraps=HARNESS.typed_gate) as typed:
            result, evaluated = HARNESS.gate_with_local_syntax_retry(BUNDLE, semantic_draft)
    require(not result.syntax_repaired, "a semantic guess was auto-repaired")
    require(typed.call_count == 1, "a semantic failure received a second gate attempt")
    require(evaluated == semantic_draft.strip(), "semantic candidate text was changed")


def main() -> int:
    checks = (
        check_candidate_kinds_and_probes,
        check_explicit_abstention,
        check_source_roles,
        check_arithmetic_results,
        check_support_labels,
        check_split_gate_outcomes,
        check_local_syntax_retry_only,
    )
    for check in checks:
        check()
        print(f"PASS {check.__name__}")
    print(f"PASS task-114 offline regression ({len(checks)} checks, no API calls)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
