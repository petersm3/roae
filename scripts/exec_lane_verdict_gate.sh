#!/usr/bin/env bash
# exec_lane_verdict_gate.sh — red-tested gate for two WRONG-VERDICT defects in exec_lane.sh.
#
# WHY THIS EXISTS (2026-09-07)
#   exec_lane.sh decides, for every documented command in the repo, whether what happened is a
#   PASS, a FAIL or a non-verdict SKIP. Two of those decisions were measured wrong, in opposite
#   directions — the two worst directions a verdict machine has:
#
#   D1  a RED that should be a SKIP.  solve.c's disk_iops_pre_check refuses with
#       "ERROR: projected fsync-wait ~%.1fh is %.0f%% of the estimated enum wall ~%.1fh."
#       (solve.c:4073) and main returns 31 (solve.c:43269). NO branch of run_one's classifier
#       matched that shape, so it fell through to the terminal `else outcome="FAIL(rc=$rc)"`.
#       `solve --preflight` is a gating row (documentation/SOLVE_C_CLI.md:58/:295) and bare
#       --preflight defaults to 560T, so the IOPS probe really runs: this host's slow disk was
#       being published as a defect in the documentation.
#
#   D2  a GREEN that should be a RED.  unbounded_branch() returned False for anything without
#       `--branch`/`--sub-branch`, so the BARE full-enum form `solve [time_limit] [threads]`
#       was never caught — and its time_limit ALSO defaults to 0, i.e. unbounded
#       (documentation/SOLVE_C_CLI.md:172-173). Those commands ran, hung, were killed at the
#       budget and landed SKIP-BUDGET: NON-gating. unbounded_branch's own docstring already
#       said the opposite policy — "This is a FAIL and never a SKIP: skipping it is the
#       could-not-fail shape the whole lane exists to refuse."
#
#   Both were fixed in exec_lane.sh on 2026-09-07. This gate exists so neither can silently
#   come back, and it was red-tested in BOTH directions against the pre-fix file.
#
# WHAT IT MEASURES, AND ON WHAT
#   It does NOT re-implement the logic it checks. Legs A and B EXTRACT the real decision text
#   out of scripts/exec_lane.sh — the classifier if/elif chain, and the unbounded_branch()
#   function — and evaluate THAT under controlled inputs. A copied predicate would pass while
#   the shipped one rotted, which is the failure this whole lane exists to refuse.
#   Leg C runs the lane's own `--list` (~1.6 s, extraction only, nothing executed).
#
# VERDICT
#   A single KEY=value token on stdout, matched by callers with `grep -qx`:
#       EXEC_LANE_VERDICT_GATE=PASS     every case measured and every case as expected
#       EXEC_LANE_VERDICT_GATE=FAIL     at least one case measured a wrong verdict
#       EXEC_LANE_VERDICT_GATE=ERROR    could not measure — extraction failed, --list failed,
#                                       or a leg ran zero cases
#   ERROR is NOT a pass. A gate that could not run must say so loudly: a check that silently
#   measures nothing is exactly the could-not-fail shape D2 was.
#
# USAGE
#   scripts/exec_lane_verdict_gate.sh            # check the shipped scripts/exec_lane.sh
#   EXEC_LANE_SH=/path/to/other.sh scripts/exec_lane_verdict_gate.sh
#        ^ point it at any candidate file. This is how the fix was red-tested: run it against a
#          copy of the PRE-fix exec_lane.sh and it must report FAIL, naming D1-A1 and D2-*.
#          A gate that has never been shown to fail has not been tested.
#   EXEC_LANE_GATE_VERBOSE=1                     # print every case, not just the failures

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LANE="${EXEC_LANE_SH:-$ROOT/scripts/exec_lane.sh}"
VERBOSE="${EXEC_LANE_GATE_VERBOSE:-0}"

NCASE=0; NBAD=0; ERRS=""
err() { ERRS="$ERRS  ERROR: $1"$'\n'; }
bad() { NBAD=$((NBAD+1)); printf '  FAIL  %-10s %s\n' "$1" "$2"; }
ok()  { [ "$VERBOSE" = "1" ] && printf '  ok    %-10s %s\n' "$1" "$2"; return 0; }

