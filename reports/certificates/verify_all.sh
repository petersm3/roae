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
#           ~7.24 MiB and the estimator adds ~1.48 MiB (gcc -fstack-usage, re-measured 2026-09-25, Q-826;
#           this read ~7.23 MB and ~1.0 MB), so an 8 MB default stack is too small.
#           This script does not invoke the estimator; the binary now refuses with a clear
#           message rather than segfaulting.
#   DISK  : ~2 GB scratch. CPU: Linux x86-64 (glibc, gcc with OpenMP, zlib -- reviewer/README.md); the checks
#           are not core-hungry and do not need a big VM. ("CPU: any" until 2026-10-17, CX-35T-L.)
#   These were previously stated only in lean/README.md and in a comment further down this
#   file. A cold external-reviewer pass on a 4 GB host hit ERROR 134 on all 13 Lean files and
#   reported them as unverifiable -- the requirement was documented, just not where a
#   replicator reads it.
#   OPTIONAL: cake_lpr (formally verified LRAT checker) — section 3c runs it only when CAKE_LPR is
#   set; by default that section emits CAKE_LPR_LEG=NOT_RUN and the run is drat-trim-only.
#   NOT required: a SAT solver. This script REPLAYS the archived DRAT proofs against freshly
#   regenerated CNF, which is the sufficient check and needs only drat-trim. The King Wen
#   over-constraint control beside each replay (`sat.py --kw-control`, added 2026-10-02) needs
#   python3 only, so it still runs on a host without drat-trim. kissat was listed
#   here until 2026-08-01 and never invoked by any code path — building it from source was
#   wasted work for a replicator (lens-sweep item T4-9). It is still what PRODUCED the archived
#   proofs (METHODS.md pins the version); reproducing the proofs themselves, rather than
#   verifying them, is the only step that needs it.
# LOG AND SCRATCH (changed 2026-09-27, Q-856): the full command output goes to $ROAE_VERIFY_LOG when
#   that is set, and otherwise to a NEW file ${TMPDIR:-/tmp}/roae_verify_all.XXXXXX whose path is
#   printed at the start and at the end of the run; it is kept. The solve build and the CNF, DRAT and
#   LRAT files (the ~2 GB of scratch above) go to a NEW directory ${TMPDIR:-/tmp}/roae_verify.XXXXXX,
#   removed when the script exits. Until 2026-09-27 all of these were fixed names
#   (/tmp/roae_verify_all.log, /tmp/roae_verify_solve, /tmp/roae_<target>.{cnf,drat,lrat}), so two
#   runs on one host overwrote a binary or a proof file while the other run was reading it.
# https://github.com/petersm3/roae — Developed with AI assistance (Claude, Anthropic)
set -uo pipefail
cd "$(dirname "$0")/../.."
PASS=0; FAIL=0
SKIP=0
RESOURCE=0
LOG=${ROAE_VERIFY_LOG:-}
if [ -z "$LOG" ]; then
  LOG=$(mktemp "${TMPDIR:-/tmp}/roae_verify_all.XXXXXX") || { echo "VERIFY_ALL_LOG=MKTEMP_FAILED"; exit 2; }
fi
: > "$LOG"
SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/roae_verify.XXXXXX") || { echo "VERIFY_ALL_SCRATCH=MKTEMP_FAILED"; exit 2; }
trap 'rm -rf "${SCRATCH:?}"' EXIT

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
  # ARGUMENT-COUNT GUARD (2026-09-24, Q-742). check takes exactly two words: a label and a command
  # string that is eval'd. A stray double quote inside a multi-line command string ends the word
  # early, the remainder becomes a third argument, and check used to ignore it silently. That is
  # what happened to §3b from a15c6ddc (2026-08-01) until today: the comment `labelled it "C1, C4"`
  # inside the heredoc split the command, so the eval'd heredoc stopped at that comment, Python ran
  # only the permutation test, and the C1/C2/C3/G/C4/C5 checks and the n == 42 count never executed
  # while the section printed PASS. Any other argument count is now a FAIL, not a silent truncation.
  if [ "$#" -ne 2 ]; then
    echo "FAIL  ${1:-<no label>}   (check() called with $# arguments, expected 2 — a stray double quote in the command string?)"
    FAIL=$((FAIL+1)); LAST_RC=2; return 0
  fi
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

# Same contract as require_match, but the pattern must be a WHOLE LINE of the output (added
# 2026-10-17, batch FT3j). A substring match would accept `LCSELFTEST_RESULT=PASSED` or a line
# that merely quotes the token; the selftests below print their verdict as a line of its own, so
# the check holds them to exactly that line. Here-string loop, not a pipe: see the note above.
require_line() {           # $1 = exact line that MUST appear; $2.. = command and arguments
  local want=$1; shift
  local out rc line
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] || { echo "NONZERO EXIT $rc from: $*"; return "$rc"; }
  while IFS= read -r line; do
    [ "$line" = "$want" ] && return 0
  done <<< "$out"
  echo "EXPECTED LINE NOT FOUND: $want"; return 1
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

# require_floor for a unittest suite (2026-10-22, push group G5b; Codex gpt-6-astra F05-020#8/#9).
# `Ran N tests` counts SKIPPED tests, so `OK (skipped=128)` met the old floor of 128 with nothing
# executed; and 128 was the 2026-09-02 population while tests.py now declares over 1,900 test
# methods, so a suite that lost nine tenths of itself still passed. This leg subtracts the skipped
# count unittest reports and holds the EXECUTED count to the floor. Emits TESTS_PY_RAN,
# TESTS_PY_SKIPPED and TESTS_PY_EXECUTED as whole-line tokens.
require_tests_floor() {    # $1 = floor  $2.. = command and arguments
  local floor=$1; shift
  local out rc line n="" k=0
  out=$("$@" 2>&1); rc=$?
  printf '%s\n' "$out"
  [ "$rc" -eq 0 ] || { echo "NONZERO EXIT $rc from: $*"; return "$rc"; }
  while IFS= read -r line; do                     # here-string, not a pipe: see the note above
    case $line in "Ran "*" test"*) n=${line#Ran }; n=${n%% *} ;; esac
    case $line in "OK ("*"skipped="*|"FAILED ("*"skipped="*) k=${line#*skipped=}; k=${k%%[!0-9]*} ;; esac
  done <<< "$out"
  case $n in ''|*[!0-9]*) echo "TESTS_PY_RAN=ABSENT"; echo "COUNT LINE NOT FOUND: expected 'Ran N tests'"; return 1 ;; esac
  case $k in ''|*[!0-9]*) echo "TESTS_PY_SKIPPED=ABSENT"; echo "SKIPPED COUNT UNPARSEABLE"; return 1 ;; esac
  echo "TESTS_PY_RAN=$n"; echo "TESTS_PY_SKIPPED=$k"; echo "TESTS_PY_EXECUTED=$((n - k))"
  [ "$((n - k))" -ge "$floor" ] || { echo "EXECUTED COUNT BELOW FLOOR: $((n - k)) < $floor (ran $n, skipped $k)"; return 1; }
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
# 🔴 THE ELAN FALLBACK IS FOR AN UNSET LEAN, NOT FOR A BAD ONE. Until 2026-09-03 this read
# `LEAN=${LEAN:-lean}` followed by an unconditional `command -v "$LEAN" || LEAN=~/.elan/bin/lean`,
# so an operator who exported `LEAN=/path/with/a/typo` had it SILENTLY REPLACED and the whole Lean
# section then ran against a different toolchain than the one they named — an opt-out that fires on
# a typo. An explicit override that is wrong must be an ERROR; only the default may fall back.
if [ -n "${LEAN+set}" ] && [ -n "$LEAN" ]; then
  if ! command -v "$LEAN" >/dev/null 2>&1; then
    echo "LEAN_RESOLVE=FAIL explicit LEAN='$LEAN' is not executable"
    echo "  You set LEAN explicitly, so this run will NOT silently fall back to"
    echo "  \$HOME/.elan/bin/lean — that would verify with a different toolchain than the one"
    echo "  you named. Fix the path, or unset LEAN to accept the default resolution."
    exit 2
  fi
