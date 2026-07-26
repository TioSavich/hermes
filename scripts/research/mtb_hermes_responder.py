#!/usr/bin/env python3
"""Hermes-assisted responders for the four MathTutorBench arithmetic tasks.

One model solve is cached by problem text for the lifetime of this process.
The solve's explicit equations are checked by the persistent Prolog worker
before task-specific responders consume it. The cache and all counters are
process-local.
"""
from __future__ import annotations

import atexit
from collections import Counter
from decimal import Decimal, InvalidOperation
import json
from pathlib import Path
import re
import sys
from typing import Any, Callable, TypedDict

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from hermes.app.worker import PersistentPrologError, PersistentPrologWorker
import mtb_responders


SOLVE_PROMPT = """Solve this elementary math word problem carefully.

First decide exactly what quantity the question asks for. Then give a short,
numbered solution using this format:

Step 1 - <reasoning with a complete arithmetic equation>
Step 2 - <reasoning with a complete arithmetic equation>
Final Answer: <one numeric value>

Use as many numbered steps as needed. State each calculation as a complete
numeric equation so it can be checked. Put the equation at the end of its step
line, with no punctuation after the result. Do not add a new problem or
question. Return only the solution.

Problem:
{problem}
"""

REPAIR_PROMPT = """Revise the solution to this elementary math word problem.
An arithmetic checker refuted the quoted calculation below. Reconsider the
problem's quantities and every calculation, then return a complete replacement
in the required format.

Required format:
Step 1 - <reasoning with a complete arithmetic equation>
Step 2 - <reasoning with a complete arithmetic equation>
Final Answer: <one numeric value>

Put each equation at the end of its step line, with no punctuation after the
result.

Problem:
{problem}

Previous solution:
{chain}

Refuted calculation and checker trace:
{refutation}

Return only the replacement solution.
"""

LOCATION_PROMPT = """Compare the student's numbered solution with the checked
solution to the same problem. Return the number of the earliest student step
that departs from the checked solution. Return one integer and nothing else.

Problem:
{problem}

Checked solution:
{chain}

Student solution:
{student_solution}
"""

_NUMBER_CORE = r"-?(?:\d{1,3}(?:,\d{3})+|\d+)(?:\.\d+)?"
_FINAL_ANSWER = re.compile(
    rf"final\s+answer\s*:\s*(?:[$£€]\s*)?(?P<number>{_NUMBER_CORE})",
    re.IGNORECASE,
)
_ANY_NUMBER = re.compile(rf"(?<![\w.])(?:[$£€]\s*)?(?P<number>{_NUMBER_CORE})")
_STEP_NUMBER = re.compile(r"\bstep\s+(\d+)\b", re.IGNORECASE)


class SolveResult(TypedDict):
    answer: str | None
    chain: str
    report: dict[str, Any] | None
    status: str


def _extract_answer(text: str) -> tuple[str | None, str]:
    explicit = list(_FINAL_ANSWER.finditer(text))
    if explicit:
        return explicit[-1].group("number").replace(",", ""), "explicit"
    numbers = list(_ANY_NUMBER.finditer(text))
    if numbers:
        return numbers[-1].group("number").replace(",", ""), "fallback"
    return None, "missing"


def _answers_agree(left: str, right: str) -> bool:
    try:
        return Decimal(left) == Decimal(right)
    except InvalidOperation:
        return left.strip() == right.strip()


def _refutation_text(report: dict[str, Any]) -> str:
    first = report.get("first_refuted_step")
    details: list[dict[str, Any]] = []
    for step in report.get("steps", []):
        if step.get("verdict") != "refuted":
            continue
        for equation in step.get("equations", []):
            if equation.get("verdict") == "refuted":
                details.append({
                    "step": step.get("index"),
                    "span": equation.get("span", ""),
                    "trace": equation.get("trace", []),
                })
    return json.dumps(
        {"first_refuted_step": first, "refuted_equations": details},
        ensure_ascii=False,
    )


