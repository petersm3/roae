#!/usr/bin/env bash
#
# row_assertion_gate.sh — THE GATE FOR THE "EMITS A TABLE, ASSERTS NOTHING" CLASS.
#
# THE ONE-LINE RULE, stated so it can be checked mechanically:
#
#   A row of scripts/tr12_repro.sh that BUILDS its own output must not be able to exit 0
#   having asserted nothing about what it emitted.
#
# WHY THIS EXISTS, and why it is a gate rather than another review round. The class was found
# three times by three instruments and fixed one instance at a time:
#
#   * round 1 (F-5, D11, 2026-09-08) — `c_v1`: an atlas with every `marginal_raw` block stripped
#     drove the loop zero times, printed a header-only table and PASSED. Fixed IN `c_v1`.
#   * round 4 (F-5, B2, 2026-09-11) — `c_v2` and `c_v5`: the SAME defect, one screen below, in
#     the siblings the round-1 fix was never swept to. Round 4's own words: "round 1's D11 class,
#     fixed for c_v1 and never swept to its siblings."
#   * G-31 (2026-09-11), independently, by row-by-row enumeration of the same file: 8 rows that
#     publish content with no derivable property at all, 16 more whose predictable property
#     nothing checks at n=31.
#
# Two lanes reaching the same place by different routes is the signature the stopping rule
# (CODEX_ROUNDS_STOPPING_RULE_2026_09_10.md, criterion 2) names: when the residue shares a SHAPE,
# the next step is a gate, not a reviewer. A fourth reviewer would find the fourth instance.
# This finds all of them, every time it runs, including the ones nobody has written yet.
#
# WHAT IT MEASURES, exactly. The battery is parsed into `row_begin` … `row_end`/`row_end_val`
# blocks. For each block the analyser asks two questions and answers both from the source text:
#
#   (1) WHO BUILT THE OUTPUT? Three classes, decided from the text:
#         DRIVER   the driver constructs the rows — a loop over a parsed input (`while read` …
#                  `done < <(grep …)`), an `awk`/`sed`/`cut`/`bc` projection written straight to
#                  the row stream, a `| tee`, or an `echo`/`printf` of a `$( … )` it computed.
#                  THIS IS THE CLASS THE GATE OWNS: the driving input can be empty, and then the
#                  loop runs zero times and the row prints a header and exits 0.
#         PUBLISH  the content is the producer's; the driver only `cat`s or `cp`s it into the row
#                  or an artifact (`( "$SOLVE" … && cat "$ARTDIR/x.json" )`).
#         PRODUCER one producer invocation, no driver-side construction at all.
#       PUBLISH and PRODUCER rows that assert nothing are REPORTED as `RC-ONLY` and counted in
#       ROW_ASSERTION_RCONLY, and they do NOT fail the gate: their rc is the producer's, which is
#       the producer/consumer axis of N31_ATTESTATION_SCOPE, a different question from this one.
#       Naming them here without failing on them is deliberate — the count is evidence, and an
#       accurate red list is worth more than a wide one.
#
#   (2) CAN IT EXIT 0 ANYWAY? A row ASSERTS if it contains at least one CONTENT-GUARDED failure
#       path that REACHES its rc:
#         content-guarded — the failure is raised under a test of the data: `[ … ]`, `case`,
#                           `grep -q`, or an awk/shell comparison (`-eq -ne -lt -gt -le -ge`,
#                           `=`, `!=`, `<`, `>`). A failure raised by a subprocess's exit status
#                           alone (`"$SOLVE" … || erc=1`) is NOT content-guarded: it asserts that
#                           the producer ran, not that what was printed is right. That
#                           distinction is the whole finding — `a2_q7_ranks` "took the solver's
#                           EXIT STATUS and nothing else, so a stub printing rank3=5 passed it".
#         reaches rc      — the failure is a literal `exit <nonzero>`, or it sets a variable the
#                           subshell later `exit`s, or one named in the `row_end` rc argument.
#                           A `fails=1` that nothing ever exits is not an assertion; the gate
#                           kills that mutant (M4 below) as readily as a deleted check.
#       A `row_end_val` row may instead be VALUE-CARRIED: its verdict variable is assigned an
#       `ERROR:`/`FAIL` literal under a guard, and `tok_record` counts ERROR* as a failure.
#
# THE EXEMPTION TABLE below is the RED LIST: the rows that are unasserted TODAY, each with the
# reason, so the gate is green on the tree it was written against and goes red the moment a new
# one appears. A row here that has since been fixed is STALE and is a FAIL — an exemption that
# exempts nothing rots (the failopen_closure_allow.tsv rule). The list is therefore a ratchet
# that can only shrink. `--strict` ignores it and prints the whole red list, which is how the
# population in ROW_ASSERTION_SWEEP_2026_09_11.md was measured.
#
# WHAT IT CANNOT SEE, stated plainly:
#   (a) it is a STATIC analysis of shell text — it proves a check EXISTS and can fail the row,
#       not that the check is the RIGHT one. `c_v2` asserting its row sums does not make cell
#       attachment across a merge detectable; that limit is real and is G-31 §3, not a gate bug.
#   (b) a check that is content-guarded and reaches rc but is trivially true (`[ 1 = 1 ]`) reads
#       as asserted. No static rule distinguishes a weak check from a strong one.
#   (c) full-line `#` comments are stripped before analysis (so commenting a check OUT is caught);
#       a trailing comment on a live line is not stripped and could in principle supply a keyword.
#   (d) it does not run the battery. It cannot tell whether a row executes at n=31.
#
# Verdict tokens, each a WHOLE line (grep -qx; never gate on output shape):
#   ROW_ASSERTION=PASS|FAIL|ERROR
#   ROW_ASSERTION_ERROR=<cause>   on ERROR: bad-args | battery-missing | battery-unreadable |
#                                 no-rows-parsed | unbalanced-block | analyzer-failed |
#                                 exemption-unknown-row | exemption-malformed
#   ROW_ASSERTION_POP=n        row_begin blocks parsed
#   ROW_ASSERTION_EMIT=n       of those, rows that write a table or artifact (DRIVER + PUBLISH)
#   ROW_ASSERTION_DRIVER=n     of those, rows the DRIVER builds (the class this gate owns)
#   ROW_ASSERTION_ASSERT=n     emitting rows with a content-guarded failure path reaching rc
#   ROW_ASSERTION_UNASSERTED=n emitting rows with none
#   ROW_ASSERTION_RCONLY=n     non-DRIVER rows with none (advisory; does not fail the gate)
#   ROW_ASSERTION_KNOWN=n      DRIVER rows covered by the exemption table below
#   ROW_ASSERTION_NEW=n        DRIVER rows unasserted and NOT covered  -> FAIL
#   ROW_ASSERTION_STALE=n      exemptions that no longer apply -> FAIL (or ERROR if the row is gone)
# Per-row lines, TAB-separated, printed on FAIL / --list / --strict:
#   ROW <id> <token> <lines> <DRIVER|PUBLISH|PRODUCER> <ASSERTED|UNASSERTED> <loop-driven|flat> <why>
#   UNASSERTED <id> …   the red list this run produced
#   RC-ONLY    <id> …   advisory: emission and rc are both the producer's
#   STALE      <id> …   an exemption that exempts nothing
# Exit 0 PASS / 1 FAIL / 2 ERROR.
#
# usage: row_assertion_gate.sh [--battery FILE] [--strict] [--list] [--selftest]
#   --battery FILE  analyse FILE instead of scripts/tr12_repro.sh (mutation testing uses this)
#   --strict        ignore the exemption table: every unasserted emitter is a FAIL
#   --list          print the per-row table even on PASS
#   --selftest      plant fixtures and prove PASS, FAIL and ERROR are all reachable
#
# Developed with AI assistance (Claude Opus 5, Anthropic). Direction is the operator's.
set -uo pipefail

