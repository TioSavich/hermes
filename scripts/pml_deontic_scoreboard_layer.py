#!/usr/bin/env python3
"""Deontic Scoreboard Layer for source-anchored PML events.

This layer does not parse raw prose and does not decide domain truth. It groups
already source-anchored PML events by speaker/author, extracts candidate
commitments and entitlements, then asks the existing Hermes deontic worker ops
to compute the scorecard, consequence closure, and up-level witnesses.

Commitment matching stays on the Prolog side. Two matchers are available:
the worker's `commitment_match` op (misconception/strategy vocabulary) and the
literature canonical matcher (`literature_canonical_match_many`), which routes
content through `misconceptions/literature_deontic_bridge.pl` and returns
`applies_rule(sr_*)` / `normative_commitment(c_*)` terms — the shapes the
scorekeeper's literature-derived `incompatible/2` rules cover. Both abstain by
default; unmatched content keeps the opaque `pml_commitment(...)` fallback the
engine can never adjudicate.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from collections import OrderedDict
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from hermes.app.worker import PersistentPrologError, PersistentPrologWorker


def deontic_scoreboard_layer(
    events: list[dict[str, Any]],
    *,
    worker_factory=PersistentPrologWorker,
) -> dict[str, Any]:
    """Return per-speaker deontic boards for source-anchored PML events."""
    grouped = _group_events_by_speaker(events)
    worker = worker_factory()
    try:
        speaker_rows = []
        for speaker_id, bucket in grouped.items():
            commitments = _dedupe(bucket["commitments"])
            entitlements = _dedupe(bucket["entitlements"])
            request_agent = _agent_atom(speaker_id)
            scorecard = worker.request(
                "deontic_scorecard",
                agent=request_agent,
                commitments=commitments,
                entitlements=entitlements,
            )
            consequences = worker.request(
                "deontic_consequences",
                agent=request_agent,
                commitments=commitments,
            )
            up_level = worker.request(
                "deontic_up_level",
                agent=request_agent,
                commitments=commitments,
            )
            speaker_rows.append(
                {
                    "speaker_id": speaker_id,
                    "event_ids": bucket["event_ids"],
                    "source_span_ids": _dedupe(bucket["source_span_ids"]),
                    "commitments": commitments,
                    "entitlements": entitlements,
                    "scorecard": scorecard,
                    "consequences": consequences.get("consequences", [])
                    if isinstance(consequences, dict)
                    else [],
                    "up_levels": up_level.get("up_levels", [])
                    if isinstance(up_level, dict)
                    else [],
                }
            )
    finally:
        close = getattr(worker, "close", None)
        if callable(close):
            close()

    incoherence_total = sum(
        len(row["scorecard"].get("incoherences", []))
        if isinstance(row.get("scorecard"), dict)
        else 0
        for row in speaker_rows
    )
    up_level_total = sum(len(row["up_levels"]) for row in speaker_rows)

    notes = [
        "PML remains the abstract event layer; this layer only tracks commitments and entitlements.",
        "Hermes deontic ops are reset per request, so scorecards do not persist between speakers.",
    ]
    notes.append(_up_level_note(incoherence_total, up_level_total))

    return {
        "layer": "deontic_scoreboard",
        "source_event_count": len(events),
        "summary": {
            "speaker_count": len(speaker_rows),
            "incoherence_total": incoherence_total,
            "up_level_total": up_level_total,
        },
        "speakers": speaker_rows,
        "notes": notes,
    }


def _up_level_note(incoherence_total: int, up_level_total: int) -> str:
    """Explain an empty up-level column so a zero reads as expected, not broken.

    `deontic_up_level` only emits an objectivation witness for a
    `commitment_without_entitlement` that survives within-level discharge. When no
    such incoherence survives (incoherence_total == 0), up_level_total is
    necessarily 0: the op was queried per speaker and correctly found nothing to
    up-level. A non-empty up-level column requires a surviving hollow commitment;
    the layer test demonstrates one (a cross-multiply result asserted without the
    area-model entitlement).
    """
    if up_level_total > 0:
        return (
            f"up_level_total={up_level_total}: at least one commitment_without_entitlement "
            "survived discharge and produced an objectivation witness."
        )
    if incoherence_total == 0:
        return (
            "up_level_total=0 because incoherence_total=0: no commitment_without_entitlement "
            "survives within-level discharge, so deontic_up_level has nothing to up-level. "
            "This is the expected reading of an empty up-level column, not a broken op."
        )
    return (
        "up_level_total=0 although incoherence_total>0: the surviving incoherences are not "
        "commitment_without_entitlement cases, which are the only ones deontic_up_level lifts."
    )


def deontic_events_from_talkmoves_audits(
    audits: list[dict[str, Any]],
    *,
    matcher=None,
) -> list[dict[str, Any]]:
    """Adapt TalkMoves/PML audit packets to source-anchored PML events.

    TalkMoves labels remain available to TalkMoves-specific report layers, but
    this adapter does not copy TalkMoves fields into the core deontic event.

    matcher, when supplied, is the stage-1 commitment matcher: it takes the
    reading content and returns the canonical commitment terms it admits
    (e.g. via the worker's commitment_match op). Admitted terms replace the
    opaque pml_commitment wrapper — the scorekeeper has rules for them; the
    wrapper it can never adjudicate stays only as the abstention fallback.
    """
    events: list[dict[str, Any]] = []
    for audit in audits:
        transcript_id = str(audit.get("transcript_id", "") or "transcript")
        for axiom in audit.get("axioms", []) or []:
            axiom_id = str(axiom.get("id", "") or f"a{len(events) + 1}")
            prolog = axiom.get("prolog", {}) or {}
            evidences = axiom.get("evidence", []) or [{}]
            for evidence in evidences:
                event_id = _event_id(transcript_id, axiom_id, evidences, evidence)
                content = str(prolog.get("content", "") or "").strip()
                validation = prolog.get("math_validation", {}) or {}
                matched_terms = _matched_commitments(matcher, content)
                commitment_terms = _candidate_terms(
                    prolog,
                    "deontic_commitments",
                    "candidate_commitments",
                    fallback=(matched_terms or _pml_commitment(content))
                    if content
                    else None,
                )
                entitlement_terms = _candidate_terms(
                    prolog,
                    "deontic_entitlements",
                    "candidate_entitlements",
                    fallback=(matched_terms or _pml_commitment(content))
                    if content and validation.get("status") == "domain_checked"
                    else None,
                )
                events.append(
                    {
                        "event_id": event_id,
                        "source_span_ids": _source_span_ids(evidence),
                        "speaker_id": _speaker_id(evidence),
                        "quote": str(evidence.get("line", "") or evidence.get("sentence", "")),
                        "pml": {
                            "content": content,
                            "mode": str(prolog.get("mode", "") or ""),
                            "operator": str(prolog.get("operator", "") or ""),
                            "polarity": str(prolog.get("polarity", "") or ""),
                        },
                        "candidate_commitments": commitment_terms,
                        "candidate_entitlements": entitlement_terms,
                    }
                )
    return events


def _group_events_by_speaker(events: list[dict[str, Any]]) -> OrderedDict[str, dict[str, Any]]:
    grouped: OrderedDict[str, dict[str, Any]] = OrderedDict()
    for event in events:
        speaker_id = _event_speaker_id(event)
        bucket = grouped.setdefault(
            speaker_id,
            {
                "event_ids": [],
                "source_span_ids": [],
                "commitments": [],
                "entitlements": [],
            },
        )
        event_id = str(event.get("event_id", "") or f"event_{len(bucket['event_ids']) + 1}")
        bucket["event_ids"].append(event_id)
        bucket["source_span_ids"].extend(_event_source_span_ids(event))
        bucket["commitments"].extend(_event_terms(event, "candidate_commitments", "commitments"))
        bucket["entitlements"].extend(_event_terms(event, "candidate_entitlements", "entitlements"))
    return grouped


def _event_terms(event: dict[str, Any], explicit_key: str, symbolic_key: str) -> list[str]:
    values = event.get(explicit_key)
    if values is None and isinstance(event.get("symbolic"), dict):
        values = event["symbolic"].get(symbolic_key)
    if values is None and isinstance(event.get("deontic"), dict):
        values = event["deontic"].get(explicit_key) or event["deontic"].get(symbolic_key)
    if values is None:
        return []
    if isinstance(values, str):
        return [values]
    if isinstance(values, list):
        return [str(value) for value in values if str(value).strip()]
    return [str(values)]


def _event_speaker_id(event: dict[str, Any]) -> str:
    for key in ("speaker_id", "author_id", "participant_id"):
        if event.get(key):
            return str(event[key])
    actor = event.get("actor") if isinstance(event.get("actor"), dict) else {}
    for key in ("pseudonym", "speaker_id", "author_id", "id"):
        if actor.get(key):
            return str(actor[key])
    return "unknown"


def _event_source_span_ids(event: dict[str, Any]) -> list[str]:
    spans = event.get("source_span_ids")
    if isinstance(spans, list):
        return [str(span) for span in spans if str(span).strip()]
    if isinstance(spans, str) and spans.strip():
        return [spans]
    span = event.get("source_span_id")
    if span:
        return [str(span)]
    return []


def worker_commitment_matcher(worker):
    """Stage-1 matcher backed by the worker's commitment_match op. Returns a
    callable suitable for deontic_events_from_talkmoves_audits(matcher=...);
    worker failures read as abstention, never as a crash of the adapter."""

    def matcher(content: str) -> list[str]:
        try:
            result = worker.request("commitment_match", content=content)
        except Exception:
            return []
        matches = result.get("matches") if isinstance(result, dict) else None
        if not isinstance(matches, list):
            return []
        return [
            str(m.get("term"))
            for m in matches
            if isinstance(m, dict) and m.get("term")
        ]

    return matcher


def literature_canonical_match_many(
    contents: list[str],
    *,
    swipl: str = "swipl",
    repo_root: Path = REPO_ROOT,
    timeout: int = 300,
) -> dict[str, list[str]]:
    """Map each content to its canonical literature commitment terms.

    One swipl batch run through paths.pl drives
    `literature_deontic_bridge:lit_deontic_content_match_files/2`, so Prolog
    stays the authority for the admission gate and the canonicalizers
    (canonical_student_rule/2, normalized_commitment/2). Returns
    {content: ["applies_rule(sr_...)", "normative_commitment(c_...)", ...]};
    any failure (missing swipl, load error, timeout) reads as abstention for
    every content — {} — never as a crash of the caller.
    """
    deduped = [c for c in OrderedDict.fromkeys(str(c) for c in contents) if c.strip()]
    if not deduped:
        return {}
    try:
        with tempfile.TemporaryDirectory(prefix="lit_match_") as tmp:
            in_path = Path(tmp) / "contents.json"
            out_path = Path(tmp) / "matches.json"
            in_path.write_text(
                json.dumps(deduped, ensure_ascii=False), encoding="utf-8"
            )
            goal = (
                "use_module(misconceptions(literature_deontic_bridge)),"
                "literature_deontic_bridge:lit_deontic_content_match_files("
                f"'{in_path}','{out_path}')"
            )
            proc = subprocess.run(
                [swipl, "-q", "-l", "paths.pl", "-g", goal, "-t", "halt"],
                cwd=repo_root,
                capture_output=True,
                timeout=timeout,
            )
            if proc.returncode != 0 or not out_path.exists():
                return {}
            rows = json.loads(out_path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    if not isinstance(rows, list):
        return {}
    table: dict[str, list[str]] = {}
    for row in rows:
        if not isinstance(row, dict):
            continue
        content = str(row.get("content", ""))
        terms = row.get("terms")
        if content and isinstance(terms, list):
            table[content] = [str(t) for t in terms if str(t).strip()]
    return table


def literature_commitment_matcher(contents: list[str], **kwargs):
    """Matcher backed by one batched literature canonical run over `contents`.

    Suitable for deontic_events_from_talkmoves_audits(matcher=...). Contents
    outside the precomputed batch, and any batch failure, read as abstention.
    """
    table = literature_canonical_match_many(contents, **kwargs)

    def matcher(content: str) -> list[str]:
        return list(table.get(content, []))

    return matcher


def composed_matcher(*matchers):
    """Union of matchers in order, first admission first, duplicates dropped.

    Each matcher abstains independently; the composition abstains only when
    all of them do."""

    def matcher(content: str) -> list[str]:
        out: list[str] = []
        for m in matchers:
            for term in _matched_commitments(m, content):
                if term not in out:
                    out.append(term)
        return out

    return matcher


def audit_contents(audits: list[dict[str, Any]]) -> list[str]:
    """The distinct reading contents carried by TalkMoves/PML audit packets,
    in first-appearance order — the batch a literature matcher precomputes."""
    contents: "OrderedDict[str, None]" = OrderedDict()
    for audit in audits:
        for axiom in audit.get("axioms", []) or []:
            prolog = axiom.get("prolog", {}) or {}
            content = str(prolog.get("content", "") or "").strip()
            if content:
                contents.setdefault(content, None)
    return list(contents)


def _matched_commitments(matcher, content: str) -> list[str]:
    """Canonical terms the stage-1 matcher admits for the content; [] when no
    matcher is supplied, the matcher abstains, or the matcher call fails."""
    if matcher is None or not content:
        return []
    try:
        matched = matcher(content)
    except Exception:
        return []
    if not isinstance(matched, list):
        return []
    return [str(term) for term in matched if str(term).strip()]


def _candidate_terms(
    prolog: dict[str, Any],
    *keys: str,
    fallback: str | list[str] | None = None,
) -> list[str]:
    for key in keys:
        raw = prolog.get(key)
        if raw is None:
            continue
        if isinstance(raw, str):
            values = [raw]
        elif isinstance(raw, list):
            values = [str(value) for value in raw if str(value).strip()]
        else:
            values = [str(raw)]
        if values:
            return values
    if isinstance(fallback, list):
        return [str(term) for term in fallback if str(term).strip()]
    return [fallback] if fallback else []


def _pml_commitment(content: str) -> str:
    return f"pml_commitment({json.dumps(content, ensure_ascii=False)})"


def _source_span_ids(evidence: dict[str, Any]) -> list[str]:
    utterance_id = evidence.get("utterance_id")
    return [str(utterance_id)] if utterance_id else []


def _speaker_id(evidence: dict[str, Any]) -> str:
    return str(evidence.get("alias") or evidence.get("speaker") or "unknown")


def _event_id(
    transcript_id: str,
    axiom_id: str,
    evidences: list[dict[str, Any]],
    evidence: dict[str, Any],
) -> str:
    base = f"{transcript_id}:{axiom_id}"
    if len(evidences) <= 1:
        return base
    utterance_id = str(evidence.get("utterance_id", "") or "")
    return f"{base}:{utterance_id}" if utterance_id else base


def _dedupe(values: list[str]) -> list[str]:
    return list(OrderedDict((value, None) for value in values if str(value).strip()).keys())


def _agent_atom(speaker_id: str) -> str:
    cleaned = "".join(ch.lower() if ch.isalnum() else "_" for ch in speaker_id).strip("_")
    return cleaned or "unknown"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--events", type=Path, help="JSON file containing a list of PML events")
    parser.add_argument("--talkmoves-audit-dir", type=Path, help="Directory of TalkMoves/PML audit JSON packets")
    parser.add_argument("--output", type=Path, help="Write JSON output here")
    args = parser.parse_args()

    if bool(args.events) == bool(args.talkmoves_audit_dir):
        parser.error("provide exactly one of --events or --talkmoves-audit-dir")

    if args.events:
        events = json.loads(args.events.read_text(encoding="utf-8"))
    else:
        audits = [
            json.loads(path.read_text(encoding="utf-8"))
            for path in sorted(args.talkmoves_audit_dir.glob("*.json"))
        ]
        # Literature canonical terms first (the scorekeeper has literature-
        # derived incompatible/2 rules for them), then the worker's
        # misconception/strategy matcher; the opaque fallback only survives
        # when both abstain.
        lit_matcher = literature_commitment_matcher(audit_contents(audits))
        match_worker = PersistentPrologWorker()
        try:
            events = deontic_events_from_talkmoves_audits(
                audits,
                matcher=composed_matcher(
                    lit_matcher, worker_commitment_matcher(match_worker)
                ),
            )
        finally:
            getattr(match_worker, "close", lambda: None)()

    try:
        result = deontic_scoreboard_layer(events)
    except PersistentPrologError as exc:
        raise SystemExit(f"deontic layer failed: {exc}") from exc

    payload = json.dumps(result, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(payload, encoding="utf-8")
    else:
        print(payload, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
