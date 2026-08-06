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
SUPPORTED_PROTOCOL_VERSIONS = {"2025-03-26", "2025-06-18"}
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
FULL_GRAPH_ARTIFACT = "docs/research/assets/automata/full_graph.json"

CORE_TO_WORKER = {
    "prolog_query": "prolog_query",
    "monitoring_chart": "monitoring_chart_export",
    "lesson_deformation_chart": "lesson_deformation_chart",
    "deontic_scorecard": "deontic_scorecard",
    "deontic_consequences": "deontic_consequences",
    "deontic_up_level": "deontic_up_level",
    "commitment_match": "commitment_match",
    "strategy_trace": "strategy_trace",
    "strategy_recognize": "strategy_recognize",
    "incompatibility_contexts": "incompatibility_contexts",
    "lesson_enactment_list": "lesson_enactment_list",
    "lesson_enactment_run": "lesson_enactment_run",
    "diagnose_error": "diagnose_error",
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
    ("lesson_deformation_chart", "Return a compact deformation-chart inventory for an IM lesson code. Read provenance before reading the chart: of the 78 lesson codes this tool serves, 3 take their hosts and fractions from a teacher guide and a fourth, a division lesson, takes compiled tasks from its guide (all 4 report provenance hand_authored); the other 74 take one fixed default set of circle/rectangle/bar and 1/2, 1/3, 1/4, 1/6, 1/8 (default_fill), which reports nothing about what that lesson asks children to model. A lesson is charted when its coverage row carries a unit-fraction partition or iteration strategy, or when it is a grade 6 unit 4 fraction-division lesson whose guide attests a tape-diagram scene; neither arm decides anything about the fill. Every reply carries provenance and provenance_note. No coverage number may cite this chart. Use lesson_deformation_chart_detail for one scene or frame; set full to true only for renderer-oriented consumers. Expected time: a few seconds after worker startup.", ("code", "full")),
    ("lesson_deformation_chart_detail", "Return one identified scene or frame from a deformation chart, with the chart's provenance and provenance_note attached. Call lesson_deformation_chart first to obtain its inventory. A default_fill scene is drawn on the fixed default fraction set, not on the lesson's own quantities. Expected time: a few seconds.", ("code", "id")),
    ("check_math_claim", "Parse and check an explicit mathematical claim in symbolic or ordinary classroom language. The reader covers registered arithmetic, fraction, comparison, and same-unit total forms; it preserves modality, polarity, reports, questions, and quotation separately and abstains on implied operations.", ("term",)),
    ("deontic_scorecard", "Return the ephemeral scorecard for stated commitment and entitlement terms.", ("agent", "commitments", "entitlements")),
    ("deontic_consequences", "Return consequences licensed by stated commitment terms.", ("agent", "commitments")),
    ("deontic_up_level", "Return named up-level questions for unresolved commitment gaps.", ("agent", "commitments")),
    ("commitment_match", "Match reading content through the strategy/misconception and literature-canonical vocabularies. Each match labels its matcher; it abstains when neither complete-name gate admits a term.", ("content",)),
    ("strategy_recognize", "Align ordinary classroom language to 114 execution-observed strategy traces. Confidence is unshared surface evidence times trace coverage, capped at one. A partial_trace requires at least two steps in trace order from two distinct surfaces and at least one full step of unshared evidence. Results are candidates rather than learner diagnoses; an empty list is an abstention.", ("content",)),
    ("strategy_trace", "Run one registered strategy with an optional input object. The schema lists the registry-backed names, operation pairing, and worked inputs. Expected time: usually under two seconds after worker startup.", ("strategy", "input")),
    ("lesson_enactment_list", "List every lesson with an executable enactment, all distinct forms declared for each lesson, and named refusals with the machine each would need. The first enactment call lazily loads five lanes and may take about eleven seconds in this checkout.", ()),
    ("lesson_enactment_run", "Run every distinct enactment form declared for one lesson and return each result through the strategy-trace response shape. Each trace carries its verdict, input provenance, and what_it_does_not_claim sentence. A lesson with no declared enactment returns a not-covered error; call lesson_enactment_list to inspect named refusals. The first enactment call may take about eleven seconds.", ("lesson",)),
    ("diagnose_error", "Return encoded misconception diagnoses whose runnable rule reproduces got for the stated domain and input. This names matching encoded misconceptions; it does not assess every possible error, and an empty result is an abstention rather than a verdict that the work is correct.", ("domain", "input", "got")),
    ("misconception_lookup", "Filter encoded misconceptions by optional domain, exact description slug, or source db_row identity. source narrows only to db_row(N); a supplied value that does not parse as a ground filter term is refused. Use misconception_search_rows for citation or author search. Results are paged; use limit and offset to move through the matched rows.", ("domain", "description", "source", "limit", "offset")),
    ("misconception_search_rows", "Search stored misconception rows offline by whole query words in their name, domain, description, or citation. All query words must be present. Returned rows carry a db_row identity for resonance_neighbors.", ("query", "k")),
    ("resonance_neighbors", "Find neighbors of one stored misconception vector. Prefer the returned db_row identity; name remains a display label and is accepted only when unambiguous. This uses only stored row vectors; it never makes a query-embedding network call.", ("db_row", "name", "k")),
    ("incompatibility_entailments", "Check one proposed replacement/replaced pair against the live finite incompatibility profiles. It reports entailment, equivalence when both directions hold, or an honest unresolved status, with its witnessing contexts. This is earned over a thin corpus and is distinct from the strict generated register; see docs/research/2026-07-28-why-entailment-does-not-move.md.", ("replacement", "replaced")),
    ("incompatibility_profile", "Return finite sets of jointly incompatible contents containing one content term, with arity 2 or more, classification kind, partners, and provenance.", ("content",)),
    ("incompatibility_contexts", "Enumerate the reviewed a-fortiori context nestings: strict input-class inclusions (narrow, broad, status, warrant) with native-triple counts at each end. These rows generate the strict register's context-earned entailments; basis prose and automaton status live in formal/incompatibility/a_fortiori_context_nestings.json. Optional context filters to rows touching one atom and reports not_covered when the atom touches none. This bounded reviewed inventory has no pagination; add limit and offset if it grows past about 100 rows. Distinct from incompatibility_entailments, which checks one replacement/replaced pair against live finite profiles.", ("context",)),
)

