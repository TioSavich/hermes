"""Hermes local teaching console — HTTP server.

Stdlib-only. Serves the console UI and a JSON API. By default the FERPA gate is
disabled for loopback hardening/evaluation and enabled for non-loopback binds
unless ``HERMES_GATE`` is set explicitly. When enabled, that gate couples a
campus/home toggle to TLS posture and refuses student-data operations unless a
verified secure REALLMS connection proves the machine is on the IU network. The
symbolic layer is this repo's live Prolog (``worker.py``); REALLMS (``llm.py``)
supplies prose only.
"""
from __future__ import annotations

import base64
import binascii
import json
import mimetypes
import os
import re
import sys
import threading
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from hermes.app import gate, llm, results, worker
from hermes.app.scripts import verify_monitoring_visuals

APP_DIR = Path(__file__).resolve().parent
WEB_ROOT = APP_DIR / "web"
RUNTIME = APP_DIR / "runtime"

# Repo-root surfaces the console links to so a teacher never needs a second URL
# (Goal A — single front door). Each entry mounts one repo directory at a URL
# prefix that mirrors the repo layout. more-zeeman/ holds the orphaned surfaces
# (fraction bars, monitoring chart, gallery); representation/ + ASKTM_Data/ +
# docs/ carry the manifest and figures the gallery fetches. The whitelist is
# deliberate: the app does NOT serve the repo root indiscriminately.
REPO_ROOT = APP_DIR.parents[1]
STATIC_MOUNTS = {
    "more-zeeman": REPO_ROOT / "more-zeeman",
    "learner": REPO_ROOT / "learner",
    "representation": REPO_ROOT / "representation",
    "ASKTM_Data": REPO_ROOT / "ASKTM_Data",
    "docs": REPO_ROOT / "docs",
}

WORKFLOW_COMMANDS = {"parse", "content", "profile", "draft", "grade", "score", "metrics"}

# Testing override: opt-in via HERMES_GATE_OVERRIDE=1 at launch. Opens the gate for
# synthetic/public-data testing off-campus. Loud in the UI; not for real student data.
OVERRIDE_ALLOWED = os.environ.get("HERMES_GATE_OVERRIDE", "").strip().lower() in ("1", "true", "yes")

# FERPA gate switch. Loopback stays open for local testing; non-loopback binds
# default to the campus/home gate unless HERMES_GATE is set explicitly.
GATE_ENABLED = gate.gate_enabled_for_launch(
    os.environ.get("HERMES_HOST", "127.0.0.1"),
    os.environ.get("HERMES_GATE"),
)

# Module-level state (single-user local dev, matching the original console).
STATE_GATE = gate.GateState(override=OVERRIDE_ALLOWED)

# One shared, long-lived Prolog worker for the whole process. The KB takes
# ~1s to load; spawning a fresh swipl per request (the old behaviour) paid that
# cost on every call. ThreadingHTTPServer can dispatch concurrent requests, so
# the single stdin/stdout exchange is serialised behind _WORKER_LOCK.
_WORKER_LOCK = threading.Lock()
_WORKER: "worker.PersistentPrologWorker | None" = None

# The field-connectivity audit walks ~1300 lessons and is deterministic over a
# given build. The first (cold) call computes it; later calls reuse the result,
# so a fresh deployment pays the cost once instead of timing out on every hit.
_FIELD_AUDIT_CACHE: "Any | None" = None

# Error messages from worker.PersistentPrologError that mean the swipl process
# (not the query) actually broke — safe to restart and retry once. A *timeout*
# is deliberately NOT here: the connectivity audit legitimately takes ~30s, and
# retrying it would kill a working process and double the cost.
_WORKER_TRANSPORT_MARKERS = (
    "pipe closed", "malformed json", "worker exited",
)

# The shared worker timeout must comfortably exceed the slowest op — the
# field-connectivity audit walks ~1300 lessons (~30s warm).
_WORKER_TIMEOUT = 120.0


def _shared_worker() -> "worker.PersistentPrologWorker":
    global _WORKER
    if _WORKER is None:
        _WORKER = worker.PersistentPrologWorker(timeout=_WORKER_TIMEOUT)
    return _WORKER


def worker_request(op: str, **payload: Any) -> Any:
    """Run one op on the shared worker, serialised. Retries once on a genuine
    transport failure (the worker auto-restarts), but never on a slow query
    (timeout) or a genuine op error."""
    global _WORKER
    with _WORKER_LOCK:
        w = _shared_worker()
        try:
            return w.request(op, **payload)
        except worker.PersistentPrologError as exc:
            if any(m in str(exc).lower() for m in _WORKER_TRANSPORT_MARKERS):
                w.restart()
                return w.request(op, **payload)
            raise
        except OSError:
            # The swipl executable could not be launched (e.g. a stale or bad
            # HERMES_SWIPL path). Drop the cached worker so the NEXT request
            # rebuilds it and re-resolves swipl from the current environment,
            # instead of being permanently poisoned by one bad path. The friendly
            # "swipl missing" message is still surfaced by the do_POST handler.
            try:
                w.close()
            except Exception:
                pass
            _WORKER = None
            raise


def _mode_payload() -> dict:
    return {
        "mode": STATE_GATE.mode,
        "verified": STATE_GATE.verified,
        "override": STATE_GATE.override,
        "override_allowed": OVERRIDE_ALLOWED,
        "gate_enabled": GATE_ENABLED,
    }

TRANSCRIPT_SPEAKER_RE = re.compile(
    r"^\s*(student\s*\d+|s\d+|[A-Za-z][A-Za-z .'-]{0,40})\s*:\s+\S",
    re.IGNORECASE,
)
NON_SPEAKER_LABELS = {"answer", "answers", "note", "prompt", "question", "response", "state", "trace"}
LESSON_CODE_RE = re.compile(r"^IM-G(?P<grade>K|\d+)-U(?P<unit>\d+)-L(?P<lesson>\d+)$")
INT_RE = r"\d[\d,]*"
FRACTION_RE = re.compile(r"\b(?P<a>\d{1,3})\s*/\s*(?P<b>\d{1,3})\b")

CHAT_SYSTEM_PROMPT = (
    "You are Hermes, a careful assistant for an Indiana mathematics-methods "
    "course. You sit on top of a symbolic knowledge base: children's arithmetic "
    "strategies modeled as finite-state automata, documented misconceptions with "
    "the exact wrong answers they produce, Common Core and Indiana standards, "
    "Lakoff & Núñez grounding metaphors, and literature-derived incompatibility "
    "analyses (the rule a student appears to follow, where that rule IS valid, "
    "and the normative commitment it collides with, each with a citation). "
    "Answer the instructor plainly and "
    "concretely, GROUNDED in the SYMBOLIC FACTS supplied with the question — refer "
    "to them by name. If the facts are empty or thin, say so plainly and answer "
    "cautiously; do NOT invent strategy names, misconception rules, or standards. "
    "Do not invent student data. Keep claims modest."
)


def _ground_message(message: str) -> dict | None:
    """Retrieve symbolic facts relevant to a chat question. Best-effort: returns
    None if the worker/swipl is unavailable, so chat still works ungrounded."""
    try:
        return worker_request("ground", query=message)
    except Exception:
        return None


def _fraction_compare_scene_request(message: str) -> dict | None:
    text = message.lower()
    if "fraction" not in text or not any(word in text for word in ("bar", "bars", "compare", "scene")):
        return None
    match = FRACTION_RE.search(message)
    if not match:
        return None
    a = int(match.group("a"))
    b = int(match.group("b"))
    if "improper" in text:
        kind = "improper_fraction_iteration"
    elif "partition" in text or "part of part" in text or "part-of-part" in text:
        kind = "recursive_partition"
    else:
        kind = "unit_fraction_iteration"
    query = urllib.parse.urlencode({"kind": kind, "a": a, "b": b})
    return {
        "kind": kind,
        "a": a,
        "b": b,
        "url": f"/more-zeeman/fraction-bars/compare.html?{query}",
    }


def _chat_render_scene_request(message: str) -> dict | None:
    text = message.lower()
    nums = [int(n) for n in re.findall(r"\d{1,4}", message)]

    def scene(op: str, payload: dict, path: str) -> dict:
        query = urllib.parse.urlencode(payload)
        return {"op": op, "payload": payload, "url": f"{path}?{query}"}

    if ("area" in text or "array" in text) and len(nums) >= 2:
        payload = {"kind": "array_multiplication", "a": nums[0], "b": nums[1]}
        return scene("area_render", payload, "/more-zeeman/area-model/index.html")
    if ("base-ten" in text or "base ten" in text or "blocks" in text) and len(nums) >= 2:
        payload = {"kind": "add_with_carry", "a": nums[0], "b": nums[1], "base": 10}
        return scene("base_ten_render", payload, "/more-zeeman/base-ten/index.html")
    if ("set grouping" in text or "make ten" in text or "ten frame" in text) and len(nums) >= 2:
        payload = {"kind": "make_ten", "a": nums[0], "b": nums[1]}
        return scene("set_grouping_render", payload, "/more-zeeman/set-grouping/index.html")
    if "balance" in text and len(nums) >= 3:
        payload = {"a": nums[0], "b": nums[1], "c": nums[2]}
        return scene("balance_render", payload, "/more-zeeman/balance-scale/index.html")
    return None


def _grounding_facts_block(g: dict | None) -> str:
    """A compact, plain-text rendering of retrieved facts for the model prompt."""
    if not g or not g.get("total"):
        return ("SYMBOLIC FACTS: Hermes has no encoded strategy, misconception, "
                "standard, or grounding metaphor matching this question.")
    lines = ["SYMBOLIC FACTS Hermes retrieved from its knowledge base "
             "(ground your answer in these; do not invent others):"]
    if g.get("strategies"):
        lines.append("- Strategies (children's arithmetic automata): " + "; ".join(
            f"{s['kind']} ({s['operation']}{', runnable' if s.get('runnable') else ''})"
            for s in g["strategies"]))
    if g.get("misconceptions"):
        parts = []
        for m in g["misconceptions"]:
            ex = m.get("example") or {}
            if ex.get("wrong"):
                parts.append(f"{m['name']} — a student computes {ex['input']} and gets "
                             f"{ex['wrong']} (correct: {ex['correct']})")
            else:
                parts.append(f"{m['name']} ({m['domain']})")
        lines.append("- Misconceptions with the exact wrong answer each produces: " + "; ".join(parts))
    if g.get("standards"):
        lines.append("- Standards: " + "; ".join(
            f"{str(s['framework']).upper()} {s['code']} — {str(s['statement'])[:110]}"
            for s in g["standards"]))
    if g.get("metaphors"):
        lines.append("- Lakoff & Núñez grounding metaphors: " + "; ".join(
            f"{m['short_name']} ({m['breaks']} break-point(s))" for m in g["metaphors"]))
    if g.get("geometry"):
        lines.append("- Geometry concepts: " + "; ".join(
            f"{item.get('concept')} — {item.get('name')} ({item.get('topic')})"
            for item in g["geometry"]))
    if g.get("literature"):
        parts = []
        for c in g["literature"]:
            valid = c.get("valid_domain")
            where = f"valid in {valid}" if valid and valid != "none" else "a genuine slip"
            parts.append(
                f"{c['student_rule']} ({where}; collides with {c['incompatible_with']}) "
                f"[{c.get('citation') or 'uncited'}]"
            )
        lines.append("- Literature-derived incompatibility analyses "
                     "(rule / where it IS valid / what it collides with): " + "; ".join(parts))
    return "\n".join(lines)


def _lesson_teacher_guide_path(code: str) -> Path | None:
    match = LESSON_CODE_RE.match(code)
    if not match:
        return None
    grade = match.group("grade")
    grade_dir = "kindergarten" if grade == "K" else f"grade{grade}"
    return (
        REPO_ROOT
        / "geometry"
        / "corpus"
        / "im_teacher_guides"
        / grade_dir
        / f"unit{match.group('unit')}"
        / f"lesson{match.group('lesson')}.md"
    )


def _lesson_teacher_guide_text(code: str) -> str:
    path = _lesson_teacher_guide_path(code)
    if not path or not path.is_file():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def _parse_int(text: str) -> int:
    return int(text.replace(",", ""))


