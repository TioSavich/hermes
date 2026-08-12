#!/usr/bin/env python3
"""The sidekick row, and the gates a row must pass before it can train.

A row records one decision: whether the model asks Hermes, what it asks, and
what it may say afterward. The tool half of every row was executed against the
live worker, so its correctness is a matter of record rather than judgment;
the gates re-execute it and drop any row whose result no longer reproduces.

Four gates run here. Provenance names the Hermes artifact a row came from and
refuses benchmark sources. The 13-gram gate catches a benchmark phrasing that
arrived with no provenance link. Re-execution catches drift between the tree
and the dataset. The mask check catches the row that would teach the model to
write tool output. A dataset that cannot show all four green does not train.
"""
from __future__ import annotations

import hashlib
import json
import random
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Sequence

from chat_format import GemmaChatFormat, conversation
from contamination import SPLIT_GRAM, OverlapGate, index_manifest, provenance_hits, split_overlap
from supervision import MaskViolation, build as build_mask, check as check_mask
from training_text import cull_display_math_markers

REPO_ROOT = Path(__file__).resolve().parents[2]
RUNTIME = REPO_ROOT / "hermes" / "app" / "runtime" / "experiments" / "sidekick"
CLASSES = ("A", "B", "C", "D")
RESPONSE_CLASSES = ("result", "refusal", "abstention")


def worker_sha() -> str:
    """Identify the symbolic core a row's results came from."""
    digest = hashlib.sha256()
    for relative in ("hermes_worker.pl", "hermes/dispatch_spec.pl"):
        digest.update((REPO_ROOT / relative).read_bytes())
    return digest.hexdigest()[:16]


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


@dataclass
class Call:
    name: str
    arguments: dict[str, Any]
    response: dict[str, Any]
    response_class: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class Row:
    id: str
    row_class: str
    menu: list[str]
    user_turn: str
    calls: list[Call]
    reply: str
    provenance: dict[str, Any]
    prior: list[dict[str, Any]] = field(default_factory=list)
    gates: dict[str, bool] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        body = {
            "id": self.id,
            "class": self.row_class,
            "menu": self.menu,
            "user_turn": self.user_turn,
            "calls": [call.to_dict() for call in self.calls],
            "reply": self.reply,
            "provenance": self.provenance,
            "gates": self.gates,
        }
        if self.prior:
            body["prior"] = self.prior
        return body

    @classmethod
    def from_dict(cls, body: dict[str, Any]) -> "Row":
        return cls(
            id=body["id"],
            row_class=body["class"],
            menu=list(body["menu"]),
            user_turn=body["user_turn"],
            calls=[Call(**call) for call in body["calls"]],
            reply=body["reply"],
            provenance=body["provenance"],
            prior=list(body.get("prior", [])),
            gates=dict(body.get("gates", {})),
        )

    def messages(self) -> list[dict[str, Any]]:
        messages: list[dict[str, Any]] = list(self.prior)
        messages.extend(
            conversation(
                self.user_turn,
                [call.to_dict() for call in self.calls],
                self.reply,
            )
        )
        return cull_display_math_markers(messages)


def write(rows: Sequence[Row], path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row.to_dict(), ensure_ascii=False, sort_keys=True) + "\n")
    return path


def read(path: Path) -> list[Row]:
    return [
        Row.from_dict(json.loads(line))
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def dataset_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:16]


# ---------------------------------------------------------------- the gates


def framing_faults(row: Row) -> list[str]:
    """A user turn that names the tool or quotes its result trains retrieval."""
    faults: list[str] = []
    turn = row.user_turn.casefold()
    if not turn.strip():
        faults.append("empty user turn")
    for call in row.calls:
        if call.name.replace("_", " ") in turn or call.name in turn:
            faults.append(f"user turn names the tool {call.name}")
        payload = json.dumps(call.response, ensure_ascii=False).casefold()
        for start in range(0, max(0, len(payload) - 24)):
            fragment = payload[start : start + 24]
            if fragment.strip() and fragment in turn:
                faults.append(f"user turn quotes the {call.name} result")
                break
    return faults


def shape_faults(row: Row) -> list[str]:
    faults: list[str] = []
    if row.row_class not in CLASSES:
        faults.append(f"unknown class {row.row_class}")
    if row.row_class == "C" and row.calls:
        faults.append("a class C row carries a call")
    if row.row_class in {"A", "B", "D"} and not row.calls:
        faults.append(f"a class {row.row_class} row carries no call")
    if row.row_class == "B" and len(row.calls) < 2:
        faults.append("a class B row carries fewer than two calls")
    for call in row.calls:
        if call.response_class not in RESPONSE_CLASSES:
            faults.append(f"unknown response class {call.response_class}")
        if call.name not in row.menu:
            faults.append(f"{call.name} is called but not declared in the menu")
    if not row.provenance or not row.provenance.get("source"):
        faults.append("no provenance")
    if not row.reply.strip():
        faults.append("empty reply")
    return faults


