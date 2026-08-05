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

# The repair module reads `ALLOWED_MODULES` to know which imports a repaired
# program may keep, so it must be imported after that name exists. The two
# modules are a cycle by design: the screen owns what may run, the repair owns
# what to try, and neither decides the other's question.
import mtb_prolog_repair  # noqa: E402


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
    error_class: str | None = None
    stdout: str = ""
    stderr: str = ""
    seconds: float = 0.0
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
        f"(call_with_time_limit({timeout}, (once(solve(Answer)), "
        "(integer(Answer) -> format('__MTB_ANSWER__~d~n', [Answer]) ; "
        "(number(Answer) -> format('__MTB_ANSWER__~15f~n', [Answer]) ; "
        "((get_attr(Answer, clpqr_itf, Attr), arg(1, Attr, clpq), "
        "once(bb_inf([Answer], -Answer, _, [Grounded])), number(Grounded)) -> "
        "(integer(Grounded) -> "
        "format('__MTB_ANSWER_GROUNDED__~d~n', [Grounded]) ; "
        "format('__MTB_ANSWER_GROUNDED__~15f~n', [Grounded])) ; "
        "writeln('__MTB_NONNUMERIC__')))))) -> true ; "
        "writeln('__MTB_NO_SOLUTION__')), "
        "Error, (Error == time_limit_exceeded -> "
        "writeln('__MTB_TIMEOUT__') ; "
        "(write('__MTB_ERROR__'), write_canonical(Error), nl)))"
    )


def _kill_process_group(process: subprocess.Popen[str]) -> None:
    """Terminate every process started for one generated program."""
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass


def _runtime_error_class(detail: str) -> str:
    """Classify the canonical SWI error term emitted by the answer wrapper."""
    if (
        "existence_error(procedure,/(solve,1))" in detail
        or re.search(r"existence_error\(procedure,(?:[^)]*:)?solve/1\)", detail)
    ):
        return "undefined_solve"
    for name in (
        "instantiation_error", "type_error", "domain_error",
        "evaluation_error", "permission_error", "representation_error",
        "resource_error",
    ):
        if name in detail:
            return name
    return "other"


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

    started = time.monotonic()
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
            return RunResult(
                "timeout", detail="wall_clock", stdout=stdout, stderr=stderr,
                seconds=round(time.monotonic() - started, 3), pid=process.pid,
            )

        lines = stdout.splitlines()
        answer_lines = [line for line in lines if line.startswith("__MTB_ANSWER__")]
        grounded_lines = [
            line for line in lines
            if line.startswith("__MTB_ANSWER_GROUNDED__")
        ]
        error_lines = [line for line in lines if line.startswith("__MTB_ERROR__")]
        common = {
            "stdout": stdout,
            "stderr": stderr,
            "seconds": round(time.monotonic() - started, 3),
            "pid": process.pid,
        }
        if "__MTB_TIMEOUT__" in lines:
            return RunResult("timeout", detail="goal_limit", **common)
        if process.returncode and (
            "Syntax error" in stderr or "operator expected" in stderr
        ):
            detail = stderr.strip().splitlines()[-1] if stderr.strip() else None
            return RunResult("syntax_error", detail=detail, **common)
        if error_lines:
            detail = error_lines[-1].removeprefix("__MTB_ERROR__").strip()
            return RunResult(
                "runtime_error", detail=detail,
                error_class=_runtime_error_class(detail), **common,
            )
        if "__MTB_NONNUMERIC__" in lines:
            return RunResult("nonnumeric", **common)
        if "__MTB_NO_SOLUTION__" in lines:
            return RunResult("no_solution", **common)
        if grounded_lines:
            value = grounded_lines[-1].removeprefix(
                "__MTB_ANSWER_GROUNDED__").strip()
            if re.fullmatch(r"-?\d+(?:\.\d+)?", value):
                return RunResult("ran_grounded", value=value, **common)
            return RunResult(
                "nonnumeric", detail="unparseable_grounded_number", **common,
            )
        if answer_lines:
            value = answer_lines[-1].removeprefix("__MTB_ANSWER__").strip()
            if re.fullmatch(r"-?\d+(?:\.\d+)?", value):
                return RunResult("ran", value=value, **common)
            return RunResult(
                "nonnumeric", detail="unparseable_number", **common,
            )
        if process.returncode:
            detail = stderr.strip().splitlines()[-1] if stderr.strip() else None
            # A program that will not load and a program whose goal raised are
            # different findings. The first is malformed Prolog; the second is
            # a quantity model that reads as Prolog and does not run, which is
            # the class the paper reports as semantic. Reversed is/2 arguments
            # land here, not in syntax.
            text = stderr or ""
            if "Syntax error" in text or "operator expected" in text:
                return RunResult("syntax_error", detail=detail, **common)
            error_class = _runtime_error_class(detail or "")
            return RunResult(
                "runtime_error", detail=detail, error_class=error_class,
                **common,
            )
        return RunResult("no_solution", detail="no_result_marker", **common)
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


