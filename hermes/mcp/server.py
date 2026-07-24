#!/usr/bin/env python3
"""A dependency-free stdio MCP bridge for the Hermes worker.

The transport is newline-delimited JSON-RPC 2.0.  It intentionally has no
network listener: one lazily-started PersistentPrologWorker owns all symbolic
requests for the lifetime of this process.
"""
from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from hermes.app.root import resolve_hermes_root
from hermes.app.routes.misconception_search import cosine_matches, load_index
from hermes.app.worker import PersistentPrologError, PersistentPrologWorker


PROTOCOL_VERSION = "2025-03-26"
REGISTRY_ROW = re.compile(
    r"^capability\('([^']+)', '([^']+)', '([^']+)', \[(.*?)\], ([^)]+)\)\.$"
)
INPUT_CONTRACT_ROW = re.compile(
    r"^automaton_input_contract\(([^,]+), ([^,]+), '(.+)', '(.+)', verified\(([^)]+)\)\)\.$"
)
EMBEDDING_ARTIFACTS = (
    "data/research/misconception_embeddings.json",
    "data/research/misconception_embeddings.npz",
)
EMBEDDING_REBUILD = "python3 scripts/research/misconception_embedding.py build"
REGISTRY_ARTIFACT = "hermes/capability_registry.pl"
REGISTRY_REBUILD = "python3 scripts/extract_capability_registry.py"

CORE_TO_WORKER = {
    "monitoring_chart": "monitoring_chart_export",
    "lesson_deformation_chart": "lesson_deformation_chart",
    "deontic_scorecard": "deontic_scorecard",
    "deontic_consequences": "deontic_consequences",
    "deontic_up_level": "deontic_up_level",
    "commitment_match": "commitment_match",
    "strategy_trace": "strategy_trace",
    "strategy_recognize": "strategy_recognize",
    "misconception_lookup": "query_misconception",
}

TOOL_BUNDLES = {
    "transcript-analysis": (
        "deontic_scorecard", "deontic_consequences", "deontic_up_level",
        "commitment_match", "strategy_trace", "misconception_lookup",
        "strategy_recognize", "misconception_search_rows", "resonance_neighbors",
    ),
    "curriculum-reading": (
        "monitoring_chart", "monitoring_chart_detail",
        "lesson_deformation_chart", "lesson_deformation_chart_detail",
        "strategy_trace", "misconception_lookup", "misconception_search_rows",
    ),
}

CORE_TOOLS = (
    ("monitoring_chart", "Return a compact monitoring-chart inventory for an IM lesson code. Use monitoring_chart_detail for one named section; set full to true only for renderer-oriented consumers. Expected time: a few seconds after worker startup.", ("code", "full")),
    ("monitoring_chart_detail", "Return one named section from a monitoring chart. Call monitoring_chart first to obtain the section inventory. Expected time: a few seconds.", ("code", "section")),
    ("lesson_deformation_chart", "Return a compact deformation-chart inventory for an IM lesson code. Use lesson_deformation_chart_detail for one scene or frame; set full to true only for renderer-oriented consumers. Expected time: a few seconds after worker startup.", ("code", "full")),
    ("lesson_deformation_chart_detail", "Return one identified scene or frame from a deformation chart. Call lesson_deformation_chart first to obtain its inventory. Expected time: a few seconds.", ("code", "id")),
    ("check_math_claim", "Parse and check an explicit mathematical claim in symbolic or ordinary classroom language. The reader covers registered arithmetic, fraction, comparison, and same-unit total forms; it preserves modality, polarity, reports, questions, and quotation separately and abstains on implied operations.", ("term",)),
    ("deontic_scorecard", "Return the ephemeral scorecard for stated commitment and entitlement terms.", ("agent", "commitments", "entitlements")),
    ("deontic_consequences", "Return consequences licensed by stated commitment terms.", ("agent", "commitments")),
    ("deontic_up_level", "Return named up-level questions for unresolved commitment gaps.", ("agent", "commitments")),
    ("commitment_match", "Match reading content through the strategy/misconception and literature-canonical vocabularies. Each match labels its matcher; it abstains when neither complete-name gate admits a term.", ("content",)),
    ("strategy_recognize", "Align ordinary classroom language to five execution-observed strategy traces. Results are candidates with token spans, missing evidence, trace frontier, order conflicts, and observed-transition provenance; an empty list is an abstention.", ("content",)),
    ("strategy_trace", "Run one registered strategy with an optional input object. The schema lists the registry-backed names, operation pairing, and worked inputs. Expected time: usually under two seconds after worker startup.", ("strategy", "input")),
    ("misconception_lookup", "Look up encoded misconceptions by optional domain, description, or source filters.", ("domain", "description", "source")),
    ("misconception_search_rows", "Search stored misconception rows offline by whole query words in their name, domain, description, or citation. All query words must be present. Use a returned name with resonance_neighbors.", ("query", "k")),
    ("resonance_neighbors", "Find neighbors of a named stored misconception vector. This uses only the stored row vector; it never makes a query-embedding network call.", ("name", "k")),
)


