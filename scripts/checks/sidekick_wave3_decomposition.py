#!/usr/bin/env python3
"""Focused contracts for wave-3 decomposition gates G1, G6, and census."""

from __future__ import annotations

import json
import os
import platform
import shutil
import sys
import tempfile
from pathlib import Path

if sys.platform == "darwin" and platform.machine() == "x86_64":
    os.execvp("arch", ["arch", "-arm64", sys.executable, *sys.argv])

ROOT = Path(__file__).resolve().parents[2]
SIDEKICK = ROOT / "scripts" / "sidekick"
for candidate in (str(ROOT), str(SIDEKICK)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

from build_wave3_sequences import (  # noqa: E402
    G6_SUFFICIENCY_RULING,
    BuildBlocked,
    DEFAULT_M1,
    DEFAULT_M1_STRATA,
    DEFAULT_OUTPUT,
    DEFAULT_SOURCE,
    DEFAULT_TOOLS,
    EXPECTED_TOTAL,
    consume_m1,
    consume_m1_strata,
    evaluate_m1,
    make_sequences,
    parse_args,
    run_g1,
    validate_census,
    verify_built,
)
from chat_format import AssetsMissing, GemmaChatFormat, asset_dir  # noqa: E402
from dataset import read as read_rows  # noqa: E402


def record(ids: list[int] | None, *, close: bool = True, stop: str = "eos") -> dict:
    return {
        "close_found": close,
        "tail_token_ids": ids,
        "raw_tail_text": "",
        "stop_reason_fields": {"stop": True, "stop_type": stop},
    }


def check_g6_total_function() -> None:
    no_call = record(None, close=False)
    cases = {
        "a": [record([106])] * 8 + [record([77])] * 2,
        "b": [record([1])] * 8 + [record([77])] * 2,
        "c": [record([50])] * 8 + [record([77])] * 2,
        "d": [record([77], stop="limit")] * 8 + [record([78])] * 2,
        "e": [record([50])] * 5 + [record([1])] * 5,
    }
    observed = {name: evaluate_m1(rows)["outcome"] for name, rows in cases.items()}
    assert observed == {name: name for name in cases}, observed

    denominator = evaluate_m1([record([50])] * 10 + [no_call] * 6)
    assert denominator["outcome"] == "c"
    assert denominator["call_bearing"] == 10
    assert denominator["disposition_only"] == 6
    assert denominator["required"] == 8

    below = evaluate_m1([record([50])] * 7 + [record([77])] * 3 + [no_call] * 20)
    assert below["outcome"] == "e"
    assert below["required"] == 8
    assert evaluate_m1([no_call] * 12)["outcome"] == "d"
    print(
        "PASS G6 total outcome function: a-e exclusive; call-bearing denominator fixed"
    )


def expect_strata_refusal(
    path: Path, source_sha: str, ruling: str | None, text: str
) -> None:
    try:
        consume_m1_strata(path, source_sha, ruling)
    except BuildBlocked as failure:
        assert text in str(failure), failure
    else:
        raise AssertionError(f"G6 strata consume-gate accepted {text}")


def main() -> int:
    check_g6_total_function()
    required = [DEFAULT_SOURCE, DEFAULT_TOOLS, DEFAULT_M1, DEFAULT_M1_STRATA]
    missing = [str(path) for path in required if not path.is_file()]
    if missing:
        print(
            "SKIP live G1/G6/census checks: local inputs absent: " + "; ".join(missing)
        )
        return 0
    try:
        chat = GemmaChatFormat()
    except AssetsMissing:
        print(f"SKIP live G1/census checks: Gemma assets absent under {asset_dir()}")
        return 0

    rows = read_rows(DEFAULT_SOURCE)
    declarations = json.loads(DEFAULT_TOOLS.read_text(encoding="utf-8"))
    tools = {tool["name"]: tool for tool in declarations}
    g1 = run_g1(chat, rows, tools)
    assert g1["passed"] is True
    assert [row["shape"] for row in g1["four_shape_render"]] == [
        "A reply",
        "B second call",
        "B reply",
        "D relay",
    ]
    assert all(row["token_id_equivalence"] for row in g1["four_shape_render"])
    print(
        "PASS G1 four-shape render: mappings -> wire strings -> mappings preserve token ids"
    )

    source_sha = __import__("hashlib").sha256(DEFAULT_SOURCE.read_bytes()).hexdigest()
    g6 = consume_m1(DEFAULT_M1, source_sha)
    assert g6["outcome"] == "c"
    assert g6["call_bearing"] == 10 and g6["disposition_only"] == 6
    assert g6["close_parameter"] == [50, 1]
    print("PASS live G6 artifact: 10/10 call-bearing tails authorize close [50, 1]")

    with tempfile.TemporaryDirectory(prefix="sidekick-wave3-check-") as directory:
        temporary = Path(directory)
        expect_strata_refusal(
            temporary / "absent.json",
            source_sha,
            G6_SUFFICIENCY_RULING,
            "artifact is absent",
        )
        print("PASS G6 strata artifact-absent refusal")

        mismatched = json.loads(DEFAULT_M1_STRATA.read_text(encoding="utf-8"))
        first = next(iter(mismatched["stratum_summaries"].values()))
        first["classification"]["outcome"] = "d"
        mismatch_path = temporary / "outcome-mismatch.json"
        mismatch_path.write_text(
            json.dumps(mismatched, ensure_ascii=False) + "\n", encoding="utf-8"
        )
        expect_strata_refusal(
            mismatch_path,
            source_sha,
            G6_SUFFICIENCY_RULING,
            "outcome mismatch",
        )
        print("PASS G6 strata outcome-mismatch refusal")

        expect_strata_refusal(
            DEFAULT_M1_STRATA,
            source_sha,
            None,
            "lacks ruling",
        )
        print("PASS G6 thin-stratum-without-ruling refusal")

        gates_source = DEFAULT_OUTPUT.with_name(f"{DEFAULT_OUTPUT.stem}-gates.json")
        gates_copy = temporary / gates_source.name
        shutil.copy2(gates_source, gates_copy)
        verify_arguments = parse_args(
            [
                "--verify-built",
                "--output",
                str(DEFAULT_OUTPUT),
                "--gates",
                str(gates_copy),
            ]
        )
        verification = verify_built(verify_arguments)
        written = json.loads(gates_copy.read_text(encoding="utf-8"))
        assert written["verification_records"][-1] == verification
        assert verification["built_dataset_sha256"].startswith("fea3e1f3")
        assert (
            verification["strata_artifact_sha256"]
            == __import__("hashlib").sha256(DEFAULT_M1_STRATA.read_bytes()).hexdigest()
        )
        print(
            "PASS G6 green verification path appends both artifact shas after G7 replay"
        )

    sequences = make_sequences(rows, 20260812)
    census = validate_census(sequences)
    assert census["total"] == EXPECTED_TOTAL
    assert census["C_share"] == 0.4
    print("PASS wave-3 census: 10,860 sequences and bare-prefix C share 0.400")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
