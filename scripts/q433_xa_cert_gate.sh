#!/usr/bin/env bash
# Q433_XA_CERT=PASS|FAIL|ERROR
#
# The XA-c/d pricing path refuses without a W0-D t-unit -> SOLVE_NODE_LIMIT mapping certificate.
# Until 2026-09-07 that refusal was `cost.get("node_mapping_cert") is None` -- it tested that a
# PATH STRING had been supplied and NEVER OPENED THE FILE. `--xa-node-mapping-cert /nope.json`
# was enough to unblock an EXHAUSTIBLE/INFEASIBLE verdict: weaker than `test -f`, because not
# even existence stood between a flag and a published number.
#
# THE POINT OF THIS GATE IS LEG 1 AS MUCH AS THE REST. A validator that refuses EVERYTHING is
# not a fix, it is a permanent FALSE dressed as rigour -- so leg 1 requires a well-formed
# certificate to be ACCEPTED. Mutant M2 is the plausible half-fix (opens the file, checks it
# parses, but not what it says) and it must die on leg 3 alone.
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "Q433_XA_CERT=ERROR cannot reach repo root"; exit 2; }
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
fail(){ echo "  [ERROR] $*"; echo "Q433_XA_CERT=ERROR"; exit 2; }
[ -f solve.py ] || fail "missing solve.py"

# --- LEG 0 (wiring): the validator must actually be CALLED by the refusal guard. A helper that
# nothing invokes is the defect it was written to fix. Static, so it survives a mutated helper.
grep -qE '^[[:space:]]*elif cost is None or _xa_node_mapping_cert_defect\(cost\.get\("node_mapping_cert"\)\):' solve.py \
  || { echo "  [FAIL] the XA refusal guard does not call _xa_node_mapping_cert_defect"; \
       echo "Q433_XA_CERT=FAIL"; exit 1; }

cat > "$WORK/legs.py" <<'PY'
import importlib.util, json, os, sys, tempfile
src = sys.argv[1]
spec = importlib.util.spec_from_file_location("solve_under_test", src)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
f = m._xa_node_mapping_cert_defect
d = tempfile.mkdtemp()
def w(name, obj):
    p = os.path.join(d, name)
    with open(p, "w", encoding="utf-8") as fh:
        json.dump(obj, fh) if not isinstance(obj, str) else fh.write(obj)
    return p
# L1  a well-formed certificate is ACCEPTED -- without this the "fix" is a permanent FALSE.
good = w("good.json", {"node_convention": {"solve_node_limit_mapping":
         "1 t-unit == 1 SOLVE_NODE_LIMIT node, certified by the W0-D worker run"}})
print("L1=OK" if f(good) is None else "L1=BAD")
# L2  a path that does not exist is REFUSED  (the original defect, exactly)
print("L2=OK" if f(os.path.join(d, "absent.json")) else "L2=BAD")
# L3  the `solve --kc-t-cert` output is REFUSED BY ITS OWN DISCLAIMER
dis = w("disclaim.json", {"node_convention": {"solve_node_limit_mapping":
        "NOT CLAIMED HERE - the W0-D worker run (WAVE0_RUNBOOK item w0d) pins the mapping"}})
print("L3=OK" if f(dis) else "L3=BAD")
# L4  a certificate that never mentions the mapping does not certify it
print("L4=OK" if f(w("nokey.json", {"n9": {"N_walks": 26112}})) else "L4=BAD")
# L5  unparseable JSON is REFUSED, not crashed on
try:
    print("L5=OK" if f(w("bad.json", "{not json")) else "L5=BAD")
except Exception as exc:                                    # noqa: BLE001
    print("L5=BAD(raised %s)" % type(exc).__name__)
PY

legs(){ python3 "$WORK/legs.py" "$1" 2>/dev/null; }

BASE=$(legs solve.py)
[ "$(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=')" = 5 ] \
  || fail "baseline produced $(printf '%s\n' "$BASE" | grep -c '^L[0-9]*=') leg verdicts, not 5 -- the gate measured nothing"
case "$BASE" in *=BAD*)
  printf '%s\n' "$BASE" | grep '=BAD' | sed 's/^/  [FAIL] baseline /'
  echo "Q433_XA_CERT=FAIL"; exit 1 ;;
esac
echo "  [gate] baseline PASS on 5 legs"

# --- mutants -----------------------------------------------------------------------------
# NEVER `legs ... | grep -q` under pipefail: grep -q exits at the first match and SIGPIPEs the
# producer, so the pipeline reports 141 and a KILLED mutant reads as SURVIVED. Capture, then match.
mutate(){ # mutate <name> <python-edit>
  local name="$1" edit="$2" out
  python3 - "$edit" <<'PY' || return 2
import sys
edit = sys.argv[1]
s = open("solve.py", encoding="utf-8").read()
if edit == "accept_all":
    old = '    if path is None:\n        return "no certificate was supplied"\n'
    new = '    if True:\n        return None\n'
elif edit == "disclaimer_blind":
    old = '    if isinstance(hit[0], str) and "NOT CLAIMED HERE" in hit[0]:\n'
    new = '    if False:\n'
else:
    sys.exit(2)
assert s.count(old) == 1, "mutant anchor drift: " + edit
open(sys.argv[0] if False else "/dev/stdout", "w") if False else None
import os
open(os.environ["MUT"], "w", encoding="utf-8").write(s.replace(old, new))
PY
  out=$(legs "$MUT")
  [ "$(printf '%s\n' "$out" | grep -c '^L[0-9]*=')" = 5 ] \
    || { echo "  [ERROR] mutant $name produced no leg verdicts -- nothing was measured"; return 2; }
  case "$out" in *=BAD*) echo "  [gate] mutant $name killed"; return 0 ;; esac
  echo "  [FAIL] mutant $name SURVIVED -- the gate cannot see this fault"; return 1
}

export MUT="$WORK/mutant.py"
K=0
for m in M1_accept_all:accept_all M2_disclaimer_blind:disclaimer_blind; do
  mutate "${m%%:*}" "${m##*:}"
  case $? in
    0) K=$((K+1)) ;;
    1) echo "Q433_XA_CERT=FAIL"; exit 1 ;;
    *) echo "Q433_XA_CERT=ERROR"; exit 2 ;;
  esac
done
[ "$K" = 2 ] || fail "evaluated $K mutants, expected 2"
echo "  [gate] baseline PASS on 5 legs; $K/2 mutants killed"
echo "Q433_XA_CERT=PASS"
