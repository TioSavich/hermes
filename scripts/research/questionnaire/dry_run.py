#!/usr/bin/env python3
"""Exercise the questionnaire slice without a model or network socket."""
from __future__ import annotations

import json
import socket
import sys
from collections import Counter
from pathlib import Path
from typing import Any
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from build_choice_sets import (  # noqa: E402
    ABSTENTION_LETTER,
    ChoicePage,
    CompiledChoiceSets,
    ContractSchema,
    compile_choice_sets,
    conforms,
)
from runner import (  # noqa: E402
    ModelOutcome,
    Question,
    QuestionnaireRunner,
    StdioHermesClient,
    TransportStatus,
    load_call_contract,
)


EXPECTED_SCHEMA_COUNTS = {
    "addition": 1,
    "subtraction": 1,
    "multiplication": 1,
    "probability": 1,
    "division": 3,
    "measurement": 3,
    "calculus": 3,
    "counting": 4,
    "decimal": 5,
    "ratio": 5,
    "integer": 6,
    "fraction": 7,
    "statistics": 9,
    "algebraic": 13,
    "geometry": 31,
}


class FakeHermes:
    def __init__(self, compiled: CompiledChoiceSets) -> None:
        self.by_kind = {
            kind: schema
            for schema in compiled.contracts
            for kind in schema.kinds
        }
        self.leaf_calls: list[tuple[str, Any]] = []

    def call_tool(self, name: str, arguments: dict[str, Any]) -> Any:
        if name == "strategy_recognize":
            return []
        if name == "strategy_trace":
            schema = self.by_kind[arguments["strategy"]]
            assert conforms(schema.template, arguments["input"])
            assert arguments["input"] == schema.example
            self.leaf_calls.append((schema.family, arguments["input"]))
            return {
                "ok": True,
                "family": schema.family,
                "strategy": arguments["strategy"],
                "input": arguments["input"],
            }
        raise AssertionError(f"unexpected fake Hermes tool: {name}")

    def close(self) -> None:
        return None


class TargetModel:
    def __init__(self, compiled: CompiledChoiceSets, family: str, schema: ContractSchema) -> None:
        self.compiled = compiled
        self.family = family
        self.schema = schema

    def desired(self, question: Question) -> Any:
        if question.level == "L1":
            return self.compiled.region_for_family(self.family)["id"]
        if question.level == "L2":
            return self.family
        if question.level == "L3":
            return self.schema.schema_id
        if question.level == "L3-kind":
            return self.schema.discriminator
        if question.level == "L3-schema":
            return self.schema.schema_id
        if question.level == "L4":
            return question.context["example_value"]
        if question.level == "L5":
            return "0"
        raise AssertionError(question.level)

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        assert request == {"temperature": 0, "num_predict": 8, "think": False, "stops": []}
        assert "Answer with exactly one letter." in prompt
        desired = self.desired(question)
        for choice in question.choices:
            value = choice.value
            if question.level in {"L4", "L5"} and isinstance(value, dict):
                value = value["value"] if question.level == "L4" else value["text"]
            if value == desired:
                return ModelOutcome(TransportStatus.OK, choice.letter, 1)
        return ModelOutcome(TransportStatus.OK, ABSTENTION_LETTER, 1)


class FirstChoiceModel:
    def __init__(self, abstain_level: str | None = None) -> None:
        self.abstain_level = abstain_level

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        letter = ABSTENTION_LETTER if question.level == self.abstain_level else question.choices[0].letter
        return ModelOutcome(TransportStatus.OK, letter, 1)


class LevelOverrideModel(TargetModel):
    def __init__(
        self,
        compiled: CompiledChoiceSets,
        family: str,
        schema: ContractSchema,
        level: str,
        outcomes: list[ModelOutcome],
    ) -> None:
        super().__init__(compiled, family, schema)
        self.level = level
        self.outcomes = list(outcomes)

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        if question.level == self.level and self.outcomes:
            return self.outcomes.pop(0)
        return super().complete(question, prompt, request)


