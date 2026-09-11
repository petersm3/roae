#!/usr/bin/env bash
# tr12_n31_golden_gate.sh — decide, in milliseconds and before a multi-day n=31 battery, WHICH of
# five states the n=31 TR-12 golden set is in, and never confuse "a golden exists" with "a golden
# was checked".
#
# Verdict (one whole line, matched with `grep -qx`):
#
#   TR12_N31_GOLDEN=OK                  every tier below was MEASURED and HELD
#   TR12_N31_GOLDEN=MINTED-UNVERIFIED   the set is real (Tier 0) but does not carry what a tier
#                                       needs, so that tier was not taken -- present, not checked
#   TR12_N31_GOLDEN=MISMATCH            a tier WAS taken and the golden CONTRADICTED a pinned value
#   TR12_N31_GOLDEN=PLACEHOLDER         Tier 0: files exist but are stubs / the set is unhashed
#   TR12_N31_GOLDEN=ABSENT              Tier 0: there is no set
#   TR12_N31_GOLDEN=ERROR               a REFERENCE this gate measures against is missing, so the
#                                       measurement could not be taken at all
#
# Precedence when several apply: MISMATCH > ERROR > MINTED-UNVERIFIED > OK. Every finding is
# printed regardless of which one wins, so nothing is hidden behind the token.
#
# 🔴 WHY THE TOKEN GREW FOUR VALUES (2026-09-11). It had OK | ABSENT | PLACEHOLDER | ERROR, and OK
# meant EXACTLY "a directory of non-stub files with a manifest exists" -- the gate's own old header
# said so. The advisory leg in the pre-gate greps `-qx TR12_N31_GOLDEN=OK`, so a merely PRESENT
# golden and a CHECKED one were the same string. The three new values are the three states that
# string was hiding:
#   * MINTED-UNVERIFIED -- present, not checked. This is the state a fresh `--regen` mint lands in.
#   * MISMATCH          -- checked and WRONG. Folding this into MINTED-UNVERIFIED would repeat the
#                          very defect being fixed, one level down: "not checked" and "checked and
#                          failed" are not the same fact and must not print the same token.
#   * ERROR             -- the gate could not take the measurement. A tier whose reference file is
#                          missing must say so; a check that passes when its subject is absent is
#                          not a check.
#
# 🔴 WHAT NO GATE HERE CAN DO, unchanged and still true. A minted golden is OUR OWN OUTPUT; diffing
# a later run against it is a regression test, not a verification. The invariants the battery
# enforces upstream of minting (N mod 24 == 0, sum_b solutions(b) == N, f.g == N at every layer)
# CANNOT fail on a minted set, because a run violating them never reaches minting. What the tiers
# below add is the part that is NOT self-minted: identity with outputs taken at a DIFFERENT n
# (Tier 1), with a DIFFERENT run on a DIFFERENT build and host (Tier 2), and with values the
# labeling theorem FORCES independently of any run (Tier 3). The residual -- rows for which no
# invariant exists at all -- is Tier 4's job to DECLARE, not to check; the list is in
# roae-private/G31_N31_GOLDEN_SCOPE_2026_09_11.md section 3 and B32_N31_GOLDEN_DECISION_2026_09_07.md.
#
# ---------------------------------------------------------------------------------------------
# THE FOUR TIERS
#
# Tier 0  the set is real            dir exists, no placeholder/stub file, _MANIFEST.txt present
#                                    and naming every non-`_` file.   Fail -> ABSENT | PLACEHOLDER
# Tier 1  n-independence, by cross-n byte identity.  FREE: needs no n=31 run.  Ten rows whose
#         output was MEASURED identical at n=9 and n=13 on 2026-09-11 (method and shas below) must
#         be byte-identical between n31/<row>.txt and n9/<row>.txt.
# Tier 2  the pinned n=31 external anchors: constants that are public in this repo (N and its
#         consequences, the Q8 gallery chi2, log2 N), the 96 per-layer ladder digests in
#         runs/20260906_kc_ladders_n31/, and the banked full-31 answers supplied through a pins
#         file (see PINS below -- they are NOT inlined here, see "WHY A PINS FILE").
# Tier 3  the theorem-forced values, present IN THE GOLDEN rather than merely in a passing run,
#         plus reader-side re-derivation of the atlas tables in bc from the golden's own numbers.
# Tier 4  provenance and DECLARED blind spots: MINTING_PROVENANCE.txt and MINTED_UNANCHORED.txt.
#
# 🔴 WHAT IS DELIBERATELY NOT CHECKED, AND WHY -- so the next reader does not "restore" it:
#   * VERDICTS.txt (proposed G3.4: TR12_Q1C=EMPTY:... / TR12_Q10A_KWRANK=EMPTY:...). NOTHING PUTS
#     VERDICTS.txt IN THE GOLDEN DIRECTORY. scripts/tr12_repro.sh writes it to the run's artifact
#     root, and the golden holds only <row>.txt blocks. Requiring it here would be a gate with no
#     producer. If the minting procedure is ever changed to copy VERDICTS.txt into the set, wire
#     it -- as a Tier 3 check whose absence is MINTED-UNVERIFIED, never a silent pass.
#   * Cell ATTACHMENT across the ~31-chunk merge, King Wen's per-step f_i/g_i, the per-layer state
#     census content, Q2c/Q2d extremality. These have no invariant to check under ANY definition of
#     this token; they need instruments that do not exist (roae-private/N31_ATTESTATION_SCOPE.md
#     section 10). Tier 4 makes the golden DECLARE them instead of pretending to check them.
#
# 🔴 WHY A PINS FILE AND NOT INLINE CONSTANTS. Tier 2's strongest anchors -- rel_rank(KW), the
# three REL walks, the 1000-row REL grid, the Q8 subset count -- were produced by the 2026-08-05/07
# runs and live in roae-private. Inlining them here would PUBLISH them as a side effect of writing
# a gate, which is not this script's decision to make. So they are read from a pins file whose path
# is TR12_N31_PINS (default scripts/tr12_expected/n31_pins.txt); point it at a private path and the
# values never enter this repo. If the file or a required pin is missing the verdict is ERROR --
# the gate says which keys it needed and stops, rather than quietly grading itself out of them.
#
# EXIT STATUS:  0 OK · 1 MINTED-UNVERIFIED | MISMATCH | PLACEHOLDER | ABSENT · 2 ERROR
#
# 2026-09-11. Claude (Opus 5). Developed with AI assistance (Claude, Anthropic); direction, the
# query program and the row-by-row scope that this implements are the operator's. The tier
# definitions are from roae-private/G31_N31_GOLDEN_SCOPE_2026_09_11.md section 5. Errors are mine;
# corrections invited -- in particular the Tier 1 membership is a MEASUREMENT, and re-running the
# measurement is how you disagree with it.
# ---------------------------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.." || { echo "TR12_N31_GOLDEN=ERROR"; exit 2; }

