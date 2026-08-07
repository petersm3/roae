#!/usr/bin/env bash
# One-command verification of the ROAE technical-report suite's machine-checkable claims.
# Requirements: gcc, python3, drat-trim, lean (elan). See reports/METHODS.md for versions.
#   NOT required: a SAT solver. This script REPLAYS the archived DRAT proofs against freshly
#   regenerated CNF, which is the sufficient check and needs only drat-trim. kissat was listed
#   here until 2026-08-01 and never invoked by any code path — building it from source was
#   wasted work for a replicator (lens-sweep item T4-9). It is still what PRODUCED the archived
#   proofs (METHODS.md pins the version); reproducing the proofs themselves, rather than
#   verifying them, is the only step that needs it.
# https://github.com/petersm3/roae — Developed with AI assistance (Claude, Anthropic)
set -uo pipefail
cd "$(dirname "$0")/../.."
PASS=0; FAIL=0
SKIP=0
LOG=${ROAE_VERIFY_LOG:-/tmp/roae_verify_all.log}
: > "$LOG"

# A MISSING TOOL AND A FAILED PROOF ARE DIFFERENT OUTCOMES (lens-sweep item T3-15).
# Until 2026-08-01 check() discarded stdout+stderr and printed a bare "FAIL", so a replicator
# without drat-trim saw 22 indistinguishable "FAIL cert …" lines and one without lean saw 13
# more — the worst case being a skeptic running the advertised one command and concluding the
# certificates are bad. Output is now captured to $LOG and a failure says where to look; tools
# are probed up front and their dependent checks are reported SKIP (not FAIL), which cannot be
# mistaken for a certificate that failed to verify. SKIPs do not pass the run: the exit status
# below is 0 only when every check ran AND every check passed.
check() {
  { echo "### $1"; eval "$2"; } >>"$LOG" 2>&1
  if [ $? -eq 0 ]; then echo "PASS  $1"; PASS=$((PASS+1))
  else echo "FAIL  $1   (output: $LOG)"; FAIL=$((FAIL+1)); fi
}
skip() { echo "SKIP  $1   ($2)"; SKIP=$((SKIP+1)); }

echo "== 0. Prerequisites =="
DRAT=${DRAT:-drat-trim}
LEAN=${LEAN:-lean}
command -v "$LEAN" >/dev/null 2>&1 || LEAN="$HOME/.elan/bin/lean"
HAVE_GCC=1; HAVE_PY=1; HAVE_DRAT=1; HAVE_LEAN=1
command -v gcc      >/dev/null 2>&1 || HAVE_GCC=0
command -v python3  >/dev/null 2>&1 || HAVE_PY=0
command -v "$DRAT"  >/dev/null 2>&1 || HAVE_DRAT=0
command -v "$LEAN"  >/dev/null 2>&1 || HAVE_LEAN=0
for t in "gcc:$HAVE_GCC" "python3:$HAVE_PY" "drat-trim ($DRAT):$HAVE_DRAT" "lean ($LEAN):$HAVE_LEAN"; do
  if [ "${t##*:}" = "1" ]; then echo "  found    ${t%:*}"; else echo "  MISSING  ${t%:*}"; fi
done
if [ "$HAVE_DRAT" = "0" ] || [ "$HAVE_LEAN" = "0" ] || [ "$HAVE_GCC" = "0" ] || [ "$HAVE_PY" = "0" ]; then
  echo "  -> checks needing a missing tool are reported SKIP, not FAIL. A SKIP says nothing about"
  echo "     whether the claim verifies; install the tool (reports/METHODS.md pins versions) and re-run."
fi
echo "  full command output: $LOG"

echo "== 1. Enumerator selftest (canonical baseline sha) =="
if [ "$HAVE_GCC" = "0" ]; then
  skip "solve.c build" "needs gcc"
  skip "--selftest" "needs gcc"
