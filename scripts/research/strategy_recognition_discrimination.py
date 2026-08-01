#!/usr/bin/env python3
"""Measure whether strategy_recognize discriminates, against its own baselines.

The recognizer returns candidates for an utterance. Two questions decide
whether those candidates carry information, and neither is answered by an
accuracy figure on its own:

  Does the top candidate depend on the mathematics in the utterance, or only
  on which surfaces happen to be shared by many traces?

  Can the recognizer decline? A tool that answers everything scores well on
  any set made only of things worth answering.

So the set below has three kinds of item. Positives come from labels the
strategy corpus already carries: the cited-phrase and student-prose arms of
data/research/recognition_benchmark.json, whose gold is a family and a
signature, and the recognizer's own canonical and synonym renderings of every
observed trace, which are circular by construction and are kept only because
the gate requires them to stay at clean_run. Negatives are ordinary
non-mathematical English in three registers: plain prose written without
consulting the surface inventory, the first-person narrating register a
transcript carries, and sentences carrying one single-word recognition surface
each.

Every accuracy is printed beside the best constant answer for the same rows,
because two thirds of the benchmark's positive items carry one gold signature
and an accuracy that does not name that is not a result. Macro accuracy over
signatures and a multi-word-only cut are printed for the same reason: 87 of the
999 positive items are a single word, and naming a strategy from one word is
a coin toss the micro number would otherwise credit.

Items are split dev/holdout by a hash of the item id, so a floor tuned on one
half can be reported on the other.

docs/research/2026-08-01-strategy-recognize-discrimination.md holds the run
this was written for.
"""
from __future__ import annotations

import argparse
import collections
import hashlib
import json
import statistics
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BENCHMARK = ROOT / "data/research/recognition_benchmark.json"
PATHS_PL = ROOT / "paths.pl"

# Ordinary non-mathematical English, written without consulting the
# recognizer's surface inventory. These measure the rate at which everyday
# prose trips a recognition surface for no reason.
N_PLAIN = [
    "The bus was late again and the shelter roof leaks whenever it rains.",
    "My neighbour repainted her fence a colour I would not have chosen.",
    "The bread needs another hour before the crust sets properly.",
    "He left the concert early because the support act ran long.",
    "She keeps her bicycle in the hallway even though the landlord objects.",
    "The library closes at four on Sundays during the winter.",
    "Nobody remembered to water the tomatoes while we were away.",
    "The film was shot entirely on location in a disused hospital.",
    "There is a heron that stands in the shallows near the weir every morning.",
    "I keep meaning to write back to her and I keep not doing it.",
    "The dog barks at the postman and at nothing in particular.",
    "We ran out of coffee and the shop on the corner had shut.",
    "His accent shifts depending on who he is talking to.",
    "The roof tiles came loose in the storm on Thursday night.",
    "She prefers the older recording, the one with the tape hiss.",
    "The train guard apologised for a delay nobody had noticed.",
    "That restaurant changed hands and the menu is unrecognisable now.",
    "My brother is learning the clarinet and the neighbours are patient.",
    "The seeds never came up, probably because the soil stayed cold.",
    "He wears the same jacket in every photograph from that decade.",
    "The council sent a letter about the bins and then another one.",
    "Her cat sleeps on the warm patch above the boiler.",
    "The paint on the windowsill is blistering where the sun hits it.",
    "They cancelled the fireworks because of the wind.",
    "The recipe calls for a herb I have never been able to find.",
    "He talks about the war his grandfather fought as if he were there.",
    "The lock on the shed has rusted and the key no longer turns.",
    "She reads three books at once and finishes none of them.",
    "The path floods every spring and the sign warning about it has faded.",
    "My phone updates itself at the worst possible moments.",
    "The choir practises in the church hall on Wednesday evenings.",
    "There was a wasp nest in the eaves and we had to call someone.",
    "He collects postcards of places he has never visited.",
    "The washing machine makes a noise the engineer could not reproduce.",
    "She left the party without saying goodbye to anyone.",
    "The hedge needs cutting and I have been saying so since June.",
    "They serve breakfast until eleven and nobody arrives before ten.",
    "The photograph is out of focus but it is the only one we have.",
    "His handwriting slopes backwards, which the teachers disliked.",
    "The kettle takes forever now that the element is furred up.",
    "We watched the tide come in and then we walked back.",
    "The bookshop keeps a chair by the window for people who linger.",
    "Her flight was diverted and she spent the night in an airport hotel.",
    "The apples this year are small and full of grubs.",
    "He plays the same three chords and calls it songwriting.",
    "The fog did not lift until the middle of the afternoon.",
    "They repaved the road and the drains have flooded ever since.",
    "She keeps a diary but writes in it only when she is unhappy.",
    "The parcel arrived open and half the contents were missing.",
    "My aunt sends the same birthday card every year by accident.",
    "The pub quiz is rigged and everyone knows which team is rigging it.",
    "He fell asleep during the second half and missed the ending.",
    "The gutters are full of moss and the ladder is broken.",
    "She teaches yoga on Tuesdays in a room above the chemist.",
    "The clock in the hall runs fast and nobody adjusts it.",
    "There is a draught under the door that no amount of tape fixes.",
    "They named the boat after a horse that never won anything.",
    "The garden centre has closed and the site is being built on.",
    "He apologised in a way that made the situation worse.",
    "The heating comes on at six whether anyone is awake or not.",
]