@dataclass(frozen=True)
class Attempt:
    """What one generated program did, after however much repair it needed."""

    outcome: str
    value: str | None
    rung: int
    steps: tuple[str, ...]
    program: str | None
    screen: ScreenResult | None
    reply: str
    detail: str | None = None
    error_class: str | None = None
    grounding: str | None = None
    stdout: str = ""
    stderr: str = ""

    @property
    def answered(self) -> bool:
        return self.outcome in {"ran", "ran_grounded"} and self.value is not None


def _vote(attempts: list[Attempt]) -> tuple[str | None, dict[str, int]]:
    """Take the value the most executed programs agree on.

    A generated program that will not run casts no vote, so the interpreter is
    doing the filtering an unassisted arm has to do with a second opinion. Ties
    go to the value the earliest sample reached, which makes a single-sample arm
    and a k-sample arm agree whenever the first sample runs.
    """
    tally: Counter[str] = Counter()
    order: dict[str, int] = {}
    for position, attempt in enumerate(attempts):
        if not attempt.answered:
            continue
        assert attempt.value is not None
        tally[attempt.value] += 1
        order.setdefault(attempt.value, position)
    if not tally:
        return None, {}
    winner = min(tally, key=lambda value: (-tally[value], order[value]))
    return winner, dict(tally)


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
        # Repair is on by default and `repair=off` reproduces the arm as it ran
        # before the ladder existed, so the two are an ablation rather than a
        # replacement. Every run records which of them it was.
        repair_value = options.get("repair", "on")
        if repair_value not in {"on", "off"}:
            raise ValueError("repair must be on or off")
        self.repair = repair_value == "on"
        self.samples = int(options.get("samples", 1))
        if self.samples < 1:
            raise ValueError("samples must be at least one")
        # One sample stays greedy, which is what every recorded run used. More
        # than one needs spread, or the samples are the same program k times.
        default_temperature = (
            mtb_responders.DEFAULT_TEMPERATURE if self.samples == 1 else 0.8
        )
        self.temperature = float(options.get("temperature", default_temperature))
        transcript_value = options.get("transcript_dir")
        self.transcript_path: Path | None = None
        self._transcript_handle = None
        if transcript_value:
            transcript_dir = Path(transcript_value).expanduser().resolve()
            transcript_dir.mkdir(parents=True, exist_ok=True)
            self.transcript_path = transcript_dir / f"{self.arm}.jsonl"
            self._transcript_handle = self.transcript_path.open(
                "w", encoding="utf-8")
        self.stats: Counter[str] = Counter()
        self._closed = False

    @property
    def arm(self) -> str:
        return "prolog_solve_guarded" if self.guarded else "prolog_solve"

    def _record(
        self, outcome: str, *, transcript: dict[str, Any], **extra: Any,
    ) -> None:
        position = self.stats["items"]
        self.stats["items"] += 1
        self.stats[outcome] += 1
        record = {"position": position, "outcome": outcome, **extra}
        print(
            "MTB_PROLOG_ITEM " + json.dumps(record, sort_keys=True),
            file=sys.stderr,
            flush=True,
        )
        if self._transcript_handle is not None:
            transcript_record = {
                "position": position,
                **transcript,
                "outcome": outcome,
                **extra,
            }
            self._transcript_handle.write(
                json.dumps(transcript_record, ensure_ascii=False, sort_keys=True)
                + "\n"
            )
            self._transcript_handle.flush()

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

    def _screen_and_run(
        self, program: str, *, rung: int, steps: tuple[str, ...], reply: str,
    ) -> Attempt:
        """Screen one program text and run it, whether written or repaired.

        Repair never widens what may run: the screen is applied to the repaired
        text, exactly as it is applied to the text as written.
        """
        screened = screen_program(program)
        if not screened.allowed:
            return Attempt(
                "rejected_unsafe", None, rung, steps, program, screened, reply,
                detail=screened.reason,
            )
        result = run_program(program, self.scratch_dir)
        grounding = None
        if result.outcome == "ran":
            grounding = "direct"
        elif result.outcome == "ran_grounded":
            grounding = "clpq_bb_inf_integer_maximum"
        return Attempt(
            result.outcome, result.value, rung, steps, program, screened, reply,
            detail=result.detail, error_class=result.error_class,
            grounding=grounding, stdout=result.stdout, stderr=result.stderr,
        )

    def _solve_once(self, question: str, *, stop: list[str] | None) -> Attempt:
        """One model call, then the repair ladder until something runs."""
        reply = ""
        self.stats["prolog_model_calls"] += 1
        try:
            reply = mtb_responders.complete(
                prolog_prompt(question), model=self.model, backend=self.backend,
                endpoint=self.endpoint, stop=stop, num_predict=self.num_predict,
                stop_mode="post", temperature=self.temperature,
            )
        except RuntimeError as exc:
            return Attempt(
                "no_program", None, 0, (), None, None, reply,
                detail=f"completion_error:{type(exc).__name__}",
            )
        program = extract_program(reply)
        if program is None:
            return Attempt("no_program", None, 0, (), None, None, reply)

        attempt = self._screen_and_run(program, rung=0, steps=(), reply=reply)
        if attempt.answered or not self.repair:
            return attempt
        try:
            rungs = mtb_prolog_repair.repair_ladder(program)
        except (ValueError, RecursionError):
            # A program the repair reader cannot take apart is left as it ran.
            self.stats["repair_errors"] += 1
            return attempt
        for number, rung in enumerate(rungs, start=1):
            repaired = self._screen_and_run(
                rung.program, rung=number, steps=rung.steps, reply=reply,
            )
            if repaired.answered:
                self.stats["repaired"] += 1
                for step in rung.steps:
                    self.stats[f"repair_step:{step}"] += 1
                return repaired
        return attempt

    def respond(
        self, *, prompt: str, stop: list[str] | None, example: dict[str, Any],
        task_name: str,
    ) -> str:
        started = time.monotonic()
        attempts: list[Attempt] = []
        record_extra: dict[str, Any] = {}
        outcome = "no_program"
        try:
            if task_name != "problem_solving":
                raise ValueError("prolog responders support only problem_solving")
            question = str(example.get("question", ""))
            if not question:
                raise ValueError("problem_solving item has no question")
            for _ in range(self.samples):
                attempts.append(self._solve_once(question, stop=stop))
            value, tally = _vote(attempts)
            chosen = next(
                (attempt for attempt in attempts
                 if attempt.answered and attempt.value == value),
                attempts[0] if attempts else None,
            )
            if chosen is not None:
                outcome = chosen.outcome
                record_extra["rung"] = chosen.rung
                if chosen.steps:
                    record_extra["repair_steps"] = list(chosen.steps)
                if chosen.detail:
                    record_extra["detail"] = chosen.detail
                if chosen.error_class:
                    record_extra["error_class"] = chosen.error_class
                if chosen.grounding:
                    record_extra["grounding"] = chosen.grounding
            if self.samples > 1:
                record_extra["votes"] = tally
                record_extra["answered_samples"] = sum(
                    1 for attempt in attempts if attempt.answered)
            if value is not None:
                record_extra["value"] = value
                return f"Final answer: {value}"
            return self._fallback(prompt, stop) if self.guarded else ""
        except (RuntimeError, ValueError) as exc:
            record_extra["detail"] = f"responder_error:{type(exc).__name__}"
            return self._fallback(prompt, stop) if self.guarded else ""
        finally:
            record_extra["seconds"] = round(time.monotonic() - started, 3)
            # The transcript's own fields describe the attempt the answer came
            # from; every other attempt is kept beside them under `attempts`.
            shown = next(
                (attempt for attempt in attempts if attempt.answered),
                attempts[0] if attempts else None,
            )
            transcript = {
                "raw_reply": shown.reply if shown else "",
                "program": shown.program if shown else None,
                "screen": (
                    None if shown is None or shown.screen is None
                    else {
                        "allowed": shown.screen.allowed,
                        "reason": shown.screen.reason,
                    }
                ),
                "swipl_stdout": shown.stdout if shown else "",
                "swipl_stderr": shown.stderr if shown else "",
                "attempts": [
                    {
                        "outcome": attempt.outcome,
                        "value": attempt.value,
                        "rung": attempt.rung,
                        "steps": list(attempt.steps),
                        "program": attempt.program,
                        "detail": attempt.detail,
                    }
                    for attempt in attempts
                ],
            }
            self._record(outcome, transcript=transcript, **record_extra)

    def close(self) -> None:
        """Emit the arm's failure taxonomy after the runner has called it."""
        if self._closed:
            return
        self._closed = True
        if self._transcript_handle is not None:
            self._transcript_handle.close()
        items = self.stats["items"]
        summary = {
            "arm": self.arm,
            "model": self.model,
            "items": items,
            "repair": "on" if self.repair else "off",
            "samples": self.samples,
            "temperature": self.temperature,
            "repaired": self.stats["repaired"],
            "repair_errors": self.stats["repair_errors"],
            "repair_steps": {
                name.removeprefix("repair_step:"): count
                for name, count in sorted(self.stats.items())
                if name.startswith("repair_step:")
            },
            "fallbacks": self.stats["fallbacks"],
            "fallback_errors": self.stats["fallback_errors"],
            "prolog_model_calls": self.stats["prolog_model_calls"],
            **{name: self.stats[name] for name in (
                "no_program", "rejected_unsafe", "syntax_error", "runtime_error",
                "no_solution",
                "timeout", "nonnumeric", "ran", "ran_grounded",
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
