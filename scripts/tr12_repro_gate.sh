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
fingerprint(){
  { sha256sum solve.c verify.py solve.py scripts/tr12_repro.sh scripts/tr12_repro_gate.sh 2>/dev/null
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
    echo "TR12_REPRO_GATE_CURRENT=UNKNOWN (no stamp — run scripts/tr12_repro_gate.sh --stamp)"; exit 1
  fi
  WANT=$(awk -F= '/^fingerprint=/{print $2}' "$STAMP")
  if [ "$FP" = "$WANT" ]; then
    echo "TR12_REPRO_GATE_CURRENT=YES"; exit 0
  fi
  echo "TR12_REPRO_GATE_CURRENT=NO (solve.c, verify.py, solve.py, tr12_repro.sh, this gate, or an expected block changed since the last recorded PASS)"
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

# D5-02 / D5-03 / D5-04 / D5-08 legs (2026-09-05, roae-private D5_QUERY_PROGRAM_REVIEW_2026_09_04.md).
# Four rows would have emitted PASS at full-31 for a computation other than the one their prose
# names: a1_q8_chi2 (an n=13 self-test in place of the gallery chi-square), a0_ls_w0 (a C2|C1 / C3|C1
# Monte-Carlo in place of TR-8's exact pair-only null), TR12_Q7 (PASS with the SAT-witness leg
# uncommanded) and the c_q6 / c_q10a shell legs (the pre-Q-394 spec). Each fix carries its own
# red/green gate with mutants and a closure check; each is wired here so the n=9 pre-push run
# protects the full-31 run. Any one of them failing fails the whole gate.
for leg in d5_02_q8_chi2_gallery_gate d5_03_ls_w0_exact_gate d5_04_q7_witnesses_gate d5_08_q6_q10a_shell_gate; do
  if ! bash "./scripts/$leg.sh"; then
    echo "  [FAIL] scripts/$leg.sh did not PASS (see message above)"
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
