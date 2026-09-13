#!/usr/bin/env bash
# tr12_mint_state_gate.sh — prove that the TR-12 battery's verdict DISTINGUISHES a run whose rows
# were diffed against an existing golden from one whose rows it MINTED from its own output.
#
# Verdict (one whole line, matched with `grep -qx`):
#
#   TR12_MINT_STATE=PASS    every leg below was MEASURED and HELD
#   TR12_MINT_STATE=FAIL    a leg was taken and the battery's emitted verdict CONTRADICTED it
#   TR12_MINT_STATE=ERROR   the SUBJECT could not be read or executed, so nothing was measured
#
# EXIT STATUS:  0 PASS · 1 FAIL · 2 ERROR
#
# 🔴 WHY THIS GATE EXISTS (2026-09-13). `--mint-missing` sets a row's status to PASS whenever rc==0
# and writes that row's own output into $EXPECTDIR as the new golden. The driver
# (roae-private/scripts/query_program_run.sh) ALWAYS passes --mint-missing. At n=31 no golden set
# exists, so on the first full-31 run EVERY row is minted and the golden-diff leg contributes ZERO
# information — yet `TR12_REPRO=PASS` and `QUERY_PROGRAM=PASS` were THE SAME STRINGS a fully diffed
# run prints. A reader, and every `grep -qx` consumer, could not tell the two apart. The battery
# already printed `TR12_REPRO_MINTED=<n>` beside them, so the fact was present and NOT load-bearing.
#
# 🔴 WHY IT EXECUTES THE BATTERY'S OWN TEXT RATHER THAN A COPY. The precedent here is
# q7ranks_parse_gate.sh, whose FIRST version defined its own copy of the row it was checking and
# therefore reported PASS with the real defect restored AND with the battery deleted outright — it
# bound to a copy of the consumer, so its red test mutated the GATE, not the SUBJECT. This gate
# EXTRACTS the region between the `# >>> TR12_MINT_STATE_BLOCK_BEGIN` and
# `# <<< TR12_MINT_STATE_BLOCK_END` markers in scripts/tr12_repro.sh and RUNS IT, with only the
# surrounding bookkeeping stubbed (say, VERD, the row counters, the token arrays). The mint-state
# decision, the token strings and the aggregate emission are all the battery's own bytes. Mutate
# them in the battery and this gate goes red; delete them and it reports ERROR, never PASS —
# a gate that cannot see its subject must not report success.
#
# WHAT THIS GATE DOES NOT DO, said plainly so the green is never read as more than it is:
#   * It does NOT verify a minted golden. Nothing can: a minted block is the run's OWN output, so
#     diffing a later run against it is a regression test, not a verification. That is
#     tr12_n31_golden_gate.sh's subject (Tiers 1-4), and its answer there is the same word,
#     MINTED-UNVERIFIED.
#   * It does NOT prove the n=31 run mints. It proves that IF rows are minted THEN the verdict says
#     so in its value, and that if none are the value is unchanged from before this change.
#
# USAGE:  bash scripts/tr12_mint_state_gate.sh [--battery FILE]
#         --battery FILE   grade FILE instead of scripts/tr12_repro.sh (this is how the mutation
#                          testing below drives a deliberately broken copy).
set -u

SELF_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
BATTERY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --battery) BATTERY="${2:-}"; shift 2 ;;
        -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
        *) echo "unknown argument: $1" >&2; echo "TR12_MINT_STATE=ERROR"; exit 2 ;;
    esac
done
[ -n "$BATTERY" ] || BATTERY="$SELF_DIR/tr12_repro.sh"

WORK=$(mktemp -d) || { echo "TR12_MINT_STATE=ERROR"; exit 2; }
trap 'rm -rf "$WORK"' EXIT

nfail=0
bad(){ echo "  [FAIL] $*"; nfail=$((nfail+1)); }
ok(){  echo "  [ok]   $*"; }
err(){ echo "  [ERROR] $*"; echo "TR12_MINT_STATE=ERROR"; exit 2; }