DIR=${TR12_N31_DIR:-scripts/tr12_expected/n31}
N9DIR=${TR12_N9_DIR:-scripts/tr12_expected/n9}
LADDERDIR=${TR12_N31_LAYERSHA_DIR:-runs/20260906_kc_ladders_n31}
PINS=${TR12_N31_PINS:-scripts/tr12_expected/n31_pins.txt}

# ---------------------------------------------------------------------------- pinned constants --
# N is not a secret and is not new here: it is already carried by verify.c, verify.py, solve.py,
# documentation/VERIFY.md, documentation/QUERY_INVENTORY.md and reports/FULL31_EXACT_AGGREGATES.md.
N31=1097051278789181790036112071176579186688
N31_DIV24=45710469949549241251504669632357466112
C3MAX31=387
ANCHOR_VALUES31=62
# Q8 gallery, 2026-08-07 T4 run; already public in scripts/d5_02_q8_chi2_gallery_gate.sh:81 and
# documentation/QUERY_INVENTORY.md:806. Its one-time process caveat (MEMBER_FAILURES 1000 -> 0) was
# RESOLVED 2026-08-13 (roae-private/GATE_T_G1_MEMBER_FAILURES_RESOLVED_20260813.md), so this anchor
# is unconditioned.
Q8_CHI2=20.224
Q8_BUCKETS='71,55,64,59,75,58,53,74,51,49,64,60,58,81,60,68'

# ------------------------------------------------------------------------- Tier 1 pinned table --
# MEASURED 2026-09-11 on this tree's ./solve. Method, reproducible: extract each row's body
# VERBATIM from scripts/tr12_repro.sh, run it once against a freshly built n=9 f/g/t ladder set and
# once against an n=13 set, normalise both with a replica of the driver's own norm(), and compare.
# A row whose two outputs are identical is n-independent BY MEASUREMENT, not by assertion. All ten
# were identical, each also reproduced scripts/tr12_expected/n9/<row>.txt byte-for-byte, and a
# deliberate n-DEPENDENT control (--kc-count FDIR) differed -- so the measurement discriminates.
# The sha here is of the n=9 golden FILE; it is checked before use, so a drifted n=9 golden is an
# ERROR (re-measure and re-pin) rather than a silently weakened Tier 1.
# Full transcript: roae-private/G31_TOKEN_IMPLEMENTED_2026_09_11.md.
TIER1_ROWS='
a0_build        bfc2153cb595d9700c3614355ed1b4c37502cde0c0f1594cfc0157051edbbd1b
a0_gates        897a2d168f60890a29f0d4c242a06e96398bac7a3de82a1c7807617c30ccd496
a0_xa_iii       fe51a662df0691da3980c719ab9cac9aaa9626fb48497e241cc42bde671d57b6
a0_q7_kw        baecd37f936b5fdb891f1b90a595270e8fe49eb854241195dd5c172d52da0aaf
a0_q7_hist      6076b14937dba09eb07dcc75518a4724a335d457f28f6f90aa2e4d68f02ad213
a0_ls_w0        bf1593a820d9e2da157d3da538523dead0b177dce8d87231e6d09a0dc959b810
a0_ls_w0_mc     00dcd5eebc9237d6722d35f3f5e15e9fb3cedf8ce1d4ce4874ef8ee77859354e
a0_q4b          fd501f7b497b4582f427657281356d822dd9e6384c1260f71f3f05decaf66312
a1_q8_midn13    565d5c4ffc39bcba232135b29536da5f82f53db3b8dcf1041f7acd559ac22a49
b_scan_selftest 599dc2021b85f230602eabe7458349d1000818308fddc319022722f990eea0d2
'