if [ ! -f "$LANE" ]; then
  echo "  ERROR: no such file: $LANE"
  echo "EXEC_LANE_VERDICT_GATE=ERROR"; exit 2
fi
echo "== exec_lane verdict gate =="
echo "   subject: $LANE"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/exec_lane_gate.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------- LEG A
# D1: the outcome classifier. Extract run_one's real if/elif chain and drive it directly.
# The chain is lifted verbatim between two anchors that occur exactly once each; it is
# wrapped in a function so its `local` declarations are legal outside run_one, and its two
# helper calls (doc_context, corpus_publishes_complete_form) are stubbed. Everything the
# chain decides with — $rc, $out, $cls, $org, $ctx, $lst — is supplied per case.
echo
echo "-- LEG A: outcome classifier (D1: host refusal must be SKIP-RESOURCE, not FAIL) --"
# Anchors are matched as FIXED strings (grep -F): the chain is shell source full of $, [ and (,
# and passing it through a regex engine — or through awk's own escape processing — silently
# matches nothing, which would have made leg A extract an empty chain and measure zero cases.
A_START='if   [ $docfail -eq 1 ] && [ $rc -ne 0 ]'
A_END='else outcome="FAIL(rc=$rc)"; fi'
a_n1="$(grep -cF -- "$A_START" "$LANE")"
a_n2="$(grep -cF -- "$A_END" "$LANE")"
if [ "$a_n1" != "1" ] || [ "$a_n2" != "1" ]; then
  err "leg A: classifier anchors not unique in $LANE (start=$a_n1 end=$a_n2) — refusing to guess"
else
  a_l1="$(grep -nF -- "$A_START" "$LANE" | cut -d: -f1)"
  a_l2="$(grep -nF -- "$A_END"   "$LANE" | cut -d: -f1)"
  sed -n "${a_l1},${a_l2}p" "$LANE" > "$TMP/chain.sh"
  if [ ! -s "$TMP/chain.sh" ]; then
    err "leg A: extracted an EMPTY classifier chain"
  else
    { echo 'doc_context() { printf "%s" "${DOC_CTX:-}"; }'
      echo 'corpus_publishes_complete_form() { return "${CORPUS_RC:-1}"; }'
      echo 'NDIFFU=0; DIFF_LINES=""; NBLDMISS=0; NUNDOC=0; NFRAG=0; NFRAGU=0'
      echo 'FRAG_LINES=""; STRICT_FRAG="${STRICT_FRAG:-0}"; budget=30; show=""; src=""; gat=1'
      echo 'classify() {'
      cat "$TMP/chain.sh"
      echo '  printf "%s\n" "$outcome"'
      echo '}'
      echo 'classify'
    } > "$TMP/harness.sh"
    if ! bash -n "$TMP/harness.sh" 2>"$TMP/harness.err"; then
      err "leg A: extracted chain does not parse: $(head -1 "$TMP/harness.err")"
    else
      # The exact bytes solve.c:4073 prints when disk_iops_pre_check refuses.
      REFUSAL='ERROR: projected fsync-wait ~55.1h is 402% of the estimated enum wall ~13.7h.
       Aggregate 210 fsync/sec over 8 concurrent threads (batch=1; ~40000000 fsyncs
       at this 560000000000000-node scale). The disk is likely too slow — fsync would
       dominate. Use Premium SSD, raise SOLVE_FSYNC_BATCH_SIZE (sha-neutral),
       or override with SOLVE_ALLOW_SLOW_IOPS=1 to proceed anyway.'
      # The exact bytes solve.c:4066 prints when it PASSES. Note it contains BOTH "fsync" and
      # the substring "fsync-wait" — which is why the fix anchors on "projected fsync-wait".
      PASSLINE='[hardening] disk-IOPS pre-check PASS: fsync ~3.1% of est enum wall (agg 9800 fsync/sec x8 threads, batch=1; ~0.02h fsync-wait vs ~13.7h est wall)'

      # case  rc  out            expected-prefix                        why
      run_a() { # $1=id $2=rc $3=out $4=expected-prefix $5=note
        NCASE=$((NCASE+1))
        local got
        got="$(docfail=0 rc="$2" out="$3" cls=RUN ctx=0 org=fence cmd="./solve --preflight" \
               lst=solve bash "$TMP/harness.sh" 2>/dev/null)"
        case "$got" in
          "$4"*) ok "$1" "$5" ;;
          *)     bad "$1" "$5"$'\n'"          expected prefix: $4"$'\n'"          got:             ${got:-<empty>}" ;;
        esac
      }
      # A1 is THE ISOLATING CASE for D1. Pre-fix this measures FAIL(rc=31); post-fix
      # SKIP-RESOURCE. Nothing else in the chain moves between those two files.
      run_a D1-A1 31 "$REFUSAL" "SKIP-RESOURCE(disk-IOPS" \
            "solve.c disk-IOPS refusal (rc=31) => SKIP-RESOURCE, not FAIL"
      # A2 pins the ORDER. A real out-of-space failure must still win over a slow-disk
      # projection, matching solve.c's own first_fail ordering — so the new branch has to
      # sit AFTER the allocation/disk branch, not before it.
      run_a D1-A2 31 "$REFUSAL
