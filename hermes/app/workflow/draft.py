#!/usr/bin/env python3
"""Draft a personalized, pair-assigned Canvas HTML for one upcoming unit.

Usage:

    python3 draft.py 3_3_6
    python3 draft.py 3_3_6_grade_1_geometry_lessons
    python3 draft.py --list

Finds the matching async HTML in `prompts/`, gathers all warm profiles in
`output/profiles/`, and asks Gemma to produce a paste-ready Canvas HTML
that pairs students and tunes each pair's central question, follow-ups,
and return task.

Output: output/canvas/<unit_id>.html.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import Counter
from itertools import combinations
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import os as _os
HERE = Path(_os.environ.get("HERMES_PACK_ROOT", HERE.parent))
DATA = HERE / "runtime"

from lib import api, monitoring as monlib  # noqa: E402

PROMPTS_DIR = HERE / "prompts"
PROFILES_DIR = DATA / "output" / "profiles"
CANVAS_DIR = DATA / "output" / "canvas"
PAIR_HISTORY_CSV = DATA / "output" / "pair_history.csv"
UNITS_4_8_FOCUS = HERE / "UNITS_4_8_FOCUS.md"


def read_pair_history() -> list[dict]:
    if not PAIR_HISTORY_CSV.exists():
        return []
    with PAIR_HISTORY_CSV.open("r", encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def append_pair_history(unit_id: str, pairs: list[tuple[str, ...]]) -> None:
    PAIR_HISTORY_CSV.parent.mkdir(parents=True, exist_ok=True)
    write_header = not PAIR_HISTORY_CSV.exists()
    with PAIR_HISTORY_CSV.open("a", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        if write_header:
            w.writerow(["unit_id", "a", "b", "c"])
        for p in pairs:
            row = list(p) + [""] * (3 - len(p))
            w.writerow([unit_id, row[0], row[1], row[2]])


def render_history_block(history: list[dict]) -> str:
    if not history:
        return "(no prior pairings on record)"
    seen: dict[tuple[str, ...], list[str]] = {}
    for h in history:
        members = tuple(sorted(x for x in (h.get("a"), h.get("b"), h.get("c")) if x))
        if members:
            seen.setdefault(members, []).append(h.get("unit_id", "?"))
    lines = []
    for members, units in sorted(seen.items(), key=lambda kv: -len(kv[1])):
        names = " & ".join(members)
        lines.append(f"- {names}  (in: {', '.join(units)})")
    return "\n".join(lines)


def student_name_from_profile(path: Path) -> str:
    text = read_optional(path)
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if line.startswith("#"):
            name = line.lstrip("#").strip()
            if name:
                return name
    return path.stem.replace("_", " ")


def pair_history_counts(history: list[dict]) -> Counter[tuple[str, str]]:
    counts: Counter[tuple[str, str]] = Counter()
    for row in history:
        members = sorted(x for x in (row.get("a"), row.get("b"), row.get("c")) if x)
        for a, b in combinations(members, 2):
            counts[(a, b)] += 1
    return counts


def coverage_pair_plan(students: list[str], history: list[dict]) -> list[tuple[str, ...]]:
    remaining = sorted({s.strip() for s in students if s.strip()})
    if len(remaining) < 2:
        return []

    counts = pair_history_counts(history)
    plan: list[tuple[str, ...]] = []

    while len(remaining) > 3:
        scored_pairs = []
        for a, b in combinations(remaining, 2):
            exposure = counts.get(tuple(sorted((a, b))), 0)
            individual_load = sum(counts.get(tuple(sorted((a, other))), 0) for other in remaining if other != a)
            individual_load += sum(counts.get(tuple(sorted((b, other))), 0) for other in remaining if other != b)
            scored_pairs.append((exposure, individual_load, a, b))
        _, _, a, b = min(scored_pairs)
        plan.append((a, b))
        remaining = [s for s in remaining if s not in {a, b}]

    if len(remaining) == 3:
        plan.append(tuple(remaining))
    elif len(remaining) == 2:
        plan.append((remaining[0], remaining[1]))

    return plan


def render_pair_plan(plan: list[tuple[str, ...]], history: list[dict]) -> str:
    if not plan:
        return "(not enough students to form a pair)"
    counts = pair_history_counts(history)
    lines = []
    for group in plan:
        dyad_counts = [
            counts.get(tuple(sorted((a, b))), 0)
            for a, b in combinations(group, 2)
        ]
        if not dyad_counts or max(dyad_counts) == 0:
            status = "all dyads new"
        else:
            status = f"prior dyad counts: {', '.join(str(c) for c in dyad_counts)}"
        lines.append(f"- {' & '.join(group)} ({status})")
    return "\n".join(lines)


PARTNERS_RE = re.compile(
    r"(?is)<strong>\s*Partners?:\s*</strong>\s*([^<\n]+?)(?=</p>|<br|\n)"
)
NAME_SPLIT_RE = re.compile(r"\s*(?:,|&amp;|&|\band\b)\s*")


def parse_pairs_from_html(html: str) -> list[tuple[str, ...]]:
    pairs: list[tuple[str, ...]] = []
    for m in PARTNERS_RE.finditer(html):
        raw = m.group(1).replace("&amp;", "&")
        names = [n.strip() for n in NAME_SPLIT_RE.split(raw) if n.strip()]
        if 2 <= len(names) <= 3:
            pairs.append(tuple(names))
    return pairs


def list_units() -> list[Path]:
    return sorted(PROMPTS_DIR.glob("*.html"))


def find_unit(unit_id: str) -> Path | None:
    """Match by exact stem, prefix, or substring (case-insensitive)."""
    units = list_units()
    needle = unit_id.lower()
    # Exact stem
    for u in units:
        if u.stem.lower() == needle:
            return u
    # Stem prefix (e.g., "3_3_6" matches "3_3_6_grade_1_geometry_lessons_async")
    for u in units:
        if u.stem.lower().startswith(needle):
            return u
    # Substring
    for u in units:
        if needle in u.stem.lower():
            return u
    return None


def unit_number(unit_id: str) -> int | None:
    m = re.match(r"^(\d+)_", unit_id)
    if not m:
        return None
    return int(m.group(1))


def read_optional(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8").strip()
    except OSError:
        return ""


def focus_brief_for(unit_id: str) -> str:
    unit = unit_number(unit_id)
    if unit is None or unit < 4 or unit > 8:
        return ""
    return read_optional(UNITS_4_8_FOCUS)


def monitoring_context_for(unit_id: str) -> str:
    chart = monlib.chart_path_for(HERE, unit_id)
    if not chart:
        unit = unit_number(unit_id)
        if unit is not None:
            fallback = HERE / "monitoring" / "unit-overviews" / f"unit{unit}.md"
            if fallback.exists():
                chart = fallback
    if not chart:
        return ""

    excerpt = monlib.pck_section(chart)
    if not excerpt:
        excerpt = read_optional(chart)
    if not excerpt:
        return ""

    return (
        f"Chart: {chart.relative_to(HERE)}\n\n"
        f"{excerpt}"
    )


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("unit", nargs="?", help="Unit id (e.g., 3_3_6 or 3_3_6_grade_1_geometry_lessons).")
    ap.add_argument("--list", action="store_true", help="List available unit ids and exit.")
    ap.add_argument("--force", action="store_true", help="Overwrite an existing output HTML.")
    args = ap.parse_args()

    if args.list:
        for u in list_units():
            print(u.stem)
        return
    if not args.unit:
        ap.error("unit id is required (or pass --list).")

    unit_path = find_unit(args.unit)
    if not unit_path:
        api.fail(f"no prompt matched '{args.unit}'. Try --list.")
    print(f"unit: {unit_path.name}")

    if not PROFILES_DIR.exists() or not any(PROFILES_DIR.glob("*.md")):
        api.fail("no profiles in output/profiles/. Run profile.py first.")

    profiles = sorted(PROFILES_DIR.glob("*.md"))
    print(f"profiles: {len(profiles)} student(s)")

    CANVAS_DIR.mkdir(parents=True, exist_ok=True)
    out_path = CANVAS_DIR / f"{unit_path.stem}.html"
    if out_path.exists() and not args.force:
        api.fail(f"{out_path.relative_to(HERE)} already exists. Pass --force to overwrite.")

    base_html = unit_path.read_text(encoding="utf-8")
    profile_block = "\n\n---\n\n".join(p.read_text(encoding="utf-8").strip() for p in profiles)
    pair_history = read_pair_history()
    history_block = render_history_block(pair_history)
    student_names = [student_name_from_profile(path) for path in profiles]
    pair_plan = coverage_pair_plan(student_names, pair_history)
    pair_plan_block = render_pair_plan(pair_plan, pair_history)
    focus_brief = focus_brief_for(unit_path.stem)
    monitoring_context = monitoring_context_for(unit_path.stem)

    client = api.make_client(DATA)
    system_prompt = (HERE / "system_prompts" / "draft.md").read_text(encoding="utf-8")

    user_content = (
        f"UNIT_ID: {unit_path.stem}\n\n"
        "----- BASE_HTML -----\n"
        f"{base_html}\n\n"
        "----- UNITS_4_8_FOCUS_BRIEF (use silently; do not quote in student-facing text) -----\n"
        f"{focus_brief or '(no additional focus brief for this unit)'}\n\n"
        "----- MONITORING_CONTEXT (use for PCK grounding and pair-question design; do not quote) -----\n"
        f"{monitoring_context or '(no monitoring context resolved)'}\n\n"
        "----- PROFILES -----\n"
        f"{profile_block}\n\n"
        "----- PRIOR_PAIRINGS (avoid repeating these dyads unless no productive alternative exists) -----\n"
        f"{history_block}\n\n"
        "----- COVERAGE_DIRECTED_PAIR_PLAN (use these partner assignments unless a profile-specific constraint makes one unsuitable) -----\n"
        f"{pair_plan_block}\n"
    )

    print(f"drafting with Gemma...", flush=True)
    reply = api.call_api(system_prompt, user_content, **client).strip()
    if reply.startswith("```"):
        # Strip code fences if Gemma adds them despite instructions.
        lines = reply.splitlines()
        if lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip().startswith("```"):
            lines = lines[:-1]
        reply = "\n".join(lines).strip()

    out_path.write_text(reply + "\n", encoding="utf-8")
    parsed_pairs = parse_pairs_from_html(reply)
    if parsed_pairs:
        append_pair_history(unit_path.stem, parsed_pairs)
        print(f"  recorded {len(parsed_pairs)} pair(s) in output/pair_history.csv")
    print(f"done. {out_path.relative_to(HERE)}")


if __name__ == "__main__":
    main()