# Required pins (Tier 2, banked full-31 answers). rule is `contains` (the literal must appear in
# that golden row) or `datasha` (sha256 of the row's tab-separated data lines).
REQUIRED_PINS='
a1_q1b          contains  rel_rank_kw
a1_q2b          contains  walk_r0
a1_q2b          contains  walk_half
a1_q2b          contains  walk_last
a1_v3           datasha   grid_rows
a1_q8_subset    contains  subset_cd_le_T
'

# ------------------------------------------------------------------------------- accumulators ---
nERR=0; nMISS=0; nBAD=0; nOK=0
err(){  nERR=$((nERR+1));  printf '  [ERROR] %s\n' "$*"; }
miss(){ nMISS=$((nMISS+1)); printf '  [UNVER] %s\n' "$*"; }
bad(){  nBAD=$((nBAD+1));  printf '  [WRONG] %s\n' "$*"; }
ok(){   nOK=$((nOK+1));   printf '  [ok   ] %s\n' "$*"; }

verdict(){ # verdict VALUE RC
  echo "TR12_N31_GOLDEN=$1"; exit "$2"
}

# gfile ROW -> sets GF to the golden path, or records MINTED-UNVERIFIED and returns 1.
# 🔴 NOT `f=$(gfile row)`. A command substitution is a SUBSHELL: the miss/err counters incremented
# inside one are discarded when it exits, so an absent golden would have been counted zero times and
# the gate could have printed OK over a set that was missing rows. Caller pattern: `if gfile x; then`.
GF=""
gfile(){
  local row="$1"
  GF="$DIR/$1.txt"
  [ -s "$GF" ] && return 0
  miss "$row: the golden set carries no non-empty $row.txt, so its tier check was NOT taken"
  return 1
}

# field FILE KEY -> first whitespace-separated value after KEY at line start (tab-separated rows)
field(){ awk -v k="$2" '$1==k {for(i=2;i<=NF;i++) if($i!=""){print $i; exit}}' "$1"; }
# kvfield FILE KEY -> value of a `key=value` line (a0_anchor.txt is written in that shape)
kvfield(){ sed -n "s/^$2=//p" "$1" | head -1; }

# want_field ROW FILE KEY EXPECTED LABEL
want_field(){
  local row="$1" f="$2" k="$3" want="$4" lbl="$5" got
  case "$row" in a0_anchor) got=$(kvfield "$f" "$k") ;; *) got=$(field "$f" "$k") ;; esac
  if [ -z "$got" ]; then bad "$row: $lbl -- the golden states no '$k' field at all (expected $want)"
  elif [ "$got" != "$want" ]; then bad "$row: $lbl -- $k = $got, pinned $want"
  else ok "$row: $lbl ($k = $want)"; fi
}

# want_grep ROW FILE REGEX LABEL
want_grep(){
  local row="$1" f="$2" re="$3" lbl="$4"
  if grep -qE "$re" "$f"; then ok "$row: $lbl"
  else bad "$row: $lbl -- no line matching /$re/ in the golden"; fi
}

# deny_grep ROW FILE REGEX LABEL   (a golden that RECORDS its own failure is not a golden)
deny_grep(){
  local row="$1" f="$2" re="$3" lbl="$4"
  if grep -qE "$re" "$f"; then bad "$row: $lbl -- the golden itself records /$re/"
  else ok "$row: $lbl"; fi
}

echo "== G-31 n=31 golden gate =="
echo "   set       $DIR"
echo "   n9 ref    $N9DIR"
echo "   ladder    $LADDERDIR"
echo "   pins      $PINS"

# =================================================================================== TIER 0 =====
if [ ! -d "$DIR" ]; then
  echo "  [BLOCK] no n=31 golden at $DIR"
  echo "          TR-12 section R step 6 says to diff every query against its [EXPECTED-*] block."
  echo "          Those blocks do not exist, so that step currently compares against NOTHING."
  echo "          The first full-31 battery must be run with --regen as an explicit MINTING run and"
  echo "          its output committed as the golden IN THE SAME COMMIT."
  verdict ABSENT 1
fi

