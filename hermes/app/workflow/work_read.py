"""Request-local READ pass for uploaded student work.

This module deliberately writes no files.  The model sees an uploaded artifact
only for the one request; its proposed identity is used to group artifacts and
is replaced with an S-handle before any result leaves this module.
"""
from __future__ import annotations

import base64
import json
import re
from pathlib import Path
from typing import Any

from hermes.app.analysis import media
from hermes.app.workflow import service

DEFAULT_MODEL = "gemma-4-31B-it"
NO_KEY_ERROR = "Reading student work needs the model, and no REALLMS API key is set. Add a key and try again."


def _result(payload: dict[str, Any], *, ok: bool = True, returncode: int = 0) -> service.WorkflowResult:
    return service.WorkflowResult("work_read", returncode, ok, json.dumps(payload, ensure_ascii=False), "")


def _decode_file(item: object) -> tuple[str, str, bytes]:
    if not isinstance(item, dict):
        raise ValueError("each file must be an object")
    name = str(item.get("name") or "upload")
    mime = str(item.get("mime") or "")
    encoded = str(item.get("data_b64") or "")
    if encoded.startswith("data:") and "," in encoded:
        encoded = encoded.split(",", 1)[1]
    if not encoded.strip():
        raise ValueError(f"{name}: data_b64 is required")
    try:
        return name, mime, base64.b64decode(encoded, validate=True)
    except (ValueError, TypeError) as exc:
        raise ValueError(f"{name}: data_b64 is not valid base64") from exc


def _json_reply(reply: object) -> dict[str, Any]:
    if isinstance(reply, dict):
        return reply
    text = str(reply or "").strip()
    if text.startswith("```"):
        text = "\n".join(text.splitlines()[1:-1]).strip()
    start, end = text.find("{"), text.rfind("}")
    if start < 0 or end < start:
        raise ValueError("the model reply contained no JSON object")
    parsed = json.loads(text[start:end + 1])
    if not isinstance(parsed, dict):
        raise ValueError("the model reply was not a JSON object")
    return parsed


def _redact(value: object, names: set[str]) -> str:
    text = str(value or "").strip()
    for name in sorted((n for n in names if n), key=len, reverse=True):
        text = re.sub(re.escape(name), "[name removed]", text, flags=re.IGNORECASE)
    return text


def _call(context: service.WorkflowContext, system: str, content: list[dict], stub: object) -> object:
    if stub is not None:
        return stub
    client = context.llm_client
    if client.load_key(context.pack_root) is None:
        raise LookupError(NO_KEY_ERROR)
    settings = client.make_client(context.pack_root)
    return client.call_api_messages(
        [{"role": "system", "content": system}, {"role": "user", "content": content}],
        **settings,
        fail_on_error=False,
    )


