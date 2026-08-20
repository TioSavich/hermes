#!/usr/bin/env python3
"""Build the readable module index from the capability registry."""
from __future__ import annotations

import html
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REGISTRY = ROOT / "hermes/capability_registry.pl"
OUTPUT = ROOT / "hermes/web/generated/data_store_index.html"
REGISTRY_ROW = re.compile(
    r"^capability\('([^']+)', '([^']+)', '([^']+)', \[(.*?)\], ([a-z_]+)\)\.$"
)
MODULE_DECL = re.compile(r":-\s*module\(\s*(?:'([^']+)'|([a-z][a-zA-Z0-9_]*))", re.MULTILINE)
TOP_LEVEL_CLAUSE = re.compile(r"^([a-z][a-zA-Z0-9_]*)\s*(?:\(|\.)", re.MULTILINE)
SUMMARY_BLOCK = re.compile(
    r"^[a-z][a-zA-Z0-9_]*summary\s*(\([^:]*?\)\s*:-\s*.*?)(?=\n\s*\n|\Z)",
    re.MULTILINE | re.DOTALL,
)
AGGREGATE_COUNT = re.compile(r"aggregate_all\(\s*count\s*,\s*([a-z][a-zA-Z0-9_]*)\s*\(")

STATUS_GROUP = {
    "routed_paged": "routed",
    "routed_only": "routed",
    "lazy_reachable": "lazy",
    "unrouted": "check-only",
    "orphan_module": "orphan by convention",
}
GROUP_ORDER = ("routed", "lazy", "check-only", "orphan by convention")
GROUP_NOTE = {
    "routed": "At least one registered operation has an app route.",
    "lazy": "The app loads these modules when a named operation needs them.",
    "check-only": "These modules are registered without an app route.",
    "orphan by convention": "These shipped modules remain outside the default and bounded lazy-load closures.",
}


@dataclass(frozen=True)
class RegistryRow:
    name: str
    module: str
    status: str


@dataclass(frozen=True)
class ModuleRow:
    module: str
    status: str
    row_count: int
    description: str


def parse_registry() -> list[RegistryRow]:
    rows: list[RegistryRow] = []
    for line in REGISTRY.read_text(encoding="utf-8").splitlines():
        match = REGISTRY_ROW.match(line)
        if match:
            rows.append(RegistryRow(match.group(1), match.group(2), match.group(5)))
    if not rows:
        raise ValueError("capability registry contains no capability rows")
    return rows


def prolog_sources() -> list[Path]:
    excluded = {".git", ".claude", ".superpowers", ".bigred-collected", ".bigred-output"}
    return sorted(
        path for path in ROOT.rglob("*.pl")
        if not excluded.intersection(path.relative_to(ROOT).parts)
    )


def module_source_index(paths: list[Path]) -> dict[str, list[Path]]:
    result: dict[str, list[Path]] = defaultdict(list)
    for path in paths:
        text = path.read_text(encoding="utf-8", errors="replace")
        match = MODULE_DECL.search(text)
        if match:
            result[match.group(1) or match.group(2)].append(path)
    return result


def source_for(module: str, rows: list[RegistryRow], index: dict[str, list[Path]]) -> Path | None:
    named_paths = [ROOT / row.name for row in rows if row.name.endswith(".pl")]
    named_paths = [path for path in named_paths if path.is_file()]
    if named_paths:
        return sorted(named_paths)[0]
    if module in {"user", "hermes_worker"}:
        return ROOT / "hermes_worker.pl"
    candidates = index.get(module, [])
    return sorted(candidates, key=lambda path: (len(path.relative_to(ROOT).parts), path.as_posix()))[0] if candidates else None


def first_header_sentence(text: str) -> str:
    block_match = re.search(r"/\*\*(.*?)\*/", text, re.DOTALL)
    if block_match:
        lines = []
        for raw in block_match.group(1).splitlines():
            line = re.sub(r"^\s*\*\s?", "", raw).strip()
            line = re.sub(r"^<module>\s*", "", line)
            if line:
                lines.append(line)
            elif lines:
                break
        paragraph = " ".join(lines)
    else:
        lines = []
        comment_blocks = re.findall(r"(?:^%[^\n]*\n)+", text, re.MULTILINE)
        for block in comment_blocks:
            candidate = []
            for raw in block.splitlines():
                match = re.match(r"^%+\s?(.*)$", raw)
                if not match:
                    continue
                line = match.group(1).strip()
                if line.startswith("!"):
                    continue
                if line:
                    candidate.append(line)
            if candidate:
                lines = candidate
                break
        paragraph = " ".join(lines)
    paragraph = re.sub(r"\s+", " ", paragraph).strip()
    sentence = re.match(r"(.+?[.!?])(?:\s|$)", paragraph)
    return sentence.group(1) if sentence else paragraph