files=$(find "$DIR" -type f ! -name '_*' 2>/dev/null | sort)
if [ -z "$files" ]; then
  echo "  [BLOCK] $DIR exists but holds no golden files"
  verdict ABSENT 1
fi

# A placeholder is anything a minting run would replace: an empty file, or one whose only content
# is a TODO/TBD/EXPECTED- marker. Matching on markers alone would miss an empty file, which is the
# commonest way a golden is "created" without being minted.
is_placeholder(){ # $1 = file
  [ -s "$1" ] || return 0
  grep -qiE '^\s*(TODO|TBD|PLACEHOLDER|\[EXPECTED-[A-Z0-9]+\]\s*$)' "$1" && return 0
  return 1
}

t0bad=0; n=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  n=$((n+1))
  if is_placeholder "$f"; then
    echo "  [FAIL] placeholder golden: $f"
    t0bad=$((t0bad+1))
  fi
done <<< "$files"

if [ ! -r "$DIR/_MANIFEST.txt" ]; then
  echo "  [FAIL] $DIR has no _MANIFEST.txt — an unhashed golden can be edited without trace"
  t0bad=$((t0bad+1))
else
  # G0.1 in full: the manifest must NAME every non-`_` file. A manifest that hashes nine of fifty
  # files is not a manifest, and presence alone never noticed.
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    grep -qF -- "$(basename "$f")" "$DIR/_MANIFEST.txt" || {
      echo "  [FAIL] $(basename "$f") is in the set but not named in _MANIFEST.txt"
      t0bad=$((t0bad+1)); }
  done <<< "$files"
fi

if [ "$t0bad" -gt 0 ]; then
  echo "  $t0bad of $n golden file(s) are placeholders, or the set is unhashed/incompletely hashed"
  verdict PLACEHOLDER 1
fi
ok "Tier 0: $n golden file(s) present, none a placeholder, all named in _MANIFEST.txt"

# ...and the manifest's digests must be RIGHT. "An unhashed golden can be edited without trace" was
# the reason to require the manifest; a manifest nobody verifies has exactly the same property, and
# the old gate checked only that the file EXISTED. A digest that disagrees is an edit after minting,
# i.e. checked-and-wrong (MISMATCH), not a missing artifact.
nh=0; nhbad=0
while read -r h nm; do
  [ -n "${h:-}" ] || continue
  nh=$((nh+1))
  mf="$DIR/$nm"
  if [ ! -f "$mf" ]; then bad "Tier 0: _MANIFEST.txt hashes $nm, which is not in the set"; nhbad=$((nhbad+1)); continue; fi
  got=$(sha256sum < "$mf" | cut -d' ' -f1)
  [ "$got" = "$h" ] || { bad "Tier 0: $nm has been edited since minting (sha $got, manifest $h)"; nhbad=$((nhbad+1)); }
done <<< "$(grep -E '^[[:space:]]*[0-9a-f]{64}[[:space:]]+[^[:space:]]+[[:space:]]*$' "$DIR/_MANIFEST.txt" | awk '{print $1, $2}')"
if [ "$nh" -eq 0 ]; then
  err "Tier 0: _MANIFEST.txt carries no parseable '<sha256>  <name>' rows -- the set's self-hash"
  err "        could not be verified at all, so 'unhashed golden' is exactly the state we are in."
elif [ "$nhbad" -eq 0 ]; then
  ok "Tier 0: all $nh manifest digests reproduce"
fi

# =================================================================================== TIER 1 =====
echo "-- Tier 1: n-independence by cross-n byte identity (measured 2026-09-11; no n=31 run needed)"
if [ ! -d "$N9DIR" ]; then
  err "Tier 1 has no reference: $N9DIR does not exist, so cross-n identity CANNOT be measured"
else
  while read -r row sha; do
    [ -n "${row:-}" ] || continue
    ref="$N9DIR/$row.txt"
    if [ ! -f "$ref" ]; then
      err "Tier 1 $row: reference $ref is missing -- cross-n identity not measurable"
      continue
    fi
    got=$(sha256sum < "$ref" | cut -d' ' -f1)
    if [ "$got" != "$sha" ]; then
      err "Tier 1 $row: the n=9 reference has CHANGED (sha $got, pinned $sha). The n-independence" \
          "measurement that put $row in this tier no longer describes this tree -- re-measure and re-pin."
      continue
    fi
    g="$DIR/$row.txt"
    if [ ! -f "$g" ]; then
      miss "Tier 1 $row: absent from the n=31 set, so cross-n identity was NOT taken"
    elif cmp -s "$ref" "$g"; then
      ok "Tier 1 $row: n31 == n9, byte-identical"
    else
      bad "Tier 1 $row: n31 differs from n9 on a row MEASURED n-independent -- one of them is wrong"
    fi
  done <<< "$(printf '%s\n' "$TIER1_ROWS" | sed '/^[[:space:]]*$/d')"
fi

