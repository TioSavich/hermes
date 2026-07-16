"""Shim: workflow scripts import `lib.api`; route them to the unified client."""
from hermes.app.llm import (  # noqa: F401
    DEFAULT_API_URL, DEFAULT_MODEL, fail, load_dotenv, require_api_key,
    resolve_api_url, resolve_model, build_ssl_context, call_api,
    call_api_messages, make_client,
)
