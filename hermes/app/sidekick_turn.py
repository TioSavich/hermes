"""The sidekick chat turn engine. Pure logic: no HTTP, no route context.

One entry point, run_turn. The caller supplies a Completer (the local model
client, or a scripted fake in the sandbox check) and an in-process
HermesMCPServer; this module owns the deterministic router, the bounded state
machine, tool execution with the three-way response classification, the
grounding-block fallback, and the reply safety filter.

The design's spine is a measured fact: this model class calls a tool when the
message mandates one and does not decide on its own that it needs one
(capacity without disposition; scripts/research/mtb_agent_responder.py:113-125,
floors artifacts under hermes/app/runtime/experiments/sidekick/floors/). In
routed mode the system decides WHEN a tool runs and WHICH one; the model
formulates only that call's arguments and the bounded reply. In model-chooses
mode the model receives the same menu and decides everything, bounded to two
rounds, so the disposition itself is on record in the transcript panel.
"""
from __future__ import annotations

import json
import re
import time
from dataclasses import dataclass, field
from typing import Any, Callable, Mapping, Sequence

from hermes.app.sidekick_llm import ClientResult, assistant_echo

Completer = Callable[[list[dict[str, Any]], list[dict[str, Any]] | None, int], ClientResult]

# Menu carved from the 28 core tools for demo value and formulation
# robustness; the exclusion reasons are recorded in the task brief
# (.superpowers/sdd/task-2026-08-18-sidekick-chat-brief.md).
MENU_TOOLS = (
    "check_math_claim",
    "monitoring_chart",
    "lesson_deformation_chart",
    "deformation_compare",
    "fraction_comparison_compare",
    "list_strategies",
    "strategy_trace",
    "strategy_recognize",
    "misconception_search_rows",
    "abduce_error",
)

MAX_TOKENS_FORMULATION = 160
MAX_TOKENS_FINAL = 320
RESULT_TRIM_BYTES = 4096
HISTORY_MAX_TURNS = 6
HISTORY_CHAR_BUDGET = 6000

# What counts as a limit statement in a reply after an abstention. Copied from
# scripts/sidekick/measure_floors.py:73-78 (LIMIT_MARKERS) with a provenance
# note rather than an import across the scripts/ boundary.
LIMIT_MARKERS = (
    "no ", "not ", "none", "nothing", "n't", "decline", "abstain", "cannot",
    "unable", "no record", "no match", "does not", "is not", "isn't", "doesn't",
    "outside", "unavailable", "no entry", "no rule", "no strategy", "no chart",
)

# Reply filter vocabulary, genre of scripts/research/mtb_agent_responder.py
# _reply_is_safe (lines 160-171), loosened for chat as the brief specifies.
_INTERNAL = re.compile(
    r"\b(?:ledger|prolog|retrieval|tool(?:s| call)?|function call|system prompt)\b",
    re.IGNORECASE,
)
_PUFFERY = re.compile(
    r"\b(?:wonderful|amazing|fantastic|excellent|awesome|brilliant|"
    r"great job|good job|nice work|very thoughtful|perfect)\b",
    re.IGNORECASE,
)
# Verdict vocabulary the tools own. After a refusal or abstention the reply
# must not speak in it: the engine computes; the model never adjudicates.
_VERDICT_WORDS = re.compile(
    r"\b(?:holds|refuted|checks out|confirmed|verified)\b", re.IGNORECASE
)

