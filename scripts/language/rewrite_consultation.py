#!/usr/bin/env python3
"""Ask a model to restate what the deterministic reader refused, then test it.

The reader refuses a curriculum sentence.  Naming the sentence's class buys
nothing — the earlier arm of the consultation loop did that and could never
admit a row, because a class name creates no facts.  This arm asks for a
restatement instead: the same claim, in the shapes the reader already reads,
with every number and every name kept.

The model's restatement is testimony, never truth.  Three gates decide:

1.  Numeral preservation.  The multiset of numbers in the restatement must
    equal the multiset in the original.  Checked in Python, exactly.
2.  Name preservation.  Every capitalized name in the original must survive.
3.  The reader.  SWI-Prolog must parse the restatement into a non-empty fact
    set.  A sentence that parses to nothing has not been read.

A restatement that passes all three is admitted to an attributed store with
its model, its prompt hash, and its gate receipt, so every admitted row stays
vetoable one by one.  A restatement that fails any gate is recorded in the
audit ledger with the gate that closed.

The same driver speaks to REALLMS or to a node-local server, so the loop runs
on the controller and at volume on the cluster without a second implementation.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

ROOT = pathlib.Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "scripts/language"))

from hermes.app import llm  # noqa: E402

GATE = ROOT / "scripts/language/rewrite_gate.pl"
LEDGER = ROOT / "hermes/app/runtime/experiments/language/pusu_results.jsonl"
STRUCTURE_ROWS = ROOT / "curriculum/im/generated/structure_task_rows.jsonl"
DEFAULT_OUT = (
    ROOT / "hermes/app/runtime/experiments/language/rewrite_consultation.jsonl"
)

NUMERAL = re.compile(r"-?\d[\d,]*(?:\.\d+)?")
NAME = re.compile(r"\b[A-Z][a-z]{2,}\b")
STOP_NAMES = {
    "The", "This", "That", "These", "Those", "There", "Here", "How", "What",
    "Which", "Where", "When", "Why", "Who", "Each", "Every", "Some", "Then",
    "Find", "Show", "Explain", "Write", "Draw", "Solve", "Use", "Are", "Does",
    "Decide", "Determine", "Complete", "Choose", "Select", "Compare",
}

SYSTEM = (
    "You restate one sentence from a school mathematics lesson so that a "
    "narrow parser can read it. You keep every number and every person's name "
    "exactly as they are. You never solve anything and you never add a number "
    "that the sentence does not carry. You answer with the restatement alone."
)

SHAPES = """The parser reads these shapes:

  possession        Mitchell has 30 pencils.
  possession        There are 6 students.
  change (add)      Clare puts 2 more books on the shelf.
  change (remove)   Mitchell gives away 6 pencils.
  equal groups      Each box has 5 pencils in it.
  rate              A machine prints 480 copies every 4 minutes.
  comparison        Tyler has 6 more blocks than Elena.
  demand            How many pencils does Mitchell have?
  demand            How many books are on the shelf now?
"""

INSTRUCTION = """{shapes}
Restate this sentence using those shapes. Keep every number exactly. Keep every
person's name exactly. Do not solve anything. Do not add information.

Answer with the restated sentence alone. Do not name the shape you used.

If the sentence is only arithmetic written in symbols — for example
"7 + 1 7 + 2 9- 1" — answer with exactly: ALREADY AN EXPRESSION

If the sentence carries no quantity and no question — for example a direction
like "Explain your reasoning." — answer with exactly: NO QUANTITY.
A sentence that contains a number almost always carries a quantity, so use
this answer sparingly.

If you cannot restate it without changing what it says, answer with exactly:
CANNOT RESTATE

Sentence:
  {sentence}

