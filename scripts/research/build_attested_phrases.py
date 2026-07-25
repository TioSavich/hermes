#!/usr/bin/env python3
"""Source recognition phrases from the research corpus instead of from one ear.

``knowledge/strategies/canonical_phrases.pl`` holds 185 classroom phrasings I
wrote, and the report that shipped them said so: one person's ear, checked for
ordinary words and nothing else.  The owner pointed out that these strategies
came from the literature, so the corpus should carry the language they arose in.
It does.

``data/research/research_shared.db`` binds corpus rows to automaton signatures in
``automaton_instance_bindings`` (936 rows over 68 signatures), and each binding
carries the ``evidence`` phrases that justified it plus a ``bibtex_key``.  This
builder turns those into cited recognition surfaces and writes
``knowledge/strategies/attested_phrases.pl``.

**The warrant is in two parts and both are emitted.**  The citation warrants the
phrase for the *signature* -- that is what the corpus row was bound to.  It does
not say which step of that signature the phrase names.  So each row also carries
the content words it shares with the action's own label, and a reader can reject
the attachment while keeping the citation.  Attachment needs two shared content
words, or one that occurs in exactly one action of that machine; a phrase that
attaches to nothing is dropped rather than spread over the whole signature.

**Register is recorded, not hidden.**  What the corpus supplies is largely what
researchers call a step -- "appending the partial sums", "indiscriminately
applying verbal rules".  What ``canonical_phrases.pl`` holds is an attempt at what
a student says -- "I made the bottoms match".  Those are different registers, both
appear in a transcript, and conflating them would make the citation carry a claim
it cannot.  So every row here is ``register(analyst)``, and the student-voice
material in the corpus -- 1,540 ``error_instances`` rows with quoted utterances --
is emitted separately as ``attested_utterance/5`` for review rather than as a
surface, because those are sentences and the recognizer matches phrases.

The output is deterministic and byte-compared by
``scripts/checks/attested_phrases.py``.
"""

from __future__ import annotations

import argparse
import collections
import pathlib
import re
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
DB = ROOT / "data/research/research_shared.db"
TABLES = ROOT / "knowledge/strategies/transition_tables"
MAP_PATH = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
DEFAULT_OUTPUT = ROOT / "knowledge/strategies/attested_phrases.pl"

# Phrases the corpus carries that are about the research rather than about the
# doing. A recognition surface has to be something said while working, and these
# are what a paper says while analysing.
ANALYST_ONLY = re.compile(
    r"scheme|construct|iterable|coordination|units? coordinat|assimilat|reversib"
    r"|epistem|framework|conceptual|cognitive|representation|didactic"
    r"|instructional|curricul|task design|interview|protocol|semiotic|register"
    r"|abstraction|encapsulat|reification|schema|buggy|incorrect rules")

STOPWORDS = frozenset(
    "the a an of to in as by and or for with on at from into is it that this "
    "their its one two be was were all".split())

MAX_PHRASE_WORDS = 6
TRANS_RE = re.compile(
    r"(?m)^automaton_transition\((\w+), (\w+), (\w+), (\w+), (\w+),")
MAPS_RE = re.compile(r"(?m)^action_maps\((\w+), (\w+), (\w+), (\w+),")


def usable_phrase(phrase: str) -> bool:
    words = phrase.split()
    if not 1 <= len(words) <= MAX_PHRASE_WORDS:
        return False
    if ANALYST_ONLY.search(phrase):
        return False
    return not re.search(r"[():;]|\d\.\d", phrase)


def content_words(text: str) -> set[str]:
    return {w for w in re.findall(r"[a-z]+", text.lower())
            if w not in STOPWORDS and len(w) > 2}


