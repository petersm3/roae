#!/usr/bin/env python3
"""n12_partition_all.py — regenerate every SPLIT of a decomp_certify_v3 ledger from the SOURCE CNF
and the ledger's recorded witness, and run q424_partition_check.py (Appendix B of
the project's partition-check design note, sha256 6c860c64…) on each one; then check proofs.tsv against the
regenerated leaves.  Independent of the driver: it imports nothing from it and re-implements
the piece text (header + source clauses in file order + one unit line per literal, which is the
byte shape the partition checker demands and the driver writes).

What PASS proves, per SPLIT row `SPLIT <tag> clause#N -`:
  the parent piece (source + units of <tag>) literally contains clause #N, every pair of its
  literals is excluded by a binary clause literally in the parent, and the children are the parent
  plus exactly one unit per literal of #N — one child per literal, none missing, none extra.
Per `SPLIT <tag> cube-varV -`: the two children are the parent + `V 0` and the parent + `-V 0`.
Per LEAF (from proofs.tsv): the sha256 the driver recorded for piece.cnf equals the sha256 of the
piece regenerated HERE from the source and the tag — so "the CNF cpog-check verified" and "the
child the partition argument needs" are the same bytes, witnessed, not assumed (P4).
Tree closure: every tag in the ledger is reachable from the root by recorded splits, every leaf
is a LEAF row, no tag is both.  The sum is NOT computed here (that is awk's job, §5.2) — only the
partition and identity facts are.

usage: n12_partition_all.py <source.cnf> <workdir> [--checker PATH] [--tmp DIR]
Prints PARTITION_ALL=PASS|FAIL as a whole line (plus one PARTITION_SPLIT line per split).
"""
import argparse, hashlib, os, re, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def read_cnf(p):
    header, clauses, lines = None, [], []
    for line in open(p):
        if line.startswith("p cnf"):
            header = line.split(); continue
        if line[:1] == "c" or not line.strip():
            continue
        clauses.append([int(t) for t in line.split()[:-1]])
    if header is None or len(clauses) != int(header[3]):
        raise SystemExit("PARTITION_ALL=FAIL source CNF parse mismatch")
    return int(header[2]), clauses


def tag_units(tag):
    if tag == "proot":
        return ()
    assert tag.startswith("p"), tag
    return tuple(int(x.replace("m", "-")) for x in tag[1:].split("_"))


def units_tag(units):
    return "p" + ("_".join(str(u).replace("-", "m") for u in units) or "root")


