#!/usr/bin/env python3
"""SANDBOX-SAFE: verify the in-process workflow service without sockets.

The live-server smoke is CONTROLLER-RUN because it binds a loopback socket;
this check covers the socket-free parity, shared-worker, isolation, response
schema, truncation, and timing requirements.
"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from types import SimpleNamespace
from typing import Any
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app import llm  # noqa: E402
from hermes.app.workflow import service  # noqa: E402
from hermes.app.workflow.lib import monitoring  # noqa: E402
from hermes.app.routes import workflow as workflow_routes  # noqa: E402

COMMANDS = service.COMMANDS
PAYLOADS: dict[str, dict[str, Any]] = {
    "parse": {"input": "missing.txt"},
    "content": {"activity": "missing"},
    "profile": {},
    "draft": {"list": True},
    "grade": {"offline": True},
    "score": {},
    "metrics": {},
}


class CheckLLM:
    def __getattr__(self, name: str) -> Any:
        return getattr(llm, name)

    def make_client(self, _pack_root: Path) -> dict[str, Any]:
        return {
            "api_key": "workflow-check-placeholder",
            "api_url": llm.DEFAULT_API_URL,
            "model": llm.DEFAULT_MODEL,
            "ssl_ctx": None,
        }


CHECK_LLM = CheckLLM()


def prepare_pack(root: Path, prompt_id: str = "fixture") -> None:
    parsed = root / "runtime" / "output" / "parsed"
    parsed.mkdir(parents=True)
    (parsed / f"{prompt_id}.json").write_text(
        json.dumps({
            "prompt_id": prompt_id,
            "raw_header": "Fixture prompt",
            "instructor_prompt_text": "",
            "threads": [],
        }),
        encoding="utf-8",
    )
    (root / "runtime" / "roster.csv").write_text(
        "first_name,last_name,student_id,User Login\nAda,Lovelace,ada,ada\n",
        encoding="utf-8",
    )
    prompts = root / "system_prompts"
    prompts.mkdir()
    for name in ("profile.md", "score.md"):
        source = ROOT / "hermes" / "app" / "system_prompts" / name
        (prompts / name).write_text(source.read_text(encoding="utf-8"), encoding="utf-8")


def output_snapshot(root: Path) -> dict[str, bytes]:
    output = root / "runtime" / "output"
    if not output.exists():
        return {}
    return {
        str(path.relative_to(output)): path.read_bytes()
        for path in sorted(output.rglob("*"))
        if path.is_file() and "parsed" not in path.relative_to(output).parts
    }


def cli_result(command: str, payload: dict[str, Any], pack_root: Path) -> int:
    env = os.environ.copy()
    env.update({
        "HERMES_PACK_ROOT": str(pack_root),
        "PYTHONPATH": str(ROOT),
        "REALLMS_API_KEY": "workflow-check-placeholder",
        "REALLMS_INSECURE": "0",
    })
    proc = subprocess.run(
        [sys.executable, str(ROOT / "hermes" / "app" / "workflow" / f"{command}.py"),
         *service.build_argv(command, payload)],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
        timeout=60,
    )
    return proc.returncode


def test_workflow_cli_service_parity() -> None:
    for command in COMMANDS:
        with tempfile.TemporaryDirectory(prefix=f"workflow_cli_{command}_") as cli_tmp, \
             tempfile.TemporaryDirectory(prefix=f"workflow_svc_{command}_") as svc_tmp:
            cli_root, svc_root = Path(cli_tmp), Path(svc_tmp)
            prepare_pack(cli_root)
            prepare_pack(svc_root)
            cli_code = cli_result(command, PAYLOADS[command], cli_root)
            context = service.WorkflowContext(
                svc_root, CHECK_LLM, lambda _op, **_payload: None, lambda _text: None
            )
            result = service.run(command, PAYLOADS[command], context)
            assert result.returncode == cli_code, (
                command, cli_code, result.returncode, result.stderr
            )
            assert output_snapshot(svc_root) == output_snapshot(cli_root), command


def test_workflow_uses_shared_worker() -> None:
    calls: list[tuple[str, dict[str, Any]]] = []

    def counting_worker(op: str, **payload: Any) -> Any:
        calls.append((op, payload))
        if op == "monitoring_chart_export":
            return {"productive_core": "fixture"}
        return []

    with tempfile.TemporaryDirectory(prefix="workflow_worker_") as tmp:
        root = Path(tmp)
        monitoring_dir = root / "monitoring"
        monitoring_dir.mkdir()
        (monitoring_dir / "im_codes.json").write_text(
            json.dumps({"fixture": "IM-G5-U1-L1"}), encoding="utf-8"
        )
        with mock.patch("subprocess.run") as run_subprocess:
            block = monitoring.prolog_pck_block(
                root, "fixture", worker_request=counting_worker
            )
        assert "fixture" in block
        assert calls == [
            ("monitoring_chart_export", {"lesson_code": "IM-G5-U1-L1"})
        ]
        run_subprocess.assert_not_called()


def test_workflow_context_isolation() -> None:
    with tempfile.TemporaryDirectory(prefix="workflow_a_") as a_tmp, \
         tempfile.TemporaryDirectory(prefix="workflow_b_") as b_tmp:
        a_root, b_root = Path(a_tmp), Path(b_tmp)
        prepare_pack(a_root, "alpha")
        prepare_pack(b_root, "beta")
        for root in (a_root, b_root):
            result = service.run(
                "metrics", {},
                service.WorkflowContext(
                    root, CHECK_LLM, lambda _op, **_payload: None, lambda _text: None
                ),
            )
            assert result.ok, result
        assert (a_root / "runtime/output/metrics/alpha.json").exists()
        assert not (a_root / "runtime/output/metrics/beta.json").exists()
        assert (b_root / "runtime/output/metrics/beta.json").exists()
        assert not (b_root / "runtime/output/metrics/alpha.json").exists()


def test_workflow_route_response_compatibility() -> None:
    result = service.WorkflowResult(
        "metrics", 7, False, "x" * 9000, "y" * 5000
    ).as_dict()
    assert tuple(result) == ("command", "returncode", "ok", "stdout", "stderr")
    assert result["command"] == "metrics"
    assert result["returncode"] == 7
    assert result["ok"] is False
    assert result["stdout"] == "x" * 8000
    assert result["stderr"] == "y" * 4000

    with tempfile.TemporaryDirectory(prefix="workflow_route_") as tmp:
        pack_root = Path(tmp)
        prepare_pack(pack_root, "route")
        sent: list[dict[str, Any]] = []
        context = SimpleNamespace(
            app_dir=pack_root,
            payload={},
            services=SimpleNamespace(
                gate=SimpleNamespace(
                    state=SimpleNamespace(mode="campus", verified=True)
                ),
                worker=SimpleNamespace(request=lambda _op, **_payload: None),
            ),
            _send_json=lambda payload: sent.append(payload),
        )
        route = next(route for route in workflow_routes.ROUTES
                     if route.path == "/api/metrics")
        route.handler(context)
        assert len(sent) == 1
        assert tuple(sent[0]) == ("command", "returncode", "ok", "stdout", "stderr")
        assert sent[0]["command"] == "metrics" and sent[0]["ok"] is True


def timing_measurement() -> tuple[float, float]:
    start = time.perf_counter()
    proc = subprocess.run(
        [sys.executable, str(ROOT / "hermes/app/workflow/metrics.py"), "--help"],
        cwd=ROOT, capture_output=True, text=True, timeout=30,
    )
    cli_ms = (time.perf_counter() - start) * 1000
    assert proc.returncode == 0

    with tempfile.TemporaryDirectory(prefix="workflow_timing_") as tmp:
        pack_root = Path(tmp)
        prepare_pack(pack_root, "timing")
        context = service.WorkflowContext(
            pack_root, CHECK_LLM, lambda _op, **_payload: None, lambda _text: None
        )
        start = time.perf_counter()
        result = service.run("metrics", {}, context)
        service_ms = (time.perf_counter() - start) * 1000
        assert result.ok, result
    return cli_ms, service_ms


def main() -> int:
    tests = (
        test_workflow_cli_service_parity,
        test_workflow_uses_shared_worker,
        test_workflow_context_isolation,
        test_workflow_route_response_compatibility,
    )
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    cli_ms, service_ms = timing_measurement()
    print(f"metrics timing: CLI --help {cli_ms:.2f} ms; in-process service {service_ms:.2f} ms")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
