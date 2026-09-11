#!/usr/bin/env bash
#
# tr12_repro_gate.sh — does the COMMITTED tree still reproduce its own published battery?
#
# WHY THIS EXISTS. On 2026-08-24 a clean checkout was found to be failing its own flagship
# reproduction battery — TR12_REPRO=FAIL, 13 of 56 rows — and had been for two days. Nothing
# noticed, because nothing ever RAN it. The repo's own checks verify that working trees are
# COMMITTED; none verified that the committed tree REPRODUCES. An engine commit can therefore
# silently invalidate the published reproduction path while every instrument reports green.
#
# The specific failure was instructive and is the reason this gate builds the way it does: the
# provenance trailer had just been correctly changed to report the branch actually built, but the
# build line PUBLISHED in documentation/VERIFY.md defines no branch, so a reproducer's binary
# emitted `branch=unknown` against expected blocks that diffed the field verbatim. The defect was
# only visible to someone building the way a STRANGER builds.
#
# So this gate does not use its own build line. It EXTRACTS the one published in
# documentation/VERIFY.md and runs that, verbatim. If the doc's line rots — a missing -lm, a
# renamed flag — this gate fails on it, which is the GAP-1 class the execution lane was built for.
# A curated copy of the build line here would rebuild exactly the blind spot being closed.
#
# Verdict token:  TR12_REPRO_GATE=PASS|FAIL   (grep -qx it; never gate on output shape)
# --check token:  TR12_REPRO_GATE_CURRENT=YES|NO|UNKNOWN  (grep -qx it too, since 2026-09-08:
#                 NO and UNKNOWN used to carry their explanation on the verdict line, so only the
#                 YES form was ever whole-line matchable. The explanation now prints above it.)
#
# Usage:
#   scripts/tr12_repro_gate.sh            # build + run the n=9 battery, print the verdict
#   scripts/tr12_repro_gate.sh --stamp    # ...and on PASS, record the input fingerprint
#   scripts/tr12_repro_gate.sh --check    # fingerprint only: has anything changed since that PASS?
#
# --check is the cheap leg (milliseconds, no build) that other checks call on every run. The full
# gate is ~2 minutes on two cores and needs no ladder data, no disk and no network.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
STAMP=scripts/tr12_expected/_GATE_STAMP.txt
MODE=${1:-run}

# The fingerprint covers everything that can invalidate a PASS: the engine (solve.c), the two
# Python files the battery CALLS as second implementations (verify.py, solve.py), the driver, the
# expected blocks, and THIS GATE ITSELF. Including the gate is deliberate -- a weakened gate still
# reporting its old PASS is the silent failure this whole exercise is about.
#
# verify.py and solve.py were MISSING from this list until 2026-08-24, found the same day by
# landing the Q6 reading-(B) oracle INTO verify.py: the battery began depending on a file whose
# change the gate could not see. A fingerprint is only as good as its enumeration of inputs, and
# the way that goes wrong is a new input, not a changed one. The stamp is excluded or it could
# never be stable.
# 🔴 Q-94, 2026-09-07: the set is DERIVED, not curated. The comment above already knew the failure
# mode -- "the way that goes wrong is a NEW input, not a changed one" -- and then went on enumerating
# by hand, which is the same bet that lost in August. Now the gate reads tr12_repro.sh for the repo
# files it actually references and FAILS if any of them is outside the hashed set. A curated list
# cannot notice its own omission; a derived one can.
# 🔴 DERIVED TO A FIXED POINT, FROM BOTH ENTRY POINTS (RCQ01 F6, 2026-09-09).
# This used to grep scripts/tr12_repro.sh alone. But THIS gate invokes gates of its own --
# q326_kc_query_surface_gate.sh, q433_xa_cert_gate.sh, kc_writer_devfull_gate.sh -- and executes the
# build command published in documentation/VERIFY.md. None of those were in the fingerprint, so
# after a successful --stamp, changing an omitted gate until it FAILED still left --check reporting
# CURRENT=YES. The currency stamp certified a state that no longer produced the result it certified.
# Fixed point rather than one extra level: a gate that invokes a gate is not a special case, and
# pinning the depth would just move the blind spot down one.
derived_inputs(){   # repo-relative files the battery and this gate reference, transitively
  local seeds="scripts/tr12_repro.sh scripts/tr12_repro_gate.sh" acc="" prev="" i=0
  acc=$(printf '%s\n' $seeds)
  while [ "$acc" != "$prev" ] && [ "$i" -lt 8 ]; do
    prev=$acc; i=$((i+1))
    acc=$( { printf '%s\n' "$acc"
             printf '%s\n' "$acc" | while read -r src; do
               case "$src" in *.sh) [ -f "$src" ] && grep -ohE '(scripts/|lean/|viz/|documentation/)?[A-Za-z0-9_./-]+\.(c|py|sh|md)\b' "$src" 2>/dev/null;; esac
             done
           } | sed 's|^\./||' | sort -u | while read -r f; do
               # 🔴 RESOLVE A BARE NAME AGAINST scripts/ BEFORE DISCARDING IT. tr12_repro.sh sources
               # `. "$SCRIPT_DIR/lib_binary_currency.sh"`; the grep recovers the basename, but a
               # bare `lib_binary_currency.sh` does not exist at the repo root, so the existence
               # filter dropped it and the fingerprint was blind to a file the battery EXECUTES.
               # Found by the F-5 re-review 2026-09-09, which measured the fingerprint byte-identical
               # when that file was mutated -- the exact failure F6 was supposed to have closed.
               [ -f "$f" ] && printf '%s\n' "$f"
             done )
  done
  printf '%s\n' "$acc" | sort -u | grep -v '^$'
}
# VERIFY.md is CORE because this gate EXECUTES the build command published in it: if that command
# changes, this gate builds something else, and the stamp must not survive that.
# 🔴 lib_binary_currency.sh is CORE because the battery SOURCES it:
# `. "$SCRIPT_DIR/lib_binary_currency.sh"` (tr12_repro.sh:183). The derivation recovers only
# "/lib_binary_currency.sh" from that -- a path that exists nowhere as written -- so the existence
# filter dropped it and the fingerprint was blind to a file the battery EXECUTES. Measured by the
# F-5 re-review 2026-09-09: mutate it and the fingerprint is byte-identical.
# Named here rather than resolved generically ON PURPOSE. Resolving bare .sh names against scripts/
# inside the fixed point cascaded 28 -> 108 files, sweeping in 37 documentation/*.md, which would
# invalidate the stamp on any doc edit -- a currency check nobody can keep green is one people learn
# to bypass. The general case (the NEXT library sourced through a variable) is a real gap and is
# queued, not silently closed by over-widening this.
# reports/certificates/c3_positional_witnesses.txt is CORE for the same reason the sourced library
# is: row a0_q4b READS it and GRADES ON ITS CONTENT (tr12_repro.sh:704), and the derivation cannot
# see it -- the regex covers .c/.py/.sh/.md, and widening it to .txt was MEASURED to sweep in
# _GATE_STAMP.txt itself plus two enumeration artefacts. Naming the one file that matters is the
# narrow fix; widening the grammar was the broad one that makes the stamp churn.
CORE="solve.c verify.py solve.py documentation/VERIFY.md scripts/lib_binary_currency.sh reports/certificates/c3_positional_witnesses.txt scripts/tr12_repro.sh scripts/tr12_repro_gate.sh scripts/q7ranks_parse_gate.sh scripts/q2_witness_gate.sh"
fingerprint_files(){ { printf '%s\n' $CORE; derived_inputs; } | sort -u; }

