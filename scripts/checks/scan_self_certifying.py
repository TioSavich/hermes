#!/usr/bin/env python3
"""Static scan: outcomes whose expected/1 shares the result/1 variable.

A row like `result(Result), ... expected(Result)` makes validity(correct)
true by construction: if the computation is wrong, the outcome still
reports result == expected. Layer 1 of audit_purported_validity.pl can
never catch these; layer 2 (independent ground truth) is the check that
can. This scan lists them so the truth-adapter work list is explicit.

Run from the repo root: python3 scripts/checks/scan_self_certifying.py
(or wherever it lands; it looks for knowledge/strategies/math/*.pl
relative to the repo root it is given or the cwd).
"""
import re, glob, sys, collections

root = sys.argv[1] if len(sys.argv) > 1 else "."
selfcert = collections.defaultdict(set)
indep = collections.defaultdict(set)
for path in glob.glob(f"{root}/knowledge/strategies/math/*.pl"):
    text = open(path, encoding="utf-8", errors="replace").read()
    for m in re.finditer(r"action_outcome\(\s*([a-z_0-9]+)\s*,", text):
        kind = m.group(1)
        window = text[m.end():m.end() + 1500]
        rm = re.search(r"result\(([A-Z_][A-Za-z0-9_]*)\)\s*,", window)
        em = re.search(r"expected\(([A-Z_][A-Za-z0-9_]*)\)\s*,?", window)
        if rm and em:
            bucket = selfcert if rm.group(1) == em.group(1) else indep
            bucket[path.split("/")[-1]].add(kind)

total = sum(len(v) for v in selfcert.values())
print(f"self-certifying expected(Result) rows: {total} kinds")
for f, kinds in sorted(selfcert.items()):
    print(f"  {f}: {len(kinds)}: {', '.join(sorted(kinds))}")
print(f"independent expected variable: {sum(len(v) for v in indep.values())} kinds")
