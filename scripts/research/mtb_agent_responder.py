#!/usr/bin/env python3
"""Tool-calling tutoring responder for MathTutorBench generation tasks."""
from __future__ import annotations

import atexit
from collections import Counter
import json
from pathlib import Path
import re
import sys
import time
from typing import Any, Callable
import urllib.error
import urllib.request

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from hermes.app.worker import PersistentPrologError, PersistentPrologWorker
import mtb_responders

CHAT_ENDPOINT = "http://localhost:11434/api/chat"
MAX_TOOL_ROUNDS = 4
MAX_MODEL_CALLS = 6
SUPPORTED_TASKS = {
    "scaffolding_generation",
    "scaffolding_generation_hard",
    "pedagogy_following",
    "pedagogy_following_hard",
}

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "check_math_claim",
            "description": (
                "Check one explicit arithmetic relation stated in the problem "
                "or dialogue. It returns a verdict and narrated trace, or says "
                "plainly that no complete relation was checkable."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "term": {
                        "type": "string",
                        "description": (
                            "The complete arithmetic claim as stated, such as "
                            "5+3=9."
                        ),
                    }
                },
                "required": ["term"],
                "additionalProperties": False,
            },
        },
    },
    {
        "type": "function",
        "function": {
            "name": "pedagogical_questions",
            "description": (
                "Find authored assessing and advancing questions for the "
                "student's mathematics. Use a concise topic phrase, an exact "
                "automaton state, or an exact standard. An empty match is an "
                "abstention; do not claim that it supplied a question."
            ),
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": (
                            "A concise mathematical topic or concept phrase, "
                            "named automaton state, or standard."
                        ),
                    },
                    "kind": {
                        "type": "string",
                        "enum": ["topic", "automaton_state", "standard"],
                        "description": "The admission rule to use.",
                    },
                },
                "required": ["query"],
                "additionalProperties": False,
            },
        },
    },
]

BASE_SYSTEM = """You write the next tutor turn for an elementary mathematics
dialogue. You may ask the available functions to check an explicit arithmetic
claim or retrieve authored teacher questions when either would help. A function
may abstain; if it does, answer from the problem and dialogue without pretending
that it supplied evidence.

Your final turn must have one or two short sentences and exactly one question
mark. Acknowledge a specific productive part when the dialogue supports one,
then ask one focused question that leaves the calculation to the student. Do
not state or confirm the answer. Do not mention functions, tools, retrieval,
internal reasoning, or hidden processes. Avoid generic praise. Return only the
tutor turn."""

# Offering the functions is not enough. Over six items, with the functions
# identical and only the wording changed: a plain tutoring prompt called them
# 0/6, "two tools are available, use them when they would help" also called
# them 0/6, and "before replying, check the arithmetic and look up what a
# teacher asks; do not rely on memory" called them 6/6. The checkpoint can
# call a function and will not decide that it needs one — it has the capacity
# without the disposition. So the consultation is either mandated or it does
# not happen, and `agent_tutor_mandated` is the arm that mandates it.
MANDATED_CONSULT = """
Before you reply, do both of these. Check any explicit arithmetic the student
wrote with check_math_claim, and look up what a teacher asks about this
mathematics with pedagogical_questions. Do not rely on memory for either. If a
function abstains, say nothing that pretends it answered."""

SCAFFOLDING_FRAME = (
    "Respond as an experienced teacher who is useful and caring while keeping "
    "the mathematical work with the student."
)
PEDAGOGY_FRAME = (
    "Respond as a friendly tutor who poses one question for the next "
    "incremental step."
)

_INTERNAL = re.compile(
    r"\b(?:analysis|ledger|prolog|retrieval|tool(?:s| call)?|function call)\b",
    re.IGNORECASE,
)
_ANSWER_STYLE = re.compile(
    r"(?:\b(?:final\s+answer|answer|result|total)\s*(?:is|=)|"
    r"\b(?:equals|makes|gives|gets|reaches)\s+[-+]?\d|"
    r"[-+]?\d+(?:\.\d+)?\s*=\s*[-+]?\d)",
    re.IGNORECASE,
)
_PUFFERY = re.compile(
    r"\b(?:wonderful|amazing|fantastic|excellent|awesome|brilliant|"
    r"great job|good job|nice work|very thoughtful|perfect)\b",
    re.IGNORECASE,
)


