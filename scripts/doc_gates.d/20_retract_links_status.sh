#@ scripts/doc_gates.d/20_retract_links_status.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATE 3 (retract), 3b (retract-figures), 4 + 4b (links, secrefs), 5 + 5b (status).
#@ Lines 1211-2352 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
gate_retract() {
  echo "== GATE 3: retracted phrasings still surviving =="
  # Registry-driven and deliberately so: auto-parsing retraction prose is unreliable,
  # and a wrong gate is worse than none. Each entry is a FIXED string that was retracted;
  # the gate fails if it appears anywhere outside the file allowed to narrate the retraction.
  #
  # HARDENED 2026-08-01 after this gate missed a LIVE survivor two ways at once
  # (SOLVE_SUMMARY.md still carried the retracted conflict-theorem scope):
  #   (a) line-break evasion — the phrase spanned a hard wrap, so line-based `git grep -F`
  #       could not see it. FIX: whitespace-normalise each file to a single line first.
  #   (b) morphology evasion — the registry held "preserving…" while the survivor said
  #       "preserves…". FIX: register the morphology-independent STEM (and add variants).
  #   (c) allow-column over-reach — matching the allow string anywhere on the line exempted
  #       too much. FIX: the allow column now matches the FILENAME only.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  require_rows "documentation/RETRACTED_PHRASES.tsv" "Zero rows silences every retraction check." || return 1
  # ITEM A1: the registry IS this gate. Skipping on its absence reported PASS for a gate
  # that had checked nothing at all.
  require_tracked "$reg" "The retraction registry IS this gate; with it gone, zero phrases are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  local bad=0
  # EVIDENCE EXTENSION (2026-08-07). The TRs quote reports/evidence/** measurement outputs
  # (.out, .json, .log, ...), and until today only the *.md half of that directory was in
  # this gate's corpus — the retracted "1.4σ" was caught ONLY because it happened to sit in
  # an evidence .md (r11/PHASE2_README.md). The non-markdown evidence files now run the
  # same fold+normalise+fixed-string pipeline. MEASURED at extension time: 54 files, 5.7 MB
  # (five ~940 KB r5 subtree logs dominate), 0 hits across all 21 registered phrases.
  # Filtered with a bash case, not a pattern — zero regex, per the SAFETY rule above.
  local evid="" ef evn efloor=120   # Q-708 (2026-09-25): the non-md evidence population gets a receipt and a floor below. Measured 155 files that day; 120 leaves room to retire ~35 without an edit here. Before this, a git mv of reports/evidence emptied $evid and the half ran on nothing at rc 0.
  for ef in $(git ls-files 'reports/evidence/*' || true); do
    case "$ef" in *.md) ;; *) evid="$evid $ef";; esac
  done; evn=$(printf '%s\n' $evid | grep -c .); echo "GATE3_EVIDENCE_COUNT=$evn"; [ "$evn" -ge "$efloor" ] || { echo "  [FAIL] GATE 3 evidence half: $evn non-md file(s) tracked under reports/evidence/, floor $efloor. A moved, renamed or emptied evidence tree leaves this half checking nothing."; bad=1; }
  # Pre-fold every doc ONCE (fold_variants above), then run the same normalise+match
  # pipeline against the folded copies. Folding per (phrase, file) pair would spawn
  # |phrases| x |DOCS| ~ 2,700 extra sed processes; folding per file is |DOCS| ~ 130.
  # COST: one sed pass per tracked .md (~130 processes, each over a ~500-line file)
  # plus the same grep counts as before, over the folded copies.
  #
  # The EVIDENCE corpus gets a different shape, and the reason is measured: running the
  # per-(phrase, file) tr|tr|grep pipeline over 54 more files — five of them ~940 KB —
  # adds |phrases| x |evid| = 1,134 three-process pipelines re-streaming 5.7 MB per
  # phrase (first cut measured 13.2 s for the whole gate, vs 4.8 s markdown-only,
  # 2026-08-07 — partly concurrent-load-polluted, but the shape is wrong regardless).
  # So each evidence file is folded AND flattened (newline->space, runs collapsed) ONCE,
  # into $flatevdir, and each phrase then makes a SINGLE `grep -rlF` pass over that
  # directory: 21 fixed-string scans of 5.7 MB at C speed.
  # COST: 2 extra processes per evidence file at fold time (~108), then |phrases| = 21
  # recursive greps. Measured on the idle 2-core orchestrator, 2026-08-07: 4.8 s
  # markdown-only -> 5.2 s with the extension. The match rule is IDENTICAL to the DOCS
  # half — same folded bytes, same whitespace normalisation, same fixed-string needle —
  # only the process orchestration differs.
  local folddir flatevdir flatdocdir f
  folddir=$(mktemp -d "${TMPDIR:-/tmp}/docgates_fold.XXXXXX") || { echo "  [FAIL] mktemp failed"; return 1; }
  flatevdir=$(mktemp -d "${TMPDIR:-/tmp}/docgates_flatev.XXXXXX") || { echo "  [FAIL] mktemp failed"; rm -rf "$folddir"; return 1; }
  flatdocdir=$(mktemp -d "${TMPDIR:-/tmp}/docgates_flatdoc.XXXXXX") || { echo "  [FAIL] mktemp failed"; rm -rf "$folddir" "$flatevdir"; return 1; }
  for f in $DOCS; do
    [ -f "$f" ] || continue        # a tracked-but-deleted doc is preflight_tracked_docs' finding
    mkdir -p "$folddir/$(dirname "$f")" "$flatdocdir/$(dirname "$f")"
    fold_variants < "$f" > "$folddir/$f"
    fold_join < "$folddir/$f" > "$flatdocdir/$f"   # Q-965: joined ONCE per doc, not once per phrase
  done
  for f in $evid; do
    if [ ! -f "$f" ]; then
      # Outside preflight_tracked_docs' corpus, so say it here: a tracked evidence file
      # missing from the working tree means this gate scanned nothing in it.
      echo "  [FAIL] $f is tracked in git but missing from the working tree — not scanned"
      bad=1
      continue
    fi
    mkdir -p "$folddir/$(dirname "$f")" "$flatevdir/$(dirname "$f")"
    fold_variants < "$f" > "$folddir/$f"
    fold_join < "$folddir/$f" > "$flatevdir/$f"
  done
  while IFS=$'\t' read -r phrase allow note; do
    # Q-761: was `case "$phrase" in ''|'#'*) continue`, which skipped a needle starting with #.
    reg_row_kind loud "$phrase" "$allow" "$note"; case $? in 0) continue;; 2) bad=1; continue;; esac
    # CX-230: a HASHED row (`sha256:<hex>/<n>`, see hashed_row_parse) is matched by digest over the
    # same corpus (DOCS minus the allowed file, plus the non-md evidence), and reported by RP key.
    local hrow
    if hrow=$(hashed_row_parse "$phrase"); then
      local hh hn hf hfiles="" hhits
      read -r hh hn <<<"$hrow"
      for hf in $DOCS $evid; do
        case "$hf" in *"$allow"*) continue;; esac
        [ -f "$hf" ] && hfiles="$hfiles $hf"
      done
      # shellcheck disable=SC2086
      hhits=$(hashed_needle_hits "$hh" "$hn" $hfiles)
      if [ -n "$hhits" ]; then
        echo "  [FAIL] retracted phrasing still present (hashed row RP-${hh:0:8}; the phrase is not restated here)"
        echo "         matched by sha256 of the $hn-character span at a dollar sign   ($note)"
        printf '%s\n' "$hhits" | sed 's/^/      /'
        bad=1
      else
        echo "  [ok] retracted (hashed row): RP-${hh:0:8}"
      fi
      continue
    fi
    local np hits=""
    np=$(printf '%s' "$phrase" | fold_variants | fold_join)
    for f in $DOCS; do
      case "$f" in *"$allow"*) continue;; esac          # the doc allowed to narrate it
      [ -f "$folddir/$f" ] || continue
      # normalise the FOLDED file to one whitespace-collapsed line, then fixed-string match
      if grep -qF -- "$np" "$flatdocdir/$f"; then
        # changelog rows legitimately quote superseded wording; only exempt if EVERY
        # line-level hit is a revision row.
        # RECORD WHERE, not just WHICH FILE (2026-08-02, #65). A bare filename makes the
        # reader re-run the search by hand to find out what the gate saw; with the registry
        # holding morphology-independent STEMS, the surviving sentence often does not read
        # like the registry row, so "which phrase matched" is a real question. Cite the first
        # line that is NOT a changelog row — the same line the condition below turns on.
        local hitln
        hitln=$(grep -nF -- "$np" "$folddir/$f" 2>/dev/null | grep -vE '^[0-9]+:\| v[0-9]' \
                | head -1 | cut -d: -f1)
        # 🔴 Q-283 / Codex N10 finding 6 — reproduced on the PUBLISHED suite 2026-08-28.
        # The `elif` below asked "does the phrase appear on NO single line?", so a WRAPPED prose
        # use was reported only when nothing else in the file matched line-wise. A revision row
        # legitimately quoting the retracted wording matches on one line — and therefore SUPPRESSED
        # the wrapped hit. Measured: a TR with one revision row plus the same phrase broken across
        # two prose lines left GATE 3 printing `[ok] retracted: "preserving the classical pairing"`
        # at rc=0. Count instead of test: if the FLATTENED file holds more occurrences than the
        # revision rows do, at least one lives outside them.
        local nflat nrev
        nflat=$(grep -oF -- "$np" "$flatdocdir/$f" 2>/dev/null | wc -l)
        nrev=$(grep -E '^\| v[0-9]' "$folddir/$f" 2>/dev/null | grep -oF -- "$np" 2>/dev/null | wc -l)
        if [ -n "$hitln" ]; then
          hits="$hits $f:$hitln"
        elif [ "${nflat:-0}" -gt "${nrev:-0}" ]; then
          hits="$hits $f(spans-lines)"                  # only visible after normalisation
        fi
      fi
    done
    # EVIDENCE half: one recursive fixed-string scan over the pre-flattened copies (see
    # the COST comment above), then the SAME per-hit reporting as the DOCS half, off the
    # line-preserving folded copy. The changelog-row exemption is deliberately NOT
    # applied here — machine outputs have no `| vN.N |` revision rows, and an evidence
    # file that somehow grew one should not be exempted by it.
    local eh ef2
    for eh in $(grep -rlF -- "$np" "$flatevdir" 2>/dev/null || true); do
      ef2=${eh#"$flatevdir/"}
      case "$ef2" in *"$allow"*) continue;; esac        # same allow rule: FILENAME only
      local ehitln
      ehitln=$(grep -nF -- "$np" "$folddir/$ef2" 2>/dev/null | head -1 | cut -d: -f1)
      if [ -n "$ehitln" ]; then
        hits="$hits $ef2:$ehitln"
      else
        hits="$hits $ef2(spans-lines)"                  # only visible after normalisation
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing still present: \"$phrase\""
      echo "         matched as the fixed string: \"$np\"   ($note)"
      for h in $hits; do echo "      $h"; done
      bad=1
    else
      echo "  [ok] retracted: \"$phrase\""
    fi
  done < "$reg"
  rm -rf "$folddir" "$flatevdir" "$flatdocdir"
  return $bad
}

