#!/usr/bin/env python3
"""Generate the worker capability registry from code and shipped surfaces."""
from __future__ import annotations

import argparse
import ast
import difflib
import re
import sys
import tempfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts" / "bundle"))

from app_manifest import build_manifest, worker_closure  # noqa: E402
from html_surface_check import (  # noqa: E402
    API_LITERAL_RE,
    DEFAULT_WEB_ROOTS,
    iter_html_files,
    normalize_api,
)

WORKER = ROOT / "hermes_worker.pl"
ROUTES_DIR = ROOT / "hermes" / "app" / "routes"
LOGIC = ROUTES_DIR / "logic.py"
OUTPUT = ROOT / "hermes" / "capability_registry.pl"
DISPATCH_RE = re.compile(
    r"(?m)^dispatch_request\(([a-z][A-Za-z0-9_]*),\s*Id,\s*(_?Request),\s*Response\)\s*:-"
)
MODULE_CALL_RE = re.compile(r"\b([a-z][A-Za-z0-9_]*)\s*:\s*[a-z][A-Za-z0-9_]*\s*\(")
MODULE_DIRECTIVE_RE = re.compile(
    r":-\s*module\(\s*(['\"]?)([^,'\"\s()]+)\1\s*,", re.MULTILINE
)


@dataclass(frozen=True)
class Operation:
    name: str
    module: str
    role: str
    inputs: tuple[str, ...]


ROLE_PREFIXES: tuple[tuple[str, str], ...] = (
    ("geometry", "geometry_witness"),
    ("standard_", "standards"),
    ("monitoring_", "monitoring"),
    ("field_", "monitoring"),
    ("ranked_", "monitoring"),
    ("representation_", "crosswalk"),
    ("canonical_", "crosswalk"),
    ("pml_", "pml"),
    ("validate_reader_", "pml"),
    ("carving_", "carving"),
    ("misconception_", "misconceptions"),
    ("query_misconception", "misconceptions"),
    ("diagnose_error", "misconceptions"),
    ("list_misconceptions", "misconceptions"),
    ("deontic_", "arche_trace"),
    ("sequent_", "arche_trace"),
    ("incompatibility_", "arche_trace"),
    ("brandom", "arche_trace"),
    ("hyperedges", "arche_trace"),
    ("axiom_", "arche_trace"),
    ("fraction_", "render"),
    ("area_", "render"),
    ("base_ten_", "render"),
    ("ace_of_bases_", "render"),
    ("set_grouping_", "render"),
    ("balance_", "render"),
    ("number_line_", "render"),
    ("place_value_", "render"),
    ("hybridization_", "render"),
    ("notation_", "render"),
    ("teacher_layer", "render"),
    ("render_coverage", "monitoring"),
    ("compute", "learner"),
    ("knowledge", "learner"),
    ("learner_", "learner"),
    ("reorganize", "learner"),
    ("visualize_coordination", "learner"),
    ("capability_", "infrastructure"),
    ("health", "infrastructure"),
    ("set_base", "infrastructure"),
    ("get_base", "infrastructure"),
)

DIRECTORY_ROLES = {
    "arche-trace": "arche_trace",
    "crosswalk": "crosswalk",
    "formalization": "synthesis",
    "geometry": "geometry_witness",
    "hermes": "infrastructure",
    "learner": "learner",
    "lessons": "workflow",
    "misconceptions": "misconceptions",
    "more-zeeman": "zeeman",
    "pml": "pml",
    "standards": "standards",
    "strategies": "synthesis",
    "tools": "infrastructure",
}


def prolog_atom(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def role_for_op(name: str) -> str:
    for prefix, role in ROLE_PREFIXES:
        if name.startswith(prefix):
            return role
    return "unclassified"


def input_keys(body: str, request_name: str) -> tuple[str, ...]:
    if request_name.startswith("_"):
        return ()
    escaped = re.escape(request_name)
    keys: set[str] = set()
    patterns = (
        rf"\bget_dict(?:_opt)?\(\s*([a-z][A-Za-z0-9_]*)\s*,\s*{escaped}\b",
        rf"\brequest_[a-zA-Z0-9_]+\(\s*{escaped}\s*,\s*([a-z][A-Za-z0-9_]*)\b",
        rf"\b{escaped}\.([a-z][A-Za-z0-9_]*)\b",
    )
    for pattern in patterns:
        keys.update(re.findall(pattern, body))
    for match in re.finditer(rf"_\{{([^}}]+)\}}\s*(?::<?|=)\s*{escaped}\b", body, re.DOTALL):
        keys.update(re.findall(r"\b([a-z][A-Za-z0-9_]*)\s*:", match.group(1)))
    return tuple(sorted(keys))


def dispatch_body(text: str, start: int) -> str:
    """Return one dispatch body, stopping at its top-level terminating period."""
    depth = 0
    quote: str | None = None
    line_comment = False
    block_comment = False
    index = start
    while index < len(text):
        char = text[index]
        following = text[index + 1] if index + 1 < len(text) else ""
        if line_comment:
            if char == "\n":
                line_comment = False
            index += 1
            continue
        if block_comment:
            if char == "*" and following == "/":
                block_comment = False
                index += 2
            else:
                index += 1
            continue
        if quote:
            if char == "\\":
                index += 2
                continue
            if char == quote:
                if following == quote:
                    index += 2
                    continue
                quote = None
            index += 1
            continue
        if char == "%":
            line_comment = True
            index += 1
            continue
        if char == "/" and following == "*":
            block_comment = True
            index += 2
            continue
        if char in {"'", '"'}:
            quote = char
            index += 1
            continue
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "." and depth == 0 and (not following or following.isspace() or following == "%"):
            return text[start:index]
        index += 1
    raise ValueError("unterminated dispatch_request clause")


def code_without_comments(body: str) -> str:
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.DOTALL)
    return re.sub(r"%[^\n]*", " ", body)


