#!/usr/bin/env python3
"""Run the strategy recognizer over every student turn in the TalkMoves corpus.

The recognizer models 106 execution-observed automata and abstains by design.
Until now it has met three transcripts and one worked demonstration.  The Sumner
lab's released corpus is 567 K-12 mathematics lesson transcripts, sentence
segmented, with teacher and student moves already coded by people — real
classroom talk at a scale this instrument has never been asked to face.

What this measures is deliberately narrow, because it is what can be measured
without a second labelling effort.  TalkMoves labels *discourse* moves; Hermes
recognizes *mathematical strategies*.  Those are different taxonomies and no
agreement statistic between them would mean anything.  What the corpus can settle
is the question a prototype has to answer before anyone funds a study:

  When this instrument reads real classroom speech, how often does it say
  something, how often does it stay silent, and is what it says defensible?

Silence is the interesting half.  A recognizer that fires on everything is a
keyword matcher wearing a citation; one that never fires is furniture.  The rate
and its distribution over machines are reported, never a claim that a recognition
is correct — correctness needs a reader and that is a separate, later pass over
the sample this writes out.

**Licence.** TalkMoves is CC BY-NC-SA 4.0 (Jacobs et al. 2022; Suresh et al.
2021).  Under the standing rights ruling this driver writes **derived counts**
and no transcript text.  A `--sample` file of short fragments can be written for
a human reading pass, and it is kept out of the repository tree by default.
"""
from __future__ import annotations

import argparse
import collections
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CORPUS = Path.home() / "Documents/GitHub/TalkMoves/data"
SPLITS = ("train_data_504.xlsx", "test_data_63.xlsx")

# One SWI process reads sentences from stdin and prints recognitions, because
# a process per sentence would put a fork between the instrument and every
# clause of classroom speech.
PROLOG_DRIVER = r"""
:- use_module(hermes(strategy_recognizer), [recognize_strategies/2]).

% Run with -g main -t halt, never initialization(main, main): under -l/-s the
% toplevel otherwise reads the piped sentences as Prolog source and dies on the
% first clause of English. The same trap silently disabled two checks earlier
% today.
main :-
    read_line_to_string(user_input, First),
    loop(First).

loop(end_of_file) :- !.
loop(Line) :-
    (   catch(recognize_strategies(Line, Candidates), _, fail)
    ->  true
    ;   Candidates = []
    ),
    emit(Candidates),
    read_line_to_string(user_input, Next),
    loop(Next).

emit([]) :- !, format("-~n").
emit(Candidates) :-
    findall(Text,
            ( member(C, Candidates), candidate_text(C, Text) ),
            Texts),
    atomic_list_concat(Texts, ' ', Joined),
    format("~w~n", [Joined]).

% A candidate is a dict. What matters for a sweep is which machine, how much of
% it was matched, and on what basis: support_level lexical_hint with
% matched_count 1 means one token met one action, which is a hint and not a
% reading, and reporting it beside a partial_trace would inflate the result.
candidate_text(Candidate, Text) :-
    get_dict(operation, Candidate, Operation),
    get_dict(kind, Candidate, Kind),
    ( get_dict(support_level, Candidate, Support) -> true ; Support = unknown ),
    ( get_dict(matched_count, Candidate, Matched) -> true ; Matched = 0 ),
    ( get_dict(expected_actions, Candidate, Expected) -> true ; Expected = 0 ),
    ( get_dict(confidence, Candidate, Confidence) -> true ; Confidence = 0 ),
    format(atom(Text), '~w/~w|~w|~w|~w|~4f',
           [Operation, Kind, Support, Matched, Expected, Confidence]).
"""


def student_sentences(limit_transcripts: int) -> list[tuple[str, str, str]]:
    """(transcript, speaker, sentence) for student turns, from both splits."""
    try:
        import pandas
    except ImportError:
        print("FAIL: pandas is needed to read the TalkMoves workbooks",
              file=sys.stderr)
        raise SystemExit(1)
    rows: list[tuple[str, str, str]] = []
    seen: set[str] = set()
    for split in SPLITS:
        path = CORPUS / split
        if not path.exists():
            print(f"FAIL: {path} not found", file=sys.stderr)
            raise SystemExit(1)
        frame = pandas.read_excel(path)
        for transcript, speaker, sentence in zip(
                frame["Transcript"], frame["Speaker"], frame["Sentence"]):
            if not isinstance(sentence, str) or not sentence.strip():
                continue
            name = str(transcript)
            if limit_transcripts and name not in seen and len(seen) >= limit_transcripts:
                continue
            seen.add(name)
            if str(speaker).strip().upper().startswith("S"):
                rows.append((name, str(speaker), sentence.strip()))
    return rows


