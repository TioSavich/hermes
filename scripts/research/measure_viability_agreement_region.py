import json, subprocess, itertools, collections, re, time

fracs=[(n,d) for d in range(2,10) for n in range(1,d)]
def frac_pairs(kind):
    for (n1,d1),(n2,d2) in itertools.permutations(fracs,2):
        yield {"kind":kind,"left":{"n":n1,"d":d1},"right":{"n":n2,"d":d2}}, f"{n1}/{d1} vs {n2}/{d2}"
def dec_pairs(kind):
    for a in range(1,60):
        for sa in (10,100):
            for b in range(1,60):
                for sb in (10,100):
                    yield {"kind":kind,"left":{"numeral":a,"scale":sa},"right":{"numeral":b,"scale":sb}}, f"{a}/{sa} vs {b}/{sb}"
def ab():
    for a in range(1,41):
        for b in range(1,41):
            yield {"a":a,"b":b}, f"{a},{b}"

CASES=[
 ("gap_thinking_fraction_comparison", frac_pairs("fraction_pair")),
 ("add_numerator_denominator_sum",    frac_pairs("fraction_addend_pair")),
 ("decimal_numeral_comparison_without_scale_alignment", dec_pairs("decimal_pair")),
 ("decimal_add_unaligned_numerals",   dec_pairs("decimal_pair")),
 ("divide_larger_by_smaller",         ab()),
]

print(f"{'automaton':<52} {'ran':>6} {'refused':>8} {'agree':>7} {'diverge':>8}  agreement-region")
print("-"*105)
for strat, gen in CASES:
    reqs=[]; labs=[]
    for i,(inp,lab) in enumerate(gen):
        reqs.append(json.dumps({"id":f"r{i}","op":"strategy_trace","strategy":strat,"input":inp}))
        labs.append(lab)
    p=subprocess.run(["swipl","-q","-g","worker_main","-t","halt","hermes_worker.pl"],
        input="\n".join(reqs)+"\n",capture_output=True,text=True,timeout=1800)
    lines=[l for l in p.stdout.splitlines() if l.strip().startswith("{")]
    c=collections.Counter(); ex={}
    for l,lab in zip(lines,labs):
        try: o=json.loads(l)
        except: c["unparsed"]+=1; continue
        if not o.get("ok"): c["refused"]+=1; continue
        v=None
        for st in o.get("result",{}).get("steps",[]):
            m=re.search(r"validity\((\w+)\)",str(st.get("value",""))+" "+str(st.get("label","")))
            if m: v=m.group(1)
        if v is None: c["no_viability"]+=1
        else:
            c[v]+=1; ex.setdefault(v,lab)
    ok=c["contextually_correct"]+c["incorrect"]
    pct=f"{100*c['contextually_correct']/ok:.1f}%" if ok else "n/a"
    print(f"{strat:<52} {len(lines):>6} {c['refused']:>8} {c['contextually_correct']:>7} {c['incorrect']:>8}  {pct:>6}  e.g. agree={ex.get('contextually_correct','-')}")
    if c["no_viability"] or c["unparsed"]:
        print(f"{'':<52} (no_viability={c['no_viability']} unparsed={c['unparsed']})")
