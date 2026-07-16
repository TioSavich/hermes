#!/usr/bin/env python3
"""Plain-language 10-point grades and feedback for parsed discussions.

Usage:

    python3 grade.py
    python3 grade.py --only 3_2_3_watch_what_you_say
    python3 grade.py --force
    python3 grade.py --offline

Reads `output/parsed/<prompt_id>.json`. For each student and prompt, writes a
colleague-friendly draft grade out of 10 plus short feedback. The default mode
uses Gemma through reallms. `--offline` uses a transparent completion heuristic
when you want quick, no-API output; those rows are marked for human review.

Output:
    output/grades/<prompt_id>/grades.csv
    output/grades/<prompt_id>/feedback.md
    output/grades/<prompt_id>/<student_slug>.md
    output/grades/<prompt_id>/<student_slug>.json
    output/grades/summary.csv

This is intentionally not the PML/research scorer. It is a practical grading
layer for "did they answer the prompt, roughly how many points, and what would
I say back to them?"
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import os as _os
HERE = Path(_os.environ.get("HERMES_PACK_ROOT", HERE.parent))
DATA = HERE / "runtime"

from lib import api, monitoring as monlib, parser as parselib, roster as rosterlib  # noqa: E402

PARSED_DIR = DATA / "output" / "parsed"
GRADES_DIR = DATA / "output" / "grades"
SUMMARY_CSV = GRADES_DIR / "summary.csv"
SYSTEM_PROMPT_PATH = HERE / "system_prompts" / "grade.md"

WORD_RE = re.compile(r"\b[\w']+\b", flags=re.UNICODE)
STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "but", "by", "can", "did",
    "do", "does", "for", "from", "had", "has", "have", "he", "her", "his",
    "i", "if", "in", "is", "it", "its", "me", "my", "of", "on", "or",
    "our", "she", "so", "that", "the", "their", "them", "then", "there",
    "they", "this", "to", "was", "we", "were", "what", "when", "where",
    "which", "who", "why", "will", "with", "would", "you", "your",
}


def words(text: str) -> list[str]:
    return WORD_RE.findall((text or "").lower())


def content_words(text: str) -> list[str]:
    return [w for w in words(text) if len(w) > 2 and w not in STOPWORDS]


def stable_hash(*parts: str) -> str:
    h = hashlib.sha256()
    for part in parts:
        h.update(part.encode("utf-8"))
        h.update(b"\0")
    return h.hexdigest()


def safe_int(value: Any, default: int = 0) -> int:
    try:
        return int(round(float(value)))
    except (TypeError, ValueError):
        return default


def clamp(value: int, lo: int, hi: int) -> int:
    return max(lo, min(hi, value))


def norm_role(post: dict, index: int) -> str:
    role = (post.get("role") or "").strip().lower()
    if role in {"initial", "reply", "return"}:
        return role
    return "initial" if index == 0 else "reply"


def student_slug(student_id: str, display_name: str) -> str:
    raw = display_name or student_id or "student"
    name_slug = re.sub(r"[^A-Za-z0-9]+", "_", raw).strip("_")
    sid_slug = re.sub(r"[^A-Za-z0-9]+", "_", student_id or "").strip("_")
    if sid_slug and sid_slug.lower() not in name_slug.lower():
        return f"{name_slug}_{sid_slug}" if name_slug else sid_slug
    return name_slug or sid_slug or "student"


def display_for_sid(
    sid: str,
    students_by_sid: dict[str, rosterlib.Student],
    raw_names_by_sid: dict[str, str],
) -> str:
    student = students_by_sid.get(sid)
    if student:
        return student.display() or sid
    return raw_names_by_sid.get(sid) or sid


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
        "----- PCK CONTEXT (from monitoring chart; use for grading feedback grounding only) -----\n"
        f"Chart: {chart.relative_to(HERE)}\n\n"
        f"{excerpt}\n"
        "----- END PCK CONTEXT -----\n\n"
    )


def collect_posts_by_student(parsed: dict) -> tuple[dict[str, list[dict]], dict[str, str]]:
    posts_by_sid: dict[str, list[dict]] = defaultdict(list)
    raw_names_by_sid: dict[str, str] = {}
    for thread in parsed.get("threads", []) or []:
        thread_posts = thread.get("posts", []) or []
        first = thread_posts[0] if thread_posts else {}
        first_sid = first.get("author_student_id")
        first_name = first.get("author_raw_name") or first_sid or "Unknown"
        for index, post in enumerate(thread_posts):
            sid = post.get("author_student_id")
            if not sid:
                continue
            raw_name = post.get("author_raw_name") or ""
            if raw_name and sid not in raw_names_by_sid:
                raw_names_by_sid[sid] = raw_name
            item = {
                "thread_index": thread.get("thread_index"),
                "post_index": post.get("post_index", index),
                "role": norm_role(post, index),
                "author_raw_name": raw_name,
                "reply_to_student_id": first_sid if sid != first_sid else "",
                "reply_to_raw_name": first_name if sid != first_sid else "",
                "text": (post.get("text") or "").strip(),
            }
            posts_by_sid[sid].append(item)
    return posts_by_sid, raw_names_by_sid


def student_ids_for_prompt(
    posts_by_sid: dict[str, list[dict]],
    students: list[rosterlib.Student],
    include_absent: bool,
) -> list[str]:
    if include_absent and students:
        roster_ids = [s.student_id for s in students]
        roster_set = set(roster_ids)
        extras = sorted(sid for sid in posts_by_sid if sid not in roster_set)
        return roster_ids + extras
    return sorted(posts_by_sid)


def render_student_packet(
    parsed: dict,
    prompt_id: str,
    sid: str,
    display_name: str,
    posts: list[dict],
    pck_context: str = "",
) -> str:
    prompt_text = (parsed.get("instructor_prompt_text") or "").strip()
    raw_header = parsed.get("raw_header") or prompt_id
    pieces = [
        f"PROMPT_ID: {prompt_id}",
        f"RAW_HEADER: {raw_header}",
        f"STUDENT: {display_name} ({sid})",
        "",
        "----- PROMPT -----",
        prompt_text or "(No instructor prompt text was found in the parsed JSON.)",
        "",
    ]
    if pck_context.strip():
        pieces.extend([pck_context.strip(), ""])
    pieces.append("----- STUDENT POSTS -----")
    if not posts:
        pieces.append("(No attributed posts for this student in this parsed prompt.)")
        return "\n".join(pieces)
    for post in sorted(posts, key=lambda p: (p.get("thread_index") or 0, p.get("post_index") or 0)):
        role = post["role"]
        heading = f"Thread {post.get('thread_index', '?')} / {role}"
        if role == "reply" and post.get("reply_to_raw_name"):
            heading += f" to {post['reply_to_raw_name']}"
        pieces.extend([f"\n[{heading}]", post.get("text") or ""])
    return "\n".join(pieces).strip()


def normalize_record(
    rec: dict,
    *,
    prompt_id: str,
    raw_header: str,
    sid: str,
    display_name: str,
    mode: str,
    input_hash: str,
) -> dict:
    breakdown = rec.get("score_breakdown") if isinstance(rec.get("score_breakdown"), dict) else {}
    normalized_breakdown = {
        "prompt_requirements": clamp(safe_int(breakdown.get("prompt_requirements")), 0, 4),
        "substance": clamp(safe_int(breakdown.get("substance")), 0, 3),
        "peer_engagement": clamp(safe_int(breakdown.get("peer_engagement")), 0, 2),
        "clarity_and_care": clamp(safe_int(breakdown.get("clarity_and_care")), 0, 1),
    }
    total = sum(normalized_breakdown.values())
    points = clamp(safe_int(rec.get("points"), total), 0, 10)
    if points != total:
        points = total

    followed = (rec.get("followed_prompt") or "unclear").strip().lower()
    if followed not in {"yes", "mostly", "partly", "no", "unclear", "no_visible_submission"}:
        followed = "unclear"

    def listify(value: Any) -> list[str]:
        if isinstance(value, list):
            return [str(v).strip() for v in value if str(v).strip()]
        if isinstance(value, str) and value.strip():
            return [value.strip()]
        return []

    feedback = str(rec.get("feedback_to_student") or "").strip()
    if not feedback:
        feedback = "I could not generate useful feedback from the parsed response. Please check the original Canvas post."
    note = str(rec.get("note_to_instructor") or "").strip()
    if not note:
        note = "Needs a quick human check against the original discussion."

    return {
        "prompt_id": prompt_id,
        "raw_header": raw_header,
        "student_id": sid,
        "student_name": display_name,
        "points": points,
        "followed_prompt": followed,
        "score_breakdown": normalized_breakdown,
        "requirements_met": listify(rec.get("requirements_met")),
        "missing_requirements": listify(rec.get("missing_requirements")),
        "evidence": listify(rec.get("evidence")),
        "feedback_to_student": feedback,
        "note_to_instructor": note,
        "needs_human_review": bool(rec.get("needs_human_review", False)),
        "mode": mode,
        "_input_hash": input_hash,
    }


def absent_record(
    *,
    prompt_id: str,
    raw_header: str,
    sid: str,
    display_name: str,
    mode: str,
    input_hash: str,
) -> dict:
    return normalize_record(
        {
            "followed_prompt": "no_visible_submission",
            "points": 0,
            "score_breakdown": {
                "prompt_requirements": 0,
                "substance": 0,
                "peer_engagement": 0,
                "clarity_and_care": 0,
            },
            "requirements_met": [],
            "missing_requirements": ["No attributed response was found in the parsed discussion."],
            "evidence": [],
            "feedback_to_student": (
                "I do not see a response from you in the parsed Canvas discussion for this prompt. "
                "If you did submit, check that it posted to the correct discussion thread and ask "
                "the instructor to review the original Canvas record."
            ),
            "note_to_instructor": "No attributed post was found for this student in the parsed JSON.",
            "needs_human_review": False,
        },
        prompt_id=prompt_id,
        raw_header=raw_header,
        sid=sid,
        display_name=display_name,
        mode=mode,
        input_hash=input_hash,
    )


def prompt_requires_peer(prompt_text: str) -> bool:
    text = (prompt_text or "").lower()
    return any(
        phrase in text
        for phrase in (
            "reply to", "respond to", "respond substantively", "peer", "classmate",
            "partner", "someone else", "another student", "their post",
        )
    )


def prompt_requires_return(prompt_text: str) -> bool:
    text = (prompt_text or "").lower()
    return any(
        phrase in text
        for phrase in (
            "return to", "come back", "revise", "revision", "after reading",
            "then return", "update your", "second post",
        )
    )


def offline_grade(
    *,
    parsed: dict,
    prompt_id: str,
    sid: str,
    display_name: str,
    posts: list[dict],
    input_hash: str,
) -> dict:
    prompt_text = parsed.get("instructor_prompt_text") or ""
    raw_header = parsed.get("raw_header") or prompt_id
    all_text = "\n\n".join(p.get("text") or "" for p in posts)
    all_words = words(all_text)
    prompt_vocab = set(content_words(prompt_text))
    response_vocab = set(content_words(all_text))
    overlap = len(prompt_vocab & response_vocab) / len(prompt_vocab) if prompt_vocab else 0.0
    n_initial = sum(1 for p in posts if p.get("role") == "initial")
    n_reply = sum(1 for p in posts if p.get("role") == "reply")
    n_return = sum(1 for p in posts if p.get("role") == "return")
    wants_peer = prompt_requires_peer(prompt_text)
    wants_return = prompt_requires_return(prompt_text)

    prompt_req = 0
    if n_initial:
        prompt_req += 1
    if len(all_words) >= 75:
        prompt_req += 1
    if overlap >= 0.05 or not prompt_vocab:
        prompt_req += 1
    if (not wants_return) or n_return:
        prompt_req += 1
    if wants_peer and n_reply == 0:
        prompt_req = min(prompt_req, 3)
    prompt_req = clamp(prompt_req, 0, 4)

    substance = 0
    if len(all_words) >= 40:
        substance += 1
    if len(response_vocab) >= 25:
        substance += 1
    if re.search(r"\b(because|for example|definition|measure|property|evidence|notice|figure|child|student)\b", all_text, re.I):
        substance += 1
    substance = clamp(substance, 0, 3)

    if wants_peer:
        peer = 2 if n_reply and len(all_words) >= 75 else (1 if n_reply else 0)
    else:
        peer = 2 if n_initial and len(all_words) >= 75 else (1 if n_initial else 0)

    clarity = 1 if len(all_words) >= 30 else 0
    points = prompt_req + substance + peer + clarity

    missing = []
    met = []
    if n_initial:
        met.append("Submitted an attributed initial response.")
    else:
        missing.append("No initial response was found.")
    if wants_peer:
        if n_reply:
            met.append("Posted an attributed peer reply.")
        else:
            missing.append("The prompt appears to ask for peer uptake, but no reply was found.")
    if wants_return:
        if n_return:
            met.append("Returned to the discussion after the first post.")
        else:
            missing.append("The prompt appears to ask for a return or revision, but none was found.")
    if len(all_words) < 75:
        missing.append("The response is brief, so the substance may need a human check.")
    if overlap < 0.05 and prompt_vocab:
        missing.append("The response has little visible overlap with the prompt language or topic.")

    followed = "yes" if points >= 9 else "mostly" if points >= 7 else "partly" if points >= 4 else "no"
    feedback_bits = []
    if n_initial:
        feedback_bits.append("You made a visible start on the discussion prompt.")
    if n_reply:
        feedback_bits.append("You also added a peer reply, which helps complete the discussion task.")
    if n_return:
        feedback_bits.append("Your return post gives the discussion a second pass.")
    if missing:
        feedback_bits.append("For a stronger score, check the prompt for the missing piece: " + missing[0])
    else:
        feedback_bits.append("The next step is to make the mathematical or teaching reason as specific as possible.")
    feedback_bits.append("This is an automated draft score, so your instructor may adjust it after reading the original post.")

    return normalize_record(
        {
            "followed_prompt": followed,
            "points": points,
            "score_breakdown": {
                "prompt_requirements": prompt_req,
                "substance": substance,
                "peer_engagement": peer,
                "clarity_and_care": clarity,
            },
            "requirements_met": met,
            "missing_requirements": missing,
            "evidence": [
                f"{len(all_words)} total word(s) across {len(posts)} attributed post(s).",
                f"Found {n_initial} initial, {n_reply} reply, and {n_return} return post(s).",
            ],
            "feedback_to_student": " ".join(feedback_bits),
            "note_to_instructor": "Offline heuristic grade based on completion, length, prompt overlap, and reply/return evidence.",
            "needs_human_review": True,
        },
        prompt_id=prompt_id,
        raw_header=raw_header,
        sid=sid,
        display_name=display_name,
        mode="offline",
        input_hash=input_hash,
    )


def llm_grade(
    *,
    parsed: dict,
    prompt_id: str,
    sid: str,
    display_name: str,
    posts: list[dict],
    pck_context: str = "",
    system_prompt: str,
    client: dict,
    input_hash: str,
) -> dict:
    packet = render_student_packet(parsed, prompt_id, sid, display_name, posts, pck_context=pck_context)
    reply = api.call_api(system_prompt, packet, **client)
    rec = parselib.parse_json_or_die(reply, what=f"grade pass for {prompt_id}/{sid}")
    return normalize_record(
        rec,
        prompt_id=prompt_id,
        raw_header=parsed.get("raw_header") or prompt_id,
        sid=sid,
        display_name=display_name,
        mode="llm",
        input_hash=input_hash,
    )


def render_student_markdown(record: dict) -> str:
    missing = record.get("missing_requirements") or []
    met = record.get("requirements_met") or []
    evidence = record.get("evidence") or []
    breakdown = record.get("score_breakdown") or {}

    def bullets(items: list[str]) -> str:
        if not items:
            return "- None noted."
        return "\n".join(f"- {item}" for item in items)

    return f"""# {record['student_name']} - {record['raw_header']}

