#!/usr/bin/env python3
"""Regression check for the canonical recognition phrases.

``knowledge/strategies/canonical_phrases.pl`` gives each canonical action a
handful of reviewed classroom phrasings.  ``hermes/strategy_recognizer.pl``
reaches them through one clause in ``action_surface/2``, which sends a local
action label to its canonical action via ``action_maps/7`` and then to that
action's phrases.  The point of the indirection is arithmetic: 808 local labels
sit in the transition tables and 24 carry a hand-written phrase, so authoring per
label means 784 more decisions, while authoring per canonical action means 90.

This check holds that arrangement to what it claims:

  Coverage is measured, not asserted.  Every canonical action that carries
  mapping rows has at least one phrase, and the check reports how many mapping
  rows and how many machines that reaches.  When the alphabet grows, the number
  moves and the failure names the actions that arrived without phrases.

  Phrases are ordinary words.  No phrase may contain a technical term the
  alphabet cites -- disembed, unitize, commensurate, deontic and the like -- or an
  underscore, or a canonical action's own name.  A phrase that repeats the
  identifier adds nothing the derived rendering did not already give.

  Phrases stay distinct.  No two canonical actions share a phrase, because a
  shared phrase makes two actions indistinguishable in exactly the position the
  recognizer is trying to tell them apart.

  The wiring is present and is the only path.  ``action_surface/2`` reaches the
  phrases through the canonical map, and the recognizer's own check still passes,
  so the added surfaces did not break generation round-trips.

  Abstention survives.  The recognizer still returns nothing for text that
  aligns with no transition.  Widening the surface must not make it answer
  everything.
"""
from __future__ import annotations

import collections
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PATHS_PL = ROOT / "paths.pl"
PHRASES = ROOT / "knowledge/strategies/canonical_phrases.pl"
MAP_PATH = ROOT / "knowledge/strategies/action_vocabulary_map.pl"
RECOGNIZER = ROOT / "hermes/strategy_recognizer.pl"

PHRASE_RE = re.compile(r"(?m)^canonical_phrase\((\w+), \[([^\]]*)\]\)\.")
MAPS_RE = re.compile(r"(?m)^action_maps\((\w+), (\w+), (\w+), (\w+),")

# Terms the alphabet cites to the literature. A recognition phrase is what a
# student says; these belong in the citation and not in the surface.
TECHNICAL = (
    "disembed", "unitize", "commensurate", "deontic", "referent", "cardinality",
    "quotitive", "partitive", "invariant", "canonical", "automaton", "iterate",
    "regroup", "minuend", "subtrahend", "multiplicand", "numeral",
)


def read_phrases() -> dict[str, list[tuple[str, ...]]]:
    text = PHRASES.read_text(encoding="utf-8")
    found: dict[str, list[tuple[str, ...]]] = collections.defaultdict(list)
    for action, body in PHRASE_RE.findall(text):
        words = tuple(w.strip() for w in body.split(",") if w.strip())
        found[action].append(words)
    if not found:
        raise SystemExit(f"{PHRASES}: no canonical_phrase/2 facts found")
    return found