LESSON_CODE = re.compile(r"\bIM-G(\d+)-U(\d+)-L(\d+)\b", re.IGNORECASE)
_CLAIM = re.compile(
    r"([^.?!\n]*\d[^.?!\n]*(?:=|\bequals\b|\bis\s+(?:bigger|greater|less|smaller)\s+than\b)[^.?!\n]*)",
    re.IGNORECASE,
)
_WRONG_ANSWER = re.compile(
    r"\b(?:got|gets|wrote|writes|answered|answers|says|said)\b[^.?!\n]*?(-?\d+(?:\.\d+)?(?:\s*/\s*\d+)?)",
    re.IGNORECASE,
)
_A_OP_B = re.compile(
    r"(-?\d+(?:\.\d+)?(?:/\d+)?)\s*([+\-x×*÷/])\s*(-?\d+(?:\.\d+)?(?:/\d+)?)"
)
_MISTAKE_WORDS = re.compile(
    r"\b(?:mistake|wrong|error|misconception|deformation)\b", re.IGNORECASE
)
_OBSERVATION = re.compile(
    r"\b(?:my student|a student|the student|my students|the child|a child|my kid)\b"
    r"|\b(?:she|he|they)\s+(?:counted|counts|skipped|skips|split|splits|added|adds|"
    r"subtracted|regrouped|carried|borrowed|drew|wrote|stacked|crossed)\b",
    re.IGNORECASE,
)
_INVENTORY = re.compile(
    r"\b(?:what|which|list)\b[^.?!\n]*\bstrateg(?:y|ies)\b", re.IGNORECASE
)
_MISCONCEPTION_ASK = re.compile(
    r"\b(?:misconception|error pattern|why do students think|common error)s?\b",
    re.IGNORECASE,
)
_COMPARE_WORDS = re.compile(r"\b(?:compare|comparison|beside|side\s+by\s+side)\b", re.IGNORECASE)
_DRAW_WORDS = re.compile(r"\b(?:draw|chart|show|render|display)\b", re.IGNORECASE)
_FRACTION_VALUE = re.compile(r"(?<![\d/])(-?\d+)\s*/\s*([1-9]\d*)(?![\d/])")
_OPERATION_WORD = re.compile(
    r"\b(addition|subtraction|multiplication|division|fraction|decimal|integer|"
    r"geometry|measurement|probability|ratio|statistics|calculus|counting)\b",
    re.IGNORECASE,
)
_DEFORMATION_FAMILIES = (
    ("quadrant_sign_error", ("quadrant sign error", "quadrant-sign error")),
    ("reflection_by_rotation", ("reflection by rotation", "reflection-by-rotation")),
    ("flip_needed", ("flip needed", "flip-needed")),
    ("unfillable_by_parity", ("unfillable by parity", "unfillable-by-parity")),
    ("angle_confused_with_ray_length", ("angle confused with ray length",)),
    ("bar_histogram_conflation", ("bar histogram conflation", "bar-chart histogram conflation")),
    ("net_fold_failure", ("net fold failure", "net-fold failure")),
    ("boundary_peg_as_interior", ("boundary peg as interior", "boundary-peg as interior")),
)
_STOPWORDS = frozenset(
    "a an the is are was were do does did my your their his her its of in on at "
    "to for with about and or but so that this these those what which how why "
    "when where who whom can could should would will i you we they he she it".split()
)


@dataclass(slots=True)
class TurnResult:
    reply: str
    mode: str
    chooser: str
    route: dict[str, str] | None
    calls: list[dict[str, Any]] = field(default_factory=list)
    drawings: list[dict[str, Any]] = field(default_factory=list)
    fallback: dict[str, str] | None = None
    rejected_reply: str | None = None
    flags: list[str] = field(default_factory=list)
    timing: dict[str, int] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "reply": self.reply,
            "mode": self.mode,
            "chooser": self.chooser,
            "route": self.route,
            "calls": self.calls,
            "drawings": self.drawings,
            "fallback": self.fallback,
            "rejected_reply": self.rejected_reply,
            "flags": self.flags,
            "timing": self.timing,
        }


def window_history(history: Sequence[Mapping[str, Any]] | None) -> list[dict[str, str]]:
    """Keep recent plain user/assistant turns within the E2B slot budget.

    llama-server divides its ``-c`` context across ``-np`` slots. Keep no more
    than six prior turns and, working newest-first, drop older turns once their
    combined content would pass 6,000 characters.
    """
    valid: list[dict[str, str]] = []
    for item in history or ():
        role = item.get("role") if isinstance(item, Mapping) else None
        content = item.get("content") if isinstance(item, Mapping) else None
        if role in {"user", "assistant"} and isinstance(content, str) and content.strip():
            valid.append({"role": role, "content": content.strip()})
    kept_reversed: list[dict[str, str]] = []
    used = 0
    for item in reversed(valid[-HISTORY_MAX_TURNS:]):
        size = len(item["content"])
        if used + size > HISTORY_CHAR_BUDGET:
            break
        kept_reversed.append(item)
        used += size
    return list(reversed(kept_reversed))


def _named_int(text: str, *names: str) -> int | None:
    for name in names:
        name_pattern = re.escape(name).replace(r"\ ", r"\s+")
        pattern = re.compile(
            rf"\b{name_pattern}\b\s*(?:=|is|:)?\s*(-?\d+)\b",
            re.IGNORECASE,
        )
        match = pattern.search(text)
        if match:
            return int(match.group(1))
    return None


def _json_after(text: str, label: str) -> Any | None:
    match = re.search(rf"\b{re.escape(label)}\b\s*(?:=|is|:)?\s*", text, re.IGNORECASE)
    if not match:
        return None
    source = text[match.end():].lstrip()
    try:
        return json.JSONDecoder().raw_decode(source)[0]
    except (json.JSONDecodeError, TypeError):
        return None


