#@ scripts/doc_gates.d/10_numbers_cli_citations.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATE 1 (numbers), GATE 2 incl. 2c (cli), citation-lines.
#@ Lines 765-1144 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ----------------------------------------------------------------------------------
gate_numbers() {
  echo "== GATE 1: cross-file numeric consistency (long integers) =="
  # Extract integers of >=12 digits (commas stripped). Group by their first 10 digits.
  # A group holding more than one DISTINCT full value means two docs disagree about
  # what is almost certainly the same quantity (e.g. a single corrupted digit).
  # Key = (length, first 10 digits). SAME LENGTH matters: a corrupted digit preserves
  # length, whereas 10^11 vs 10^12 are simply different budgets, not a disagreement.
  # Round numbers (>=4 trailing zeros) are budgets/powers of ten — skipped.
  # Report-only ([WARN]) with an allowlist, because legitimately-close pairs exist
  # (e.g. a byte count with and without the 32-byte header).
  # 🔴 Q-283 / Codex N10 finding 3 — EXECUTABLE FALSE CLEAR, reproduced on origin/main
  # 2026-08-27. This was `tmp=$(mktemp)` UNCHECKED: when mktemp fails (read-only or
  # restricted TMPDIR) $tmp is EMPTY, every write to it fails, the reads that follow find
  # nothing, and the gate emits its clean message having examined nothing at all. Measured
  # under TMPDIR pointed at a mode-500 directory: GATES 3 and 22, which DO check their
  # mktemp, correctly went [FAIL] while GATES 1 and 20 emitted [ok] on the same condition.
  # Report-only refers to a gate's FINDINGS being advisory; it does not make its ability to
  # RUN optional. A check that cannot run must ERROR, never emit [ok].
  local tmp allow
  tmp=$(mktemp) || { echo "  [FAIL] GATE 1: mktemp failed, so NOTHING was checked."; return 1; }
  allow="documentation/DOC_GATE_NUMBER_ALLOWLIST.txt"
  for f in $DOCS; do
    grep -oE '[0-9][0-9,]{11,}' "$f" 2>/dev/null | tr -d ',' \
      | awk -v F="$f" 'length($0)>=12 && $0 !~ /0000$/ {print length($0)":"substr($0,1,10)"\t"$0"\t"F}'
  done | sort -u > "$tmp"

  local found=0
  while read -r key; do
    [ -z "$key" ] && continue
    if [ -f "$allow" ] && grep -qxF -- "$key" "$allow" 2>/dev/null; then continue; fi
    echo "  [WARN] near-twin long integers (same length, same 10-digit prefix) — key $key:"
    awk -v K="$key" -F'\t' '$1==K {print "      "$2"   <- "$3}' "$tmp" | sort -u
    found=1
  done < <(cut -f1,2 "$tmp" | sort -u | cut -f1 | uniq -d)

  if [ "$found" -eq 0 ]; then
    echo "  [ok] no long integer disagrees with a same-length near-twin elsewhere"
  else
    echo "  (report-only: confirm each pair is intentional, then add its key to $allow)"
  fi
  rm -f "$tmp"
  return 0   # report-only gate — never blocks
}