def _sentence_count(reply: str) -> int:
    return len([
        part for part in re.split(r"(?<=[.!?])\s+", reply.strip())
        if part.strip()
    ])


def _reply_is_safe(reply: str) -> bool:
    sentence_count = _sentence_count(reply)
    return bool(
        reply.strip()
        and reply.count("?") == 1
        and 1 <= sentence_count <= 2
        and len(re.findall(r"\b\w+\b", reply)) <= 60
        and "\n" not in reply.strip()
        and not _INTERNAL.search(reply)
        and not _ANSWER_STYLE.search(reply)
        and not _PUFFERY.search(reply)
    )


def _fallback(task_name: str) -> str:
    if task_name.startswith("pedagogy_following"):
        return (
            "You connected the quantities in a useful way. "
            "Which relationship can you check next?"
        )
    return (
        "You named quantities that matter to the problem. "
        "Which relationship should you check first?"
    )


def _tool_arguments(call: dict[str, Any]) -> dict[str, Any]:
    arguments = call.get("function", {}).get("arguments", {})
    if isinstance(arguments, dict):
        return arguments
    if isinstance(arguments, str):
        try:
            parsed = json.loads(arguments)
        except json.JSONDecodeError:
            return {}
        return parsed if isinstance(parsed, dict) else {}
    return {}


def _checked_equations(report: dict[str, Any]) -> list[dict[str, Any]]:
    checked: list[dict[str, Any]] = []
    for step in report.get("steps", []):
        for equation in step.get("equations", []):
            verdict = equation.get("verdict")
            if verdict not in {"holds", "refuted"}:
                continue
            checked.append({
                "claim": equation.get("span", ""),
                "verdict": verdict,
                "trace": equation.get("trace", []),
            })
    return checked