# =================================================================================== TIER 2 =====
echo "-- Tier 2: pinned n=31 anchors (public constants, the 96 ladder digests, banked answers)"

# G2.1 -- a0_anchor
if gfile a0_anchor; then f=$GF
  want_field a0_anchor "$f" N_total          "$N31"             "N is the pinned full-31 count"
  want_field a0_anchor "$f" N_mod_24         0                  "N mod 24 == 0"
  want_field a0_anchor "$f" N_div_24         "$N31_DIV24"       "N/24 identity"
  want_field a0_anchor "$f" anchor_values    "$ANCHOR_VALUES31" "the anchor is a 62-value walk"
  want_field a0_anchor "$f" c3_max_used      "$C3MAX31"         "the C3 gate actually used"
  want_field a0_anchor "$f" anchor_is_member MEMBER             "the anchor is IN the universe"
  want_field a0_anchor "$f" universe_n       31                 "the set really is the n=31 universe"
fi

# G2.2 -- the 96 per-layer decompressed-stream digests. This is the anchor that makes the REST of
# Tier 2 sound: it proves the ladder mounted at query time is the ladder the banked runs read.
for st in F:a1_fsha G:a2_gsha T:b_tsha; do
  stage=${st%%:*}; row=${st##*:}
  reg="$LADDERDIR/STAGE_${stage}_LAYERSHA.txt"
  if [ ! -r "$reg" ]; then
    err "Tier 2 $row: registry $reg is missing -- the 32 stage-$stage digests cannot be checked"
    continue
  fi
  gfile "$row" || continue; f=$GF
  nreg=0; nhit=0; nmiss=0
  while read -r rsha rname; do
    [ -n "${rsha:-}" ] || continue
    case "$rsha" in \#*|'') continue ;; esac
    case "$rsha" in *[!0-9a-f]*) continue ;; esac
    [ ${#rsha} -eq 64 ] || continue
    nreg=$((nreg+1))
    base=$(basename "${rname:-}")
    # both on the SAME line: a golden listing 32 digests and 32 basenames in unrelated places
    # would otherwise satisfy a pair of independent greps while binding neither to the other.
    if grep -F -- "$rsha" "$f" | grep -qF -- "$base"; then nhit=$((nhit+1)); else nmiss=$((nmiss+1)); fi
  done <<< "$(grep -vE '^[[:space:]]*#' "$reg" | awk 'NF>=2{print $1, $2}')"
  if [ "$nreg" -eq 0 ]; then
    err "Tier 2 $row: $reg parsed to ZERO digest rows -- the registry format changed under this gate"
  elif [ "$nmiss" -gt 0 ]; then
    bad "Tier 2 $row: $nmiss of $nreg stage-$stage layer digests are NOT in the golden row"
  else
    ok "Tier 2 $row: all $nreg stage-$stage layer digests match $reg"
  fi
done

# G2.8 -- log2 N, recomputed here from the pinned N rather than read from the row
if gfile a2_ew1; then f=$GF
  want=$(echo "scale=10; l($N31)/l(2)" | bc -l 2>/dev/null)
  got=$(field "$f" log2N)
  if [ -z "$want" ]; then
    err "Tier 2 a2_ew1: bc could not compute log2(N) -- the check could not be taken"
  elif [ -z "$got" ]; then
    bad "Tier 2 a2_ew1: the golden states no log2N field"
  elif [ "$(echo "d=$got-($want); if(d<0) d=-d; if(d<=0.0001) 1 else 0" | bc -l)" = 1 ]; then
    ok "Tier 2 a2_ew1: log2N = $got agrees with log2($N31) to 1e-4"
  else
    bad "Tier 2 a2_ew1: log2N = $got, but log2(N) = $want"
  fi
  want_grep a2_ew1 "$f" '^EW1_SUM_EQ_LOG2N[[:space:]]+OK$' "the row's own sum==log2N gate reads OK"
fi

# G2.6 -- the Q8 gallery chi2 and its 16 bucket counts
if gfile a1_q8_chi2; then f=$GF
  want_field a1_q8_chi2 "$f" chi2 "$Q8_CHI2" "the 2026-08-07 T4 gallery chi2"
  bk=$(awk '$1 ~ /^[0-9]+$/ && NF==2 {printf "%s%s", (c++?",":""), $2} END{print ""}' "$f")
  if [ "$bk" = "$Q8_BUCKETS" ]; then ok "a1_q8_chi2: the 16 bucket counts are the banked vector"
  else bad "a1_q8_chi2: bucket counts [$bk] != banked [$Q8_BUCKETS]"; fi
  want_grep a1_q8_chi2 "$f" '^Q8_CHI2_GALLERY[[:space:]]+PASS$' "the row's own chi2 gate reads PASS"
fi

# G2.3/G2.4/G2.5/G2.7 -- the banked full-31 answers, through the pins file
if [ ! -r "$PINS" ]; then
  err "Tier 2: no pins file at $PINS. The banked 2026-08-05/07 full-31 answers are the only"
  err "        DIFFERENT-build, DIFFERENT-host, DIFFERENT-date check this gate can make, and they"
  err "        are not inlined here on purpose (they would be published by doing so). Required keys:"
  printf '%s\n' "$REQUIRED_PINS" | sed '/^[[:space:]]*$/d' | awk '{printf "          %-14s %-9s %s\n",$1,$2,$3}'
  err "        Format: <row> <TAB> contains|datasha <TAB> <pin-id> <TAB> <value>   (# comments ok)"
  err "        Set TR12_N31_PINS to a private path to keep the values out of this repo."
else
  while read -r prow prule pid; do
    [ -n "${prow:-}" ] || continue
    pval=$(awk -v r="$prow" -v u="$prule" -v i="$pid" '
        !/^[[:space:]]*#/ && $1==r && $2==u && $3==i {v=$4; for(j=5;j<=NF;j++) v=v" "$j; print v; exit}' "$PINS")
    if [ -z "$pval" ]; then
      err "Tier 2 pin $prow/$pid: not present in $PINS -- the banked answer was not supplied"
      continue
    fi
    gfile "$prow" || continue; f=$GF
    case "$prule" in
      contains)
        if grep -qF -- "$pval" "$f"; then ok "Tier 2 pin $prow/$pid: the banked value is in the golden"
        else bad "Tier 2 pin $prow/$pid: the banked value is NOT in $prow.txt"; fi ;;
      datasha)
        dsha=$(awk -F'\t' 'NF>=3 && $1 ~ /^[0-9]+$/' "$f" | sha256sum | cut -d' ' -f1)
        nd=$(awk -F'\t' 'NF>=3 && $1 ~ /^[0-9]+$/' "$f" | wc -l)
        if [ "${nd:-0}" -eq 0 ]; then
          err "Tier 2 pin $prow/$pid: $prow.txt holds ZERO tab-separated data rows -- nothing to hash"
        elif [ "$dsha" = "$pval" ]; then ok "Tier 2 pin $prow/$pid: data-line sha matches the banked run"
        else bad "Tier 2 pin $prow/$pid: data-line sha $dsha != banked $pval"; fi ;;
      *) err "Tier 2 pin $prow/$pid: unknown rule '$prule' -- this gate cannot evaluate it" ;;
    esac
  done <<< "$(printf '%s\n' "$REQUIRED_PINS" | sed '/^[[:space:]]*$/d')"
