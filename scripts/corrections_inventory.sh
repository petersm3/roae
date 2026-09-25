#!/usr/bin/env bash
# corrections_inventory.sh — mechanical inventory of CORRECTION EVENTS in this repo.
#
# WHAT IT IS
#   The raw feedstock for documentation/CORRECTIONS.md. It sweeps three independent
#   sources, classifies every candidate line, and writes an 8-column TSV:
#
#     id  date  class  matched  source  document  line  text
#
#   CORRECTIONS.md is the CURATED ledger written from this inventory by hand; this file
#   is the UNCURATED evidence the ledger is answerable to. Neither replaces the other:
#   a hand ledger with no sweep behind it cannot be shown to be complete, and a sweep
#   with no ledger in front of it is 600 grep hits nobody will read.
#
# WHY THE `matched` COLUMN IS REQUIRED (and is not a nicety)
#   An earlier build of this inventory recorded only <class> and a TRUNCATED <text>.
#   When a row was classified C1 the evidence for that verdict had usually been cut off
#   by the truncation, so auditing "why is this a retraction?" meant re-deriving the
#   classifier by hand — one full debugging cycle, 2026-08-01. `matched` records the
#   exact keyword that DROVE the class. A classifier that reports its verdict without
#   its reason is not auditable, and an unauditable classifier is the defect class that
#   dominated 2026-08-01: the checker, not the fix, was where the errors lived.
#
# WHY C1 REQUIRES A HARD TOKEN
#   C1 was first keyed on soft prose ("that claim is false", "was wrong", "refuted").
#   That produced 21 false positives — every counterexample discussion, every null-model
#   caveat, and every sentence describing someone ELSE's refuted claim scored as one of
#   OUR retractions. C1 now requires an explicit retraction verb (retract / withdraw /
#   rescind). Soft prose is deliberately NOT a C1 token; it is left to the other classes
#   or dropped. Under-firing on a real retraction is caught by GATE 11 (completeness
#   against RETRACTED_PHRASES.tsv), which is registry-driven and does not depend on
#   this classifier at all — that is the point of having both.
#
# USAGE
#   scripts/corrections_inventory.sh            # write documentation/CORRECTIONS_INVENTORY.tsv
#   scripts/corrections_inventory.sh --stdout   # write to stdout instead
#   scripts/corrections_inventory.sh --summary  # counts per class/source, no file written
#   scripts/corrections_inventory.sh --selftest # known-answer anchors (see below)
#
# ERRORS: every refusal prints one `CORRECTIONS_INVENTORY=ERROR <cause> ...` line and exits 2
# without touching the published TSV. Causes: source-failed:markdown | source-failed:git |
# shallow-repository | mktemp-failed | sweep-failed (incl. id-collision) | population-collapsed.
# (Same one-line shape as the pre-existing population-collapsed line; splitting the cause onto a
# separate whole-line cause token needs a DEVELOPMENT.md token-table row first.)
#
# SAFETY (2-core orchestrator)
#   Index-based `git grep` / `git log` only. No `find` over trees. NO bounded-repetition
#   regex (`.{0,N}`) anywhere — a pathological one hung this box on a 381-byte input.
#   Exactly one pass per source and exactly one awk process does all classification.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

OUT="documentation/CORRECTIONS_INVENTORY.tsv"
LEDGER="documentation/CORRECTIONS.md"