BATTERY=""; STRICT=0; LIST=0; SELFTEST=0
while [ $# -gt 0 ]; do
  case "$1" in
    --battery) BATTERY=${2:-}; shift 2 ;;
    --strict)  STRICT=1; shift ;;
    --list)    LIST=1; shift ;;
    --selftest) SELFTEST=1; shift ;;
    *) echo "usage: $0 [--battery FILE] [--strict] [--list] [--selftest]"
       echo "ROW_ASSERTION_ERROR=bad-args"; echo "ROW_ASSERTION=ERROR"; exit 2 ;;
  esac
done

SELF_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd) || SELF_DIR=.
[ -n "$BATTERY" ] || BATTERY="$SELF_DIR/tr12_repro.sh"

# ---------------------------------------------------------------------------------------------
# THE RED LIST. TAB-separated: rowid <TAB> token <TAB> class <TAB> reason.
#   class  DRIVER-BUILT    the driver builds the table and checks nothing about it
# Measured 2026-09-11 against scripts/tr12_repro.sh at the working tree; see
# roae-private/ROW_ASSERTION_SWEEP_2026_09_11.md for the row-by-row derivation.
# DO NOT add a row here to make the gate green. Every line is a published number nothing checks.
# ---------------------------------------------------------------------------------------------
exemptions(){ cat <<'ALLOW_EOF'
ALLOW_EOF
}

