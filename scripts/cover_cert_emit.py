#!/usr/bin/env python3
"""cover_cert_emit.py — emit the COVER CERTIFICATE of a decomposition tree (Q-1092).

Given the source CNF F (the formula whose model count was certified piecewise) and the run's
ledger.tsv (LEAF / SPLIT rows, decomp_certify_v3.py), write

  (i)  cover.cnf  =  F  ∧  ⋀_{leaf ℓ} ¬cube_ℓ        (F's clauses first, byte-identical, in file order;
                                                      then one clause per LEAF row, in ledger order)
  (ii) cover.lrat =  a tree-derived LRAT proof of UNSAT of cover.cnf: one RUP lemma per internal
                     (SPLIT) node v, clause ¬cube_v, hints = the clauses/lemmas of v's children followed
                     by v's split clause (clause#N of F); the root lemma is the empty clause.  Lemmas are
                     emitted in post-order, ids consecutive from (|F| + #leaves + 1).  A split witnessed
                     as `cube-varV` needs no split clause (its two children carry complementary literals).

cover.cnf UNSAT  <=>  every model of F satisfies some leaf cube  <=>  the leaves COVER the models of F.
The judge of (ii) is the formally verified LRAT checker shipped with Lean 4 (`lratcheck`, Std.Tactic.BVDecide.
LRAT.check + check_sound, scripts/lratcheck/); this script's own RUP simulation (EMIT_RUP_SIM) is a
convenience, not evidence.  Disjointness of the leaves is NOT part of (ii): it is checked syntactically by
cover_cert_check.py (every pair of a split clause excluded by a binary clause of F).  Where a pair is not
literally in F this script emits an AMO lemma (¬a ∨ ¬b) by unit propagation and records it in
amo_lemmas.tsv; cover_cert_check.py then accepts the pair only if lratcheck accepted the file.

Mutation controls (--mutant), applied to the in-memory ledger before emission, so the emitted certificate
is self-consistent but wrong — the checker must reject it:
    drop:TAG            remove LEAF TAG                      (a hole in the cover)
    dup:TAG             a second LEAF row for TAG            (double counting; the duplicate hint is satisfied)
    swaplit:TAG:NEW     replace the last literal of TAG's cube by literal NEW (sign flip: NEW = -old)

usage: cover_cert_emit.py --cnf F.cnf --ledger ledger.tsv[.gz] --out DIR [--mutant SPEC] [--expect-cnf-sha HEX]
Prints whole-line tokens EMIT_COVER=OK|FAIL, EMIT_RUP_SIM=PASS|FAIL|SKIP and a manifest (manifest.tsv).
"""
import argparse, gzip, hashlib, os, sys


def read_cnf_lines(path):
    """Return (nvars, header_count, clause_lines) with clause_lines the exact text lines of F (no comments)."""
    nvars = hdr_n = None
    lines = []
    with open(path) as f:
        for raw in f:
            line = raw.rstrip("\n")
            if line.startswith("p cnf"):
                t = line.split(); nvars, hdr_n = int(t[2]), int(t[3]); continue
            if line[:1] == "c" or not line.strip():
                continue
            lines.append(line)
    if nvars is None or len(lines) != hdr_n:
        raise SystemExit("EMIT_COVER=FAIL source CNF header/clause-count mismatch")
    return nvars, lines


def lits_of(line):
    t = line.split()
    if t[-1] != "0":
        raise SystemExit("EMIT_COVER=FAIL clause line without terminating 0: %r" % line)
    return [int(x) for x in t[:-1]]


def tag_units(tag):
    if tag == "proot":
        return ()
    if not tag.startswith("p"):
        raise SystemExit("EMIT_COVER=FAIL bad tag %r" % tag)
    return tuple(int(x.replace("m", "-")) for x in tag[1:].split("_"))


def units_tag(units):
    return "proot" if not units else "p" + "_".join(str(u).replace("-", "m") for u in units)