def pl_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def pl_atom(text: str) -> str:
    """Quote as a Prolog atom, escaping the apostrophes bibtex keys carry."""
    escaped = text.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def pl_words(phrase: str) -> str:
    """The phrase as a Prolog list. A pure digit run stays an integer, because
    that is what library(porter_stem)'s tokenize_atom/2 produces for one."""
    tokens = []
    for token in re.findall(r"[a-z0-9]+", phrase.lower()):
        if token.isdigit():
            tokens.append(token)
        elif re.fullmatch(r"[a-z][a-z0-9_]*", token):
            tokens.append(token)
        else:
            tokens.append(pl_atom(token))
    return ", ".join(tokens)


def read_machines() -> dict[tuple[str, str], set[str]]:
    actions: dict[tuple[str, str], set[str]] = collections.defaultdict(set)
    for path in sorted(TABLES.glob("*.pl")):
        for family, signature, _, action, _ in TRANS_RE.findall(
                path.read_text(encoding="utf-8")):
            actions[(family, signature)].add(action)
    return actions


def read_canonical() -> dict[str, str]:
    return {label: canonical for _, _, label, canonical
            in MAPS_RE.findall(MAP_PATH.read_text(encoding="utf-8"))}


def read_bindings(connection: sqlite3.Connection):
    """Cited phrases per signature, and the quoted utterances per signature."""
    phrases: dict[tuple[str, str], set[tuple[str, str]]] = collections.defaultdict(set)
    for row in connection.execute(
            "select operation, kind, evidence, notes from automaton_instance_bindings"):
        operation, kind, evidence, notes = row
        key_match = re.search(r"bibtex_key=([^;]+)", notes or "")
        if not (evidence and key_match) or key_match.group(1) == "None":
            continue
        key = key_match.group(1).strip()
        for phrase in (part.strip().lower() for part in evidence.split(";")):
            if phrase and usable_phrase(phrase):
                phrases[(operation, kind)].add((phrase, key))
    utterances: dict[tuple[str, str], set[tuple[str, str]]] = collections.defaultdict(set)
    for row in connection.execute(
            "select b.operation, b.kind, e.example, b.notes "
            "from automaton_instance_bindings b "
            "join error_instances e on e.id = b.row_id "
            "where b.row_type = 'misconception' and e.example is not null"):
        operation, kind, example, notes = row
        if "'" not in example and '"' not in example:
            continue
        key_match = re.search(r"bibtex_key=([^;]+)", notes or "")
        key = key_match.group(1).strip() if key_match else "unattributed"
        if key == "None":
            key = "unattributed"
        utterances[(operation, kind)].add((" ".join(example.split()), key))
    return phrases, utterances


def attach(phrases, actions):
    """Attach a signature's cited phrases to the specific actions they name."""
    rows = []
    dropped = collections.Counter()
    for key, pairs in sorted(phrases.items()):
        if key not in actions:
            dropped["signature has no extracted automaton"] += len(pairs)
            continue
        label_words = {action: content_words(action.replace("_", " "))
                       for action in sorted(actions[key])}
        occurrences = collections.Counter(
            word for words in label_words.values() for word in words)
        for phrase, citation in sorted(pairs):
            phrase_words = content_words(phrase)
            scored = []
            for action, words in label_words.items():
                shared = phrase_words & words
                if not shared:
                    continue
                if len(shared) >= 2 or occurrences[next(iter(shared))] == 1:
                    scored.append((len(shared), action, tuple(sorted(shared))))
            if not scored:
                dropped["no action of the signature shares a content word"] += 1
                continue
            best = max(count for count, _, _ in scored)
            for count, action, shared in scored:
                if count == best:
                    rows.append((key[0], key[1], action, phrase, citation, shared))
    return rows, dropped