def _deformation_arguments(text: str) -> dict[str, Any] | None:
    lowered = text.casefold().replace("_", " ")
    family = next(
        (name for name, phrases in _DEFORMATION_FAMILIES
         if any(phrase in lowered for phrase in phrases)),
        None,
    )
    if family is None:
        return None
    arguments: dict[str, Any] = {"family": family}
    if family == "quadrant_sign_error":
        x = _named_int(text, "x")
        y = _named_int(text, "y")
        if x is None or y is None:
            point = re.search(r"\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)", text)
            if point:
                x, y = int(point.group(1)), int(point.group(2))
        if x is None or y is None:
            return None
        arguments.update(x=x, y=y)
    elif family in {"reflection_by_rotation", "boundary_peg_as_interior"}:
        vertices = _json_after(text, "vertices")
        if not isinstance(vertices, list):
            return None
        arguments["vertices"] = vertices
    elif family == "flip_needed":
        piece = re.search(r"\bpiece\s*(?:=|is|:)?\s*([lfnpyz])\b", text, re.IGNORECASE)
        if not piece:
            return None
        arguments["piece"] = piece.group(1).casefold()
    elif family == "unfillable_by_parity":
        cols = _named_int(text, "cols", "columns")
        rows = _named_int(text, "rows")
        if cols is None or rows is None:
            return None
        arguments.update(cols=cols, rows=rows)
    elif family == "angle_confused_with_ray_length":
        degrees = _named_int(text, "degrees", "angle")
        short_length = _named_int(text, "short length", "short_length")
        long_length = _named_int(text, "long length", "long_length")
        if None in {degrees, short_length, long_length}:
            return None
        arguments.update(
            degrees=degrees, short_length=short_length, long_length=long_length
        )
    elif family == "bar_histogram_conflation":
        pairs = _json_after(text, "pairs")
        if not isinstance(pairs, list):
            return None
        arguments["pairs"] = pairs
    elif family == "net_fold_failure":
        solid = re.search(r"\bsolid\s*(?:=|is|:)?\s*(cube)\b", text, re.IGNORECASE)
        if not solid and "cube" not in lowered:
            return None
        arguments["solid"] = "cube"
    return arguments


def route_message(message: str, strategy_names: frozenset[str]) -> dict[str, Any] | None:
    """Deterministic intent router: ordered, first match wins.

    Genre of the console chat's scene routers
    (hermes/app/routes/logic.py:337-380). The router chooses the tool; the
    model formulates only the arguments.
    """
    text = message.strip()
    lowered = text.casefold()

    claim = _CLAIM.search(text)
    if claim:
        return {"intent": "explicit_claim", "tool": "check_math_claim",
                "hint": f"The claim to check, verbatim from the teacher: {claim.group(1).strip()}",
                "arguments": {"term": claim.group(1).strip()}}

    fractions = _FRACTION_VALUE.findall(text)
    if len(fractions) >= 2 and _COMPARE_WORDS.search(text):
        (n1, d1), (n2, d2) = fractions[:2]
        family = "number_line_fraction_comparison"
        family_phrases = {
            "area model": "area_model_fraction_comparison",
            "set model": "set_model_fraction_comparison",
            "benchmark": "benchmark_fraction_comparison",
            "common unit": "common_unit_fraction_comparison",
            "number line": "number_line_fraction_comparison",
        }
        family = next(
            (value for phrase, value in family_phrases.items() if phrase in lowered),
            family,
        )
        arguments = {
            "family": family,
            "n1": int(n1), "d1": int(d1), "n2": int(n2), "d2": int(d2),
        }
        return {
            "intent": "fraction_comparison_draw",
            "tool": "fraction_comparison_compare",
            "hint": "Use the two stated fractions and the stated representation, if any",
            "arguments": arguments,
        }

    deformation_arguments = _deformation_arguments(text)
    if deformation_arguments and (_COMPARE_WORDS.search(text) or _DRAW_WORDS.search(text)):
        return {
            "intent": "deformation_comparison_draw",
            "tool": "deformation_compare",
            "hint": "Use the named deformation family and only its stated fields",
            "arguments": deformation_arguments,
        }

    wrong = _WRONG_ANSWER.search(text)
    operands = _A_OP_B.search(text)
    if wrong and operands:
        a, op, b = operands.groups()
        op_norm = {"x": "*", "×": "*", "÷": "/"}.get(op, op)
        # Domain names verified live against the misconception registry's
        # abduce surface on 2026-08-18: whole_number carries the integer
        # arithmetic rules; fraction and decimal exist and may abstain.
        if "/" in a or "/" in b:
            domain = "fraction"
        elif "." in a or "." in b or "." in wrong.group(1):
            domain = "decimal"
        else:
            domain = "whole_number"
        compact = f"{a}{op_norm}{b}".replace(" ", "")
        return {"intent": "wrong_answer_report", "tool": "abduce_error",
                "hint": (f"domain: {domain}; input: {compact}; "
                         f"got: {wrong.group(1).replace(' ', '')}"),
                "arguments": {"domain": domain, "input": compact,
                              "got": wrong.group(1).replace(" ", "")}}

    code = LESSON_CODE.search(text)
    if code:
        canonical = f"IM-G{code.group(1)}-U{code.group(2)}-L{code.group(3)}"
        if _MISTAKE_WORDS.search(text):
            return {"intent": "lesson_mistakes", "tool": "lesson_deformation_chart",
                    "hint": f"code: {canonical}",
                    "arguments": {"code": canonical, "full": bool(_DRAW_WORDS.search(text))}}
        return {"intent": "lesson_chart", "tool": "monitoring_chart",
                "hint": f"code: {canonical}",
                "arguments": {"code": canonical, "full": bool(_DRAW_WORDS.search(text))}}

    for name in sorted(strategy_names):
        spoken = name.replace("_", " ")
        if name.casefold() in lowered or (spoken and spoken in lowered):
            return {"intent": "named_strategy", "tool": "strategy_trace",
                    "hint": (f"strategy: {name}; use the worked input from the "
                             "declaration unless the teacher gave numbers"),
                    "arguments": {"strategy": name}}

    if _INVENTORY.search(text):
        operation = _OPERATION_WORD.search(text)
        arguments = {"operation": operation.group(1).casefold()} if operation else {}
        return {"intent": "strategy_inventory", "tool": "list_strategies",
                "hint": "pass an operation word only when the teacher named one",
                "arguments": arguments}

    if _OBSERVATION.search(text):
        return {"intent": "classroom_observation", "tool": "strategy_recognize",
                "hint": "content: the teacher's whole message, verbatim",
                "arguments": {"content": text}}

    if _MISCONCEPTION_ASK.search(text):
        return {"intent": "misconception_ask", "tool": "misconception_search_rows",
                "hint": f"query: {content_words(text)}; k: 5",
                "arguments": {"query": content_words(text), "k": 5}}

    return None