**Draft grade:** {record['points']}/10
**Followed prompt:** {record['followed_prompt']}
**Human review:** {"yes" if record.get("needs_human_review") else "no"}

**Breakdown.** Prompt requirements {breakdown.get('prompt_requirements', 0)}/4; substance {breakdown.get('substance', 0)}/3; peer engagement {breakdown.get('peer_engagement', 0)}/2; clarity and care {breakdown.get('clarity_and_care', 0)}/1.

**Feedback to student.** {record['feedback_to_student']}

**Met.**
{bullets(met)}

**Missing or next step.**
{bullets(missing)}

**Evidence.**
{bullets(evidence)}

**Instructor note.** {record['note_to_instructor']}
"""


def write_prompt_feedback(records: list[dict], path: Path) -> None:
    sections = [f"# {records[0]['raw_header']} - Practical Grades\n"] if records else ["# Practical Grades\n"]
    for rec in sorted(records, key=lambda r: (r["student_name"], r["student_id"])):
        sections.append(
            f"## {rec['student_name']} ({rec['points']}/10)\n\n"
            f"**Followed prompt:** {rec['followed_prompt']}  \n"
            f"**Human review:** {'yes' if rec.get('needs_human_review') else 'no'}\n\n"
            f"{rec['feedback_to_student']}\n\n"
            f"**Instructor note.** {rec['note_to_instructor']}\n"
        )
    path.write_text("\n".join(sections), encoding="utf-8")


def flatten_row(record: dict) -> dict:
    breakdown = record.get("score_breakdown") or {}
    return {
        "prompt_id": record.get("prompt_id", ""),
        "raw_header": record.get("raw_header", ""),
        "student_id": record.get("student_id", ""),
        "student_name": record.get("student_name", ""),
        "points": record.get("points", ""),
        "followed_prompt": record.get("followed_prompt", ""),
        "needs_human_review": "yes" if record.get("needs_human_review") else "no",
        "prompt_requirements": breakdown.get("prompt_requirements", ""),
        "substance": breakdown.get("substance", ""),
        "peer_engagement": breakdown.get("peer_engagement", ""),
        "clarity_and_care": breakdown.get("clarity_and_care", ""),
        "requirements_met": " | ".join(record.get("requirements_met") or []),
        "missing_requirements": " | ".join(record.get("missing_requirements") or []),
        "evidence": " | ".join(record.get("evidence") or []),
        "feedback_to_student": record.get("feedback_to_student", ""),
        "note_to_instructor": record.get("note_to_instructor", ""),
        "mode": record.get("mode", ""),
    }


def write_csv(records: list[dict], path: Path) -> None:
    if not records:
        return
    fields = [
        "prompt_id", "raw_header", "student_id", "student_name", "points",
        "followed_prompt", "needs_human_review", "prompt_requirements",
        "substance", "peer_engagement", "clarity_and_care", "requirements_met",
        "missing_requirements", "evidence", "feedback_to_student",
        "note_to_instructor", "mode",
    ]
    with path.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        for record in sorted(records, key=lambda r: (r["student_name"], r["student_id"])):
            w.writerow(flatten_row(record))


def main() -> None:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--only", help="Only grade one prompt_id.")
    ap.add_argument("--force", action="store_true", help="Re-grade even if cached JSON exists.")
    ap.add_argument("--offline", action="store_true", help="Use no-API heuristic grading and mark rows for human review.")
    ap.add_argument("--include-absent", dest="include_absent", action="store_true", default=True,
                    help="Include roster students with no parsed posts as 0-point rows (default when roster.csv exists).")
    ap.add_argument("--no-absent", dest="include_absent", action="store_false",
                    help="Only write rows for students who have parsed posts.")
    args = ap.parse_args()

    if not PARSED_DIR.exists() or not any(PARSED_DIR.glob("*.json")):
        api.fail("no parsed files in output/parsed/. Run parse.py first.")

    mode = "offline" if args.offline else "llm"
    students = rosterlib.read_roster(DATA / "roster.csv")
    students_by_sid = {s.student_id: s for s in students}
    include_absent = bool(args.include_absent and students)
    if args.include_absent and not students:
        print("roster.csv not found or empty; grading only students present in parsed JSON.")

    system_prompt = ""
    client: dict[str, Any] = {}
    if mode == "llm":
        system_prompt = SYSTEM_PROMPT_PATH.read_text(encoding="utf-8")
        client = api.make_client(DATA)

    GRADES_DIR.mkdir(parents=True, exist_ok=True)
    all_records: list[dict] = []
    parsed_files = sorted(PARSED_DIR.glob("*.json"))

    for parsed_file in parsed_files:
        prompt_id = parsed_file.stem
        if args.only and prompt_id != args.only:
            continue

        parsed = json.loads(parsed_file.read_text(encoding="utf-8"))
        parsed.setdefault("prompt_id", prompt_id)
        raw_header = parsed.get("raw_header") or prompt_id
        pck_context = pck_block(prompt_id)
        posts_by_sid, raw_names_by_sid = collect_posts_by_student(parsed)
        prompt_dir = GRADES_DIR / prompt_id
        prompt_dir.mkdir(parents=True, exist_ok=True)
        prompt_records: list[dict] = []
        sid_list = student_ids_for_prompt(posts_by_sid, students, include_absent)

        print(f"{prompt_id}: grading {len(sid_list)} student(s) in {mode} mode")
        for sid in sid_list:
            display_name = display_for_sid(sid, students_by_sid, raw_names_by_sid)
            posts = posts_by_sid.get(sid, [])
            packet = render_student_packet(
                parsed,
                prompt_id,
                sid,
                display_name,
                posts,
                pck_context=pck_context,
            )
            input_hash = stable_hash(mode, system_prompt, packet)
            slug = student_slug(sid, display_name)
            json_path = prompt_dir / f"{slug}.json"
            md_path = prompt_dir / f"{slug}.md"

            if json_path.exists() and not args.force:
                try:
                    cached = json.loads(json_path.read_text(encoding="utf-8"))
                    if cached.get("_input_hash") == input_hash:
                        prompt_records.append(cached)
                        print(f"  {display_name}: cached")
                        continue
                except json.JSONDecodeError:
                    pass

            if not posts:
                record = absent_record(
                    prompt_id=prompt_id,
                    raw_header=raw_header,
                    sid=sid,
                    display_name=display_name,
                    mode=mode,
                    input_hash=input_hash,
                )
            elif mode == "offline":
                record = offline_grade(
                    parsed=parsed,
                    prompt_id=prompt_id,
                    sid=sid,
                    display_name=display_name,
                    posts=posts,
                    input_hash=input_hash,
                )
            else:
                print(f"  {display_name}: grading with Gemma...", flush=True)
                try:
                    record = llm_grade(
                        parsed=parsed,
                        prompt_id=prompt_id,
                        sid=sid,
                        display_name=display_name,
                        posts=posts,
                        pck_context=pck_context,
                        system_prompt=system_prompt,
                        client=client,
                        input_hash=input_hash,
                    )
                except ValueError as e:
                    raw_path = prompt_dir / f"{slug}.raw.md"
                    raw_path.write_text(str(e), encoding="utf-8")
                    record = normalize_record(
                        {
                            "followed_prompt": "unclear",
                            "points": 0,
                            "score_breakdown": {
                                "prompt_requirements": 0,
                                "substance": 0,
                                "peer_engagement": 0,
                                "clarity_and_care": 0,
                            },
                            "requirements_met": [],
                            "missing_requirements": ["The model response could not be parsed as JSON."],
                            "evidence": [],
                            "feedback_to_student": (
                                "I could not generate reliable feedback from the automated grader. "
                                "Your instructor should check the original Canvas post."
                            ),
                            "note_to_instructor": f"Grade pass failed to parse: {e}",
                            "needs_human_review": True,
                        },
                        prompt_id=prompt_id,
                        raw_header=raw_header,
                        sid=sid,
                        display_name=display_name,
                        mode=mode,
                        input_hash=input_hash,
                    )

            json_path.write_text(json.dumps(record, indent=2, ensure_ascii=False), encoding="utf-8")
            md_path.write_text(render_student_markdown(record), encoding="utf-8")
            prompt_records.append(record)

        write_csv(prompt_records, prompt_dir / "grades.csv")
        write_prompt_feedback(prompt_records, prompt_dir / "feedback.md")
        all_records.extend(prompt_records)

    if all_records:
        write_csv(all_records, SUMMARY_CSV)
        print(f"done. {GRADES_DIR.relative_to(HERE)}/")
    else:
        print("no matching parsed prompts.")


if __name__ == "__main__":
    main()