def clause_count(text: str) -> int:
    counts: dict[str, int] = defaultdict(int)
    for match in TOP_LEVEL_CLAUSE.finditer(text):
        counts[match.group(1)] += 1
    for block in SUMMARY_BLOCK.findall(text):
        if "row_count" not in block:
            continue
        counted = AGGREGATE_COUNT.search(block)
        if counted and counts.get(counted.group(1)):
            return counts[counted.group(1)]
    return sum(counts.values())


def combined_status(statuses: set[str]) -> str:
    groups = {STATUS_GROUP[status] for status in statuses}
    for group in GROUP_ORDER:
        if group in groups:
            return group
    raise ValueError(f"unrecognized registry statuses: {sorted(statuses)}")


def module_rows() -> list[ModuleRow]:
    registry_rows = parse_registry()
    by_module: dict[str, list[RegistryRow]] = defaultdict(list)
    for row in registry_rows:
        by_module[row.module].append(row)
    sources = module_source_index(prolog_sources())
    result: list[ModuleRow] = []
    for module, rows in sorted(by_module.items()):
        source = source_for(module, rows, sources)
        if source is None:
            description = ""
            count = 0
        else:
            text = source.read_text(encoding="utf-8", errors="replace")
            description = first_header_sentence(text)
            count = clause_count(text)
        result.append(ModuleRow(
            module=module,
            status=combined_status({row.status for row in rows}),
            row_count=count,
            description=description,
        ))
    return result


def esc(value: object) -> str:
    return html.escape(str(value), quote=True)


def render(rows: list[ModuleRow]) -> str:
    grouped = {group: [row for row in rows if row.status == group] for group in GROUP_ORDER}
    sections = []
    for group in GROUP_ORDER:
        body = "\n".join(
            "<tr>"
            f"<td><code>{esc(row.module)}</code></td>"
            f"<td>{esc(row.status)}</td>"
            f"<td class=number>{row.row_count}</td>"
            f"<td>{esc(row.description) if row.description else '<span aria-label=\"No authored header sentence\">&#8212;</span>'}</td>"
            "</tr>"
            for row in grouped[group]
        )
        sections.append(f"""<section>
      <h2>{esc(group.title())} <span>{len(grouped[group])}</span></h2>
      <p>{esc(GROUP_NOTE[group])}</p>
      <div class=table-wrap><table>
        <thead><tr><th>Module</th><th>Status</th><th>Rows</th><th>Description</th></tr></thead>
        <tbody>{body}</tbody>
      </table></div>
    </section>""")
    section_html = "\n".join(sections)
    return f"""<!DOCTYPE html>
<html lang=en>
<head>
  <meta charset=utf-8>
  <meta name=viewport content="width=device-width, initial-scale=1">
  <title>Data-store index — Hermes</title>
  <link rel=stylesheet href=../hermes-tokens.css>
  <script defer src=../render/hermes-shell.js data-root=../ data-app=/ data-active=research></script>
  <style>
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; color: var(--ink); background: var(--paper); }}
    main {{ max-width: 1180px; margin: 0 auto; padding: 2rem 1.25rem 4rem; }}
    h1 {{ margin-bottom: .3rem; }}
    .lede, section > p {{ max-width: 72ch; color: var(--muted); }}
    section {{ margin-top: 2rem; }}
    h2 {{ margin-bottom: .2rem; font-size: 1.2rem; }}
    h2 span {{ color: var(--muted); font: .75rem var(--mono); }}
    .table-wrap {{ overflow-x: auto; border: 1px solid var(--line); border-radius: 8px; }}
    table {{ width: 100%; border-collapse: collapse; background: var(--paper-cool); font-size: .86rem; }}
    th, td {{ padding: .55rem .65rem; border-bottom: 1px solid var(--line); text-align: left; vertical-align: top; }}
    th {{ font: .72rem var(--mono); text-transform: uppercase; letter-spacing: .04em; }}
    td code {{ font: .78rem var(--mono); overflow-wrap: anywhere; }}
    td.number {{ text-align: right; font-family: var(--mono); }}
    tbody tr:last-child td {{ border-bottom: 0; }}
  </style>
</head>
<body>
  <main>
    <h1>Data-store index</h1>
    <p class=lede>A generated list of the {len(rows)} Prolog modules named in the capability registry, grouped by how the app reaches them.</p>
    {section_html}
  </main>
</body>
</html>
"""


def main() -> int:
    rows = module_rows()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(render(rows), encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({len(rows)} modules)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
