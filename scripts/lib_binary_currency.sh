#!/usr/bin/env bash
# lib_binary_currency.sh — establish that a compiled `solve` binary corresponds to solve.c.
# Sourced by gates; not executable on its own.
#
# ============================================================================================
# WHY THIS EXISTS
# ============================================================================================
# MEASURED 2026-09-07/08. scripts/resume_budget_infinity_gate.sh reported
#     RESUME_BUDGET_INFINITY=FAIL — "budget 0 is being read as 'no constraint' instead of infinity"
# which asserts an UNDERCOUNT PRESENTED AS A COMPLETE ENUMERATION, this project's worst error
# class. It was not true. The gate's own logic was sound — it checks both directions from one
# binary precisely so it cannot pass on an engine that never skips. What was wrong was its
# SUBJECT: `BIN=${BIN:-./solve}` names a PATH, and nothing established that the path's contents
# corresponded to the source the gate was making an assertion about. The ./solve lying in the
# working directory was dated 2026-09-05; the fix (779fff4c) landed 2026-09-07. Same gate, same
# tree, two verdicts:
#     ./solve on disk (2026-09-05)   -> FAIL
#     built from HEAD (fc427bf7)     -> PASS
# So a gate was announcing a live undercount in an engine where the defect had been fixed for two
# days, and it defaulted into that state simply because a stale artifact was on disk. A gate whose
# subject is "whatever binary happens to be there" is not testing the engine; it is testing the
# housekeeping.
#
# ERROR, NEVER FAIL. An unestablished subject is not a defect. Reporting it as one sends a reader
# hunting a bug that is not there — which is exactly the cost that was paid above. Every caller
# emits its own ERROR token; this library only decides and explains.
#
# ============================================================================================
# THE SIGNAL, AND WHY IT BEATS mtime
# ============================================================================================
# The PUBLISHED build line (documentation/VERIFY.md) bakes the source hash into the binary:
#     gcc ... -DGIT_HASH="\"...\"" -DSOURCE_SHA="\"$(sha256sum solve.c | cut -d' ' -f1)\"" ...
# so a binary built that way LITERALLY CARRIES the sha256 of the solve.c it was compiled from.
# That is an exact, content-bound identity. mtime is a proxy for it and a weak one: `touch ./solve`
# defeats mtime completely, and a checkout or a `cp -p` can reorder the two timestamps without
# anything being rebuilt.
#
# MEASURED, both directions, 2026-09-08:
#   solve.c at HEAD                  sha256 8dde23e4230e44b7c4e9003a4cb7b59d39e935557da67c1a9c97912f5298549e
#   binary built from it (pub. line) `strings -a` contains that sha                      -> 1 hit
#   ./solve dated 2026-09-05         0 hits for the current sha                          -> 0 hits
#
# 🔴 A 64-HEX STRING IN THE BINARY IS NOT AUTOMATICALLY A SOURCE_SHA. solve.c carries four 64-hex
# literals of its own — the canonical selftest sha 403f7202... (solve.c:478, :1200, :1580) and
# three all-one-digit placeholders. An early draft of this library read 403f7202... out of the
# stale ./solve and concluded it was that binary's SOURCE_SHA, i.e. that the binary came from some
# uncommitted tree. WRONG: it is a constant present in EVERY build, current ones included. The
# stale ./solve embeds no SOURCE_SHA at all (it holds the "unknown" default, solve.c:389 — five
# occurrences). Hence the FOREIGN set below subtracts solve.c's own literals before concluding
# anything, and the fact that a stale binary may carry NO usable signal whatsoever is why the
# mtime arm is still needed and is not dead code.
#
# MATCHING IS BY SUBSTRING, DELIBERATELY. The published line embeds the bare 64-hex sha as its own
# `strings` line, but a hand-rolled build with one more layer of shell quoting embeds it framed in
# literal double quotes ("8dde23e4..."). Both were produced and inspected today. Plain `grep -F`
# on the bare sha matches both framings; an anchored `grep -xF` matches only the first and would
# have called a correctly-built binary stale. A 64-hex substring collision is not a concern.
#
# 🔴 PIPELINE HYGIENE. Callers run under `set -o pipefail`, where a `grep -q` that exits on its
# first match SIGPIPEs its producer, the PIPELINE then reports failure, and A MATCH READS AS NO
# MATCH — which would invert this verifier exactly as the stale binary inverted the gate above.
# The main arm therefore greps the IMAGE DIRECTLY (`grep -a -F -q -e "$want" "$bin"`, no pipe at
# all, so grep's own status IS the answer) — the same idiom as manifest_zero_entry_gate.sh's
# build_verified(). The foreign-sha arm below does need a pipeline; it ends in `awk NR==1`, which
# consumes all input, never `head -1`, which would not.
#
# A THIRD, STRONGER SIGNAL EXISTS where the binary can be cheaply run: solve.c emits SOURCE_SHA at
# runtime (`source_sha=` in the --kc-record provenance trailer, solve.c:23475/:24106; also
# "build_source_sha" in solve_results.json, solve.c:11922). scripts/q326_kc_unrank_m0_gate.sh:63-66
# already compares that against `sha256sum solve.c`. Asking the binary is better than reading its
# image, but it costs a run and needs a subcommand the gate is not otherwise using; the image grep
# is universal and free, so that is what this library does.
#
# ============================================================================================
# THE LADDER  (first rule that applies wins)
# ============================================================================================
#   binary embeds the CURRENT solve.c sha        -> CURRENT   (rc 0, signal source-sha)
#       A binary built from older source cannot contain the newer source's hash, and solve.c
#       cannot contain its own hash, so presence is proof and has no false-positive arm.
#   binary embeds a FOREIGN 64-hex sha           -> STALE     (rc 1, signal foreign-sha)
#       "Foreign" = a 64-hex string in the binary that is neither the current source sha nor any
#       of solve.c's own 64-hex literals. The only way such a string gets in is -DSOURCE_SHA from
#       a DIFFERENT solve.c. This arm is what closes the hole mtime alone leaves: `touch ./solve`
#       makes a stale binary look new, and this rule is indifferent to timestamps entirely.
#   sha absent, and solve.c is NEWER than binary -> STALE     (rc 1, signal mtime)
#   sha absent, and binary is newer or equal     -> CURRENT, weak (rc 0, signal mtime-weak)
#       "Absent" does not mean stale: several gates build with a bare `gcc -O2 ... -o solve solve.c`
#       and no -DSOURCE_SHA, leaving SOURCE_SHA at its "unknown" default (solve.c:389). Those
#       binaries are current BY CONSTRUCTION. Erroring on them would be a false ERROR, which is
#       the same disease in the other direction. This arm is exactly as strong as the mtime guard
#       it replaces — no weaker — and the sha arm above is a strict addition to it.
#       🔴 It is NOT proof. solve.c:25272 records the matching fail-open on the engine side:
#       a build passing neither -DGIT_HASH nor -DSOURCE_SHA leaves both "unknown", and
#       "unknown" == "unknown" compares EQUAL. Callers should say "not established", not "verified".
#
# ============================================================================================
# USAGE
# ============================================================================================
#   . "$(dirname "$0")/lib_binary_currency.sh"
#   if ! solve_binary_currency "$BIN" "$ROOT/solve.c"; then
#     echo "   [ERROR] $BINCUR_MSG"; echo "MY_GATE=ERROR"; exit 2
#   fi
# Sets, on every path:  BINCUR_MSG (human text)  BINCUR_SIGNAL (source-sha|mtime|mtime-weak|
# foreign-sha|no-source|no-binary)  BINCUR_WANT (the current source sha, or empty).
#
# Authored by Claude (ROAE lane, 2026-09-08), generalising the guard landed the same night in
# scripts/resume_budget_infinity_gate.sh. Errors here are mine; corrections invited.

