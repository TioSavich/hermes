#!/usr/bin/env python3
"""Focused regressions for the deterministic Mobius surface scanners."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / "scripts/research/mobius_adversarial_loop.py"
spec = importlib.util.spec_from_file_location("mobius_reader_checks", DRIVER)
if spec is None or spec.loader is None:
    raise RuntimeError(f"cannot load {DRIVER}")
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)

tagger = module.load_module(
    "mobius_reader_check_tagger", ROOT / "scripts/research/brandomian_tagger.py"
)
brandom = tagger.load_lexicon(tagger.DEFAULT_LEXICON)
bands = json.loads(module.LEXICONS.read_text(encoding="utf-8"))

text = "I don't think I got this one right."
yellow = module.yellow_reading(text, bands)
violet = module.violet_reading(text, bands)
assert yellow["status"] == "read", yellow
assert any(
    hit["text"].lower() == "i don't think"
    for hit in yellow["candidate_catastrophe_sites"]
), yellow
assert violet["status"] == "silence", violet

evaluative = "Which is awesome."
tag = tagger.tag_utterance("u0001", evaluative, brandom)
blue = module.blue_reading(tag, evaluative)
assert not any(
    span["type"] == "substitution_inference_candidate"
    for span in blue["surface_spans"]
), blue

mathematical = "Two fourths is equal to one half."
tag = tagger.tag_utterance("u0002", mathematical, brandom)
blue = module.blue_reading(tag, mathematical)
assert any(
    span["type"] == "substitution_inference_candidate"
    for span in blue["surface_spans"]
), blue

print("PASS Mobius band reader regressions")
