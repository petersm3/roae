#!/bin/bash
# prepush_verdict_record.sh — TREE-KEYED VERDICT RECORD for the pre-push hook (Q-798, 2026-09-27).
#
# WHY. scripts/pre_push_gate.sh re-runs the whole blocking battery (doc_gates all, the compile
# gate, the #167 resume legs, ...) on the pushing machine. When a separate, larger machine has
# ALREADY run that battery green on the IDENTICAL tree, the second run adds no information and
# costs the pushing machine minutes of CPU and disk I/O (Q-798: ~16 min on a 2-core box for one
# push of a tree already checked green elsewhere). This script lets the first run leave a record
# and the hook reuse it — only on an exact tree match, and only when every recorded result is PASS.
#
# WHAT IS NOT CHANGED. No gate is weakened or removed. Absent, unreadable, truncated, malformed,
# non-PASS, or for any other tree / citation base / toolchain: the hook runs the FULL battery,
# exactly as before. Legs whose answer depends on the pushing clone's refs, history, network or git
# config (branch registry, append-only ledger, revision rows, tracked-but-ignored files, new-ref
# declaration), and GATE 21 (script-paths), whose private-checkout legs depend on ROAE_PRIVATE_DIR
# (Q-919), ALWAYS run locally; see "Q-798: TREE-KEYED REUSE" in scripts/pre_push_gate.sh and
# DEVELOPMENT.md section "Pre-push verdict record".
#
# ADVISORY LEGS (lane HAJ, 2026-09-27). The record also carries the verdicts of the hook's ADVISORY
# legs whose answer depends on nothing but the tree and the toolchain (ADV_LEGS below), under the same
# exact-tree binding. They stay advisory: an ADV_ verdict never decides MATCH (a record with an ADV_
# FAIL still matches, and the hook reports that FAIL without blocking), and a record that lacks one, or
# carries NOT-RUN, MISSING, REUSED or UNREADABLE for it, only means the hook runs that leg itself.
# EXCLUDED, and why (they always run locally): doc_gates.sh --selftest (its fire-proofs read history:
# `git rev-list HEAD -- documentation/CORRECTIONS.md` and the named commits b5bcff7c and 00c0db0, in a
# clone that fetches refs/remotes/origin/*); the scale-distinguishable gate (a private script, located
# by ROAE_PRIVATE_DIR); the review-loop and Group C legs (they read $ROOT, the pushing clone's working
# tree and private state, not the pushed tree); the reproduction stamp and the row-assertion sweep
# (tree-only, but under a second each: nothing to save, and the stamp stays a local cross-check of the
# record's own LEG_TR12_STAMP_CURRENT).
#
# MODES
#   write --out FILE --hook-log F --tests-log F --citation-log F --stamp-log F [--repo DIR]
#       Distils a COMPLETED check into a record. Every verdict is read from the logs by token
#       (exactly one KEY= line, whole-line value), never taken from the caller. The repo's HEAD
#       tree must equal the hook log's PREPUSH_TREE, and the repo must be clean against HEAD, so
#       the record names the tree the checks ran on. FILE must not lie inside the repo's tree.
#       Q-956 (format v2): EVERY log is bound to that tree, not only the hook's. Each producer names
#       the tree it measured in one line, and the writer refuses (nothing written) a log whose line
#       is absent, repeated, DIRTY/NONE or names another tree:
#         hook log      PREPUSH_TREE=<tree>              (scripts/pre_push_gate.sh, per pushed sha)
#         tests log     ROAE_TESTS_TREE=<tree>           (tests.py, before the first test runs)
#         citation log  CITATION_LINE_GATE_TREE=<tree>   (citation_line_gate.sh --all-files)
#         stamp log     TR12_REPRO_GATE_TREE=<tree>      (tr12_repro_gate.sh --check)
#       TOOLCHAIN comes from the LOGS, not from the writing host: the hook log's PREPUSH_TOOLCHAIN=
#       and the tests log's ROAE_TESTS_TOOLCHAIN= (the interpreter that ran tests.py) must both be
#       present and agree with each other AND with this host's toolchain id; any disagreement is
#       refused. TESTS is PASS only with exactly one "Ran N tests" line, N >= TESTS_FLOOR (the
#       number of `    def test_` methods in the record tree's tests.py, at least 1, so "Ran 0" is a
#       FAIL), at most MAX_TEST_SKIPS skipped/expected-failure tests, one OK line and no FAILED line.
#       Every log is read from a private snapshot, so what is judged is what is hashed.
#       Tokens: PREPUSH_RECORD=WRITTEN|ERROR, and PREPUSH_RECORD_ALL_PASS=YES|NO when written.
#       Exit 0 written and all PASS / 1 written with a non-PASS result / 2 nothing written.
#   check --record FILE --tree TREE --citgate-base SHA|NONE [--forbid-under DIR]...
#       Reads a record and says whether it covers TREE. Token: PREPUSH_RECORD=MATCH|NOMATCH, and
#       on NOMATCH exactly one PREPUSH_RECORD_WHY=<code>. Exit 0 MATCH / 1 NOMATCH / 2 bad usage
#       (PREPUSH_RECORD=ERROR). WHY codes: absent unreadable inside-tree empty too-large truncated
#       nul-byte bad-line bad-header old-version checksum duplicate-key unknown-key missing-key
#       bad-value not-pass:<LEG> tests-count tree-mismatch citbase-mismatch toolchain-mismatch.
#       old-version (Q-956): the record is a well-formed header of another format version (a v1
#       record carries no per-log tree binding and a host-stamped toolchain); it is never reused,
#       re-run the writer with this tree's scripts. The record is read once into a private
#       snapshot and every check reads the snapshot, not the path.
#   toolchain
#       Prints the toolchain id this host would record (gcc and python3 versions).
#
# RECORD FORMAT, version 2 (Q-956; version 1 lacked the per-log bindings and TESTS_*): plain text, one KEY=value per line, LF-terminated, no spaces, in this
# order (the order is fixed so the checksum is well defined; the reader checks key SET and values):
#   ROAE_PREPUSH_RECORD=2
#   TREE=<git tree id of the checked tree, 40 or 64 hex>
#   CITGATE_BASE=<commit the citation gate's shift leg diffed against, or NONE>
#   TOOLCHAIN=gcc-<ver>,python-<ver>          (from the hook and tests logs; see write above)
#   TESTS_RAN=<N>  TESTS_FLOOR=<F>  TESTS_SKIPPED=<S>   (one per line; the tests log's counts)
#   LEG_<NAME>=PASS|FAIL|NOT-RUN|MISSING|REUSED|UNREADABLE   (one per name in REQ_LEGS below)
#   ADV_<NAME>=PASS|FAIL|NOT-RUN|MISSING|REUSED|UNREADABLE   (OPTIONAL; one per name in ADV_LEGS below)
#   LOG_<NAME>_SHA256=<64 hex>                                (one per name in REQ_LOGS below)
#   RECORD_SHA256=<sha256 of every byte above this line>      (LAST line; catches truncation)
# The record is an ATTESTATION by whoever wrote it, not a proof: the operator who can hand the hook
# a record can equally run `git push --no-verify`. What it adds over --no-verify is that the hook
# still runs every local leg, refuses any record that is not complete and all-PASS for this exact
# tree, and prints the record's log digests into the push log so the reuse is visible and auditable.
set -u
export LC_ALL=C

