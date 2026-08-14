#!/usr/bin/env python3
"""Render and audit pass-1 IM-guide lexicon dispositions.

The sets below are authored lexical judgments.  The runtime saturation census
supplies occurrence counts and contexts; this module supplies class and
morphology.  Rendering is deterministic and never edits the supplement.
"""

from __future__ import annotations

import argparse
import json
import re

from build_math_lexicon import REPO


CENSUS = REPO / "hermes/app/runtime/experiments/language/im_guide_saturation.json"
SUPPLEMENT = REPO / "knowledge/strategies/abstraction/lexicon_supplement_pilot.pl"
LEDGER = REPO / ".superpowers/sdd/language-lane/saturation_ledger.json"
PASS = "guide_saturation_1"

STOP_FUNCTION_WORDS = set("could its others our should the they to".split())
FUNCTION_WORDS = STOP_FUNCTION_WORDS | {"yourselves"}
CONTRACTION_FRAGMENTS = set(
    "s t doesn isn didn re ve ll wasn couldn wouldn weren hasn hadn shouldn".split()
)
CURRICULUM_CODES = set(
    """cc nc oa nbt k md nf sp im plc mlr mlr1 mlr2 mlr3 mlr4 mlr5 mlr6 mlr7 mlr8
    mp1 mp2 mp3 mp4 mp5 mp6 mp7 mp8 g1 g2 g3 g4 g5 gk grade1 grade2 grade3 grade4
    grade5 u u1 u2 u3 u4 u5 u6 u7 u8 u9 q1 q2 q3 l1 l2 l3 l4 l5 l6 l7 l8 l9 l10
    l11 l12 l13 l14 l15 l16 l17 l18 l19 l20 l21 l22 l23 l24 l25 l26 rp ns aa ee
    e343 wn90 wn11 nm44 al16 ab25 bq64 sk51 cl48 vt35 bb dd ff gg hh ii jj""".split()
)
ALGEBRA_SYMBOLS = set("v z xs sh".split())
ABBREVIATIONS = set("info pdf pdfs json feb apr aug nov dec oct sep dc nba ok vs cd".split())
INTERJECTIONS = {"glub", "okay", "yum"}
NAME_PARTICLES = {"de"}
UNIT_ABBREVIATIONS = {"mm": "millimeter", "mg": "milligram", "hr": "hour"}
WEB_TOKENS = set(
    "https www org pdftotext poppler creativecommons openupresources "
    "illustrativemathematics wikimedia vimeo flickr pixabay".split()
)
TOKENIZER_ARTIFACTS = set(
    "quadrilat eral ters coun interpet bindergarten english106 ths resp th st rd nd co pre".split()
)
TRANSLITERATIONS = set(
    "fuertes lah loh pih soh sohz tah taow tuhs vohz fuhl mayng mahn kruh goh hohs kah soo "
    "es kels nic nie".split()
)

GIVEN_NAMES = set(
    """allyson felix jeison meegan pierre linda sanya adriana alicia andres anthony bao carey
    carrie chandra enrique jackie jarrion judy lorraine margarita miguel monique oge rukhsana
    shaunae tio tonique valerie verónica louis craig rufus""".split()
)
FAMILY_NAMES = set(
    """agassiz beliveau brantley brisco chango cheesborough cooke gustafson hirst joyner kersee
    lawson newton peña phillips powell richards ridley rodriguez sayre schneider silverman tanco
    beamon fenton ferris eiffel
    trujillo uibo willems williams""".split()
)
PLACE_NAMES = set(
    """africa alaska alabama angeles apache arizona australia bahamas bermuda brooklyn california
    carolina cherokee chicago chihuahua choctaw colombia egypt fenway florida ghana gila giza
    harrisburg indiana indianapolis ireland jacksonville keres lincoln madison malaysia mexico
    miami michigan milwaukee minnesota nashville navajo new zealand ojibwa oklahoma pennsylvania
    komodo fe
    philadelphia portugal rhode santa staten thailand washington wisconsin wyoming yupik zuni""".split()
)
NAMED_ENTITIES = set(
    "bingo lotería mancala mondrian olympics pilolo palooza sunnyside usa penta".split()
)