def extract_operations(text: str) -> list[Operation]:
    matches = list(DISPATCH_RE.finditer(text))
    operations: list[Operation] = []
    for match in matches:
        body = code_without_comments(dispatch_body(text, match.end()))
        module_match = MODULE_CALL_RE.search(body)
        operations.append(Operation(
            name=match.group(1),
            module=module_match.group(1) if module_match else "hermes_worker",
            role=role_for_op(match.group(1)),
            inputs=input_keys(body, match.group(2)),
        ))
    return sorted(operations, key=lambda op: op.name)


def function_worker_ops(node: ast.AST) -> set[str]:
    ops: set[str] = set()
    for child in ast.walk(node):
        if not isinstance(child, ast.Call) or not child.args:
            continue
        func = child.func
        if isinstance(func, ast.Attribute) and func.attr in {"worker_request", "request"}:
            if isinstance(child.args[0], ast.Constant) and isinstance(child.args[0].value, str):
                ops.add(child.args[0].value)
    return ops


def logic_methods() -> tuple[dict[str, set[str]], set[str]]:
    tree = ast.parse(LOGIC.read_text(encoding="utf-8"), filename=str(LOGIC))
    methods: dict[str, set[str]] = {}
    render_ops: set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            methods[node.name] = function_worker_ops(node)
            if node.name == "_handle_render":
                for child in ast.walk(node):
                    if isinstance(child, ast.Set):
                        values = {
                            item.value for item in child.elts
                            if isinstance(item, ast.Constant) and isinstance(item.value, str)
                        }
                        if "fraction_render" in values:
                            render_ops |= values
    methods.setdefault("_handle_render", set()).update(render_ops)
    # Chat can forward the finite scene op vocabulary returned by these helpers.
    for helper in ("_chat_render_scene_request", "_fraction_compare_scene_request"):
        helper_node = next(
            (n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef) and n.name == helper),
            None,
        )
        if helper_node:
            for call in (n for n in ast.walk(helper_node) if isinstance(n, ast.Call)):
                if call.args and isinstance(call.args[0], ast.Constant) and isinstance(call.args[0].value, str):
                    candidate = call.args[0].value
                    if candidate.endswith(("_render", "_compare")):
                        methods.setdefault("_handle_chat", set()).add(candidate)
    return methods, render_ops


def route_logic_method(module_tree: ast.AST, handler_name: str) -> str | None:
    for node in getattr(module_tree, "body", []):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name == handler_name:
            for call in (child for child in ast.walk(node) if isinstance(child, ast.Call)):
                if isinstance(call.func, ast.Attribute) and call.func.attr.startswith("_handle_"):
                    return call.func.attr
        if isinstance(node, ast.Assign):
            if any(isinstance(t, ast.Name) and t.id == handler_name for t in node.targets):
                call = node.value
                if isinstance(call, ast.Call) and call.args:
                    arg = call.args[0]
                    if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                        return arg.value
    return None


def route_map() -> dict[str, set[tuple[str, str]]]:
    methods, _render_ops = logic_methods()
    mapping: dict[str, set[tuple[str, str]]] = defaultdict(set)
    for path in sorted(ROUTES_DIR.glob("*.py")):
        if path.name in {"__init__.py", "logic.py", "registry.py"}:
            continue
        text = path.read_text(encoding="utf-8")
        tree = ast.parse(text, filename=str(path))
        functions = {
            node.name: node for node in tree.body
            if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef))
        }

        if path.name == "worker.py":
            for match in re.finditer(
                r"\(\s*[\"'](/api/[^\"']+)[\"']\s*,\s*[\"'](_handle_[^\"']+)[\"']\s*\)", text
            ):
                for op in methods.get(match.group(2), set()):
                    mapping[op].add(("POST", match.group(1)))
        for call in (node for node in ast.walk(tree) if isinstance(node, ast.Call)):
            if not isinstance(call.func, ast.Name) or call.func.id != "Route" or len(call.args) < 3:
                continue
            if not all(isinstance(arg, ast.Constant) and isinstance(arg.value, str) for arg in call.args[:2]):
                continue
            method = call.args[0].value
            route_path = call.args[1].value
            handler = call.args[2]
            ops: set[str] = set()
            if isinstance(handler, ast.Name):
                logic_method = route_logic_method(tree, handler.id)
                if logic_method:
                    ops |= methods.get(logic_method, set())
                if handler.id in functions:
                    ops |= function_worker_ops(functions[handler.id])
            elif isinstance(handler, ast.Call) and handler.args:
                arg = handler.args[0]
                if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                    ops |= methods.get(arg.value, set())
            for op in ops:
                mapping[op].add((method, route_path))

    # Monitoring visuals forwards a worker callback into this finite builder.
    visuals = ROOT / "hermes" / "app" / "monitoring" / "visuals.py"
    visual_tree = ast.parse(visuals.read_text(encoding="utf-8"), filename=str(visuals))
    visual_ops = function_worker_ops(visual_tree)
    for node in ast.walk(visual_tree):
        if isinstance(node, ast.Dict):
            visual_ops.update(
                key.value for key in node.keys
                if isinstance(key, ast.Constant)
                and isinstance(key.value, str)
                and key.value.endswith(("_render", "_compare"))
            )
    for op in visual_ops:
        mapping[op].add(("POST", "/api/monitoring_visuals"))

    return mapping