REC_VERSION=2
MAX_BYTES=65536
# Q-956: a full run skips 1-3 tests on the worker (tools a lane box lacks); a fail-open that skips a
# whole class (E4: `OK (skipped=12)`) must not count as PASS.
MAX_TEST_SKIPS=8
TOOLCHAIN_RE='^gcc-([0-9.]+|none),python-([0-9.]+|none)$'
# Hook legs the record carries (the hook prints PREPUSH_LEG_<NAME>= for each, per pushed sha).
HOOK_LEGS="DOC_GATES_ALL GENERATED COMPILE_GATE PUBLISHED_CONSISTENCY R167 R167_M3 R167_M4 ATLAS_N31 TR12_OUTPUT_PATHS"
# Every result a record must carry, all PASS: the hook legs, the hook's own overall verdict, the
# regression harness, the citation gate over every target, and the reproduction stamp.
REQ_LEGS="$HOOK_LEGS HOOK TESTS CITATION TR12_STAMP_CURRENT"
REQ_LOGS="HOOK TESTS CITATION STAMP"
# Advisory hook legs the record MAY carry (the hook prints PREPUSH_ADV_<NAME>= for each, per pushed sha).
# Optional keys: a record without them is a valid record, and the hook runs those legs itself.
ADV_LEGS="Q479_F1C5_ADOPT Q479_RESUME_BUDGET Q479_MISSING_SHARD REPRODUCE_DIGESTS FAILOPEN_CLOSURE"