# ----------------------------------------------------------------------------------
gate_cli() {
  echo "== GATE 2: CLI flags live in code but undocumented =="
  local bad=0
  check_pair() { # $1=code file  $2=doc file  $3=extractor
    local code="$1" doc="$2" mode="$3" cf df miss rcc=0 rcd=0
    # ITEM A1. Both sides are probed before either verdict, so a run that lost both prints
    # both names; a single `&&` chain would hide the second. A deleted CLI doc used to make
    # this pair vanish from the gate entirely — the flags it documented then went unchecked
    # while the run stayed green.
    require_tracked "$code" "Delete a source file and every flag it declares stops being checked." || rcc=$?
    require_tracked "$doc"  "Delete a CLI doc and its pair stops being checked, silently." || rcd=$?
    if [ "$rcc" -eq 2 ] || [ "$rcd" -eq 2 ]; then bad=1; return 0; fi
    if [ "$rcc" -ne 0 ] || [ "$rcd" -ne 0 ]; then return 0; fi
    # 🔴 Q-283 / Codex N10 finding 3 — the same false-clear shape, and this one is WORSE
    # because GATE 2 is BLOCKING, so it can clear a push. Reproduced: it printed
    #   [ok] roae.py fully documented in ... ( flag(s) compared against  documented, ...)
    # with the counts BLANK, because it compared zero flags against zero documentation. The
    # gate's own message carried the proof it had examined nothing, and nothing read it.
    # Do not leak cf if df is the one that fails.
    # Q-748 (a) (V3A-111#2, Fable R code-read; demonstrated 2026-09-24 by Opus FF): these two
    # branches did `return 1` WITHOUT bad=1, and every check_pair caller below ignores its
    # status, so under TMPDIR=/dev/null all five pairs printed [FAIL] ... NOTHING was checked
    # while the gate returned 0 and the run printed `DOC GATES: PASS  (cli)`. The printed FAIL
    # was decoration. bad=1 is what the gate's verdict reads, so it is set here, in BOTH branches.
    cf=$(mktemp) || { echo "  [FAIL] GATE 2: mktemp failed, so NOTHING was checked."; bad=1; return 1; }
    df=$(mktemp) || { rm -f "$cf"; echo "  [FAIL] GATE 2: mktemp failed, so NOTHING was checked."; bad=1; return 1; }
    # ITEM A4 (2026-08-02) — DECIDED: NARROW, and here is the decision rather than a
    # rediscovery of the question. The extractor is a line-based grep, so a COMMENTED-OUT
    # declaration was emitted as an undocumented flag. MEASURED while writing item A3's
    # fire-proof: run against a comment line it returned `--commented-out-flag`. Nothing had
    # triggered it, so it was a latent false positive, and the round-6 note recorded it as
    # "decide, do not rediscover".
    #
    # WHY NARROW AND NOT ACCEPT. The first person to comment out a flag would have been
    # handed a RED gate with a correct-looking finding and no way to satisfy it except by
    # documenting a flag that does not exist. A gate whose remedy is to write a false
    # sentence into a CLI doc is worse than no gate.
    #
    # THE DIRECTION OF FAILURE IS THE REASON THIS IS SAFE. The comparison is `comm -23`
    # (code minus doc) and nothing else, so dropping lines from the CODE side can only
    # SUPPRESS a finding, never manufacture one. The cost is stated rather than waved away:
    # if a flag is declared on a commented line but still parsed somewhere else, GATE 2 now
    # stops reporting it. That is a real, remote loss, accepted deliberately.
    #
    # WHAT THIS FILTER CANNOT SEE: a flag inside a C block comment (`/* ... */`) spanning
    # lines, a flag in a docstring or other string literal, and a declaration sharing a line
    # with a trailing comment that itself names a second flag. Whole-line `#` and `//`
    # comments are all it removes.
    # BOTH QUOTE STYLES (2026-08-11, defect 6's fix). The py extractor read
    # `add_argument("--...` and NOTHING ELSE for its whole life, so it was blind to a file
    # that quotes with apostrophes. That is not hypothetical: verify.py declares all 19 of its
    # flags as `add_argument('--...` and the double-quote-only extractor returned ZERO of
    # them — measured, which is why verify.py could not simply be added as a fifth pair.
    # WIDENING THE CODE SIDE IS THE DANGEROUS DIRECTION (the comparison is `comm -23`, code
    # minus doc, so a flag added here can MANUFACTURE a finding), so it was measured before it
    # was written rather than argued: roae.py 59 double-quoted / 0 single-quoted, solve.py
    # 78 / 0, verify.py 0 / 19. The two live py pairs contain no apostrophe-quoted declaration
    # at all, so this widening adds exactly zero flags to either and cannot move their census.
    # The flag is re-extracted by a second grep instead of `sed 's/.*"//'`, which could only
    # ever strip one of the two quote characters.
    if [ "$mode" = py ]; then
      grep -vE '^[[:space:]]*(#|//)' "$code" \
        | grep -oE 'add_argument\(("|'"'"')--[a-z0-9][a-z0-9_-]*' \
        | grep -oE -- '--[a-z0-9][a-z0-9_-]*' | sort -u > "$cf"
    else
      grep -vE '^[[:space:]]*(#|//)' "$code" \
        | grep -oE '"--[a-z0-9][a-z0-9-]*"' | tr -d '"' | sort -u > "$cf"
    fi
    grep -oE -- '--[a-z0-9][a-z0-9_-]*' "$doc" | sort -u > "$df"
    miss=$(comm -23 "$cf" "$df")
    # THE PASS LINE CARRIES A CENSUS (item B9, round 9, 2026-08-02). It did not, and the
    # consequence was measured rather than supposed: GATE 2's two negative controls could
    # only ever pin `solve.py fully documented`, a sentence that is printed whenever the leg
    # RUNS. No ERE over a countless pass line can tell "the classifier read my injection and
    # correctly ignored it" from "the classifier never looked". Three numbers fix that, and
    # each is chosen so that one of the two controls MOVES it:
    #   flags     — the extracted code-side set. The "flag added to BOTH" control adds one
    #               declaration and one doc line, so this moves; that leg's ERE now pins the
    #               POST-injection value and fails if the file was not re-read.
    #   documented— the doc-side set, which moves with it.
    #   commented — declarations on whole-line comments, which the item-A4 filter DROPS. The
    #               "SAME declaration commented out" control adds exactly one of these, so it
    #               moves this number while leaving the other two fixed. That is the A4
    #               property made visible: the line was seen AND classified as a comment,
    #               which a flags count alone cannot distinguish from never reading it.
    local ncode ndoc ncmt
    ncode=$(wc -l < "$cf"); ndoc=$(wc -l < "$df")
    if [ "$mode" = py ]; then
      ncmt=$(grep -E '^[[:space:]]*(#|//)' "$code" \
             | grep -oE 'add_argument\(("|'"'"')--[a-z0-9][a-z0-9_-]*' \
             | grep -oE -- '--[a-z0-9][a-z0-9_-]*' | sort -u | wc -l)
    else
      ncmt=$(grep -E '^[[:space:]]*(#|//)' "$code" \
             | grep -oE '"--[a-z0-9][a-z0-9-]*"' | sort -u | wc -l)
    fi
    if [ -n "$miss" ]; then
      echo "  [FAIL] in $code but NOT in $doc:"; echo "$miss" | sed 's/^/      /'; bad=1
    else
      echo "  [ok] $code fully documented in $doc ($ncode flag(s) compared against $ndoc" \
           "documented, $ncmt commented-out declaration(s) dropped)"
    fi
    rm -f "$cf" "$df"
  }
  check_pair roae.py  documentation/ROAE_PY_CLI.md  py
  check_pair solve.py documentation/SOLVE_PY_CLI.md py
  check_pair solve.c  documentation/SOLVE_C_CLI.md  c
  # sat.py hand-rolls sys.argv parsing with literal quoted flag strings, so the
  # C-mode extractor applies verbatim (verified 2026-08-01: passes).
  check_pair sat.py   documentation/SAT_CLI.md      c
  # verify.py — WIRED 2026-08-11 (defect 6). It was outside this gate entirely from the day
  # the independence exception created it (CLAUDE.md §"The INDEPENDENCE exception"), so the
  # one file whose whole purpose is to be an INDEPENDENT check of published results had no
  # check that its own CLI was documented. It gained three flags (--t3-stats,
  # --t3-membership, --g-structure, plus --t3-membership-limit) the same week this was
  # noticed, which is the drift GATE 2 exists for.
  #
  # MEASURED BEFORE WIRING, on BOTH the committed tree at a23d82a9 and the tree carrying the
  # uncommitted verify.py/VERIFY.md work: `comm -23` of the extracted code side against the
  # doc side is EMPTY in both cases (15 flags then, 19 now, all documented). A gate wired on
  # top of pre-existing undocumented flags would be a red pre-push hook for everybody until
  # someone else's backlog was written, which is why the measurement came first and why the
  # result is recorded rather than the intention.
  #
  # THE PAIR IS py MODE, which required widening the py extractor to apostrophe-quoted
  # declarations — see the extractor above for the measurement that widening is safe for the
  # two pairs that already existed.
  check_pair verify.py documentation/VERIFY.md      py

  # ---- LEG: a documented flag's ARGUMENT GRAMMAR must match the one the binary prints -------
  # Q-410. GATE 2 above compares the SET OF FLAG NAMES and it works -- it is what caught
  # --kc-g-check-layer and --kc-g-status. But a flag can be present and its DESCRIPTION or
  # SIGNATURE wrong, and nothing checked that. Measured 2026-09-07: --kc-oracle printed
  # "Usage: solve --kc-oracle FDIR BIN [BIN...]" and SOLVE_C_CLI.md had NO section for it at all
  # -- only prose mentions plus a section for the neighbouring --kc-oracle-selftest -- so GATE 2
  # passed on the name while the grammar was undocumented. --validate-canonical documented
  # <expected-sha256> where the binary says <expected-sha256-64-hex>, dropping the constraint.
  #
  # The binary's own Usage: string is the cheapest oracle available. This leg compares ARGUMENT
  # TOKENS, not the line verbatim: measured, only 25 of 35 literal usage strings appear verbatim
  # in the doc, and the other 10 differ by rendering alone. A verbatim rule would have shipped
  # red at 10 sites and been ignored by the next morning -- the Q-199 defect adopted as policy.
  if [ -r solve.c ] && [ -r documentation/SOLVE_C_CLI.md ]; then
    _ua=$(python3 - <<'PYEOF'
import re,sys
src=open("solve.c",encoding="utf-8",errors="replace").read()
doc=open("documentation/SOLVE_C_CLI.md",encoding="utf-8",errors="replace").read()

# ---- THE EXTRACTOR ------------------------------------------------------------------------
# Q-410 FOLLOW-UP, 2026-09-07 — THIS LEG USED TO FAIL OPEN, on its own defect class.
# It read:   re.findall(r'"Usage: ([^"\\]*)', src)
# `[^"\\]` stops at the first BACKSLASH, and a C usage string that documents a QUOTED operand
# spells it \" -- so every such grammar was silently TRUNCATED at the operand the gate existed
# to compare. MEASURED before the fix, on this tree: `--kc-member` extracted as
# `solve --kc-member DIR ` and the "e,x,..." operand was never compared at all; `--kc-repr`
# lost [--kc-c3-max T]; `--check-arrangement` lost "h0,h1,...,h63"|KW [--cert-out FILE]. The
# same class-blindness applied to C ADJACENT STRING-LITERAL CONCATENATION ("Usage: ..." "..."
# across two source lines), which `[^"\\]*` ends at the first closing quote: that truncated
# --f1-exact-c1c2c4, --f1-exact-c1c2, --f1-exact-c1c2c4c5, --f1-c3-hist and --kc-sample.
# TWELVE of the 35 literal grammars were truncated. The leg still printed [ok] on all of them,
# because a truncated grammar has fewer argument tokens to find and every remaining one was
# present -- a shorter needle in a 192 KB haystack is a WEAKER test that looks like the same
# test. A gate written for Q-410 could not see the Q-410 defect on a third of its population.
#
# The fix is a real C string-literal scanner: walk the literal honouring \\-escapes, absorb any
# adjacent literals, then unescape. MEASURED, and this is the evidence the fix worked -- the
# count of ARGUMENT TOKENS actually compared against the document went UP:
#     before  34 flags, 110 argument tokens compared
#     after   34 flags, 147 argument tokens compared     (+37, +34%)
# and `bad` stayed 0, so the wider comparison is not paid for with a red gate. ARG_FLOOR below
# pins that number: reintroduce the truncating regex and the leg drops to 110 and FAILS LOUDLY
# instead of quietly comparing less.
def _lit_at(s,i):
    """s[i] is the opening quote. Returns (raw body with escapes intact, index past the close)."""
    j=i+1; out=[]
    while j < len(s):
        c=s[j]
        if c=='\\': out.append(s[j:j+2]); j+=2; continue
        if c=='"':  return "".join(out), j+1
        out.append(c); j+=1
    return "".join(out), j
_ESC={'n':'\n','t':'\t','r':'\r','\\':'\\','"':'"',"'":"'"}
def _unesc(b): return re.sub(r'\\(.)', lambda m:_ESC.get(m.group(1),m.group(1)), b)
def _usages():
    out=[]
    for m in re.finditer(r'"Usage: ', src):
        body,k=_lit_at(src,m.start())
        while True:                                  # C adjacent-literal concatenation
            m2=re.match(r'\s*"', src[k:])
            if not m2: break
            b2,k2=_lit_at(src, k+m2.end()-1); body+=b2; k=k2
        # The GRAMMAR is the first physical line; the rest of the literal is prose description.
        out.append(_unesc(body)[len("Usage: "):].split("\n")[0].strip())
    return sorted(set(out))

us=_usages()
lit=[u for u in us if "%s" not in u]
FLOOR=25
ARG_FLOOR=140
if len(lit) < FLOOR:
    print(f"ERROR only {len(lit)} literal usage string(s) extracted, floor {FLOOR}"); sys.exit(0)

# ---- LEG A: every argument token of a documented flag's grammar must appear in the doc -------
bad=[]; ntok=0
for u in lit:
    toks=u.split()
    f=next((t for t in toks if t.startswith("--")), None)
    if not f or f not in doc: continue
    args=[a for a in toks[toks.index(f)+1:] if a.strip("[]<>.")]
    ntok+=len(args)
    missing=[a for a in args if a.strip("[]<>.") not in doc]
    if missing: bad.append(f"{f} -> doc never shows {missing}")
if ntok < ARG_FLOOR:
    print(f"ERROR only {ntok} argument token(s) compared, floor {ARG_FLOOR} -- the extractor is"
          f" truncating grammars again (the pre-2026-09-07 fail-open); NOTHING useful was compared")
    sys.exit(0)

# ---- LEG B: the CONTIGUOUS grammar, as a RATCHET ---------------------------------------------
# LEG A is weak in a second, independent way, and it was measured rather than argued: it asks
# only whether each token appears SOMEWHERE in a 192 KB document. `DIR`, `FDIR`, `GDIR`,
# `OUT.json` occur in dozens of unrelated places, so for many flags LEG A is very nearly free --
# a flag can print a full Usage: grammar the document never shows anywhere and LEG A still says
# [ok]. MEASURED 2026-09-07 with the repaired extractor: FIVE flags are in exactly that state.
# It is NOT flipped on as a hard check, for the reason recorded above this function (Q-199): a
# rule that ships red at five sites is a rule read by nobody by the next morning. It ships as a
# RATCHET on the same pattern as GATE 18 and scripts/gate_published_consistency.pin -- the five
# are named, and no SIXTH may be added. A count that FALLS is announced so the pin comes down in
# the same change. The five are KNOWN-OPEN, not acceptable: each needs the document to gain a
# grammar line, which is documentation/ lane work.
WEAK_KNOWN={"--branch","--f1c5-sidecar-retrofit","--kc-ladder-verify","--kc-sample","--kc-scan"}
_nd=re.sub(r'\s+',' ',doc)
weak=[]
for u in lit:
    toks=u.split()
    f=next((t for t in toks if t.startswith("--")), None)
    if not f or f not in doc: continue
    args=toks[toks.index(f)+1:]
    if not args: continue
    if re.sub(r'\s+',' ',f+" "+" ".join(args)).strip() not in _nd: weak.append(f)
print(f"COUNT {len(lit)}")
print(f"ARGS {ntok}")
for b in bad: print("BAD "+b)
for w in sorted(set(weak)-WEAK_KNOWN): print("WEAKNEW "+w)
print(f"WEAK {len(weak)}")
if len(weak) < len(WEAK_KNOWN):
    print(f"WEAKREPIN {len(weak)} of {len(WEAK_KNOWN)}")
PYEOF
)
    # `$_ua` is CAPTURED first and matched from the variable. Never `python3 ... | grep -q`:
    # grep -q exits at the first match, the producer dies of SIGPIPE, and under `set -o pipefail`
    # the pipeline status is 141 -- so a MATCH would read as NO MATCH and this leg would fail open
    # a second time, in a second way.
    if grep -q '^ERROR' <<<"$_ua"; then
      echo "  [FAIL] GATE 2 usage-grammar leg: $(printf '%s\n' "$_ua" | sed -n 's/^ERROR //p')"
      echo "         The extractor is broken, so NOTHING was compared."; bad=1
    else
      _n=$(printf '%s\n' "$_ua" | sed -n 's/^COUNT //p')
      _a=$(printf '%s\n' "$_ua" | sed -n 's/^ARGS //p')
      _b=$(printf '%s\n' "$_ua" | grep -c '^BAD ')
      _wn=$(printf '%s\n' "$_ua" | grep -c '^WEAKNEW ')
      _w=$(printf '%s\n' "$_ua" | sed -n 's/^WEAK //p')
      if [ "${_b:-0}" -gt 0 ]; then
        echo "  [FAIL] $_b flag(s) whose printed grammar the doc does not show:"
        printf '%s\n' "$_ua" | sed -n 's/^BAD /      /p'; bad=1
      else
        echo "  [ok] all $_n literal Usage: grammar(s) in solve.c are reflected in SOLVE_C_CLI.md"
        echo "       ($_a argument tokens compared; the pre-2026-09-07 truncating extractor compared 110)"
      fi
      # LEG B ratchet. A SIXTH flag printing a grammar the doc never shows is a FAIL; the five
      # standing ones stay named and visible instead of being waved through.
      if [ "${_wn:-0}" -gt 0 ]; then
        echo "  [FAIL] $_wn flag(s) NEWLY printing a contiguous Usage: grammar the doc never shows:"
        printf '%s\n' "$_ua" | sed -n 's/^WEAKNEW /      /p'
        echo "         Add the grammar line to documentation/SOLVE_C_CLI.md, or extend WEAK_KNOWN"
        echo "         in this leg with a written reason."; bad=1
      else
        echo "  [ok] contiguous-grammar ratchet: ${_w:-0} known-open, none new"
        printf '%s\n' "$_ua" | sed -n 's/^WEAKREPIN /      [repin] contiguous-grammar known-open fell to /p'
      fi
    fi
  fi

  # ---- LEG: a documented flag's DECLARED METADATA must match its argparse declaration ----------
  # Q-410, the last leg (batch 32, 2026-10-02). solve.py, roae.py and verify.py print no Usage:
  # strings, so the usage-grammar leg above has nothing to read for them; their oracle is the
  # add_argument declaration. scripts/cli_decl_metadata_gate.sh reads every declaration with `ast`
  # and checks each default, choice list and argument count that SOLVE_PY_CLI.md, ROAE_PY_CLI.md
  # and VERIFY.md STATE against it, with three in-memory positive controls on every run. It is a
  # separate script so that its red test can run on a scratch copy; this is the dispatch. Judged on
  # its whole-line token, captured first (never `producer | grep -q`, see the leg above).
  echo "  -- declaration-metadata leg (scripts/cli_decl_metadata_gate.sh)"
  if [ ! -r scripts/cli_decl_metadata_gate.sh ]; then
    echo "  [FAIL] scripts/cli_decl_metadata_gate.sh missing — the declaration-metadata leg checked NOTHING"; bad=1
  else
    _dm=$(bash scripts/cli_decl_metadata_gate.sh 2>&1)
    sed -n '/^  \[/p; /^         /p' <<<"$_dm"
    if ! grep -qx 'CLI_DECL_METADATA=PASS' <<<"$_dm"; then
      grep -qxE 'CLI_DECL_METADATA=(FAIL|ERROR)' <<<"$_dm" \
        || echo "  [FAIL] the declaration-metadata leg printed no verdict token — treated as FAIL"
      bad=1
    fi
  fi

  return $bad


}