# ---- LEG 0: the subject exists and can be extracted -------------------------------------------
# An empty extraction is ERROR, not PASS. This is the leg that fires if someone deletes the
# markers, renames the block, or points --battery at a file that is not the battery.
if [ ! -r "$BATTERY" ]; then err "cannot read the battery at $BATTERY — the subject of this gate is absent"; fi
BLOCK="$WORK/block.sh"
awk '/^# >>> TR12_MINT_STATE_BLOCK_BEGIN/{f=1}
     f{print}
     /^# <<< TR12_MINT_STATE_BLOCK_END/{f=0}' "$BATTERY" > "$BLOCK"
if [ ! -s "$BLOCK" ]; then
    err "the TR12_MINT_STATE block markers are not present in $BATTERY — extracted 0 bytes, so the
        verdict emission was NOT measured. That is not the same as passing."
fi
if ! grep -q 'TR12_REPRO=' "$BLOCK"; then
    err "the extracted block emits no TR12_REPRO line at all — the region between the markers is
        not the verdict emission this gate grades, so nothing was measured."
fi
ok "extracted $(wc -l < "$BLOCK") line(s) of the battery's OWN verdict emission from $BATTERY"

# ---- the harness: run the EXTRACTED text with the surrounding bookkeeping stubbed --------------
# REGEN and MINT_MISSING are both 0 so the manifest writer (which needs a real $EXPECTDIR full of
# blocks) stays out of the way; it is not this gate's subject. Everything that decides the TOKEN is
# the battery's own text.
run_block(){ # run_block OUTFILE N_PAIRS SCAN_OK NFAIL [MINTED_ROW...]
    local out="$1" np="$2" so="$3" nf="$4"; shift 4
    local runner="$WORK/runner.sh" m
    {
        printf 'set -u\n'
        printf 'say(){ :; }\n'
        printf 'VERD=%q\n' "$out"
        # `printf '%s=%q\n' EXPECTDIR` and not `printf 'EXPECTDIR=%q\n'`: these lines are SHELL
        # SOURCE being generated into a runner, not verdict tokens, and the literal form is
        # indistinguishable to doc_gates.sh GATE 89's extractor, which would census EXPECTDIR as an
        # emitted verdict token and demand a documentation row for a name no run ever prints.
        printf '%s=%q\n' EXPECTDIR "$WORK/expect"
        printf 'N_PAIRS=%s\nSCAN_OK=%s\nNFAIL=%s\nREGEN=0\nMINT_MISSING=0\n' "$np" "$so" "$nf"
        printf 'declare -a TOKORDER=()\n'
        printf 'declare -A TOKSTATE=()\n'
        printf 'declare -a MINTED=('
        for m in "$@"; do printf '%q ' "$m"; done
        printf ')\n'
        cat "$BLOCK"
    } > "$runner"
    : > "$out"
    ( bash "$runner" ) >/dev/null 2>&1
    return 0
}

has(){  grep -qx "$2" "$1"; }           # whole-line, never output shape
show(){ sed 's/^/        /' "$1"; }

# ---- LEG 1: n=31, NOTHING minted — the diffed reading -----------------------------------------
# This is also the POSITIVE CONTROL for legs 2 and 3: it proves the harness can produce a bare
# `TR12_REPRO=PASS`, so leg 2's "must NOT contain it" is a real measurement and not a broken
# harness that emits nothing at all.
V1="$WORK/v_diffed.txt"; run_block "$V1" 31 1 0
if has "$V1" 'TR12_REPRO=PASS' && has "$V1" 'TR12_REPRO_GOLDEN_STATE=DIFFED' && has "$V1" 'QUERY_PROGRAM=PASS'; then
    ok "n=31, 0 minted -> TR12_REPRO=PASS + GOLDEN_STATE=DIFFED + QUERY_PROGRAM=PASS (control: a bare PASS IS reachable)"