ADVERBS = set(
    """abstractly additively conceptually contextually conversely formatively incrementally
    interchangeably kinesthetically logistically mathematically meaningfully partially precisely
    quantitatively separately severely simultaneously strategically successfully succinctly
    unusually visibly visually flexibly farthest versa""".split()
)
ADJECTIVES = set(
    """analog boxy centered colorful contextual creative critical curious cumbersome darker
    environmental facedown fahrenheit feasible fizzy foldable foundational freehand friendliest
    firsthand countless layered meta organizational reliable unsubstantiated indo
    crawly creepy smiley
    formatted gridded imprecise interactive interquartile kinesthetic largemouth leftmost lemony
    meaningful messy multimodal mustardy nondefining nonfiction obtuse overlapping pointy premade
    procedural recyclable rectilinear relevant repetitive respective responsible rightmost
    skinnier steepest unconnected unchanged unfamiliar unlabeled unmarked unmatched unshaded
    unsharpened unstuck uppercase""".split()
)
MATH_TERMS = set(
    """accuracy benchmark benchmarks cardinality commutativity correspondence correspondences
    endpoints endpoint expectation expectations interquartile iqrs midpoint nonexample nonexamples
    percentile percentiles remainders regularity relation regroupings subset unknowns zeroes""".split()
)
PEDAGOGY_TERMS = set(
    """access awareness blackline contextualize cultivate decontextualize internalize
    manipulatives mathematize monitoring processing recap recontextualize reference reflect
    rephrase sequencing subitize subitizing timeline visualization""".split()
)

VERB_BASE = {
    "access": "access",
    "brainstorm": "brainstorm",
    "coded": "code",
    "collaborate": "collaborate",
    "concentrate": "concentrate",
    "conceptualize": "conceptualize",
    "contextualize": "contextualize",
    "contextualized": "contextualize",
    "cultivate": "cultivate",
    "decontextualize": "decontextualize",
    "decontextualized": "decontextualize",
    "downplayed": "downplay",
    "internalize": "internalize",
    "intuit": "intuit",
    "leveraging": "leverage",
    "mathematize": "mathematize",
    "optimize": "optimize",
    "opt": "opt",
    "packaged": "package",
    "previews": "preview",
    "preview": "preview",
    "previewing": "preview",
    "proceed": "proceed",
    "progressed": "progress",
    "quantify": "quantify",
    "quantifying": "quantify",
    "reacquainted": "reacquaint",
    "reallocate": "reallocate",
    "reallocated": "reallocate",
    "reconstruct": "reconstruct",
    "recontextualize": "recontextualize",
    "reconvene": "reconvene",
    "recounting": "recount",
    "redesign": "redesign",
    "redesigned": "redesign",
    "redistribute": "redistribute",
    "redistributed": "redistribute",
    "redistributing": "redistribute",
    "referred": "refer",
    "referring": "refer",
    "referencing": "reference",
    "reflect": "reflect",
    "reflects": "reflect",
    "refreshed": "refresh",
    "reinforcing": "reinforce",
    "reintroduced": "reintroduce",
    "reiterate": "reiterate",
    "released": "release",
    "rephrase": "rephrase",
    "replicate": "replicate",
    "resemble": "resemble",
    "resembles": "resemble",
    "restock": "restock",
    "reused": "reuse",
    "sequenced": "sequence",
    "showcase": "showcase",
    "subitize": "subitize",
    "worn": "wear",
    "wore": "wear",
}

