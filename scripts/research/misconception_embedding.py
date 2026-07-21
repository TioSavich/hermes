#!/usr/bin/env python3
"""Build and query a compact embedding index for documented misconceptions.

Vectors are written as float32 ``.npy`` bytes inside an ``.npz`` archive and
the small JSON sidecar holds reviewable provenance.  This avoids a very large
JSON-float artifact while remaining usable with the Python standard library.
"""
from __future__ import annotations

import argparse
import array
import datetime as dt
import json
import os
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))  # hermes.app imports resolve from the checkout
SIDECAR = REPO_ROOT / "data/research/misconception_embeddings.json"
VECTORS = REPO_ROOT / "data/research/misconception_embeddings.npz"
DEFAULT_EMBEDDING_MODEL = "Qwen3-Embedding-8B"
DEFAULT_RERANKER_MODEL = "Qwen3-Reranker-8B"


def enumerate_entries() -> list[dict[str, str]]:
    """Enumerate loaded domain-table rows through the public catalog seam."""
    goal = "use_module(library(http/json)),encyclopedia:misconception_catalog_dict(all,D),json_write_dict(current_output,D),nl,halt"
    result = subprocess.run(
        ["swipl", "-q", "-l", "paths.pl", "-l", "hermes/encyclopedia.pl", "-g", goal],
        cwd=REPO_ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False,
    )
    if result.returncode:
        raise RuntimeError(f"Prolog catalog query failed: {result.stderr.strip()}")
    try:
        rows = json.loads(result.stdout)["misconceptions"]
    except (json.JSONDecodeError, KeyError, TypeError) as exc:
        raise RuntimeError("Prolog catalog did not produce the expected JSON") from exc
    entries = [
        {"name": str(row["name"]).strip(), "domain": str(row["domain"]).strip(),
         "description": str(row["name"]).strip(), "citation": str(row.get("citation", "")).strip()}
        for row in rows if isinstance(row, dict) and row.get("name") and row.get("domain")
    ]
    return sorted(entries, key=lambda row: (row["domain"], row["name"], row["citation"]))


def composed_text(entry: dict[str, str]) -> str:
    return "\n".join((f"Misconception: {entry['name']}", f"Domain: {entry['domain']}",
                      f"Documented error: {entry['description']}", f"Citation: {entry['citation']}"))


def embedding_url() -> str:
    from hermes.app import llm
    chat_url = llm.resolve_api_url()
    if not chat_url.endswith("/chat/completions"):
        raise RuntimeError(f"REALLMS chat URL has unexpected shape: {chat_url}")
    return chat_url.removesuffix("/chat/completions") + "/embeddings"


def call_json(url: str, payload: dict[str, Any], *, api_key: str, ssl_ctx: Any, retries: int = 3) -> dict[str, Any]:
    body = json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    last_error = "unknown error"
    for attempt in range(1, retries + 1):
        try:
            request = urllib.request.Request(url, data=body, headers=headers, method="POST")
            with urllib.request.urlopen(request, timeout=600, context=ssl_ctx) as response:
                data = json.loads(response.read().decode("utf-8"))
                if isinstance(data, dict): return data
                raise RuntimeError("embedding endpoint returned a non-object JSON response")
        except urllib.error.HTTPError as exc:
            last_error, retryable = f"HTTP {exc.code}: {exc.read().decode('utf-8', errors='replace')[:500]}", exc.code in (429, 500, 502, 503, 504)
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error, retryable = f"network: {exc}", True
        if retryable and attempt < retries:
            time.sleep(5 * attempt)
            continue
        break
    raise RuntimeError(f"embedding API call failed after {retries} attempts: {last_error}")


def embed(texts: list[str], *, model: str, client: dict[str, Any]) -> list[list[float]]:
    data = call_json(embedding_url(), {"model": model, "input": texts}, api_key=client["api_key"], ssl_ctx=client["ssl_ctx"])
    rows = data.get("data")
    if not isinstance(rows, list) or len(rows) != len(texts):
        raise RuntimeError("embedding response did not contain one vector per input")
    vectors = [[float(value) for value in row["embedding"]] for row in sorted(rows, key=lambda row: int(row["index"])) if isinstance(row, dict)]
    if len(vectors) != len(texts) or not vectors or len({len(vector) for vector in vectors}) != 1:
        raise RuntimeError("embedding response contained malformed or inconsistent vectors")
    return vectors


def npy_bytes(vectors: list[list[float]]) -> bytes:
    width = len(vectors[0])
    if not vectors or any(len(vector) != width for vector in vectors): raise ValueError("embedding vectors are empty or inconsistent")
    header = str({"descr": "<f4", "fortran_order": False, "shape": (len(vectors), width)}).encode("latin1")
    padding = (16 - ((10 + len(header) + 1) % 16)) % 16
    prefix = b"\x93NUMPY\x01\x00" + struct.pack("<H", len(header) + padding + 1) + header + b" " * padding + b"\n"
    flat = array.array("f", (value for vector in vectors for value in vector))
    if sys.byteorder != "little": flat.byteswap()
    return prefix + flat.tobytes()


def write_index(entries: list[dict[str, str]], vectors: list[list[float]], *, model: str) -> None:
    VECTORS.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(VECTORS, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        archive.writestr("vectors.npy", npy_bytes(vectors))
    SIDECAR.write_text(json.dumps({"format": "misconception-embedding-index-v1", "model": model,
        "built_at": dt.datetime.now(dt.timezone.utc).isoformat(), "count": len(entries),
        "dimensions": len(vectors[0]), "vectors": VECTORS.name, "entries": entries}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    build = commands.add_parser("build"); build.add_argument("--dry-run", action="store_true"); build.add_argument("--batch-size", type=int, default=24)
    search = commands.add_parser("search"); search.add_argument("utterance"); search.add_argument("--k", type=int, default=8); search.add_argument("--rerank", action="store_true")
    args = parser.parse_args()
    if args.command == "build":
        entries = enumerate_entries()
        if args.dry_run:
            print(json.dumps({"count": len(entries), "first": entries[:3]}, indent=2)); return 0
        if args.batch_size < 1: parser.error("--batch-size must be positive")
        from hermes.app import llm
        client, model, vectors = llm.make_client(REPO_ROOT), os.environ.get("REALLMS_EMBEDDING_MODEL", DEFAULT_EMBEDDING_MODEL).strip(), []
        for start in range(0, len(entries), args.batch_size):
            batch = entries[start:start + args.batch_size]; vectors.extend(embed([composed_text(row) for row in batch], model=model, client=client))
            print(f"embedded {min(start + len(batch), len(entries))}/{len(entries)}", file=sys.stderr)
        write_index(entries, vectors, model=model)
        print(json.dumps({"count": len(entries), "model": model, "sidecar": str(SIDECAR), "vectors": str(VECTORS)})); return 0
    from hermes.app.routes.misconception_search import cosine_matches, load_index, rerank_matches
    from hermes.app import llm
    index = load_index(REPO_ROOT)
    if index is None: raise RuntimeError("index is absent or invalid; run build first")
    client = llm.make_client(REPO_ROOT)
    matches = cosine_matches(index, embed([args.utterance], model=index.model, client=client)[0], limit=max(32, args.k))
    if args.rerank: matches = rerank_matches(args.utterance, matches, client=client, model=os.environ.get("REALLMS_RERANKER_MODEL", DEFAULT_RERANKER_MODEL))
    for row in matches[:max(1, args.k)]: print(f"{row['name']} [{row['domain']}] score={row['score']:.4f}\n  {row['citation']}\n  {row['description']}")
    return 0


if __name__ == "__main__": raise SystemExit(main())