def piece_text(nvars, clauses, units):
    out = ["p cnf %d %d\n" % (nvars, len(clauses) + len(units))]
    out += [" ".join(map(str, c)) + " 0\n" for c in clauses]
    out += ["%d 0\n" % u for u in units]
    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("workdir")
    ap.add_argument("--checker", default=os.path.join(HERE, "q424_partition_check.py"))
    ap.add_argument("--tmp", default=None)
    a = ap.parse_args()
    ledger = os.path.join(a.workdir, "ledger.tsv")
    proofs = os.path.join(a.workdir, "proofs.tsv")
    bind = os.path.join(a.workdir, "source.sha256")
    fails = []

    def fail(msg):
        fails.append(msg)
        print("PARTITION_FAIL_REASON=" + msg)

    src_sha = hashlib.sha256(open(a.source, "rb").read()).hexdigest()
    if os.path.exists(bind):
        rec = open(bind).read().split()[0]
        if rec != src_sha:
            fail("source.sha256 %s != sha256(%s) %s" % (rec, a.source, src_sha))
    else:
        fail("no source.sha256 in workdir (pre-P4 ledger)")
    nvars, clauses = read_cnf(a.source)

    leaves, splits, order = {}, {}, []
    for ln, line in enumerate(open(ledger), 1):
        parts = line.rstrip("\n").split("\t")
        if len(parts) != 4 or parts[0] not in ("LEAF", "SPLIT"):
            fail("ledger line %d malformed: %r" % (ln, line)); continue
        kind, tag, route, count = parts
        if kind == "LEAF":
            if tag in leaves:
                fail("duplicate LEAF %s" % tag)
            leaves[tag] = (route, count)
        else:
            if tag in splits:
                fail("duplicate SPLIT %s" % tag)
            splits[tag] = route
            order.append(tag)
    both = set(leaves) & set(splits)
    if both:
        fail("tags both LEAF and SPLIT: %s" % sorted(both)[:5])

    # tree closure from the root
    expected_children = {}
    reach = {"proot"}
    frontier = ["proot"]
    while frontier:
        t = frontier.pop()
        if t in splits:
            how = splits[t]
            units = tag_units(t)
            m = re.fullmatch(r"clause#(\d+)", how)
            if m:
                idx = int(m.group(1))
                if not (1 <= idx <= len(clauses)):
                    fail("%s witness %s out of range" % (t, how)); continue
                lits = clauses[idx - 1]
                kids = [units + (l,) for l in lits]
            else:
                m = re.fullmatch(r"cube-var(\d+)", how)
                if not m:
                    fail("%s has no usable witness (%r)" % (t, how)); continue
                v = int(m.group(1))
                kids = [units + (v,), units + (-v,)]
            expected_children[t] = [units_tag(k) for k in kids]
            for k in expected_children[t]:
                if k in reach:
                    fail("tag %s reached twice" % k)
                reach.add(k)
                frontier.append(k)
        elif t not in leaves:
            fail("tag %s is neither LEAF nor SPLIT" % t)
    unreached = (set(leaves) | set(splits)) - reach
    if unreached:
        fail("%d ledger tags unreachable from root, e.g. %s" % (len(unreached), sorted(unreached)[:3]))

    tmp = a.tmp or tempfile.mkdtemp(prefix="n12part_")
    own_tmp = a.tmp is None
    n_ok = 0
    try:
        for t in order:
            if t not in expected_children:
                continue
            how = splits[t]
            units = tag_units(t)
            d = os.path.join(tmp, t)
            os.makedirs(d, exist_ok=True)
            parent = os.path.join(tmp, t + ".parent.cnf")
            with open(parent, "w") as f:
                f.write(piece_text(nvars, clauses, units))
            m = re.fullmatch(r"clause#(\d+)", how)
            if m:
                lits = clauses[int(m.group(1)) - 1]
                for l in lits:
                    with open(os.path.join(d, units_tag(units + (l,)) + ".cnf"), "w") as f:
                        f.write(piece_text(nvars, clauses, units + (l,)))
                r = subprocess.run([sys.executable, a.checker, parent, m.group(1), d],
                                   capture_output=True, text=True)
                ok = r.returncode == 0 and "PARTITION_CHECK=PASS" in r.stdout.split("\n")
                print("PARTITION_SPLIT %s %s k=%d %s" % (t, how, len(lits), "PASS" if ok else "FAIL"))
                if not ok:
                    fail("split %s: %s" % (t, (r.stdout + r.stderr).strip().replace("\n", " | ")[-300:]))
            else:
                v = int(re.fullmatch(r"cube-var(\d+)", how).group(1))
                ptxt = open(parent).read()
                ok = True
                for l in (v, -v):
                    want = ptxt.replace("p cnf %d %d\n" % (nvars, len(clauses) + len(units)),
                                        "p cnf %d %d\n" % (nvars, len(clauses) + len(units) + 1), 1) + "%d 0\n" % l
                    if piece_text(nvars, clauses, units + (l,)) != want or abs(l) in {abs(u) for u in units}:
                        ok = False
                print("PARTITION_SPLIT %s %s k=2 %s" % (t, how, "PASS" if ok else "FAIL"))
                if not ok:
                    fail("cube split %s" % t)
            if ok:
                n_ok += 1
            shutil.rmtree(d, ignore_errors=True)
            os.remove(parent)
        # proofs.tsv vs regenerated leaves
        if not os.path.exists(proofs):
            fail("no proofs.tsv")
        else:
            seen = {}
            for ln, line in enumerate(open(proofs), 1):
                p = line.rstrip("\n").split("\t")
                if len(p) != 7:
                    fail("proofs.tsv line %d malformed" % ln); continue
                tag, route, count, cnf_sha, proof_sha, nbytes, wall = p
                if tag in seen and seen[tag][:3] != (route, count, cnf_sha):
                    fail("proofs.tsv tag %s has conflicting duplicate lines" % tag)
                seen[tag] = (route, count, cnf_sha, proof_sha)
            if set(seen) != set(leaves):
                fail("proofs.tsv tags != ledger LEAF tags (missing %s, extra %s)"
                     % (sorted(set(leaves) - set(seen))[:3], sorted(set(seen) - set(leaves))[:3]))
            for tag, (route, count) in leaves.items():
                if tag not in seen:
                    continue
                r_, c_, cnf_sha, proof_sha = seen[tag]
                if (r_, c_) != (route, count):
                    fail("proofs.tsv %s (%s,%s) != ledger (%s,%s)" % (tag, r_, c_, route, count))
                if route not in ("CPOG", "DRAT0"):
                    fail("leaf %s route %s is not certified" % (tag, route))
                regen = hashlib.sha256(piece_text(nvars, clauses, tag_units(tag)).encode()).hexdigest()
                if regen != cnf_sha:
                    fail("leaf %s piece.cnf sha %s != regenerated %s" % (tag, cnf_sha[:12], regen[:12]))
                if not re.fullmatch(r"[0-9a-f]{64}", proof_sha):
                    fail("leaf %s has no proof sha" % tag)
    finally:
        if own_tmp:
            shutil.rmtree(tmp, ignore_errors=True)
    print("PARTITION_SPLITS_CHECKED=%d LEAVES=%d" % (n_ok, len(leaves)))
    if fails:
        print("PARTITION_ALL=FAIL (%d)" % len(fails))
        sys.exit(1)
    print("PARTITION_ALL=PASS")


if __name__ == "__main__":
    main()