PLURAL_BASE = {
    "antennae": "antenna", "attendees": "attendee", "azulejos": "azulejo", "backpacks": "backpack", "benchmarks": "benchmark", "breadsticks": "breadstick",
    "burgers": "burger", "clipboards": "clipboard", "collages": "collage",
    "centavos": "centavo", "corrections": "correction", "countries": "country", "cranes": "crane", "criteria": "criterion",
    "creations": "creation", "creatures": "creature", "cubbies": "cubby",
    "cutouts": "cutout", "dominoes": "domino", "dragonflies": "dragonfly",
    "dreidels": "dreidel", "endpoints": "endpoint", "expectations": "expectation",
    "formats": "format", "gameboards": "gameboard", "grandparents": "grandparent",
    "grapefruits": "grapefruit", "handouts": "handout", "highlighters": "highlighter",
    "huskies": "husky", "iqrs": "iqr", "jamuns": "jamun", "makers": "maker",
    "manipulatives": "manipulative", "noisemakers": "noisemaker", "nonexamples": "nonexample",
    "paletas": "paleta", "partygoers": "partygoer", "percentiles": "percentile",
    "plastics": "plastic", "quizzes": "quiz", "ratings": "rating",
    "recyclables": "recyclable", "references": "reference", "regroupings": "regrouping",
    "remainders": "remainder", "reminders": "reminder", "resources": "resource",
    "roles": "role", "satsumas": "satsuma", "subcategories": "subcategory", "stingrays": "stingray",
    "teenagers": "teenager", "terrariums": "terrarium", "trompos": "trompo", "veggies": "veggie",
    "visuals": "visual", "whiteboards": "whiteboard", "zookeepers": "zookeeper",
    "zeroes": "zero",
}
INVARIANT_NOUNS = set(
    """cardstock coding cornbread countdown criteria curriculum debris dosage exposure fundraising
    halftime lifetime motivation oregano packaging rainwater regulation repetition resolution sheep
    wildlife workload""".split()
)


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def regular_verb(base: str) -> tuple[str, str, str, str, str]:
    if base == "wear":
        return "wear", "wears", "wore", "wearing", "worn"
    if base.endswith("e") and not base.endswith("ee"):
        past = base + "d"
        ing = base[:-1] + "ing"
    elif re.search(r"[^aeiou][aeiou][^aeiouwxy]$", base):
        past = base + base[-1] + "ed"
        ing = base + base[-1] + "ing"
    else:
        past = base + "ed"
        ing = base + "ing"
    third = base[:-1] + "ies" if base.endswith("y") and base[-2] not in "aeiou" else base + "s"
    return base, third, past, ing, past


def noun_forms(word: str) -> tuple[str, str]:
    if word in PLURAL_BASE:
        return PLURAL_BASE[word], word
    if word in INVARIANT_NOUNS:
        return word, word
    if word.endswith("y") and len(word) > 1 and word[-2] not in "aeiou":
        return word, word[:-1] + "ies"
    if word.endswith(("s", "x", "z", "ch", "sh")):
        return word, word + "es"
    return word, word + "s"


def judgment(word: str) -> tuple[str, str, str]:
    if word in FUNCTION_WORDS:
        source = (
            "The absorbed questioning-paper STOP list supplies this closed function-word judgment."
            if word in STOP_FUNCTION_WORDS
            else "The guides use this invariant grammatical function word."
        )
        return "function_word", "forms(invariant)", source
    if word in CONTRACTION_FRAGMENTS:
        return "contraction_fragment", "none", "The tokenizer detached this contraction fragment; it remains refused as a word."
    if word in TOKENIZER_ARTIFACTS:
        return "tokenizer_artifact", "none", "uncertain: the guide text contains a truncated, fused, or malformed token, so it remains refused as a word."
    if word in CURRICULUM_CODES:
        return "curriculum_code", "forms(invariant)", "The guides use this invariant token in a curriculum, standard, lesson, or source identifier."
    if word in ALGEBRA_SYMBOLS:
        return "algebra_symbol", "forms(invariant)", "The guides use this invariant token as a variable or labeled quantity."
    if word in UNIT_ABBREVIATIONS:
        return "unit_abbreviation", f"expands_to({UNIT_ABBREVIATIONS[word]})", "The guides use this unit abbreviation with the stated expansion."
    if word in ABBREVIATIONS:
        return "abbreviation", "forms(invariant)", "The guides use this invariant abbreviation or file label."
    if word in INTERJECTIONS:
        return "interjection", "forms(invariant)", "The guides use this invariant conversational interjection."
    if word in NAME_PARTICLES:
        return "name_particle", "forms(invariant)", "The guides use this invariant particle inside a person's name."
    if word in WEB_TOKENS:
        return "web_token", "forms(invariant)", "The guide source metadata uses this web, file-conversion, or publishing token."
    if word in TRANSLITERATIONS:
        return "pronunciation_token", "forms(invariant)", "The guides use this invariant pronunciation or transliteration component."
    if word in GIVEN_NAMES:
        return "given_name", "none", "The guides use this capitalized token as an individual person's given name."
    if word in FAMILY_NAMES:
        return "family_name", "none", "The guides use this capitalized token as a person's family name."
    if word in PLACE_NAMES:
        return "place_name", "none", "The guides use this capitalized token as a place or people-name component."
    if word in NAMED_ENTITIES:
        return "named_entity", "none", "The guides use this token as a named game, organization, event, or team."
    if word in ADVERBS:
        return "adverb", "forms(invariant)", "The guides use this word adverbially."
    if word in ADJECTIVES:
        return "adjective", "forms(invariant)", "The guides use this word adjectivally."
    if word in MATH_TERMS:
        singular, plural = noun_forms(word)
        return "math_term", f"forms(noun({singular}, {plural}))", "The guides use this word as a mathematics or classroom-analysis noun."
    if word in PEDAGOGY_TERMS:
        if word in VERB_BASE:
            forms = ", ".join(regular_verb(VERB_BASE[word]))
            return "corpus_verb", f"forms(verb({forms}))", "The guides use this instructional verb; the row records its five-form paradigm."
        singular, plural = noun_forms(word)
        return "pedagogy_term", f"forms(noun({singular}, {plural}))", "The guides use this noun for an instructional routine, resource, or analysis practice."
    if word in VERB_BASE:
        forms = ", ".join(regular_verb(VERB_BASE[word]))
        return "corpus_verb", f"forms(verb({forms}))", "The guides use this verb form; the row records its five-form paradigm."
    singular, plural = noun_forms(word)
    return "common_noun", f"forms(noun({singular}, {plural}))", "The guides use this word as a noun absent from the combined stores."


