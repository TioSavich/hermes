#!/usr/bin/env python3
"""Run one questionnaire item with an injected model and symbolic client.

Navigation uses bounded letter questions. Binding uses constrained verbatim
transcription; the runner validates and locates the text before it can enter a
contract. Import and construction make no model or network call.
"""
from __future__ import annotations

import copy
import hashlib
import json
import re
import sys
from dataclasses import asdict, dataclass, field
from enum import Enum
from fractions import Fraction
from pathlib import Path
from typing import Any, Callable, Protocol


ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))

from build_choice_sets import (  # noqa: E402
    ABSTENTION_LETTER,
    Choice,
    ChoicePage,
    CompiledChoiceSets,
    ContractSchema,
    NumericSlot,
    compile_choice_sets,
    conforms,
    numeric_slots,
    plain_label,
    replace_path,
)
from scripts.research.gemma_hermes_protocol import MCPClient  # noqa: E402


CALL_CONTRACT_PATH = HERE / "call_contract.json"
NUMERAL_PATTERN = (
    r"[-+]?(?:\d+\s+\d+/\d+|\d+/\d+|\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)"
)
NUMERAL_RE = re.compile(rf"(?<![\w.]){NUMERAL_PATTERN}(?![\w.])")
SIMPLE_FRACTION_RE = re.compile(r"^([+-]?\d+)/(\d+)$")
EQUATION_RE = re.compile(
    rf"(?P<a>{NUMERAL_PATTERN})\s*"
    r"(?P<operator>\+|-|×|÷|/|times)\s*"
    rf"(?P<b>{NUMERAL_PATTERN})\s*=\s*(?P<got>{NUMERAL_PATTERN})",
    re.IGNORECASE,
)
GIVEN_RE = re.compile(
    rf"^given\((?P<name>[a-z][a-z0-9_]*),\s*(?P<value>{NUMERAL_PATTERN})\)\.$"
)
OPERATOR_FAMILIES = {
    "+": "addition",
    "-": "subtraction",
    "×": "multiplication",
    "times": "multiplication",
    "÷": "division",
    "/": "division",
}


class TransportStatus(str, Enum):
    OK = "ok"
    TRUNCATED = "truncated"
    EMPTY_CONTENT = "empty_content"
    INVALID_CONTENT = "invalid_content"
    ERROR = "error"


class ResponseKind(str, Enum):
    LETTER = "letter"
    TRANSCRIPTION = "transcription"


@dataclass(frozen=True)
class ModelOutcome:
    status: TransportStatus
    content: str = ""
    eval_count: int = 0
    detail: str = ""
    latency_ms: float | None = None
    raw_exact_one_letter: bool | None = None
    reply_stops_honored: bool | None = None
    request_contract_exact: bool | None = None
    parse_ok: bool | None = None


@dataclass(frozen=True)
class NumeralSpan:
    text: str
    start: int
    end: int
    line: int
    value: int | float | str
    role: str = "numeral"


@dataclass(frozen=True)
class Question:
    level: str
    text: str
    excerpt: str
    page_index: int
    page_count: int
    choices: tuple[Choice, ...] = ()
    context: dict[str, Any] = field(default_factory=dict)
    response_kind: str = ResponseKind.LETTER.value


@dataclass(frozen=True)
class BoundValue:
    text: str
    value: int | float | str
    spans: tuple[NumeralSpan, ...]


@dataclass(frozen=True)
class SchemaBinding:
    schema: ContractSchema
    operand: Any


@dataclass
class ItemResult:
    status: str
    excerpt_sha256: str
    family: str | None = None
    schema_id: str | None = None
    operand: Any = None
    got: str | None = None
    leaf: Any = None
    ledger: list[dict[str, Any]] = field(default_factory=list)
    model_calls: int = 0
    eval_count: int = 0

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class ModelClient(Protocol):
    def complete(self, question: Question, prompt: str, request: dict[str, Any]) -> ModelOutcome:
        """Return one transport-typed outcome; no response text is trusted yet."""


class SymbolicClient(Protocol):
    def call_tool(self, name: str, arguments: dict[str, Any]) -> Any:
        """Call one local symbolic tool."""

    def close(self) -> None:
        """Release local resources."""