class AgentTutorResponder:
    """Bounded Ollama chat loop backed by one persistent Prolog worker."""

    def __init__(self, model: str, **options: str) -> None:
        self.model = model
        self.endpoint = options.get("endpoint", CHAT_ENDPOINT)
        self.num_predict = int(options.get("num_predict", "1024"))
        self.ollama_timeout = float(options.get("ollama_timeout", "600"))
        self.worker_timeout = float(options.get("worker_timeout", "120"))
        self.mandate_consultation = options.get(
            "mandate_consultation", "0") not in {"0", "", "false", "False"}
        self.worker: PersistentPrologWorker | None = None
        self.stats: Counter[str] = Counter()
        self.item_records: list[dict[str, Any]] = []
        self.total_seconds = 0.0
        self._closed = False

    def _worker(self) -> PersistentPrologWorker:
        if self.worker is None:
            self.worker = PersistentPrologWorker(timeout=self.worker_timeout)
        return self.worker

    def _chat(
        self,
        messages: list[dict[str, Any]],
        tools: list[dict[str, Any]],
        item: Counter[str],
    ) -> dict[str, Any]:
        if item["model_calls"] >= MAX_MODEL_CALLS:
            raise RuntimeError("model call bound reached")
        payload = json.dumps({
            "model": self.model,
            "messages": messages,
            "tools": tools,
            "stream": False,
            "options": {
                "temperature": 0.0,
                "num_predict": self.num_predict,
            },
        }).encode("utf-8")
        request = urllib.request.Request(
            self.endpoint,
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        item["model_calls"] += 1
        self.stats["model_calls"] += 1
        started = time.time()
        try:
            with urllib.request.urlopen(
                    request, timeout=self.ollama_timeout) as response:
                body = json.loads(response.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError,
                OSError) as exc:
            self.stats["model_failures"] += 1
            item["model_failures"] += 1
            raise RuntimeError(f"ollama chat failed: {exc}") from exc
        finally:
            elapsed = time.time() - started
            self.stats["model_seconds_millis"] += round(elapsed * 1000)
            item["model_seconds_millis"] += round(elapsed * 1000)
        message = body.get("message")
        if not isinstance(message, dict):
            raise RuntimeError("ollama chat returned no assistant message")
        return message

    def _check_math_claim(
        self, arguments: dict[str, Any], item: Counter[str]
    ) -> dict[str, Any]:
        term = arguments.get("term")
        if not isinstance(term, str) or not term.strip():
            item["check_math_claim_abstentions"] += 1
            self.stats["check_math_claim_abstentions"] += 1
            return {
                "status": "abstained",
                "message": (
                    "No non-empty explicit arithmetic claim was supplied, so "
                    "nothing was checked."
                ),
            }
        try:
            report = self._worker().request(
                "check_solution_steps", text=term.strip())
        except (PersistentPrologError, OSError, RuntimeError) as exc:
            item["check_math_claim_failures"] += 1
            self.stats["check_math_claim_failures"] += 1
            return {
                "status": "unavailable",
                "message": f"The arithmetic claim could not be checked: {exc}",
            }
        checks = _checked_equations(report if isinstance(report, dict) else {})
        if not checks:
            item["check_math_claim_abstentions"] += 1
            self.stats["check_math_claim_abstentions"] += 1
            return {
                "status": "abstained",
                "term": term,
                "message": (
                    "No complete explicit arithmetic relation was read and "
                    "checked. Continue without a checked verdict."
                ),
            }
        item["check_math_claim_successes"] += 1
        self.stats["check_math_claim_successes"] += 1
        return {"status": "checked", "term": term, "checks": checks}

    def _pedagogical_questions(
        self, arguments: dict[str, Any], item: Counter[str]
    ) -> dict[str, Any]:
        query = arguments.get("query")
        kind = arguments.get("kind", "topic")
        if (
            not isinstance(query, str)
            or not query.strip()
            or kind not in {"topic", "automaton_state", "standard"}
        ):
            item["pedagogical_questions_abstentions"] += 1
            self.stats["pedagogical_questions_abstentions"] += 1
            return {
                "status": "abstained",
                "message": (
                    "No valid non-empty topic, automaton state, or standard "
                    "query was supplied. Continue without retrieved questions."
                ),
            }
        try:
            result = self._worker().request(
                "pedagogical_questions",
                query=query.strip(),
                kind=kind,
            )
        except (PersistentPrologError, OSError, RuntimeError) as exc:
            item["pedagogical_questions_failures"] += 1
            self.stats["pedagogical_questions_failures"] += 1
            return {
                "status": "unavailable",
                "message": f"Teacher questions could not be retrieved: {exc}",
            }
        matches = result.get("matches", []) if isinstance(result, dict) else []
        if not matches:
            item["pedagogical_questions_abstentions"] += 1
            self.stats["pedagogical_questions_abstentions"] += 1
            result = dict(result) if isinstance(result, dict) else {}
            result.update({
                "status": "abstained",
                "matches": [],
                "message": (
                    "No monitoring-question cluster matched this query. "
                    "Continue without a retrieved teacher question."
                ),
            })
        else:
            item["pedagogical_questions_successes"] += 1
            self.stats["pedagogical_questions_successes"] += 1
        return result

    def _execute_tool(
        self, call: dict[str, Any], item: Counter[str]
    ) -> tuple[str, dict[str, Any]]:
        function = call.get("function", {})
        name = function.get("name", "")
        arguments = _tool_arguments(call)
        item["tool_calls"] += 1
        self.stats["tool_calls"] += 1
        if name == "check_math_claim":
            item["check_math_claim_calls"] += 1
            self.stats["check_math_claim_calls"] += 1
            return name, self._check_math_claim(arguments, item)
        if name == "pedagogical_questions":
            item["pedagogical_questions_calls"] += 1
            self.stats["pedagogical_questions_calls"] += 1
            return name, self._pedagogical_questions(arguments, item)
        item["unknown_tool_calls"] += 1
        self.stats["unknown_tool_calls"] += 1
        return str(name), {
            "status": "unavailable",
            "message": "That function is not available; continue without it.",
        }

    def respond(
        self,
        *,
        prompt: str,
        stop: list[str] | None,
        example: dict[str, Any],
        task_name: str,
    ) -> str:
        del prompt
        started = time.time()
        position = self.stats["items"]
        self.stats["items"] += 1
        item: Counter[str] = Counter()
        final_source = "fallback"
        try:
            if task_name not in SUPPORTED_TASKS:
                self.stats["task_mismatches"] += 1
                item["task_mismatch"] += 1
                return ""
            question = example.get("question")
            dialogue = example.get("dialog_history")
            if not isinstance(question, str) or not isinstance(dialogue, str):
                self.stats["missing_inputs"] += 1
                item["missing_inputs"] += 1
                return _fallback(task_name)

            framing = (
                PEDAGOGY_FRAME
                if task_name.startswith("pedagogy_following")
                else SCAFFOLDING_FRAME
            )
            system = BASE_SYSTEM + "\n\n" + framing
            if self.mandate_consultation:
                system += "\n" + MANDATED_CONSULT
            messages: list[dict[str, Any]] = [
                {"role": "system", "content": system},
                {
                    "role": "user",
                    "content": (
                        f"Math problem:\n{question}\n\n"
                        f"Dialogue:\n{dialogue}"
                    ),
                },
            ]

            while item["model_calls"] < MAX_MODEL_CALLS:
                available_tools = (
                    TOOLS if item["tool_call_rounds"] < MAX_TOOL_ROUNDS else [])
                message = self._chat(messages, available_tools, item)
                tool_calls = message.get("tool_calls", [])
                if (
                    isinstance(tool_calls, list)
                    and tool_calls
                    and item["tool_call_rounds"] < MAX_TOOL_ROUNDS
                ):
                    item["tool_call_rounds"] += 1
                    self.stats["tool_call_rounds"] += 1
                    messages.append({
                        "role": "assistant",
                        "content": str(message.get("content") or ""),
                        "tool_calls": tool_calls,
                    })
                    for call in tool_calls:
                        if not isinstance(call, dict):
                            continue
                        tool_name, result = self._execute_tool(call, item)
                        messages.append({
                            "role": "tool",
                            "tool_name": tool_name,
                            "content": json.dumps(
                                result, ensure_ascii=False, sort_keys=True),
                        })
                    continue

                reply = mtb_responders.truncate_at_stop(
                    str(message.get("content") or ""), stop).strip()
                if _reply_is_safe(reply):
                    final_source = "model"
                    self.stats["safe_model_replies"] += 1
                    return reply

                item["repair_requests"] += 1
                self.stats["repair_requests"] += 1
                messages.append({
                    "role": "assistant",
                    "content": str(message.get("content") or ""),
                })
                messages.append({
                    "role": "user",
                    "content": (
                        "Revise the tutor turn to one or two short sentences "
                        "with exactly one question mark. Do not state an answer "
                        "or mention internal processes. Return only the turn."
                    ),
                })

            item["fallbacks"] += 1
            self.stats["fallbacks"] += 1
            return _fallback(task_name)
        except RuntimeError:
            item["fallbacks"] += 1
            self.stats["fallbacks"] += 1
            return _fallback(task_name)
        finally:
            elapsed = time.time() - started
            self.total_seconds += elapsed
            cluster_success = item["pedagogical_questions_successes"] > 0
            if cluster_success:
                self.stats["items_with_successful_cluster_lookup"] += 1
            record = {
                "position": position,
                "task": task_name,
                "seconds": round(elapsed, 3),
                "model_calls": item["model_calls"],
                "tool_call_rounds": item["tool_call_rounds"],
                "tool_calls": item["tool_calls"],
                "check_math_claim_calls": item["check_math_claim_calls"],
                "check_math_claim_abstentions":
                    item["check_math_claim_abstentions"],
                "pedagogical_questions_calls":
                    item["pedagogical_questions_calls"],
                "pedagogical_questions_abstentions":
                    item["pedagogical_questions_abstentions"],
                "successful_cluster_lookup": cluster_success,
                "final_source": final_source,
            }
            self.item_records.append(record)
            print(
                "MTB_AGENT_ITEM " + json.dumps(record, sort_keys=True),
                file=sys.stderr,
                flush=True,
            )

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        if self.worker is not None:
            self.worker.close()
        items = self.stats["items"]
        summary: dict[str, Any] = {
            "arm": "agent_tutor",
            "model": self.model,
            **dict(sorted(self.stats.items())),
            "calls_per_item": (
                round(self.stats["model_calls"] / items, 3) if items else 0.0
            ),
            "seconds_per_item": (
                round(self.total_seconds / items, 3) if items else 0.0
            ),
            "item_records": self.item_records,
        }
        print(
            "MTB_AGENT_STATS " + json.dumps(summary, sort_keys=True),
            file=sys.stderr,
        )


def _builder(model: str, **options: str) -> mtb_responders.Responder:
    responder = AgentTutorResponder(model, **options)
    atexit.register(responder.close)
    return responder.respond


def _mandated_builder(model: str, **options: str) -> mtb_responders.Responder:
    responder = AgentTutorResponder(model, mandate_consultation="1", **options)
    atexit.register(responder.close)
    return responder.respond


mtb_responders.register("agent_tutor", _builder)
mtb_responders.register("agent_tutor_mandated", _mandated_builder)
