#!/usr/bin/env python3
"""Check HTML surfaces for dead literal API calls and local asset drift."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from urllib.parse import urlsplit


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WEB_ROOTS = [
    ROOT / "hermes" / "app" / "web",
    ROOT / "more-zeeman",
]
DEFAULT_SERVER = ROOT / "hermes" / "app" / "server.py"

API_LITERAL_RE = re.compile(r"""["'`](/api/[A-Za-z0-9_./:-]+(?:\?[^"'`]*)?)["'`]""")
ASSET_RE = re.compile(
    r"""<(?:script|link|img|iframe|source)\b[^>]*\b(?:src|href)=["']([^"']+)["']""",
    re.IGNORECASE,
)
SNAPSHOT_RE = re.compile(r"\bSNAPSHOT_URL\b|mua_data\.json|frozen_snapshot", re.IGNORECASE)
LEGACY_FALLBACK_ROUTES = {"/api/base", "/api/cgi_dispatch", "/api/action/topology/gaps"}
# learner/server.pl routes. The pages that call them carry a visible
# under-construction notice until the wing is wired (refactor plan, Tier 1).
RESEARCH_WING_ROUTES = {"/api/compute", "/api/knowledge",
                        "/api/visualize/coordination"}


def iter_html_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    for root in roots:
        if root.is_file() and root.suffix.lower() == ".html":
            files.append(root)
        elif root.is_dir():
            files.extend(path for path in root.rglob("*.html") if path.is_file())
    return sorted(files)


def server_routes(server: Path) -> tuple[set[str], list[str]]:
    text = server.read_text(encoding="utf-8")
    exact = set(re.findall(r"""(?:self\.path|raw_path)\s*==\s*["'](/api/[^"']+)["']""", text))
    exact |= set(re.findall(r"""route\s*==\s*["'](/api/[^"']+)["']""", text))
    prefixes = re.findall(
        r"""(?:self\.path|raw_path)\.startswith\(["'](/api/[^"']+)["']\)""", text
    )
    workflow_dir = server.parent / "workflow"
    if workflow_dir.exists():
        exact |= {f"/api/{path.stem}" for path in workflow_dir.glob("*.py")}
    return exact, prefixes


def normalize_api(path: str) -> str:
    return urlsplit(path).path.rstrip("/") or path


def route_known(path: str, exact: set[str], prefixes: list[str]) -> bool:
    normalized = normalize_api(path)
    return (
        normalized in exact
        or normalized in LEGACY_FALLBACK_ROUTES
        or normalized in RESEARCH_WING_ROUTES
        or any(normalized.startswith(prefix) for prefix in prefixes)
    )


def local_asset_target(target: str) -> str | None:
    if not target or target.startswith(("#", "data:", "mailto:", "tel:", "javascript:")):
        return None
    if target.startswith(("http://", "https://", "//", "/api/")):
        return None
    if "{" in target or "}" in target:
        return None
    return urlsplit(target).path


def asset_exists(html: Path, target: str, web_roots: list[Path]) -> bool:
    if target.startswith("/"):
        rel = target.lstrip("/")
        return any((root / rel).exists() for root in web_roots)
    if (html.parent / target).exists():
        return True
    normalized = target.replace("\\", "/")
    marker = "more-zeeman/"
    if marker in normalized:
        rel = normalized[normalized.index(marker):]
        return (ROOT / rel).exists()
    return False


def issue(kind: str, html: Path, target: str, detail: str) -> dict[str, str]:
    return {
        "type": kind,
        "file": html.relative_to(ROOT).as_posix() if html.is_relative_to(ROOT) else html.as_posix(),
        "target": target,
        "detail": detail,
    }


def scan_html(html: Path, web_roots: list[Path], exact: set[str], prefixes: list[str]) -> list[dict[str, str]]:
    text = html.read_text(encoding="utf-8")
    issues: list[dict[str, str]] = []

    for api in sorted(set(API_LITERAL_RE.findall(text))):
        if not route_known(api, exact, prefixes):
            issues.append(issue("dead_api", html, normalize_api(api), "literal API route not found in server"))

    for asset in sorted(set(ASSET_RE.findall(text))):
        target = local_asset_target(asset)
        if target is not None and not asset_exists(html, target, web_roots):
            issues.append(issue("missing_asset", html, target, "local src/href target does not exist"))

    return issues


def build_report(web_roots: list[Path], server: Path) -> dict[str, object]:
    exact, prefixes = server_routes(server)
    html_files = iter_html_files(web_roots)
    issues: list[dict[str, str]] = []
    notes: list[dict[str, str]] = []
    for html in html_files:
        issues.extend(scan_html(html, web_roots, exact, prefixes))
        text = html.read_text(encoding="utf-8")
        if SNAPSHOT_RE.search(text):
            notes.append(issue(
                "frozen_snapshot", html, "snapshot marker",
                "surface reads a static snapshot; its regenerator is named in the page or the refactor plan",
            ))
    return {
        "server": server.as_posix(),
        "web_roots": [root.as_posix() for root in web_roots],
        "html_files": len(html_files),
        "api_routes": len(exact),
        "api_prefixes": prefixes,
        "issues": issues,
        "notes": notes,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--server", type=Path, default=DEFAULT_SERVER)
    parser.add_argument("--web-root", type=Path, action="append", dest="web_roots")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = parser.parse_args()

    web_roots = args.web_roots or DEFAULT_WEB_ROOTS
    report = build_report([root.resolve() for root in web_roots], args.server.resolve())

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"HTML files: {report['html_files']}")
        print(f"API routes: {report['api_routes']}")
        print(f"Issues: {len(report['issues'])}")
        for row in report["issues"]:
            print(f"{row['type']}: {row['file']} -> {row['target']} ({row['detail']})")
        for row in report["notes"]:
            print(f"note {row['type']}: {row['file']} -> {row['target']} ({row['detail']})")

    return 1 if report["issues"] else 0


if __name__ == "__main__":
    sys.exit(main())