# These public core tools are intentionally outside Task 240's frozen branch
# catalog. They are available to MCP callers without changing the branch-agent
# carving.
CORE_STANDALONE_TOOLS = (
    ("prolog_query", "Run one caller-supplied Prolog goal against the loaded knowledge base after SWI's sandbox accepts its complete call graph. Calls are read-only, capped at 100 solutions, and limited to 2 seconds. Call with goal to query. Call without goal to list loaded knowledge predicates; narrow that listing with a name substring, a knowledge-relative file substring, or an exact arity, then use a module-qualified predicate from the result.", ("goal", "name", "file", "arity")),
    ("graph_overview", "Return the full computational graph's scope, authored level ladder, counts, and per-family inventory. The level ladder is authored rather than derived from the transition tables. This reads the shipped JSON artifact without starting the Prolog worker.", ()),
    ("graph_machine", "Return one machine's states, transitions, and shared canonical-action summary from the full computational graph. A borrow records a shared canonical action name; it does not assert that two machines, transitions, or mathematical practices are equivalent.", ("family", "kind")),
    ("graph_borrows", "Return borrow pairs for one canonical action or one family-and-kind machine. A borrow records only that transition edges share a canonical action name. It does not assert equivalence, prerequisite order, or a learner relation. Results are paged; cross_family_only restricts pairs before paging.", ("canonical_action", "family", "kind", "cross_family_only", "limit", "offset")),
)


class ToolCallError(ValueError):
    """A user-facing tool failure with an MCP error category."""

    def __init__(self, message: str, *, kind: str, worker_type: str | None = None, extra: dict[str, Any] | None = None) -> None:
        super().__init__(message)
        self.kind = kind
        self.worker_type = worker_type
        self.extra = extra or {}


class InvalidArguments(ValueError):
    """A JSON-RPC invalid-params error that names the rejected argument."""


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


def tool_metadata(name: str, *, read_only: bool, idempotent: bool) -> dict[str, Any]:
    return {
        "title": name.replace("_", " ").title(),
        "annotations": {"readOnlyHint": read_only, "idempotentHint": idempotent},
    }


