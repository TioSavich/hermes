"""Reallms API client. Pure stdlib. One call per invocation."""

from __future__ import annotations

import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any, Sequence

DEFAULT_API_URL = "https://reallms.rescloud.iu.edu/direct/v1/chat/completions"
DEFAULT_MODEL = "gemma-4-31B-it"
DEFAULT_MAX_TOKENS = 8192
OUTCOMES = {
    "ok",
    "empty_content",
    "truncated",
    "transport_error",
    "http_error",
}
RETRYABLE_HTTP_CODES = {429, 500, 502, 503, 504}


class ReallmsResult:
    """Channel-preserving result from one completed API call."""

    __slots__ = (
        "outcome",
        "content",
        "reasoning_content",
        "finish_reason",
        "usage",
        "raw_response",
        "error",
        "status_code",
        "attempts",
        "retryable",
    )

    def __init__(
        self,
        *,
        outcome: str,
        content: str = "",
        reasoning_content: str = "",
        finish_reason: str | None = None,
        usage: dict[str, Any] | None = None,
        raw_response: Any = None,
        error: str | None = None,
        status_code: int | None = None,
        attempts: int = 1,
        retryable: bool = False,
    ) -> None:
        if outcome not in OUTCOMES:
            raise ValueError(f"unknown REALLMS outcome: {outcome}")
        self.outcome = outcome
        self.content = content
        self.reasoning_content = reasoning_content
        self.finish_reason = finish_reason
        self.usage = usage or {}
        self.raw_response = raw_response
        self.error = error
        self.status_code = status_code
        self.attempts = attempts
        self.retryable = retryable

    @property
    def ok(self) -> bool:
        return self.outcome == "ok"

    def to_dict(self) -> dict[str, Any]:
        return {
            "outcome": self.outcome,
            "content": self.content,
            "reasoning_content": self.reasoning_content,
            "finish_reason": self.finish_reason,
            "usage": self.usage,
            "raw_response": self.raw_response,
            "error": self.error,
            "status_code": self.status_code,
            "attempts": self.attempts,
            "retryable": self.retryable,
        }


def load_dotenv(pack_root: Path) -> None:
    candidates = [Path.cwd() / ".env", pack_root / ".env"]
    candidates.extend(parent / ".env" for parent in pack_root.parents)
    for candidate in candidates:
        if not candidate.exists():
            continue
        for raw in candidate.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value
        break


def fail(msg: str) -> None:
    sys.stderr.write(f"error: {msg}\n")
    sys.exit(1)


def require_api_key() -> str:
    api_key = os.environ.get("REALLMS_API_KEY", "").strip()
    if not api_key or api_key.startswith("sk-PASTE") or api_key == "YOUR_KEY_HERE":
        fail("set REALLMS_API_KEY in your environment or in a .env file (see paste.txt).")
    return api_key


def load_key(pack_root: Path) -> str | None:
    """Non-exiting key lookup for the long-running server (never sys.exit)."""
    load_dotenv(pack_root)
    api_key = os.environ.get("REALLMS_API_KEY", "").strip()
    if not api_key or api_key.startswith("sk-PASTE") or api_key == "YOUR_KEY_HERE":
        return None
    return api_key


def api_key_configured(pack_root: Path) -> bool:
    return load_key(pack_root) is not None


def resolve_api_url() -> str:
    api_url = os.environ.get("REALLMS_BASE_URL", DEFAULT_API_URL).strip().rstrip("/")
    if not api_url.endswith("/chat/completions"):
        suffix = "/chat/completions" if api_url.endswith("/v1") else "/v1/chat/completions"
        api_url = api_url + suffix
    return api_url


def resolve_model() -> str:
    return os.environ.get("REALLMS_MODEL", DEFAULT_MODEL).strip()


