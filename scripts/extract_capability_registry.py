#!/usr/bin/env python3
"""Generate the worker capability registry from code and shipped surfaces."""
from __future__ import annotations

import argparse
import ast
import difflib
import functools
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
DISPATCH_SPEC = ROOT / "hermes" / "dispatch_spec.pl"
ROUTES_DIR = ROOT / "hermes" / "app" / "routes"
LOGIC = ROUTES_DIR / "logic.py"
OUTPUT = ROOT / "hermes" / "capability_registry.pl"
DISPATCH_RE = re.compile(
    r"(?m)^dispatch_request\(([a-z][A-Za-z0-9_]*),\s*Id,\s*(_?Request),\s*Response\)\s*:-"
)
MODULE_CALL_RE = re.compile(r"\b([a-z][A-Za-z0-9_]*)\s*:\s*[a-z][A-Za-z0-9_]*\s*\(")
SPEC_RE = re.compile(
    r"dispatch_spec\(\s*([a-z][A-Za-z0-9_]*)\s*,\s*\[(.*?)\]\s*,\s*"
    r"call\(\s*([a-z][A-Za-z0-9_]*)\s*:", re.DOTALL
)
MODULE_DIRECTIVE_RE = re.compile(
    r":-\s*module\(\s*(['\"]?)([^,'\"\s()]+)\1\s*,", re.MULTILINE
)
ENSURE_RE = re.compile(r"(?m)^(ensure_[a-z][A-Za-z0-9_]*)\s*:-")
LOAD_CALL_RE = re.compile(
    r"\b(?:consult|use_module|ensure_loaded|load_files)\(\s*"
    r"(?:(?P<alias>[a-z][A-Za-z0-9_]*)\(\s*(?P<target>'[^']+'|\"[^\"]+\"|[a-zA-Z0-9_./-]+)\s*\)"
    r"|(?P<plain>'[^']+'|\"[^\"]+\"|[a-z][A-Za-z0-9_./-]*))"
)

PROLOG_PATHS = {
    "carving": Path("formal/tools/carving"),
    "crosswalk": Path("knowledge/crosswalk"),
    "formalization": Path("formal/formalization"),
    "geometry": Path("knowledge/geometry"),
    "hermes": Path("hermes"),
    "im_lessons": Path("curriculum/im"),
    "learner": Path("formal/learner"),
    "lessons": Path("curriculum"),
    "math": Path("knowledge/strategies/math"),
    "misconceptions": Path("knowledge/misconceptions"),
    "pml": Path("formal/pml"),
    "sequent": Path("formal/sequent"),
    "incompat": Path("formal/incompatibility"),
    "dialectic": Path("formal/dialectic"),
    "juncture": Path("formal/juncture"),
    "render": Path("knowledge/strategies/render"),
    "standards": Path("knowledge/standards"),
    "strategies": Path("knowledge/strategies"),
    "tools": Path("formal/tools"),
    "zeeman": Path("hermes/web/prolog"),
}


@dataclass(frozen=True)
class Operation:
    name: str
    module: str
    role: str
    inputs: tuple[str, ...]
    parameters: tuple["Parameter", ...] = ()
    description: str | None = None


@dataclass(frozen=True)
class Parameter:
    name: str
    json_type: str | None = None
    required: bool | None = None
    example: object | None = None


# These examples are requests exercised through the worker seam.  The
# extractor derives converter type and requiredness from dispatch_spec/4; this
# table supplies examples for the MCP core's irregular legacy operations too.
PARAMETER_EXAMPLES: dict[str, dict[str, object]] = {
    "monitoring_chart_export": {"lesson_code": "IM-G3-U5-L2"},
    "lesson_dossier": {"lesson_code": "IM-G1-U1-L1"},
    "lesson_deformation_chart": {"code": "IM-G3-U5-L2"},
    "deontic_scorecard": {"agent": "student", "commitments": [], "entitlements": []},
    "deontic_consequences": {"agent": "student", "commitments": []},
    "deontic_up_level": {"agent": "student", "commitments": []},
    "commitment_match": {"content": "A square is a rectangle."},
    "check_math_claim": {"claim": "equivalence(fraction(3,4), fraction(6,8))"},
    "lesson_enactment_run": {"lesson": "IM-G4-U2-L4"},
    "diagnose_error": {
        "domain": "fraction",
        "input": "frac(1,7)-frac(1,7)",
        "got": "frac(1,14)",
    },
    # Added 2026-08-07 with the additive rule_builds/4 worker seam.
    "abduce_error": {
        "domain": "fraction",
        "input": "frac(1,9)-frac(1,9)",
        "got": "frac(1,18)",
    },
    "fraction_comparison_compare": {
        "family": "number_line_fraction_comparison",
        "n1": 1, "d1": 3, "n2": 2, "d2": 5,
    },
    "deformation_compare": {
        "family": "quadrant_sign_error", "x": -3, "y": 2,
        "vertices": [[0, 0], [4, 0], [4, 3], [0, 3]],
        "piece": "l", "cols": 5, "rows": 5,
        "degrees": 60, "short_length": 120, "long_length": 240,
        "pairs": [{"category": "red", "count": 4},
                  {"category": "blue", "count": 6}],
        "solid": "cube",
    },
}

