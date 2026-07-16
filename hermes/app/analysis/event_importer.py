"""Runtime event import boundary for Hermes.

Raw classroom text may enter here in memory, but downstream pair scoring and
graphing must receive metadata-only canonical events.
"""
from __future__ import annotations

import json
import re
from typing import Any

from .hermes_n103 import HermesEvent


PAIR_GRAPH_FORBIDDEN_KEYS = {
    "raw_text",
    "text",
    "actor_id",
    "student",
    "student_id",
    "student_name",
    "source_id",
    "path",
    "evidence",
}

CANONICAL_EVENT_KEYS = {"event_id", "actor", "symbolic", "pml"}


def assert_pair_graph_safe(value: Any, *, path: str = "$") -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            key_text = str(key)
            if key_text in PAIR_GRAPH_FORBIDDEN_KEYS:
                raise ValueError(f"unsafe pair_graph field at {path}.{key_text}")
            assert_pair_graph_safe(child, path=f"{path}.{key_text}")
        return
    if isinstance(value, list):
        for index, child in enumerate(value):
            assert_pair_graph_safe(child, path=f"{path}[{index}]")
        return


def worker_events_from_payload(raw: object) -> list[dict[str, Any]]:
    """Return Prolog-safe canonical events for scoring endpoints.

    Already-canonical records may pass through after the same raw-field
    quarantine used by pair_graph. Raw transcript/list/object payloads are
    parsed in memory and pseudonymized before they reach the worker.
    """
    rows = _as_event_rows(raw)
    if rows is not None and all(_looks_canonical_event(row) for row in rows):
        assert_pair_graph_safe(rows)
        return rows

    events = events_from_payload(raw)
    if not events:
        return []

    from .pipeline import canonical_events_from_hermes_events

    canonical = canonical_events_from_hermes_events(events)
    assert_pair_graph_safe(canonical)
    return canonical


def _as_event_rows(raw: object) -> list[dict[str, Any]] | None:
    if isinstance(raw, dict):
        for key in ("events", "event"):
            value = raw.get(key)
            if isinstance(value, list) and all(isinstance(row, dict) for row in value):
                return value
            if isinstance(value, dict):
                return [value]
        return [raw]
    if isinstance(raw, list) and all(isinstance(row, dict) for row in raw):
        return raw
    return None


def _looks_canonical_event(row: dict[str, Any]) -> bool:
    return CANONICAL_EVENT_KEYS.issubset(row)


def events_from_payload(raw: object) -> list[HermesEvent]:
    if isinstance(raw, str):
        text = raw.strip()
        if not text:
            return []
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError:
            return _events_from_transcript(raw)
        return events_from_payload(parsed)
    if isinstance(raw, dict):
        for key in ("events", "posts", "messages"):
            if isinstance(raw.get(key), list):
                return events_from_payload(raw[key])
        raw = [raw]
    if not isinstance(raw, list):
        raise ValueError("events must be a JSON list, object, or transcript text")

    events: list[HermesEvent] = []
    for idx, item in enumerate(raw, start=1):
        if not isinstance(item, dict):
            raise ValueError("event rows must be objects")
        event = HermesEvent(
            student=str(item.get("student") or item.get("speaker") or item.get("name") or "Unknown"),
            text=str(item.get("text") or item.get("body") or item.get("message") or ""),
            source=str(item.get("source") or "local"),
            timestamp=str(item.get("timestamp") or item.get("time") or ""),
            event_id=str(item.get("id") or item.get("event_id") or idx),
        )
        if event.text.strip():
            events.append(event)
    return events


# A line begins a new turn only when it opens with a short, capitalised speaker
# label ("Maria:", "David Chen:", "T:", "Student 1:") followed by ": text". This
# keeps multi-sentence turns intact and stops embedded colons (ratios, times,
# mid-sentence clauses) from inventing speakers. For structured data use the table
# adapter in ingest.py; this parser is the best-effort paste path.
_SPEAKER_LABEL_RE = re.compile(r"^\s*([A-Z][\w.'\-]*(?:\s+[\w.'\-]+){0,2})\s*:\s+(\S.*)$")


def _label_for(line: str) -> tuple[str, str] | None:
    m = _SPEAKER_LABEL_RE.match(line)
    if not m:
        return None
    label = m.group(1).strip()
    if len(label) > 20 or len(label.split()) > 3:
        return None
    return label, m.group(2).strip()


def _events_from_transcript(text: str) -> list[HermesEvent]:
    # HermesEvent is frozen, so buffer each turn's lines and build the event once.
    turns: list[tuple[str, list[str]]] = []
    for line in text.splitlines():
        if not line.strip():
            continue
        labelled = _label_for(line)
        if labelled is not None:
            speaker, body = labelled
            turns.append((speaker, [body]))
        elif turns:
            turns[-1][1].append(line.strip())
        # lines before the first speaker label (headers, prompts) are skipped
    events: list[HermesEvent] = []
    for idx, (speaker, parts) in enumerate(turns, start=1):
        body = " ".join(p for p in parts if p).strip()
        if body:
            events.append(HermesEvent(student=speaker, text=body, source="transcript", event_id=str(idx)))
    return events