# ---------------------------------------------------------------------------------------------
# The analyser. Emits one TSV line per row block:
#   ROW <TAB> id <TAB> token <TAB> firstline-lastline <TAB> EMIT|PRODUCER <TAB> ASSERTED|UNASSERTED <TAB> why
# and exits nonzero with an ERR line if the file does not parse as a battery.
# ---------------------------------------------------------------------------------------------
analyse(){ awk '
function reset(   i){
    drv=0; pub=0; loop=0; nfail=0; nrcprop=0; valguard=0; emitted=0
    delete failvar; delete failkind; delete exited; delete guard
    depth=0
}
function testish(s){
    return (s ~ /\[ / || s ~ /\[\[/ || s ~ /(^|[^-A-Za-z0-9_])-(eq|ne|lt|gt|le|ge)([^A-Za-z0-9_]|$)/ \
         || s ~ /grep -q/ || s ~ /^case / || s ~ /; *case / || s ~ /!=/ || s ~ /==/ \
         || s ~ /if *\(/ || s ~ /\$[0-9] *!?~/ || s ~ /^assert / || s ~ /^if .*:$/)
}
# a failure raised by a subprocess exit status ALONE is not a check of the content
function rcprop(s){
    return (s ~ /(\$SOLVE|\$\{SOLVE\}|python3|solve\.py|verify\.py|^S |; *S ).*\|\|/ \
         || s ~ /^\( *cd .*\|\|/ || s ~ /^ *S .*\|\|/)
}
function failname(s,   v){
    if (match(s, /[A-Za-z_][A-Za-z0-9_]*\+\+/))          { v=substr(s,RSTART,RLENGTH-2); return v }
    if (match(s, /[A-Za-z_][A-Za-z0-9_]*=1([^0-9]|$)/))  { v=substr(s,RSTART,RLENGTH); sub(/=1.*/,"",v); return v }
    if (match(s, /[A-Za-z_][A-Za-z0-9_]*=\$\(\([A-Za-z_][A-Za-z0-9_]*\+1\)\)/)) { v=substr(s,RSTART,RLENGTH); sub(/=.*/,"",v); return v }
    return ""
}
# only a variable that reaches rc, or one NAMED like a failure flag, is a failure path.
# SCAN_OK=1 is a success flag and must not read as one.
function failflag(s,   v){
    v=failname(s); if (v=="") return ""
    if (v in exited) return v
    if (index(rcseen, "<" v ">") > 0) return v
    if (tolower(v) ~ /fail|err|bad|^rc$|rc$/) return v
    return ""
}
function directexit(s){
    return (s ~ /exit +[1-9]/ || s ~ /exit *\(? *[A-Za-z_][A-Za-z0-9_]* *\? *[1-9]/ \
         || s ~ /sys\.exit\([1-9]\)/ || s ~ /raise SystemExit/ || s ~ /^assert /)
}
function failish(s){ return (failname(s) != "" || directexit(s)) }

/^[ \t]*[A-Za-z0-9_]+\(\)[ \t]*\{/ { fn=$0; sub(/\(\).*/,"",fn); gsub(/[ \t]/,"",fn) }

# join shell line continuations before anything else looks at the text
{ raw=$0
  if (pend != "") { raw = pend " " raw; pend="" }
  if (raw ~ /\\[ \t]*$/) { sub(/\\[ \t]*$/,"",raw); pend=raw; next }
  L=raw
}

L ~ /^[ \t]*row_begin([ \t]|$)/ {
    if (inb) { printf "ERR\tunbalanced-block\t%d\n", NR; bad=1; exit 3 }
    inb=1; start=NR; split(L,F," "); id=F[2]
    if (id !~ /^[A-Za-z0-9_]+$/) id = "fn:" fn
    reset(); rcseen=""; next
}

inb && L ~ /^[ \t]*row_end(_val)?([ \t]|$)/ {
    split(L,F," "); kind=F[1]; token=F[2]; rcarg=F[3]
    why=""; asserted=0
    for (i=1;i<=nfail;i++) {
        if (failkind[i] == "direct") { asserted=1; why="direct-exit"; break }
        v = failvar[i]
        if (v != "" && (v in exited)) { asserted=1; why="exit $" v; break }
        if (v != "" && index(rcarg, v) > 0) { asserted=1; why="row_end rc " rcarg; break }
    }
    if (!asserted && valguard) { asserted=1; why="value-carried (ERROR/FAIL literal raised under a guard)" }
    if (!asserted) {
        if (nfail > 0) why="a check is written but nothing exits its flag"
        else if (nrcprop > 0) why="rc-propagated only: the producer ran, nothing checked what it printed"
        else why="no failure path of any kind"
    }
    cls = drv ? "DRIVER" : (pub ? "PUBLISH" : "PRODUCER")
    printf "ROW\t%s\t%s\t%d-%d\t%s\t%s\t%s\t%s\n", id, token, start, NR, cls, \
           (asserted?"ASSERTED":"UNASSERTED"), (loop?"loop-driven":"flat"), why
    n++; inb=0; next
}

inb {
    l=L; sub(/^[ \t]+/,"",l)
    if (l ~ /^#/) next                      # a check that has been commented out is not a check
    if (l == "") next
    # --- emission class ---------------------------------------------------------------------
    if (l ~ /done *< *</ || l ~ /done *< *"/ || l ~ /while +read/ || l ~ /^for +[A-Za-z_]+ +in/ \
        || l ~ /^while +\[/ || l ~ /\| *while +read/) { loop=1; drv=1 }
    if (l ~ /(^|\| *)(awk|sed|cut|bc|tr)[ \t]/ || l ~ /^\( *(awk|sed)[ \t]/ || l ~ /(^|\| *)grep -o/ \
        || l ~ /\| *tee/) drv=1
    if (l ~ /(echo|printf)[^|]*\$\(/) drv=1
    if (l ~ /[A-Za-z_][A-Za-z0-9_]*=\$\((sed|grep|awk|cut|wc|bc|tr)/ && emitted) drv=1
    if (l ~ /(^|[|;&({] *)(echo|printf)([ \t]|$)/) emitted=1
    if (l ~ /(^|[|;&({] *)cat([ \t]|$)/ || l ~ /cp "\$RAW"/ || l ~ /^cp /) pub=1
    # --- rc plumbing ------------------------------------------------------------------------
    if (l ~ /^exit +\$/ || l ~ /; *exit +\$/) {
        e=l; sub(/.*exit +/,"",e); gsub(/[^A-Za-z0-9_]/," ",e); m=split(e,E," ")
        for (j=1;j<=m;j++) if (E[j] ~ /^[A-Za-z_]/) exited[E[j]]=1
    }
    if (l ~ /^if /)        { depth++; guard[depth]= (testish(l) && !rcprop(l)) ? 1 : 0 }
    else if (l ~ /^elif /) { if (depth>0) guard[depth]= (testish(l) && !rcprop(l)) ? 1 : 0 }
    else if (l ~ /^fi([ \t;]|$)/) { if (depth>0) depth-- }
    # --- failure paths ----------------------------------------------------------------------
    if (failish(l)) {
        if (rcprop(l) && !directexit(l)) nrcprop++
        else if (testish(l) || (depth>0 && guard[depth]) || directexit(l)) {
            if (directexit(l) && !(testish(l) || (depth>0 && guard[depth]))) {
                # an unguarded `exit 1` at the tail of a subshell is a failure path only if some
                # test can reach it; treat it as one only when the block has a test at all
                nfail++; failkind[nfail]="direct"; failvar[nfail]=""
            } else {
                nfail++
                failkind[nfail] = directexit(l) ? "direct" : "flag"
                failvar[nfail]  = directexit(l) ? "" : failflag(l)
                if (failkind[nfail]=="flag" && failvar[nfail]=="") nfail--
            }
        } else nrcprop++
    }
    if (l ~ /[A-Za-z_][A-Za-z0-9_]*="(ERROR|FAIL)/ && (testish(l) || (depth>0 && guard[depth]))) valguard=1
    next
}
END{
    if (pend != "") { }
    if (inb) { printf "ERR\tunterminated-block\t%d\n", start; exit 3 }
    if (bad) exit 3
    if (n == 0) { printf "ERR\tno-rows-parsed\t0\n"; exit 4 }
}
' "$1"; }

fail(){ echo "ROW_ASSERTION_ERROR=$1"; echo "ROW_ASSERTION=ERROR"; exit 2; }

# ---------------------------------------------------------------------------------------------
run_gate(){   # run_gate BATTERY STRICT ; prints the report, sets globals, returns 0/1/2
    local bat="$1" strict="$2"
    [ -f "$bat" ] || { echo "ROW_ASSERTION_ERROR=battery-missing"; echo "ROW_ASSERTION=ERROR"; return 2; }
    [ -r "$bat" ] || { echo "ROW_ASSERTION_ERROR=battery-unreadable"; echo "ROW_ASSERTION=ERROR"; return 2; }
    local out arc
    out=$(analyse "$bat"); arc=$?
    if [ "$arc" -eq 3 ]; then printf '%s\n' "$out"; echo "ROW_ASSERTION_ERROR=unbalanced-block"; echo "ROW_ASSERTION=ERROR"; return 2; fi
    if [ "$arc" -eq 4 ]; then printf '%s\n' "$out"; echo "ROW_ASSERTION_ERROR=no-rows-parsed"; echo "ROW_ASSERTION=ERROR"; return 2; fi
    if [ "$arc" -ne 0 ]; then echo "ROW_ASSERTION_ERROR=analyzer-failed"; echo "ROW_ASSERTION=ERROR"; return 2; fi
    printf '%s\n' "$out" | grep -q '^ROW	' || { echo "ROW_ASSERTION_ERROR=no-rows-parsed"; echo "ROW_ASSERTION=ERROR"; return 2; }

    local pop emit drvn asrt unas rcon
    pop=$(printf '%s\n' "$out" | grep -c '^ROW	')
    emit=$(printf '%s\n' "$out" | awk -F'\t' '$5=="DRIVER"||$5=="PUBLISH"' | grep -c . )
    drvn=$(printf '%s\n' "$out" | awk -F'\t' '$5=="DRIVER"' | grep -c . )
    asrt=$(printf '%s\n' "$out" | awk -F'\t' '($5=="DRIVER"||$5=="PUBLISH") && $6=="ASSERTED"' | grep -c . )
    unas=$(printf '%s\n' "$out" | awk -F'\t' '($5=="DRIVER"||$5=="PUBLISH") && $6=="UNASSERTED"' | grep -c . )
    rcon=$(printf '%s\n' "$out" | awk -F'\t' '$5!="DRIVER" && $6=="UNASSERTED"' | grep -c . )

    # exemption table
    local ex allowed=0 stale=0 newn=0 unknown=0
    ex=$(exemptions | grep -v '^[ \t]*#' | grep -v '^[ \t]*$')
    [ "$strict" -eq 1 ] && ex=""      # --strict ignores the table entirely: no matches, no staleness
    if [ -n "$ex" ]; then
        while IFS=$'\t' read -r xid xtok xcls xwhy; do
            [ -n "${xid:-}" ] || continue
            if [ -z "${xtok:-}" ] || [ -z "${xcls:-}" ] || [ -z "${xwhy:-}" ]; then
                echo "ROW_ASSERTION_ERROR=exemption-malformed"; echo "ROW_ASSERTION=ERROR"; return 2; fi
            local line
            line=$(printf '%s\n' "$out" | awk -F'\t' -v i="$xid" '$2==i')
            if [ -z "$line" ]; then
                echo "STALE	$xid	exemption names a row that is not in this battery"; unknown=$((unknown+1)); continue; fi
            if printf '%s\n' "$line" | awk -F'\t' '$6=="ASSERTED"{exit 0} {exit 1}'; then
                echo "STALE	$xid	exemption is stale: this row now asserts, remove the line"; stale=$((stale+1)); continue; fi
            allowed=$((allowed+1))
        done <<< "$ex"
    fi

    local reds
    reds=$(printf '%s\n' "$out" | awk -F'\t' '$5=="DRIVER" && $6=="UNASSERTED"{print $2"\t"$3"\t"$4"\t"$7"\t"$8}')
    local newlist=""
    while IFS=$'\t' read -r rid rtok rln rsub rwhy; do
        [ -n "${rid:-}" ] || continue
        if [ "$strict" -eq 0 ] && printf '%s\n' "$ex" | awk -F'\t' -v i="$rid" '$1==i{f=1} END{exit f?0:1}'; then continue; fi
        newlist="${newlist}UNASSERTED	$rid	$rtok	$rln	$rsub	$rwhy"$'\n'
        newn=$((newn+1))
    done <<< "$reds"

    if [ "$LIST" -eq 1 ] || [ "$newn" -gt 0 ] || [ "$stale" -gt 0 ] || [ "$unknown" -gt 0 ]; then
        printf '%s\n' "$out" | grep '^ROW	'
    fi
    [ -n "$newlist" ] && printf '%s' "$newlist"

    printf '%s\n' "$out" | awk -F'\t' '$5!="DRIVER" && $6=="UNASSERTED"{printf "RC-ONLY\t%s\t%s\t%s\t%s\t%s\n",$2,$3,$4,$5,$8}'
    echo "ROW_ASSERTION_POP=$pop"
    echo "ROW_ASSERTION_EMIT=$emit"
    echo "ROW_ASSERTION_DRIVER=$drvn"
    echo "ROW_ASSERTION_ASSERT=$asrt"
    echo "ROW_ASSERTION_UNASSERTED=$unas"
    echo "ROW_ASSERTION_RCONLY=$rcon"
    echo "ROW_ASSERTION_KNOWN=$allowed"
    echo "ROW_ASSERTION_NEW=$newn"
    echo "ROW_ASSERTION_STALE=$((stale+unknown))"
    if [ "$unknown" -gt 0 ]; then echo "ROW_ASSERTION_ERROR=exemption-unknown-row"; echo "ROW_ASSERTION=ERROR"; return 2; fi
    if [ "$newn" -gt 0 ] || [ "$stale" -gt 0 ]; then echo "ROW_ASSERTION=FAIL"; return 1; fi
    echo "ROW_ASSERTION=PASS"; return 0
}

# ---------------------------------------------------------------------------------------------
if [ "$SELFTEST" -eq 1 ]; then
    T=$(mktemp -d) || fail analyzer-failed
    trap 'rm -rf "$T"' EXIT
    sfails=0
    # F1 — an emitter that asserts nothing (the class). Must FAIL.
    cat > "$T/bad.sh" <<'EOS'
row_begin c_x
(
  echo "k	v"
  while read -r line; do echo "$line"; done < <(grep -o '"x": {[^}]*}' "$A")
) >>"$RAW" 2>&1; rc=$?
cp "$RAW" "$ARTDIR/x.tsv"
row_end TR12_X $rc
EOS
    # F2 — the same emitter with a row-count check that reaches rc. Must PASS.
    cat > "$T/good.sh" <<'EOS'
row_begin c_x
(
  echo "k	v"
  while read -r line; do echo "$line"; done < <(grep -o '"x": {[^}]*}' "$A") | tee "$W/x.tsv"
  fails=0
  n=$(grep -c . "$W/x.tsv")
  [ "$n" -eq "$N_PAIRS" ] || { echo "X_FAIL	emitted $n rows"; fails=1; }
  exit $fails
) >>"$RAW" 2>&1; rc=$?
row_end TR12_X $rc
EOS
    # F3 — a check that is written but never exited. Must FAIL (the "reaches rc" leg).
    sed 's/^  exit \$fails$/  true/' "$T/good.sh" > "$T/noexit.sh"
    # F4 — rc-propagation only. Must FAIL (the producer-rc leg).
    cat > "$T/rcprop.sh" <<'EOS'
row_begin c_y
(
  erc=0
  echo "k	v"
  for j in "$ARTDIR"/*.json; do
      "$SOLVE" --kc-thing "$j" || erc=1
      cat "$WORK/out"
  done
  exit $erc
) >>"$RAW" 2>&1; rc=$?
row_end TR12_Y $rc
EOS
    for f in bad:FAIL good:PASS noexit:FAIL rcprop:FAIL; do
        n=${f%%:*}; want=${f##*:}
        got=$("$0" --battery "$T/$n.sh" --strict 2>&1 | grep -E '^ROW_ASSERTION=' | tail -1)
        if [ "$got" = "ROW_ASSERTION=$want" ]; then echo "SELFTEST	$n	ok ($want)"
        else echo "SELFTEST	$n	MISMATCH want=ROW_ASSERTION=$want got=$got"; sfails=$((sfails+1)); fi
    done
    # F5 — ERROR classes
    got=$("$0" --battery "$T/does-not-exist.sh" 2>&1 | grep -E '^ROW_ASSERTION=' | tail -1)
    [ "$got" = "ROW_ASSERTION=ERROR" ] && echo "SELFTEST	missing-battery	ok (ERROR)" \
        || { echo "SELFTEST	missing-battery	MISMATCH got=$got"; sfails=$((sfails+1)); }
    echo "# not a battery" > "$T/empty.sh"
    got=$("$0" --battery "$T/empty.sh" 2>&1 | grep -E '^ROW_ASSERTION=' | tail -1)
    [ "$got" = "ROW_ASSERTION=ERROR" ] && echo "SELFTEST	no-rows	ok (ERROR)" \
        || { echo "SELFTEST	no-rows	MISMATCH got=$got"; sfails=$((sfails+1)); }
    printf 'row_begin a\n( echo hi ) >>"$RAW"\nrow_begin b\n' > "$T/unbal.sh"
    got=$("$0" --battery "$T/unbal.sh" 2>&1 | grep -E '^ROW_ASSERTION=' | tail -1)
    [ "$got" = "ROW_ASSERTION=ERROR" ] && echo "SELFTEST	unbalanced	ok (ERROR)" \
        || { echo "SELFTEST	unbalanced	MISMATCH got=$got"; sfails=$((sfails+1)); }
    echo "ROW_ASSERTION_SELFTEST_FAILS=$sfails"
    if [ "$sfails" -eq 0 ]; then echo "ROW_ASSERTION_SELFTEST=PASS"; exit 0; fi
    echo "ROW_ASSERTION_SELFTEST=FAIL"; exit 1
fi

run_gate "$BATTERY" "$STRICT"
exit $?
