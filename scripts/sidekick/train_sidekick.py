#!/usr/bin/env python3
"""LoRA the disposition to ask, on one A100, with the mask that matters.

Phase 0 runs this only as the law-zero proof: a handful of steps, a checkpoint
written, a resume exercised, and a throughput number to replace the design's
estimate band. No adapter produced here is a result.

The collator is written out rather than delegated, because the mask in
`supervision.py` is what keeps the model from learning to write Hermes's
answers for it, and a library default would silently supervise the tool
response.
"""
from __future__ import annotations

import argparse
import json
import os
import random
import sys
import time
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
for candidate in (str(REPO_ROOT), str(SCRIPT_DIR)):
    if candidate not in sys.path:
        sys.path.insert(0, candidate)

import torch  # noqa: E402
from torch.utils.data import Dataset  # noqa: E402

from chat_format import GemmaChatFormat  # noqa: E402
from dataset import Row, read as read_rows  # noqa: E402
from supervision import IGNORE, build as build_mask, check as check_mask  # noqa: E402

PROJECTIONS = ("q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj")
FROZEN_TOWERS = ("vision", "audio")
PAD_ID = 0


class SidekickDataset(Dataset):
    """Rendered rows, masked once at load so training cannot re-decide it."""

    def __init__(self, rows: list[Row], chat: GemmaChatFormat, tools: dict[str, dict[str, Any]], max_length: int) -> None:
        self.examples: list[dict[str, list[int]]] = []
        self.truncated = 0
        self.token_total = 0
        for row in rows:
            rendered = chat.render(row.messages(), [tools[name] for name in row.menu])
            supervision = build_mask(chat, rendered)
            check_mask(chat, rendered, supervision, expects_call=bool(row.calls))
            ids, labels = supervision.ids, supervision.labels
            if len(ids) > max_length:
                self.truncated += 1
                ids, labels = ids[-max_length:], labels[-max_length:]
            self.token_total += len(ids)
            self.examples.append({"input_ids": ids, "labels": labels})

    def __len__(self) -> int:
        return len(self.examples)

    def __getitem__(self, index: int) -> dict[str, list[int]]:
        return self.examples[index]


def collate(batch: list[dict[str, list[int]]]) -> dict[str, torch.Tensor]:
    width = max(len(item["input_ids"]) for item in batch)
    input_ids, labels, attention = [], [], []
    for item in batch:
        pad = width - len(item["input_ids"])
        input_ids.append(item["input_ids"] + [PAD_ID] * pad)
        labels.append(item["labels"] + [IGNORE] * pad)
        attention.append([1] * len(item["input_ids"]) + [0] * pad)
    return {
        "input_ids": torch.tensor(input_ids, dtype=torch.long),
        "labels": torch.tensor(labels, dtype=torch.long),
        "attention_mask": torch.tensor(attention, dtype=torch.long),
    }