fi

# =================================================================================== TIER 3 =====
echo "-- Tier 3: the theorem-forced values, present IN THE GOLDEN (not merely in a passing run)"

# G3.1 -- the labeling theorem forces (0,0,0) at n>=31
if gfile a2_q1_labeling; then f=$GF
  want_field a2_q1_labeling "$f" n                 31 "the row ran at n=31"
  want_field a2_q1_labeling "$f" rank3             0  "rank3 forced to 0 by the labeling theorem"
  want_field a2_q1_labeling "$f" class_first_rank3 0  "class_first_rank3 forced to 0"
  want_field a2_q1_labeling "$f" orient_idx        0  "orient_idx forced to 0"
  want_grep  a2_q1_labeling "$f" '^Q1_LABELING[[:space:]]+OK$' "the row's own labeling gate reads OK"
fi

# G3.2 -- the one external anchor of the O3 machinery
if gfile a2_q2; then f=$GF
  want_grep a2_q2 "$f" '^Q2_R0_IS_ANCHOR[[:space:]]+YES' "unrank_O3(0) is byte-identical to the anchor"
fi

# G3.3 -- the n=31-ONLY row. No n=9 golden can ever cover it; its first execution IS the full-31
#         run, and it publishes King Wen's serial number.
if gfile a2_q7_ranks; then f=$GF
  want_grep  a2_q7_ranks "$f" 'label=KW[[:space:]]+verdict_super=IN' "King Wen is IN and was ranked"
  want_grep  a2_q7_ranks "$f" '(^|[^0-9a-z_])rank3=0([^0-9]|$)'      "rank_O3(KW) = 0, the labeling theorem"
  deny_grep  a2_q7_ranks "$f" '^Q7RANKS_FAIL'                        "no Q7RANKS_FAIL in the golden"
fi

# G3.5 -- the Q3 reader, the model the other reader-side checks follow
if gfile a2_q3_reader; then f=$GF
  want_field a2_q3_reader "$f" reader_steps  31 "the reader walked all 31 steps"
  want_field a2_q3_reader "$f" READER_FAILS  0  "the reader found no broken link"
  want_grep  a2_q3_reader "$f" '^reader_telescoping[[:space:]]+OK \(30 links\)' "30 telescoping links"
  want_grep  a2_q3_reader "$f" '^reader_p_num_n_eq_1[[:space:]]+OK'             "p_num[n] == 1"
  want_grep  a2_q3_reader "$f" "^reader_p_den_1_eq_N[[:space:]]+OK \\($N31\\)"  "p_den[1] == N"