def read_ledger(path):
    op = gzip.open if path.endswith(".gz") else open
    leaves, splits = [], []          # lists of (tag, route, count) / (tag, witness); ledger order kept
    with op(path, "rt") as f:
        for raw in f:
            if not raw.strip():
                continue
            t = raw.rstrip("\n").split("\t")
            if len(t) != 4 or t[0] not in ("LEAF", "SPLIT"):
                raise SystemExit("EMIT_COVER=FAIL bad ledger row %r" % raw)
            if t[0] == "LEAF":
                leaves.append((t[1], t[2], int(t[3])))
            else:
                splits.append((t[1], t[2]))
    return leaves, splits


def apply_mutant(leaves, spec):
    kind, _, rest = spec.partition(":")
    if kind == "drop":
        n = len(leaves); leaves = [l for l in leaves if l[0] != rest]
        if len(leaves) != n - 1:
            raise SystemExit("EMIT_COVER=FAIL mutant drop: tag %r not a unique leaf" % rest)
    elif kind == "dup":
        hit = [l for l in leaves if l[0] == rest]
        if len(hit) != 1:
            raise SystemExit("EMIT_COVER=FAIL mutant dup: tag %r not a unique leaf" % rest)
        i = leaves.index(hit[0]); leaves = leaves[:i + 1] + [hit[0]] + leaves[i + 1:]
    elif kind == "swaplit":
        tag, _, new = rest.partition(":")
        hit = [l for l in leaves if l[0] == tag]
        if len(hit) != 1:
            raise SystemExit("EMIT_COVER=FAIL mutant swaplit: tag %r not a unique leaf" % tag)
        u = list(tag_units(tag)); u[-1] = int(new)
        i = leaves.index(hit[0]); leaves[i] = (units_tag(tuple(u)), hit[0][1], hit[0][2])
    else:
        raise SystemExit("EMIT_COVER=FAIL unknown mutant %r" % spec)
    return leaves