class StdioHermesClient:
    """Thin JSON adapter around the established stdio MCP client."""

    def __init__(self) -> None:
        self._client = MCPClient()

    def call_tool(self, name: str, arguments: dict[str, Any]) -> Any:
        text = self._client.call_tool(name, arguments)
        return json.loads(text) if text else None

    def close(self) -> None:
        self._client.close()


def load_call_contract() -> dict[str, Any]:
    contract = json.loads(CALL_CONTRACT_PATH.read_text(encoding="utf-8"))
    navigation = {"temperature": 0, "num_predict": 8, "think": False, "stops": []}
    binding = {"temperature": 0, "num_predict": 24, "think": False, "stops": []}
    if contract.get("request") != navigation:
        raise ValueError("call contract drifted from the designed navigation request")
    if contract.get("binding_request") != binding:
        raise ValueError("call contract drifted from the designed binding request")
    if contract["output"]["abstention_letter"] != ABSTENTION_LETTER:
        raise ValueError("call contract abstention letter does not match the compiler")
    return contract


def request_for_question(contract: dict[str, Any], question: Question) -> dict[str, Any]:
    key = "binding_request" if question.response_kind == ResponseKind.TRANSCRIPTION.value else "request"
    return dict(contract[key])


def _parse_numeric(text: str) -> int | float | str:
    compact = text.replace(",", "").strip()
    if SIMPLE_FRACTION_RE.fullmatch(compact) or " " in compact:
        return compact
    if "." in compact:
        return float(compact)
    return int(compact)


def harvest_numerals(excerpt: str) -> tuple[NumeralSpan, ...]:
    """Harvest maximal numeral spans and fraction components with source spans."""
    line_starts = [0]
    for match in re.finditer(r"\n", excerpt):
        line_starts.append(match.end())

    def line_number(offset: int) -> int:
        low = 0
        for index, start in enumerate(line_starts):
            if start > offset:
                break
            low = index
        return low + 1

    spans: list[NumeralSpan] = []
    for match in NUMERAL_RE.finditer(excerpt):
        text = match.group(0)
        spans.append(NumeralSpan(
            text=text,
            start=match.start(),
            end=match.end(),
            line=line_number(match.start()),
            value=_parse_numeric(text),
        ))
        fraction = SIMPLE_FRACTION_RE.fullmatch(text)
        if fraction:
            numerator_text, denominator_text = fraction.groups()
            numerator_start = match.start()
            denominator_start = match.end() - len(denominator_text)
            spans.extend((
                NumeralSpan(
                    numerator_text, numerator_start, numerator_start + len(numerator_text),
                    line_number(numerator_start), int(numerator_text), "fraction_component",
                ),
                NumeralSpan(
                    denominator_text, denominator_start, match.end(),
                    line_number(denominator_start), int(denominator_text), "fraction_component",
                ),
            ))
    return tuple(sorted(spans, key=lambda span: (span.start, -(span.end - span.start), span.role)))


def final_step_bounds(excerpt: str) -> tuple[int, int]:
    matches = list(re.finditer(r"[^\n]+", excerpt))
    if not matches:
        return 0, 0
    final = next((match for match in reversed(matches) if match.group(0).strip()), matches[-1])
    return final.start(), final.end()


def compatible_value(slot: NumericSlot, value: int | float | str) -> bool:
    if isinstance(value, str):
        return False
    if slot.type_name in {"integer", "positive_integer"} and not isinstance(value, int):
        return False
    if slot.type_name in {"positive_integer", "positive_number"} and value <= 0:
        return False
    return True


def compatible_span(slot: NumericSlot, span: NumeralSpan) -> bool:
    return compatible_value(slot, span.value)


def equation_matches(text: str) -> tuple[re.Match[str], ...]:
    matches: list[re.Match[str]] = []
    for line_match in re.finditer(r"[^\n]+", text):
        line = line_match.group(0)
        if "=" not in line:
            continue
        matches.extend(EQUATION_RE.finditer(line))
    return tuple(matches)