fi

# G3.6 -- XA-a / XA-b
if gfile c_xa_ab; then f=$GF
  want_field c_xa_ab "$f" sum_solutions       "$N31" "sum_b solutions(b) == N"
  want_field c_xa_ab "$f" N_total             "$N31" "the row's own N agrees with the pinned N"
  want_field c_xa_ab "$f" shared_trunk_t_units 1     "t(root) - sum_b prefixes(b) == 1"
  want_grep  c_xa_ab "$f" '^XA_A_GATE.*OK'  "XA-a gate OK"
  want_grep  c_xa_ab "$f" '^XA_B_GATE.*OK'  "XA-b gate OK"
fi

# G3.7 -- the atlas header
if gfile c_atlas; then f=$GF
  want_field c_atlas "$f" atlas_N_total                     "$N31" "the atlas N"
  want_field c_atlas "$f" ladder_N_total                    "$N31" "the ladder N"
  want_field c_atlas "$f" layers                            31     "31 layers"
  want_field c_atlas "$f" gate_per_layer_flow_eq_N          true   "per-layer flow == N"
  want_field c_atlas "$f" gate_raw_marginal_sums_eq_N       true   "raw marginals sum to N"
  want_field c_atlas "$f" gate_branch_masses_sum_eq_N       true   "branch masses sum to N"
  want_field c_atlas "$f" gate_fails                        0      "producer gate_fails 0"
  want_field c_atlas "$f" branches_with_t_source_not_t_ladder 0    "every branch is t-ladder sourced"
fi

# G3.9 -- Q10(a)
if gfile c_q10a; then f=$GF
  want_field c_q10a "$f" N_div_24                 "$N31_DIV24" "the N/24 cell"
  want_field c_q10a "$f" Q10A_LAYER_MOD24_FAILS   0            "every layer flow is 0 mod 24"
  last=$(awk '$1 ~ /^[0-9]+$/ && NF>=4 && $4 ~ /^[0-9]+$/ {v=$4} END{print v}' "$f")
  if [ "$last" = "$N31" ]; then ok "c_q10a: the last census layer's mass_total == N"
  else bad "c_q10a: the last census layer's mass_total is '${last:-none}', not N"; fi
fi

# G3.8 -- reader-side re-derivation IN BC, from the golden's own printed tables. This is what turns
#         c_v2 / c_v5 from "no assertion of any kind" into checked rows: the row sums are recomputed
#         here, from the published cells, instead of being inherited from the producer's boolean.
if gfile c_v1; then f=$GF
  # 🔴 IN BC, NOT AWK. N is ~1.1e39; awk would hold it as a double and a discrepancy of 10^22 would
  # compare EQUAL. The row this check models (c_v1 in tr12_repro.sh) sums in bc for the same reason.
  exprs=$(awk '$1 ~ /^[0-9]+$/ && NF==3 {s[$1]=(s[$1]==""? $3 : s[$1]"+"$3)} END{for(i in s) print s[i]}' "$f")
  nk=$(printf '%s\n' "$exprs" | grep -c .)
  nbadsum=$(printf '%s\n' "$exprs" | bc 2>/dev/null | grep -vcx -- "$N31")
  if [ "${nk:-0}" -eq 31 ] && [ "${nbadsum:-1}" -eq 0 ]; then
    ok "c_v1: all 31 layers' raw marginals sum to N (re-derived here, in bc, from the printed cells)"
  else
    bad "c_v1: re-derived ${nk:-0} layers, ${nbadsum:-?} of which do NOT sum to N (want 31 layers, 0 bad)"
  fi
fi
if gfile c_v2; then f=$GF
  exprs=$(awk '$1 ~ /^[0-9]+$/ && NF==6 {print $2"+"$3"+"$4"+"$5"+"$6}' "$f")
  nk=$(printf '%s\n' "$exprs" | grep -c .)
  nbadsum=$(printf '%s\n' "$exprs" | bc 2>/dev/null | grep -vcx -- "$N31")
  if [ "${nk:-0}" -eq 31 ] && [ "${nbadsum:-1}" -eq 0 ]; then
    ok "c_v2: all 31 layers' five class masses sum to N (re-derived here, in bc) -- the row itself asserts nothing"
  else
    bad "c_v2: re-derived ${nk:-0} layers, ${nbadsum:-?} of which do NOT sum to N (want 31 layers, 0 bad)"
  fi
