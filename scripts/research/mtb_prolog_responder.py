#!/usr/bin/env python3
"""MathTutorBench responders that run model-produced quantity programs alone."""
from __future__ import annotations

import atexit
from collections import Counter
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

import mtb_responders

GOAL_TIMEOUT_SECONDS = 5.0
WALL_TIMEOUT_SECONDS = 20.0
STACK_LIMIT = "512m"

ALLOWED_MODULES = {"clpq", "clpfd", "lists", "apply", "arith"}
FORBIDDEN_ATOMS = {
    "shell", "process_create", "exec", "open", "close", "see", "tell",
    "read_term", "consult", "ensure_loaded", "load_files", "assert",
    "asserta", "assertz", "retract", "halt", "setenv", "getenv",
    "absolute_file_name", "tmp_file", "delete_file", "directory_files",
    # These additions keep the same file and process boundary intact when a
    # generated program names related SWI file, stream, process, or dynamic
    # predicates that are not useful for a quantity model.
    "system", "working_directory", "make_directory", "rename_file",
    "copy_file", "access_file", "exists_file", "exists_directory",
    "same_file", "size_file", "time_file", "read_file_to_codes",
    "read_file_to_string", "write", "writeln", "format", "nl",
    "stream_property", "set_stream", "current_stream", "current_input",
    "current_output", "set_input", "set_output", "pipe", "call",
    "once", "ignore", "catch", "setup_call_cleanup", "call_cleanup",
    "atom_to_term", "term_to_atom", "read_term_from_atom",
    "read_term_from_string", "read_term_from_codes", "qsave_program",
}
FORBIDDEN_PREFIXES = ("http_", "socket", "qsave")


@dataclass(frozen=True)
class Token:
    """A small Prolog token sufficient for the pre-execution safety screen."""

    kind: str
    value: str


@dataclass(frozen=True)
class ScreenResult:
    """Whether a program passes the static screen and, if not, its rule."""

    allowed: bool
    reason: str | None = None


@dataclass(frozen=True)
class RunResult:
    """The classified result of one fresh SWI-Prolog process."""

    outcome: str
    value: str | None = None
    detail: str | None = None
    pid: int | None = None


_TOKEN_RE = re.compile(
    r"""
    (?P<space>\s+)
  | (?P<line_comment>%[^\n]*)
  | (?P<block_comment>/\*.*?\*/)
  | (?P<quoted_atom>'(?:''|\\.|[^'\\])*')
  | (?P<string>"(?:""|\\.|[^"\\])*")
  | (?P<number>(?:\d+\.\d*|\d*\.\d+|\d+)(?:[eE][+-]?\d+)?)
  | (?P<dollar_atom>\$[A-Za-z_][A-Za-z0-9_]*)
  | (?P<atom>[a-z][A-Za-z0-9_]*)
  | (?P<variable>[_A-Z][A-Za-z0-9_]*)
  | (?P<operator>:-|-->|\\\+|\*->|->|>=|=<|=:=|=\\=|==|\\==)
  | (?P<punct>.)
    """,
    re.DOTALL | re.VERBOSE,
)

_FENCE_RE = re.compile(r"```(?:prolog|pl)?\s*\n?(.*?)```", re.IGNORECASE | re.DOTALL)
_PROGRAM_START_RE = re.compile(
    r"(?m)^[ \t]*(?=:-\s|[a-z][A-Za-z0-9_]*\s*(?:\(|:-|\.))"
)


def _unquote_atom(text: str) -> str:
    """Decode the ordinary quoted-atom escapes needed by the screen."""
    return text[1:-1].replace("''", "'")


def tokenize(program: str) -> list[Token]:
    """Tokenize Prolog while omitting comments and strings from safety checks."""
    tokens: list[Token] = []
    position = 0
    while position < len(program):
        match = _TOKEN_RE.match(program, position)
        if match is None:  # The final punctuation branch makes this unreachable.
            raise ValueError("cannot tokenize Prolog program")
        position = match.end()
        kind = match.lastgroup
        assert kind is not None
        if kind in {"space", "line_comment", "block_comment", "string"}:
            continue
        value = match.group(kind)
        if kind == "quoted_atom":
            tokens.append(Token("atom", _unquote_atom(value)))
        elif kind == "dollar_atom":
            tokens.append(Token("dollar_atom", value))
        else:
            tokens.append(Token(kind, value))
    return tokens


