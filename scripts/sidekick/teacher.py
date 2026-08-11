#!/usr/bin/env python3
"""The 31 B teacher writes narrative framings, and never writes a relay.

The deliverable model is E2B. A 31 B checkpoint appears here in one offline
role — writing the teacher turn that would warrant a call the worker has
already executed — and never at inference, never in an arm, never in a reported
number. That is stated rather than buried, per the consumer-hardware ruling.

Two constraints from the amendment are enforced here rather than hoped for:

- **Surface distance.** A framing that hands over an argument in the tool's own
  serialization teaches copying. `frac(1,14)` is rejected; "one fourteenth" is
  admitted. The rejection happens before the framing is ever paired with a row.
- **No class-D replies.** Relay text is template-bound to the worker's own
  refusal string or its abstention status. A teacher model writing relay prose
  can smuggle in the answer Hermes declined to give, which is the disqualifying
  failure this program trains against.

Generation is checkpointed per batch. Any recompute over about thirty minutes
either checkpoints or does not run, and six thousand framings is well over it.
"""
from __future__ import annotations

import json
import re
import ssl
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Sequence

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from hermes.app import llm  # noqa: E402

MAX_TOKENS = 2500
BATCH = 6

# Tool serialization a framing may never carry. These are the shapes a caller
# would copy rather than form.
TOOL_NOTATION = (
    re.compile(r"frac\s*\(\s*\d+\s*,\s*\d+\s*\)"),
    re.compile(r"db_row\s*\(\s*\d+\s*\)"),
    re.compile(r"\{[^}]*[\"']\s*(?:strategy|domain|input|got|code|lesson|content|query)\s*[\"']"),
    re.compile(r"\b[a-z]+(?:_[a-z]+){2,}\b"),
    re.compile(r"\b(?:strategy_trace|misconception_lookup|misconception_search_rows|monitoring_chart"
               r"|monitoring_chart_detail|lesson_enactment_run|lesson_enactment_list|graph_machine"
               r"|graph_borrows|graph_overview|list_strategies|check_math_claim|diagnose_error"
               r"|incompatibility_profile|incompatibility_entailments|commitment_match"
               r"|deontic_scorecard|deontic_consequences|lesson_deformation_chart"
               r"|lesson_arithmetic_demonstration|strategy_recognize)\b"),
)

SYSTEM = (
    "You write short turns that a real United States elementary or middle school teacher "
    "would type to a classroom assistant. You are producing training data, so the turns "
    "must sound like a busy teacher, not like a prompt.\n\n"
    "Hard rules, every time:\n"
    "1. Write ordinary classroom English. Never write code, JSON, function names, "
    "underscored_identifiers, or notation like frac(1,4). Write 'one quarter', not 'frac(1,4)'.\n"
    "2. Never name a tool, a database, or a lookup. The teacher does not know what is under the hood.\n"
    "3. Never state the answer the teacher is asking about.\n"
    "4. Each turn is one to three sentences and stands on its own.\n"
    "5. Vary the grade, the classroom situation, and the sentence shape across the turns you write.\n"
    "Reply with one JSON object and nothing else."
)


@dataclass
class Framing:
    key: str
    turn: str
    reply: str = ""


class Rejected(ValueError):
    """A framing that would teach the wrong thing."""


def notation_faults(text: str) -> list[str]:
    faults: list[str] = []
    for pattern in TOOL_NOTATION:
        found = pattern.findall(text)
        if found:
            faults.append(str(found[0]))
    return faults


class Teacher:
    """One REALLMS channel, checkpointed to a resumable cache."""

    def __init__(self, cache: Path, model: str | None = None, dry_run: bool = False) -> None:
        llm.load_dotenv(REPO_ROOT)
        self.key = llm.load_key(REPO_ROOT)
        self.url = llm.resolve_api_url()
        self.model = model or llm.resolve_model()
        self.ssl: ssl.SSLContext | None = None if dry_run else llm.build_ssl_context()
        self.dry_run = dry_run
        self.cache_path = cache
        self.cache: dict[str, Any] = {}
        self.calls = 0
        self.rejections: dict[str, int] = {}
        self.usage = {"prompt_tokens": 0, "completion_tokens": 0}
        self.failures: list[str] = []
        if cache.is_file():
            for line in cache.read_text(encoding="utf-8").splitlines():
                if line.strip():
                    row = json.loads(line)
                    self.cache[row["key"]] = row["value"]
        cache.parent.mkdir(parents=True, exist_ok=True)
        self.handle = cache.open("a", encoding="utf-8")

    def close(self) -> None:
        self.handle.close()

    def reject(self, reason: str) -> None:
        self.rejections[reason] = self.rejections.get(reason, 0) + 1

    def remember(self, key: str, value: Any) -> None:
        self.cache[key] = value
        self.handle.write(json.dumps({"key": key, "value": value}, ensure_ascii=False) + "\n")
        self.handle.flush()

    def ask(self, key: str, prompt: str, max_tokens: int = MAX_TOKENS, timeout: int = 120) -> Any:
        """One cached call. A cached key never spends the channel again."""
        if key in self.cache:
            return self.cache[key]
        if self.dry_run:
            # Offline assembly: a cache miss is a missing framing, not a
            # reason to open the channel. Every call already made is on disk.
            self.reject("cache miss while offline")
            return None
        started = time.time()
        result = llm.call_api_result(
            SYSTEM, prompt, api_key=self.key, api_url=self.url, model=self.model,
            ssl_ctx=self.ssl, retries=2, timeout=timeout, max_tokens=max_tokens,
        )
        self.calls += 1
        # Never parse content unless the outcome is ok: a starved reply lands
        # reasoning in content with finish_reason length, and reads as an answer.
        if result.outcome != "ok":
            self.failures.append(f"{key}: {result.outcome} {result.error or ''}".strip())
            self.reject(f"channel {result.outcome}")
            return None
        for field in ("prompt_tokens", "completion_tokens"):
            self.usage[field] += int((result.usage or {}).get(field, 0) or 0)
        parsed = extract_json(result.content)
        if parsed is None:
            self.failures.append(f"{key}: unparseable reply after {time.time() - started:.1f}s")
            self.reject("unparseable reply")
            return None
        self.remember(key, parsed)
        return parsed


