#!/usr/bin/env python3
"""Build and query compact embedding indexes over Hermes knowledge domains.

The embedding engine is shared.  Each domain supplies only row enumeration,
stable identifiers, and text composition.  Vectors are float32 ``.npy`` bytes
inside a compressed ``.npz`` archive; a JSON sidecar keeps reviewable metadata.
When the network-bound embedding service is unavailable, the builder preserves
the exact row payloads that would have been sent.
"""
from __future__ import annotations

import argparse
import array
import datetime as dt
import hashlib
import io
import json
import math
import os
import re
import struct
import subprocess
import sys
import time
import urllib.error
import urllib.request
import zipfile
from collections import Counter
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))  # hermes.app imports resolve from the checkout
INDEX_DIR = REPO_ROOT / "data/research"
DEFAULT_EMBEDDING_MODEL = "Qwen3-Embedding-8B"
DEFAULT_RERANKER_MODEL = "Qwen3-Reranker-8B"
NEW_DOMAINS = ("lessons", "strategies", "registry_ops")
ALL_DOMAINS = ("misconceptions", *NEW_DOMAINS)
EXPECTED_COUNTS = {
    "misconceptions": 2056,
    "lessons": 1308,
    "strategies": 172,
    "registry_ops": 196,
}
IDENTIFIER_FIELDS = {
    "misconceptions": "misconception_id",
    "lessons": "lesson_id",
    "strategies": "signature",
    "registry_ops": "op",
}
ARTIFACT_STEMS = {
    "misconceptions": "misconception",
    "lessons": "lesson",
    "strategies": "strategy",
    "registry_ops": "registry_op",
}
SOURCE_FILES = {
    "misconceptions": ["hermes/encyclopedia.pl", "knowledge/misconceptions/*.pl"],
    "lessons": [
        "curriculum/im/coverage/im_coverage.json",
        "curriculum/im/generated/field_context_cache.json",
        "curriculum/im/generated/compiled_lesson_context.pl",
        "curriculum/im/generated/compiled_action_mappings.pl",
        "knowledge/standards/im/lesson_anchors.pl",
        "knowledge/strategies/math/action_automata_registry.pl",
    ],
    "strategies": ["knowledge/strategies/math/action_automata_registry.pl"],
    "registry_ops": ["hermes/capability_registry.pl"],
}
TOKEN_RE = re.compile(r"[a-z0-9]+")


def artifact_paths(domain: str) -> tuple[Path, Path, Path]:
    stem = ARTIFACT_STEMS[domain]
    return (
        INDEX_DIR / f"{stem}_embeddings.json",
        INDEX_DIR / f"{stem}_embeddings.npz",
        INDEX_DIR / f"{stem}_embedding_payloads.json",
    )


def run_swipl_json(loads: list[str], goal: str) -> dict[str, Any]:
    command = ["swipl", "-q"]
    for load in loads:
        command.extend(("-l", load))
    command.extend(("-g", goal))
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        raise RuntimeError(f"Prolog query failed: {result.stderr.strip()}")
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError("Prolog query did not produce the expected JSON") from exc
    if not isinstance(data, dict):
        raise RuntimeError("Prolog query produced a non-object JSON value")
    return data


def enumerate_misconceptions() -> list[dict[str, Any]]:
    """Enumerate loaded domain-table rows through the public catalog seam."""
    goal = (
        "use_module(library(http/json)),"
        "encyclopedia:misconception_catalog_dict(all,D),"
        "json_write_dict(current_output,D),nl,halt"
    )
    data = run_swipl_json(["paths.pl", "hermes/encyclopedia.pl"], goal)
    rows = data.get("misconceptions")
    if not isinstance(rows, list):
        raise RuntimeError("Prolog catalog did not return a misconceptions list")
    entries = []
    for row in rows:
        if not isinstance(row, dict) or not row.get("name") or not row.get("domain"):
            continue
        name = str(row["name"]).strip()
        domain = str(row["domain"]).strip()
        citation = str(row.get("citation", "")).strip()
        identity_text = json.dumps(
            [domain, name, citation], ensure_ascii=False, separators=(",", ":")
        )
        entries.append(
            {
                "misconception_id": (
                    f"{domain}:{name}:"
                    f"{hashlib.sha256(identity_text.encode('utf-8')).hexdigest()[:12]}"
                ),
                "name": name,
                "domain": domain,
                "description": name,
                "citation": citation,
            }
        )
    return sorted(entries, key=lambda row: (row["domain"], row["name"], row["citation"]))


