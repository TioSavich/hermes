#!/usr/bin/env python3
"""Print the task-82 `too_vague` rename proposal; never edits knowledge/."""
from __future__ import annotations

import argparse
import json

from misconception_survey import load_rows, rename_rows


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--format", choices=("json", "tsv"), default="tsv")
    args = parser.parse_args()
    rows = rename_rows(load_rows())
    if args.format == "json":
        print(json.dumps(rows, indent=2, ensure_ascii=False))
    else:
        print("row_id\told_name\tnew_name\tdocumented_error\tcitation")
        for row in rows:
            print("\t".join((row["id"], row["name"], row["new_name"], row["error"].replace("\t", " "), row["citation"].replace("\t", " "))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