# ----------------------------------------------------------------------------------
# GATE 3b — retracted FIGURES (2026-08-02, item A6). The half of the retraction surface
# GATE 3 and GATE 1 both miss.
#
# WHY. GATE 3 matches retracted PHRASES; GATE 1 only compares integers of >=12 digits.
# A retracted STATISTIC — "1.4σ", "~5,500×", "≈10×", "net +1.6" — is invisible to both.
# That is not hypothetical: the surviving "1.4σ above" in evidence/r11/PHASE2_README.md
# was found by a human reading (TR-2 v1.23), and TR-9's draft-stage note carried two
# figures its own v1.7 had superseded through five subsequent revisions (TR-9 v1.20).
# Both were one-off manual sweeps. This gate is that sweep, permanent.
#
# THE EXEMPTION PROBLEM, and why this gate has NO automatic exemption.
# A retracted figure is quoted MORE after its retraction than before — every revision row,
# every ledger entry, every "this sentence read X until <date>" note must repeat it to
# record what changed. GATE 3 handles that with a filename allow-column plus a changelog-row
# exemption. Neither works here, and the failure is measured, not assumed:
#   * filename is too coarse — the legitimate quotations sit in BODY paragraphs of files
#     (METHODS.md, CORRECTIONS.md, TR-9) that also carry live prose;
#   * a changelog exemption would have HIDDEN this gate's first live finding, TR-2 v1.12's
#     "2.0σ", which sits inside a revision row and had been superseded for a day.
# So every legitimate occurrence is an explicit, CONTENT-ANCHORED allowlist row, in the
# shape GATE 4b uses (A8's lesson: no line numbers — they drift). Anything not allowlisted
# is a [FAIL]. The cost is ~25 curated rows; the benefit is that the exemption mechanism
# cannot silently widen.
#
# WHY-IT-FIRED (#65): every finding prints the matched fixed string, the registry note
# saying what superseded it, and the line text. Every exemption prints its class and reason.
# Allowlist rows that no longer match anything are re-printed as [note] — the drift audit.
# ITEM A2 (2026-08-02) — THE TWO QUESTIONS, for GATE 3b's whitespace normalisation.
#
# The normalisation is `flat = ' '.join(text.split())`, used only for the hard-wrap check.
#
# Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? The difference between one space and many,
#     and the difference between a space and a newline. That is the point: a figure split
#     across a hard wrap is the same figure. It also erases the difference between a figure
#     written with one internal space and the same figure written with two — which is the
#     residual already recorded below the wrap check, and it over-reports rather than
#     misses.
# Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? Everything that is not whitespace.
#     The matching itself is FIXED-STRING, so `2σ` and `2.00σ` do not match the registered
#     `2.0σ`; that is round-5 item A6, still open, and it is a property of the match rule
#     rather than of this normalisation. Note also that the ALLOWLIST anchor is matched
#     against the raw line and the wrap check against `flat`, so a legitimate occurrence
#     that is itself hard-wrapped cannot be anchored at all — it is reported, which is the
#     safe direction, but it cannot be exempted without rewrapping the source.
gate_retract_figures() {
  echo "== GATE 3b: retracted FIGURES restated without a supersession marker =="
  # ITEM A1, at the bash level so the check uses the git index (python's os.path.exists
  # cannot tell "never existed" from "deleted"). The ALLOWLIST is deliberately NOT guarded
  # here: losing it makes this gate STRICTER, not blinder — every exemption disappears and
  # the gate goes red. That is the fail-safe direction, so it needs no guard.
  require_rows "documentation/RETRACTED_FIGURES.tsv" "A retracted FIGURE that nothing registers is a figure nobody re-checks." || return 1
  require_tracked "documentation/RETRACTED_FIGURES.tsv" \
    "The figure registry IS this gate; with it gone, zero statistics are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  python3 - "$(reg_rows_count documentation/RETRACTED_FIGURES.tsv)" <<'PY'   # argv[1] = require_rows' count (Q-969)
import os, re, subprocess, sys
REG   = 'documentation/RETRACTED_FIGURES.tsv'
ALLOW = 'documentation/DOC_GATE_FIGURE_ALLOWLIST.txt'
if not os.path.exists(REG):
    # ITEM A1: unreachable in normal use — the bash `require_tracked` above returns first —
    # but it must not be left as a `sys.exit(0)` skip. A dead false-clear is still a false
    # clear the moment someone edits the guard above it out, and this one would report PASS
    # for a gate that had inspected nothing.
    print(f'  [FAIL] {REG} is absent, so this gate checked nothing'); sys.exit(1)

figs, hashrow = [], []
for ln in open(REG, encoding='utf-8'):
    # Q-761: reg_row_kind's rule: comment = column 1 exactly '#' or starting '# '; '#7' is DATA; '# ' + data column FAILS.
    f = ln.rstrip('\n').split('\t')
    if not ln.strip() or f[0] == '#' or f[0].startswith('# '):
        if any(c and not (c.startswith('<') and c.endswith('>')) for c in f[1:]): hashrow.append(f[0]); print(f'  [FAIL] Q-761: {REG} line "{f[0]}" is comment-shaped ("# ...") but carries data column(s), so it is not checked.\n         Register the figure without the leading "# ", or drop the tab-separated columns.')
        continue
    if len(f) >= 2 and f[0].strip() and f[1].strip():
        figs.append((f[0], f[1]))
    else:   # Q-969 (A04#11): a one-column row was DROPPED here while require_rows counted it
        hashrow.append(f[0]); print(f'  [FAIL] Q-969: {REG} row "{ln.rstrip(chr(10))[:80]}" is not "figure<TAB>why", so it is not checked.')
if len(figs) != int((sys.argv[1:] or ['-1'])[0] or '-1'):
    hashrow.append(''); print(f'  [FAIL] Q-969: GATE 3b accepted {len(figs)} row(s) of {REG}, which holds {(sys.argv[1:] or ["?"])[0]} data row(s).')

# (file, figure, anchor) -> (class, why).  Anchor is a fixed substring that must appear on
# the SAME LINE as the figure for the exemption to apply.
allow, used = {}, set()
if os.path.exists(ALLOW):
    for ln in open(ALLOW, encoding='utf-8'):
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.rstrip('\n').split('\t')
        if len(f) >= 5:
            allow[(f[0], f[1], f[2])] = (f[3], f[4])

# CHARACTER-VARIANT FOLD (2026-08-06). PROVEN LIVE before this shipped: a doc line
# carrying "~52x" (ASCII letter x) passed this gate green while the registry holds
# "~52×" (U+00D7) — a retracted figure could be restated, and the gate stayed green,
# purely by typing a different character. The registry header's item 2(a) measured
# these variant families at zero live escapes; this fold turns that one-off
# measurement into enforcement. Both needle and haystack are folded to a canonical
# ASCII form before the fixed-substring test; the ALLOWLIST anchor still matches the
# RAW line, so the content-anchored exemption machinery is untouched — only the
# needle side widened. Folds: multiplication signs ×/✕/⨯ and '*' -> x; en/em dash
# and U+2212 minus -> '-'; ≥/≤ -> '>='/'<='; NBSP/thin/narrow/figure spaces -> ' ';
# fullwidth ＋ -> '+'; digit-group commas stripped ("5,500" == "5500"); spaces
# around '+' collapsed ("net + 1.6" == "net +1.6").
# NOT folded, deliberately:
#   * APPROXIMATION GLYPHS (≈/∼ vs ~) — and this is MEASURED, not aesthetic. The
#     registry chooses each string "as narrow as the corpus allows", and "≈10×"
#     exploits exactly the ≈-vs-~ distinction: folding ≈ -> ~ made this gate fire
#     on 14 innocent sites on the 2026-08-06 pre-ship measurement ("~10× faster
#     than sklearn", and the SUPPORTED floor "≥~10×" itself) — the naive-widening
#     failure the registry header item 2(b) documents. A restatement that swaps
#     ≈ for ~ is the strip-the-qualifier family, unsafe to widen; residual, stated.
#   * σ -> "sigma", × -> "times", re-rounding ("2.0σ" vs "2σ" vs "2.00σ"),
#     spelled-out numbers: measured-zero families (item 2(b)) whose widening has
#     word-level false-positive surface.
#   * superscript digits: no registered figure carries an exponent; revisit if one
#     ever does.
# str.translate + str.replace + one linear scan — no regex of any kind.
FOLD1 = {0x00D7: 'x', 0x2715: 'x', 0x2A2F: 'x',
         0x2013: '-', 0x2014: '-', 0x2212: '-',
         0x2265: '>=', 0x2264: '<=', 0xFF0B: '+',
         0x00A0: ' ', 0x2007: ' ', 0x2009: ' ', 0x202F: ' ',
         # QUOTE FOLD (2026-09-02, batch C9) — added HERE ONLY to hold the
         # "keep the three in step" contract this table's own header states. The
         # defect and the red tests are GATE 3's (see fold_variants); this side has
         # ZERO quote-bearing needles today (14 figure rows, all numeric; 3 alias
         # rows: C1+C2+C3, "the exhaustive enumeration", "Zheng Qiao"), so the
         # extension is measured-INERT here and the full `all` output is unchanged
         # by it. It is applied anyway because the alternative is a table that
         # diverges silently and re-opens the same hole the day someone registers a
         # quote-bearing figure caption or alias. U+0060 backtick is NOT folded, for
         # the reason measured at fold_variants: no true positive exists and a real
         # false positive does. 0x2019 is the only one of the four the corpus
         # actually carries in prose; the other three are included so the pair
         # (open, close) is closed on both the single and double forms.
         0x2019: "'", 0x2018: "'", 0x201C: '"', 0x201D: '"'}
def canon(s, star):
    # star is what ASCII '*' folds to, and it is genuinely two-valued: as a variant
    # of × it must become 'x' ("~52*"), as markdown emphasis it must vanish so the
    # figure's own characters rejoin ("net **+1.6**"). Haystacks are checked under
    # BOTH readings (max of the two counts — over-report is this gate's safe
    # direction); no registered figure contains '*', so needles canon identically.
    s = s.translate(FOLD1).replace('*', star)
    if ',' in s:
        # Digit-group-comma strip, REWRITTEN 2026-08-07 with the evidence-corpus
        # extension, behaviour-identical and proven so by a differential test at ship
        # time: 207,470 corpus units (every line + every flattened whole-file text of
        # all 83 md + 54 evidence files, both star-readings, plus adversarial comma
        # edges), 0 differences against the original. The original was a per-character
        # PYTHON loop; fine on ~83 markdown files, but the evidence corpus adds five
        # ~940 KB machine logs whose ONE comma each forced the loop over the entire
        # flattened file (x2 star-readings) — millions of python steps to strip
        # nothing. This form is split/join on ',' — O(number of commas) python steps,
        # everything else at C speed; with it the whole gate measures 1.8 s against
        # 1.6 s markdown-only. Same decision rule on the ORIGINAL string: a comma is
        # dropped iff its immediate neighbours are digits (split parts preserve the
        # original neighbourhoods; empty parts = string-edge or consecutive commas,
        # kept, exactly as `0 < i < len(s)-1` kept them). Still no regex of any kind.
        parts = s.split(',')
        out = [parts[0]]
        for k in range(1, len(parts)):
            if parts[k-1] and parts[k] and parts[k-1][-1].isdigit() and parts[k][0].isdigit():
                out.append(parts[k])        # digit,digit — drop the comma
            else:
                out.append(',')
                out.append(parts[k])
        s = ''.join(out)
    return s.replace(' +', '+').replace('+ ', '+')

mds = subprocess.run(['git', 'ls-files', '*.md'], capture_output=True, text=True).stdout.split()
# EVIDENCE EXTENSION (2026-08-07) — the corpus is no longer markdown-only. The TRs quote
# reports/evidence/** measurement outputs (.out, .json, .log ...), and this registry's own
# motivating example ("1.4σ") was caught only because it happened to sit in an evidence
# .md; a figure surviving in the .out file one directory over was invisible. The non-md
# evidence files now run the same canon+count pipeline, same allowlist machinery.
# MEASURED at extension time: exactly ONE hit in 54 files / 5.7 MB — dav_tier1.out's
# "dav_hist palnbr 16 4.169e-04", a population HISTOGRAM BIN ROW (P(palnbr=16)), not the
# retracted Mawangdui corpus-control value. That is a fixed-string COLLISION, not a
# restatement, hence the `literal` allow class (GATE 18's vocabulary) introduced with
# this extension; see the allowlist header.
evid = [f for f in subprocess.run(['git', 'ls-files', 'reports/evidence/*'],
                                  capture_output=True, text=True).stdout.split()
        if not f.endswith('.md')]; EVID_FLOOR = 120; print(f'GATE3B_EVIDENCE_COUNT={len(evid)}')  # Q-708 sibling: same population and floor as GATE 3's evidence half
# COST, evaluated before writing it (box-safety rule): canonicalisation is |mds| ~ 130
# files x ~500 lines x 2 star-readings of canon() (a translate + one linear scan each),
# then |figs| = 11 fixed-string `in`/`count` tests per line per reading ~ 1.5e6 linear
# steps over data already in memory. No regex, no bounded repetition, no accumulation
# across the loop. The evidence extension adds 54 files / 5.7 MB; with the split/join
# comma strip in canon() the whole gate measured 1.8 s on the idle 2-core orchestrator
# (was 1.6 s markdown-only, 2026-08-07).
bad, exempt, spans, missing = [], [], [], []
# The registry (.tsv) and the allowlist (.txt) are not in `git ls-files '*.md'`, so the
# gate cannot match its own rows. Verified rather than assumed: both extensions are
# outside the glob. (The evidence list DOES include one .tsv and one .txt — they are
# corpus there, quoted by the TRs like any other measurement output.)
for m in mds + evid:
    if not os.path.exists(m):
        # Tracked-but-deleted. The .md half is also preflight_tracked_docs' finding, but
        # evidence non-md files are OUTSIDE that preflight, and an open() here would die
        # as a traceback — red either way, but a stated FAIL beats a stack trace.
        missing.append(m)
        continue
    text = open(m, encoding='utf-8', errors='replace').read()
    lines = text.split('\n')
    # Canonicalise once per file, in both '*' readings; needle tests below run against
    # these, while allowlist ANCHORS keep matching the RAW `line` — same rows, same
    # anchors, no parallel exemption mechanism.
    clx = [canon(l, 'x') for l in lines]
    cld = [canon(l, '') for l in lines]
    flat = ' '.join(text.split())          # line-break evasion check, GATE 3's lesson (a)
    cfx, cfd = canon(flat, 'x'), canon(flat, '')
    for fig, note in figs:
        cfig = canon(fig, '')              # needles carry no '*': one canon suffices
        n_online = 0
        for i, line in enumerate(lines, 1):
            c = max(clx[i-1].count(cfig), cld[i-1].count(cfig))
            if not c:
                continue
            n_online += c                   # OCCURRENCES, not lines: TR-2:650 carries
                                            # "1.4σ" twice and would otherwise look short
            # MARK EVERY MATCHING ROW USED, not just the first (fixed on this gate's
            # first run, before it shipped). Two anchors can legitimately land on one
            # line: TR-2 v1.23 quotes v1.19's "not reconstructible from the stated
            # errors" AND says where 1.4 came from, so both rows match line 654. A
            # break-on-first left the second looking dead and printed a [note] that was
            # a pure false alarm — the drift audit crying wolf on its own first run is
            # exactly how a real dead row later gets ignored.
            hits = [(anchor, cls, why)
                    for (af, afig, anchor), (cls, why) in allow.items()
                    if af == m and afig == fig and anchor in line]
            if hits:
                for anchor, _, _ in hits:
                    used.add((m, fig, anchor))
                exempt.append((m, i, fig, hits[0][1], hits[0][2]))
            else:
                bad.append((m, i, fig, note, line.strip()))
        # A figure visible only after whitespace normalisation spans a hard wrap, so no
        # single line carries it and the anchor rule cannot be applied. Report it as a
        # finding rather than passing it: this is exactly the evasion that hid the
        # conflict-theorem scope from GATE 3 until 2026-08-01.
        #
        # COUNT-based, not "did any line carry it" (tightened in this batch's own Phase-4
        # pass). The first cut asked `if not seen_on_a_line`, which meant a file with one
        # ordinary occurrence AND one wrapped occurrence reported only the ordinary one —
        # the wrapped copy, i.e. the harder-to-see one, was masked by the easy one. flat
        # collapses runs of whitespace to a single space, so a figure whose own internal
        # spacing is already single is counted identically on both sides.
        #
        # And the count is of OCCURRENCES, not of matching lines. The first version of this
        # comparison counted lines, so a line carrying the figure twice (TR-2:650 does) read
        # as one and the file reported a phantom hard wrap. Caught by this batch's own
        # Phase-4 pass, three false [FAIL]s, before it shipped.
        #
        # Residual, stated: a figure containing a space ("marginal 4.6") that is written with
        # a DOUBLE space on some line is collapsed by flat and not by line.count, so it would
        # be reported as wrapped. That direction over-reports rather than misses, which is the
        # direction a retraction gate should err in. Both sides of the comparison use the
        # same canon() fold, so a variant-form occurrence cannot produce a phantom wrap.
        if max(cfx.count(cfig), cfd.count(cfig)) > n_online:
            spans.append((m, fig, note))

for m, i, fig, note, line in bad:
    print(f'  [FAIL] {m}:{i} — retracted figure "{fig}" restated with no supersession marker')
    print(f'         WHY: {note}')
    print(f'         LINE: {line[:150]}')
for m, fig, note in spans:
    print(f'  [FAIL] {m} — retracted figure "{fig}" present only after whitespace')
    print(f'         normalisation, so it spans a hard wrap and cannot be anchored.')
    print(f'         WHY: {note}')
for m in missing:
    print(f'  [FAIL] {m} is tracked in git but missing from the working tree — this gate')
    print(f'         scanned nothing in it, and a corpus file that silently drops out is')
    print(f'         exactly the false clear this suite exists to stop.')

# `literal` joined the exempt-from-[OPEN] set 2026-08-07 with the evidence-corpus
# extension: a fixed-string collision (same characters, different quantity) is a
# LEGITIMATE occurrence, not an adjudicated-open defect — printing it [OPEN] forever
# would train readers to ignore [OPEN], which is the ledger-contract failure mode.
opens = [e for e in exempt if e[3] not in ('meta-mention', 'historical', 'literal')]
for m, i, fig, cls, why in opens:
    print(f'  [OPEN] {m}:{i} "{fig}" — {why}')
dead = [k for k in allow if (k[0], k[1], k[2]) not in used]
# Q-937 (batch 35): a row that matches nothing is a FAIL, not a note. Most rows anchor on the
# wording of an inline correction marker, and those markers are to move into CORRECTIONS.md
# (Q-938). As a note, a moved marker left its row behind and the gate still passed: a licence for
# the next sentence that reuses the anchor, which nobody had to look at. GATE 4b and GATE 18 already
# fail a stale exemption row for the same reason. Measured before the change: 0 dead rows on the
# tree; 3 after ablating every marker (scripts/correction_marker_inventory.sh), all printed as notes.
for k in dead:
    print(f'  [FAIL] allowlist row matched nothing this run: {k[0]} "{k[1]}" @ "{k[2][:40]}"')
    print(f'         Either the text was fixed (delete the row) or the anchor drifted (re-anchor it).')
    print(f'         A row that exempts nothing is a silent licence for the next line that matches it.')

nbad = len(bad) + len(spans) + len(missing) + len(hashrow) + len(dead) + (len(evid) < EVID_FLOOR); _ = len(evid) < EVID_FLOOR and print(f'  [FAIL] GATE 3b evidence corpus: {len(evid)} non-md file(s) tracked under reports/evidence/, floor {EVID_FLOOR}. A moved, renamed or emptied evidence tree leaves it checking nothing.')
if not nbad:
    byclass = {}
    for _, _, _, cls, _ in exempt:
        byclass[cls] = byclass.get(cls, 0) + 1
    tally = ', '.join(f'{v} {k}' for k, v in sorted(byclass.items())) or 'none'
    print(f'  [ok] {len(figs)} registered retracted figure(s); every occurrence in '
          f'{len(mds)} markdown + {len(evid)} evidence files is an allowlisted '
          f'narration or literal collision ({tally})')
sys.exit(1 if nbad else 0)
PY
}

