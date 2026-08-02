#!/usr/bin/env python3
"""A diagnosis responder that consults the Prolog knowledge base by query.

Two model calls frame one Prolog call. The first call asks the model to
write a single SWI-Prolog goal — an arithmetic check of the student's work,
a keyword probe over the misconception corpus, or both. The goal runs
through the same `prolog_query` surface the MCP tool serves, inside one
persistent `kb_query_server.pl` process, so the sandbox and the scope
guards are identical to the interactive ones; only the recorded limits are
widened through the environment. The second call hands the original
benchmark prompt back to the model with the query and its result inserted,
and the model names the category.

The engine computes and the model reads: a failed goal travels to the
second call as a failure with its status, never as an answer. Every item's
query, status, and binding count land in a trace file so a run can be
audited after the fact.
"""
from __future__ import annotations

import json
import os
import queue
import re
import subprocess
import threading
import time
from pathlib import Path
from typing import Any

import mtb_responders

REPO_ROOT = Path(__file__).resolve().parents[2]
SERVER_RELATIVE = "scripts/research/kb_query_server.pl"
READY_LINE = "KB_QUERY_SERVER_READY"

QUERY_PROMPT = """You may consult a Prolog knowledge base before diagnosing \
a student's error.

Problem: {problem}

Student's solution:
{solution}

Write exactly one SWI-Prolog goal that would help check this solution.
Available forms:
- compute a value:  X is 132.5 - 45.
- check an equality:  17 * 4 =:= 68.
- search a corpus of documented student misconceptions by keyword:
  misconception_mentions("place value", M).
- two goals joined by a comma:  (X is 3 * 15, 45 =:= 3 * 15).

Rules: one goal only, end it with a period, put it alone inside a
```prolog code fence, and write nothing after the fence.
"""

RETRY_SUFFIX = """

Your previous goal was:
{goal}
It was not accepted: {message}
Write one corrected goal, alone in a ```prolog code fence.
"""

ANCHOR = "Answer with the category text alone.\nCategory:"

PROBLEM_PATTERN = re.compile(
    r"Problem: (?P<problem>.*?)\n\nStudent's solution:\n(?P<solution>.*?)"
    r"\n\nName the single category", re.DOTALL)

FENCE_PATTERN = re.compile(r"```(?:prolog)?\s*\n(.*?)```", re.DOTALL)


class KBQueryServer:
    """One swipl process, one JSON line out per JSON line in.

    A lock serializes queries; the knowledge base loads once. The watchdog
    is external to Prolog, as the Big Red laws require: a goal that wedges
    the process gets the process killed and restarted, and the caller gets
    a status rather than a hang.
    """

    def __init__(self, repo_root: Path, swipl: str = "swipl",
                 watchdog_seconds: float = 30.0,
                 environment: dict[str, str] | None = None) -> None:
        self.repo_root = repo_root
        self.swipl = swipl
        self.watchdog_seconds = watchdog_seconds
        self.environment = environment or {}
        self.lock = threading.Lock()
        self.process: subprocess.Popen[str] | None = None
        self.lines: queue.Queue[str] = queue.Queue()

    def _start(self) -> None:
        env = dict(os.environ)
        env.update(self.environment)
        self.lines = queue.Queue()
        self.process = subprocess.Popen(
            [self.swipl, "-q", "-l", "paths.pl", "-l", SERVER_RELATIVE,
             "-g", "kb_query_server_main"],
            cwd=self.repo_root, env=env, text=True, encoding="utf-8",
            stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL)
        thread = threading.Thread(
            target=self._pump, args=(self.process,), daemon=True)
        thread.start()
        deadline = time.time() + 120.0
        while time.time() < deadline:
            try:
                line = self.lines.get(timeout=deadline - time.time())
            except queue.Empty:
                break
            if line.strip() == READY_LINE:
                return
        self._stop()
        raise RuntimeError("kb_query_server did not become ready")

    def _pump(self, process: subprocess.Popen[str]) -> None:
        assert process.stdout is not None
        for line in process.stdout:
            self.lines.put(line)

    def _stop(self) -> None:
        if self.process is not None:
            self.process.kill()
            self.process.wait()
            self.process = None

    def query(self, goal: str) -> dict[str, Any]:
        with self.lock:
            if self.process is None or self.process.poll() is not None:
                self._start()
            assert self.process is not None and self.process.stdin is not None
            request = json.dumps({"goal": goal}, ensure_ascii=False)
            try:
                self.process.stdin.write(request + "\n")
                self.process.stdin.flush()
            except (BrokenPipeError, OSError):
                self._stop()
                return {"status": "server_lost",
                        "error": "the query server pipe closed mid-request"}
            deadline = time.time() + self.watchdog_seconds
            while True:
                remaining = deadline - time.time()
                if remaining <= 0:
                    self._stop()
                    return {"status": "watchdog_timeout",
                            "error": f"no reply within "
                                     f"{self.watchdog_seconds}s; "
                                     "the server process was killed"}
                try:
                    line = self.lines.get(timeout=remaining)
                except queue.Empty:
                    continue
                line = line.strip()
                if not line or line == READY_LINE:
                    continue
                try:
                    return json.loads(line)
                except json.JSONDecodeError:
                    return {"status": "server_error",
                            "error": f"unreadable reply: {line[:200]}"}


