#!/usr/bin/env python3
"""renumber_lrat.py IN.lrat OUT.lrat NORIG -- rewrite a text LRAT proof so that lemma ids are consecutive
from NORIG+1 (NORIG = the clause count in the CNF's `p cnf` header).

Why (Q-1094, 2026-11-12). `drat-trim <cnf> <drat> -L <lrat>` writes its core lemmas with the ids they had in
its own numbering, so the ids of consecutive lines have gaps (the lemmas drat-trim dropped from the core).
The LRAT checker shipped with Lean 4 (v4.31.0, `Std.Tactic.BVDecide.LRAT.check`) stores clauses in an array
indexed by id and REJECTS a proof whose ids are not consecutive (SAT_CLI.md, B.14). This script applies one
bijection to the ids: original clauses 1..NORIG keep their ids, every added lemma gets the next free id in
file order, and every hint (positive RUP/RAT hints and the negative RAT candidate ids) is mapped through the
same table. Literals are never touched.

Trust. UNTRUSTED preprocessing, in the same position as drat-trim's elaboration: the checker judges the file
this script writes, against the CNF, with its own soundness theorem, so a defect here can only make the
checker print ERROR or REJECTED, never VERIFIED for a proof that does not refute the CNF.

Rules that the unit tests in tests.py (TestBatchQ1094) pin:
  * an add line `id lits 0 hints 0` is written as `newid lits 0 mapped-hints 0`, every field separated by ONE
    space -- a lemma with NO hints (drat-trim writes `id lits 0 0` for a fresh-variable clause with no
    resolution candidate) is written `newid lits 0 0`; a double space is a parse ERROR in Lean's strict parser;
  * a deletion line `id d ids 0` is written with the id of the last lemma written so far; ids never seen
    (lemmas outside drat-trim's core) are dropped; a deletion with nothing left is not written at all;
  * a hint naming an id that was never defined is an ERROR (exit 2, line `RENUMBER=ERROR ...`), never a
    silent rewrite; so is a line that cannot be parsed.
Exit 0 and the line `RENUMBER=OK adds=<n> dels=<m> first_id=<NORIG+1> last_id=<k>` on success.
Developed with AI assistance (Claude, Anthropic): claude-fable-5-1.
"""
import sys


class RenumberError(Exception):
    pass


def renumber(lines, norig):
    """Return (out_lines, adds, dels) for the LRAT text in `lines` (any iterable of strings)."""
    m = {i: i for i in range(1, norig + 1)}
    nxt = norig + 1
    out, adds, dels = [], 0, 0
    for lineno, ln in enumerate(lines, 1):
        t = ln.split()
        if not t:
            continue
        if len(t) < 3 or t[-1] != "0":
            raise RenumberError("line %d: not an LRAT line (needs an id, a body and a terminating 0)" % lineno)
        if t[1] == "d":
            try:
                ids = [m[int(x)] for x in t[2:-1] if int(x) in m]
            except ValueError:
                raise RenumberError("line %d: non-integer id in a deletion line" % lineno)
            if ids:
                out.append("%d d %s 0" % (nxt - 1, " ".join(map(str, ids))))
                dels += 1
            continue
        try:
            z = t.index("0")
            lemma_id = int(t[0])
            clause = t[1:z]
            hints = t[z + 1:-1]
            for lit in clause:
                int(lit)
            hs = []
            for h in hints:
                hv = int(h)
                if hv < 0:
                    hs.append(str(-m[-hv]))
                else:
                    hs.append(str(m[hv]))
        except ValueError:
            raise RenumberError("line %d: malformed add line (no clause terminator, or a non-integer field)" % lineno)
        except KeyError as e:
            raise RenumberError("line %d: hint names an id that was never defined: %s" % (lineno, e.args[0]))
        if lemma_id in m:
            raise RenumberError("line %d: lemma id %d defined twice" % (lineno, lemma_id))
        m[lemma_id] = nxt
        out.append(" ".join([str(nxt)] + clause + ["0"] + hs + ["0"]))
        adds += 1
        nxt += 1
    return out, adds, dels


def main(argv):
    if len(argv) != 4:
        sys.stdout.write("RENUMBER=ERROR usage: renumber_lrat.py IN.lrat OUT.lrat NORIG\n")
        return 2
    src, dst = argv[1], argv[2]
    try:
        norig = int(argv[3])
        if norig < 0:
            raise ValueError
    except ValueError:
        sys.stdout.write("RENUMBER=ERROR NORIG must be a non-negative integer, got %r\n" % argv[3])
        return 2
    try:
        with open(src) as fh:
            out, adds, dels = renumber(fh, norig)
    except RenumberError as e:
        sys.stdout.write("RENUMBER=ERROR %s\n" % e)
        return 2
    except OSError as e:
        sys.stdout.write("RENUMBER=ERROR cannot read %s: %s\n" % (src, e))
        return 2
    with open(dst, "w") as o:
        for ln in out:
            o.write(ln + "\n")
    sys.stdout.write("RENUMBER=OK adds=%d dels=%d first_id=%d last_id=%d\n" % (adds, dels, norig + 1, norig + adds))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