# ---------------------------------------------------------------------------
# CLASS TOKEN TABLES.
#
# These four strings ARE the classifier. Priority is C1 > C2 > C3 > C4: a line that
# says "retracted ... corrected" is a retraction, not a typo fix. `matched` records
# which token of the WINNING class fired, so the priority decision is visible per row.
#
# C1 RETRACTION — a published claim was withdrawn or its truth value reversed.
#   HARD tokens only. See "WHY C1 REQUIRES A HARD TOKEN" above.
C1_RE='retract(ed|ion|ions|ing)?|withdraw(n|al|als|ing|s)?|rescind(ed|s)?'
#
# C2 CIRCULATED SCOPE-LABEL — the claim survived; the SCOPE or epistemic label attached
#   to it changed after it had already been circulated, so the fix had to be propagated
#   into every document that had repeated the old label. This is its own class because
#   its failure mode is distinct: the claim reads fine locally and is wrong globally.
C2_RE='rescop(e|ed|es|ing)|re-scop(e|ed|ing)|under-scoped|mis-scoped|over-scoped|mis-?label(l?ed|l?ing|s)?|scope note|scope-label|propagat(e|ed|es|ion|ions|ing)'
#
# C3 TYPO / CONSISTENCY — a value, pointer, date, digit or wording was corrected without
#   any claim changing truth value or scope. The bulk class by construction.
C3_RE='corrected|correction(s)?|erratum|errata|typo(s|ed)?|misprint(s)?|off-by|rounding|transcription|consistency|supersed(e|ed|es|ing)|renumber(ed|ing)?'
#
# C4 QUALIFIER — a caveat / hedge / qualifier was added or tightened. EXCLUDED from
#   CORRECTIONS.md: a qualifier is load-bearing SCOPE that is live in the current text,
#   not a historical event. Kept in the inventory (never deleted) so the exclusion is
#   auditable rather than invisible. Lowest priority, so it only wins when nothing else did.
C4_RE='qualifier(s)?|qualif(y|ied|ies|ication(s)?)|hedg(e|ed|es|ing)|caveat(s)?'

ALL_RE="$C1_RE|$C2_RE|$C3_RE|$C4_RE"

# CORRECTIONS.md and this TSV are excluded from the sweep. They are ABOUT corrections,
# so including them makes every regeneration re-ingest its own output and the inventory
# grows without bound. Stated here because a silent exclusion is the container-level
# exemption that let "hard floor k >= 13" survive in TR-4's body (see doc_gates.sh).
PATHSPEC=( -- '*.md' ":!$LEDGER" )

# ---------------------------------------------------------------------------
# SOURCE 1 + 2 — markdown corpus.
#   A line inside a report's Revision-history table (`| v1.7 | 2026-.. | ...`) is a
#   per-report CHANGELOG row; anything else is an INLINE marker. They are separated
#   because they have different reliability: a changelog row is a deliberate record and
#   an inline marker is prose, and TR-2 v1.20 is the standing proof that a changelog row
#   can assert a propagation that never happened.
# 🔴 2026-09-24 (Q-747, Codex v3 E3 V3A-105#1): `2>/dev/null` used to hide this command's
# errors, and its status was lost inside `{ src_markdown; src_git; } | classify` (a brace group's
# status is its LAST command's). A `git grep` that could not run therefore produced 0 markdown rows
# while ~744 git rows cleared the population floor, and the published inventory was overwritten
# with no INL-/CHA- rows at rc 0. stderr is no longer suppressed, and sweep() below reads each
# source's status separately. Under pipefail this function's status is git grep's: 0 = matches,
# 1 = no match at all (itself impossible for this corpus, so also a failure), >1 = error.
src_markdown() {
  git grep -n -I -i -E "$ALL_RE" "${PATHSPEC[@]}" | awk '
    { gsub(/\t/, " ") }
    {
      i = index($0, ":"); if (i == 0) next
      f = substr($0, 1, i-1); r = substr($0, i+1)
      j = index(r, ":");      if (j == 0) next
      ln = substr(r, 1, j-1); t = substr(r, j+1)
      src = (t ~ /^\| *[vV][0-9]/) ? "changelog" : "inline"
      print src "\t" f "\t" ln "\t" t
    }'
}

