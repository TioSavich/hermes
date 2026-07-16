"""Format-agnostic ingest: any input -> [HermesEvent].

Two local routes (no LLM): a deterministic delimited-table adapter (CSV/TSV with
a speaker column, optional turn + text columns), and the best-effort
`Speaker: text` transcript parser. The Gemma normalizer for truly unstructured
paste is added in a later phase.
"""
from __future__ import annotations

import csv
import io
from typing import Any

from .event_importer import _events_from_transcript
from .hermes_n103 import HermesEvent

_SPEAKER_COLS = ("speaker", "name", "role", "participant", "student", "who",
                 "author", "poster")
_TEXT_COLS = ("sentence", "text", "utterance", "message", "body", "transcript",
              "response", "post", "comment", "contribution", "content", "said")
_TURN_COLS = ("turn", "turn_id", "turnnumber", "turn number")


import re as _re


def _match_col(header: list[str], candidates: tuple[str, ...]) -> str | None:
    for h in header:
        if (h or "").strip().lower() in candidates:
            return h
    # Second pass by whole word, so "Student Name" or "Contribution text"
    # match without letting substrings ("context") through.
    for h in header:
        tokens = _re.split(r"[^a-z]+", (h or "").strip().lower())
        if any(t in candidates for t in tokens if t):
            return h
    return None


def _looks_like_table(text: str) -> csv.Dialect | None:
    sample = text[:4096]
    if "\n" not in sample:
        return None
    first = sample.splitlines()[0]
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=",\t;")
        if dialect.delimiter in first:
            return dialect
    except csv.Error:
        pass
    # The sniffer gives up on some ordinary exports (semicolon files with
    # commas inside cells, short samples). Fall back to the delimiter every
    # non-empty line shares, most-specific first.
    lines = [l for l in sample.splitlines() if l.strip()]
    for delim in ("\t", ";", ","):
        if delim in first and all(delim in l for l in lines):
            class _Manual(csv.excel):
                delimiter = delim
            return _Manual
    return None


def _two_column_rows(text: str, dialect: csv.Dialect) -> list[tuple[str, str]] | None:
    """Headerless fallback: a consistent multi-column table reads as
    (speaker, said) — but only when the first column plausibly holds
    speaker labels, so prose that merely contains delimiters never
    matches. The column names a teacher's export happens to use stop
    mattering; the shape carries the meaning."""
    rows = [r for r in csv.reader(io.StringIO(text), dialect=dialect)
            if any(c.strip() for c in r)]
    if len(rows) < 3 or any(len(r) < 2 for r in rows):
        return None
    pairs = [(r[0].strip(), " ".join(c.strip() for c in r[1:] if c.strip()))
             for r in rows]
    labels = [s for s, _ in pairs]
    if any(":" in s or len(s) > 40 or not s for s in labels):
        return None
    # Speakers recur across turns; a column of only one-off values is data.
    if len(set(labels)) > max(2, len(labels) - 1):
        return None
    # Drop a header row: a label never seen again, with a short dot-free cell.
    first_label, first_said = pairs[0]
    if first_label not in labels[1:] and len(first_said) <= 24 and "." not in first_said:
        pairs = pairs[1:]
    pairs = [(s, t) for s, t in pairs if s and t]
    return pairs or None


def events_from_table(text: str) -> list[HermesEvent] | None:
    dialect = _looks_like_table(text)
    if dialect is None:
        return None
    reader = csv.DictReader(io.StringIO(text), dialect=dialect)
    header = reader.fieldnames or []
    spk_col = _match_col(header, _SPEAKER_COLS)
    txt_col = _match_col(header, _TEXT_COLS)
    if not spk_col or not txt_col:
        inferred = _two_column_rows(text, dialect)
        if inferred is None:
            return None
        return [
            HermesEvent(student=spk, text=said, source="table", event_id=str(idx))
            for idx, (spk, said) in enumerate(inferred, start=1)
        ]
    turn_col = _match_col(header, _TURN_COLS)
    # Buffer (speaker, turn_key, sentences); HermesEvent is frozen so build once.
    groups: list[tuple[str, str, list[str]]] = []
    for i, row in enumerate(reader, start=1):
        speaker = (row.get(spk_col) or "").strip()
        sentence = (row.get(txt_col) or "").strip()
        if not speaker or not sentence:
            continue
        turn_key = (row.get(turn_col) or "").strip() if turn_col else str(i)
        if groups and turn_col and groups[-1][1] == turn_key and groups[-1][0] == speaker:
            groups[-1][2].append(sentence)
        else:
            groups.append((speaker, turn_key, [sentence]))
    events = [
        HermesEvent(student=spk, text=" ".join(s).strip(), source="table", event_id=str(idx))
        for idx, (spk, _tk, s) in enumerate(groups, start=1)
    ]
    return events or None


def ingest(raw: str) -> tuple[list[HermesEvent], dict[str, Any]]:
    """Return (events, meta). meta['format'] is 'table' or 'transcript'."""
    text = raw if isinstance(raw, str) else str(raw)
    table = events_from_table(text)
    if table is not None:
        return table, {"format": "table", "event_count": len(table)}
    events = _events_from_transcript(text)
    return events, {"format": "transcript", "event_count": len(events)}


def implausible_speakers(events: list[HermesEvent], *, max_speakers: int = 40) -> dict[str, Any]:
    """Flag a parse that yielded an implausible speaker count (likely a format
    problem, not 90 real students). Returns {implausible, speakers, turns, reason}.
    """
    turns = len(events)
    speakers = len({e.student for e in events})
    too_many = speakers > max_speakers or (turns >= 8 and speakers > turns / 2)
    reason = ""
    if too_many:
        reason = (f"Parsed {speakers} speakers from {turns} turns — the input may not be in "
                  "'Speaker: text' form. Try the table importer or clean the paste.")
    return {"implausible": too_many, "speakers": speakers, "turns": turns, "reason": reason}