ERROR: No space left on device" "SKIP-RESOURCE(allocation/disk failure" \
            "disk-space failure still outranks the IOPS projection"
      # A3 is the other direction: the classifier must NOT swallow a real failure just
      # because the word "fsync" appears. The PASS line contains "fsync" AND "fsync-wait".
      run_a D1-A3 2 "$PASSLINE
error: something genuinely broke" "FAIL(rc=2)" \
            "IOPS PASS line does not launder a real nonzero exit into a skip"
      # A4 proves the harness itself can still see an ordinary verdict — without it, a
      # harness that produced "" for everything would score three green cases above.
      run_a D1-A4 0 "all good" "PASS" \
            "harness sanity: rc=0 still classifies PASS"
    fi
  fi
fi

# ---------------------------------------------------------------------------- LEG B
# D2: unbounded_branch(). Extract the real function out of the extractor's python heredoc
# and drive a case table through it. Table-driven in BOTH directions: commands that must be
# flagged, and commands that must NOT be — an over-broad predicate that flagged every
# `solve` line would be just as wrong as the under-broad one being fixed.
echo
echo "-- LEG B: unbounded_branch (D2: the BARE solve [time_limit] form must be caught) --"
if [ "$(grep -c '^def unbounded_branch(c):' "$LANE")" != "1" ]; then
  err "leg B: 'def unbounded_branch(c):' is not unique in $LANE — cannot extract"
else
  awk '/^def unbounded_branch\(c\):/{f=1} f && /^def gating/{exit} f{print}' "$LANE" > "$TMP/ub.py"
  if [ ! -s "$TMP/ub.py" ]; then
    err "leg B: extracted an EMPTY unbounded_branch"
  else
    B_OUT="$TMP/legb.out"
    { echo 'import re, sys'; cat "$TMP/ub.py"; cat <<'PYCASES'
# (expected, command, note). True = must be flagged FAIL-UNBOUNDED (never executed).
CASES = [
  # --- must be FLAGGED: every one of these runs to completion and never returns ---
  (True,  'solve 0',                                   'bare, explicit 0'),
  (True,  './solve 0',                                 'bare with ./ (HISTORY.md:4582)'),
  (True,  './solve 0 128',                             'bare with threads'),
  (True,  'SOLVE_THREADS=128 ./solve 0 128',           'ISOLATING CASE (SOLVE_C_CLI.md:429)'),
  (True,  'SOLVE_RESUME_HISTORY="2026-05-14T18:23:00Z=spot-eviction-at-90%" ./solve 0 64',
                                                       'ISOLATING CASE (DEVELOPMENT.md:585): the'
                                                       ' assignment value holds an = and must be'
                                                       ' stripped quote-aware'),
  (True,  'SOLVE_A="x y z" ./solve 0',                 'assignment value with SPACES'),
  (True,  'solve',                                     'no time_limit at all: default 0'),
  (True,  './solve',                                   'ditto, with ./'),
  (True,  'solve 0 64',                                'bare (BRANCHES_EXPLAINED.md:383)'),
  (True,  './solve --branch 24 0 0',                   'REGRESSION: --branch still caught'),
  (True,  './solve --sub-branch 1 0 2 0 3 0 0 64',     'REGRESSION: --sub-branch still caught'),
  # --- must NOT be flagged ---
  (False, './solve 3600',                              'a real budget is bounded'),
  (False, './solve 3600 128',                          'real budget + threads'),
  (False, 'SOLVE_NODE_LIMIT=1000 ./solve 0',           'explicit node budget bounds it'),
  (False, 'SOLVE_PER_SUB_BRANCH_LIMIT=63146557 ./solve 0', 'any SOLVE_*LIMIT bounds it'),
  (False, './solve --branch 24 0 3600',                'REGRESSION: bounded --branch'),
  (False, 'solve --selftest',                          'subcommand, not the bare form'),
  (False, 'solve --merge out.bin',                     'subcommand with an operand'),
  (False, './solve --preflight',                       'subcommand: D1s own command'),
  (False, './solve --verify',                          'subcommand'),
  (False, 'python3 solve.py 0',                        'solve.py is a different program'),
  (False, './verify solve 0',                          'solve as a non-leading ARGUMENT'),
  (False, 'solve 0 64 == solve --branch p1 o1',        'prose/pseudocode, not a command'),
]
nbad = 0
for exp, cmd, note in CASES:
    got = bool(unbounded_branch(cmd))
    tag = 'ok  ' if got == exp else 'FAIL'
    if got != exp: nbad += 1
    print('%s\t%s\t%r\t%s' % (tag, 'flag' if exp else 'pass', cmd, note))
print('CASES=%d' % len(CASES))
print('BAD=%d' % nbad)
PYCASES
    } > "$TMP/legb.py"
    # NOTE: capture first, match after. Never `python3 ... | grep -q` under pipefail --
    # grep -q exits at the first match, SIGPIPEs the producer, the pipeline reports 141 and
    # a real match reads as no match. That inversion is the bug class this whole gate is about.
    if ! python3 "$TMP/legb.py" > "$B_OUT" 2>"$TMP/legb.err"; then
      err "leg B: case table could not run: $(tail -1 "$TMP/legb.err")"
    else
      b_total="$(sed -n 's/^CASES=//p' "$B_OUT" | tail -1)"
      b_bad="$(sed -n 's/^BAD=//p' "$B_OUT" | tail -1)"
      case "${b_total:-x}${b_bad:-x}" in
        *[!0-9]*) err "leg B: no case count reported — refusing to call that a pass" ;;
        *)
          if [ "$b_total" -eq 0 ]; then
            err "leg B: ZERO cases in the table"
          else
            NCASE=$((NCASE+b_total))
            NBAD=$((NBAD+b_bad))
            [ "$VERBOSE" = "1" ] && grep -v '^CASES=\|^BAD=' "$B_OUT" | sed 's/^/  /'
            if [ "$b_bad" -gt 0 ]; then
              grep '^FAIL' "$B_OUT" | sed 's/^/  /'
            fi
            printf '  %d/%d cases as expected\n' "$((b_total-b_bad))" "$b_total"
          fi ;;
      esac
    fi
  fi