def content_words(message: str, limit: int = 8) -> str:
    words = [w for w in re.findall(r"[A-Za-z][A-Za-z_-]+", message)
             if w.casefold() not in _STOPWORDS]
    return " ".join(words[:limit]) or message.strip()[:60]


def classify_result(value: Any) -> str:
    """An empty list, or a status that names no coverage, is an abstention.

    Copied from scripts/sidekick/dataset.py:199-217 with a provenance note
    (the app bundle does not ship scripts/sidekick/). Do not weaken: an empty
    result never licenses a verdict.
    """
    if value == [] or value == {} or value is None:
        return "abstention"
    if isinstance(value, dict):
        status = str(value.get("status", ""))
        if status.startswith("no_") or status.startswith("not_") or status in {
            "refused", "sandbox_refused", "parse_error", "unresolved"
        }:
            return "abstention"
        if value.get("rejection") or value.get("error"):
            return "abstention"
        if isinstance(value.get("rows"), list) and not value["rows"]:
            return "abstention"
    return "result"


def execute_tool(mcp: Any, name: str, arguments: dict[str, Any]) -> tuple[dict[str, Any], str]:
    """Validate and run one call; genre of scripts/sidekick/dataset.py:175-197."""
    from hermes.mcp.server import InvalidArguments, ToolCallError

    try:
        prepared = dict(arguments)
        mcp.validate_arguments(name, prepared)
        value = mcp.call(name, prepared)
    except (ToolCallError, InvalidArguments, ValueError) as exc:
        kind = getattr(exc, "kind", "malformed_input")
        worker_type = getattr(exc, "worker_type", None)
        return (
            {"ok": False, "error": {"type": worker_type or kind, "message": str(exc)}},
            "refusal",
        )
    return {"ok": True, "result": value}, classify_result(value)


def _trim_payload(payload: Any) -> tuple[str, bool]:
    text = json.dumps(payload, ensure_ascii=False, sort_keys=True)
    raw = text.encode("utf-8")
    if len(raw) <= RESULT_TRIM_BYTES:
        return text, False
    return raw[:RESULT_TRIM_BYTES].decode("utf-8", "ignore"), True


def _drawing_artifact(tool: str, payload: dict[str, Any]) -> dict[str, Any] | None:
    if payload.get("ok") is not True:
        return None
    document = payload.get("result")
    if not isinstance(document, dict):
        return None
    if isinstance(document.get("frames"), list):
        kind = "frames"
    elif (
        isinstance(document.get("productive"), dict)
        and isinstance(document["productive"].get("frames"), list)
        and isinstance(document.get("deformation"), dict)
        and isinstance(document["deformation"].get("frames"), list)
    ):
        kind = "compare"
    elif tool in {"monitoring_chart", "lesson_deformation_chart"}:
        # These are chart documents rather than one filmstrip. The page keeps
        # their bounded JSON fallback and extracts any nested frame documents.
        kind = "chart"
    else:
        return None
    return {"tool": tool, "kind": kind, "document": document}


def _remember_drawing(turn: TurnResult, tool: str, payload: dict[str, Any]) -> None:
    artifact = _drawing_artifact(tool, payload)
    if artifact is not None:
        turn.drawings.append(artifact)


