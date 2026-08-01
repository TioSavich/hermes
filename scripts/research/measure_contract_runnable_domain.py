import json, subprocess, collections

STRATS=["borrow_without_reducing_bases","smaller_from_larger_in_column",
        "borrow_across_zero_cascade","borrow_across_zero_no_cascade",
        "drop_ones_after_base_takeaway","slide_subtrahend_only",
        "add_instead_of_subtract_column","column_addition_with_carrying",
        "drop_carry_to_next_column","append_column_sum_without_carrying",
        "wrong_carry_amount_to_next_column","long_division",
        "add_instead_of_multiply","drop_second_partial_product"]
reqs=[];meta=[]
i=0
for s in STRATS:
    for a in range(1,100):
        for b in range(1,100):
            i+=1
            reqs.append(json.dumps({"id":f"r{i}","op":"strategy_trace","strategy":s,"input":{"a":a,"b":b}}))
            meta.append(s)
p=subprocess.run(["swipl","-q","-g","worker_main","-t","halt","hermes_worker.pl"],
    input="\n".join(reqs)+"\n",capture_output=True,text=True,timeout=3600)
lines=[l for l in p.stdout.splitlines() if l.strip().startswith("{")]
ran=collections.Counter(); ref=collections.Counter()
for l,s in zip(lines,meta):
    try: o=json.loads(l)
    except: continue
    if o.get("ok") and o.get("result",{}).get("ok"): ran[s]+=1
    else: ref[s]+=1
print(f"declared contract for every row below: {{'a':'integer','b':'integer'}}   swept a,b in 1..99 = 9801 inputs each")
print(f"{'automaton':<42} {'runs':>6} {'refuses':>8} {'runnable share':>15}")
print("-"*75)
for s in STRATS:
    tot=ran[s]+ref[s]
    print(f"{s:<42} {ran[s]:>6} {ref[s]:>8} {100*ran[s]/tot if tot else 0:>14.1f}%")
