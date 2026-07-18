#!/usr/bin/env python3
"""Run every witnesses.html default through one persistent Prolog worker."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
PAGE = ROOT / "more-zeeman" / "witnesses.html"
sys.path.insert(0, str(ROOT))

from hermes.app.worker import PersistentPrologError, PersistentPrologWorker  # noqa: E402


EXTRACT_JS = r"""
const fs = require("fs");
const vm = require("vm");
const html = fs.readFileSync(process.argv[1], "utf8");
const open = html.lastIndexOf("<script>");
const close = html.indexOf("</script>", open);
if (open < 0 || close < 0) throw new Error("inline witness script not found");
const script = html.slice(open + "<script>".length, close);
const strict = script.indexOf('"use strict";');
const stop = script.indexOf("function inOpMap", strict);
if (strict < 0 || stop < 0) throw new Error("witness data block not found");
const context = Object.create(null);
vm.createContext(context);
vm.runInContext(script.slice(strict + '"use strict";'.length, stop), context, {
  filename: process.argv[1]
});
const fields = [
  "id", "groups", "defaults", "examples", "fieldHints", "details",
  "listInputs", "numberInputs", "numberInputsByOp"
];
const output = context.families.map((family) => {
  const row = {};
  fields.forEach((field) => { if (family[field] !== undefined) row[field] = family[field]; });
  return row;
});
process.stdout.write(JSON.stringify(output));
"""

BOUNDARY_RE = re.compile(
    r"no_[a-z_]*witness|\bfound no\b|\bno recorded crosswalk record\b|"
    r"\bno [^\n]*recorded example\b",
    re.I,
)


def extract_families() -> list[dict[str, Any]]:
    """Evaluate the page's JavaScript data block instead of parsing JS as text."""
    proc = subprocess.run(
        ["node", "-e", EXTRACT_JS, str(PAGE)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode:
        raise RuntimeError(f"Node witness-data extraction failed: {proc.stderr.strip()}")
    value = json.loads(proc.stdout)
    if not isinstance(value, list) or not value:
        raise RuntimeError("Node witness-data extraction returned no families")
    return value


def in_op_map(mapping: dict[str, list[str]], op: str, name: str) -> bool:
    return name in mapping.get(op, [])


def page_value(family: dict[str, Any], op: str, name: str) -> Any:
    defaults = family.get("defaults", {}).get(op, {})
    if name in defaults:
        value = defaults[name]
    elif name in family.get("examples", {}):
        value = family["examples"][name]
    else:
        value = f"{name}_example"

    if family.get("listInputs", {}).get(name):
        if isinstance(value, list):
            return value
        return [part.strip() for part in str(value).split(",") if part.strip()]
    if family.get("numberInputs", {}).get(name) or in_op_map(
        family.get("numberInputsByOp", {}), op, name
    ) or (family["id"] == "geometry" and name == "level"):
        return float(value) if "." in str(value) else int(value)
    if family["id"] == "pml" and name == "clauses" and isinstance(value, str):
        return json.loads(value)
    return value


def error_text(response: dict[str, Any]) -> str:
    error = response.get("error", "")
    if isinstance(error, dict):
        return " ".join(str(error.get(key, "")) for key in ("code", "message"))
    return str(error)


def classify(response: dict[str, Any]) -> tuple[str, str]:
    if response.get("ok") is True:
        return "WITNESS", ""
    detail = error_text(response).strip()
    if BOUNDARY_RE.search(detail):
        return "BOUNDARY", detail
    return "ERROR", detail or "worker returned ok:false without error detail"


def main() -> int:
    try:
        families = extract_families()
    except (OSError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"witness defaults: ERROR: {exc}", file=sys.stderr)
        return 1

    rows: dict[str, list[tuple[str, str, str]]] = {}
    worker = PersistentPrologWorker(umedcta_root=ROOT, timeout=60.0)
    try:
        atlas = worker.request("capability_atlas")
        inputs_by_op = {
            item["name"]: item.get("inputs", []) for item in atlas.get("capabilities", [])
        }
        for family in families:
            family_rows: list[tuple[str, str, str]] = []
            for group in family["groups"]:
                for op in group["ops"]:
                    if op not in inputs_by_op:
                        family_rows.append((op, "ERROR", "op missing from capability atlas"))
                        continue
                    try:
                        input_names = list(inputs_by_op[op])
                        for name in family.get("defaults", {}).get(op, {}):
                            if name not in input_names:
                                input_names.append(name)
                        payload = {
                            name: page_value(family, op, name) for name in input_names
                        }
                        response = worker.raw_request({"op": op, **payload})
                        status, detail = classify(response)
                    except (PersistentPrologError, TypeError, ValueError, json.JSONDecodeError) as exc:
                        status, detail = "ERROR", str(exc)
                    family_rows.append((op, status, detail))
            rows[family["id"]] = family_rows
    except (PersistentPrologError, OSError, TypeError) as exc:
        print(f"witness defaults: ERROR: {exc}", file=sys.stderr)
        return 1
    finally:
        worker.close()

    print(f"{'family':<12} {'WITNESS':>7} {'BOUNDARY':>8} {'ERROR':>5} {'TOTAL':>5}")
    totals: Counter[str] = Counter()
    failed = False
    for family, family_rows in rows.items():
        counts = Counter(status for _, status, _ in family_rows)
        totals.update(counts)
        print(
            f"{family:<12} {counts['WITNESS']:>7} {counts['BOUNDARY']:>8} "
            f"{counts['ERROR']:>5} {len(family_rows):>5}"
        )
        if counts["ERROR"] or counts["WITNESS"] * 2 < len(family_rows):
            failed = True
        for op, status, detail in family_rows:
            if status != "WITNESS":
                print(f"  {status:<8} {op}: {detail}")
    print(
        f"{'TOTAL':<12} {totals['WITNESS']:>7} {totals['BOUNDARY']:>8} "
        f"{totals['ERROR']:>5} {sum(totals.values()):>5}"
    )
    if failed:
        print("witness defaults: FAIL", file=sys.stderr)
        return 1
    print("witness defaults: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