class ToolCallError(ValueError):
    """A user-facing tool failure with an MCP error category."""

    def __init__(self, message: str, *, kind: str, worker_type: str | None = None, extra: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.kind = kind
        self.worker_type = worker_type
        self.extra = extra or {}


def error(request_id: Any, code: int, message: str, data: Any = None) -> dict[str, Any]:
    body: dict[str, Any] = {"jsonrpc": "2.0", "id": request_id, "error": {"code": code, "message": message}}
    if data is not None:
        body["error"]["data"] = data
    return body


def result(request_id: Any, value: Any) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": value}


def schema(parameters: tuple[str, ...] | list[str]) -> dict[str, Any]:
    """Registry rows retain names, not types/defaults; represent that honestly."""
    return {
        "type": "object",
        "properties": {
            name: {"type": "string", "description": "Registry metadata does not provide a type; pass the worker's JSON value as a string when unsure."}
            for name in parameters
        },
        "additionalProperties": False,
    }


def tool(name: str, description: str, parameters: tuple[str, ...] | list[str]) -> dict[str, Any]:
    return {"name": name, "description": description, "inputSchema": schema(parameters)}


def core_tool(name: str, description: str, parameters: tuple[str, ...], strategy_contracts: list[dict[str, Any]]) -> dict[str, Any]:
    """Hand-authored tools can state the few JSON shapes their worker accepts."""
    kinds = {"commitments": "array", "entitlements": "array", "input": "object", "k": "integer", "full": "boolean"}
    properties: dict[str, dict[str, Any]] = {}
    for parameter in parameters:
        kind = kinds.get(parameter, "string")
        item: dict[str, Any] = {"type": kind}
        if kind == "array":
            item["items"] = {"type": "string"}
        properties[parameter] = item
    if name == "strategy_trace":
        properties["strategy"] = {
            "oneOf": [
                {
                    "const": row["name"],
                    "description": (
                        f"{row['operation']} strategy. Input template: "
                        f"{json.dumps(row['template'], sort_keys=True)}. Worked input: "
                        f"{json.dumps(row['example'], sort_keys=True)}; verified by {row['verified']}."
                    ),
                }
                for row in strategy_contracts
            ]
        }
        properties["input"] = {
            "type": "object",
            "description": "Optional override for the worked input shown with the selected strategy.",
        }
    return {"name": name, "description": description, "inputSchema": {"type": "object", "properties": properties, "additionalProperties": False}}


def registry_tools(root: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    registry = root / "hermes" / "capability_registry.pl"
    try:
        registry_text = registry.read_text(encoding="utf-8")
    except OSError as exc:
        raise ToolCallError(
            f"Registry artifact {REGISTRY_ARTIFACT} is unavailable; run {REGISTRY_REBUILD}",
            kind="worker_failure",
        ) from exc
    for line in registry_text.splitlines():
        match = REGISTRY_ROW.match(line)
        if not match:
            continue
        name, module, role, raw_params, status = match.groups()
        parameters = tuple(re.findall(r"'([^']+)'", raw_params))
        description = (
            f"Hermes registry operation from {module}, classified as {role} ({status}). "
            "Parameter names come from the capability registry; it does not carry parameter types or required/default metadata."
        )
        rows.append(tool(name, description, parameters))
    return rows


def worker_error_kind(worker_type: str) -> str:
    if worker_type.startswith(("missing_", "malformed_", "invalid_")):
        return "malformed_input"
    if worker_type.startswith(("no_", "unknown_", "op_failed", "not_covered")):
        return "not_covered"
    return "worker_failure"


def row_matches_query(query: str, entry: dict[str, str]) -> bool:
    """Match query words without admitting empty or substring-only hits."""
    tokens = re.findall(r"[^\W_]+", query.casefold())
    if not tokens:
        return False
    haystack = " ".join(
        entry[key] for key in ("name", "domain", "description", "citation")
    ).casefold()
    haystack_tokens = set(re.findall(r"[^\W_]+", haystack))
    return all(token in haystack_tokens for token in tokens)


class HermesMCPServer:
    def __init__(self, mode: str, root: Path) -> None:
        self.mode = mode
        self.root = root
        self.worker: PersistentPrologWorker | None = None
        self._strategy_contracts = self._load_strategy_contracts() if mode != "registry" else []
        self._startup_error: ToolCallError | None = None
        try:
            tools = registry_tools(root) if mode == "registry" else [core_tool(*row, self._strategy_contracts) for row in CORE_TOOLS]
        except ToolCallError as exc:
            self._startup_error = exc
            tools = []
        if mode.startswith("bundle:"):
            wanted = set(TOOL_BUNDLES[mode.removeprefix("bundle:")])
            tools = [entry for entry in tools if entry["name"] in wanted]
        self._tools = tools
        self._tool_names = {entry["name"] for entry in self._tools}

    def close(self) -> None:
        if self.worker is not None:
            self.worker.close()
            self.worker = None

    def _worker(self) -> PersistentPrologWorker:
        if self.worker is None:
            # Monitoring exports can take longer than the web request default.
            # MCP is a deliberate, local analysis surface, so retain one worker
            # but give a bounded long-running export room to finish.
            self.worker = PersistentPrologWorker(umedcta_root=self.root, timeout=120.0)
        return self.worker

    def _worker_request(self, op: str, **payload: Any) -> Any:
        try:
            response = self._worker().raw_request({"id": "mcp", "op": op, **payload})
        except PersistentPrologError as exc:
            # A process can exit after a successful cold boot. Drop the dead
            # handle so the next call starts a fresh worker rather than
            # retaining crash state for the rest of the MCP session.
            self.close()
            raise ToolCallError(
                "Hermes worker became unavailable; retry the request.",
                kind="worker_failure",
                extra={"detail": str(exc)},
            ) from exc
        if response.get("ok"):
            return response.get("result")
        worker_error = response.get("error") if isinstance(response.get("error"), dict) else {}
        worker_type = str(worker_error.get("type") or "worker_failure")
        message = str(worker_error.get("message") or "Hermes worker could not complete the request.")
        raise ToolCallError(message, kind=worker_error_kind(worker_type), worker_type=worker_type)

    def _load_strategy_contracts(self) -> list[dict[str, Any]]:
        """Read execution-verified JSON contracts without starting a worker."""
        contracts_file = self.root / "knowledge" / "strategies" / "automaton_input_contracts.pl"
        contracts: list[dict[str, Any]] = []
        for line in contracts_file.read_text(encoding="utf-8").splitlines():
            match = INPUT_CONTRACT_ROW.match(line)
            if not match:
                continue
            operation, name, template_text, example_text, verified = match.groups()
            try:
                template = json.loads(template_text.replace(r'\"', '"'))
                example = json.loads(example_text.replace(r'\"', '"'))
            except json.JSONDecodeError as exc:
                raise ToolCallError(f"Invalid strategy input contract for {name}: {exc}", kind="worker_failure") from exc
            contracts.append({"name": name, "operation": operation, "template": template,
                              "example": example, "verified": verified})
        if not contracts:
            raise ToolCallError("No execution-verified strategy input contracts were found.", kind="worker_failure")
        return sorted(contracts, key=lambda row: (row["operation"], row["name"]))

    def handle(self, request: Any) -> dict[str, Any] | None:
        if not isinstance(request, dict) or request.get("jsonrpc") != "2.0" or not isinstance(request.get("method"), str):
            return error(request.get("id") if isinstance(request, dict) else None, -32600, "Invalid Request")
        request_id = request.get("id")
        method = request["method"]
        params = request.get("params", {})
        if method == "notifications/initialized":
            return None
        if method == "initialize":
            if not isinstance(params, dict):
                return error(request_id, -32602, "initialize params must be an object")
            return result(request_id, {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "hermes-mcp", "version": "0.1.0"},
            })
        if method == "tools/list":
            if self._startup_error is not None:
                return error(request_id, -32000, str(self._startup_error), {"kind": self._startup_error.kind})
            return result(request_id, {"tools": self._tools})
        if method == "tools/call":
            if not isinstance(params, dict) or not isinstance(params.get("name"), str):
                return error(request_id, -32602, "tools/call requires a string name")
            arguments = params.get("arguments", {})
            if not isinstance(arguments, dict):
                return error(request_id, -32602, "tools/call arguments must be an object")
            if params["name"] not in self._tool_names:
                return error(request_id, -32602, f"unknown tool: {params['name']}")
            try:
                value = self.call(params["name"], arguments)
            except ToolCallError as exc:
                data: dict[str, Any] = {"kind": exc.kind}
                if exc.worker_type is not None:
                    data["worker_type"] = exc.worker_type
                data.update(exc.extra)
                return error(request_id, -32000, str(exc), data)
            except PersistentPrologError as exc:
                return error(request_id, -32000, str(exc), {"kind": "worker_failure"})
            except ValueError as exc:
                return error(request_id, -32000, str(exc), {"kind": "malformed_input"})
            except Exception as exc:  # Preserve a valid protocol response on unexpected worker failure.
                return error(request_id, -32000, "Hermes tool failed", {"kind": "worker_failure", "detail": str(exc)})
            return result(request_id, {"content": [{"type": "text", "text": json.dumps(value, ensure_ascii=False, sort_keys=True)}]})
        return error(request_id, -32601, "Method not found")

    def call(self, name: str, arguments: dict[str, Any]) -> Any:
        if self.mode == "registry":
            return self._worker_request(name, **arguments)
        if name == "check_math_claim":
            term = arguments.get("term")
            if not isinstance(term, str) or not term.strip():
                raise ValueError("check_math_claim requires a non-empty term")
            grounded = self._worker_request("ground", query=term)
            claims = grounded.get("math_claims", []) if isinstance(grounded, dict) else []
            if not claims:
                raise ValueError("check_math_claim found no complete explicit mathematical relation; include the stated operands, operation or relation, and claimed result")
            return {"term": term, "checks": claims}
        if name == "resonance_neighbors":
            return self.resonance_neighbors(arguments)
        if name == "misconception_search_rows":
            return self.misconception_search_rows(arguments)
        if name == "monitoring_chart":
            return self.monitoring_chart(arguments)
        if name == "monitoring_chart_detail":
            return self.monitoring_chart_detail(arguments)
        if name == "lesson_deformation_chart":
            return self.lesson_deformation_chart(arguments)
        if name == "lesson_deformation_chart_detail":
            return self.lesson_deformation_chart_detail(arguments)
        worker_op = CORE_TO_WORKER[name]
        payload = dict(arguments)
        value = self._worker_request(worker_op, **payload)
        if name == "strategy_trace" and isinstance(value, dict) and value.get("ok") is False:
            supplied = str(arguments.get("strategy", ""))
            suggestions = difflib.get_close_matches(supplied, [row["name"] for row in self._strategy_contracts], n=5, cutoff=0.25)
            suggested_rows = [row for row in self._strategy_contracts if row["name"] in suggestions]
            suggestion_text = "; ".join(
                f"{row['name']}: template {json.dumps(row['template'], sort_keys=True)}, example {json.dumps(row['example'], sort_keys=True)}"
                for row in suggested_rows
            ) or "no close contracted name"
            raise ToolCallError(
                f"strategy_trace could not run {supplied!r}; contracted alternatives: {suggestion_text}.",
                kind="not_covered", extra={"suggestions": suggestions},
            )
        return value

    @staticmethod
    def _code(arguments: dict[str, Any], tool_name: str) -> str:
        code = arguments.get("code")
        if not isinstance(code, str) or not code.strip():
            raise ToolCallError(f"{tool_name} requires code.", kind="malformed_input")
        return code

    @staticmethod
    def _section_inventory(chart: dict[str, Any], detail_tool: str) -> list[dict[str, str]]:
        return [{"name": key, "detail_tool": detail_tool} for key in chart if key != "lesson_code"]

    def _monitoring_full(self, code: str) -> dict[str, Any]:
        value = self._worker_request("monitoring_chart_export", lesson_code=code)
        if not isinstance(value, dict):
            raise ToolCallError("monitoring_chart returned an invalid chart.", kind="worker_failure")
        return value

    def monitoring_chart(self, arguments: dict[str, Any]) -> dict[str, Any]:
        code = self._code(arguments, "monitoring_chart")
        if "full" in arguments and not isinstance(arguments["full"], bool):
            raise ToolCallError("monitoring_chart full must be boolean.", kind="malformed_input")
        chart = self._monitoring_full(code)
        if arguments.get("full"):
            return chart
        strategies = chart.get("anticipated_strategies", [])
        names = [row.get("kind", row.get("strategy", row.get("name"))) for row in strategies if isinstance(row, dict)]
        deformation_chart = chart.get("deformation_chart")
        deformation_standards = deformation_chart.get("standards", []) if isinstance(deformation_chart, dict) else []
        return {
            "lesson_identity": {"lesson_code": chart.get("lesson_code", code), "lesson": chart.get("lesson", chart.get("title"))},
            "standards": chart.get("standards", chart.get("addressing_standards", deformation_standards)),
            "strategy_names": [name for name in names if isinstance(name, str)],
            "task_instance_count": len(chart.get("registered_task_instances", [])),
            "resonance_row_count": len(chart.get("resonant_misconceptions", [])),
            "sections": self._section_inventory(chart, "monitoring_chart_detail"),
        }

    def monitoring_chart_detail(self, arguments: dict[str, Any]) -> dict[str, Any]:
        code = self._code(arguments, "monitoring_chart_detail")
        section = arguments.get("section")
        if not isinstance(section, str) or not section:
            raise ToolCallError("monitoring_chart_detail requires section.", kind="malformed_input")
        chart = self._monitoring_full(code)
        if section not in chart:
            raise ToolCallError(f"monitoring_chart has no section named {section!r}.", kind="not_covered", extra={"sections": list(chart)})
        return {"lesson_code": chart.get("lesson_code", code), "section": section, "data": chart[section]}

    @staticmethod
    def _deformation_items(value: Any, path: str = "$") -> list[dict[str, Any]]:
        """Assign stable local IDs to renderer scenes and their frames."""
        items: list[dict[str, Any]] = []
        if isinstance(value, dict):
            frames = value.get("frames")
            if isinstance(frames, list):
                items.append({"id": path, "kind": "scene"})
                for index, frame in enumerate(frames):
                    items.append({"id": f"{path}.frames[{index}]", "kind": "frame"})
            for key, child in value.items():
                items.extend(HermesMCPServer._deformation_items(child, f"{path}.{key}"))
        elif isinstance(value, list):
            for index, child in enumerate(value):
                items.extend(HermesMCPServer._deformation_items(child, f"{path}[{index}]"))
        return items

    @staticmethod
    def _find_deformation_item(value: Any, identifier: str) -> Any | None:
        for item in HermesMCPServer._deformation_items(value):
            if item["id"] == identifier:
                current = value
                for key, index in re.findall(r"\.([A-Za-z_][A-Za-z0-9_]*)|\[(\d+)\]", identifier.removeprefix("$")):
                    current = current[key] if key else current[int(index)]
                return current
        return None

    def _deformation_full(self, code: str) -> dict[str, Any]:
        value = self._worker_request("lesson_deformation_chart", code=code)
        if not isinstance(value, dict):
            raise ToolCallError("lesson_deformation_chart returned an invalid chart.", kind="worker_failure")
        return value

    def lesson_deformation_chart(self, arguments: dict[str, Any]) -> dict[str, Any]:
        code = self._code(arguments, "lesson_deformation_chart")
        if "full" in arguments and not isinstance(arguments["full"], bool):
            raise ToolCallError("lesson_deformation_chart full must be boolean.", kind="malformed_input")
        chart = self._deformation_full(code)
        if arguments.get("full"):
            return chart
        return {
            "lesson_code": chart.get("lesson_code", chart.get("code", code)),
            "title": chart.get("title"),
            "standards": chart.get("standards", []),
            "inventory": [
                {**row, "detail_tool": "lesson_deformation_chart_detail"}
                for row in self._deformation_items(chart)
            ],
        }

    def lesson_deformation_chart_detail(self, arguments: dict[str, Any]) -> dict[str, Any]:
        code = self._code(arguments, "lesson_deformation_chart_detail")
        identifier = arguments.get("id")
        if not isinstance(identifier, str) or not identifier:
            raise ToolCallError("lesson_deformation_chart_detail requires id.", kind="malformed_input")
        chart = self._deformation_full(code)
        item = self._find_deformation_item(chart, identifier)
        if item is None:
            raise ToolCallError(f"lesson_deformation_chart has no scene or frame id {identifier!r}.", kind="not_covered")
        return {"lesson_code": chart.get("lesson_code", chart.get("code", code)), "id": identifier, "data": item}

    def resonance_neighbors(self, arguments: dict[str, Any]) -> dict[str, Any]:
        name = arguments.get("name")
        if not isinstance(name, str) or not name.strip():
            raise ValueError("resonance_neighbors requires a stored misconception name")
        try:
            limit = int(arguments.get("k", 5))
        except (TypeError, ValueError) as exc:
            raise ValueError("resonance_neighbors k must be an integer") from exc
        if not 1 <= limit <= 32:
            raise ValueError("resonance_neighbors k must be between 1 and 32")
        index = load_index(self.root)
        if index is None:
            raise ToolCallError(
                f"Offline artifacts {', '.join(EMBEDDING_ARTIFACTS)} are unavailable or invalid; run {EMBEDDING_REBUILD}",
                kind="worker_failure",
            )
        source_index = next((i for i, entry in enumerate(index.entries) if entry["name"] == name), None)
        if source_index is None:
            raise ValueError(f"no stored misconception vector named {name!r}")
        matches = cosine_matches(index, list(index.vectors[source_index]), limit=min(limit + 1, len(index.entries)))
        neighbors = [row for row in matches if row["name"] != name][:limit]
        return {"retrieval": "stored_vector", "query_name": name, "model": index.model, "neighbors": neighbors}

    def misconception_search_rows(self, arguments: dict[str, Any]) -> dict[str, Any]:
        query = arguments.get("query")
        if not isinstance(query, str) or not query.strip():
            raise ToolCallError("misconception_search_rows requires a non-empty query.", kind="malformed_input")
        try:
            limit = int(arguments.get("k", 8))
        except (TypeError, ValueError) as exc:
            raise ToolCallError("misconception_search_rows k must be an integer.", kind="malformed_input") from exc
        if not 1 <= limit <= 32:
            raise ToolCallError("misconception_search_rows k must be between 1 and 32.", kind="malformed_input")
        index = load_index(self.root)
        if index is None:
            raise ToolCallError(
                f"Offline artifacts {', '.join(EMBEDDING_ARTIFACTS)} are unavailable or invalid; run {EMBEDDING_REBUILD}",
                kind="worker_failure",
            )
        rows = [entry for entry in index.entries if row_matches_query(query, entry)]
        rows.sort(key=lambda entry: (entry["domain"], entry["name"]))
        return {"retrieval": "offline_row_search", "query": query, "count": len(rows), "rows": list(rows[:limit])}


def serve(mode: str) -> int:
    server = HermesMCPServer(mode, resolve_hermes_root())
    try:
        for raw_line in sys.stdin:
            try:
                request = json.loads(raw_line)
            except json.JSONDecodeError as exc:
                response = error(None, -32700, "Parse error", str(exc))
            else:
                response = server.handle(request)
            if response is not None:
                sys.stdout.write(json.dumps(response, ensure_ascii=False) + "\n")
                sys.stdout.flush()
    finally:
        server.close()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Hermes stdio MCP server")
    parser.add_argument("--mode", choices=("core", "registry", *(f"bundle:{name}" for name in TOOL_BUNDLES)), default="core")
    return serve(parser.parse_args().mode)


if __name__ == "__main__":
    raise SystemExit(main())