# 🔴 MY FIRST VERSION OF THIS CHECK WAS TAUTOLOGICAL. It asserted that every derived input was in
# a set BUILT FROM the derived inputs -- true by construction, and therefore worthless: the exact
# defect class this gate exists to catch, reintroduced while fixing it. Deriving the set makes
# coverage automatic; what can still go wrong is the DERIVATION ITSELF returning nothing (a changed
# grep, a moved battery), which would silently fall back to hashing CORE alone and read green.
# So the check is on the derivation, and it fails when the derivation stops working.
# 🔴 F-5 ROUND 5 condition 1b (2026-09-11). B1(r5) was an n>=31-ONLY row whose PARSE of engine
# output no n<=13 execution ever exercised, so nothing in this gate, the battery or the rehearsal
# could see it. row_assertion_gate.sh proves a row ASSERTS; it cannot prove the assertion's parse
# MATCHES ITS PRODUCER. This runs that check against a freshly built binary and real ladders.
q7ranks_parse_leg(){
  # Paths are relative to the repo root, matching this file's own idiom (:306, :318).
  # The first draft used "$ROOT", which is pre_push_gate.sh's variable and is unset here --
  # under `set -u` that aborted the gate AFTER the battery passed and BEFORE the stamp was
  # written. Loud and in the right direction (no stamp on an unmeasured tree), but a defect.
  # 🔴 F-5 ROUND 6, sibling finding: this returned 0 when the gate script was ABSENT, so
  # `rm scripts/q7ranks_parse_gate.sh` made the whole reproduction gate PASS -- deleting the
  # check made everything green. A missing subject is ERROR, never agreement; the leg's own
  # ERROR branch four lines below already said so and this line contradicted it.
  [ -x ./scripts/q7ranks_parse_gate.sh ] || {
      echo "  [ERROR] scripts/q7ranks_parse_gate.sh is absent or not executable -- the n>=31-only"
      echo "          parse class is UNMEASURED. That is not the same as passing."
      return 2; }
  local out; out=$(bash ./scripts/q7ranks_parse_gate.sh 2>&1)
  printf '%s\n' "$out" | sed 's/^/  /'
  if printf '%s\n' "$out" | grep -qx 'Q7RANKS_PARSE=PASS'; then return 0; fi
  if printf '%s\n' "$out" | grep -qx 'Q7RANKS_PARSE=ERROR'; then
    echo "  [ERROR] Q7RANKS_PARSE could not be measured -- NOT the same as PASS"; return 2; fi
  echo "  [FAIL] Q7RANKS_PARSE=FAIL -- an n>=31-only row's parse does not match its producer"; return 1
}

