#!/usr/bin/env python3
"""Run the shipped typed-quantity compiler arm and emit raw receipts."""
from __future__ import annotations

import argparse
import json
import re
import sys
import types
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Protocol


ROOT = Path(__file__).resolve().parents[3]
RESEARCH = ROOT / "scripts/research"
HERE = Path(__file__).resolve().parent
for path in (str(RESEARCH), str(HERE)):
    if path not in sys.path:
        sys.path.insert(0, path)

import mtb_responders  # noqa: E402
from corpus import RunItem, load_corpus  # noqa: E402
from ledger import AppendLedger, SCHEMA  # noqa: E402


DEFAULT_MODEL = "gemma-4-E2B-it"
DEFAULT_ENDPOINT = "http://127.0.0.1:8080/v1/chat/completions"


@dataclass
class Usage:
    model_calls: int = 0
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0

    def copy(self) -> "Usage":
        return Usage(**asdict(self))

    def delta(self, earlier: "Usage") -> dict[str, int]:
        return {
            name: getattr(self, name) - getattr(earlier, name)
            for name in asdict(self)
        }


class Completion(Protocol):
    usage: Usage

    def __call__(self, prompt: str, *, num_predict: int) -> str:
        """Return one completion and update usage."""


class _BufferedResponse:
    def __init__(self, payload: bytes) -> None:
        self.payload = payload

    def __enter__(self) -> "_BufferedResponse":
        return self

    def __exit__(self, *unused: Any) -> None:
        return None

    def read(self) -> bytes:
        return self.payload


class LlamaCompletion:
    """Call the required responder while retaining llama.cpp usage fields."""

    def __init__(self, *, model: str, endpoint: str) -> None:
        self.model = model
        self.endpoint = endpoint
        self.usage = Usage()
        self.history: list[dict[str, Any]] = []

    def __call__(self, prompt: str, *, num_predict: int) -> str:
        original = mtb_responders.urllib.request.urlopen
        attempt_rows: list[dict[str, Any]] = []

        def capture(request: Any, timeout: float) -> _BufferedResponse:
            self.usage.model_calls += 1
            response = original(request, timeout=timeout)
            try:
                payload = response.read()
            finally:
                response.close()
            value = json.loads(payload.decode("utf-8"))
            usage = value.get("usage") or {}
            row = {
                "prompt_tokens": _token_count(usage.get("prompt_tokens")),
                "completion_tokens": _token_count(usage.get("completion_tokens")),
                "total_tokens": _token_count(usage.get("total_tokens")),
                "finish_reason": _finish_reason(value),
            }
            if row["total_tokens"] == 0:
                row["total_tokens"] = row["prompt_tokens"] + row["completion_tokens"]
            self.usage.prompt_tokens += row["prompt_tokens"]
            self.usage.completion_tokens += row["completion_tokens"]
            self.usage.total_tokens += row["total_tokens"]
            attempt_rows.append(row)
            return _BufferedResponse(payload)

        mtb_responders.urllib.request.urlopen = capture
        try:
            text = mtb_responders.complete(
                prompt,
                model=self.model,
                backend="llama",
                endpoint=self.endpoint,
                stop=None,
                stop_mode="post",
                num_predict=num_predict,
            )
        except Exception as exc:
            self.history.append({
                "status": "error",
                "detail": f"{type(exc).__name__}: {exc}",
                "attempts": attempt_rows,
            })
            raise
        finally:
            mtb_responders.urllib.request.urlopen = original
        self.history.append({"status": "ok", "attempts": attempt_rows})
        return text


def _token_count(value: Any) -> int:
    return value if isinstance(value, int) and not isinstance(value, bool) and value >= 0 else 0


def _finish_reason(value: Any) -> str:
    try:
        return str(value["choices"][0].get("finish_reason") or "")
    except (KeyError, IndexError, TypeError):
        return ""


