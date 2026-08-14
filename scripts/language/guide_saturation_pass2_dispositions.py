#!/usr/bin/env python3
"""Render and audit pass-2 IM-guide singleton dispositions.

The sets in this file are authored lexical judgments over the durable pass-1
frontier. The saturation census supplies each word's occurrence and context;
this file supplies one disjoint class and, where applicable, a real
morphological paradigm. Rendering is deterministic and never edits the
supplement.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter

from build_math_lexicon import REPO, load_supplement


CENSUS = REPO / "hermes/app/runtime/experiments/language/im_guide_saturation.json"
SUPPLEMENT = REPO / "knowledge/strategies/abstraction/lexicon_supplement_pilot.pl"
LEDGER = REPO / ".superpowers/sdd/language-lane/saturation_ledger.json"
PASS = "guide_saturation_2"
EXPECTED_FRONTIER = 499


def words(text: str) -> set[str]:
    return set(text.split())


CLASS_WORDS = {
    "abbreviation": words("ca ceo fl gcf lcm va"),
    "adjective": words(
        "aesthetic arrowed automated bottlenose bulleted competent countable culminating cultural "
        "cute freshwater friendlier grassy insightful invitational lowercase nonzero prefilled "
        "relational reserved rotational trickiest unambiguous unattended unavailable uncooked "
        "uneaten unfilled unhealthy unpartitioned unresolved unrounded unsafe untorn worthwhile"
    ),
    "adverb": words(
        "anymore collaboratively creatively developmentally digitally exclusively inadvertently "
        "iteratively nicely obviously productively progressively receptively selectively "
        "structurally symbolically thoughtfully unreasonably vigorously"
    ),
    "common_noun": words(
        "app audiobooks beekeepers bodegas bookcase bow casseroles checkmark cleanup clothespins "
        "commercials corpus costumes counselor countertop creativity cycling delis fettuccine "
        "fishbowl fishbowls flatbread floorspace freeways frisbee groupmates helicopter heptathlon "
        "hippos hummingbirds judgement landfills lasagna mappings mashup murals newborns nightstand "
        "notecard papadum paperclips pressure pros quesadilla quiltmakers ramen recorder reliability "
        "replacement route setup setups shortcuts souvenir stoplight supermarkets takeout tamari "
        "thingies trademarks wartime wisdom workstations yogurt youth zipper"
    ),
    "corpus_verb": words(
        "begun biked criticize experimenting exploiting hypothesize misalign notated overlapped "
        "overspend prioritize quantified reconsidering reframe remake remaking renames reorganize "
        "reorganized squishing transitioned updating"
    ),
    "curriculum_code": words("ccss l27 l28 lessondoc ms3"),
    "family_name": words(
        "aceves acosta addington alves atehortúa barnum behmer bejarano bement berger blaker "
        "bondurant bonilla bossio botero brokaw buckner casias castelblanco catanese cerrahoglu "
        "chang chavez chiasson coer connally crilley cuervo cukier cummins cunningham daro dieckmann "
        "disalvo doran drawdy dunbar ehlert englard espinosa estrella flanagan forero gael garrett "
        "giang gonzález guarín gutiérrez gómez haase harris hathaway hemmings hernandez hollister "
        "hovan jaramillo karim kerins kessel kobyra koppens kranendonk krismen kuo lahme larrieu "
        "lemense lesondak lipitz liévano lyons lópez mak malamut mariño martínez mccallum mckissack "
        "mcleman mourtgos muñoz nakamaye neihaus norstrom nowak otero ott parascand paredes paternina "
        "petersen pikcilingis pina portee puchalik pérez quach ramirez reyes rivera russell rutherford "
        "salazar salgarino shean skarin skousen stoll sturges suárez sánchez taranto tehrani tioanda "
        "tompert umland walsh weiss whiteman winkler zapata zwiers"
    ),
    "function_word": words("gonna ours themself"),
    "given_name": words(
        "adolfo aishlinn alberto alejandro alphonese andrea andrés angela anke arjun ashli aubrey "
        "audrey becca bernadette beverly bowen brendan bridget brigitte camilo celeana clara deb dina "
        "dougie dyanne eleanor elijah ellen francy gary gretchen hannah jackyra jareb jed jenise jon "
        "judith kathy kia kim kristine libby lindsay liz lizzy lois maddie madeleine maría marsaili "
        "mauricio medina mia micah michelle mimi moises nathaly nia nik orlando parker patti philomen "
        "phyllis preetha renae renee rodney rolando roxy sadako sadie sara siavash somari stefanie "
        "taren thai tiana toni trish vinci xander yenche yoko"
    ),
    "interjection": words("tock"),
    "math_notation": words("cm2 cm3 iii iiiii iiiiiii iiiiiiii"),
    "math_term": words(
        "additivity approximations midrange misalignment partitionings quantifiers quintillion "
        "recomposing renaming zillion"
    ),
    "named_entity": words("bim bop gehé ipad miqramah moma nctm oware pallanguzhi skydive tate"),
    "pedagogy_term": words("backline chunking distractors infographic infographics metacognition mindset"),
    "place_name": words(
        "alaskans argentina asia audubon augusta baltimore brazil colorado delhi france hamilton "
        "iguazu illinois iraq jaragua lebanon manhattan massachusetts mesa montana nevada oakland "
        "ohio pakistan peru sacramento shadyside southeast sudan syria taiwan tanzania tennessee "
        "topeka trenton utah wolfsburg"
    ),
    "pronunciation_token": words("baow duhls ehn fawlz gah geh gwah krah lahn mah mee nah pohs reh teh trohm voh wah"),
    "tokenizer_artifact": words(
        "anothers ascars awarenes bal by1 by5 centersl dislay drawhen erase2 forg inche least1 lefto "
        "mathematicals mexicos minuter number10 of54 protractorhas pullin rdquo reasonin s15strategy "
        "socio stitchin thetwo thier ver write1"
    ),
    "unit_abbreviation": words("tsp"),
    "unit_prefix": words("centi"),
    "web_token": words("clker http jkpics jpg mathforum py soulsgrowndeep wiki"),
}


PLURAL_BASE = {
    "approximations": "approximation",
    "audiobooks": "audiobook",
    "beekeepers": "beekeeper",
    "bodegas": "bodega",
    "casseroles": "casserole",
    "clothespins": "clothespin",
    "commercials": "commercial",
    "costumes": "costume",
    "delis": "deli",
    "distractors": "distractor",
    "fishbowls": "fishbowl",
    "freeways": "freeway",
    "groupmates": "groupmate",
    "hippos": "hippo",
    "hummingbirds": "hummingbird",
    "infographics": "infographic",
    "landfills": "landfill",
    "mappings": "mapping",
    "murals": "mural",
    "newborns": "newborn",
    "paperclips": "paperclip",
    "partitionings": "partitioning",
    "pros": "pro",
    "quantifiers": "quantifier",
    "quiltmakers": "quiltmaker",
    "setups": "setup",
    "shortcuts": "shortcut",
    "supermarkets": "supermarket",
    "thingies": "thingy",
    "trademarks": "trademark",
    "workstations": "workstation",
}

INVARIANT_NOUNS = words(
    "chunking corpus creativity cycling freshwater metacognition pressure recomposing reliability "
    "renaming takeout wartime wisdom youth"
)

VERB_FORMS = {
    "begun": ("begin", "begins", "began", "beginning", "begun"),
    "biked": ("bike", "bikes", "biked", "biking", "biked"),
    "criticize": ("criticize", "criticizes", "criticized", "criticizing", "criticized"),
    "experimenting": ("experiment", "experiments", "experimented", "experimenting", "experimented"),
    "exploiting": ("exploit", "exploits", "exploited", "exploiting", "exploited"),
    "hypothesize": ("hypothesize", "hypothesizes", "hypothesized", "hypothesizing", "hypothesized"),
    "misalign": ("misalign", "misaligns", "misaligned", "misaligning", "misaligned"),
    "notated": ("notate", "notates", "notated", "notating", "notated"),
    "overlapped": ("overlap", "overlaps", "overlapped", "overlapping", "overlapped"),
    "overspend": ("overspend", "overspends", "overspent", "overspending", "overspent"),
    "prioritize": ("prioritize", "prioritizes", "prioritized", "prioritizing", "prioritized"),
    "quantified": ("quantify", "quantifies", "quantified", "quantifying", "quantified"),
    "reconsidering": ("reconsider", "reconsiders", "reconsidered", "reconsidering", "reconsidered"),
    "reframe": ("reframe", "reframes", "reframed", "reframing", "reframed"),
    "remake": ("remake", "remakes", "remade", "remaking", "remade"),
    "remaking": ("remake", "remakes", "remade", "remaking", "remade"),
    "renames": ("rename", "renames", "renamed", "renaming", "renamed"),
    "reorganize": ("reorganize", "reorganizes", "reorganized", "reorganizing", "reorganized"),
    "reorganized": ("reorganize", "reorganizes", "reorganized", "reorganizing", "reorganized"),
    "squishing": ("squish", "squishes", "squished", "squishing", "squished"),
    "transitioned": ("transition", "transitions", "transitioned", "transitioning", "transitioned"),
    "updating": ("update", "updates", "updated", "updating", "updated"),
}

UNIT_EXPANSIONS = {"tsp": "teaspoon"}


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def noun_forms(word: str) -> tuple[str, str]:
    if word in PLURAL_BASE:
        return PLURAL_BASE[word], word
    if word in INVARIANT_NOUNS:
        return word, word
    if word.endswith("y") and word[-2] not in "aeiou":
        return word, word[:-1] + "ies"
    if word.endswith(("s", "x", "z", "ch", "sh")):
        return word, word + "es"
    return word, word + "s"


RATIONALES = {
    "abbreviation": "The guide context uses this invariant abbreviation.",
    "adjective": "The guide context uses this surface adjectivally.",
    "adverb": "The guide context uses this surface adverbially.",
    "common_noun": "The guide context uses this surface as an ordinary noun.",
    "corpus_verb": "The guide context uses this verb surface; the row records its five-form paradigm.",
    "curriculum_code": "The guide source uses this invariant curriculum or lesson identifier.",
    "family_name": "The guide credits use this capitalized token as a person's family name.",
    "function_word": "The guide context uses this invariant grammatical function word.",
    "given_name": "The guide text or credits use this capitalized token as a person's given name.",
    "interjection": "The guide text uses this invariant sound word.",
    "math_notation": "The guide context uses this invariant measurement or tally notation.",
    "math_term": "The guide context uses this surface as a mathematics noun.",
    "named_entity": "The guide context uses this token as a named product, organization, title, or game.",
    "pedagogy_term": "The guide context uses this noun for an instructional resource or practice.",
    "place_name": "The guide context uses this capitalized token as a place or people-name component.",
    "pronunciation_token": "The guide prints this invariant pronunciation component beside a named term.",
    "tokenizer_artifact": "uncertain: the guide source contains a fused, truncated, elided, or malformed token, so it remains refused as an ordinary word.",
    "unit_abbreviation": "The guide recipe uses this unit abbreviation with the stated expansion.",
    "unit_prefix": "The guide explicitly uses this invariant SI unit-prefix name.",
    "web_token": "The guide source metadata uses this invariant web, file, or publishing token.",
}


def authored_classes() -> dict[str, str]:
    duplicates = sorted(
        word
        for word, count in Counter(
            word for members in CLASS_WORDS.values() for word in members
        ).items()
        if count != 1
    )
    if duplicates:
        raise ValueError(f"words assigned to more than one class: {duplicates}")
    return {
        word: word_class
        for word_class, members in CLASS_WORDS.items()
        for word in members
    }


def morphology(word: str, word_class: str) -> str:
    if word_class in {"given_name", "family_name", "place_name", "named_entity", "tokenizer_artifact"}:
        return "none"
    if word_class == "corpus_verb":
        forms = VERB_FORMS[word]
        if word not in forms:
            raise ValueError(f"verb surface absent from its paradigm: {word} {forms}")
        return f"forms(verb({', '.join(forms)}))"
    if word_class in {"common_noun", "math_term", "pedagogy_term"}:
        singular, plural = noun_forms(word)
        return f"forms(noun({singular}, {plural}))"
    if word_class == "unit_abbreviation":
        return f"expands_to({UNIT_EXPANSIONS[word]})"
    return "forms(invariant)"


def check_frontier_evidence() -> None:
    census = json.loads(CENSUS.read_text(encoding="utf-8"))
    classes = authored_classes()
    census_rows = {
        str(row["word"]): row for row in census["unknown_census"]["ranked"]
    }
    if census.get("pass") == "guide_saturation_1":
        rows = [census_rows[word] for word in classes if word in census_rows]
        frontier = {str(row["word"]) for row in rows}
        if len(rows) != EXPECTED_FRONTIER or any(int(row["occurrences"]) != 1 for row in rows):
            raise ValueError(
                f"frontier drifted: rows={len(rows)}, occurrences={sum(int(row['occurrences']) for row in rows)}"
            )
        if frontier != set(classes):
            raise ValueError(
                f"authored frontier mismatch: missing={sorted(frontier-set(classes))}, "
                f"extra={sorted(set(classes)-frontier)}"
            )
        for row in rows:
            if not row.get("samples"):
                raise ValueError(f"frontier word lacks context evidence: {row['word']}")
    elif census.get("pass") != PASS:
        raise ValueError(
            f"unexpected saturation pass: {census.get('pass')!r}"
        )


def render() -> str:
    check_frontier_evidence()
    classes = authored_classes()
    lines = []
    for word in sorted(classes):
        word_class = classes[word]
        lines.append(
            f"ls_word({prolog_atom(word)}, {word_class}, {morphology(word, word_class)}, "
            f"evidence(occurrences(1), pass({PASS})), "
            f"{json.dumps(RATIONALES[word_class], ensure_ascii=False)})."
        )
    return "\n".join(lines) + "\n"


def check() -> None:
    check_frontier_evidence()
    expected = set(authored_classes())
    text = SUPPLEMENT.read_text(encoding="utf-8")
    found = {
        word.replace("''", "'")
        for word in re.findall(
            rf"^ls_word\('((?:''|[^'])+)'[^\n]+pass\({PASS}\)",
            text,
            flags=re.MULTILINE,
        )
    }
    if found != expected:
        raise SystemExit(
            f"pass-2 disposition mismatch: missing={sorted(expected-found)}, extra={sorted(found-expected)}"
        )
    supplement = load_supplement()
    pass_rows = [row for row in supplement["words"] if row["pass"] == PASS]
    if len(pass_rows) != EXPECTED_FRONTIER or sum(int(row["occurrences"]) for row in pass_rows) != EXPECTED_FRONTIER:
        raise SystemExit("pass-2 occurrence evidence drifted")
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    if ledger.get("pass") != 2 or ledger.get("remaining_census_size") != 0:
        raise SystemExit("pass-2 ledger is not closed")
    print(
        json.dumps(
            {
                "pass": PASS,
                "dispositioned": len(found),
                "class_counts": dict(sorted(Counter(authored_classes().values()).items())),
            },
            ensure_ascii=False,
            sort_keys=True,
        )
    )


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