Restatement:"""

REFUSALS = {"NO QUANTITY", "CANNOT RESTATE", "ALREADY AN EXPRESSION"}

# The model sometimes prefixes the shape it chose.  That label is not part of
# the restatement and the reader chokes on it; 181 of 181 refusals in the
# first volume run carried one, and 22 of them read once it was removed.
SHAPE_LABEL = re.compile(
    r"^\s*(possession|change\s*\((?:add|remove)\)|change|equal\s+groups|rate|"
    r"comparison|demand)\s+(?=\S)",
    re.I,
)

# A sentence the printed-expression reader already handles must never reach
# the model.  605 of 1,578 calls in the first volume run were spent asking for
# a restatement of "7 + 1 7 + 2 9- 1 9- 2".
EXPRESSION_ONLY = re.compile(r"^[\d\s.,+\-*/=×÷x()]+$")


def sha(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def numerals(text: str) -> Counter:
    found: Counter = Counter()
    for token in NUMERAL.findall(text):
        cleaned = token.replace(",", "")
        try:
            value = float(cleaned)
        except ValueError:
            continue
        found[str(int(value)) if value == int(value) else str(value)] += 1
    return found


def names(text: str) -> set[str]:
    return {word for word in NAME.findall(text) if word not in STOP_NAMES}


class Gate:
    """One long-lived SWI process; the reader stays loaded across candidates."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.process = subprocess.Popen(
            ["swipl", "-q", "-f", str(GATE)],
            cwd=str(ROOT),
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
        )

    def read(self, identifier: str, text: str) -> dict[str, Any]:
        request = json.dumps({"id": identifier, "text": text}, ensure_ascii=False)
        with self.lock:
            assert self.process.stdin and self.process.stdout
            self.process.stdin.write(request + "\n")
            self.process.stdin.flush()
            line = self.process.stdout.readline()
        if not line:
            raise RuntimeError("rewrite gate died")
        return json.loads(line)

    def close(self) -> None:
        try:
            assert self.process.stdin
            self.process.stdin.close()
            self.process.wait(timeout=30)
        except Exception:  # noqa: BLE001
            self.process.kill()


def unadmitted_lessons() -> set[str]:
    """Lessons that carry anchored task statements but no defragged row.

    The defrag builder admits a lesson only when one of the authored task
    parsers fires, so about half the corpus has never been offered to the
    readers at all. Those lessons are where consultation has the most to say.
    """
    text = (
        ROOT / "curriculum/im/generated/compiled_defragged_task_instances.pl"
    ).read_text(encoding="utf-8")
    admitted = set(re.findall(r"'(IM-G[K1-8]-U\d+-L\d+)'", text))
    lessons: set[str] = set()
    for line in STRUCTURE_ROWS.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        lessons.add(json.loads(line)["lesson"])
    return lessons - admitted


def structure_sentences(limit: int, grades: set[str] | None) -> list[dict[str, Any]]:
    """Refused sentences from the anchored task statements of those lessons.

    Every candidate is a sentence of a task statement the structure pass found
    and the byte-anchor confirmed, drawn only from lessons the defrag store
    never admitted. The reader decides what refuses; only refusals are sent.
    """
    from probe_reader_coverage import sentences as split_sentences

    wanted = unadmitted_lessons()
    gate = Gate()
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    try:
        for line in STRUCTURE_ROWS.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            record = json.loads(line)
            lesson = record["lesson"]
            if lesson not in wanted:
                continue
            if grades and lesson.split("-")[1].removeprefix("G") not in grades:
                continue
            ask = (record.get("ask") or {}).get("text") or ""
            for text in split_sentences(ask):
                text = text.strip()
                if len(text) < 12 or text in seen:
                    continue
                if EXPRESSION_ONLY.fullmatch(text):
                    continue
                seen.add(text)
                reading = gate.read(sha(text)[:12], text)
                if reading.get("parsed") and reading.get("fact_count"):
                    continue
                rows.append(
                    {
                        "text": text,
                        "lesson": lesson,
                        "grade": lesson.split("-")[1].removeprefix("G"),
                        "record_id": f"{lesson}#{record['task_index']}",
                        "sentence_form": record.get("kind"),
                        "source": "structure_task_rows",
                    }
                )
                if len(rows) >= limit:
                    return rows
    finally:
        gate.close()
    return rows


