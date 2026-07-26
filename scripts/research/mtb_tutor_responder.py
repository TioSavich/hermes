#!/usr/bin/env python3
"""Measured tutoring responders with a private analysis and checked ledger.

Both registered arms use the same two-pass model path. ``tutor_analysis``
leaves the arithmetic ledger empty; ``tutor_ledger`` adds only equations that
the existing Prolog worker adjudicated. The comparison keeps the ledger's
incremental effect separate from the private-analysis and reply constraints.
"""
from __future__ import annotations

import atexit
from collections import Counter
import json
from pathlib import Path
import re
import sys
import time
from typing import Any, Callable

from arith_step_reader import read_steps

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from hermes.app.worker import PersistentPrologError, PersistentPrologWorker
import mtb_responders


ANALYSIS_PROMPT = """Read the math problem, dialogue, and checked arithmetic
ledger as a private analysis pass. Diagnose only what the student's words
support. Preserve a productive part of the student's approach, locate the
earliest divergence or unsupported relationship, and plan one question that
leaves the calculation to the student.

Ledger rows marked holds or refuted are checked facts. A refuted row's trace
may locate an arithmetic divergence. An empty ledger means no explicit
arithmetic was checkable; reason from the dialogue without inventing evidence.
Do not solve the problem or state its answer.

Return one JSON object with exactly these keys:
productive_part, earliest_divergence, next_question, ledger_use.
JSON only.

Problem:
{question}

Dialogue:
{dialogue}

Checked arithmetic ledger:
{ledger}
"""

SCAFFOLDING_REPLY_PROMPT = """You are an experienced math teacher responding
usefully and caringly to a student. Use the private analysis below, but do not
mention the analysis or any internal process.

Write exactly two short sentences. The first acknowledges one specific
productive part of the student's work. The second asks one focused question
about the earliest divergence. Use exactly one question mark. Leave the
calculation to the student. Do not state or confirm the final answer, do not
introduce or repeat a calculated result, and do not use headings, preamble, or
generic praise such as "wonderful," "amazing," or "great job."

Problem:
{question}

Dialogue:
{dialogue}

Private analysis:
{analysis}
"""

PEDAGOGY_REPLY_PROMPT = """You are a friendly, supportive math tutor. Use the
private analysis below to nudge the student through one incremental step, but
do not mention the analysis or any internal process.

Write exactly two short sentences. The first acknowledges one specific
productive part of the student's work. The second asks one focused guiding
question about the earliest divergence. Use exactly one question mark. Leave
the calculation to the student. Do not state or confirm the final answer, do
not introduce or repeat a calculated result, and do not use headings,
preamble, or generic praise such as "wonderful," "amazing," or "great job."

Problem:
{question}

Dialogue:
{dialogue}

Private analysis:
{analysis}
"""

REPAIR_PROMPT = """Revise the tutor turn below so it follows every constraint.
Return only the revised tutor turn.

- Exactly two short sentences.
- Sentence one acknowledges a specific productive part of the student's work.
- Sentence two asks one focused question about the earliest divergence.
- Exactly one question mark.
- No headings, preamble, internal process, calculated result, or final answer.
- No generic or exaggerated praise.
- Leave the calculation to the student.

Task framing:
{framing}

Problem:
{question}

Dialogue:
{dialogue}

Private analysis:
{analysis}

Draft tutor turn:
{draft}
"""

SUPPORTED_TASKS = {
    "scaffolding_generation",
    "scaffolding_generation_hard",
    "pedagogy_following",
    "pedagogy_following_hard",
}
_SAFE_EXPRESSION = re.compile(r"[0-9().+\-*/ ]+\Z")
_SPEAKER = re.compile(r"(?m)^(Teacher|Tutor|Student):\s*")
_INTERNAL = re.compile(
    r"\b(?:analysis|ledger|prolog|retrieval|tool(?:s| call)?)\b",
    re.IGNORECASE,
)
_ANSWER_STYLE = re.compile(
    r"\b(?:final\s+answer|answer|result|total)\s*(?:is|=)|=",
    re.IGNORECASE,
)
_PUFFERY = re.compile(
    r"\b(?:wonderful|amazing|fantastic|excellent|awesome|brilliant|great job)\b",
    re.IGNORECASE,
)