# ----------------------------------------------------------------------------------
gate_links() {
  local rc=0
  echo "== GATE 4: internal markdown links + anchors resolve =="
  # Every [text](target) pointing INSIDE the repo must resolve: the file must exist,
  # and a #fragment must match a heading slug (GitHub rules, including the -1/-2
  # suffixing of duplicate headings) or an explicit <a name=>/<a id=> anchor.
  # External http(s)/mailto targets are NOT fetched — this gate is offline and
  # deterministic by design; link-rot is a separate, network-dependent concern.
  # A dangling CITATIONS.md#anchor is the specific failure this protects against:
  # attribution that silently stops resolving when a citation entry is renamed.
  { _md_norm_prelude; cat <<'PY'
import os, re, sys, subprocess, collections, unicodedata
LINK = re.compile(r'\[[^\]]*\]\(([^)\s]+)\)')
HEAD = re.compile(r'^(#{1,6})\s+(.*?)\s*$', re.M)
def slug(t):  # Q-816: GitHub's rule. Keep letters, marks, Nd/Nl digits, '_', ' ', '-'; each space -> '-'.
    t = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', t)
    t = re.sub(r'[`*~]', '', t).strip().lower()  # literal '_' survives rendering and stays in the slug
    t = ''.join(c for c in t if c in ' -' or unicodedata.category(c)[0] in 'LM' or unicodedata.category(c) in ('Nd', 'Nl', 'Pc'))
    return t.replace(' ', '-')  # no collapsing: 'A — B' -> 'a--b'; superscripts (No) and emoji (So) drop out
mds = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
       .stdout.split()]
anchors = {}
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    seen, a = collections.Counter(), set()
    # Q-965 (A04#14): headings come from the shared normaliser. A "## Heading" inside a fenced code
    # block is not a heading and gives no anchor (it satisfied a dead #fragment before); an indented,
    # setext or block-quoted heading is one, as GitHub renders it.
    for h in [b['title'] for b in md_parse(txt)[2] if b['kind'] == 'heading']:
        s = slug(h); seen[s] += 1
        a.add(s if seen[s] == 1 else f"{s}-{seen[s]-1}")
    a.update(re.findall(r'<a\s+(?:name|id)="([^"]+)"', txt))
    anchors[os.path.realpath(m)] = a
bad = []
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    base = os.path.dirname(m) or '.'
    for tgt in LINK.findall(txt):
        if tgt.startswith(('http://','https://','mailto:')):
            continue
        path, _, frag = tgt.partition('#')
        if path == '':
            dest = os.path.realpath(m)
        else:
            dest = os.path.realpath(os.path.join(base, path))
            if not os.path.exists(dest):
                bad.append((m, tgt, 'no such file')); continue
        if frag and dest in anchors and frag not in anchors[dest] \
           and frag.lower() not in anchors[dest]:
            bad.append((m, tgt, 'no such anchor'))
for m, t, why in bad:
    print(f"  [FAIL] {m} -> {t}  ({why})")
if not bad:
    # CLAIM MATCHES CHECK (2026-08-06): #fragments are validated only when the target is
    # a tracked markdown file (`dest in anchors`); a fragment pointing into any other
    # target kind passes unchecked, so the [ok] line says which half is attested.
    print(f"  [ok] all internal links resolve across {len(mds)} markdown files "
          f"(#anchors verified on tracked-markdown targets only)")
sys.exit(1 if bad else 0)
PY
} | python3 -
  rc=$?

  return $rc
}

