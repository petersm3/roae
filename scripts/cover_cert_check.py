#!/usr/bin/env python3
"""cover_cert_check.py — SECOND, independent implementation of the structural side of the cover certificate
(Q-1092).  Shares no code with cover_cert_emit.py; rebuilds everything from the source CNF, the ledger and the
emitted files, and reads the Lean checker's verdict from its captured stdout.

Legs (each a whole-line token):
  COVER_HEADER    cover.cnf has F's variable count, exactly |F| + #LEAF clauses, and its first |F| clause lines
                  are byte-identical to F's clause lines in F's order (so clause#N of the ledger is clause id N).
  COVER_LEAVES    the clauses after F are, in ledger order, exactly the negated cubes of the ledger's LEAF rows
                  (as literal sets), the LEAF tags are unique, and every leaf clause id occurs as a hint in the LRAT.
  COVER_TREE      every non-root tag's parent (tag minus its last literal) is a SPLIT row; for every SPLIT row with
                  witness clause#N the set of children (SPLIT or LEAF tags one literal longer) is exactly
                  {parent units + l : l in clause N of F}, each l on a variable not in the parent's units; a
                  cube-varV witness has exactly the children +V and -V; no tag is both SPLIT and LEAF; the LEAF
                  rows are exactly the tags without children.
  COVER_DISJOINT  for every SPLIT with witness clause#N: every pair {a,b} of clause N is excluded by a binary
                  clause (-a v -b) literally in F, or (fallback) by a lemma clause {-a,-b} in cover.lrat — such
                  pairs are only accepted when COVER_LRAT_LEAN=VERIFIED, and are counted separately.
  COVER_LRAT_LEAN the whole-line verdict in the lratcheck stdout: VERIFIED only for exactly one line
                  `LRAT_LEAN=VERIFIED` and rc 0 (rc file), else REJECTED/ERROR/MISSING.
  COVER_CERT_<n>  PASS iff all of the above are PASS / VERIFIED.

usage: cover_cert_check.py --cnf F.cnf --ledger ledger.tsv[.gz] --dir COVERDIR --label n12
   COVERDIR holds cover.cnf, cover.lrat and (from the driver) lratcheck.out, lratcheck.rc.
"""
import argparse, gzip, os, re, sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cnf", required=True); ap.add_argument("--ledger", required=True)
    ap.add_argument("--dir", required=True); ap.add_argument("--label", required=True)
    a = ap.parse_args()
    out = []
    def tok(k, v, detail=""):
        out.append("%s=%s %s" % (k, v, detail)); print(out[-1])
        return v

    # ---- F --------------------------------------------------------------------------------------------------
    nvars = hdr = None; flines = []
    for raw in open(a.cnf):
        s = raw.rstrip("\n")
        if s.startswith("p cnf"):
            nvars, hdr = int(s.split()[2]), int(s.split()[3])
        elif s[:1] != "c" and s.strip():
            flines.append(s)
    assert nvars is not None and hdr == len(flines), "F header"
    F = [tuple(int(x) for x in l.split()[:-1]) for l in flines]
    m = len(F)
    binset = set()
    for c in F:
        if len(c) == 2:
            binset.add(frozenset(c))

    # ---- ledger ---------------------------------------------------------------------------------------------
    op = gzip.open if a.ledger.endswith(".gz") else open
    LEAF, SPLIT = [], {}
    split_order = []
    dup_split = 0
    for raw in op(a.ledger, "rt"):
        if not raw.strip():
            continue
        k, tag, x, y = raw.rstrip("\n").split("\t")
        if k == "LEAF":
            LEAF.append(tag)
        else:
            if tag in SPLIT:
                dup_split += 1
            SPLIT[tag] = x; split_order.append(tag)
    def units(tag):
        return () if tag == "proot" else tuple(int(p.replace("m", "-")) for p in tag[1:].split("_"))
    def mk(us):
        return "proot" if not us else "p" + "_".join(str(u).replace("-", "m") for u in us)

    # ---- cover.cnf -------------------------------------------------------------------------------------------
    cl = [l.rstrip("\n") for l in open(os.path.join(a.dir, "cover.cnf"))]
    chdr = cl[0].split(); cbody = [l for l in cl[1:] if l.strip()]
    ok_hdr = (chdr[:2] == ["p", "cnf"] and int(chdr[2]) == nvars and int(chdr[3]) == m + len(LEAF)
              and len(cbody) == m + len(LEAF) and cbody[:m] == flines)
    tok("COVER_HEADER", "PASS" if ok_hdr else "FAIL",
        "vars=%s/%d clauses=%s/%d F_lines_identical=%s" % (chdr[2], nvars, chdr[3], m + len(LEAF), cbody[:m] == flines))

    # ---- LRAT: parse lemmas (clause, hints) and collect every hint id ----------------------------------------
    lemmas = {}; all_hints = set(); lrat_ok = True; last_id = None
    for raw in open(os.path.join(a.dir, "cover.lrat")):
        t = raw.split()
        if not t:
            continue
        cid = int(t[0])
        if t[1] == "d":
            lrat_ok = False; continue                           # the tree proof never deletes
        z = t.index("0"); clause = tuple(int(x) for x in t[1:z]); hints = [int(x) for x in t[z + 1:-1]]
        if t[-1] != "0" or any(h <= 0 for h in hints):
            lrat_ok = False
        lemmas[cid] = (frozenset(clause), hints); all_hints.update(hints)
        last_id = cid
    lemma_sets = set(c for c, h in lemmas.values())

    # ---- leaves ----------------------------------------------------------------------------------------------
    leaf_sets = [frozenset(-u for u in units(t)) for t in LEAF]
    cover_leaf_sets = [frozenset(int(x) for x in l.split()[:-1]) for l in cbody[m:]]
    unique = len(set(LEAF)) == len(LEAF)
    hinted = all((m + 1 + i) in all_hints for i in range(len(LEAF)))
    sane = all(len(s) == len(units(t)) and all(abs(x) <= nvars and x != 0 for x in s) for s, t in zip(leaf_sets, LEAF))
    tok("COVER_LEAVES", "PASS" if (leaf_sets == cover_leaf_sets and unique and hinted and sane and len(LEAF) > 0) else "FAIL",
        "leaves=%d match_in_order=%s unique_tags=%s every_leaf_id_hinted=%s" % (len(LEAF), leaf_sets == cover_leaf_sets, unique, hinted))

    # ---- tree ------------------------------------------------------------------------------------------------
    children = {t: [] for t in SPLIT}
    bad_parent = []
    for t in LEAF + [s for s in split_order if s != "proot"]:
        us = units(t)
        p = mk(us[:-1]) if us else None
        if p is None or p not in SPLIT:
            bad_parent.append(t)
        else:
            children[p].append(t)
    both = set(LEAF) & set(SPLIT)
    tree_ok = not bad_parent and not both and dup_split == 0 and "proot" in SPLIT and lrat_ok
    bad_nodes = []
    for s in split_order:
        us = units(s); how = SPLIT[s]
        if how.startswith("clause#"):
            C = F[int(how[7:]) - 1]
            want = [us + (l,) for l in C]
        elif how.startswith("cube-var"):
            v = int(how[8:]); want = [us + (v,), us + (-v,)]
        else:
            bad_nodes.append((s, "witness " + how)); continue
        got = [units(c) for c in children[s]]
        if sorted(got) != sorted(want) or len(set(got)) != len(got):
            bad_nodes.append((s, "children %d vs clause %d" % (len(got), len(want)))); continue
        if any(abs(l) in {abs(u) for u in us} for l in [w[-1] for w in want]):
            bad_nodes.append((s, "split literal on an already-fixed variable"))
    leaves_are_childless = set(LEAF) == {t for t in LEAF + split_order if t not in children or not children[t]} - set(SPLIT)
    tree_ok = tree_ok and not bad_nodes and leaves_are_childless
    tok("COVER_TREE", "PASS" if tree_ok else "FAIL",
        "splits=%d bad_parent=%d both_leaf_and_split=%d dup_split=%d bad_nodes=%d lrat_wellformed=%s leaves_childless=%s%s"
        % (len(SPLIT), len(bad_parent), len(both), dup_split, len(bad_nodes), lrat_ok, leaves_are_childless,
           (" first_bad=" + repr(bad_nodes[0])) if bad_nodes else ""))

    # ---- Lean verdict -----------------------------------------------------------------------------------------
    lean = "MISSING"
    try:
        lines = [l.rstrip("\r\n") for l in open(os.path.join(a.dir, "lratcheck.out"))]
        rc = int(open(os.path.join(a.dir, "lratcheck.rc")).read().split()[0])
        v = [l for l in lines if l.startswith("LRAT_LEAN=")]
        if rc == 0 and len(v) == 1 and v[0] == "LRAT_LEAN=VERIFIED":
            lean = "VERIFIED"
        elif rc == 1 and v and v[-1] == "LRAT_LEAN=REJECTED":
            lean = "REJECTED"
        else:
            lean = "ERROR"
        detail = "rc=%d lines=%r" % (rc, v[:2])
    except (OSError, ValueError) as e:
        detail = repr(e)
    tok("COVER_LRAT_LEAN", lean, detail)

    # ---- disjointness ------------------------------------------------------------------------------------------
    in_f = by_lemma = missing = 0
    for s in split_order:
        how = SPLIT[s]
        if not how.startswith("clause#"):
            continue
        C = F[int(how[7:]) - 1]
        for i in range(len(C)):
            for j in range(i + 1, len(C)):
                pair = frozenset((-C[i], -C[j]))
                if pair in binset:
                    in_f += 1
                elif pair in lemma_sets and lean == "VERIFIED":
                    by_lemma += 1
                else:
                    missing += 1
    tok("COVER_DISJOINT", "PASS" if missing == 0 else "FAIL",
        "pairs_in_F=%d pairs_by_verified_lemma=%d pairs_missing=%d" % (in_f, by_lemma, missing))

    allok = all(l.split()[0].endswith(("=PASS", "=VERIFIED")) for l in out)
    root_empty = last_id is not None and lemmas[last_id][0] == frozenset()
    tok("COVER_ROOT_EMPTY_CLAUSE", "PASS" if root_empty else "FAIL", "last_lemma_id=%s" % last_id)
    allok = allok and root_empty
    print("COVER_CERT_%s=%s" % (a.label, "PASS" if allok else "FAIL"))
    return 0 if allok else 1


if __name__ == "__main__":
    sys.exit(main())
