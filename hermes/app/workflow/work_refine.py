"""Request-local REFINE pass over already-pseudonymized READ results."""
from __future__ import annotations

import json
from typing import Any

from hermes.app.workflow import service
from hermes.app.workflow.work_read import DEFAULT_MODEL, NO_KEY_ERROR


def _result(payload: dict[str, Any], *, ok: bool = True, returncode: int = 0) -> service.WorkflowResult:
    return service.WorkflowResult("work_refine", returncode, ok, json.dumps(payload, ensure_ascii=False), "")


def _call(context: service.WorkflowContext, system: str, content: str, stub: object) -> str:
    if stub is not None:
        return str(stub)
    client = context.llm_client
    if client.load_key(context.pack_root) is None:
        raise LookupError(NO_KEY_ERROR)
    settings = client.make_client(context.pack_root)
    return str(client.call_api_messages([{"role": "system", "content": system}, {"role": "user", "content": content}], **settings, fail_on_error=False))


def run(payload: dict[str, Any], context: service.WorkflowContext) -> service.WorkflowResult:
    if not isinstance(payload, dict):
        return _result({"ok": False, "error": "JSON object required", "error_type": "invalid_request"}, ok=False, returncode=1)
    assignment = str(payload.get("assignment") or "").strip()
    reads = payload.get("read_results")
    if not assignment or not isinstance(reads, list):
        return _result({"ok": False, "error": "assignment and read_results are required", "error_type": "invalid_request"}, ok=False, returncode=1)
    grouped: dict[str, list[dict[str, Any]]] = {}
    for item in reads:
        if isinstance(item, dict) and str(item.get("student") or "").startswith("S"):
            grouped.setdefault(str(item["student"]), []).append(item)
    system = (context.pack_root / "system_prompts" / "work_refine.md").read_text(encoding="utf-8")
    stubs = payload.get("stub_reply")
    if stubs is not None and not isinstance(stubs, list):
        stubs = [stubs]
    stubs = list(stubs or [])
    cards = []
    try:
        for student, items in grouped.items():
            content = "ASSIGNMENT:\n" + assignment + "\n\nSTUDENT: " + student + "\n\nPER-FILE NOTES:\n" + json.dumps(items, ensure_ascii=False)
            cards.append({"student": student, "assessment": _call(context, system, content, stubs.pop(0) if stubs else None).strip()})
    except LookupError as exc:
        return _result({"ok": False, "error": str(exc), "error_type": "no_key"}, ok=False, returncode=1)
    except Exception as exc:
        return _result({"ok": False, "error": f"REFINE could not complete: {exc}", "error_type": "reallms"}, ok=False, returncode=1)
    return _result({"ok": True, "model": DEFAULT_MODEL, "refine_cards": cards, "privacy": "REFINE receives only S-handles and request-local READ results."})


def main(argv: list[str] | None = None) -> int:
    """CLI transport: decode --key value argv into the run() payload."""
    def _entry(args: list[str] | None) -> int:
        payload: dict = {}
        items = list(args or [])
        i = 0
        while i < len(items):
            token = items[i]
            if token.startswith("--"):
                key = token[2:].replace("-", "_")
                if i + 1 < len(items) and not items[i + 1].startswith("--"):
                    payload[key] = items[i + 1]
                    i += 2
                else:
                    payload[key] = True
                    i += 1
            else:
                i += 1
        result = run(payload, service.current_context())
        if result.text:
            print(result.text)
        return result.returncode

    return service.run_cli("work_refine", argv, _entry)


if __name__ == "__main__":
    raise SystemExit(main())
