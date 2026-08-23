#!/usr/bin/env python3
"""Build the public index of every shipped Hermes HTML entrance."""
from __future__ import annotations

import argparse
import html
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_WEB = ROOT / "hermes" / "app" / "web"
HERMES_WEB = ROOT / "hermes" / "web"
GENERATED = APP_WEB / "generated"
MANIFEST = ROOT / "scripts" / "bundle" / "app_manifest.txt"
OUTPUT = APP_WEB / "surfaces.html"


def title_for(path: Path) -> str:
    if path == OUTPUT:
        return "Hermes page index"
    text = path.read_text(encoding="utf-8", errors="replace") if path.is_file() else ""
    start = text.lower().find("<title>")
    end = text.lower().find("</title>", start + 7)
    if start >= 0 and end >= 0:
        return html.unescape(text[start + 7 : end].strip()).replace(" — ", ": ").replace("—", "-")
    return path.stem.replace("_", " ").replace("-", " ").title()


def tracked_generated_indexes() -> list[Path]:
    prefix = "hermes/app/web/generated/"
    paths: list[Path] = []
    for raw in MANIFEST.read_text(encoding="utf-8").splitlines():
        value = raw.strip()
        if value.startswith(prefix) and value.endswith("/index.html"):
            path = ROOT / value
            if not path.is_file():
                raise FileNotFoundError(f"tracked generated index is missing: {value}")
            paths.append(path)
    return paths


def surface_inventory() -> tuple[list[Path], list[Path], list[Path]]:
    app_pages = sorted(APP_WEB.glob("*.html"))
    if OUTPUT not in app_pages:
        app_pages.append(OUTPUT)
        app_pages.sort()
    tool_pages = sorted(HERMES_WEB.rglob("*.html"))
    generated = sorted(set(tracked_generated_indexes()) | set(GENERATED.rglob("*.html")))
    return app_pages, tool_pages, generated


def link(href: str, label: str, detail: str = "") -> str:
    detail_html = f"<span>{html.escape(detail)}</span>" if detail else ""
    return (
        f'<li><a href="{html.escape(href, quote=True)}">'
        f"{html.escape(label)}{detail_html}</a></li>"
    )


def render() -> str:
    app_pages, tool_pages, generated = surface_inventory()
    groups: dict[str, list[Path]] = defaultdict(list)
    for path in generated:
        relative = path.relative_to(GENERATED)
        groups[relative.parts[0]].append(path)

    app_rows = "\n".join(
        link("/" if path.name == "console.html" else f"/{path.name}", title_for(path), path.name)
        for path in app_pages
    )
    tool_rows = "\n".join(
        link(
            f"/more-zeeman/{path.relative_to(HERMES_WEB).as_posix()}",
            title_for(path),
            path.relative_to(HERMES_WEB).as_posix(),
        )
        for path in tool_pages
    )
    generated_sections: list[str] = []
    for group in sorted(groups):
        rows = []
        for path in groups[group]:
            relative = path.relative_to(GENERATED)
            rows.append(
                link(
                    f"/generated/{relative.as_posix()}",
                    title_for(path),
                    relative.as_posix(),
                )
            )
        generated_sections.append(
            f'<details><summary>{html.escape(group)} <span>{len(rows)} page(s)</span></summary>'
            f'<ul>{"".join(rows)}</ul></details>'
        )

    total = len(app_pages) + len(tool_pages) + len(generated)
    return f'''<!doctype html>
<html lang="en" data-hermes-base="light">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>Hermes page index</title>
<link rel="stylesheet" href="../more-zeeman/hermes-tokens.css" />
<script defer src="../more-zeeman/render/hermes-shell.js" data-root="../more-zeeman/" data-app="./" data-active="surfaces"></script>
<style>
*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font:16px/1.5 var(--serif)}}
.wrap{{max-width:72rem;margin:0 auto;padding:1.5rem 1.3rem 4rem}}h1{{margin:0 0:.3rem}}
.lede{{max-width:64ch;color:var(--muted)}}.cols{{display:grid;grid-template-columns:1fr 1fr;gap:1.2rem}}
section,details{{border:1px solid var(--line);border-radius:8px;background:rgba(255,253,247,.65);padding:.7rem .9rem;margin:.7rem 0}}
section h2{{margin:.1rem 0 .4rem;font-size:1.1rem}}summary{{cursor:pointer;font-weight:600}}summary span,li span{{color:var(--muted);font-size:.78rem;margin-left:.5rem}}
ul{{margin:.35rem 0;padding-left:1.25rem}}li{{margin:.25rem 0;overflow-wrap:anywhere}}
@media(max-width:720px){{.cols{{grid-template-columns:1fr}}}}
</style>
</head>
<body><main class="wrap">
<h1>Hermes page index</h1>
<p class="lede">This generated index links {total} HTML entrances shipped with the app. The capability Atlas groups operations; this page inventories files.</p>
<div class="cols"><section><h2>Workspace pages</h2><ul>{app_rows}</ul></section>
<section><h2>Mathematics and research pages</h2><ul>{tool_rows}</ul></section></div>
<h2>Generated galleries, lesson charts, demonstrations, and reports</h2>
{''.join(generated_sections)}
</main></body></html>
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = render()
    if args.check:
        actual = OUTPUT.read_text(encoding="utf-8") if OUTPUT.is_file() else ""
        if actual != expected:
            print(f"STALE {OUTPUT.relative_to(ROOT)}")
            return 1
        _, _, generated = surface_inventory()
        missing = [
            path.relative_to(GENERATED).as_posix()
            for path in generated
            if f'/generated/{path.relative_to(GENERATED).as_posix()}' not in actual
        ]
        if missing:
            for path in missing:
                print(f"MISSING LINK {path}")
            return 1
        print(f"PASS HTML surface index: {actual.count('<li>')} linked pages")
        return 0
    OUTPUT.write_text(expected, encoding="utf-8")
    print(OUTPUT.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
