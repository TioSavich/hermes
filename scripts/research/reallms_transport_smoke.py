#!/usr/bin/env python3
"""Five-call live smoke for the REALLMS thinking-model transport contract.

The controller runs this script where REALLMS is reachable. Each completed
call is written atomically before the next call begins.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app import llm  # noqa: E402

RUN_VERSION = "reallms-transport-v1"
EMPTY_SENTINEL = "FINAL_CHANNEL_MUST_BE_EMPTY"


def atomic_write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(path)


def prompt_hash(messages: list[dict[str, str]]) -> str:
    encoded = json.dumps(
        messages, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def usage_shape_ok(result: llm.ReallmsResult) -> bool:
    usage = result.usage
    details = usage.get("prompt_tokens_details", {})
    return (
        all(name in usage for name in ("completion_tokens", "prompt_tokens", "total_tokens"))
        and isinstance(details, dict)
        and "cached_tokens" in details
        and all(name in usage for name in ("ttft_s", "tpot_s", "latency_s"))
    )


def clean_validator(result: llm.ReallmsResult) -> tuple[bool, str]:
    passed = (
        result.outcome == "ok"
        and result.finish_reason == "stop"
        and bool(result.content.strip())
        and bool(result.reasoning_content.strip())
        and result.content != result.reasoning_content
        and usage_shape_ok(result)
    )
    return passed, (
        "final and reasoning channels separated with stop finish and measured usage"
        if passed
        else "expected nonempty distinct channels, stop finish, and the measured usage fields"
    )


def starvation_validator(result: llm.ReallmsResult) -> tuple[bool, str]:
    passed = result.outcome == "truncated" and not result.ok and result.finish_reason == "length"
    return passed, (
        "length finish classified truncated; content is diagnostic only"
        if passed
        else "small-budget response must be length-finished and never classify ok"
    )


def empty_validator(result: llm.ReallmsResult) -> tuple[bool, str]:
    raw_content = ""
    try:
        raw_content = result.raw_response["choices"][0]["message"].get("content") or ""
    except (KeyError, IndexError, TypeError, AttributeError):
        pass
    passed = (
        result.outcome == "empty_content"
        and result.content == ""
        and EMPTY_SENTINEL in raw_content
    )
    return passed, (
        "local final-channel stop produced an empty final without altering the raw response"
        if passed
        else "expected sentinel in raw final content and empty_content after local final isolation"
    )


def http_validator(result: llm.ReallmsResult) -> tuple[bool, str]:
    passed = result.outcome == "http_error" and result.status_code is not None
    return passed, (
        "bad model name returned a branchable HTTP error"
        if passed
        else "bad model name must classify http_error"
    )


def fraction_validator(result: llm.ReallmsResult) -> tuple[bool, str]:
    passed = (
        result.outcome == "ok"
        and result.finish_reason == "stop"
        and len(result.content.strip()) >= 80
    )
    return passed, (
        "text-rich fraction response completed in the final channel"
        if passed
        else "fraction task needs a nontrivial, stop-finished final response"
    )


def cases(default_budget: int, model: str) -> list[dict[str, Any]]:
    clean_messages = [
        {
            "role": "user",
            "content": (
                "Answer in exactly one sentence: A student says 7/8 + 1/8 = 8/16. "
                "State the correct sum and name the student's operation error."
            ),
        }
    ]
    starvation_messages = [
        {
            "role": "user",
            "content": (
                "Reason carefully about the mathematical structure before answering. "
                "A student claims 3/5 + 1/10 = 4/15. Determine the correct sum, identify "
                "the exact denominator mistake, and end with one concise instructional question."
            ),
        }
    ]
    empty_messages = [
        {
            "role": "user",
            "content": (
                f"Return exactly this token and no other final text: {EMPTY_SENTINEL}"
            ),
        }
    ]
    bad_model_messages = [
        {"role": "user", "content": "Return the word ready."}
    ]
    fraction_messages = [
        {
            "role": "system",
            "content": (
                "Respond as a mathematics tutor. Address only the written work. Preserve "
                "the distinction between what the student wrote and what follows mathematically."
            ),
        },
        {
            "role": "user",
            "content": (
                "A student writes: '3/4 + 1/2 = 4/6 because I added the tops and then "
                "the bottoms.' Write one compact paragraph that states the correct sum, "
                "describes the specific mistake without diagnosing the student, uses an "
                "equivalent-fraction step, and ends with one question the tutor could ask."
            ),
        },
    ]
    return [
        {
            "name": "clean_two_channel",
            "messages": clean_messages,
            "model": model,
            "max_tokens": default_budget,
            "final_stop_sequences": (),
            "expected": "ok",
            "validator": clean_validator,
        },
        {
            "name": "starvation_leak",
            "messages": starvation_messages,
            "model": model,
            "max_tokens": 100,
            "final_stop_sequences": (),
            "expected": "truncated",
            "validator": starvation_validator,
        },
        {
            "name": "empty_content",
            "messages": empty_messages,
            "model": model,
            "max_tokens": default_budget,
            "final_stop_sequences": (EMPTY_SENTINEL,),
            "expected": "empty_content",
            "validator": empty_validator,
        },
        {
            "name": "bad_model_http_error",
            "messages": bad_model_messages,
            "model": f"{model}-transport-smoke-invalid",
            "max_tokens": 100,
            "final_stop_sequences": (),
            "expected": "http_error",
            "validator": http_validator,
        },
        {
            "name": "text_rich_fraction_mistake",
            "messages": fraction_messages,
            "model": model,
            "max_tokens": default_budget,
            "final_stop_sequences": (),
            "expected": "ok",
            "validator": fraction_validator,
        },
    ]


def print_verdicts(records: list[dict[str, Any]]) -> None:
    headers = ("checkpoint", "outcome", "finish", "verdict")
    rows = [
        (
            record["name"],
            record["result"]["outcome"],
            record["result"]["finish_reason"] or "-",
            "PASS" if record["passed"] else "FAIL",
        )
        for record in records
    ]
    widths = [
        max(len(headers[index]), *(len(str(row[index])) for row in rows))
        for index in range(len(headers))
    ]
    print("  ".join(headers[index].ljust(widths[index]) for index in range(len(headers))))
    print("  ".join("-" * width for width in widths))
    for row in rows:
        print("  ".join(str(row[index]).ljust(widths[index]) for index in range(len(row))))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, required=True, help="checkpoint output directory")
    parser.add_argument("--model", default="glm-5.2")
    parser.add_argument("--max-tokens", type=int, default=llm.DEFAULT_MAX_TOKENS)
    parser.add_argument("--timeout", type=int, default=600)
    args = parser.parse_args(argv)

    client = llm.make_client(ROOT)
    client["model"] = args.model
    specs = cases(args.max_tokens, args.model)
    hashes = {spec["name"]: prompt_hash(spec["messages"]) for spec in specs}
    manifest = {
        "run_version": RUN_VERSION,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "model": args.model,
        "endpoint": client["api_url"],
        "prompt_hash": hashlib.sha256(
            "".join(hashes[name] for name in sorted(hashes)).encode("ascii")
        ).hexdigest(),
        "prompt_hashes": hashes,
        "calls": [
            {
                "checkpoint": index,
                "name": spec["name"],
                "model": spec["model"],
                "max_tokens": spec["max_tokens"],
                "expected": spec["expected"],
            }
            for index, spec in enumerate(specs, 1)
        ],
    }
    args.out.mkdir(parents=True, exist_ok=True)
    atomic_write_json(args.out / "manifest.json", manifest)

    records: list[dict[str, Any]] = []
    for index, spec in enumerate(specs, 1):
        result = llm.call_api_messages_result(
            spec["messages"],
            api_key=client["api_key"],
            api_url=client["api_url"],
            model=spec["model"],
            ssl_ctx=client["ssl_ctx"],
            retries=2,
            timeout=args.timeout,
            max_tokens=spec["max_tokens"],
            final_stop_sequences=spec["final_stop_sequences"],
        )
        validator: Callable[[llm.ReallmsResult], tuple[bool, str]] = spec["validator"]
        passed, note = validator(result)
        record = {
            "run_version": RUN_VERSION,
            "checkpoint": index,
            "name": spec["name"],
            "model": spec["model"],
            "endpoint": client["api_url"],
            "prompt_sha256": hashes[spec["name"]],
            "max_tokens": spec["max_tokens"],
            "expected": spec["expected"],
            "passed": passed,
            "note": note,
            "result": result.to_dict(),
        }
        atomic_write_json(args.out / f"{index:02d}_{spec['name']}.json", record)
        records.append(record)

    print_verdicts(records)
    passed = all(record["passed"] for record in records)
    print(f"\ntransport smoke: {'PASS' if passed else 'FAIL'} ({sum(r['passed'] for r in records)}/5)")
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
