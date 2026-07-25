#!/usr/bin/env python3
"""Hold the generated self-description census to its evidence and counts."""
from __future__ import annotations

import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
BUILDER = ROOT / "scripts/research/build_self_description_census.py"
JSON_PATH = ROOT / "data/research/self_description_census.json"
REPORT_PATH = ROOT / "docs/research/2026-07-25-what-the-repo-knows-about-itself.md"
REGISTRY = ROOT / "hermes/capability_registry.pl"
EXPECTED_VERDICTS = {
    "consumed_by_check",
    "consumed_by_builder",
    "include_active",
    "deliberately_unloaded",
    "stalled_input",
    "superseded",
    "undetermined",
}
CAPABILITY_RE = re.compile(
    r"^capability\('[^']+', '[^']+', '([^']+)', \[.*\], ([a-z_]+)\)\.$"
)


def fail(message: str) -> "NoReturn":
    print(f"self_description_census.py: {message}", file=sys.stderr)
    raise SystemExit(1)


def run_builder() -> None:
    result = subprocess.run(
        [sys.executable, str(BUILDER)],
        cwd=ROOT,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode:
        detail = result.stderr.strip() or result.stdout.strip() or "no diagnostic"
        fail(f"builder failed: {detail}")


def artifact_bytes() -> tuple[bytes, bytes]:
    missing = [path for path in (JSON_PATH, REPORT_PATH) if not path.is_file()]
    if missing:
        fail("missing generated artifact: " + ", ".join(str(path) for path in missing))
    return JSON_PATH.read_bytes(), REPORT_PATH.read_bytes()


def check_determinism() -> tuple[dict[str, object], str]:
    before = artifact_bytes()
    run_builder()
    first = artifact_bytes()
    run_builder()
    second = artifact_bytes()
    if before != first:
        fail("generated census is stale; run the builder")
    if first != second:
        fail("two consecutive builder runs are not byte-identical")
    try:
        return json.loads(second[0]), second[1].decode("utf-8")
    except (json.JSONDecodeError, UnicodeDecodeError) as exc:
        fail(f"generated artifact cannot be parsed: {exc}")


def evidence_groups(data: dict[str, object]):
    for row in data.get("orphan_modules", []):
        yield row.get("path", "orphan row"), row.get("evidence", [])
    for row in data.get("proposed_classes", []):
        yield f"proposed class {row.get('name')}", row.get("evidence", [])
    for row in data.get("unrouted", []):
        yield f"unrouted {row.get('name')}", row.get("evidence", [])


def check_evidence(data: dict[str, object]) -> int:
    checked = 0
    for owner, items in evidence_groups(data):
        if not items:
            fail(f"{owner} has no named evidence")
        for item in items:
            rel = item.get("path")
            locator = item.get("locator")
            if not isinstance(rel, str) or not rel:
                fail(f"{owner} has evidence without a path")
            if not isinstance(locator, str) or not locator:
                fail(f"{owner} has evidence without a locator")
            path = (ROOT / rel).resolve()
            try:
                path.relative_to(ROOT.resolve())
            except ValueError:
                fail(f"{owner} names evidence outside the repository: {rel}")
            if not path.is_file():
                fail(f"{owner} names missing evidence: {rel}")
            text = path.read_text(encoding="utf-8", errors="replace")
            if locator not in text:
                fail(f"{owner} has a dead evidence locator in {rel}: {locator!r}")
            checked += 1
    return checked


def registry_counts() -> tuple[Counter[str], Counter[str]]:
    status_counts: Counter[str] = Counter()
    class_counts: Counter[str] = Counter()
    for line in REGISTRY.read_text(encoding="utf-8").splitlines():
        match = CAPABILITY_RE.match(line)
        if not match:
            continue
        class_counts[match.group(1)] += 1
        status_counts[match.group(2)] += 1
    return status_counts, class_counts


def check_counts(data: dict[str, object], report: str) -> None:
    counts = data.get("counts")
    if not isinstance(counts, dict):
        fail("JSON has no counts object")
    orphan_rows = data.get("orphan_modules")
    class_rows = data.get("class_resolution")
    unrouted_rows = data.get("unrouted")
    if not isinstance(orphan_rows, list) or not isinstance(class_rows, list):
        fail("JSON row collections are malformed")
    if not isinstance(unrouted_rows, list):
        fail("JSON unrouted collection is malformed")

    live_status_counts, live_class_counts = registry_counts()
    status_counts = counts.get("by_status")
    if status_counts != dict(sorted(live_status_counts.items())):
        fail("JSON status counts do not match capability_registry.pl")
    if counts.get("by_class") != dict(sorted(live_class_counts.items())):
        fail("JSON class counts do not match capability_registry.pl")
    if counts.get("total") != sum(status_counts.values()):
        fail("JSON total does not equal the status-count sum")
    if counts.get("orphan_verdicts") != {
        verdict: sum(row.get("verdict") == verdict for row in orphan_rows)
        for verdict in (
            "consumed_by_check",
            "consumed_by_builder",
            "include_active",
            "deliberately_unloaded",
            "stalled_input",
            "superseded",
            "undetermined",
        )
    }:
        fail("JSON orphan verdict counts do not match its rows")
    if {row.get("verdict") for row in orphan_rows} - EXPECTED_VERDICTS:
        fail("JSON contains an unknown orphan verdict")
    if len(orphan_rows) != status_counts.get("orphan_module"):
        fail("JSON orphan rows do not match the registry orphan count")
    if len(class_rows) != counts.get("baseline_unclassified"):
        fail("JSON class-resolution rows do not match the baseline count")
    if len(unrouted_rows) != counts.get("unrouted"):
        fail("JSON unrouted rows do not match the count")

    table_groups = (
        counts.get("by_status", {}),
        counts.get("by_class", {}),
        counts.get("orphan_verdicts", {}),
        counts.get("baseline_class_resolution", {}),
    )
    for group in table_groups:
        for name, count in group.items():
            if f"| `{name}` | {count} |" not in report:
                fail(f"report count is absent or stale: {name}={count}")
    for row in orphan_rows:
        if f"| `{row['path']}` | `{row['verdict']}` |" not in report:
            fail(f"report orphan row is absent or stale: {row['path']}")
    for row in unrouted_rows:
        if f"| `{row['name']}` | {row['does']} | {row['judgement']} |" not in report:
            fail(f"report unrouted row is absent or stale: {row['name']}")


def main() -> int:
    data, report = check_determinism()
    evidence_count = check_evidence(data)
    check_counts(data, report)
    print(
        "PASS self-description census: "
        f"{len(data['orphan_modules'])} orphan rows, "
        f"{len(data['class_resolution'])} class resolutions, "
        f"{evidence_count} live evidence references; builder rerun byte-identical twice"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
