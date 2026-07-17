"""Workflow LLM shim backed by the active WorkflowContext."""
from __future__ import annotations

from typing import Any

from hermes.app import llm as _default_llm
from hermes.app.workflow.service import current_context

DEFAULT_API_URL = _default_llm.DEFAULT_API_URL
DEFAULT_MODEL = _default_llm.DEFAULT_MODEL


def _client() -> Any:
    try:
        return current_context().llm_client
    except RuntimeError:
        return _default_llm


def load_dotenv(*args: Any, **kwargs: Any) -> Any:
    return _client().load_dotenv(*args, **kwargs)


def require_api_key(*args: Any, **kwargs: Any) -> Any:
    return _client().require_api_key(*args, **kwargs)


def resolve_api_url(*args: Any, **kwargs: Any) -> Any:
    return _client().resolve_api_url(*args, **kwargs)


def resolve_model(*args: Any, **kwargs: Any) -> Any:
    return _client().resolve_model(*args, **kwargs)


def build_ssl_context(*args: Any, **kwargs: Any) -> Any:
    return _client().build_ssl_context(*args, **kwargs)


def call_api(*args: Any, **kwargs: Any) -> Any:
    return _client().call_api(*args, **kwargs)


def call_api_messages(*args: Any, **kwargs: Any) -> Any:
    return _client().call_api_messages(*args, **kwargs)


def make_client(*args: Any, **kwargs: Any) -> Any:
    return _client().make_client(*args, **kwargs)


def fail(*args: Any, **kwargs: Any) -> Any:
    return _client().fail(*args, **kwargs)