def _call_row(
    tool: str,
    chooser: str,
    arguments: dict[str, Any],
    *,
    executed: bool,
    response_class: str | None = None,
    payload: Any = None,
    elapsed_ms: int = 0,
    dropped_reason: str | None = None,
) -> dict[str, Any]:
    trimmed_text, trimmed = ("", False)
    if payload is not None:
        trimmed_text, trimmed = _trim_payload(payload)
    return {
        "tool": tool,
        "chooser": chooser,
        "arguments": arguments,
        "executed": executed,
        "response_class": response_class,
        "dropped_reason": dropped_reason,
        "elapsed_ms": elapsed_ms,
        "result_trimmed": trimmed_text,
        "trimmed": trimmed,
    }


def reply_is_safe(reply: str, worst_class: str | None) -> bool:
    words = re.findall(r"\b\w+\b", reply)
    if not reply.strip() or len(words) > 80:
        return False
    if reply.count("\n") > 3:
        return False
    if _INTERNAL.search(reply) or _PUFFERY.search(reply):
        return False
    if worst_class in {"refusal", "abstention"} and _VERDICT_WORDS.search(reply):
        return False
    return True


def states_limit(reply: str) -> bool:
    lowered = reply.casefold()
    return any(marker in lowered for marker in LIMIT_MARKERS)


def _menu(mcp: Any, names: tuple[str, ...] = MENU_TOOLS) -> list[dict[str, Any]]:
    by_name = {tool["name"]: tool for tool in mcp._public_tools}
    return [by_name[name] for name in names if name in by_name]


def grounding_block(mcp: Any, message: str) -> tuple[str, list[dict[str, Any]]]:
    """Two route-selected calls rendered into a compact facts block.

    Genre of _grounding_facts_block (hermes/app/routes/logic.py:382-425):
    every line names its source; an empty retrieval says so.
    """
    rows: list[dict[str, Any]] = []
    lines: list[str] = []

    started = time.time()
    args_a: dict[str, Any] = {"content": message}
    payload_a, class_a = execute_tool(mcp, "commitment_match", args_a)
    rows.append(_call_row("commitment_match", "route", args_a, executed=True,
                          response_class=class_a, payload=payload_a,
                          elapsed_ms=int((time.time() - started) * 1000)))
    if class_a == "result":
        value = payload_a.get("result")
        lines.append("- commitment_match: " + json.dumps(value, ensure_ascii=False)[:400])

    started = time.time()
    args_b: dict[str, Any] = {"query": content_words(message), "k": 5}
    payload_b, class_b = execute_tool(mcp, "misconception_search_rows", args_b)
    rows.append(_call_row("misconception_search_rows", "route", args_b, executed=True,
                          response_class=class_b, payload=payload_b,
                          elapsed_ms=int((time.time() - started) * 1000)))
    if class_b == "result":
        value = payload_b.get("result") or {}
        found = value.get("rows") or []
        parts = []
        for row in found[:5]:
            if isinstance(row, dict):
                parts.append(f"{row.get('name')} ({row.get('domain')})")
        if parts:
            lines.append("- misconception_search_rows: " + "; ".join(parts))

    if lines:
        block = ("KNOWLEDGE-BASE FACTS (each line names its source tool; "
                 "ground the reply in these and invent nothing):\n" + "\n".join(lines))
    else:
        block = ("KNOWLEDGE-BASE FACTS: the knowledge base returned nothing "
                 "for this message.")
    return block, rows


def offline_answer(block: str) -> str:
    """Genre of _offline_chat_answer (hermes/app/routes/logic.py:446): the
    retrieval itself, naming its own boundary."""
    return ("The local model is not running, so this answer is the "
            "knowledge-base retrieval itself rather than prose about it.\n" + block)


def _abstention_sentence(tool: str) -> str:
    return (f"The knowledge base holds no entry for this ask: {tool} returned "
            "nothing, so there is no ground for an answer here.")


def _refusal_sentence(tool: str, payload: dict[str, Any]) -> str:
    message = ""
    error = payload.get("error")
    if isinstance(error, dict):
        message = str(error.get("message", ""))[:200]
    return (f"{tool} did not accept the request"
            + (f": {message}" if message else ".")
            + " Nothing was checked, so nothing is claimed.")


def _first_menu_call(result: ClientResult) -> tuple[str, dict[str, Any]] | None:
    for call in result.tool_calls():
        function = call.get("function") or {}
        name = function.get("name")
        arguments = function.get("arguments")
        if isinstance(name, str) and isinstance(arguments, dict):
            return name, arguments
    return None


