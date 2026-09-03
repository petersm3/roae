#!/usr/bin/env bash
# One-command verification of the ROAE technical-report suite's machine-checkable claims.
# Requirements (SOFTWARE): gcc, python3, drat-trim, lean (elan), and git -- the last one for
#   SECTION 7 ONLY, because scripts/doc_gates.sh enumerates the documentation corpus with
#   `git ls-files`, so a tarball export with no work tree cannot run it (added 2026-09-02 with
#   sections 5-7). See reports/METHODS.md for versions.
# Requirements (HARDWARE) -- added 2026-08-21, and they are NOT optional:
#   RAM   : >= 12 GB free. The Lean phase peaks at ~9.6 GB resident on Automorphism.lean and
#           ~8.0 GB on KingWen.lean; an 8 GB host CANNOT check those two files
#           [CORRECTED 2026-08-28: this named PruneGInvariance.lean as the second-heaviest file.
#            It is not, and lean/README.md's own table said so all along (~4.1 GB). Full 13-module
#            re-measurement on an 8 vCPU / 31 GB host: Automorphism 9.33 GB, KingWen 7.98 GB,
#            PruneGInvariance 4.05 GB. The >= 12 GB requirement is UNCHANGED and was never wrong --
#            only the file named as the reason for it.]
#           (lean/README.md SS"Verify yourself" carries the measured per-file table).
#   STACK : ulimit -s unlimited, if you also run --estimate-knuth by hand. main's frame is
#           ~7.23 MB and the estimator adds ~1.02 MB, so an 8 MB default stack SIGSEGVs.
#           This script does not invoke the estimator; the binary now refuses with a clear
#           message rather than segfaulting.
#   DISK  : ~2 GB scratch. CPU: any; the checks are not core-hungry and do not need a big VM.
#   These were previously stated only in lean/README.md and in a comment further down this
#   file. A cold external-reviewer pass on a 4 GB host hit ERROR 134 on all 13 Lean files and
#   reported them as unverifiable -- the requirement was documented, just not where a
#   replicator reads it.
#   OPTIONAL: cake_lpr (formally verified LRAT checker) — section 3c runs it only when CAKE_LPR is
#   set; by default that section emits CAKE_LPR_LEG=NOT_RUN and the run is drat-trim-only.
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
RESOURCE=0
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
#
# A HOST THAT RAN OUT OF MEMORY IS A THIRD OUTCOME (added 2026-08-09), the same principle applied
# once more. The Lean checks are memory-hungry — lean/README.md §"Verify yourself" measures the
# suite ceiling at ~9.6 GB peak RSS and states outright that an 8 GB host CANNOT check
# Automorphism.lean or KingWen.lean — so the OOM killer reaching a `lean` process is a routine
# replicator experience, not an exotic one. Until 2026-08-09 that arrived as "FAIL lean/…",
# indistinguishable in the summary from a proof the kernel rejected: the same wrong conclusion the
# tool probing above was written to prevent. Such a check is now reported ERROR and tallied
# separately. SCOPE LIMIT, stated plainly: this is a heuristic on the exit status and the captured
# output (see is_resource_status), and it is one-directional. It catches three signal statuses
# (137 = SIGKILL, what the kernel OOM killer sends; 139 = SIGSEGV; 134 = SIGABRT, how an uncaught
# C++ bad_alloc terminates) and allocator messages. Any other nonzero exit is still counted FAIL,
# so a FAIL is NOT proof that the environment was fine. If a FAIL appears on a host near its
# memory ceiling, read $LOG before believing it. An ERROR does not pass the run either; the exit
# status is 0 only when every check ran AND every check passed.

# True when a nonzero status $1 looks like the host, not the claim, gave out. Fixed-string
# matching only, and scoped to the bytes THIS check appended ($2 = the log's SIZE IN BYTES before
# it ran). The window matters: a first cut grepped a fixed tail of the log and promoted a later
# genuine FAIL to ERROR on an allocator message left behind by an earlier check — which would
# have hidden exactly the failed proof this file exists to surface. Bytes, not `wc -l` lines:
# output with no trailing newline (what a process killed mid-write leaves) shifts a line-based
# window by one and re-admits the previous check's last line — measured 2026-08-09.
# The status test is enumerated, NOT a bare `-ge 128`: measured 2026-08-09, this script's own
# `set -o pipefail` reports 141 for a `| grep -q` check whose grep MATCHED, and `exit 255` is not
# a signal at all — both read as ERROR under `-ge 128`.
# NB: plain `grep -F … >/dev/null`, deliberately NOT `grep -Fq`. Under this script's `set -o
# pipefail`, -q makes grep exit at the first match, SIGPIPEs `tail`, and the pipeline reports 141
# — so a real match reads as "no match" and the ERROR silently downgrades to FAIL. The race is
# size-dependent, which is what makes it nasty: measured here at 200/200 occurrences on a
# 200k-line log and 0/200 without -q, while on a short log it can go the other way and look fine.
# Without -q grep drains its input, so the status is grep's own. Do not "tidy" the -q back in.
is_resource_status() {
  case "$1" in 134|137|139) return 0 ;; esac
  # Q-347: 'failed to create thread' added 2026-08-28. An ADDRESS-SPACE cap (ulimit -v) starves
  # thread-stack reservation long before RSS is anywhere near a memory limit — measured on this
  # harness, Lean died at ~480 MB RSS under a 4 GB -v cap. That message is not an allocator string,
  # so without it the classification rested on exit code alone.
  tail -c +"$(( $2 + 1 ))" "$LOG" | grep -F -e 'std::bad_alloc' -e 'out of memory' \
    -e 'Out of memory' -e 'Cannot allocate memory' -e 'cannot allocate memory' \
    -e 'MemoryError' -e 'failed to create thread' >/dev/null && return 0
  return 1
}