def _last_student(dialogue: str) -> str:
    """Return the final Student turn without Teacher or Tutor text."""
    matches = list(_SPEAKER.finditer(dialogue))
    for position in range(len(matches) - 1, -1, -1):
        match = matches[position]
        if match.group(1) != "Student":
            continue
        end = matches[position + 1].start() if position + 1 < len(matches) else len(dialogue)
        return dialogue[match.end():end].strip()
    return ""


def _prolog_string(value: str) -> str:
    return json.dumps(value, ensure_ascii=True)


def _worker_step_terms(student_turn: str) -> list[str]:
    terms: list[str] = []
    for step in read_steps(student_turn):
        equations: list[str] = []
        for equation in step["equations"]:
            left = equation["left"]
            right = equation["right"]
            if not (_SAFE_EXPRESSION.fullmatch(left)
                    and _SAFE_EXPRESSION.fullmatch(right)):
                continue
            equations.append(
                "equation("
                f"{_prolog_string(equation['span'])},{left},{right}"
                ")"
            )
        terms.append(f"step({step['index']},[{','.join(equations)}])")
    return terms


def _checked_ledger(report: dict[str, Any]) -> list[dict[str, Any]]:
    """Keep only equations for which the worker returned a verdict."""
    ledger: list[dict[str, Any]] = []
    for step in report.get("steps", []):
        for equation in step.get("equations", []):
            verdict = equation.get("verdict")
            if verdict not in {"holds", "refuted"}:
                continue
            ledger.append({
                "step": step.get("index"),
                "claim": equation.get("span", ""),
                "verdict": verdict,
                "trace": equation.get("trace", []),
            })
    return ledger


def _sentence_count(reply: str) -> int:
    return len([
        part for part in re.split(r"(?<=[.!?])\s+", reply.strip())
        if part.strip()
    ])


def _reply_is_safe(reply: str) -> bool:
    return bool(
        reply.strip()
        and reply.count("?") == 1
        and _sentence_count(reply) == 2
        and len(re.findall(r"\b\w+\b", reply)) <= 60
        and not _INTERNAL.search(reply)
        and not _ANSWER_STYLE.search(reply)
        and not _PUFFERY.search(reply)
        and "\n" not in reply.strip()
    )


def _fallback(task_name: str) -> str:
    if task_name.startswith("pedagogy_following"):
        return (
            "You made a useful start by explaining how the quantities relate. "
            "Which relationship can you check first to test your approach?"
        )
    return (
        "You made a useful start by naming the quantities in the problem. "
        "Which relationship in your setup should you check first?"
    )


