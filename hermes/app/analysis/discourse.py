"""Domain-general, local, student-level discourse pairing.

Pairs STUDENTS (not utterances) from observable structure — who responds to
whom, name-mentions, agree/challenge cues, participation balance — plus the
project's PML discourse-marker stance proxies (categorical -> compressive,
hedging/surprise -> expansive). No domain model, no worker, no LLM. The output
is local-only, so it carries real names (never sent to the cloud on this path).
"""
from __future__ import annotations

import re
from itertools import combinations
from typing import Any

from .hermes_n103 import HermesEvent, classify_stance


def _stance(text: str) -> dict[str, Any]:
    """Per-student PML stance via the project's documented discourse-marker
    *proxy* — NOT the symbolic PML engine (event_scoring.pl). Categorical/closing
    markers map to compressive polarity and opening/hedging markers to expansive;
    first-person markers to S-mode, object/content to O-mode, norm-language to
    N-mode. The matched markers are returned as evidence so the proxy is legible
    and falsifiable rather than a black box. This shares one cue lexicon with
    hermes_n103.classify_stance so the two surfaces cannot drift apart.
    """
    stance = classify_stance(text.lower())
    return {
        "polarity": stance.polarity,
        "mode": stance.mode,
        "markers": list(stance.evidence),
        "method": "discourse_marker_proxy",
    }


def _mention_tokens(student_ids: list[str]) -> dict[str, str]:
    # each student id -> lowercase mention token (first name, or whole label)
    return {s: (s.split()[0] if s.split() else s).lower() for s in student_ids}


# Labels that are not pairable individual students: the teacher and whole-class /
# collective markers. Pairing a teacher with everyone, or pairing "the whole class",
# is noise — these are kept in the participant list but excluded from dyads.
_TEACHER_EXACT = re.compile(r"^(t|teacher|instructor|tutor|prof|professor|facilitator)$", re.I)
_TEACHER_TITLE = re.compile(r"^(mr|mrs|ms|mx|dr|prof|professor)\.?\s+\S", re.I)
_COLLECTIVE = {"ss", "others", "class", "all", "everyone", "group", "groups",
               "students", "the class", "whole class", "multiple", "several"}
# Section markers / non-utterance labels that some transcript formats put before a
# colon (e.g. "Header: 3_3_2", "Prompt: …"). Never a real participant.
_METADATA = {"header", "prompt", "question", "note", "topic", "title", "answer",
             "answers", "response", "state", "trace", "instructions", "directions",
             "subject", "section"}


def _role(label: str) -> str:
    low = label.strip().lower()
    if low in _METADATA:
        return "metadata"
    if _TEACHER_EXACT.match(low) or _TEACHER_TITLE.match(label.strip()):
        return "teacher"
    if low in _COLLECTIVE:
        return "collective"
    return "student"


def analyze_discourse(events: list[HermesEvent], *, top_n: int = 8, include_all: bool = False) -> dict[str, Any]:
    order = [e.student for e in events]
    student_ids = list(dict.fromkeys(order))  # first-seen, unique
    texts: dict[str, list[str]] = {s: [] for s in student_ids}
    for e in events:
        texts[e.student].append(e.text)

    students = []
    for s in student_ids:
        joined = " ".join(texts[s])
        students.append({
            "id": s,
            "label": s,
            "role": _role(s),
            "turns": len(texts[s]),
            "words": len(joined.split()),
            "stance": _stance(joined),
        })
    by_id = {s["id"]: s for s in students}
    tokens = _mention_tokens(student_ids)

    # Only individual students are pairable: the teacher and collective labels
    # ("SS", "Others", …) stay in the participant list but never form dyads.
    pairable = [s for s in student_ids if include_all or by_id[s]["role"] == "student"]
    excluded = [s for s in student_ids if s not in pairable]

    # interaction signals
    mentions: set[tuple[str, str]] = set()
    for e in events:
        low = e.text.lower()
        for other in student_ids:
            if other == e.student or len(tokens[other]) < 3:
                continue  # skip self and 1-2 char labels (e.g. "T", "SS") to avoid false mentions
            if re.search(r"\b" + re.escape(tokens[other]) + r"\b", low):
                mentions.add((e.student, other))
    adjacency: set[frozenset] = set()
    for a, b in zip(order, order[1:]):
        if a != b:
            adjacency.add(frozenset((a, b)))

    median_turns = sorted(by_id[s]["turns"] for s in pairable)[len(pairable) // 2] if pairable else 0

    pairs = []
    for a, b in combinations(pairable, 2):
        reasons: list[str] = []
        score = 0
        if (a, b) in mentions or (b, a) in mentions:
            reasons.append("direct_interaction(name_mention)")
            score += 2
        elif frozenset((a, b)) in adjacency:
            reasons.append("direct_interaction(adjacency)")
            score += 1
        pa, pb = by_id[a]["stance"]["polarity"], by_id[b]["stance"]["polarity"]
        if pa != pb and "unknown" not in (pa, pb):
            # A discourse-marker polarity contrast (one tends to close ideas
            # down, one to open them up). Named honestly: it is a marker proxy,
            # not a verdict from the symbolic PML engine.
            reasons.append("discourse_polarity_contrast")
            score += 1
        hi, lo = max(by_id[a]["turns"], by_id[b]["turns"]), min(by_id[a]["turns"], by_id[b]["turns"])
        if hi > median_turns >= lo and hi != lo:
            reasons.append("participation_complement")
            score += 1
        if score > 0:
            pairs.append({"a": a, "b": b, "score": score, "reasons": reasons})

    pairs.sort(key=lambda p: -p["score"])
    pairs = pairs[:top_n]

    excl_note = f" {len(excluded)} non-student label(s) set aside ({', '.join(excluded)})." if excluded else ""
    summary = (f"{len(events)} contributions from {len(pairable)} students; "
               f"top {len(pairs)} candidate pairs by observable discourse structure.{excl_note}")
    return {
        "provenance": "discourse-only",
        "event_count": len(events),
        "students": students,
        "pairable_count": len(pairable),
        "excluded": excluded,
        "pairs": pairs,
        "summary": summary,
    }