def enumerate_strategies() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(_{operation:Op,signature:K,input:IS,output:OS,vocabulary:Vs},"
        "(action_automata_registry:action_automaton_signature(Op,K,I,O),"
        "term_string(I,IS,[quoted(true)]),term_string(O,OS,[quoted(true)]),"
        "once(action_automata_registry:action_automaton_vocabulary(Op,K,Vs))),Rows),"
        "json_write_dict(current_output,_{rows:Rows}),nl,halt"
    )
    data = run_swipl_json(
        ["paths.pl", "knowledge/strategies/math/action_automata_registry.pl"],
        goal,
    )
    rows = data.get("rows")
    if not isinstance(rows, list):
        raise RuntimeError("automaton registry did not return a rows list")
    entries: list[dict[str, Any]] = []
    for row in rows:
        if not isinstance(row, dict):
            continue
        operation = str(row["operation"])
        signature = str(row["signature"])
        input_schema = str(row["input"])
        output_schema = str(row["output"])
        entries.append(
            {
                "signature": signature,
                "operation": operation,
                "input_schema": input_schema,
                "output_schema": output_schema,
                "state_action_labels": [str(value) for value in row.get("vocabulary", [])],
                "contract_description": (
                    f"{signature} accepts {input_schema} for {operation} and returns "
                    f"{output_schema}."
                ),
            }
        )
    return sorted(entries, key=lambda row: (row["operation"], row["signature"]))


def lesson_anchor_rows() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(_{lesson_id:Code,title:Title,description:Desc},"
        "(user:standard_anchor(C,im_lesson,Code,Desc),"
        "user:geom_concept(C,Title,_,_)),Rows),"
        "json_write_dict(current_output,_{rows:Rows}),nl,halt"
    )
    data = run_swipl_json(
        ["paths.pl", "knowledge/standards/im/lesson_anchors.pl"],
        goal,
    )
    rows = data.get("rows")
    return rows if isinstance(rows, list) else []