else
    bad "n=31 with nothing minted did not emit the unqualified PASS triple:"; show "$V1"
fi

# ---- LEG 2: n=31, 3 rows minted — THE DEFECT THIS GATE EXISTS FOR ------------------------------
# The load-bearing assertion is the NEGATIVE one: a whole-line `TR12_REPRO=PASS` must NOT be
# present. Before the 2026-09-13 fix it WAS, identically to leg 1, and that is the red.
V2="$WORK/v_minted.txt"; run_block "$V2" 31 1 0 r_alpha r_beta r_gamma
if has "$V2" 'TR12_REPRO=PASS'; then
    bad "n=31 with 3 MINTED rows still emits a whole-line TR12_REPRO=PASS — a minted run is
         indistinguishable from a diffed one, which is the entire defect:"; show "$V2"
else
    ok "n=31, 3 minted -> no whole-line TR12_REPRO=PASS (a stale consumer fails closed)"
fi
if has "$V2" 'TR12_REPRO=PASS:MINTED-3'; then ok "the count rides in the token: TR12_REPRO=PASS:MINTED-3"
else bad "expected a whole-line TR12_REPRO=PASS:MINTED-3:"; show "$V2"; fi
if has "$V2" 'TR12_REPRO_GOLDEN_STATE=MINTED-UNVERIFIED'; then ok "TR12_REPRO_GOLDEN_STATE=MINTED-UNVERIFIED"
else bad "expected a whole-line TR12_REPRO_GOLDEN_STATE=MINTED-UNVERIFIED:"; show "$V2"; fi
if has "$V2" 'QUERY_PROGRAM=PASS'; then
    bad "the PROGRAM-level aggregate still reads as an unqualified PASS on a fully minted run:"; show "$V2"
else ok "the aggregate is qualified too: no whole-line QUERY_PROGRAM=PASS"; fi
if has "$V2" 'QUERY_PROGRAM=PASS:MINTED-3'; then ok "QUERY_PROGRAM=PASS:MINTED-3"
else bad "expected a whole-line QUERY_PROGRAM=PASS:MINTED-3:"; show "$V2"; fi

# ---- LEG 3: n=9 REGRESSION — goldens exist, nothing is minted, nothing may change --------------
# The n=9 path is what tr12_repro_gate.sh, query_program_rehearse_n9.sh and c305_k1w5_remote.sh
# all grep whole-line. If this leg ever goes red, those three break.
V3="$WORK/v_n9.txt"; run_block "$V3" 9 1 0
if has "$V3" 'TR12_REPRO=PASS' && has "$V3" 'QUERY_DRYRUN=PASS' && has "$V3" 'TR12_REPRO_GOLDEN_STATE=DIFFED'; then
    ok "n=9, 0 minted -> TR12_REPRO=PASS + QUERY_DRYRUN=PASS unchanged (the existing consumers keep working)"
else
    bad "the n=9 path CHANGED — this breaks tr12_repro_gate.sh and the n=9 rehearsals:"; show "$V3"
fi

# ---- LEG 4: the FAIL path is untouched and is never qualified ----------------------------------
V4="$WORK/v_fail.txt"; run_block "$V4" 31 1 1 r_alpha
if has "$V4" 'TR12_REPRO=FAIL' && ! grep -q '^TR12_REPRO=PASS' "$V4"; then
    ok "a failing battery still emits a bare TR12_REPRO=FAIL, minted rows or not"
else
    bad "the FAIL path changed; FAIL must never carry a mint qualifier:"; show "$V4"
fi

if [ "$nfail" -eq 0 ]; then echo "TR12_MINT_STATE=PASS"; exit 0; fi
echo "  $nfail leg(s) failed"
echo "TR12_MINT_STATE=FAIL"; exit 1