# The same, in the first-person narrating register a transcript carries. This
# is the register the reported defect lives in: the recognizer's broadest
# surfaces are self-report phrases, and this stratum is written to that class
# rather than to any one example of it.
N_SELF_REPORT = [
    "I got a letter from the bank and I still have not opened it.",
    "I got to the station just as the doors were closing.",
    "I have a cousin in Leeds and I have never once visited her.",
    "Then I remembered the oven was still on and I ran back.",
    "So it is going to rain all weekend, which ruins the plan.",
    "I started with the kitchen and then I lost interest entirely.",
    "I looked at the photographs and I could not name half the people.",
    "I got the job, though I am not sure I wanted it.",
    "I have been meaning to cancel that subscription for a year.",
    "Then I told him what I thought and he stopped speaking to me.",
    "So it turns out the leak was coming from upstairs the whole time.",
    "I started with good intentions and finished with a takeaway.",
    "I looked at the map and decided the walk was too far.",
    "I got a new puppy and I got to name her.",
    "I have the receipt somewhere, probably in the car.",
    "Then I noticed the door had been open the whole afternoon.",
    "So it is settled, we are going in September instead.",
    "I started with the oldest boxes because they smelled of damp.",
    "I looked at him and I knew he had forgotten my name.",
    "I got halfway through the book and gave up on it.",
    "I have no idea where the spare key ended up.",
    "Then I put the kettle on because there was nothing else to do.",
    "So it was my fault after all, which he enjoyed pointing out.",
    "I started with a phone call and ended up writing three letters.",
    "I looked at the sky and decided against the washing.",
    "I got the impression she wanted us to leave.",
    "I have a photograph of that street before they knocked it down.",
    "Then I found the receipt in the pocket of a coat I never wear.",
    "So it is her turn to drive and mine to stay awake.",
    "I started with the intention of tidying and ended up reading.",
    "I looked at the price and put it straight back on the shelf.",
    "I got two of the same present from two different people.",
    "I have not slept properly since the clocks changed.",
    "Then I heard the gate and knew somebody was in the garden.",
    "So it is a long story and none of it reflects well on me.",
    "I started with the assumption that he was joking.",
    "I looked at the guest list and recognised almost nobody.",
    "I got soaked walking back from the shop without a coat.",
    "I have kept every letter she ever sent me.",
    "Then I realised the address on the envelope was wrong.",
    "So it is done, and I do not want to talk about it again.",
    "I started with a small garden and now it has taken over.",
    "I looked at the calendar and the date had already passed.",
    "I got lost twice on the way and arrived in a temper.",
    "I have a friend who claims to have met him once.",
    "Then I gave up and asked somebody who actually knew.",
    "So it is the same argument every Christmas without fail.",
    "I started with the radio on and turned it off after ten minutes.",
    "I looked at the instructions and they were in four languages, none useful.",
    "I got the last seat on the train and felt briefly triumphant.",
    "I have never understood why anyone enjoys camping.",
    "Then I closed the laptop and went to bed.",
    "So it was the cat all along, knocking things off the shelf.",
    "I started with a list and abandoned it by lunchtime.",
    "I looked at the bill and asked them to check it again.",
    "I got a puncture on the towpath and had to walk home.",
    "I have the wrong sort of memory for names.",
    "Then I said something I regretted immediately.",
    "So it is going to be a long winter by the look of things.",
    "I started with the smallest job so I could feel I had done something.",
]