err() {   # $1 = ERROR cause (log line), exit 2
  echo "  [ERROR] $1"
  echo "PREPUSH_RECORD=ERROR"
  exit 2
}
nomatch() {   # $1 = WHY code, $2 = human line
  echo "  [nomatch] $2"
  echo "PREPUSH_RECORD=NOMATCH"
  echo "PREPUSH_RECORD_WHY=$1"
  exit 1
}

toolchain_id() {
  local g p
  g=$(gcc -dumpfullversion 2>/dev/null) || g=""
  case "$g" in ''|*[!0-9.]*) g=none ;; esac
  p=$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])' 2>/dev/null) || p=""
  case "$p" in ''|*[!0-9.]*) p=none ;; esac
  printf 'gcc-%s,python-%s\n' "$g" "$p"
}

# Exactly-one reader, same contract as one_token() in pre_push_gate.sh: the count of ^KEY= lines
# must be 1, else nothing is believed. Sets TOKV to the value (text after the first '=').
TOKV=""
one_val() {   # $1 key, $2 file
  local n
  TOKV=""
  n=$(grep -acE "^$1=" "$2" 2>/dev/null) || true
  [ "${n:-0}" = 1 ] || return 1
  TOKV=$(grep -aE "^$1=" "$2")
  TOKV=${TOKV#*=}
  return 0
}

# Is $1 (a path) at or under directory $2? Both are resolved; an unresolvable path is "under"
# (fail closed: a record we cannot place is not trusted).
path_under() {
  local p d
  p=$(realpath -m -- "$1" 2>/dev/null) || return 0
  d=$(realpath -m -- "$2" 2>/dev/null) || return 0
  [ -n "$p" ] && [ -n "$d" ] || return 0
  case "$p/" in "$d"/*) return 0 ;; esac
  return 1
}

is_hex_id() { [[ "$1" =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]]; }

MODE=${1:-}
[ $# -gt 0 ] && shift

# =============================================================================================
if [ "$MODE" = toolchain ]; then
  toolchain_id
  exit 0
fi

# =============================================================================================
if [ "$MODE" = write ]; then
  OUT=""; HL=""; TL=""; CL=""; SL=""; REPO=.
  while [ $# -gt 0 ]; do
    case "$1" in
      --out)          OUT=${2:-}; shift 2 || shift ;;
      --hook-log)     HL=${2:-}; shift 2 || shift ;;
      --tests-log)    TL=${2:-}; shift 2 || shift ;;
      --citation-log) CL=${2:-}; shift 2 || shift ;;
      --stamp-log)    SL=${2:-}; shift 2 || shift ;;
      --repo)         REPO=${2:-}; shift 2 || shift ;;
      *) err "write: unknown argument '$1'" ;;
    esac
  done
  [ -n "$OUT" ] && [ -n "$HL" ] && [ -n "$TL" ] && [ -n "$CL" ] && [ -n "$SL" ] \
    || err "write needs --out, --hook-log, --tests-log, --citation-log and --stamp-log"
  for f in "$HL" "$TL" "$CL" "$SL"; do
    [ -f "$f" ] && [ -r "$f" ] || err "write: log '$f' is missing or unreadable — nothing to distil"
  done
  top=$(git -C "$REPO" rev-parse --show-toplevel 2>/dev/null) || err "write: '$REPO' is not a git work tree"
  path_under "$OUT" "$top" && err "write: --out '$OUT' lies inside the checked tree ($top); a record must live outside it"
  headtree=$(git -C "$top" rev-parse -q --verify 'HEAD^{tree}' 2>/dev/null) || err "write: no HEAD commit in $top"
  [ "$(git -C "$top" rev-parse --is-shallow-repository 2>/dev/null)" = false ] || err "write: $top is a shallow clone; doc_gates.sh's require_tracked() reads history for an absent path, so a record from here would not carry a full clone's answers"
  # The logs describe the working tree they ran in; the record names a TREE ID. Those are the same
  # thing only when tracked content equals HEAD, so a dirty tree is refused, not recorded.
  git -C "$top" diff --quiet HEAD -- 2>/dev/null && git -C "$top" diff --cached --quiet HEAD -- 2>/dev/null \
    || err "write: $top has tracked changes against HEAD; the logs cannot be attributed to tree $headtree"
  # Q-956: judge and hash private snapshots, so a log rewritten mid-distil cannot split the two.
  SNAP=$(mktemp -d "${TMPDIR:-/tmp}/prepush_logs.XXXXXX") || err "write: mktemp failed"
  trap 'rm -rf "$SNAP"' EXIT
  cp -- "$HL" "$SNAP/hook" && cp -- "$TL" "$SNAP/tests" && cp -- "$CL" "$SNAP/citation" && cp -- "$SL" "$SNAP/stamp" \
    || err "write: could not snapshot the logs"
  HL=$SNAP/hook; TL=$SNAP/tests; CL=$SNAP/citation; SL=$SNAP/stamp
  one_val PREPUSH_TREE "$HL" || err "write: the hook log has no single PREPUSH_TREE= line (one pushed sha per producer run)"
  [ "$TOKV" = "$headtree" ] || err "write: the hook log gated tree '$TOKV', but HEAD's tree is $headtree"
  one_val PREPUSH_CITGATE_BASE "$HL" || err "write: the hook log has no single PREPUSH_CITGATE_BASE= line"
  cb=$TOKV
  { [ "$cb" = NONE ] || is_hex_id "$cb"; } || err "write: PREPUSH_CITGATE_BASE='$cb' is neither NONE nor an object id"
  # Q-956 (2): every auxiliary log names the tree it measured; a log for another tree, a dirty
  # tree, or no tree at all is not evidence about this one.
  for _b in "tests:$TL:ROAE_TESTS_TREE" "citation:$CL:CITATION_LINE_GATE_TREE" "stamp:$SL:TR12_REPRO_GATE_TREE"; do
    _n=${_b%%:*}; _k=${_b##*:}; _f=${_b#*:}; _f=${_f%:*}
    one_val "$_k" "$_f" || err "write: the $_n log has no single $_k= line (its producer predates Q-956, or it is not that producer's log)"
    [ "$TOKV" = "$headtree" ] || err "write: the $_n log measured tree '$TOKV', but the record's tree is $headtree"
  done
  # Q-956 (1): the toolchain is what the logs say ran, and it must be this host's too.
  one_val PREPUSH_TOOLCHAIN "$HL" || err "write: the hook log has no single PREPUSH_TOOLCHAIN= line"
  tc_hook=$TOKV
  one_val ROAE_TESTS_TOOLCHAIN "$TL" || err "write: the tests log has no single ROAE_TESTS_TOOLCHAIN= line"
  tc_tests=$TOKV
  [[ "$tc_hook" =~ $TOOLCHAIN_RE ]] || err "write: PREPUSH_TOOLCHAIN='$tc_hook' is not a toolchain id"
  [ "$tc_tests" = "$tc_hook" ] || err "write: the tests ran under '$tc_tests' but the hook under '$tc_hook'"
  [ "$tc_hook" = "$(toolchain_id)" ] || err "write: the logs were measured with '$tc_hook' but this host has $(toolchain_id); distil on the host that ran them"

  declare -A V=()
  for leg in $HOOK_LEGS; do
    if one_val "PREPUSH_LEG_$leg" "$HL"; then
      case "$TOKV" in PASS|FAIL|NOT-RUN|REUSED) V[$leg]=$TOKV ;; *) V[$leg]=UNREADABLE ;; esac
    else V[$leg]=MISSING; fi
  done
  declare -A A=()
  for leg in $ADV_LEGS; do
    if one_val "PREPUSH_ADV_$leg" "$HL"; then
      case "$TOKV" in PASS|FAIL|NOT-RUN|REUSED) A[$leg]=$TOKV ;; *) A[$leg]=UNREADABLE ;; esac
    else A[$leg]=MISSING; fi
  done
  if one_val PREPUSH_VERDICT "$HL"; then
    case "$TOKV" in PASS) V[HOOK]=PASS ;; FAIL) V[HOOK]=FAIL ;; *) V[HOOK]=UNREADABLE ;; esac
  else V[HOOK]=MISSING; fi
  # tests.py is unittest: PASS = exactly one "Ran N tests in" line, exactly one bare OK line (with
  # or without a parenthesised skip/xfail count), and no FAILED line anywhere. Q-956 (3): and N is
  # at least the tree's own test count (so "Ran 0 tests" + OK, or a one-class run, is a FAIL), and
  # at most MAX_TEST_SKIPS of them were skipped or expected failures.
  nran=$(grep -acE '^Ran [0-9]+ tests? in ' "$TL") || true
  nok=$(grep -acE '^OK( \([a-z_=0-9, ]+\))?$' "$TL") || true
  nfail=$(grep -acE '^FAILED' "$TL") || true
  tran=0; tskip=0
  if [ "${nran:-0}" = 1 ]; then tran=$(grep -aE '^Ran [0-9]+ tests? in ' "$TL" | sed -E 's/^Ran ([0-9]+) .*/\1/'); fi
  if [ "${nok:-0}" = 1 ]; then
    _okl=$(grep -aE '^OK( \([a-z_=0-9, ]+\))?$' "$TL")
    for _sk in $(printf '%s\n' "$_okl" | grep -oE '(skipped|expected failures)=[0-9]+' | sed 's/.*=//'); do tskip=$((tskip + 10#$_sk)); done
  fi
  # Q-982 (c) (batch 42; Codex gpt-6-astra, Q964-D07#3): the floor's POPULATION must be read, not
  # assumed. This was `git show … 2>/dev/null | grep -c … || true` and then `[ -ge 1 ] || tfloor=1`, so
  # a failed READ of HEAD:tests.py floored to ONE and `Ran 1 test` + `OK` recorded LEG_TESTS=PASS.
  # Now: HEAD's listing must be readable; a tests.py it lists must be read, and must hold at least one
  # test method; either failure is an ERROR and no record is written. A HEAD that carries no tests.py
  # at all (the hook's own test fixtures) keeps the floor of 1, as before.
  _tls=$(git -C "$top" ls-tree HEAD -- tests.py 2>/dev/null) \
    || err "write: cannot list HEAD (git ls-tree failed), so the tree's test count (the TESTS floor) is unknown"
  if [ -n "$_tls" ]; then
    git -C "$top" show HEAD:tests.py >/dev/null 2>&1 \
      || err "write: HEAD lists tests.py but it cannot be read, so the TESTS floor is unknown"
  fi
  tfloor=$(git -C "$top" show HEAD:tests.py 2>/dev/null | grep -cE '^    def test_') || true
  case "$tfloor" in ''|*[!0-9]*) tfloor=0 ;; esac
  if [ -n "$_tls" ]; then
    [ "$tfloor" -ge 1 ] || err "write: HEAD:tests.py has no test methods, so the TESTS floor has no population"
  else
    tfloor=1
  fi
  case "$tran" in ''|*[!0-9]*) tran=0 ;; esac
  tran=$((10#$tran))
  if [ "${nran:-0}" = 1 ] && [ "${nok:-0}" = 1 ] && [ "${nfail:-0}" = 0 ] \
     && [ "$tran" -ge "$tfloor" ] && [ "$tskip" -le "$MAX_TEST_SKIPS" ]; then V[TESTS]=PASS; else V[TESTS]=FAIL; fi
  [ "$tran" -ge "$tfloor" ] || echo "  [tests] Ran $tran test(s), fewer than the tree's $tfloor test methods"
  [ "$tskip" -le "$MAX_TEST_SKIPS" ] || echo "  [tests] $tskip tests skipped or expected-failure (limit $MAX_TEST_SKIPS)"
  if one_val CITATION_LINE_GATE "$CL"; then
    [ "$TOKV" = PASS ] && V[CITATION]=PASS || V[CITATION]=FAIL
  else V[CITATION]=MISSING; fi
  if one_val TR12_REPRO_GATE_CURRENT "$SL"; then
    [ "$TOKV" = YES ] && V[TR12_STAMP_CURRENT]=PASS || V[TR12_STAMP_CURRENT]=FAIL
  else V[TR12_STAMP_CURRENT]=MISSING; fi

  body=$(mktemp "${TMPDIR:-/tmp}/prepush_record.XXXXXX") || err "write: mktemp failed"
  {
    printf '%s=%s\n' ROAE_PREPUSH_RECORD "$REC_VERSION"
    printf '%s=%s\n' TREE "$headtree"
    printf '%s=%s\n' CITGATE_BASE "$cb"
    printf '%s=%s\n' TOOLCHAIN "$tc_hook"
    printf '%s=%s\n' TESTS_RAN "$tran"
    printf '%s=%s\n' TESTS_FLOOR "$tfloor"
    printf '%s=%s\n' TESTS_SKIPPED "$tskip"
    for leg in $REQ_LEGS; do printf '%s=%s\n' "LEG_$leg" "${V[$leg]}"; done
    for leg in $ADV_LEGS; do printf '%s=%s\n' "ADV_$leg" "${A[$leg]}"; done
    printf '%s=%s\n' LOG_HOOK_SHA256     "$(sha256sum < "$HL" | cut -c1-64)"
    printf '%s=%s\n' LOG_TESTS_SHA256    "$(sha256sum < "$TL" | cut -c1-64)"
    printf '%s=%s\n' LOG_CITATION_SHA256 "$(sha256sum < "$CL" | cut -c1-64)"
    printf '%s=%s\n' LOG_STAMP_SHA256    "$(sha256sum < "$SL" | cut -c1-64)"
  } > "$body" || { rm -f "$body"; err "write: could not compose the record"; }
  printf '%s=%s\n' RECORD_SHA256 "$(sha256sum < "$body" | cut -c1-64)" >> "$body"
  # Atomic replace: a reader never sees a half-written record under the final name.
  tmp="$OUT.tmp.$$"
  cp -- "$body" "$tmp" && mv -f -- "$tmp" "$OUT" || { rm -f "$body" "$tmp"; err "write: could not write '$OUT'"; }
  rm -f "$body"
  allpass=YES
  for leg in $REQ_LEGS; do
    [ "${V[$leg]}" = PASS ] || { allpass=NO; echo "  [not-pass] LEG_$leg=${V[$leg]}"; }
  done
  for leg in $ADV_LEGS; do
    [ "${A[$leg]}" = PASS ] || echo "  [advisory] ADV_$leg=${A[$leg]} (advisory: does not affect ALL_PASS)"
  done
  echo "  record for tree $headtree written to $OUT"
  echo "PREPUSH_RECORD=WRITTEN"
  echo "PREPUSH_RECORD_ALL_PASS=$allpass"
  [ "$allpass" = YES ] && exit 0
  exit 1
fi

# =============================================================================================
if [ "$MODE" = check ]; then
  REC=""; WANT_TREE=""; WANT_CB=""; FORBID=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --record)       REC=${2:-}; shift 2 || shift ;;
      --tree)         WANT_TREE=${2:-}; shift 2 || shift ;;
      --citgate-base) WANT_CB=${2:-}; shift 2 || shift ;;
      --forbid-under) FORBID+=("${2:-}"); shift 2 || shift ;;
      *) err "check: unknown argument '$1'" ;;
    esac
  done
  [ -n "$REC" ] && [ -n "$WANT_TREE" ] && [ -n "$WANT_CB" ] \
    || err "check needs --record, --tree and --citgate-base"
  is_hex_id "$WANT_TREE" || err "check: --tree '$WANT_TREE' is not an object id"
  { [ "$WANT_CB" = NONE ] || is_hex_id "$WANT_CB"; } || err "check: --citgate-base '$WANT_CB' is neither NONE nor an object id"

  [ -e "$REC" ] || nomatch absent "no record at $REC"
  [ -f "$REC" ] && [ -r "$REC" ] || nomatch unreadable "$REC is not a readable regular file"
  for d in "${FORBID[@]+"${FORBID[@]}"}"; do
    [ -n "$d" ] || continue
    path_under "$REC" "$d" && nomatch inside-tree "$REC lies inside $d; a record inside the tree it vouches for is refused"
  done
  # Q-956: read the record ONCE into a private snapshot (one byte past the limit is enough to tell
  # too-large); every check below reads the snapshot, so the path cannot change between passes.
  SNAP=$(mktemp "${TMPDIR:-/tmp}/prepush_rec.XXXXXX") || err "check: mktemp failed"
  trap 'rm -f "$SNAP"' EXIT
  head -c "$((MAX_BYTES + 1))" -- "$REC" > "$SNAP" 2>/dev/null || nomatch unreadable "could not read $REC"
  REC_SHOWN=$REC; REC=$SNAP
  size=$(wc -c < "$REC" | tr -d ' ') || size=""
  case "$size" in ''|*[!0-9]*) nomatch unreadable "could not size $REC" ;; esac
  [ "$size" -gt 0 ] || nomatch empty "$REC is empty"
  [ "$size" -le "$MAX_BYTES" ] || nomatch too-large "$REC_SHOWN is more than $MAX_BYTES bytes"
  [ "$(tail -c1 "$REC" | od -An -tx1 | tr -d ' \n')" = 0a ] || nomatch truncated "$REC does not end in a newline"
  [ "$(tr -d '\000' < "$REC" | wc -c | tr -d ' ')" = "$size" ] || nomatch nul-byte "$REC contains a NUL byte"
  nbad=$(grep -avcE '^[A-Z][A-Z0-9_]*=[A-Za-z0-9._,:-]+$' "$REC") || true
  [ "${nbad:-1}" = 0 ] || nomatch bad-line "$nbad line(s) of $REC are not KEY=value"
  _h1=$(head -n1 "$REC")
  if [ "$_h1" != "ROAE_PREPUSH_RECORD=$REC_VERSION" ]; then
    [[ "$_h1" =~ ^ROAE_PREPUSH_RECORD=[0-9]+$ ]] \
      && nomatch old-version "record format v${_h1#*=} is not v$REC_VERSION, the only format this tree reuses (Q-956: v1 records carry no per-log tree binding); re-run scripts/prepush_verdict_record.sh write with this tree's scripts"
    nomatch bad-header "first line is not ROAE_PREPUSH_RECORD=$REC_VERSION"
  fi
  last=$(tail -n1 "$REC")
  case "$last" in RECORD_SHA256=*) ;; *) nomatch truncated "last line is not RECORD_SHA256= (record cut short)" ;; esac
  [ "$(sed '$d' "$REC" | sha256sum | cut -c1-64)" = "${last#RECORD_SHA256=}" ] \
    || nomatch checksum "RECORD_SHA256 does not match the lines above it"
  dup=$(cut -d= -f1 "$REC" | sort | uniq -d | head -1)
  [ -z "$dup" ] || nomatch duplicate-key "key $dup appears more than once"
  allowed=" ROAE_PREPUSH_RECORD TREE CITGATE_BASE TOOLCHAIN TESTS_RAN TESTS_FLOOR TESTS_SKIPPED RECORD_SHA256 "
  for leg in $REQ_LEGS; do allowed="$allowed LEG_$leg "; done
  for lg in $REQ_LOGS;  do allowed="$allowed LOG_${lg}_SHA256 "; done
  optional=" "
  for leg in $ADV_LEGS; do optional="$optional ADV_$leg "; done
  while IFS= read -r k; do
    case "$allowed$optional" in *" $k "*) ;; *) nomatch unknown-key "key $k is not in record format v$REC_VERSION" ;; esac
  done < <(cut -d= -f1 "$REC")
  for k in $allowed; do
    grep -aqE "^$k=" "$REC" || nomatch missing-key "key $k is missing"
  done
  one_val TREE "$REC";  rtree=$TOKV
  is_hex_id "$rtree" || nomatch bad-value "TREE=$rtree is not an object id"
  one_val CITGATE_BASE "$REC"; rcb=$TOKV
  { [ "$rcb" = NONE ] || is_hex_id "$rcb"; } || nomatch bad-value "CITGATE_BASE=$rcb"
  for lg in $REQ_LOGS; do
    one_val "LOG_${lg}_SHA256" "$REC"
    [[ "$TOKV" =~ ^[0-9a-f]{64}$ ]] || nomatch bad-value "LOG_${lg}_SHA256 is not a sha256"
  done
  one_val TOOLCHAIN "$REC"
  [[ "$TOKV" =~ $TOOLCHAIN_RE ]] || nomatch bad-value "TOOLCHAIN=$TOKV is not a toolchain id"
  for k in TESTS_RAN TESTS_FLOOR TESTS_SKIPPED; do
    one_val "$k" "$REC"
    [[ "$TOKV" =~ ^(0|[1-9][0-9]{0,8})$ ]] || nomatch bad-value "$k=$TOKV is not a count"
  done
  one_val TESTS_RAN "$REC"; rran=$TOKV
  one_val TESTS_FLOOR "$REC"; rfloor=$TOKV
  one_val TESTS_SKIPPED "$REC"; rskip=$TOKV
  # Q-956 (3), re-checked here so a resealed record cannot carry a PASS over a short run.
  { [ "$rfloor" -ge 1 ] && [ "$rran" -ge "$rfloor" ] && [ "$rskip" -le "$MAX_TEST_SKIPS" ]; } \
    || nomatch tests-count "TESTS_RAN=$rran TESTS_FLOOR=$rfloor TESTS_SKIPPED=$rskip: not a full test run"
  for leg in $ADV_LEGS; do
    one_val "ADV_$leg" "$REC" || continue
    case "$TOKV" in PASS|FAIL|NOT-RUN|MISSING|REUSED|UNREADABLE) ;; *) nomatch bad-value "ADV_$leg=$TOKV" ;; esac
  done
  # Every result must be PASS. NOT-RUN, MISSING, REUSED (a record distilled from a hook run that
  # itself reused a record) and FAIL all refuse the whole record: a partial record is no record.
  for leg in $REQ_LEGS; do
    one_val "LEG_$leg" "$REC"
    [ "$TOKV" = PASS ] || nomatch "not-pass:$leg" "LEG_$leg=$TOKV — the record is not all-PASS"
  done
  [ "$rtree" = "$WANT_TREE" ] || nomatch tree-mismatch "record is for tree $rtree, the pushed tree is $WANT_TREE"
  [ "$rcb" = "$WANT_CB" ] || nomatch citbase-mismatch "record's citation base is $rcb, this push's is $WANT_CB"
  one_val TOOLCHAIN "$REC"
  [ "$TOKV" = "$(toolchain_id)" ] || nomatch toolchain-mismatch "record was measured with $TOKV, this host has $(toolchain_id)"
  echo "  record $(sha256sum < "$REC" | cut -c1-16) ($REC_SHOWN) covers tree $rtree (citation base $rcb, $TOKV)"
  for lg in $REQ_LOGS; do one_val "LOG_${lg}_SHA256" "$REC"; echo "    log ${lg}: sha256 $TOKV"; done
  # Advisory verdicts the hook may reuse: only PASS and FAIL are measurements; the rest are omitted.
  for leg in $ADV_LEGS; do
    one_val "ADV_$leg" "$REC" || continue
    case "$TOKV" in PASS|FAIL) printf '%s=%s\n' "PREPUSH_RECORD_ADV_$leg" "$TOKV" ;; esac
  done
  echo "PREPUSH_RECORD=MATCH"
  exit 0
fi

echo "usage: $0 write --out FILE --hook-log F --tests-log F --citation-log F --stamp-log F [--repo DIR]"
echo "       $0 check --record FILE --tree TREE --citgate-base SHA|NONE [--forbid-under DIR]..."
echo "       $0 toolchain"
echo "PREPUSH_RECORD=ERROR"
exit 2
