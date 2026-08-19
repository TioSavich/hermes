#!/usr/bin/env python3
"""Deterministic installer: coverage-grind admitted ledger -> attributed Prolog store.

Reads hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl
(gitignored, machine-local) and writes
knowledge/strategies/abstraction/model_analysis_pilot.pl (tracked).

Every admitted row already survived propose_verify_driver.py's five gates:
quantities bound to source bytes, steps that re-execute exactly to the
answer, and an oracle tier. This script does not re-run those gates; it
takes the ledger's own "admitted" verdict as testimony and re-derives the
arithmetic independently inside the generated store's own check predicate
(model_analysis_pilot:check_model_analysis_pilot/0), which is the thing
that actually catches drift or transcription error.

Determinism: the only run-to-run variable this script may write is a sha256
of its own inputs (the ledger and the two targets files a statement's text
is read from). No wall-clock timestamp, hostname, or process id is ever
written. Running this script twice against the same inputs produces a
byte-identical .pl file; running it after the ledger's second merge pass
lands produces a new, larger, still-deterministic file.

Statement text: the ledger stores model output but not the source problem
text the model read. The exact text — the one propose_verify_driver.py's
gate 2 validated every quantity's verbatim_span against — lives in the
targets files (uncovered_targets.jsonl, retry_targets.jsonl) under the same
gitignored experiment directory. When a stored row's record_id is missing
from both, this script fails loudly rather than guessing at a substitute
text (curriculum/im/generated/compiled_defragged_task_instances.pl carries
two candidate statement fields per record_id — complete_statement and
source_statement — and empirically neither one alone reproduces the text
the driver actually used for every record, so guessing between them would
misattribute a sha to text the model never saw).
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# propose_verify_driver.py's own tolerant-number reader — gate 3 already ran
# every step operand/result and answer value through _normalize_scalar +
# to_fraction before admitting a row; a 2026-08-18 second-pass retry lane
# ("tolerant parsing") produced rows whose stored answer.value survived that
# tolerant read but is still a descriptive string ("2 is a whole number and
# can be written as 2/1"), not a bare JSON number. Reusing the driver's own
# reader here (never a fresh heuristic) writes the exact number gate 3
# already verified, not a guess.
_pvd_spec = importlib.util.spec_from_file_location(
    "pvd", REPO / "scripts" / "coverage" / "propose_verify_driver.py")
pvd = importlib.util.module_from_spec(_pvd_spec)
_pvd_spec.loader.exec_module(pvd)

DEFAULT_LEDGER = REPO / "hermes/app/runtime/experiments/coverage_grind/merged_admitted_ledger.jsonl"
DEFAULT_TARGETS = [
    REPO / "hermes/app/runtime/experiments/coverage_grind/uncovered_targets.jsonl",
    REPO / "hermes/app/runtime/experiments/coverage_grind/retry_targets.jsonl",
]
DEFAULT_OUTPUT = REPO / "knowledge/strategies/abstraction/model_analysis_pilot.pl"

HELD_TIER = "oracle_mismatched_held"
STORED_TIERS = ("oracle_matched", "unoracled_executable")

# Every step-operation string this script has observed in the ledger, and
# the arithmetic symbol the check predicate treats it as: read off the
# ledger itself as merges land, most recently the 2026-08-18 recovery merge
# (3,640 rows, 760 admitted, 1,274 stored steps), which added one new
# claim-verdict form beside compare_equal: compare_less_equal, admitted
# under the same substring rule propose_verify_driver.py's gate 3 already
# used for compare_equal (any "compare"/"equal"/"verify"/"check" operation
# name is treated as an equality claim on its two operands, so the check
# predicate mirrors that rather than re-deriving a stricter comparison the
# admission gate never asked for). A future ledger row carrying an
# operation string outside this list is not silently coerced — the check
# predicate's op_symbol/2 simply will not match it, and check_stored_row/6
# throws step_not_reproduced naming the row, so a new verbatim operation
# name surfaces as a loud failure, not a guess.
STATIC_PROLOG = '''\
:- encoding(utf8).
/** <module> Attributed store for coverage-grind model-authored problem analyses
 *
 * Nothing imports this module; rows are vetoable one by one; admission to
 * anything canonical happens only by ceremony.
 *
 * scripts/coverage/propose_verify_driver.py asks a small local model to
 * analyze one IM story problem into quantities (each anchored to a verbatim
 * substring of the problem), a restated ask, arithmetic steps, and an
 * answer. Five deterministic gates decide admission on the node and again
 * at collection (scripts/coverage/merge_and_regate.py replays every gate
 * locally before a row is trusted); nothing the model said becomes a row
 * here without surviving them. A gate-admitted row still carries an oracle
 * tier from gate 5: `oracle_matched` (the answer matches a known-correct
 * oracle value), `unoracled_executable` (no oracle exists to check
 * against, but the steps execute exactly to the stated answer), or
 * `oracle_mismatched_held` (the answer executes but disagrees with an
 * oracle that does exist — most often because the oracle itself answers an
 * intermediate sub-problem, the pattern this repo calls the Han 33/4
 * pattern). HELD-tier rows are excluded from this store and await
 * adjudication; scripts/coverage/build_model_analysis_store.py counts them
 * in model_analysis_held_excluded/1 rather than dropping them from sight.
 *
 * VOCABULARY DIVERSITY RULE. The model's own kind and operation vocabulary
 * — "unit_or_kind" on a quantity, "operation" on a step, "kind" on an
 * answer — is recorded verbatim as a quoted Prolog string, exactly as the
 * model wrote it, under the 2026-08-18 diversity-over-abstraction ruling.
 * "meters east of the camera" and "dollars per egg" sit beside "number"
 * unchanged; none of it is mapped onto this repository's canonical
 * quantity or operation vocabulary. Two model backends contributed rows —
 * a local llama-server on Big Red (`model('local')`) and REALLMS-hosted
 * gemma-4-31B-it (`model('gemma-4-31B-it')`) — and each row is attributed
 * to whichever one actually produced it.
 *
 * check_model_analysis_pilot/0 re-derives every stored row's arithmetic
 * independently: every step's operands and result are decoded into exact
 * SWI rationals through g8_quantity_input.pl's g8_quantity/2 (the same
 * decoder the six grade-8 pilots use; `rationalize/1` recovers the exact
 * decimal a JSON float like 0.00034 or 11.55 was written from, verified
 * against every distinct float the ledger contains at each rebuild), the
 * operation name is read through a hand-built table naming every operation
 * string this module has ever seen, and the folded result must equal the
 * stored result exactly — `=:=` on exact rationals, never `=~=` on floats.
 * The stored answer must equal ANY step's result, not only the last one —
 * verified live by im_defrag_c9877aaf92acf187936f38a6_1 (a divide-then-
 * verify-by-multiplying problem, tier unoracled_executable), whose answer
 * names an earlier step rather than its last one: the built store still
 * exercises the any-step-not-just-the-last rule this store's check shares
 * with propose_verify_driver.py's gate 3. Every stored statement sha is
 * re-hashed from the stored statement text and compared to the stored
 * anchor; every stored tier is checked against the two tiers this store
 * admits. Any failure throws, naming the row.
 *
 * Check from the repository root:
 * `swipl -q -l paths.pl -l knowledge/strategies/abstraction/model_analysis_pilot.pl -g model_analysis_pilot:check_model_analysis_pilot -t halt`
 *
{PROVENANCE}
 */

:- module(model_analysis_pilot,
          [ model_analysis_row/6,
            model_analysis_held_excluded/1,
            model_analysis_summary/1,
            check_model_analysis_pilot/0
          ]).

:- use_module(library(sha)).
:- use_module(strategies('abstraction/g8_quantity_input'), [ g8_quantity/2 ]).

:- dynamic model_analysis_row/6.

%! check_model_analysis_pilot is det.
%
%  Record ids are unique, every row's steps reproduce its answer under
%  exact rational arithmetic, every statement sha reproduces from the
%  stored statement text, and every tier is one this store admits.
check_model_analysis_pilot :-
    findall(Id, model_analysis_row(Id, _, _, _, _, _), Ids),
    sort(Ids, Unique),
    length(Ids, Count),
    length(Unique, Count),
    forall(model_analysis_row(Id, Text, Analysis, Anchor, Testimony, Receipt),
           check_stored_row(Id, Text, Analysis, Anchor, Testimony, Receipt)),
    format('model_analysis_pilot: all ~d row receipts passed~n', [Count]).

check_stored_row(Id, Text, Analysis, Anchor, Testimony, Receipt) :-
    Anchor = anchor(lesson(Lesson), grade(Grade), record_id(Id), statement_sha(Sha)),
    atom(Lesson), atom(Grade), atom(Sha),
    Testimony = testimony(model(_), backend(_), job(_), date(_), tier(Tier)),
    ( valid_stored_tier(Tier)
    -> true
    ;  throw(error(model_analysis_pilot(bad_tier(Id, Tier)), _))
    ),
    Receipt == receipt(swipl_test([steps_reproduce_answer, statement_sha_verified,
                                   tier_valid])),
    sha256_hex(Text, ComputedSha),
    ( ComputedSha == Sha
    -> true
    ;  throw(error(model_analysis_pilot(sha_mismatch(Id, ComputedSha, Sha)), _))
    ),
    Analysis = analysis(quantities(Qs), ask(_), steps(Steps), answer(AnswerValue, _),
                        missing_doing(_)),
    is_list(Qs),
    is_list(Steps),
    Steps \\== [],
    forall(member(step(Op, Operands, Result), Steps),
           ( verify_step(Op, Operands, Result)
           -> true
           ;  throw(error(model_analysis_pilot(step_not_reproduced(Id, Op, Operands, Result)), _))
           )),
    findall(R, member(step(_, _, R), Steps), Results),
    ( member(R2, Results), answer_matches(AnswerValue, R2)
    -> true
    ;  throw(error(model_analysis_pilot(answer_not_a_step_result(Id, AnswerValue, Results)), _))
    ).

%! valid_stored_tier(+Tier) is semidet.
%
%  Only the two tiers this store admits. oracle_mismatched_held rows never
%  reach model_analysis_row/6 in the first place (the builder excludes
%  them), so seeing that tier here would mean the builder's own exclusion
%  broke, not that the row is merely unwelcome.
valid_stored_tier(oracle_matched).
valid_stored_tier(unoracled_executable).

%! verify_step(+Operation, +Operands, +Result) is semidet.
%
%  A claim-verdict step (compare_equal) decodes both operands and compares
%  them for exact rational equality against the stored boolean result. An
%  arithmetic step decodes every operand, left-folds the named operation
%  across them exactly as propose_verify_driver.py's gate 3 does (operand
%  list order matters for - and /), and requires the fold to equal the
%  decoded stored result exactly.
verify_step(Op, [A, B], Result) :-
    claim_operation(Op),
    !,
    g8_quantity(A, RA),
    g8_quantity(B, RB),
    ( RA =:= RB -> Computed = true ; Computed = false ),
    Result == Computed.
verify_step(Op, Operands, Result) :-
    op_symbol(Op, Sym),
    Operands = [_ | Rest],
    Rest \\== [],
    maplist(g8_quantity, Operands, [RFirst | RRest]),
    foldl(apply_symbol(Sym), RRest, RFirst, Computed),
    g8_quantity(Result, Expected),
    Computed =:= Expected.

apply_symbol(+, B, A, R) :- R is A + B.
apply_symbol(-, B, A, R) :- R is A - B.
apply_symbol(*, B, A, R) :- R is A * B.
apply_symbol(/, B, A, R) :- B =\\= 0, R is A / B.
apply_symbol(^, B, A, R) :- integer(B), R is A ^ B.

%! op_symbol(+OperationString, -Symbol) is semidet.
%
%  Every verbatim arithmetic step-operation string the ledger contains,
%  read off the ledger itself as merges land, not invented ahead of it.
%  "addition_of_decimal_places" names a step that really does add two
%  decimal-place counts, so it maps to +, matching
%  propose_verify_driver.py's own OP_TABLE substring match on "addition".
op_symbol("addition", +).
op_symbol("add", +).
op_symbol("addition_of_decimal_places", +).
op_symbol("subtraction", -).
op_symbol("subtract", -).
op_symbol("-", -).
op_symbol("multiplication", *).
op_symbol("multiply", *).
op_symbol("*", *).
op_symbol("division", /).
op_symbol("divide", /).
op_symbol("exponentiation", ^).

%! claim_operation(+OperationString) is semidet.
%
%  Claim-verdict operation strings the ledger contains. Both compare a
%  step's two operands for exact equality and check the claimed boolean
%  against that — compare_less_equal is not decoded as a genuine <=, it is
%  admitted under propose_verify_driver.py gate 3's own substring rule
%  (any operation name containing "compare"/"equal"/"verify"/"check" is
%  read as an equality claim), and this predicate mirrors that reading
%  rather than inventing a stricter comparison the admission gate never
%  applied.
claim_operation("compare_equal").
claim_operation("compare_less_equal").

%! answer_matches(+AnswerValue, +StepResult) is semidet.
%
%  A boolean answer must meet an identical boolean step result; a numeric
%  answer must meet a numeric step result at exact rational equality. A
%  boolean is never compared to a number or vice versa.
answer_matches(true, R) :- !, R == true.
answer_matches(false, R) :- !, R == false.
answer_matches(V, R) :-
    R \\== true, R \\== false,
    g8_quantity(V, RV),
    g8_quantity(R, RR),
    RV =:= RR.

%! sha256_hex(+Text, -HexAtom) is det.
%
%  The same digest scripts/coverage/build_model_analysis_store.py takes
%  over the UTF-8 bytes of the statement text, so a stored sha anchors a
%  row to the exact bytes the model read rather than a re-typed
%  approximation.
sha256_hex(Text, Atom) :-
    text_to_string(Text, String),
    sha_hash(String, Hash, [algorithm(sha256), encoding(utf8)]),
    hash_atom(Hash, Atom).

%! model_analysis_summary(-Summary) is det.
model_analysis_summary(summary(row_count(RowCount), held_excluded(HeldCount),
                               by_tier(TierPairs), by_grade(GradePairs))) :-
    aggregate_all(count, model_analysis_row(_, _, _, _, _, _), RowCount),
    model_analysis_held_excluded(HeldCount),
    by_tier_counts(TierPairs),
    by_grade_counts(GradePairs).

by_tier_counts(Pairs) :-
    findall(T, model_analysis_row(_, _, _, _, testimony(_, _, _, _, tier(T)), _), Ts),
    sort(Ts, Tiers),
    findall(T-N,
           ( member(T, Tiers),
             aggregate_all(count,
                           model_analysis_row(_, _, _, _, testimony(_, _, _, _, tier(T)), _),
                           N)
           ),
           Pairs).

by_grade_counts(Pairs) :-
    findall(G, model_analysis_row(_, _, _, anchor(_, grade(G), _, _), _, _), Gs),
    sort(Gs, Grades),
    findall(G-N,
           ( member(G, Grades),
             aggregate_all(count,
                           model_analysis_row(_, _, _, anchor(_, grade(G), _, _), _, _),
                           N)
           ),
           Pairs).

'''


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def pl_string(text: str) -> str:
    """A Prolog double-quoted string literal for arbitrary model-authored text."""
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def pl_atom(text: str) -> str:
    """A Prolog single-quoted atom literal for a structured identifier."""
    escaped = text.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{escaped}'"


def pl_number(value) -> str:
    """A Prolog numeral literal reproducing the JSON value exactly.

    Ints render as plain integers. Floats render via repr(), which for a
    Python float sourced from json.loads is the shortest decimal string
    that round-trips to the same float — the same text the JSON literal
    itself carried, verified at introduction against SWI's rationalize/1
    over every distinct float the ledger held at the time (see the module
    docstring in STATIC_PROLOG); check_model_analysis_pilot/0 re-verifies
    every float the ledger holds at each rebuild, not just that first set.
    """
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        return repr(value)
    raise TypeError(f"not a JSON number/bool: {value!r}")


def coerce_admitted_number(value):
    """A step operand/result or answer value as gate 3 actually read it.

    gate3_execution reads every step operand/result and answer value through
    _normalize_scalar (unwrap {"value": x} nesting, or extract the single
    number a descriptive string carries) before to_fraction. Most rows carry
    a plain JSON number already, in which case this is a no-op; a minority
    (the 2026-08-18 tolerant-parsing retry lane) carry the model's original
    descriptive string, which this re-derives to the same Fraction gate 3
    verified and renders as an int or float rather than fabricating a guess.
    """
    if isinstance(value, bool) or isinstance(value, (int, float)):
        return value
    frac = pvd.to_fraction(pvd._normalize_scalar(value))
    if frac is None:
        raise ValueError(f"cannot re-derive a number gate 3 already verified: {value!r}")
    return int(frac) if frac.denominator == 1 else float(frac)


def render_quantity(q: dict) -> str:
    value = pl_number(q["value"])
    kind = pl_string(str(q.get("unit_or_kind", "")))
    span = pl_string(str(q.get("verbatim_span", "")))
    return f"quantity({value}, {kind}, {span})"


def render_step(s: dict) -> str:
    op = pl_string(str(s["operation"]))
    operands = ", ".join(pl_number(coerce_admitted_number(o)) for o in s["operands"])
    result = pl_number(coerce_admitted_number(s["result"]))
    return f'step({op}, [{operands}], {result})'


def render_analysis(a: dict) -> str:
    quantities = ", ".join(render_quantity(q) for q in a.get("quantities", []))
    ask = pl_string(str(a.get("ask", "")))
    steps = ", ".join(render_step(s) for s in a.get("steps", []))
    answer = a.get("answer") or {}
    answer_raw = answer.get("value")
    answer_value = pl_number(
        answer_raw if isinstance(answer_raw, bool) else coerce_admitted_number(answer_raw))
    answer_kind = pl_string(str(answer.get("kind", "")))
    md = a.get("missing_doing")
    missing_doing = pl_string(str(md)) if md is not None else "null"
    return (
        "analysis(\n"
        f"        quantities([{quantities}]),\n"
        f"        ask({ask}),\n"
        f"        steps([{steps}]),\n"
        f"        answer({answer_value}, {answer_kind}),\n"
        f"        missing_doing({missing_doing}))"
    )


def render_row(row: dict, statement_text: str) -> str:
    record_id = row["record_id"]
    lesson = row["lesson"]
    grade = row["grade"]
    tier = row["tier"]
    testimony = row["testimony"]
    sha = sha256_text(statement_text)

    text_literal = pl_string(statement_text)
    analysis_literal = render_analysis(row["analysis"])
    anchor = (
        f"anchor(lesson({pl_atom(lesson)}), grade({pl_atom(grade)}), "
        f"record_id({pl_atom(record_id)}), statement_sha({pl_atom(sha)}))"
    )
    testimony_literal = (
        f"testimony(model({pl_atom(testimony['model'])}), "
        f"backend({pl_atom(testimony['backend'])}), "
        f"job(source_file({pl_atom(row['collected_from'])})), "
        f"date({pl_atom(testimony['date'])}), "
        f"tier({tier}))"
    )
    receipt = "receipt(swipl_test([steps_reproduce_answer, statement_sha_verified, tier_valid]))"

    return (
        f"model_analysis_row({pl_atom(record_id)}, {text_literal},\n"
        f"    {analysis_literal},\n"
        f"    {anchor},\n"
        f"    {testimony_literal},\n"
        f"    {receipt})."
    )


def load_jsonl(path: Path) -> list[dict]:
    rows = []
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                rows.append(json.loads(line))
    return rows


def build(ledger_path: Path, targets_paths: list[Path], output_path: Path) -> dict:
    ledger_rows = load_jsonl(ledger_path)
    admitted = [r for r in ledger_rows if r.get("gate") == "admitted"]

    stored_rows = [r for r in admitted if r.get("tier") != HELD_TIER]
    held_rows = [r for r in admitted if r.get("tier") == HELD_TIER]

    for r in stored_rows:
        if r.get("tier") not in STORED_TIERS:
            raise ValueError(f"record {r['record_id']} has unrecognized tier {r.get('tier')!r}")

    statements: dict[str, str] = {}
    for tp in targets_paths:
        if not tp.exists():
            continue
        for t in load_jsonl(tp):
            statements.setdefault(t["record_id"], t["statement"])

    missing = [r["record_id"] for r in stored_rows if r["record_id"] not in statements]
    if missing:
        raise KeyError(
            "no statement text found (in "
            + ", ".join(str(p) for p in targets_paths)
            + f") for {len(missing)} admitted record_id(s), e.g. {missing[:5]!r}. "
            "Refusing to guess a substitute; extend --targets or regenerate "
            "the targets files before re-running the builder."
        )

    stored_rows_sorted = sorted(stored_rows, key=lambda r: r["record_id"])

    provenance_lines = [" * PROVENANCE (content shas, not timestamps):"]
    provenance_lines.append(f" *   ledger  sha256={sha256_file(ledger_path)}  ({ledger_path.relative_to(REPO)})")
    for tp in targets_paths:
        if tp.exists():
            provenance_lines.append(f" *   targets sha256={sha256_file(tp)}  ({tp.relative_to(REPO)})")
    provenance = "\n".join(provenance_lines)

    rendered_rows = [render_row(r, statements[r["record_id"]]) for r in stored_rows_sorted]

    header = STATIC_PROLOG.format(PROVENANCE=provenance)
    generated_banner = (
        "% GENERATED ROWS FOLLOW. Do not edit by hand; re-run\n"
        "% scripts/coverage/build_model_analysis_store.py. Source: the "
        f"{len(admitted)} gate==\"admitted\" rows of\n"
        f"% {ledger_path.relative_to(REPO)},\n"
        f"% minus {len(held_rows)} tier==\"{HELD_TIER}\" rows held for adjudication "
        "(counted below, not stored).\n"
        f"% {len(stored_rows_sorted)} rows follow, sorted by record_id.\n\n"
        f"model_analysis_held_excluded({len(held_rows)}).\n\n"
    )

    body = "\n\n".join(rendered_rows)
    content = header + "\n" + generated_banner + body + "\n"

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")

    return {
        "ledger_rows": len(ledger_rows),
        "admitted": len(admitted),
        "stored": len(stored_rows_sorted),
        "held_excluded": len(held_rows),
        "output": str(output_path),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    ap.add_argument("--targets", type=Path, nargs="+", default=DEFAULT_TARGETS)
    ap.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = ap.parse_args()

    if not args.ledger.exists():
        print(f"missing ledger: {args.ledger}")
        return 2

    stats = build(args.ledger, args.targets, args.output)
    print(json.dumps(stats, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
