#!/usr/bin/env python3
"""Build the wave-3 per-round sequence artifact from frozen wave-2 rows.

This is a rendering-only build. It authors no rows, executes no teacher, and
does not alter the frozen row, triple, probe, cache, or transcript artifacts.
Call sequences use the measured M-1 close [50, EOS] (token ids [50, 1]).
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import random
import sys
from collections import Counter
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable, Sequence

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from chat_format import (  # noqa: E402
    EXPECTED_MARKER_IDS,
    AssetsMissing,
    GemmaChatFormat,
    Rendered,
    asset_dir,
)
from contamination import (  # noqa: E402
    GRAM,
    SPLIT_GRAM,
    OverlapGate,
    index_manifest,
    provenance_hits,
    split_overlap,
)
from dataset import (  # noqa: E402
    GATE_NAMES,
    RUNTIME,
    Row,
    framing_faults,
    read as read_rows,
    shape_faults,
)
from supervision import (  # noqa: E402
    EOS_ID,
    IGNORE,
    SequenceKind,
    build_sequence,
    check_sequence,
)

DEFAULT_SOURCE = RUNTIME / "datasets" / "sidekick-wave2-6000.jsonl"
DEFAULT_OUTPUT = RUNTIME / "datasets" / "sidekick-wave3-seqs.jsonl"
DEFAULT_PROBE = RUNTIME / "probes" / "probe-v1.jsonl"
DEFAULT_TOOLS = RUNTIME / "datasets" / "core_tools.json"
DEFAULT_M1 = (
    REPO_ROOT / ".bigred-collected" / "2026-08-12-m1-tail" / "tail-capture.json"
)
DEFAULT_M1_STRATA = (
    REPO_ROOT / ".bigred-collected" / "2026-08-12-m1-tail" / "tail-capture-strata.json"
)
SOURCE_SHA256 = "df27ec0af663466732e6befb56b87d4528f01204528a9fa797e180fa7514f682"
BUILT_SHA256 = "fea3e1f35144ac3fa43428e85928f8ca5442462b721ed30447c0e3782619e22a"
G6_SUFFICIENCY_RULING = "§G6-SUFFICIENCY 2026-08-12"
EXPECTED_STRATA = {
    "B_second_call_after_result": "c",
    "D_second_call_after_refusal": "c",
}
TOOL_CALL_CLOSE_ID = 49
TOOL_RESPONSE_OPEN_ID = 50
TURN_CLOSE_ID = 106
CLOSE_TAIL = [TOOL_RESPONSE_OPEN_ID, EOS_ID]
MAX_LENGTH = 4096
EXPECTED_SHAPES = {
    ("A", 1): 1500,
    ("B", 2): 900,
    ("C", 0): 2400,
    ("D", 1): 840,
    ("D", 2): 360,
}
EXPECTED_KINDS = {"call": 4860, "reply": 2400, "relay": 1200, "C": 2400}
EXPECTED_TOTAL = 10860
EXPECTED_BARE = {"calling": 3600, "declining": 2400}


class BuildBlocked(RuntimeError):
    """A specified build gate failed; callers must not loosen the gate."""


@dataclass(frozen=True)
class SequenceRow:
    id: str
    source_row_id: str
    row_class: str
    kind: SequenceKind
    round_index: int | None
    bare_prefix: bool
    menu: list[str]
    messages: list[dict[str, Any]]
    source_provenance: dict[str, Any]
    source_gates: dict[str, bool]
    token_count: int = 0
    labeled_token_count: int = 0
    render_sha256: str = ""

    def with_render(self, rendered: Rendered, labels: Sequence[int]) -> "SequenceRow":
        return SequenceRow(
            **{
                **self.__dict__,
                "token_count": len(rendered.ids),
                "labeled_token_count": sum(label != IGNORE for label in labels),
                "render_sha256": hashlib.sha256(
                    rendered.text.encode("utf-8")
                ).hexdigest(),
            }
        )

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "source_row_id": self.source_row_id,
            "class": self.row_class,
            "kind": self.kind,
            "round": self.round_index,
            "bare_prefix": self.bare_prefix,
            "menu": self.menu,
            "messages": self.messages,
            "source_provenance": self.source_provenance,
            "source_gates": self.source_gates,
            "token_count": self.token_count,
            "labeled_token_count": self.labeled_token_count,
            "render_sha256": self.render_sha256,
        }

    @classmethod
    def from_dict(cls, body: dict[str, Any]) -> "SequenceRow":
        return cls(
            id=str(body["id"]),
            source_row_id=str(body["source_row_id"]),
            row_class=str(body["class"]),
            kind=body["kind"],
            round_index=body.get("round"),
            bare_prefix=bool(body["bare_prefix"]),
            menu=list(body["menu"]),
            messages=list(body["messages"]),
            source_provenance=dict(body["source_provenance"]),
            source_gates=dict(body["source_gates"]),
            token_count=int(body["token_count"]),
            labeled_token_count=int(body["labeled_token_count"]),
            render_sha256=str(body["render_sha256"]),
        )


def _assistant_call(call: Any, index: int) -> dict[str, Any]:
    return {
        "role": "assistant",
        "content": "",
        "tool_calls": [
            {
                "id": f"call_{index}",
                "type": "function",
                "function": {
                    "name": call.name,
                    "arguments": copy.deepcopy(call.arguments),
                },
            }
        ],
    }


def _tool_response(call: Any, index: int) -> dict[str, Any]:
    return {
        "role": "tool",
        "tool_call_id": f"call_{index}",
        "name": call.name,
        "content": json.dumps(call.response, ensure_ascii=False, sort_keys=True),
    }


def call_messages(row: Row, call_index: int) -> list[dict[str, Any]]:
    """Prefix through one assistant call, with earlier rounds fully answered."""
    messages = copy.deepcopy(row.prior)
    messages.append({"role": "user", "content": row.user_turn})
    for index, call in enumerate(row.calls[: call_index + 1]):
        messages.append(_assistant_call(call, index))
        if index < call_index:
            messages.append(_tool_response(call, index))
    return messages


def final_messages(row: Row) -> list[dict[str, Any]]:
    """Prefix through every executed round, followed by the recorded reply."""
    messages = copy.deepcopy(row.prior)
    messages.append({"role": "user", "content": row.user_turn})
    for index, call in enumerate(row.calls):
        messages.append(_assistant_call(call, index))
        messages.append(_tool_response(call, index))
    messages.append({"role": "assistant", "content": row.reply})
    return messages


def _argument_values(messages: Sequence[dict[str, Any]]) -> Iterable[Any]:
    for message in messages:
        if message.get("role") != "assistant":
            continue
        for tool_call in message.get("tool_calls") or []:
            yield tool_call["function"].get("arguments")


def to_wire_messages(messages: Sequence[dict[str, Any]]) -> list[dict[str, Any]]:
    """Serialize OpenAI wire arguments while leaving renderer objects untouched."""
    wire = copy.deepcopy(list(messages))
    for message in wire:
        if message.get("role") != "assistant":
            continue
        for tool_call in message.get("tool_calls") or []:
            arguments = tool_call["function"].get("arguments")
            if not isinstance(arguments, dict):
                raise BuildBlocked("renderer boundary received non-mapping arguments")
            tool_call["function"]["arguments"] = json.dumps(
                arguments, ensure_ascii=False, sort_keys=True, separators=(",", ":")
            )
    return wire


def from_wire_messages(messages: Sequence[dict[str, Any]]) -> list[dict[str, Any]]:
    """Normalize wire strings back to mappings before invoking the HF renderer."""
    normalized = copy.deepcopy(list(messages))
    for message in normalized:
        if message.get("role") != "assistant":
            continue
        for tool_call in message.get("tool_calls") or []:
            arguments = tool_call["function"].get("arguments")
            if not isinstance(arguments, str):
                raise BuildBlocked("wire boundary received non-string arguments")
            decoded = json.loads(arguments)
            if not isinstance(decoded, dict):
                raise BuildBlocked("wire arguments did not decode to a mapping")
            tool_call["function"]["arguments"] = decoded
    return normalized


def render_tools(
    sequence: SequenceRow, tools: dict[str, dict[str, Any]]
) -> list[dict[str, Any]]:
    try:
        return [tools[name] for name in sequence.menu]
    except KeyError as exc:
        raise BuildBlocked(
            f"{sequence.id} names an undeclared menu tool: {exc}"
        ) from exc


def render_sequence(
    chat: GemmaChatFormat,
    sequence: SequenceRow,
    tools: dict[str, dict[str, Any]],
) -> Rendered:
    """Render one sequence and apply the ruled [50, EOS] call close."""
    arguments = list(_argument_values(sequence.messages))
    if any(not isinstance(value, dict) for value in arguments):
        raise BuildBlocked(f"{sequence.id} gives the renderer non-mapping arguments")
    declarations = render_tools(sequence, tools)
    rendered = chat.render(sequence.messages, declarations)
    rerendered = chat.render(sequence.messages, declarations)
    if rendered.text != rerendered.text or rendered.ids != rerendered.ids:
        raise BuildBlocked(f"{sequence.id} is not stable across identical renders")

    wire = to_wire_messages(sequence.messages)
    if any(not isinstance(value, str) for value in _argument_values(wire)):
        raise BuildBlocked(f"{sequence.id} carries a non-string argument on the wire")
    normalized = from_wire_messages(wire)
    normalized_render = chat.render(normalized, declarations)
    if normalized_render.ids != rendered.ids:
        raise BuildBlocked(f"{sequence.id} changes token ids across the wire boundary")

    if sequence.kind != "call":
        return rendered
    if not rendered.ids or rendered.ids[-1] != TOOL_RESPONSE_OPEN_ID:
        raise BuildBlocked(
            f"{sequence.id} canonical call-only render does not end at token 50"
        )
    amended = Rendered(text=rendered.text + "<eos>", ids=rendered.ids + [EOS_ID])
    if chat.encode(amended.text) != amended.ids:
        raise BuildBlocked(f"{sequence.id} [50, EOS] tail is not tokenization-stable")
    if amended.ids[-3:] != [TOOL_CALL_CLOSE_ID, *CLOSE_TAIL]:
        raise BuildBlocked(f"{sequence.id} does not end in token ids [49, 50, 1]")
    return amended


def make_sequences(rows: Sequence[Row], seed: int) -> list[SequenceRow]:
    sequences: list[SequenceRow] = []
    for row in rows:
        if not row.calls:
            sequences.append(
                SequenceRow(
                    id=f"{row.id}::C",
                    source_row_id=row.id,
                    row_class=row.row_class,
                    kind="C",
                    round_index=None,
                    bare_prefix=True,
                    menu=list(row.menu),
                    messages=row.messages(),
                    source_provenance=copy.deepcopy(row.provenance),
                    source_gates=dict(row.gates),
                )
            )
            continue
        for index in range(len(row.calls)):
            sequences.append(
                SequenceRow(
                    id=f"{row.id}::call-{index + 1}",
                    source_row_id=row.id,
                    row_class=row.row_class,
                    kind="call",
                    round_index=index + 1,
                    bare_prefix=index == 0,
                    menu=list(row.menu),
                    messages=call_messages(row, index),
                    source_provenance=copy.deepcopy(row.provenance),
                    source_gates=dict(row.gates),
                )
            )
        kind: SequenceKind = "relay" if row.row_class == "D" else "reply"
        sequences.append(
            SequenceRow(
                id=f"{row.id}::{kind}",
                source_row_id=row.id,
                row_class=row.row_class,
                kind=kind,
                round_index=None,
                bare_prefix=False,
                menu=list(row.menu),
                messages=final_messages(row),
                source_provenance=copy.deepcopy(row.provenance),
                source_gates=dict(row.gates),
            )
        )
    random.Random(seed).shuffle(sequences)
    return sequences


def _tail_signature(record: dict[str, Any]) -> str | None:
    if record.get("close_found") is not True:
        return None
    ids = record.get("tail_token_ids")
    if isinstance(ids, list) and all(isinstance(token, int) for token in ids):
        return "ids:" + json.dumps(ids, separators=(",", ":"))
    text = record.get("raw_tail_text")
    return "text:" + json.dumps(text if isinstance(text, str) else "")


def _eos_stop(record: dict[str, Any]) -> bool:
    fields = record.get("stop_reason_fields") or {}
    reason = str(
        fields.get("stop_type")
        or fields.get("stopping_type")
        or fields.get("finish_reason")
        or fields.get("stop_reason")
        or ""
    ).casefold()
    return fields.get("stopped_eos") is True or reason == "eos"


def _record_outcome(record: dict[str, Any]) -> str:
    ids = record.get("tail_token_ids")
    text = record.get("raw_tail_text")
    if isinstance(ids, list) and TURN_CLOSE_ID in ids:
        return "a"
    if ids == [EOS_ID] or text == "<eos>":
        return "b"
    if ids == CLOSE_TAIL or text == "<|tool_response><eos>":
        return "c"
    if (ids == [TOOL_RESPONSE_OPEN_ID] or text == "<|tool_response>") and _eos_stop(
        record
    ):
        return "c"
    return "d"


def evaluate_m1(records: Sequence[dict[str, Any]]) -> dict[str, Any]:
    """Total M-1 outcome function over call-bearing records (gate G6)."""
    call_bearing = [record for record in records if _tail_signature(record) is not None]
    disposition_only = len(records) - len(call_bearing)
    if not call_bearing:
        return {
            "outcome": "d",
            "basis": "no call-bearing records",
            "records": len(records),
            "call_bearing": 0,
            "disposition_only": disposition_only,
            "required": 0,
            "modal_count": 0,
            "unique_mode": False,
            "modal_signature": None,
        }
    counts = Counter(_tail_signature(record) for record in call_bearing)
    modal_count = max(counts.values())
    modes = sorted(
        signature for signature, count in counts.items() if count == modal_count
    )
    required = math.ceil(0.8 * len(call_bearing))
    base = {
        "records": len(records),
        "call_bearing": len(call_bearing),
        "disposition_only": disposition_only,
        "required": required,
        "modal_count": modal_count,
        "unique_mode": len(modes) == 1,
        "modal_signature": modes[0] if len(modes) == 1 else None,
        "signature_counts": dict(sorted(counts.items())),
    }
    if len(modes) != 1:
        return {**base, "outcome": "e", "basis": "tail signatures have no unique mode"}
    if modal_count < required:
        return {
            **base,
            "outcome": "e",
            "basis": "unique modal tail is below ceil(0.8 * N_call-bearing)",
        }
    modal_records = [
        record for record in call_bearing if _tail_signature(record) == modes[0]
    ]
    outcomes = {_record_outcome(record) for record in modal_records}
    if len(outcomes) != 1:
        return {
            **base,
            "outcome": "d",
            "basis": "stable tail has inconsistent close or stop evidence",
        }
    outcome = outcomes.pop()
    basis = {
        "a": "stable tail contains turn-close token 106",
        "b": "stable tail is EOS token 1",
        "c": "stable tail is token 50 followed by model-emitted EOS",
        "d": "stable tail matches none of the authorized closes",
    }[outcome]
    return {**base, "outcome": outcome, "basis": basis}


def consume_m1(path: Path, source_sha256: str) -> dict[str, Any]:
    artifact = json.loads(path.read_text(encoding="utf-8"))
    recorded_source = artifact.get("source_selection", {}).get("dataset_sha256")
    if recorded_source != source_sha256:
        raise BuildBlocked(
            f"M-1 source sha {recorded_source!r} does not match {source_sha256}"
        )
    result = evaluate_m1(artifact.get("records") or [])
    if result["outcome"] != "c":
        raise BuildBlocked(f"G6 did not authorize outcome (c): {result}")
    result.update(
        {
            "artifact": str(path),
            "artifact_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "close_parameter": CLOSE_TAIL,
            "stored_legacy_outcome": artifact.get("classification", {}).get("outcome"),
        }
    )
    return result


def consume_m1_strata(
    path: Path,
    source_sha256: str,
    sufficiency_ruling: str | None,
) -> dict[str, Any]:
    """Consume the ruled B/D tail strata and refuse thin unruled evidence."""
    if not path.is_file():
        raise BuildBlocked(f"G6 strata artifact is absent: {path}")
    artifact = json.loads(path.read_text(encoding="utf-8"))
    recorded_source = artifact.get("source_selection", {}).get("dataset_sha256")
    if recorded_source != source_sha256:
        raise BuildBlocked(
            f"G6 strata source sha {recorded_source!r} does not match {source_sha256}"
        )

    render = artifact.get("render_verification") or {}
    required_render = {
        "stable_rerender": True,
        "text_to_token_round_trip": True,
        "prefix_end_marker_id": 51,
        "prefix_ends_inside_model_turn_after_closed_response": True,
        "turn_close_absent_after_response_open": True,
        "eos_id": EOS_ID,
    }
    render_failures = {
        key: {"expected": expected, "recorded": render.get(key)}
        for key, expected in required_render.items()
        if render.get(key) != expected
    }
    if render.get("marker_ids") != EXPECTED_MARKER_IDS:
        render_failures["marker_ids"] = {
            "expected": EXPECTED_MARKER_IDS,
            "recorded": render.get("marker_ids"),
        }
    if render_failures:
        raise BuildBlocked(f"G6 strata render verification failed: {render_failures}")

    summaries = artifact.get("stratum_summaries") or {}
    if set(summaries) != set(EXPECTED_STRATA):
        raise BuildBlocked(
            "G6 strata names differ from the ruled set: "
            f"recorded={sorted(summaries)} expected={sorted(EXPECTED_STRATA)}"
        )
    records = artifact.get("records") or []
    checked: dict[str, Any] = {}
    for stratum, ruled_outcome in EXPECTED_STRATA.items():
        summary = summaries[stratum]
        stratum_records = [
            record for record in records if record.get("stratum") == stratum
        ]
        recomputed = evaluate_m1(stratum_records)
        recorded_outcome = (summary.get("classification") or {}).get("outcome")
        recorded_acceptance = summary.get("acceptance_check") or {}
        if recorded_outcome != ruled_outcome or recomputed["outcome"] != ruled_outcome:
            raise BuildBlocked(
                f"G6 stratum {stratum} outcome mismatch: recorded={recorded_outcome!r} "
                f"recomputed={recomputed['outcome']!r} ruled={ruled_outcome!r}"
            )
        if recorded_acceptance.get("call_bearing_count") != recomputed["call_bearing"]:
            raise BuildBlocked(
                f"G6 stratum {stratum} call-bearing count disagrees with its records"
            )
        render_prompt_count = (render.get("stratum_prompt_counts") or {}).get(stratum)
        if render_prompt_count != len(stratum_records):
            raise BuildBlocked(
                f"G6 stratum {stratum} render prompt count {render_prompt_count!r} "
                f"does not match {len(stratum_records)} records"
            )
        thin = recomputed["call_bearing"] < 3
        if thin and sufficiency_ruling != G6_SUFFICIENCY_RULING:
            raise BuildBlocked(
                f"G6 stratum {stratum} has {recomputed['call_bearing']} call-bearing "
                f"observation(s) and lacks ruling {G6_SUFFICIENCY_RULING!r}"
            )
        checked[stratum] = {
            "prompt_count": len(stratum_records),
            "call_bearing": recomputed["call_bearing"],
            "disposition_only": recomputed["disposition_only"],
            "required": recomputed["required"],
            "modal_count": recomputed["modal_count"],
            "modal_signature": recomputed["modal_signature"],
            "recorded_outcome": recorded_outcome,
            "recomputed_outcome": recomputed["outcome"],
            "ruled_outcome": ruled_outcome,
            "thin_stratum": thin,
            "sufficiency_ruling": sufficiency_ruling if thin else None,
        }
    unassigned = [
        record.get("row_id")
        for record in records
        if record.get("stratum") not in summaries
    ]
    if unassigned:
        raise BuildBlocked(
            f"G6 strata artifact has records outside its ruled strata: {unassigned[:5]}"
        )
    if render.get("prompt_count") != len(records):
        raise BuildBlocked(
            f"G6 strata render prompt count {render.get('prompt_count')!r} "
            f"does not match {len(records)} records"
        )
    return {
        "artifact": str(path),
        "artifact_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "source_sha256": recorded_source,
        "render_verification": {**required_render, "marker_ids": EXPECTED_MARKER_IDS},
        "sufficiency_floor": 3,
        "sufficiency_ruling": sufficiency_ruling,
        "strata": checked,
        "passed": True,
    }


def validate_source(
    rows: Sequence[Row], source: Path, probe: Path
) -> tuple[dict[str, Any], dict[str, dict[str, bool]]]:
    source_sha = hashlib.sha256(source.read_bytes()).hexdigest()
    if source_sha != SOURCE_SHA256:
        raise BuildBlocked(f"frozen source sha changed: {source_sha}")
    shapes = Counter((row.row_class, len(row.calls)) for row in rows)
    if dict(shapes) != EXPECTED_SHAPES:
        raise BuildBlocked(f"source shape census differs from the design: {shapes}")

    benchmark = OverlapGate()
    per_row: dict[str, dict[str, bool]] = {}
    failures: list[str] = []
    for row in rows:
        gates = {
            "shape_ok": not shape_faults(row),
            "provenance_ok": not provenance_hits(row.provenance),
            "ngram_ok": not benchmark.hits(row.user_turn),
            "framing_ok": not framing_faults(row),
            "reexecuted_ok": row.gates.get("reexecuted_ok") is True,
            "mask_ok": row.gates.get("mask_ok") is True,
        }
        recorded = all(row.gates.get(name) is True for name in GATE_NAMES)
        if not all(gates.values()) or not recorded:
            failures.append(row.id)
        per_row[row.id] = gates
    if failures:
        raise BuildBlocked(
            f"six-gate source chain failed for {len(failures)} rows: {failures[:5]}"
        )

    held_out = read_rows(probe)
    collisions = split_overlap(
        {row.id: row.user_turn for row in held_out},
        {row.id: row.user_turn for row in rows},
    )
    if collisions:
        raise BuildBlocked(
            f"{len(collisions)} held-out {SPLIT_GRAM}-gram collisions: {collisions[:3]}"
        )
    return (
        {
            "source": str(source),
            "source_sha256": source_sha,
            "source_rows": len(rows),
            "source_shapes": {
                f"{row_class}:{calls}": count
                for (row_class, calls), count in sorted(shapes.items())
            },
            "six_gate_chain": {
                name: sum(gates[name] for gates in per_row.values())
                for name in GATE_NAMES
            },
            "benchmark_overlap": {
                "gram": GRAM,
                "rows_checked": len(rows),
                "collisions": 0,
                "index": index_manifest(),
            },
            "held_out_overlap": {
                "gram": SPLIT_GRAM,
                "probe": str(probe),
                "probe_rows": len(held_out),
                "training_rows": len(rows),
                "collisions": 0,
            },
        },
        per_row,
    )


def _shape_examples(rows: Sequence[Row]) -> list[tuple[str, list[dict[str, Any]], Row]]:
    by_shape = {(row.row_class, len(row.calls)): row for row in reversed(rows)}
    return [
        ("A reply", final_messages(by_shape[("A", 1)]), by_shape[("A", 1)]),
        ("B second call", call_messages(by_shape[("B", 2)], 1), by_shape[("B", 2)]),
        ("B reply", final_messages(by_shape[("B", 2)]), by_shape[("B", 2)]),
        ("D relay", final_messages(by_shape[("D", 1)]), by_shape[("D", 1)]),
    ]


def run_g1(
    chat: GemmaChatFormat,
    rows: Sequence[Row],
    tools: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    results = []
    for label, messages, row in _shape_examples(rows):
        direct_arguments = list(_argument_values(messages))
        if not direct_arguments or any(
            not isinstance(value, dict) for value in direct_arguments
        ):
            raise BuildBlocked(f"G1 {label} does not give mappings to the renderer")
        wire = to_wire_messages(messages)
        wire_arguments = list(_argument_values(wire))
        if any(not isinstance(value, str) for value in wire_arguments):
            raise BuildBlocked(f"G1 {label} does not carry strings on the wire")
        declarations = [tools[name] for name in row.menu]
        direct = chat.render(messages, declarations)
        normalized = chat.render(from_wire_messages(wire), declarations)
        if direct.ids != normalized.ids:
            raise BuildBlocked(f"G1 {label} token ids differ after normalization")
        results.append(
            {
                "shape": label,
                "source_row_id": row.id,
                "tool_calls": len(direct_arguments),
                "tokens": len(direct.ids),
                "renderer_arguments": "mapping",
                "wire_arguments": "string",
                "token_id_equivalence": True,
            }
        )
    return {"passed": True, "four_shape_render": results}


def validate_census(sequences: Sequence[SequenceRow]) -> dict[str, Any]:
    kinds = Counter(sequence.kind for sequence in sequences)
    bare = Counter(
        "calling" if sequence.kind == "call" else "declining"
        for sequence in sequences
        if sequence.bare_prefix
    )
    if len(sequences) != EXPECTED_TOTAL or dict(kinds) != EXPECTED_KINDS:
        raise BuildBlocked(
            f"sequence census differs from section 4: total={len(sequences)} kinds={kinds}"
        )
    if dict(bare) != EXPECTED_BARE:
        raise BuildBlocked(f"bare-prefix census differs from section 4: {bare}")
    return {
        "total": len(sequences),
        "kinds": dict(sorted(kinds.items())),
        "bare_prefix": dict(sorted(bare.items())),
        "C_share": bare["declining"] / sum(bare.values()),
    }


def write_sequences(sequences: Sequence[SequenceRow], path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        for sequence in sequences:
            handle.write(
                json.dumps(sequence.to_dict(), ensure_ascii=False, sort_keys=True)
                + "\n"
            )
    temporary.replace(path)
    return path


def read_sequences(path: Path) -> list[SequenceRow]:
    return [
        SequenceRow.from_dict(json.loads(line))
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def account_artifact(
    path: Path,
    chat: GemmaChatFormat,
    tools: dict[str, dict[str, Any]],
) -> dict[str, Any]:
    """Re-render the final JSONL and emit G7 accounting from that artifact."""
    rows = read_sequences(path)
    lengths: list[int] = []
    labeled = 0
    by_kind: dict[str, dict[str, int]] = {}
    for sequence in rows:
        rendered = render_sequence(chat, sequence, tools)
        supervision = build_sequence(chat, rendered, sequence.kind)
        check_sequence(chat, rendered, supervision, sequence.kind)
        digest = hashlib.sha256(rendered.text.encode("utf-8")).hexdigest()
        if (
            sequence.token_count != len(rendered.ids)
            or sequence.labeled_token_count != supervision.supervised_count
            or sequence.render_sha256 != digest
        ):
            raise BuildBlocked(
                f"{sequence.id} does not reproduce from the final artifact"
            )
        lengths.append(len(rendered.ids))
        labeled += supervision.supervised_count
        bucket = by_kind.setdefault(
            sequence.kind, {"sequences": 0, "processed_tokens": 0, "labeled_tokens": 0}
        )
        bucket["sequences"] += 1
        bucket["processed_tokens"] += len(rendered.ids)
        bucket["labeled_tokens"] += supervision.supervised_count
    over = sum(length > MAX_LENGTH for length in lengths)
    if over:
        raise BuildBlocked(
            f"G7 found {over} sequences over {MAX_LENGTH}; census would drop"
        )
    total = sum(lengths)
    return {
        "sequences": len(rows),
        "processed_tokens": total,
        "mean_tokens": total / max(1, len(rows)),
        "maximum_tokens": max(lengths, default=0),
        "over_4096": over,
        "labeled_tokens": labeled,
        "three_epoch_processed_tokens": total * 3,
        "by_kind": dict(sorted(by_kind.items())),
    }


def _rebuild_obligation(message: str) -> BuildBlocked:
    return BuildBlocked(
        f"{message}; rebuild obligation: rerun build_wave3_sequences.py only after "
        "the G6 consume-gate inputs agree with the ruled outcomes"
    )


def verify_built(arguments: argparse.Namespace) -> dict[str, Any]:
    """Run the consume-gate and G7 over the admitted on-disk artifact."""
    try:
        source_sha = hashlib.sha256(arguments.source.read_bytes()).hexdigest()
        if source_sha != SOURCE_SHA256:
            raise BuildBlocked(f"frozen source sha changed: {source_sha}")
        class_a = consume_m1(arguments.m1_artifact, source_sha)
        strata = consume_m1_strata(
            arguments.strata_artifact,
            source_sha,
            G6_SUFFICIENCY_RULING,
        )
        if not arguments.output.is_file():
            raise BuildBlocked(f"built dataset is absent: {arguments.output}")
        built_sha = hashlib.sha256(arguments.output.read_bytes()).hexdigest()
        if built_sha != BUILT_SHA256:
            raise BuildBlocked(
                f"built dataset sha {built_sha} does not match admitted {BUILT_SHA256}"
            )
        gates_path = arguments.gates or arguments.output.with_name(
            f"{arguments.output.stem}-gates.json"
        )
        if not gates_path.is_file():
            raise BuildBlocked(f"built gate record is absent: {gates_path}")
        gates = json.loads(gates_path.read_text(encoding="utf-8"))
        if gates.get("output_sha256") != built_sha:
            raise BuildBlocked(
                "built gate record names output sha "
                f"{gates.get('output_sha256')!r}, not {built_sha}"
            )

        chat = GemmaChatFormat()
        declarations = json.loads(arguments.tools.read_text(encoding="utf-8"))
        if not isinstance(declarations, list):
            raise BuildBlocked("tool declaration artifact is not a JSON list")
        tools = {tool["name"]: tool for tool in declarations}
        g7 = account_artifact(arguments.output, chat, tools)
        if gates.get("G7") != g7:
            raise BuildBlocked("G7 replay differs from the built gate record")

        record = {
            "gate": G6_SUFFICIENCY_RULING,
            "status": "green",
            "verified_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "built_dataset": str(arguments.output),
            "built_dataset_sha256": built_sha,
            "strata_artifact": str(arguments.strata_artifact),
            "strata_artifact_sha256": strata["artifact_sha256"],
            "class_A_artifact": str(arguments.m1_artifact),
            "class_A_artifact_sha256": class_a["artifact_sha256"],
            "source_dataset_sha256": source_sha,
            "close_parameter": CLOSE_TAIL,
            "strata": strata["strata"],
            "G7": g7,
        }
        records = gates.setdefault("verification_records", [])
        if not isinstance(records, list):
            raise BuildBlocked("built gate record verification_records is not a list")
        records.append(record)
        temporary = gates_path.with_suffix(gates_path.suffix + ".tmp")
        temporary.write_text(
            json.dumps(gates, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        temporary.replace(gates_path)
        return record
    except (BuildBlocked, FileNotFoundError, json.JSONDecodeError) as exc:
        if isinstance(exc, BuildBlocked) and "rebuild obligation:" in str(exc):
            raise
        raise _rebuild_obligation(str(exc)) from exc


def build(arguments: argparse.Namespace) -> dict[str, Any]:
    rows = read_rows(arguments.source)
    source_report, source_gates = validate_source(
        rows, arguments.source, arguments.probe
    )
    g6 = consume_m1(arguments.m1_artifact, source_report["source_sha256"])
    g6_strata = consume_m1_strata(
        arguments.strata_artifact,
        source_report["source_sha256"],
        G6_SUFFICIENCY_RULING,
    )
    chat = GemmaChatFormat()
    declarations = json.loads(arguments.tools.read_text(encoding="utf-8"))
    if not isinstance(declarations, list):
        raise BuildBlocked("tool declaration artifact is not a JSON list")
    tools = {tool["name"]: tool for tool in declarations}
    g1 = run_g1(chat, rows, tools)
    sequences = make_sequences(rows, arguments.seed)
    census = validate_census(sequences)

    rendered_sequences: list[SequenceRow] = []
    for sequence in sequences:
        if not all(source_gates[sequence.source_row_id].values()):
            raise BuildBlocked(f"{sequence.id} inherited a failed source gate")
        rendered = render_sequence(chat, sequence, tools)
        supervision = build_sequence(chat, rendered, sequence.kind)
        check_sequence(chat, rendered, supervision, sequence.kind)
        if len(rendered.ids) > MAX_LENGTH:
            raise BuildBlocked(
                f"{sequence.id} has {len(rendered.ids)} tokens; drop would break the census"
            )
        rendered_sequences.append(sequence.with_render(rendered, supervision.labels))

    write_sequences(rendered_sequences, arguments.output)
    g7 = account_artifact(arguments.output, chat, tools)
    if g7["sequences"] != EXPECTED_TOTAL:
        raise BuildBlocked(f"final artifact has {g7['sequences']} sequences")
    sequence_gate_counts = {name: len(rendered_sequences) for name in GATE_NAMES}
    summary = {
        "green": True,
        "output": str(arguments.output),
        "output_sha256": hashlib.sha256(arguments.output.read_bytes()).hexdigest(),
        "source": source_report,
        "dataset_gates": {
            "six_gate_chain_armed_on_final_sequences": sequence_gate_counts,
            "benchmark_13gram_gate": "PASS",
            "held_out_8gram_gate": "PASS",
        },
        "G1": {**g1, "all_sequence_wire_normalizations": len(rendered_sequences)},
        "G2": {
            "passed": True,
            "state_machine_sequences_checked": len(rendered_sequences),
            "terminal_close": CLOSE_TAIL,
        },
        "G6": {"class_A": g6, "strata": g6_strata},
        "G7": g7,
        "census": census,
        "seed": arguments.seed,
    }
    summary_path = arguments.output.with_name(f"{arguments.output.stem}-gates.json")
    summary_path.write_text(
        json.dumps(summary, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    summary["summary"] = str(summary_path)
    return summary


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=DEFAULT_SOURCE)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--probe", type=Path, default=DEFAULT_PROBE)
    parser.add_argument("--tools", type=Path, default=DEFAULT_TOOLS)
    parser.add_argument("--m1-artifact", type=Path, default=DEFAULT_M1)
    parser.add_argument("--strata-artifact", type=Path, default=DEFAULT_M1_STRATA)
    parser.add_argument(
        "--gates",
        type=Path,
        help="gate-summary path; verification defaults beside --output",
    )
    parser.add_argument(
        "--verify-built",
        action="store_true",
        help="verify the admitted artifact and append a green consume-gate record",
    )
    parser.add_argument("--seed", type=int, default=20260812)
    parser.add_argument(
        "--if-present",
        action="store_true",
        help="skip when local runtime inputs or Gemma assets are absent",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_args(argv)
    if arguments.verify_built:
        try:
            record = verify_built(arguments)
        except AssetsMissing:
            if arguments.if_present:
                print(
                    "SKIP wave-3 built verification: Gemma assets absent under "
                    f"{asset_dir()}"
                )
                return 0
            raise
        except BuildBlocked as exc:
            print(f"BLOCKED wave-3 built verification: {exc}", file=sys.stderr)
            return 1
        print(
            "VERIFICATION_RECORD "
            + json.dumps(record, ensure_ascii=False, sort_keys=True)
        )
        print(
            "PASS wave-3 built verification: G6 class-A and strata consume-gates "
            "plus G7 replay are green"
        )
        return 0

    required = [
        arguments.source,
        arguments.probe,
        arguments.tools,
        arguments.m1_artifact,
        arguments.strata_artifact,
    ]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        if arguments.if_present:
            print(
                "SKIP wave-3 sequence build: local inputs absent: " + "; ".join(missing)
            )
            return 0
        print(
            "BLOCKED wave-3 sequence build: required local inputs absent: "
            + "; ".join(missing),
            file=sys.stderr,
        )
        return 1
    try:
        summary = build(arguments)
    except AssetsMissing:
        if arguments.if_present:
            print(
                f"SKIP wave-3 sequence build: Gemma assets absent under {asset_dir()}"
            )
            return 0
        raise
    except BuildBlocked as exc:
        print(f"BLOCKED wave-3 sequence build: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    print(
        f"PASS wave-3 sequence build: {summary['census']['total']} sequences; "
        "G1/G2/G6/G7 and both overlap gates green"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
