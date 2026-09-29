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
# declaration) and every advisory leg ALWAYS run locally; see "Q-798: TREE-KEYED REUSE" in
# scripts/pre_push_gate.sh and DEVELOPMENT.md section "Pre-push verdict record".
#
# MODES
#   write --out FILE --hook-log F --tests-log F --citation-log F --stamp-log F [--repo DIR]
#       Distils a COMPLETED check into a record. Every verdict is read from the logs by token
#       (exactly one KEY= line, whole-line value), never taken from the caller. The repo's HEAD
#       tree must equal the hook log's PREPUSH_TREE, and the repo must be clean against HEAD, so
#       the record names the tree the checks ran on. FILE must not lie inside the repo's tree.
#       Tokens: PREPUSH_RECORD=WRITTEN|ERROR, and PREPUSH_RECORD_ALL_PASS=YES|NO when written.
#       Exit 0 written and all PASS / 1 written with a non-PASS result / 2 nothing written.
#   check --record FILE --tree TREE --citgate-base SHA|NONE [--forbid-under DIR]...
#       Reads a record and says whether it covers TREE. Token: PREPUSH_RECORD=MATCH|NOMATCH, and
#       on NOMATCH exactly one PREPUSH_RECORD_WHY=<code>. Exit 0 MATCH / 1 NOMATCH / 2 bad usage
#       (PREPUSH_RECORD=ERROR). WHY codes: absent unreadable inside-tree empty too-large truncated
#       nul-byte bad-line bad-header checksum duplicate-key unknown-key missing-key bad-value
#       not-pass:<LEG> tree-mismatch citbase-mismatch toolchain-mismatch.
#   toolchain
#       Prints the toolchain id this host would record (gcc and python3 versions).
#
# RECORD FORMAT, version 1: plain text, one KEY=value per line, LF-terminated, no spaces, in this
# order (the order is fixed so the checksum is well defined; the reader checks key SET and values):
#   ROAE_PREPUSH_RECORD=1
#   TREE=<git tree id of the checked tree, 40 or 64 hex>
#   CITGATE_BASE=<commit the citation gate's shift leg diffed against, or NONE>
#   TOOLCHAIN=gcc-<ver>,python-<ver>
#   LEG_<NAME>=PASS|FAIL|NOT-RUN|MISSING|REUSED|UNREADABLE   (one per name in REQ_LEGS below)
#   LOG_<NAME>_SHA256=<64 hex>                                (one per name in REQ_LOGS below)
#   RECORD_SHA256=<sha256 of every byte above this line>      (LAST line; catches truncation)
# The record is an ATTESTATION by whoever wrote it, not a proof: the operator who can hand the hook
# a record can equally run `git push --no-verify`. What it adds over --no-verify is that the hook
# still runs every local leg, refuses any record that is not complete and all-PASS for this exact
# tree, and prints the record's log digests into the push log so the reuse is visible and auditable.
set -u
export LC_ALL=C