# shellcheck shell=bash

solve_binary_currency() {   # solve_binary_currency <binary> [solve.c]
  local bin=${1-} src=${2-solve.c}
  BINCUR_MSG=""; BINCUR_SIGNAL=""; BINCUR_WANT=""

  if [ -z "$bin" ] || [ ! -x "$bin" ]; then
    BINCUR_SIGNAL="no-binary"
    BINCUR_MSG="no executable binary at '${bin:-<empty>}' — nothing to establish currency for."
    return 1
  fi
  if [ ! -f "$src" ]; then
    # No source to compare against is not evidence of currency. Say so; do not pass.
    BINCUR_SIGNAL="no-source"
    BINCUR_MSG="no source at '$src' — cannot establish that $bin corresponds to anything."
    return 1
  fi

  local want
  want=$(sha256sum "$src" 2>/dev/null | cut -d' ' -f1)
  BINCUR_WANT="$want"

  # Same idiom as scripts/manifest_zero_entry_gate.sh's build_verified(): grep the IMAGE directly.
  # NOT a pipeline, so grep's own status is the answer and there is no producer to SIGPIPE.
  if [ -n "$want" ] && grep -a -F -q -e "$want" "$bin" 2>/dev/null; then
    BINCUR_SIGNAL="source-sha"
    BINCUR_MSG="$bin embeds SOURCE_SHA ${want:0:12}… = sha256($src): built from this exact source."
    return 0
  fi

  # FOREIGN-SHA ARM. Any 64-hex string in the image that is neither the current source sha nor one
  # of solve.c's own literals can only have come from -DSOURCE_SHA on a DIFFERENT source. This is
  # the arm that survives `touch`: it never looks at a timestamp.
  # `awk NR==1` and not `head -1`: awk drains the pipe, head would close it early and SIGPIPE
  # `sort`, which under the caller's `set -o pipefail` is the same trap described above.
  local foreign
  foreign=$(strings -a "$bin" 2>/dev/null | grep -oE '[0-9a-f]{64}' | sort -u \
            | grep -vxF -f <( { grep -oE '[0-9a-f]{64}' "$src" 2>/dev/null; printf '%s\n' "$want"; } \
                              | sort -u ) \
            | awk 'NR==1{print}') || true
  # `|| true` is load-bearing. `grep -vxF` exits 1 when it filters everything out — the NORMAL
  # case for a current binary — and under a caller's `set -euo pipefail` that would abort this
  # function before it reached the mtime arm, returning 1 with an EMPTY BINCUR_SIGNAL. Today every
  # caller invokes this inside an `if`, where errexit is suppressed, so the bug is latent rather
  # than live; a future bare call would wake it. The value is what matters here, never the status.
  if [ -n "$foreign" ]; then
    BINCUR_SIGNAL="foreign-sha"
    BINCUR_MSG="$bin carries SOURCE_SHA ${foreign:0:12}… but $src hashes to ${want:0:12}… — the
           binary was built from a DIFFERENT source and cannot attest anything about this one.
           (Timestamps were not consulted: this is a content comparison, so touching the
           binary does not change the answer.)"
    return 1
  fi

  if [ "$src" -nt "$bin" ]; then
    BINCUR_SIGNAL="mtime"
    BINCUR_MSG="$bin is OLDER than $src and does not embed its sha (${want:0:12}…) — it cannot attest
           anything about the current source. Rebuild it, or point the gate at a binary you
           know matches. The published build line in documentation/VERIFY.md bakes in
           -DSOURCE_SHA, which makes this check exact rather than a timestamp guess."
    return 1
  fi

  BINCUR_SIGNAL="mtime-weak"
  BINCUR_MSG="$bin is not older than $src, but carries no SOURCE_SHA — currency is assumed from
           timestamps, NOT established. Rebuild with documentation/VERIFY.md's published line
           (it passes -DSOURCE_SHA) to make this exact."
  return 0
}