# ---------------------------------------------------------------------------
# SOURCE 3 — git log.
#   Each commit is flattened to ONE record (subject + body) with \x01 as the record
#   separator, so a multi-line body cannot break the framing. One `git log`, one `tr`
#   chain; no per-commit subprocess.
#
#   🔴 2026-09-24 (Q-747, V3A-105#2): the hash is `%H` cut to a FIXED 8 characters. It was `%h`,
#   whose length is core.abbrev's (7 on a default-config clone, "auto" grows it with the object
#   count), and that string is `doc`, which enters the id's hash key. At core.abbrev=7 none of the
#   562 published GIT- ids reproduced; every published GIT- row carries an 8-character hash, so a
#   fixed 8 reproduces all of them on any clone, whatever its config. `%H` + cut, not
#   `--abbrev=8`: git lengthens an abbreviation that is ambiguous, and the length must not depend
#   on the object store either. A shallow clone is refused in sweep(): it would publish a
#   truncated history as the whole of it.
src_git() {
  git log --date=short --format='%x01%H%x09%ad%x09%s %b' \
    | tr -d '\r' | tr '\t' ' ' | tr '\n' ' ' | tr '\001' '\n' | awk -v RE="$ALL_RE" '
    NF == 0 { next }
    {
      n = split($0, a, " ")
      # fields were joined with a literal space by the format string; recover them
      sha = a[1]; dt = a[2]
      msg = substr($0, length(sha) + length(dt) + 3)
      sha = substr(sha, 1, 8)
      if (tolower(msg) ~ RE) print "git\t" sha "\t" dt "\t" msg
    }'
}

# ---------------------------------------------------------------------------
# CLASSIFIER — one awk process for every record from every source.
#   Emits: id  date  class  matched  source  document  line  text
#
#   id is CONTENT-ADDRESSED (source + document + normalised text), not a sequence
#   number. A sequence number renumbers every downstream row the moment one candidate
#   is inserted, which would break CORRECTIONS.md's append-only property by way of its
#   own id column. Hash = polynomial mod 1000000007, printed hex. Collisions are
#   detected and reported, not silently merged.
classify() {
  awk -F'\t' \
    -v C1RE="$C1_RE" -v C2RE="$C2_RE" -v C3RE="$C3_RE" -v C4RE="$C4_RE" \
    -v MAXTEXT=400 '
    function hash(s,   i, h, n) {
      h = 0; n = length(s)
      for (i = 1; i <= n; i++) h = (h * 131 + index(CHARS, substr(s, i, 1))) % 1000000007
      return sprintf("%x", h)
    }
    function firsttok(low, re,   m) {
      if (match(low, re) == 0) return ""
      return substr(low, RSTART, RLENGTH)
    }
    BEGIN {
      CHARS = " !\"#$%&'"'"'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
      OFS = "\t"
      tokre["C1"] = C1RE; tokre["C2"] = C2RE; tokre["C3"] = C3RE; tokre["C4"] = C4RE
      print "id", "date", "class", "matched", "source", "document", "line", "text"
    }
    {
      src = $1
      if (src == "git") { doc = $2; ln = "-"; dt = $3; text = $4 }
      else              { doc = $2; ln = $3;  dt = "";  text = $4 }

      low = tolower(text)

      cls = ""; tok = ""
      tok = firsttok(low, C1RE); if (tok != "") { cls = "C1" }
      if (cls == "") { tok = firsttok(low, C2RE); if (tok != "") cls = "C2" }
      if (cls == "") { tok = firsttok(low, C3RE); if (tok != "") cls = "C3" }
      if (cls == "") { tok = firsttok(low, C4RE); if (tok != "") cls = "C4" }
      if (cls == "") next

      # date: an explicit ISO date on the line beats everything (it is the date the
      # correction is ASSERTED to have happened); otherwise the commit date; else "-".
      # 🔴 2026-09-24 (Q-747, V3A-105#4): the date is BOUND TO THE MARKER when the line says so.
      # It used to be the FIRST ISO date on the line, so CANONICAL_HASHES.md:117 -- "... not
      # planned (2026-08-01) ... WITHDRAWN 2026-08-24 -- ..." -- was dated 2026-08-01, a date the
      # line gives for something else. Now, when an occurrence of a token of the winning class is
      # IMMEDIATELY followed by a date (only spaces/punctuation between: "WITHDRAWN 2026-08-24",
      # "(Corrected 2026-07-04:"), that date is the one asserted. Otherwise the first date, as
      # before. Deliberately tight: a looser "first date within 40 characters after the token"
      # was measured against the corpus and mis-dated rows such as "supersedes the 2026-07-03
      # estimator value" and "corrected ... -- a 2026-05-30 doc-pass", where the nearby date is
      # the thing corrected, not the correction. A `changelog` row keeps its row date (column 2 of
      # a revision table, which is also its first date). The date is not part of the id.
      if (match(text, /20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        dt = substr(text, RSTART, RLENGTH)
        if (src != "changelog") {
          scan = low; off = 0
          while (match(scan, tokre[cls])) {
            rest = substr(text, off + RSTART + RLENGTH)
            adv = RSTART + RLENGTH
            if (match(rest, /^[^A-Za-z0-9]*20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]/) && RLENGTH <= 14) {
              dt = substr(rest, RLENGTH - 9, 10); break
            }
            scan = substr(scan, adv); off += adv - 1
          }
        }
      }
      else if (dt == "") dt = "-"

      # Truncation marker is explicit. `matched` above already carries the evidence for
      # the verdict, which is the whole reason truncation is survivable here.
      out = text
      if (length(out) > MAXTEXT) out = substr(out, 1, MAXTEXT) "  [...truncated]"
      gsub(/[[:space:]]+/, " ", out)
      sub(/^ /, "", out)

      key = src "|" doc "|" tolower(out)
      id = toupper(substr(src, 1, 3)) "-" hash(key)
      # 🔴 2026-09-24 (Q-747, V3A-105#3): the id is hashed over the TRUNCATED text (kept, so that
      # none of the 1,115 truncated published ids renumbers), but the collision check now compares
      # the FULL normalised text. It compared `key`, so two distinct lines sharing their first
      # MAXTEXT characters -- the same key by construction -- got one id silently (Fable R: a
      # C3 line and a C1 line, one id, rc 0). Identical full text is the same row, not a collision.
      full = text; gsub(/[[:space:]]+/, " ", full); sub(/^ /, "", full)
      fkey = src "|" doc "|" tolower(full)
      if (id in seen && seen[id] != fkey) {
        printf("COLLISION\t%s\t%s\n", id, key) > "/dev/stderr"
        collided = 1
      }
      seen[id] = fkey
      print id, dt, cls, tok, src, doc, ln, out
    }
    END { if (collided) exit 3 }'
}