def load_probe(*, fixture: bool = False) -> Any:
    """Import the shipped probe, with a dataset stub only for offline fixtures."""
    if "quantity_binding_probe" in sys.modules:
        probe = sys.modules["quantity_binding_probe"]
    elif fixture:
        previous = {
            name: sys.modules.get(name)
            for name in ("datasets", "mtb_official_runner")
        }
        dataset_stub = types.ModuleType("datasets")

        def unavailable(*unused_args: Any, **unused_kwargs: Any) -> Any:
            raise RuntimeError("dataset loading is disabled in fixtures")

        dataset_stub.load_dataset = unavailable  # type: ignore[attr-defined]
        runner_stub = types.ModuleType("mtb_official_runner")
        runner_stub.select_indexes = unavailable  # type: ignore[attr-defined]
        sys.modules["datasets"] = dataset_stub
        sys.modules["mtb_official_runner"] = runner_stub
        try:
            import quantity_binding_probe as probe
        finally:
            for name, module in previous.items():
                if module is None:
                    sys.modules.pop(name, None)
                else:
                    sys.modules[name] = module
    else:
        import quantity_binding_probe as probe
    probe.__dict__.pop("HUMAN_KIND_MAP", None)
    if "HUMAN_KIND_MAP" in probe.__dict__:
        raise RuntimeError("target-bearing kind map remains reachable")
    return probe


def bindings_for(
    probe: Any,
    problem: str,
    step: str,
    *,
    model: str,
    completion: Completion,
) -> tuple[list[Any], dict[str, Any]]:
    """Use model_bindings unchanged, redirecting only its transport call."""
    original = probe.mtb_responders.ollama_complete

    def redirect(prompt: str, **options: Any) -> str:
        if options.get("num_predict") != 2048:
            raise RuntimeError("shipped binding token budget changed")
        return completion(prompt, num_predict=2048)

    probe.mtb_responders.ollama_complete = redirect
    try:
        before = len(getattr(completion, "history", []))
        values = probe.model_bindings(problem, step, model=model)
        history = getattr(completion, "history", [])[before:]
        return values, {"status": "ok", "transport": history}
    except Exception as exc:
        history = getattr(completion, "history", [])[before:]
        return [], {
            "status": "error",
            "detail": f"{type(exc).__name__}: {exc}",
            "transport": history,
        }
    finally:
        probe.mtb_responders.ollama_complete = original


