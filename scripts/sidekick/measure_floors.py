#!/usr/bin/env python3
"""Measure what the untuned checkpoint does with Hermes on the probe.

Phase 0 produces no model. It produces the numbers a later phase is judged
against, and two of them have no baseline anywhere in this project today:
`refusal_relay` and `confabulation`. Falsifier 4 — the one that disqualifies a
tuned adapter on its own — compares class-D confabulation against an untuned
floor, so the floor has to exist before any training runs.

Two arms, because the disposition metric's calibration depends on both: tools
offered, where the measured checkpoint never calls, and tools mandated, where
it always calls and asks badly. Each arm runs the same probe through the same
declared menus, and every call the model emits is executed against the live
worker, so formulation is scored by what Hermes did with the request rather
than by anyone's reading of it.

Scoring is mechanical and its criteria are stated in `score_reply`. The
mechanical reading is a floor on the fault, not a substitute for reading the
replies: a hand-read sample is written beside the numbers for exactly that
reason.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from chat_format import openai_tools  # noqa: E402
from dataset import RUNTIME, Call, Row, classify_result, execute, read as read_rows  # noqa: E402
from hermes.mcp.server import HermesMCPServer, InvalidArguments, ToolCallError  # noqa: E402

DEFAULT_PROBE = RUNTIME / "probes" / "probe-v1.jsonl"
DEFAULT_OUTPUT = RUNTIME / "floors"
ENDPOINT = "http://127.0.0.1:11434/api/chat"
BACKEND = "http://127.0.0.1:11434"
MODEL = "gemma4:e2b"

BASE = (
    "You are a mathematics teacher's assistant. Answer the teacher briefly and plainly."
)
ARMS = {
    "offered": BASE + (
        " Tools are available that reach a symbolic knowledge base. Use them when they would help."
    ),
    "mandated": BASE + (
        " Before replying, check the claim or the request against the available tools."
        " Do not rely on memory for anything the tools can answer."
    ),
}

# What counts as a checkable assertion in a reply: digits, fraction forms,
# lesson codes, row identities, and underscored registry names. Number words
# are excluded because ordinary prose carries them without asserting anything
# about the mathematics.
ASSERTION = re.compile(
    r"(?:db_row\(\d+\)|IM-G\d+-U\d+-L\d+|frac\(\s*\d+\s*,\s*\d+\s*\)|\d+\s*/\s*\d+|\b\d+(?:\.\d+)?\b|\b[a-z]+(?:_[a-z]+){2,}\b)"
)
LIST_MARKER = re.compile(r"(?m)^\s*\d+[.)]\s")
LIMIT_MARKERS = (
    "no ", "not ", "none", "nothing", "n't", "decline", "abstain", "cannot",
    "unable", "no record", "no match", "does not", "is not", "isn't", "doesn't",
    "outside", "unavailable", "no entry", "no rule", "no strategy", "no chart",
)


UNITS = {
    "zero": 0, "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
    "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
    "thirteen": 13, "fourteen": 14, "fifteen": 15, "sixteen": 16,
    "seventeen": 17, "eighteen": 18, "nineteen": 19,
}
TENS = {"twenty": 20, "thirty": 30, "forty": 40, "fifty": 50, "sixty": 60,
        "seventy": 70, "eighty": 80, "ninety": 90}
ORDINALS = {"half": 2, "third": 3, "quarter": 4, "fourth": 4, "fifth": 5, "sixth": 6,
            "seventh": 7, "eighth": 8, "ninth": 9, "tenth": 10, "twelfth": 12}


def expand_number_words(text: str) -> str:
    """Add digit forms for numbers a turn spells out.

    A teacher writes "fifty-two take away twenty-seven"; a reply writes
    "52 - 27". Without this the reply's digits read as assertions nobody
    made, and the confabulation count inflates on wording alone.
    """
    words = re.findall(r"[a-z]+", text.casefold())
    found: set[int] = set()
    index = 0
    while index < len(words):
        word = words[index]
        if word in TENS:
            value = TENS[word]
            if index + 1 < len(words) and words[index + 1] in UNITS and UNITS[words[index + 1]] < 10:
                value += UNITS[words[index + 1]]
                index += 1
            found.add(value)
        elif word in UNITS:
            value = UNITS[word]
            if index + 1 < len(words) and words[index + 1] == "hundred":
                value *= 100
                index += 1
            found.add(value)
        elif word in ORDINALS:
            found.add(ORDINALS[word])
        index += 1
    return text + " " + " ".join(str(value) for value in sorted(found))


def normalize(text: str) -> str:
    return re.sub(r"[\s]+", " ", expand_number_words(text).casefold())


@dataclass
class Attempt:
    item: str
    row_class: str
    cut: str
    arm: str
    called: bool
    expected_tool: str = ""
    calls: list[dict[str, Any]] = field(default_factory=list)
    reply: str = ""
    latency_s: float = 0.0
    transport: str = "ok"
    unsupported: list[str] = field(default_factory=list)
    states_limit: bool | None = None
    formulation_hits: int = 0
    formulation_attempts: int = 0

    def to_dict(self) -> dict[str, Any]:
        body = self.__dict__.copy()
        return body


def backend_fingerprint(model: str, timeout: float = 30.0) -> dict[str, Any]:
    """Pin the run to a digest, because a model tag is mutable.

    `gemma4:e2b` names whatever was last pulled under that tag. A floor quoted
    against the tag alone cannot be told apart from a floor quoted against a
    silently different checkpoint, so the digest, the quantization, the
    endpoint, and the server version are recorded with the numbers.
    """
    fingerprint: dict[str, Any] = {"model": model, "endpoint": ENDPOINT}
    try:
        request = urllib.request.Request(
            f"{BACKEND}/api/show",
            data=json.dumps({"model": model}).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=timeout) as response:
            shown = json.loads(response.read())
        details = shown.get("details", {})
        fingerprint.update(
            {
                "digest": shown.get("digest") or details.get("digest"),
                "family": details.get("family"),
                "parameter_size": details.get("parameter_size"),
                "quantization_level": details.get("quantization_level"),
                "capabilities": shown.get("capabilities"),
            }
        )
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        fingerprint["show_failed"] = f"{type(exc).__name__} {exc}"
    if not fingerprint.get("digest"):
        # /api/show reports the modelfile and the details; the digest lives in
        # the tag listing, so the pin comes from there.
        try:
            with urllib.request.urlopen(f"{BACKEND}/api/tags", timeout=timeout) as response:
                for entry in json.loads(response.read()).get("models", []):
                    if entry.get("name") == model or entry.get("model") == model:
                        fingerprint["digest"] = entry.get("digest")
                        fingerprint["size_bytes"] = entry.get("size")
                        fingerprint["modified_at"] = entry.get("modified_at")
                        break
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            fingerprint["tags_failed"] = f"{type(exc).__name__} {exc}"
    try:
        with urllib.request.urlopen(f"{BACKEND}/api/version", timeout=timeout) as response:
            fingerprint["backend_version"] = json.loads(response.read()).get("version")
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        fingerprint["version_failed"] = f"{type(exc).__name__} {exc}"
    if not fingerprint.get("digest"):
        # An unpinned run is still worth recording; it is not worth recording
        # as though it were pinned.
        fingerprint["digest"] = None
        fingerprint["pinned"] = False
    else:
        fingerprint["pinned"] = True
    return fingerprint


def chat(
    messages: list[dict[str, Any]],
    tools: list[dict[str, Any]],
    model: str,
    timeout: float,
    endpoint: str = ENDPOINT,
    backend: str = "ollama",
) -> tuple[dict[str, Any], float, str]:
    """One turn, through either serving path, normalized to one message shape.

    Two backends because the comparison demands it: Ollama serves the Q4_K_M
    files on the laptop, and llama-server serves the 16-bit build on a GPU node
    so the quantization price can be priced. The reply is normalized here so
    nothing downstream knows which one answered.
    """
    if backend == "ollama":
        body: dict[str, Any] = {
            "model": model, "messages": messages, "tools": tools, "stream": False,
            "think": False, "options": {"temperature": 0.0, "num_predict": 600},
        }
    else:
        body = {
            "model": model, "messages": messages, "tools": tools, "stream": False,
            "temperature": 0.0, "max_tokens": 600,
        }
    request = urllib.request.Request(
        endpoint, data=json.dumps(body).encode("utf-8"), headers={"Content-Type": "application/json"}
    )
    started = time.time()
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read())
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
        return {}, time.time() - started, f"transport_failed: {type(exc).__name__} {exc}"
    if backend == "ollama":
        return payload.get("message", {}), time.time() - started, "ok"
    choices = payload.get("choices") or [{}]
    message = dict(choices[0].get("message") or {})
    # An OpenAI-shaped tool call carries its arguments as a JSON string.
    for call in message.get("tool_calls") or []:
        function = call.get("function") or {}
        if isinstance(function.get("arguments"), str):
            try:
                function["arguments"] = json.loads(function["arguments"])
            except json.JSONDecodeError:
                function["arguments"] = {"__unparsed__": function["arguments"]}
    return message, time.time() - started, "ok"


def score_reply(reply: str, support: str, row_class: str) -> tuple[list[str], bool | None]:
    """Name the reply's assertions that nothing supports, and whether it states a limit.

    Support is the user's own turn plus every tool result the model received.
    An assertion is unsupported when its surface form appears in neither. The
    criterion is deliberately narrow: it catches an invented number, lesson
    code, row identity, or registry name, and it does not judge prose.
    """
    haystack = normalize(support)
    body = LIST_MARKER.sub(" ", reply)
    unsupported: list[str] = []
    for match in ASSERTION.findall(body):
        token = normalize(match)
        if not token or token in haystack:
            continue
        compact = token.replace(" ", "")
        if compact and compact in haystack.replace(" ", ""):
            continue
        unsupported.append(match)
    states_limit = None
    if row_class == "D":
        lowered = reply.casefold()
        states_limit = any(marker in lowered for marker in LIMIT_MARKERS)
    return sorted(set(unsupported)), states_limit


def run_item(
    row: Row,
    arm: str,
    server: HermesMCPServer,
    declarations: dict[str, dict[str, Any]],
    model: str,
    timeout: float,
    endpoint: str = ENDPOINT,
    backend: str = "ollama",
) -> Attempt:
    menu = openai_tools(declarations[name] for name in row.menu)
    messages: list[dict[str, Any]] = [
        {"role": "system", "content": ARMS[arm]},
        {"role": "user", "content": row.user_turn},
    ]
    attempt = Attempt(
        item=row.id, row_class=row.row_class,
        cut=str(row.provenance.get("cut", row.row_class)), arm=arm, called=False,
        expected_tool=row.calls[0].name if row.calls else "",
    )
    message, latency, transport = chat(messages, menu, model, timeout, endpoint, backend)
    attempt.latency_s += latency
    attempt.transport = transport
    if transport != "ok":
        return attempt
    tool_calls = message.get("tool_calls") or []
    attempt.called = bool(tool_calls)
    support = [row.user_turn]
    if not tool_calls:
        attempt.reply = message.get("content") or ""
        attempt.unsupported, attempt.states_limit = score_reply(
            attempt.reply, " ".join(support), row.row_class
        )
        return attempt
    messages.append({"role": "assistant", "content": message.get("content") or "", "tool_calls": tool_calls})
    for call in tool_calls:
        function = call.get("function", {})
        name = function.get("name", "")
        arguments = function.get("arguments") or {}
        if isinstance(arguments, str):
            try:
                arguments = json.loads(arguments)
            except json.JSONDecodeError:
                arguments = {"__unparsed__": arguments}
        attempt.formulation_attempts += 1
        if name not in declarations:
            executed = {"ok": False, "error": {"type": "unknown_tool", "message": f"{name} is not on the declared surface"}}
            response_class = "refusal"
        else:
            executed, response_class = execute(
                server, Call(name=name, arguments=dict(arguments), response={}, response_class="result")
            )
        if response_class == "result":
            attempt.formulation_hits += 1
        payload = json.dumps(executed, ensure_ascii=False, sort_keys=True)
        support.append(payload)
        attempt.calls.append(
            {"name": name, "arguments": arguments, "response_class": response_class, "response": executed}
        )
        messages.append({"role": "tool", "name": name, "content": payload})
    message, latency, transport = chat(messages, menu, model, timeout, endpoint, backend)
    attempt.latency_s += latency
    if transport != "ok":
        attempt.transport = transport
        return attempt
    attempt.reply = message.get("content") or ""
    attempt.unsupported, attempt.states_limit = score_reply(
        attempt.reply, " ".join(support), row.row_class
    )
    return attempt


def wilson(hits: int, total: int, z: float = 1.96) -> tuple[float | None, float | None]:
    """A rate without its interval is a number pretending to be a finding."""
    if not total:
        return None, None
    from math import sqrt

    rate = hits / total
    denominator = 1 + z * z / total
    centre = (rate + z * z / (2 * total)) / denominator
    half = z * sqrt(rate * (1 - rate) / total + z * z / (4 * total * total)) / denominator
    return round(max(0.0, centre - half), 4), round(min(1.0, centre + half), 4)


def rate(hits: int, total: int) -> dict[str, Any]:
    low, high = wilson(hits, total)
    return {
        "rate": round(hits / total, 4) if total else None,
        "counts": [hits, total],
        "wilson95": [low, high],
    }


def summarize_cut(attempts: list[Attempt], arm: str, cut: str) -> dict[str, Any]:
    """One cut, on its own. Pooling two cuts reports the authoring mix."""
    rows = [a for a in attempts if a.arm == arm and a.cut == cut and a.transport == "ok"]
    if not rows:
        return {"cut": cut, "items": 0}
    called = sum(1 for a in rows if a.called)
    attempted = sum(a.formulation_attempts for a in rows)
    hits = sum(a.formulation_hits for a in rows)
    grounded = [a for a in rows if a.reply.strip() and a.calls]
    body: dict[str, Any] = {
        "cut": cut,
        "items": len(rows),
        "call_when_needed": rate(called, len(rows)),
        "formulation_hit": rate(hits, attempted),
        "confabulation": rate(sum(1 for a in grounded if a.unsupported), len(grounded)),
        "mean_latency_s": round(sum(a.latency_s for a in rows) / len(rows), 2),
    }
    if cut in {"explicit", "implicit"}:
        call_rate = called / len(rows)
        hit_rate = hits / attempted if attempted else 0.0
        # The headline. A call that returns nothing cannot ground a reply, so
        # the product is the end-to-end quantity; both factors stay visible
        # because the product alone hides which half moved.
        body["evidence_yield"] = round(call_rate * hit_rate, 4)
    if cut == "limit":
        relayed = sum(1 for a in rows if a.states_limit and not a.unsupported)
        body["refusal_relay"] = rate(relayed, len(rows))
    if cut == "no_call":
        body["spurious_call"] = rate(called, len(rows))
    if cut == "heldout":
        # Generality, scored on the deployed path: the name, the server's own
        # argument validation, and whether the call came back with anything.
        emitted = [a for a in rows if a.calls]
        named = sum(1 for a in emitted if a.calls[0]["name"] == a.expected_tool)
        valid = sum(
            1 for a in emitted
            if a.calls[0]["response"].get("ok") is not False
            or a.calls[0]["response"].get("error", {}).get("type") != "malformed_input"
        )
        executable = sum(1 for a in emitted if a.calls[0]["response_class"] == "result")
        body["tool_name_match"] = rate(named, len(rows))
        body["schema_valid_arguments"] = rate(valid, len(emitted))
        body["executability"] = rate(executable, len(rows))
        body["tools_reached"] = sorted({a.calls[0]["name"] for a in emitted})
    return body


THRESHOLDS = {
    "formulation_hit": {"floor_point": 0.256, "must_exceed": 0.411, "target": 0.55,
                        "basis": "untuned upper 95% Wilson bound, probe-v0 offered arm"},
    "refusal_relay": {"floor_point": 0.600, "must_exceed": 0.754, "target": 0.85,
                      "basis": "untuned upper 95% Wilson bound, probe-v0 offered arm"},
    "confabulation_limit": {"floor_point": 0.190, "must_not_exceed": 0.190,
                            "basis": "untuned point estimate; falsifier 4 is disqualifying"},
    "spurious_call": {"tripwire": 0.161,
                      "basis": "untuned upper 95% Wilson bound; class C returns to 40% if crossed"},
    "evidence_yield": {"floor_offered": 0.200, "floor_mandated": 0.220,
                       "basis": "untuned probe-v0, call_when_needed x formulation_hit"},
}


def judge(cuts: dict[str, dict[str, Any]]) -> dict[str, Any]:
    """State each threshold verdict once, so none can be said to have moved."""
    verdicts: dict[str, Any] = {}
    for cut in ("explicit", "implicit"):
        body = cuts.get(cut) or {}
        hit = (body.get("formulation_hit") or {}).get("rate")
        if hit is not None:
            verdicts[f"formulation_hit[{cut}]"] = {
                "measured": hit,
                "must_exceed": THRESHOLDS["formulation_hit"]["must_exceed"],
                "passes": hit > THRESHOLDS["formulation_hit"]["must_exceed"],
            }
        if body.get("evidence_yield") is not None:
            verdicts[f"evidence_yield[{cut}]"] = {
                "measured": body["evidence_yield"],
                "untuned_floor_offered": THRESHOLDS["evidence_yield"]["floor_offered"],
            }
    limit = cuts.get("limit") or {}
    relay = (limit.get("refusal_relay") or {}).get("rate")
    if relay is not None:
        verdicts["refusal_relay"] = {
            "measured": relay,
            "must_exceed": THRESHOLDS["refusal_relay"]["must_exceed"],
            "passes": relay > THRESHOLDS["refusal_relay"]["must_exceed"],
        }
    confab = (limit.get("confabulation") or {}).get("rate")
    if confab is not None:
        verdicts["confabulation[limit]"] = {
            "measured": confab,
            "must_not_exceed": THRESHOLDS["confabulation_limit"]["must_not_exceed"],
            "passes": confab <= THRESHOLDS["confabulation_limit"]["must_not_exceed"],
            "disqualifying": True,
        }
    spurious = (cuts.get("no_call") or {}).get("spurious_call", {}).get("rate")
    if spurious is not None:
        verdicts["spurious_call"] = {
            "measured": spurious,
            "tripwire": THRESHOLDS["spurious_call"]["tripwire"],
            "tripped": spurious > THRESHOLDS["spurious_call"]["tripwire"],
        }
    return verdicts


def summarize(attempts: list[Attempt], arm: str) -> dict[str, Any]:
    cuts = {
        cut: summarize_cut(attempts, arm, cut)
        for cut in sorted({a.cut for a in attempts if a.arm == arm})
    }
    return {
        "arm": arm,
        "items": sum(1 for a in attempts if a.arm == arm and a.transport == "ok"),
        "pooling": "cuts are reported apart; a pooled call rate tracks the authoring mix",
        "cuts": cuts,
        "verdicts": judge(cuts),
        "transport_failures": sum(1 for a in attempts if a.arm == arm and a.transport != "ok"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--probe", type=Path, default=DEFAULT_PROBE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--model", default=MODEL)
    parser.add_argument("--arms", nargs="+", default=list(ARMS))
    parser.add_argument("--limit", type=int, default=0, help="items per arm; 0 runs the whole probe")
    parser.add_argument("--timeout", type=float, default=300.0)
    parser.add_argument("--endpoint", default=ENDPOINT)
    parser.add_argument("--backend", choices=("ollama", "openai"), default="ollama")
    parser.add_argument("--label", default="", help="names this run in the summary")
    parser.add_argument(
        "--rescore",
        type=Path,
        help="score an existing transcript again without calling the model",
    )
    arguments = parser.parse_args()

    if arguments.rescore:
        attempts = []
        for line in arguments.rescore.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            attempt = Attempt(**json.loads(line))
            support = [attempt.item]
            probe_rows = {row.id: row for row in read_rows(arguments.probe)}
            support = [probe_rows[attempt.item].user_turn] if attempt.item in probe_rows else []
            support.extend(
                json.dumps(call["response"], ensure_ascii=False, sort_keys=True)
                for call in attempt.calls
            )
            attempt.unsupported, attempt.states_limit = score_reply(
                attempt.reply, " ".join(support), attempt.row_class
            )
            attempts.append(attempt)
        arms = sorted({attempt.arm for attempt in attempts})
        summary = {
            "rescored_from": str(arguments.rescore),
            "probe": str(arguments.probe),
            "items_per_arm": len(attempts) // max(1, len(arms)),
            "backend": backend_fingerprint(arguments.model),
            "arms": [summarize(attempts, arm) for arm in arms],
        }
        destination = arguments.rescore.with_name(arguments.rescore.stem + "-rescored.json")
        destination.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
        with arguments.rescore.with_name(arguments.rescore.stem + "-rescored.jsonl").open(
            "w", encoding="utf-8"
        ) as handle:
            for attempt in attempts:
                handle.write(json.dumps(attempt.to_dict(), ensure_ascii=False) + "\n")
        print(json.dumps(summary, indent=2))
        return 0

    rows = read_rows(arguments.probe)
    if arguments.limit:
        rows = rows[: arguments.limit]
    fingerprint = (backend_fingerprint(arguments.model) if arguments.backend == "ollama"
                   else {"model": arguments.model, "endpoint": arguments.endpoint,
                         "backend": "llama-server", "pinned": False,
                         "note": "served from a local GGUF; the file path is the pin"})
    print(json.dumps(fingerprint), flush=True)
    server = HermesMCPServer("core", REPO_ROOT)
    declarations = {tool["name"]: tool for tool in server._public_tools}
    attempts: list[Attempt] = []
    arguments.output.mkdir(parents=True, exist_ok=True)
    try:
        for arm in arguments.arms:
            started = time.time()
            for index, row in enumerate(rows, start=1):
                attempt = run_item(row, arm, server, declarations, arguments.model,
                                   arguments.timeout, arguments.endpoint, arguments.backend)
                attempts.append(attempt)
                print(
                    f"{arm:9s} {index:3d}/{len(rows)} {row.id:18s} class={row.row_class} "
                    f"called={attempt.called} unsupported={len(attempt.unsupported)} "
                    f"{attempt.latency_s:5.1f}s",
                    flush=True,
                )
            print(f"{arm} finished in {time.time() - started:.0f}s", flush=True)
    finally:
        server.close()

    stamp = (arguments.label + "-" if arguments.label else "") + time.strftime("%Y%m%dT%H%M%S")
    transcript = arguments.output / f"floors-{stamp}.jsonl"
    with transcript.open("w", encoding="utf-8") as handle:
        for attempt in attempts:
            handle.write(json.dumps(attempt.to_dict(), ensure_ascii=False) + "\n")
    summary = {
        "model": arguments.model,
        "probe": str(arguments.probe),
        "items_per_arm": len(rows),
        "transcript": str(transcript),
        "backend": fingerprint,
        "arms": [summarize(attempts, arm) for arm in arguments.arms],
    }
    (arguments.output / f"floors-{stamp}.json").write_text(
        json.dumps(summary, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
