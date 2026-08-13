#!/usr/bin/env python3
"""Count model tokens for newline-delimited JSON strings on stdin."""
from __future__ import annotations

import json
import sys
from pathlib import Path

from tokenizers import Tokenizer


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: wave5_token_count.py TOKENIZER_JSON")
    tokenizer = Tokenizer.from_file(str(Path(sys.argv[1])))
    for line in sys.stdin:
        text = json.loads(line)
        print(len(tokenizer.encode(text).ids), flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