def fixture_excerpt(schema: ContractSchema, final: str = "0") -> str:
    return "Student work: " + json.dumps(schema.example, sort_keys=True) + f"\nFinal answer: {final}"


def all_pages(compiled: CompiledChoiceSets) -> list[ChoicePage]:
    pages = list(compiled.l1_pages())
    for region in compiled.regions:
        pages.extend(compiled.l2_pages(region["id"]))
    for family in compiled.family_order:
        schemas = compiled.schemas_for_family(family)
        if len(schemas) <= 7:
            pages.extend(compiled.l3_pages(family))
        else:
            pages.extend(compiled.l3_discriminator_pages(family))
            for discriminator in sorted({schema.discriminator for schema in schemas}):
                pages.extend(compiled.l3_schema_pages(family, discriminator))
    return pages


def assert_compiler(compiled: CompiledChoiceSets) -> str:
    assert len(compiled.family_order) == 15
    assert compiled.contract_row_count == 246
    assert {
        family: len(compiled.schemas_for_family(family))
        for family in compiled.family_order
    } == EXPECTED_SCHEMA_COUNTS
    for page in all_pages(compiled):
        assert 2 <= len(page.choices) <= 8
        assert page.choices[-1].letter == ABSTENTION_LETTER
        assert sum(choice.letter == ABSTENTION_LETTER for choice in page.choices) == 1
    first = compiled.to_bytes()
    second = compile_choice_sets().to_bytes()
    assert first == second
    import hashlib
    return hashlib.sha256(first).hexdigest()


def assert_family_reachability(compiled: CompiledChoiceSets) -> tuple[Counter[str], list[str]]:
    route_census: Counter[str] = Counter()
    fixture_names: list[str] = []
    for family in compiled.family_order:
        schema = compiled.schemas_for_family(family)[0]
        symbolic = FakeHermes(compiled)
        runner = QuestionnaireRunner(TargetModel(compiled, family, schema), symbolic, compiled)
        result = runner.run(fixture_excerpt(schema))
        fixture_names.append(f"family_reachability/{family}")
        assert result.status == "leaf_computed", (family, result.to_dict())
        assert result.family == family
        assert result.schema_id == schema.schema_id
        assert symbolic.leaf_calls == [(family, schema.example)]
        assert any(event["kind"] == "leaf_call" for event in result.ledger)
        route_census.update(event["kind"] for event in result.ledger)

    addition_schema = compiled.schemas_for_family("addition")[0]
    addition_result = QuestionnaireRunner(
        TargetModel(compiled, "addition", addition_schema), FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition_schema))
    assert any(event["kind"] == "auto_bind" and event["level"] == "L3" for event in addition_result.ledger)
    return route_census, fixture_names


