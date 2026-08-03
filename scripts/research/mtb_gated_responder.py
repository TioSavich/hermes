#!/usr/bin/env python3
"""The gated protocol as a mistake_location responder.

Per item: the model transcribes problem and steps into facts with units
(one small question per call), SWI-Prolog derives what the facts license,
and an accusation is emitted ONLY when the corpus gate opens — the
misconception corpus returns ranked rows for the named violation. A
violation without rows, an item without a violation, and an item whose
budget runs out all answer 0. The always-0 floor on this benchmark is
0.500, so the run's information is in the trace, not the headline: every
item records how far it got and which gate closed.

Model calls route through mtb_responders.complete, so the same responder
runs against local Ollama (thinking pinned off per request) and the
cluster's llama-server (thinking turned off at the server flag).
"""
from __future__ import annotations

import json
import threading
from pathlib import Path
from typing import Any

import mtb_responders
from gemma_hermes_protocol import (
    Budget, MCPClient, corpus_gate, extract, run_checker,
    violation_summary)

REPO_ROOT = Path(__file__).resolve().parents[2]


def _prolog_gated(model: str, **options: str) -> mtb_responders.Responder:
    backend = options.get("backend", "ollama")
    endpoint = options.get("endpoint")
    trace_path = options.get("trace")
    budget_cap = int(options.get("budget", 2200))
    max_steps = int(options.get("max_steps", 12))

    trace_lock = threading.Lock()
    client_lock = threading.Lock()
    client_box: dict[str, MCPClient] = {}

    def trace(record: dict[str, Any]) -> None:
        if not trace_path:
            return
        with trace_lock:
            with Path(trace_path).open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record, ensure_ascii=False) + "\n")

    def call_model(prompt: str, budget: Budget,
                   num_predict: int = 256) -> str:
        if budget.exhausted():
            return ""
        num_predict = min(num_predict, budget.remaining())
        reply = mtb_responders.complete(
            prompt, model=model, backend=backend, endpoint=endpoint,
            stop=None, num_predict=num_predict, stop_mode="post",
            **({"think": False} if backend == "ollama" else {}))
        # The ollama route reports eval_count only in its raw body, which
        # complete() does not surface. Word count is an estimate, not a
        # token count, so this responder clamps the next call to the estimate
        # of the remaining budget.
        budget.spent += max(1, len(reply.split()))
        return reply

    class LockedClient:
        """One MCP server shared across worker threads; each tool call
        holds the lock only for its own round trip."""

        def call_tool(self, name: str, arguments: dict) -> str:
            with client_lock:
                if "client" not in client_box:
                    client_box["client"] = MCPClient()
                return client_box["client"].call_tool(name, arguments)

    locked_client = LockedClient()

    def respond(*, prompt: str, stop: list[str] | None,
                example: dict[str, Any], task_name: str) -> str:
        problem = example.get("question", "")
        solution = example.get("student_solution", "")
        steps = [part for part in solution.split("\\n") if part.strip()]
        budget = Budget(budget_cap)
        transcript: list[str] = []
        record: dict[str, Any] = {
            "question_head": problem[:80], "answer": "0",
            "facts": 0, "verdicts": {}, "violation": None,
            "gate": "none"}
        try:
            facts = extract(problem, steps, budget, transcript,
                            complete_fn=call_model, max_steps=max_steps)
            record["facts"] = len(facts)
            report = run_checker(facts)
            for line in report:
                parts = line.split()
                if parts[0] == "verdict":
                    record["verdicts"][parts[1]] = (
                        record["verdicts"].get(parts[1], 0) + 1)
            violation = violation_summary(report)
            if violation and not budget.exhausted():
                kind, summary, step = violation
                record["violation"] = {"kind": kind, "step": step,
                                       "summary": summary}
                rows = corpus_gate(problem, kind, summary, budget,
                                   transcript, locked_client,
                                   complete_fn=call_model)
                if rows:
                    record["gate"] = "a_rows_matched"
                    record["rows"] = [str(row.get("db_row"))
                                      for row in rows]
                    record["answer"] = str(step)
                else:
                    record["gate"] = "a_closed_no_rows"
            elif violation:
                record["gate"] = "budget_exhausted"
        except Exception as error:  # a broken item must not sink the run
            record["responder_error"] = f"{type(error).__name__}: {error}"
        record["spent"] = budget.spent
        trace(record)
        return record["answer"]

    return respond


mtb_responders.register("prolog_gated", _prolog_gated)