# One ordinary sentence per single-word recognition surface with an everyday
# sense. 32 surfaces are a single word; 17 come from an action identifier and
# 15 are cited as bare words. This stratum was added after the first
# measurement, when that route was found.
N_SINGLE_WORD = [
    "The viability of the whole scheme depends on whether the council agrees.",
    "The house was transformed by nothing more than new curtains.",
    "She was selected for the choir and has not stopped talking about it.",
    "The second act was better than the first.",
    "He weighs his letters on kitchen scales before posting them.",
    "There is a residual smell of paint three weeks after they finished.",
    "I trust his judgment about wine and about nothing else.",
    "The chimney used to emit a smell of soot every autumn.",
    "The contrast between the two brothers is hard to miss.",
    "You cannot compare the two records, they were made decades apart.",
    "The bus does not stop here after seven in the evening.",
    "They split the bill and argued about it in the car.",
    "The rounding of the hills on that coast is what I remember.",
    "The edges of the table have been rounded so the children do not bruise.",
    "We went round to see them and nobody was in.",
    "You can omit the middle verse, nobody will notice.",
    "There is leftover curry in the fridge from Tuesday.",
    "First we went to the shop and then we came home.",
    "The endpoint of the walk is a pub with a very poor kitchen.",
    "The distance between us is mostly a matter of trains.",
    "People confuse him with his brother constantly.",
    "We sat in the garden altogether too long and the midges found us.",
    "He had to adjust the strap because the bag kept slipping.",
    "The endpoints of the cable were taped and left under the floor.",
]

POSITIVE_STRATA = ("P_literature", "P_student")
CIRCULAR_STRATA = ("P_canonical_canonical", "P_canonical_synonym")
NEGATIVE_STRATA = ("N_plain", "N_self_report", "N_single_word")

GENERATE_GOAL = r"""
:- use_module(hermes(strategy_recognizer)).
:- use_module(library(http/json)).
emit_renderings :-
    findall(_{operation:Op, kind:Kind, variant:V, text:T},
            ( strategy_recognizer:observed_strategy(Op, Kind, _),
              member(V, [canonical, synonym]),
              strategy_recognizer:generate_strategy_variant(Op, Kind, V, T)
            ), Rows),
    json_write_dict(user_output, _{renderings:Rows}, [width(0)]), nl.
"""

SCORE_GOAL = r"""
:- use_module(hermes(strategy_recognizer)).
:- use_module(library(http/json)).
score_file :-
    current_prolog_flag(argv, [InFile, OutFile]),
    setup_call_cleanup(open(InFile, read, In), json_read_dict(In, Req), close(In)),
    maplist(score_one, Req.items, Results),
    setup_call_cleanup(open(OutFile, write, Out),
                       json_write_dict(Out, _{results:Results}, [width(0)]),
                       close(Out)).
score_one(Item, _{id:Id, candidates:Top}) :-
    get_dict(id, Item, Id), get_dict(text, Item, Text),
    ( catch(strategy_recognizer:recognize_strategies(Text, Cs), _, fail)
    -> true ; Cs = [] ),
    maplist(candidate_row, Cs, Top).
candidate_row(C, Row) :-
    get_dict(operation, C, Op), get_dict(kind, C, Kind),
    get_dict(confidence, C, Conf0), Conf is float(Conf0),
    get_dict(support_level, C, Support),
    Row = _{family:Op, signature:Kind, confidence:Conf, support_level:Support}.
"""