def _candidate_ca_files() -> list[Path]:
    raw_paths: list[str] = []
    env_cafile = os.environ.get("SSL_CERT_FILE", "").strip()
    if env_cafile:
        raw_paths.append(env_cafile)
    verify_paths = ssl.get_default_verify_paths()
    for value in (verify_paths.cafile, verify_paths.openssl_cafile):
        if value:
            raw_paths.append(value)
    raw_paths.extend(
        [
            "/etc/ssl/cert.pem",
            "/opt/homebrew/etc/openssl@3/cert.pem",
            "/usr/local/etc/openssl@3/cert.pem",
        ]
    )
    try:
        import certifi  # type: ignore[import-not-found]

        raw_paths.append(certifi.where())
    except ImportError:
        pass

    seen: set[Path] = set()
    candidates: list[Path] = []
    for raw_path in raw_paths:
        path = Path(raw_path).expanduser()
        if path.exists() and path not in seen:
            candidates.append(path)
            seen.add(path)
    return candidates


def insecure_tls_requested() -> bool:
    """Whether the user opted into the temporary TLS-debugging escape hatch."""
    return os.environ.get("REALLMS_INSECURE", "").strip() in ("1", "true", "yes")


def build_ssl_context() -> ssl.SSLContext:
    if insecure_tls_requested():
        sys.stderr.write("warning: REALLMS_INSECURE is set; TLS verification disabled.\n")
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx
    ctx = ssl.create_default_context()
    for cafile in _candidate_ca_files():
        try:
            ctx.load_verify_locations(cafile=str(cafile))
        except OSError as e:
            sys.stderr.write(f"warning: could not load CA bundle {cafile}: {e}\n")
    return ctx


def _looks_like_cert_error(exc: BaseException) -> bool:
    text = repr(exc)
    return "CERTIFICATE_VERIFY_FAILED" in text or "unable to get local issuer certificate" in text


def _text(value: Any) -> str:
    return value if isinstance(value, str) else ""


def _apply_final_stops(content: str, stop_sequences: Sequence[str]) -> str:
    """Apply local stops after the final channel has been isolated."""
    positions = [content.find(stop) for stop in stop_sequences if stop and stop in content]
    return content[: min(positions)] if positions else content


def parse_chat_completion(
    raw_response: Any,
    *,
    final_stop_sequences: Sequence[str] = (),
    attempts: int = 1,
) -> ReallmsResult:
    """Classify one decoded OpenAI-compatible response without channel fallback."""
    try:
        choice = raw_response["choices"][0]
        message = choice["message"]
        if not isinstance(message, dict):
            raise TypeError("choice message is not an object")
    except (KeyError, IndexError, TypeError) as exc:
        return ReallmsResult(
            outcome="transport_error",
            raw_response=raw_response,
            error=f"malformed chat-completion response: {exc}",
            attempts=attempts,
        )

    content = _apply_final_stops(_text(message.get("content")), final_stop_sequences)
    reasoning_content = _text(message.get("reasoning_content"))
    finish_reason = _text(choice.get("finish_reason")) or None
    usage_value = raw_response.get("usage", {}) if isinstance(raw_response, dict) else {}
    usage = usage_value if isinstance(usage_value, dict) else {}

    if finish_reason == "length":
        outcome = "truncated"
    elif content.strip():
        outcome = "ok"
    else:
        outcome = "empty_content"
    return ReallmsResult(
        outcome=outcome,
        content=content,
        reasoning_content=reasoning_content,
        finish_reason=finish_reason,
        usage=usage,
        raw_response=raw_response,
        attempts=attempts,
    )


def _decoded_error_body(body: str) -> Any:
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        return body


def call_api(
    system_prompt: str,
    user_content: str,
    *,
    api_key: str,
    api_url: str,
    model: str,
    ssl_ctx: ssl.SSLContext,
    retries: int = 3,
    timeout: int = 600,
    max_tokens: int = DEFAULT_MAX_TOKENS,
    final_stop_sequences: Sequence[str] = (),
) -> str:
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_content},
    ]
    return call_api_messages(
        messages,
        api_key=api_key,
        api_url=api_url,
        model=model,
        ssl_ctx=ssl_ctx,
        retries=retries,
        timeout=timeout,
        max_tokens=max_tokens,
        final_stop_sequences=final_stop_sequences,
    )