def execute(server: Any, call: Call) -> tuple[dict[str, Any], str]:
    """Re-run one call and report its response and response class.

    The three response shapes stay separate: a result, a refusal, and an
    `ok: true` whose emptiness the tool's own description names an abstention.
    Collapsing the third into the first would teach the sidekick that an empty
    result licenses a verdict.
    """
    from hermes.mcp.server import InvalidArguments, ToolCallError

    try:
        arguments = dict(call.arguments)
        server.validate_arguments(call.name, arguments)
        value = server.call(call.name, arguments)
    except (ToolCallError, InvalidArguments, ValueError) as exc:
        kind = getattr(exc, "kind", "malformed_input")
        worker_type = getattr(exc, "worker_type", None)
        return (
            {"ok": False, "error": {"type": worker_type or kind, "message": str(exc)}},
            "refusal",
        )
    return {"ok": True, "result": value}, classify_result(value)


def classify_result(value: Any) -> str:
    """An empty list, or a status that names no coverage, is an abstention."""
    if value == [] or value == {} or value is None:
        return "abstention"
    if isinstance(value, dict):
        status = str(value.get("status", ""))
        # `not_entailed_or_uncovered` is the entailment checker's honest
        # unresolved status: it reports no relation rather than the absence of
        # one, which is an abstention and not a finding.
        if status.startswith("no_") or status.startswith("not_") or status in {
            "refused", "sandbox_refused", "parse_error", "unresolved"
        }:
            return "abstention"
        if value.get("rejection") or value.get("error"):
            return "abstention"
        if isinstance(value.get("rows"), list) and not value["rows"]:
            return "abstention"
    return "result"


GATE_NAMES = ("shape_ok", "provenance_ok", "ngram_ok", "framing_ok", "reexecuted_ok", "mask_ok")



class WorkerHolder:
    """A replaceable worker with a second wall-clock boundary.

    `PersistentPrologWorker` bounds partial-line reads at its own deadline.
    Re-execution still runs on a thread with a wall clock around the full call.
    When an operation stalls, the row is dropped as not reproducing and the
    server is replaced, so one stalled operation does not hold the full build.
    """

    def __init__(self, factory: Any) -> None:
        self.factory = factory
        self.server = factory()
        self.stalls = 0

    def replace(self) -> None:
        self.stalls += 1
        try:
            self.server.close()
        except Exception:
            pass
        self.server = self.factory()


def bounded_execute(holder: "WorkerHolder", call: Call, seconds: float = 20.0) -> tuple[dict[str, Any], str]:
    import concurrent.futures

    # Not a context manager: its exit joins the worker thread, which is the
    # very thing that cannot be waited on here.
    runner = concurrent.futures.ThreadPoolExecutor(max_workers=1)
    future = runner.submit(execute, holder.server, call)
    try:
        result = future.result(timeout=seconds)
    except concurrent.futures.TimeoutError:
        holder.replace()
        runner.shutdown(wait=False, cancel_futures=True)
        return (
            {"ok": False, "error": {"type": "worker_stalled",
                                    "message": f"{call.name} did not answer within {seconds:.0f}s"}},
            "refusal",
        )
    runner.shutdown(wait=False)
    return result