def _format_int(value: int) -> str:
    return f"{value:,}" if abs(value) >= 1000 else str(value)


def _lesson_addition_candidates(text: str) -> list[tuple[int, int]]:
    candidates: list[tuple[int, int]] = []
    for match in re.finditer(rf"(?<!\d)({INT_RE})\s*\+\s*({INT_RE})(?:\s*=\s*({INT_RE}))?", text):
        a, b = _parse_int(match.group(1)), _parse_int(match.group(2))
        if match.group(3) and a + b != _parse_int(match.group(3)):
            continue
        candidates.append((a, b))
    for match in re.finditer(rf"sum of\s+({INT_RE})\s+and\s+({INT_RE})", text, re.IGNORECASE):
        candidates.append((_parse_int(match.group(1)), _parse_int(match.group(2))))
    return candidates


def _lesson_subtraction_candidates(text: str) -> list[tuple[int, int]]:
    candidates: list[tuple[int, int]] = []
    for match in re.finditer(rf"(?<!\d)({INT_RE})\s*-\s*({INT_RE})(?:\s*=\s*({INT_RE}))?", text):
        a, b = _parse_int(match.group(1)), _parse_int(match.group(2))
        if match.group(3) and a - b != _parse_int(match.group(3)):
            continue
        candidates.append((a, b))
    start = re.search(rf"Starting number:\s*({INT_RE})", text, re.IGNORECASE)
    end = re.search(rf"Ending number:\s*({INT_RE})", text, re.IGNORECASE)
    if start and end:
        a, result = _parse_int(start.group(1)), _parse_int(end.group(1))
        if a >= result:
            candidates.insert(0, (a, a - result))
    return candidates


def _chart_names(chart: dict, key: str) -> set[str]:
    rows = chart.get(key) or []
    names = {
        str(row.get("kind") or row.get("name") or "")
        for row in rows
        if isinstance(row, dict)
    }
    return {name for name in names if name}


def _render_doc(request: dict[str, Any]) -> dict:
    op = str(request.get("op") or "")
    kwargs = {k: v for k, v in request.items() if k != "op"}
    doc = worker_request(op, **kwargs)
    return doc if isinstance(doc, dict) else {"error": f"{op} returned a non-document value"}


def _representation_spec_proof_request(request: dict[str, Any]) -> dict[str, Any] | None:
    """Translate a render request into the grammar proof request it should satisfy."""
    op = str(request.get("op") or "")
    payload = {k: v for k, v in request.items() if k != "op"}
    representation_by_op = {
        "set_grouping_render": "set_grouping",
        "base_ten_render": "base_ten_blocks",
        "ace_of_bases_render": "base_ten_blocks",
        "unit_echo_render": "fraction_bars",
        "base_ten_compare": "base_ten_blocks",
        "number_line_render": "number_line",
        "place_value_chart_render": "place_value_chart",
        "area_render": "area_model",
        "area_compare": "area_model",
        "balance_render": "balance_scale",
        "balance_compare": "balance_scale",
        "fraction_render": "fraction_bars",
        "hybridization_render": "hybridization",
    }
    representation = representation_by_op.get(op)
    if not representation:
        return None

    proof = {"representation": representation, **payload}
    kind = str(payload.get("kind") or "")
    if op == "base_ten_compare":
        proof["kind"] = "add_with_dropped_carry"
        proof["task"] = "whole_number_addition"
    elif op == "area_compare":
        proof["kind"] = "area_compare"
        proof["task"] = "fraction_product"
    elif op == "balance_compare":
        proof["kind"] = "balance_compare"
        proof["task"] = "equation_linear"
    elif op == "set_grouping_render" and kind == "make_ten_drop_leftover":
        proof["task"] = "whole_number_addition"
    elif op == "base_ten_render" and kind == "subtract_without_reducing_borrow":
        proof["task"] = "whole_number_subtraction"
    elif op == "hybridization_render":
        proof.setdefault("kind", "circle_partition_on_rectangle")
    elif op == "fraction_render" and kind == "add_numerators_and_denominators":
        proof["task"] = "fraction_addition"
    return proof


def _representation_spec_proof(request: dict[str, Any]) -> dict:
    proof_request = _representation_spec_proof_request(request)
    if proof_request is None:
        return {
            "status": "proof_unavailable",
            "reason": f"no representation_spec_check mapping for {request.get('op')}",
        }
    grammar = worker_request("representation_spec_check", **proof_request)
    if not isinstance(grammar, dict):
        return {
            "status": "proof_error",
            "request": {"op": "representation_spec_check", **proof_request},
            "reason": f"representation_spec_check returned {type(grammar).__name__}",
        }
    if grammar.get("preserves") is True:
        status = "productive_preserves_denoted_task"
    elif grammar.get("deformation"):
        status = "misconception_deformation"
    else:
        status = "proof_inconclusive"
    return {
        "status": status,
        "request": {"op": "representation_spec_check", **proof_request},
        "grammar": grammar,
    }


def _frame_proof(doc: dict) -> dict:
    frames = doc.get("frames") if isinstance(doc, dict) else []
    frames = frames if isinstance(frames, list) else []
    frame_count = len(frames)
    sequence = [
        {
            "step": frame.get("step"),
            "verb": str(frame.get("verb") or ""),
            "caption": str(frame.get("caption") or ""),
        }
        for frame in frames
        if isinstance(frame, dict)
    ]
    return {
        "frame_count": frame_count,
        "temporal": frame_count > 1,
        "frame_sequence": sequence,
    }


def _interpretive_residue() -> dict:
    return {
        "status": "human_endorsement_required",
        "claim": (
            "Hermes checks representation grammar, denotation, deformation evidence, "
            "refusal, and render frames; it does not certify that this generated "
            "visual is a faithful reading of any particular student's work."
        ),
        "machine_certifies": [
            "render spec denotation or named deformation evidence",
            "representation refusal when a vocabulary cannot productively denote the task",
            "temporal frame count and scene-contract shape",
        ],
        "human_must_endorse": [
            "the fit between extracted teacher-guide numbers and the lesson activity",
            "the projective reading from an actual student work sample to this labeled misconception",
        ],
    }


def _proof_for_render_pair(correct_request: dict[str, Any], correct_doc: dict,
                           incorrect_request: dict[str, Any], incorrect_doc: dict) -> dict:
    correct_proof = _representation_spec_proof(correct_request)
    correct_proof.update(_frame_proof(correct_doc))
    incorrect_proof = _representation_spec_proof(incorrect_request)
    incorrect_proof.update(_frame_proof(incorrect_doc))
    return {
        "source": "representation_grammar_and_render_contract",
        "correct": correct_proof,
        "incorrect": incorrect_proof,
        "interpretive_residue": _interpretive_residue(),
    }


def _proof_for_refusal(correct_request: dict[str, Any], correct_doc: dict,
                       decision: dict) -> dict:
    correct_proof = _representation_spec_proof(correct_request)
    correct_proof.update(_frame_proof(correct_doc))
    return {
        "source": "representation_grammar_and_render_contract",
        "correct": correct_proof,
        "incorrect": {
            "status": "refused_by_representation_grammar",
            "refusal": str(decision.get("refusal") or ""),
            "grammar": decision,
            "frame_count": 0,
            "temporal": False,
            "frame_sequence": [],
        },
        "interpretive_residue": _interpretive_residue(),
    }


def _representation_check(representation: str, task: str, **payload: Any) -> dict:
    decision = worker_request(
        "representation_check",
        mode="productive",
        representation=representation,
        task=task,
        **payload,
    )
    return decision if isinstance(decision, dict) else {
        "allowed": False,
        "refusal": f"representation_check returned {type(decision).__name__}",
    }


def _representation_candidates(lesson_code: str, task: str, **payload: Any) -> dict:
    result = worker_request(
        "representation_candidates",
        lesson_code=lesson_code,
        task=task,
        **payload,
    )
    return result if isinstance(result, dict) else {
        "candidates": [],
        "refusals": [],
        "error": f"representation_candidates returned {type(result).__name__}",
    }


def _refusal_reason_for_candidate_result(candidate_result: dict, representation: str) -> str | None:
    refusals = [
        refusal for refusal in (candidate_result.get("refusals") or [])
        if refusal.get("representation") == representation
    ]
    if not refusals:
        return None
    physical = [
        str(refusal.get("reason") or "")
        for refusal in refusals
        if "no_physical_block_for_required_place_value" in str(refusal.get("reason") or "")
    ]
    if physical:
        def refusal_number(reason: str) -> int:
            match = re.search(r"\((\d+)\)", reason)
            return int(match.group(1)) if match else 10**18
        return sorted(physical, key=refusal_number)[0]
    return str(refusals[0].get("reason") or "")


def _has_drawable_candidate(candidate_result: dict, representation: str) -> bool:
    return any(
        candidate.get("representation") == representation
        and str(candidate.get("render_status") or "").startswith("renderable(")
        for candidate in (candidate_result.get("candidates") or [])
    )


def _candidate_for_representation(candidate_result: dict, representation: str) -> dict | None:
    for candidate in candidate_result.get("candidates") or []:
        if isinstance(candidate, dict) and candidate.get("representation") == representation:
            return candidate
    return None


def _refusal_for_representation(candidate_result: dict, representation: str) -> dict | None:
    for refusal in candidate_result.get("refusals") or []:
        if isinstance(refusal, dict) and refusal.get("representation") == representation:
            return refusal
    return None


def _alternative_representation_search(
    candidate_result: dict,
    failed_representation: str,
    failed_reason: str,
    order: list[str],
) -> dict:
    attempts: list[dict] = []
    selected: dict | None = None
    for representation in order:
        candidate = _candidate_for_representation(candidate_result, representation)
        refusal = _refusal_for_representation(candidate_result, representation)
        if candidate and str(candidate.get("render_status") or "").startswith("renderable("):
            attempt = {
                "representation": representation,
                "status": "selected" if selected is None else "available",
                "render_status": str(candidate.get("render_status") or ""),
                "evidence": candidate.get("evidence") or [],
            }
            if selected is None:
                selected = attempt
        elif refusal:
            attempt = {
                "representation": representation,
                "status": "refused",
                "reason": str(refusal.get("reason") or ""),
            }
        else:
            attempt = {
                "representation": representation,
                "status": "unavailable",
                "reason": "no lesson-licensed drawable candidate returned",
            }
        attempts.append(attempt)
    return {
        "failed": {
            "representation": failed_representation,
            "reason": failed_reason,
        },
        "attempts": attempts,
        "selected": selected or {},
    }


def _visual_card(expression: str, correct: dict, incorrect: dict,
                 correct_label: str, incorrect_label: str,
                 family: str) -> dict:
    correct_doc = _render_doc(correct)
    incorrect_doc = _render_doc(incorrect)
    return {
        "expression": expression,
        "family": family,
        "source": "generated_from_teacher_guide_and_monitoring_chart",
        "correct": {
            "label": "Correct strategy",
            "description": correct_label,
            "request": correct,
            "doc": correct_doc,
        },
        "incorrect": {
            "label": "Incorrect strategy",
            "description": incorrect_label,
            "request": incorrect,
            "doc": incorrect_doc,
        },
        "proof": _proof_for_render_pair(correct, correct_doc, incorrect, incorrect_doc),
    }


def _visual_refusal_card(expression: str, correct: dict, refused: dict,
                         correct_label: str, refusal_label: str,
                         family: str, decision: dict) -> dict:
    reason = str(decision.get("refusal") or "representation grammar refused this visual")
    correct_doc = _render_doc(correct)
    return {
        "expression": expression,
        "family": family,
        "source": "generated_from_teacher_guide_and_monitoring_chart",
        "status": "refused_by_representation_grammar",
        "grammar": decision,
        "correct": {
            "label": "Correct strategy",
            "description": correct_label,
            "request": correct,
            "doc": correct_doc,
        },
        "incorrect": {
            "label": "Misconception visual refused",
            "description": refusal_label,
            "request": refused,
            "doc": {
                "error": f"Representation grammar refused this base-ten picture: {reason}",
                "frames": [],
            },
        },
        "proof": _proof_for_refusal(correct, correct_doc, decision),
    }