LAST_RC=-1                     # status of the most recent check(); -1 = none ran (read by section 3)
check() {
  local rc before
  before=$(wc -c < "$LOG")
  { echo "### $1"; eval "$2"; } >>"$LOG" 2>&1
  rc=$?
  LAST_RC=$rc
  if [ "$rc" -eq 0 ]; then echo "PASS  $1"; PASS=$((PASS+1))
  elif is_resource_status "$rc" "$before"; then
    echo "ERROR $1   (host resources: exit $rc, killed or out of memory — NOT a failed proof; output: $LOG)"
    RESOURCE=$((RESOURCE+1))
  else echo "FAIL  $1   (output: $LOG)"; FAIL=$((FAIL+1)); fi
}
skip() { echo "SKIP  $1   ($2)"; SKIP=$((SKIP+1)); }

# --- CLASS-B SWEEP 2026-09-02: no check may pipe a producer into `grep -q` --------------------
# The note above is_resource_status explains this hazard and was written when THAT function was
# fixed. The `check` CALL SITES below it were not swept, so the reasoning landed in 2026-08-09 and
# the four siblings did not (§1 --selftest, §2 registry-verify, §2 recount-subtree, and §3's
# drat-trim replay). Restated here because the fix now lives in two places and each has to be
# able to justify itself alone:
#   Under this script's `set -o pipefail`, `producer | grep -q PAT` returns the PRODUCER's exit
#   status, and `grep -q` stops reading at the first match — which SIGPIPEs the producer, so a
#   check that genuinely PASSED reports 141 and prints FAIL. It is size-dependent, which is what
#   makes it nasty: it looks fine on a short output and breaks the day the tool gets chattier.
#   MEASURED 2026-09-02 against this file's own check(): a producer that prints the pattern and
#   then 200,000 lines and exits 0 reported **FAIL** through the pipe and **PASS** through
#   require_match. The same run showed the second, unconditional half of the defect — $LOG gained
#   only the 14-byte "### <label>" banner, so the tool's own words never reached the log a
#   replicator is told to read. For the drat-trim site that means the PASS line was this script's
#   assertion about the checker rather than the checker's verdict (Codex V2-14).
# require_match therefore:
#   * captures instead of piping, and ECHOES the capture, so $LOG holds the tool's own output;
#   * requires BOTH a zero producer status AND the match, so it is not weaker than the pipeline
#     it replaces — a producer that prints the pattern and then dies still FAILs;
#   * returns the PRODUCER's status unchanged when nonzero, so is_resource_status still sees
#     134/137/139 and still reports ERROR rather than FAIL;
#   * matches with a bash `case`, NOT a second pipeline, so the race cannot be reintroduced here.
#     The pattern is quoted inside the case, which makes it a literal test — the same fixed-string
#     semantics as the `grep` it replaces, neither wider nor narrower.
require_match() {          # $1 = fixed string that MUST appear; $2.. = command and arguments
  local pat=$1; shift
  local out rc
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] || { echo "NONZERO EXIT $rc from: $*"; return "$rc"; }
  case $out in
    *"$pat"*) return 0 ;;
    *) echo "EXPECTED OUTPUT NOT FOUND: $pat"; return 1 ;;
  esac
}

# Same contract as require_match, plus a COUNT FLOOR — because exit status alone is fail-open for
# a test suite: `unittest` exits 0 when it collects ZERO tests, so "every test passed" and "an
# import error emptied the suite" are the same status. A floor rather than an equality so a suite
# that GROWS keeps passing while one that silently SHRANK fails. Emits a whole-line verdict token.
require_floor() {          # $1 = token name  $2 = floor  $3 = text before N  $4 = text after N
  local tok=$1 floor=$2 pre=$3 post=$4; shift 4   # $5.. = command and arguments
  local out rc line n=""
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] || { echo "NONZERO EXIT $rc from: $*"; return "$rc"; }
  while IFS= read -r line; do                     # here-string, not a pipe: see the note above
    case $line in *"$pre"*"$post"*) n=${line#*"$pre"}; n=${n%%"$post"*} ;; esac
  done <<< "$out"
  case $n in ''|*[!0-9]*)
    echo "$tok=ABSENT"
    echo "COUNT LINE NOT FOUND: expected a number between '$pre' and '$post'"; return 1 ;;
  esac
  echo "$tok=$n"
  [ "$n" -ge "$floor" ] || { echo "COUNT BELOW FLOOR: $n < $floor"; return 1; }
  return 0
}