@dataclass
class GateReport:
    rows: int = 0
    provenance_ok: int = 0
    ngram_ok: int = 0
    reexecuted_ok: int = 0
    mask_ok: int = 0
    framing_ok: int = 0
    shape_ok: int = 0
    class_counts: dict[str, int] = field(default_factory=dict)
    response_class_counts: dict[str, int] = field(default_factory=dict)
    token_lengths: list[int] = field(default_factory=list)
    failures: list[dict[str, Any]] = field(default_factory=list)
    reexecution: dict[str, Any] = field(default_factory=dict)
    per_row: dict[str, dict[str, bool]] = field(default_factory=dict)
    held_out_overlap: dict[str, Any] = field(default_factory=dict)

    @property
    def green(self) -> bool:
        return bool(self.rows) and not self.failures and all(
            count == self.rows
            for count in (
                self.provenance_ok,
                self.ngram_ok,
                self.reexecuted_ok,
                self.mask_ok,
                self.framing_ok,
                self.shape_ok,
            )
        )

    def summary(self) -> dict[str, Any]:
        lengths = sorted(self.token_lengths)
        return {
            "rows": self.rows,
            "green": self.green,
            "contamination_index": index_manifest(),
            "reexecution": self.reexecution,
            "held_out_overlap": self.held_out_overlap
            or {"training_overlap_checked": False, "reason": "no comparison set was supplied"},
            "provenance_ok": self.provenance_ok,
            "ngram_ok": self.ngram_ok,
            "reexecuted_ok": self.reexecuted_ok,
            "mask_ok": self.mask_ok,
            "framing_ok": self.framing_ok,
            "shape_ok": self.shape_ok,
            "class_counts": self.class_counts,
            "response_class_counts": self.response_class_counts,
            "tokens": {
                "median": lengths[len(lengths) // 2] if lengths else 0,
                "max": lengths[-1] if lengths else 0,
                "over_2048": sum(1 for length in lengths if length > 2048),
            },
            "failures": self.failures[:20],
            "failure_count": len(self.failures),
        }


def run_gates(
    rows: Iterable[Row],
    *,
    server: Any,
    chat: GemmaChatFormat,
    overlap: OverlapGate,
    tools: dict[str, dict[str, Any]],
    reexecute: bool = True,
    held_out: dict[str, str] | None = None,
    held_out_label: str = "",
    holder: "WorkerHolder | None" = None,
    reexecute_sample: int = 0,
    sample_seed: int = 20260810,
) -> GateReport:
    report = GateReport()
    rows = list(rows)
    # Several rows share one executed call, because one triple carries several
    # framings. Reproduction is a property of the call, not of the row, so it
    # is checked once per distinct call and reused.
    seen_calls: dict[str, tuple[dict[str, Any], str]] = {}
    # Re-execution can be sampled. The worker client blocks inside `readline`
    # when an operation stalls mid-line, and one stall poisons the replacement
    # worker too, so a full sweep over thousands of rows cannot be bounded.
    # A sample keeps drift detection at a cost that terminates, and the report
    # says how large the sample was rather than implying every row was checked.
    sampled: set[str] | None = None
    if reexecute_sample:
        signatures = sorted({
            json.dumps([call.name, call.arguments], ensure_ascii=False, sort_keys=True)
            for row in rows for call in row.calls
        })
        rng = random.Random(sample_seed)
        rng.shuffle(signatures)
        sampled = set(signatures[:reexecute_sample])
        report.reexecution = {
            "mode": "sampled", "distinct_calls": len(signatures), "sampled": len(sampled),
        }
    elif reexecute:
        report.reexecution = {"mode": "every_call"}
    else:
        report.reexecution = {"mode": "none"}
    # The probe is authored first and frozen; a training row that reaches into
    # it is the row that must go. Collisions are attributed per row so they are
    # dropped like any other gate failure rather than reddening the whole set.
    collisions: dict[str, list[dict[str, str]]] = {}
    if held_out is None:
        report.held_out_overlap = {
            "training_overlap_checked": False,
            "reason": f"no {held_out_label or 'comparison'} set was available",
        }
    else:
        shared = split_overlap(held_out, {row.id: row.user_turn for row in rows})
        for hit in shared:
            collisions.setdefault(hit["right"], []).append(hit)
        report.held_out_overlap = {
            "training_overlap_checked": True,
            "compared_with": held_out_label,
            "compared_items": len(held_out),
            "gram": SPLIT_GRAM,
            "shared_ngrams": len(shared),
            "rows_touching_held_out": len(collisions),
            "examples": shared[:5],
        }
    for row in rows:
        report.rows += 1
        report.class_counts[row.row_class] = report.class_counts.get(row.row_class, 0) + 1
        gates = dict.fromkeys(GATE_NAMES, False)
        faults: list[str] = shape_faults(row)
        if not faults:
            report.shape_ok += 1
            gates["shape_ok"] = True
        forbidden = provenance_hits(row.provenance)
        if forbidden:
            faults.append(f"provenance names a benchmark source: {forbidden}")
        else:
            report.provenance_ok += 1
            gates["provenance_ok"] = True
        hits = overlap.hits(row.user_turn)
        if hits:
            faults.append(f"user turn shares a 13-gram with the benchmark: {hits[0]!r}")
        else:
            report.ngram_ok += 1
            gates["ngram_ok"] = True
        framing = framing_faults(row)
        faults.extend(framing)
        if not framing:
            report.framing_ok += 1
            gates["framing_ok"] = True
        for hit in collisions.get(row.id, []):
            faults.append(
                f"shares an {SPLIT_GRAM}-gram with held-out item {hit['left']}: {hit['gram']!r}"
            )
        drifted = False
        if reexecute:
            for call in row.calls:
                signature = json.dumps(
                    [call.name, call.arguments], ensure_ascii=False, sort_keys=True
                )
                if sampled is not None and signature not in sampled:
                    report.response_class_counts[call.response_class] = (
                        report.response_class_counts.get(call.response_class, 0) + 1
                    )
                    continue
                if signature in seen_calls:
                    response, response_class = seen_calls[signature]
                elif holder is not None:
                    response, response_class = bounded_execute(holder, call)
                    seen_calls[signature] = (response, response_class)
                else:
                    response, response_class = execute(server, call)
                    seen_calls[signature] = (response, response_class)
                report.response_class_counts[response_class] = (
                    report.response_class_counts.get(response_class, 0) + 1
                )
                if response != call.response or response_class != call.response_class:
                    drifted = True
                    faults.append(f"{call.name} no longer reproduces its recorded result")
        else:
            for call in row.calls:
                report.response_class_counts[call.response_class] = (
                    report.response_class_counts.get(call.response_class, 0) + 1
                )
        if not drifted:
            report.reexecuted_ok += 1
            gates["reexecuted_ok"] = True
        try:
            rendered = chat.render(row.messages(), [tools[name] for name in row.menu])
            supervision = build_mask(chat, rendered)
            check_mask(chat, rendered, supervision, expects_call=bool(row.calls))
            report.mask_ok += 1
            gates["mask_ok"] = True
            report.token_lengths.append(len(rendered.ids))
        except (MaskViolation, KeyError) as exc:
            faults.append(f"mask: {exc}")
        report.per_row[row.id] = gates
        if faults:
            report.failures.append({"id": row.id, "class": row.row_class, "faults": faults})
    return report


DEFAULT_ROWS = RUNTIME / "datasets" / "pilot-200.jsonl"
DEFAULT_PROBE = RUNTIME / "probes" / "probe-v0.jsonl"


def main() -> int:
    import argparse
    import sys

    sys.path.insert(0, str(REPO_ROOT))
    from chat_format import AssetsMissing, asset_dir
    from hermes.mcp.server import HermesMCPServer

    parser = argparse.ArgumentParser(description="Run every dataset gate over one row file.")
    parser.add_argument("path", type=Path, nargs="?", default=DEFAULT_ROWS)
    parser.add_argument("--probe", type=Path, default=DEFAULT_PROBE)
    parser.add_argument("--no-reexecute", action="store_true")
    parser.add_argument(
        "--if-present",
        action="store_true",
        help="skip rather than fail when the local runtime inputs are absent",
    )
    arguments = parser.parse_args()

    missing = [str(path) for path in (arguments.path,) if not path.is_file()]
    try:
        chat = GemmaChatFormat()
    except AssetsMissing:
        chat = None
        missing.append(f"gemma-4 template and vocabulary under {asset_dir()}")
    try:
        overlap = OverlapGate()
    except FileNotFoundError as exc:
        overlap = None
        missing.append(str(exc).split(".")[0])
    if missing:
        if arguments.if_present:
            print(
                "SKIP sidekick dataset gates: local runtime inputs are absent — "
                + "; ".join(missing)
            )
            return 0
        print("cannot run the dataset gates: " + "; ".join(missing))
        return 1

    rows = read(arguments.path)
    held_out, held_out_label = None, "probe"
    if arguments.probe.is_file() and arguments.probe != arguments.path:
        held_out = {row.id: row.user_turn for row in read(arguments.probe)}
        held_out_label = str(arguments.probe.name)
    server = HermesMCPServer("core", REPO_ROOT)
    tools = {tool["name"]: tool for tool in server._public_tools}
    try:
        report = run_gates(
            rows,
            server=server,
            chat=chat,
            overlap=overlap,
            tools=tools,
            reexecute=not arguments.no_reexecute,
            held_out=held_out,
            held_out_label=held_out_label,
        )
    finally:
        server.close()
    summary = report.summary()
    summary["dataset_sha"] = dataset_sha(arguments.path)
    summary["worker_sha"] = worker_sha()
    print(json.dumps(summary, indent=2))
    if report.green:
        print(
            f"PASS sidekick dataset gates: {report.rows} rows, six gates green, "
            f"held-out overlap checked against {held_out_label}"
        )
    return 0 if report.green else 1


if __name__ == "__main__":
    raise SystemExit(main())