def call_api_result(
    system_prompt: str,
    user_content: str,
    *,
    api_key: str,
    api_url: str,
    model: str,
    ssl_ctx: ssl.SSLContext,
    retries: int = 3,
    timeout: int = 600,
    max_tokens: int = DEFAULT_MAX_TOKENS,
    final_stop_sequences: Sequence[str] = (),
) -> ReallmsResult:
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_content},
    ]
    return call_api_messages_result(
        messages,
        api_key=api_key,
        api_url=api_url,
        model=model,
        ssl_ctx=ssl_ctx,
        retries=retries,
        timeout=timeout,
        max_tokens=max_tokens,
        final_stop_sequences=final_stop_sequences,
    )


def call_api_messages(
    messages: list[dict],
    *,
    api_key: str,
    api_url: str,
    model: str,
    ssl_ctx: ssl.SSLContext,
    retries: int = 3,
    timeout: int = 600,
    fail_on_error: bool = True,
    max_tokens: int = DEFAULT_MAX_TOKENS,
    final_stop_sequences: Sequence[str] = (),
) -> str:
    """Call the chat API with already-formed messages.

    This supports both plain text messages and OpenAI-compatible multimodal
    content arrays with `image_url` parts.
    """
    result = call_api_messages_result(
        messages,
        api_key=api_key,
        api_url=api_url,
        model=model,
        ssl_ctx=ssl_ctx,
        retries=retries,
        timeout=timeout,
        max_tokens=max_tokens,
        final_stop_sequences=final_stop_sequences,
    )
    if result.outcome in {"transport_error", "http_error"}:
        message = f"API call failed after {result.attempts} attempts: {result.error}"
        if fail_on_error:
            fail(message)
        raise RuntimeError(message)
    if result.outcome == "truncated":
        return ""
    return result.content


def call_api_messages_result(
    messages: list[dict],
    *,
    api_key: str,
    api_url: str,
    model: str,
    ssl_ctx: ssl.SSLContext,
    retries: int = 3,
    timeout: int = 600,
    max_tokens: int = DEFAULT_MAX_TOKENS,
    final_stop_sequences: Sequence[str] = (),
) -> ReallmsResult:
    """Call REALLMS and retain final, reasoning, status, usage, and raw data.

    The request deliberately has no stop parameter. Local stop sequences are
    applied only to message.content after the response channels are separated.
    """
    if retries < 1:
        raise ValueError("retries must be at least 1")
    if not isinstance(max_tokens, int) or isinstance(max_tokens, bool) or max_tokens < 1:
        raise ValueError("max_tokens must be a positive integer")
    payload = {
        "model": model,
        "messages": messages,
        "max_tokens": max_tokens,
    }
    body = json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    for attempt in range(1, retries + 1):
        req = urllib.request.Request(api_url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout, context=ssl_ctx) as resp:
                try:
                    response_bytes = resp.read()
                    response_text = response_bytes.decode("utf-8")
                    data = json.loads(response_text)
                except UnicodeDecodeError as exc:
                    result = ReallmsResult(
                        outcome="transport_error",
                        raw_response=response_bytes.decode("utf-8", errors="replace"),
                        error=f"malformed UTF-8 response: {exc}",
                        attempts=attempt,
                        retryable=True,
                    )
                    if attempt < retries:
                        time.sleep(5 * attempt)
                        continue
                    return result
                except json.JSONDecodeError as exc:
                    result = ReallmsResult(
                        outcome="transport_error",
                        raw_response=response_text,
                        error=f"malformed JSON response: {exc}",
                        attempts=attempt,
                        retryable=True,
                    )
                    if attempt < retries:
                        time.sleep(5 * attempt)
                        continue
                    return result
                result = parse_chat_completion(
                    data,
                    final_stop_sequences=final_stop_sequences,
                    attempts=attempt,
                )
                if result.outcome == "transport_error" and attempt < retries:
                    result.retryable = True
                    time.sleep(5 * attempt)
                    continue
                return result
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8", errors="replace")
            retryable = e.code in RETRYABLE_HTTP_CODES
            result = ReallmsResult(
                outcome="http_error",
                raw_response=_decoded_error_body(err_body),
                error=f"HTTP {e.code}: {err_body[:500]}",
                status_code=e.code,
                attempts=attempt,
                retryable=retryable,
            )
            if retryable and attempt < retries:
                wait = 5 * attempt
                sys.stderr.write(f"  retry {attempt}/{retries} after {wait}s ({result.error.splitlines()[0]})\n")
                time.sleep(wait)
                continue
            return result
        except (urllib.error.URLError, TimeoutError) as e:
            error = f"network: {e}"
            if _looks_like_cert_error(e):
                error += (
                    "\nTLS certificate verification failed before the API key could be checked. "
                    "Set SSL_CERT_FILE to a trusted CA bundle such as /etc/ssl/cert.pem, "
                    "install certifi, or ask campus IT for the IU/network CA bundle. "
                    "REALLMS_INSECURE=1 disables server verification and should only be used for temporary debugging."
                )
                return ReallmsResult(
                    outcome="transport_error",
                    error=error,
                    attempts=attempt,
                    retryable=False,
                )
            if attempt < retries:
                time.sleep(5 * attempt)
                continue
            return ReallmsResult(
                outcome="transport_error",
                error=error,
                attempts=attempt,
                retryable=True,
            )
    raise AssertionError("REALLMS retry loop ended without a result")