def repeated_rows() -> list[dict[str, object]]:
    data = json.loads(CENSUS.read_text(encoding="utf-8"))
    return [row for row in data["unknown_census"]["ranked"] if row["occurrences"] >= 2]


def slice2_words() -> set[str]:
    text = SUPPLEMENT.read_text(encoding="utf-8")
    return {
        word.replace("''", "'")
        for word in re.findall(
            r"^ls_word\('((?:''|[^'])+)'[^\n]+evidence\(occurrences\(\d+\)\),",
            text,
            flags=re.MULTILINE,
        )
    }


def new_rows() -> list[dict[str, object]]:
    prior = slice2_words()
    return [row for row in repeated_rows() if str(row["word"]) not in prior]


def render() -> str:
    lines = []
    for row in sorted(new_rows(), key=lambda item: str(item["word"])):
        word = str(row["word"])
        word_class, morphology, rationale = judgment(word)
        lines.append(
            f"ls_word({prolog_atom(word)}, {word_class}, {morphology}, "
            f"evidence(occurrences({row['occurrences']}), pass({PASS})), "
            f"{json.dumps(rationale, ensure_ascii=False)})."
        )
    return "\n".join(lines) + "\n"


def check() -> None:
    if LEDGER.exists():
        ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
        pass_record = next(
            row for row in ledger["passes"] if row["evidence_pass"] == PASS
        )
        expected = {
            str(row["word"]) for row in pass_record["words"]
        }
    else:
        expected = {str(row["word"]) for row in new_rows()}
    text = SUPPLEMENT.read_text(encoding="utf-8")
    found = set(
        re.findall(
            rf"^ls_word\('((?:''|[^'])+)'[^\n]+pass\({PASS}\)", text, flags=re.MULTILINE
        )
    )
    found = {word.replace("''", "'") for word in found}
    if found != expected:
        raise SystemExit(
            f"guide disposition mismatch: missing={sorted(expected-found)}, extra={sorted(found-expected)}"
        )
    supplement_words = slice2_words() | found
    repeated_unresolved = {
        str(row["word"])
        for row in repeated_rows()
        if int(row["occurrences"]) >= 2
    }
    if not repeated_unresolved <= supplement_words:
        raise SystemExit(
            f"post-grind repeated unknowns lack dispositions: {sorted(repeated_unresolved-supplement_words)}"
        )
    print(json.dumps({"pass": PASS, "dispositioned": len(found)}, sort_keys=True))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        check()
    else:
        print(render(), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