def refused_sentences(limit: int, grades: set[str] | None) -> list[dict[str, Any]]:
    """Sentences the deterministic reader did not read, from the live ledger."""
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    with LEDGER.open(encoding="utf-8") as handle:
        for line in handle:
            record = json.loads(line)
            if grades and record.get("grade") not in grades:
                continue
            for sentence in record.get("sentences", []):
                if sentence.get("parsed"):
                    continue
                text = (sentence.get("text") or "").strip()
                if len(text) < 12 or text in seen:
                    continue
                if EXPRESSION_ONLY.fullmatch(text):
                    # The printed-expression reader owns this shape already.
                    continue
                seen.add(text)
                rows.append(
                    {
                        "text": text,
                        "lesson": record.get("lesson"),
                        "grade": record.get("grade"),
                        "record_id": record.get("record_id"),
                        "sentence_form": sentence.get("sentence_form"),
                    }
                )
                if len(rows) >= limit:
                    return rows
    return rows


def call_model(args, key, url, ssl_ctx, prompt: str) -> tuple[str, str]:
    messages = [
        {"role": "system", "content": SYSTEM},
        {"role": "user", "content": prompt},
    ]
    if args.endpoint:
        import urllib.request

        payload = json.dumps(
            {
                "model": args.model,
                "messages": messages,
                "max_tokens": args.max_tokens,
                "temperature": 0.0,
                "stream": False,
            }
        ).encode("utf-8")
        request = urllib.request.Request(
            args.endpoint.rstrip("/") + "/v1/chat/completions",
            data=payload,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(request, timeout=args.timeout) as response:
                body = json.loads(response.read())
        except Exception as error:  # noqa: BLE001
            return f"transport:{type(error).__name__}", ""
        choices = body.get("choices") or []
        if not choices:
            return "no_choices", ""
        return "ok", (choices[0].get("message") or {}).get("content") or ""
    result = llm.call_api_messages_result(
        messages,
        api_key=key,
        api_url=url,
        model=args.model,
        ssl_ctx=ssl_ctx,
        max_tokens=args.max_tokens,
        timeout=args.timeout,
    )
    if result.outcome != "ok":
        return result.finish_reason or result.outcome or "transport", ""
    return "ok", result.content


def clean(reply: str) -> str:
    text = reply.strip()
    text = re.sub(r"^(restatement|answer)\s*:\s*", "", text, flags=re.I)
    text = text.strip().strip('"').strip()
    text = text.splitlines()[0].strip() if text else ""
    if text.upper() in REFUSALS:
        return text
    return SHAPE_LABEL.sub("", text).strip()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=200)
    parser.add_argument("--grades", default="", help="comma separated, e.g. 6,7")
    parser.add_argument("--model", default="glm-5.2")
    parser.add_argument("--endpoint", default=None)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--max-tokens", type=int, default=2048)
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT)
    parser.add_argument("--restart", action="store_true")
    parser.add_argument(
        "--source",
        choices=("ledger", "structure"),
        default="ledger",
        help="ledger = refused sentences of admitted statements; "
        "structure = asks of lessons the defrag store never admitted",
    )
    args = parser.parse_args()

    key = url = ssl_ctx = None
    if not args.endpoint:
        llm.load_dotenv(ROOT)
        key = os.environ.get("REALLMS_API_KEY")
        if not key:
            raise SystemExit("REALLMS_API_KEY missing")
        url = llm.resolve_api_url()
        ssl_ctx = llm.build_ssl_context()

    grades = {g.strip() for g in args.grades.split(",") if g.strip()} or None
    args.out.parent.mkdir(parents=True, exist_ok=True)
    if args.restart and args.out.exists():
        args.out.unlink()
    done: set[str] = set()
    if args.out.exists():
        for line in args.out.read_text(encoding="utf-8").splitlines():
            try:
                done.add(json.loads(line)["sentence_sha"])
            except Exception:  # noqa: BLE001
                continue

    pick = structure_sentences if args.source == "structure" else refused_sentences
    candidates = [
        row for row in pick(args.limit * 3, grades)
        if sha(row["text"]) not in done
    ][: args.limit]
    print(f"refused sentences to consult: {len(candidates)}", flush=True)

    gate = Gate()
    stats: Counter = Counter()
    write_lock = threading.Lock()
    handle = args.out.open("a", encoding="utf-8")

    def consult(row: dict[str, Any]) -> dict[str, Any]:
        sentence = row["text"]
        prompt = INSTRUCTION.format(shapes=SHAPES, sentence=sentence)
        started = time.time()
        outcome, content = call_model(args, key, url, ssl_ctx, prompt)
        record: dict[str, Any] = {
            **row,
            "sentence_sha": sha(sentence),
            "prompt_sha": sha(prompt),
            "model": args.model,
            "outcome": outcome,
            "seconds": round(time.time() - started, 2),
        }
        if outcome != "ok":
            record["gate"] = "transport"
            return record
        restatement = clean(content)
        record["restatement"] = restatement
        if restatement.upper() in REFUSALS or not restatement:
            record["gate"] = "model_declined"
            record["declined_as"] = restatement.upper() or "empty"
            return record
        wanted, got = numerals(sentence), numerals(restatement)
        if wanted != got:
            record["gate"] = "numerals_changed"
            record["numerals"] = {"original": dict(wanted), "restated": dict(got)}
            return record
        missing = names(sentence) - names(restatement)
        if missing:
            record["gate"] = "names_dropped"
            record["names_dropped"] = sorted(missing)
            return record
        reading = gate.read(record["sentence_sha"][:12], restatement)
        record["reader"] = {
            "parsed": reading.get("parsed"),
            "fact_count": reading.get("fact_count"),
            "ask_count": reading.get("ask_count"),
            "facts": reading.get("facts"),
        }
        if not reading.get("parsed"):
            record["gate"] = "reader_refused"
            # A refusal here is either a missing sentence class or a missing
            # countable noun. "Andre has 4 blocks." reads; "Andre has 4 cubes."
            # does not. Record the nouns that follow a numeral so the two
            # demands can be counted apart instead of guessed at.
            record["nouns_after_numeral"] = sorted(
                set(re.findall(r"\b\d+(?:\.\d+)?\s+([A-Za-z][A-Za-z-]{1,})", restatement))
            )
            return record
        if not reading.get("fact_count"):
            record["gate"] = "parsed_to_nothing"
            return record
        record["gate"] = "admitted"
        return record

    try:
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            futures = {pool.submit(consult, row): row for row in candidates}
            for position, future in enumerate(as_completed(futures), 1):
                try:
                    record = future.result()
                except Exception as error:  # noqa: BLE001
                    record = {
                        "gate": "driver_error",
                        "error": f"{type(error).__name__}: {error}",
                    }
                with write_lock:
                    stats[record.get("gate", "?")] += 1
                    handle.write(json.dumps(record, ensure_ascii=False) + "\n")
                    handle.flush()
                    if position % 10 == 0 or record.get("gate") == "admitted":
                        print(
                            f"[{position}/{len(candidates)}] {record.get('gate')} "
                            f"{(record.get('restatement') or '')[:70]}",
                            flush=True,
                        )
    finally:
        handle.close()
        gate.close()

    total = sum(stats.values())
    print("\n== gates ==", flush=True)
    for name, count in stats.most_common():
        share = count / total if total else 0
        print(f"{count:6d}  {share:6.1%}  {name}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