# ---- Lean DefaultFormula RUP semantics (a Python replay of the Lean checker's): units pre-assigned; a hint that is
#      satisfied with one true literal is a no-op, Both/Empty = conflict, NonUnit = error ----------------------
class RupSim:
    def __init__(self):
        self.db = {}; self.asg = {}

    def add_clause(self, cid, cl):
        self.db[cid] = cl
        if len(cl) == 1:
            self.asg.setdefault(abs(cl[0]), set()).add(cl[0] > 0)

    def reduce(self, cl):
        st, ul = "Empty", None
        for x in cl:
            v, b = abs(x), x > 0; a = self.asg.get(v, set())
            if a == {True, False}:
                return "Both", None
            if st == "Empty":
                if b in a: st, ul = "Unit", (v, b)
                elif (not b) in a: pass
                else: st, ul = "Unit", (v, b)
            else:
                if (not b) in a: pass
                else: return "NonUnit", None
        return st, ul

    def check(self, clause, hints):
        """-> (ok, used_hints, reason).  Mirrors performRupAdd: negate clause into the assignment, walk hints."""
        derived, found = [], False
        for x in clause:
            v, b = abs(x), x > 0
            if b in self.asg.get(v, set()):
                found = True
            self.asg.setdefault(v, set()).add(not b); derived.append((v, not b))
        ok, used, reason = found, [], ""
        if not found:
            for h in hints:
                used.append(h)
                if h not in self.db:
                    reason = "missing hint %d" % h; break
                k, ul = self.reduce(self.db[h])
                if k in ("Both", "Empty"):
                    ok = True; break
                if k == "Unit":
                    v, b = ul
                    if b in self.asg.get(v, set()):
                        continue
                    self.asg.setdefault(v, set()).add(b); derived.append((v, b))
                else:
                    reason = "NonUnit hint %d" % h; break
            if not ok and not reason:
                reason = "hints exhausted without conflict"
        for v, b in derived:
            self.asg[v].discard(b)
        return ok, used, reason

    def propagate_hints(self, assume_lits, max_steps=10 ** 6):
        """Unit propagation from `assume_lits` over the db (no hint list given); returns the hint ids in
        the order they fired, ending with a conflict clause, or None.  Used only for AMO lemmas."""
        derived, used = [], []
        for x in assume_lits:
            v, b = abs(x), x > 0
            self.asg.setdefault(v, set()).add(b); derived.append((v, b))
        ok = False; changed = True; steps = 0
        while changed and not ok and steps < max_steps:
            changed = False
            for cid, cl in self.db.items():
                steps += 1
                k, ul = self.reduce(cl)
                if k in ("Both", "Empty"):
                    used.append(cid); ok = True; break
                if k == "Unit" and ul[1] not in self.asg.get(ul[0], set()):
                    self.asg.setdefault(ul[0], set()).add(ul[1]); derived.append(ul); used.append(cid); changed = True
        for v, b in derived:
            self.asg[v].discard(b)
        return used if ok else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cnf", required=True); ap.add_argument("--ledger", required=True); ap.add_argument("--out", required=True)
    ap.add_argument("--mutant", default=None); ap.add_argument("--expect-cnf-sha", default=None)
    ap.add_argument("--no-sim", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    raw = open(a.cnf, "rb").read()
    src_sha = hashlib.sha256(raw).hexdigest()
    if a.expect_cnf_sha and src_sha != a.expect_cnf_sha:
        raise SystemExit("EMIT_COVER=FAIL source CNF sha %s != expected %s" % (src_sha, a.expect_cnf_sha))
    nvars, flines = read_cnf_lines(a.cnf)
    F = [lits_of(l) for l in flines]
    m = len(F)
    leaves, splits = read_ledger(a.ledger)
    if a.mutant:
        leaves = apply_mutant(leaves, a.mutant)
    bins = set(frozenset(c) for c in F if len(c) == 2)

    # ---- tree: children by tag prefix (ledger order), witness per split ------------------------------------
    witness = dict(splits)
    if "proot" not in witness:
        raise SystemExit("EMIT_COVER=FAIL ledger has no SPLIT proot row")
    nodes = {}                                   # tag -> list of child tags (ledger order)
    for tag in witness:
        nodes[tag] = []
    def parent_of(tag):
        u = tag_units(tag)
        return units_tag(u[:-1]) if u else None
    def nearest_split_ancestor(tag):
        # a mutated/foreign tag whose parent is not a split is hung under the nearest existing ancestor, so the
        # certificate is still emitted and the checker gets to reject it
        p = parent_of(tag)
        while p is not None and p not in nodes:
            p = parent_of(p)
        if p is None:
            raise SystemExit("EMIT_COVER=FAIL tag %r has no ancestor in the tree" % tag)
        return p
    # children lists: splits first (ledger order), then leaves, one entry per ledger occurrence
    for tag, _ in splits:
        if tag != "proot":
            nodes[nearest_split_ancestor(tag)].append(("S", tag))
    for i, (tag, _, _) in enumerate(leaves):
        nodes[nearest_split_ancestor(tag)].append(("L", m + 1 + i))

    # the ledger as used (after any mutation), so a checker can be run against a self-consistent wrong certificate
    with open(os.path.join(a.out, "ledger_used.tsv"), "w") as f:
        for tag, how in splits:
            f.write("SPLIT\t%s\t%s\t-\n" % (tag, how))
        for tag, route, cnt in leaves:
            f.write("LEAF\t%s\t%s\t%d\n" % (tag, route, cnt))

    # ---- (i) cover.cnf ----------------------------------------------------------------------------------------
    leaf_lines = [" ".join(str(-u) for u in tag_units(tag)) + " 0" for tag, _, _ in leaves]
    cover_path = os.path.join(a.out, "cover.cnf")
    with open(cover_path, "w") as f:
        f.write("p cnf %d %d\n" % (nvars, m + len(leaves)))
        f.write("\n".join(flines) + "\n")
        if leaf_lines:
            f.write("\n".join(leaf_lines) + "\n")

    sim = None if a.no_sim else RupSim()
    if sim:
        for i, c in enumerate(F):
            sim.add_clause(i + 1, c)
        for i, l in enumerate(leaf_lines):
            sim.add_clause(m + 1 + i, lits_of(l))

    # ---- AMO lemmas for split-clause pairs not literally in F (none for n=10 / n=12: witnessed splits) ------
    next_id = m + len(leaves) + 1
    lrat_lines, amo_rows, amo_fail = [], [], 0
    sim_fail = 0
    for tag, how in splits:
        if not how.startswith("clause#"):
            continue
        C = F[int(how[len("clause#"):]) - 1]
        for i in range(len(C)):
            for j in range(i + 1, len(C)):
                if frozenset((-C[i], -C[j])) in bins:
                    continue
                hints = sim.propagate_hints([C[i], C[j]]) if sim else None
                if hints is None:
                    amo_fail += 1; amo_rows.append((tag, how, C[i], C[j], "NOT_DERIVED", ""))
                    continue
                lrat_lines.append("%d %d %d 0 %s 0" % (next_id, -C[i], -C[j], " ".join(map(str, hints))))
                amo_rows.append((tag, how, C[i], C[j], "LEMMA", next_id))
                if sim:
                    sim.add_clause(next_id, [-C[i], -C[j]])
                next_id += 1
    with open(os.path.join(a.out, "amo_lemmas.tsv"), "w") as f:
        f.write("split\twitness\tlit_a\tlit_b\tstatus\tlemma_id\n")
        for r in amo_rows:
            f.write("\t".join(map(str, r)) + "\n")

    # ---- (ii) node lemmas, post-order -------------------------------------------------------------------------
    lemma_id = {}
    node_rows = []
    def emit(tag):
        for kind, ch in nodes[tag]:
            if kind == "S":
                emit(ch)
        nonlocal next_id
        units = tag_units(tag)
        clause = [-u for u in units]
        hints = [lemma_id[ch] if kind == "S" else ch for kind, ch in nodes[tag]]
        how = witness[tag]
        if how.startswith("clause#"):
            hints.append(int(how[len("clause#"):]))
        lrat_lines.append("%d %s0 %s 0" % (next_id, "".join("%d " % x for x in clause), " ".join(map(str, hints))))
        lemma_id[tag] = next_id
        status = "-"
        if sim:
            ok, used, reason = sim.check(clause, hints)
            status = "ok" if ok else "FAIL:" + reason
            if not ok:
                nonlocal sim_fail; sim_fail += 1
            sim.add_clause(next_id, clause)
        node_rows.append((tag, next_id, how, len(nodes[tag]), status))
        next_id += 1
    emit("proot")
    with open(os.path.join(a.out, "cover.lrat"), "w") as f:
        f.write("\n".join(lrat_lines) + "\n")
    with open(os.path.join(a.out, "node_lemmas.tsv"), "w") as f:
        f.write("node\tlemma_id\twitness\tchildren\tsim\n")
        for r in node_rows:
            f.write("\t".join(map(str, r)) + "\n")

    # ---- manifest ---------------------------------------------------------------------------------------------
    def sha(p):
        return hashlib.sha256(open(p, "rb").read()).hexdigest()
    man = [("source_cnf", a.cnf), ("source_cnf_sha256", src_sha), ("source_vars", nvars), ("source_clauses", m),
           ("ledger", a.ledger), ("ledger_sha256", hashlib.sha256((gzip.open(a.ledger, "rb") if a.ledger.endswith(".gz") else open(a.ledger, "rb")).read()).hexdigest()),
           ("mutant", a.mutant or "none"), ("leaves", len(leaves)), ("splits", len(splits)),
           ("cover_cnf_clauses", m + len(leaves)), ("cover_cnf_sha256", sha(cover_path)),
           ("amo_lemmas", sum(1 for r in amo_rows if r[4] == "LEMMA")), ("amo_not_derived", amo_fail),
           ("node_lemmas", len(node_rows)), ("lrat_lines", len(lrat_lines)), ("cover_lrat_sha256", sha(os.path.join(a.out, "cover.lrat"))),
           ("root_lemma_id", lemma_id["proot"]), ("emitter_sha256", sha(os.path.abspath(__file__)))]
    with open(os.path.join(a.out, "manifest.tsv"), "w") as f:
        for k, v in man:
            f.write("%s\t%s\n" % (k, v))
    for k, v in man:
        print("%s=%s" % (k, v))
    print("EMIT_RUP_SIM=%s" % ("SKIP" if not sim else ("PASS" if sim_fail == 0 and amo_fail == 0 else "FAIL")))
    print("EMIT_COVER=OK")


if __name__ == "__main__":
    main()