def make_client(pack_root: Path) -> dict:
    """Return a dict bundling the call_api kwargs for this run."""
    load_dotenv(pack_root)
    return {
        "api_key": require_api_key(),
        "api_url": resolve_api_url(),
        "model": resolve_model(),
        "ssl_ctx": build_ssl_context(),
    }


def build_secure_ssl_context(*, warn_on_error: bool = False) -> ssl.SSLContext:
    """A CA-verified context that ignores REALLMS_INSECURE.

    Secure preflight must never relax verification regardless of how the
    renderer is configured.

    `warn_on_error` mirrors `build_ssl_context`'s stderr warning on a CA-bundle
    `OSError`; it defaults off to keep preflight quiet. The workflow LLM client
    passes `warn_on_error=True`.
    """
    ctx = ssl.create_default_context()
    ctx.check_hostname = True
    ctx.verify_mode = ssl.CERT_REQUIRED
    for cafile in _candidate_ca_files():
        try:
            ctx.load_verify_locations(cafile=str(cafile))
        except OSError as e:
            if warn_on_error:
                sys.stderr.write(f"warning: could not load CA bundle {cafile}: {e}\n")
    return ctx


def _preflight_request(api_url: str, headers: dict, ssl_ctx: ssl.SSLContext, timeout: int = 10) -> int:
    """Make a minimal verified request; return the HTTP status code."""
    req = urllib.request.Request(api_url, data=b"{}", headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ssl_ctx) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        # Reached the server over verified TLS; auth/validation errors still prove connectivity.
        return e.code


def secure_preflight(*, api_key: str, api_url: str, timeout: int = 10) -> tuple[bool, str]:
    """Return (ok, reason). True only if a CA-verified connection succeeds."""
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    ctx = build_secure_ssl_context()
    try:
        code = _preflight_request(api_url, headers, ctx, timeout=timeout)
    except Exception as e:  # noqa: BLE001 — any TLS/DNS failure means not verified
        if _looks_like_cert_error(e):
            return False, "secure TLS verification failed (the CA bundle may be missing)"
        return False, f"could not reach REALLMS over verified TLS: {e}"
    return True, f"verified secure connection (HTTP {code})"
