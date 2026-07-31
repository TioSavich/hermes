#!/usr/bin/env python3
"""Isolated engine fixtures for the PUSU division schema reader."""

from __future__ import annotations

import argparse
import json
import runpy
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNNER = ROOT / "scripts/curriculum/pusu_pass.py"

FIXTURES = {
    "registry_schema_coverage": r"""
        findall(Schema,
                action_automata_registry:action_automaton_signature(
                    division, _, _, Schema),
                Schemas0),
        sort(Schemas0, Schemas),
        forall(member(Schema, Schemas),
               pusu_division_schema_translation(Schema, _)),
        pusu_division_schema_translation(
            long_division_quotient_and_remainder,
            untranslatable(truncated_decimal_numeral)),
        pusu_division_schema_translation(
            rejected_exact_quotient_match,
            untranslatable(rejected_value))
    """,
    "integer_and_remainder_value_agreement": r"""
        pusu_division_comparison_relation(
            divide_larger_by_smaller, productive_integer_quotient,
            96, 4, 24, quotient_remainder(24, 0),
            arithmetic_value_agreement)
    """,
    "mixed_fraction_value_agreement": r"""
        pusu_division_comparison_relation(
            raw_quotient_with_remainder,
            integer_quotient_and_remainder,
            1865, 4, quotient_remainder(466, 1),
            quot_plus_frac(466, 1, 4),
            arithmetic_value_agreement)
    """,
    "raw_quotient_structural_divmod_identity": r"""
        pusu_rule_value_layer_separator_capability(
            raw_quotient_with_remainder,
            cannot_separate(structural_divmod_identity)),
        pusu_operation_domain(division, Domain),
        test_harness:arith_misconception(
            _, Domain, raw_quotient_with_remainder, Rule, _, _),
        forall(
            member(Dividend-Divisor,
                   [2-3, 94-3, 1865-4, 4852-8, 1000000-7]),
            ( call(Rule, Dividend-Divisor, RuleOutput),
              RuleOutput =
                  quot_plus_frac(Quotient, Remainder, Divisor),
              Quotient is Dividend // Divisor,
              Remainder is Dividend mod Divisor,
              Remainder > 0,
              pusu_division_read_value(
                  quotient_plus_fraction, Dividend, Divisor,
                  RuleOutput, RuleValue),
              pusu_division_read_value(
                  quotient_with_implicit_remainder, Dividend, Divisor,
                  Quotient, ProductiveValue),
              pusu_arithmetic_value_equal(RuleValue, ProductiveValue)
            )),
        \+ call(Rule, 12-3, _)
    """,
    "untranslatable_schema_fallback": r"""
        pusu_division_comparison_relation(
            sum_dividend_and_divisor,
            long_division_quotient_and_remainder,
            1001, 7, long_division_result("143", 0),
            digit_sum_numeral(1008),
            untranslatable_term_fallback)
    """,
    "division_agreement_join_path": r"""
        pusu_lesson('IM-G4-U6-L15', Row),
        member(Contrast, Row.contrasts),
        Contrast.kind == "divide_larger_by_smaller",
        Contrast.task == "divide(96,4)",
        Contrast.status == "agrees_at_input",
        Contrast.value_relation == arithmetic_value_agreement,
        Contrast.contrast_relation == distinct_automata,
        Contrast.productive_kind == fair_share_equal_groups,
        Contrast.agreement_context ==
            "given_dividend_at_least_given_divisor",
        Contrast.separating_input == "divide(2,3)",
        Contrast.viability = [_]
    """,
    "mixed_fraction_agreement_region": r"""
        pusu_lesson('IM-G4-U6-L19', Row),
        Row.pusu == "cannot_separate_at_value_layer",
        member(Contrast, Row.contrasts),
        Contrast.kind == "raw_quotient_with_remainder",
        Contrast.status == "cannot_separate_at_value_layer",
        Contrast.value_relation == arithmetic_value_agreement,
        Contrast.contrast_relation == distinct_rule_and_automaton,
        Contrast.agreement_context == "nonzero_remainder",
        Contrast.separating_input == "",
        length(Contrast.battery_refusals, 10),
        Contrast.viability = [Viability],
        Witness = Viability.separation_witness,
        Witness.kind == cannot_separate_at_value_layer,
        Witness.reason == structural_divmod_identity
    """,
    "exact_division_agreement_region": r"""
        pusu_lesson('IM-G5-U8-L16', Row),
        member(Contrast, Row.contrasts),
        Contrast.kind == "adjust_dividend_for_division",
        Contrast.task == "divide(98,14)",
        Contrast.status == "agrees_at_input",
        Contrast.value_relation == arithmetic_value_agreement,
        Contrast.contrast_relation == distinct_rule_and_automaton,
        Contrast.agreement_context == "exact_division",
        Contrast.separating_input == "divide(2,3)",
        Contrast.viability = [_]
    """,
    "genuine_separation_control": r"""
        pusu_lesson('IM-G6-U5-L10', Row),
        member(Contrast, Row.contrasts),
        Contrast.kind == "stop_after_first_partial_quotient",
        Contrast.task == "divide(1032,43)",
        Contrast.status == "separates",
        Contrast.value_relation == untranslatable_term_fallback
    """,
    "undeclared_productive_kind_refuses_shape_guess": r"""
        pusu_lesson('IM-G4-U6-L15', Row),
        member(Contrast, Row.contrasts),
        Contrast.kind == "divide_larger_by_smaller",
        Contrast.task == "divide(108,9)",
        Contrast.status == "separates",
        Contrast.value_relation == untranslatable_term_fallback,
        Contrast.productive_kind == not_available,
        Contrast.contrast_relation == not_compared
    """,
}


def load_runner(path: Path) -> str:
    namespace = runpy.run_path(str(path))
    runner = namespace.get("PROLOG_RUNNER")
    if not isinstance(runner, str):
        raise RuntimeError(f"{path} does not define PROLOG_RUNNER")
    return runner


def run_fixture(runner: str, name: str, condition: str) -> dict:
    program = (
        runner
        + "\n:- (("
        + condition
        + ") -> writeln('SCHEMA_FIXTURE\\tpass')"
        + "; writeln('SCHEMA_FIXTURE\\tfail')), halt.\n"
    )
    proc = subprocess.run(
        ["swipl", "-q", "-l", str(ROOT / "paths.pl"), "-g", "consult(user),halt"],
        cwd=ROOT,
        input=program,
        text=True,
        capture_output=True,
        check=False,
        timeout=20 * 60,
    )
    results = [
        line.split("\t", 1)[1]
        for line in proc.stdout.splitlines()
        if line.startswith("SCHEMA_FIXTURE\t")
    ]
    actual = results[-1] if results else "runner_error"
    return {
        "fixture": name,
        "expected": "pass",
        "actual": actual,
        "exit": proc.returncode,
        "stderr": proc.stderr.strip() if actual == "runner_error" else "",
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--runner",
        type=Path,
        default=DEFAULT_RUNNER,
        help="pusu_pass.py implementation to exercise",
    )
    args = parser.parse_args()
    runner = load_runner(args.runner.resolve())
    rows = [
        run_fixture(runner, name, condition)
        for name, condition in FIXTURES.items()
    ]
    print(json.dumps({"runner": str(args.runner), "fixtures": rows}, indent=2))
    return 0 if all(row["actual"] == row["expected"] for row in rows) else 1


if __name__ == "__main__":
    raise SystemExit(main())