def equation_operator_tokens(text: str) -> tuple[str, ...]:
    """Find explicit operator tokens on equation lines without treating signs as operators."""
    found: list[str] = []
    for line in text.splitlines():
        if "=" not in line:
            continue
        found.extend(match.group(0).lower() for match in re.finditer(r"\btimes\b", line, re.I))
        for index, character in enumerate(line):
            if character not in "+-×÷":
                continue
            left = next((value for value in reversed(line[:index]) if not value.isspace()), "")
            right = next((value for value in line[index + 1:] if not value.isspace()), "")
            if left and right and left not in "=([{,:+-×÷/" and right not in "=)]},:+×÷/":
                found.append(character)
        # A slash surrounded by space is an explicit division token. Compact
        # numeric division is admitted only when the equation parser identifies
        # the slash as its operator, so fraction bars do not create ambiguity.
        found.extend("/" for _ in re.finditer(r"\s/\s", line))
        if "/" not in found:
            found.extend(
                match.group("operator").lower()
                for match in EQUATION_RE.finditer(line)
                if match.group("operator") == "/"
            )
    return tuple(found)


def operator_family(text: str) -> tuple[str | None, tuple[str, ...]]:
    operators = equation_operator_tokens(text)
    families = {OPERATOR_FAMILIES[operator] for operator in operators}
    return (next(iter(families)) if len(families) == 1 else None), operators


def exact_spans(text: str, spans: tuple[NumeralSpan, ...]) -> tuple[NumeralSpan, ...]:
    """Recover every maximal source span with exactly the transcribed text."""
    return tuple(span for span in spans if span.role == "numeral" and span.text == text)


def _candidate_letter(raw: str, valid: set[str]) -> str | None:
    matched = re.match(r"\s*([A-Za-z])", raw)
    if not matched:
        return None
    letter = matched.group(1).upper()
    return letter if letter in valid else None


def _slot_name(slot_key: str) -> str:
    value = slot_key.strip("/").replace("/", "_").replace("-", "_") or "operand"
    value = re.sub(r"[^a-zA-Z0-9_]", "_", value).lower()
    return value if re.match(r"^[a-z]", value) else "slot_" + value


