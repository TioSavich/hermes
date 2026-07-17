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

DEFAULT_API_URL = "https://reallms.rescloud.iu.edu/direct/v1/chat/completions"
DEFAULT_MODEL = "gemma-4-31B-it"


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


def build_ssl_context() -> ssl.SSLContext:
    if os.environ.get("REALLMS_INSECURE", "").strip() in ("1", "true", "yes"):
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
) -> str:
    """Call the chat API with already-formed messages.

    This supports both plain text messages and OpenAI-compatible multimodal
    content arrays with `image_url` parts.
    """
    payload = {
        "model": model,
        "messages": messages,
    }
    body = json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    last_err = None
    for attempt in range(1, retries + 1):
        req = urllib.request.Request(api_url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=timeout, context=ssl_ctx) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                return data["choices"][0]["message"]["content"]
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8", errors="replace")
            last_err = f"HTTP {e.code}: {err_body[:500]}"
            if e.code in (429, 500, 502, 503, 504) and attempt < retries:
                wait = 5 * attempt
                sys.stderr.write(f"  retry {attempt}/{retries} after {wait}s ({last_err.splitlines()[0]})\n")
                time.sleep(wait)
                continue
            break
        except (urllib.error.URLError, TimeoutError) as e:
            last_err = f"network: {e}"
            if _looks_like_cert_error(e):
                last_err += (
                    "\nTLS certificate verification failed before the API key could be checked. "
                    "Set SSL_CERT_FILE to a trusted CA bundle such as /etc/ssl/cert.pem, "
                    "install certifi, or ask campus IT for the IU/network CA bundle. "
                    "REALLMS_INSECURE=1 disables server verification and should only be used for temporary debugging."
                )
                break
            if attempt < retries:
                time.sleep(5 * attempt)
                continue
            break
    message = f"API call failed after {retries} attempts: {last_err}"
    if fail_on_error:
        fail(message)
    raise RuntimeError(message)
    return ""


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

    Used by the campus/home gate: a successful secure connection is the proof
    that the machine is on the IU network, so the preflight must never relax
    verification regardless of how the renderer is configured.

    `warn_on_error` mirrors `build_ssl_context`'s stderr warning on a CA-bundle
    `OSError`; it defaults off to keep the gate preflight's frequent mode
    switches quiet. The workflow LLM client passes `warn_on_error=True`.
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
    """Return (on_campus, reason). True only if a CA-VERIFIED connection succeeds."""
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    ctx = build_secure_ssl_context()
    try:
        code = _preflight_request(api_url, headers, ctx, timeout=timeout)
    except Exception as e:  # noqa: BLE001 — any TLS/DNS failure means "not verified / not on campus"
        if _looks_like_cert_error(e):
            return False, "secure TLS verification failed — not on the IU network (or CA bundle missing)"
        return False, f"could not reach REALLMS over verified TLS: {e}"
    return True, f"verified secure connection (HTTP {code})"