def swipl(goal_text: str, entry: str, argv: list[str] | None = None,
          timeout: int = 900) -> subprocess.CompletedProcess:
    with tempfile.NamedTemporaryFile("w", suffix=".pl", delete=False) as handle:
        handle.write(goal_text)
        script = handle.name
    command = ["swipl", "-q", "-g", f"consult('{PATHS_PL}')",
               "-g", f"consult('{script}')", "-g", entry, "-t", "halt"]
    if argv:
        command += ["--"] + argv
    try:
        return subprocess.run(command, cwd=ROOT, capture_output=True,
                              text=True, timeout=timeout)
    finally:
        Path(script).unlink(missing_ok=True)


def split_of(item_id: str) -> str:
    digest = int(hashlib.md5(item_id.encode()).hexdigest(), 16)
    return "dev" if digest % 2 == 0 else "holdout"


def build_items() -> list[dict]:
    benchmark = json.loads(BENCHMARK.read_text(encoding="utf-8"))
    items: list[dict] = []

    def add(item_id, text, stratum, family=None, signature=None):
        items.append({"id": item_id, "text": text, "stratum": stratum,
                      "gold_family": family, "gold_signature": signature,
                      "split": split_of(item_id)})

    for arm, stratum in (("literature", "P_literature"), ("student", "P_student")):
        for row in benchmark["arms"][arm]["items"]:
            add(row["id"], row["text"], stratum,
                row["gold"]["family"], row["gold"]["signature"])

    generated = swipl(GENERATE_GOAL, "emit_renderings")
    if generated.returncode != 0:
        raise RuntimeError(f"could not generate renderings:\n{generated.stderr}")
    payload = json.loads(generated.stdout.strip().splitlines()[-1])
    for index, row in enumerate(payload["renderings"], 1):
        add(f"canon-{index:04d}", row["text"],
            f"P_canonical_{row['variant']}", row["operation"], row["kind"])

    for prefix, stratum, texts in (("nplain", "N_plain", N_PLAIN),
                                   ("nself", "N_self_report", N_SELF_REPORT),
                                   ("nsingle", "N_single_word", N_SINGLE_WORD)):
        for index, text in enumerate(texts, 1):
            add(f"{prefix}-{index:04d}", text, stratum)
    return items


def score(items: list[dict], workdir: Path) -> dict[str, dict]:
    in_path, out_path = workdir / "items.json", workdir / "results.json"
    in_path.write_text(json.dumps({"items": items}), encoding="utf-8")
    run = swipl(SCORE_GOAL, "score_file", [str(in_path), str(out_path)])
    if run.returncode != 0:
        raise RuntimeError(f"scoring failed:\n{run.stderr}")
    return {row["id"]: row for row in
            json.loads(out_path.read_text(encoding="utf-8"))["results"]}