def _content_variants(assignment: str, index: int, name: str, mime: str, data: bytes,
                      parts: list[dict]) -> list[list[dict]]:
    """Offer document transports in addition to rendered/extracted parts.

    REALLMS deployments differ on whether they accept a file part, an
    input_file part, or only the image/text representation.  The rendered
    representation remains first because it is readable by vision models;
    later variants are tried only when that transport fails.
    """
    header = {"type": "text", "text": f"ASSIGNMENT:\n{assignment}\n\nFILE {index}: {name}"}
    variants = [[header] + parts]
    if Path(name).suffix.lower() not in {".pdf", ".docx"}:
        return variants
    resolved_mime = mime or ("application/pdf" if name.lower().endswith(".pdf") else "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    data_url = f"data:{resolved_mime};base64,{base64.b64encode(data).decode('ascii')}"
    variants.append([header, {"type": "file", "file": {"filename": name, "file_data": data_url}}])
    variants.append([header, {"type": "input_file", "filename": name, "file_data": data_url}])
    return variants


def run(payload: dict[str, Any], context: service.WorkflowContext) -> service.WorkflowResult:
    if not isinstance(payload, dict):
        return _result({"ok": False, "error": "JSON object required", "error_type": "invalid_request"}, ok=False, returncode=1)
    assignment = str(payload.get("assignment") or "").strip()
    files = payload.get("files")
    if not assignment:
        return _result({"ok": False, "error": "assignment is required", "error_type": "invalid_request"}, ok=False, returncode=1)
    if not isinstance(files, list) or not files:
        return _result({"ok": False, "error": "at least one uploaded file is required", "error_type": "invalid_request"}, ok=False, returncode=1)
    if len(files) > 12:
        return _result({"ok": False, "error": "send at most 12 files in one READ request", "error_type": "invalid_request"}, ok=False, returncode=1)

    system = (context.pack_root / "system_prompts" / "work_read.md").read_text(encoding="utf-8")
    supplied_stubs = payload.get("stub_reply")
    if supplied_stubs is not None and not isinstance(supplied_stubs, list):
        supplied_stubs = [supplied_stubs]
    stubs = list(supplied_stubs or [])
    raw_reads: list[dict[str, Any]] = []
    for index, item in enumerate(files, start=1):
        try:
            name, mime, data = _decode_file(item)
            diagnostics: list[str] = []
            parts, render = media.parts_for_upload(name, mime, data, diagnostics)
            if not parts:
                raw_reads.append({"index": index, "name": name, "quarantined": True, "transcription": "", "per_file_notes": "", "uncertainty": "; ".join(diagnostics) or "The upload could not be read.", "render": render})
                continue
            stub = stubs.pop(0) if stubs else None
            reply, last_error = None, None
            for content in _content_variants(assignment, index, name, mime, data, parts):
                try:
                    reply = _call(context, system, content, stub)
                    break
                except LookupError:
                    raise
                except Exception as exc:  # try the next documented transport shape
                    last_error = exc
            if reply is None:
                raise RuntimeError(f"all document transport variants failed: {last_error}")
            parsed = _json_reply(reply)
            confidence = str(parsed.get("confidence") or "low").lower()
            identity = str(parsed.get("student_id") or "").strip()
            quarantined = confidence == "low" or not identity
            raw_reads.append({"index": index, "name": name, "identity": identity, "quarantined": quarantined, "transcription": parsed.get("transcription"), "per_file_notes": parsed.get("per_file_notes"), "uncertainty": parsed.get("uncertainty"), "render": render, "diagnostics": diagnostics})
        except LookupError as exc:
            return _result({"ok": False, "error": str(exc), "error_type": "no_key"}, ok=False, returncode=1)
        except Exception as exc:  # a single bad upload should not disclose or stop the rest
            raw_reads.append({"index": index, "name": "upload", "quarantined": True, "transcription": "", "per_file_notes": "", "uncertainty": f"Could not read this upload: {exc}", "render": "unreadable"})

    handles: dict[str, str] = {}
    for item in raw_reads:
        identity = str(item.get("identity") or "")
        if not item.get("quarantined") and identity not in handles:
            handles[identity] = f"S{len(handles) + 1:02d}"
    all_names = set(handles)
    results, unattributed = [], []
    for item in raw_reads:
        safe = {"file_index": item["index"], "transcription": _redact(item.get("transcription"), all_names), "per_file_notes": _redact(item.get("per_file_notes"), all_names), "uncertainty": _redact(item.get("uncertainty"), all_names), "render": item.get("render")}
        identity = str(item.get("identity") or "")
        if item.get("quarantined"):
            safe["student"] = "unattributed work"
            unattributed.append(safe)
        else:
            safe["student"] = handles[identity]
            results.append(safe)
    return _result({"ok": True, "model": DEFAULT_MODEL, "read_results": results, "unattributed_work": unattributed, "privacy": "Names were used only to group this request. Returned work uses S-handles; the name map is not returned or persisted."})


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

    return service.run_cli("work_read", argv, _entry)


if __name__ == "__main__":
    raise SystemExit(main())
