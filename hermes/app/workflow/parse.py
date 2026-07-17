#!/usr/bin/env python3
"""Parse All_Discussions_*.txt into one JSON per prompt section.

Usage:

    python3 parse.py input/All_Discussions_052226.txt
    python3 parse.py input/All_Discussions_052226.txt --force

The input file is one big paste with `Header:` lines separating each
discussion's prompt+responses. For each section, one Gemma call turns the
messy paste into structured JSON with thread-attributed posts.

Output: output/parsed/<prompt_id>.json (one file per section).

This step is idempotent: parsed files are skipped on re-run unless --force.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from hermes.app.workflow import service  # noqa: E402
from hermes.app.workflow.lib import api, parser as parselib, roster as rosterlib  # noqa: E402
from hermes.app.workflow.runtime import DATA, HERE  # noqa: E402

PARSED_DIR = DATA / "output" / "parsed"


def _main(argv: list[str] | None = None) -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("input", help="Path to the All_Discussions paste file.")
    ap.add_argument("--force", action="store_true", help="Re-parse sections even if their JSON already exists.")
    ap.add_argument("--only", help="Only parse sections whose prompt_id matches this slug.")
    args = ap.parse_args(argv)

    input_path = Path(args.input)
    if not input_path.is_absolute():
        input_path = DATA / input_path
    if not input_path.exists():
        api.fail(f"missing input file: {input_path}")

    client = api.make_client(DATA)
    system_prompt = (HERE / "system_prompts" / "parse.md").read_text(encoding="utf-8")

    students = rosterlib.read_roster(DATA / "roster.csv")
    if not students:
        api.fail("roster.csv is empty or missing. Add roster rows and re-run.")
    print(f"roster: {len(students)} student(s) loaded")
    roster_block = rosterlib.roster_block_for_gemma(students)

    raw = input_path.read_text(encoding="utf-8")
    sections = parselib.split_sections(raw)
    if not sections:
        api.fail("no `Header:` lines found in input.")
    print(f"sections: {len(sections)} prompt section(s) in {input_path.name}")

    PARSED_DIR.mkdir(parents=True, exist_ok=True)

    for i, section in enumerate(sections, start=1):
        if args.only and section.prompt_id != args.only:
            continue
        out_path = PARSED_DIR / f"{section.prompt_id}.json"
        if out_path.exists() and not args.force:
            print(f"  {i}/{len(sections)} {section.prompt_id}: cached, skipping")
            continue

        print(f"  {i}/{len(sections)} {section.prompt_id}: parsing with Gemma...", flush=True)
        user_content = (
            f"RAW_HEADER: {section.raw_header}\n\n"
            "----- ROSTER -----\n"
            f"{roster_block}\n\n"
            "----- SECTION -----\n"
            f"{section.body}\n"
        )
        reply = api.call_api(system_prompt, user_content, **client)
        try:
            parsed = parselib.parse_json_or_die(reply, what=f"parse pass for {section.prompt_id}")
        except ValueError as e:
            sys.stderr.write(f"  warning: {e}\n")
            (PARSED_DIR / f"{section.prompt_id}.raw.md").write_text(reply, encoding="utf-8")
            sys.stderr.write(f"  saved raw reply to output/parsed/{section.prompt_id}.raw.md\n")
            continue

        parsed.setdefault("prompt_id", section.prompt_id)
        parsed.setdefault("raw_header", section.raw_header)
        threads = parsed.get("threads", [])
        unmatched = parsed.get("unmatched_authors", [])
        print(f"      → {len(threads)} thread(s), {len(unmatched)} unmatched author(s)")
        if unmatched:
            for u in unmatched[:5]:
                sys.stderr.write(
                    f"        unmatched: thread {u.get('thread_index', '?')} "
                    f"post {u.get('post_index', '?')} '{u.get('raw_name', '?')}'\n"
                )
            if len(unmatched) > 5:
                sys.stderr.write(f"        ... and {len(unmatched) - 5} more\n")

        out_path.write_text(json.dumps(parsed, indent=2, ensure_ascii=False), encoding="utf-8")

    print("done.")


def run(payload: dict, context: service.WorkflowContext) -> service.WorkflowResult:
    return service.run_command("parse", payload, context, _main)


def main(argv: list[str] | None = None) -> int:
    return service.run_cli("parse", argv, _main)


if __name__ == "__main__":
    raise SystemExit(main())