fi
if gfile c_v5; then f=$GF
  # the p column is O(1), so the probability sum is the one place a double is the right instrument
  r=$(awk '$1 ~ /^[0-9]+$/ && NF==4 {p[$1]+=$4; c[$1]++}
        END{nk=0; b=0; for(i in p){nk++; d=p[i]-1; if(d<0)d=-d; if(d>0.000001 || c[i]!=5) b++} print nk, b}' "$f")
  set -- $r
  if [ "${1:-0}" -eq 31 ] && [ "${2:-1}" -eq 0 ]; then
    ok "c_v5: every one of 31 layers has 5 classes whose p sum to 1 (re-derived here)"
  else
    bad "c_v5: re-derived ${1:-0} layers, ${2:-?} of which do NOT have 5 classes summing to 1"
  fi
  # and the cross-row tie: c_v5's mass column must equal c_v2's cell for the same (k, class).
  # Compared as STRINGS -- these are 39-digit integers and awk's numeric compare would not see a
  # difference below its 53 bits of mantissa.
  if [ -s "$DIR/c_v2.txt" ]; then
    d=$(awk 'FNR==NR{ if($1 ~ /^[0-9]+$/ && NF==6){cl[1]="d1";cl[2]="d2";cl[3]="d3";cl[4]="d4";cl[5]="d6";
                       for(i=1;i<=5;i++) m[$1"/"cl[i]]=$(i+1)""} ; next}
              $1 ~ /^[0-9]+$/ && NF==4 { key=$1"/"$2; if(!(key in m) || m[key]"" != $3"") b++ }
              END{print b+0}' "$DIR/c_v2.txt" "$f")
    if [ "${d:-1}" -eq 0 ]; then ok "c_v5 x c_v2: every (k,class) mass agrees across the two published tables"
    else bad "c_v5 x c_v2: $d (k,class) mass cells disagree between the two published tables"; fi
  fi
fi

# =================================================================================== TIER 4 =====
echo "-- Tier 4: provenance, and the golden's DECLARED blind spots"
prov="$DIR/MINTING_PROVENANCE.txt"
if [ ! -s "$prov" ]; then
  miss "Tier 4: no MINTING_PROVENANCE.txt -- the set does not say which commit, binary or ladder minted it"
else
  for k in minting_commit source_sha atlas_sha256 operator_signoff; do
    if grep -qE "^$k[[:space:]]" "$prov"; then ok "Tier 4 provenance: $k present"
    else bad "Tier 4 provenance: MINTING_PROVENANCE.txt has no $k line"; fi
  done
  for s in STAGE_F_LAYERSHA.txt STAGE_G_LAYERSHA.txt STAGE_T_LAYERSHA.txt; do
    grep -qF -- "$s" "$prov" || bad "Tier 4 provenance: MINTING_PROVENANCE.txt does not name $s"
  done
fi

unanch="$DIR/MINTED_UNANCHORED.txt"
# The rows of G31 section 3 -- the ones for which NO invariant exists. The golden must state its own
# blind spots in machine-readable form, so a later reader cannot mistake a minted PASS for a
# verified one. This list is a CONTRACT: if the set declares fewer rows than are really unanchored,
# it is overclaiming.
UNANCHORED_ROWS='c_v2 c_v5 c_q6 c_q10a a2_q3_profile a2_q3 a2_v4 a1_q2c a1_q2d a1_q4ac c_atlas'
if [ ! -s "$unanch" ]; then
  miss "Tier 4: no MINTED_UNANCHORED.txt -- the set does not declare the rows nothing can check"
else
  nmiss2=0
  for r in $UNANCHORED_ROWS; do
    grep -qE "(^|[^a-z0-9_])$r([^a-z0-9_]|$)" "$unanch" || { bad "Tier 4: MINTED_UNANCHORED.txt does not list $r"; nmiss2=$((nmiss2+1)); }
  done
  [ "$nmiss2" -eq 0 ] && ok "Tier 4: the set declares all $(set -- $UNANCHORED_ROWS; echo $#) unanchored rows"
fi

# =================================================================================== VERDICT ====
echo "-- summary: $nOK check(s) held, $nBAD contradicted, $nMISS not taken (golden side), $nERR not measurable"
if [ "$nBAD" -gt 0 ]; then
  echo "  [BLOCK] the golden CONTRADICTS a pinned value. This is not an unverified golden; it is a"
  echo "          wrong one, or the pins are stale. Do not certify against it either way."
  verdict MISMATCH 1
fi
if [ "$nERR" -gt 0 ]; then
  echo "  [BLOCK] a reference this gate measures against is missing, so the measurement was not"
  echo "          taken. A check that passes when its subject is absent is not a check."
  verdict ERROR 2
fi
if [ "$nMISS" -gt 0 ]; then
  echo "  [note] the set is real and nothing in it contradicts a pinned value, but it does not carry"
  echo "         everything the tiers verify, so it is PRESENT rather than CHECKED. This is the"
  echo "         state a fresh --regen mint lands in, and the state the old OK token hid."
  verdict MINTED-UNVERIFIED 1
fi
echo "  [ok]   Tiers 0-4 all measured and held."
echo "  [note] this still does NOT attest the rows of MINTED_UNANCHORED.txt: no invariant exists"
echo "         for them at n=31. See that file and roae-private/B32_N31_GOLDEN_DECISION_2026_09_07.md."
verdict OK 0
