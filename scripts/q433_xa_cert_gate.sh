#!/usr/bin/env bash
# Q433_XA_CERT=PASS|FAIL|ERROR
#
# The XA-c/d pricing path refuses without a W0-D t-unit -> SOLVE_NODE_LIMIT mapping certificate.
# Until 2026-09-07 that refusal was `cost.get("node_mapping_cert") is None` -- it tested that a
# PATH STRING had been supplied and NEVER OPENED THE FILE. `--xa-node-mapping-cert /nope.json`
# was enough to unblock an EXHAUSTIBLE/INFEASIBLE verdict: weaker than `test -f`, because not
# even existence stood between a flag and a published number.
#
# 🔴 Q-772 (2026-09-24), implementing the Q-768 ruling: THE CERTIFICATE IS NOW USED. Three more
# rounds after 2026-09-07 tightened the grammar of a permission SENTENCE (`solve_node_limit_mapping`
# = "CERTIFIED: ...") and RCQ04 measured that no grammar closes it -- "CERTIFIED: no mapping has
# been established" authorised a price, because nothing the certificate said reached the
# arithmetic. `_xa_node_mapping_load` now reads a fixed schema whose `mapping.nodes_per_t_unit`
# (an exact "p/q") MULTIPLIES every priced row and whose `mapping.kind` (exact / upper-bound /
# lower-bound) limits the call a row may make. The legacy key is no longer consulted, so the old
# leg 1 -- a string-only "good" certificate -- FLIPS to refused, and the new positive leg is a
# full-schema certificate that must be ACCEPTED AND PRICED.
#
# THE POINT OF THIS GATE IS THE POSITIVE LEG AS MUCH AS THE REST. A loader that refuses
# EVERYTHING is not a fix, it is a permanent FALSE dressed as rigour, so mutant M0b (refuse all)
# must die on leg L1. The ruling's four mutants must each die on the leg named for them:
#   m1  the consumer ignores the factor (`* 1`)     -> L15 (R2)
#   m2  every kind is treated as exact              -> L16 (R3)
#   m3  the loader's field checks are removed       -> L17 (R4)
#   m4  a recursive search for `mapping` is kept    -> L18 (R5)
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q433_XA_CERT=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "Q433_XA_CERT=ERROR"; exit 2; }
[ -f solve.py ] || fail "missing solve.py"

# --- LEG 0 (wiring): the loader must actually be CALLED by the refusal guard, and the guard must
# key on what it returns. A helper that nothing invokes is the defect it was written to fix.
# Static, so it survives a mutated helper.
grep -qE '_xa_node_mapping_load\(cost\.get\("node_mapping_cert"\)\)' solve.py \
  && grep -qE '^[[:space:]]*elif xa_map is None:' solve.py \
  || { echo "  [FAIL] the XA refusal guard does not call _xa_node_mapping_load"; \
       echo "Q433_XA_CERT=FAIL"; exit 1; }

cat > "$WORK/legs.py" <<'PY'
import importlib.util, json, os, re, sys, tempfile
from fractions import Fraction
src = sys.argv[1]
spec = importlib.util.spec_from_file_location("solve_under_test", src)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
load = m._xa_node_mapping_load
d = tempfile.mkdtemp()
def w(name, obj):
    p = os.path.join(d, name)
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(obj, fh) if not isinstance(obj, str) else fh.write(obj)
    return p
def cert(kind="exact", F="1/1", residual=0, **top):
    doc = {"type": "roae-w0d-node-mapping-certificate", "version": 1,
           "mapping": {"kind": kind, "nodes_per_t_unit": F, "residual": residual,
                       "formula": "GATE: production_nodes = F * t", "law": "GATE: fixture"},
           "measured": {"n": [9, 13], "per_n": [], "verdict_line": "W0-D PASS mapping: GATE"},
           "provenance": {"engine_git": "FIXTURE:q433_xa_cert_gate.sh"},
           "semantics": "certificate-not-proof"}
    doc.update(top)
    return doc
def refused(p):
    mp, why = load(p)
    return mp is None and isinstance(why, str) and bool(why)
def emit(p, t_units=("10",), budget="1"):
    A = {"n": 9, "N_total": str(24 * len(t_units)), "layers": [{"flow": "24"}],
         "branch_atlas": [{"global_pair": i + 1, "entry": 2, "exit": 0, "solutions": "24",
                           "walks": 24, "prefixes_t_units": t} for i, t in enumerate(t_units)]}
    X = m._ExactAnchor
    cost = {"nodes_per_sec": X("1000"), "usd_per_hour": X("1"), "budget_usd": X(budget),
            "hedge": X("1"), "work_factor": X("1"), "note": "q433 gate", "node_mapping_cert": p}
    out = tempfile.mkdtemp(dir=d)
    _t, md, v, _g = m.atlas_emit_xa(A, out, cost=cost, atlas_path="q433.json")
    rows = {}
    for line in open(md, encoding="utf-8").read().splitlines():
        c = [x.strip() for x in line.strip().strip("|").split("|")]
        if len(c) == 9 and c[0].isdigit():
            rows[c[2]] = (Fraction(c[6]), c[7])
    return v, rows
