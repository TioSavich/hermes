# What Hermes computes

This repository encodes children's arithmetic strategies, meaning the ways children carry out arithmetic, as small machines. Each machine enacts one doing step by step. Some enact correct strategies, and some enact documented wrong strategies. The repository also checks what each computed answer is worth: correct, incorrect, or correct only on a particular input.

## The structure is explicit

An **action automaton** is a small machine whose current state determines which action comes next. This command loads the generated addition transition table and asks for the tuple and static transition rows for `count_on_from_larger`.

```console
$ swipl -q -l knowledge/strategies/transition_tables/addition.pl -g "automaton_tuple(addition,count_on_from_larger,States,Actions,Start,Accepting),format('~q.~n',[automaton_tuple(addition,count_on_from_larger,States,Actions,Start,Accepting)]),forall(automaton_transition(addition,count_on_from_larger,From,Action,To,provenance(static(Source))),format('~q.~n',[automaton_transition(addition,count_on_from_larger,From,Action,To,provenance(static(Source)))]))" -t halt
automaton_tuple(addition,count_on_from_larger,states([q_start,q_step_1,q_step_2,q_step_3,q_accept]),actions([choose_larger_addend_as_start,hold_other_addend_as_count,iterate_successor_ticks,name_last_tick_as_sum]),start(q_start),accepting([q_accept])).
automaton_transition(addition,count_on_from_larger,q_start,choose_larger_addend_as_start,q_step_1,provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:65'))).
automaton_transition(addition,count_on_from_larger,q_step_1,hold_other_addend_as_count,q_step_2,provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:65'))).
automaton_transition(addition,count_on_from_larger,q_step_2,iterate_successor_ticks,q_step_3,provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:65'))).
automaton_transition(addition,count_on_from_larger,q_step_3,name_last_tick_as_sum,q_accept,provenance(static('knowledge/strategies/math/sar_add_action_pairs.pl:65'))).
```

`states` lists the named positions the machine can occupy.

`actions` lists the moves the machine can take.

`start(q_start)` names the initial state.

`accepting([q_accept])` names the state in which the doing is complete.

Each transition row gives the arithmetic family, machine name, state before the move, enacted action, state after the move, and **provenance**, meaning the source location from which the row was generated.

## A correct doing: count on from the larger addend

The public route is the stdio interface exposed by `hermes.mcp.server.HermesMCPServer`. The input was:

```json
{"strategy":"count_on_from_larger","input":{"a":47,"b":28}}
```

The exact request and live response were:

```console
$ printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"count_on_from_larger","input":{"a":47,"b":28}}}}' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool
...
        "structuredContent": {
            ...
            "ok": true,
            "representation": "action_automaton",
            "result": "75",
            "steps": [
                {
                    "label": "choose_larger_addend_as_start(47)",
                    "n": 1,
                    "value": ""
                },
                {
                    "label": "hold_other_addend_as_count(28)",
                    "n": 2,
                    "value": ""
                },
                {
                    "label": "iterate_successor_ticks([48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75])",
                    "n": 3,
                    "value": ""
                },
                {
                    "label": "name_last_tick_as_sum(75)",
                    "n": 4,
                    "value": ""
                }
            ],
            "strategy": "count_on_from_larger"
        }
...
```

Step 1 chooses 47 because it is the larger addend.

Step 2 holds 28 as the number of counts still to make.

Step 3 generates the 28 successors from 48 through 75.

Step 4 names the last count, 75, as the sum.

The machine does not return only `75`. It records the counting-on moves that produced `75`.

## A documented wrong doing, and when it is not diagnostic

A **deformation** is a machine for a documented wrong doing. `stop_after_first_partial_quotient` divides by one large chunk and then stops before using the remainder. On 96 divided by 4, the input was:

```json
{"strategy":"stop_after_first_partial_quotient","input":{"a":96,"b":4}}
```

The live public trace was:

```console
$ printf '%s\n' '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"stop_after_first_partial_quotient","input":{"a":96,"b":4}}}}' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool
...
        "structuredContent": {
            ...
            "ok": true,
            "representation": "action_automaton",
            "result": "quotient_remainder(10,56)",
            "steps": [
                {
                    "label": "set_divisor_as_chunk_unit(4)",
                    "n": 1,
                    "value": ""
                },
                {
                    "label": "choose_first_partial_multiple(40,10)",
                    "n": 2,
                    "value": ""
                },
                {
                    "label": "subtract_first_partial_multiple(56)",
                    "n": 3,
                    "value": ""
                },
                {
                    "label": "stop_before_recomposing_remaining_total(56)",
                    "n": 4,
                    "value": ""
                },
                {
                    "label": "name_incomplete_partial_quotient(quotient_remainder(10,56))",
                    "n": 5,
                    "value": ""
                },
                {
                    "label": "lose_partial_quotient_recomposition(expected(quotient_remainder(24,0)),produced(quotient_remainder(10,56)))",
                    "n": 6,
                    "value": ""
                }
            ],
            "strategy": "stop_after_first_partial_quotient"
        }
...
```