def _monitoring_visuals_for_chart(code: str, chart: dict) -> dict:
    text = _lesson_teacher_guide_text(code)
    strategies = _chart_names(chart, "anticipated_strategies")
    misconceptions = _chart_names(chart, "teacher_misconceptions")
    visuals: list[dict] = []

    if {"make_ten_split_leftover", "make_ten_drop_leftover"} & (strategies | misconceptions):
        small_additions = [
            (a, b) for a, b in _lesson_addition_candidates(text)
            if a + b <= 20 and max(a, b) < 10 and min(a, b) > 0
        ]
        if small_additions:
            shown_a, shown_b = small_additions[0]
            render_a, render_b = (shown_a, shown_b)
            if shown_b > shown_a:
                render_a, render_b = shown_b, shown_a
            visuals.append(_visual_card(
                f"{shown_a} + {shown_b}",
                {"op": "set_grouping_render", "kind": "make_ten", "a": render_a, "b": render_b},
                {"op": "set_grouping_render", "kind": "make_ten_drop_leftover", "a": render_a, "b": render_b},
                "Make a ten, then preserve the leftover.",
                "Make a ten, then drop the leftover.",
                "make_ten",
            ))

    subtraction_needs_borrow = "borrow_without_reducing_bases" in misconceptions or "decompose_base_for_ones" in strategies
    if subtraction_needs_borrow:
        subtraction = next(
            ((a, b) for a, b in _lesson_subtraction_candidates(text) if a >= b and (a % 10) < (b % 10)),
            None,
        )
        if subtraction:
            a, b = subtraction
            visuals.append(_visual_card(
                f"{_format_int(a)} - {_format_int(b)}",
                {"op": "base_ten_render", "kind": "subtract_with_borrow", "a": a, "b": b, "base": 10},
                {"op": "base_ten_render", "kind": "subtract_without_reducing_borrow", "a": a, "b": b, "base": 10},
                "Decompose one ten and reduce the tens place.",
                "Add ten ones but leave the tens place unchanged.",
                "base_ten_subtraction_borrow",
            ))

    addition_with_carry = "column_addition_with_carrying" in strategies or "add_with_dropped_carry" in misconceptions
    if addition_with_carry:
        addition = next(
            ((a, b) for a, b in _lesson_addition_candidates(text) if max(a, b) >= 100 and (a % 1000) + (b % 1000) >= 1000),
            None,
        )
        if addition:
            a, b = addition
            candidate_result = _representation_candidates(
                code,
                "whole_number_addition",
                a=a,
                b=b,
                strategy="column_addition_with_carrying",
                misconception="add_with_dropped_carry",
            )
            expression = f"{_format_int(a)} + {_format_int(b)}"
            base_ten_refusal = _refusal_reason_for_candidate_result(candidate_result, "base_ten_blocks")
            if base_ten_refusal:
                alternative_search = _alternative_representation_search(
                    candidate_result,
                    "base_ten_blocks",
                    base_ten_refusal,
                    ["number_line", "fraction_bars", "place_value_chart"],
                )
                selected_representation = str(
                    (alternative_search.get("selected") or {}).get("representation") or ""
                )
                if selected_representation == "number_line":
                    correct_request = {
                        "op": "number_line_render",
                        "mode": "magnitude",
                        "operation": "addition",
                        "a": a,
                        "b": b,
                    }
                    correct_label = "Use a scalable number-line measure model for the large magnitude."
                elif selected_representation == "place_value_chart":
                    correct_request = {
                        "op": "place_value_chart_render",
                        "kind": "add_with_carry",
                        "a": a,
                        "b": b,
                        "base": 10,
                    }
                    correct_label = "Use a place-value chart for the large-number column algorithm."
                else:
                    correct_request = {"op": "representation_candidates", "lesson_code": code}
                    correct_label = "No drawable productive representation is registered for this task."
                base_ten_decision = {
                    **candidate_result,
                    "allowed": False,
                    "refusal": base_ten_refusal,
                    "alternative_search": alternative_search,
                    "preferred": {
                        "representation": selected_representation,
                        "reason": "alternative_representation_search",
                    },
                }
                visuals.append(_visual_refusal_card(
                    expression,
                    correct_request,
                    {"op": "representation_check", "mode": "productive",
                     "representation": "base_ten_blocks", "task": "whole_number_addition",
                     "a": a, "b": b},
                    correct_label,
                    "Base-ten blocks stop being a productive physical vocabulary here; a collapsed-cube picture would be a labeled misconception, not a calculator answer.",
                    "base_ten_addition_carry_refused_large_number",
                    base_ten_decision,
                ))
            else:
                visuals.append(_visual_card(
                    expression,
                    {"op": "base_ten_render", "kind": "add_with_carry", "a": a, "b": b, "base": 10},
                    {"op": "base_ten_compare", "a": a, "b": b, "base": 10},
                    "Regroup by place value and carry the base-group.",
                    "Write the place remainder and drop the carry.",
                    "base_ten_addition_carry",
                ))

    fraction_addition_names = {
        "fraction_addition_co_measurement",
        "add_fractions_by_co_measurement",
        "co_measurement_fraction_addition",
    }
    fraction_componentwise_names = {
        "add_numerators_and_denominators",
        "add_denominators_unit_fractions",
        "componentwise_fraction_addition",
    }
    if fraction_addition_names & strategies or fraction_componentwise_names & misconceptions:
        visuals.append(_visual_card(
            "1/3 + 1/4",
            {
                "op": "fraction_render",
                "kind": "arith",
                "operation": "add",
                "na": 1,
                "da": 3,
                "nb": 1,
                "db": 4,
            },
            {
                "op": "fraction_render",
                "kind": "add_numerators_and_denominators",
                "na": 1,
                "da": 3,
                "nb": 1,
                "db": 4,
            },
            "Measure both fractions in a shared unit before combining.",
            "Add the visible numerator and denominator components as if they were independent counts.",
            "fraction_bars_addition",
        ))

    balance_strategy_names = {
        "balance_solve_equation",
        "solve_linear_equation",
        "preserve_balance",
    }
    balance_misconception_names = {
        "operational_equals_subtract_from_one_side",
        "operational_equals_compute_one_side",
        "balance_not_preserved",
    }
    if balance_strategy_names & strategies or balance_misconception_names & misconceptions:
        visuals.append(_visual_card(
            "2x + 3 = 11",
            {"op": "balance_render", "a": 2, "b": 3, "c": 11},
            {"op": "balance_compare", "a": 2, "b": 3, "c": 11},
            "Preserve equality by making the same move on both pans.",
            "Treat the equals sign as a command and change only one side.",
            "balance_scale_equation",
        ))

    hybridization_names = {
        "hybridized_model",
        "circle_partition_on_rectangle",
        "circle_radial_partition_on_rectangle",
        "object_language_binding_violation",
    }
    if hybridization_names & misconceptions:
        visuals.append(_visual_card(
            "circle partition transplanted onto a rectangle",
            {
                "op": "area_render",
                "kind": "area_model_fraction",
                "na": 1,
                "da": 2,
                "nb": 1,
                "db": 3,
            },
            {
                "op": "hybridization_render",
                "kind": "circle_partition_on_rectangle",
            },
            "Partition the rectangular area model by its own part-of-part vocabulary.",
            "Move the circle's radial partition rule onto the rectangle host.",
            "hybridization_transplant",
        ))

    return {"lesson_code": code, "visuals": visuals}


def _grounding_summary(g: dict | None) -> dict:
    """Compact source list for the UI to show what the answer was grounded in."""
    if not g:
        return {"total": 0, "strategies": [], "misconceptions": [], "standards": [],
                "metaphors": [], "geometry": [], "literature": []}
    return {
        "total": g.get("total", 0),
        "strategies": [s["kind"] for s in (g.get("strategies") or [])],
        "misconceptions": [m["name"] for m in (g.get("misconceptions") or [])],
        "standards": [f"{s['framework']} {s['code']}" for s in (g.get("standards") or [])],
        "metaphors": [m["short_name"] for m in (g.get("metaphors") or [])],
        "geometry": [f"{c.get('concept')} ({c.get('topic')})" for c in (g.get("geometry") or [])],
        "literature": [f"{c['student_rule']} [{c.get('citation') or 'uncited'}]"
                       for c in (g.get("literature") or [])],
        "math_claims": [f"{c.get('claim', '')}: {c.get('verdict') or c.get('status', '')}"
                        for c in (g.get("math_claims") or [])],
    }


def _offline_chat_answer(grounded: dict) -> str:
    """Deterministic chat answer assembled from the symbolic grounding when no
    language-model key is configured. It states its own boundary rather than
    imitating prose the model would have written."""
    sections = [
        ("math_claims", "Checked claims"),
        ("strategies", "Strategies"),
        ("misconceptions", "Misconceptions"),
        ("standards", "Standards"),
        ("metaphors", "Grounding metaphors"),
        ("geometry", "Geometry concepts"),
        ("literature", "Literature"),
    ]
    lines = []
    for field, label in sections:
        values = grounded.get(field) or []
        if values:
            lines.append(f"{label}: " + ", ".join(str(v) for v in values))
    if not lines:
        return ("No language-model key is configured, and the symbolic knowledge "
                "base returned nothing for this message. " + KEY_HINT)
    return ("No language-model key is configured, so this answer is the symbolic "
            "grounding itself rather than prose about it.\n" + "\n".join(lines))


# The neuro-symbolic loop: Gemma EMITS PML axioms (Prolog), swipl VALIDATES + scores.
PML_SYSTEM_PROMPT = (
    "You are the PML reader. You read a short text and encode the MODAL POSTURE of "
    "each sentence as Prolog facts — not a paraphrase. Output ONLY Prolog facts, "
    "nothing else: no prose, no commentary, no markdown fences.\n\n"
    "Polarized Modal Logic has 12 operators = 3 modes x 4 modal operators.\n"
    "Mode (validity register): s = subjective (first-person avowal: I think/feel/"
    "notice/wonder); o = objective (a claim about the content, object, or world); "
    "n = normative (a demand, rule, entitlement: must/should/counts as/not allowed).\n"
    "Modal operator: comp_nec = binding closure (fixes a rule, identity, or "
    "incompatibility); exp_nec = binding openness (commits to keeping something "
    "open); comp_poss = possible narrowing (entertains a constraint without binding "
    "it); exp_poss = possible opening (offers a live alternative, a hedge, an "
    "invitation).\n\n"
    "For EACH sentence emit exactly one fact:\n"
    "  reader_axiom(AxiomId, [Premises], Mode(Operator(content)), Polarity).\n"
    "- AxiomId: a short snake_case atom you choose (e.g. ax_teacher_demand).\n"
    "- [Premises]: a list; use [] when there are none.\n"
    "- Mode(Operator(content)): the mode wraps the operator which wraps a snake_case "
    "content atom paraphrasing the point, e.g. n(comp_nec(square_is_a_rectangle)) or "
    "s(exp_poss(it_might_be_a_diamond)). Use functional syntax with parentheses; "
    "never the operator-prefix form.\n"
    "- Polarity: compressive for comp_* operators, expansive for exp_* operators. It "
    "MUST agree with the operator.\n\n"
    "End with one fact: passage_mode(passage, OverallMode, \"one-line reading\"). "
    "OverallMode is a snake_case atom (e.g. binds_then_opens).\n\n"
    "Example input: A square is definitely a rectangle. But maybe it looks more like "
    "a diamond to me.\n"
    "Example output:\n"
    "reader_axiom(ax_square_is_rectangle, [], o(comp_nec(square_is_a_rectangle)), compressive).\n"
    "reader_axiom(ax_diamond_hedge, [], s(exp_poss(it_looks_like_a_diamond)), expansive).\n"
    "passage_mode(passage, binds_then_opens, \"a categorical claim softened by a first-person hedge\").\n"
)


def _extract_pml_clauses(text: str) -> list[str]:
    """Pull balanced reader_axiom(...) / passage_mode(...) clauses out of the model
    output, ignoring any prose or markdown fences around them. The worker only
    term-PARSES these (never consults them), so this is the safe collection step."""
    clauses: list[str] = []
    for kw in ("reader_axiom", "passage_mode"):
        needle, start = kw + "(", 0
        while True:
            j = text.find(needle, start)
            if j < 0:
                break
            depth, k = 0, j + len(kw)
            while k < len(text):
                ch = text[k]
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0:
                        break
                k += 1
            if k < len(text):
                clauses.append(text[j:k + 1])
                start = k + 1
            else:
                break
    return clauses

