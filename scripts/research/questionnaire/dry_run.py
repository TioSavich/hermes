#!/usr/bin/env python3
"""Exercise slice 3 with injected clients and zero live calls or sockets."""
from __future__ import annotations

import hashlib
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
    numeric_slots,
)
from runner import (  # noqa: E402
    ModelOutcome,
    Question,
    QuestionnaireRunner,
    ResponseKind,
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
        self.by_kind = {kind: schema for schema in compiled.contracts for kind in schema.kinds}
        self.leaf_calls: list[tuple[str, Any]] = []

    def call_tool(self, name: str, arguments: dict[str, Any]) -> Any:
        if name != "strategy_trace":
            raise AssertionError(f"unexpected fake Hermes tool: {name}")
        schema = self.by_kind[arguments["strategy"]]
        assert conforms(schema.template, arguments["input"])
        self.leaf_calls.append((schema.family, arguments["input"]))
        return {
            "ok": True,
            "family": schema.family,
            "strategy": arguments["strategy"],
            "input": arguments["input"],
        }

    def close(self) -> None:
        return None


def value_at(value: Any, path: tuple[str | int, ...]) -> Any:
    cursor = value
    for part in path:
        cursor = cursor[part]
    return cursor


class TargetModel:
    def __init__(self, compiled: CompiledChoiceSets, family: str, schema: ContractSchema) -> None:
        self.compiled = compiled
        self.family = family
        self.schema = schema
        self.values = {slot.key: value_at(schema.example, slot.path) for slot in numeric_slots(schema)}

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        del prompt
        if question.response_kind == ResponseKind.TRANSCRIPTION.value:
            assert request == {"temperature": 0, "num_predict": 24, "think": False, "stops": []}
            mode = question.context["binding_mode"]
            if mode == "prose_slot":
                slot = question.context["slot"]
                name = question.context["slot_name"]
                value = self.values.get(slot, 999999)
                return ModelOutcome(TransportStatus.OK, f"given({name}, {value}).", 1)
            if mode == "prose_got":
                return ModelOutcome(TransportStatus.OK, "given(got, 0).", 1)
            raise AssertionError(mode)

        assert request == {"temperature": 0, "num_predict": 8, "think": False, "stops": []}
        if question.level == "L1":
            desired = self.compiled.region_for_family(self.family)["id"]
        elif question.level == "L2":
            desired = self.family
        elif question.level == "L3-binary":
            desired = "yes" if question.context["schema_id"] == self.schema.schema_id else "no"
        else:
            raise AssertionError(question.level)
        choice = next(choice for choice in question.choices if choice.key == desired)
        return ModelOutcome(TransportStatus.OK, choice.letter, 1)


class ScriptedSymbolModel:
    def __init__(self, transcription: str, selected_schema_id: str | None = None) -> None:
        self.transcription = transcription
        self.selected_schema_id = selected_schema_id

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        del prompt
        if question.response_kind == ResponseKind.TRANSCRIPTION.value:
            assert request["num_predict"] == 24
            return ModelOutcome(TransportStatus.OK, self.transcription, 1)
        if question.level == "L3-binary":
            key = "yes" if question.context["schema_id"] == self.selected_schema_id else "no"
            choice = next(choice for choice in question.choices if choice.key == key)
            return ModelOutcome(TransportStatus.OK, choice.letter, 1)
        raise AssertionError(question.level)


class FirstChoiceModel:
    def __init__(self, abstain_level: str | None = None) -> None:
        self.abstain_level = abstain_level

    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        del prompt, request
        if question.response_kind == ResponseKind.TRANSCRIPTION.value:
            return ModelOutcome(TransportStatus.OK, "invalid", 1)
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


def navigation_pages(compiled: CompiledChoiceSets) -> list[ChoicePage]:
    pages = list(compiled.l1_pages())
    for region in compiled.regions:
        pages.extend(compiled.l2_pages(region["id"]))
    return pages


def assert_compiler(compiled: CompiledChoiceSets) -> str:
    assert len(compiled.family_order) == 15
    assert compiled.contract_row_count == 246
    assert {family: len(compiled.schemas_for_family(family)) for family in compiled.family_order} == EXPECTED_SCHEMA_COUNTS
    for page in navigation_pages(compiled):
        assert 2 <= len(page.choices) <= 8
        assert page.choices[-1].letter == ABSTENTION_LETTER
        assert sum(choice.letter == ABSTENTION_LETTER for choice in page.choices) == 1
    serialized = compiled.to_dict()
    assert all(
        row.get("selection") == "engine_side_contract_binding"
        and not any(key.startswith("l3_") for key in row)
        for row in serialized["families"].values()
    )
    first = compiled.to_bytes()
    second = compile_choice_sets().to_bytes()
    assert first == second
    return hashlib.sha256(first).hexdigest()


def assert_family_reachability(compiled: CompiledChoiceSets) -> tuple[Counter[str], list[str]]:
    route_census: Counter[str] = Counter()
    names: list[str] = []
    for family in compiled.family_order:
        schema = compiled.schemas_for_family(family)[0]
        symbolic = FakeHermes(compiled)
        result = QuestionnaireRunner(TargetModel(compiled, family, schema), symbolic, compiled).run(
            fixture_excerpt(schema)
        )
        assert result.status == "leaf_computed", (family, result.to_dict())
        assert result.family == family and result.schema_id == schema.schema_id
        assert symbolic.leaf_calls == [(family, schema.example)]
        assert any(event["kind"] == "schema_selected_by_binding" or event["kind"] == "schema_selected_by_binary" for event in result.ledger)
        assert not any(event.get("level") in {"L3", "L3-kind", "L3-schema"} and event["kind"] == "model_attempt" for event in result.ledger)
        route_census.update(event["kind"] for event in result.ledger)
        names.append(f"family_reachability/{family}")
    return route_census, names


def assert_operator_and_residual_routes(compiled: CompiledChoiceSets) -> list[str]:
    names: list[str] = []
    addition = compiled.schemas_for_family("addition")[0]
    result = QuestionnaireRunner(
        ScriptedSymbolModel("27 + 15 = 42"), FakeHermes(compiled), compiled,
    ).run("Student work: 27 + 15 = 42\nFinal answer: 42")
    assert result.status == "leaf_computed" and result.family == "addition"
    assert result.model_calls == 1
    assert any(event["kind"] == "l0_operator_bound" for event in result.ledger)
    assert not any(event.get("level") in {"L1", "L2"} for event in result.ledger)
    names.append("l0/operator_gate_skips_navigation")

    division = compiled.schemas_for_family("division")[0]
    result = QuestionnaireRunner(
        ScriptedSymbolModel("12 / 3 = 4", division.schema_id), FakeHermes(compiled), compiled,
    ).run("Student work: 12 / 3 = 4\nFinal answer: 4")
    assert result.status == "leaf_computed" and result.schema_id == division.schema_id
    assert sum(event.get("level") == "L3-binary" and event["kind"] == "model_attempt" for event in result.ledger) >= 2
    assert any(event["kind"] == "schema_selected_by_binary" for event in result.ledger)
    names.append("l3/contract_binding_then_residual_binary")

    # Both operator families are present, so L0 records ambiguity and navigation remains active.
    result = QuestionnaireRunner(
        TargetModel(compiled, "addition", addition), FakeHermes(compiled), compiled,
    ).run("Student work: 27 + 15 = 42; then 42 - 1 = 41\nFinal answer: 0")
    assert any(event["kind"] == "l0_operator_ambiguous" for event in result.ledger)
    assert any(event.get("level") == "L1" and event["kind"] == "model_attempt" for event in result.ledger)
    names.append("l0/ambiguous_operator_uses_navigation")
    return names


def assert_abstention_routes(compiled: CompiledChoiceSets) -> list[str]:
    names: list[str] = []
    addition = compiled.schemas_for_family("addition")[0]
    prose = fixture_excerpt(addition)

    result = QuestionnaireRunner(FirstChoiceModel("L1"), FakeHermes(compiled), compiled).run(prose)
    assert result.status == "not_covered" and result.ledger[-1]["reason"] == "l1_abstention"
    names.append("abstention/l1_terminal")

    result = QuestionnaireRunner(FirstChoiceModel("L2"), FakeHermes(compiled), compiled).run(prose)
    assert result.status == "not_covered"
    assert sum(event["kind"] == "l2_reopen_l1" for event in result.ledger) == 1
    names.append("abstention/l2_reopen_once_then_terminal")

    result = QuestionnaireRunner(
        ScriptedSymbolModel("27 + 15 = 999"), FakeHermes(compiled), compiled,
    ).run("Student work: 27 + 15 = 42\nFinal answer: 42")
    assert result.status == "extraction_incomplete" and result.model_calls == 2
    assert sum(event["kind"] == "binding_rejected" for event in result.ledger) == 2
    assert any(event["kind"] == "system_abstention" for event in result.ledger)
    names.append("abstention/nonverbatim_retry_then_system_abstention")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled,
            "addition",
            addition,
            "L4",
            [ModelOutcome(TransportStatus.OK, "given(a, 999999).", 1)] * 2,
        ),
        FakeHermes(compiled),
        compiled,
    ).run(prose)
    assert result.status == "extraction_incomplete"
    assert any(event["kind"] == "slot_unbound" for event in result.ledger)
    assert not any(event["kind"] == "leaf_call" for event in result.ledger)
    names.append("abstention/prose_slot_retry_then_partial")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled,
            "addition",
            addition,
            "L1",
            [ModelOutcome(TransportStatus.TRUNCATED, "A", 1), ModelOutcome(TransportStatus.EMPTY_CONTENT, "", 1)],
        ),
        FakeHermes(compiled),
        compiled,
    ).run(prose)
    assert result.status == "not_covered" and result.model_calls == 2
    names.append("abstention/transport_retry_exhausted")

    result = QuestionnaireRunner(
        LevelOverrideModel(
            compiled,
            "addition",
            addition,
            "L1",
            [ModelOutcome(TransportStatus.OK, "A because", 1), ModelOutcome(TransportStatus.OK, "B", 1)],
        ),
        FakeHermes(compiled),
        compiled,
    ).run(prose)
    assert result.status == "not_covered"
    assert any(event["kind"] == "conflict" for event in result.ledger)
    names.append("abstention/conflicting_navigation_retry")
    return names


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
        fixtures.extend(assert_operator_and_residual_routes(compiled))
        fixtures.extend(assert_abstention_routes(compiled))
        assert socket.socket is not real_socket

    assert socket_count == 0
    print("QUESTIONNAIRE SLICE 3 DRY-RUN: PASS")
    print(f"choice-set sha256 (two byte-identical compiles): {digest}")
    print(f"family reachability: {len(compiled.family_order)}/{len(compiled.family_order)}")
    print(f"contract rows: {compiled.contract_row_count}; distinct schemas: {len(compiled.contracts)}")
    print(f"navigation pages checked: {len(navigation_pages(compiled))}; maximum choices including X: {max(len(page.choices) for page in navigation_pages(compiled))}")
    print(
        "requests: navigation num_predict="
        f"{contract['request']['num_predict']}; binding num_predict={contract['binding_request']['num_predict']}; "
        f"think={str(contract['request']['think']).lower()}"
    )
    print("authored region partition (vetoable):")
    for region in compiled.regions:
        print(f"  {region['id']}: {', '.join(region['families'])}")
    print("authored family-to-domain map (vetoable):")
    for family in compiled.family_order:
        print(f"  {family}: {compiled.family_domains[family]}")
    print("route census: " + ", ".join(f"{key}={route_census[key]}" for key in sorted(route_census)))
    print("fixtures: " + ", ".join(fixtures))
    print("network sockets opened: 0; live symbolic calls: 0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