def text_tower_targets(model: torch.nn.Module) -> list[str]:
    """Name every projection in the text tower, and nothing in the others."""
    targets: list[str] = []
    for name, module in model.named_modules():
        if not isinstance(module, torch.nn.Linear):
            continue
        lowered = name.casefold()
        if any(tower in lowered for tower in FROZEN_TOWERS):
            continue
        if name.rsplit(".", 1)[-1] in PROJECTIONS:
            targets.append(name)
    return targets


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rows", type=Path, required=True)
    parser.add_argument("--model", default="google/gemma-4-E2B-it")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--max-steps", type=int, default=20)
    parser.add_argument("--save-steps", type=int, default=10)
    parser.add_argument("--batch-size", type=int, default=1)
    parser.add_argument("--accumulation", type=int, default=8)
    parser.add_argument("--max-length", type=int, default=2048)
    parser.add_argument("--rank", type=int, default=32)
    parser.add_argument("--alpha", type=int, default=64)
    parser.add_argument("--dropout", type=float, default=0.05)
    parser.add_argument("--learning-rate", type=float, default=1e-4)
    parser.add_argument("--seed", type=int, default=20260810)
    parser.add_argument("--resume", action="store_true", help="continue from the last checkpoint in --output")
    parser.add_argument("--tools", type=Path, help="JSON list of tool declarations; defaults to the live core surface")
    arguments = parser.parse_args()

    random.seed(arguments.seed)
    torch.manual_seed(arguments.seed)
    print(f"torch {torch.__version__} cuda {torch.version.cuda} devices {torch.cuda.device_count()}", flush=True)

    from peft import LoraConfig, get_peft_model
    from transformers import AutoModelForCausalLM, Trainer, TrainingArguments

    chat = GemmaChatFormat()
    if arguments.tools:
        declarations = json.loads(arguments.tools.read_text(encoding="utf-8"))
    else:
        from hermes.mcp.server import HermesMCPServer

        declarations = list(HermesMCPServer("core", REPO_ROOT)._public_tools)
    tools = {tool["name"]: tool for tool in declarations}

    rows = read_rows(arguments.rows)
    data = SidekickDataset(rows, chat, tools, arguments.max_length)
    print(
        f"rows {len(data)} tokens {data.token_total} truncated {data.truncated} "
        f"mean {data.token_total / max(1, len(data)):.0f}",
        flush=True,
    )

    started = time.time()
    model = AutoModelForCausalLM.from_pretrained(arguments.model, dtype=torch.bfloat16)
    print(f"weights loaded in {time.time() - started:.0f}s: {type(model).__name__}", flush=True)
    targets = text_tower_targets(model)
    print(f"lora targets {len(targets)} text-tower projections; towers {FROZEN_TOWERS} frozen", flush=True)
    if not targets:
        raise SystemExit("no text-tower projection matched; refusing to train an empty adapter")
    model = get_peft_model(
        model,
        LoraConfig(
            r=arguments.rank,
            lora_alpha=arguments.alpha,
            lora_dropout=arguments.dropout,
            bias="none",
            task_type="CAUSAL_LM",
            target_modules=targets,
        ),
    )
    trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
    total = sum(p.numel() for p in model.parameters())
    print(f"trainable {trainable} of {total} ({100 * trainable / total:.3f}%)", flush=True)

    arguments.output.mkdir(parents=True, exist_ok=True)
    training = TrainingArguments(
        output_dir=str(arguments.output),
        max_steps=arguments.max_steps,
        per_device_train_batch_size=arguments.batch_size,
        gradient_accumulation_steps=arguments.accumulation,
        learning_rate=arguments.learning_rate,
        lr_scheduler_type="cosine",
        warmup_ratio=0.03,
        logging_steps=1,
        save_steps=arguments.save_steps,
        save_total_limit=3,
        bf16=True,
        gradient_checkpointing=True,
        report_to=[],
        disable_tqdm=True,
        seed=arguments.seed,
        remove_unused_columns=False,
    )
    trainer = Trainer(model=model, args=training, train_dataset=data, data_collator=collate)
    checkpoints = sorted(arguments.output.glob("checkpoint-*"), key=lambda path: int(path.name.split("-")[1]))
    resume = str(checkpoints[-1]) if (arguments.resume and checkpoints) else None
    print(f"resume from {resume}", flush=True)

    started = time.time()
    result = trainer.train(resume_from_checkpoint=resume)
    elapsed = time.time() - started
    steps = result.global_step - (int(Path(resume).name.split("-")[1]) if resume else 0)
    tokens = steps * arguments.batch_size * arguments.accumulation * (data.token_total / max(1, len(data)))
    throughput = {
        "steps": steps,
        "seconds": round(elapsed, 1),
        "tokens_per_second": round(tokens / elapsed, 1) if elapsed else None,
        "seconds_per_step": round(elapsed / steps, 2) if steps else None,
        "mean_tokens_per_example": round(data.token_total / max(1, len(data)), 1),
        "effective_batch": arguments.batch_size * arguments.accumulation,
        "train_loss": result.training_loss,
        "device": torch.cuda.get_device_name(0) if torch.cuda.is_available() else "cpu",
    }
    print("THROUGHPUT " + json.dumps(throughput), flush=True)
    (arguments.output / "throughput.json").write_text(json.dumps(throughput, indent=2) + "\n", encoding="utf-8")
    trainer.save_model(str(arguments.output / "adapter"))
    print(f"adapter written to {arguments.output / 'adapter'}", flush=True)
    return 0


if __name__ == "__main__":
    os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")
    raise SystemExit(main())