The machine chooses 40 as ten groups of 4, subtracts that chunk from 96, and leaves 56. It stops instead of dividing the 56 and reports `quotient_remainder(10,56)`. The complete result is `quotient_remainder(24,0)`.

The repository's coincidence ledger supplies `(3,2)` as an input where this same wrong doing happens to return the right quotient and remainder:

```console
$ rg -n '^coincidence_profile\(division, stop_after_first_partial_quotient' knowledge/strategies/deformation_coincidence.pl
95:coincidence_profile(division, stop_after_first_partial_quotient, deformation, ran(612), coincide(192), rate_pct(31), purport_violations(192), sample_coincide(some(3,2)), sample_separate(some(3,1)), sample_violation(some(3,2,claimed_incorrect_but_right))).
```

Here is the public trace for that coincident input:

```console
$ printf '%s\n' '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"stop_after_first_partial_quotient","input":{"a":3,"b":2}}}}' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool
...
        "structuredContent": {
            ...
            "ok": true,
            "representation": "action_automaton",
            "result": "quotient_remainder(1,1)",
            "steps": [
                {
                    "label": "set_divisor_as_chunk_unit(2)",
                    "n": 1,
                    "value": ""
                },
                {
                    "label": "choose_first_partial_multiple(2,1)",
                    "n": 2,
                    "value": ""
                },
                {
                    "label": "subtract_first_partial_multiple(1)",
                    "n": 3,
                    "value": ""
                },
                {
                    "label": "stop_before_recomposing_remaining_total(1)",
                    "n": 4,
                    "value": ""
                },
                {
                    "label": "name_incomplete_partial_quotient(quotient_remainder(1,1))",
                    "n": 5,
                    "value": ""
                },
                {
                    "label": "lose_partial_quotient_recomposition(expected(quotient_remainder(1,1)),produced(quotient_remainder(1,1)))",
                    "n": 6,
                    "value": ""
                }
            ],
            "strategy": "stop_after_first_partial_quotient"
        }
...
```

The audit exposes the machine's `validity` field and independently decides whether each input separates the deformation from correct division. `qr` is the audit's normalized notation for a quotient and remainder.

```console
$ swipl -q -l paths.pl -l scripts/checks/audit_purported_validity.pl -g "forall(member(input(A,B),[input(96,4),input(3,2)]),(audit_purported_validity:run_action_automaton(division,stop_after_first_partial_quotient,A,B,action_outcome(_,Fields),_),memberchk(result(Result),Fields),memberchk(expected(Expected),Fields),memberchk(validity(Validity),Fields),format('input(~w,~w): result=~q expected=~q validity=~w~n',[A,B,Result,Expected,Validity]),(audit_purported_validity:deformation_separates_on(division,stop_after_first_partial_quotient,input(A,B),Evidence)->format('deformation_separates_on: true ~q~n',[Evidence]);writeln('deformation_separates_on: false'))))" -t halt
input(96,4): result=quotient_remainder(10,56) expected=quotient_remainder(24,0) validity=incorrect
deformation_separates_on: true evidence(result(qr(10,56)),truth(qr(24,0)))
input(3,2): result=quotient_remainder(1,1) expected=quotient_remainder(1,1) validity=incorrect
deformation_separates_on: false
```

The diagnostic rule is strict: never accuse a student of this doing on an input where the doing gives the right answer. On `(3,2)`, the wrong procedure and correct division produce the same result, so this input cannot distinguish them.

## What the structured-input work bought today

Before today's structured-operand decoder, the public door spoke only bare numbers. Geometry objects and data lists could not reach these machines through `strategy_trace`. The live contract calls its rectangle tag `rectangle_with_unit`; the payload carries the rectangle's length, width, and unit.

This request traverses all four sides of a 7-by-4 rectangle:

```console
$ printf '%s\n' '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"rectangle_perimeter_boundary_traversal","input":{"kind":"rectangle_with_unit","length":7,"width":4,"unit":"centimeter"}}}}' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool
...
        "structuredContent": {
            ...
            "ok": true,
            "representation": "action_automaton",
            "result": "length(22,centimeter)",
            "steps": [
                {
                    "label": "establish_rectangle(7,4)",
                    "n": 1,
                    "value": ""
                },
                {
                    "label": "traverse_side(length,7)",
                    "n": 2,
                    "value": ""
                },
                {
                    "label": "traverse_side(width,4)",
                    "n": 3,
                    "value": ""
                },
                {
                    "label": "traverse_opposite_side(length,7)",
                    "n": 4,
                    "value": ""
                },
                {
                    "label": "traverse_opposite_side(width,4)",
                    "n": 5,
                    "value": ""
                },
                {
                    "label": "accumulate_boundary_length(22,centimeter)",
                    "n": 6,
                    "value": ""
                }
            ],
            "strategy": "rectangle_perimeter_boundary_traversal"
        }
...
```