else
  LEAN=lean
  command -v "$LEAN" >/dev/null 2>&1 || LEAN="$HOME/.elan/bin/lean"
fi
# 🔴 RAM WAS DOCUMENTED AND NEVER CHECKED. The header has said ">= 12 GB free" since the Lean phase
# was added (it peaks ~9.6 GB resident on Automorphism.lean), but nothing asserted it, so a host that
# is short — c293-satcert has 7.9 GB — discovers this as an OOM kill deep inside section 4 rather than
# here. That is the same failure mode this section already prevents for git, and for the same reason:
# a replicator should read what is missing, not decode a signal 9. Reported, NOT fatal: the shortfall
# only affects the Lean phase, and a run that skips Lean is still useful.
LEAN_MIN_GB=${LEAN_MIN_GB:-12}
if [ -r /proc/meminfo ]; then
  _avail_kb=$(awk '/^MemAvailable:/{print $2; exit}' /proc/meminfo 2>/dev/null)
  case "$_avail_kb" in
    ''|*[!0-9]*) echo "  [note] could not read MemAvailable — RAM headroom for section 4 unverified" ;;
    *) if [ "$_avail_kb" -lt $((LEAN_MIN_GB * 1024 * 1024)) ]; then
         echo "LEAN_RAM=LOW available=$((_avail_kb / 1048576))GB required=${LEAN_MIN_GB}GB"
         echo "  [warn] section 4 (Lean) peaks ~9.6 GB resident on Automorphism.lean and ~7.9 GB on"
         echo "         KingWen.lean. On this host it may be OOM-killed, which surfaces as a bare"
         echo "         'Killed' or signal 9 rather than a Lean error. This is a WARNING, not a"
         echo "         refusal — the other sections are unaffected."
       else
         echo "LEAN_RAM=OK available=$((_avail_kb / 1048576))GB required=${LEAN_MIN_GB}GB"
       fi ;;
  esac
fi
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
  check "solve.c build" "gcc -O2 -pthread -fopenmp -o \"\$SCRATCH/solve\" solve.c -lm -lz"
  check "--selftest" "require_match PASS \"\$SCRATCH/solve\" --selftest"
fi

# 1b (added 2026-10-17, batch FT3j, Codex gpt-6-astra F12-014#2). verify.c's two layer-reader
# selftests synthesize their own fixtures and need no real data. From 2026-10-03 to 2026-10-17 both
# printed FAIL -- the stored-last domain check added that day rejected their own positive fixtures
# -- and nothing ran them, while documentation/VERIFY.md told readers to. They now run here (and in
# tests.py TestBatchFT3j) and must print their verdict line exactly.
echo "== 1b. Independent layer-reader selftests (verify.c) =="
if [ "$HAVE_GCC" = "0" ]; then
  skip "verify.c build" "needs gcc"
  skip "verify --check-layers-selftest" "needs gcc"
  skip "verify --scan-selftest" "needs gcc"
else
  check "verify.c build" "gcc -O2 -pthread -fopenmp -o \"\$SCRATCH/verify\" verify.c -lm -lz"
  check "verify --check-layers-selftest" \
    "require_line 'LCSELFTEST_RESULT=PASS' \"\$SCRATCH/verify\" --check-layers-selftest"
  check "verify --scan-selftest" \
    "require_line 'SCAN-SELFTEST: PASS' \"\$SCRATCH/verify\" --scan-selftest"
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
    "require_agree F4P_AGREE 14 '\"\$SCRATCH/solve\" --f4p-verify' 'python3 solve.py --f4p-verify'"
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