fi

# ---------------------------------------------------------------------------- LEG C
# End-to-end on the real corpus, via the lane's own --list (extraction only, nothing executed,
# ~1.6 s). The assertion is deliberately written so it stays true after the DOCS get fixed:
#   * anything classed FAIL-UNBOUNDED must genuinely be unbounded, and
#   * NO command matching the bare unbounded shape may still be sitting in a runnable class.
# If every doc site is repaired tomorrow, both counts go to zero and the invariant still holds.
# What it can never do is pass while an unbounded full enumeration is queued to RUN.
echo
echo "-- LEG C: end-to-end --list on the corpus (nothing is executed) --"
C_OUT="$TMP/list.txt"
bash "$LANE" --tree "$ROOT" --list > "$C_OUT" 2>"$TMP/list.err"; c_rc=$?
# $? is captured on its own line: reading it inside the `if` message would report the status
# of the `if` itself, not of the lane -- the message would say rc=0 about a failed run.
if [ "$c_rc" -ne 0 ]; then
  err "leg C: '--list' failed (rc=$c_rc): $(tail -1 "$TMP/list.err")"
else
  n_ext="$(sed -n 's/^EXEC_LANE_EXTRACTED=//p' "$C_OUT" | tail -1)"
  case "${n_ext:-x}" in
    ''|*[!0-9]*) err "leg C: --list reported no EXEC_LANE_EXTRACTED count" ;;
    *)
      if [ "$n_ext" -eq 0 ]; then
        err "leg C: --list extracted ZERO commands — measured nothing, so nothing is proven"
      else
        NCASE=$((NCASE+1))
        # C1: no bare unbounded full-enum command may remain in a RUN/BUILD class. This is the
        # end-to-end form of D2. Pre-fix it measures 6 such rows; post-fix, 0.
        #
        # The shape is re-stated here INDEPENDENTLY rather than by calling the extracted
        # unbounded_branch: routing this leg through the same predicate the extractor already
        # applied would agree with it by construction and could never go red. Independence is
        # what makes it a check. It is anchored to the COMMAND FIELD (columns 5..NF of a --list
        # row) — matching anywhere in the row would hit `pgrep -x solve` and `numactl ... ./solve`,
        # neither of which is the bare form this fix governs.
        # `|| true`: grep exits 1 on no-match, which is the PASSING state here.
        leaked="$(awk '$1=="RUN"||$1=="BUILD" {
                         c=""; for (i=5; i<=NF; i++) c = c (i>5 ? " " : "") $i
                         if (c ~ /^([A-Za-z_][A-Za-z0-9_]*=("[^"]*"|[^ ]*) +)*(\.\/)?solve( +0( +[0-9]+)?)? *$/)
                           print
                       }' "$C_OUT" \
                  | grep -vE 'SOLVE_[A-Z0-9_]*LIMIT[[:space:]]*=' || true)"
        if [ -n "$leaked" ]; then
          bad D2-C1 "$(printf '%s\n' "$leaked" | wc -l) unbounded command(s) still in a runnable class:"
          printf '%s\n' "$leaked" | sed 's/^/            /'
        else
          ok D2-C1 "no unbounded bare-solve command is queued to RUN"
        fi
        # C2: the other direction — whatever IS flagged must really be unbounded. A budgeted
        # command wrongly parked in FAIL-UNBOUNDED would be a manufactured red.
        NCASE=$((NCASE+1))
        mis="$(grep '^FAIL-UNBOUNDED' "$C_OUT" | grep -E 'SOLVE_[A-Z0-9_]*LIMIT[[:space:]]*=' || true)"
        if [ -n "$mis" ]; then
          bad D2-C2 "budgeted command wrongly flagged unbounded:"
          printf '%s\n' "$mis" | sed 's/^/            /'
        else
          ok D2-C2 "nothing budgeted is flagged unbounded"
        fi
        printf '  %s commands extracted; %s flagged FAIL-UNBOUNDED\n' \
               "$n_ext" "$(grep -c '^FAIL-UNBOUNDED' "$C_OUT" || true)"
      fi ;;
  esac
fi

# ---------------------------------------------------------------------------- VERDICT
echo
if [ -n "$ERRS" ]; then
  printf '%s' "$ERRS"
  echo "EXEC_LANE_VERDICT_GATE_CASES=$NCASE"
  echo "EXEC_LANE_VERDICT_GATE=ERROR"
  exit 2
fi
if [ "$NCASE" -eq 0 ]; then
  echo "  ERROR: zero cases measured. A gate that measured nothing has proven nothing."
  echo "EXEC_LANE_VERDICT_GATE_CASES=0"
  echo "EXEC_LANE_VERDICT_GATE=ERROR"
  exit 2
fi
echo "EXEC_LANE_VERDICT_GATE_CASES=$NCASE"
echo "EXEC_LANE_VERDICT_GATE_BAD=$NBAD"
if [ "$NBAD" -gt 0 ]; then
  echo "EXEC_LANE_VERDICT_GATE=FAIL"
  exit 1
fi
echo "EXEC_LANE_VERDICT_GATE=PASS"
exit 0