# ----------------------------------------------------------------------------------
gate_secrefs() {
  local rc=0
  # -- GATE 4b (added 2026-08-01, unit r70-serialize) --------------------------------
  # The half of a cross-reference that phase 1 CANNOT see. A pointer like
  #     [CRITIQUE.md](../documentation/CRITIQUE.md) Q1
  # has a LINK target that resolves perfectly — the file exists — so phase 1 passes it,
  # while the part a reader actually follows ("go to section Q1") is dead. Six such
  # pointers to a non-existent "CRITIQUE.md Q1" survived every gate in this file for
  # months for exactly that reason.
  #
  # SCOPE, deliberately narrow: only DELIMITED section references are checked —
  #   FILE.md §"Quoted Name"     and     FILE.md Q<n>
  # Undelimited `FILE.md §Some words` is NOT checked: prose runs on past the section
  # name with no terminator, so the extracted "name" is whatever the sentence happened
  # to say next, and a first cut of this gate produced ~60 findings of which most were
  # mis-parses. A gate that cries wolf gets switched off. If you want an undelimited
  # reference checked, quote it.
  #
  # MATCH RULE: the reference text, normalised (case, smart quotes, dashes, emphasis,
  # trailing punctuation), must appear as a substring of some heading in the target
  # file; "…" in the reference acts as a gap, its fragments matched in order. That is
  # the convention the repo already uses, e.g. CRITIQUE.md §"Pre-registered tests …
  # Davis (2012)" against a much longer real heading.
  #
  # WHY-IT-FIRED: every finding prints the target file it resolved to and the reason,
  # not just a verdict — and allowlisted entries are re-printed every run as [OPEN]
  # with a count, so the known-dangling set can never quietly become invisible.
  #
  # OWN DISPATCH NAME (`secrefs`, added 2026-08-02, item A3). 4b used to live inside
  # gate_links, and the self-test asserted on `doc_gates.sh links` — one exit code
  # covering BOTH phases. A phase-1 failure for any unrelated reason would have satisfied
  # that assertion with 4b never having fired: [ok] printed for a gate that was not
  # exercised, which is precisely the untested-test shape this file's header warns about
  # (and the shape GATE 8's manual fire-proof shipped in). `links` still runs both, so
  # `all` and every existing caller are unchanged; the SELF-TEST now targets `secrefs`,
  # whose exit code no other gate can supply.
  # ITEM A2 (2026-08-02) — THE TWO QUESTIONS, for `norm()` and for the SUBSTRING match rule.
  #
  # Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? Case, smart quotes vs ASCII quotes, en/em
  #     dashes vs hyphens, emphasis markers, link syntax around the heading text, runs of
  #     whitespace, and trailing `.,;:`. Every one of those is a difference between how a
  #     heading is WRITTEN and how it is CITED, and none changes which section is meant.
  #
  # Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? The substring rule, not the
  #     normalisation, is where the give is. A reference resolves if its text appears
  #     ANYWHERE inside ANY heading of the target file, so `§"Rule 2"` would also resolve
  #     against a heading named "Rule 25", and `§"A … B"` resolves against any heading with
  #     A somewhere before B. The gate reports RESOLUTION, never IDENTITY: it cannot tell
  #     "this points at the right section" from "some heading contains these characters".
  #
  #     MEASURED, because a claim about how weak a rule is should not be a guess. Across the
  #     corpus there are 55 resolving delimited references, 2 of them using the `…` gap form.
  #     Ranked by (reference length / matched heading length) the weakest is 0.10 —
  #     `HISTORY.md:5052 -> MCKENNA.md §"Rule 2"` against the heading "mckenna's rule 2 —
  #     declined for promotion to formal c-rule". Every one of the 15 weakest was read: all
  #     are a short PREFIX of a long heading, which is how this repo cites, and NONE resolves
  #     against an unrelated heading. So the rule is loose but is not currently producing a
  #     false clear — a statement about today's corpus, not about the rule.
  echo "== GATE 4b: plain-text section references resolve to a real heading =="
  { _md_norm_prelude; cat <<'PY'
import os, re, sys, subprocess, bisect
MDLINK = re.compile(r'\[([^\]]*)\]\(([^)\s]+)\)')
HEAD   = re.compile(r'^#+\s+(.*?)\s*$', re.M)
# ITEM B1 (2026-08-02, drain-2) — THE SECOND ANCHOR FORM. This repo names a block in two
# ways, and until now the gate modelled only one. `**Global observable ledger (enterprise-wide
# multiple comparisons).**` at reports/METHODS.md:318 is cited as METHODS.md §"Global observable
# ledger" from five files; `**Stop-flag resolution (v1.12, 2026-07-13): …**` at
# TR2_THE_RULES_CONFLICT.md:587 is cited from three. MEASURED, not assumed: of the 19 non-meta
# rows on the allowlist, 10 resolve against a line-leading bold label and 2 more resolve after a
# stale word is fixed in the citation — a majority. Rewriting twelve citations to name the
# enclosing `##` heading instead would have made each of them point at a whole section rather
# than the paragraph meant, so the corpus was right and the gate's model of an anchor was wrong.
#
# DELIBERATELY NARROW. Only a bold span that OPENS a line (after an optional blockquote marker
# and an optional list bullet) counts. Arbitrary mid-sentence emphasis does not — the corpus is
# full of it, and treating it as an anchor would make almost any short reference resolve. A table
# cell (`| **x** |`) is not an anchor either: the line opens with `|`.
#
# WHAT THIS CANNOT SEE, stated because a widened rule is a weakened rule: heading resolution
# already reports RESOLUTION, never IDENTITY (see the A7 block below), and bold labels are far
# more numerous than headings, so the substring rule has more room to find a wrong match here
# than it did before. That is why bold resolution is NOT silent — every one is printed as
# [bold-anchor] with the label it matched, on every run, so the weaker leg is auditable instead
# of being a clear.
BOLD   = re.compile(r'^[ \t]*(?:>[ \t]*)*(?:[-*+][ \t]+|\d+\.[ \t]+)?\*\*([^*][^*]*?)\*\*', re.M)
# The trailing `` ` `` is ITEM B1's backtick leg: a path written as `` `documentation/X.md` §"…" ``
# was invisible to this gate because \s* cannot match the closing backtick. Two references in the
# corpus are written that way and one of them — PARTITION_STABILITY_BOUNDARIES.md:83 — is dead.
# ⚠ ':' added 2026-08-27 (Q-283 finding 5). Without it the class could not capture a
# `repo:FILE.md` qualifier, so the `':' not in path` exclusion below was UNREACHABLE for the colon
# form — and the colon form is exactly what the FINDING message tells the reader to write. The fix
# advised a remedy its own regex could not see. Verified: clean tree still reports zero findings.
SEC_Q  = re.compile(r'([\w.:/+-]+\.md)`?\s*§\s*"([^"]+)"')
SEC_N  = re.compile(r'([\w./+-]+\.md)`?\s+(Q\d+)\b')
ALLOW  = 'documentation/DOC_GATE_SECREF_ALLOWLIST.txt'

def norm(s):
    s = re.sub(r'\[([^\]]*)\]\([^)]*\)', r'\1', s)
    for a, b in (('’', "'"), ('‘', "'"), ('“', '"'), ('”', '"'),
                 ('–', '-'), ('—', '-')):
        s = s.replace(a, b)
    s = re.sub(r'[`*_~"]', '', s)
    s = re.sub(r'\s+', ' ', s)
    return s.strip().strip('.,;:').lower()

mds = subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True).stdout.split()
heads, bolds, bybase = {}, {}, {}
for m in mds:
    txt = open(m, encoding='utf-8', errors='replace').read()
    heads[os.path.realpath(m)] = [norm(b['title']) for b in md_parse(txt)[2] if b['kind'] == 'heading']   # Q-965: not inside a fence; indented/setext count
    bolds[os.path.realpath(m)] = [norm(b) for b in BOLD.findall(txt)]
    bybase.setdefault(os.path.basename(m), []).append(os.path.realpath(m))

allow, allow_why = set(), {}
if os.path.exists(ALLOW):
    for ln in open(ALLOW, encoding='utf-8'):
        if not ln.strip() or ln.startswith('#'):
            continue
        f = ln.rstrip('\n').split('\t')
        if len(f) >= 4:
            allow.add((f[0], f[1], norm(f[2])))
            allow_why[(f[0], f[1], norm(f[2]))] = f[3]

bad, opened, ambiguous, viabold = [], [], [], []
bare = []   # Q-937: a bare reference to a file that does not exist. This was `bad = True`, which rebound
            # the LIST: the next dangling reference crashed on `bad.append` and every later finding was lost.
hit_allow = set()
# ITEM B1 (2026-08-02, drain-2) — TWO-LINE WINDOW. The scan was per line, so a reference a hard
# wrap splits between `FILE.md` and its §"…" was invisible. GATE 3's hardening note (a) already
# records that exact evasion for a different gate; this is the same hole, and MEASURED it hides
# 15 of the corpus's 85 delimited references — 18%, none of which any run had adjudicated. Each
# line is flattened SEPARATELY and then joined, so the boundary offset stays exact and a markdown
# link is never mangled across the join; a match is attributed to the line it STARTS on
# (mo.start() < boundary), which is also what stops a reference lying wholly on line i+1 from
# being counted twice. SEC_Q is blanked with same-length spaces before the SEC_N pass for the
# same reason — a shortening substitution would move every offset after it.
for m in mds:
    base = os.path.dirname(m) or '.'
    # Q-965 (A04#15): the window is the LOGICAL line of the shared normaliser -- a whole paragraph,
    # every other block kind per line -- not two lines, so a reference wrapped over three or four lines
    # is read; and curly quotes are folded to ASCII before matching, so §“Name” is a delimited
    # reference (it matched nothing, and passed). Same-length folds only, so offsets stay exact; a hit
    # is attributed to the line its match STARTS on, as before.
    raw = md_text(open(m, encoding='utf-8', errors='replace').read())
    flats = [md_fold_quotes(MDLINK.sub(lambda mo: mo.group(2), ln))      # [text](path) -> path
             for ln in raw.split('\n')]
    units = []
    for blk in md_parse(raw)[2]:
        span = [x for x, _ in blk['lines']] if blk['kind'] == 'para' else None
        if span: units.append(span)
        else: units += [[x] for x in range(blk['start'], blk['end'] + 1)]
    allhits = []
    for span in units:
        window, offs = '', []
        for k, x in enumerate(span):
            # drop the wrap's own blockquote/bullet decoration; it is not part of the sentence
            s = flats[x - 1] if k == 0 else re.sub(r'^[ \t]*(?:>[ \t]*)*(?:[-*+][ \t]+)?', '', flats[x - 1])
            if k: window += ' '
            offs.append(len(window)); window += s
        at = lambda o: span[bisect.bisect_right(offs, o) - 1]
        allhits += [(at(mo.start()), mo.group(1), mo.group(2)) for mo in SEC_Q.finditer(window)]
        blanked = SEC_Q.sub(lambda mo: ' ' * len(mo.group(0)), window)
        allhits += [(at(mo.start()), mo.group(1), mo.group(2)) for mo in SEC_N.finditer(blanked)]
    for lineno, path, sec in sorted(allhits, key=lambda h: h[0]):   # (the body keeps its old depth)
            if path.startswith(('http://', 'https://')):
                continue
            dest = None
            for cand in (os.path.realpath(os.path.join(base, path)), os.path.realpath(path)):
                if cand in heads:
                    dest = cand; break
            # Q-967 (Q-835 A04#16): the unique-basename fallback is for a BARE file name only.
            # A reference that names a directory binds to that directory; when it resolves to
            # nothing it is dangling, and `nonexistent/CRITIQUE.md` must not be read as
            # documentation/CRITIQUE.md because that is the only CRITIQUE.md there is.
            if dest is None and '/' not in path:   # bare "CRITIQUE.md", no path
                same = bybase.get(os.path.basename(path), [])
                if len(same) == 1:
                    dest = same[0]
            if dest is None:
                # 🔴 Q-283 / Codex N10 finding 5 — reproduced on the PUBLISHED suite 2026-08-27.
                # "file-level resolution is phase 1's job" is true for a path phase 1 can SEE.
                # A path with no repo qualifier that resolves to nothing in this repo reaches
                # NEITHER gate: phase 1 skips it as out-of-repo, and this skipped it as phase 1's.
                # Measured: `NO_SUCH_FILE_ZZ.md §"A Heading That Does Not Exist"` planted in a
                # tracked file left GATE 4b printing "[ok] every delimited section reference
                # resolves ... (90 markdown files scanned)" at rc=0 — not silence, an explicit
                # positive claim about a reference that resolves nowhere.
                # A qualified `repo:FILE.md` is deliberate cross-repo intent and still skips here.
                # `roae-private/FILE.md` is the same explicit cross-repo intent as `repo:FILE.md`,
                # just written with a slash. Both are legible to a reader; neither is a dangling
                # same-repo link. ⚠ I ported commit 8f291120 and MISSED its sibling 86f58ce9, which
                # exists precisely because a first cut excluded only the colon form — so my version
                # flagged 3 of these on a clean tree. Two commits, one defect class; porting one is
                # the "fix the instance, not the class" error this repo queued as Q-305 today.
                # `FILE.md` is the documented PLACEHOLDER for this very syntax — TR9 §changelog
                # narrates "the form `FILE.md §\"Name\"` / `FILE.md Q<n>`". No file is named that,
                # so treating it as a dangling reference makes the gate fire on the document that
                # explains the gate. Narration is not a claim; this repo's own GATE 20 draws the
                # same line between a marker and a sentence about markers.
                if ':' not in path and not path.startswith('roae-private/') and path != 'FILE.md':
                    # ⚠ The enclosing loop is `for m in mds:` with `lineno`; `ln` is a COMPREHENSION
                    # variable bound to file lines, and `rc` does not exist here — this block signals
                    # failure through `bare`, consumed by `sys.exit(1 if (bad or stale or bare) else 0)`.
                    # My first port copied the branch's `{f}:{ln}` and `rc = 1` verbatim: the message
                    # printed a LIST and the finding did not move the exit code. Copying the shape of
                    # a fix without checking its scope is the same error twice in one evening.
                    print(f'  [FINDING] {m}:{lineno} - bare section reference to "{path}", which '
                          f'resolves to no file in this repo. Qualify it as repo:FILE.md if the '
                          f'target is private, or fix the name.')
                    bare.append((m, lineno, path))
                continue                           # file-level resolution is phase 1's job
            want = norm(sec)
            if not want:
                continue
            parts = [p.strip() for p in re.split('…|\\.\\.\\.', want) if p.strip()]

            # ITEM B4 (2026-08-02, drain-1) — `anchored` is the bold leg's PREFIX rule. The
            # reference's first part must sit at offset 0 of the label, not anywhere inside
            # it. Heading resolution is unchanged (anchored=False); see the B4 note below the
            # ratio block for why the two legs get different rules.
            def _match(anchors, parts=parts, anchored=False):
                out = []
                for h in anchors:
                    pos, ok = 0, True
                    for k, p in enumerate(parts):
                        i = h.find(p, pos)
                        if i < 0 or (anchored and k == 0 and i != 0):
                            ok = False; break
                        pos = i + len(p)
                    if ok:
                        out.append(h)
                return out

            matches = _match(heads[dest])
            if not matches:
                # ITEM B1 — the second anchor form. Reported, never silent: see the BOLD note.
                bm = _match(bolds[dest], anchored=True)
                if bm:
                    viabold.append((m, lineno, os.path.relpath(dest), sec, bm[0]))
                    continue
            if matches:
                # ITEM A7 (2026-08-02). This gate reports RESOLUTION, never IDENTITY: a
                # reference resolves if its text appears anywhere inside ANY heading of the
                # target, so §"Rule 2" also resolves against a heading "Rule 25", and the gap
                # form §"A … B" resolves against any heading with A before B.
                if len(matches) > 1:
                    ambiguous.append((m, lineno, os.path.relpath(dest), sec, matches))
                continue
            rel = os.path.relpath(dest)
            key = (m, rel, want)
            if key in allow:
                hit_allow.add(key)
                opened.append((m, lineno, rel, sec, key))
            else:
                bad.append((m, lineno, rel, sec, key))

for m, ln, d, s, key in bad:
    print(f'  [FAIL] {m}:{ln} -> {d} §"{s}"')
    print(f'         WHY: nothing in {d} is named "{norm(s)}" — no heading contains that'
          f' normalised text, and no line-leading bold label BEGINS with it (ITEM B4: a bold'
          f' label matched mid-text is not an anchor)')
for m, ln, d, s, key in opened:
    print(f'  [OPEN] {m}:{ln} -> {d} §"{s}"  ({allow_why.get(key, "allowlisted")})')
# ITEM B1 (2026-08-02, drain-2) — STALE ALLOWLIST ROWS ARE A FAILURE, not a tidiness issue.
# This gate's allowlist is the record of what is KNOWN broken. A row that no longer corresponds
# to any live finding is an exemption with nothing under it: it can be silently satisfying a
# future reference that happens to reuse the same (source, target, section) triple, and it makes
# the [note] count below overstate the open-defect load. Widening the anchor model in this very
# commit retired ten rows at a stroke, which is exactly the moment such rot gets created — so
# the check ships with the change that would otherwise have caused it.
stale = sorted(allow - hit_allow)
for src, tgt, want in stale:
    print(f'  [FAIL] stale allowlist row: {src} -> {tgt} §"{want}"')
    print(f'         WHY: that reference no longer fails, so the row exempts nothing.'
          f' Delete it from {ALLOW} — an exemption with no finding under it is a silent'
          f' licence for the next reference that reuses the same triple')
# ITEM A7 (2026-08-02) — REPORT-ONLY AMBIGUITY NOTE, and why it is this and not a strength
# floor on the match.
#
# The hazard A7 names is that "the next dangling reference that happens to be a substring of
# an unrelated heading passes silently". The obvious instrument is a COVERAGE RATIO — flag a
# resolution when the matched heading is much longer than the reference — and it was measured
# before being written. Over the 55 references that resolve today the ratio runs:
#     1.0 : 12    0.8 : 2    0.7 : 3    0.6 : 3    0.5 : 3
#     0.4 : 12    0.3 : 13   0.2 : 3    0.1 : 4
# so any threshold loose enough to be a tripwire fires on ~15-20 references that were each
# read individually in round 5 and are each a legitimate short prefix (§"d3 560T" ->
# "d3 560t - current deepest", ratio 0.28; §"Data-like vs principled" -> the F-23 heading,
# 0.33). A report-only note firing twenty times on correct references is how a report-only
# gate stops being read, which is the open question C3 already carries.
#
# AMBIGUITY is the same hazard with none of that cost. A reference is dangerous precisely
# when it does NOT single out one heading; §"Rule 2" is harmless until MCKENNA.md gains a
# "Rule 25". MEASURED on the corpus of 2026-08-02: 55 references resolve and ZERO resolve
# against more than one heading, so this note is silent today and speaks only when a heading
# is added that makes an existing reference stop identifying its target.
#
# IT IS DELIBERATELY NOT A FAILURE. Whether an ambiguous-but-resolving reference should go
# red is a judgment about the corpus, not a mechanical fact, and A7 lists "accept as
# documented" as a live option; escalating this to rc 1 is the operator's call, not a drain
# unit's. WHAT IT CANNOT SEE: a reference that resolves against exactly one WRONG heading —
# no amount of counting finds that, only reading does.
#
# ITEM B4 (2026-08-02, drain-1) — THE PREFIX RULE, SHIPPED. `f3179f8` measured the two candidate
# strength floors for the bold leg and rejected one of them; this ships the other. The decision
# is NOT re-derived here, because re-deriving it with a length ratio is the specific error the
# measurement warns against — the seven lowest-ratio references (0.159-0.193) are the CORRECT
# ones, citing the stable opening of a long annotated label, so the ratio is backwards for this
# corpus and a floor loose enough to spare them (<=0.15) sits far below the ~0.47 the motivating
# defect scored. No threshold separates them. Recorded at f3179f8; do not re-measure it.
#
# WHAT SHIPPED INSTEAD: `_match(..., anchored=True)` on the bold leg only. A reference must match
# at the LABEL'S START. Population at ship time: 0 of 18 — the rule is green with NO allowlist,
# because the one reference that violated it was fixed at f3179f8
# (documentation/CITATIONS.md:1055@d8b94054 -> SPECIFICATION.md §"wrap-around parity", which resolved at
# offset 9 inside "theorem (wrap-around parity is odd)" and was widened to the label's own
# opening form). That fix is what the LEG 7 fire-proof re-injects, so this rule is proven against
# its real motivating example rather than a synthesised one.
#
# WHY THE HEADING LEG IS LEFT ALONE. Its anchors are far less numerous, its §"A … B" gap form is
# in live use, and A7's ambiguity note already covers its weak case. Tightening both legs in one
# commit would make a green run unattributable to either. WHAT THE PREFIX RULE CANNOT SEE: a
# reference that IS a correct prefix of the WRONG label — prefix anchoring constrains WHERE a
# match may start, never WHICH label is meant, so it is a strictly weaker claim than identity and
# the [bold-anchor] print stays.
for m, ln, d, s, hs in ambiguous:
    print(f'  [note] {m}:{ln} -> {d} §"{s}" resolves against {len(hs)} headings, so it does')
    print(f'         not identify one section. Lengthen the reference until it does:')
    for h in hs[:4]:
        print(f'           also matches: {h}')
for m, ln, d, s, b in viabold:
    print(f'  [bold-anchor] {m}:{ln} -> {d} §"{s}" resolves against a line-leading bold label,')
    print(f'         not a heading: "{b[:96]}"')
if viabold:
    print(f"  [note] {len(viabold)} reference(s) above resolve via the WEAKER of the two anchor "
          f"forms; bold labels outnumber headings, so this leg is printed rather than cleared")
if opened:
    print(f"  [note] {len(opened)} allowlisted dangling reference(s) above are OPEN DEFECTS, "
          f"not exemptions — see {ALLOW}")
if not bad and not stale:
    print(f"  [ok] every delimited section reference resolves to a heading or a line-leading "
          f"bold label ({len(mds)} markdown files scanned)")
sys.exit(1 if (bad or stale or bare) else 0)
PY
} | python3 -
  [ $? -ne 0 ] && rc=1
  return $rc
}