def _normalized(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def _captured_probe_call(
    probe: Any, function: Any, *args: Any,
) -> tuple[Any, dict[str, Any]]:
    """Run one shipped Prolog helper and retain whether its process succeeded."""
    original = probe.subprocess.run
    completed: list[Any] = []

    def capture(*run_args: Any, **run_kwargs: Any) -> Any:
        result = original(*run_args, **run_kwargs)
        completed.append(result)
        return result

    probe.subprocess.run = capture
    try:
        value = function(*args)
    finally:
        probe.subprocess.run = original
    result = completed[-1] if completed else None
    success = bool(
        result is not None
        and result.returncode == 0
        and isinstance(result.stdout, str)
        and result.stdout.strip()
    )
    event: dict[str, Any] = {"ran": result is not None, "success": success}
    if result is not None and result.returncode:
        event["returncode"] = result.returncode
        event["stderr"] = str(result.stderr or "").strip()
    return value, event


def _quantity_shape(probe: Any, node: Any, bindings: list[Any]) -> str | None:
    if isinstance(node, probe.ast.Constant) and isinstance(node.value, (int, float)):
        binding = probe.binding_for(float(node.value), bindings, str(node.value))
        return f"quantity({probe.prolog_atom(binding.kind)})"
    if not isinstance(node, probe.ast.BinOp):
        return None
    operation = probe.OPERATIONS.get(type(node.op))
    left = _quantity_shape(probe, node.left, bindings)
    right = _quantity_shape(probe, node.right, bindings)
    if operation is None or left is None or right is None:
        return None
    return f"{operation}({left},{right})"


def _operator_claim(probe: Any, step: str) -> str:
    for match in probe.EQUATION.finditer(step):
        tree = probe.expression_tree(match.group("left"))
        if isinstance(tree, probe.ast.BinOp):
            operation = probe.OPERATIONS.get(type(tree.op))
            if operation is not None:
                return f"operator({operation})"
    return "operator(unknown)"


def quantity_receipt(
    probe: Any, step: str, step_number: int, bindings: list[Any],
) -> tuple[dict[str, Any] | None, list[dict[str, Any]]]:
    """Retain the first refuting quantity expression, matching the shipped probe."""
    events: list[dict[str, Any]] = []
    for match in probe.EQUATION.finditer(step):
        tree = probe.expression_tree(match.group("left"))
        if tree is None or not isinstance(tree, probe.ast.BinOp):
            continue
        expression = probe.prolog_expression(tree, bindings)
        if expression is None:
            continue
        right_value = float(probe.normalize_magnitude(match.group("right")))
        claimed = probe.quantity_term(
            right_value,
            probe.binding_for(right_value, bindings, match.group("right")),
        )
        verdict, status = _captured_probe_call(
            probe, probe.run_quantity_expression, expression, claimed,
        )
        events.append({
            "kind": "symbolic_leaf",
            "tool": "quantity_claim:check_quantity_expression/3",
            "step": step_number,
            "verdict": verdict,
            **status,
        })
        if verdict in {"refuted", "incommensurable"}:
            expression_shape = _quantity_shape(probe, tree, bindings)
            claimed_binding = probe.binding_for(
                right_value, bindings, match.group("right"),
            )
            return {
                "step": step_number,
                "source_span": match.group(0),
                "tool": "quantity_claim:check_quantity_expression/3",
                "verdict": verdict,
                "normalized_claim": (
                    f"{expression_shape}=quantity({probe.prolog_atom(claimed_binding.kind)})"
                ),
                "call": {"expression": expression, "claimed": claimed},
                "accusation": True,
            }, events
    return None, events


def arithmetic_outcome(probe: Any, steps: list[str]) -> tuple[int | None, dict[str, Any]]:
    value, status = _captured_probe_call(probe, probe.arithmetic_first_wrong, steps)
    return value, {
        "kind": "symbolic_leaf",
        "tool": "check_solution_steps",
        "first_refuted_step": value,
        **status,
    }


def run_item(
    item: RunItem,
    *,
    model: str,
    completion: Completion,
    fixture: bool = False,
) -> dict[str, Any]:
    probe = load_probe(fixture=fixture)
    usage_before = completion.usage.copy()
    events: list[dict[str, Any]] = []
    receipt_candidates: list[dict[str, Any]] = []
    quantity_steps: list[int] = []
    for step_number, step in enumerate(item.steps, 1):
        bindings, transport = bindings_for(
            probe, item.problem, step, model=model, completion=completion,
        )
        events.append({
            "kind": "binding",
            "step": step_number,
            "bindings": [asdict(binding) for binding in bindings],
            **transport,
        })
        receipt, symbolic_events = quantity_receipt(probe, step, step_number, bindings)
        events.extend(symbolic_events)
        if receipt is not None:
            receipt_candidates.append(receipt)
            quantity_steps.append(step_number)

    arithmetic, arithmetic_event = arithmetic_outcome(probe, list(item.steps))
    events.append(arithmetic_event)
    if arithmetic is not None and 1 <= arithmetic <= len(item.steps):
        step = item.steps[arithmetic - 1]
        receipt_candidates.append({
            "step": arithmetic,
            "source_span": step,
            "tool": "check_solution_steps",
            "verdict": "refuted",
            "normalized_claim": _operator_claim(probe, step),
            "call": {"step": arithmetic},
            "accusation": True,
        })
    receipts: list[dict[str, Any]] = []
    accused_steps: set[int] = set()
    for receipt in receipt_candidates:
        step_number = receipt["step"]
        if step_number in accused_steps:
            events.append({
                "kind": "duplicate_accusation",
                "step": step_number,
                "receipt": receipt,
            })
            continue
        accused_steps.add(step_number)
        receipts.append(receipt)
    candidates = [value for value in [arithmetic, *quantity_steps] if value is not None]
    events.append({
        "kind": "first_flag",
        "arithmetic": arithmetic,
        "quantity": quantity_steps,
        "first": min(candidates) if candidates else None,
    })
    return {
        "schema": SCHEMA,
        "arm": "compiler",
        "index": item.index,
        "side": item.side,
        "problem": item.problem,
        "steps": list(item.steps),
        "receipts": receipts,
        "events": events,
        "usage": completion.usage.delta(usage_before),
    }


def run_items(
    items: list[RunItem],
    ledger: AppendLedger,
    *,
    model: str,
    completion: Completion,
    fixture: bool = False,
) -> tuple[int, int]:
    appended = skipped = 0
    for item in items:
        if ledger.has("compiler", item.index, item.side):
            skipped += 1
            continue
        row = run_item(item, model=model, completion=completion, fixture=fixture)
        appended += int(ledger.append(row))
    return appended, skipped


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", type=Path, required=True)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--endpoint", default=DEFAULT_ENDPOINT)
    args = parser.parse_args()
    items = load_corpus()
    ledger = AppendLedger(args.ledger)
    completion = LlamaCompletion(model=args.model, endpoint=args.endpoint)
    appended, skipped = run_items(
        items, ledger, model=args.model, completion=completion,
    )
    print(f"ARM COMPILER: COMPLETE appended={appended} resumed={skipped} ledger={args.ledger}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