def assert_abstention_routes(compiled: CompiledChoiceSets) -> list[str]:
    names: list[str] = []
    addition = compiled.schemas_for_family("addition")[0]
    fraction = compiled.schemas_for_family("fraction")[0]

    result = QuestionnaireRunner(
        FirstChoiceModel("L1"), FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition))
    assert result.status == "not_covered" and result.ledger[-1]["reason"] == "l1_abstention"
    names.append("abstention/l1_terminal")

    result = QuestionnaireRunner(
        FirstChoiceModel("L2"), FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition))
    assert result.status == "not_covered"
    assert sum(event["kind"] == "l2_reopen_l1" for event in result.ledger) == 1
    names.append("abstention/l2_reopen_once_then_terminal")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled, "fraction", fraction, "L3",
            [ModelOutcome(TransportStatus.OK, "X", 1)],
        ),
        FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(fraction))
    assert result.status == "not_covered"
    assert any(event["kind"] == "l3_free_route_abstention" for event in result.ledger)
    names.append("abstention/l3_free_route_then_terminal")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled, "addition", addition, "L4",
            [ModelOutcome(TransportStatus.OK, "X", 1)] * 20,
        ),
        FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition))
    assert result.status == "extraction_incomplete"
    assert any(event["kind"] == "slot_unbound" for event in result.ledger)
    assert not any(event["kind"] == "leaf_call" for event in result.ledger)
    names.append("abstention/l4_partial_binding")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled, "addition", addition, "L5",
            [ModelOutcome(TransportStatus.OK, "X", 1)] * 2,
        ),
        FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition, "0 or 1"))
    assert result.status == "extraction_incomplete" and result.got is None
    names.append("abstention/l5_partial_binding")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled, "addition", addition, "L1",
            [ModelOutcome(TransportStatus.TRUNCATED, "A", 1),
             ModelOutcome(TransportStatus.EMPTY_CONTENT, "", 1)],
        ),
        FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition))
    assert result.status == "not_covered" and result.model_calls == 2
    names.append("abstention/transport_retry_exhausted")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled, "addition", addition, "L1",
            [ModelOutcome(TransportStatus.OK, "Q", 1),
             ModelOutcome(TransportStatus.OK, "not a letter", 1)],
        ),
        FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition))
    assert result.status == "not_covered" and result.model_calls == 2
    names.append("abstention/invalid_letter_retry_exhausted")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled, "addition", addition, "L1",
            [ModelOutcome(TransportStatus.OK, "A because", 1),
             ModelOutcome(TransportStatus.OK, "B", 1)],
        ),
        FakeHermes(compiled), compiled,
    ).run(fixture_excerpt(addition))
    assert result.status == "not_covered"
    assert any(event["kind"] == "conflict" for event in result.ledger)
    names.append("abstention/conflicting_retry")
    return names


def assert_worker_abduction() -> None:
    client = StdioHermesClient()
    try:
        arguments = {
            "domain": "fraction",
            "input": "frac(1,9)-frac(1,9)",
            "got": "frac(1,18)",
        }
        exemplar_bound = client.call_tool("diagnose_error", arguments)
        abductive = client.call_tool("abduce_error", arguments)
        assert exemplar_bound == []
        assert isinstance(abductive, list) and abductive
        assert all(candidate.get("citations") for candidate in abductive)
        assert all(
            citation.get("source", "").startswith("db_row(")
            for candidate in abductive
            for citation in candidate["citations"]
        )
    finally:
        client.close()


def main() -> int:
    real_socket = socket.socket
    socket_count = 0

    def forbidden_socket(*args: Any, **kwargs: Any) -> Any:
        nonlocal socket_count
        socket_count += 1
        raise AssertionError("questionnaire dry-run attempted to open a network socket")

    with patch("socket.socket", forbidden_socket):
        contract = load_call_contract()
        compiled = compile_choice_sets()
        digest = assert_compiler(compiled)
        route_census, fixtures = assert_family_reachability(compiled)
        fixtures.extend(assert_abstention_routes(compiled))
        assert socket.socket is not real_socket

    assert socket_count == 0
    assert_worker_abduction()

    print("QUESTIONNAIRE SLICE 1 DRY-RUN: PASS")
    print(f"choice-set sha256 (two byte-identical compiles): {digest}")
    print(f"family reachability: {len(compiled.family_order)}/{len(compiled.family_order)}")
    print(f"contract rows: {compiled.contract_row_count}; distinct schemas: {len(compiled.contracts)}")
    print(f"choice pages checked: {len(all_pages(compiled))}; maximum choices including X: {max(len(page.choices) for page in all_pages(compiled))}")
    print(f"one-letter request: num_predict={contract['request']['num_predict']}, think={str(contract['request']['think']).lower()}, request_stops={contract['request']['stops']}, reply_stops={contract['reply_stops']}")
    print("authored region partition (vetoable):")
    for region in compiled.regions:
        print(f"  {region['id']}: {', '.join(region['families'])}")
    print("authored family-to-domain map (vetoable):")
    for family in compiled.family_order:
        print(f"  {family}: {compiled.family_domains[family]}")
    print("route census: " + ", ".join(f"{key}={route_census[key]}" for key in sorted(route_census)))
    print("fixtures: " + ", ".join(fixtures))
    print("network sockets opened: 0")
    print("worker/MCP probe: diagnose_error=[]; abduce_error=nonempty with db_row citations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