REC_VERSION=1
MAX_BYTES=65536
# Hook legs the record carries (the hook prints PREPUSH_LEG_<NAME>= for each, per pushed sha).
HOOK_LEGS="DOC_GATES_ALL GENERATED COMPILE_GATE PUBLISHED_CONSISTENCY R167 R167_M3 R167_M4 ATLAS_N31 TR12_OUTPUT_PATHS"
# Every result a record must carry, all PASS: the hook legs, the hook's own overall verdict, the
# regression harness, the citation gate over every target, and the reproduction stamp.
REQ_LEGS="$HOOK_LEGS HOOK TESTS CITATION TR12_STAMP_CURRENT"
REQ_LOGS="HOOK TESTS CITATION STAMP"

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
  one_val PREPUSH_TREE "$HL" || err "write: the hook log has no single PREPUSH_TREE= line (one pushed sha per producer run)"
  [ "$TOKV" = "$headtree" ] || err "write: the hook log gated tree '$TOKV', but HEAD's tree is $headtree"
  one_val PREPUSH_CITGATE_BASE "$HL" || err "write: the hook log has no single PREPUSH_CITGATE_BASE= line"
  cb=$TOKV
  { [ "$cb" = NONE ] || is_hex_id "$cb"; } || err "write: PREPUSH_CITGATE_BASE='$cb' is neither NONE nor an object id"

  declare -A V=()
  for leg in $HOOK_LEGS; do
    if one_val "PREPUSH_LEG_$leg" "$HL"; then
      case "$TOKV" in PASS|FAIL|NOT-RUN|REUSED) V[$leg]=$TOKV ;; *) V[$leg]=UNREADABLE ;; esac
    else V[$leg]=MISSING; fi
  done
  if one_val PREPUSH_VERDICT "$HL"; then
    case "$TOKV" in PASS) V[HOOK]=PASS ;; FAIL) V[HOOK]=FAIL ;; *) V[HOOK]=UNREADABLE ;; esac
  else V[HOOK]=MISSING; fi
  # tests.py is unittest: PASS = exactly one "Ran N tests in" line, exactly one bare OK line (with
  # or without a parenthesised skip/xfail count), and no FAILED line anywhere.
  nran=$(grep -acE '^Ran [0-9]+ tests? in ' "$TL") || true
  nok=$(grep -acE '^OK( \([a-z_=0-9, ]+\))?$' "$TL") || true
  nfail=$(grep -acE '^FAILED' "$TL") || true
  if [ "${nran:-0}" = 1 ] && [ "${nok:-0}" = 1 ] && [ "${nfail:-0}" = 0 ]; then V[TESTS]=PASS; else V[TESTS]=FAIL; fi
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
    printf '%s=%s\n' TOOLCHAIN "$(toolchain_id)"
    for leg in $REQ_LEGS; do printf '%s=%s\n' "LEG_$leg" "${V[$leg]}"; done
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
  size=$(wc -c < "$REC" | tr -d ' ') || size=""
  case "$size" in ''|*[!0-9]*) nomatch unreadable "could not size $REC" ;; esac
  [ "$size" -gt 0 ] || nomatch empty "$REC is empty"
  [ "$size" -le "$MAX_BYTES" ] || nomatch too-large "$REC is $size bytes (limit $MAX_BYTES)"
  [ "$(tail -c1 "$REC" | od -An -tx1 | tr -d ' \n')" = 0a ] || nomatch truncated "$REC does not end in a newline"
  [ "$(tr -d '\000' < "$REC" | wc -c | tr -d ' ')" = "$size" ] || nomatch nul-byte "$REC contains a NUL byte"
  nbad=$(grep -avcE '^[A-Z][A-Z0-9_]*=[A-Za-z0-9._,:-]+$' "$REC") || true
  [ "${nbad:-1}" = 0 ] || nomatch bad-line "$nbad line(s) of $REC are not KEY=value"
  [ "$(head -n1 "$REC")" = "ROAE_PREPUSH_RECORD=$REC_VERSION" ] \
    || nomatch bad-header "first line is not ROAE_PREPUSH_RECORD=$REC_VERSION"
  last=$(tail -n1 "$REC")
  case "$last" in RECORD_SHA256=*) ;; *) nomatch truncated "last line is not RECORD_SHA256= (record cut short)" ;; esac
  [ "$(sed '$d' "$REC" | sha256sum | cut -c1-64)" = "${last#RECORD_SHA256=}" ] \
    || nomatch checksum "RECORD_SHA256 does not match the lines above it"
  dup=$(cut -d= -f1 "$REC" | sort | uniq -d | head -1)
  [ -z "$dup" ] || nomatch duplicate-key "key $dup appears more than once"
  allowed=" ROAE_PREPUSH_RECORD TREE CITGATE_BASE TOOLCHAIN RECORD_SHA256 "
  for leg in $REQ_LEGS; do allowed="$allowed LEG_$leg "; done
  for lg in $REQ_LOGS;  do allowed="$allowed LOG_${lg}_SHA256 "; done
  while IFS= read -r k; do
    case "$allowed" in *" $k "*) ;; *) nomatch unknown-key "key $k is not in record format v$REC_VERSION" ;; esac
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
  echo "  record $(sha256sum < "$REC" | cut -c1-16) covers tree $rtree (citation base $rcb, $TOKV)"
  for lg in $REQ_LOGS; do one_val "LOG_${lg}_SHA256" "$REC"; echo "    log ${lg}: sha256 $TOKV"; done
  echo "PREPUSH_RECORD=MATCH"
  exit 0
fi

echo "usage: $0 write --out FILE --hook-log F --tests-log F --citation-log F --stamp-log F [--repo DIR]"
echo "       $0 check --record FILE --tree TREE --citgate-base SHA|NONE [--forbid-under DIR]..."
echo "       $0 toolchain"
echo "PREPUSH_RECORD=ERROR"
exit 2