def compiled_lesson_prompts() -> dict[str, list[dict[str, Any]]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(_{lesson_id:Code,task_stems:Tasks},"
        "(compiled_lesson_context:compiled_lesson_context(Code,Prompts,_,source(Source)),"
        "findall(_{heading:H,text:T,line:L,source_guide:Source},"
        "member(context_item(H,T,line(L)),Prompts),Tasks)),Rows),"
        "json_write_dict(current_output,_{rows:Rows}),nl,halt"
    )
    data = run_swipl_json(
        ["paths.pl", "curriculum/im/generated/compiled_lesson_context.pl"],
        goal,
    )
    return {
        str(row["lesson_id"]): row.get("task_stems", [])
        for row in data.get("rows", [])
        if isinstance(row, dict) and row.get("lesson_id")
    }


def compiled_lesson_strategies() -> dict[str, list[dict[str, Any]]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(_{lesson_id:Code,operation:Op,signature:K,evidence:E},"
        "(compiled_action_mappings:compiled_lesson_strategy(Code,Op,K,Ev),"
        "term_string(Ev,E,[quoted(true)])),Rows),"
        "json_write_dict(current_output,_{rows:Rows}),nl,halt"
    )
    data = run_swipl_json(
        ["paths.pl", "curriculum/im/generated/compiled_action_mappings.pl"],
        goal,
    )
    result: dict[str, list[dict[str, Any]]] = {}
    for row in data.get("rows", []):
        if isinstance(row, dict) and row.get("lesson_id"):
            result.setdefault(str(row["lesson_id"]), []).append(row)
    return result


def strategy_contract(
    operation: str,
    signature: str,
    registry: dict[tuple[str, str], dict[str, Any]],
    *,
    source: str,
    evidence: str = "",
    labels: list[str] | None = None,
) -> dict[str, Any]:
    registered = registry.get((operation, signature), {})
    if registered:
        input_schema: str | None = str(registered["input_schema"])
        output_schema: str | None = str(registered["output_schema"])
        state_action_labels = list(registered["state_action_labels"])
        contract_kind = "registered_automaton"
        description = (
            f"{signature} accepts {input_schema} for {operation} and returns "
            f"{output_schema}."
        )
    else:
        input_schema = None
        output_schema = None
        state_action_labels = labels or []
        contract_kind = "lesson_strategy_descriptor"
        description = evidence or f"{operation} strategy descriptor: {signature}."
    return {
        "signature": signature,
        "operation": operation,
        "input_schema": input_schema,
        "output_schema": output_schema,
        "state_action_labels": state_action_labels,
        "contract_kind": contract_kind,
        "contract_description": description,
        "source": source,
        "evidence": evidence,
    }


def enumerate_lessons() -> list[dict[str, Any]]:
    coverage_path = REPO_ROOT / "curriculum/im/coverage/im_coverage.json"
    context_path = REPO_ROOT / "curriculum/im/generated/field_context_cache.json"
    coverage = json.loads(coverage_path.read_text(encoding="utf-8")).get("published_lessons")
    contexts = json.loads(context_path.read_text(encoding="utf-8")).get("field_contexts")
    if not isinstance(coverage, list) or not isinstance(contexts, dict):
        raise RuntimeError("lesson coverage or field-context cache has an unexpected shape")

    anchors = {
        str(row["lesson_id"]): row
        for row in lesson_anchor_rows()
        if isinstance(row, dict) and row.get("lesson_id")
    }
    prompts = compiled_lesson_prompts()
    compiled_strategies = compiled_lesson_strategies()
    registered_rows = enumerate_strategies()
    registry = {
        (str(row["operation"]), str(row["signature"])): row
        for row in registered_rows
    }

    entries: list[dict[str, Any]] = []
    for coverage_row in coverage:
        if not isinstance(coverage_row, dict) or not coverage_row.get("lesson"):
            continue
        lesson_id = str(coverage_row["lesson"])
        context = contexts.get(lesson_id)
        if not isinstance(context, dict):
            raise RuntimeError(f"published lesson {lesson_id} is absent from field_context_cache.json")
        anchor = anchors.get(lesson_id, {})
        lesson_meta = context.get("lesson")
        if not isinstance(lesson_meta, dict):
            lesson_meta = {}
        title = str(lesson_meta.get("title") or anchor.get("title") or lesson_id)

        standards = context.get("standards")
        if not isinstance(standards, list) or not standards:
            description = str(anchor.get("description") or "")
            standards = (
                [{"framework": "im_lesson", "code": lesson_id, "statement": description}]
                if description
                else []
            )
        standard_rows = [
            {
                "framework": str(row.get("framework", "")),
                "code": str(row.get("code", "")),
                "statement": str(row.get("statement", "")),
            }
            for row in standards
            if isinstance(row, dict)
        ]

        contracts: list[dict[str, Any]] = []
        seen_contracts: set[tuple[str, str]] = set()
        context_strategies = context.get("strategies")
        if isinstance(context_strategies, list):
            for row in context_strategies:
                if not isinstance(row, dict) or not row.get("operation") or not row.get("kind"):
                    continue
                key = (str(row["operation"]), str(row["kind"]))
                if key in seen_contracts:
                    continue
                contracts.append(
                    strategy_contract(
                        *key,
                        registry,
                        source=str(row.get("source") or "field_context_cache"),
                        evidence=str(row.get("commitment_made") or row.get("entitlement_granted") or ""),
                        labels=[str(value) for value in row.get("vocabulary", [])],
                    )
                )
                seen_contracts.add(key)
        for row in compiled_strategies.get(lesson_id, []):
            key = (str(row["operation"]), str(row["signature"]))
            if key in seen_contracts:
                continue
            contracts.append(
                strategy_contract(
                    *key,
                    registry,
                    source="compiled_action_mappings",
                    evidence=str(row.get("evidence", "")),
                )
            )
            seen_contracts.add(key)

        task_stems = prompts.get(lesson_id)
        if task_stems is None:
            raw_stems = context.get("activity_prompt")
            task_stems = raw_stems if isinstance(raw_stems, list) else []
        stem_rows = [
            {
                "heading": str(row.get("heading", "")),
                "text": str(row.get("text", "")),
                "line": row.get("line"),
                "source_guide": str(row.get("source_guide", context.get("source_guide", ""))),
            }
            for row in task_stems
            if isinstance(row, dict)
        ]
        entries.append(
            {
                "lesson_id": lesson_id,
                "title": title,
                "standards": standard_rows,
                "strategy_contracts": sorted(
                    contracts, key=lambda row: (row["operation"], row["signature"])
                ),
                "task_stems": stem_rows,
            }
        )
    return sorted(entries, key=lambda row: row["lesson_id"])


def enumerate_registry_ops() -> list[dict[str, Any]]:
    goal = (
        "use_module(library(http/json)),"
        "findall(_{op:Op,module:M,role:R,inputs:Is,status:S,parameters:Ps,"
        "description:D,routes:Routes,pages:Pages,lazy_via:Lazy},"
        "(capability_registry:capability(Op,M,R,Is,S),"
        "memberchk(S,[routed_paged,unrouted]),"
        "findall(_{name:N,type:T,required:Req,example:E},"
        "capability_registry:capability_parameter(Op,N,T,Req,E),Ps),"
        "(capability_registry:capability_description(Op,D0)->D=D0;D=null),"
        "findall(_{method:Method,path:Path},"
        "capability_registry:capability_route(Op,Method,Path),Routes),"
        "findall(Page,capability_registry:capability_page(Op,Page),Pages),"
        "findall(Via,capability_registry:capability_lazy_via(Op,Via),Lazy)),Rows),"
        "json_write_dict(current_output,_{rows:Rows}),nl,halt"
    )
    data = run_swipl_json(["hermes/capability_registry.pl"], goal)
    rows = data.get("rows")
    if not isinstance(rows, list):
        raise RuntimeError("capability registry did not return a rows list")
    return sorted(
        (row for row in rows if isinstance(row, dict) and row.get("op")),
        key=lambda row: str(row["op"]),
    )


def enumerate_entries(domain: str) -> list[dict[str, Any]]:
    enumerators = {
        "misconceptions": enumerate_misconceptions,
        "lessons": enumerate_lessons,
        "strategies": enumerate_strategies,
        "registry_ops": enumerate_registry_ops,
    }
    entries = enumerators[domain]()
    expected = EXPECTED_COUNTS[domain]
    if len(entries) != expected:
        raise RuntimeError(f"{domain} count is {len(entries)}, expected exactly {expected}")
    identifier = IDENTIFIER_FIELDS[domain]
    identifiers = [str(row.get(identifier, "")).strip() for row in entries]
    if any(not value for value in identifiers) or len(set(identifiers)) != len(identifiers):
        raise RuntimeError(f"{domain} has missing or duplicate {identifier} values")
    return entries


def composed_text(domain: str, entry: dict[str, Any]) -> str:
    if domain == "misconceptions":
        return "\n".join(
            (
                f"Misconception: {entry['name']}",
                f"Domain: {entry['domain']}",
                f"Documented error: {entry['description']}",
                f"Citation: {entry['citation']}",
            )
        )
    if domain == "strategies":
        labels = ", ".join(entry["state_action_labels"]) or "none registered"
        return "\n".join(
            (
                f"Automaton signature: {entry['signature']}",
                f"Operation: {entry['operation']}",
                f"Input schema: {entry['input_schema']}",
                f"Output schema: {entry['output_schema']}",
                f"State and action labels: {labels}",
                f"Contract: {entry['contract_description']}",
            )
        )
    if domain == "registry_ops":
        parameters = "; ".join(
            f"{row.get('name')} ({row.get('type') or 'untyped'}, "
            f"{'required' if row.get('required') else 'optional'})"
            for row in entry.get("parameters", [])
        )
        routes = ", ".join(
            f"{row.get('method')} {row.get('path')}" for row in entry.get("routes", [])
        )
        pages = ", ".join(str(value) for value in entry.get("pages", []))
        description = entry.get("description") or "No additional description registered."
        return "\n".join(
            (
                f"Dispatch operation: {entry['op']}",
                f"Provider module: {entry['module']}",
                f"Role: {entry['role']}",
                f"Inputs: {', '.join(entry.get('inputs', [])) or 'none'}",
                f"Parameters: {parameters or 'none'}",
                f"Description: {description}",
                f"Status: {entry['status']}",
                f"Routes: {routes or 'none'}",
                f"Pages: {pages or 'none'}",
            )
        )
    standards = "\n".join(
        f"- {row['framework']} {row['code']}: {row['statement']}"
        for row in entry["standards"]
    )
    strategies = "\n".join(
        f"- {row['operation']}:{row['signature']}; {row['contract_description']} "
        f"State/action labels: {', '.join(row['state_action_labels']) or 'none registered'}"
        for row in entry["strategy_contracts"]
    )
    tasks = "\n".join(
        f"- {row['heading']}: {row['text']}" for row in entry["task_stems"]
    )
    return "\n".join(
        (
            f"Lesson ID: {entry['lesson_id']}",
            f"Title: {entry['title']}",
            "Standards:",
            standards or "- none attached",
            "Strategy contracts:",
            strategies or "- none attached",
            "Task stems:",
            tasks or "- none recovered",
        )
    )


def configured_model() -> str:
    from hermes.app import llm

    llm.load_dotenv(REPO_ROOT)
    return os.environ.get("REALLMS_EMBEDDING_MODEL", DEFAULT_EMBEDDING_MODEL).strip()


def exact_payload(domain: str, entries: list[dict[str, Any]], *, model: str) -> dict[str, Any]:
    identifier = IDENTIFIER_FIELDS[domain]
    rows = [
        {
            "id": str(entry[identifier]),
            "text": composed_text(domain, entry),
            "metadata": entry,
        }
        for entry in entries
    ]
    canonical = json.dumps(rows, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    source_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
    return {
        "format": "hermes-embedding-payload-v1",
        "domain": domain,
        "model": model,
        "network_bound": True,
        "count": len(rows),
        "identifier_field": identifier,
        "source_files": SOURCE_FILES[domain],
        "source_hash": source_hash,
        "rows": rows,
    }


def json_bytes(value: Any) -> bytes:
    return (
        json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    ).encode("utf-8")


def write_if_changed(path: Path, content: bytes) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_bytes() == content:
        return False
    path.write_bytes(content)
    return True


def embedding_url() -> str:
    from hermes.app import llm

    chat_url = llm.resolve_api_url()
    if not chat_url.endswith("/chat/completions"):
        raise RuntimeError(f"REALLMS chat URL has unexpected shape: {chat_url}")
    return chat_url.removesuffix("/chat/completions") + "/embeddings"


def embedding_client() -> dict[str, Any]:
    from hermes.app import llm

    api_key = llm.load_key(REPO_ROOT)
    if api_key is None:
        raise RuntimeError("REALLMS_API_KEY is not configured")
    return {"api_key": api_key, "ssl_ctx": llm.build_ssl_context()}


def call_json(
    url: str,
    payload: dict[str, Any],
    *,
    api_key: str,
    ssl_ctx: Any,
    retries: int = 3,
) -> dict[str, Any]:
    body = json.dumps(payload).encode("utf-8")
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    last_error = "unknown error"
    for attempt in range(1, retries + 1):
        try:
            request = urllib.request.Request(url, data=body, headers=headers, method="POST")
            with urllib.request.urlopen(request, timeout=600, context=ssl_ctx) as response:
                data = json.loads(response.read().decode("utf-8"))
                if isinstance(data, dict):
                    return data
                raise RuntimeError("embedding endpoint returned a non-object JSON response")
        except urllib.error.HTTPError as exc:
            last_error = (
                f"HTTP {exc.code}: "
                f"{exc.read().decode('utf-8', errors='replace')[:500]}"
            )
            retryable = exc.code in (429, 500, 502, 503, 504)
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error, retryable = f"network: {exc}", True
        if retryable and attempt < retries:
            time.sleep(5 * attempt)
            continue
        break
    raise RuntimeError(f"embedding API call failed after {retries} attempts: {last_error}")


def embed(
    texts: list[str],
    *,
    model: str,
    client: dict[str, Any],
    retries: int = 3,
) -> list[list[float]]:
    data = call_json(
        embedding_url(),
        {"model": model, "input": texts},
        api_key=client["api_key"],
        ssl_ctx=client["ssl_ctx"],
        retries=retries,
    )
    rows = data.get("data")
    if not isinstance(rows, list) or len(rows) != len(texts):
        raise RuntimeError("embedding response did not contain one vector per input")
    vectors = [
        [float(value) for value in row["embedding"]]
        for row in sorted(rows, key=lambda row: int(row["index"]))
        if isinstance(row, dict)
    ]
    if (
        len(vectors) != len(texts)
        or not vectors
        or len({len(vector) for vector in vectors}) != 1
    ):
        raise RuntimeError("embedding response contained malformed or inconsistent vectors")
    return vectors


def npy_bytes(vectors: list[list[float]]) -> bytes:
    if not vectors:
        raise ValueError("embedding vectors are empty")
    width = len(vectors[0])
    if not width or any(len(vector) != width for vector in vectors):
        raise ValueError("embedding vectors are empty or inconsistent")
    header = str(
        {"descr": "<f4", "fortran_order": False, "shape": (len(vectors), width)}
    ).encode("latin1")
    padding = (16 - ((10 + len(header) + 1) % 16)) % 16
    prefix = (
        b"\x93NUMPY\x01\x00"
        + struct.pack("<H", len(header) + padding + 1)
        + header
        + b" " * padding
        + b"\n"
    )
    flat = array.array("f", (value for vector in vectors for value in vector))
    if sys.byteorder != "little":
        flat.byteswap()
    return prefix + flat.tobytes()


def deterministic_npz(vectors: list[list[float]]) -> bytes:
    buffer = io.BytesIO()
    info = zipfile.ZipInfo("vectors.npy", date_time=(1980, 1, 1, 0, 0, 0))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o600 << 16
    with zipfile.ZipFile(buffer, "w", compresslevel=9) as archive:
        archive.writestr(info, npy_bytes(vectors))
    return buffer.getvalue()


def write_index(
    domain: str,
    entries: list[dict[str, Any]],
    vectors: list[list[float]],
    *,
    model: str,
    source_hash: str,
) -> None:
    sidecar, vector_path, _ = artifact_paths(domain)
    vector_bytes = deterministic_npz(vectors)
    write_if_changed(vector_path, vector_bytes)
    if domain == "misconceptions":
        index_format = "misconception-embedding-index-v1"
    else:
        index_format = "hermes-embedding-index-v1"
    artifact = {
        "format": index_format,
        "domain": domain,
        "model": model,
        "built_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "count": len(entries),
        "dimensions": len(vectors[0]),
        "vectors": vector_path.name,
        "identifier_field": IDENTIFIER_FIELDS[domain],
        "source_hash": source_hash,
        "entries": entries,
    }
    write_if_changed(sidecar, json_bytes(artifact))


def current_index(domain: str, *, model: str, source_hash: str) -> bool:
    sidecar, vector_path, _ = artifact_paths(domain)
    try:
        artifact = json.loads(sidecar.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False
    return (
        vector_path.is_file()
        and artifact.get("model") == model
        and artifact.get("source_hash") == source_hash
        and artifact.get("count") == EXPECTED_COUNTS[domain]
    )


def selected_domains(value: str) -> tuple[str, ...]:
    if value == "new":
        return NEW_DOMAINS
    if value == "all":
        return ALL_DOMAINS
    return (value,)


def build_domains(args: argparse.Namespace) -> int:
    model = configured_model()
    prepared: list[tuple[str, list[dict[str, Any]], dict[str, Any]]] = []
    for domain in selected_domains(args.domain):
        entries = enumerate_entries(domain)
        payload = exact_payload(domain, entries, model=model)
        prepared.append((domain, entries, payload))
        if args.dry_run:
            continue
        _, _, payload_path = artifact_paths(domain)
        write_if_changed(payload_path, json_bytes(payload))
    if args.dry_run:
        print(
            json.dumps(
                {
                    "model": model,
                    "domains": [
                        {"domain": domain, "count": len(entries), "first": entries[:1]}
                        for domain, entries, _ in prepared
                    ],
                },
                indent=2,
            )
        )
        return 0
    if args.payload_only:
        print(
            json.dumps(
                {
                    "status": "payload_only",
                    "model": model,
                    "domains": [
                        {
                            "domain": domain,
                            "count": len(entries),
                            "payload": str(artifact_paths(domain)[2]),
                        }
                        for domain, entries, _ in prepared
                    ],
                }
            )
        )
        return 0
    if args.batch_size < 1:
        raise ValueError("--batch-size must be positive")
    if args.retries < 1:
        raise ValueError("--retries must be positive")

    results: list[dict[str, Any]] = []
    service_error: str | None = None
    try:
        client = embedding_client()
    except RuntimeError as exc:
        client, service_error = {}, str(exc)
    for domain, entries, payload in prepared:
        if current_index(domain, model=model, source_hash=payload["source_hash"]):
            results.append({"domain": domain, "count": len(entries), "status": "unchanged"})
            continue
        if service_error is not None:
            results.append(
                {
                    "domain": domain,
                    "count": len(entries),
                    "status": "payload_only",
                    "reason": service_error,
                }
            )
            continue
        vectors: list[list[float]] = []
        try:
            rows = payload["rows"]
            for start in range(0, len(rows), args.batch_size):
                batch = rows[start : start + args.batch_size]
                vectors.extend(
                    embed(
                        [row["text"] for row in batch],
                        model=model,
                        client=client,
                        retries=args.retries,
                    )
                )
                print(
                    f"{domain}: embedded {min(start + len(batch), len(rows))}/{len(rows)}",
                    file=sys.stderr,
                )
        except RuntimeError as exc:
            service_error = str(exc)
            results.append(
                {
                    "domain": domain,
                    "count": len(entries),
                    "status": "payload_only",
                    "reason": service_error,
                }
            )
            continue
        write_index(
            domain,
            entries,
            vectors,
            model=model,
            source_hash=payload["source_hash"],
        )
        results.append(
            {
                "domain": domain,
                "count": len(entries),
                "status": "built",
                "dimensions": len(vectors[0]),
            }
        )
    status = "partial" if any(row["status"] == "payload_only" for row in results) else "complete"
    print(json.dumps({"status": status, "model": model, "domains": results}))
    return 0 if status == "complete" or args.allow_payload_only else 2


def read_npy(raw: bytes) -> list[list[float]]:
    if raw[:8] != b"\x93NUMPY\x01\x00":
        raise ValueError("vectors.npy is not a supported NumPy v1 file")
    header_length = struct.unpack("<H", raw[8:10])[0]
    header = raw[10 : 10 + header_length].decode("latin1")
    if "'descr': '<f4'" not in header or "'fortran_order': False" not in header:
        raise ValueError("vectors.npy has an unsupported layout")
    marker = "'shape': ("
    start = header.find(marker)
    if start < 0:
        raise ValueError("vectors.npy is missing its shape")
    rows, columns = (
        int(value.strip())
        for value in header[start + len(marker) :].split(")", 1)[0].split(",")[:2]
    )
    values = array.array("f")
    values.frombytes(raw[10 + header_length :])
    if sys.byteorder != "little":
        values.byteswap()
    if len(values) != rows * columns:
        raise ValueError("vectors.npy byte count does not match its shape")
    return [
        list(values[offset : offset + columns])
        for offset in range(0, len(values), columns)
    ]


def load_index(domain: str) -> tuple[dict[str, Any], list[list[float]]]:
    sidecar, vector_path, _ = artifact_paths(domain)
    artifact = json.loads(sidecar.read_text(encoding="utf-8"))
    with zipfile.ZipFile(vector_path) as archive:
        vectors = read_npy(archive.read("vectors.npy"))
    entries = artifact.get("entries")
    if not isinstance(entries, list) or len(entries) != len(vectors):
        raise RuntimeError(f"{domain} index entries do not align with its vectors")
    return artifact, vectors


def cosine_matches(
    entries: list[dict[str, Any]],
    vectors: list[list[float]],
    query_vector: list[float],
    *,
    domain: str,
    limit: int,
) -> list[dict[str, Any]]:
    if not query_vector or not vectors or len(query_vector) != len(vectors[0]):
        raise ValueError("query embedding dimensions do not match the built index")
    query_norm = math.sqrt(sum(value * value for value in query_vector))
    if query_norm == 0:
        raise ValueError("query embedding has zero magnitude")
    identifier = IDENTIFIER_FIELDS[domain]
    scored = []
    for entry, vector in zip(entries, vectors):
        norm = math.sqrt(sum(value * value for value in vector))
        if norm == 0:
            continue
        score = sum(left * right for left, right in zip(query_vector, vector))
        scored.append({**entry, "score": score / (query_norm * norm)})
    return sorted(scored, key=lambda row: (-row["score"], str(row[identifier])))[:limit]


def search_index(args: argparse.Namespace) -> int:
    artifact, vectors = load_index(args.domain)
    client = embedding_client()
    query_vector = embed(
        [args.utterance],
        model=str(artifact["model"]),
        client=client,
        retries=args.retries,
    )[0]
    matches = cosine_matches(
        artifact["entries"],
        vectors,
        query_vector,
        domain=args.domain,
        limit=max(32, args.k),
    )
    if args.rerank:
        from hermes.app.routes.misconception_search import rerank_matches

        if args.domain != "misconceptions":
            raise RuntimeError("--rerank is currently supported only for misconceptions")
        matches = rerank_matches(
            args.utterance,
            matches,
            client=client,
            model=os.environ.get("REALLMS_RERANKER_MODEL", DEFAULT_RERANKER_MODEL),
        )
    print(json.dumps(matches[: max(1, args.k)], indent=2, ensure_ascii=False))
    return 0


def tokenize(text: str) -> list[str]:
    return TOKEN_RE.findall(text.lower())


def lexical_payload_matches(
    payload: dict[str, Any], query: str, *, limit: int
) -> list[dict[str, Any]]:
    """Inspect row composition offline; this is not an embedding fallback."""
    rows = payload.get("rows")
    if not isinstance(rows, list) or not rows:
        raise RuntimeError("payload artifact has no rows")
    documents = [Counter(tokenize(str(row["text"]))) for row in rows]
    lengths = [sum(document.values()) for document in documents]
    average_length = sum(lengths) / len(lengths)
    document_frequency: Counter[str] = Counter()
    for document in documents:
        document_frequency.update(document.keys())
    query_terms = Counter(tokenize(query))
    scored: list[dict[str, Any]] = []
    for row, document, length in zip(rows, documents, lengths):
        score = 0.0
        for term, query_count in query_terms.items():
            frequency = document.get(term, 0)
            if not frequency:
                continue
            inverse_frequency = math.log(
                1 + (len(rows) - document_frequency[term] + 0.5)
                / (document_frequency[term] + 0.5)
            )
            denominator = frequency + 1.5 * (1 - 0.75 + 0.75 * length / average_length)
            score += query_count * inverse_frequency * frequency * 2.5 / denominator
        scored.append({"id": row["id"], "score": score})
    return sorted(scored, key=lambda row: (-row["score"], str(row["id"])))[:limit]


def probe_payload(args: argparse.Namespace) -> int:
    _, _, payload_path = artifact_paths(args.domain)
    payload = json.loads(payload_path.read_text(encoding="utf-8"))
    matches = lexical_payload_matches(payload, args.query, limit=args.k)
    print(
        json.dumps(
            {
                "domain": args.domain,
                "query": args.query,
                "retrieval": "lexical_payload_inspection_not_embedding",
                "matches": matches,
            },
            ensure_ascii=False,
        )
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)

    build = commands.add_parser("build")
    build.add_argument(
        "--domain",
        choices=(*ALL_DOMAINS, "new", "all"),
        default="misconceptions",
    )
    build.add_argument("--dry-run", action="store_true")
    build.add_argument("--payload-only", action="store_true")
    build.add_argument("--allow-payload-only", action="store_true")
    build.add_argument("--batch-size", type=int, default=24)
    build.add_argument("--retries", type=int, default=3)

    search = commands.add_parser("search")
    search.add_argument("utterance")
    search.add_argument("--domain", choices=ALL_DOMAINS, default="misconceptions")
    search.add_argument("--k", type=int, default=8)
    search.add_argument("--rerank", action="store_true")
    search.add_argument("--retries", type=int, default=3)

    probe = commands.add_parser("probe")
    probe.add_argument("--domain", choices=ALL_DOMAINS, required=True)
    probe.add_argument("--query", required=True)
    probe.add_argument("--k", type=int, default=3)

    args = parser.parse_args()
    if args.command == "build":
        return build_domains(args)
    if args.command == "search":
        return search_index(args)
    return probe_payload(args)


if __name__ == "__main__":
    raise SystemExit(main())
