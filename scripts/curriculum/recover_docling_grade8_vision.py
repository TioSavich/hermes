#!/usr/bin/env python3
"""Run a small, provenance-gated vision residue for Grade 8 recovery.

The default worklist contains only still-blocked image rows whose existing
picture description explicitly transcribes task text. A model result is parsed
only when the shared REALLMS client reports ``ok``. Acceptance additionally
requires a certain verbatim statement that occurs in the picture description.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from scripts.curriculum import extract_docling_grade as extraction  # noqa: E402
from scripts.curriculum import recover_docling_grade8 as recovery  # noqa: E402
from scripts.curriculum import vision_pass  # noqa: E402
from scripts.curriculum import vision_statement_contract  # noqa: E402


MODEL = "gemma-4-31B-it"
MAX_TOKENS = 2500
HARD_CALL_BUDGET = 300
DEFAULT_OUTPUT = recovery.DEFAULT_RECOVERY_DIR / "vision"
DESCRIPTION_TRANSCRIPT_RE = re.compile(
    r"\b(?:text reads|reads as follows|textual description)\b", re.I
)
SYSTEM_PROMPT = (
    "Transcribe only the student task statement printed in the attached source "
    "image. Return raw JSON with no code fence or commentary. Copy wording, "
    "symbols, labels, values, and punctuation; do not repair or paraphrase."
)
USER_PROMPT = (
    'Return exactly {"statement":"verbatim task text",'
    '"certainty":"certain or uncertain"}. Use an empty statement and uncertain '
    "when the image does not contain a complete student task statement."
)


def _normalize(value: str) -> str:
    return " ".join(value.split())


def _digest_from_asset(asset: str) -> str:
    match = re.search(r"_([0-9a-f]{64})\.[A-Za-z0-9]+$", asset)
    if match is None:
        raise ValueError(f"image asset has no digest: {asset}")
    return match.group(1)


def _description(row: dict[str, str]) -> str:
    path = ROOT / row["description"]
    descriptions = vision_pass.description_index(path.with_name("document.md"))
    return descriptions.get(_digest_from_asset(row["asset"]), "")


def _payloads() -> list[dict[str, Any]]:
    paths = sorted((recovery.DEFAULT_RECOVERY_DIR / "checkpoints").glob("IM-G8-*.json"))
    if len(paths) != 134:
        raise ValueError(f"expected 134 recovery checkpoints, found {len(paths)}")
    payloads = [json.loads(path.read_text(encoding="utf-8")) for path in paths]
    return sorted(
        payloads,
        key=lambda payload: tuple(map(int, re.findall(r"\d+", payload["lesson"]))),
    )


def _worklist(payloads: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rows = []
    for payload in payloads:
        for task in payload["tasks"]:
            if task["blocker"] == "none" or not task["visual_provenance"]:
                continue
            described = []
            for visual in task["visual_provenance"]:
                description = _description(visual)
                if description and DESCRIPTION_TRANSCRIPT_RE.search(description):
                    described.append((visual, description))
            if not described:
                continue
            visual, description = described[0]
            stable = "\0".join(
                [payload["lesson"], task["position"], visual["asset"], MODEL]
            )
            rows.append(
                {
                    "lesson": payload["lesson"],
                    "position": task["position"],
                    "original_blocker": task["blocker"],
                    "asset": visual["asset"],
                    "description_file": visual["description"],
                    "description": description,
                    "call_id": "g8v_" + hashlib.sha256(stable.encode()).hexdigest()[:20],
                }
            )
    return rows


def _parse_ok(result: Any, description: str) -> tuple[str | None, str | None]:
    if getattr(result, "outcome", None) != "ok":
        return None, f"outcome_{getattr(result, 'outcome', 'unknown')}"
    content = getattr(result, "content", "")
    try:
        value = json.loads(content)
    except json.JSONDecodeError:
        return None, "invalid_json"
    if set(value) != {"statement", "certainty"}:
        return None, "schema"
    statement = value["statement"]
    if not isinstance(statement, str) or not statement.strip():
        return None, "empty_statement"
    if value["certainty"] != "certain":
        return None, "uncertain"
    normalized = _normalize(statement)
    # Shared contract: the whitespace-normalized statement must be an exact,
    # contiguous character sequence in the description; surrounding text or
    # punctuation is not part of the statement.
    if vision_statement_contract.normalized_contiguous_span(
        normalized, description
    ) is None:
        return None, "description_inconsistent"
    return normalized, None


def _messages(asset: Path) -> list[dict[str, Any]]:
    return [
        {"role": "system", "content": SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": USER_PROMPT},
                {
                    "type": "image_url",
                    "image_url": {"url": vision_pass.image_data_url(asset)},
                },
            ],
        },
    ]


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--limit", type=int, default=1)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--derive-only", action="store_true")
    args = parser.parse_args(argv)
    if not 0 <= args.limit <= HARD_CALL_BUDGET:
        parser.error(f"--limit must be between 0 and {HARD_CALL_BUDGET}")
    return args


def run(args: argparse.Namespace) -> int:
    payloads = _payloads()
    worklist = _worklist(payloads)
    recovery.atomic_write_json(
        args.out / "worklist.json",
        {"model": MODEL, "max_tokens": MAX_TOKENS, "rows": worklist},
    )
    if args.derive_only or args.limit == 0:
        print(json.dumps({"eligible": len(worklist), "calls": 0}))
        return 0

    llm = vision_pass.load_llm_module()
    llm.load_dotenv(ROOT)
    api_key = llm.load_key(ROOT)
    if api_key is None:
        raise RuntimeError("REALLMS_API_KEY is not configured")
    api_url = llm.resolve_api_url()
    ssl_ctx = llm.build_ssl_context()
    payload_by_lesson = {payload["lesson"]: payload for payload in payloads}
    calls = 0
    accepted = 0
    for row in worklist[: args.limit]:
        checkpoint_path = args.out / "checkpoints" / f"{row['call_id']}.json"
        if checkpoint_path.is_file():
            checkpoint = json.loads(checkpoint_path.read_text(encoding="utf-8"))
        else:
            remaining_budget = HARD_CALL_BUDGET - calls
            if remaining_budget <= 0:
                break
            result = llm.call_api_messages_result(
                _messages(ROOT / row["asset"]),
                api_key=api_key,
                api_url=api_url,
                model=MODEL,
                ssl_ctx=ssl_ctx,
                retries=min(3, remaining_budget),
                timeout=args.timeout,
                max_tokens=MAX_TOKENS,
            )
            attempts = max(1, int(getattr(result, "attempts", 1)))
            calls += attempts
            if calls > HARD_CALL_BUDGET:
                raise RuntimeError("vision call budget exceeded")
            statement, failure = _parse_ok(result, row["description"])
            response = result.to_dict()
            checkpoint = {
                **row,
                "model": MODEL,
                "max_tokens": MAX_TOKENS,
                "attempts": attempts,
                "outcome": getattr(result, "outcome", "unknown"),
                "accepted": statement is not None,
                "failure": failure,
                "statement": statement,
                "response": response,
            }
            recovery.atomic_write_json(checkpoint_path, checkpoint)

        payload = payload_by_lesson[row["lesson"]]
        task = next(task for task in payload["tasks"] if task["position"] == row["position"])
        if not any(call.get("call_id") == row["call_id"] for call in payload["model_calls"]):
            payload["model_calls"].append(
                {
                    "provider": "REALLMS",
                    "model": MODEL,
                    "call_id": row["call_id"],
                    "attempts": checkpoint["attempts"],
                    "outcome": checkpoint["outcome"],
                }
            )
        if checkpoint["accepted"]:
            statement = checkpoint["statement"]
            task["excerpt"] = statement
            task["extraction_status"] = "recovered"
            task["blocker"] = "none"
            task["vision_recovery"] = {
                "model": MODEL,
                "call_id": row["call_id"],
                "asset": row["asset"],
                "description_file": row["description_file"],
                "response_sha256": hashlib.sha256(
                    json.dumps(checkpoint["response"], sort_keys=True).encode()
                ).hexdigest(),
                "statement": statement,
            }
            accepted += 1

    for payload in payloads:
        recovery.atomic_write_json(
            recovery.recovery_checkpoint_path(recovery.DEFAULT_RECOVERY_DIR, payload["lesson"]),
            payload,
        )
    recovery.atomic_write(
        recovery.DEFAULT_TASK_OUTPUT,
        extraction.render_tasks(8, payloads),
    )
    summary = recovery.build_summary(payloads, resumed=134, wall=0.0)
    recovery.atomic_write_json(recovery.DEFAULT_RECOVERY_DIR / "summary.json", summary)
    print(
        json.dumps(
            {
                "eligible": len(worklist),
                "selected": min(args.limit, len(worklist)),
                "provider_calls": calls,
                "accepted": accepted,
            }
        )
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    try:
        return run(parse_args(argv))
    except (OSError, RuntimeError, ValueError, json.JSONDecodeError) as exc:
        sys.stderr.write(f"error: {exc}\n")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