This request preserves a list of five measurements, totals them, counts them, and redistributes the total equally:

```console
$ printf '%s\n' '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"mean_as_fair_share","input":{"kind":"numeric_data_with_unit","values":[2,4,4,6,9],"unit":"minutes"}}}}' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool
...
        "structuredContent": {
            ...
            "ok": true,
            "representation": "action_automaton",
            "result": "rational(5,1)",
            "steps": [
                {
                    "label": "preserve_data_set([2,4,4,6,9])",
                    "n": 1,
                    "value": ""
                },
                {
                    "label": "collect_total(25)",
                    "n": 2,
                    "value": ""
                },
                {
                    "label": "count_values(5)",
                    "n": 3,
                    "value": ""
                },
                {
                    "label": "redistribute_total_equally(rational(5,1))",
                    "n": 4,
                    "value": ""
                }
            ],
            "strategy": "mean_as_fair_share"
        }
...
```

The first computation returns a perimeter of 22 centimeters. The second returns the mean 5 minutes. Both results come with the enacted operations over the structured inputs.

## The guard refuses a formerly fatal input

`make_base_transfer` moves enough from one addend to bring the other to the next multiple of ten. The input `(1,3)` cannot supply the required transfer. It previously drove the worker into a C-stack overflow. The same public route now returns a bounded `not_covered` refusal and exits normally in 2.50 seconds, including worker startup:

```console
$ /usr/bin/time -p sh -c 'printf "%s\n" '\''{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"make_base_transfer","input":{"a":1,"b":3}}}}'\'' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool' 2>&1
{
    "jsonrpc": "2.0",
    "id": 7,
    "error": {
        "code": -32000,
        ...
        "data": {
            "kind": "not_covered",
            ...
        }
    }
}
real 2.50
user 2.41
sys 0.12
```

Its ordinary contracted example still traces:

```console
$ printf '%s\n' '{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"strategy_trace","arguments":{"strategy":"make_base_transfer","input":{"a":47,"b":28}}}}' | python3 -m hermes.mcp.server --mode core | python3 -m json.tool
...
        "structuredContent": {
            ...
            "ok": true,
            "representation": "action_automaton",
            "result": "75",
            "steps": [
                {
                    "label": "order_addends(larger(47),smaller(28))",
                    "n": 1,
                    "value": ""
                },
                {
                    "label": "identify_target_base(47,10,50)",
                    "n": 2,
                    "value": ""
                },
                {
                    "label": "count_distance_to_base(47,50,3)",
                    "n": 3,
                    "value": ""
                },
                {
                    "label": "transfer_from_smaller_to_larger(3,28,25)",
                    "n": 4,
                    "value": ""
                },
                {
                    "label": "preserve_total_by_balanced_transfer(50,25,75)",
                    "n": 5,
                    "value": ""
                }
            ],
            "strategy": "make_base_transfer"
        }
...
```

The machine orders 47 and 28, finds that 47 is 3 short of 50, transfers 3 from 28, and adds 50 and 25 without changing the total.

## The execution ledger

An input **contract** records the JSON shape and verified example for one registered machine. The contract checker reran every example through the same live strategy route:

```console
$ python3 scripts/checks/automaton_input_contracts.py
automaton-input-contracts: contracts=219 registered-signatures=219 remaining-gap=0 verified-live=219
```

The validity audit then checked the declared result against each machine's expected result. Its second layer used independent arithmetic adapters where they exist rather than trusting the machine's own expected field.

```console
$ swipl -q -l paths.pl -l scripts/checks/audit_purported_validity.pl -g audit_purported_validity:audit -t halt
AUDIT: purported vs computed validity, one contract example per kind

contracted kinds audited: 219
  claim holds on execution:      216
  PURPORT BROKEN:                0
  purports validity, no expected: 0
  did not run / errored:         0
  nonstandard / not auditable:    3

--- nonstandard validity categories ---
  accidentally_correct, per-input claim consistent: 3

--- coverage gap: registered kinds with NO contract (not yet auditable) ---
  total: 0 of 219 registered kinds

=== LAYER 2: independent ground truth (catches self-certifying rows) ===
rows with executable outcome: 221
  truth check passes:                        76
  WRONG while purporting correct:            0
  RIGHT while purporting incorrect (example fails to witness the bug): 0
  no truth adapter for family/shape yet:     119
  result shape not yet normalizable:         26
  validity atom not auditable:                0
```

The contract line means every registered kind has an input contract and ran live on its verified example. The audit means every validity claim among those contracted kinds survived execution, while the independent layer separately counts 119 cases without a truth adapter and 26 result shapes it cannot yet normalize rather than treating those cases as independently verified.

## Why this is useful

A tutor or diagnostic tool can use these machines to test which doing produced a student's answer. It can also refuse to name a wrong doing when the input does not separate that doing from correct work. Recognition from a student's words or written work is a separate hard problem. This document demonstrates only the enactment and checking layer.
