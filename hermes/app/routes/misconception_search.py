"""Embedding retrieval over the generated misconception index; no worker call."""
from __future__ import annotations

import array
import json
import math
import os
import struct
import sys
import urllib.error
import urllib.request
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from hermes.app import llm
from hermes.app.routes.registry import Route

DEFAULT_RERANKER_MODEL = "Qwen3-Reranker-8B"


@dataclass(frozen=True)
class EmbeddingIndex:
    entries: tuple[dict[str, str], ...]
    vectors: tuple[tuple[float, ...], ...]
    norms: tuple[float, ...]
    model: str


def _read_npy(raw: bytes) -> tuple[tuple[float, ...], ...]:
    if raw[:8] != b"\x93NUMPY\x01\x00": raise ValueError("vectors.npy is not a supported NumPy v1 file")
    header_length = struct.unpack("<H", raw[8:10])[0]
    header = raw[10:10 + header_length].decode("latin1")
    if "'descr': '<f4'" not in header or "'fortran_order': False" not in header: raise ValueError("vectors.npy has an unsupported layout")
    marker = "'shape': ("; start = header.find(marker)
    if start < 0: raise ValueError("vectors.npy is missing its shape")
    rows, columns = (int(value.strip()) for value in header[start + len(marker):].split(")", 1)[0].split(",")[:2])
    values = array.array("f"); values.frombytes(raw[10 + header_length:])
    if sys.byteorder != "little": values.byteswap()
    if len(values) != rows * columns: raise ValueError("vectors.npy byte count does not match its shape")
    return tuple(tuple(values[offset:offset + columns]) for offset in range(0, len(values), columns))


def load_index(repo_root: Path) -> EmbeddingIndex | None:
    try:
        artifact = json.loads((repo_root / "data/research/misconception_embeddings.json").read_text(encoding="utf-8"))
        with zipfile.ZipFile(repo_root / "data/research/misconception_embeddings.npz") as archive: vectors = _read_npy(archive.read("vectors.npy"))
        entries = artifact["entries"]
        if not isinstance(entries, list) or not entries or len(entries) != len(vectors): return None
        cleaned = tuple({key: str(entry.get(key, "")) for key in ("name", "domain", "description", "citation")} for entry in entries if isinstance(entry, dict))
        norms = tuple(math.sqrt(sum(value * value for value in vector)) for vector in vectors)
        if len(cleaned) != len(vectors) or any(norm == 0 for norm in norms): return None
        return EmbeddingIndex(cleaned, vectors, norms, str(artifact["model"]))
    except (KeyError, OSError, ValueError, json.JSONDecodeError, zipfile.BadZipFile): return None


def cosine_matches(index: EmbeddingIndex, query_vector: list[float], *, limit: int) -> list[dict[str, Any]]:
    if not query_vector or len(query_vector) != len(index.vectors[0]): raise ValueError("query embedding dimensions do not match the built index")
    query_norm = math.sqrt(sum(value * value for value in query_vector))
    if query_norm == 0: raise ValueError("query embedding has zero magnitude")
    matches = [{**entry, "score": sum(left * right for left, right in zip(query_vector, vector)) / (query_norm * norm)} for entry, vector, norm in zip(index.entries, index.vectors, index.norms)]
    return sorted(matches, key=lambda row: (-row["score"], row["domain"], row["name"]))[:limit]


def _api_json(url: str, payload: dict[str, Any], *, api_key: str, ssl_ctx: Any) -> dict[str, Any]:
    request = urllib.request.Request(url, data=json.dumps(payload).encode("utf-8"), headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(request, timeout=300, context=ssl_ctx) as response: data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc: raise RuntimeError(f"REALLMS embedding request failed (HTTP {exc.code})") from exc
    except (urllib.error.URLError, TimeoutError) as exc: raise RuntimeError(f"REALLMS embedding request could not reach the service: {exc}") from exc
    if not isinstance(data, dict): raise RuntimeError("REALLMS embedding request returned malformed JSON")
    return data


def _v1_url(endpoint: str) -> str:
    chat_url = llm.resolve_api_url()
    if not chat_url.endswith("/chat/completions"): raise RuntimeError("REALLMS chat URL does not identify a v1 endpoint")
    return chat_url.removesuffix("/chat/completions") + endpoint


def embed_query(utterance: str, *, index: EmbeddingIndex, repo_root: Path) -> list[float]:
    api_key = llm.load_key(repo_root)
    if api_key is None: raise PermissionError("misconception retrieval needs REALLMS_API_KEY; no query was sent")
    model = os.environ.get("REALLMS_EMBEDDING_MODEL", index.model).strip()
    rows = _api_json(_v1_url("/embeddings"), {"model": model, "input": [utterance]}, api_key=api_key, ssl_ctx=llm.build_ssl_context()).get("data")
    if not isinstance(rows, list) or len(rows) != 1 or not isinstance(rows[0], dict) or not isinstance(rows[0].get("embedding"), list): raise RuntimeError("REALLMS embedding response did not contain one query vector")
    return [float(value) for value in rows[0]["embedding"]]


def rerank_matches(query: str, matches: list[dict[str, Any]], *, client: dict[str, Any], model: str = DEFAULT_RERANKER_MODEL) -> list[dict[str, Any]]:
    documents = [f"{row['name']}\n{row['description']}\n{row['citation']}" for row in matches]
    data = _api_json(_v1_url("/rerank"), {"model": model, "query": query, "documents": documents}, api_key=client["api_key"], ssl_ctx=client["ssl_ctx"])
    rows = data.get("data") or data.get("results")
    if not isinstance(rows, list): raise RuntimeError("reranker response did not contain results")
    scores = {int(row["index"]): float(row.get("relevance_score", row.get("score", 0))) for row in rows if isinstance(row, dict) and "index" in row}
    return sorted(({**row, "score": scores.get(index, row["score"])} for index, row in enumerate(matches)), key=lambda row: -row["score"])


def misconception_search(ctx: Any) -> None:
    payload = ctx.payload if isinstance(ctx.payload, dict) else {}; utterance = str(payload.get("utterance") or "").strip()
    if not utterance: ctx._send_json({"error": "utterance is required"}, status=400); return
    if len(utterance) > 8000: ctx._send_json({"error": "utterance must be at most 8000 characters"}, status=400); return
    try: k = min(max(int(payload.get("k", 8)), 1), 32)
    except (TypeError, ValueError): ctx._send_json({"error": "k must be an integer"}, status=400); return
    index = ctx.services.misconception_embedding_index
    if index is None:
        ctx._send_json({"error": "misconception embedding index is not built; run scripts/research/misconception_embedding.py build"}, status=503); return
    try: matches = cosine_matches(index, embed_query(utterance, index=index, repo_root=ctx.repo_root), limit=k)
    except PermissionError as exc: ctx._send_json({"error": str(exc)}, status=503); return
    except (RuntimeError, ValueError) as exc: ctx._send_json({"error": str(exc)}, status=502); return
    ctx._send_json({"ok": True, "retrieval": "embedding", "model": index.model, "results": matches})


ROUTES = (Route("POST", "/api/misconception_search", misconception_search),)