def _clauses(tokens: list[Token]) -> list[list[Token]]:
    """Split top-level clauses without treating decimal points as terminators."""
    clauses: list[list[Token]] = []
    clause: list[Token] = []
    depth = 0
    for token in tokens:
        if token.value in {"(", "[", "{"}:
            depth += 1
        elif token.value in {")", "]", "}"}:
            depth = max(0, depth - 1)
        if token.value == "." and depth == 0:
            clauses.append(clause)
            clause = []
        else:
            clause.append(token)
    if clause:
        clauses.append(clause)
    return clauses


def _allowed_use_module(clause: list[Token]) -> bool:
    """Accept exactly ``:- use_module(library(Name)).`` for allowed modules."""
    values = [token.value for token in clause]
    if len(values) != 8:
        return False
    return (
        values[0] == ":-"
        and values[1] == "use_module"
        and values[2] == "("
        and values[3] == "library"
        and values[4] == "("
        and values[5] in ALLOWED_MODULES
        and values[6] == ")"
        and values[7] == ")"
    )


def screen_program(program: str) -> ScreenResult:
    """Reject program text that names prohibited operations or directives."""
    tokens = tokenize(program)
    for token in tokens:
        if token.kind == "dollar_atom" or token.value == "$":
            return ScreenResult(False, "dollar_atom")
        if token.kind != "atom":
            continue
        if token.value in FORBIDDEN_ATOMS:
            return ScreenResult(False, f"forbidden_atom:{token.value}")
        for prefix in FORBIDDEN_PREFIXES:
            if token.value.startswith(prefix):
                return ScreenResult(False, f"forbidden_prefix:{prefix}")

    for clause in _clauses(tokens):
        if not clause:
            continue
        if clause[0].value == ":-":
            if not _allowed_use_module(clause):
                if len(clause) > 1 and clause[1].value == "use_module":
                    return ScreenResult(False, "disallowed_use_module")
                return ScreenResult(False, "disallowed_directive")
        elif any(token.value == "use_module" for token in clause):
            return ScreenResult(False, "use_module_not_directive")
    return ScreenResult(True)


def extract_program(reply: str) -> str | None:
    """Prefer a fenced Prolog block, then use the first program-looking line."""
    fenced = _FENCE_RE.findall(reply)
    if fenced:
        for block in fenced:
            if _PROGRAM_START_RE.search(block):
                return block.strip()
        return fenced[0].strip() or None
    start = _PROGRAM_START_RE.search(reply)
    if start is None:
        return None
    end = reply.rfind(".")
    if end < start.start():
        return None
    return reply[start.start():end + 1].strip() or None


def _answer_goal(goal_timeout_seconds: float) -> str:
    timeout = f"{goal_timeout_seconds:g}"
    return (
        "catch("
        f"(call_with_time_limit({timeout}, once(solve(Answer))) -> "
        "(integer(Answer) -> format('__MTB_ANSWER__~d~n', [Answer]) ; "
        "(number(Answer) -> format('__MTB_ANSWER__~15f~n', [Answer]) ; "
        "writeln('__MTB_NONNUMERIC__'))) ; "
        "writeln('__MTB_NO_SOLUTION__')), "
        "time_limit_exceeded, writeln('__MTB_TIMEOUT__'))"
    )


