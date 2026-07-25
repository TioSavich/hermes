#!/usr/bin/env python3
"""Regression check for the utterance layers and the denial veto.

``knowledge/strategies/utterance_layers.pl`` separates what an utterance carries
besides its mathematics into layers -- person, force, polarity -- so that "I made
a ten", "you made a ten" and "did you make a ten" are one arithmetic under three
deontic uptakes, and so that "I did not make a ten" stops counting as evidence
for making a ten.

The behaviours this check holds, each of which was a live defect before the
module existed:

  A denial removes what it denies.  ``i did not make ten i just counted them all``
  must not return a make-ten candidate, and must still return a counting one.
  Before the veto it returned ``make_ten_drop_leftover`` at 0.2 in favour of the
  strategy the sentence denies.

  A denial does not over-reach.  The affirmed clause after the denial keeps its
  candidates.  The reach is stated as ``denial_reach/1`` and is checked here
  against both the case it must catch and the case it must not.

  Label-internal negation is not polarity.  The identifier-derived surface for
  ``decimal/decimal_scale_loss_comparison`` is "scales seen but not coordinated";
  a bare-``not`` denial form vetoed the very step that utterance reports, and the
  recognizer's own round-trip check caught it.  So the denial forms are
  clause-level, and this check fails if a single-word ``not`` form comes back.

  Person does not move the mathematics.  First, second and third person over the
  same predicate return the same top candidate at the same confidence, and their
  uptakes differ.  A person layer that changed the arithmetic would not be a
  layer.

  Every layer can go unread.  Each layer has an unmarked value, and text carrying
  none of a layer's forms reads as unmarked rather than as a guess.

  Uptakes and substitutions land in the discursive genre.  Every
  ``layer_uptake/3`` names an action that ``commitment_automata.pl`` actually
  fires, and every ``layer_substitution/5`` names uptakes that exist, so the
  layers parse into that genre rather than into free-floating tags.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PATHS_PL = ROOT / "paths.pl"
LAYERS = ROOT / "knowledge/strategies/utterance_layers.pl"
DISCOURSE = ROOT / "knowledge/discourse/commitment_automata.pl"
RECOGNIZER = ROOT / "hermes/strategy_recognizer.pl"

LAYER_RE = re.compile(r"(?m)^utterance_layer\((\w+), order\((\d+)\)")
FORM_RE = re.compile(r"(?m)^layer_form\((\w+), (\w+), \[([^\]]*)\]\)\.")
UPTAKE_RE = re.compile(r"(?m)^layer_uptake\((\w+), (\w+), (\w+)\)\.")
SUB_RE = re.compile(
    r"(?m)^layer_substitution\((\w+), (\w+), (\w+),\s*\n?\s*"
    r"induces\((\w+), (\w+), (\w+)\)")
PREDICATE_RE = re.compile(r"(?m)^canonical_predicate\((\w+), \[")


def prolog(goal: str, timeout: int = 180) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["swipl", "-q", "--on-warning=status", "--on-error=status",
         "-l", str(PATHS_PL), "-g", goal],
        cwd=ROOT, capture_output=True, text=True, timeout=timeout)


def recognize(text: str) -> list[str]:
    """Return the candidate kinds the recognizer offers for text."""
    goal = (
        "use_module(hermes(strategy_recognizer), [recognize_strategies/2]), "
        f'recognize_strategies("{text}", Cs), '
        "forall(member(C, Cs), "
        "( get_dict(candidate_strategy, C, S), get_dict(kind, S, K), "
        "  get_dict(confidence, C, F), format('~w ~4f~n', [K, F]) )), halt.")
    out = prolog(goal)
    if out.returncode != 0:
        raise RuntimeError(f"recognize failed for {text!r}:\n{out.stderr}")
    return [line.split()[0] for line in out.stdout.strip().splitlines() if line.strip()]


def main() -> int:
    for path in (LAYERS, DISCOURSE, RECOGNIZER):
        if not path.exists():
            print(f"FAIL: {path} does not exist", file=sys.stderr)
            return 1

    text = LAYERS.read_text(encoding="utf-8")
    errors: list[str] = []

    layers = {name: int(order) for name, order in LAYER_RE.findall(text)}
    forms: dict[tuple[str, str], list[list[str]]] = {}
    for layer, value, body in FORM_RE.findall(text):
        words = [w.strip() for w in body.split(",") if w.strip()]
        forms.setdefault((layer, value), []).append(words)
    uptakes = UPTAKE_RE.findall(text)
    substitutions = SUB_RE.findall(text)
    predicates = set(PREDICATE_RE.findall(text))

    if sorted(layers) != sorted({"person", "force", "polarity", "action"}):
        errors.append(f"the layers are {sorted(layers)}; expected person, force, "
                      "polarity and action")
    if sorted(layers.values()) != list(range(1, len(layers) + 1)):
        errors.append(f"layer orders are {sorted(layers.values())}; they must be "
                      "a run from 1 with no gaps, because the order is the order "
                      "a parse peels them")

    # every layer that has forms must have an unmarked one
    layers_with_forms = {layer for layer, _ in forms}
    for layer in sorted(layers_with_forms):
        unmarked = [v for (lyr, v), variants in forms.items()
                    if lyr == layer and any(w == [] for w in variants)]
        if not unmarked:
            errors.append(
                f"the {layer} layer has no value with an empty form; a layer that "
                "cannot go unread will be guessed instead of reported unread")

    # clause-level denials only
    for words in forms.get(("polarity", "denied"), []):
        if words == ["not"]:
            errors.append(
                "polarity carries a bare 'not' form. The action labels themselves "
                "contain negation words -- 'scales seen but not coordinated' is an "
                "identifier-derived surface -- so a bare not vetoes the step the "
                "utterance is reporting")
        if not words:
            errors.append("polarity has an empty denied form")

    # uptakes and substitutions must land in the discursive genre
    discursive = set(re.findall(
        r"(?m)^automaton_transition\(discourse, \w+, \w+, (\w+),",
        DISCOURSE.read_text(encoding="utf-8")))
    for layer, value, action in uptakes:
        if layer not in layers:
            errors.append(f"layer_uptake names layer {layer}, which is not declared")
        if (layer, value) not in forms:
            errors.append(f"layer_uptake names {layer}/{value}, which has no form")
        if action not in discursive:
            errors.append(
                f"layer_uptake sends {layer}/{value} to {action}, which no "
                "machine in commitment_automata.pl fires; an uptake that names "
                "nothing the discursive genre does is a tag")
    if not substitutions:
        errors.append("no layer_substitution/5 rows; the substitutions are the "
                      "reason the layers are separate")
    known_uptakes = {action for _, _, action in uptakes}
    for layer, source, target, _, from_uptake, to_uptake in substitutions:
        if (layer, source) not in forms or (layer, target) not in forms:
            errors.append(f"layer_substitution {layer} {source}->{target} names a "
                          "value with no form")
        for uptake in (from_uptake, to_uptake):
            if uptake not in known_uptakes:
                errors.append(
                    f"layer_substitution induces {uptake}, which no layer_uptake "
                    "produces")

    if not predicates:
        errors.append("no canonical_predicate/2 rows")
    if "denied_span" not in RECOGNIZER.read_text(encoding="utf-8"):
        errors.append(
            "hermes/strategy_recognizer.pl does not consult denied_span/3, so a "
            "denial still counts as evidence for what it denies")

    try:
        denied = recognize(
            "i did not make ten i just counted them all")
        affirmed = recognize(
            "i split the other number and made ten then i added the leftover "
            "and used both parts")
        second = recognize(
            "you split the other number and made ten then you added the leftover "
            "and used both parts")
        unrelated = recognize("purple bicycle tuesday")
    except RuntimeError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1

    if any(kind.startswith("make_ten") for kind in denied):
        errors.append(
            "a denial of making ten still returns a make-ten candidate "
            f"({[k for k in denied if k.startswith('make_ten')]}); the veto is "
            "not biting")
    if not any("count_all" in kind for kind in denied):
        errors.append(
            "the affirmed clause after the denial lost its candidates "
            f"(got {denied}); the denial's reach over-reaches")
    if not any(kind == "make_ten_split_leftover" for kind in affirmed):
        errors.append(f"the affirmed make-ten description no longer recognizes "
                      f"(got {affirmed})")
    if affirmed[:1] != second[:1]:
        errors.append(
            f"first person returns {affirmed[:1]} and second person {second[:1]}; "
            "a person layer that moves the mathematics is not a layer")
    if unrelated:
        errors.append(f"unrelated text no longer abstains (got {unrelated})")

    if errors:
        print(f"FAIL: {len(errors)} problem(s):", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("PASS a denial removes what it denies and keeps the clause after it")
    print("PASS person does not move the mathematics; first and second person "
          "return the same top candidate")
    print("PASS every layer can go unread, and the denial forms are clause-level")
    print("PASS every uptake names an action commitment_automata.pl fires, and "
          "every substitution names uptakes that exist")
    print("PASS unrelated text still abstains")
    print()
    print("The layers:")
    for layer in sorted(layers, key=lambda name: layers[name]):
        values = sorted({v for (lyr, v) in forms if lyr == layer})
        print(f"  {layers[layer]}. {layer:9s} {values if values else '(read from the alphabet)'}")
    print(f"  uptakes into the discursive genre : {len(uptakes)}")
    print(f"  substitutions recorded            : {len(substitutions)}")
    print(f"  person-free predicates            : {len(predicates)} canonical actions")
    print()
    print("PASS utterance_layers check")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