def output_schema(name: str) -> dict[str, Any] | None:
    """Stable result contracts only; renderer-facing payloads remain open-ended."""
    schemas: dict[str, dict[str, Any]] = {
        "resonance_neighbors": {
            "type": "object",
            "required": ["retrieval", "query_name", "model", "neighbors"],
            "properties": {"retrieval": {"type": "string"}, "query_name": {"type": "string"}, "model": {"type": "string"}, "neighbors": {"type": "array"}},
        },
        "misconception_search_rows": {
            "type": "object",
            "required": ["retrieval", "query", "count", "rows"],
            "properties": {"retrieval": {"type": "string"}, "query": {"type": "string"}, "count": {"type": "integer"}, "rows": {"type": "array"}},
        },
        "incompatibility_entailments": {
            "type": "object",
            "required": ["relation", "contents", "status", "witnessing_contexts"],
            "properties": {"relation": {"type": "string"}, "contents": {"type": "object"}, "status": {"type": "string"}, "witnessing_contexts": {"type": "array", "items": {"type": "string"}}},
        },
        "incompatibility_profile": {
            "type": "object",
            "required": ["content", "status", "minimal_sets", "partners"],
            "properties": {"content": {"type": "string"}, "status": {"type": "string"}, "minimal_sets": {"type": "array"}, "partners": {"type": "array", "items": {"type": "string"}}},
        },
        "incompatibility_contexts": {
            "type": "object",
            "required": ["count", "context_filter", "nestings", "register_note"],
            "properties": {"count": {"type": "integer"}, "context_filter": {"type": "string"}, "nestings": {"type": "array"}, "register_note": {"type": "string"}},
        },
        "prolog_query": {
            "type": "object",
            "required": ["kind", "status"],
            "properties": {"kind": {"type": "string"}, "status": {"type": "string"}},
        },
        "graph_overview": {
            "type": "object",
            "required": ["meta", "counts", "families"],
            "properties": {
                "meta": {"type": "object"},
                "counts": {
                    "type": "object",
                    "required": ["validity_counts", "review_status_counts", "reviewed_unreviewed_counts"],
                    "properties": {
                        "validity_counts": {"type": "object"},
                        "review_status_counts": {"type": "object"},
                        "reviewed_unreviewed_counts": {"type": "object"},
                    },
                },
                "families": {"type": "array"},
            },
        },
        "graph_machine": {
            "type": "object",
            "required": ["machine", "family", "kind", "states", "edges", "borrow_summary"],
            "properties": {"machine": {"type": "string"}, "family": {"type": "string"}, "kind": {"type": "string"}, "states": {"type": "array"}, "edges": {"type": "array", "items": {"type": "object", "required": ["validity_modes", "review_status"], "properties": {"validity_modes": {"type": "array", "items": {"type": "string"}}, "review_status": {"type": ["string", "null"]}}}}, "borrow_summary": {"type": "object"}},
        },
        "graph_borrows": {
            "type": "object",
            "required": ["query", "assertion", "carriers", "totals", "page", "pairs"],
            "properties": {"query": {"type": "object"}, "assertion": {"type": "string"}, "carriers": {"type": "array", "items": {"type": "object", "required": ["validity_modes"], "properties": {"validity_modes": {"type": "array", "items": {"type": "string"}}}}}, "totals": {"type": "object"}, "page": {"type": "object"}, "pairs": {"type": "array"}},
        },
    }
    return schemas.get(name)


def tool(name: str, description: str, parameters: tuple[str, ...] | list[str]) -> dict[str, Any]:
    # The generated registry records web-route exposure, not state effects.
    # Registry-mode annotations therefore make no safety promise. A false hint
    # is conservative for read-only ops and honest for state-mutating ops.
    entry = {"name": name, "description": description, "inputSchema": schema(parameters), **tool_metadata(name, read_only=False, idempotent=False)}
    if stable := output_schema(name):
        entry["outputSchema"] = stable
    return entry