def page_map() -> dict[str, set[str]]:
    route_pages: dict[str, set[str]] = defaultdict(set)
    pages = iter_html_files([Path(root) for root in DEFAULT_WEB_ROOTS])
    for page in pages:
        source = page.read_text(encoding="utf-8")
        rel = page.relative_to(ROOT).as_posix()
        for literal in API_LITERAL_RE.findall(source):
            route_pages[normalize_api(literal)].add("/" + rel)
    return route_pages


def module_name(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    match = MODULE_DIRECTIVE_RE.search(text)
    return match.group(2) if match else path.stem


def orphan_modules() -> list[tuple[str, str, str]]:
    closure = set(worker_closure())
    shipped = (rel for rel in build_manifest(with_figures=False) if rel.endswith(".pl"))
    rows = []
    for rel in sorted(set(shipped) - closure):
        path = ROOT / rel
        role = DIRECTORY_ROLES.get(rel.split("/", 1)[0], "unclassified")
        rows.append((rel, module_name(path), role))
    return rows


def render_registry() -> str:
    operations = extract_operations(WORKER.read_text(encoding="utf-8"))
    routes = route_map()
    pages_by_route = page_map()
    lines = [
        "% Generated by scripts/extract_capability_registry.py.",
        "% Regenerate: python3 scripts/extract_capability_registry.py",
        ":- module(capability_registry,",
        "          [ capability/5,",
        "            capability_route/3,",
        "            capability_page/2",
        "          ]).",
        "",
    ]
    for op in operations:
        op_routes = routes.get(op.name, set())
        op_pages = {
            page for _method, route in op_routes for page in pages_by_route.get(route, set())
        }
        status = "routed_paged" if op_pages else "routed_only" if op_routes else "unrouted"
        inputs = "[" + ", ".join(prolog_atom(key) for key in op.inputs) + "]"
        lines.append(
            f"capability({prolog_atom(op.name)}, {prolog_atom(op.module)}, "
            f"{prolog_atom(op.role)}, {inputs}, {status})."
        )
    for rel, module, role in orphan_modules():
        lines.append(
            f"capability({prolog_atom(rel)}, {prolog_atom(module)}, "
            f"{prolog_atom(role)}, [], orphan_module)."
        )
    lines.append("")
    for op in operations:
        for method, route in sorted(routes.get(op.name, set())):
            lines.append(
                f"capability_route({prolog_atom(op.name)}, {prolog_atom(method)}, {prolog_atom(route)})."
            )
    lines.append("")
    for op in operations:
        op_pages = {
            page
            for _method, route in routes.get(op.name, set())
            for page in pages_by_route.get(route, set())
        }
        for page in sorted(op_pages):
            lines.append(f"capability_page({prolog_atom(op.name)}, {prolog_atom(page)}).")
    return "\n".join(lines) + "\n"


def check_output(expected: str) -> int:
    actual = OUTPUT.read_text(encoding="utf-8") if OUTPUT.is_file() else ""
    if actual == expected:
        print(f"capability registry is current: {OUTPUT.relative_to(ROOT)}")
        return 0
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".pl", delete=False) as tmp:
        tmp.write(expected)
        temp_path = Path(tmp.name)
    diff = list(difflib.unified_diff(
        actual.splitlines(), expected.splitlines(),
        fromfile=str(OUTPUT.relative_to(ROOT)), tofile=str(temp_path), lineterm="",
    ))
    print("capability registry is stale; run python3 scripts/extract_capability_registry.py", file=sys.stderr)
    for line in diff[:12]:
        print(line, file=sys.stderr)
    temp_path.unlink(missing_ok=True)
    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if the generated registry is stale")
    args = parser.parse_args()
    rendered = render_registry()
    if args.check:
        return check_output(rendered)
    OUTPUT.write_text(rendered, encoding="utf-8")
    op_count = len(extract_operations(WORKER.read_text(encoding="utf-8")))
    print(f"wrote {OUTPUT.relative_to(ROOT)}: {op_count} dispatch ops")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