# `links` keeps running BOTH phases, so `all` and every existing caller are unchanged.
gate_links_and_secrefs() {
  local rc=0
  gate_links   || rc=1
  gate_secrefs || rc=1
  return $rc
}

# ----------------------------------------------------------------------------------
gate_status() {
  echo "== GATE 5: canonical quantities keep their epistemic status =="
  # GATE 1 catches a number whose DIGITS changed. This catches the other half: a number
  # that keeps its digits while silently changing epistemic status — an estimate promoted
  # to "exact", or an exact count demoted to an estimate. reports/METHODS.md is the single
  # source of truth; documentation/CANONICAL_VALUE_STATUS.tsv is its machine-readable
  # projection. Report-only, because legitimate sentences DO compare the two (e.g. "the
  # ratio of the exact count to the Knuth estimate"), so an allowlist carries those.
  { _md_num_prelude; cat <<'PY'
import re, subprocess, sys, os
reg = 'documentation/CANONICAL_VALUE_STATUS.tsv'
allow = 'documentation/DOC_GATE_STATUS_ALLOWLIST.txt'
if not os.path.exists(reg):
    print(f"  [FAIL] missing registry {reg}"); sys.exit(1)
rows = []
# Q-969 (A04#17): an emptied registry gave "[ok] 0 occurrences of 0/0", and a row the parser could
# not read was dropped. Now: a comment (the header's own rule, `#` first) that carries a TAB column is
# a data row in comment shape; a data row needs match<TAB>exact|estimate; zero rows is no registry.
# Each is a structural FAIL (rc 1) even though the status findings themselves stay report-only.
regbad = []
for lno, line in enumerate(open(reg, encoding='utf-8'), 1):
    line = line.rstrip('\n')
    if not line.strip(): continue
    p = line.split('\t')
    if line.lstrip().startswith('#'):
        if any(c.strip() for c in p[1:]): regbad.append(f'{reg}:{lno} is comment-shaped but carries TAB column(s)')
        continue
    if len(p) >= 2 and p[0].strip() and p[1].strip() in ('exact', 'estimate'): rows.append((p[0].strip(), p[1].strip()))
    else: regbad.append(f'{reg}:{lno} is not match<TAB>exact|estimate')
if not rows: regbad.append(f'{reg} has ZERO rows, so no canonical quantity is checked')
if regbad:
    for b in regbad: print(f"  [FAIL] Q-969: {b}")
    sys.exit(1)
# Allowlist entries are "path:line" with an optional TAB-separated content anchor: a literal
# substring identifying the reviewed sentence.
#
# WHY the anchor is now the PRIMARY key (2026-08-01, second revision). The file:line form drifts,
# and drifts constantly: both entries in the allowlist drifted within a single day. The TR-4
# calibration row was written at line 119, two lines were inserted above it, and the entry then
# (a) failed to suppress the real row at line 121 and (b) silently covered whatever had moved into
# :119. Direction (b) is the dangerous one — an unreviewed line inheriting somebody else's
# suppression. The HISTORY.md entry then repeated the pattern: correct at line 5563 when written,
# pushed to :5566 hours later by an unrelated insertion three lines above it.
#
# Matching an anchored entry by (file, anchor) instead of (file, line) fixes both directions at
# once. Direction (b) becomes impossible — suppression now REQUIRES the reviewed text, so no
# unreviewed line can inherit it no matter how the file is edited. And benign renumbering stops
# raising a WARN that carries no information. The recorded line number is kept as documentation
# and audited below, so a stale or dead entry is still reported rather than silently accumulating.
# ITEM A8, DECIDED 2026-08-02: the recorded line number is GONE from the format. The key is
# (file, anchor) and nothing else.
#
# The item offered three options — (i) keep and refresh by hand, (ii) drop it and lose the
# dead-entry audit, (iii) have the gate REWRITE the recorded line, self-healing. (iii) was
# the favourite. All three are declined, because (ii)'s stated cost is not real and (iii)
# has a cost that was not stated:
#
#   * "(ii) loses the dead-entry audit" is FALSE. Read the audit below: of its four
#     branches, three — file gone, anchor gone, anchor matches several lines — are driven
#     entirely by the ANCHOR. Only the fourth, "anchor now sits at :N, update the recorded
#     line", uses the number, and that branch is precisely the recurring [note] the item
#     complains about. Dropping the number costs the noise and keeps the whole audit.
#   * (iii) would make a gate a writer. The self-test REFUSES TO RUN unless the tree is
#     clean, so a self-healing gate run first would break the next run's precondition, and
#     a writer needs its own mutation case proving it wrote the RIGHT line — a new
#     instrument to trust, added to solve a documentation problem.
#
# The locator readers actually want is still printed: the gate resolves the anchor and
# reports the line it found, every run. A computed location cannot go stale.
#
# An entry with no anchor now SUPPRESSES NOTHING. It used to suppress by line number, which
# is the dangerous direction this whole design exists to close: an unreviewed line inheriting
# somebody else's exemption after an edit above it.
anchorless = []    # entries with no anchor: reported, and deliberately inert
anchored = {}      # file -> [anchor] — matched by content, immune to renumbering
if os.path.exists(allow):
    for l in open(allow, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        key = parts[0].strip()
        anc = parts[1].strip() if len(parts) > 1 and parts[1].strip() else None
        if anc is None:
            anchorless.append(key)
        else:
            anchored.setdefault(key, []).append(anc)
EST = r'\b(?:estimate(?=[sd]?\b)|Knuth\b|CI\b|confidence\b|Monte\b)'
# EST, BOTH ENDS BOUNDARIED (2026-09-26, the sibling of Q-604 below). The old alternation
# `estimate|estimated|Knuth|\bCI\b|confidence|Monte` anchored neither end of four of its
# words, so on a registry-value line it read identifiers -- knuth_whole_tree_5e10,
# SOLVE_KNUTH_* -- and "underestimate", "Montel", "unconfidenced" as estimate markers. Now each
# word needs a word boundary on both sides; "_" is a word character, so an identifier that
# merely CONTAINS knuth no longer counts, while "Knuth's", "Knuth-style" and "--knuth" still
# do. The plural/participle forms "estimates" and "estimated" are kept, and they still report
# as the token "estimate" (the old `estimated` alternative was unreachable behind `estimate`),
# so a WARN names the same token it did. Words the old pattern never matched (estimation,
# estimator) are NOT added. header_labels (5b) uses EST too and gets the same boundaries.
# Q-604 (2026-09-26): BOTH ENDS ARE WORD-BOUNDARIED NOW. The old alternation anchored only
# the START of each word, so it also matched "exactly", "exactness", "provenance" and
# identifiers such as exact_count; on a registry-value line that made a manner adverb or a
# word about sources read as a status claim (the live case: documentation/SOLVE.md, "matches
# King Wen exactly", reported as token "exact" beside 5.21e31). A BLANKET trailing boundary
# is not the whole fix, as the row filing this said: "gives EXACTLY as 1,097,..." IS an
# exactness claim about the figure. So "exactly" is admitted by ADJACENCY (exly_near): it
# counts only when the text between it and an occurrence of the registry value is nothing
# but spaces, markup (* _), the separators : = , and at most one of as/at/is/of/to -- after
# the value's own x10^k / e+k tail when the value comes first. "provenance", "exactness" and
# a non-adjacent "exactly" never count. EX alone is still what 5b's header_labels uses.
EX  = r'\b(?:exact|proven|proved)\b'
EXLY = r'\bexactly\b'
_EXLY_TAIL = r'^(?:\s*[×x]\s*10\S*|[eE]\+?\d+)'
_EXLY_GLUE = r'[\s*_:=,]*(?:(?:as|at|is|of|to)\s[\s*_]*)?'
def exly_near(line, val):
    """{'exactly'} if an 'exactly' is ADJACENT (glue only) to an occurrence of val."""
    vs = [(m.start(), m.end()) for m in re.finditer(re.escape(val), line)]
    for m in re.finditer(EXLY, line, re.I):
        for a, b in vs:
            if m.start() >= b:
                gap = re.sub(_EXLY_TAIL, '', line[b:m.start()])
            elif m.end() <= a:
                gap = line[m.end():a]
            else:
                continue
            if re.fullmatch(_EXLY_GLUE, gap, re.I):
                return {'exactly'}
    return set()
# Q-968 (A04#18): A COMMA-GROUPED REGISTRY INTEGER IS MATCHED BY VALUE, not only by its literal
# spelling. `val not in line` needed the commas, so the same integer written ungrouped (or grouped
# with thin spaces) was never an occurrence, and calling it an estimate passed GATE 5 while GATE 1's
# comma stripping saw unchanged digits. spelled() returns the spelling under which val occurs on the
# line, read by the shared number lexer (md_normalise.sh); exly_near is then given that spelling.
_VINT = {}
def spelled(line, val):
    want = _VINT.setdefault(val, int(val.replace(',', '')))
    w = str(want)
    if w[-3:] not in line or w not in re.sub(r'[^0-9]', '', line):   # cheap pre-filters: every spelling ends in w's last 3 digits
        return None
    for n in md_nums(line):
        if n.kind == 'int' and n.value == want:
            return n.raw
    return None
files = [p for p in subprocess.run(['git','ls-files','*.md'],capture_output=True,text=True)
         .stdout.split()]
seen = 0; bad = 0; hits = set()   # hits: which registry rows actually occur in the corpus
# GATE 5b state (2026-08-02, item A4). Cost formula, evaluated before writing it: F files x
# L lines, F ~ 250 and the whole tracked-markdown corpus ~10 MB, held once.
TEXT = {}          # f -> lines, kept only for files that actually carry a registry value
unmarked = {}      # f -> [(ln, val, want, line)] occurrences with NEITHER kind of token
marked = {}        # f -> {ln} occurrences that DID carry a token (either side)
n_unmarked = 0
for f in files:
    _lines = open(f, encoding='utf-8', errors='replace').read().splitlines()
    for ln, line in enumerate(_lines, 1):
        for val, want in rows:
            if re.fullmatch(r'[\d.]+', val) and ',' not in val:
                # SIBLING OF GATE 26 LEG 2 (2026-09-02), and measured the same way. This
                # required the SUPERSCRIPT form, so a registry value typed the way the solver
                # PRINTS it -- 1.3287e38 -- was invisible to GATE 5/5b: FOUR occurrences
                # (documentation/CORRECTIONS.md:2025, reports/evidence/f1/
                # F1_ORBIT_QUOTIENT_2026_07.md:9, and FH1_RESIDUAL_DOMINANCE.md:179 and :181),
                # none of them examined.
                # 🔴 THE FIRST CUT OF THIS FIX WAS WRONG AND THE MEASUREMENT CAUGHT IT. Without
                # the code-span condition below it added ONE [WARN], and that [WARN] was false:
                # CORRECTIONS.md:2050 quotes solver output, and the only 'exact' token on the
                # line is the FLAG NAME `--f1-exact-c1c2c4c5` inside a code span. A quoted
                # transcript is evidence, not a status claim about the figure -- the same
                # reasoning, on the same notation, that GATE 26 LEG 2 records at length. With
                # the condition: population +3, findings +0.
                # The hex-context lookbehind is also LEG 2's: without it a sha256 fragment
                # reads as a registry value.
                _spans = [(m.start(), m.end()) for m in re.finditer(r'`[^`]*`', line)]
                _asc = re.search(r'(?<![0-9a-fA-F.])' + re.escape(val) + r'[eE]\+?\d', line)
                if _asc and any(a <= _asc.start() and _asc.end() <= b for a, b in _spans):
                    _asc = None
                if not (re.search(re.escape(val) + r'\s*[×x]\s*10', line) or _asc):
                    continue
            elif val not in line:
                vsp = spelled(line, val) if ',' in val and re.fullmatch(r'[\d,]+', val) else None
                if vsp is None:
                    continue
            seen += 1
            hits.add(val)
            TEXT[f] = _lines
            etoks = sorted(set(t.lower() for t in re.findall(EST, line, re.I)))
            xtoks = sorted(set(t.lower() for t in re.findall(EX, line, re.I))
                           | exly_near(line, val if val in line else (spelled(line, val) or val)))
            he, hx = bool(etoks), bool(xtoks)
            if not he and not hx:
                unmarked.setdefault(f, []).append((ln, val, want, line))
                n_unmarked += 1
            else:
                marked.setdefault(f, set()).add(ln)
            conflict = (want == 'exact' and he and not hx) or (want == 'estimate' and hx and not he)
            if conflict:
                if any(a in line for a in anchored.get(f, ())): continue
                # RECORD WHICH QUANTITY AND WHICH TOKEN (2026-08-02, #65). "this line reads
                # otherwise" made the reader re-run the classifier by eye to find the word that
                # tripped it — and on a report-only gate, an unexplained WARN is one nobody
                # actions. Name the registry value, its METHODS status, and the exact status
                # token(s) matched on the wrong side.
                got = ", ".join(f'"{t}"' for t in (xtoks if want == 'estimate' else etoks))
                side = 'exact/proven' if want == 'estimate' else 'estimate'
                print(f"  [WARN] {f}:{ln} — quantity {val[:28]} is '{want}' in METHODS, but this line "
                      f"carries {side} token(s) {got} and no '{want}' marker")
                print(f"         {line.strip()[:170]}")
                bad += 1
if bad == 0:
    print(f"  [ok] {seen} occurrences of {len(hits)}/{len(rows)} canonical quantities "
          f"all carry a consistent status")
else:
    print(f"  (report-only: if a hit is a legitimate exact-vs-estimate COMPARISON, add its 'file:line' to {allow})")
# Audit the allowlist itself. A suppression that no longer corresponds to real text is a
# permission nobody reviewed and nobody can see; it must be reported, not accumulate silently.
for fpath, entries in sorted(anchored.items()):
    if not os.path.exists(fpath):
        print(f"  [note] allowlist: {fpath} no longer exists — prune its {len(entries)} entry/entries")
        continue
    text = open(fpath, encoding='utf-8', errors='replace').read().splitlines()
    for anc in entries:
        # ITEM A11 (2026-08-02): this loop variable used to be called `hits`, rebinding the
        # registry-hit SET built above into a list of allowlist line numbers. Benign only by
        # ordering — the "[ok] {seen} occurrences of {len(hits)}/{len(rows)}" print happens
        # before this loop. Any future edit that adds or moves a use of `hits` after this
        # point would silently report allowlist line numbers as canonical-quantity coverage:
        # a wrong denominator inside a coverage claim, which is the exact class this suite
        # exists to catch. Renamed so the two can never collide.
        anchor_lines = [i for i, l in enumerate(text, 1) if anc in l]
        if not anchor_lines:
            print(f"  [note] allowlist: {fpath} anchor no longer appears in the file — prune it")
            print(f"         anchor: {anc[:120]}")
        elif len(anchor_lines) > 1:
            print(f"  [note] allowlist: {fpath} anchor matches {len(anchor_lines)} lines {anchor_lines[:6]} — "
                  "suppression is broader than one reviewed sentence; make it more specific")
        else:
            # The locator, COMPUTED not recorded (item A8). Printed as [ok] rather than
            # [note] because a live, single-match exemption is not a defect and must not
            # compete for attention with the two branches above, which are.
            print(f"  [ok]   allowlist: {fpath}:{anchor_lines[0]} exemption live (matched by content)")
for key in sorted(anchorless):
    print(f"  [note] allowlist: \"{key}\" has no TAB-separated anchor, so it SUPPRESSES NOTHING "
          "and is ignored. Add an anchor: the format is file<TAB>anchor, no line number.")

# ---------------------------------------------------------------------------------
# GATE 5b — a canonical quantity restated with NO epistemic marker among siblings that
# carry one (2026-08-02, item A4).
#
# WHY. GATE 5 above fires only when a line carries a status token that CONTRADICTS
# METHODS. The two unlabelled TR-9 ledger cells fixed under #23 carried no token at all
# and were therefore invisible to it BY CONSTRUCTION — TR-9's own v1.19 row says so in as
# many words: "GATE 5 ... fires on a status token contradicting METHODS, and these cells
# carried no status token at all." An omission is the commoner shape and it was ungated.
#
# WHY IT IS SCOPED TO MIXED TABLES, and not to every unmarked occurrence. "Report every
# occurrence with neither token" measures at the noise floor printed below — most prose
# mentions of a canonical number legitimately carry no marker, and a gate that prints
# hundreds of lines every run is one whose output reviewers learn to skip (the same
# erosion items A8 and B2 describe). The DEFECT shape is narrower and is exactly what
# TR-9 v1.19 describes: "In a table where siblings are explicitly marked exact, an
# unmarked cell reads as one more exact count." So the reported class is: an unmarked
# occurrence inside a markdown table block where ANOTHER line of the SAME table carries a
# marker. The bare count is printed alongside, so the noise floor is MEASURED rather than
# assumed, and a future implementer can widen the class knowing what widening costs.
#
# REPORT-ONLY, with its own allowlist. The allowlist is a SEPARATE file from GATE 5's on
# purpose: 5 and 5b are different classes, and one file would let a suppression written
# for a reviewed exact-vs-estimate COMPARISON silently also exempt an unmarked cell on the
# same line. Anchored entries only — the line-number-only form drifted twice in one day.
alw5b = 'documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt'
anc5b = {}
if os.path.exists(alw5b):
    for l in open(alw5b, encoding='utf-8'):
        l = l.rstrip('\n')
        if not l.strip() or l.lstrip().startswith('#'): continue
        parts = l.split('\t')
        if len(parts) < 2 or not parts[1].strip():
            print(f"  [note] {alw5b}: entry without a TAB-separated anchor is ignored — {parts[0][:80]}")
            continue
        # (file, anchor), no line number — the same convention GATE 5's allowlist adopted
        # under item A8 on 2026-08-02. Aligned in the same batch, because two allowlists
        # disagreeing about their own format is how the NEXT entry gets written in the old
        # one. This file is empty today, so aligning it costs nothing and leaving it costs a
        # silent parse failure later: rpartition(':') on a path with no colon yields
        # fpath == '', which would have keyed every entry under the empty string and
        # suppressed nothing, quietly.
        anc5b.setdefault(parts[0].strip(), []).append(parts[1].strip())

def table_blocks(lines):
    """Maximal runs of consecutive markdown table lines, as (start, end) 1-based inclusive."""
    blocks, start = [], None
    for i, l in enumerate(lines, 1):
        if l.lstrip().startswith('|'):
            if start is None: start = i
        elif start is not None:
            blocks.append((start, i - 1)); start = None
    if start is not None: blocks.append((start, len(lines)))
    return blocks

def header_labels(header, row, val, want):
    """True if the table HEADER already labels the column this value sits in.

    Found by running 5b for the first time, which is the point of running it: 4 of its 6
    initial findings were cells in tables whose header column IS the label — TR-4's
    "| Layer | Exact value | Prior Knuth estimate | ... |" and SEARCH_SPACE_SIZE's
    "| quantity | estimate | 95% CI | rel. error |". Those cells are not unlabelled; the
    label is one row up, where a per-line classifier cannot see it. Reporting them would
    have been the false-positive flood that gets a report-only gate ignored.

    Column-aware rather than whole-header: a table with BOTH an exact and an estimate
    column (TR-4 has exactly that) would otherwise be self-exempting in both directions.
    """
    hc = [c.strip() for c in re.split(r'(?<!\\)\|', header)]   # Q-525: a GFM \| is not a cell break
    rc = [c.strip() for c in re.split(r'(?<!\\)\|', row)]
    pat = EST if want == 'estimate' else EX
    idx = [i for i, c in enumerate(rc) if val in c]
    if idx and len(hc) == len(rc):
        return bool(re.search(pat, hc[idx[0]], re.I))
    return False                        # ragged table: fall through and report it

found5b = 0
print("  -- 5b: unmarked canonical quantity among marked siblings in the same table --")
for f in sorted(unmarked):
    mk = marked.get(f, set())
    if not mk:
        continue
    for lo, hi in table_blocks(TEXT[f]):
        if not any(lo <= m <= hi for m in mk):
            continue                      # no marked sibling in this table — not the class
        header = TEXT[f][lo - 1]
        for ln, val, want, line in unmarked[f]:
            if not (lo <= ln <= hi):
                continue
            # A REVISION-HISTORY row is exempt, exactly as GATE 3 exempts one: a changelog
            # records what was said at a date and quotes figures in passing; demanding an
            # epistemic marker there would fire on every historical entry forever. Both of
            # 5b's remaining initial findings were changelog rows.
            if re.match(r'\|\s*\**v\d', line.lstrip()):  # Q-763: a version row (| v1.2 |), not any cell starting 'v' ("valid")
                continue
            if header_labels(header, line, val, want):
                continue
            if any(a in line for a in anc5b.get(f, ())):
                continue
            sibs = sorted(m for m in mk if lo <= m <= hi)
            # RECORD WHY IT FIRED (#65): the quantity, its METHODS status, the table it sits
            # in, and the sibling line whose marker makes the omission readable as a claim.
            print(f"  [WARN] {f}:{ln} — quantity {val[:28]} is '{want}' in METHODS and carries NO "
                  f"status marker, inside the table at :{lo}-{hi} whose sibling line(s) "
                  f"{sibs[:4]} DO carry one")
            print(f"         {line.strip()[:170]}")
            found5b += 1
if found5b == 0:
    print(f"  [ok] no unmarked canonical quantity sits in a table whose siblings are marked")
else:
    print(f"  (report-only: label the cell, or add 'file<TAB>anchor' to {alw5b})")
print(f"  [measured] noise floor: {n_unmarked} of {seen} registry-value occurrences carry no "
      f"status token at all; {found5b} of those are in a MIXED table, which is the reported class")
for fpath, entries in sorted(anc5b.items()):
    if not os.path.exists(fpath):
        print(f"  [note] {alw5b}: {fpath} no longer exists — prune its {len(entries)} entry/entries")
        continue
    txt = open(fpath, encoding='utf-8', errors='replace').read().splitlines()
    for anc in entries:
        hh = [i for i, l in enumerate(txt, 1) if anc in l]
        if not hh:
            print(f"  [note] {alw5b}: {fpath} anchor no longer appears — prune it")
        elif len(hh) > 1:
            print(f"  [note] {alw5b}: {fpath} anchor matches {len(hh)} lines {hh[:6]} — "
                  "make it more specific")
        else:
            print(f"  [ok]   {alw5b}: {fpath}:{hh[0]} exemption live (matched by content)")
sys.exit(0)
PY
  } | python3 -
}