def recognize(sentences: list[str], timeout: int) -> list[str]:
    driver = ROOT / "scripts/research/_talkmoves_sweep_driver.pl"
    driver.write_text(PROLOG_DRIVER, encoding="utf-8")
    try:
        payload = "\n".join(s.replace("\n", " ") for s in sentences) + "\n"
        result = subprocess.run(
            ["swipl", "-q", "--on-warning=status", "--on-error=status",
             "-l", "paths.pl", "-s", str(driver), "-g", "main", "-t", "halt"],
            cwd=ROOT, input=payload, capture_output=True, text=True,
            timeout=timeout)
    finally:
        driver.unlink(missing_ok=True)
    if result.returncode:
        print(f"FAIL: recognizer exited {result.returncode}\n{result.stderr[-1500:]}",
              file=sys.stderr)
        raise SystemExit(1)
    lines = result.stdout.splitlines()
    if len(lines) != len(sentences):
        print(f"FAIL: {len(lines)} results for {len(sentences)} sentences",
              file=sys.stderr)
        raise SystemExit(1)
    return lines


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--transcripts", type=int, default=0,
                        help="0 = every transcript in both splits")
    parser.add_argument("--batch", type=int, default=2000)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--output", type=Path,
                        default=ROOT / "data/research/talkmoves_recognizer_sweep.json")
    parser.add_argument("--sample", type=Path, default=None,
                        help="write recognized fragments for a reading pass; "
                             "keep this OUTSIDE the repository (CC BY-NC-SA)")
    args = parser.parse_args()

    rows = student_sentences(args.transcripts)
    transcripts = {t for t, _, _ in rows}
    print(f"student sentences: {len(rows)} across {len(transcripts)} transcripts",
          flush=True)
    if not rows:
        print("FAIL: no student sentences read", file=sys.stderr)
        return 1

    fired = 0
    by_machine: collections.Counter = collections.Counter()
    by_family: collections.Counter = collections.Counter()
    by_support: collections.Counter = collections.Counter()
    by_machine_substantive: collections.Counter = collections.Counter()
    sentence_support: collections.Counter = collections.Counter()
    substantive = 0
    per_transcript: collections.Counter = collections.Counter()
    sample: list[dict] = []

    for start in range(0, len(rows), args.batch):
        chunk = rows[start:start + args.batch]
        results = recognize([s for _, _, s in chunk], args.timeout)
        for (transcript, _speaker, sentence), line in zip(chunk, results):
            if line.strip() == "-":
                continue
            fired += 1
            per_transcript[transcript] += 1
            machines = []
            best_support = "none"
            for token in line.split():
                parts = token.split("|")
                if len(parts) != 5 or "/" not in parts[0]:
                    continue
                machine, support, matched, expected, confidence = parts
                by_machine[machine] += 1
                by_family[machine.split("/")[0]] += 1
                by_support[support] += 1
                if int(matched) >= 2:
                    substantive += 1
                    by_machine_substantive[machine] += 1
                if support == "partial_trace" or best_support == "partial_trace":
                    best_support = "partial_trace"
                elif best_support == "none":
                    best_support = support
                machines.append({"machine": machine, "support": support,
                                 "matched": int(matched),
                                 "expected": int(expected),
                                 "confidence": float(confidence)})
            sentence_support[best_support] += 1
            if args.sample and len(sample) < 400:
                sample.append({"transcript": transcript, "sentence": sentence,
                               "machines": machines})
        print(f"  {min(start + args.batch, len(rows))}/{len(rows)}"
              f"  fired={fired}", flush=True)

    payload = {
        "corpus": "TalkMoves (Sumner lab), CC BY-NC-SA 4.0; derived counts only",
        "student_sentences": len(rows),
        "transcripts": len(transcripts),
        "sentences_with_a_candidate": fired,
        "abstention_rate": round(1 - fired / len(rows), 4),
        "distinct_machines_fired": len(by_machine),
        "candidate_support_levels": dict(by_support.most_common()),
        "sentences_by_best_support": dict(sentence_support.most_common()),
        "candidates_matching_two_or_more_actions": substantive,
        "distinct_machines_with_two_or_more_matched": len(by_machine_substantive),
        "top_machines_two_or_more_matched":
            dict(by_machine_substantive.most_common(25)),
        "by_family": dict(by_family.most_common()),
        "top_machines": dict(by_machine.most_common(40)),
        "transcripts_with_no_recognition":
            len(transcripts) - len(per_transcript),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n",
                           encoding="utf-8")
    if args.sample:
        args.sample.parent.mkdir(parents=True, exist_ok=True)
        args.sample.write_text(
            "\n".join(json.dumps(r, sort_keys=True) for r in sample) + "\n",
            encoding="utf-8")
        print(f"wrote {len(sample)} fragments to {args.sample} "
              "(licence: keep out of the repository)")

    print()
    print(f"student sentences        : {len(rows)}")
    print(f"recognized something     : {fired}")
    print(f"abstained                : {len(rows) - fired} "
          f"({payload['abstention_rate']:.1%})")
    print(f"distinct machines fired  : {len(by_machine)} of 232")
    print(f"candidate support levels : {dict(by_support.most_common())}")
    print(f"candidates matching >=2  : {substantive}")
    print(f"  over machines          : {len(by_machine_substantive)}")
    print(f"transcripts with nothing : {payload['transcripts_with_no_recognition']}"
          f" of {len(transcripts)}")
    print(f"wrote {args.output.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
