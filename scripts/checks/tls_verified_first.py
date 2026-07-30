#!/usr/bin/env python3
"""Regression checks for verified-first REALLMS TLS resolution.

This stays socket-free: it tests the context-selection contract and preflight
invariant with stubs, leaving a live verified REALLMS request to the controller.
"""
from __future__ import annotations

import os
import shutil
import ssl
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app import gate, llm, server  # noqa: E402
from hermes.app.routes.logic import RouteLogic  # noqa: E402

# This is deliberately a grep pattern. It catches a direct assignment such as
# the former route-side write, while allowing user configuration to enter via
# the inherited environment or a user-authored .env file.
FORBIDDEN_ENV_WRITE = r"os\.environ\[(['\"])REALLMS_INSECURE\1\]\s*="


def route_logic(*, mode: str, preflight_ok: bool | None) -> RouteLogic:
    last_preflight = None
    if preflight_ok is not None:
        last_preflight = server.PreflightResult(
            ok=preflight_ok,
            reason="fixture",
            checked_at=datetime.now(timezone.utc),
        )
    gate_service = SimpleNamespace(
        state=gate.GateState(mode=mode), last_preflight=last_preflight
    )
    return RouteLogic(SimpleNamespace(services=SimpleNamespace(gate=gate_service)))


def environment_without_insecure() -> mock._patch_dict:  # type: ignore[name-defined]
    copied = os.environ.copy()
    copied.pop("REALLMS_INSECURE", None)
    return mock.patch.dict(os.environ, copied, clear=True)


def test_successful_preflight_prefers_verified_context_in_both_modes() -> None:
    with environment_without_insecure():
        for mode in (gate.HOME, gate.CAMPUS):
            ctx = route_logic(mode=mode, preflight_ok=True)._ssl_ctx_for_mode()
            assert ctx.verify_mode == ssl.CERT_REQUIRED, (mode, ctx.verify_mode)
            assert ctx.check_hostname is True, mode
    print("PASS successful preflight selects a verifying context in home and campus modes")


def test_user_insecure_request_is_the_only_fallback() -> None:
    insecure = object()
    secure = object()
    with mock.patch.dict(os.environ, {"REALLMS_INSECURE": "1"}, clear=True), \
         mock.patch.object(llm, "build_ssl_context", return_value=insecure) as build_default, \
         mock.patch.object(llm, "build_secure_ssl_context", return_value=secure) as build_secure:
        actual = route_logic(mode=gate.HOME, preflight_ok=False)._ssl_ctx_for_mode()
    assert actual is insecure
    build_default.assert_called_once_with()
    build_secure.assert_not_called()
    print("PASS explicit user REALLMS_INSECURE request remains the fallback")


def test_retained_preflight_outranks_user_insecure_request() -> None:
    insecure = object()
    secure = object()
    with mock.patch.dict(os.environ, {"REALLMS_INSECURE": "1"}, clear=True), \
         mock.patch.object(llm, "build_ssl_context", return_value=insecure) as build_default, \
         mock.patch.object(llm, "build_secure_ssl_context", return_value=secure) as build_secure:
        actual = route_logic(mode=gate.HOME, preflight_ok=True)._ssl_ctx_for_mode()
    assert actual is secure
    build_secure.assert_called_once_with()
    build_default.assert_not_called()
    print("PASS a retained verified preflight outranks the user insecure request")


def test_campus_mode_always_verifies_despite_user_insecure_request() -> None:
    insecure = object()
    secure = object()
    for preflight_ok in (None, False):
        with mock.patch.dict(os.environ, {"REALLMS_INSECURE": "1"}, clear=True), \
             mock.patch.object(llm, "build_ssl_context", return_value=insecure) as build_default, \
             mock.patch.object(llm, "build_secure_ssl_context", return_value=secure) as build_secure:
            actual = route_logic(mode=gate.CAMPUS, preflight_ok=preflight_ok)._ssl_ctx_for_mode()
        assert actual is secure, preflight_ok
        build_secure.assert_called_once_with()
        build_default.assert_not_called()
    print("PASS campus mode always verifies, whatever the environment says")


def test_workflow_client_insecurity_is_user_opt_in_only_and_never_campus() -> None:
    from hermes.app.routes import workflow

    with environment_without_insecure():
        assert workflow._tls_insecure(gate.GateState(mode=gate.HOME)) is False
        assert workflow._tls_insecure(gate.GateState(mode=gate.CAMPUS)) is False
    with mock.patch.dict(os.environ, {"REALLMS_INSECURE": "1"}, clear=True):
        assert workflow._tls_insecure(gate.GateState(mode=gate.HOME)) is True
        assert workflow._tls_insecure(gate.GateState(mode=gate.CAMPUS)) is False
    print("PASS workflow client insecurity is user opt-in only and never campus")