# SIBLING SWEPT 2026-09-02, one line below the class-B site above: `diff <(A) <(B)` is fail-open.
# Process substitution does not propagate either producer's exit status — `pipefail` does not
# reach inside `<()` — so if BOTH instruments fail and print nothing to stdout, diff compares two
# EMPTY streams and returns 0, and the two-language gate PASSES on a run where neither instrument
# produced anything. MEASURED 2026-09-02: `diff <(false) <(false)` -> rc 0; so does a pair that
# writes its error to stderr and exits 1. This is the same shape as the grep -q sites (a status
# that never reaches the verdict), which is why it is fixed in the same pass rather than filed.
# require_agree keeps the comparison identical and adds the two things `diff` cannot see: that
# both producers exited 0, and that each side actually emitted something. The floor is a LINE
# COUNT because "two empty streams compare equal" is the exact failure being closed.
# It returns the FAILING PRODUCER's status, so is_resource_status still classifies 134/137/139.
require_agree() {  # $1 = token name  $2 = minimum lines per side  $3 = command A  $4 = command B
  local tok=$1 minl=$2 A=$3 B=$4
  local fa fb ra rb na nb rc=0
  fa=$(mktemp "${TMPDIR:-/tmp}/roae_agree_a.XXXXXX") || { echo "$tok=MKTEMP_FAILED"; return 1; }
  fb=$(mktemp "${TMPDIR:-/tmp}/roae_agree_b.XXXXXX") || { echo "$tok=MKTEMP_FAILED"; rm -f "$fa"; return 1; }
  eval "$A" > "$fa"; ra=$?      # stderr is NOT redirected: check() already sends it to $LOG
  eval "$B" > "$fb"; rb=$?
  na=$(wc -l < "$fa"); nb=$(wc -l < "$fb")
  echo "$tok=rcA:$ra,rcB:$rb,linesA:$na,linesB:$nb"
  if [ "$ra" -ne 0 ] || [ "$rb" -ne 0 ]; then
    echo "AN INSTRUMENT DID NOT RUN: exit $ra (A) / $rb (B) — this is NOT a disagreement"
    rc=$ra; if [ "$rc" -eq 0 ]; then rc=$rb; fi
  elif [ "$na" -lt "$minl" ] || [ "$nb" -lt "$minl" ]; then
    echo "OUTPUT BELOW FLOOR: $na / $nb line(s), floor $minl — two empty streams compare EQUAL"
    rc=1
  elif ! diff "$fa" "$fb"; then
    rc=1
  fi
  rm -f "$fa" "$fb"
  return "$rc"
}

# WHOLE-LINE VERDICT, TWO LEGS, LOG FIRST (added 2026-09-02, lane S-1/S-2). require_match above is a
# SUBSTRING test on the captured output, which is the right shape for a producer whose sentence
# carries the verdict inside a longer line ("ALL 31 …"). For a proof CHECKER it is too loose: the
# verdict is a line the checker prints on its own -- drat-trim's `s VERIFIED`, cake_lpr's
# `s VERIFIED UNSAT` -- and the harness must consume exactly that line, not a fragment of it.
# Three measured facts shaped this function (all 2026-09-02, on this box, against the archive):
#   * drat-trim exits 0 on a run that checked NOTHING: an empty CNF gives "c ERROR: did not find
#     p cnf line", no `s` line, rc 0. So rc alone is fail-open. It exits 1 with `s NOT VERIFIED` on
#     a truncated or empty proof of a non-trivial instance, and 255 on a missing proof file.
#   * drat-trim prefixes EVERY output line with a bare carriage return (its progress-line erase):
#     `grep -cx 's VERIFIED'` on a clean run's output is 0; after `tr -d '\r'` it is 1. The CR is
#     the ONE byte normalised below; nothing else is.
#   * cake_lpr exits 0 on pass AND on fail (documentation/SAT_CLI.md §Checkers). The verdict line is
#     the whole verdict; the rc leg here is inert for it and costs nothing.
# Contract: capture the producer's UNFILTERED stdout+stderr to a file; copy it to the log BEFORE
# anything is judged; then leg A = producer rc 0, leg B = the exact line is present (grep -Fqx on
# the CR-stripped FILE -- not a pipe: `tr | grep -q` is the class-B shape this file bans). Emits one
# whole-line token `<TOKEN>=PASS` or `<TOKEN>=FAIL rc=<n> verdict_line=<present|absent>` so a reader
# can `grep -qx` the log. Returns the producer's status when nonzero (is_resource_status still sees
# 134/137/139), else 1 when the line is missing. A grep that cannot read its own file is reported
# and treated as ABSENT: "could not look" must never read as "found".
require_verdict_line() {   # $1 = token name  $2 = exact whole line that MUST appear  $3.. = command
  local tok=$1 want=$2; shift 2
  local cap rc line=absent g
  cap=$(mktemp "${TMPDIR:-/tmp}/roae_verdict.XXXXXX") || { echo "$tok=FAIL rc=? verdict_line=MKTEMP_FAILED"; return 1; }
  "$@" > "$cap" 2>&1; rc=$?
  cat "$cap"
  tr -d '\r' < "$cap" > "$cap.nocr"
  grep -Fqx -- "$want" "$cap.nocr"; g=$?
  case $g in 0) line=present ;; 1) line=absent ;; *) echo "GREP FAILED rc=$g on $cap.nocr -- treated as ABSENT"; line=absent ;; esac
  rm -f "$cap" "$cap.nocr"
  if [ "$rc" -eq 0 ] && [ "$line" = present ]; then echo "$tok=PASS"; return 0; fi
  echo "$tok=FAIL rc=$rc verdict_line=$line"
  [ "$line" = absent ] && echo "EXPECTED VERDICT LINE NOT FOUND (whole line): $want"
  [ "$rc" -ne 0 ] && return "$rc"
  return 1
}