# R5 item 4 / Q-487: rows a1_q2c and a1_q2d took the solver's EXIT STATUS as their only failure
# flag, and an enumeration that finds NOTHING exits 0 -- measured, not argued. At n=31 those goldens
# are minted from whatever the run emits, so an empty FIRST^C15 would have published as PASS and the
# battery ships frozen by `git archive`. The gate EXTRACTS the witness helper and both rows from the
# battery and EXECUTES them. Absence is ERROR, never agreement -- the F-5 round 6 lesson, where
# deleting the check made the whole reproduction gate green.
q2_witness_leg(){
  [ -x ./scripts/q2_witness_gate.sh ] || {
      echo "  [ERROR] scripts/q2_witness_gate.sh is absent or not executable -- the FIRST^C15 /"
      echo "          LAST^C15 witness requirement is UNMEASURED. That is not the same as passing."
      return 2; }
  local out; out=$(bash ./scripts/q2_witness_gate.sh 2>&1)
  printf '%s\n' "$out" | sed 's/^/  /'
  if printf '%s\n' "$out" | grep -qx 'Q2_WITNESS=PASS'; then return 0; fi
  if printf '%s\n' "$out" | grep -qx 'Q2_WITNESS=ERROR'; then
    echo "  [ERROR] Q2_WITNESS could not be measured -- NOT the same as PASS"; return 2; fi
  echo "  [FAIL] Q2_WITNESS=FAIL -- an extremal row can publish an enumeration that found nothing"; return 1
}

fingerprint_coverage_check(){
  # 🔴 CAPTURE ONCE. This called derived_inputs FOUR times and piped each into `grep -q`, which
  # closes the pipe on first match and SIGPIPEs the producer mid-loop. The result was an
  # INTERMITTENT failure -- "no longer sees: solve.py" on one run, "sat.py" on the next, both while
  # the derivation was demonstrably fine when run alone. A flaky gate is worse than no gate: it
  # teaches people to re-run until green, which is how a real failure gets waved through.
  local n known_missing="" _derived
  _derived=$(derived_inputs)
  n=$(printf '%s\n' "$_derived" | grep -c .)
  if [ "$n" -lt 5 ]; then
    echo "  [FAIL] the input derivation returned $n file(s); it found 9 on 2026-09-07."
    echo "         A derivation that stops working degrades SILENTLY to hashing the curated core,"
    echo "         which is the hand-maintained list this replaced. Fix the derivation, do not pin it."
    return 1
  fi
  # the battery demonstrably calls these; if the derivation cannot see them it is broken
  # The must-see list is the point of this check: a derivation that silently narrows still returns
  # plenty of files. The three gates THIS file invokes are named here for the same reason the
  # battery's own dependencies are -- if the fingerprint stops seeing them, --check goes back to
  # certifying a tree whose gates it no longer tracks.
  for f in solve.py verify.py sat.py documentation/VERIFY.md \
           scripts/q326_kc_query_surface_gate.sh scripts/q433_xa_cert_gate.sh \
           scripts/kc_writer_devfull_gate.sh scripts/a5_orbit_membership_gate.sh; do
    printf '%s\n' "$_derived" | grep -qx "$f" || known_missing="$known_missing $f"
  done
  if [ -n "$known_missing" ]; then
    echo "  [FAIL] the derivation no longer sees:$known_missing — the battery calls these"
    return 1
  fi
  return 0
}

fingerprint(){
  { fingerprint_files | xargs sha256sum 2>/dev/null
    find scripts/tr12_expected -type f ! -name '_GATE_STAMP.txt' -print0 2>/dev/null \
      | sort -z | xargs -0 sha256sum 2>/dev/null
  } | sha256sum | cut -d' ' -f1
}

