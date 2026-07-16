"""Optional campus/home gate. Couples TLS posture to student-data access.

This module defines the gate semantics; `server.py` decides whether to enforce
them via HERMES_GATE. When enforcement is on, the toggle is a request and a
verified secure REALLMS connection is the proof. Student data unlocks only when
mode == "campus" AND a secure preflight has succeeded. Off-campus (home mode),
student-data operations are refused.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

CAMPUS = "campus"
HOME = "home"

_TRUTHY_GATE_VALUES = {"1", "on", "true", "yes"}
_FALSY_GATE_VALUES = {"0", "off", "false", "no"}
_LOCAL_BIND_HOSTS = {"", "127.0.0.1", "localhost", "::1"}

# Relative to hermes/app/runtime/, these are the student-data zones.
_STUDENT_DATA_PREFIXES = ("runtime/input", "runtime/output")
_STUDENT_DATA_FILES = ("roster.csv",)

# Server endpoints / worker ops that touch student data when the gate is on.
STUDENT_DATA_OPS = frozenset({
    "parse", "content", "profile", "draft", "grade", "score", "metrics",
    "n103_pipeline", "pair_graph", "pair_score", "event_score", "batch_event_score",
    "media_alignment", "gesture_alignment", "discourse_features", "discourse_pragmatics",
    "trace_adjudication",
})


def is_student_data_path(rel_path: str) -> bool:
    p = rel_path.lstrip("./")
    if any(p == f or p.endswith("/" + f) for f in _STUDENT_DATA_FILES):
        return True
    return any(p == pre or p.startswith(pre + "/") for pre in _STUDENT_DATA_PREFIXES)


def gate_enabled_for_launch(host: str | None, env_value: str | None) -> bool:
    """Default local loopback launches open, and non-loopback binds gated."""
    if env_value is not None and env_value.strip():
        normalized = env_value.strip().lower()
        if normalized in _TRUTHY_GATE_VALUES:
            return True
        if normalized in _FALSY_GATE_VALUES:
            return False
    normalized_host = (host or "").strip().lower()
    return normalized_host not in _LOCAL_BIND_HOSTS


@dataclass
class GateState:
    mode: str = HOME
    verified: bool = False  # True only after a successful SECURE preflight
    override: bool = False   # testing override: opens the gate regardless of verification


def student_data_unlocked(state: GateState) -> bool:
    # The testing override deliberately bypasses the campus+verified requirement.
    # It is opt-in (HERMES_GATE_OVERRIDE) and loud in the UI; not for real student data.
    return state.override or (state.mode == CAMPUS and state.verified)


def check_op_allowed(op_name: str, state: GateState) -> tuple[bool, str]:
    """Return (allowed, reason). Student-data ops require an unlocked gate."""
    if op_name not in STUDENT_DATA_OPS:
        return True, "tinker op (allowed in any mode)"
    if state.override:
        return True, "TESTING OVERRIDE — gate open; do not use real student data"
    if student_data_unlocked(state):
        return True, "student data unlocked (campus + verified)"
    if state.mode != CAMPUS:
        return False, "student data is locked in home mode; switch to campus mode on the IU network"
    return False, "campus mode selected but secure connection not verified — run preflight on the IU network"


def set_mode(state: GateState, mode: str, *, preflight: Callable[[], tuple[bool, str]]) -> GateState:
    """Transition mode. Campus mode runs the secure preflight; home clears verification.
    The testing override (if set) is preserved across mode changes."""
    if mode == CAMPUS:
        ok, _reason = preflight()
        return GateState(mode=CAMPUS, verified=bool(ok), override=state.override)
    return GateState(mode=HOME, verified=False, override=state.override)


def set_override(state: GateState, on: bool) -> GateState:
    """Toggle the testing override (only meaningful when HERMES_GATE_OVERRIDE is allowed)."""
    return GateState(mode=state.mode, verified=state.verified, override=bool(on))