def leg(name, fn):
    try:
        ok = fn()
    except Exception as exc:                                # noqa: BLE001
        print("%s=BAD(raised %s)" % (name, type(exc).__name__)); return
    print("%s=OK" % name if ok else "%s=BAD" % name)
LEGACY = "solve_node_limit_mapping"
# L1  a full-schema exact certificate is ACCEPTED and PRICED -- without this the fix is a FALSE.
def _l1():
    v, rows = emit(w("good.json", cert()))
    return v == "PASS" and rows.get("10", (None, ""))[1] == "EXHAUSTIBLE"
leg("L1", _l1)
# L1b the pre-Q-772 "good" certificate (a sentence, no factor) is now REFUSED: the flip.
leg("L1b", lambda: refused(w("old_good.json", {"node_convention": {LEGACY:
    "CERTIFIED: 1 t-unit == 1 SOLVE_NODE_LIMIT node, certified by the W0-D worker run"}})))
# L2  a path that does not exist is REFUSED  (the original defect, exactly)
leg("L2", lambda: refused(os.path.join(d, "absent.json")))
# L3  the `solve --kc-t-cert` output is REFUSED BY ITS TYPE
leg("L3", lambda: refused(w("kct.json", {"type": "roae-kc-t-node-convention-certificate",
    "version": 1, "convention": {LEGACY: "NOT CLAIMED HERE - the W0-D worker run pins it"}})))
# L4  a document with no mapping at all certifies nothing
leg("L4", lambda: refused(w("nokey.json", {"n9": {"N_walks": 26112}})))
# L5  unparseable JSON is REFUSED, not crashed on
leg("L5", lambda: refused(w("bad.json", "{not json")))
# L6-L12  every legacy value the earlier rounds were about (RCQ02 F2, RCQ04 finding 2)
for i, v in enumerate([None, False, "", "FAIL", "CERTIFIED:", "CERTIFIED:   ", "CERTIFIED:\t\n "]):
    leg("L%d" % (6 + i), lambda v=v, i=i: refused(w("legacy_%d.json" % i,
                                                    {"node_convention": {LEGACY: v}})))
# L13-L14  R1: the two RCQ04 inputs no grammar could close
leg("L13", lambda: refused(w("neg.json", {LEGACY: "CERTIFIED: no mapping has been established"})))
leg("L14", lambda: refused(w("claimed.json", {LEGACY: {"claimed": True, "mapping": "unrelated"}})))
# L15  R2: F MULTIPLIES every exact cost, and a row flips (kills m1)
def _l15():
    t = ("2400000", "3000000")
    _v1, r1 = emit(w("f1.json", cert(F="1/1")), t_units=t)
    _v2, r2 = emit(w("f32.json", cert(F="3/2")), t_units=t)
    return (all(r2[k][0] == Fraction(3, 2) * r1[k][0] for k in t)
            and r1["3000000"][1] == "EXHAUSTIBLE" and r2["3000000"][1] == "INFEASIBLE")
leg("L15", _l15)
# L16  R3: a bound never makes the call it cannot support (kills m2)
def _l16():
    t = ("600000", "6000000")
    vu, ru = emit(w("ub.json", cert(kind="upper-bound", residual=3)), t_units=t)
    vl, rl = emit(w("lb.json", cert(kind="lower-bound", residual=-3)), t_units=t)
    return (vu == "ONE-SIDED:upper-bound" and ru["6000000"][1] == "UNDECIDED:upper-bound"
            and ru["600000"][1] == "EXHAUSTIBLE"
            and vl == "ONE-SIDED:lower-bound" and rl["600000"][1] == "UNDECIDED:lower-bound"
            and rl["6000000"][1] == "INFEASIBLE")
leg("L16", _l16)
# L17  R4: a malformed mapping is a refusal with a reason (kills m3)
def _l17():
    bad = [dict(F=1.5), dict(F="0/1"), dict(F="-3/2"), dict(F="abc"), dict(F="1/0"),
           dict(residual=7), dict(kind="sideways")]
    ok = all(refused(w("r4_%d.json" % i, cert(**kw))) for i, kw in enumerate(bad))
    miss = cert(); del miss["mapping"]["residual"]
    return ok and refused(w("r4_miss.json", miss))
leg("L17", _l17)
# L18  R5: no recursive search; no RecursionError (kills m4)
def _l18():
    nested = cert(); nested["node_convention"] = {"mapping": nested.pop("mapping")}
    deep = w("deep.json", "[" * 100000 + "]" * 100000)
    return refused(w("nested.json", nested)) and refused(deep)
leg("L18", _l18)
PY

NLEGS=19
legs(){ python3 "$WORK/legs.py" "$1" 2>/dev/null; }

