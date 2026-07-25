#!/usr/bin/env python3
"""Propose strategy-automaton pairings for the grade 7-8 lessons that have none.

The coverage ledger records the gap plainly: grades 7 and 8 hold 277 published
lessons with complete text, complete field context and complete standard anchors,
and six automaton pairings between them.  Grade 8 has none.  Everything needed to
propose one is already in the tree; what is missing is the proposal.

This driver asks a model for candidates and writes them to a proposal file.  It
never writes `curriculum/im/grade_8.pl`.  Promoting a proposal into the tree is a
separate act of judgement, the same rule the corpus binding proposals follow.

Candidates are pruned by the negation layer before the model reads them: a
lesson's topics come from `lesson_topics/2`, and `surviving_slices/3` removes the
machines whose family bears no relation to those topics.  That is the index doing
the work it was built for, and it is measured here rather than asserted — the
record for each lesson carries how many machines survived out of 232.

`none` is a first-class answer.  Grade 8 unit 7 is exponents and scientific
notation and there may be no automaton for it; a lesson that gets `none` with a
reason is an authoring gap the tree can act on, not a failure of the run.

Checkpointed: one JSON line per lesson, appended as it completes, and a rerun
skips lessons already recorded.  Nothing here takes under thirty minutes.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))

from hermes.app import llm  # noqa: E402

WINDOW = ROOT / "knowledge/index/corpus_window.txt"
FIELD_CONTEXT = ROOT / "curriculum/im/generated/field_context_cache.json"
COVERAGE = ROOT / "curriculum/im/coverage/im_coverage.json"
NEGATION = "knowledge/index/relevance_negation"

WINDOW_ROW_RE = re.compile(r"(?m)^\s{2}(\w+)/(\w+) arc=")


def prolog(goal: str, timeout: int = 300) -> str:
    result = subprocess.run(
        ["swipl", "-q", "--on-warning=status", "--on-error=status",
         "-l", "paths.pl", "-g", goal],
        cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(f"prolog failed ({result.returncode}): "
                           f"{result.stdout[-400:]} {result.stderr[-400:]}")
    return result.stdout


def lesson_topics_and_survivors(codes: list[str]) -> dict[str, dict]:
    """Per lesson: its topics, and the machines surviving topic subtraction."""
    listing = ",".join(f"'{code}'" for code in codes)
    goal = (
        f"use_module(im_lessons(lesson_monitoring)),"
        f"ensure_loaded('{NEGATION}'),"
        f"forall(member(C,[{listing}]),"
        f"( ( lesson_topics(C,Ts) -> true ; Ts=[] ),"
        f"  findall(M,"
        f"    ( member(T,Ts), surviving_slices(T,S,_),"
        f"      member(slice(family,machine(F,Sig)),S),"
        f"      format(atom(M),'~w/~w',[F,Sig]) ),"
        f"    Ms0), sort(Ms0,Ms),"
        f"  format('~w\\t~q\\t~q~n',[C,Ts,Ms]) )),halt."
    )
    out: dict[str, dict] = {}
    for line in prolog(goal).splitlines():
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        code, topics, machines = parts
        out[code] = {
            "topics": re.findall(r"[a-z_]+", topics),
            "machines": re.findall(r"'?([a-z_]+/[a-z_0-9]+)'?", machines),
        }
    return out


def window_rows() -> dict[str, str]:
    """Two-line machine entries from the served index, keyed family/signature."""
    text = WINDOW.read_text(encoding="utf-8")
    rows: dict[str, str] = {}
    lines = text.splitlines()
    for index, line in enumerate(lines):
        match = WINDOW_ROW_RE.match(line)
        if match:
            key = f"{match.group(1)}/{match.group(2)}"
            body = line.strip()
            if index + 1 < len(lines) and not WINDOW_ROW_RE.match(lines[index + 1]):
                body += "\n    " + lines[index + 1].strip()
            rows[key] = body
    return rows


ASK = """You are helping catalogue which mathematical strategies a curriculum lesson
could elicit from students.

LESSON {code} — "{title}"
concept: {concept}
grade {grade}, unit {unit}
standards anchored to this lesson:
{standards}

CANDIDATE MACHINES. Each is a finite-state model of one strategy or one error.
The line gives its family/signature, the normative arc its steps spell, and its
steps grouped as shell (preparing the problem), core (the iterative work) and
closure (what it records).

{candidates}

Which candidate machines could a student's work in this lesson actually run?