def _student_step_numbers(text: str) -> set[int]:
    normalized = text.replace("\\n", "\n")
    explicit = {int(value) for value in _STEP_NUMBER.findall(normalized)}
    if explicit:
        return explicit
    lines = [line for line in normalized.splitlines() if line.strip()]
    return set(range(1, len(lines) + 1))


def _without_final_answer(chain: str) -> str:
    kept = [
        line for line in chain.splitlines()
        if not _FINAL_ANSWER.search(line)
    ]
    return "\n".join(kept).strip()


class HermesResponder:
    """Process-local solver, Prolog guard, and one task arm."""

    def __init__(self, model: str, arm: str, **options: str) -> None:
        self.model = model
        self.arm = arm
        self.endpoint = options.get(
            "endpoint", mtb_responders.DEFAULT_ENDPOINT)
        self.num_predict = int(options.get("num_predict", "1024"))
        self.ollama_timeout = float(options.get("ollama_timeout", "600"))
        self.worker_timeout = float(options.get("worker_timeout", "60"))
        self.cache: dict[str, SolveResult] = {}
        self.worker: PersistentPrologWorker | None = None
        self.stats: Counter[str] = Counter()
        self._closed = False

    def _complete(self, prompt: str, purpose: str) -> str:
        self.stats["model_calls"] += 1
        self.stats[f"{purpose}_model_calls"] += 1
        return mtb_responders.ollama_complete(
            prompt,
            model=self.model,
            stop=None,
            endpoint=self.endpoint,
            num_predict=self.num_predict,
            timeout=self.ollama_timeout,
            stop_mode="post",
        )

    def _adjudicate(self, chain: str) -> dict[str, Any]:
        if self.worker is None:
            self.worker = PersistentPrologWorker(timeout=self.worker_timeout)
        self.stats["prolog_reports"] += 1
        report = self.worker.request("check_solution_steps", text=chain)
        if not isinstance(report, dict):
            raise PersistentPrologError(
                "check_solution_steps returned no report")
        if int(report.get("checked_equations", 0)):
            self.stats["prolog_reports_with_checks"] += 1
        self.stats["checked_equations"] += int(
            report.get("checked_equations", 0))
        self.stats["refuted_equations"] += int(
            report.get("refuted_equations", 0))
        return report

    def solve(self, problem: str) -> SolveResult:
        cached = self.cache.get(problem)
        if cached is not None:
            self.stats["solve_cache_hits"] += 1
            return cached

        self.stats["unique_problems"] += 1
        try:
            chain = self._complete(
                SOLVE_PROMPT.format(problem=problem), "solve")
            report = self._adjudicate(chain)
        except (RuntimeError, PersistentPrologError, OSError) as exc:
            self.stats["solve_failures"] += 1
            result: SolveResult = {
                "answer": None,
                "chain": "",
                "report": None,
                "status": f"solve_or_check_failed_{type(exc).__name__}",
            }
            self.cache[problem] = result
            return result

        if int(report.get("refuted_equations", 0)) > 0:
            self.stats["solves_refuted"] += 1
            try:
                repaired = self._complete(
                    REPAIR_PROMPT.format(
                        problem=problem,
                        chain=chain,
                        refutation=_refutation_text(report),
                    ),
                    "repair",
                )
                repaired_report = self._adjudicate(repaired)
            except (RuntimeError, PersistentPrologError, OSError) as exc:
                self.stats["repair_failures"] += 1
                result = {
                    "answer": None,
                    "chain": chain,
                    "report": report,
                    "status": f"repair_or_check_failed_{type(exc).__name__}",
                }
                self.cache[problem] = result
                return result

            if int(repaired_report.get("refuted_equations", 0)) == 0:
                chain = repaired
                report = repaired_report
                self.stats["repairs_accepted"] += 1
            else:
                self.stats["repairs_rejected"] += 1
                result = {
                    "answer": None,
                    "chain": chain,
                    "report": report,
                    "status": "refuted_after_retry",
                }
                self.cache[problem] = result
                return result

        answer, source = _extract_answer(chain)
        self.stats[f"answer_{source}"] += 1
        result = {
            "answer": answer,
            "chain": chain,
            "report": report,
            "status": "ok" if answer is not None else "answer_unparsed",
        }
        if answer is None:
            self.stats["solve_failures"] += 1
        self.cache[problem] = result
        return result

    def _abstain(self, reason: str, safest: str = "") -> str:
        self.stats["abstentions"] += 1
        self.stats[f"abstain_{reason}"] += 1
        marker = f"HERMES_ABSTAINED: {reason}"
        return f"{safest}\n{marker}".strip()

    def respond(
        self,
        *,
        prompt: str,
        stop: list[str] | None,
        example: dict[str, Any],
        task_name: str,
    ) -> str:
        del prompt, stop
        self.stats["items"] += 1
        expected = {
            "solve": "problem_solving",
            "correctness": "solution_correctness",
            "location": "mistake_location",
            "correction": "mistake_correction",
        }[self.arm]
        if task_name != expected:
            return self._abstain("task_mismatch")

        problem = example.get("question")
        if not isinstance(problem, str) or not problem.strip():
            return self._abstain(
                "missing_problem", "Yes" if self.arm == "correctness"
                else "0" if self.arm == "location" else "")

        solved = self.solve(problem)
        answer = solved["answer"]
        if solved["status"] != "ok" or answer is None:
            safest = (
                "Yes" if self.arm == "correctness"
                else "0" if self.arm == "location"
                else ""
            )
            return self._abstain("solve_failed", safest)

        if self.arm == "solve":
            return f"Final Answer: {answer}"

        student_field = (
            "student_solution" if self.arm == "location"
            else "student_chat_solution"
        )
        student_solution = example.get(student_field)
        if not isinstance(student_solution, str) or not student_solution.strip():
            safest = "Yes" if self.arm == "correctness" else (
                "0" if self.arm == "location" else "")
            return self._abstain("missing_student_solution", safest)

        student_answer, source = _extract_answer(student_solution)
        self.stats[f"student_answer_{source}"] += 1
        if self.arm == "correction":
            body = _without_final_answer(solved["chain"])
            if body:
                return f"{body}\nFinal Answer: {answer}"
            return f"Final Answer: {answer}"

        if student_answer is None:
            safest = "Yes" if self.arm == "correctness" else "0"
            return self._abstain("student_answer_unparsed", safest)

        agrees = _answers_agree(student_answer, answer)
        if self.arm == "correctness":
            return "No" if agrees else "Yes"

        if agrees:
            return "0"

        try:
            raw_location = self._complete(
                LOCATION_PROMPT.format(
                    problem=problem,
                    chain=solved["chain"],
                    student_solution=student_solution.replace("\\n", "\n"),
                ),
                "location",
            )
        except RuntimeError:
            return self._abstain("location_call_failed", "0")

        match = re.search(r"\d+", raw_location)
        if not match:
            return self._abstain("location_unparsed", "0")
        candidate = int(match.group())
        if candidate <= 0 or candidate not in _student_step_numbers(
                student_solution):
            return self._abstain("location_out_of_range", "0")
        return str(candidate)

    def close(self) -> None:
        if self._closed:
            return
        self._closed = True
        if self.worker is not None:
            self.worker.close()
        summary = {
            "arm": self.arm,
            "model": self.model,
            **dict(sorted(self.stats.items())),
        }
        print(
            "MTB_HERMES_STATS " + json.dumps(summary, sort_keys=True),
            file=sys.stderr,
        )


def _builder(arm: str) -> Callable[..., mtb_responders.Responder]:
    def build(model: str, **options: str) -> mtb_responders.Responder:
        responder = HermesResponder(model, arm, **options)
        atexit.register(responder.close)
        return responder.respond

    return build


mtb_responders.register("hermes_solve", _builder("solve"))
mtb_responders.register("hermes_correctness", _builder("correctness"))
mtb_responders.register("hermes_location", _builder("location"))
mtb_responders.register("hermes_correction", _builder("correction"))
