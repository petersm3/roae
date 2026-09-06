#!/usr/bin/env bash
# gate_published_consistency.sh — the three classes that dominated v3 lens B's surviving yield.
#
# WHY THIS EXISTS. Two independent Fable adjudications of Codex lens-B transcripts measured the same
# thing on documents at opposite ends of the maturity range:
#   TR-12 (a July spec patched through September, 1,198 lines, 43 findings) -> 17 survived (40%)
#   TR-6  (a settled report, 15 findings)                                   ->  6 survived (40%)
# Survival did NOT fall with maturity, and 0 of 58 findings were factually wrong about their
# document. What survived was overwhelmingly CROSS-DOCUMENT DRIFT: a claim that stopped being true
# when a sibling moved. Both adjudicators concluded, independently, that buying a consistency gate
# beats buying a 158-target adversarial pass that would rediscover these same classes 158 times.
#
# Verdict token: PUBLISHED_CONSISTENCY=PASS|FAIL — grep -qx it, never gate on output shape.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
fail=0

# ---- G1: unfilled placeholder tokens in PUBLISHED text -----------------------------------------
# A reader following `[REPRO-TAG]` gets nothing: the document's own resolver command returns no
# match against any of the repository's tags. Three lens-B findings collapsed to this one grep.
echo "== G1: unfilled placeholders in published reports =="
G1=$(grep -rnoE "\[(REPRO-TAG|EXPECTED-[A-Z0-9]+|STAGE-[FGT]-SHA-REGISTRY)\]" reports/ README.md 2>/dev/null || true)
if [ -n "$G1" ]; then
  echo "$G1" | sed 's/^/   [FAIL] /'
  echo "   $(echo "$G1" | grep -c .) unfilled placeholder(s) in published text"
  fail=1
else
  echo "   [ok]   no unfilled placeholders"
fi

# ---- G2: sampled-figure commands with no thread pin --------------------------------------------
# METHODS.md requires every reproduction command for a SAMPLED figure to carry its thread count;
# a sampled draw does not reproduce without it. Only real commands are checked -- a line must
# invoke ./solve, so prose ABOUT the estimator does not trip it.
echo "== G2: sampled-figure commands missing SOLVE_THREADS =="
# 🔴 NARROWED, and the first draft is why. Written broadly it fired on CORRECTIONS.md and
# CORRECTIONS_INVENTORY.tsv -- which MUST quote superseded commands verbatim, that being what a
# corrections ledger is for -- and on template forms (`<probes>`, `--estimate-knuth ...`) that are
# not runnable commands at all. That is the "gate correct data fails" class this project has hit
# five times, reproduced here in a gate written to stop a different one. A command only counts if
# it names a CONCRETE probe count.
# ZERO-PROBE RUNS ARE EXCLUDED, and that is not a loophole: `--estimate-knuth 0 <prefix>` performs
# no sampling at all -- it walks the prefix ladder deterministically -- so its output does not depend
# on thread count and METHODS' pin requirement, which exists for SAMPLED draws, does not apply.
# Second false-positive class found while red-testing this gate, after the corrections-ledger one.
G2=$(grep -rnE '`[^`]*\./solve --estimate-knuth +[1-9][0-9]*[^`]*`' reports/ documentation/ 2>/dev/null \
     | grep -v 'SOLVE_THREADS' \
     | grep -vE '^documentation/CORRECTIONS(_INVENTORY)?\.(md|tsv):' || true)
if [ -n "$G2" ]; then
  echo "$G2" | cut -c1-140 | sed 's/^/   [FAIL] /'
  fail=1
else
  echo "   [ok]   every published --estimate-knuth command carries a thread pin"
fi

# ---- G3: disclosures that have become FALSE ----------------------------------------------------
# 🔴 THIS GATE FIRES WHEN THE ARTIFACT EXISTS. A "no public artifact" disclosure is a claim about
# the repository, and it expires silently the moment the artifact ships. Registry:
# documentation/DISCLOSURE_CHECKS.tsv, one row per disclosure with the test that proves it.
echo "== G3: published disclosures that are now stale =="
REG=documentation/DISCLOSURE_CHECKS.tsv
if [ ! -r "$REG" ]; then
  echo "   [FAIL] $REG missing — the gate cannot run, which is a FAILURE, not a pass"; fail=1
else
  n=0
  while IFS=$'\t' read -r f claim test_cmd; do
    case "$f" in ''|'#'*) continue;; esac
    n=$((n+1))
    if ! grep -qF -- "$claim" "$f" 2>/dev/null; then
      echo "   [FAIL] $f no longer contains \"$claim\" — registry row is stale; remove it"; fail=1; continue
    fi
    if ( eval "$test_cmd" ) >/dev/null 2>&1; then
      echo "   [FAIL] $f says \"$claim\" but the artifact EXISTS — the disclosure understates what"
      echo "          this repository can prove. Test that fired: $test_cmd"; fail=1
    else
      echo "   [ok]   $f: \"$claim\" still true"
    fi
  done < "$REG"
  [ "$n" -gt 0 ] || { echo "   [FAIL] registry has zero rows — a vacuous gate is not a passing one"; fail=1; }
fi

echo
[ "$fail" -eq 0 ] && echo "PUBLISHED_CONSISTENCY=PASS" || echo "PUBLISHED_CONSISTENCY=FAIL"
exit 0