Answer as JSON and nothing else:
{{"pairings": [{{"machine": "family/signature", "confidence": "high|medium|low",
  "reason": "<one clause naming what in the lesson would elicit it>"}}],
  "gap": "<if no candidate fits, one clause saying what kind of machine the
           lesson would need; otherwise empty string>"}}

Propose at most three, only ones you would defend. An empty pairings list with a
stated gap is a better answer than a guess."""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--grades", default="8", help="comma-separated, e.g. 7,8")
    parser.add_argument("--limit", type=int, default=0, help="0 = all")
    parser.add_argument("--max-candidates", type=int, default=60)
    parser.add_argument("--output", type=Path,
                        default=ROOT / "data/research/grade8_pairing_proposals.jsonl")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    grades = {int(g) for g in args.grades.split(",")}
    coverage = json.loads(COVERAGE.read_text(encoding="utf-8"))
    published = [row for row in coverage["published_lessons"]
                 if int(str(row["grade"]).replace("K", "0")) in grades]
    unpaired = [row for row in published if row.get("strategy") == "none"]
    print(f"grades {sorted(grades)}: {len(published)} published, "
          f"{len(unpaired)} with strategy=none")

    codes = [row["lesson"] for row in unpaired]
    if args.limit:
        codes = codes[:args.limit]

    done: set[str] = set()
    if args.output.exists():
        for line in args.output.read_text(encoding="utf-8").splitlines():
            try:
                done.add(json.loads(line)["lesson"])
            except (json.JSONDecodeError, KeyError):
                continue
    codes = [code for code in codes if code not in done]
    if done:
        print(f"resuming: {len(done)} already recorded, {len(codes)} to go")
    if not codes:
        print("nothing to do")
        return 0

    contexts = json.loads(FIELD_CONTEXT.read_text(encoding="utf-8"))["field_contexts"]
    rows = window_rows()
    pruned = lesson_topics_and_survivors(codes)

    if args.dry_run:
        for code in codes[:5]:
            info = pruned.get(code, {"topics": [], "machines": []})
            print(f"  {code}: topics={info['topics'] or '[]'} "
                  f"candidates={len(info['machines'])}/{len(rows)}")
        return 0

    client = llm.make_client(ROOT)
    print(f"model: {client['model']}")
    args.output.parent.mkdir(parents=True, exist_ok=True)

    with args.output.open("a", encoding="utf-8") as sink:
        for index, code in enumerate(codes, 1):
            context = contexts.get(code, {})
            lesson = context.get("lesson", {})
            info = pruned.get(code, {"topics": [], "machines": []})
            candidates = info["machines"] or sorted(rows)
            candidates = candidates[:args.max_candidates]
            block = "\n".join(rows[key] for key in candidates if key in rows)
            standards = context.get("standards", []) or []
            standard_text = "\n".join(
                f"  {s.get('code')}: {(s.get('statement') or '')[:200]}"
                for s in standards[:4]) or "  (none recorded)"
            prompt = ASK.format(
                code=code, title=lesson.get("title", "?"),
                concept=lesson.get("concept_id", "?"),
                grade=lesson.get("grade", "?"), unit=lesson.get("unit", "?"),
                standards=standard_text, candidates=block)
            try:
                reply = llm.call_api_messages(
                    [{"role": "user", "content": prompt}],
                    retries=2, timeout=300, fail_on_error=False, **client)
            except Exception as exc:                      # noqa: BLE001
                reply = None
                error = str(exc)[:300]
            else:
                error = None

            parsed = None
            if reply:
                match = re.search(r"\{.*\}", reply, re.S)
                if match:
                    try:
                        parsed = json.loads(match.group(0))
                    except json.JSONDecodeError:
                        parsed = None

            valid: list[dict] = []
            invented: list[str] = []
            if isinstance(parsed, dict):
                for pairing in parsed.get("pairings", []) or []:
                    if not isinstance(pairing, dict):
                        continue
                    machine = str(pairing.get("machine", "")).strip()
                    if machine in rows:
                        valid.append({
                            "machine": machine,
                            "confidence": str(pairing.get("confidence", ""))[:10],
                            "reason": str(pairing.get("reason", ""))[:300],
                            "was_candidate": machine in info["machines"],
                        })
                    elif machine:
                        invented.append(machine)

            record = {
                "lesson": code,
                "title": lesson.get("title"),
                "unit": lesson.get("unit"),
                "topics": info["topics"],
                "candidates_offered": len(candidates),
                "machines_surviving": len(info["machines"]),
                "machines_total": len(rows),
                "pairings": valid,
                "gap": (parsed or {}).get("gap", "") if isinstance(parsed, dict) else "",
                "invented_machines": invented,
                "parse_failed": parsed is None,
                "error": error,
                "review_status": "unreviewed",
            }
            sink.write(json.dumps(record, sort_keys=True) + "\n")
            sink.flush()
            mark = ("E" if error else "?" if parsed is None
                    else str(len(valid)) if valid else "-")
            print(f"  [{index}/{len(codes)}] {mark} {code} "
                  f"cand={len(candidates)} {lesson.get('title', '')[:44]}",
                  flush=True)

    print(f"\nwrote {args.output.relative_to(ROOT)}")
    print("Proposals only. Nothing entered curriculum/im/grade_8.pl.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