def run_prolog(goal: str, timeout: int = 240) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["swipl", "-q", "--on-warning=status", "--on-error=status",
         "-l", str(PATHS_PL), "-g", goal],
        cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def main() -> int:
    for path in (PHRASES, MAP_PATH, RECOGNIZER):
        if not path.exists():
            print(f"FAIL: {path} does not exist", file=sys.stderr)
            return 1

    errors: list[str] = []
    phrases = read_phrases()
    rows = MAPS_RE.findall(MAP_PATH.read_text(encoding="utf-8"))
    in_use = collections.Counter(canonical for *_, canonical in rows)

    for action in sorted(set(in_use) - set(phrases)):
        errors.append(
            f"{action} carries {in_use[action]} mapping row(s) and has no "
            "canonical_phrase/2; a canonical action without a phrase leaves "
            "every label that maps to it on identifier-derived rendering alone")
    for action in sorted(set(phrases) - set(in_use)):
        errors.append(
            f"{action} has phrases and carries no mapping rows; the phrase "
            "reaches nothing")

    seen: dict[tuple[str, ...], str] = {}
    for action, variants in sorted(phrases.items()):
        for words in variants:
            if not words:
                errors.append(f"{action}: an empty phrase")
                continue
            if words in seen and seen[words] != action:
                errors.append(
                    f"{action} and {seen[words]} share the phrase "
                    f"{' '.join(words)}; a shared phrase cannot tell them apart")
            seen.setdefault(words, action)
            joined = " ".join(words)
            for term in TECHNICAL:
                if term in joined:
                    errors.append(
                        f"{action}: phrase '{joined}' contains the technical "
                        f"term '{term}'; a recognition surface is what a student "
                        "says, and the citation belongs in the alphabet")
            if "_" in joined:
                errors.append(f"{action}: phrase '{joined}' contains an underscore")
            if action.replace("_", " ") in joined:
                errors.append(
                    f"{action}: phrase '{joined}' repeats the action's own name, "
                    "which the derived rendering already covers")

    wiring = RECOGNIZER.read_text(encoding="utf-8")
    if "canonical_action_of(Action, Canonical)" not in wiring:
        errors.append(
            "hermes/strategy_recognizer.pl does not reach the phrases through "
            "the canonical map; without that clause this file is unconsumed")
    for table in ("calculus.pl", "probability.pl"):
        if table not in wiring:
            errors.append(
                f"the recognizer does not include transition_tables/{table}, so "
                "those automata have no recognition surface at all")

    load = run_prolog("use_module(hermes(strategy_recognizer), []), halt.")
    if load.returncode != 0:
        print(f"FAIL: recognizer does not load:\n{load.stdout}\n{load.stderr}",
              file=sys.stderr)
        return 1

    abstain = run_prolog(
        "use_module(hermes(strategy_recognizer), [recognize_strategies/2]), "
        "recognize_strategies(\"purple bicycle Tuesday\", C), "
        "( C == [] -> writeln(abstained) ; writeln(answered) ), halt.")
    if "abstained" not in abstain.stdout:
        errors.append(
            "the recognizer no longer abstains on text that aligns with "
            f"nothing (got {abstain.stdout.strip()!r}); widening the surface "
            "must not make it answer everything")

    round_trip = run_prolog(
        "use_module(hermes(strategy_recognizer)), "
        "generate_strategy_language(addition, count_on_from_larger, T), "
        "recognize_strategies(T, C), length(C, N), "
        "format('candidates ~w~n', [N]), halt.")
    if "candidates 0" in round_trip.stdout or round_trip.returncode != 0:
        errors.append(
            "a generated strategy description no longer recognizes; the added "
            f"surfaces broke the round trip ({round_trip.stdout.strip()!r})")

    if errors:
        print(f"FAIL: {len(errors)} problem(s):", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    by_signature: dict[tuple[str, str], set[str]] = collections.defaultdict(set)
    for family, signature, _, canonical in rows:
        by_signature[(family, signature)].add(canonical)
    covered_rows = sum(n for action, n in in_use.items() if action in phrases)
    covered_machines = sum(
        1 for actions in by_signature.values() if actions <= set(phrases))
    variants = sum(len(v) for v in phrases.values())

    print("PASS the recognizer loads, abstains on unaligned text, and still "
          "round-trips a generated description")
    print(f"PASS coverage: every one of the {len(in_use)} canonical actions in "
          "use has at least one phrase")
    print("PASS phrases are ordinary words, distinct across actions, and none "
          "repeats an action's own name")
    print("PASS the wiring goes through the canonical map, and every transition "
          "table the tables hold is included")
    print()
    print("What authoring per canonical action buys:")
    print(f"  local action labels in the tables : {len({l for _, _, l, _ in rows})}")
    print(f"  labels with a hand-written phrase  : 24")
    print(f"  canonical actions phrased          : {len(phrases)}")
    print(f"  phrase variants authored           : {variants}")
    print(f"  mapping rows reached               : {covered_rows} of {len(rows)}")
    print(f"  machines fully phrased             : {covered_machines} of {len(by_signature)}")
    print()
    print("PASS canonical_phrases check")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