def _kill_process_group(process: subprocess.Popen[str]) -> None:
    """Terminate every process started for one generated program."""
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def run_program(
    program: str,
    scratch_dir: Path,
    *,
    goal_timeout_seconds: float = GOAL_TIMEOUT_SECONDS,
    wall_timeout_seconds: float = WALL_TIMEOUT_SECONDS,
) -> RunResult:
    """Run ``solve/1`` in a new SWI process rooted in a caller scratch dir."""
    scratch_dir = scratch_dir.resolve()
    if not scratch_dir.is_dir():
        raise ValueError(f"scratch directory does not exist: {scratch_dir}")
    if scratch_dir == REPO_ROOT or REPO_ROOT in scratch_dir.parents:
        raise ValueError("scratch directory must be outside the repository")
    if not (0 < goal_timeout_seconds <= GOAL_TIMEOUT_SECONDS):
        raise ValueError("goal timeout must be positive and at most five seconds")
    if not (0 < wall_timeout_seconds <= WALL_TIMEOUT_SECONDS):
        raise ValueError("wall timeout must be positive and at most twenty seconds")

    temp_path: Path | None = None
    process: subprocess.Popen[str] | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", suffix=".pl", prefix="mtb_prolog_",
            dir=scratch_dir, delete=False,
        ) as handle:
            handle.write(program)
            temp_path = Path(handle.name)

        command = [
            "swipl", "--stack-limit=" + STACK_LIMIT, "--on-error=status",
            "-q", "-f", "none", "-s", str(temp_path),
            "-g", _answer_goal(goal_timeout_seconds), "-t", "halt",
        ]
        process = subprocess.Popen(
            command,
            cwd=scratch_dir,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            start_new_session=True,
        )
        try:
            stdout, stderr = process.communicate(timeout=wall_timeout_seconds)
        except subprocess.TimeoutExpired:
            _kill_process_group(process)
            stdout, stderr = process.communicate()
            return RunResult("timeout", detail="wall_clock", pid=process.pid)

        lines = stdout.splitlines()
        answer_lines = [line for line in lines if line.startswith("__MTB_ANSWER__")]
        if "__MTB_TIMEOUT__" in lines:
            return RunResult("timeout", detail="goal_limit", pid=process.pid)
        if "__MTB_NONNUMERIC__" in lines:
            return RunResult("nonnumeric", pid=process.pid)
        if "__MTB_NO_SOLUTION__" in lines:
            return RunResult("no_solution", pid=process.pid)
        if answer_lines:
            value = answer_lines[-1].removeprefix("__MTB_ANSWER__").strip()
            if re.fullmatch(r"-?\d+(?:\.\d+)?", value):
                return RunResult("ran", value=value, pid=process.pid)
            return RunResult("nonnumeric", detail="unparseable_number", pid=process.pid)
        if process.returncode:
            detail = stderr.strip().splitlines()[-1] if stderr.strip() else None
            # A program that will not load and a program whose goal raised are
            # different findings. The first is malformed Prolog; the second is
            # a quantity model that reads as Prolog and does not run, which is
            # the class the paper reports as semantic. Reversed is/2 arguments
            # land here, not in syntax.
            text = stderr or ""
            if "Syntax error" in text or "operator expected" in text:
                return RunResult("syntax_error", detail=detail, pid=process.pid)
            return RunResult("runtime_error", detail=detail, pid=process.pid)
        return RunResult("no_solution", detail="no_result_marker", pid=process.pid)
    except FileNotFoundError as exc:
        raise RuntimeError("swipl is required for the Prolog responder") from exc
    finally:
        if process is not None and process.poll() is None:
            _kill_process_group(process)
            process.communicate()
        if temp_path is not None:
            try:
                temp_path.unlink()
            except FileNotFoundError:
                pass


JANET_SHOT = """Question: Janet's ducks lay 16 eggs per day. She eats three for breakfast every morning and sells the rest at the farmers market daily for $2 per egg. How much in dollars does she make per day at the farmers market?
Program:
```prolog
:- use_module(library(clpq)).
eggs_per_day(janet, 16).
eaten(janet, 3).
price_per_egg(2).
solve(Dollars) :-
    eggs_per_day(janet, Laid),
    eaten(janet, Eaten),
    price_per_egg(Price),
    {Sold = Laid - Eaten},
    {Dollars = Sold * Price}.
```"""

NATALIE_SHOT = """Question: Natalie sold clips to 48 of her friends in April, and then she sold half as many clips in May. How many clips did Natalie sell in all?
Program:
```prolog
:- use_module(library(clpq)).
april_clips(natalie, 48).
half_of(Whole, Half) :- {Half = Whole / 2}.
solve(Clips) :-
    april_clips(natalie, April),
    half_of(April, May),
    {Clips = April + May}.
```"""


def prolog_prompt(question: str) -> str:
    """Ask for a runnable quantity model using the benchmark's two examples."""
    return (
        "Translate each word problem into a self-contained SWI-Prolog program. "
        "Return only one Prolog program. It must define solve(Answer), use "
        "facts and relations for the quantities, and let the interpreter bind "
        "Answer.\n\n"
        "Write every arithmetic relation as a clpq constraint in braces, like "
        "{Total = Price * Count}. Never use is/2, =:=, =<, or >=. A constraint "
        "holds in both directions, so the order of goals does not matter; is/2 "
        "needs its right side already known and fails when it is not.\n\n"
        + JANET_SHOT + "\n\n" + NATALIE_SHOT + "\n\n"
        + f"Question: {question}\nProgram:\n```prolog\n"
    )