# ----------------------------------------------------------------------------------
# GATE 2c — CITATION LINE INTEGRITY (2026-09-07). documentation/SOLVE_C_CLI.md carries ~100
# hand-maintained `solve.c:NNNNN` line citations into a 44,000-line file under continuous edit.
# GATE 2 above checks that a flag is NAMED and (usage leg) that its GRAMMAR is shown; nothing
# checked that a citation still POINTS AT the code it claims. MEASURED 2026-09-07: all 38
# citations in the `--kc-*` tables had drifted, with non-uniform offsets (+3229, +3655, +4749),
# i.e. accumulated across several restructurings — so no bulk shift could repair them and no
# reviewer checking one could infer the rest. The implementation and its ratchet live in
# scripts/citation_line_gate.sh (verdict token CITATION_LINE_GATE=PASS|FAIL|ERROR); this is the
# dispatch wrapper. It is a SEPARATE SCRIPT because it must be runnable, and red-testable, on an
# arbitrary (doc, source) pair via CITGATE_DOC / CITGATE_SRC — which is how its both-directions
# red-test is built, and which a function reading fixed paths inside this file could not offer.
gate_citation_lines() {
  echo "== GATE 2c: solve.c line citations must land on the symbol they name =="
  if [ ! -x scripts/citation_line_gate.sh ]; then
    echo "  [FAIL] scripts/citation_line_gate.sh missing or not executable — NOTHING was measured"
    return 1
  fi
  # CAPTURE, then match — and match from a HERE-STRING, which has no producer process at all.
  # `producer | grep -q` is the trap: grep -q exits at the first match, the producer takes
  # SIGPIPE, and under `set -o pipefail` the pipeline status is 141, so a MATCH reads as NO
  # MATCH. That is the same fail-open shape as the truncating regex this gate family just
  # removed, and a `printf` builtin only escapes it by accident of pipe-buffer size.
  # THREE runs, each judged on its own token (Q-786, 2026-09-25): the SOLVE_C_CLI.md mode (the
  # original gate, unchanged); `--all-files`, every tracked text file's `solve.c:N` citations
  # (LEG A shift map against $CITGATE_BASE, default HEAD; LEG B anchor ratchet); and the gate's
  # own `--selftest`, so a mutant of the gate (a disabled comparison) turns THIS gate red rather
  # than silently passing everything. A FOURTH run (Q-791, 2026-09-25): `--all-files --all-targets`,
  # the same two legs over `<file>:N` citations into EVERY tracked file, not only solve.c -- one
  # batch had left 88 of them behind, none of which the solve.c-only run could see.
  local _out _rc _mode _bad=0
  for _mode in "" --all-files "--all-files --all-targets" --selftest; do
    _out=$(bash scripts/citation_line_gate.sh $_mode 2>&1); _rc=$?
    [ -n "$_mode" ] && echo "  -- citation_line_gate.sh $_mode"
    sed -n '/^  \[/p' <<<"$_out"
    if grep -qx 'CITATION_LINE_GATE=PASS' <<<"$_out"; then
      continue
    fi
    _bad=1
    if grep -qx 'CITATION_LINE_GATE=ERROR' <<<"$_out"; then
      echo "  [FAIL] GATE 2c ${_mode:-(SOLVE_C_CLI.md)} measured NOTHING (ERROR verdict) — this is not agreement"
    elif ! grep -qx 'CITATION_LINE_GATE=FAIL' <<<"$_out"; then
      echo "  [FAIL] GATE 2c ${_mode:-(SOLVE_C_CLI.md)} produced no verdict token at all (rc=$_rc) — treated as FAIL"
    fi
  done
  return $_bad
}