else
  check "solve.c build" "gcc -O2 -pthread -fopenmp -o /tmp/roae_verify_solve solve.c -lm -lz"
  check "--selftest" "/tmp/roae_verify_solve --selftest | grep -q PASS"
fi

echo "== 2. Two-language gates =="
if [ "$HAVE_PY" = "0" ]; then
  skip "solve.py --registry-verify (31 rules)" "needs python3"
else
  check "solve.py --registry-verify (31 rules)" "python3 solve.py --registry-verify | grep -q 'ALL 31'"
fi
if [ "$HAVE_PY" = "0" ] || [ "$HAVE_GCC" = "0" ]; then
  skip "f4p two-language match" "needs gcc + python3"
else
  check "f4p two-language match" "diff <(/tmp/roae_verify_solve --f4p-verify) <(python3 solve.py --f4p-verify)"
fi
# The exact-subtree recount is the ONLY independent instrument that exercises the C3
# predicate in both directions (false-positive AND false-negative) — the full-scale
# two-instrument checks above are C3-free by scope. It replays TR-5 §3's published
# anchors (incl. TR-4 §4's "exactly 8" C6/C7 count among the 16,504 canonical
# completions, the README.md corroboration) plus three away-from-KW anchors whose
# expectations came from solve.c --estimate-knuth exact mode (leaf C3 528..1104; see
# verify.py _CROSS_PREFIXES). ~1 min in CPython — the sub-second subset of these
# anchors also runs on every `python3 tests.py` (TestSubtreeCrossAnchors); this is
# the full set. Wired 2026-08-06; previously the gate existed but ran only by hand.
if [ "$HAVE_PY" = "0" ]; then
  skip "verify.py --recount-subtree (C3 both-direction subtree anchors)" "needs python3"
else
  check "verify.py --recount-subtree (C3 both-direction subtree anchors)" \
    "python3 verify.py --recount-subtree | grep -q 'recount-subtree: ALL MATCH'"
fi

echo "== 3. DRAT certificates (regenerated CNF vs archived proof; all 21 archived certs) =="
# No SAT solver is invoked here — see the header note. $DRAT is probed in section 0.
declare -A CERTS=( [alt-le-14]="alt-le-14" [alt-ge-16]="alt-ge-16" \
  [moore-strict-near-2]="moore-strict-near-2" [rc4_near2_unsat]="rc4-strict-near-2" \
  [grand_ccn4_unsat]="grand-ccn4" \
  [grander_strict_unsat]="grander-strict" [grander_strict_near2_unsat]="grander-strict-near-2" \
  [grander_strict_near3_unsat]="grander-strict-near-3" [grander_strict_near4_unsat]="grander-strict-near-4" \
  [five_loo_parity_unsat]="five-loo-parity" [five_loo_rhythm_unsat]="five-loo-rhythm" \
  [five_loo_gender_unsat]="five-loo-gender" [five_loo_ccn4_unsat]="five-loo-ccn4" \
  [five_loo_ccn8_unsat]="five-loo-ccn8" \
  [core_parity_ccn4_unsat]="five-sub-parity+ccn4" [core_rhythm_ccn4_unsat]="five-sub-rhythm+ccn4" \
  [core_gender_ccn8_unsat]="gender-ccn8" \
  [ccn8_kwfail_unsat]="ccn8-kwfail" [ccn8_kwchain_not_unsat]="ccn8-kwchain-not" \
  [rigidity_sc4_unsat]="rigidity" [c3_kwpin_ge777_unsat]="kwpin-ge777" )