# Plain-language remediation for the three backend-missing failure modes a colleague
# is most likely to hit. We translate raw backend errors into these at the API
# boundary (see _friendly_backend_error) so the console shows an action to take
# rather than a stack-trace fragment. The raw detail is still carried alongside.
SWIPL_HINT = (
    "SWI-Prolog (swipl) isn't installed, or it isn't on your PATH. Install it from "
    "https://www.swi-prolog.org/download/stable, then quit Hermes (Ctrl-C in the "
    "terminal) and run ./hermes/app/launch.sh again. See QUICKSTART_N103.md, step 1."
)
KEY_HINT = (
    "No REALLMS API key is set. Click “Set key” (top-right) and paste your "
    "key, or add it to hermes/app/runtime/.env. See QUICKSTART_N103.md, step 2."
)
WORKER_HINT = (
    "The local Prolog worker didn't respond as expected. If you just installed "
    "SWI-Prolog, restart Hermes. The terminal that launched Hermes has the full detail."
)


def _friendly_backend_error(text: str) -> tuple[str | None, str | None]:
    """Map a raw backend error string to (plain_message, error_type).

    Returns (None, None) when no rule matches, so the caller keeps the raw text.
    Rules are ordered most-specific first.
    """
    low = (text or "").lower()
    if "swipl" in low or ("no such file or directory" in low and "prolog" in low):
        return SWIPL_HINT, "swipl_missing"
    if "reallms_api_key" in low or "set reallms" in low or "no api key" in low \
            or "no reallms api key" in low:
        return KEY_HINT, "no_key"
    if ("worker returned malformed json" in low or "worker exited with" in low
            or "worker request timed out" in low or "worker pipe closed" in low):
        return WORKER_HINT, "worker_failed"
    return None, None


def _looks_like_discussion_transcript(text: str) -> bool:
    labels: list[str] = []
    for raw_line in text.splitlines():
        match = TRANSCRIPT_SPEAKER_RE.match(raw_line)
        if not match:
            continue
        label = re.sub(r"\s+", " ", match.group(1).strip().lower())
        if label in NON_SPEAKER_LABELS:
            continue
        labels.append(label)
    return len(set(labels)) >= 2


def _run_preflight() -> tuple[bool, str]:
    """Secure preflight using the configured key. Never raises."""
    key = llm.load_key(RUNTIME)
    if key is None:
        return False, "no REALLMS_API_KEY configured (set it in the app or runtime/.env)"
    return llm.secure_preflight(api_key=key, api_url=llm.resolve_api_url())


def _ssl_ctx_for_mode():
    """campus -> secure (verified); home -> insecure (tinker only)."""
    os.environ["REALLMS_INSECURE"] = "0" if STATE_GATE.mode == gate.CAMPUS else "1"
    if STATE_GATE.mode == gate.CAMPUS:
        return llm.build_secure_ssl_context()
    return llm.build_ssl_context()


def _resolve_input(key: str):
    """Resolve an /api/inputs key to a file, confined to examples/ or runtime/input/."""
    key = (key or "").strip()
    if key.startswith("examples/"):
        base, name = APP_DIR / "examples", key[len("examples/"):]
    elif key.startswith("input/"):
        base, name = RUNTIME / "input", key[len("input/"):]
    else:
        return None
    target = (base / name).resolve()
    if base.resolve() not in target.parents or not target.is_file():
        return None
    return target


_TWO_PASS_MODULE = None