def run_turn(
    message: str,
    mode: str,
    complete: Completer,
    mcp: Any,
    prompts: Mapping[str, str],
    strategy_names: frozenset[str],
    history: Sequence[Mapping[str, Any]] | None = None,
) -> TurnResult:
    started = time.time()
    if mode not in {"routed", "model"}:
        mode = "routed"
    try:
        if mode == "routed":
            result = _run_routed(
                message, complete, mcp, prompts, strategy_names, window_history(history)
            )
        else:
            result = _run_model_chooses(
                message, complete, mcp, prompts, window_history(history)
            )
    except _ModelOffline as offline:
        if mode == "routed":
            result = _run_offline_routed(
                message, mcp, strategy_names, offline.kind, offline.detail, offline.calls
            )
        else:
            result = TurnResult(
                reply=("The local model is offline, so model-decides mode cannot "
                       "answer this message."),
                mode=mode,
                chooser="none",
                route=None,
                calls=list(offline.calls),
                fallback={"kind": offline.kind, "detail": offline.detail},
            )
    result.timing["total_ms"] = int((time.time() - started) * 1000)
    return result


def _run_offline_routed(
    message: str,
    mcp: Any,
    strategy_names: frozenset[str],
    offline_kind: str,
    offline_detail: str,
    prior_calls: list[dict[str, Any]],
) -> TurnResult:
    route = route_message(message, strategy_names)
    if route is None:
        return TurnResult(
            reply=("The local model is offline, and no deterministic route "
                   "matches this message."),
            mode="routed",
            chooser="none",
            route=None,
            calls=list(prior_calls),
            fallback={"kind": offline_kind, "detail": offline_detail},
        )
    tool = str(route["tool"])
    arguments = route.get("arguments")
    if not isinstance(arguments, dict):
        return TurnResult(
            reply=("The local model is offline, and this deterministic route "
                   "cannot form the required inputs from the message."),
            mode="routed",
            chooser="route",
            route={"intent": str(route["intent"]), "tool": tool},
            calls=list(prior_calls),
            fallback={"kind": offline_kind, "detail": offline_detail},
        )
    turn = TurnResult(
        reply="",
        mode="routed",
        chooser="route",
        route={"intent": str(route["intent"]), "tool": tool},
        calls=[row for row in prior_calls
               if not (row.get("executed") and row.get("tool") == tool)],
        fallback={"kind": offline_kind, "detail": offline_detail},
    )
    exec_started = time.time()
    payload, response_class = execute_tool(mcp, tool, arguments)
    turn.calls.append(_call_row(
        tool, "route", arguments, executed=True,
        response_class=response_class, payload=payload,
        elapsed_ms=int((time.time() - exec_started) * 1000),
    ))
    _remember_drawing(turn, tool, payload)
    if response_class == "result":
        names = {
            "monitoring_chart": "the lesson monitoring chart",
            "lesson_deformation_chart": "the lesson deformation chart",
            "deformation_compare": "the representation and its deformation",
            "fraction_comparison_compare": "the fraction comparison and its deformation",
        }
        subject = names.get(tool, f"the {tool.replace('_', ' ')} result")
        turn.reply = (f"I returned {subject}. This used a deterministic route; "
                      "the local model is not running.")
    elif response_class == "abstention":
        turn.reply = _abstention_sentence(tool) + " The model is offline."
    else:
        turn.reply = _refusal_sentence(tool, payload) + " The model is offline."
    return turn


class _ModelOffline(Exception):
    def __init__(self, kind: str, detail: str, calls: list[dict[str, Any]]) -> None:
        super().__init__(detail)
        self.kind = kind
        self.detail = detail
        self.calls = calls


def _completed(
    complete: Completer,
    messages: list[dict[str, Any]],
    tools: list[dict[str, Any]] | None,
    max_tokens: int,
    calls_so_far: list[dict[str, Any]],
) -> ClientResult:
    result = complete(messages, tools, max_tokens)
    if result.outcome == "transport_error":
        raise _ModelOffline("model_offline", result.error or "transport error", calls_so_far)
    if result.outcome == "http_error":
        raise _ModelOffline("model_error", result.error or "http error", calls_so_far)
    return result


def _finalize(
    turn: TurnResult,
    complete: Completer,
    conversation: list[dict[str, Any]],
    worst_class: str | None,
) -> TurnResult:
    """One bounded final call, then the safety filter."""
    final = _completed(complete, conversation, None, MAX_TOKENS_FINAL, turn.calls)
    reply = final.content().strip()
    if worst_class == "abstention" and not states_limit(reply):
        turn.rejected_reply = reply or None
        executed = [row for row in turn.calls if row["executed"]]
        tool = executed[-1]["tool"] if executed else "the consultation"
        turn.reply = _abstention_sentence(tool)
        turn.fallback = {"kind": "abstention_unstated",
                         "detail": "the reply stated no limit after an abstention"}
        return turn
    if not reply_is_safe(reply, worst_class):
        turn.rejected_reply = reply or None
        executed = [row for row in turn.calls if row["executed"]]
        if executed and executed[-1]["response_class"] == "result":
            turn.reply = (f"{executed[-1]['tool']} returned a finding; the panel "
                          "beside this reply carries it in full.")
        elif executed and executed[-1]["response_class"] == "refusal":
            turn.reply = _refusal_sentence(executed[-1]["tool"], {})
        elif executed:
            turn.reply = _abstention_sentence(executed[-1]["tool"])
        else:
            turn.reply = ("No reply cleared the filter and no consultation ran; "
                          "there is nothing to report for this turn.")
        turn.fallback = {"kind": "reply_unsafe",
                         "detail": "the model reply failed the safety filter"}
        return turn
    turn.reply = reply
    return turn