# 🔴 2026-09-24 (Q-747, V3A-105#1): each source is captured to its own file and its status read
# BEFORE anything is classified. See src_markdown for the fail-open this replaces. A source that
# fails, or yields nothing, is an ERROR with its name on the line: the population floor below is a
# second net, and it did not catch this case (744 git rows clear a floor of 50 on their own).
sweep() {
  local d rc_md rc_git rc
  d=$(mktemp -d) || { echo "CORRECTIONS_INVENTORY=ERROR mktemp-failed" >&2; return 2; }
  if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" != "false" ]; then
    echo "CORRECTIONS_INVENTORY=ERROR shallow-repository — git log would see a truncated history" >&2
    rm -rf "$d"; return 2
  fi
  src_markdown > "$d/md";  rc_md=$?
  src_git      > "$d/git"; rc_git=$?
  if [ "$rc_md" -ne 0 ] || [ ! -s "$d/md" ]; then
    echo "CORRECTIONS_INVENTORY=ERROR source-failed:markdown rc=$rc_md rows=$(grep -c . "$d/md")" >&2
    rm -rf "$d"; return 2
  fi
  if [ "$rc_git" -ne 0 ] || [ ! -s "$d/git" ]; then
    echo "CORRECTIONS_INVENTORY=ERROR source-failed:git rc=$rc_git rows=$(grep -c . "$d/git")" >&2
    rm -rf "$d"; return 2
  fi
  cat "$d/md" "$d/git" | classify; rc=$?
  rm -rf "$d"; return "$rc"
}

