#!/usr/bin/env python3
"""The accusation ledger for a graph_only mistake_location run.

The f1 on this task cannot say much. Items divide evenly between erroneous
and correct solutions, so answering 0 everywhere scores 0.500, and a
responder built to stay quiet can only move a little either side of that.
What the arithmetic of the metric does say is worth stating plainly:

* accusing a CORRECT solution costs a point — it is the only move that does
* accusing an ERRONEOUS solution at the wrong step costs nothing, since 0
  would also have been wrong
* accusing an erroneous solution at the right step gains a point

So the run's information is the ledger: how often the catalog licensed an
accusation, where those accusations landed, and which gate stopped the
rest. Read from the per-item rows, each of which carries the responder's
own working record.

    python3 mtb_graph_ledger.py RUN_DIR/mistake_location.jsonl
"""
from __future__ import annotations

import collections
import json
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    rows = [json.loads(line)
            for line in Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
            if line.strip()]

    gates: collections.Counter[str] = collections.Counter()
    machines: collections.Counter[str] = collections.Counter()
    accusations = []
    missing_record = 0
    for row in rows:
        working = row.get("responder_record")
        if working is None:
            missing_record += 1
            continue
        gates[working.get("gate", "none")] += 1
        if working.get("gate") == "accused":
            accusations.append(row)
            machines[working.get("machine", "?")] += 1

    on_correct = [row for row in accusations if int(row["target"]) == 0]
    on_erroneous = [row for row in accusations if int(row["target"]) != 0]
    exact = [row for row in on_erroneous
             if int(row["prediction"]) == int(row["target"])]

    zeros_right = sum(1 for row in rows
                      if int(row["prediction"]) == 0 and int(row["target"]) == 0)
    accuracy = sum(1 for row in rows
                   if int(row["prediction"]) == int(row["target"])) / len(rows)

    print(f"items                          {len(rows)}")
    if missing_record:
        print(f"rows with no responder record  {missing_record}")
    print(f"accuracy (= f1_micro)          {accuracy:.4f}   "
          f"[always-0 floor 0.500]")
    print()
    print("ACCUSATION LEDGER")
    print(f"  accusations                  {len(accusations)}")
    print(f"    on a correct solution      {len(on_correct)}   "
          f"(each costs one point)")
    print(f"    on an erroneous solution   {len(on_erroneous)}")
    print(f"      at the exact step        {len(exact)}   "
          f"(each gains one point)")
    print(f"      at another step          {len(on_erroneous) - len(exact)}   "
          f"(costs nothing; 0 was wrong too)")
    if accusations:
        print(f"  precision on erroneous       "
              f"{len(on_erroneous) / len(accusations):.3f}")
        print(f"  precision on the exact step  "
              f"{len(exact) / len(accusations):.3f}")
    print(f"  net against the floor        "
          f"{(len(exact) - len(on_correct)) / len(rows):+.4f}")
    print(f"  correct silences             {zeros_right} of "
          f"{sum(1 for row in rows if int(row['target']) == 0)}")
    print()
    print("WHERE THE REST STOPPED")
    for gate, count in gates.most_common():
        print(f"  {gate:32s} {count}")
    print()
    print("MACHINES NAMED IN ACCUSATIONS")
    for machine, count in machines.most_common(25):
        print(f"  {machine:60s} {count}")


if __name__ == "__main__":
    main()