def build(output: pathlib.Path) -> dict:
    if not DB.exists():
        raise SystemExit(f"{DB} does not exist")
    connection = sqlite3.connect(f"file:{DB}?mode=ro", uri=True)
    try:
        phrases, utterances = read_bindings(connection)
    finally:
        connection.close()
    actions = read_machines()
    canonical = read_canonical()
    rows, dropped = attach(phrases, actions)

    lines: list[str] = []
    W = lines.append
    W("% Generated by scripts/research/build_attested_phrases.py from")
    W("% data/research/research_shared.db. Do not hand-edit; edit the builder.")
    W("%")
    W("% WHY THIS EXISTS. knowledge/strategies/canonical_phrases.pl holds 185")
    W("% classroom phrasings written from one person's ear, and the report that")
    W("% shipped them said so. These strategies came from the literature, so the")
    W("% corpus carries the language they arose in: automaton_instance_bindings")
    W("% binds corpus rows to signatures and keeps the evidence phrases that")
    W("% justified each binding, with a bibtex key.")
    W("%")
    W("% THE WARRANT IS IN TWO PARTS AND BOTH ARE HERE. The citation warrants the")
    W("% phrase for the SIGNATURE, which is what the corpus row was bound to. It")
    W("% does not say which step of that signature the phrase names. So every row")
    W("% carries the content words the phrase shares with the action's own label,")
    W("% and a reader can reject the attachment while keeping the citation.")
    W("% Attachment needs two shared content words, or one that occurs in exactly")
    W("% one action of that machine. A phrase that attaches to nothing is dropped")
    W("% rather than spread across the signature.")
    W("%")
    W("% REGISTER. What the corpus supplies is mostly what a researcher calls a")
    W("% step: 'appending the partial sums', 'indiscriminately applying verbal")
    W("% rules'. What canonical_phrases.pl holds is an attempt at what a student")
    W("% says. Both turn up in a transcript and they are not the same register, so")
    W("% every row here says register(analyst) and nothing here claims to be")
    W("% student voice. The student voice in the corpus is the quoted utterances")
    W("% below, which are sentences rather than phrases and are emitted for review")
    W("% rather than as recognition surfaces.")
    W("")
    W(":- module(attested_phrases,")
    W("          [ attested_phrase/6,")
    W("            attested_utterance/4")
    W("          ]).")
    W("")
    W("% attested_phrase(Family, Signature, Action, Words, source(BibtexKey),")
    W("%                 attachment(register(analyst), shared([Word, ...]))).")
    for family, signature, action, phrase, citation, shared in rows:
        W(f"attested_phrase({family}, {signature}, {action},")
        W(f"                [{pl_words(phrase)}],")
        W(f"                source({pl_atom(citation)}),")
        W(f"                attachment(register(analyst), shared([{', '.join(shared)}]))).")
    W("")
    W("% attested_utterance(Family, Signature, Quote, source(BibtexKey)) -- a")
    W("% quoted student utterance the corpus records for a machine this repository")
    W("% runs. Sentences, not phrases: recorded so the student register has a")
    W("% source at all, and left out of the recognition surfaces because the")
    W("% recognizer matches phrases. Mining these into phrases is authoring work")
    W("% with a citation behind it, which is the point of keeping them.")
    utterance_rows = []
    for key in sorted(utterances):
        if key not in actions:
            continue
        for quote, citation in sorted(utterances[key]):
            utterance_rows.append((key[0], key[1], quote, citation))
            W(f"attested_utterance({key[0]}, {key[1]},")
            W(f"                   {pl_string(quote)},")
            W(f"                   source({pl_atom(citation)})).")

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n", encoding="utf-8")

    reached_canonical = {canonical[a] for _, _, a, _, _, _ in rows if a in canonical}
    return {
        "cited_phrase_rows": len(rows),
        "distinct_phrase_attachments": len({(f, s, a, p) for f, s, a, p, _, _ in rows}),
        "signatures": len({(f, s) for f, s, *_ in rows}),
        "actions": len({(f, s, a) for f, s, a, *_ in rows}),
        "canonical_actions_reached": len(reached_canonical),
        "bibtex_keys": len({c for *_, c, _ in rows}),
        "quoted_utterances": len(utterance_rows),
        "dropped": dict(dropped),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=pathlib.Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    summary = build(args.output)
    print(f"wrote {args.output}")
    for key, value in summary.items():
        print(f"  {key:28s} {value}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
