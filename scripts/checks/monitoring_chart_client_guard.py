#!/usr/bin/env python3
"""Exercise the monitoring page's cached field-context error guard."""
from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PAGE = ROOT / "hermes/web/monitoring_chart.html"


def function_source(source: str, name: str) -> str:
    marker = f"function {name}("
    start = source.find(marker)
    if start < 0:
        raise SystemExit(f"{name} is absent from {PAGE.relative_to(ROOT)}")
    brace = source.find("{", start)
    depth = 0
    for position in range(brace, len(source)):
        if source[position] == "{":
            depth += 1
        elif source[position] == "}":
            depth -= 1
            if depth == 0:
                return source[start : position + 1]
    raise SystemExit(f"{name} has unbalanced braces")


def main() -> int:
    field_fetch = function_source(PAGE.read_text(encoding="utf-8"), "fetchFieldContext")
    program = f"""
const HermesFetch = {{
  HEAVY_PROLOG_TIMEOUT_MS: 1,
  requestJSON: () => Promise.resolve({{ok: true, result: {{error: 'field_context_dict/2 failed'}}}}),
  requireOK: value => value
}};
{field_fetch}
fetchFieldContext('IM-G4-U2-L1').then(
  () => {{ throw new Error('cached error reached the renderer'); }},
  error => {{
    if (error.message !== 'field_context_dict/2 failed') throw error;
    console.log('PASS monitoring chart client guard: nested cached error rejected');
  }}
);
"""
    completed = subprocess.run(
        ["node", "-e", program], cwd=ROOT, text=True, capture_output=True
    )
    if completed.returncode:
        raise SystemExit(completed.stderr.strip() or completed.stdout.strip())
    print(completed.stdout.strip())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