echo "== 0. Prerequisites =="
DRAT=${DRAT:-drat-trim}
LEAN=${LEAN:-lean}
command -v "$LEAN" >/dev/null 2>&1 || LEAN="$HOME/.elan/bin/lean"
HAVE_GCC=1; HAVE_PY=1; HAVE_DRAT=1; HAVE_LEAN=1; HAVE_GIT=1
command -v gcc      >/dev/null 2>&1 || HAVE_GCC=0
command -v python3  >/dev/null 2>&1 || HAVE_PY=0
command -v "$DRAT"  >/dev/null 2>&1 || HAVE_DRAT=0
command -v "$LEAN"  >/dev/null 2>&1 || HAVE_LEAN=0
# git: section 7 only, and BOTH legs matter — the binary AND a work tree. An exported tarball has
# the binary and no work tree, which is the case that would otherwise fail obscurely deep inside
# doc_gates.sh instead of being reported here, where a replicator reads what is missing.
command -v git      >/dev/null 2>&1 || HAVE_GIT=0
[ "$HAVE_GIT" = "1" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1 || HAVE_GIT=0
for t in "gcc:$HAVE_GCC" "python3:$HAVE_PY" "drat-trim ($DRAT):$HAVE_DRAT" "lean ($LEAN):$HAVE_LEAN" \
         "git (work tree; section 7 only):$HAVE_GIT"; do
  if [ "${t##*:}" = "1" ]; then echo "  found    ${t%:*}"; else echo "  MISSING  ${t%:*}"; fi
done
if [ "$HAVE_DRAT" = "0" ] || [ "$HAVE_LEAN" = "0" ] || [ "$HAVE_GCC" = "0" ] || [ "$HAVE_PY" = "0" ] \
   || [ "$HAVE_GIT" = "0" ]; then
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
  check "--selftest" "require_match PASS /tmp/roae_verify_solve --selftest"
fi

echo "== 2. Two-language gates =="
if [ "$HAVE_PY" = "0" ]; then
  skip "solve.py --registry-verify (31 rules)" "needs python3"
else
  check "solve.py --registry-verify (31 rules)" "require_match 'ALL 31' python3 solve.py --registry-verify"
fi
if [ "$HAVE_PY" = "0" ] || [ "$HAVE_GCC" = "0" ]; then
  skip "f4p two-language match" "needs gcc + python3"
else
  # 14 = the line count each side emits, measured 2026-09-02. A floor, not an equality, for the
  # same reason as sections 5 and 6: the table may grow, but it must never silently empty.
  check "f4p two-language match" \
    "require_agree F4P_AGREE 14 '/tmp/roae_verify_solve --f4p-verify' 'python3 solve.py --f4p-verify'"
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
    "require_match 'recount-subtree: ALL MATCH' python3 verify.py --recount-subtree"
fi

echo "== 3. DRAT certificates (regenerated CNF vs archived proof; all 22 archived certs) =="
# No SAT solver is invoked here — see the header note. $DRAT is probed in section 0.
# All 22 certificates carry BOTH checkers as of 2026-09-02: the 21 archived earlier passed the
# formally verified cake_lpr in the 2026-07-27 batch, and core_gender_ccn4_unsat (the fourth
# two-rule core, shipped 2026-09-02) went through the same drat-trim -> LRAT -> cake_lpr chain that
# day, on a rebuild of pin a36874a8 whose compiled sha is byte-identical to the batch binary
# (README.md §"Checker coverage"). This script supplies only the drat-trim leg; the cake_lpr leg is
# run out of band and recorded there, so a PASS here is NOT evidence about cake_lpr.
#
# [CLOSED 2026-09-02 — this paragraph previously read "KNOWN GAP, queued: the drat-trim invocation
#  below pipes into `grep -q`, so this log records only the PASS line and never the checker's own
#  's VERIFIED' output. A PASS line is therefore this script's assertion about drat-trim rather
#  than drat-trim's own words. Tee it." (Codex V2-14.) The pipe is gone: the call now goes through
#  require_match, which echoes drat-trim's captured output into $LOG, so the checker's verdict line
#  is recorded next to this script's PASS line and can be read back. The checker's IDENTITY is
#  emitted below as DRAT_TRIM_ID= — a PASS is evidence only about the binary that produced it, and
#  drat-trim carries no --version flag, so the sha256 of the resolved binary is the honest name.]
# [TIGHTENED 2026-09-02, later the same day: require_match tested `s VERIFIED` as a SUBSTRING. The
#  call now goes through require_verdict_line, which demands the WHOLE line (after stripping
#  drat-trim's leading CR) AND rc 0 as two separate legs, and writes DRAT_VERIFIED_<cert>=PASS|FAIL
#  into $LOG per certificate. Mutation-tested against the real archive: a proof truncated to half,
#  an empty proof, and a fake checker that prints `xs VERIFIED` / prints the line and exits 1 /
#  prints nothing and exits 0 all FAIL; the 24 archived proofs all PASS. Note two mutations that do
#  NOT fail and must not be expected to: a byte flipped inside a DELETION line (drat-trim warns
#  "deleted clause … does not occur" and still verifies -- a stray deletion is harmless) and one
#  non-core clause removed from the CNF (the proof still refutes what remains). Both are soundness,
#  not leniency.]
# The checker's identity, emitted as a whole-line verdict token so a reader (or a matcher, with
# `grep -qx`) can tell WHICH binary produced the PASS lines below. drat-trim has no --version
# flag, so the sha256 of the resolved executable is the only honest name for it. This must be
# emitted on EVERY run, including the run where drat-trim is absent: a token that vanishes when
# the tool is missing is indistinguishable from a token nobody looked for, and the certificate
# checks in that case are SKIPped, which already holds the exit status nonzero.
if [ "$HAVE_DRAT" = "1" ]; then
  DRAT_PATH=$(command -v "$DRAT" 2>/dev/null || echo "$DRAT")
  if command -v sha256sum >/dev/null 2>&1 && [ -r "$DRAT_PATH" ]; then
    DRAT_SHA=$(sha256sum "$DRAT_PATH" | cut -d" " -f1)
  else
    DRAT_SHA=UNAVAILABLE                  # never silently blank: an empty token reads as a pass
  fi
  echo "DRAT_TRIM_ID=$DRAT_SHA"      | tee -a "$LOG"
  echo "DRAT_TRIM_PATH=$DRAT_PATH"   | tee -a "$LOG"
else
  echo "DRAT_TRIM_ID=ABSENT"         | tee -a "$LOG"
  echo "DRAT_TRIM_PATH=ABSENT"       | tee -a "$LOG"
fi
declare -A CERTS=( [alt-le-14]="alt-le-14" [alt-ge-16]="alt-ge-16" \
  [moore-strict-near-2]="moore-strict-near-2" [rc4_near2_unsat]="rc4-strict-near-2" \
  [grand_ccn4_unsat]="grand-ccn4" \
  [grander_strict_unsat]="grander-strict" [grander_strict_near2_unsat]="grander-strict-near-2" \
  [grander_strict_near3_unsat]="grander-strict-near-3" [grander_strict_near4_unsat]="grander-strict-near-4" \
  [five_loo_parity_unsat]="five-loo-parity" [five_loo_rhythm_unsat]="five-loo-rhythm" \
  [five_loo_gender_unsat]="five-loo-gender" [five_loo_ccn4_unsat]="five-loo-ccn4" \
  [five_loo_ccn8_unsat]="five-loo-ccn8" \
  [core_parity_ccn4_unsat]="five-sub-parity+ccn4" [core_rhythm_ccn4_unsat]="five-sub-rhythm+ccn4" \
  [core_gender_ccn8_unsat]="gender-ccn8" [core_gender_ccn4_unsat]="five-sub-gender+ccn4" \
  [ccn8_kwfail_unsat]="ccn8-kwfail" [ccn8_kwchain_not_unsat]="ccn8-kwchain-not" \
  [rigidity_sc4_unsat]="rigidity" [c3_kwpin_ge777_unsat]="kwpin-ge777" \
  [alt_le_14_noY_unsat]="alt-le-14-noY" [alt_ge_16_noY_unsat]="alt-ge-16-noY" )
# The rigidity kernel (TR-5 SC-4) regenerates via its own flag, not --emit-cnf; the KW
# C3-exactness gate (kw-pin + C3 >= 777) needs the --c3-min flag; see the loop below.
# alt_{le_14,ge_16}_noY_unsat (added 2026-09-02, TR-6 / Codex V2-F08 #3): the CARDINALITY-ONLY
# clause subset of alt-le-14 / alt-ge-16 -- exactly the clauses in which no ordering (Y) variable
# occurs (sat.py `-noY`; le-14 keeps 11,073 of 240,039 clauses, ge-16 11,134 of 240,100) -- shown
# UNSAT on its own. Proofs: kissat 4.0.1, 2026-09-02, then CORE-TRIMMED with `drat-trim -l` (the
# raw kissat proofs gzip to 1,049,354 / 330,799 B; the trimmed ones to 614,082 / 171,203 B) and
# re-verified from the trimmed file: ~36.4k / ~11.7k core lemmas, so neither is decided by unit
# propagation, and a half-truncated trimmed proof is `s NOT VERIFIED`. The trimming is drat-trim's,
# but the archived file is checked as a proof in its own right by this loop, not trusted as one. These certify the SEMANTIC claim behind TR-6's
# "corroborating, not independent" verdict: the alternation theorem follows from C5's cardinalities
# before any ordering variable is consulted. They do NOT certify "no ordering variable appears in
# the full proofs" -- the archived alt-le-14 core contains 356 of them (cores are proof-relative).
# The pair's joint verdict is emitted below as ALT_NOY_SUBSET_UNSAT=PASS|FAIL|NOT_RUN.
CERT_FLOOR=24        # archived certificates as of 2026-09-02; a corpus that silently shrinks must not pass
# Completeness gate: every archived .drat.gz must be in the CERTS map above.
for f in reports/certificates/*.drat.gz; do b=$(basename "$f" .drat.gz)
  check "cert inventory covers $b" "[ -n \"\${CERTS[$b]+x}\" ]"
done
declare -A CERT_RC=()          # cert -> status of its drat-trim check (only certs that RAN)
CERTS_CHECKED=0
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
  # With the opt-in cake_lpr leg requested (section 3c), drat-trim also elaborates the LRAT that
  # cake_lpr checks; a stale LRAT from an earlier run is removed first so 3c can never read one
  # this run did not write.
  LRAT_OPT=""
  if [ -n "${CAKE_LPR:-}" ]; then rm -f "/tmp/roae_$t.lrat"; LRAT_OPT="-L /tmp/roae_$t.lrat"; fi
  check "cert $cert ($t)" \
    "$GEN && gunzip -kc reports/certificates/$cert.drat.gz > /tmp/roae_$t.drat && require_verdict_line DRAT_VERIFIED_$cert 's VERIFIED' \"$DRAT\" /tmp/roae_$t.cnf /tmp/roae_$t.drat $LRAT_OPT"
  CERT_RC[$cert]=$LAST_RC
  CERTS_CHECKED=$((CERTS_CHECKED+1))
done
# POPULATION, then the pair verdict. Both are whole-line tokens, emitted on every run: a count that
# vanished would be indistinguishable from one nobody looked for.
echo "DRAT_CERTS_CHECKED=$CERTS_CHECKED" | tee -a "$LOG"
if [ "$HAVE_DRAT" = "1" ] && [ "$HAVE_PY" = "1" ]; then
  check "cert population >= $CERT_FLOOR (checked $CERTS_CHECKED)" "[ $CERTS_CHECKED -ge $CERT_FLOOR ]"
else
  skip "cert population >= $CERT_FLOOR" "needs python3 + drat-trim"
fi
if [ -n "${CERT_RC[alt_le_14_noY_unsat]+x}" ] && [ -n "${CERT_RC[alt_ge_16_noY_unsat]+x}" ]; then
  if [ "${CERT_RC[alt_le_14_noY_unsat]}" -eq 0 ] && [ "${CERT_RC[alt_ge_16_noY_unsat]}" -eq 0 ]; then
    echo "ALT_NOY_SUBSET_UNSAT=PASS" | tee -a "$LOG"
  else
    echo "ALT_NOY_SUBSET_UNSAT=FAIL" | tee -a "$LOG"
  fi
else
  echo "ALT_NOY_SUBSET_UNSAT=NOT_RUN" | tee -a "$LOG"
fi

echo "== 3c. cake_lpr (formally verified LRAT checker) — OPT-IN second leg =="
# DECISION, stated so it can be argued with (2026-09-02, lane S-2): cake_lpr is NOT part of the
# default shipped verification and this section says so with a token rather than by silence.
# Reasons: (1) it is a CakeML binary built from a ~100 MB generated assembly file, with no package
# on any common host; (2) its default heap+stack (4096+4096 MB) refuses to start on an 8 GB host
# and needs --CML_HEAP_SIZE/--CML_STACK_SIZE; (3) the archive's cake_lpr coverage is an out-of-band
# record (README.md §Checker coverage), and a SKIP here on every replicator's machine would hold the
# exit status nonzero for a checker most cannot install. But the hazard SAT_CLI.md documents --
# cake_lpr EXITS 0 WHETHER IT VERIFIES OR FAILS -- was until today documented and never exercised by
# any code in this tree. So the leg exists, opt-in: set CAKE_LPR=<path or name> (and, on a small
# host, CAKE_LPR_OPTS='--CML_HEAP_SIZE=2048 --CML_STACK_SIZE=1024'); every certificate is then
# elaborated to LRAT by drat-trim in section 3 and checked here, gated on the WHOLE line
# `s VERIFIED UNSAT` via require_verdict_line -- never on the exit status. An LRAT that is absent or
# empty, or whose drat-trim leg did not pass, FAILS loudly: it is not a proof that was checked.
# With CAKE_LPR set to a binary that cannot be found, the resolve check FAILs and the per-cert legs
# SKIP -- an operator who asked for the leg must not receive a green run without it.
if [ -z "${CAKE_LPR:-}" ]; then
  echo "CAKE_LPR_LEG=NOT_RUN"  | tee -a "$LOG"
  echo "CAKE_LPR_ID=NOT_RUN"   | tee -a "$LOG"
  echo "  not requested (set CAKE_LPR=/path/to/cake_lpr to run it). The shipped verification is the"
  echo "  drat-trim leg above; cake_lpr coverage of the archive is recorded out of band in"
  echo "  reports/certificates/README.md §\"Checker coverage\". NOT_RUN is not a pass and not a failure."
else
  CAKE_PATH=$(command -v "$CAKE_LPR" 2>/dev/null || true)
  if [ -z "$CAKE_PATH" ] || [ ! -x "$CAKE_PATH" ]; then
    echo "CAKE_LPR_LEG=REQUESTED_BUT_ABSENT" | tee -a "$LOG"
    echo "CAKE_LPR_ID=ABSENT"                | tee -a "$LOG"
    check "cake_lpr binary resolves (CAKE_LPR=$CAKE_LPR)" "false"
    for cert in "${!CERTS[@]}"; do skip "cake_lpr $cert" "CAKE_LPR is set but not executable"; done
  elif [ "$HAVE_DRAT" = "0" ] || [ "$HAVE_PY" = "0" ]; then
    echo "CAKE_LPR_LEG=REQUESTED_NO_LRAT"   | tee -a "$LOG"
    echo "CAKE_LPR_ID=ABSENT"               | tee -a "$LOG"
    for cert in "${!CERTS[@]}"; do skip "cake_lpr $cert" "needs python3 + drat-trim to elaborate the LRAT"; done
  else
    if command -v sha256sum >/dev/null 2>&1; then CAKE_SHA=$(sha256sum "$CAKE_PATH" | cut -d" " -f1); else CAKE_SHA=UNAVAILABLE; fi
    echo "CAKE_LPR_LEG=RUN"          | tee -a "$LOG"
    echo "CAKE_LPR_ID=$CAKE_SHA"     | tee -a "$LOG"
    echo "CAKE_LPR_PATH=$CAKE_PATH"  | tee -a "$LOG"
    for cert in "${!CERTS[@]}"; do
      t=${CERTS[$cert]}
      if [ "${CERT_RC[$cert]:--1}" -ne 0 ]; then
        check "cake_lpr $cert ($t)" "echo 'drat-trim leg did not pass; its LRAT is not evidence'; false"
        continue
      fi
      # ${CAKE_LPR_OPTS:-} is deliberately unquoted: it is a word list of runtime sizing flags.
      check "cake_lpr $cert ($t)" \
        "{ [ -s /tmp/roae_$t.lrat ] || { echo 'LRAT ABSENT OR EMPTY: /tmp/roae_$t.lrat'; false; }; } && require_verdict_line CAKE_LPR_VERIFIED_$cert 's VERIFIED UNSAT' \"$CAKE_PATH\" \${CAKE_LPR_OPTS:-} /tmp/roae_$t.cnf /tmp/roae_$t.lrat"
    done
  fi
fi

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
    if sorted(seq) != list(range(64)):                                    # permutation of H
        raise SystemExit(f'FAIL witness {n}: not a permutation of H')
    # C1 is the PAIRING predicate (SPECIFICATION.md: s_{i+1} = partner(s_i) for even i),
    # not permutation-ness. Until 2026-08-01 this line asserted only the permutation and
    # labelled it "C1, C4" — so a witness with broken pair structure would have passed the
    # 'independent recheck' these artifacts are advertised under. verify.PAIRS was already
    # imported for exactly this. (All 42 archived witnesses re-verified WITH pairing when the
    # gap was found: all pass. The data was sound; the checker was not.)
    _pairs = {frozenset(pr) for pr in verify.PAIRS}
    if not all(frozenset((seq[2*k], seq[2*k+1])) in _pairs for k in range(32)):  # C1
        raise SystemExit(f'FAIL witness {n}: C1 pairing broken')
    if seq[:2] != [63, 0]:                                                # C4 (oriented)
        raise SystemExit(f'FAIL witness {n}: C4 orientation, head={seq[:2]}')
    if not all(verify.hamming(seq[i], seq[i+1]) != 5 for i in range(63)):  # C2
        raise SystemExit(f'FAIL witness {n}: C2 violated (a step of Hamming 5)')
    dist = [0]*7
    for i in range(63): dist[verify.hamming(seq[i], seq[i+1])] += 1
    if dist != verify.KW_DIST:                                            # C5
        raise SystemExit(f'FAIL witness {n}: C5 spectrum {dist} != {verify.KW_DIST}')
    if not (verify.compute_comp_dist(seq) == c3 == 16 + 8*g):             # C3/G
        raise SystemExit(f'FAIL witness {n}: C3/G mismatch '
                         f'({verify.compute_comp_dist(seq)} vs c3={c3} vs {16 + 8*g})')
    n += 1
if n != 42:
    raise SystemExit(f'FAIL: checked {n} witnesses, expected 42 — '
                     f'a short count means the input was truncated or empty, '
                     f'not that the witnesses passed')
print(f'  [ok] {n} witnesses re-checked independently (permutation, C1, C2, C3/G, C4, C5)')
PYEOF"
fi

echo "== 4. Lean kernel check (every lean/*.lean file) =="
# $LEAN resolved and probed in section 0 (plain `lean`, else the elan fallback).
for f in lean/*.lean; do
  if [ "$HAVE_LEAN" = "0" ]; then skip "$f" "needs lean (elan)"; continue; fi
  check "$f" "\"$LEAN\" \"$f\""
done

echo "== 5. Python regression harness (python3 tests.py) =="
# ADDED 2026-09-02 (backlog F2, from README P11). Until today the repo's advertised one-command
# front door ran neither the regression harness nor the analysis battery nor the doc gates, while
# README.md described it as "the instrument that checks the other five". The three sections below
# close that, each gated by the same HAVE_* probe + skip() the rest of the file uses, so a host
# without the tool still gets SKIP (not FAIL) and still exits nonzero.
#
# The floor, not an equality: `unittest` exits 0 when it collects ZERO tests, so exit status alone
# would pass a suite emptied by an import error. A suite that GROWS keeps passing; one that
# silently shrank fails.
# THE FLOOR IS 128, MEASURED, NOT 77. `python3 tests.py` reported "Ran 128 tests in 94.281s",
# 0 skipped, on 2026-09-02, and `grep -c '    def test_' tests.py` independently gives 128 —
# collection is unconditional, so the two agree by construction. README.md §Quick start still
# says "77 tests as of 2026-09-01" and documentation/DEVELOPMENT.md still says 76; BOTH are
# stale against HEAD. Those are published figures and correcting them needs an append to the
# corrections ledger, so they are reported rather than edited here — but this gate is set to
# what it actually measured, because a floor pinned to a stale figure is barely a floor at all.
# gcc as well as python3: TestCheckArtifactControls.setUpClass shells out to `gcc` to build
# verify.c, uncaught, so on a host without gcc the whole class ERRORs and section 5 would report
# FAIL for a missing tool — the exact confusion the SKIP machinery at the top of this file exists
# to prevent. Gated the same way the f4p check above is gated.
if [ "$HAVE_PY" = "0" ] || [ "$HAVE_GCC" = "0" ]; then
  skip "tests.py (regression harness, >= 128 tests)" "needs gcc + python3 (tests.py builds verify.c)"
else
  check "tests.py (regression harness, >= 128 tests)" \
    "require_floor TESTS_PY_RAN 128 'Ran ' ' test' python3 tests.py"
fi

echo "== 6. Analysis-battery ground-truth smoke (python3 roae.py --verify) =="
# SCOPE, stated rather than implied: this runs `roae.py --verify`, NOT the full battery. A bare
# `python3 roae.py` is `--all`, which includes Monte-Carlo sections — minutes of runtime and a
# non-deterministic result, neither of which belongs in a pass/fail gate. `--verify` is the
# battery's own deterministic ground-truth self-check (table identity vs solve.py, permutation /
# involution / trigram invariants, the KW C5 multiset, oriented C4; no sampling) and it is the
# only roae.py path that reaches the shell with a meaningful exit status — `main()` returns None
# on nearly every other path, so `sys.exit(main())` would be 0 regardless. So: a PASS here says
# roae.py imports and its ground truth holds. It is NOT evidence about the 28 analyses.
# Floor 11 = the count measured 2026-09-02, same reasoning as section 5.
if [ "$HAVE_PY" = "0" ]; then
  skip "roae.py --verify (ground-truth self-check, >= 11 checks)" "needs python3"
else
  check "roae.py --verify (ground-truth self-check, >= 11 checks)" \
    "require_floor ROAE_VERIFY_CHECKS 11 'ROAE VERIFY: ALL ' ' CHECKS PASS' python3 roae.py --verify"
fi

echo "== 7. Documentation gates (scripts/doc_gates.sh) =="
# Plain invocation ONLY. `scripts/doc_gates.sh --selftest` mutation-tests the gates and reverts
# with `git checkout -- .`, which discards the whole working tree; that flag is confined to the
# `--selftest` branch of that script and is deliberately not reachable from here.
# The gates read the tracked markdown corpus via `git ls-files`, so they need a git work tree.
# HAVE_GIT is probed in section 0 with the other tools, so a tarball export is told what is
# missing where a replicator reads it rather than failing obscurely inside doc_gates.sh.
if [ ! -r scripts/doc_gates.sh ]; then
  skip "scripts/doc_gates.sh" "script not present in this tree"
elif [ "$HAVE_GIT" = "0" ]; then
  skip "scripts/doc_gates.sh" "needs a git work tree (the gates enumerate the corpus with git ls-files)"
else
  # TWO legs, because exit status alone is not the whole verdict here: doc_gates.sh prints
  # "DOC GATES: PASS  — hard gates only: ..." ONLY when its own RC is 0 AND it ran the full
  # `all` mode. Requiring the banner as well as the status catches a run that died silently
  # after the last gate, and pins the check to `all` rather than to one of the named modes
  # (`retract`, `generated`, `repro-reach`) whose banners read "PASS" too.
  # NOT a substitute for reading the output: that banner covers the HARD gates only, and
  # names its own carve-outs — gates 1, 5, 13 and GATE 17 LEG B are report-only, GATE 24 is
  # not in `all` at all, and GATE 18 is hard for UNADJUDICATED defects only. A PASS here is
  # exactly what the banner says it is and no more. Measured 2026-09-02: 2m24s, 38 gates.
  check "scripts/doc_gates.sh (documentation gates, 'all' mode)" \
    "require_match 'DOC GATES: PASS  — hard gates only:' bash scripts/doc_gates.sh"
fi

echo; echo "RESULT: $PASS passed, $FAIL failed, $RESOURCE host-resource errors, $SKIP skipped"
if [ "$SKIP" -gt 0 ]; then
  echo "NOTE: $SKIP check(s) did not run because a required tool is absent — a SKIP is NOT a"
  echo "      verification failure and NOT a pass. Exit status is nonzero until every check runs."
fi
if [ "$RESOURCE" -gt 0 ]; then
  echo "NOTE: $RESOURCE check(s) exited 134/137/139 or reported an allocation failure. That is a"
  echo "      crash or a kill, not a rejected proof: nothing was disproved. The Lean files are the usual"
  echo "      cause, and there are TWO distinct limits — check which one you hit before buying a host:"
  echo "        (a) RSS: lean/README.md §\"Verify yourself\" gives measured per-file peak RSS (~9.6 GB"
  echo "            worst case; an 8 GB host cannot check Automorphism.lean or KingWen.lean)."
  echo "        (b) ADDRESS SPACE / thread creation: 'failed to create thread' at low RSS means a"
  echo "            ulimit -v cap (containers and CI commonly set one), NOT a shortage of RAM."
  echo "            Measured 2026-08-28: all 13 Lean checks ERROR'd at ~480 MB RSS under a 4 GB -v"
  echo "            cap. A larger host does NOT fix this. TRY FIRST, it costs nothing:"
  echo "                LEAN_NUM_THREADS=1   (or lean --threads=1)"
  echo "            which verified C1RuleConstants.lean and PruneSafety.lean on that same capped host."
  echo "      Re-run on a larger host only for case (a). Like a SKIP, an ERROR is not a pass:"
  echo "      exit status stays nonzero."
  echo "      Detection is heuristic and one-sided — a resource kill that neither exits 134/137/139"
  echo "      nor leaves an allocator message still shows up as FAIL: read $LOG before trusting a FAIL."
fi
[ "$FAIL" -eq 0 ] && [ "$RESOURCE" -eq 0 ] && [ "$SKIP" -eq 0 ]
