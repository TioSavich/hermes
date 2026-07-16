"""Signal-gated router: grounded vs. domain-general analysis.

Runs the local grounded detector (`hermes_n103.analyze_event`) over the events.
If it finds substantial curriculum signal, the discussion is in a domain the repo
models, so the discourse pairing is enriched with grounded reasons and labelled
``grounded``. If not (e.g. the TalkMoves ratios transcript, which fires nothing),
it stays ``discourse-only`` — honest about the absence of a domain model. The
teacher can force ``general`` to skip grounding entirely.

This path is local and model-free (no worker, no LLM). The Gemma advisory branch
for ungrounded domains is intentionally opt-in elsewhere, not automatic here.
"""
from __future__ import annotations

from collections import Counter
from typing import Any

from .hermes_n103 import HermesEvent, analyze_event


def ground(events: list[HermesEvent]) -> tuple[int, dict[str, dict[str, set]]]:
    """Return (signalled_event_count, {student: {topics, misconception_topics}})."""
    by_student: dict[str, dict[str, set]] = {}
    signalled = 0
    for e in events:
        analysis = analyze_event(e)
        if analysis.signals:
            signalled += 1
        d = by_student.setdefault(e.student, {"topics": set(), "misconception_topics": set()})
        for s in analysis.signals:
            d["topics"].add(s.topic)
            if s.family == "misconception":
                d["misconception_topics"].add(s.topic)
    return signalled, by_student


def route(events: list[HermesEvent], *, grounding_min: int = 1, force_mode: str | None = None) -> dict[str, Any]:
    """Decide grounded vs discourse-only. `force_mode='general'` forces discourse-only."""
    signalled, by_student = ground(events)
    topics: Counter = Counter()
    for d in by_student.values():
        for t in d["topics"]:
            topics[t] += 1
    if force_mode == "general":
        mode = "discourse-only"
    elif signalled >= grounding_min:
        mode = "grounded"
    else:
        mode = "discourse-only"
    return {
        "mode": mode,
        "grounding_score": signalled,
        "topics": dict(topics),
        "by_student": by_student,
        "forced": force_mode,
    }


def enrich_pairs(pairs: list[dict], by_student: dict[str, dict[str, set]]) -> list[dict]:
    """Add grounded reasons to student pairs, in place, and re-sort by score.

    - shared_grounded_topic(T): both students engaged the same modelled topic.
    - grounded_repair_affordance(T): one student raised a misconception on T — the
      pair has something concrete to repair.
    """
    empty = {"topics": set(), "misconception_topics": set()}
    for p in pairs:
        ta = by_student.get(p["a"], empty)
        tb = by_student.get(p["b"], empty)
        added = 0
        for t in sorted(ta["topics"] & tb["topics"]):
            p["reasons"].append(f"shared_grounded_topic({t})")
            added += 2
        for t in sorted(ta["misconception_topics"] | tb["misconception_topics"]):
            p["reasons"].append(f"grounded_repair_affordance({t})")
            added += 2
        p["score"] += added
    pairs.sort(key=lambda p: -p["score"])
    return pairs