# The rigidity kernel (TR-5 SC-4) regenerates via its own flag, not --emit-cnf; the KW
# C3-exactness gate (kw-pin + C3 >= 777) needs the --c3-min flag; see the loop below.
# Completeness gate: every archived .drat.gz must be in the CERTS map above.
for f in reports/certificates/*.drat.gz; do b=$(basename "$f" .drat.gz)
  check "cert inventory covers $b" "[ -n \"\${CERTS[$b]+x}\" ]"
done
for cert in "${!CERTS[@]}"; do
  t=${CERTS[$cert]}
  # The TR-5 rigidity kernel has its own emitter flag (--rigidity-cnf, self-validating);
  # every other certificate regenerates through the --emit-cnf target table.
  if [ "$cert" = "rigidity_sc4_unsat" ]; then
    GEN="python3 sat.py --rigidity-cnf /tmp/roae_$t.cnf"
  elif [ "$cert" = "c3_kwpin_ge777_unsat" ]; then
    GEN="python3 sat.py --emit-cnf kw-pin /tmp/roae_$t.cnf --c3-min 777"
  else
    GEN="python3 sat.py --emit-cnf $t /tmp/roae_$t.cnf"
  fi
  if [ "$HAVE_DRAT" = "0" ] || [ "$HAVE_PY" = "0" ]; then
    skip "cert $cert ($t)" "needs python3 + drat-trim"
    continue
  fi
  check "cert $cert ($t)" \
    "$GEN && gunzip -kc reports/certificates/$cert.drat.gz > /tmp/roae_$t.drat && $DRAT /tmp/roae_$t.cnf /tmp/roae_$t.drat | grep -q 's VERIFIED'"
done

echo "== 3b. C3 positional witnesses (independent verify.py-path recheck) =="
if [ "$HAVE_PY" = "0" ]; then skip "c3_positional_witnesses.txt (42 witnesses)" "needs python3"; else
check "c3_positional_witnesses.txt (42 witnesses)" "python3 - <<'PYEOF'
import sys
sys.argv = ['verify.py']
import verify
g = c3 = None; n = 0
for ln in open('reports/certificates/c3_positional_witnesses.txt'):
    if ln.startswith('G='):
        head = ln.split('#')[0].split()
        g, c3 = int(head[0][2:]), int(head[1][3:])
    if not ln.startswith('SEQ='):
        continue
    seq = [int(x) for x in ln[4:].split()]
    assert sorted(seq) == list(range(64))                                 # permutation of H
    # C1 is the PAIRING predicate (SPECIFICATION.md: s_{i+1} = partner(s_i) for even i),
    # not permutation-ness. Until 2026-08-01 this line asserted only the permutation and
    # labelled it "C1, C4" — so a witness with broken pair structure would have passed the
    # 'independent recheck' these artifacts are advertised under. verify.PAIRS was already
    # imported for exactly this. (All 42 archived witnesses re-verified WITH pairing when the
    # gap was found: all pass. The data was sound; the checker was not.)
    _pairs = {frozenset(pr) for pr in verify.PAIRS}
    assert all(frozenset((seq[2*k], seq[2*k+1])) in _pairs for k in range(32))  # C1
    assert seq[:2] == [63, 0]                                             # C4 (oriented)
    assert all(verify.hamming(seq[i], seq[i+1]) != 5 for i in range(63))  # C2
    dist = [0]*7
    for i in range(63): dist[verify.hamming(seq[i], seq[i+1])] += 1
    assert dist == verify.KW_DIST                                         # C5
    assert verify.compute_comp_dist(seq) == c3 == 16 + 8*g                # C3/G
    n += 1
assert n == 42, n
PYEOF"
fi

echo "== 4. Lean kernel check (every lean/*.lean file) =="
# $LEAN resolved and probed in section 0 (plain `lean`, else the elan fallback).
for f in lean/*.lean; do
  if [ "$HAVE_LEAN" = "0" ]; then skip "$f" "needs lean (elan)"; continue; fi
  check "$f" "\"$LEAN\" \"$f\""
done

echo; echo "RESULT: $PASS passed, $FAIL failed, $SKIP skipped"
if [ "$SKIP" -gt 0 ]; then
  echo "NOTE: $SKIP check(s) did not run because a required tool is absent — a SKIP is NOT a"
  echo "      verification failure and NOT a pass. Exit status is nonzero until every check runs."
fi
[ "$FAIL" -eq 0 ] && [ "$SKIP" -eq 0 ]
