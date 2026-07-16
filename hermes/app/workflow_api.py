"""Map an HTTP workflow request to a vendored CLI invocation.

The seven n103_profile_first commands keep their CLI; this wraps each as a
subprocess. By default the server runs them locally with the FERPA gate disabled;
when launched with HERMES_GATE=on, the server-side gate must unlock before these
student-data commands dispatch.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

WORKFLOW_DIR = Path(__file__).resolve().parent / "workflow"
REPO_ROOT = Path(__file__).resolve().parents[2]

COMMANDS = {"parse", "content", "profile", "draft", "grade", "score", "metrics"}
# positional argument name per command (absent = flags only)
POSITIONAL = {"parse": "input", "content": "activity", "draft": "unit"}
# payload keys treated as boolean flags (presence = on)
FLAGS = {
    "force", "list", "graph", "offline", "skip_prompts",
    "no_consolidate", "no_per_file", "include_absent",
}


def build_argv(command: str, payload: dict) -> list[str]:
    if command not in COMMANDS:
        raise ValueError(f"unknown workflow command: {command}")
    argv = [str(WORKFLOW_DIR / f"{command}.py")]
    pos = POSITIONAL.get(command)
    if pos and payload.get(pos):
        argv.append(str(payload[pos]))
    for key, val in payload.items():
        if key == pos:
            continue
        flag = "--" + key.replace("_", "-")
        if key in FLAGS:
            if val:
                argv.append(flag)
        elif val not in (None, ""):
            argv.extend([flag, str(val)])
    return argv


def run(command: str, payload: dict, pack_root: Path, timeout: int = 1800) -> dict:
    argv = [sys.executable, *build_argv(command, payload)]
    env = os.environ.copy()
    env["HERMES_PACK_ROOT"] = str(pack_root)
    # The vendored scripts import lib.api -> hermes.app.llm; the repo root must
    # be importable for that to resolve in the subprocess.
    existing = env.get("PYTHONPATH", "")
    env["PYTHONPATH"] = str(REPO_ROOT) + (os.pathsep + existing if existing else "")
    try:
        proc = subprocess.run(
            argv, cwd=str(WORKFLOW_DIR), env=env,
            capture_output=True, text=True, timeout=timeout,
        )
    except subprocess.TimeoutExpired:
        return {"command": command, "returncode": -1, "ok": False, "stdout": "",
                "stderr": f"timed out after {timeout}s"}
    return {
        "command": command,
        "returncode": proc.returncode,
        "ok": proc.returncode == 0,
        "stdout": proc.stdout[-8000:],
        "stderr": proc.stderr[-4000:],
    }