# ---------------------------------------------------------------------------
# SELF-TEST — known-answer anchors, written before the classifier was trusted.
#
#   Each anchor is a REAL line from this repo (or the exact false-positive shape that
#   motivated a rule) with a hand-computed expected class. If the classifier drifts, the
#   anchor fails and names which rule moved. Anchors are checked against the CLASSIFIER
#   ITSELF via stdin, not against the corpus, so they keep working as the corpus changes.
selftest() {
  local rc=0 tmp
  tmp=$(mktemp) || return 2

  # anchor <label> <expected-class> <expected-matched> <text>
  anchor() {
    local label="$1" ecls="$2" etok="$3" txt="$4" got gcls gtok
    got=$(printf 'inline\tANCHOR.md\t1\t%s\n' "$txt" | classify | tail -n +2)
    gcls=$(printf '%s' "$got" | cut -f3)
    gtok=$(printf '%s' "$got" | cut -f4)
    if [ "$gcls" = "$ecls" ] && [ "$gtok" = "$etok" ]; then
      echo "  [ok]   $label -> $gcls via \"$gtok\""
    else
      echo "  [FAIL] $label -> got ($gcls, \"$gtok\"), expected ($ecls, \"$etok\")"
      rc=1
    fi
  }

  echo "== CORRECTIONS INVENTORY SELF-TEST (known-answer anchors) =="

  # (1) The motivating C1: SPECIFICATION.md:106, the retracted forced-orientation theorem.
  anchor "C1 hard token (SPECIFICATION.md:106 shape)" C1 "retracted" \
    '**RETRACTED (2026-07-26) — former "Theorem (Forced orientation)".** That claim is false.'

  # (2) The 21 false positives. THIS IS THE ANCHOR THAT DEFINES C1: soft prose asserting
  #     falsity, with no retraction verb, must NOT be C1. It carries no other class token
  #     either, so the correct answer is "no row at all" — the classifier must stay silent.
  local softout
  softout=$(printf 'inline\tANCHOR.md\t1\t%s\n' \
    'The claim is false and the premise was wrong; the published result is refuted.' \
    | classify | tail -n +2)
  if [ -z "$softout" ]; then
    echo "  [ok]   C1 soft-prose false positive is NOT classified (the 21-FP anchor)"
  else
    echo "  [FAIL] C1 soft-prose false positive was classified: $softout"
    rc=1
  fi

  # (3) C2, in the exact shape of the 2026-08-01 propagation failure.
  anchor "C2 circulated scope-label (TR-2 v1.20 shape)" C2 "rescoped" \
    'Conflict theorem rescoped 2026-07-30 to C1nC2nC4nC5 scope; propagated 2026-08-01.'

  # (4) C3, the bulk class.
  anchor "C3 typo/consistency (SOLVE.md:334 shape)" C3 "corrected" \
    '*(Corrected 2026-07-04: previously listed as "4".)*'

  # (5) C4, which must be reachable but must NOT outrank anything.
  anchor "C4 qualifier (excluded class, still reachable)" C4 "caveat" \
    'Applying the same methodology adds a critical methodological caveat.'

  # (6) PRIORITY. A line carrying BOTH a C1 and a C3 token must classify C1 and must
  #     say so via `matched`. Without this anchor the priority order is untested and a
  #     retraction narrated as a "correction" would be filed as a typo.
  anchor "priority C1 > C3 on a mixed line" C1 "withdrawn" \
    'Withdrawn 2026-08-01: the hard-floor claim; corrected label is heuristic floor k >= 12.'

  # (7) DATE extraction prefers the asserted date over any commit date.
  local dout
  dout=$(printf 'git\tabc1234\t2026-01-01\tCorrected 2026-07-05 per Shaughnessy 2022\n' \
    | classify | tail -n +2 | cut -f2)
  if [ "$dout" = "2026-07-05" ]; then
    echo "  [ok]   date prefers the asserted ISO date (2026-07-05) over the commit date"
  else
    echo "  [FAIL] date extraction: got '$dout', expected 2026-07-05"
    rc=1
  fi

  # (8) SOURCE separation: a revision-history row is `changelog`, not `inline`.
  #     This anchor calls src_markdown ITSELF. The first version re-implemented the
  #     splitter inside the anchor and then `head -400`-ed the corpus, so it tested a
  #     copy of the logic against a truncated input and reported FAIL while the real
  #     splitter was fine — a checker defect, which is the class that dominated
  #     2026-08-01. An anchor that does not run the production code path proves nothing.
  local sc si
  sc=$(src_markdown | awk -F'\t' '$1=="changelog"' | wc -l)
  si=$(src_markdown | awk -F'\t' '$1=="inline"'    | wc -l)
  if [ "${sc:-0}" -gt 0 ] && [ "${si:-0}" -gt 0 ]; then
    echo "  [ok]   src_markdown separates sources (changelog=$sc, inline=$si)"
  else
    echo "  [FAIL] src_markdown split degenerate (changelog=$sc, inline=$si)"
    rc=1
  fi

  # (8b) and it must put a KNOWN revision row on the changelog side. TR-9's v1.16 row is
  #      the anchor: a `| v1.16 | 2026-08-01 | ...corrected...` line that any naive
  #      "line contains 'corrected'" sweep would file as inline prose.
  local kr
  kr=$(src_markdown | awk -F'\t' '$2=="reports/TR9_PRICING_THE_CONSTRAINTS.md" && $1=="changelog"' | wc -l)
  if [ "${kr:-0}" -gt 0 ]; then
    echo "  [ok]   known changelog rows in TR-9 land in the changelog source ($kr)"
  else
    echo "  [FAIL] TR-9 revision rows did not land in the changelog source"
    rc=1
  fi

  # (9) ID STABILITY: the same input twice must produce the same id.
  local i1 i2
  i1=$(printf 'inline\tX.md\t1\tCorrected 2026-07-04: previously listed as 4.\n' | classify | tail -1 | cut -f1)
  i2=$(printf 'inline\tX.md\t9\tCorrected 2026-07-04: previously listed as 4.\n' | classify | tail -1 | cut -f1)
  if [ -n "$i1" ] && [ "$i1" = "$i2" ]; then
    echo "  [ok]   id is content-addressed and line-number independent ($i1)"
  else
    echo "  [FAIL] id instability: '$i1' vs '$i2' (line number leaked into the id)"
    rc=1
  fi

  # (10)-(13) 2026-09-24, Q-747 (Codex v3 E3 V3A-105). Each leg is the red case Fable R executed.
  # (10) GIT- ids do not depend on core.abbrev: every git row's hash is exactly 8 characters at
  #      core.abbrev=7 (the default-config clone that reproduced 0 of 562 published ids).
  local badlen ngit
  ngit=$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.abbrev GIT_CONFIG_VALUE_0=7 src_git | grep -c .)
  badlen=$(GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.abbrev GIT_CONFIG_VALUE_0=7 src_git \
             | awk -F'\t' 'length($2) != 8' | grep -c .)
  if [ "${ngit:-0}" -gt 0 ] && [ "${badlen:-1}" -eq 0 ]; then
    echo "  [ok]   GIT- hash column is a fixed 8 characters at core.abbrev=7 ($ngit rows)"
  else
    echo "  [FAIL] GIT- hash column depends on core.abbrev (rows=$ngit, not 8 chars=$badlen)"
    rc=1
  fi

  # (11) two DISTINCT lines sharing their first 400 characters get one id: that must be a loud
  #      COLLISION (exit 3), not a silent merge. Control: the same line twice is one row, rc 0.
  local pfx crc crc2
  pfx=$(printf 'x%.0s' $(seq 1 405))     # > MAXTEXT, so both lines truncate to the same 400
  printf 'inline\tX.md\t1\t%s Corrected tail one\ninline\tX.md\t2\t%s Withdrawn tail two\n' "$pfx" "$pfx" \
    | classify >/dev/null 2>&1; crc=$?
  printf 'inline\tX.md\t1\t%s Corrected tail one\ninline\tX.md\t2\t%s Corrected tail one\n' "$pfx" "$pfx" \
    | classify >/dev/null 2>&1; crc2=$?
  if [ "$crc" -eq 3 ] && [ "$crc2" -eq 0 ]; then
    echo "  [ok]   shared-400-char-prefix lines collide LOUDLY (rc 3); an identical repeat does not"
  else
    echo "  [FAIL] truncated-prefix collision: distinct rc=$crc (want 3), identical rc=$crc2 (want 0)"
    rc=1
  fi

  # (12) the date is the one bound to the marker, not the first on the line (CANONICAL_HASHES:117).
  dout=$(printf 'inline\tX.md\t1\t%s\n' \
    'not planned (2026-08-01). More prose here. **[WITHDRAWN 2026-08-24 — the figure exceeds its own bound' \
    | classify | tail -n +2 | cut -f2)
  if [ "$dout" = "2026-08-24" ]; then
    echo "  [ok]   date bound to the marker (2026-08-24), not the first date on the line"
  else
    echo "  [FAIL] date binding: got '$dout', expected 2026-08-24"
    rc=1
  fi

  # (13) a markdown source that cannot run fails the sweep; it does not publish git rows alone.
  local shim src
  shim=$(mktemp -d) && {
    printf '#!/bin/sh\n[ "$1" = grep ] && { echo "shim: git grep refused" >&2; exit 2; }\nexec %s "$@"\n' \
      "$(command -v git)" > "$shim/git"; chmod +x "$shim/git"
    PATH="$shim:$PATH" sweep >/dev/null 2>&1; src=$?
    rm -rf "$shim"
    if [ "$src" -ne 0 ]; then
      echo "  [ok]   a failing git grep fails the sweep (rc $src)"
    else
      echo "  [FAIL] a failing git grep still returned rc 0 from sweep"
      rc=1
    fi
  }

  rm -f "$tmp"
  echo
  [ "$rc" -eq 0 ] && echo "CORRECTIONS INVENTORY SELF-TEST: PASS" \
                  || echo "CORRECTIONS INVENTORY SELF-TEST: FAIL"
  return "$rc"
}

