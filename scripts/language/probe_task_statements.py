#!/usr/bin/env python3
"""Measure the narrow reader on a fixed row-ordered task-statement sample.

The probe loads the usable ``complete_statement`` rows from the generated IM
task store, chooses 200 evenly spaced rows in source order, sentence-splits
them, and records the reader's verdict and emitted facts for every sentence.
It is deterministic and does not call a model or solve the tasks.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from collections import Counter
from pathlib import Path

from probe_reader_coverage import sentences


REPO = Path(__file__).resolve().parents[2]
SOURCE = REPO / "curriculum/im/generated/compiled_defragged_task_instances.pl"
READER = REPO / "knowledge/strategies/abstraction/word_problem_reader_pilot.pl"
APE_READER = REPO / "knowledge/strategies/abstraction/ape_reader_pilot.pl"
APE_LEXICON = REPO / "hermes/app/runtime/experiments/language/ape_user_lexicon.pl"
OUTPUT = REPO / "hermes/app/runtime/experiments/language/task_statement_probe.json"
APE_OUTPUT = REPO / "hermes/app/runtime/experiments/language/task_statement_probe_ape.json"
SAMPLE_SIZE = 200
USABLE_STATUSES = ("already_complete", "recovered")
ALLOWED_FACT_FUNCTORS = {
    "quantity",
    "conversion",
    "relation",
    "asks",
    "discrete_kinds",
}


def file_sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prolog_atom(path: Path) -> str:
    return "'" + str(path).replace("'", "''") + "'"


def load_rows() -> list[dict[str, object]]:
    goal = (
        "use_module(library(http/json)),"
        f"load_files({prolog_atom(SOURCE)},[silent(true)]),"
        "findall(_{id:IdString,lesson:LessonString,task:TaskString,"
        "status:StatusString,complete_statement:Statement,"
        "source_statement:SourceStatement,referents:Referents,"
        "source_spans:Spans,source_statement_spans:SourceStatementSpans,"
        "statement_joiner:StatementJoiner,statement_spans:StatementSpans},"
        "(compiled_defragged_task_instances:defragged_task_instance(Id,Lesson,Task,Data),"
        "get_dict(status,Data,Status),memberchk(Status,[already_complete,recovered]),"
        "get_dict(complete_statement,Data,Statement),"
        "get_dict(source_statement,Data,SourceStatement),"
        "get_dict(source_statement_segments,Data,SourceStatementSegmentIds),"
        "get_dict(statement_joiner,Data,StatementJoiner),"
        "get_dict(statement_segments,Data,StatementSegmentIds),"
        "get_dict(referents,Data,Referents),"
        "get_dict(source_segments,Data,Segments),"
        "atom_string(Id,IdString),atom_string(Lesson,LessonString),"
        "term_string(Task,TaskString,[quoted(true)]),atom_string(Status,StatusString),"
        "findall(_{id:SegmentId,path:Path,line_start:LineStart,line_end:LineEnd,"
        "byte_start:ByteStart,byte_end:ByteEnd,sha256:Sha},"
        "(member(Segment,Segments),get_dict(path,Segment,Path),"
        "get_dict(id,Segment,SegmentId),"
        "get_dict(line_start,Segment,LineStart),get_dict(line_end,Segment,LineEnd),"
        "get_dict(byte_start,Segment,ByteStart),get_dict(byte_end,Segment,ByteEnd),"
        "get_dict(sha256,Segment,Sha)),Spans),"
        "findall(_{id:SourceSegmentIdString,path:SourcePath,"
        "line_start:SourceLineStart,line_end:SourceLineEnd,"
        "byte_start:SourceByteStart,byte_end:SourceByteEnd,sha256:SourceSha},"
        "(member(SourceSegmentId,SourceStatementSegmentIds),"
        "atom_string(SourceSegmentId,SourceSegmentIdString),"
        "member(SourceSegment,Segments),"
        "get_dict(id,SourceSegment,SourceSegmentIdString),"
        "get_dict(path,SourceSegment,SourcePath),"
        "get_dict(line_start,SourceSegment,SourceLineStart),"
        "get_dict(line_end,SourceSegment,SourceLineEnd),"
        "get_dict(byte_start,SourceSegment,SourceByteStart),"
        "get_dict(byte_end,SourceSegment,SourceByteEnd),"
        "get_dict(sha256,SourceSegment,SourceSha)),"
        "SourceStatementSpans),"
        "findall(_{id:StatementSegmentIdString,path:StatementPath,"
        "line_start:StatementLineStart,line_end:StatementLineEnd,"
        "byte_start:StatementByteStart,byte_end:StatementByteEnd,"
        "sha256:StatementSha},"
        "(member(StatementSegmentId,StatementSegmentIds),"
        "atom_string(StatementSegmentId,StatementSegmentIdString),"
        "member(StatementSegment,Segments),"
        "get_dict(id,StatementSegment,StatementSegmentIdString),"
        "get_dict(path,StatementSegment,StatementPath),"
        "get_dict(line_start,StatementSegment,StatementLineStart),"
        "get_dict(line_end,StatementSegment,StatementLineEnd),"
        "get_dict(byte_start,StatementSegment,StatementByteStart),"
        "get_dict(byte_end,StatementSegment,StatementByteEnd),"
        "get_dict(sha256,StatementSegment,StatementSha)),"
        "StatementSpans)),"
        "Rows),json_write_dict(user_output,Rows,[width(0)])"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        text=True,
        capture_output=True,
        check=True,
    )
    rows = json.loads(result.stdout)
    if len(rows) < SAMPLE_SIZE:
        raise ValueError(f"need {SAMPLE_SIZE} usable rows, found {len(rows)}")
    return rows


def sample_indices(row_count: int) -> list[int]:
    """Choose SAMPLE_SIZE evenly spaced zero-based indices in row order."""
    indices = [(offset * row_count) // SAMPLE_SIZE for offset in range(SAMPLE_SIZE)]
    if len(set(indices)) != SAMPLE_SIZE:
        raise ValueError("row-ordered sample produced duplicate indices")
    return indices


def reader_receipts(all_sentences: list[str]) -> list[dict[str, object]]:
    goal = (
        "use_module(library(http/json)),"
        f"load_files({prolog_atom(READER)},[silent(true)]),"
        "json_read_dict(user_input,Input),"
        "get_dict(sentences,Input,Sentences),"
        "findall(Row,(member(S,Sentences),"
        "(word_problem_reader_pilot:word_problem_facts(S,Facts)"
        "->maplist(term_string,Facts,FactStrings),"
        "Row=_{parsed:true,facts:FactStrings};"
        "Row=_{parsed:false,facts:[]})),Rows),"
        "json_write_dict(user_output,Rows,[width(0)])"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        input=json.dumps({"sentences": all_sentences}, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


def union_reader_receipts(all_sentences: list[str]) -> list[dict[str, object]]:
    """Run the incumbent first and APE only after an incumbent refusal."""
    goal = (
        "use_module(library(http/json)),use_module(library(porter_stem)),"
        f"load_files({prolog_atom(READER)},[silent(true)]),"
        f"load_files({prolog_atom(APE_READER)},[silent(true)]),"
        "json_read_dict(user_input,Input),get_dict(sentences,Input,Sentences),"
        "findall(Row,(member(S,Sentences),"
        "(word_problem_reader_pilot:word_problem_facts(S,Facts)"
        "->maplist(term_string,Facts,FactStrings),"
        "Row=_{parsed:true,reader:incumbent,facts:FactStrings,fact_spans:[],"
        "rewrite_rules:[],refusals:_{}};"
        "string_lower(S,Lower),tokenize_atom(Lower,Tokens),"
        "(Tokens=[Entry|_]->term_string(Entry,EntryToken);EntryToken=\"\"),"
        "ape_reader_pilot:ape_reader_result(S,ApeResult),"
        "(ApeResult=parsed(ApeFacts,ApeSpans,Rules)"
        "->maplist(term_string,ApeFacts,ApeFactStrings),"
        "findall(_{fact_index:I,start:Start,end:End,text:Text},"
        "member(fact_span(I,Start,End,Text),ApeSpans),SpanRows),"
        "maplist(term_string,Rules,RuleStrings),"
        "Row=_{parsed:true,reader:ape,facts:ApeFactStrings,fact_spans:SpanRows,"
        "rewrite_rules:RuleStrings,refusals:_{incumbent:_{token:EntryToken,"
        "token_basis:sentence_entry_no_failure_api}}};"
        "ApeResult=refusal(Token,span(Start,End,Surface),Reason,Rules),"
        "term_string(Reason,ReasonString),maplist(term_string,Rules,RuleStrings),"
        "Row=_{parsed:false,reader:both_refused,facts:[],fact_spans:[],"
        "rewrite_rules:RuleStrings,refusals:_{incumbent:_{token:EntryToken,"
        "token_basis:sentence_entry_no_failure_api},ape:_{token:Token,start:Start,"
        "end:End,text:Surface,reason:ReasonString}}}))),Rows),"
        "json_write_dict(user_output,Rows,[width(0)])"
    )
    result = subprocess.run(
        ["swipl", "-q", "-g", goal, "-t", "halt"],
        input=json.dumps({"sentences": all_sentences}, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=True,
    )
    return json.loads(result.stdout)


def build_receipt(second_reader: str | None = None) -> dict[str, object]:
    eligible = load_rows()
    indices = sample_indices(len(eligible))
    sampled = [eligible[index] for index in indices]
    sentence_groups = [sentences(str(row["complete_statement"])) for row in sampled]
    flat_sentences = [sentence for group in sentence_groups for sentence in group]
    verdicts = iter(
        union_reader_receipts(flat_sentences)
        if second_reader == "ape"
        else reader_receipts(flat_sentences)
    )

    totals = Counter(rows=len(sampled), sentences=len(flat_sentences))
    output_rows: list[dict[str, object]] = []
    emitted_functors = Counter()
    for sample_ordinal, (row_index, row, group) in enumerate(
        zip(indices, sampled, sentence_groups), start=1
    ):
        sentence_rows: list[dict[str, object]] = []
        for sentence_index, sentence in enumerate(group):
            verdict = next(verdicts)
            if verdict["parsed"]:
                totals["parsed_sentences"] += 1
            else:
                totals["refused_sentences"] += 1
            if second_reader == "ape":
                reader = str(verdict["reader"])
                totals[f"{reader}_sentences"] += 1
            for fact in verdict["facts"]:
                functor = str(fact).split("(", 1)[0]
                if functor not in ALLOWED_FACT_FUNCTORS:
                    raise ValueError(f"out-of-contract reader fact: {fact}")
                emitted_functors[functor] += 1
            sentence_rows.append(
                {
                    "sentence_index": sentence_index,
                    "text": sentence,
                    "parsed": verdict["parsed"],
                    "facts": verdict["facts"],
                    **(
                        {
                            "reader": verdict["reader"],
                            "fact_spans": verdict["fact_spans"],
                            "rewrite_rules": verdict["rewrite_rules"],
                            "refusals": verdict["refusals"],
                        }
                        if second_reader == "ape"
                        else {}
                    ),
                }
            )
        output_rows.append(
            {
                "sample_ordinal": sample_ordinal,
                "eligible_row_index": row_index,
                **row,
                "sentences": sentence_rows,
            }
        )

    totals["emitted_facts"] = sum(emitted_functors.values())
    totals["parse_rate"] = (
        totals["parsed_sentences"] / totals["sentences"] if totals["sentences"] else 0.0
    )
    source_sha = {
        "compiled_defragged_task_instances.pl": file_sha(SOURCE),
        "word_problem_reader_pilot.pl": file_sha(READER),
    }
    if second_reader == "ape":
        source_sha.update(
            {
                "ape_reader_pilot.pl": file_sha(APE_READER),
                "ape_user_lexicon.pl": file_sha(APE_LEXICON),
            }
        )
    return {
        "role": "row_ordered_task_statement_reader_probe",
        "second_reader": second_reader,
        "selection": {
            "usable_statuses": list(USABLE_STATUSES),
            "eligible_rows": len(eligible),
            "sample_size": SAMPLE_SIZE,
            "method": "floor(sample_offset * eligible_rows / 200), source row order",
            "eligible_row_indices": indices,
        },
        "source_sha256": source_sha,
        "totals": dict(totals),
        "emitted_fact_functors": dict(sorted(emitted_functors.items())),
        "allowed_fact_functors": sorted(ALLOWED_FACT_FUNCTORS),
        "rows": output_rows,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--second-reader", choices=["ape"])
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    receipt = build_receipt(args.second_reader)
    selected_output = args.output or (APE_OUTPUT if args.second_reader == "ape" else OUTPUT)
    output = selected_output if selected_output.is_absolute() else REPO / selected_output
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(receipt, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(receipt["totals"], sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