# ---- THE GOLDEN MANIFEST MUST DESCRIBE THE GOLDENS ---------------------------------------------
# 🔴 UNTIL 2026-09-06 _MANIFEST.txt WAS WRITTEN BY THE BATTERY AND READ BY NOTHING.
# tr12_repro.sh --regen emits it; no gate, script or test ever compared it to the files it names.
# So it rotted silently: commit accc1ac7 changed c_consumer.txt without re-stamping, and the
# manifest carried a wrong hash for that golden through two further commits. Nobody noticed,
# because noticing required a check that did not exist.
#
# The fingerprint above does NOT cover this. It hashes every file under scripts/tr12_expected,
# _MANIFEST.txt included, so it detects that the tree CHANGED -- it cannot detect that the tree is
# internally INCONSISTENT. A manifest nothing verifies is decoration.
#
# Both directions are checked. A listed file that is missing or mis-hashed is the obvious failure;
# a golden present but UNLISTED is the one that matters more, because that is how a new expected
# block gets committed without ever entering the manifest.
manifest_check(){
  local md=scripts/tr12_expected/n9 mf=scripts/tr12_expected/n9/_MANIFEST.txt
  [ -r "$mf" ] || { echo "  [FAIL] $mf missing — the golden manifest cannot be verified"; return 1; }
  local rows=0 bad=0 h f a
  local listed; listed=$(mktemp)
  while read -r h f; do
    case "$h" in ''|'#'*) continue;; esac
    case "$h" in *[!0-9a-f]*|"") continue;; esac
    [ ${#h} -eq 64 ] || continue
    rows=$((rows+1)); printf '%s\n' "$f" >> "$listed"
    if [ ! -f "$md/$f" ]; then echo "  [FAIL] manifest lists $f, which is not present"; bad=$((bad+1)); continue; fi
    a=$(sha256sum "$md/$f" | cut -d' ' -f1)
    [ "$a" = "$h" ] || { echo "  [FAIL] $f: manifest says ${h:0:16}…, file hashes to ${a:0:16}…"; bad=$((bad+1)); }
  done < "$mf"
  if [ "$rows" -eq 0 ]; then
    echo "  [FAIL] $mf parsed to ZERO rows — an empty manifest verifies vacuously"; rm -f "$listed"; return 1
  fi
  # the mirror: every golden must be listed. _-prefixed files are the manifest and the skip pin.
  local unlisted=0 g
  for g in "$md"/*; do
    g=$(basename "$g"); case "$g" in _*) continue;; esac
    grep -qxF "$g" "$listed" || { echo "  [FAIL] golden $g exists but is NOT in _MANIFEST.txt"; unlisted=$((unlisted+1)); }
  done
  rm -f "$listed"
  if [ "$bad" -eq 0 ] && [ "$unlisted" -eq 0 ]; then
    echo "  [ok] golden manifest describes all $rows golden(s), and every golden is listed"
    return 0
  fi
  echo "  [FAIL] golden manifest: $bad mis-hashed/absent, $unlisted unlisted"
  echo "         Re-stamp with: ./scripts/tr12_repro.sh --n9 --regen --solve <solve> --out <dir>"
  return 1
}
if ! manifest_check; then echo "TR12_REPRO_GATE=FAIL"; exit 1; fi

# 🔴 INVOKE IT. A coverage check nobody calls is the defect this gate is named after.
fingerprint_coverage_check || { echo "TR12_REPRO_GATE=ERROR"; exit 2; }
FP=$(fingerprint)

# 🔴 THE PINNED SKIP SET (2026-09-05 fail-open class sweep, S-06). tr12_repro.sh emits
# TR12_REPRO=PASS whenever no executed row FAILED — rows that SKIP or report PENDING do not
# count against it, and it says so beside the token (TR12_REPRO_COMPLETE=NO). Several skips are
# keyed on capability discovery: `PENDING:--kc-profile — this binary does not accept it`,
# `SKIP:no-profile-tsv` (three rows ride Q3's TSV), `SKIP:python3-unavailable`. So a regression that
# DROPS a flag from solve.c, or a Q3 leg that silently stops writing its TSV, turns rows that used
# to run into skips — and this gate, which until today grepped only TR12_REPRO=PASS, still said
# TR12_REPRO_GATE=PASS. The battery's contract is fine (it reports completeness); the CONSUMER
# has to hold it to the set of skips it was stamped with. Mechanism: --stamp records every
# `TR12_<ROW>=SKIP:…|PENDING:…` line into $SKIPPIN; a run FAILS on any skip not in the pin (a row
# that used to run now skips) AND on any pinned skip that vanished (a row now runs — progress, but
# the pin must move with it, same discipline as the fingerprint stamp). No pin file = FAIL: an
# unpinned skip set is exactly the state this leg exists to refuse.
#   SEED (2026-09-05): $SKIPPIN was seeded from the 2026-09-04 evidence run (roae-private
#   evidence_q257_2026_09_04/VERDICTS.txt, 57 rows / 12 skips, same --n9 mode) because the box
#   refused the battery during the sweep. The next `--stamp` on a quiet box confirms or corrects
#   it; if the seed is wrong the gate fails LOUDLY with the diff, which is the safe side.
#   `--selftest-skip-pin` exercises the comparison on synthetic files, no battery needed.
SKIPPIN=scripts/tr12_expected/n9/_EXPECTED_SKIPS.txt
observed_skips(){ # $1 = VERDICTS.txt -> sorted TOKEN=VALUE lines, one per skipped/pending row
  grep -E '^TR12_[A-Z0-9_]+=(SKIP|PENDING)[:A-Za-z0-9_.-]*$' "$1" 2>/dev/null | grep -v '_REASON=' | sort -u
}
skip_pin_compare(){ # $1 = VERDICTS.txt  $2 = pin file ; prints findings; rc 0 same / 1 differs / 2 cannot
  local v="$1" pin="$2" obs exp new gone
  [ -r "$v" ]   || { echo "  [FAIL] skip pin: VERDICTS file unreadable: $v"; return 2; }
  [ -r "$pin" ] || { echo "  [FAIL] skip pin: no pinned skip set at $pin — run scripts/tr12_repro_gate.sh --stamp on a quiet box; an UNPINNED skip set cannot be certified"; return 2; }
  obs=$(observed_skips "$v"); exp=$(grep -vE '^[[:space:]]*(#|$)' "$pin" | sort -u)
  [ -n "$exp" ] || { echo "  [FAIL] skip pin: $pin has zero rows — an empty pin certifies nothing; re-stamp"; return 2; }
  new=$(comm -23 <(printf '%s\n' "$obs") <(printf '%s\n' "$exp"))
  gone=$(comm -13 <(printf '%s\n' "$obs") <(printf '%s\n' "$exp"))
  if [ -z "$new" ] && [ -z "$gone" ]; then
    echo "  [ok] skip set matches the pin ($(printf '%s\n' "$exp" | grep -c .) pinned skip/pending rows)"; return 0
  fi
  [ -n "$new" ]  && { echo "  [FAIL] rows that used to RUN now SKIP (a capability or input silently went away):"; printf '%s\n' "$new"  | sed 's/^/           /'; }
  [ -n "$gone" ] && { echo "  [FAIL] pinned skips that no longer occur (rows now run — re-stamp so the pin moves with them):"; printf '%s\n' "$gone" | sed 's/^/           /'; }
  return 1
}
if [ "$MODE" = "--selftest-skip-pin" ]; then
  T=$(mktemp -d); trap 'rm -rf "$T"' EXIT; f=0
  printf 'TR12_A=PASS\nTR12_B=SKIP:doc-only\nTR12_C=PENDING:--kc-x\nTR12_C_REASON=PENDING:--kc-x long text\nTR12_REPRO=PASS\n' > "$T/v"
  printf '# pin\nTR12_B=SKIP:doc-only\nTR12_C=PENDING:--kc-x\n' > "$T/pin"
  skip_pin_compare "$T/v" "$T/pin" >/dev/null; r=$?; [ "$r" -eq 0 ] && echo "  [ok] identical set -> 0" || { echo "  [FAIL] identical set -> $r"; f=1; }
  printf 'TR12_A=SKIP:no-profile-tsv\nTR12_B=SKIP:doc-only\nTR12_C=PENDING:--kc-x\nTR12_REPRO=PASS\n' > "$T/v2"
  o=$(skip_pin_compare "$T/v2" "$T/pin"); r=$?; [ "$r" -eq 1 ] && grep -q 'TR12_A=SKIP:no-profile-tsv' <<<"$o" && echo "  [ok] a NEW skip -> 1, named" || { echo "  [FAIL] new skip -> $r"; f=1; }
  printf 'TR12_A=PASS\nTR12_B=SKIP:doc-only\nTR12_C=PASS\nTR12_REPRO=PASS\n' > "$T/v3"
  o=$(skip_pin_compare "$T/v3" "$T/pin"); r=$?; [ "$r" -eq 1 ] && grep -q 'TR12_C=PENDING:--kc-x' <<<"$o" && echo "  [ok] a VANISHED skip -> 1, named" || { echo "  [FAIL] vanished skip -> $r"; f=1; }
  skip_pin_compare "$T/v" "$T/nopin" >/dev/null; r=$?; [ "$r" -eq 2 ] && echo "  [ok] missing pin -> 2" || { echo "  [FAIL] missing pin -> $r"; f=1; }
  : > "$T/empty"; skip_pin_compare "$T/v" "$T/empty" >/dev/null; r=$?; [ "$r" -eq 2 ] && echo "  [ok] empty pin -> 2" || { echo "  [FAIL] empty pin -> $r"; f=1; }
  skip_pin_compare "$T/absent" "$T/pin" >/dev/null; r=$?; [ "$r" -eq 2 ] && echo "  [ok] missing VERDICTS -> 2" || { echo "  [FAIL] missing VERDICTS -> $r"; f=1; }
  n=$(grep -cvE '^[[:space:]]*(#|$)' "$SKIPPIN" 2>/dev/null); [ "${n:-0}" -ge 1 ] && echo "  [ok] live pin $SKIPPIN has $n rows" || { echo "  [FAIL] live pin unreadable or empty"; f=1; }
  [ "$f" -eq 0 ] && { echo "TR12_SKIP_PIN_SELFTEST=PASS"; exit 0; } || { echo "TR12_SKIP_PIN_SELFTEST=FAIL"; exit 1; }
fi

if [ "$MODE" = "--check" ]; then
  if [ ! -f "$STAMP" ]; then
    echo "  no stamp exists yet — run scripts/tr12_repro_gate.sh --stamp"
    echo "TR12_REPRO_GATE_CURRENT=UNKNOWN"; exit 1
  fi
  WANT=$(awk -F= '/^fingerprint=/{print $2}' "$STAMP")
  if [ "$FP" = "$WANT" ]; then
    echo "TR12_REPRO_GATE_CURRENT=YES"; exit 0
  fi
  echo "  one of the $(fingerprint_files | wc -l | tr -d ' ') DERIVED inputs, this gate, or an"
  echo "  expected block changed since the last recorded PASS"
  echo "TR12_REPRO_GATE_CURRENT=NO"
  exit 1
fi

# ---- extract the PUBLISHED build line, do not invent one -------------------------------------
BUILD=$(grep -m1 -E '^gcc .*solve\.c' documentation/VERIFY.md)
if [ -z "$BUILD" ]; then
  echo "  [FAIL] no 'gcc ... solve.c' line found in documentation/VERIFY.md — the published build line is the input to this gate"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi
WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
printf '  build line (from documentation/VERIFY.md): %s\n' "$BUILD"
# run it verbatim, only redirecting the output binary into the scratch dir
if ! ( eval "${BUILD/-o solve/-o $WORK/solve}" ) >"$WORK/build.log" 2>&1; then
  # Show the ERRORS, not the first ten lines. A link failure (-lm dropped) lands at the END of
  # the log behind pages of warnings, and the first negative-control run printed warnings only.
  echo "  [FAIL] the PUBLISHED build line does not build:"
  grep -E 'error:|undefined reference|collect2|ld returned' "$WORK/build.log" | head -10 \
    || tail -10 "$WORK/build.log"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi
echo "  [ok] published build line builds"

# D5-01 leg (2026-09-05). THIS GATE ONLY EVER RUNS --n9, so it can never exercise the full-31 path
# on its own -- and the full-31 path is precisely where a2_q1c was guaranteed to FAIL after burning
# 3-5 h. Wiring the skip guard's own red/green gate in here is the only way an n=9 pre-push check
# protects a full-31 run. Fails the whole gate: a broken or moved guard means the next full-31
# battery is a scheduled 3-5 h failure.
if ! bash ./scripts/d5_01_q1c_skip_gate.sh; then
  echo "  [FAIL] the a2_q1c full-31 skip guard is broken or has moved (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# N3 leg (2026-09-10). Same reasoning one level down. D5-01 pins the CONTRACT between the interval
# measurement and the spend; this pins the MEASUREMENT -- that q1c_interval_measure and
# q10a_kwrank_measure can say EMPTY, can refuse to say EMPTY, and can say ERROR. An n=9 battery
# only ever exercises the "refuse" direction, because at n=9 the anchor is not the O3-least object;
# the EMPTY direction it will take at n=31 would otherwise be published untested. Fails the whole
# gate: a null that cannot fail is an assertion wearing a token's clothes, which is the exact
# defect these two rows were built to remove.
if ! bash ./scripts/n3_measured_nulls_gate.sh; then
  echo "  [FAIL] the Q1c / Q10a measured-null producers can no longer fail, or have moved (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# MQ1A-3 leg (2026-09-05). Same reasoning: the a2_q3_reader row is exact at n=9 (N < 2^53) and was
# a 53-bit comparison at full-31, so an n=9 battery can never see that defect. The reader's own
# full-31-magnitude red/green gate runs here instead (0.2 s). Fails the whole gate.
if ! bash ./scripts/q3_reader_exactness_gate.sh; then
  echo "  [FAIL] the a2_q3_reader exact-identity row can no longer fail at full-31 magnitude (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# Q-422 (Codex MQ1 §2c / MQ1A finding 2): the consumer's derived columns -- the ones V1 plots --
# must be gated by the brute-force recount and shown able to fail. Reuses the binary built above.
if ! Q422_SOLVE="$WORK/solve" bash ./scripts/q422_ratio_columns_gate.sh; then
  echo "  [FAIL] scripts/q422_ratio_columns_gate.sh did not PASS: the derived-ratio columns are no longer gated by the recount, or a mutant survived (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# Q-314 item 1: 48-divisibility of N_total and every layer flow, RE-DERIVED rather than read from
# the mod24_ok column, plus the fault that isolates it from the mod-24 gate. Wired here on the day
# it was written -- an unwired gate is a gate that never runs, which is the same defect it exists
# to catch (cf. bcf2a9bc, which wired a gate that had zero invokers).
if ! Q314_SOLVE="$WORK/solve" bash ./scripts/q314_mod48_gate.sh; then
  echo "  [FAIL] scripts/q314_mod48_gate.sh did not PASS: 48-divisibility is no longer gated, or the"
  echo "         q10-mod48 fault no longer isolates it from the mod-24 gate"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# Q-326 items (3)/(4)/(5): three ways the --kc-* surface answered a DIFFERENT question than the
# one asked and said nothing about it. `--kc-count DIR --kc-c3-max 387` returned the SUPERSPACE
# count at rc=0; T = 2^32 truncated to int 0 and enumerated 0 walks instead of 26112; and
# kc_parse_walk never checked the pairs form a permutation -- MEASURED, 11 of 28 duplicate-pair
# vectors got back a POSITIVE multiplicity and a repr line under a #provenance trailer stamping
# the ratified convention. Baseline reuses this gate's binary; the 4 mutants are rebuilt inside,
# because a handed-in binary cannot carry a mutation. ~2m50s.
if ! Q326_QS_SOLVE="$WORK/solve" bash ./scripts/q326_kc_query_surface_gate.sh; then
  echo "  [FAIL] scripts/q326_kc_query_surface_gate.sh did not PASS: the --kc-* query surface no"
  echo "         longer refuses options it cannot honour, or a walk that is not a permutation"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# RCQ01 F3 / KC04 #3 (2026-09-02, re-found 2026-09-09). Every KC artifact writer announced success
# on /dev/full: "atlas written", KC_SCAN=OK, rc 0, nothing on disk. One writer was fixed on
# 2026-09-04 and the other six were left. This gate is red on the pre-fix engine with exactly those
# six named and the merge [ok] -- it reproduces the partial fix as a visible pattern -- and green on
# the fixed one. ~40s including its own n=9 build.
if ! SOLVE="$WORK/solve" bash ./scripts/kc_writer_devfull_gate.sh; then
  echo "  [FAIL] scripts/kc_writer_devfull_gate.sh did not PASS: a KC writer reports success for an"
  echo "         artifact it could not write, or a writer that should work no longer does."
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# A-5 orbit membership (Q-421 / Codex MQ1 s2b). MEASURED UNWIRED 2026-09-09: nothing invoked this
# gate, so the ONLY coverage of atlas_orbit_columns / atlas_orbit_membership -- which have 0
# references in tests.py and run only at n == 31 -- never executed. A5 is therefore a path whose
# first real run would have followed a 7-33 day scan, with a safety net nobody switched on.
if ! bash ./scripts/a5_orbit_membership_gate.sh; then
  echo "  [FAIL] scripts/a5_orbit_membership_gate.sh did not PASS: the A-5 orbit field no longer"
  echo "         detects a swap between two orbits of the same size, which atlas_orbit_columns"
  echo "         alone is blind to."
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# Q-433 sibling: the XA-c/d pricing path refused without a W0-D mapping certificate, but the
# refusal only tested that a PATH STRING was supplied -- the file was never opened, so
# `--xa-node-mapping-cert /nope.json` unblocked a scientific verdict. Pure-python gate, <1s.
if ! bash ./scripts/q433_xa_cert_gate.sh; then
  echo "  [FAIL] scripts/q433_xa_cert_gate.sh did not PASS: the XA node-mapping certificate is"
  echo "         no longer validated, or a mutant that accepts any path survived"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# R12b #8 / Q-286 (wired 2026-09-08). MEASURED INERT: `grep -rn tr8_merge_pool_integrity` over the
# whole public repo returned the gate file and nothing else, so the two defects it certifies —
# `solve.py --tr8-dof-merge` accepting a shard id outside the header's declared range, and merging
# against a bank.json whose recomputed digest no longer matches admitted_bank_sha256 — were guarded
# by an instrument that had never run outside the session that wrote it. An unrun instrument is not
# coverage. Same class and same remedy as the a2/xa sibling sweep below.
# Blocking, like every other leg here: it is GREEN today (measured 3.0 s on the orchestrator), so
# wiring it blocks nothing that exists, and both defects are silent-corruption of a published
# statistic. Pure python, no ladder data, no binary — it does NOT use "$WORK/solve".
if ! bash ./scripts/tr8_merge_pool_integrity_gate.sh; then
  echo "  [FAIL] scripts/tr8_merge_pool_integrity_gate.sh did not PASS: --tr8-dof-merge no longer"
  echo "         refuses an undeclared extra shard, or a bank.json mutated since the shards were"
  echo "         drawn, or the three-way control stopped merging cleanly (see message above)"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# Q-326 item (1): `--kc-unrank --kc-record` printed the class representative unconditionally, but
# kc_class_repr leaves `repr` UNWRITTEN on every m == 0 exit -- so the record line was uninitialised
# stack, indexing partner[64] with bytes up to 255, shipped under rc = 0 with a #provenance trailer
# stamping it conformant. Reachable at n=9 in under a second via `--kc-c3-max 0`. Wired the day it
# was written; the mutants are rebuilt here because a handed-in binary cannot carry a mutation.
if ! Q326_SOLVE="$WORK/solve" bash ./scripts/q326_kc_unrank_m0_gate.sh; then
  echo "  [FAIL] scripts/q326_kc_unrank_m0_gate.sh did not PASS: the m == 0 guard on the unrank"
  echo "         record path is gone, or a mutant that still prints uninitialised repr survived"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

# D5-02 / D5-03 / D5-04 / D5-08 legs (2026-09-05, roae-private D5_QUERY_PROGRAM_REVIEW_2026_09_04.md).
# Four rows would have emitted PASS at full-31 for a computation other than the one their prose
# names: a1_q8_chi2 (an n=13 self-test in place of the gallery chi-square), a0_ls_w0 (a C2|C1 / C3|C1
# Monte-Carlo in place of TR-8's exact pair-only null), TR12_Q7 (PASS with the SAT-witness leg
# uncommanded) and the c_q6 / c_q10a shell legs (the pre-Q-394 spec). Each fix carries its own
# red/green gate with mutants and a closure check; each is wired here so the n=9 pre-push run
# protects the full-31 run. Any one of them failing fails the whole gate.
# 🔴 LITERAL PATHS, NOT STEMS (RCQ02 F6, 2026-09-09). This loop used to name the four gates
# WITHOUT `.sh` and append it inside. derived_inputs() greps for `…\.(c|py|sh|md)` and so could not
# see them: d5_03 and d5_04 were EXECUTED on every pre-push run and were absent from the
# fingerprint, measured by mirror-mutation (append `exit 1` to either and the fingerprint is
# byte-identical). d5_02 and d5_08 were hashed only by accident, because they happen to be named
# with `.sh` somewhere else in the tree. Writing the path the way the file is actually spelled
# costs nothing and removes a class of invisibility that depends on coincidence.
for leg in scripts/d5_02_q8_chi2_gallery_gate.sh scripts/d5_03_ls_w0_exact_gate.sh \
           scripts/d5_04_q7_witnesses_gate.sh scripts/d5_08_q6_q10a_shell_gate.sh; do
  if ! bash "./$leg"; then
    echo "  [FAIL] $leg did not PASS (see message above)"
    echo "TR12_REPRO_GATE=FAIL"; exit 1
  fi
done

# Sibling sweep (2026-09-05, MQ1A adjudication): the two other full-31-only verdict gates already in
# the tree were wired into NOTHING -- each could be run by hand and was run by nobody. Same class,
# same remedy; 1.1 s and 0.3 s.
if ! bash ./scripts/a2_slot_verdict_gate.sh | grep -qx 'A2_SLOT_VERDICT=OK'; then
  echo "  [FAIL] the A2 slot / verdict-exit gate (MQ1 §2a/§2d) did not report OK"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi
if ! bash ./scripts/xa_exact_verdict_gate.sh | grep -qx 'XA_EXACT_VERDICT=OK'; then
  echo "  [FAIL] the XA exact-verdict gate (MQ1 §4) did not report OK"
  echo "TR12_REPRO_GATE=FAIL"; exit 1
fi

if ! ./scripts/tr12_repro.sh --n9 --solve "$WORK/solve" --out "$WORK/out" >"$WORK/repro.log" 2>&1; then
  :   # non-zero exit is expected on FAIL; the token below is the authority
fi
if grep -qx 'TR12_REPRO=PASS' "$WORK/out/VERDICTS.txt" 2>/dev/null; then
  sed -n 's/^rows=/  /p' "$WORK/repro.log" | tail -1
  echo "  [ok] TR12_REPRO=PASS"
  grep -E '^TR12_REPRO_(ROWS|SKIPPED|COMPLETE)=' "$WORK/out/VERDICTS.txt" | sed 's/^/  /'
  if [ "$MODE" = "--stamp" ]; then
    { echo "# Pinned skip/pending rows of the n=9 battery, recorded by scripts/tr12_repro_gate.sh --stamp."
      echo "# A run whose skip set differs from this list FAILS the gate (see the gate header). Re-stamp"
      echo "# in the SAME commit as any change that legitimately adds or removes a skip."
      observed_skips "$WORK/out/VERDICTS.txt"
    } > "$SKIPPIN"
    echo "  [ok] pinned $(observed_skips "$WORK/out/VERDICTS.txt" | grep -c .) skip/pending rows into $SKIPPIN"
  elif ! skip_pin_compare "$WORK/out/VERDICTS.txt" "$SKIPPIN"; then
    echo "  [FAIL] the battery PASSED its executed rows, but its SKIP set is not the pinned one (above)"
    echo "TR12_REPRO_GATE=FAIL"; exit 1
  fi
  # F-5 round 5 condition 1b: the parse-matches-producer leg. Runs BEFORE the stamp is written,
  # so a tree whose n>=31-only parse does not match its engine cannot be stamped as reproducing.
  q7ranks_parse_leg; _q7rc=$?
  if [ "$_q7rc" -eq 1 ]; then echo "TR12_REPRO_GATE=FAIL"; exit 1; fi
  if [ "$_q7rc" -eq 2 ]; then echo "TR12_REPRO_GATE=ERROR"; exit 2; fi
  # Same placement and the same reason: a tree whose extremal rows can pass on an empty
  # enumeration must not be stamped as reproducing.
  q2_witness_leg; _q2rc=$?
  if [ "$_q2rc" -eq 1 ]; then echo "TR12_REPRO_GATE=FAIL"; exit 1; fi
  if [ "$_q2rc" -eq 2 ]; then echo "TR12_REPRO_GATE=ERROR"; exit 2; fi

  if [ "$MODE" = "--stamp" ]; then
    { echo "# Recorded by scripts/tr12_repro_gate.sh --stamp. Proves the committed tree REPRODUCED,"
      echo "# not merely that it was committed. Re-stamp in the SAME commit as any solve.c,"
      echo "# tr12_repro.sh or expected-block change, or --check will correctly report NO."
      echo "fingerprint=$FP"
    } > "$STAMP"
    echo "  [ok] stamped $STAMP"
  fi
  echo "TR12_REPRO_GATE=PASS"; exit 0
fi
echo "  [FAIL] the committed tree does not reproduce its own published battery:"
grep -E '^TR12_[A-Z0-9_]*=FAIL' "$WORK/out/VERDICTS.txt" 2>/dev/null | head -15
sed -n 's/^rows=/  /p' "$WORK/repro.log" | tail -1
echo "TR12_REPRO_GATE=FAIL"; exit 1
