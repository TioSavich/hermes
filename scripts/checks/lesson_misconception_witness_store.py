#!/usr/bin/env python3
"""Check the generated lesson-misconception witness store against the live path."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO))
from scripts.curriculum import build_lesson_misconception_witness_store as builder


DEFAULT_STORE = REPO / "curriculum/im/generated/lesson_misconception_witness_store.pl"
# Five codes per generated stratum, selected deterministically and pinned here.
# A corpus change that removes or reclassifies one is a deliberate gate update.
PINNED_CODES: tuple[str, ...] = (
    # explicit_attachment
    "IM-G1-U1-L1",
    "IM-G2-U6-L3",
    "IM-G4-U4-L1",
    "IM-G5-U8-L12",
    "TRAD-RAY-G5-NF-A1-FRACTION-ADD",
    # cluster_fallback
    "IM-G1-U1-L11",
    "IM-G5-U6-L21",
    "IM-G7-U6-L15",
    "IM-G8-U4-L10",
    "IM-GK-U8-L9",
    # geometry_fallback
    "IM-G1-U7-L12",
    "IM-G4-U7-L3",
    "IM-G5-U8-L9",
    "IM-GK-U3-L7",
    "IM-GK-U7-L7",
)


def prolog_atom(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def run_goal(goal: str) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    for name in builder.ITER7_CAPS:
        env.pop(name, None)
    env.pop("HERMES_WITNESS_LIVE", None)
    return subprocess.run(
        ["swipl", "-q", "-l", "hermes_worker.pl", "-g", f"load_runtime,{goal}", "-t", "halt"],
        cwd=REPO,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )


def json_envelopes(stdout: str) -> dict[str, object]:
    envelopes: dict[str, object] = {}
    for line in stdout.splitlines():
        if not line.startswith("{"):
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(row, dict) and isinstance(row.get("kind"), str):
            envelopes[row["kind"]] = row.get("rows")
    return envelopes


def equality_check(store: Path, codes: list[str]) -> tuple[bool, int]:
    code_terms = ",".join(prolog_atom(code) for code in codes)
    store_term = prolog_atom(str(store.resolve()))
    goal = f"""
use_module(library(http/json)),
lesson_monitoring:load_files({store_term},[if(not_loaded)]),Codes=[{code_terms}],
findall(_{{code:CodeText,operation:OperationText,name:NameText,witness:WitnessJson}},
        ( member(Code,Codes),
          lesson_monitoring:lesson_misconception_witness_fact(Code,Operation,Name,Witness),
          json_safe(Witness,WitnessJson),
          atom_string(Code,CodeText),atom_string(Operation,OperationText),atom_string(Name,NameText)
        ),StoreRows0),sort(StoreRows0,StoreRows),
findall(_{{code:CodeText,operation:OperationText,name:NameText,witness:WitnessJson}},
        ( member(Code,Codes),
          lesson_monitoring:lesson_misconception(Code,Operation,Name,Info),
          member(incompatibility_witness(Witness),Info),
          json_safe(Witness,WitnessJson),
          atom_string(Code,CodeText),atom_string(Operation,OperationText),atom_string(Name,NameText)
        ),LiveRows0),sort(LiveRows0,LiveRows),
json_write_dict(user_output,_{{kind:store,rows:StoreRows}},[width(0)]),nl,
json_write_dict(user_output,_{{kind:live,rows:LiveRows}},[width(0)]),nl
""".replace("\n", " ")
    proc = run_goal(goal)
    if proc.returncode:
        raise RuntimeError(f"store equality worker failed: {proc.stderr.strip()}")
    rows = json_envelopes(proc.stdout)
    store_rows = rows.get("store")
    live_rows = rows.get("live")
    if not isinstance(store_rows, list) or not isinstance(live_rows, list):
        raise RuntimeError("store equality worker did not return both row arrays")
    store_bytes = json.dumps(store_rows, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    live_bytes = json.dumps(live_rows, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return store_bytes == live_bytes, len(store_rows)


def legacy_diff(codes: list[str]) -> tuple[bool, str]:
    code_terms = ",".join(prolog_atom(code) for code in codes)
    goal = f"""
Codes=[{code_terms}],
( forall(member(Code,Codes),
         ( findall(Operation-Name-Info,
                   lesson_monitoring:lesson_misconception(Code,Operation,Name,Info),New),
           findall(Operation0-Name0,
                   lesson_monitoring:lesson_misconception_candidate(Code,Operation0,Name0,_),Keys0),
           sort(Keys0,Keys),
           findall(Operation1-Name1-Info1,
                   ( member(Operation1-Name1,Keys),
                     findall(Info0,
                             lesson_monitoring:lesson_misconception_candidate(
                                 Code,Operation1,Name1,Info0),Infos),
                     lesson_monitoring:preferred_info(Code,Infos,Info1)
                   ),Legacy),
           ( New =@= Legacy -> true ; format('DIFF ~q~n',[Code]),fail )
         ))
-> format('LEGACY_DIFF_OK ~d~n',[{len(codes)}])
;  halt(3)
)
""".replace("\n", " ")
    proc = run_goal(goal)
    return proc.returncode == 0 and "LEGACY_DIFF_OK" in proc.stdout, proc.stdout + proc.stderr


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--store", type=Path, default=DEFAULT_STORE)
    parser.add_argument("--sample-size", type=int, help="use the generator's deterministic three-stratum sample")
    parser.add_argument("--legacy-diff", type=int, metavar="N", help="compare the single-pass implementation with the former algorithm on N stratified codes")
    args = parser.parse_args()

    if args.legacy_diff is not None:
        rows = builder.discover_codes()
        codes = builder.stratified_sample(rows, args.legacy_diff)
        ok, detail = legacy_diff(codes)
        if not ok:
            print(detail, end="" if detail.endswith("\n") else "\n")
            print("FAIL lesson misconception single-pass term diff")
            return 1
        print(f"PASS lesson misconception single-pass term diff: {len(codes)} stratified codes")
        return 0

    if not args.store.exists():
        print(f"SKIP lesson misconception witness store: generated store absent ({args.store})")
        return 0
    activated = (
        "lesson_monitoring:lesson_misconception_witness_store_baked."
        in args.store.read_text(encoding="utf-8").splitlines()
    )
    if args.sample_size is None and not activated:
        print("SKIP lesson misconception witness store: verification sample is not store-first active")
        return 0
    if args.sample_size is not None:
        codes = builder.stratified_sample(builder.discover_codes(), args.sample_size)
    else:
        if not PINNED_CODES:
            raise RuntimeError("PINNED_CODES has not been populated")
        codes = list(PINNED_CODES)
    ok, fact_count = equality_check(args.store, codes)
    if not ok:
        print(f"FAIL lesson misconception witness store: canonical JSON differs on {len(codes)} codes")
        return 1
    print(
        "PASS lesson misconception witness store: "
        f"{fact_count} rows canonical-JSON equal across {len(codes)} codes"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