def extract_goal(reply: str) -> str:
    """Take the goal out of the model's fence, or its last plausible line."""
    found = FENCE_PATTERN.search(reply)
    text = found.group(1) if found else ""
    if not text:
        candidates = [line.strip() for line in reply.splitlines()
                      if line.strip().endswith(".")
                      and not line.strip().startswith(("%", "//", "#"))]
        text = candidates[-1] if candidates else ""
    text = " ".join(text.split()).strip()
    text = text.removeprefix("?-").strip()
    return text.rstrip(".").strip()


def clip(text: str, width: int) -> str:
    text = " ".join(str(text).split())
    return text if len(text) <= width else text[:width - 1] + "…"


def describe_result(reply: dict[str, Any], max_show: int,
                    value_width: int = 240) -> str:
    status = reply.get("status", "unknown")
    if status != "ok":
        detail = (reply.get("error") or reply.get("rejection") or {})
        if isinstance(detail, dict):
            detail = detail.get("message", "")
        return f"the query was not run (status: {status}). {clip(detail, 200)}"
    count = reply.get("solution_count", 0)
    if not count:
        return ("the goal failed: zero solutions. For an arithmetic "
                "comparison this means the stated equality is false; for a "
                "keyword search it means no documented misconception "
                "mentions it.")
    shown = []
    for binding in reply.get("bindings", [])[:max_show]:
        pairs = ", ".join(f"{name} = {clip(value, value_width)}"
                          for name, value in sorted(binding.items()))
        shown.append(f"- {pairs}")
    suffix = "" if count <= max_show else f" (showing {max_show} of {count})"
    return f"{count} solution(s){suffix}:\n" + "\n".join(shown)


def _prolog_kb(model: str, **options: str) -> mtb_responders.Responder:
    backend = options.get("backend", "ollama")
    endpoint = options.get("endpoint")
    num_predict = int(options.get("num_predict", 4096))
    max_show = int(options.get("max_show", 6))
    trace_path = options.get("trace")
    server = KBQueryServer(
        repo_root=Path(options.get("repo", REPO_ROOT)),
        swipl=options.get("swipl", "swipl"),
        watchdog_seconds=float(options.get("watchdog", 30.0)),
        environment={
            "HERMES_PROLOG_QUERY_TIMEOUT_SECONDS":
                options.get("prolog_timeout", "10"),
            "HERMES_PROLOG_QUERY_SOLUTION_CAP":
                options.get("solution_cap", "40"),
        })
    trace_lock = threading.Lock()

    def trace(record: dict[str, Any]) -> None:
        if not trace_path:
            return
        with trace_lock:
            path = Path(trace_path)
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record, ensure_ascii=False) + "\n")

    def call_model(prompt: str) -> str:
        return mtb_responders.complete(
            prompt, model=model, backend=backend, endpoint=endpoint,
            stop=None, num_predict=num_predict, stop_mode="post")

    def respond(*, prompt: str, stop: list[str] | None,
                example: dict[str, Any], task_name: str) -> str:
        found = PROBLEM_PATTERN.search(prompt)
        problem = found.group("problem") if found else prompt
        solution = found.group("solution") if found else ""
        query_prompt = QUERY_PROMPT.format(problem=problem, solution=solution)

        record: dict[str, Any] = {"task": task_name, "attempts": []}
        goal, reply = "", {"status": "no_goal",
                           "error": "no goal was extracted"}
        for attempt in range(2):
            former_reply = call_model(query_prompt)
            goal = extract_goal(former_reply)
            if not goal:
                record["attempts"].append({"goal": "", "status": "no_goal"})
                break
            reply = server.query(goal)
            record["attempts"].append({
                "goal": goal, "status": reply.get("status"),
                "solution_count": reply.get("solution_count"),
                "cap_hit": reply.get("cap_hit")})
            if reply.get("status") == "ok":
                break
            detail = (reply.get("error") or reply.get("rejection") or {})
            if isinstance(detail, dict):
                detail = detail.get("message", "")
            query_prompt = QUERY_PROMPT.format(
                problem=problem, solution=solution) + RETRY_SUFFIX.format(
                goal=goal, message=clip(detail, 300))

        if goal:
            consultation = (f"A Prolog knowledge base was consulted.\n"
                            f"Query: {goal}\n"
                            f"Result: {describe_result(reply, max_show)}\n"
                            "These are suggestions to weigh, not a verdict.")
        else:
            consultation = ("The Prolog knowledge base was not consulted: "
                            "no usable query was formed.")
        if ANCHOR in prompt:
            final_prompt = prompt.replace(
                ANCHOR, consultation + "\n\n" + ANCHOR)
        else:
            final_prompt = prompt + "\n\n" + consultation
        answer = call_model(final_prompt)
        record["final_head"] = clip(answer, 160)
        trace(record)
        return answer

    return respond


mtb_responders.register("prolog_kb", _prolog_kb)
