#!/usr/bin/env python3
"""Fold the adapter into the base weights, so the result can be quantized.

An adapter is reversible and cheap to ship, which is why phase 1 trains one.
It is also not a thing `llama.cpp` can quantize on its own, and the deployment
claim this project makes is a Q4_K_M file on a teacher's laptop. Merging is the
step between those two facts, and the amendment pulled it into phase 1 because
without it there is no honest before-and-after.

The tokenizer and the processor configuration travel with the merged weights;
a conversion that cannot find them produces a model that cannot be served.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

import torch


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--adapter", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()

    from peft import PeftModel
    from transformers import AutoModelForCausalLM, AutoTokenizer

    if not (arguments.adapter / "adapter_model.safetensors").is_file():
        print(f"no adapter weights at {arguments.adapter}", file=sys.stderr)
        return 1

    print(f"loading base weights from {arguments.base}", flush=True)
    model = AutoModelForCausalLM.from_pretrained(arguments.base, dtype=torch.bfloat16)
    print(f"applying the adapter from {arguments.adapter}", flush=True)
    model = PeftModel.from_pretrained(model, str(arguments.adapter))
    model = model.merge_and_unload()
    arguments.output.mkdir(parents=True, exist_ok=True)
    model.save_pretrained(str(arguments.output), safe_serialization=True)

    tokenizer = AutoTokenizer.from_pretrained(arguments.base)
    tokenizer.save_pretrained(str(arguments.output))
    # The chat template is what makes a tool conversation renderable. Carry it
    # explicitly rather than trusting the tokenizer save to include it.
    for name in ("chat_template.jinja", "preprocessor_config.json", "processor_config.json"):
        source = arguments.base / name
        if source.is_file():
            shutil.copy2(source, arguments.output / name)

    written = sorted(path.name for path in arguments.output.iterdir())
    print(json.dumps({"output": str(arguments.output), "files": written}, indent=2))
    return 0 if (arguments.output / "config.json").is_file() else 1


if __name__ == "__main__":
    raise SystemExit(main())