BASE=$(legs solve.py)
# 19 since 2026-09-24 (Q-772): L1, L1b, L2-L18. A count that lags its population is a check that
# has stopped counting, so the pin moves in the same change as the legs.
[ "$(printf '%s\n' "$BASE" | grep -c '^L[0-9a-z]*=')" = "$NLEGS" ] \
  || fail "baseline produced $(printf '%s\n' "$BASE" | grep -c '^L[0-9a-z]*=') leg verdicts, not $NLEGS -- the gate measured nothing"
case "$BASE" in *=BAD*)
  printf '%s\n' "$BASE" | grep '=BAD' | sed 's/^/  [FAIL] baseline /'
  echo "Q433_XA_CERT=FAIL"; exit 1 ;;
esac
echo "  [gate] baseline PASS on $NLEGS legs"

# --- mutants -----------------------------------------------------------------------------
# NEVER `legs ... | grep -q` under pipefail: grep -q exits at the first match and SIGPIPEs the
# producer, so the pipeline reports 141 and a KILLED mutant reads as SURVIVED. Capture, then match.
mutate(){ # mutate <name> <python-edit> <leg that must go BAD>
  local name="$1" edit="$2" must="$3" out
  python3 - "$edit" <<'PY' || return 2
import os, sys
edit = sys.argv[1]
s = open("solve.py", encoding="utf-8").read()
FIX = ('    if True:\n        from fractions import Fraction as _F\n'
       '        return {"factor": _F(1), "kind": "exact", "residual": 0, "formula": "m",\n'
       '                "law": "m", "sha256": "0" * 64, "path": str(path), "provenance": {},\n'
       '                "engine_git": "m", "measured_n": [], "verdict_line": "m"}, None\n')
if edit == "accept_all":
    old = '    if path is None:\n        return None, "no certificate was supplied"\n'
    new = FIX
elif edit == "refuse_all":
    old = '    if path is None:\n        return None, "no certificate was supplied"\n'
    new = '    if True:\n        return None, "mutant: refuse everything"\n'
elif edit == "m1_factor_ignored":
    old = '            x_nodes = Fraction(int(r[7])) * xa_map["factor"]'
    new = '            x_nodes = Fraction(int(r[7])) * 1'
elif edit == "m2_kind_ignored":
    old = '            kind = xa_map["kind"]\n'
    new = '            kind = "exact"\n'
elif edit == "m3_checks_removed":
    old = '    why = _xa_w0d_mapping_defect(mp)\n'
    new = '    why = None\n'
elif edit == "m4_recursive_find":
    old = '    mp = doc.get("mapping")\n'
    new = ('    def _mf(n):\n'
           '        if isinstance(n, dict):\n'
           '            if isinstance(n.get("mapping"), dict):\n'
           '                return n["mapping"]\n'
           '            n = list(n.values())\n'
           '        if isinstance(n, list):\n'
           '            for v in n:\n'
           '                r = _mf(v)\n'
           '                if r is not None:\n'
           '                    return r\n'
           '        return None\n'
           '    mp = _mf(doc)\n')
else:
    sys.exit(2)
if s.count(old) != 1:
    raise SystemExit("mutant anchor drift: %s (%d matches)" % (edit, s.count(old)))
open(os.environ["MUT"], "w", encoding="utf-8").write(s.replace(old, new))
PY
  out=$(legs "$MUT")
  [ "$(printf '%s\n' "$out" | grep -c '^L[0-9a-z]*=')" = "$NLEGS" ] \
    || { echo "  [ERROR] mutant $name produced no leg verdicts -- nothing was measured"; return 2; }
  case "$out" in *=BAD*) : ;; *)
    echo "  [FAIL] mutant $name SURVIVED -- the gate cannot see this fault"; return 1 ;; esac
  # Killed is not enough: it must die on the leg NAMED for it, or the leg has stopped testing
  # what its comment says.
  printf '%s\n' "$out" | grep -q "^$must=BAD" \
    || { echo "  [FAIL] mutant $name was killed, but not by $must -- that leg no longer sees it:"; \
         printf '%s\n' "$out" | grep '=BAD' | sed 's/^/         /'; return 1; }
  echo "  [gate] mutant $name killed by $must (BAD legs: $(printf '%s\n' "$out" | grep '=BAD' | cut -d= -f1 | tr '\n' ' '))"
  return 0
}

export MUT="$WORK/mutant.py"
K=0
for m in M0_accept_all:accept_all:L1b M0b_refuse_all:refuse_all:L1 \
         m1_factor_ignored:m1_factor_ignored:L15 m2_kind_ignored:m2_kind_ignored:L16 \
         m3_checks_removed:m3_checks_removed:L17 m4_recursive_find:m4_recursive_find:L18; do
  IFS=: read -r mname medit mleg <<<"$m"
  mutate "$mname" "$medit" "$mleg"
  case $? in
    0) K=$((K+1)) ;;
    1) echo "Q433_XA_CERT=FAIL"; exit 1 ;;
    *) echo "Q433_XA_CERT=ERROR"; exit 2 ;;
  esac
done
[ "$K" = 6 ] || fail "evaluated $K mutants, expected 6"
echo "  [gate] baseline PASS on $NLEGS legs; $K/6 mutants killed"
echo "Q433_XA_CERT=PASS"