OPERATION_DESCRIPTIONS = {
    "lesson_dossier": (
        "Gather the tracked lesson-filtered stores for one IM lesson code and "
        "report content or absence for each surface, with detail-call keys and "
        "links to matching generated pages."
    ),
    "check_math_claim": (
        "Check one typed mathematical claim term: equivalence(fraction(A,B), "
        "fraction(C,D)), multiplication, difference, sum, subtraction, "
        "comparison, fraction_sum, fraction_of, iterate_to_whole, ordering, "
        "quadrilateral claims, or arithmetic_equation; leaves are integers or "
        "registered vocabulary atoms."
    ),
    "lesson_enactment_list": (
        "List enacted IM lessons with every declared form, plus named refusals "
        "and the machine each refusal would need."
    ),
    "lesson_enactment_run": (
        "Run every distinct enacted form for one IM lesson and return each "
        "result through the strategy-trace response shape."
    ),
}

# These legacy handlers are outside dispatch_spec/4.  Their contracts were
# read from the handler guards before being recorded here; unlike spec-backed
# rows, this metadata is deliberately limited to the MCP core surface.
IRREGULAR_PARAMETER_METADATA: dict[str, dict[str, tuple[str, bool]]] = {
    "abduce_error": {
        "domain": ("string", True), "input": ("string", True),
        "got": ("string", True),
    },
    "diagnose_error": {
        "domain": ("string", True), "input": ("string", True),
        "got": ("string", True),
    },
    "lesson_deformation_chart": {"code": ("string", True)},
    "fraction_comparison_compare": {
        "family": ("string", True),
        "n1": ("integer", True), "d1": ("integer", True),
        "n2": ("integer", True), "d2": ("integer", True),
    },
    "deformation_compare": {
        "family": ("string", True),
        "x": ("integer", False), "y": ("integer", False),
        "vertices": ("array", False), "piece": ("string", False),
        "cols": ("integer", False), "rows": ("integer", False),
        "degrees": ("integer", False),
        "short_length": ("integer", False),
        "long_length": ("integer", False),
        "pairs": ("array", False), "solid": ("string", False),
    },
    "model_analysis_lookup": {
        "lesson_code": ("string", False),
        "statement_id": ("string", False),
        "limit": ("integer", False),
        "offset": ("integer", False),
    },
    "deontic_scorecard": {
        "agent": ("string", False), "commitments": ("array", False),
        "entitlements": ("array", False),
    },
    "deontic_consequences": {
        "agent": ("string", False), "commitments": ("array", False),
    },
    "deontic_up_level": {
        "agent": ("string", False), "commitments": ("array", False),
    },
}


ROLE_PREFIXES: tuple[tuple[str, str], ...] = (
    ("abduce_error", "misconceptions"),
    ("batch_event_score", "infrastructure"),
    ("benny_demo", "misconceptions"),
    ("check_math_claim", "misconceptions"),
    ("model_analysis_lookup", "synthesis"),
    ("commitment_match", "misconceptions"),
    ("deformation_compare", "render"),
    ("deformation_visualizer_catalog", "render"),
    ("elaborations", "synthesis"),
    ("fraction_comparison_compare", "render"),
    ("image_schema", "render"),
    ("inferential_strength", "synthesis"),
    ("lesson_deformation_chart", "workflow"),
    ("lesson_enactment_", "workflow"),
    ("lesson_misconception_", "misconceptions"),
    ("pair_", "infrastructure"),
    ("primitive_for_practice", "render"),
    ("state_labels", "synthesis"),
    ("strategy_", "synthesis"),
    ("target_inferential_strength", "synthesis"),
    ("unit_coordination_svg", "render"),
    ("unit_echo_", "render"),
    ("geometry", "geometry_witness"),
    ("standard_", "standards"),
    ("multiply_array_witness", "standards"),
    ("mult_div_family_witness", "standards"),
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
    ("deontic_", "sequent"),
    ("sequent_", "sequent"),
    ("incompatibility_", "incompatibility"),
    ("brandom", "incompatibility"),
    ("hyperedges", "incompatibility"),
    ("axiom_", "sequent"),
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
    "curriculum": "workflow",
    "knowledge/crosswalk": "crosswalk",
    "knowledge/discourse": "pml",
    "knowledge/strategies/render": "render",
    "formal/sequent": "sequent",
    "formal/incompatibility": "incompatibility",
    "formal/dialectic": "dialectic",
    "formal/juncture": "juncture",
    "formal/formalization": "synthesis",
    "knowledge/geometry": "geometry_witness",
    "hermes/web": "zeeman",
    "hermes": "infrastructure",
    "formal/learner": "learner",
    "lessons": "workflow",
    "knowledge/misconceptions": "misconceptions",
    "formal/pml": "pml",
    "knowledge/standards": "standards",
    "knowledge/strategies": "synthesis",
    "formal/tools": "infrastructure",
}