class TutorResponder:
    """Two-pass tutoring responder with an optional checked arithmetic ledger."""

    def __init__(self, model: str, use_ledger: bool, **options: str) -> None:
        self.model = model
        self.use_ledger = use_ledger
        self.endpoint = options.get(
            "endpoint", mtb_responders.DEFAULT_ENDPOINT)
        self.num_predict = int(options.get("num_predict", "1024"))
        self.ollama_timeout = float(options.get("ollama_timeout", "600"))
        self.worker_timeout = float(options.get("worker_timeout", "60"))
        self.worker: PersistentPrologWorker | None = None
        self.stats: Counter[str] = Counter()
        self.total_seconds = 0.0
        self._closed = False

    def _complete(
        self,
        prompt: str,
        *,
        purpose: str,
        stop: list[str] | None = None,
        num_predict: int | None = None,
    ) -> str:
        self.stats["model_calls"] += 1
        self.stats[f"{purpose}_model_calls"] += 1
        return mtb_responders.ollama_complete(
            prompt,
            model=self.model,
            stop=stop,
            endpoint=self.endpoint,
            num_predict=num_predict or self.num_predict,
            timeout=self.ollama_timeout,
            stop_mode="post",
        )

    def _ledger(self, student_turn: str) -> list[dict[str, Any]]:
        if not self.use_ledger:
            return []
        self.stats["prolog_requests"] += 1
        if self.worker is None:
            self.worker = PersistentPrologWorker(timeout=self.worker_timeout)
        terms = _worker_step_terms(student_turn)
        report = self.worker.request("check_solution_steps", steps=terms)
        if not isinstance(report, dict):
            raise PersistentPrologError(
                "check_solution_steps returned no report")
        checked = int(report.get("checked_equations", 0))
        refuted = int(report.get("refuted_equations", 0))
        self.stats["checked_equations"] += checked
        self.stats["refuted_equations"] += refuted
        if checked:
            self.stats["items_with_adjudication"] += 1
        else:
            self.stats["ledger_abstentions"] += 1
        if refuted:
            self.stats["items_with_refutation"] += 1
        return _checked_ledger(report)

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
        self.stats["items"] += 1
        try:
            if task_name not in SUPPORTED_TASKS:
                self.stats["task_mismatches"] += 1
                return ""
            question = example.get("question")
            dialogue = example.get("dialog_history")
            if not isinstance(question, str) or not isinstance(dialogue, str):
                self.stats["missing_inputs"] += 1
                return _fallback(task_name)

            student_turn = _last_student(dialogue)
            try:
                ledger = self._ledger(student_turn)
            except (PersistentPrologError, OSError, RuntimeError):
                self.stats["prolog_failures"] += 1
                self.stats["ledger_abstentions"] += 1
                ledger = []

            analysis = self._complete(
                ANALYSIS_PROMPT.format(
                    question=question,
                    dialogue=dialogue,
                    ledger=json.dumps(ledger, ensure_ascii=False),
                ),
                purpose="analysis",
            )
            reply_template = (
                PEDAGOGY_REPLY_PROMPT
                if task_name.startswith("pedagogy_following")
                else SCAFFOLDING_REPLY_PROMPT
            )
            reply = self._complete(
                reply_template.format(
                    question=question,
                    dialogue=dialogue,
                    analysis=analysis,
                ),
                purpose="reply",
                stop=stop,
            ).strip()
            if not _reply_is_safe(reply):
                self.stats["repair_attempts"] += 1
                framing = (
                    "friendly tutor giving one incremental nudge"
                    if task_name.startswith("pedagogy_following")
                    else "experienced teacher responding usefully and caringly"
                )
                reply = self._complete(
                    REPAIR_PROMPT.format(
                        framing=framing,
                        question=question,
                        dialogue=dialogue,
                        analysis=analysis,
                        draft=reply,
                    ),
                    purpose="repair",
                    stop=stop,
                ).strip()
            if not _reply_is_safe(reply):
                self.stats["fallbacks"] += 1
                reply = _fallback(task_name)
            return reply
        finally:
            self.total_seconds += time.time() - started

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        if self.worker is not None:
            self.worker.close()
        items = self.stats["items"]
        summary: dict[str, Any] = {
            "arm": "tutor_ledger" if self.use_ledger else "tutor_analysis",
            "model": self.model,
            **dict(sorted(self.stats.items())),
            "seconds_per_item": (
                round(self.total_seconds / items, 3) if items else 0.0
            ),
            "model_calls_per_item": (
                round(self.stats["model_calls"] / items, 3) if items else 0.0
            ),
        }
        print(
            "MTB_TUTOR_STATS " + json.dumps(summary, sort_keys=True),
            file=sys.stderr,
        )


def _builder(use_ledger: bool) -> Callable[..., mtb_responders.Responder]:
    def build(model: str, **options: str) -> mtb_responders.Responder:
        responder = TutorResponder(model, use_ledger, **options)
        atexit.register(responder.close)
        return responder.respond

    return build


mtb_responders.register("tutor_analysis", _builder(False))
mtb_responders.register("tutor_ledger", _builder(True))