# ---------------------------------------------------------------------------
case "${1:-}" in
  --selftest) selftest; exit $? ;;
  --stdout)   sweep; exit $? ;;
  --summary)
    sweep | awk -F'\t' 'NR>1 { c[$3]++; s[$5]++; n++ }
      END { printf "candidates: %d\n", n
            for (k in c) printf "  class %s  %6d\n", k, c[k] | "sort"
            close("sort")
            for (k in s) printf "  source %-10s %6d\n", k, s[k] | "sort" }'
    exit $? ;;
  "") ;;
  *)  echo "usage: $0 [--stdout|--summary|--selftest]"; exit 2 ;;
esac

sweep > "$OUT.new"; SRC=$?
if [ "$SRC" -ne 0 ]; then
  rm -f "$OUT.new"
  # a failed source already said why (stderr); an id collision (classify rc 3) printed COLLISION rows
  echo "CORRECTIONS_INVENTORY=ERROR sweep-failed rc=$SRC$([ "$SRC" -eq 3 ] && echo ' id-collision') — $OUT NOT overwritten"
  exit 2
fi
# 🔴 POPULATION FLOOR (2026-09-05 fail-open class sweep). `src_markdown` runs `git grep … 2>/dev/null`
# and `src_git` runs `git log … 2>/dev/null`; when either cannot run, the sweep is EMPTY and this
# script used to print "wrote 0 candidates", overwrite the published inventory with a header-only
# file, and exit 0. An inventory of a corpus that has carried hundreds of correction sites since
# 2026-07 is never legitimately empty: refuse to overwrite, and say why.
NROWS=$(awk 'NR>1' "$OUT.new" | grep -c .)
if [ "${NROWS:-0}" -lt 50 ]; then
  echo "CORRECTIONS_INVENTORY=ERROR population-collapsed rows=$NROWS (floor 50) — $OUT NOT overwritten"
  echo "  git grep / git log produced (almost) nothing; this is an unreadable corpus, not a clean one."
  rm -f "$OUT.new"; exit 2
fi
mv "$OUT.new" "$OUT"
awk -F'\t' 'NR>1 { c[$3]++; n++ } END {
  printf "wrote %d candidates\n", n
  for (k in c) printf "  %s %6d\n", k, c[k] | "sort" }' "$OUT"
echo "-> $OUT"
