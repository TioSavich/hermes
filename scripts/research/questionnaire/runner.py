#!/usr/bin/env python3
"""Run one offline questionnaire item with injected model and Hermes clients.

The default symbolic client is the repository's stdio ``MCPClient``.  A model
client is always injected; this module has no network transport and makes no
model call on import or construction.
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
from typing import Any, Protocol


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
    MAX_CONTENT_CHOICES,
    NumericSlot,
    compile_choice_sets,
    conforms,
    make_pages,
    numeric_slots,
    replace_path,
)
from scripts.research.gemma_hermes_protocol import MCPClient  # noqa: E402


CALL_CONTRACT_PATH = HERE / "call_contract.json"
NUMERAL_RE = re.compile(
    r"(?<![\w.])[-+]?(?:\d+\s+\d+/\d+|\d+/\d+|\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)(?![\w.])"
)
SIMPLE_FRACTION_RE = re.compile(r"^([+-]?\d+)/(\d+)$")


class TransportStatus(str, Enum):
    OK = "ok"
    TRUNCATED = "truncated"
    EMPTY_CONTENT = "empty_content"
    INVALID_CONTENT = "invalid_content"
    ERROR = "error"


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
    choices: tuple[Choice, ...]
    context: dict[str, Any] = field(default_factory=dict)


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
    request = contract["request"]
    if request != {"temperature": 0, "num_predict": 8, "think": False, "stops": []}:
        raise ValueError("call contract drifted from the designed one-letter request")
    if contract["output"]["abstention_letter"] != ABSTENTION_LETTER:
        raise ValueError("call contract abstention letter does not match the compiler")
    return contract


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


def compatible_span(slot: NumericSlot, span: NumeralSpan) -> bool:
    value = span.value
    if isinstance(value, str):
        return False
    if slot.type_name in {"integer", "positive_integer"} and not isinstance(value, int):
        return False
    if slot.type_name in {"positive_integer", "positive_number"} and value <= 0:
        return False
    return True


def span_pages(level: str, question: str, spans: tuple[NumeralSpan, ...]) -> tuple[ChoicePage, ...]:
    rows = [
        (
            f"{span.start}:{span.end}:{span.role}",
            f"{span.text} [characters {span.start}:{span.end}]",
            asdict(span),
        )
        for span in spans
    ]
    return make_pages(level, question, rows)


def _candidate_letter(raw: str, valid: set[str]) -> str | None:
    matched = re.match(r"\s*([A-Za-z])", raw)
    if not matched:
        return None
    letter = matched.group(1).upper()
    return letter if letter in valid else None


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

    def _render_prompt(self, question: Question, *, corrective_note: str = "") -> str:
        choices = "\n".join(f"{choice.letter} — {choice.label}" for choice in question.choices)
        prompt = self.call_contract["prompt_template"].format(
            excerpt=question.excerpt,
            question=question.text,
            choices=choices,
        )
        if corrective_note:
            prompt += f"\n\nValidator note: {corrective_note}"
        return prompt

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
            prompt = self._render_prompt(question, corrective_note=corrective_note)
            request = dict(self.call_contract["request"])
            outcome = self.model.complete(question, prompt, request)
            self._model_calls += 1
            self._eval_count += max(0, int(outcome.eval_count))
            event = {
                "kind": "model_attempt",
                "level": page.level,
                "page": page.page_index,
                "attempt": attempt,
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
                event["letter"] = outcome.content
            self._ledger.append(event)

            if self._eval_count > self.call_contract["item_eval_count_cap"]:
                corrective_note = "The item output budget is exhausted; this answer is recorded as X."
                self._record("budget_exhausted", level=page.level, eval_count=self._eval_count)
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
                    return None
                selected = next(choice for choice in question.choices if choice.letter == normalized)
                self._record("choice", level=page.level, letter=normalized, key=selected.key)
                return None if normalized == ABSTENTION_LETTER else selected
            corrective_note = "The prior reply was invalid. Reply with exactly one listed letter, with no other text."
            self._record("invalid_letter", level=page.level, reply=outcome.content)
        self._record("retry_exhausted", level=page.level)
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

    def _recognized_schema(self, family: str, excerpt: str) -> ContractSchema | None:
        value = self.symbolic.call_tool("strategy_recognize", {"content": excerpt})
        candidates = value if isinstance(value, list) else value.get("items", []) if isinstance(value, dict) else []
        by_kind = {
            kind: schema
            for schema in self.compiled.schemas_for_family(family)
            for kind in schema.kinds
        }
        for candidate in candidates:
            if not isinstance(candidate, dict):
                continue
            kind = candidate.get("strategy") or candidate.get("kind") or candidate.get("name")
            if kind in by_kind:
                self._record("l3_free_route", family=family, strategy=kind)
                return by_kind[kind]
        self._record("l3_free_route_abstention", family=family)
        return None

    def _select_schema(self, family: str, excerpt: str) -> ContractSchema | None:
        schemas = self.compiled.schemas_for_family(family)
        if len(schemas) <= MAX_CONTENT_CHOICES:
            choice = self._ask_pages(self.compiled.l3_pages(family), excerpt, {"family": family})
        else:
            discriminator_choice = self._ask_pages(
                self.compiled.l3_discriminator_pages(family), excerpt, {"family": family},
            )
            if discriminator_choice is None:
                return self._recognized_schema(family, excerpt)
            discriminator = str(discriminator_choice.value)
            choice = self._ask_pages(
                self.compiled.l3_schema_pages(family, discriminator), excerpt,
                {"family": family, "discriminator": discriminator},
            )
        if choice is None:
            return self._recognized_schema(family, excerpt)
        return self.compiled.schema_by_id(str(choice.value))

    def _bind_operand(
        self,
        schema: ContractSchema,
        excerpt: str,
        spans: tuple[NumeralSpan, ...],
    ) -> tuple[Any, bool]:
        operand = copy.deepcopy(schema.example)
        complete = True
        for slot in numeric_slots(schema):
            candidates = tuple(span for span in spans if compatible_span(slot, span))
            if not candidates:
                self._record("slot_unbound", slot=slot.key, reason="no_compatible_numeral")
                complete = False
                continue
            choice = self._ask_pages(
                span_pages("L4", f"Which numeral binds operand slot {slot.key}?", candidates),
                excerpt,
                {"family": schema.family, "schema_id": schema.schema_id,
                 "slot": slot.key, "example_value": slot.example},
            )
            if choice is None:
                self._record("slot_unbound", slot=slot.key, reason="abstention")
                complete = False
                continue
            value = choice.value["value"]
            operand = replace_path(operand, slot.path, value)
        return operand, complete and conforms(schema.template, operand)

    def _bind_got(self, excerpt: str, spans: tuple[NumeralSpan, ...]) -> str | None:
        start, end = final_step_bounds(excerpt)
        final_spans = tuple(span for span in spans if start <= span.start and span.end <= end and span.role == "numeral")
        if not final_spans:
            self._record("got_unbound", reason="no_final_step_numeral")
            return None
        choice = self._ask_pages(
            span_pages("L5", "Which numeral is the student's final answer?", final_spans),
            excerpt[start:end],
            {"final_step_start": start, "final_step_end": end},
        )
        if choice is None:
            self._record("got_unbound", reason="abstention")
            return None
        return str(choice.value["text"]).replace(",", "")

    def run(self, excerpt: str) -> ItemResult:
        self._ledger = []
        self._eval_count = 0
        self._model_calls = 0
        digest = hashlib.sha256(excerpt.encode("utf-8")).hexdigest()
        spans = harvest_numerals(excerpt)
        self._record("l0", excerpt_sha256=digest, numeral_spans=[asdict(span) for span in spans])
        if not excerpt.strip() or not spans:
            return self._finish(ItemResult("not_covered", digest), reason="l0_gate")

        family, reason = self._select_family(excerpt)
        if family is None:
            return self._finish(ItemResult("not_covered", digest), reason=reason)
        schema = self._select_schema(family, excerpt)
        if schema is None:
            return self._finish(ItemResult("not_covered", digest, family=family), reason="l3_abstention")

        operand, operand_complete = self._bind_operand(schema, excerpt, spans)
        got = self._bind_got(excerpt, spans)
        if not operand_complete or got is None:
            return self._finish(ItemResult(
                "extraction_incomplete", digest, family=family,
                schema_id=schema.schema_id, operand=operand, got=got,
            ))

        leaf = self.symbolic.call_tool(
            "strategy_trace",
            {"strategy": schema.representative_kind, "input": operand},
        )
        self._record(
            "leaf_call", tool="strategy_trace", family=family,
            strategy=schema.representative_kind, schema_id=schema.schema_id,
        )
        return self._finish(ItemResult(
            "leaf_computed", digest, family=family, schema_id=schema.schema_id,
            operand=operand, got=got, leaf=leaf,
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
    "ItemResult",
    "ModelClient",
    "ModelOutcome",
    "NumeralSpan",
    "Question",
    "QuestionnaireRunner",
    "StdioHermesClient",
    "SymbolicClient",
    "TransportStatus",
    "harvest_numerals",
    "load_call_contract",
]