class PrologResponder:
    """One strict or guarded Prolog-generation arm for ``problem_solving``."""

    def __init__(self, model: str, *, guarded: bool, **options: str) -> None:
        scratch_value = options.get("scratch_dir")
        if not scratch_value:
            raise ValueError("prolog responders require responder-arg scratch_dir=...")
        self.scratch_dir = Path(scratch_value).expanduser().resolve()
        if not self.scratch_dir.is_dir():
            raise ValueError(f"scratch directory does not exist: {self.scratch_dir}")
        if self.scratch_dir == REPO_ROOT or REPO_ROOT in self.scratch_dir.parents:
            raise ValueError("scratch directory must be outside the repository")
        self.model = model
        self.guarded = guarded
        self.backend = options.get("backend", "ollama")
        self.endpoint = options.get("endpoint")
        self.num_predict = int(options.get("num_predict", mtb_responders.DEFAULT_NUM_PREDICT))
        self.stats: Counter[str] = Counter()
        self._closed = False

    @property
    def arm(self) -> str:
        return "prolog_solve_guarded" if self.guarded else "prolog_solve"

    def _record(self, outcome: str, **extra: Any) -> None:
        position = self.stats["items"]
        self.stats["items"] += 1
        self.stats[outcome] += 1
        record = {"position": position, "outcome": outcome, **extra}
        print(
            "MTB_PROLOG_ITEM " + json.dumps(record, sort_keys=True),
            file=sys.stderr,
            flush=True,
        )

    def _fallback(self, prompt: str, stop: list[str] | None) -> str:
        self.stats["fallbacks"] += 1
        try:
            return mtb_responders.complete(
                prompt, model=self.model, backend=self.backend,
                endpoint=self.endpoint, stop=stop, num_predict=self.num_predict,
                stop_mode="decode",
            )
        except RuntimeError:
            self.stats["fallback_errors"] += 1
            return ""

    def respond(
        self, *, prompt: str, stop: list[str] | None, example: dict[str, Any],
        task_name: str,
    ) -> str:
        started = time.monotonic()
        outcome = "no_program"
        record_extra: dict[str, Any] = {}
        answer = ""
        try:
            if task_name != "problem_solving":
                raise ValueError("prolog responders support only problem_solving")
            question = str(example.get("question", ""))
            if not question:
                raise ValueError("problem_solving item has no question")
            self.stats["prolog_model_calls"] += 1
            try:
                reply = mtb_responders.complete(
                    prolog_prompt(question), model=self.model, backend=self.backend,
                    endpoint=self.endpoint, stop=stop, num_predict=self.num_predict,
                    stop_mode="post",
                )
            except RuntimeError as exc:
                record_extra["detail"] = f"completion_error:{type(exc).__name__}"
                reply = ""
            program = extract_program(reply)
            if program is None:
                return self._fallback(prompt, stop) if self.guarded else ""
            screened = screen_program(program)
            if not screened.allowed:
                outcome = "rejected_unsafe"
                record_extra["rule"] = screened.reason
                return self._fallback(prompt, stop) if self.guarded else ""
            result = run_program(program, self.scratch_dir)
            outcome = result.outcome
            if result.detail:
                record_extra["detail"] = result.detail
            if result.outcome == "ran" and result.value is not None:
                answer = f"Final answer: {result.value}"
                return answer
            return self._fallback(prompt, stop) if self.guarded else ""
        except (RuntimeError, ValueError) as exc:
            record_extra["detail"] = f"responder_error:{type(exc).__name__}"
            return self._fallback(prompt, stop) if self.guarded else ""
        finally:
            record_extra["seconds"] = round(time.monotonic() - started, 3)
            self._record(outcome, **record_extra)

    def close(self) -> None:
        """Emit the arm's failure taxonomy after the runner has called it."""
        if self._closed:
            return
        self._closed = True
        items = self.stats["items"]
        summary = {
            "arm": self.arm,
            "model": self.model,
            "items": items,
            "fallbacks": self.stats["fallbacks"],
            "fallback_errors": self.stats["fallback_errors"],
            "prolog_model_calls": self.stats["prolog_model_calls"],
            **{name: self.stats[name] for name in (
                "no_program", "rejected_unsafe", "syntax_error", "runtime_error",
                "no_solution",
                "timeout", "nonnumeric", "ran",
            )},
        }
        print("MTB_PROLOG_STATS " + json.dumps(summary, sort_keys=True), file=sys.stderr)


def _builder(guarded: bool):
    def build(model: str, **options: str) -> mtb_responders.Responder:
        responder = PrologResponder(model, guarded=guarded, **options)
        atexit.register(responder.close)
        return responder.respond

    return build


mtb_responders.register("prolog_solve", _builder(False))
mtb_responders.register("prolog_solve_guarded", _builder(True))