def extract_json(text: str) -> Any:
    """Read the object out of a reply that may be fenced or prefaced."""
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = re.sub(r"^```[a-zA-Z]*\s*", "", stripped)
        stripped = re.sub(r"\s*```$", "", stripped)
    try:
        return json.loads(stripped)
    except json.JSONDecodeError:
        pass
    start, end = stripped.find("{"), stripped.rfind("}")
    if start >= 0 and end > start:
        try:
            return json.loads(stripped[start : end + 1])
        except json.JSONDecodeError:
            return None
    return None


def admissible(turn: str, forbidden_answer: Sequence[str] = ()) -> tuple[bool, str]:
    """Decide whether one framing may enter the set, and say why not."""
    text = turn.strip()
    if not text:
        return False, "empty"
    if len(text) < 25:
        return False, "too short to be a turn"
    if len(text) > 600:
        return False, "too long to be a turn"
    faults = notation_faults(text)
    if faults:
        return False, f"tool notation in the turn: {faults[0]}"
    lowered = text.casefold()
    for answer in forbidden_answer:
        if answer and answer.casefold() in lowered:
            return False, "the turn states the answer"
    return True, ""


def framing_prompt(kind: str, subject: str, seed: dict[str, Any], count: int) -> str:
    """Ask for `count` turns about one already-executed piece of mathematics."""
    detail = json.dumps({key: value for key, value in seed.items() if value not in (None, "", [])},
                        ensure_ascii=False)
    shapes = {
        "narrative": (
            "Each turn must describe something that happened in the classroom — what a named or "
            "unnamed child did, said, or wrote — and then ask the assistant for help. The "
            "mathematics must be carried by the story in ordinary words, not requested by name."
        ),
        "direct": (
            "Each turn asks the assistant directly for the thing described, the way a teacher "
            "in a hurry would ask a colleague."
        ),
        "limit": (
            "Each turn asks for something the assistant will turn out not to have. Write the turn "
            "as though the teacher expects an answer; do not hint that anything is missing."
        ),
        "surface": (
            "Each turn mentions this mathematics but asks a question about teaching that no lookup "
            "could answer — about grading, seating, timing, parents, or what to say to a child. "
            "The mathematics must appear; the question must not be answerable by looking anything up."
        ),
        "known_fact": (
            "Each turn asks a small arithmetic or vocabulary question a teacher would expect an "
            "immediate answer to, with no classroom story attached."
        ),
        "out_of_scope": (
            "Each turn asks for help with something entirely outside mathematics content — "
            "classroom management, a colleague, a parent, timing, or the teacher's own workload."
        ),
    }
    return (
        f"Subject: {subject}\n"
        f"Details: {detail}\n\n"
        f"{shapes[kind]}\n\n"
        f"Write {count} different turns. Reply exactly as "
        f'{{"turns": [{", ".join(chr(34) + "..." + chr(34) for _ in range(min(count, 3)))}]}}'
    )


def reply_prompt(subject: str, result_digest: str, count: int) -> str:
    return (
        f"An assistant asked its knowledge base about {subject} and received exactly this:\n"
        f"{result_digest}\n\n"
        f"Write {count} different one-or-two-sentence replies the assistant could give the teacher. "
        "Every reply must state only what is in the result above. Do not add mathematics, numbers, "
        "names, or advice that is not there. Do not mention tools, lookups, or databases.\n"
        'Reply exactly as {"replies": ["...", "..."]}'
    )


def batches(items: Sequence[Any], size: int) -> Iterable[Sequence[Any]]:
    for start in range(0, len(items), size):
        yield items[start : start + size]


def main() -> int:
    """A channel smoke: one framing batch and one reply batch, cached."""
    import argparse

    from dataset import RUNTIME

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache", type=Path, default=RUNTIME / "teacher" / "smoke.jsonl")
    arguments = parser.parse_args()

    teacher = Teacher(arguments.cache)
    try:
        framings = teacher.ask(
            "smoke-framing",
            framing_prompt(
                "narrative",
                "a student adding one seventh and one seventh and writing one fourteenth",
                {"student_wrote": "one seventh and one seventh as one fourteenth", "domain": "fraction"},
                3,
            ),
        )
        print(json.dumps(framings, indent=2)[:800])
        for turn in (framings or {}).get("turns", []):
            ok, why = admissible(turn)
            print(f"  {'admit ' if ok else 'REJECT'} {why:40s} {turn[:70]}")
        print(f"calls {teacher.calls} usage {teacher.usage} failures {teacher.failures}")
    finally:
        teacher.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