def public_page_path(page: Path) -> str:
    """Return the stable served path for a repository HTML file."""
    rel = page.relative_to(ROOT).as_posix()
    if rel.startswith("hermes/web/"):
        return "/more-zeeman/" + rel.removeprefix("hermes/web/")
    if rel.startswith("hermes/representation/"):
        return "/representation/" + rel.removeprefix("hermes/representation/")
    return "/" + rel


def directory_role(path: str) -> str:
    for prefix, role in DIRECTORY_ROLES.items():
        if path == prefix or path.startswith(prefix + "/"):
            return role
    return "unclassified"


def prolog_atom(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def prolog_json_value(value: object | None) -> str:
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return '"' + value.replace('"', '\\"') + '"'
    if isinstance(value, list):
        return "[" + ", ".join(prolog_json_value(item) for item in value) + "]"
    if isinstance(value, dict):
        pairs = ", ".join(
            f"{key}: {prolog_json_value(item)}" for key, item in sorted(value.items())
        )
        return "_{" + pairs + "}"
    raise TypeError(f"unsupported registry example value: {value!r}")


@functools.lru_cache(maxsize=1)
def module_directory_roles() -> dict[str, str]:
    """Return unambiguous existing classes for shipped Prolog modules."""
    candidates: dict[str, set[str]] = defaultdict(set)
    for rel in build_manifest(with_figures=False):
        if not rel.endswith(".pl"):
            continue
        role = directory_role(rel)
        if role == "unclassified":
            continue
        path = ROOT / rel
        candidates[module_name(path)].add(role)
    return {
        module: next(iter(roles))
        for module, roles in candidates.items()
        if len(roles) == 1
    }


def role_for_op(name: str, module: str) -> str:
    for prefix, role in ROLE_PREFIXES:
        if name.startswith(prefix):
            return role
    return module_directory_roles().get(module, "unclassified")


def top_level_items(text: str) -> list[str]:
    """Split a Prolog list body without mistaking converter arguments for rows."""
    items: list[str] = []
    start = 0
    depth = 0
    quote: str | None = None
    for index, char in enumerate(text):
        if quote:
            if char == quote:
                quote = None
            continue
        if char in {"'", '"'}:
            quote = char
        elif char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            items.append(text[start:index].strip())
            start = index + 1
    final = text[start:].strip()
    if final:
        items.append(final)
    return items


def base_converter(converter: str) -> str:
    converter = converter.strip()
    for wrapper in ("default(", "fallback("):
        if converter.startswith(wrapper):
            return top_level_items(converter[len(wrapper):-1])[0]
    return converter


def converter_json_type(converter: str) -> str | None:
    converter = base_converter(converter)
    if converter in {"atom", "code", "string", "filter", "op_atom", "nonempty_text", "optional_code", "practice", "math_claim"}:
        return "string"
    if converter == "int" or converter.startswith("int("):
        return "integer"
    if converter == "dict":
        return "object"
    if converter in {"json_list", "list"}:
        return "array"
    return None


def converter_required(converter: str) -> bool:
    return not converter.strip().startswith(("default(", "fallback("))


def spec_parameters(name: str, inputs_text: str) -> tuple[Parameter, ...]:
    examples = PARAMETER_EXAMPLES.get(name, {})
    parameters = []
    for item in top_level_items(inputs_text):
        key, converter = item.split("-", 1)
        parameters.append(Parameter(
            key.strip(), converter_json_type(converter), converter_required(converter),
            examples.get(key.strip()),
        ))
    return tuple(parameters)


def irregular_parameters(name: str, inputs: tuple[str, ...]) -> tuple[Parameter, ...]:
    examples = PARAMETER_EXAMPLES.get(name, {})
    metadata = IRREGULAR_PARAMETER_METADATA.get(name, {})
    return tuple(Parameter(key, *(metadata.get(key, (None, None))), examples.get(key)) for key in inputs)


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


def extract_spec_operations() -> dict[str, Operation]:
    text = code_without_comments(DISPATCH_SPEC.read_text(encoding="utf-8"))
    operations: dict[str, Operation] = {}
    rows = SPEC_RE.findall(text)
    if len(rows) != len(re.findall(r"(?m)^dispatch_spec\(", text)):
        raise ValueError("unreadable dispatch_spec row")
    for name, inputs_text, module in rows:
        parameters = spec_parameters(name, inputs_text)
        inputs = tuple(sorted(parameter.name for parameter in parameters))
        if name in operations:
            raise ValueError(f"duplicate dispatch_spec row: {name}")
        operations[name] = Operation(
            name, module, role_for_op(name, module), inputs, parameters,
            OPERATION_DESCRIPTIONS.get(name),
        )
    return operations


def extract_operations(text: str) -> list[Operation]:
    spec_operations = extract_spec_operations()
    matches = list(DISPATCH_RE.finditer(text))
    operations: list[Operation] = []
    for match in matches:
        if match.group(1) in spec_operations:
            raise ValueError(f"spec-backed op still has bespoke dispatch clause: {match.group(1)}")
        body = code_without_comments(dispatch_body(text, match.end()))
        module_match = MODULE_CALL_RE.search(body)
        name = match.group(1)
        inputs = tuple(sorted(set(input_keys(body, match.group(2))) |
                              set(IRREGULAR_PARAMETER_METADATA.get(name, {}))))
        operations.append(Operation(
            name=name,
            module=module_match.group(1) if module_match else "hermes_worker",
            role=role_for_op(
                name, module_match.group(1) if module_match else "hermes_worker"
            ),
            inputs=inputs,
            parameters=irregular_parameters(name, inputs),
            description=OPERATION_DESCRIPTIONS.get(name),
        ))
    operations.extend(spec_operations.values())
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
    nodes: dict[str, ast.FunctionDef | ast.AsyncFunctionDef] = {}
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            nodes[node.name] = node
    direct = {name: function_worker_ops(node) for name, node in nodes.items()}
    # A helper "forwards" when it calls worker_request with a variable op: the
    # op literal then lives at the helper's call sites (_forward_op idiom), and
    # crediting the callee's empty set would hide those ops from the registry.
    forwarders = {
        name
        for name, node in nodes.items()
        if not direct[name]
        and any(
            isinstance(child, ast.Call)
            and isinstance(child.func, ast.Attribute)
            and child.func.attr in {"worker_request", "request"}
            and child.args
            and not isinstance(child.args[0], ast.Constant)
            for child in ast.walk(node)
        )
    }
    # A handler may reach the worker through one intra-class helper hop
    # (_handle_chat -> _ground_message); union each helper's direct ops in.
    methods: dict[str, set[str]] = {}
    for name, node in nodes.items():
        ops = set(direct[name])
        for call in (child for child in ast.walk(node) if isinstance(child, ast.Call)):
            func = call.func
            if (
                isinstance(func, ast.Attribute)
                and isinstance(func.value, ast.Name)
                and func.value.id == "self"
                and not func.attr.startswith("_handle_")
                and func.attr in direct
            ):
                ops |= direct[func.attr]
                if (
                    func.attr in forwarders
                    and call.args
                    and isinstance(call.args[0], ast.Constant)
                    and isinstance(call.args[0].value, str)
                ):
                    ops.add(call.args[0].value)
        methods[name] = ops
    render_ops: set[str] = set()
    render_node = nodes.get("_handle_render")
    if render_node is not None:
        for child in ast.walk(render_node):
            if isinstance(child, ast.Set):
                values = {
                    item.value for item in child.elts
                    if isinstance(item, ast.Constant) and isinstance(item.value, str)
                }
                if "fraction_render" in values:
                    render_ops |= values
    methods.setdefault("_handle_render", set()).update(render_ops)
    witness_ops: dict[str, set[str]] = {}
    for node in tree.body:
        if not isinstance(node, (ast.Assign, ast.AnnAssign)):
            continue
        targets = node.targets if isinstance(node, ast.Assign) else [node.target]
        if not any(isinstance(target, ast.Name) and target.id == "WITNESS_OPS" for target in targets):
            continue
        value = node.value
        if not isinstance(value, ast.Dict):
            continue
        for key, family_value in zip(value.keys, value.values):
            if not isinstance(key, ast.Constant) or not isinstance(key.value, str):
                continue
            if not isinstance(family_value, ast.Call) or not family_value.args:
                continue
            literal = family_value.args[0]
            if not isinstance(literal, ast.Set):
                continue
            witness_ops[key.value] = {
                item.value for item in literal.elts
                if isinstance(item, ast.Constant) and isinstance(item.value, str)
            }
    for family, ops in witness_ops.items():
        methods[f"_handle_witness_{family}"] = ops
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
        # A module-level helper "forwards" when it calls worker_request/request
        # with a variable op: the op literal then lives at the helper's call
        # sites (the _forward_op idiom, here with ctx threaded ahead of the op),
        # and crediting the handler's empty direct set would hide those ops.
        module_forwarders = {
            name
            for name, node in functions.items()
            if not function_worker_ops(node)
            and any(
                isinstance(child, ast.Call)
                and isinstance(child.func, ast.Attribute)
                and child.func.attr in {"worker_request", "request"}
                and child.args
                and not isinstance(child.args[0], ast.Constant)
                for child in ast.walk(node)
            )
        }

        def forwarded_ops(node: ast.AST) -> set[str]:
            ops: set[str] = set()
            for call in ast.walk(node):
                if (
                    isinstance(call, ast.Call)
                    and isinstance(call.func, ast.Name)
                    and call.func.id in module_forwarders
                ):
                    ops.update(
                        arg.value
                        for arg in call.args
                        if isinstance(arg, ast.Constant)
                        and isinstance(arg.value, str)
                        and re.fullmatch(r"[a-z][a-z0-9_]*", arg.value)
                    )
            return ops

        if path.name == "worker.py":
            for match in re.finditer(
                r"\(\s*[\"'](/api/[^\"']+)[\"']\s*,\s*[\"'](_handle_[^\"']+)[\"']\s*\)", text
            ):
                for op in methods.get(match.group(2), set()):
                    mapping[op].add(("POST", match.group(1)))
            for match in re.finditer(
                r"\(\s*[\"'](/api/witness/[^\"']+)[\"']\s*,\s*[\"']([^\"']+)[\"']\s*\)", text
            ):
                family = match.group(2)
                for op in methods.get(f"_handle_witness_{family}", set()):
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
                    ops |= forwarded_ops(functions[handler.id])
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


CONTROL_TAG_RE = re.compile(r"<(?:button|input|select|textarea|form|a)\b[^>]*\bid=[\"']([^\"']+)[\"']", re.I)
INLINE_HANDLER_RE = re.compile(r"\bon[a-z]+=[\"'][^\"']*?\b([A-Za-z_$][\w$]*)\s*\(", re.I)
FUNCTION_RE = re.compile(r"\bfunction\s+([A-Za-z_$][\w$]*)\s*\([^)]*\)\s*\{")
CONTROL_LISTENER_RE = re.compile(
    r"(?:getElementById\(\s*[\"']([^\"']+)[\"']\s*\)|querySelector\(\s*[\"']#([^\"']+)[\"']\s*\))"
    r"[\s\S]{0,240}?\.addEventListener\(\s*[\"'](?:click|change|input|submit|keydown)[\"']",
    re.I,
)
LIFECYCLE_HANDLER_RE = re.compile(
    r"(?:document|window)\.addEventListener\(\s*[\"'](?:DOMContentLoaded|load)[\"']\s*,\s*([A-Za-z_$][\w$]*)",
    re.I,
)
CONTROL_HANDLER_RE = re.compile(
    r"(?:getElementById\(\s*[\"']([^\"']+)[\"']\s*\)|querySelector\(\s*[\"']#([^\"']+)[\"']\s*\)|\$\(\s*[\"']#?([^\"']+)[\"']\s*\))"
    r"[\s\S]{0,240}?\.addEventListener\(\s*[\"'](?:click|change|input|submit|keydown)[\"']\s*,\s*"
    r"(?:async\s+)?(?!function\b)([A-Za-z_$][\w$]*)\b(?!\s*=>)",
    re.I,
)
CONTROL_ANONYMOUS_HANDLER_RE = re.compile(
    r"(?:getElementById\(\s*[\"']([^\"']+)[\"']\s*\)|querySelector\(\s*[\"']#([^\"']+)[\"']\s*\)|\$\(\s*[\"']#?([^\"']+)[\"']\s*\))"
    r"[\s\S]{0,240}?\.addEventListener\(\s*[\"'](?:click|change|input|submit|keydown)[\"']\s*,\s*"
    r"(?:async\s+)?(?:(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>|function\s*\([^)]*\))\s*\{",
    re.I,
)
# Controls are also wired by handler-property assignment (el.onclick = fn),
# which binds exactly like addEventListener for reachability purposes.
CONTROL_PROPERTY_HANDLER_RE = re.compile(
    r"(?:getElementById\(\s*[\"']([^\"']+)[\"']\s*\)|querySelector\(\s*[\"']#([^\"']+)[\"']\s*\)|\$\(\s*[\"']#?([^\"']+)[\"']\s*\))"
    r"[\s\S]{0,240}?\.on(?:click|change|input|submit|keydown)\s*=\s*"
    r"(?:async\s+)?(?!function\b)([A-Za-z_$][\w$]*)\b(?!\s*=>)",
    re.I,
)
CONTROL_PROPERTY_ANONYMOUS_RE = re.compile(
    r"(?:getElementById\(\s*[\"']([^\"']+)[\"']\s*\)|querySelector\(\s*[\"']#([^\"']+)[\"']\s*\)|\$\(\s*[\"']#?([^\"']+)[\"']\s*\))"
    r"[\s\S]{0,240}?\.on(?:click|change|input|submit|keydown)\s*=\s*"
    r"(?:async\s+)?(?:(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>|function\s*\([^)]*\))\s*\{",
    re.I,
)
# Concise arrow handlers carry their body as one expression, no braces:
# $("run").onclick = () => runEventRoute("/api/event_score"). The captured
# expression is a live body for reachability (API literals + called helpers).
CONTROL_CONCISE_HANDLER_RE = re.compile(
    r"(?:getElementById\(\s*[\"']([^\"']+)[\"']\s*\)|querySelector\(\s*[\"']#([^\"']+)[\"']\s*\)|\$\(\s*[\"']#?([^\"']+)[\"']\s*\))"
    r"[\s\S]{0,240}?(?:\.addEventListener\(\s*[\"'](?:click|change|input|submit|keydown)[\"']\s*,\s*|\.on(?:click|change|input|submit|keydown)\s*=\s*)"
    r"(?:async\s+)?(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>\s*(?!\{)([^\n]+)",
    re.I,
)
LIFECYCLE_ANONYMOUS_HANDLER_RE = re.compile(
    r"(?:document|window)\.addEventListener\(\s*[\"'](?:DOMContentLoaded|load)[\"']\s*,\s*"
    r"(?:async\s+)?(?:(?:\([^)]*\)|[A-Za-z_$][\w$]*)\s*=>|function\s*\([^)]*\))\s*\{",
    re.I,
)
ARROW_BODY_RE = re.compile(r"=>\s*\{")
ANONYMOUS_FUNCTION_BODY_RE = re.compile(r"\bfunction\s*\([^)]*\)\s*\{")
ANY_FUNCTION_BODY_RE = re.compile(
    r"\b(?:async\s+)?function(?:\s+[A-Za-z_$][\w$]*)?\s*\([^)]*\)\s*\{"
)


def _braced_body(source: str, open_brace: int) -> str:
    """Return a JavaScript function body without attempting to parse JavaScript."""
    depth = 0
    for index in range(open_brace, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return source[open_brace + 1:index]
    return ""


def _braced_end(source: str, open_brace: int) -> int | None:
    """Return the closing-brace index for a JavaScript function body."""
    depth = 0
    for index in range(open_brace, len(source)):
        char = source[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    return None


def _called_functions(body: str, functions: dict[str, str]) -> set[str]:
    return {
        name for name in functions
        if re.search(r"\b" + re.escape(name) + r"\s*\(", body)
    }


def _is_iife_tail(tail: str) -> bool:
    """Recognize both ``(function () {})()`` and ``(function () {}())``."""
    return bool(re.match(r"\s*(?:\)\s*\(\s*\)|\(\s*\)\s*\))", tail))


def reachable_api_literals(source: str) -> set[str]:
    """Keep API literals reached by a control, lifecycle handler, or form/link.

    A literal inside a dormant helper is not a page capability. This lightweight
    check covers the shipped HTML idioms without treating every script string as
    a user-facing route.
    """
    controls = set(CONTROL_TAG_RE.findall(source))
    handlers = set(INLINE_HANDLER_RE.findall(source))
    handlers.update(LIFECYCLE_HANDLER_RE.findall(source))
    reachable: set[str] = set()
    functions: dict[str, str] = {}
    iifes: set[str] = set()
    body_spans: list[tuple[int, int]] = []
    live_anonymous_bodies: list[str] = []

    for match in FUNCTION_RE.finditer(source):
        open_brace = source.find("{", match.start())
        body = _braced_body(source, open_brace)
        name = match.group(1)
        functions[name] = body
        close_brace = _braced_end(source, open_brace)
        if close_brace is not None:
            body_spans.append((open_brace, close_brace))
        if close_brace is not None and _is_iife_tail(source[close_brace + 1:]):
            iifes.add(name)

    # Anonymous callbacks are still functions. Their spans keep a route inside
    # a dead callback from being mistaken for a top-level page-load route.
    for pattern in (ARROW_BODY_RE, ANONYMOUS_FUNCTION_BODY_RE):
        for match in pattern.finditer(source):
            open_brace = source.find("{", match.start())
            close_brace = _braced_end(source, open_brace)
            if close_brace is not None:
                body_spans.append((open_brace, close_brace))

    # Parenthesized named and anonymous function expressions invoked with
    # ``()`` are unconditional page-load paths.
    for match in ANY_FUNCTION_BODY_RE.finditer(source):
        open_brace = source.find("{", match.start())
        close_brace = _braced_end(source, open_brace)
        if close_brace is not None and _is_iife_tail(source[close_brace + 1:]):
            live_anonymous_bodies.append(_braced_body(source, open_brace))

    # A control handler is live only when its control exists in the page. The
    # resulting functions seed the graph; arbitrary callers do not.
    for pattern in (CONTROL_HANDLER_RE, CONTROL_PROPERTY_HANDLER_RE):
        for first, second, third, handler in pattern.findall(source):
            if (first or second or third) in controls:
                handlers.add(handler)
    for pattern in (
        CONTROL_ANONYMOUS_HANDLER_RE,
        CONTROL_PROPERTY_ANONYMOUS_RE,
        LIFECYCLE_ANONYMOUS_HANDLER_RE,
    ):
        for match in pattern.finditer(source):
            if pattern is not LIFECYCLE_ANONYMOUS_HANDLER_RE:
                first, second, third = match.group(1), match.group(2), match.group(3)
                if (first or second or third) not in controls:
                    continue
            open_brace = source.rfind("{", match.start(), match.end())
            body = _braced_body(source, open_brace)
            live_anonymous_bodies.append(body)
    for match in CONTROL_CONCISE_HANDLER_RE.finditer(source):
        first, second, third = match.group(1), match.group(2), match.group(3)
        if (first or second or third) in controls:
            live_anonymous_bodies.append(match.group(4))

    # Named controls, lifecycle handlers, and named IIFEs seed a small local
    # call graph. A helper becomes live only from a function already live.
    active = (handlers | iifes) & functions.keys()
    for body in live_anonymous_bodies:
        reachable.update(API_LITERAL_RE.findall(body))
        active.update(_called_functions(body, functions))

    # Bare calls at top level are also page-load paths. Calls inside any named
    # or anonymous function body must first inherit reachability from that
    # function, so a callback guarded by a missing control cannot seed a path.
    for name in functions:
        for call in re.finditer(r"(?m)(?:^|;)\s*" + re.escape(name) + r"\s*\(", source):
            if not any(start < call.start() < end for start, end in body_spans):
                active.add(name)
                break
    checked: set[str] = set()
    while active:
        name = active.pop()
        if name in checked:
            continue
        checked.add(name)
        body = functions.get(name, "")
        reachable.update(API_LITERAL_RE.findall(body))
        active.update(_called_functions(body, functions))

    # A top-level fetch is an unconditional page-load path (Atlas is the
    # intentional example); it is not dormant helper code.
    function_bodies = [source[start + 1:end] for start, end in body_spans]
    for literal in API_LITERAL_RE.findall(source):
        if not any(literal in body for body in function_bodies):
            reachable.add(literal)

    # Declarative links/forms and lifecycle callbacks are live paths without a
    # named control handler; helper bodies are intentionally excluded.
    for match in re.finditer(r"<(?:a|form)\b[^>]*(?:href|action)=[\"']([^\"']*/api/[^\"']*)", source, re.I):
        reachable.add(match.group(1))
    return reachable


def page_map() -> dict[str, set[str]]:
    route_pages: dict[str, set[str]] = defaultdict(set)
    pages = iter_html_files([Path(root) for root in DEFAULT_WEB_ROOTS])
    for page in pages:
        source = page.read_text(encoding="utf-8")
        rel = public_page_path(page)
        for literal in reachable_api_literals(source):
            route_pages[normalize_api(literal)].add(rel)
    return route_pages


def module_name(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    match = MODULE_DIRECTIVE_RE.search(text)
    return match.group(2) if match else path.stem


def _unquote(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def resolve_prolog_spec(alias: str | None, value: str, base: Path) -> Path | None:
    """Resolve one literal Prolog load spec to a repository-relative file."""
    target = Path(_unquote(value))
    if alias:
        prefix = PROLOG_PATHS.get(alias)
        if prefix is None:
            return None
        candidate = ROOT / prefix / target
    else:
        candidate = (base / target) if not target.is_absolute() else target
    if not candidate.suffix:
        candidate = candidate.with_suffix(".pl")
    try:
        resolved = candidate.resolve()
        rel = resolved.relative_to(ROOT.resolve())
    except (OSError, ValueError):
        return None
    return rel if resolved.is_file() else None


def literal_loads(text: str, base: Path) -> set[Path]:
    paths: set[Path] = set()
    for match in LOAD_CALL_RE.finditer(code_without_comments(text)):
        value = match.group("target") or match.group("plain")
        resolved = resolve_prolog_spec(match.group("alias"), value, base)
        if resolved is not None:
            paths.add(resolved)
    return paths


def lazy_module_ops(worker_text: str) -> dict[str, set[str]]:
    """Map op-time-loaded module paths to the dispatch ops that reach them.

    The worker scan follows ensure_* calls, resolves literal load directives,
    and follows one import hop from each directly loaded file. This reaches the
    fraction-band modules through fraction_band_ladder.pl without treating
    unrelated shipped files as live.
    """
    ensure_bodies: dict[str, str] = {}
    for match in ENSURE_RE.finditer(worker_text):
        ensure_bodies[match.group(1)] = code_without_comments(
            dispatch_body(worker_text, match.end())
        )

    direct: dict[str, set[Path]] = {}
    ensure_calls: dict[str, set[str]] = {}
    for name, body in ensure_bodies.items():
        direct[name] = literal_loads(body, ROOT)
        ensure_calls[name] = {
            called for called in ensure_bodies
            if called != name and re.search(rf"\b{re.escape(called)}\b", body)
        }

    def files_for(name: str, seen: set[str] | None = None) -> set[Path]:
        seen = set() if seen is None else set(seen)
        if name in seen:
            return set()
        seen.add(name)
        files = set(direct.get(name, set()))
        for called in ensure_calls.get(name, set()):
            files |= files_for(called, seen)
        return files

    ensure_ops: dict[str, set[str]] = defaultdict(set)
    for match in DISPATCH_RE.finditer(worker_text):
        body = code_without_comments(dispatch_body(worker_text, match.end()))
        for name in ensure_bodies:
            if re.search(rf"\b{re.escape(name)}\b", body):
                ensure_ops[name].add(match.group(1))

    result: dict[str, set[str]] = defaultdict(set)
    for ensure_name, ops in ensure_ops.items():
        loaded = files_for(ensure_name)
        one_hop = set(loaded)
        for rel in loaded:
            source = ROOT / rel
            one_hop |= literal_loads(
                source.read_text(encoding="utf-8", errors="replace"), source.parent
            )
        for rel in one_hop:
            result[rel.as_posix()].update(ops)
    return result


def module_page_map(module_paths: set[str]) -> dict[str, set[str]]:
    pages_by_module: dict[str, set[str]] = defaultdict(set)
    for page in iter_html_files([Path(root) for root in DEFAULT_WEB_ROOTS]):
        source = page.read_text(encoding="utf-8", errors="replace")
        page_name = public_page_path(page)
        for module_path in module_paths:
            if module_path in source:
                pages_by_module[module_path].add(page_name)
    return pages_by_module


def orphan_modules() -> list[tuple[str, str, str]]:
    closure = set(worker_closure())
    shipped = (rel for rel in build_manifest(with_figures=False) if rel.endswith(".pl"))
    rows = []
    for rel in sorted(set(shipped) - closure):
        path = ROOT / rel
        role = directory_role(rel)
        rows.append((rel, module_name(path), role))
    return rows


def render_registry() -> str:
    worker_text = WORKER.read_text(encoding="utf-8")
    operations = extract_operations(worker_text)
    routes = route_map()
    pages_by_route = page_map()
    outside_closure = orphan_modules()
    lazy_via = lazy_module_ops(worker_text)
    module_pages = module_page_map({rel for rel, _module, _role in outside_closure})
    lines = [
        "% Generated by scripts/extract_capability_registry.py.",
        "% Regenerate: python3 scripts/extract_capability_registry.py",
        ":- module(capability_registry,",
        "          [ capability/5,",
        "            capability_parameter/5,",
        "            capability_description/2,",
        "            capability_route/3,",
        "            capability_page/2,",
        "            capability_lazy_via/2",
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
    for rel, module, role in outside_closure:
        status = "lazy_reachable" if rel in lazy_via else "orphan_module"
        lines.append(
            f"capability({prolog_atom(rel)}, {prolog_atom(module)}, "
            f"{prolog_atom(role)}, [], {status})."
        )
    lines.append("")
    for op in operations:
        for parameter in op.parameters:
            if (parameter.json_type is None and parameter.required is None
                    and parameter.example is None):
                continue
            json_type = prolog_atom(parameter.json_type) if parameter.json_type else "null"
            required = ("true" if parameter.required else "false") if parameter.required is not None else "null"
            lines.append(
                f"capability_parameter({prolog_atom(op.name)}, {prolog_atom(parameter.name)}, "
                f"{json_type}, {required}, {prolog_json_value(parameter.example)})."
            )
    for op in operations:
        if op.description:
            lines.append(
                f"capability_description({prolog_atom(op.name)}, {prolog_json_value(op.description)})."
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
    for rel, _module, _role in outside_closure:
        for page in sorted(module_pages.get(rel, set())):
            lines.append(f"capability_page({prolog_atom(rel)}, {prolog_atom(page)}).")
    lines.append("")
    outside_paths = {rel for rel, _module, _role in outside_closure}
    for rel in sorted(lazy_via):
        if rel in outside_paths:
            for op in sorted(lazy_via[rel]):
                lines.append(
                    f"capability_lazy_via({prolog_atom(rel)}, {prolog_atom(op)})."
                )
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