def _tool_message(call_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    return {"role": "tool", "tool_call_id": call_id,
            "content": json.dumps(payload, ensure_ascii=False, sort_keys=True)}


def _run_routed(
    message: str,
    complete: Completer,
    mcp: Any,
    prompts: Mapping[str, str],
    strategy_names: frozenset[str],
    history: list[dict[str, str]],
) -> TurnResult:
    system = prompts["sidekick_routed.md"]
    route = route_message(message, strategy_names)
    turn = TurnResult(reply="", mode="routed",
                      chooser="route" if route else "none",
                      route=({"intent": route["intent"], "tool": route["tool"]}
                             if route else None))

    if route is None:
        block, rows = grounding_block(mcp, message)
        turn.calls.extend(rows)
        turn.fallback = {"kind": "no_route",
                         "detail": "no deterministic route matched this message"}
        conversation = [
            {"role": "system", "content": system},
            *history,
            {"role": "user", "content": f"{message}\n\n{block}"},
        ]
        return _finalize(turn, complete, conversation, None)

    tool = route["tool"]
    menu = _menu(mcp, (tool,))
    parsed_arguments = json.dumps(route.get("arguments", {}), ensure_ascii=False, sort_keys=True)
    mandate = (f"For this message, call {tool} now. {route['hint']}. "
               f"The deterministic parse produced these candidate arguments: {parsed_arguments}. "
               "Draw every argument only from the teacher's words.")
    conversation: list[dict[str, Any]] = [
        {"role": "system", "content": f"{system}\n\n{mandate}"},
        *history,
        {"role": "user", "content": message},
    ]

    emitted: tuple[str, dict[str, Any]] | None = None
    last_result: ClientResult | None = None
    for attempt in range(2):
        result = _completed(complete, conversation, menu, MAX_TOKENS_FORMULATION, turn.calls)
        last_result = result
        candidate = _first_menu_call(result)
        if candidate and candidate[0] == tool:
            emitted = candidate
            break
        if attempt == 0:
            wrong = candidate[0] if candidate else None
            correction = (f"Call {tool}, not {wrong}." if wrong
                          else f"No call was made. Call {tool} now with arguments "
                               "drawn from the teacher's words.")
            conversation.append(assistant_echo(result.message))
            conversation.append({"role": "user", "content": correction})

    if emitted is None:
        block, rows = grounding_block(mcp, message)
        turn.calls.extend(rows)
        turn.fallback = {"kind": "no_call",
                         "detail": f"the model made no {tool} call in two attempts"}
        conversation = [
            {"role": "system", "content": system},
            *history,
            {"role": "user", "content": f"{message}\n\n{block}"},
        ]
        return _finalize(turn, complete, conversation, None)

    name, arguments = emitted
    call_id = "call_0"
    exec_started = time.time()
    payload, response_class = execute_tool(mcp, name, arguments)
    turn.calls.append(_call_row(name, "route", arguments, executed=True,
                                response_class=response_class, payload=payload,
                                elapsed_ms=int((time.time() - exec_started) * 1000)))
    _remember_drawing(turn, name, payload)

    if response_class == "refusal":
        error = payload.get("error") or {}
        correction = (f"That call was rejected: {error.get('message', 'invalid arguments')}. "
                      f"Call {tool} again with corrected arguments.")
        conversation.append(assistant_echo(last_result.message))
        conversation.append(_tool_message(call_id, payload))
        conversation.append({"role": "user", "content": correction})
        retry = _completed(complete, conversation, menu, MAX_TOKENS_FORMULATION, turn.calls)
        candidate = _first_menu_call(retry)
        if candidate and candidate[0] == tool:
            name2, arguments2 = candidate
            exec_started = time.time()
            payload2, response_class2 = execute_tool(mcp, name2, arguments2)
            turn.calls.append(_call_row(name2, "route", arguments2, executed=True,
                                        response_class=response_class2, payload=payload2,
                                        elapsed_ms=int((time.time() - exec_started) * 1000)))
            turn.drawings.clear()
            _remember_drawing(turn, name2, payload2)
            if response_class2 == "refusal":
                turn.fallback = {"kind": "refusal_after_retry",
                                 "detail": "both calls were rejected by the tool"}
                turn.reply = _refusal_sentence(tool, payload2)
                return turn
            payload, response_class = payload2, response_class2
            last_result = retry
        else:
            turn.fallback = {"kind": "refusal_after_retry",
                             "detail": "the corrected call never arrived"}
            turn.reply = _refusal_sentence(tool, payload)
            return turn

    conversation = [
        {"role": "system", "content": system},
        *history,
        {"role": "user", "content": message},
        assistant_echo(last_result.message),
        _tool_message(call_id, payload),
    ]
    return _finalize(turn, complete, conversation, response_class)


def _run_model_chooses(
    message: str,
    complete: Completer,
    mcp: Any,
    prompts: Mapping[str, str],
    history: list[dict[str, str]],
) -> TurnResult:
    system = prompts["sidekick_menu.md"]
    menu = _menu(mcp)
    turn = TurnResult(reply="", mode="model", chooser="model", route=None)
    conversation: list[dict[str, Any]] = [
        {"role": "system", "content": system},
        *history,
        {"role": "user", "content": message},
    ]

    first = _completed(complete, conversation, menu, MAX_TOKENS_FINAL, turn.calls)
    emitted = first.tool_calls()
    if not emitted:
        turn.flags.append("model_declined_consult")
        reply = first.content().strip()
        if reply_is_safe(reply, None) and reply:
            turn.reply = reply
            return turn
        turn.rejected_reply = reply or None
        turn.reply = ("The model wrote no usable reply and chose no consultation "
                      "for this turn.")
        turn.fallback = {"kind": "reply_unsafe",
                         "detail": "the model reply failed the safety filter"}
        return turn

    executed_payloads: list[tuple[str, dict[str, Any]]] = []
    worst_class: str | None = None
    menu_names = {tool["name"] for tool in menu}
    for index, call in enumerate(emitted):
        function = call.get("function") or {}
        name = str(function.get("name") or "")
        arguments = function.get("arguments")
        arguments = arguments if isinstance(arguments, dict) else {"__unparsed__": arguments}
        if index >= 2:
            turn.calls.append(_call_row(name, "model", arguments, executed=False,
                                        dropped_reason="round_bound"))
            continue
        if name not in menu_names:
            payload = {"ok": False, "error": {"type": "off_menu",
                                              "message": f"{name} is not on the menu"}}
            turn.calls.append(_call_row(name, "model", arguments, executed=True,
                                        response_class="refusal", payload=payload))
            executed_payloads.append((f"call_{index}", payload))
            worst_class = worst_class or "refusal"
            continue
        exec_started = time.time()
        payload, response_class = execute_tool(mcp, name, arguments)
        turn.calls.append(_call_row(name, "model", arguments, executed=True,
                                    response_class=response_class, payload=payload,
                                    elapsed_ms=int((time.time() - exec_started) * 1000)))
        _remember_drawing(turn, name, payload)
        executed_payloads.append((f"call_{index}", payload))
        order = {"refusal": 2, "abstention": 1, "result": 0}
        if worst_class is None or order[response_class] > order.get(worst_class, 0):
            worst_class = response_class

    conversation.append(assistant_echo(first.message))
    for call_id, payload in executed_payloads:
        conversation.append(_tool_message(call_id, payload))

    final = _completed(complete, conversation, menu, MAX_TOKENS_FINAL, turn.calls)
    late_calls = final.tool_calls()
    if late_calls:
        for call in late_calls:
            function = call.get("function") or {}
            arguments = function.get("arguments")
            turn.calls.append(_call_row(
                str(function.get("name") or ""), "model",
                arguments if isinstance(arguments, dict) else {"__unparsed__": arguments},
                executed=False, dropped_reason="call_after_bound"))
        block, rows = grounding_block(mcp, message)
        turn.calls.extend(rows)
        turn.fallback = {"kind": "call_after_bound",
                         "detail": "the model called past the two-round bound"}
        turn.reply = offline_answer(block).replace(
            "The local model is not running, so this", "The turn passed its round bound, so this")
        return turn

    reply = final.content().strip()
    if worst_class == "abstention" and not states_limit(reply):
        turn.rejected_reply = reply or None
        executed = [row for row in turn.calls if row["executed"]]
        turn.reply = _abstention_sentence(executed[-1]["tool"] if executed else "the consultation")
        turn.fallback = {"kind": "abstention_unstated",
                         "detail": "the reply stated no limit after an abstention"}
        return turn
    if not reply_is_safe(reply, worst_class):
        turn.rejected_reply = reply or None
        turn.reply = ("The model reply did not clear the filter; the panel beside "
                      "this turn carries every consultation in full.")
        turn.fallback = {"kind": "reply_unsafe",
                         "detail": "the model reply failed the safety filter"}
        return turn
    turn.reply = reply
    return turn