def test_unproven_route_still_verifies_and_names_certificate_limit() -> None:
    with environment_without_insecure():
        logic = route_logic(mode=gate.HOME, preflight_ok=False)
        ctx = logic._ssl_ctx_for_mode()
        assert ctx.verify_mode == ssl.CERT_REQUIRED
        assert ctx.check_hostname is True
        error = logic._reallms_error(
            ssl.SSLCertVerificationError(1, "CERTIFICATE_VERIFY_FAILED")
        )
    expected = (
        "Could not verify the REALLMS server's certificate. Set "
        "SSL_CERT_FILE to a trusted CA bundle such as /etc/ssl/cert.pem, "
        "install certifi, or ask campus IT for the IU/network CA bundle. "
        "REALLMS_INSECURE=1 disables server verification and should only "
        "be used for temporary debugging."
    )
    assert error == expected, error
    print("PASS unproven route still verifies; certificate failure copy is explicit")


def test_gate_service_retains_last_preflight_with_timestamp() -> None:
    with mock.patch.object(server.llm, "load_key", return_value="fixture-key"), \
         mock.patch.object(server.llm, "secure_preflight", return_value=(True, "fixture verified")):
        service = server.GateService(runtime=ROOT)
        result = service.run_preflight()
    assert result == (True, "fixture verified")
    assert service.last_preflight is not None
    assert service.last_preflight.ok is True
    assert service.last_preflight.reason == "fixture verified"
    assert service.last_preflight.checked_at.tzinfo is timezone.utc
    print("PASS GateService retains the most recent secure preflight and UTC timestamp")


def test_secure_preflight_ignores_insecure_flag() -> None:
    captured: list[ssl.SSLContext] = []

    def verified_probe(_url: str, _headers: dict, ctx: ssl.SSLContext, *, timeout: int) -> int:
        captured.append(ctx)
        assert timeout == 10
        return 401

    with mock.patch.dict(os.environ, {"REALLMS_INSECURE": "1"}, clear=True), \
         mock.patch.object(llm, "_preflight_request", side_effect=verified_probe):
        result = llm.secure_preflight(api_key="fixture-key", api_url="https://fixture.invalid/v1/chat/completions")
    assert result == (True, "verified secure connection (HTTP 401)")
    assert len(captured) == 1
    assert captured[0].verify_mode == ssl.CERT_REQUIRED
    assert captured[0].check_hostname is True
    print("PASS FERPA invariant: secure_preflight ignores REALLMS_INSECURE")


def env_writes(tree: Path) -> str:
    result = subprocess.run(
        ["rg", "--pcre2", "-n", "--glob", "*.py", FORBIDDEN_ENV_WRITE, str(tree)],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.strip() or "rg failed")
    return result.stdout


def test_no_app_side_env_write_and_synthetic_reversion_bites() -> None:
    actual = env_writes(ROOT)
    assert not actual, actual
    with tempfile.TemporaryDirectory(prefix="tls_verified_first_") as raw_tmp:
        scratch = Path(raw_tmp)
        copied = scratch / "logic.py"
        shutil.copy2(ROOT / "hermes/app/routes/logic.py", copied)
        copied.write_text(
            copied.read_text(encoding="utf-8").replace(
                "    def _ssl_ctx_for_mode(self):",
                "    def _ssl_ctx_for_mode(self):\n        os.environ[\"REALLMS_INSECURE\"] = \"1\"",
                1,
            ),
            encoding="utf-8",
        )
        synthetic = env_writes(scratch)
    assert "REALLMS_INSECURE" in synthetic, synthetic
    print("PASS grep guard rejects a synthetic route-side REALLMS_INSECURE write")


def main() -> int:
    test_successful_preflight_prefers_verified_context_in_both_modes()
    test_user_insecure_request_is_the_only_fallback()
    test_retained_preflight_outranks_user_insecure_request()
    test_campus_mode_always_verifies_despite_user_insecure_request()
    test_workflow_client_insecurity_is_user_opt_in_only_and_never_campus()
    test_unproven_route_still_verifies_and_names_certificate_limit()
    test_gate_service_retains_last_preflight_with_timestamp()
    test_secure_preflight_ignores_insecure_flag()
    test_no_app_side_env_write_and_synthetic_reversion_bites()
    print("tls verified-first checks PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
