#!/usr/bin/env python3
"""q424_partition_check.py — INDEPENDENT check that a set of child CNFs is an exact partition of a
parent CNF's models, by SYNTACTIC witnesses only (no solver, no trust in the generator):

  1. parent P contains clause C = (l_1 v ... v l_k)                 -> exhaustive
  2. parent P contains (~l_i v ~l_j) for every pair i<j              -> exclusive
  3. child_i is byte-for-byte  P's lines + one line "l_i 0", with the header clause count +1,
     and the set {l_i} over the children is exactly the literal set of C.
  4. (optional) results.tsv: every child has a certified verdict, and the certified counts sum to
     the parent's expected count.

usage: q424_partition_check.py <parent.cnf> <witness_clause_index_1based> <childdir> [results.tsv expected]
Prints PARTITION_CHECK=PASS|FAIL as a whole line.
"""
import sys, os, glob

def read(p):
    lines = open(p).read().split("\n")
    if lines and lines[-1] == "": lines.pop()
    hdr = lines[0].split(); assert hdr[:2] == ["p", "cnf"], p
    body = lines[1:]
    assert len(body) == int(hdr[3]), (p, len(body), hdr)
    return int(hdr[2]), body

def clause(line):
    t = line.split(); assert t[-1] == "0", line
    return tuple(int(x) for x in t[:-1])

def fail(msg):
    print("PARTITION_FAIL_REASON=" + msg); print("PARTITION_CHECK=FAIL"); sys.exit(1)

parent, widx, childdir = sys.argv[1], int(sys.argv[2]), sys.argv[3]
nv, pbody = read(parent)
pset = set(clause(l) for l in pbody)
C = clause(pbody[widx - 1])
if len(C) < 2: fail("witness clause too short")
# 1. exhaustive: C is literally a clause of P (it is: we took it from P's body)
# 2. exclusive: every pair excluded by a binary clause of P (either literal order)
for i in range(len(C)):
    for j in range(i + 1, len(C)):
        if (-C[i], -C[j]) not in pset and (-C[j], -C[i]) not in pset:
            fail("no exclusion clause for pair %d %d" % (C[i], C[j]))
# 3. children: exactly P + one unit per literal of C
seen = {}
for f in sorted(glob.glob(os.path.join(childdir, "*.cnf"))):
    cv, cbody = read(f)
    if cv != nv or len(cbody) != len(pbody) + 1: fail("shape %s" % f)
    if cbody[:-1] != pbody: fail("body differs %s" % f)
    u = clause(cbody[-1])
    if len(u) != 1 or u[0] not in C or u[0] in seen: fail("unit %s in %s" % (u, f))
    seen[u[0]] = os.path.basename(f)[:-4]
if set(seen) != set(C): fail("children cover %d of %d literals" % (len(seen), len(C)))
print("PARTITION_WITNESS clause#%d k=%d children=%d" % (widx, len(C), len(seen)))
# 4. certified counts
if len(sys.argv) > 5:
    res, expected = sys.argv[4], int(sys.argv[5])
    got = {}
    for line in open(res):
        t = line.rstrip("\n").split("\t")
        if t[0] not in ("SAT", "UNSAT") or t[1] not in seen.values(): continue
        if t[-1] == "FULL_PROOF_SUCCESS_COUNT_MATCH": got[t[1]] = int(t[-2])
        elif t[-1] == "DRAT_VERIFIED_COUNT0": got[t[1]] = 0
        else: fail("uncertified child %s verdict %s" % (t[1], t[-1]))
    missing = set(seen.values()) - set(got)
    if missing: fail("no verdict for %s" % sorted(missing))
    s = sum(got.values())
    print("PARTITION_CERTIFIED_SUM=%d EXPECTED=%d" % (s, expected))
    if s != expected: fail("sum %d != expected %d" % (s, expected))
print("PARTITION_CHECK=PASS")