# 🔴 COUNT CORRECTED 2026-09-10: this header said "all 22 archived certs" while the section
# checks and reports 24. A header that miscounts what it verifies invites a reader to believe two
# certificates were skipped. Measured on a fresh host: DRAT_CERTS_CHECKED=24, 75 passed, 0 failed.
echo "== 3. DRAT certificates (regenerated CNF vs archived proof; all 24 archived certs) =="
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
# KW over-constraint controls that must PASS (2026-10-02): every sequence-formula certificate, i.e.
# CERT_FLOOR minus the one rigidity kernel, which is reported INAPPLICABLE by name in the loop below.
KW_CONTROL_FLOOR=23
KW_CONTROLS_PASSED=0
# FILE POPULATION, counted with no tool (Q-709, 2026-09-25). The population check below counts the
# CERTS map entries that drat-trim ran, so on a host without drat-trim or python3 it is a SKIP, and
# a missing .drat.gz reads exactly like a present one. And with no file matching, the completeness
# loop's glob stays literal: b becomes `*`, `${CERTS[*]+x}` is non-empty, and the check PASSes
# having examined nothing. This counts the files themselves and runs on every host. Measured
# 2026-09-25: 24 files. The floor is CERT_FLOOR with no margin: the corpus is archived, and every
# file in it is named in the CERTS map, so any shortfall is a lost certificate.
cert_files(){ local n=0 f; for f in reports/certificates/*.drat.gz; do [ -f "$f" ] && n=$((n+1)); done; echo "certificate files: $n found"; }
check "cert files on disk >= $CERT_FLOOR" \
  "require_floor DRAT_CERTS $CERT_FLOOR 'certificate files: ' ' found' cert_files"
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
    GEN="python3 sat.py --rigidity-cnf \"\$SCRATCH/$t.cnf\""
  elif [ "$cert" = "c3_kwpin_ge777_unsat" ]; then
    GEN="python3 sat.py --emit-cnf kw-pin \"\$SCRATCH/$t.cnf\" --c3-min 777"
  else
    GEN="python3 sat.py --emit-cnf $t \"\$SCRATCH/$t.cnf\""
  fi
  # THE KING WEN OVER-CONSTRAINT CONTROL, per certificate (Q-58 / GATES-04, 2026-10-02). DRAT is
  # monotone: a formula with a stray extra clause has the same (or a shorter) refutation, so `s VERIFIED`
  # above says nothing about whether the regenerated CNF forbids orderings the target's statement does
  # not. `sat.py --kw-control` asks the King Wen assignment to falsify ONLY the families the target is
  # about (its theorem family plus the rule families solve.py's scorers say KW violates), nothing on the
  # formula minus those families, and each of them on its own (SAT_CLI.md §--kw-control). It needs
  # python3 only, so it runs on a host without drat-trim. Until today the control lived in tests.py
  # for 8 of the 24 targets and surfaced only inside section 5's "Ran N tests" line; it is now one
  # whole-line token per certificate here, KW_CONTROL_<cert>=PASS|FAIL…, with the population floor
  # below. The rigidity kernel is not a sequence formula (no ordering to pin King Wen into); its own
  # positive control is sat.py's rigidity_validate(), run by --rigidity-cnf before it writes, so it is
  # stated INAPPLICABLE on every run rather than silently left out of the count.
  if [ "$cert" = "rigidity_sc4_unsat" ]; then
    echo "KW_CONTROL_$cert=INAPPLICABLE (not a sequence formula; its positive control is rigidity_validate, run by --rigidity-cnf)" | tee -a "$LOG"
  elif [ "$HAVE_PY" = "0" ]; then
    skip "kw-control $cert ($t)" "needs python3"
  else
    KWC_ARGS="$t"
    if [ "$cert" = "c3_kwpin_ge777_unsat" ]; then KWC_ARGS="kw-pin --c3-min 777"; fi
    check "kw-control $cert ($t)" \
      "require_verdict_line KW_CONTROL_$cert 'KW_CONTROL=PASS' python3 sat.py --kw-control $KWC_ARGS"
    if [ "$LAST_RC" -eq 0 ]; then KW_CONTROLS_PASSED=$((KW_CONTROLS_PASSED+1)); fi
  fi
  if [ "$HAVE_DRAT" = "0" ] || [ "$HAVE_PY" = "0" ]; then
    skip "cert $cert ($t)" "needs python3 + drat-trim"
    continue
  fi
  # With the opt-in cake_lpr leg requested (section 3c), drat-trim also elaborates the LRAT that
  # cake_lpr checks; a stale LRAT is removed first so 3c can never read one this run did not write
  # (the per-run $SCRATCH already rules out another run's; the rm is kept as a second guard).
  LRAT_OPT=""
  if [ -n "${CAKE_LPR:-}" ]; then rm -f "$SCRATCH/$t.lrat"; LRAT_OPT="-L \"\$SCRATCH/$t.lrat\""; fi
  check "cert $cert ($t)" \
    "$GEN && gunzip -kc reports/certificates/$cert.drat.gz > \"\$SCRATCH/$t.drat\" && require_verdict_line DRAT_VERIFIED_$cert 's VERIFIED' \"$DRAT\" \"\$SCRATCH/$t.cnf\" \"\$SCRATCH/$t.drat\" $LRAT_OPT"
  CERT_RC[$cert]=$LAST_RC
  # Counted only when drat-trim printed `s VERIFIED` (check() rc 0). Until 2026-09-29 (Codex LSD
  # R18k) this counted ATTEMPTS, so DRAT_CERTS_CHECKED=24 was printed by a run in which every
  # certificate had failed; the population floor below is over verified certificates.
  if [ "$LAST_RC" -eq 0 ]; then CERTS_CHECKED=$((CERTS_CHECKED+1)); fi
done
# POPULATION, then the pair verdict. Both are whole-line tokens, emitted on every run: a count that
# vanished would be indistinguishable from one nobody looked for.
echo "DRAT_CERTS_CHECKED=$CERTS_CHECKED" | tee -a "$LOG"
if [ "$HAVE_DRAT" = "1" ] && [ "$HAVE_PY" = "1" ]; then
  check "cert population >= $CERT_FLOOR (checked $CERTS_CHECKED)" "[ $CERTS_CHECKED -ge $CERT_FLOOR ]"
else
  skip "cert population >= $CERT_FLOOR" "needs python3 + drat-trim"
fi
# The control population, the same way (2026-10-02): counted over PASSED controls, so a run in which
# every control failed cannot print the floor.
echo "KW_CONTROLS_PASSED=$KW_CONTROLS_PASSED" | tee -a "$LOG"
if [ "$HAVE_PY" = "1" ]; then
  check "kw-control population >= $KW_CONTROL_FLOOR (passed $KW_CONTROLS_PASSED)" "[ $KW_CONTROLS_PASSED -ge $KW_CONTROL_FLOOR ]"
else
  skip "kw-control population >= $KW_CONTROL_FLOOR" "needs python3"
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
        "{ [ -s \"\$SCRATCH/$t.lrat\" ] || { echo \"LRAT ABSENT OR EMPTY: \$SCRATCH/$t.lrat\"; false; }; } && require_verdict_line CAKE_LPR_VERIFIED_$cert 's VERIFIED UNSAT' \"$CAKE_PATH\" \${CAKE_LPR_OPTS:-} \"\$SCRATCH/$t.cnf\" \"\$SCRATCH/$t.lrat\""
    done
  fi
fi

echo "== 3b. C3 positional witnesses (independent verify.py-path recheck) =="
if [ "$HAVE_PY" = "0" ]; then skip "c3_positional_witnesses.txt (42 witnesses)" "needs python3"; else
check "c3_positional_witnesses.txt (42 witnesses)" "python3 - <<'PYEOF'
import sys, re
sys.argv = ['verify.py']
import verify
g = c3 = None; n = 0; seen_g = []; hdr = ''; g95_layout = None; annotations = 0
for ln in open('reports/certificates/c3_positional_witnesses.txt'):
    if ln.startswith('G='):
        head = ln.split('#')[0].split()
        g, c3 = int(head[0][2:]), int(head[1][3:])
        hdr = ln
    if not ln.startswith('SEQ='):
        continue
    seq = [int(x) for x in ln[4:].split()]
    if sorted(seq) != list(range(64)):                                    # permutation of H
        raise SystemExit(f'FAIL witness {n}: not a permutation of H')
    # C1 is the PAIRING predicate (SPECIFICATION.md: s_{i+1} = partner(s_i) for even i),
    # not permutation-ness. Until 2026-08-01 this line asserted only the permutation and
    # labelled it 'C1, C4' — so a witness with broken pair structure would have passed the
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
    # WHAT THE ROWS SAY ABOUT THEMSELVES (2026-09-29, Codex LSD R18a). Until today the header
    # annotations were not checked by anything: the G=95 row is published as the tie with a
    # pair-slot layout != KW, and one ladder row annotates its yangcount/entryyang; a file whose
    # G=95 SEQ was KW itself, or whose annotation was 91, passed this block.
    if g == 95:
        g95_layout = any(frozenset(seq[2*k:2*k+2]) != frozenset(verify.KW[2*k:2*k+2])
                         for k in range(32))
        if not g95_layout:
            raise SystemExit(f'FAIL witness {n}: the G=95 tie row repeats KW pair-slot layout')
    # EVERY occurrence, and an occurrence that is not an unsigned decimal FAILS (2026-10-22, G5b;
    # Codex F01-001#2): the old unsigned regex read yangcount=-1 as no annotation at all.
    for _name, _j in (('yangcount', 1), ('entryyang', 0)):      # solve.py _yang_count: exit / entry
        _vals = re.findall(r'\b' + _name + r'=([^\s,;)]*)', hdr)
        _got = sum(bin(seq[2*k + _j]).count('1') for k in range(1, 32))   # the 31 free slots
        for _v in _vals:
            if not re.fullmatch(r'[0-9]+', _v) or _got != int(_v):
                raise SystemExit(f'FAIL witness {n}: annotated {_name}={_v} but the '
                                 f'sequence has {_name}={_got}')
            annotations += 1
    seen_g.append(g)
    n += 1
if n != 42:
    raise SystemExit(f'FAIL: checked {n} witnesses, expected 42 — '
                     f'a short count means the input was truncated or empty, '
                     f'not that the witnesses passed')
# COVERAGE, NOT JUST COUNT (2026-09-24, Q-742 / Codex V3A-097#1). Until today the gate asserted
# n == 42 and nothing else, so a file whose G=12 witness had been replaced by a second G=13
# witness still counted 42 and printed [ok] while the floor witness the README promises was gone
# (executed: CODEX_V3_E3_BATCH2 F6). The README promises one witness at EVERY rung G = 12..51
# plus the tie (G = 95) and the above-ceiling row (G = 97); assert exactly that multiset.
_want_g = list(range(12, 52)) + [95, 97]
if sorted(seen_g) != _want_g:
    _dup = sorted({x for x in seen_g if seen_g.count(x) > 1})
    _miss = sorted(set(_want_g) - set(seen_g))
    _extra = sorted(set(seen_g) - set(_want_g))
    raise SystemExit(f'FAIL: witness G-set is not {{12..51, 95, 97}} — '
                     f'missing {_miss}, duplicated {_dup}, unexpected {_extra}')
if g95_layout is not True:
    raise SystemExit('FAIL: the G=95 layout check did not run — nothing compared the tie row to KW')
if annotations < 1:
    raise SystemExit('FAIL: no yangcount/entryyang annotation was checked — the annotated row is gone')
print('WITNESS_G95_LAYOUT=PASS')
print(f'WITNESS_ANNOTATIONS_CHECKED={annotations}')
print(f'  [ok] {n} witnesses re-checked independently (permutation, C1, C2, C3/G, C4, C5); '
      f'G-set = {{12..51, 95, 97}}')
PYEOF"
fi

echo "== 4. Lean kernel check (every lean/*.lean file) =="
# $LEAN resolved and probed in section 0 (plain `lean`, else the elan fallback).
# 🔴 RUN FROM INSIDE lean/, AND NAME THE KERNEL (B11a, 2026-09-03; Codex V2-14 #2). Until today this
# loop ran `"$LEAN" lean/<Module>.lean` from the REPO ROOT. elan's `lean` proxy chooses the toolchain
# by walking UP from the WORKING DIRECTORY to the nearest `lean-toolchain`; the input file's own
# directory is never consulted, and the only pin in this repository is `lean/lean-toolchain`. So from
# the root the pin was dead: every module was checked under whatever `elan default` happened to be,
# and the run recorded no `lean --version`, so the attestation named no kernel. PLANT-TESTED on
# c293-satcert 2026-09-03: with `elan default leanprover/lean4:v4.30.0` and the pin still v4.31.0,
# `lean --version` from the root answered 4.30.0, from lean/ it answered 4.31.0, and this loop as it
# stood reported 12 PASS + 2 FAIL while `pgrep` showed `…/leanprover--lean4---v4.30.0/bin/lean` doing
# the checking: the twelve PASS lines named no kernel, and the two FAILs (RecordConvention,
# TrigramTheorems: `rw` pattern-not-found, a 4.30->4.31 elaboration difference; both pass under the
# pin) were blamed on the proofs. Same shape as the drat-trim leg before DRAT_TRIM_ID= existed: a
# PASS is evidence only about the binary that produced it, and this one did not say which. Two legs
# now, each on its own:
#   (1) every module runs as `(cd lean && "$LEAN" <Module>.lean)` — a subshell, so this script's own
#       cwd is untouched — which is what makes elan honour lean/lean-toolchain, and is the command
#       documentation/CLAIM_TO_ARTIFACT.md row 13 already advertises;
#   (2) the kernel is IDENTIFIED before any module runs, from the same cwd the modules use:
#       `LEAN_ID=<pin>/<lean --version>` is one whole line (consume it with grep -qx, like
#       DRAT_TRIM_ID=), and its version MUST agree with the pin (LEAN_PIN_MATCH=PASS|FAIL). A
#       disagreement — $LEAN naming a toolchain's bin/lean directly and so bypassing elan, a proxy
#       that resolved elsewhere, a pin nobody installed, an unreadable pin file — is a counted FAIL
#       that ALSO fails every module line: never a SKIP, never a pass. A run that cannot see its
#       target must not report green (the class this file exists to close; see the header).
# The module count is a floor for the same reason as sections 5 and 6: an unmatched glob fails on
# its own, but a directory that quietly lost modules must not pass either. 14 on `main` since
# SatEncodingFidelity.lean (2026-08-31); override with LEAN_FILES_MIN on a branch that has fewer.
# 🔴 A `sorry` PASSED THIS GATE (found 2026-09-21; roae-private LEAN_11_UNEXECUTED_CLAIM_RESOLVED_2026_09_21.md §3).
# check() judges the exit status, and on the pinned 4.31.0 a module containing `sorry` exits 0 — its
# only trace is `warning: declaration uses `sorry`` on STDOUT, which nothing here read. Measured on
# this file's own check(), lifted verbatim: a shipped module with an appended `sorry` printed PASS;
# with `sorry` + `#print axioms` (stdout `depends on axioms: [sorryAx]`) printed PASS; only a false
# `rfl` (rc 1) printed FAIL. `native_decide` has the same shape — rc 0, no warning, its only trace
# an auxiliary axiom `<decl>._native.native_decide.ax_*` in the `#print axioms` line — so the
# "kernel-only, no compiler trust" claim lean/README.md makes was not enforced by this gate either.
# Two legs now, both required, each on its own:
#   (A) `-DwarningAsError=true`: the `sorry` warning becomes an error and the module exits 1.
#       Measured: rc 1 on sorry mutants; rc 0 and byte-identical stdout on clean modules.
#   (B) EVERY stdout line must be an in-file `#print axioms` report whose set lies within Lean's
#       standard axioms [propext, Classical.choice, Quot.sound] — the allowlist form lean/README.md
#       prescribes ("the tell is the allowlist, not the absence of one name"). Any other line —
#       `[sorryAx]`, a `_native` axiom, a warning, an error — fails the module. This is the leg that
#       catches native_decide, which leg (A) cannot; a module with no directive prints nothing and
#       passes leg (B) on rc alone, so leg (A) is what carries it.
# One whole-line token per module, written to $LOG and repeated on stdout:
#   LEAN_MODULE_<Module>=PASS  |  LEAN_MODULE_<Module>=FAIL rc=<n> non_allowlisted_lines=<k>
# The output is captured to a file and copied to $LOG BEFORE it is judged (class-B: no `| grep -q`),
# so is_resource_status still sees a kill or a thread-creation failure. Red-tested on the shipped
# script with sorry / sorry+#print axioms / native_decide / false-rfl mutants and a clean control
# (roae-private scripts/lean_gate_redtest.sh).
LEAN_AXIOM_ALLOWLIST_RE="^'[^']+' does not depend on any axioms\$|^'[^']+' depends on axioms: \[(propext|Classical\.choice|Quot\.sound)(, (propext|Classical\.choice|Quot\.sound))*\]\$"
LEAN_LAST_TOKEN=""
lean_module_check() {   # $1 = <Module>.lean relative to lean/; runs from INSIDE lean/ (B11a above)
  local m=$1 name cap rc bad
  name=${m%.lean}
  cap=$(mktemp "${TMPDIR:-/tmp}/roae_lean.XXXXXX") || { LEAN_LAST_TOKEN="LEAN_MODULE_$name=FAIL rc=? non_allowlisted_lines=MKTEMP_FAILED"; echo "$LEAN_LAST_TOKEN"; return 1; }
  (cd lean && "$LEAN" -DwarningAsError=true "$m") > "$cap" 2>&1; rc=$?
  cat "$cap"
  bad=$(grep -v -E -- "$LEAN_AXIOM_ALLOWLIST_RE" "$cap" | grep -c '')
  rm -f "$cap"
  if [ "$rc" -eq 0 ] && [ "$bad" -eq 0 ]; then
    LEAN_LAST_TOKEN="LEAN_MODULE_$name=PASS"; echo "$LEAN_LAST_TOKEN"; return 0
  fi
  LEAN_LAST_TOKEN="LEAN_MODULE_$name=FAIL rc=$rc non_allowlisted_lines=$bad"
  echo "$LEAN_LAST_TOKEN"
  [ "$bad" -gt 0 ] && echo "EVERY stdout line must be an in-file '#print axioms' report within [propext, Classical.choice, Quot.sound]; $bad line(s) above are not (a sorry, a native_decide axiom, a warning, or an error)."
  [ "$rc" -ne 0 ] && return "$rc"
  return 1
}
#   (D) MODULE-WIDE AXIOM CENSUS (2026-10-23, Codex gpt-6-astra F01-001#5 and six siblings, push
#       group G8L). lean/README.md and CLAIM_TO_ARTIFACT.md row 13 cite "1,500 non-internal
#       constants, 0 outside [propext, Classical.choice, Quot.sound]" -- a `Lean.collectAxioms`
#       walk over EVERY constant of every module, not only the directive sites leg (B) reads --
#       and until today the driver that produced it lived only in the private evidence record.
#       It now ships as lean/AxiomCensus.lean.in (byte-identical to the template the attested
#       2026-09-10 and 2026-09-21 runs executed) and this leg runs it per module, in the shape
#       those runs used: compile the module to an .olean in a scratch directory, copy
#       lean/lean-toolchain into that directory (elan's proxy resolves the toolchain from the
#       working directory; without the copy the scan would run under `elan default`), substitute
#       the module name into the template, elaborate the scan file from that directory with
#       LEAN_PATH at it. Judged on rc 0 AND one `AXSCAN_COMPLETE <Module> constants=<n> hits=0`
#       line with n >= 1 AND exactly n well-formed `AXSCAN_OK` lines AND no other stdout line --
#       any line that is not one of those two forms (a warning, an error, an `AXSCAN_HIT`, a
#       COMPLETE line for another module, a malformed OK line) fails the module, the leg-(B)
#       allowlist discipline. Tokens, one per module
#       and one total, written to $LOG and repeated on stdout:
#         LEAN_AXIOM_CENSUS_<Module>=PASS constants=<n>  |  =FAIL rc=<n> constants=<n> hits=<h> ...
#         LEAN_AXIOM_CENSUS_CONSTANTS=<sum>   with floor LEAN_CENSUS_CONSTANTS_MIN (1500, the
#       published count on the pinned 4.31.0; a floor, like LEAN_FILES_MIN, so a module that
#       quietly lost declarations fails while one that grew passes). The second compile is the
#       price of leaving leg (A)'s command untouched (it adds `-o`; stdout is unchanged by it).
#       Positive control, executed on both attested runs: a module with one `sorry` theorem and
#       one `native_decide` theorem gives `hits=2` (`sorryAx`, `_native.native_decide.ax_*`).
#       tests.py `TestBatchG8L` runs this function against an elan-like stub `lean` (it refuses
#       when no lean-toolchain is in its cwd) with canned outputs (clean / a hit / no COMPLETE
#       line / an extra line / constants=0 / another module's COMPLETE line / a malformed OK
#       line / no pin to copy) -- the judge is tested on every harness run; the Lean side is
#       tested wherever this script runs with Lean.
LEAN_CENSUS_LAST=""; LEAN_CENSUS_LAST_N=0
lean_axiom_census_check() {   # $1 = <Module>.lean  $2 = scratch dir  $3 = template; runs from the repo root
  local m=$1 dir=$2 tpl=$3 name rc n ok hit complete other pin
  name=${m%.lean}
  pin=${LEAN_PIN_FILE:-lean/lean-toolchain}
  LEAN_CENSUS_LAST_N=0
  if [ ! -f "$tpl" ]; then
    LEAN_CENSUS_LAST="LEAN_AXIOM_CENSUS_$name=FAIL rc=? template_missing=$tpl"; echo "$LEAN_CENSUS_LAST"; return 1
  fi
  (cd lean && "$LEAN" "$m" -o "$dir/$name.olean") > "$dir/$name.o.out" 2>&1; rc=$?
  if [ "$rc" -ne 0 ] || [ ! -s "$dir/$name.olean" ]; then
    cat "$dir/$name.o.out"
    LEAN_CENSUS_LAST="LEAN_AXIOM_CENSUS_$name=FAIL rc=$rc olean=$([ -s "$dir/$name.olean" ] && echo present || echo missing)"
    echo "$LEAN_CENSUS_LAST"
    [ "$rc" -ne 0 ] && return "$rc"
    return 1
  fi
  sed "s/MODNAME/$name/g" "$tpl" > "$dir/AxiomCensus_$name.lean"
  # The scan is elaborated from the scratch directory, and elan's `lean` proxy picks the toolchain
  # by walking UP from the WORKING DIRECTORY to the nearest lean-toolchain (the B11a note above):
  # without the pin there the scan would run under `elan default` -- an unidentified kernel, or
  # none -- while LEAN_PIN_MATCH was measured from inside lean/. Both attested runs seeded the
  # scratch directory with a copy of the pin before the scan; so does this leg, and it refuses to
  # scan without it (2026-10-27, Codex gpt-6-astra rev_g8l #3 on push group G8L: the first draft
  # omitted the copy; an elan-like stub `lean` then failed the clean census from the scratch cwd).
  cp "$pin" "$dir/lean-toolchain" 2>/dev/null
  if ! cmp -s "$pin" "$dir/lean-toolchain"; then
    LEAN_CENSUS_LAST="LEAN_AXIOM_CENSUS_$name=FAIL rc=? pin_not_in_scratch=$dir"; echo "$LEAN_CENSUS_LAST"
    echo "the scan must elaborate under the pinned toolchain: $pin could not be copied into $dir"
    return 1
  fi
  (cd "$dir" && LEAN_PATH=$dir "$LEAN" "AxiomCensus_$name.lean") > "$dir/$name.census.out" 2>&1; rc=$?
  cat "$dir/$name.census.out"
  ok=$(grep -c -E '^AXSCAN_OK [^ ]+ :: \[' "$dir/$name.census.out")
  hit=$(grep -c 'AXSCAN_HIT' "$dir/$name.census.out")
  complete=$(grep -c -E "^AXSCAN_COMPLETE $name constants=[0-9]+ hits=[0-9]+\$" "$dir/$name.census.out")
  # `other` = every line that is not one of the two VALIDATED forms (an OK line with a name and a
  # bracketed list; THIS module's COMPLETE line). Until 2026-10-27 (Codex gpt-6-astra rev_g8l #6)
  # the exemption was by prefix, so `AXSCAN_COMPLETE Bar constants=1 hits=1` or `AXSCAN_OK malformed
  # garbage` beside a clean census was "nothing else on stdout" and the module passed (measured).
  other=$(grep -v -E "^AXSCAN_OK [^ ]+ :: \[|^AXSCAN_COMPLETE $name constants=[0-9]+ hits=[0-9]+\$" "$dir/$name.census.out" | grep -c '')
  n=$(sed -n -E "s/^AXSCAN_COMPLETE $name constants=([0-9]+) hits=[0-9]+\$/\1/p" "$dir/$name.census.out" | head -n 1)
  [ -n "$n" ] || n=0
  LEAN_CENSUS_LAST_N=$n
  if [ "$rc" -eq 0 ] && [ "$complete" -eq 1 ] && [ "$hit" -eq 0 ] && [ "$other" -eq 0 ] \
     && [ "$n" -ge 1 ] && [ "$ok" -eq "$n" ] \
     && grep -q -E "^AXSCAN_COMPLETE $name constants=$n hits=0\$" "$dir/$name.census.out"; then
    LEAN_CENSUS_LAST="LEAN_AXIOM_CENSUS_$name=PASS constants=$n"; echo "$LEAN_CENSUS_LAST"; return 0
  fi
  LEAN_CENSUS_LAST="LEAN_AXIOM_CENSUS_$name=FAIL rc=$rc constants=$n ok_lines=$ok hits=$hit complete_lines=$complete other_lines=$other"
  echo "$LEAN_CENSUS_LAST"
  echo "a census passes only on rc 0, one AXSCAN_COMPLETE line for $name with hits=0, constants >= 1 and as many AXSCAN_OK lines, and nothing else on stdout"
  [ "$rc" -ne 0 ] && return "$rc"
  return 1
}
LEAN_PIN_FILE=lean/lean-toolchain
# 14 -> 15 on 2026-09-04: `CompilerCorrectness.lean` arrived on `main` with the v4-query-program
# merge (a19682b2). Raised rather than left at 14 for the same reason the compile gate's warning
# baseline is a census and not a budget: a floor pinned BELOW reality still passes while a file
# is silently removed, which is precisely what the floor exists to catch.
LEAN_FILES_MIN=${LEAN_FILES_MIN:-15}
if [ "$HAVE_LEAN" = "0" ]; then
  echo "LEAN_ID=ABSENT"        | tee -a "$LOG"
  echo "LEAN_PIN_MATCH=ABSENT" | tee -a "$LOG"
  for f in lean/*.lean; do skip "$f" "needs lean (elan)"; done
else
  LEAN_PIN=$(head -n 1 "$LEAN_PIN_FILE" 2>/dev/null | tr -d '[:space:]')
  [ -n "$LEAN_PIN" ] || LEAN_PIN=UNREADABLE        # never blank: an empty token reads as a pass
  # Captured, not piped (class-B note above); from INSIDE lean/, the cwd the module checks use.
  LEAN_VER=$(cd lean && "$LEAN" --version 2>&1); LEAN_VER_RC=$?
  [ -n "$LEAN_VER" ] || LEAN_VER=NO_OUTPUT
  # pin `leanprover/lean4:v4.31.0` -> `4.31.0`; `lean --version` prints `Lean (version 4.31.0, …)`.
  _pin_ver=${LEAN_PIN##*:}; _pin_ver=${_pin_ver#v}
  LEAN_PIN_MATCH=FAIL
  if [ "$LEAN_VER_RC" -eq 0 ] && [ "$LEAN_PIN" != UNREADABLE ]; then
    case $LEAN_VER in *"(version $_pin_ver,"*) LEAN_PIN_MATCH=PASS ;; esac
  fi
  echo "LEAN_ID=$LEAN_PIN/$LEAN_VER"            | tee -a "$LOG"
  echo "LEAN_PATH=$(command -v "$LEAN")"        | tee -a "$LOG"
  echo "LEAN_PIN_MATCH=$LEAN_PIN_MATCH"         | tee -a "$LOG"
  check "lean kernel identity matches $LEAN_PIN_FILE ($LEAN_PIN)" \
    "[ \"\$LEAN_PIN_MATCH\" = PASS ] || { printf 'pin: %s\\nran: %s (rc %s)\\n' \"\$LEAN_PIN\" \"\$LEAN_VER\" \"\$LEAN_VER_RC\"; false; }"
  _n=0
  for f in lean/*.lean; do
    _n=$((_n + 1))
    if [ "$LEAN_PIN_MATCH" != PASS ]; then
      check "$f" "echo 'NOT RUN: kernel identity did not match $LEAN_PIN_FILE (LEAN_PIN_MATCH=$LEAN_PIN_MATCH); a proof checked by an unidentified kernel is not evidence'; false"
      continue
    fi
    LEAN_LAST_TOKEN=""
    check "$f" "lean_module_check \"${f#lean/}\""
    # The token is in $LOG already (the check() redirect); repeat it on stdout so a reader can
    # `grep -qx` the run's output for it, the way LEAN_ID= and DRAT_TRIM_ID= are consumed.
    [ -n "$LEAN_LAST_TOKEN" ] && echo "$LEAN_LAST_TOKEN"
  done
  echo "LEAN_FILES=$_n" | tee -a "$LOG"
  check "lean module count >= $LEAN_FILES_MIN (found $_n)" "[ $_n -ge $LEAN_FILES_MIN ]"
  # leg (D): the module-wide collectAxioms census (comment above lean_axiom_census_check)
  LEAN_CENSUS_TEMPLATE=lean/AxiomCensus.lean.in
  LEAN_CENSUS_CONSTANTS_MIN=${LEAN_CENSUS_CONSTANTS_MIN:-1500}
  if [ "$LEAN_PIN_MATCH" != PASS ]; then
    echo "LEAN_AXIOM_CENSUS_CONSTANTS=NOT_RUN (kernel identity did not match $LEAN_PIN_FILE; see LEAN_PIN_MATCH)" | tee -a "$LOG"
  else
    LEAN_CENSUS_DIR=$(mktemp -d "${TMPDIR:-/tmp}/roae_lean_census.XXXXXX") || LEAN_CENSUS_DIR=""
    _tot=0
    for f in lean/*.lean; do
      LEAN_CENSUS_LAST=""; LEAN_CENSUS_LAST_N=0
      if [ -z "$LEAN_CENSUS_DIR" ]; then
        check "lean axiom census $f" "echo 'mktemp -d failed: no scratch directory for the .olean'; false"
      else
        check "lean axiom census $f (collectAxioms over every non-internal constant)" "lean_axiom_census_check \"${f#lean/}\" \"$LEAN_CENSUS_DIR\" \"$LEAN_CENSUS_TEMPLATE\""
      fi
      [ -n "$LEAN_CENSUS_LAST" ] && echo "$LEAN_CENSUS_LAST"
      [ "$LAST_RC" -eq 0 ] && _tot=$((_tot + LEAN_CENSUS_LAST_N))
    done
    [ -n "$LEAN_CENSUS_DIR" ] && rm -rf "$LEAN_CENSUS_DIR"
    echo "LEAN_AXIOM_CENSUS_CONSTANTS=$_tot" | tee -a "$LOG"
    check "lean axiom census constants >= $LEAN_CENSUS_CONSTANTS_MIN over the passing modules (found $_tot)" "[ $_tot -ge $LEAN_CENSUS_CONSTANTS_MIN ]"
  fi
fi
#   (C) SOURCE CENSUS (2026-09-29, Codex LSD R8). Leg (B) reads `#print axioms` reports, so it
#       screens exactly the theorems that carry a directive: a module with NO directive passes on
#       rc alone, and at 5ad06afa five of the fifteen modules carried none (C1RuleConstants,
#       CompilerCorrectness, KingWen, PruneSafety, RecordConvention) while the loaded theorems of
#       three more sat after their module's last directive. This leg reads the SOURCES: every
#       `lean/*.lean` with `--` line comments and (nested) `/- ... -/` blocks removed, and fails
#       the run on any remaining line matching one of the trust-base escape hatches:
#         native_decide  skipKernelTC  implemented_by  extern  unsafe  sorry   (anywhere),
#         ofReduceBool  trustCompiler  `decide +native`  `native := true`     (anywhere: the other
#         spellings of native_decide and the terms it elaborates to), or
#         axiom  opaque  partial def, bare or after private/protected/noncomputable/@[..]
#                                                                             (declaration head).
#       (2026-09-29, Fable batch-26 prepub: the first pattern passed `by decide +native`,
#       `Lean.ofReduceBool _ _ rfl` and `private axiom`, each measured PASS n=0 on a probe.)
#       It needs python3 only, so it runs on a host without Lean too. Positive control (measured on
#       a temp copy of lean/): `theorem _probe : (1:Nat) = 1 := by native_decide` appended to
#       KingWen.lean, which leg (B) passes (no directive names it), prints
#       LEAN_SOURCE_CENSUS=FAIL n=1 here; the shipped tree prints LEAN_SOURCE_CENSUS=PASS n=0.
#       tests.py `TestLeanSourceCensusLeg` runs this same filter (extracted from this file) on
#       that probe on every harness run. What it cannot see: a directive-less theorem proved by
#       an axiom smuggled through a term the regex does not name; leg (B) plus the module-wide
#       constant census recorded in CLAIM_TO_ARTIFACT.md row 13 are the complements.
if [ "$HAVE_PY" = "0" ]; then
  skip "lean source census (no native_decide/axiom/sorry/skipKernelTC/implemented_by/extern/unsafe/opaque/partial def outside comments)" "needs python3"
else
  check "lean source census (no native_decide/axiom/sorry/skipKernelTC/implemented_by/extern/unsafe/opaque/partial def outside comments)" "python3 - <<'PYEOF'
import re, glob, sys
PAT = re.compile(r'\b(native_decide|skipKernelTC|implemented_by|extern|unsafe|sorry|ofReduceBool|trustCompiler)\b|decide\s*\+\s*native\b|native\s*:=\s*true|^\s*(?:(?:private|protected|noncomputable|@\[[^\]]*\])\s+)*(axiom|opaque|partial\s+def)\b')
# String-aware since 2026-10-23 (Codex gpt-6-astra F01-001#1 and five siblings, push group G8L):
# until then this had no string-literal state, so a definition whose string body is the two
# characters /- opened a block comment that never closed, and everything after it -- an axiom,
# a native_decide -- was stripped as comment text and the census printed PASS n=0 (measured; a
# bare axiom printed FAIL n=1). Lean's lexer gives a string literal priority over a comment
# opener inside it, so the census must too: ordinary string bodies (with backslash escapes),
# raw r#...# string bodies and the char literal holding a double quote are skipped at comment
# depth 0; inside an interpolated s!/m!/f! string body the braces open an expression that is
# CODE (scanned, with its own literals and comments). The stripped text keeps every newline, so hit line numbers are source line
# numbers. A structural check per file follows: an unterminated block comment or string at end
# of file, or a file with no non-blank line left after stripping, is a census hit in its own
# right (a runaway opener is exactly the fail-open shape above). NB: this heredoc is the body of
# a double-quoted check() argument, so it must contain no double-quote character (Q-742): Q is it.
# Rewritten 2026-10-27 (Codex gpt-6-astra rev_g8l #2, #4, #5 on the first draft of this leg): one
# recursive scanner in Lean's lexical order. The draft dropped an interpolation EXPRESSION with its
# string body (a sorry inside s!...{...} printed PASS n=0 -- the pre-2026-10-23 census caught it),
# let a double quote inside an escaped identifier open a string (the next declaration's by sorry
# vanished), and counted a brace inside a char literal or a comment within an interpolation as an
# expression brace (valid Lean printed FAIL n=1); all three measured. Code is emitted; comment text and string BODIES are dropped (newlines kept).
# An interpolation expression {...} inside an s!/m!/f! body is CODE and is emitted (it can hold
# sorry/native_decide); its nested strings, comments and char literals follow the same rules.
# An escaped identifier «...» is one token: a double quote inside it opens nothing. A char literal
# (any of 'Q', 'BS Q', '{', 'BS {', 'BS u{41}', ...) is one token: its brace or quote opens nothing.
# NB: no double-quote character anywhere in this heredoc (Q-742): Q is it.
Q = chr(34); BS = chr(92); NL = chr(10); SQ = chr(39)
CHAR_LIT = re.compile(SQ + '(?:' + BS + BS + 'u' + BS + '{[0-9a-fA-F]+' + BS + '}|' + BS + BS + '.|[^' + BS + BS + SQ + NL + '])' + SQ)
RAW_OPEN = re.compile('r#*' + Q)
class _State:
    def __init__(self, src):
        self.src, self.n, self.out, self.ok = src, len(src), [], True
def _skip_block_comment(st, i):
    # st.src[i:] starts with /- ; returns the index just past the matching -/ (nested), keeping newlines
    src, n, depth = st.src, st.n, 0
    while i < n:
        if src.startswith('/-', i):
            depth += 1; i += 2; continue
        if src.startswith('-/', i):
            depth -= 1; i += 2
            if depth == 0:
                return i
            continue
        if src[i] == NL:
            st.out.append(NL)
        i += 1
    st.ok = False
    return n
def _skip_string(st, i, interp):
    # st.src[i] == Q ; returns the index just past the closing quote; the body is dropped,
    # except an interpolation expression, which is scanned as code
    src, n = st.src, st.n
    i += 1
    while i < n:
        c = src[i]
        if c == BS:
            if i + 1 < n and src[i + 1] == NL:
                st.out.append(NL)
            i += 2; continue
        if c == Q:
            return i + 1
        if c == NL:
            st.out.append(NL)
        if interp and c == '{':
            i = _scan(st, i + 1, True)
            if i >= n:
                return n
            continue
        i += 1
    st.ok = False
    return n
def _skip_raw_string(st, i):
    src, n = st.src, st.n
    j = i + 1
    while j < n and src[j] == '#':
        j += 1
    close = Q + '#' * (j - (i + 1))
    k = src.find(close, j + 1)
    if k < 0:
        st.out.append(NL * src.count(NL, i)); st.ok = False
        return n
    st.out.append(NL * src.count(NL, i, k))
    return k + len(close)
def _scan(st, i, in_expr):
    # scan CODE from i; emits it. in_expr: stop at the } that closes the interpolation
    # expression (returns the index just past it). Otherwise runs to end of file.
    src, n, out = st.src, st.n, st.out
    depth = 0
    while i < n:
        c = src[i]
        if src.startswith('--', i):
            while i < n and src[i] != NL:
                i += 1
            continue
        if src.startswith('/-', i):
            i = _skip_block_comment(st, i); continue
        if c == chr(171):                                   # « escaped identifier »
            k = src.find(chr(187), i + 1)
            if k < 0:
                st.ok = False; out.append(src[i:]); return n
            out.append(src[i:k + 1]); i = k + 1; continue
        if c == SQ and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] in '_.' + SQ)):
            m = CHAR_LIT.match(src, i)
            if m:
                out.append(m.group(0)); i = m.end(); continue
        raw = RAW_OPEN.match(src, i) and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] in '_.'))
        if c == Q or raw:
            if raw:
                i = _skip_raw_string(st, i)
            else:
                interp = i >= 2 and src[i - 1] == '!' and src[i - 2] in 'smf'
                i = _skip_string(st, i, interp)
            continue
        if in_expr:
            if c == '{':
                depth += 1
            elif c == '}':
                if depth == 0:
                    return i + 1
                depth -= 1
        out.append(c); i += 1
    if in_expr:
        st.ok = False
    return n
def strip_comments(src):
    st = _State(src)
    _scan(st, 0, False)
    return ''.join(st.out), st.ok
files = sorted(glob.glob('lean/*.lean'))
if len(files) < 15:
    print('LEAN_SOURCE_CENSUS=FAIL n=NO_SOURCES')
    raise SystemExit('FAIL: the census saw %d lean/*.lean files (needs >= 15); an empty census is not a pass' % len(files))
hits = []
for f in files:
    text, ok = strip_comments(open(f, encoding='utf-8').read())
    if not ok:
        hits.append((f, 0, 'unterminated block comment, string literal, interpolation or escaped identifier at end of file (a runaway opener hides everything after it)'))
    if not any(t.strip() for t in text.split(chr(10))):
        hits.append((f, 0, 'no non-blank line left after stripping (the file is all comment or string, or an opener swallowed it)'))
    for ln, text in enumerate(text.split(chr(10)), 1):
        if PAT.search(text):
            hits.append((f, ln, text.strip()[:120]))
for f, ln, text in hits:
    print('  census hit %s:%d: %s' % (f, ln, text))
print('LEAN_SOURCE_CENSUS=%s n=%d' % ('PASS' if not hits else 'FAIL', len(hits)))
if hits:
    raise SystemExit('FAIL: %d trust-base escape hatch(es) outside comments' % len(hits))
PYEOF"
fi

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
  skip "tests.py (regression harness, >= 1500 executed tests)" "needs gcc + python3 (tests.py builds verify.c)"
else
  # FLOOR 1500 EXECUTED (2026-10-22, G5b): tests.py declares over 1,900 test methods; the floor
  # leaves room for the skips a host without the optional tools (Lean, a SAT solver) takes.
  check "tests.py (regression harness, >= 1500 executed tests)" \
    "require_tests_floor 1500 python3 tests.py"
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
  # names its own carve-outs — gates 1, 5, 13 and GATE 17 LEG B are report-only (GATE 24 has
  # been in `all` since 2026-09-04; Codex FV-FT1-G:OOS:12214), and GATE 18 is hard for UNADJUDICATED defects only. A PASS here is
  # exactly what the banner says it is and no more. Measured 2026-09-02: 2m24s, 38 gates.
  check "scripts/doc_gates.sh (documentation gates, 'all' mode)" \
    "require_match 'DOC GATES: PASS  — hard gates only:' bash scripts/doc_gates.sh"
fi

echo; echo "RESULT: $PASS passed, $FAIL failed, $RESOURCE host-resource errors, $SKIP skipped"
echo "  full command output: $LOG"
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