def core_tool(name: str, description: str, parameters: tuple[str, ...], strategy_contracts: list[dict[str, Any]]) -> dict[str, Any]:
    """Hand-authored tools can state the few JSON shapes their worker accepts."""
    kinds = {"commitments": "array", "entitlements": "array", "input": "object", "k": "integer", "limit": "integer", "offset": "integer", "full": "boolean", "arity": "integer", "cross_family_only": "boolean"}
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
    elif name == "prolog_query":
        properties = {
            "goal": {"type": "string", "minLength": 1, "description": "One Prolog goal. Use module qualification from the generated predicate listing when the predicate is not imported into user."},
            "name": {"type": "string", "description": "Case-insensitive predicate-name substring for a listing call."},
            "file": {"type": "string", "description": "Case-insensitive knowledge-relative source-file substring for a listing call."},
            "arity": {"type": "integer", "minimum": 0, "description": "Exact predicate arity for a listing call."},
        }
    elif name == "graph_machine":
        properties = {
            "family": {"type": "string", "minLength": 1, "description": "Exact machine family from graph_overview."},
            "kind": {"type": "string", "minLength": 1, "description": "Exact machine kind within the family."},
        }
    elif name == "graph_borrows":
        properties = {
            "canonical_action": {"type": "string", "minLength": 1, "description": "Exact canonical action name. Do not combine this with family or kind."},
            "family": {"type": "string", "minLength": 1, "description": "Exact machine family; supply kind with it. Do not combine it with canonical_action."},
            "kind": {"type": "string", "minLength": 1, "description": "Exact machine kind; supply family with it. Do not combine it with canonical_action."},
            "cross_family_only": {"type": "boolean", "description": "When true, retain only pairs whose machines have different families."},
            "limit": {"type": "integer", "minimum": 1, "maximum": 100, "description": "Pair rows to return; defaults to 25 and cannot exceed 100."},
            "offset": {"type": "integer", "minimum": 0, "description": "Zero-based pair offset; defaults to 0."},
        }
    required: list[str] = []
    if name == "diagnose_error":
        required = ["domain", "input", "got"]
        properties["domain"] = {"type": "string", "minLength": 1, "description": "Registered misconception domain, such as fraction."}
        properties["input"] = {"type": "string", "minLength": 1, "description": "Problem input in the worker's term-form text."}
        properties["got"] = {"type": "string", "minLength": 1, "description": "Student answer in the worker's term-form text."}
    elif name == "lesson_enactment_run":
        required = ["lesson"]
        properties["lesson"] = {"type": "string", "minLength": 1, "description": "Exact IM lesson code returned by lesson_enactment_list."}
    elif name == "graph_machine":
        required = ["family", "kind"]
    input_schema: dict[str, Any] = {"type": "object", "properties": properties, "additionalProperties": False}
    if required:
        input_schema["required"] = required
    if name == "graph_borrows":
        input_schema["oneOf"] = [
            {"required": ["canonical_action"]},
            {"required": ["family", "kind"]},
        ]
    entry = {"name": name, "description": description, "inputSchema": input_schema, **tool_metadata(name, read_only=True, idempotent=True)}
    if stable := output_schema(name):
        entry["outputSchema"] = stable
    return entry


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
        if status in {"orphan_module", "lazy_reachable"}:
            continue
        parameters = tuple(re.findall(r"'([^']+)'", raw_params))
        description = (
            f"Hermes worker operation from {module}, classified as {role}. "
            f"Its web-exposure status is {status}; this status does not determine worker callability. "
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
        self._full_graph: dict[str, Any] | None = None
        self._strategy_contracts = self._load_strategy_contracts() if mode != "registry" else []
        self._startup_error: ToolCallError | None = None
        try:
            tools = registry_tools(root) if mode == "registry" else [core_tool(*row, self._strategy_contracts) for row in CORE_TOOLS]
            public_tools = list(tools)
            if mode == "core":
                public_tools.extend(core_tool(*row, self._strategy_contracts) for row in CORE_STANDALONE_TOOLS)
        except ToolCallError as exc:
            self._startup_error = exc
            tools = []
            public_tools = []
        if mode.startswith("bundle:"):
            wanted = set(TOOL_BUNDLES[mode.removeprefix("bundle:")])
            tools = [entry for entry in tools if entry["name"] in wanted]
            public_tools = list(tools)
        # _tools remains Task 240's carved catalog for branch_agents.py. MCP
        # discovery and calls use the complete public core surface.
        self._tools = tools
        self._public_tools = public_tools
        self._tool_names = {entry["name"] for entry in self._public_tools}

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
        for line_number, line in enumerate(
            contracts_file.read_text(encoding="utf-8").splitlines(), start=1
        ):
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
                              "example": example, "verified": verified,
                              "source": f"knowledge/strategies/automaton_input_contracts.pl:{line_number}"})
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
                "protocolVersion": params.get("protocolVersion") if params.get("protocolVersion") in SUPPORTED_PROTOCOL_VERSIONS else PROTOCOL_VERSION,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "hermes-mcp", "version": "0.1.0"},
            })
        if method == "tools/list":
            if self._startup_error is not None:
                return error(request_id, -32000, str(self._startup_error), {"kind": self._startup_error.kind})
            return result(request_id, {"tools": self._public_tools})
        if method == "tools/call":
            if not isinstance(params, dict) or not isinstance(params.get("name"), str):
                return error(request_id, -32602, "tools/call requires a string name")
            arguments = params.get("arguments", {})
            if not isinstance(arguments, dict):
                return error(request_id, -32602, "tools/call arguments must be an object")
            if params["name"] not in self._tool_names:
                return error(request_id, -32602, f"unknown tool: {params['name']}")
            try:
                self.validate_arguments(params["name"], arguments)
                value = self.call(params["name"], arguments)
            except InvalidArguments as exc:
                return error(request_id, -32602, str(exc))
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
            structured_content = value if isinstance(value, dict) else {"items": value}
            return result(request_id, {"content": [{"type": "text", "text": json.dumps(value, ensure_ascii=False, sort_keys=True)}], "structuredContent": structured_content})
        return error(request_id, -32601, "Method not found")

    def validate_arguments(self, name: str, arguments: dict[str, Any]) -> None:
        """Enforce the declared input schema before any worker request."""
        entry = next(tool for tool in self._public_tools if tool["name"] == name)
        input_schema = entry["inputSchema"]
        properties = input_schema.get("properties", {})
        if input_schema.get("additionalProperties") is False:
            for key in arguments:
                if key not in properties:
                    raise InvalidArguments(f"invalid argument key: {key}")
        for key in input_schema.get("required", []):
            if key not in arguments:
                raise InvalidArguments(f"missing required argument: {key}")
        for key, value in arguments.items():
            property_schema = properties[key]
            kind = property_schema.get("type")
            if kind == "integer":
                normalized = self._coerce_integer(value)
                if normalized is None:
                    raise InvalidArguments(f"invalid argument {key}: expected integer")
                arguments[key] = normalized
            elif kind is not None and not self._matches_json_type(value, kind):
                raise InvalidArguments(f"invalid argument {key}: expected {kind}")
            if kind == "string" and len(value) < property_schema.get("minLength", 0):
                raise InvalidArguments(f"invalid argument {key}: expected non-empty string")
            if kind == "integer" and value < property_schema.get("minimum", value):
                raise InvalidArguments(f"invalid argument {key}: below minimum")
            item_kind = property_schema.get("items", {}).get("type")
            if kind == "array" and item_kind is not None:
                for item in value:
                    if not self._matches_json_type(item, item_kind):
                        raise InvalidArguments(f"invalid argument {key}: expected {item_kind} items")

    @staticmethod
    def _coerce_integer(value: Any) -> int | None:
        """Preserve historical numeric-string and integral-float acceptance."""
        if isinstance(value, int) and not isinstance(value, bool):
            return value
        if isinstance(value, float) and value.is_integer():
            return int(value)
        if isinstance(value, str):
            try:
                return int(value)
            except ValueError:
                return None
        return None

    @staticmethod
    def _matches_json_type(value: Any, kind: str) -> bool:
        if kind == "string":
            return isinstance(value, str)
        if kind == "array":
            return isinstance(value, list)
        if kind == "object":
            return isinstance(value, dict)
        if kind == "boolean":
            return isinstance(value, bool)
        if kind == "integer":
            return isinstance(value, int) and not isinstance(value, bool)
        if kind == "number":
            return isinstance(value, (int, float)) and not isinstance(value, bool)
        return True

    def call(self, name: str, arguments: dict[str, Any]) -> Any:
        if self.mode == "registry":
            return self._worker_request(name, **arguments)
        if name == "graph_overview":
            return self.graph_overview()
        if name == "graph_machine":
            return self.graph_machine(arguments)
        if name == "graph_borrows":
            return self.graph_borrows(arguments)
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
        if name == "incompatibility_profile":
            return self.incompatibility_profile(arguments)
        if name == "incompatibility_entailments":
            return self.incompatibility_entailments(arguments)
        if name == "misconception_lookup":
            return self.misconception_lookup(arguments)
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

    def _load_full_graph(self) -> dict[str, Any]:
        """Load the shipped graph artifact once without starting Prolog."""
        if self._full_graph is not None:
            return self._full_graph
        graph_file = self.root / FULL_GRAPH_ARTIFACT
        try:
            value = json.loads(graph_file.read_text(encoding="utf-8"))
        except FileNotFoundError as exc:
            raise ToolCallError(
                f"Full graph artifact {FULL_GRAPH_ARTIFACT} is missing.",
                kind="worker_failure",
            ) from exc
        except (OSError, json.JSONDecodeError) as exc:
            raise ToolCallError(
                f"Full graph artifact {FULL_GRAPH_ARTIFACT} is unavailable or invalid.",
                kind="worker_failure",
            ) from exc
        if not isinstance(value, dict):
            raise ToolCallError(
                f"Full graph artifact {FULL_GRAPH_ARTIFACT} is invalid.",
                kind="worker_failure",
            )
        self._full_graph = value
        return value

    @staticmethod
    def _graph_rows(graph: dict[str, Any], name: str) -> list[dict[str, Any]]:
        rows = graph.get(name)
        if not isinstance(rows, list) or not all(isinstance(row, dict) for row in rows):
            raise ToolCallError(
                f"Full graph artifact {FULL_GRAPH_ARTIFACT} has an invalid {name} inventory.",
                kind="worker_failure",
            )
        return rows

    def graph_overview(self) -> dict[str, Any]:
        graph = self._load_full_graph()
        meta = graph.get("meta")
        if not isinstance(meta, dict) or not isinstance(meta.get("counts"), dict):
            raise ToolCallError(
                f"Full graph artifact {FULL_GRAPH_ARTIFACT} has invalid meta counts.",
                kind="worker_failure",
            )
        nodes = self._graph_rows(graph, "nodes")
        family_machines: dict[str, set[str]] = {}
        family_states: dict[str, int] = {}
        family_levels: dict[str, set[int]] = {}
        for node in nodes:
            family = node.get("family")
            kind = node.get("kind")
            level = node.get("level")
            if not isinstance(family, str) or not isinstance(kind, str) or not isinstance(level, int):
                raise ToolCallError(
                    f"Full graph artifact {FULL_GRAPH_ARTIFACT} has an invalid node identity.",
                    kind="worker_failure",
                )
            family_machines.setdefault(family, set()).add(kind)
            family_states[family] = family_states.get(family, 0) + 1
            family_levels.setdefault(family, set()).add(level)
        families: list[dict[str, Any]] = []
        for family in family_machines:
            levels = family_levels[family]
            if len(levels) != 1:
                raise ToolCallError(
                    f"Full graph artifact {FULL_GRAPH_ARTIFACT} assigns multiple levels to family {family}.",
                    kind="worker_failure",
                )
            families.append({
                "family": family,
                "level": next(iter(levels)),
                "machine_count": len(family_machines[family]),
                "state_count": family_states[family],
            })
        families.sort(key=lambda row: (row["level"], row["family"]))
        counts = meta["counts"]
        return {
            "meta": {
                "scope": meta.get("scope"),
                "level_ladder": meta.get("level_ladder"),
                "level_note": meta.get("level_note"),
            },
            "counts": {
                "machines": counts.get("machines"),
                "nodes": counts.get("nodes"),
                "edges": counts.get("edges"),
                "borrow_actions": counts.get("borrows"),
                "borrow_pairs": counts.get("borrow_pairs"),
                "cross_family_pairs": counts.get("cross_family_borrow_pairs"),
                "validity_counts": counts.get("deforming_edges_by_validity"),
                "review_status_counts": counts.get("deforming_edges_by_review_status"),
                "reviewed_unreviewed_counts": counts.get("deforming_edges_by_review_state"),
            },
            "families": families,
        }

    def graph_machine(self, arguments: dict[str, Any]) -> dict[str, Any]:
        family = arguments.get("family")
        kind = arguments.get("kind")
        if not isinstance(family, str) or not family.strip() or not isinstance(kind, str) or not kind.strip():
            raise ToolCallError("graph_machine requires non-empty family and kind strings.", kind="malformed_input")
        machine = f"{family}/{kind}"
        graph = self._load_full_graph()
        nodes = [
            node for node in self._graph_rows(graph, "nodes")
            if node.get("family") == family and node.get("kind") == kind
        ]
        if not nodes:
            raise ToolCallError(f"Full graph has no machine named {machine!r}.", kind="not_covered")
        nodes.sort(key=lambda node: (node.get("formal_index", 0), str(node.get("state", ""))))
        node_states = {
            node.get("id"): node.get("state")
            for node in nodes
            if isinstance(node.get("id"), str)
        }
        edges = [edge for edge in self._graph_rows(graph, "edges") if edge.get("machine") == machine]
        edges.sort(key=lambda edge: str(edge.get("id", "")))
        machine_edge_ids = {edge.get("id") for edge in edges}
        borrow_actions: list[dict[str, Any]] = []
        for borrow in self._graph_rows(graph, "borrows"):
            pairs = [
                pair for pair in borrow.get("pairs", [])
                if isinstance(pair, dict) and machine in pair.get("machines", [])
            ]
            if not pairs:
                continue
            other_machines = sorted({
                other
                for pair in pairs
                for other in pair.get("machines", [])
                if isinstance(other, str) and other != machine
            })
            cross_family_machines = sorted({
                other
                for pair in pairs if pair.get("cross_family") is True
                for other in pair.get("machines", [])
                if isinstance(other, str) and other != machine
            })
            borrow_actions.append({
                "canonical_action": borrow.get("canonical_action"),
                "machine_edge_ids": sorted(
                    edge_id for edge_id in borrow.get("edge_ids", []) if edge_id in machine_edge_ids
                ),
                "other_machine_count": len(other_machines),
                "cross_family_machine_count": len(cross_family_machines),
            })
        borrow_actions.sort(key=lambda row: str(row["canonical_action"]))
        return {
            "machine": machine,
            "family": family,
            "kind": kind,
            "level": nodes[0].get("level"),
            "states": [
                {
                    "id": node.get("id"),
                    "state": node.get("state"),
                    "formal_index": node.get("formal_index"),
                    "start": node.get("start"),
                    "accepting": node.get("accepting"),
                    "level": node.get("level"),
                }
                for node in nodes
            ],
            "edges": [
                {
                    "id": edge.get("id"),
                    "from": edge.get("from"),
                    "from_state": node_states.get(edge.get("from")),
                    "to": edge.get("to"),
                    "to_state": node_states.get(edge.get("to")),
                    "local_action": edge.get("local_action"),
                    "canonical_action": edge.get("canonical_action"),
                    "stance": edge.get("stance"),
                    "validity_modes": edge.get("validity_modes", []),
                    "review_status": edge.get("review_status"),
                    "provenance_kinds": edge.get("provenance_kinds"),
                }
                for edge in edges
            ],
            "borrow_summary": {
                "assertion": "A borrow records a shared canonical action name and does not assert equivalence between machines or transitions.",
                "shared_canonical_action_count": len(borrow_actions),
                "actions": borrow_actions,
            },
        }

    def graph_borrows(self, arguments: dict[str, Any]) -> dict[str, Any]:
        canonical_action = arguments.get("canonical_action")
        family = arguments.get("family")
        kind = arguments.get("kind")
        has_action = canonical_action is not None
        has_machine_part = family is not None or kind is not None
        if has_action == has_machine_part:
            raise ToolCallError(
                "graph_borrows requires either canonical_action or family with kind.",
                kind="malformed_input",
            )
        if has_action:
            if not isinstance(canonical_action, str) or not canonical_action.strip():
                raise ToolCallError("graph_borrows canonical_action must be a non-empty string.", kind="malformed_input")
            machine = None
            query = {"canonical_action": canonical_action}
        else:
            if not isinstance(family, str) or not family.strip() or not isinstance(kind, str) or not kind.strip():
                raise ToolCallError("graph_borrows requires non-empty family and kind strings.", kind="malformed_input")
            machine = f"{family}/{kind}"
            query = {"family": family, "kind": kind, "machine": machine}
        cross_family_only = arguments.get("cross_family_only", False)
        if not isinstance(cross_family_only, bool):
            raise ToolCallError("graph_borrows cross_family_only must be boolean.", kind="malformed_input")
        limit = arguments.get("limit", 25)
        offset = arguments.get("offset", 0)
        if not isinstance(limit, int) or isinstance(limit, bool) or not 1 <= limit <= 100:
            raise ToolCallError("graph_borrows limit must be an integer between 1 and 100.", kind="malformed_input")
        if not isinstance(offset, int) or isinstance(offset, bool) or offset < 0:
            raise ToolCallError("graph_borrows offset must be a non-negative integer.", kind="malformed_input")

        graph = self._load_full_graph()
        edges = self._graph_rows(graph, "edges")
        if canonical_action is not None:
            action_edges = [edge for edge in edges if edge.get("canonical_action") == canonical_action]
            if not action_edges:
                raise ToolCallError(f"Full graph has no canonical action named {canonical_action!r}.", kind="not_covered")
        else:
            action_edges = [edge for edge in edges if edge.get("machine") == machine]
            if not action_edges:
                raise ToolCallError(f"Full graph has no machine named {machine!r}.", kind="not_covered")

        pairs: list[dict[str, Any]] = []
        for borrow in self._graph_rows(graph, "borrows"):
            action = borrow.get("canonical_action")
            if canonical_action is not None and action != canonical_action:
                continue
            for pair in borrow.get("pairs", []):
                if not isinstance(pair, dict) or (machine is not None and machine not in pair.get("machines", [])):
                    continue
                machines = pair.get("machines", [])
                edge_groups = pair.get("edge_ids", [])
                pairs.append({
                    "canonical_action": action,
                    "machines": [
                        {"machine": machine_name, "edge_ids": edge_groups[index] if index < len(edge_groups) else []}
                        for index, machine_name in enumerate(machines)
                    ],
                    "cross_family": pair.get("cross_family") is True,
                })
        pairs.sort(key=lambda pair: (
            str(pair.get("canonical_action", "")),
            tuple(str(row.get("machine", "")) for row in pair.get("machines", [])),
        ))
        cross_family_pairs = [pair for pair in pairs if pair["cross_family"]]
        matching_pairs = cross_family_pairs if cross_family_only else pairs
        returned_pairs = matching_pairs[offset:offset + limit]
        next_offset = offset + len(returned_pairs)
        carriers: dict[str, list[dict[str, Any]]] = {}
        for edge in action_edges:
            edge_machine = edge.get("machine")
            edge_id = edge.get("id")
            if isinstance(edge_machine, str) and isinstance(edge_id, str):
                carriers.setdefault(edge_machine, []).append(edge)
        query["cross_family_only"] = cross_family_only
        return {
            "query": query,
            "assertion": "Each pair records only that its transition edges share a canonical action name; it does not assert equivalence, prerequisite order, or a learner relation.",
            "carriers": [
                {
                    "machine": name,
                    "edge_ids": sorted(str(edge["id"]) for edge in carrier_edges),
                    "validity_modes": [
                        mode for mode in (
                            "objective_invalid", "context_sensitive_or_inefficient"
                        )
                        if any(mode in edge.get("validity_modes", []) for edge in carrier_edges)
                    ],
                }
                for name, carrier_edges in sorted(carriers.items())
            ],
            "totals": {
                "canonical_actions": len({pair["canonical_action"] for pair in matching_pairs}),
                "carrier_machines": len(carriers),
                "carrier_edges": sum(len(carrier_edges) for carrier_edges in carriers.values()),
                "pairs": len(pairs),
                "cross_family_pairs": len(cross_family_pairs),
                "matching_pairs": len(matching_pairs),
            },
            "page": {
                "limit": limit,
                "offset": offset,
                "returned": len(returned_pairs),
                "truncated": next_offset < len(matching_pairs),
                "next_offset": next_offset if next_offset < len(matching_pairs) else None,
            },
            "pairs": returned_pairs,
        }

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
        chart = self._deformation_full(code)
        if arguments.get("full"):
            return chart
        return {
            "lesson_code": chart.get("lesson_code", chart.get("code", code)),
            "title": chart.get("title"),
            "standards": chart.get("standards", []),
            # The compact form drops the scenes, never the provenance: a caller
            # who cannot tell a read lesson from a default fill cannot read the
            # chart at all.
            "provenance": chart.get("provenance"),
            "provenance_note": chart.get("provenance_note"),
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
        return {
            "lesson_code": chart.get("lesson_code", chart.get("code", code)),
            "id": identifier,
            "provenance": chart.get("provenance"),
            "provenance_note": chart.get("provenance_note"),
            "data": item,
        }

    def resonance_neighbors(self, arguments: dict[str, Any]) -> dict[str, Any]:
        db_row = arguments.get("db_row")
        name = arguments.get("name")
        if db_row is not None and (not isinstance(db_row, str) or not db_row.strip()):
            raise ValueError("resonance_neighbors db_row must be a non-empty stored row identity")
        if db_row is None and (not isinstance(name, str) or not name.strip()):
            raise ValueError("resonance_neighbors requires a stored misconception db_row identity or an unambiguous name")
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
        if isinstance(db_row, str):
            source_index = next((i for i, entry in enumerate(index.entries) if entry["db_row"] == db_row), None)
            query_identity = db_row
        else:
            named = [i for i, entry in enumerate(index.entries) if entry["name"] == name]
            if len(named) != 1:
                raise ValueError(f"stored misconception name {name!r} is ambiguous; pass a db_row returned by misconception_search_rows")
            source_index = named[0]
            query_identity = index.entries[source_index]["db_row"] or index.entries[source_index]["misconception_id"]
        if source_index is None:
            raise ValueError(f"no stored misconception vector has db_row {db_row!r}")
        matches = cosine_matches(index, list(index.vectors[source_index]), limit=min(limit + 1, len(index.entries)))
        neighbors = [
            row for row in matches
            if (row["db_row"] or row["misconception_id"]) != query_identity
        ][:limit]
        return {"retrieval": "stored_vector", "query_name": index.entries[source_index]["name"],
                "query_db_row": index.entries[source_index]["db_row"],
                "model": index.model, "neighbors": neighbors}

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

    def misconception_lookup(self, arguments: dict[str, Any]) -> dict[str, Any]:
        limit = arguments.get("limit", 20)
        offset = arguments.get("offset", 0)
        if not 1 <= limit <= 100:
            raise ToolCallError("misconception_lookup limit must be between 1 and 100.", kind="malformed_input")
        if offset < 0:
            raise ToolCallError("misconception_lookup offset must be non-negative.", kind="malformed_input")
        filters = {key: value for key, value in arguments.items() if key in {"domain", "description", "source"}}
        matches = self._worker_request("query_misconception", **filters)
        if not isinstance(matches, list):
            raise ToolCallError("misconception_lookup returned an invalid result.", kind="worker_failure")
        return {"total": len(matches), "limit": limit, "offset": offset, "rows": matches[offset:offset + limit]}

    def incompatibility_profile(self, arguments: dict[str, Any]) -> dict[str, Any]:
        content = arguments.get("content")
        if not isinstance(content, str) or not content.strip():
            raise ToolCallError("incompatibility_profile requires a content term string.", kind="malformed_input")
        inventory = self._worker_request("hyperedges")
        rows = inventory.get("hyperedges") if isinstance(inventory, dict) else None
        if not isinstance(rows, list):
            raise ToolCallError("incompatibility_profile returned an invalid hyperedge inventory.", kind="worker_failure")
        minimal_sets = [row for row in rows if isinstance(row, dict) and content in row.get("set", [])]
        partners = sorted({term for row in minimal_sets for term in row["set"] if term != content})
        return {"content": content, "status": "matched" if minimal_sets else "no_incompatibility_profile", "minimal_sets": minimal_sets, "partners": partners}

    def incompatibility_entailments(self, arguments: dict[str, Any]) -> dict[str, Any]:
        replacement = arguments.get("replacement")
        replaced = arguments.get("replaced")
        if not isinstance(replacement, str) or not replacement.strip() or not isinstance(replaced, str) or not replaced.strip():
            raise ToolCallError("incompatibility_entailments requires replacement and replaced term strings.", kind="malformed_input")
        contents = {"replacement": replacement, "replaced": replaced}
        try:
            witness = self._worker_request("incompatibility_entailment_witness", **contents)
        except ToolCallError as exc:
            if exc.kind == "not_covered":
                return {"relation": "live_finite_profile_non_strict", "contents": contents,
                        "status": "not_entailed_or_uncovered", "witnessing_contexts": []}
            raise
        if not isinstance(witness, dict):
            raise ToolCallError("incompatibility_entailments returned an invalid witness.", kind="worker_failure")
        reverse_contents = {"replacement": replaced, "replaced": replacement}
        try:
            reverse_witness = self._worker_request("incompatibility_entailment_witness", **reverse_contents)
        except ToolCallError as exc:
            if exc.kind != "not_covered":
                raise
            reverse_witness = None
        contexts = sorted({profile["context"] for profile in witness.get("profiles_checked", []) if isinstance(profile, dict) and isinstance(profile.get("context"), str)})
        response = {"relation": "live_finite_profile_non_strict", "contents": contents,
                    "status": "equivalent" if isinstance(reverse_witness, dict) else "entailed",
                    "witnessing_contexts": contexts, "witness": witness}
        if isinstance(reverse_witness, dict):
            response["reverse_witness"] = reverse_witness
        return response


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
