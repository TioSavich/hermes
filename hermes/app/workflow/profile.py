#!/usr/bin/env python3
"""Generate one warm profile per student from their parsed discussion posts.

Usage:

    python3 profile.py
    python3 profile.py --force
    python3 profile.py --only Doe_Jane

Reads `output/parsed/<prompt_id>.json` files produced by parse.py, gathers
each student's posts across all prompts they answered, and asks Gemma for
a 350-500 word warm profile. One API call per student. Always one job per
call.

Output: output/profiles/<Last>_<First>.md (one file per student).

Idempotent: existing profiles are skipped unless --force.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import os as _os
HERE = Path(_os.environ.get("HERMES_PACK_ROOT", HERE.parent))
DATA = HERE / "runtime"

from lib import api, monitoring as monlib, roster as rosterlib  # noqa: E402

PARSED_DIR = DATA / "output" / "parsed"
PROFILES_DIR = DATA / "output" / "profiles"
CONTENT_DIR = DATA / "output" / "content"


def pck_block(prompt_id: str) -> str:
    prolog_block = monlib.prolog_pck_block(HERE, prompt_id)
    if prolog_block:
        return prolog_block

    chart = monlib.chart_path_for(HERE, prompt_id)
    if not chart:
        return monlib.prolog_fallback_pck(HERE, prompt_id)
    excerpt = monlib.pck_section(chart)
    if not excerpt:
        return monlib.prolog_fallback_pck(HERE, prompt_id)
    return (
        "----- PCK CONTEXT (from monitoring chart; use for profile grounding only) -----\n"
        f"Chart: {chart.relative_to(HERE)}\n\n"
        f"{excerpt}\n"
        "----- END PCK CONTEXT -----\n\n"
    )


def gather_student_content(student: rosterlib.Student) -> list[dict]:
    """Return [{assignment_id, text}, ...] from output/content/<assignment>/<slug>.{md,txt}."""
    out: list[dict] = []
    if not CONTENT_DIR.exists():
        return out
    slug = student.file_slug()
    for assignment_dir in sorted(p for p in CONTENT_DIR.iterdir() if p.is_dir()):
        candidate = None
        for ext in (".md", ".txt"):
            p = assignment_dir / f"{slug}{ext}"
            if p.exists():
                candidate = p
                break
        if candidate:
            out.append({
                "assignment_id": assignment_dir.name,
                "text": candidate.read_text(encoding="utf-8", errors="replace").strip(),
            })
    return out


def gather_student_posts(student: rosterlib.Student) -> list[dict]:
    """Return [{prompt_id, raw_header, role, text}, ...] for this student."""
    out: list[dict] = []
    for parsed_file in sorted(PARSED_DIR.glob("*.json")):
        try:
            parsed = json.loads(parsed_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        prompt_id = parsed.get("prompt_id", parsed_file.stem)
        raw_header = parsed.get("raw_header", prompt_id)
        for thread in parsed.get("threads", []):
            for post in thread.get("posts", []):
                if post.get("author_student_id") == student.student_id:
                    out.append({
                        "prompt_id": prompt_id,
                        "raw_header": raw_header,
                        "role": post.get("role", ""),
                        "text": (post.get("text") or "").strip(),
                    })
    return out


def format_posts_for_gemma(
    student: rosterlib.Student,
    posts: list[dict],
    content_items: list[dict] | None = None,
    pck_by_prompt: dict[str, str] | None = None,
) -> str:
    if not posts and not content_items:
        return f"NAME: {student.display()}\n\n(No posts or content found.)\n"
    pieces = [f"NAME: {student.display()}\n"]

    if posts:
        by_prompt: dict[str, list[dict]] = {}
        headers: dict[str, str] = {}
        for p in posts:
            by_prompt.setdefault(p["prompt_id"], []).append(p)
            headers[p["prompt_id"]] = p["raw_header"]
        role_order = {"initial": 0, "reply": 1, "return": 2, "": 3}
        for prompt_id in sorted(by_prompt):
            pieces.append(f"=== POST in {headers.get(prompt_id, prompt_id)} ===")
            pck_context = (pck_by_prompt or {}).get(prompt_id, "").strip()
            if pck_context:
                pieces.append(pck_context)
            ordered = sorted(by_prompt[prompt_id], key=lambda p: role_order.get(p["role"], 9))
            for p in ordered:
                label = p["role"].upper() or "POST"
                pieces.append(f"[{label}]\n{p['text']}\n")

    if content_items:
        for c in content_items:
            pieces.append(f"=== COURSEWORK from {c['assignment_id']} ===")
            pieces.append(f"[HOMEWORK]\n{c['text']}\n")

    return "\n".join(pieces).strip() + "\n"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--force", action="store_true", help="Re-write profiles that already exist.")
    ap.add_argument("--only", help="Generate only the profile whose file slug matches (e.g., Doe_Jane).")
    args = ap.parse_args()

    students = rosterlib.read_roster(DATA / "roster.csv")
    if not students:
        api.fail("roster.csv is empty or missing.")
    print(f"roster: {len(students)} student(s)")

    if not PARSED_DIR.exists() or not any(PARSED_DIR.glob("*.json")):
        api.fail("no parsed files in output/parsed/. Run parse.py first.")

    client = api.make_client(DATA)
    system_prompt = (HERE / "system_prompts" / "profile.md").read_text(encoding="utf-8")
    PROFILES_DIR.mkdir(parents=True, exist_ok=True)

    selected = [s for s in students if not args.only or s.file_slug() == args.only]
    if args.only and not selected:
        api.fail(f"no roster row matches --only {args.only}")

    for i, student in enumerate(selected, start=1):
        out_path = PROFILES_DIR / f"{student.file_slug()}.md"
        if out_path.exists() and not args.force:
            print(f"  {i}/{len(selected)} {student.file_slug()}: cached, skipping")
            continue

        posts = gather_student_posts(student)
        content_items = gather_student_content(student)
        if not posts and not content_items:
            print(f"  {i}/{len(selected)} {student.file_slug()}: no posts or content, writing stub")
            out_path.write_text(
                f"# {student.display()}\n\n*No posts or coursework found.*\n",
                encoding="utf-8",
            )
            continue

        content_note = f" + {len(content_items)} coursework file(s)" if content_items else ""
        print(
            f"  {i}/{len(selected)} {student.file_slug()}: profiling with Gemma "
            f"({len(posts)} post(s){content_note})...",
            flush=True,
        )
        prompt_ids = sorted({p["prompt_id"] for p in posts if p.get("prompt_id")})
        pck_by_prompt = {prompt_id: pck_block(prompt_id) for prompt_id in prompt_ids}
        user_content = format_posts_for_gemma(student, posts, content_items, pck_by_prompt)
        reply = api.call_api(system_prompt, user_content, **client).strip()
        if not reply.startswith("#"):
            sys.stderr.write(f"  warning: {student.file_slug()} reply did not start with '#'; saved anyway\n")
        out_path.write_text(reply + "\n", encoding="utf-8")

    print("done.")
    print(f"  profiles: {PROFILES_DIR.relative_to(HERE)}/")


if __name__ == "__main__":
    main()