class QuestionnaireRunner:
    def __init__(
        self,
        model: ModelClient,
        symbolic: SymbolicClient | None = None,
        compiled: CompiledChoiceSets | None = None,
    ) -> None:
        self.model = model
        self.symbolic = symbolic if symbolic is not None else StdioHermesClient()
        self.compiled = compiled if compiled is not None else compile_choice_sets()
        self.call_contract = load_call_contract()
        self._ledger: list[dict[str, Any]] = []
        self._eval_count = 0
        self._model_calls = 0

    def close(self) -> None:
        self.symbolic.close()

    def _record(self, kind: str, **fields: Any) -> None:
        self._ledger.append({"kind": kind, **fields})

    def _render_choice_prompt(self, question: Question, *, corrective_note: str = "") -> str:
        choices = "\n".join(f"{choice.letter} — {choice.label}" for choice in question.choices)
        prompt = self.call_contract["prompt_template"].format(
            excerpt=question.excerpt,
            question=question.text,
            choices=choices,
        )
        if corrective_note:
            prompt += f"\n\nValidator note: {corrective_note}"
        return prompt

    def _render_binding_prompt(self, question: Question, *, corrective_note: str = "") -> str:
        template = self.call_contract["binding_prompt_templates"][question.context["binding_mode"]]
        prompt = template.format(excerpt=question.excerpt, **question.context)
        if corrective_note:
            prompt += f"\n\nValidator note: {corrective_note}"
        return prompt

    def _record_outcome(self, question: Question, outcome: ModelOutcome, attempt: int) -> None:
        self._model_calls += 1
        self._eval_count += max(0, int(outcome.eval_count))
        event: dict[str, Any] = {
            "kind": "model_attempt",
            "level": question.level,
            "page": question.page_index,
            "attempt": attempt,
            "response_kind": question.response_kind,
            "transport": outcome.status.value,
            "eval_count": outcome.eval_count,
        }
        if outcome.detail:
            event["detail"] = outcome.detail
        for name in (
            "latency_ms",
            "raw_exact_one_letter",
            "reply_stops_honored",
            "request_contract_exact",
            "parse_ok",
        ):
            value = getattr(outcome, name)
            if value is not None:
                event[name] = value
        if outcome.status is TransportStatus.OK and outcome.content:
            field_name = "letter" if question.response_kind == ResponseKind.LETTER.value else "transcription"
            event[field_name] = outcome.content
        self._ledger.append(event)

    def _budget_available(self, level: str) -> bool:
        if self._eval_count <= self.call_contract["item_eval_count_cap"]:
            return True
        self._record("budget_exhausted", level=level, eval_count=self._eval_count)
        return False

    def _ask_page(self, page: ChoicePage, excerpt: str, context: dict[str, Any], *, auto_bind: bool) -> Choice | None:
        content = page.content_choices
        if auto_bind:
            selected = content[0]
            self._record("auto_bind", level=page.level, key=selected.key)
            return selected

        question = Question(
            level=page.level,
            text=page.question,
            excerpt=excerpt,
            page_index=page.page_index,
            page_count=page.page_count,
            choices=page.choices,
            context=context,
        )
        valid = {choice.letter for choice in question.choices}
        first_candidate: str | None = None
        corrective_note = ""
        for attempt in range(1, self.call_contract["max_attempts_per_question"] + 1):
            prompt = self._render_choice_prompt(question, corrective_note=corrective_note)
            outcome = self.model.complete(question, prompt, request_for_question(self.call_contract, question))
            self._record_outcome(question, outcome, attempt)
            if not self._budget_available(page.level):
                break
            if outcome.status is not TransportStatus.OK:
                corrective_note = "The prior transport outcome was not usable. Reply with exactly one listed letter."
                continue

            stopped = outcome.content
            for stop in self.call_contract["reply_stops"]:
                stopped = stopped.split(stop, 1)[0]
            normalized = stopped.strip().upper()
            candidate = _candidate_letter(stopped, valid)
            if first_candidate is None:
                first_candidate = candidate
            if len(normalized) == 1 and normalized in valid:
                if attempt > 1 and first_candidate is not None and normalized != first_candidate:
                    self._record(
                        "conflict", level=page.level,
                        first_letter=first_candidate, retry_letter=normalized,
                    )
                    self._record("system_abstention", level=page.level, reason="conflicting_retry")
                    return None
                selected = next(choice for choice in question.choices if choice.letter == normalized)
                self._record("choice", level=page.level, letter=normalized, key=selected.key)
                if normalized == ABSTENTION_LETTER:
                    self._record("system_abstention", level=page.level, reason="abstention_exit")
                    return None
                return selected
            corrective_note = "The prior reply was invalid. Reply with exactly one listed letter, with no other text."
            self._record("invalid_letter", level=page.level, reply=outcome.content)
        self._record("retry_exhausted", level=page.level)
        self._record("system_abstention", level=page.level, reason="retry_exhausted")
        return None

    def _ask_pages(self, pages: tuple[ChoicePage, ...], excerpt: str, context: dict[str, Any]) -> Choice | None:
        total_content = sum(len(page.content_choices) for page in pages)
        if total_content == 0:
            return None
        for page in pages:
            choice = self._ask_page(page, excerpt, context, auto_bind=total_content == 1)
            if choice is not None:
                return choice
            if page.page_index + 1 < page.page_count:
                self._record("page_continue", level=page.level, next_page=page.page_index + 1)
        return None

    def _ask_transcription(
        self,
        question: Question,
        validator: Callable[[str], tuple[Any | None, str]],
    ) -> Any | None:
        corrective_note = ""
        for attempt in range(1, self.call_contract["max_attempts_per_question"] + 1):
            prompt = self._render_binding_prompt(question, corrective_note=corrective_note)
            outcome = self.model.complete(question, prompt, request_for_question(self.call_contract, question))
            self._record_outcome(question, outcome, attempt)
            if not self._budget_available(question.level):
                break
            if outcome.status is not TransportStatus.OK:
                corrective_note = "The prior transport outcome was unusable. Transcribe only the requested text."
                continue
            value, reason = validator(outcome.content)
            if value is not None:
                self._record("binding_accepted", level=question.level, mode=question.context["binding_mode"])
                return value
            self._record(
                "binding_rejected", level=question.level,
                mode=question.context["binding_mode"], reason=reason,
            )
            corrective_note = (
                f"The prior transcription failed validation ({reason}). "
                "Copy the requested numeral or operation verbatim from the excerpt."
            )
        self._record("binding_retry_exhausted", level=question.level)
        self._record("system_abstention", level=question.level, reason="binding_retry_exhausted")
        return None

    def _select_family(self, excerpt: str) -> tuple[str | None, str | None]:
        masked: set[str] = set()
        for l2_attempt in range(2):
            region_choice = self._ask_pages(
                self.compiled.l1_pages(masked_region_ids=masked), excerpt,
                {"masked_regions": sorted(masked)},
            )
            if region_choice is None:
                return None, "l1_abstention"
            region_id = str(region_choice.value)
            family_choice = self._ask_pages(
                self.compiled.l2_pages(region_id), excerpt,
                {"region_id": region_id},
            )
            if family_choice is not None:
                return str(family_choice.value), None
            if l2_attempt == 0:
                self._record("l2_reopen_l1", region_id=region_id)
                masked.add(region_id)
                continue
            return None, "l2_abstention"
        return None, "l2_abstention"

    def _validate_equation(
        self,
        raw: str,
        excerpt: str,
        spans: tuple[NumeralSpan, ...],
        family: str,
    ) -> tuple[dict[str, Any] | None, str]:
        text = raw.strip()
        matched = EQUATION_RE.fullmatch(text)
        if not matched:
            return None, "not_one_equation"
        transcribed_family = OPERATOR_FAMILIES[matched.group("operator").lower()]
        if transcribed_family != family:
            return None, "operator_family_mismatch"
        if text not in excerpt:
            return None, "equation_not_exact_text"
        bound: dict[str, BoundValue] = {}
        for name in ("a", "b", "got"):
            numeral = matched.group(name)
            matches = exact_spans(numeral, spans)
            if not matches:
                return None, f"non_verbatim_numeral:{numeral}"
            bound[name] = BoundValue(numeral, _parse_numeric(numeral), matches)
        self._record(
            "verbatim_span_recovery",
            mode="symbol_equation",
            equation=text,
            values={name: {"text": value.text, "spans": [asdict(span) for span in value.spans]}
                    for name, value in bound.items()},
        )
        return {"operands": (bound["a"], bound["b"]), "got": bound["got"]}, ""

    def _transcribe_symbol(
        self,
        family: str,
        excerpt: str,
        spans: tuple[NumeralSpan, ...],
    ) -> dict[str, Any] | None:
        question = Question(
            level="L4/L5",
            text="Write the student's operation exactly as written.",
            excerpt=excerpt,
            page_index=0,
            page_count=1,
            context={"binding_mode": "symbol_equation", "family": family},
            response_kind=ResponseKind.TRANSCRIPTION.value,
        )
        return self._ask_transcription(
            question,
            lambda raw: self._validate_equation(raw, excerpt, spans, family),
        )

    def _validate_given(
        self,
        raw: str,
        expected_name: str,
        spans: tuple[NumeralSpan, ...],
        *,
        require_final_step: tuple[int, int] | None = None,
    ) -> tuple[BoundValue | None, str]:
        matched = GIVEN_RE.fullmatch(raw.strip())
        if not matched or matched.group("name") != expected_name:
            return None, "not_expected_given_fact"
        text = matched.group("value")
        matches = exact_spans(text, spans)
        if not matches:
            return None, f"non_verbatim_numeral:{text}"
        if require_final_step is not None:
            start, end = require_final_step
            if not any(start <= span.start and span.end <= end for span in matches):
                return None, "got_absent_from_final_step"
        value = BoundValue(text, _parse_numeric(text), matches)
        self._record(
            "verbatim_span_recovery",
            mode="prose_given",
            name=expected_name,
            text=text,
            spans=[asdict(span) for span in matches],
        )
        return value, ""

    def _prose_bindings(
        self,
        family: str,
        excerpt: str,
        spans: tuple[NumeralSpan, ...],
    ) -> tuple[dict[str, BoundValue], BoundValue | None]:
        schemas = self.compiled.schemas_for_family(family)
        slot_keys = sorted({slot.key for schema in schemas for slot in numeric_slots(schema)})
        values: dict[str, BoundValue] = {}
        for slot_key in slot_keys:
            name = _slot_name(slot_key)
            question = Question(
                level="L4",
                text=f"Transcribe the given for operand slot {slot_key}.",
                excerpt=excerpt,
                page_index=0,
                page_count=1,
                context={
                    "binding_mode": "prose_slot",
                    "family": family,
                    "slot": slot_key,
                    "slot_name": name,
                },
                response_kind=ResponseKind.TRANSCRIPTION.value,
            )
            value = self._ask_transcription(
                question,
                lambda raw, expected=name: self._validate_given(raw, expected, spans),
            )
            if value is not None:
                values[slot_key] = value
            else:
                self._record("slot_unbound", slot=slot_key, reason="system_abstention")

        start, end = final_step_bounds(excerpt)
        got_question = Question(
            level="L5",
            text="Transcribe the student's final answer.",
            excerpt=excerpt[start:end],
            page_index=0,
            page_count=1,
            context={"binding_mode": "prose_got", "family": family, "slot_name": "got"},
            response_kind=ResponseKind.TRANSCRIPTION.value,
        )
        got = self._ask_transcription(
            got_question,
            lambda raw: self._validate_given(raw, "got", spans, require_final_step=(start, end)),
        )
        if got is None:
            self._record("got_unbound", reason="system_abstention")
        return values, got

    @staticmethod
    def _bind_schema(schema: ContractSchema, values: dict[str, BoundValue]) -> SchemaBinding | None:
        slots = numeric_slots(schema)
        if any(slot.key not in values or not compatible_value(slot, values[slot.key].value) for slot in slots):
            return None
        operand = copy.deepcopy(schema.example)
        for slot in slots:
            operand = replace_path(operand, slot.path, values[slot.key].value)
        if not conforms(schema.template, operand):
            return None
        return SchemaBinding(schema, operand)

    def _schema_candidates_from_symbol(
        self,
        family: str,
        transcription: dict[str, Any],
    ) -> tuple[SchemaBinding, ...]:
        operands: tuple[BoundValue, ...] = transcription["operands"]
        candidates: list[SchemaBinding] = []
        for schema in self.compiled.schemas_for_family(family):
            slots = numeric_slots(schema)
            if len(slots) != len(operands):
                continue
            values = {slot.key: value for slot, value in zip(slots, operands)}
            bound = self._bind_schema(schema, values)
            if bound is not None:
                candidates.append(bound)
        return tuple(candidates)

    def _residual_question(self, binding: SchemaBinding, excerpt: str) -> ChoicePage:
        slots = numeric_slots(binding.schema)
        anchors = ", ".join(f"{slot.key}={self._value_at(binding.operand, slot.path)}" for slot in slots)
        shape = binding.schema.discriminator
        if shape == "untyped":
            shape = binding.schema.representative_kind
        question = (
            f"The excerpt supplies {anchors}. Does it explicitly use the "
            f"{plain_label(shape)} form?"
        )
        return ChoicePage(
            "L3-binary",
            question,
            0,
            1,
            (
                Choice("A", "yes", "yes", True),
                Choice("B", "no", "no", False),
                Choice("X", "abstain", "the excerpt does not say", None),
            ),
        )

    @staticmethod
    def _value_at(value: Any, path: tuple[str | int, ...]) -> Any:
        cursor = value
        for part in path:
            cursor = cursor[part]
        return cursor

    def _select_schema_by_binding(
        self,
        candidates: tuple[SchemaBinding, ...],
        excerpt: str,
    ) -> SchemaBinding | None:
        self._record(
            "schema_binding_candidates",
            candidates=[candidate.schema.schema_id for candidate in candidates],
        )
        if not candidates:
            self._record("system_abstention", level="L3", reason="no_conforming_schema")
            return None
        if len(candidates) == 1:
            selected = candidates[0]
            self._record("schema_selected_by_binding", schema_id=selected.schema.schema_id)
            return selected

        yes: list[SchemaBinding] = []
        for candidate in candidates:
            choice = self._ask_page(
                self._residual_question(candidate, excerpt),
                excerpt,
                {"schema_id": candidate.schema.schema_id, "contract_bound": True},
                auto_bind=False,
            )
            if choice is not None and choice.key == "yes":
                yes.append(candidate)
        if len(yes) == 1:
            self._record("schema_selected_by_binary", schema_id=yes[0].schema.schema_id)
            return yes[0]
        self._record(
            "system_abstention", level="L3-binary", reason="residual_tie_unresolved",
            affirmative_schemas=[candidate.schema.schema_id for candidate in yes],
        )
        return None

    def run(self, excerpt: str) -> ItemResult:
        self._ledger = []
        self._eval_count = 0
        self._model_calls = 0
        digest = hashlib.sha256(excerpt.encode("utf-8")).hexdigest()
        spans = harvest_numerals(excerpt)
        self._record("l0", excerpt_sha256=digest, numeral_spans=[asdict(span) for span in spans])
        if not excerpt.strip() or not spans:
            return self._finish(ItemResult("not_covered", digest), reason="l0_gate")

        gated_family, operators = operator_family(excerpt)
        if gated_family is not None:
            family = gated_family
            self._record("l0_operator_bound", family=family, operators=list(operators))
        else:
            if operators:
                self._record("l0_operator_ambiguous", operators=list(operators))
            family, reason = self._select_family(excerpt)
            if family is None:
                return self._finish(ItemResult("not_covered", digest), reason=reason)

        symbol_form = gated_family is not None
        if symbol_form:
            transcription = self._transcribe_symbol(family, excerpt, spans)
            if transcription is None:
                return self._finish(ItemResult("extraction_incomplete", digest, family=family))
            candidates = self._schema_candidates_from_symbol(family, transcription)
            got_value: BoundValue | None = transcription["got"]
        else:
            prose_values, got_value = self._prose_bindings(family, excerpt, spans)
            candidates = tuple(
                bound for schema in self.compiled.schemas_for_family(family)
                if (bound := self._bind_schema(schema, prose_values)) is not None
            )

        selected = self._select_schema_by_binding(candidates, excerpt)
        if selected is None:
            status = "extraction_incomplete" if not candidates or got_value is None else "not_covered"
            return self._finish(ItemResult(status, digest, family=family), reason="schema_selection_abstention")
        if got_value is None:
            return self._finish(ItemResult(
                "extraction_incomplete", digest, family=family,
                schema_id=selected.schema.schema_id, operand=selected.operand,
            ))

        leaf = self.symbolic.call_tool(
            "strategy_trace",
            {"strategy": selected.schema.representative_kind, "input": selected.operand},
        )
        self._record(
            "leaf_call", tool="strategy_trace", family=family,
            strategy=selected.schema.representative_kind, schema_id=selected.schema.schema_id,
        )
        return self._finish(ItemResult(
            "leaf_computed", digest, family=family, schema_id=selected.schema.schema_id,
            operand=selected.operand, got=got_value.text.replace(",", ""), leaf=leaf,
        ))

    def _finish(self, result: ItemResult, *, reason: str | None = None) -> ItemResult:
        if reason:
            self._record("terminal", status=result.status, reason=reason)
        result.ledger = list(self._ledger)
        result.model_calls = self._model_calls
        result.eval_count = self._eval_count
        return result


def prolog_fraction(text: str) -> Fraction | None:
    """Parse a simple fraction for callers that need an exact comparison."""
    matched = SIMPLE_FRACTION_RE.fullmatch(text.strip())
    if not matched:
        return None
    return Fraction(int(matched.group(1)), int(matched.group(2)))


__all__ = [
    "BoundValue",
    "ItemResult",
    "ModelClient",
    "ModelOutcome",
    "NumeralSpan",
    "Question",
    "QuestionnaireRunner",
    "ResponseKind",
    "SchemaBinding",
    "StdioHermesClient",
    "SymbolicClient",
    "TransportStatus",
    "equation_matches",
    "equation_operator_tokens",
    "harvest_numerals",
    "load_call_contract",
    "operator_family",
    "request_for_question",
]
