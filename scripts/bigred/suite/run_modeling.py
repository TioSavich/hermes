#!/usr/bin/env python3
"""Execute contracted action automata over a small offline input neighborhood."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
import sys
sys.path.insert(0, str(ROOT))

from hermes.mcp.server import HermesMCPServer

ROW = re.compile(r"^automaton_input_contract\(([^,]+), ([^,]+), '(.+)', '(.+)', verified\(([^)]+)\)\)\.$")


def contracts() -> list[dict]:
    path = ROOT / "knowledge/strategies/automaton_input_contracts.pl"
    result = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = ROW.match(line)
        if not match:
            continue
        operation, kind, template, example, verified = match.groups()
        result.append({"operation": operation, "kind": kind,
                       "template": json.loads(template.replace(r'\"', '"')),
                       "example": json.loads(example.replace(r'\"', '"')),
                       "verified": verified})
    return result


def neighborhood(contract: dict) -> list[dict]:
    example = contract["example"]
    if example.get("kind") == "fraction_pair":
        return [example, {"kind": "fraction_pair", "left": {"n": 1, "d": 2}, "right": {"n": 1, "d": 3}}]
    if example.get("kind") == "decimal_pair":
        return [example, {"kind": "decimal_pair", "left": {"numeral": 12, "scale": 10}, "right": {"numeral": 3, "scale": 10}}]
    return [example, {"a": 12, "b": 3}, {"a": 7, "b": 2}]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.limit < 0:
        parser.error("--limit must be nonnegative")
    rows = contracts()
    if args.limit:
        rows = rows[:args.limit]
    args.output.mkdir(parents=True, exist_ok=True)
    server = HermesMCPServer("core", ROOT)
    try:
        index = []
        for contract in rows:
            results = []
            for input_value in neighborhood(contract):
                value = server._worker_request("strategy_trace", strategy=contract["kind"], input=input_value)
                results.append({"input": input_value, "ok": bool(value.get("ok")), "result": value.get("result", ""), "note": value.get("note", "")})
            filename = f"{contract['operation']}--{contract['kind']}.json"
            (args.output / filename).write_text(json.dumps({**contract, "results": results}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
            index.append({"operation": contract["operation"], "kind": contract["kind"], "file": filename,
                          "runs": len(results), "successful_runs": sum(row["ok"] for row in results)})
        (args.output / "index.json").write_text(json.dumps({"scenario": "modeling", "contracted": len(rows), "uncontracted": 172 - len(contracts()), "signatures": index}, indent=2) + "\n", encoding="utf-8")
    finally:
        server.close()


if __name__ == "__main__":
    main()