def positive_row(rows: list[tuple[dict, dict]]) -> dict:
    total = len(rows)
    top1 = sum(1 for item, result in rows if result["candidates"]
               and result["candidates"][0]["signature"] == item["gold_signature"])
    family = sum(1 for item, result in rows if result["candidates"]
                 and result["candidates"][0]["family"] == item["gold_family"])
    answered = [(item, result) for item, result in rows if result["candidates"]]
    abstained = total - len(answered)
    by_signature = collections.defaultdict(list)
    for item, result in rows:
        by_signature[item["gold_signature"]].append(
            bool(result["candidates"])
            and result["candidates"][0]["signature"] == item["gold_signature"])
    macro = statistics.mean(sum(v) / len(v) for v in by_signature.values())
    constant = collections.Counter(
        item["gold_signature"] for item, _ in rows).most_common(1)[0][1] / total
    return {
        "n": total,
        "top1": round(top1 / total, 4),
        "best_constant_answer": round(constant, 4),
        "lift_over_constant": round(top1 / total - constant, 4),
        "family_top1": round(family / total, 4),
        "macro_top1": round(macro, 4),
        "macro_constant": round(1 / len(by_signature), 4),
        "precision_when_answering": (
            round(top1 / len(answered), 4) if answered else None),
        "abstain": round(abstained / total, 4),
        "mean_candidates": round(
            statistics.mean(len(r["candidates"]) for _, r in rows), 2),
    }


def negative_row(rows: list[tuple[dict, dict]]) -> dict:
    total = len(rows)
    abstained = sum(1 for _, result in rows if not result["candidates"])
    strong = sum(1 for _, result in rows
                 if any(c["support_level"] in ("partial_trace", "clean_run")
                        for c in result["candidates"]))
    return {
        "n": total,
        "abstain": round(abstained / total, 4),
        "partial_trace_or_better": round(strong / total, 4),
        "mean_candidates": round(
            statistics.mean(len(r["candidates"]) for _, r in rows), 2),
    }


def report(items: list[dict], results: dict[str, dict]) -> dict:
    out: dict[str, dict] = {}
    for split in ("dev", "holdout", "all"):
        section: dict[str, dict] = {}

        def rows(strata, multi_word_only=False):
            return [(i, results[i["id"]]) for i in items
                    if i["stratum"] in strata
                    and (split == "all" or i["split"] == split)
                    and (not multi_word_only or len(i["text"].split()) >= 2)]

        for name, strata, multi in (
                ("positives", POSITIVE_STRATA, False),
                ("positives_multi_word_only", POSITIVE_STRATA, True),
                ("literature", ("P_literature",), False),
                ("student_prose", ("P_student",), False),
                ("canonical_rendering", ("P_canonical_canonical",), False),
                ("synonym_rendering", ("P_canonical_synonym",), False)):
            selected = rows(strata, multi)
            if selected:
                section[name] = positive_row(selected)
        for stratum in NEGATIVE_STRATA:
            selected = rows((stratum,))
            if selected:
                section[stratum] = negative_row(selected)
        selected = rows(NEGATIVE_STRATA)
        if selected:
            section["negatives_all"] = negative_row(selected)
        positives = section.get("positives_multi_word_only")
        negatives = section.get("negatives_all")
        if positives and negatives:
            # The best constant answerer over both halves is "always abstain":
            # zero on positives, one on negatives, so 0.5 balanced.
            section["balanced_accuracy_multi_word"] = {
                "value": round((positives["top1"] + negatives["abstain"]) / 2, 4),
                "best_constant": 0.5,
            }
        out[split] = section
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=None,
                        help="write the full report as JSON")
    parser.add_argument("--results", type=Path, default=None,
                        help="write the per-item candidates as JSON")
    arguments = parser.parse_args()

    items = build_items()
    with tempfile.TemporaryDirectory() as workdir:
        results = score(items, Path(workdir))
        if arguments.results:
            arguments.results.write_text(
                json.dumps({"results": list(results.values())}), encoding="utf-8")
    summary = report(items, results)

    counts = collections.Counter(item["stratum"] for item in items)
    print(f"items: {len(items)}")
    for stratum in sorted(counts):
        print(f"  {stratum:26s} {counts[stratum]}")
    for split in ("dev", "holdout", "all"):
        print(f"\n--- split={split}")
        for name, row in summary[split].items():
            print(f"  {name:28s} " + "  ".join(
                f"{key}={value}" for key, value in row.items()))
    if arguments.output:
        arguments.output.write_text(json.dumps(summary, indent=2),
                                    encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main())