def _two_pass_module():
    """Load scripts/talkmoves_two_pass.py once, by path (scripts/ is not a
    package). All transcript-report logic lives and is tested there; the
    server is glue."""
    global _TWO_PASS_MODULE
    if _TWO_PASS_MODULE is None:
        import importlib.util
        path = REPO_ROOT / "scripts" / "talkmoves_two_pass.py"
        spec = importlib.util.spec_from_file_location("talkmoves_two_pass", path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        _TWO_PASS_MODULE = module
    return _TWO_PASS_MODULE


def _resolve_static_mount(url_path: str) -> Path | None:
    """Map a GET path to a file under one of the whitelisted STATIC_MOUNTS.

    The first path segment selects the mount; the rest is resolved beneath it
    and must stay contained (no traversal out via '..'). Returns None when the
    prefix is unknown, the file is absent, or containment fails.
    """
    rel = urllib.parse.unquote(url_path.lstrip("/"))
    head, _, tail = rel.partition("/")
    base = STATIC_MOUNTS.get(head)
    if base is None or not tail:
        return None
    target = (base / tail).resolve()
    base_resolved = base.resolve()
    if not target.is_file():
        return None
    if base_resolved != target and base_resolved not in target.parents:
        return None
    return target


class HermesHandler(BaseHTTPRequestHandler):
    server_version = "HermesConsole/0.2"

    # ---- dispatch ----------------------------------------------------------
    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._send_cors_headers()
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self) -> None:
        parsed = urllib.parse.urlsplit(self.path)
        if parsed.path == "/":
            self._send_file(WEB_ROOT / "console.html")
            return
        # Learner research-wing routes operate on public model/demo data and
        # remain outside the student-data gate.
        if parsed.path == "/api/knowledge":
            self._handle_learner_knowledge()
            return
        if parsed.path == "/api/visualize/coordination":
            self._handle_visualize_coordination(parsed.query)
            return
        if parsed.path == "/api/reorganize":
            self._handle_learner_reorganize(parsed.query)
            return
        if self.path == "/api/mode":
            self._send_json(_mode_payload())
            return
        if self.path == "/api/preflight":
            ok, reason = _run_preflight()
            self._send_json({"on_campus": ok, "reason": reason,
                             "key_configured": llm.api_key_configured(RUNTIME)})
            return
        if self.path == "/api/models":
            self._send_json({
                "default_model": llm.DEFAULT_MODEL,
                "model": llm.resolve_model(),
                "renderer": "reallms",
                "key_configured": llm.api_key_configured(RUNTIME),
            })
            return
        if self.path == "/api/quickstart":
            doc = APP_DIR / "QUICKSTART_N103.md"
            if doc.is_file():
                self._send_json({"content": doc.read_text(encoding="utf-8")})
            else:
                self._send_json({"error": "quickstart not found"}, status=404)
            return
        if self.path == "/api/sample":
            sample = APP_DIR / "examples" / "All_Discussions.txt"
            if sample.is_file():
                self._send_json({"name": "All_Discussions.txt (synthetic geometry)",
                                 "text": sample.read_text(encoding="utf-8")})
            else:
                self._send_json({"error": "sample not found"}, status=404)
            return
        if self.path == "/api/inputs":
            # Discussion files a teacher can pick instead of pasting: bundled
            # examples + whatever they dropped in runtime/input/.
            files = []
            for tag, base, prefix in (("sample", APP_DIR / "examples", "examples"),
                                      ("runtime", RUNTIME / "input", "input")):
                if base.is_dir():
                    for p in sorted(base.iterdir()):
                        if p.is_file() and p.suffix.lower() in (".txt", ".md", ".csv") and not p.name.startswith("."):
                            files.append({"label": f"{p.name} ({tag})", "key": f"{prefix}/{p.name}"})
            self._send_json({"files": files})
            return
        # Fraction-bars frames, drawn from the live render automaton. The viewer
        # (more-zeeman/fraction-bars/viewer.js) fetches /api/fraction/render?kind=&n=&d=
        # in its live mode; serving it here lets an embedded viewer draw against
        # this same origin. /api/fraction/compare lays out the productive-vs-
        # deformation pair for a fraction scheme. Public KB, no student data.
        if parsed.path in ("/api/fraction/render", "/api/fraction/compare"):
            self._handle_fraction_frames(self.path)
            return
        path = WEB_ROOT / parsed.path.lstrip("/")
        if path.is_file() and path.resolve().is_relative_to(WEB_ROOT.resolve()):
            self._send_file(path)
            return
        # Repo-root surfaces (more-zeeman/, representation/, ASKTM_Data/, docs/)
        # the console links to — served only via the whitelisted mounts above.
        static = _resolve_static_mount(parsed.path)
        if static is not None:
            self._send_file(static)
            return
        self._send_json({"error": "not found"}, status=404)

    def do_POST(self) -> None:
        global STATE_GATE
        try:
            payload = self._read_json()

            # Learner research-wing routes operate on public model/demo data
            # and remain outside the student-data gate.
            if self.path == "/api/compute":
                self._handle_learner_compute(payload)
                return

            if self.path == "/api/learner/reset":
                self._handle_learner_reset(payload)
                return

            if self.path == "/api/render":
                self._handle_render(payload)
                return

            if self.path == "/api/mode":
                target = str(payload.get("mode") or gate.HOME)
                STATE_GATE = gate.set_mode(STATE_GATE, target, preflight=_run_preflight)
                self._send_json(_mode_payload())
                return

            if self.path == "/api/override":
                if not OVERRIDE_ALLOWED:
                    self._send_json(
                        {"error": "override not allowed; launch with HERMES_GATE_OVERRIDE=1"},
                        status=403,
                    )
                    return
                STATE_GATE = gate.set_override(STATE_GATE, bool(payload.get("on")))
                self._send_json(_mode_payload())
                return

            if self.path == "/api/preflight":
                ok, reason = _run_preflight()
                self._send_json({"on_campus": ok, "reason": reason})
                return

            if self.path == "/api/input":
                if not self._require_unlocked():
                    return
                target = _resolve_input(str(payload.get("key") or ""))
                if target is None:
                    self._send_json({"error": "input not found"}, status=404)
                    return
                self._send_json({"text": target.read_text(encoding="utf-8", errors="replace")})
                return

            if self.path == "/api/set_key":
                self._handle_set_key(payload)
                return

            if self.path == "/api/reset":
                STATE_GATE = gate.GateState(override=OVERRIDE_ALLOWED)
                self._send_json({"ok": True, "mode": STATE_GATE.mode})
                return

            if self.path == "/api/results/list":
                if not self._require_unlocked():
                    return
                self._send_json(results.list_outputs(RUNTIME))
                return

            if self.path == "/api/results/get":
                if not self._require_unlocked():
                    return
                try:
                    self._send_json(results.read_output_file(RUNTIME, str(payload.get("path") or "")))
                except (ValueError, FileNotFoundError) as exc:
                    self._send_json({"error": str(exc)}, status=400)
                return

            if self.path == "/api/analyze":
                if not self._require_unlocked():
                    return
                self._handle_analyze(payload)
                return

            if self.path == "/api/chat":
                self._handle_chat(payload)
                return

            if self.path == "/api/pml_score":
                self._handle_pml_score(payload)
                return

            if self.path == "/api/expressive_power":
                self._handle_expressive_power(payload)
                return

            if self.path == "/api/field_context":
                self._handle_field_context(payload)
                return

            if self.path == "/api/monitoring_chart_export":
                self._handle_monitoring_chart_export(payload)
                return

            if self.path == "/api/ranked_figures":
                self._handle_ranked_figures(payload)
                return

            if self.path == "/api/monitoring_visuals":
                self._handle_monitoring_visuals(payload)
                return

            if self.path == "/api/field_connectivity_audit":
                self._handle_field_connectivity_audit(payload)
                return

            if self.path == "/api/render_coverage":
                self._handle_render_coverage(payload)
                return

            if self.path == "/api/pair_graph":
                if not self._gate_or_423("pair_graph"):
                    return
                self._handle_pair_graph(payload)
                return

            # Encyclopedia surfaces — the public knowledge base, no student data,
            # reachable regardless of the FERPA gate (like field_context).
            if self.path == "/api/strategies":
                self._handle_strategies(payload)
                return
            if self.path == "/api/strategy_trace":
                self._handle_strategy_trace(payload)
                return
            # Two-pass discussion report: blind the speakers locally, extract
            # the math layer (Gemma), adjudicate every typed claim (swipl),
            # mask, read the posture layer (Gemma), and return the
            # teacher-legible report. Blinding happens before any model call.
            if self.path == "/api/transcript_report":
                self._handle_transcript_report(payload)
                return
            # Media ingest for the discussion surface: one uploaded artifact
            # (photo of written work, PDF/DOCX, audio recording) goes to Gemma
            # for a transcription pass; the proposed transcript returns to the
            # composer for the teacher to review before any report runs. The
            # raw artifact cannot be blinded before the model reads it, so
            # this is the one route where the upload itself reaches REALLMS.
            if self.path == "/api/media_transcribe":
                self._handle_media_transcribe(payload)
                return
            # The break, made operable (Goal G): the deontic scorecard surfaces
            # commitment-without-entitlement (a procedurally-correct move that
            # deployed no justifying vocabulary); the sequent witness surfaces
            # erasure(...) where a trace-tainted source makes the proof go hollow.
            # Public reasoning surfaces — no student data, no FERPA gate.
            if self.path == "/api/deontic_scorecard":
                self._handle_deontic_scorecard(payload)
                return
            if self.path == "/api/crisis":
                self._handle_crisis(payload)
                return
            # The rest of the deontic board: consequences reads back what a set of
            # commitments materially commits the agent to; up_level is the
            # objectivation move for an incoherence the within-level layer cannot
            # discharge; requires_entitlement is the single-proposition lookup.
            # Same public-surface posture as the scorecard.
            if self.path == "/api/deontic_consequences":
                self._handle_deontic_consequences(payload)
                return
            if self.path == "/api/deontic_up_level":
                self._handle_deontic_up_level(payload)
                return
            if self.path == "/api/deontic_requires_entitlement":
                self._handle_deontic_requires_entitlement(payload)
                return
            if self.path == "/api/sequent_proof":
                self._handle_sequent_proof(payload)
                return
            if self.path == "/api/misconceptions":
                self._handle_misconceptions(payload)
                return
            if self.path == "/api/standards":
                self._handle_standards(payload)
                return
            if self.path == "/api/grounding":
                self._handle_grounding(payload)
                return
            if self.path == "/api/geometry":
                self._handle_geometry(payload)
                return
            if self.path == "/api/canonical_contract":
                self._handle_canonical_contract(payload)
                return
            if self.path == "/api/canonical_check":
                self._handle_canonical_check(payload)
                return
            if self.path == "/api/diagnose_error":
                self._handle_diagnose_error(payload)
                return
            if self.path == "/api/query_misconception":
                self._handle_query_misconception(payload)
                return
            if self.path == "/api/literature":
                self._handle_literature(payload)
                return
            if self.path == "/api/event_score":
                self._handle_event_score(payload)
                return
            # Public reasoning surfaces — no student data. notation renders the
            # symbol-level representation language; fraction_cgi_addition runs a
            # CGI addition automaton over a shared denominator; the deformation
            # chart covers the three grade-3 IM fraction lessons; the two carving
            # routes expose the arithmetic-proof entitlement surface.
            if self.path == "/api/notation_render":
                self._handle_notation_render(payload)
                return
            if self.path == "/api/fraction_cgi_addition":
                self._handle_fraction_cgi_addition(payload)
                return
            if self.path == "/api/lesson_deformation_chart":
                self._handle_lesson_deformation_chart(payload)
                return
            if self.path == "/api/notation_monitoring_chart":
                self._handle_notation_monitoring_chart(payload)
                return
            if self.path == "/api/brandom_backstop":
                self._handle_brandom_backstop(payload)
                return
            # The break, made operable, from the Brandomian side: one commitment
            # set checked against the declared incompatibility hyperedges (union
            # incoherence + incompatibility entailment + the classical backstop
            # verdict); the discovered hyperedges surfaced with their computed
            # emergence; and runtime axiom toggling. Public KB surfaces — no
            # student data, no FERPA gate.
            if self.path == "/api/brandomian_check":
                self._handle_brandomian_check(payload)
                return
            if self.path == "/api/hyperedges":
                self._handle_hyperedges(payload)
                return
            if self.path == "/api/axiom_toggle":
                self._handle_axiom_toggle(payload)
                return
            if self.path == "/api/carving_strategy_proof":
                self._handle_carving_strategy_proof(payload)
                return
            if self.path == "/api/carving_operation_summary":
                self._handle_carving_operation_summary(payload)
                return
            if self.path == "/api/benny_demo":
                self._handle_benny_demo(payload)
                return

            # The seven workflow commands — all gated (campus + verified only).
            if self.path.startswith("/api/") and self.path[len("/api/"):] in WORKFLOW_COMMANDS:
                op = self.path[len("/api/"):]
                if not self._gate_or_423(op):
                    return
                # Verified campus -> secure; testing/home override -> insecure so the
                # subprocess can reach REALLMS off the IU network.
                os.environ["REALLMS_INSECURE"] = (
                    "0" if (STATE_GATE.mode == gate.CAMPUS and STATE_GATE.verified) else "1"
                )
                from hermes.app import workflow_api
                result = workflow_api.run(op, payload, APP_DIR)
                if not result.get("ok"):
                    # A non-zero exit is reported in stderr/stdout the surface already
                    # renders; add a plain hint when we recognize the cause.
                    hint, error_type = _friendly_backend_error(
                        f"{result.get('stderr') or ''}\n{result.get('stdout') or ''}"
                    )
                    if hint:
                        result["hint"] = hint
                        result["error_type"] = error_type
                self._send_json(result)
                return

            self._send_json({"error": "not found"}, status=404)
        except Exception as exc:  # keep the local server honest
            # Translate the backend-missing cases into a plain action; keep the detail.
            message, error_type = _friendly_backend_error(str(exc))
            if message:
                self._send_json(
                    {"error": message, "error_type": error_type, "detail": str(exc)},
                    status=500,
                )
            else:
                self._send_json({"error": str(exc)}, status=500)

    def log_message(self, fmt: str, *args: Any) -> None:
        return

    # ---- handlers ----------------------------------------------------------
    def _handle_learner_compute(self, payload: object) -> None:
        if not isinstance(payload, dict):
            self._send_json({"error": "request body must be a JSON object"}, status=400)
            return
        operation = payload.get("operation")
        if operation not in {"add", "subtract", "multiply", "divide"}:
            self._send_json(
                {"error": "operation must be add, subtract, multiply, or divide"},
                status=400,
            )
            return
        if type(payload.get("a")) is not int or type(payload.get("b")) is not int:
            self._send_json({"error": "a and b must be integers"}, status=400)
            return
        limit = payload.get("limit", 20)
        if type(limit) is not int or limit <= 0:
            self._send_json({"error": "limit must be a positive integer"}, status=400)
            return
        mode = payload.get("mode", "direct")
        if mode not in {"direct", "developmental"}:
            self._send_json(
                {"error": "mode must be direct or developmental"}, status=400
            )
            return
        request = {
            "operation": operation,
            "a": payload["a"],
            "b": payload["b"],
            "limit": limit,
            "mode": mode,
        }
        try:
            result = worker_request("compute", **request)
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        self._send_json(result)

    def _handle_learner_knowledge(self) -> None:
        try:
            result = worker_request("knowledge")
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        self._send_json(result)

    def _handle_visualize_coordination(self, query: str) -> None:
        params = urllib.parse.parse_qs(query, keep_blank_values=True)
        try:
            base = self._query_integer(params, "base", 10)
            val_up = self._query_integer(params, "val_up", 0)
        except ValueError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        if not 2 <= base <= 15:
            self._send_json({"error": "base must be between 2 and 15"}, status=400)
            return
        if val_up < 0:
            self._send_json({"error": "val_up must be non-negative"}, status=400)
            return
        val_down = params.get("val_down", ["1"])[-1]
        if "/" in val_down:
            pieces = val_down.split("/")
            try:
                if len(pieces) != 2:
                    raise ValueError
                int(pieces[0])
                denominator = int(pieces[1])
            except ValueError:
                self._send_json(
                    {"error": "val_down fractions must have integer numerator and denominator"},
                    status=400,
                )
                return
            if denominator == 0:
                self._send_json(
                    {"error": "val_down denominator must be non-zero"}, status=400
                )
                return
        try:
            result = worker_request(
                "visualize_coordination",
                base=base,
                val_up=val_up,
                val_down=val_down,
            )
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        self._send_utf8(result["svg"], "image/svg+xml; charset=utf-8")

    def _handle_learner_reorganize(self, query: str) -> None:
        params = urllib.parse.parse_qs(query, keep_blank_values=True)
        domain = params.get("domain", ["fraction_splitting"])[-1]
        if domain not in {
            "fraction_splitting", "fraction_improper",
            "fraction_of_fraction", "fraction_algebra",
        }:
            self._send_json({"error": "unknown reorganization domain"}, status=400)
            return
        try:
            request = {
                "domain": domain,
                "a": self._query_integer(params, "a", 3),
                "b": self._query_integer(params, "b", 8),
                "c": self._query_integer(params, "c", 4),
                "d": self._query_integer(params, "d", 5),
            }
        except ValueError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        try:
            result = worker_request("reorganize", **request)
        except worker.PersistentPrologError as exc:
            self._send_json(
                {"error": True, "message": str(exc), "domain": domain}, status=400
            )
            return
        self._send_json(result)

    def _handle_learner_reset(self, payload: object) -> None:
        if not isinstance(payload, dict):
            self._send_json({"error": "request body must be a JSON object"}, status=400)
            return
        try:
            result = worker_request("learner_reset")
        except worker.PersistentPrologError as exc:
            self._send_json({"error": str(exc)}, status=400)
            return
        self._send_json(result)

    @staticmethod
    def _query_integer(params: dict[str, list[str]], key: str, default: int) -> int:
        values = params.get(key)
        if not values:
            return default
        try:
            return int(values[-1])
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{key} must be an integer") from exc

    def _handle_analyze(self, payload: dict) -> None:
        """Ingest -> domain-general discourse layer -> signal-gated router ->
        student-level, capped, provenance-labelled pairing. Local and model-free."""
        from hermes.app.analysis import discourse, event_importer, ingest, router
        raw = payload.get("transcript")
        if raw is None:
            raw = payload.get("text") or payload.get("events")
        if raw is None:
            self._send_json({"error": "transcript, text, or events required"}, status=400)
            return
        if isinstance(raw, (list, dict)):
            try:
                events = event_importer.events_from_payload(raw)
            except ValueError as exc:
                self._send_json({"error": str(exc)}, status=400)
                return
            meta = {"format": "events", "event_count": len(events)}
        else:
            events, meta = ingest.ingest(str(raw))
        if not events:
            self._send_json(
                {"error": "no contributions parsed — use 'Speaker: text' lines (two or more speakers), "
                          "or paste a table with Speaker and text columns"},
                status=400,
            )
            return
        flag = ingest.implausible_speakers(events)
        top_n = int(payload.get("top_n") or 8)
        result = discourse.analyze_discourse(events, top_n=top_n, include_all=bool(payload.get("include_all")))
        # Signal-gated router: enrich + relabel as grounded when the domain is modelled.
        routing = router.route(events, force_mode=payload.get("force_mode"))
        if routing["mode"] == "grounded":
            result["pairs"] = router.enrich_pairs(result["pairs"], routing["by_student"])[:top_n]
            result["provenance"] = "grounded"
        result["routing"] = {k: routing[k] for k in ("mode", "grounding_score", "topics", "forced")}
        result["ingest"] = meta
        if flag["implausible"]:
            result["warning"] = flag["reason"]
        self._send_json(result)

    def _handle_set_key(self, payload: dict) -> None:
        key = str(payload.get("api_key") or "").strip()
        if not key.startswith("sk-"):
            self._send_json({"error": "expected a key starting with sk-"}, status=400)
            return
        RUNTIME.mkdir(parents=True, exist_ok=True)
        env_path = RUNTIME / ".env"
        env_path.write_text(f"REALLMS_API_KEY={key}\n", encoding="utf-8")
        os.environ["REALLMS_API_KEY"] = key
        self._send_json({"ok": True, "key_configured": True})

    def _handle_chat(self, payload: dict) -> None:
        message = str(payload.get("message") or "").strip()
        if not message:
            self._send_json({"error": "message is required"}, status=400)
            return
        if _looks_like_discussion_transcript(message):
            self._send_json({
                "error": ("This looks like speaker-labeled discussion text. "
                          "Use the Discussion reports page (/discussions.html) — "
                          "it blinds the speakers locally before any model call "
                          "and returns a claim-by-claim report."),
                "error_type": "chat_transcript_safety",
            }, status=400)
            return
        scene = _fraction_compare_scene_request(message)
        if scene is not None:
            result = worker_request("fraction_compare",
                                    kind=scene["kind"],
                                    a=scene["a"],
                                    b=scene["b"])
            self._send_json({
                "answer": f"Fraction-bars compare scene: {scene['url']}",
                "scene": scene,
                "result": result,
                "model": "offline-symbolic",
                "offline": True,
                "mode": STATE_GATE.mode,
                "insecure": not (STATE_GATE.mode == gate.CAMPUS and STATE_GATE.verified),
            })
            return
        scene = _chat_render_scene_request(message)
        if scene is not None:
            result = worker_request(scene["op"], **scene["payload"])
            self._send_json({
                "answer": f"Render scene: {scene['url']}",
                "scene": scene,
                "result": result,
                "model": "offline-symbolic",
                "offline": True,
                "mode": STATE_GATE.mode,
                "insecure": not (STATE_GATE.mode == gate.CAMPUS and STATE_GATE.verified),
            })
            return
        # Retrieve symbolic facts FIRST, so the answer is grounded in the KB
        # (and so the UI can show what it was grounded in) — neuro-symbolic, not
        # a free-associating chatbot. Best-effort; chat still works ungrounded.
        grounding = _ground_message(message)
        grounded = _grounding_summary(grounding)
        key = llm.load_key(RUNTIME)
        if key is None:
            # Offline fallback: the symbolic grounding IS the answer. No prose
            # model is imitated; the reply names its own boundary and carries
            # the key hint so the console can say how to enable prose.
            self._send_json({
                "answer": _offline_chat_answer(grounded),
                "grounded": grounded,
                "model": "offline-symbolic",
                "offline": True,
                "key_hint": KEY_HINT,
                "mode": STATE_GATE.mode,
                "insecure": not (STATE_GATE.mode == gate.CAMPUS and STATE_GATE.verified),
            })
            return
        ssl_ctx = _ssl_ctx_for_mode()
        messages = [
            {"role": "system", "content": CHAT_SYSTEM_PROMPT},
            {"role": "user", "content": f"{message}\n\n{_grounding_facts_block(grounding)}"},
        ]
        try:
            answer = llm.call_api_messages(
                messages, api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx, fail_on_error=False,
            )
        except Exception as exc:  # network / API failure -> clean 502, not 500
            self._send_json({"error": str(exc), "error_type": "reallms", "grounded": grounded}, status=502)
            return
        self._send_json({"answer": answer, "grounded": grounded, "model": llm.resolve_model(),
                         "mode": STATE_GATE.mode, "insecure": not (STATE_GATE.mode == gate.CAMPUS and STATE_GATE.verified)})

    def _handle_transcript_report(self, payload: dict) -> None:
        """Discussion transcript -> teacher-legible two-pass report.

        Pipeline (scripts/talkmoves_two_pass.py, all logic tested there):
        blind speakers locally -> pass 1 math extraction (Gemma) -> Prolog
        adjudication of every typed claim -> deterministic mask -> pass 2
        posture read over the residue (Gemma) -> teacher_report. Two model
        calls total; the verdicts are computed, never generated.

        Offline path, symmetric with pml_score's `clauses` shortcut: a request
        that already carries `claims` (pass-1 claim objects) skips both model
        calls. The deterministic chain (blind -> adjudicate -> mask ->
        teacher_report) runs unchanged on the supplied claims; the posture
        section stays empty because pass 2 is a model read."""
        text = str(payload.get("text") or "").strip()
        if not text:
            self._send_json({"error": "text is required"}, status=400)
            return
        # Symmetric with pml_score's `clauses` shortcut: a non-empty `claims`
        # list selects the offline path; an absent or empty one falls through
        # to the two-pass model pipeline.
        claims_payload = payload.get("claims")
        offline_claims: list[dict] | None = None
        if claims_payload:
            if not (isinstance(claims_payload, list)
                    and all(isinstance(c, dict) for c in claims_payload)):
                self._send_json(
                    {"error": "claims must be a list of pass-1 claim objects"},
                    status=400,
                )
                return
            offline_claims = claims_payload
        key = llm.load_key(RUNTIME)
        if key is None and offline_claims is None:
            self._send_json(
                {"error": ("The report's extraction and posture passes need "
                           "the model, and no REALLMS API key is set. A "
                           "request that supplies pre-extracted `claims` "
                           "runs the deterministic adjudication without a "
                           "key. " + KEY_HINT),
                 "error_type": "no_key"},
                status=503)
            return
        tp = _two_pass_module()
        blinded, _aliases = tp.blind_transcript(text)
        if not blinded.strip():
            self._send_json({"error": ("No speaker lines found. Paste "
                                       "'Speaker: utterance' lines, or a "
                                       "CSV/TSV where one column names the "
                                       "speaker and one holds what they "
                                       "said (most header names are "
                                       "recognized; a headerless "
                                       "speaker,text table works too).")},
                            status=400)
            return
        scorer = tp._load_scorer()
        numbered, _ = scorer.number_transcript(blinded)
        transcript_id = str(payload.get("transcript_id") or "pasted")
        if offline_claims is not None:
            # Symbolic-only report: Prolog adjudicates the supplied claims and
            # the deterministic mask and report run as usual. No model call.
            extractions = tp.adjudicate_claims(offline_claims)
            mask_result = tp.mask_transcript(numbered, extractions)
            report = tp.teacher_report(transcript_id, extractions, [],
                                       numbered, mask_result=mask_result)
            self._send_json({"ok": True, "report": report,
                             "offline": True, "model": "offline-symbolic"})
            return
        ssl_ctx = _ssl_ctx_for_mode()

        def call(system: str, user: str) -> str:
            return llm.call_api_messages(
                [{"role": "system", "content": system},
                 {"role": "user", "content": user}],
                api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx,
                fail_on_error=False,
            )

        def json_after(reply: str, heading: str) -> dict:
            start = reply.find("{", max(reply.find(heading), 0))
            if start < 0:
                raise ValueError(f"the model reply contained no {heading} block")
            try:
                return json.loads(reply[start:reply.rfind("}") + 1])
            except json.JSONDecodeError as exc:
                raise ValueError(
                    f"the model's {heading} block was not valid JSON ({exc})"
                ) from exc

        try:
            reply1 = call(tp.PASS1_PROMPT_PATH.read_text(encoding="utf-8"),
                          tp.build_pass1_user_content(transcript_id, numbered))
            math_json = json_after(reply1, "## MATH_JSON")
            extractions = tp.adjudicate_claims(math_json.get("claims", []))
            mask_result = tp.mask_transcript(numbered, extractions)
            reply2 = call(tp.PASS2_PROMPT_PATH.read_text(encoding="utf-8"),
                          tp.build_pass2_user_content(
                              transcript_id, mask_result,
                              variant="hard_mask"))
            pml_json = json_after(reply2, "## PML_JSON")
            readings = pml_json.get("readings", [])
        except Exception as exc:  # noqa: BLE001 — surface, don't crash
            self._send_json({"error": f"report failed: {exc}",
                             "error_type": "transcript_report_failed"},
                            status=502)
            return
        report = tp.teacher_report(transcript_id, extractions, readings,
                                   numbered, mask_result=mask_result)
        self._send_json({"ok": True, "report": report})

    def _handle_media_transcribe(self, payload: dict) -> None:
        """One uploaded artifact -> a proposed transcript and optional timing.

        Gemma proposes the transcript. For audio, Prolog validates the timed
        segment structure without interpreting the discussion. The teacher
        reviews (and can edit) the proposal in the composer, and the
        report pipeline then blinds and adjudicates it exactly as pasted
        text. Pasted text never reaches the model unblinded; an image or a
        recording necessarily does, because transcription is the first read.
        Audio segment bounds pass through Prolog shape validation and remain an
        unreviewed model proposal; the response names that boundary."""
        from hermes.app.analysis import media

        name = str(payload.get("name") or "upload")
        raw_b64 = str(payload.get("data_b64") or "")
        if "," in raw_b64 and raw_b64.lstrip().startswith("data:"):
            raw_b64 = raw_b64.split(",", 1)[1]
        if not raw_b64.strip():
            self._send_json({"error": "data_b64 is required (base64 file content)"},
                            status=400)
            return
        try:
            data = base64.b64decode(raw_b64, validate=True)
        except (ValueError, binascii.Error):
            self._send_json({"error": "data_b64 is not valid base64"}, status=400)
            return
        key = llm.load_key(RUNTIME)
        if key is None:
            # Honest 503: reading an image or a recording is the model's first
            # pass, and there is no symbolic substitute for it. Name what
            # still works without a key alongside the remedy.
            self._send_json(
                {"error": ("Transcribing an upload needs the model, and no "
                           "REALLMS API key is set. Pasted-text analysis and "
                           "reports still work without one. " + KEY_HINT),
                 "error_type": "no_key"},
                status=503)
            return
        notes: list[str] = []
        parts, render = media.parts_for_upload(
            name, str(payload.get("mime") or ""), data, notes)
        if not parts:
            self._send_json({"error": f"could not read {name} ({render})",
                             "error_type": "unreadable_upload",
                             "notes": notes}, status=422)
            return
        timed_audio = media.has_audio(parts)
        prompt_name = "transcribe_timed.md" if timed_audio else "transcribe.md"
        system = (APP_DIR / "system_prompts" / prompt_name).read_text(encoding="utf-8")
        content = [{"type": "text", "text": f"FILE: {name}"}] + parts
        ssl_ctx = _ssl_ctx_for_mode()

        def call(user_content: list) -> str:
            return llm.call_api_messages(
                [{"role": "system", "content": system},
                 {"role": "user", "content": user_content}],
                api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx, fail_on_error=False,
            )

        try:
            reply = call(content)
        except Exception as exc:  # noqa: BLE001 — surface, don't crash
            # Some OpenAI-compatible servers take audio only in the
            # audio_url data-URI shape; retry once in that form before
            # reporting the failure.
            if media.has_audio(parts) and "HTTP 4" in str(exc):
                try:
                    reply = call([content[0]] + media.audio_parts_as_urls(parts))
                    notes.append("audio accepted in audio_url form after input_audio was refused")
                except Exception as retry_exc:  # noqa: BLE001
                    self._send_json({"error": str(retry_exc), "error_type": "reallms",
                                     "notes": notes}, status=502)
                    return
            else:
                self._send_json({"error": str(exc), "error_type": "reallms",
                                 "notes": notes}, status=502)
                return
        alignment = None
        if timed_audio:
            try:
                segments = media.timed_segments_from_reply(reply)
                alignment = worker_request(
                    "media_alignment",
                    segments=segments,
                    source=f"reallms_audio_alignment:{llm.resolve_model()}",
                )
            except (ValueError, worker.PersistentPrologError) as exc:
                self._send_json({
                    "error": f"timed transcription failed validation: {exc}",
                    "error_type": "media_alignment_failed",
                    "notes": notes,
                }, status=502)
                return
            transcript = alignment["transcript"]
            notes.append(
                "audio timestamps are a model proposal validated for shape by Prolog; review them against the recording before discourse analysis")
        else:
            transcript = re.sub(r"^```[a-z]*\n|\n```$", "", reply.strip())
        self._send_json({
            "ok": True,
            "transcript": transcript,
            "render": render,
            "notes": notes,
            "model": llm.resolve_model(),
            "alignment": alignment,
            "privacy": ("The uploaded file itself was sent to REALLMS for "
                        "transcription; review the transcript before building "
                        "a report. Report passes blind the speakers locally."),
        })

    def _handle_pml_score(self, payload: dict) -> None:
        """Neuro-symbolic loop: Gemma encodes the text as PML reader_axiom/4 facts;
        the Prolog worker SAFELY parses, validates against the 12 operators, and
        scores them. The model emits the symbolic axioms; swipl is the judge.

        Offline path: a request that already carries `clauses` (reader_axiom/4
        or passage_mode/3 strings) skips the model entirely — the worker scores
        them whether or not a key is configured. The neural side proposes;
        here the caller has already proposed, so only the symbolic judge runs."""
        clauses_payload = payload.get("clauses")
        if clauses_payload:
            if not (isinstance(clauses_payload, list)
                    and all(isinstance(c, str) and c.strip() for c in clauses_payload)):
                self._send_json(
                    {"error": "clauses must be a list of non-empty Prolog clause strings"},
                    status=400,
                )
                return
            clauses = [c.strip().rstrip(".") for c in clauses_payload]
            result = worker_request("pml_score", clauses=clauses)
            self._send_json({"ok": True, "clauses": clauses, "result": result,
                             "offline": True, "model": "offline-symbolic"})
            return
        text = str(payload.get("text") or "").strip()
        if not text:
            self._send_json({"error": "text is required"}, status=400)
            return
        key = llm.load_key(RUNTIME)
        if key is None:
            self._send_json({"error": KEY_HINT, "error_type": "no_key"}, status=503)
            return
        ssl_ctx = _ssl_ctx_for_mode()
        messages = [
            {"role": "system", "content": PML_SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ]
        try:
            raw = llm.call_api_messages(
                messages, api_key=key, api_url=llm.resolve_api_url(),
                model=llm.resolve_model(), ssl_ctx=ssl_ctx, fail_on_error=False,
            )
        except Exception as exc:
            self._send_json({"error": str(exc), "error_type": "reallms"}, status=502)
            return
        clauses = _extract_pml_clauses(raw)
        if not clauses:
            self._send_json(
                {
                    "error": "model output did not contain reader_axiom/4 or passage_mode/3 clauses",
                    "error_type": "no_pml_clauses",
                    "raw": raw,
                },
                status=422,
            )
            return
        result = worker_request("pml_score", clauses=clauses)
        self._send_json({"ok": True, "text": text, "result": result, "raw": raw,
                         "model": llm.resolve_model()})

    def _handle_expressive_power(self, payload: dict) -> None:
        lesson = payload.get("lesson")
        if not lesson:
            self._send_json({"error": "lesson is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("expressive_power", lesson=lesson)})

    def _handle_field_context(self, payload: dict) -> None:
        lesson_code = str(payload.get("lesson_code") or payload.get("lesson") or "").strip()
        if not lesson_code:
            self._send_json({"error": "lesson_code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("field_context", lesson_code=lesson_code)})

    def _handle_field_connectivity_audit(self, payload: dict) -> None:
        # Compute once on the first (cold) call, then serve the cached result.
        # The audit is deterministic over a given build, so repeat hits are
        # instant and a fresh deployment does not appear broken.
        global _FIELD_AUDIT_CACHE
        if _FIELD_AUDIT_CACHE is None:
            _FIELD_AUDIT_CACHE = worker_request("field_connectivity_audit")
        self._send_json({"ok": True, "result": _FIELD_AUDIT_CACHE})

    def _handle_render_coverage(self, payload: dict) -> None:
        # The four-lane misconception render-coverage report: which registry
        # ops draw live, which carry a parametric deformation clause, which
        # point at corpus figures, and which are not covered. Public knowledge
        # base, no student data; counts are computed live by the worker.
        self._send_json({"ok": True, "result": worker_request("render_coverage")})

    def _handle_monitoring_chart_export(self, payload: dict) -> None:
        lesson_code = str(payload.get("lesson_code") or payload.get("lesson") or "").strip()
        if not lesson_code:
            self._send_json({"error": "lesson_code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("monitoring_chart_export", lesson_code=lesson_code)})

    def _handle_ranked_figures(self, payload: dict) -> None:
        lesson_code = str(payload.get("lesson_code") or payload.get("lesson") or "").strip()
        if not lesson_code:
            self._send_json({"error": "lesson_code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("ranked_figures", lesson_code=lesson_code)})

    def _handle_deontic_scorecard(self, payload: dict) -> None:
        # The deontic board for one ephemeral agent: seed `commitments` and
        # `entitlements` (lists of Prolog term strings), read back commitments,
        # entitlements, and incoherences. The signature incoherence is
        # commitment_without_entitlement — a move that is procedurally correct but
        # inferentially hollow; depositing the missing vocabulary clears it.
        commitments = payload.get("commitments") or []
        entitlements = payload.get("entitlements") or []
        if not isinstance(commitments, list) or not isinstance(entitlements, list):
            self._send_json({"error": "commitments and entitlements must be lists of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "deontic_scorecard",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
            entitlements=entitlements,
        )})

    def _handle_crisis(self, payload: dict) -> None:
        commitments = payload.get("commitments") or []
        entitlements = payload.get("entitlements") or []
        if not isinstance(commitments, list) or not isinstance(entitlements, list):
            self._send_json({"error": "commitments and entitlements must be lists of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "deontic_crisis",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
            entitlements=entitlements,
        )})

    def _handle_deontic_consequences(self, payload: dict) -> None:
        # What a set of `commitments` (a list of Prolog term strings) materially
        # commits the agent to: the one-step consequence of every commitment in
        # the closure, each carrying the witness that records which rule or MUA
        # mechanism licensed it. An agent committed to the area-model practice is
        # thereby committed to the cross-multiplication result — entitlement
        # carried, not procedural recall.
        commitments = payload.get("commitments") or []
        if not isinstance(commitments, list):
            self._send_json({"error": "commitments must be a list of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "deontic_consequences",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
        )})

    def _handle_deontic_up_level(self, payload: dict) -> None:
        # The objectivation move. For each commitment_without_entitlement that
        # survives the within-level closure, the witness lifts the gap into a new
        # object of discourse one level up ("talking about talking"). The
        # witness's `erasure` field marks what the formalism does not supply; a
        # coherent or within-level-dischargeable board returns an empty list. The
        # board names the break and the move past it; it does not close it.
        commitments = payload.get("commitments") or []
        if not isinstance(commitments, list):
            self._send_json({"error": "commitments must be a list of term strings"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "deontic_up_level",
            agent=str(payload.get("agent") or "scoreboard"),
            commitments=commitments,
        )})

    def _handle_deontic_requires_entitlement(self, payload: dict) -> None:
        # Single-proposition lookup: does this proposition require an entitlement
        # the agent has to earn (an LX-elaboration in the MUA graph), and what
        # source licenses that requirement? Distinct from the full board above.
        proposition = payload.get("proposition")
        if not proposition:
            self._send_json({"error": "proposition is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "deontic_requires_entitlement", proposition=proposition,
        )})

    def _handle_sequent_proof(self, payload: dict) -> None:
        # A sequent witness from the embodied prover. Where the proof goes
        # through, the witness records it; where the source is trace-tainted the
        # engine returns erasure(...) — the boundary, made operable, where formal
        # proof goes hollow and human judgment has to take over.
        sequent = payload.get("sequent")
        source = payload.get("source")
        if not sequent or not source:
            self._send_json({"error": "sequent and source are required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "sequent_proof_witness", sequent=sequent, source=source,
        )})

    def _handle_monitoring_visuals(self, payload: dict) -> None:
        lesson_code = str(payload.get("lesson_code") or payload.get("lesson") or "").strip()
        if not lesson_code:
            self._send_json({"error": "lesson_code is required"}, status=400)
            return
        chart = worker_request("monitoring_chart_export", lesson_code=lesson_code)
        if not isinstance(chart, dict):
            self._send_json({"error": "monitoring_chart_export returned a non-object payload"}, status=500)
            return
        result = _monitoring_visuals_for_chart(lesson_code, chart)
        issues = verify_monitoring_visuals.verify_docs({lesson_code: result})
        if issues:
            self._send_json({
                "ok": False,
                "error": "monitoring visual proof contract failed",
                "issues": issues,
            }, status=500)
            return
        self._send_json({"ok": True, "result": result})

    def _handle_pair_graph(self, payload: dict) -> None:
        from hermes.app.analysis import event_importer

        events = payload.get("events")
        if not isinstance(events, list):
            self._send_json({"error": "events list is required"}, status=400)
            return
        try:
            event_importer.assert_pair_graph_safe(events)
        except ValueError as exc:
            self._send_json(
                {"error": str(exc), "error_type": "unsafe_event_payload"},
                status=400,
            )
            return
        self._send_json({
            "pairs": worker_request("pair_score", events=events),
            "graph": worker_request("pair_graph", events=events),
        })

    # ---- encyclopedia surfaces (no student data; the public knowledge base) --
    def _handle_strategies(self, _payload: dict) -> None:
        self._send_json({"ok": True, "result": worker_request("list_strategies")})

    def _handle_fraction_frames(self, raw_path: str) -> None:
        """Lay out a fraction automaton as bars (v2 frames). Returns the frame
        document at the top level so the viewer's live mode can fetch it directly
        (it reads doc.frames / doc.productive.frames). Public KB; no student data."""
        url = urllib.parse.urlparse(raw_path)
        q = urllib.parse.parse_qs(url.query)
        kind = (q.get("kind") or [""])[0].strip()
        if not kind:
            self._send_json({"error": "kind is required"}, status=400)
            return

        def _int(name: str, default: int) -> int:
            try:
                return int((q.get(name) or [str(default)])[0])
            except (TypeError, ValueError):
                return default

        if url.path.endswith("/compare"):
            result = worker_request("fraction_compare", kind=kind,
                                    a=_int("a", _int("n", 5)), b=_int("b", _int("d", 3)))
        else:
            result = worker_request("fraction_render", kind=kind,
                                    n=_int("n", 5), d=_int("d", 3))
        self._send_json(result)

    def _handle_render(self, payload: dict) -> None:
        """Generic render bridge. The unified drawer (more-zeeman/render/drawer.js)
        POSTs {op, ...inputs} here; forward to the worker op and return its render
        document. Whitelisted ops only — this is a public KB surface, no student
        data. Lets every visualizer page draw against this same origin."""
        allowed = {
            "fraction_render", "fraction_compare", "area_render", "area_compare",
            "base_ten_render", "ace_of_bases_render", "base_ten_compare", "set_grouping_render",
            "unit_echo_render",
            "set_grouping_compare", "number_line_render", "number_line_compare",
            "place_value_chart_render", "hybridization_render",
            "balance_render", "balance_compare", "teacher_layer",
            "primitive_for_practice", "image_schema", "set_base", "get_base",
            "strategy_trace",
        }
        op = str(payload.get("op") or "").strip()
        if op not in allowed:
            self._send_json(
                {"ok": False, "error": f"unknown render op: {op or '(none)'}"},
                status=400,
            )
            return
        kwargs = {k: v for k, v in payload.items() if k != "op"}
        try:
            result = worker_request(op, **kwargs)
        except Exception as exc:  # noqa: BLE001
            # A worker-side op error (ok:false) or a transport failure. Return a
            # shape the drawer can reason about rather than a bare 500 body.
            self._send_json({"ok": False, "error": str(exc)}, status=400)
            return
        # The drawer expects a render document (an object with frames). Some
        # whitelisted ops (set_base/get_base/image_schema/primitive_for_practice)
        # return a scalar; wrap those so the drawer never receives a bare value
        # it would crash on. A render document (a dict) passes through unchanged.
        if not isinstance(result, dict):
            self._send_json(
                {
                    "ok": False,
                    "error": f"the {op} op returned a value, not a drawable scene",
                    "value": result,
                },
                status=200,
            )
            return
        self._send_json(result)

    def _handle_strategy_trace(self, payload: dict) -> None:
        strategy = str(payload.get("strategy") or "").strip()
        if not strategy:
            self._send_json({"error": "strategy is required"}, status=400)
            return
        inp = payload.get("input")
        kwargs = {"strategy": strategy}
        if isinstance(inp, dict):
            kwargs["input"] = inp
        self._send_json({"ok": True, "result": worker_request("strategy_trace", **kwargs)})

    def _handle_literature(self, payload: dict) -> None:
        # Public: literature-derived incompatibility analyses (student_rule /
        # valid_domain / incompatible_with triples with citations). No student data.
        query = str(payload.get("query") or "").strip()
        if not query:
            self._send_json({"ok": False, "error": "literature requires query"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("lit_search", query=query)})

    def _handle_misconceptions(self, payload: dict) -> None:
        kwargs = {}
        domain = str(payload.get("domain") or "").strip()
        if domain:
            kwargs["domain"] = domain
        self._send_json({"ok": True, "result": worker_request("list_misconceptions", **kwargs)})

    def _handle_standards(self, payload: dict) -> None:
        kwargs = {}
        framework = str(payload.get("framework") or "").strip()
        if framework:
            kwargs["framework"] = framework
        self._send_json({"ok": True, "result": worker_request("list_standards", **kwargs)})

    def _handle_grounding(self, payload: dict) -> None:
        operation = str(payload.get("operation") or "").strip()
        if operation:
            result = worker_request("grounding_for", operation=operation)
        else:
            result = worker_request("grounding_metaphors")
        self._send_json({"ok": True, "result": result})

    def _handle_geometry(self, payload: dict) -> None:
        predicate = str(payload.get("predicate") or "").strip()
        args = payload.get("args")
        if not predicate or not isinstance(args, list):
            self._send_json(
                {"error": "geometry requires predicate and args list"},
                status=400,
            )
            return
        self._send_json({
            "ok": True,
            "result": worker_request("geometry", predicate=predicate, args=args),
        })

    def _handle_canonical_contract(self, _payload: dict) -> None:
        # Public: the legal-vocabulary contract (canonical query predicates and
        # the scattered legacy functors each subsumes). No student data.
        self._send_json({"ok": True, "result": worker_request("canonical_contract")})

    def _handle_canonical_check(self, payload: dict) -> None:
        # Judge a list of functor-name strings against the legal vocabulary:
        # each is classified canonical | legacy | unknown.
        terms = payload.get("terms") or []
        self._send_json({"ok": True, "result": worker_request("canonical_check", terms=terms)})

    def _handle_diagnose_error(self, payload: dict) -> None:
        domain = str(payload.get("domain") or "").strip()
        if not domain:
            self._send_json({"error": "domain is required"}, status=400)
            return
        # input/got pass through json_to_term in the worker, so the UI may send
        # plain values (e.g. "1/2 + 1/3", "2/5") and the worker term-parses them.
        self._send_json({"ok": True, "result": worker_request(
            "diagnose_error", domain=domain,
            input=str(payload.get("input") or ""),
            got=str(payload.get("got") or ""))})

    def _handle_query_misconception(self, payload: dict) -> None:
        kwargs = {}
        for key in ("domain", "description", "source"):
            val = str(payload.get(key) or "").strip()
            if val:
                kwargs[key] = val
        self._send_json({"ok": True, "result": worker_request("query_misconception", **kwargs)})

    def _handle_event_score(self, payload: dict) -> None:
        from hermes.app.analysis import event_importer

        raw = (
            payload.get("events")
            if "events" in payload
            else payload.get("event", payload.get("transcript", payload))
        )
        try:
            events = event_importer.worker_events_from_payload(raw)
        except ValueError as exc:
            self._send_json(
                {"error": str(exc), "error_type": "unsafe_event_payload"},
                status=400,
            )
            return
        if not events:
            self._send_json(
                {
                    "ok": False,
                    "error": "no scoreable events after pseudonymization",
                    "error_type": "quarantined_no_scoreable_events",
                },
                status=422,
            )
            return
        if len(events) == 1 and "event" in payload and "events" not in payload:
            self._send_json({"ok": True, "result": worker_request("event_score", event=events[0])})
            return
        self._send_json({"ok": True, "result": worker_request("batch_event_score", events=events)})

    def _handle_notation_render(self, payload: dict) -> None:
        # Symbol-level representation language: `kind` selects the lane
        # (write_equation productive, mirror_written deformation); a/b/r are the
        # operands and result, `operator` the symbol (+, -, =). The worker
        # supplies defaults, so only kind is required here.
        kind = str(payload.get("kind") or "").strip()
        if not kind:
            self._send_json({"error": "kind is required"}, status=400)
            return
        kwargs: dict[str, Any] = {"kind": kind}
        for key in ("a", "b", "r", "operator"):
            if payload.get(key) is not None:
                kwargs[key] = payload[key]
        self._send_json({"ok": True, "result": worker_request("notation_render", **kwargs)})

    def _handle_fraction_cgi_addition(self, payload: dict) -> None:
        # A CGI addition automaton over a shared denominator: `kind` names the
        # automaton, na/nb are the numerators, d the common denominator. The
        # worker carries defaults, so only kind is required.
        kind = str(payload.get("kind") or "").strip()
        if not kind:
            self._send_json({"error": "kind is required"}, status=400)
            return
        kwargs: dict[str, Any] = {"kind": kind}
        for key in ("na", "nb", "d"):
            if payload.get(key) is not None:
                kwargs[key] = payload[key]
        self._send_json({"ok": True, "result": worker_request("fraction_cgi_addition", **kwargs)})

    def _handle_lesson_deformation_chart(self, payload: dict) -> None:
        # The deformation monitoring chart for one lesson code. Covers the three
        # grade-3 IM fraction lessons; out-of-coverage codes return a clear
        # coverage error from the worker.
        code = str(payload.get("code") or payload.get("lesson_code") or "").strip()
        if not code:
            self._send_json({"error": "code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("lesson_deformation_chart", code=code)})

    def _handle_notation_monitoring_chart(self, payload: dict) -> None:
        # The notation monitoring chart for one lesson code (183 K/G1 lessons).
        # Out-of-coverage codes return a clear coverage error from the worker.
        code = str(payload.get("code") or payload.get("lesson_code") or "").strip()
        if not code:
            self._send_json({"error": "code is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request("notation_monitoring_chart", code=code)})

    def _handle_brandom_backstop(self, _payload: dict) -> None:
        # The Brandomian backstop audit: the per-check report and the all-pass
        # flag for the data-driven incompatibility relation. Public KB surface;
        # no student data.
        self._send_json({"ok": True, "result": worker_request("brandom_backstop")})

    def _handle_brandomian_check(self, payload: dict) -> None:
        # One commitment set (a list of Prolog term strings) checked against the
        # declared incompatibility hyperedges: the union incoherence verdict
        # (hyperedge first, classical neg-pair floor second, with the firing
        # witness), the incompatibility-entailment pairs that hold inside the
        # set, an optional single `entails: {from, to}` query, and the classical
        # backstop verdict alongside.
        commitments = payload.get("commitments")
        if not isinstance(commitments, list) or not commitments:
            self._send_json(
                {"error": "commitments must be a non-empty list of term strings"},
                status=400,
            )
            return
        request: dict[str, Any] = {"commitments": commitments}
        entails = payload.get("entails")
        if isinstance(entails, dict) and entails.get("from") and entails.get("to"):
            request["entails"] = {"from": str(entails["from"]), "to": str(entails["to"])}
        self._send_json({"ok": True, "result": worker_request("brandomian_check", **request)})

    def _handle_hyperedges(self, payload: dict) -> None:
        # The discovered incompatibility hyperedges (Big Red discovery cache +
        # the canonical relation's declared size>=3 sets), each with its
        # computed emergence verdict. Optional `kind` filter (emergent /
        # defeated / incoherent / nonterminating / declared).
        request: dict[str, Any] = {}
        kind = str(payload.get("kind") or "").strip()
        if kind:
            request["kind"] = kind
        self._send_json({"ok": True, "result": worker_request("hyperedges", **request)})

    def _handle_axiom_toggle(self, payload: dict) -> None:
        # Runtime axiom toggling: action=list enumerates every toggle with its
        # state; enable/disable require `axiom` (a toggle term string such as
        # "pack(eml)"). Only these three actions exist on this surface, so any
        # disable stays inspectable and reversible from the same console.
        action = str(payload.get("action") or "list").strip()
        request: dict[str, Any] = {"action": action}
        axiom = str(payload.get("axiom") or "").strip()
        if axiom:
            request["axiom"] = axiom
        self._send_json({"ok": True, "result": worker_request("axiom_toggle", **request)})

    def _handle_carving_strategy_proof(self, payload: dict) -> None:
        # An on-demand proof entitlement for one arithmetic fact: `operation`
        # plus operands x, y and result z. Facts without a carving proof return a
        # no_carving_proof error from the worker.
        operation = str(payload.get("operation") or "").strip()
        if not operation:
            self._send_json({"error": "operation is required"}, status=400)
            return
        if any(payload.get(k) is None for k in ("x", "y", "z")):
            self._send_json({"error": "x, y, and z are required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "carving_strategy_proof",
            operation=operation,
            x=payload["x"], y=payload["y"], z=payload["z"],
        )})

    def _handle_carving_operation_summary(self, payload: dict) -> None:
        # Carved-fact count and residue for one `operation` — how much of the
        # table the carving covers and what it leaves uncarved.
        operation = str(payload.get("operation") or "").strip()
        if not operation:
            self._send_json({"error": "operation is required"}, status=400)
            return
        self._send_json({"ok": True, "result": worker_request(
            "carving_operation_summary", operation=operation,
        )})

    def _handle_benny_demo(self, _payload: dict) -> None:
        # Public: Benny's rule deformations run side by side with their correct
        # coordinated counterparts on the same inputs. No student data, no FERPA
        # gate (like the rest of the encyclopedia surfaces).
        self._send_json({"ok": True, "result": worker_request("benny_demo")})

    # ---- gate guard --------------------------------------------------------
    def _gate_or_423(self, op_name: str) -> bool:
        if not GATE_ENABLED:
            return True
        allowed, reason = gate.check_op_allowed(op_name, STATE_GATE)
        if not allowed:
            self._send_json({"error": reason, "error_type": "locked"}, status=423)
            return False
        return True

    def _require_unlocked(self) -> bool:
        """Results are student data — require the gate open unless the gate is disabled."""
        if not GATE_ENABLED:
            return True
        if gate.student_data_unlocked(STATE_GATE):
            return True
        self._send_json(
            {"error": "results are student data — unlock the gate (campus + verified, or testing override)",
             "error_type": "locked"},
            status=423,
        )
        return False

    # ---- io helpers (from the original console) ----------------------------
    # Base64 media uploads are the largest legitimate request; a class-period
    # recording fits well under this, a runaway request does not.
    MAX_BODY_BYTES = 64 * 1024 * 1024

    def _read_json(self) -> dict:
        length = int(self.headers.get("Content-Length", "0"))
        if length > self.MAX_BODY_BYTES:
            raise ValueError(
                f"request body is {length} bytes; this server accepts up to "
                f"{self.MAX_BODY_BYTES // (1024 * 1024)} MB")
        raw = self.rfile.read(length).decode("utf-8")
        return json.loads(raw or "{}")

    def _send_file(self, path: Path) -> None:
        data = path.read_bytes()
        ctype = mimetypes.guess_type(str(path))[0] or "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_utf8(self, payload: str, content_type: str, *, status: int = 200) -> None:
        data = payload.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self._send_cors_headers()
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _send_cors_headers(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")

    def _send_json(self, payload: Any, *, status: int = 200) -> None:
        data = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self._send_cors_headers()
        self.send_header("Cache-Control", "no-store, max-age=0")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main(argv: list[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Run the local Hermes console.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args(argv)

    global GATE_ENABLED
    GATE_ENABLED = gate.gate_enabled_for_launch(args.host, os.environ.get("HERMES_GATE"))

    server = ThreadingHTTPServer((args.host, args.port), HermesHandler)

    # Warm the lesson-catalog audit at startup so the console's Explore tab
    # answers from cache instead of making the first visitor sit through the
    # connectivity sweep. Failures stay silent: the handler recomputes lazily.
    def _warm_field_audit_cache() -> None:
        global _FIELD_AUDIT_CACHE
        try:
            result = worker_request("field_connectivity_audit")
            if _FIELD_AUDIT_CACHE is None:
                _FIELD_AUDIT_CACHE = result
        except Exception:
            pass

    threading.Thread(target=_warm_field_audit_cache, daemon=True).start()
    print(f"Hermes console: http://{args.host}:{args.port}")
    print(f"Mode: {STATE_GATE.mode}  (student data {'unlocked' if gate.student_data_unlocked(STATE_GATE) else 'locked'})")
    if OVERRIDE_ALLOWED:
        print("*** TESTING OVERRIDE ON (HERMES_GATE_OVERRIDE) — gate open; use synthetic/public data only ***")
    print(f"Default model: {llm.DEFAULT_MODEL}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
        if _WORKER is not None:
            _WORKER.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
