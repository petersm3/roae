#@ scripts/doc_gates.d/30_figures_liveness_banner_revisions.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATE 6 (figures), 7 (liveness), 9 (banner), 12 (revhist), 13 (revrows).
#@ Lines 2353-3237 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ----------------------------------------------------------------------------------
gate_figures() {
  echo "== GATE 6: figure GENERATORS carry no retracted phrasing =="
  # WHY: on 2026-08-01 a withdrawn claim ("hard floor k >= 13") was found RENDERED in a
  # published figure, having survived every gate. matplotlib converts text to glyph
  # paths, so fig_tr4_boundary_information.svg holds 0 <text> elements and 920 <use>
  # refs — the sentence is visible to a reader and invisible to grep. Most of the repo's
  # image assets are in that state (the matplotlib SVGs incl. the PCA plots, plus every
  # PNG). NO TALLY IS QUOTED HERE, and that is a correction: this sentence said "38 of
  # the repo's 40", a pair that was BOTH wrong by 2026-09-04 — the live [info] line this
  # gate prints on every run said 37 unscannable of 39, and the 40 counted
  # example/report.pdf, which is not in this gate's population (`git ls-files '*.svg'
  # '*.png'`) and was removed from the repository that day for embedding the complete
  # unsubsetted DejaVu font programs. LEG 3's [info] line below is the authority; it is
  # computed from `$nimg` every run and a comment restating it can only be right by
  # accident. We cannot grep the output, so we grep what PRODUCES it: the annotation
  # strings in the figure generators. Keeping generator text and figure in sync is the
  # generators' documented obligation.
  #
  # ITEM A8 (2026-08-02) — THE SAME BLINDNESS, FOR STATISTICS. Until now this gate read
  # RETRACTED_PHRASES.tsv only, so a withdrawn NUMBER annotated onto a published plot —
  # "~5,500×", "1.4σ", "+125" — was invisible everywhere: to GATE 3b (markdown only, and it
  # says so at RETRACTED_FIGURES.tsv's item 5), to GATE 6 (phrase registry only), and to any
  # grep of the asset itself (matplotlib renders text to glyph paths). The figure registry is
  # now a SECOND pass over the same generators. MEASURED before shipping: every registered
  # figure against every tracked generator gives ZERO hits, so this ships with no allowlist
  # and a clean baseline — and, unlike the markdown corpus GATE 3b policed, the
  # legitimate-restatement problem does not arise here, because a figure generator has no
  # changelog rows and no retraction narrations to quote.
  #
  # NEITHER POPULATION IS ASSERTED HERE AS A LIVE FACT, AND THAT IS A CORRECTION rather
  # than a house style. (The two superseded figures ARE quoted just below, deliberately, in
  # order to name what drifted — so this paragraph does contain digits and is not claiming
  # otherwise. That distinction is caveat (l)'s lesson: a caveat that says a form does not
  # occur in the file, in the line that makes it occur, falsifies itself.)
  # This sentence shipped at `29d83a1` reading "all nine registered figures against the
  # three tracked generators". Nine was EXACT at that commit — the registry held nine rows.
  # `2ac589e` took it to eleven the same day ("the figure registry was seeded from revision
  # rows, so it missed the bodies") and did not touch this comment, so it went stale within
  # hours — while GATE 11's own header, which nobody had to update because it was written
  # after the widening, says "of the eleven registered figures". ONE SITE SAID NINE AND
  # ANOTHER SAID ELEVEN, in the same file, about the same registry, and nothing could see
  # the disagreement. Both populations are printed on this gate's own [ok]
  # lines at the bottom of this function — the registry count from `$nfig`, the generator
  # count from `$gens` — so a comment restating them can only ever be right by accident.
  # Found by round 12 drain-3's `R11` sweep of this file's date-stamped MEASURED numbers.
  local reg="documentation/RETRACTED_PHRASES.tsv"
  local figreg="documentation/RETRACTED_FIGURES.tsv"
  # ITEM A1, and this gate had the shape TWICE. (i) the registry skip, same as GATE 3.
  # (ii) the worse one: `gens` comes from `git ls-files`, an INDEX listing, so deleting
  # viz/report_figures.py from the working tree left it in `gens`, made `tr < "$f"` emit a
  # redirect error to stderr, produced no match, and the gate reported [ok] on a generator
  # it never opened. The `-n "$gens"` test cannot see that: the list was never empty.
  require_tracked "$reg" "The retraction registry IS this gate; with it gone, zero generators are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  local gens bad=0 g
  # 🔴 Q-283 / Codex N10 finding 9 — reproduced on origin/main 2026-08-27. This population was
  # keyed on a DIRECTORY, so it covered 3 tracked viz/*.py and reported "[ok] 3 figure
  # generator(s)" while a FOURTH tracked file — solve.py — also calls savefig and was never
  # examined. A gate that checks 3 of 4 and reports on all of them is a coverage hole that
  # states its own count and is still read as complete. Key on the BEHAVIOUR (calls savefig),
  # not on where the file happens to live: "exempt a construction, never a directory" is
  # already this file's own rule, three hundred lines above.
  gens=$( { git ls-files 'viz/*.py'
            git ls-files '*.py' | xargs grep -ln 'savefig' 2>/dev/null; } | sort -u)
  # ---- THE PUBLISHED-ASSET POPULATION, and the [skip] that was a fail-open ----------
  # Added 2026-09-02 (batch C7) with LEG 3 below, which needs this population anyway.
  #
  # 🔴 THE LINE THIS REPLACES READ `[ -n "$gens" ] || { echo "  [skip] ..."; return 0; }`.
  # With no generator tracked, this gate printed [skip] and RETURNED 0 — a PASS — while every
  # published figure in the tree stayed exactly as unscanned as it had ever been. The glyph-path
  # assets cannot be scanned through their output (this gate's own WHY header measures that:
  # matplotlib renders text to glyph paths), so the generator is the ONLY place a retracted
  # phrase in them can be caught. "No generator" is therefore the state in which this gate
  # protects nothing at all, and it was the state in which it reported clean. That is the
  # fail-open class — a verdict inferred from an absence that can mean "the check did not run".
  local imgs nimg
  imgs=$(git ls-files '*.svg' '*.png')
  nimg=$(printf '%s\n' "$imgs" | grep -c . )
  if [ "$nimg" -eq 0 ]; then
    echo "  [FAIL] zero tracked image assets enumerated — vacuous, treated as failure."
    echo "         This gate exists to protect published figures and it just found none. If the"
    echo "         assets genuinely moved, update the pathspec; do not read an empty glob as clean."
    return 1
  fi
  if [ -z "$gens" ]; then
    echo "  [FAIL] $nimg tracked image asset(s) are published and ZERO figure generators are"
    echo "         tracked (no viz/*.py in the index, and no tracked .py calls savefig). The"
    echo "         glyph-path assets are unscannable through their own output, so the generator"
    echo "         is the only place a retracted phrase in them could be caught — and there is"
    echo "         no generator. This printed [skip] and returned 0 until 2026-09-02."
    return 1
  fi
  for g in $gens; do
    # Every path here came out of the index, so require_tracked can only return 0 or 2.
    local grc=0
    require_tracked "$g" "A tracked figure generator that is absent is not a clean generator." || grc=$?
    [ "$grc" -eq 0 ] || bad=1
  done
  [ "$bad" -eq 0 ] || return 1
  # CHARACTER-VARIANT FOLD (2026-08-06): both passes below fold needle and generator
  # through fold_variants (GATE 3's helper — one implementation, kept in step with the
  # python canon() in GATEs 3b/18). Without it a generator annotating "~52x" (ASCII x)
  # was invisible against the registered "~52×" — the same proven evasion the doc-corpus
  # gates closed the same day. Inline per (row, generator): the generator set is ~3
  # files, so the extra sed processes are ~2 per row, noise.
  while IFS=$'\t' read -r phrase allow note; do
    reg_row_kind quiet "$phrase" "$allow" "$note"; [ $? -eq 1 ] || continue   # Q-761 (GATE 3/11 are the loud sites)
    local np hits=""
    np=$(printf '%s' "$phrase" | fold_variants | fold_join)
    for f in $gens; do
      if fold_variants < "$f" | fold_join | grep -cF -- "$np" >/dev/null; then
        # RECORD WHERE (2026-08-02, item A5 / #65). This printed a bare filename, so a
        # maintainer given a 900-line generator had to re-run the search by hand to find
        # the annotation string — the same debugging cost #65 removed from GATE 3 and
        # GATE 5. Cite the line; fall back to the filename when the hit is only visible
        # after normalisation, which is the case a hard-wrapped Python string produces.
        local gln
        gln=$(fold_variants < "$f" 2>/dev/null | grep -nF -- "$np" | head -1 | cut -d: -f1)
        if [ -n "$gln" ]; then hits="$hits $f:$gln"; else hits="$hits $f(spans-lines)"; fi
      fi
    done
    if [ -n "$hits" ]; then
      echo "  [FAIL] retracted phrasing in a figure generator: \"$phrase\""
      echo "         matched as the fixed string: \"$np\"   ($note)"
      for h in $hits; do echo "      $h  — regenerate the figure after fixing"; done
      bad=1
    fi
  done < "$reg"

  # ---- ITEM A8: the FIGURE registry, second pass over the same generators. -------------
  # Deliberately NOT merged into the loop above. The two registries have different column
  # counts (3 vs 2) and their verdicts must read differently — a maintainer needs to know
  # which registry to go and edit. Merging them would have rewritten the phrase leg's output
  # lines, and two existing fire-proofs assert on exactly those lines: that is the GATE 8
  # shape (an invocation rewritten under a fire-proof that was not re-run) and it is not
  # worth fifteen lines. What IS shared is the scan itself, below.
  local figbad=0 nfig=0
  require_tracked "$figreg" "The figure registry is the second half of this gate; absent, no retracted STATISTIC is checked."
  case $? in
    2) return 1 ;;
    1) echo "  [note] no figure registry, so retracted STATISTICS in generators are unchecked" ;;
    0)
      while IFS=$'\t' read -r figure fignote; do
        reg_row_kind quiet "$figure" "$fignote"; [ $? -eq 1 ] || continue   # Q-761
        nfig=$((nfig+1))
        local nf fighits=""
        nf=$(printf '%s' "$figure" | fold_variants | fold_join)
        for f in $gens; do
          if fold_variants < "$f" | fold_join | grep -cF -- "$nf" >/dev/null; then
            local fgln
            fgln=$(fold_variants < "$f" 2>/dev/null | grep -nF -- "$nf" | head -1 | cut -d: -f1)
            if [ -n "$fgln" ]; then fighits="$fighits $f:$fgln"; else fighits="$fighits $f(spans-lines)"; fi
          fi
        done
        if [ -n "$fighits" ]; then
          echo "  [FAIL] retracted FIGURE in a figure generator: \"$figure\""
          echo "         matched as the fixed string: \"$nf\"   ($fignote)"
          for h in $fighits; do echo "      $h  — regenerate the figure after fixing"; done
          figbad=1
        fi
      done < "$figreg"
      ;;
  esac
  [ "$figbad" -eq 0 ] || bad=1

  # ---- LEG 3: THE OUTPUT SIDE (batch C7, 2026-09-02). --------------------------------
  #
  # WHY. Both legs above scan GENERATORS, and that is sound for a matplotlib figure because its
  # text is unreachable in the output. It is NOT the whole population. A published .svg whose
  # text survives as real XML character data — example/hexagrams.svg carries 64 <text> nodes,
  # example/wave.dot.svg 255 (graphviz, not matplotlib) — is greppable, is published, and was in
  # no needle scan anywhere: neither GATE 3 (whose corpus is *.md plus reports/evidence/**) nor
  # either leg above (whose corpus is *.py). Their producer, roae.py, writes SVG directly and
  # calls no savefig, so it is not in `gens` either. A registry row for a phrase drawn into one
  # of those two files would have been present, ledgered, and checked against nothing.
  #
  # 🔴 WHAT WAS PROPOSED AND WHY IT IS NOT WHAT SHIPPED (batch C7). The finding asked for a scan of
  # `viz/*.py` and `reports/figures/*.svg`. `viz/` was ALREADY COVERED by the two legs above (both
  # registries since 2026-08-01; past the directory key since 2026-08-27, Q-283 / Codex N10 #9). The
  # matplotlib SVGs carry ZERO <text> elements (glyph <use> refs instead), so a tag-stripped scan of
  # them passes every needle, always -- a manufactured fail-open -- and LEG 3's population is keyed
  # on the BEHAVIOUR that makes a scan meaningful (renderable character data), never on a directory.
  # ⚠ Q-894 (2026-09-28, Codex VIZ A4-12): "would attest nothing" was wrong for those SVGs. matplotlib
  # writes every rendered string, line by line, as an XML comment `<!-- label -->` inside its
  # `<g id="text_N">` group, and a label COMPUTED at render time (a V3 panel title is a TSV header)
  # is in no generator literal the legs above can read. LEG 4 therefore reads the comments of every
  # glyph-path .svg and runs the same two registry scans over them, printing GATE6_SVG_LABELS=N
  # (comments read; zero while a glyph-path .svg is present is a FAIL, never a pass). The tracked
  # .png assets remain unreadable to every output leg; they rest on the generator legs above.
  #
  # THE UNSCANNABLE REMAINDER IS COUNTED AND PRINTED, not passed over in silence. An asset this
  # leg cannot read is not an asset it has cleared, and the census line below says so every run.
  local svgs nsvg=0 ntext=0 nglyph=0 npng tbf="" ff xd nx xln gsv="" nlab=0
  npng=$(printf '%s\n' "$imgs" | grep -c '\.png$')
  svgs=$(printf '%s\n' "$imgs" | grep '\.svg$')
  if [ -z "$svgs" ]; then
    echo "  [FAIL] LEG 3 — zero tracked .svg assets, out of $nimg tracked image asset(s)."
    echo "         Vacuous, treated as failure: this leg's whole population is the .svg pathspec"
    echo "         and it matched nothing. If this tree genuinely ships no SVG, retire this leg"
    echo "         deliberately; do not let a mis-globbed population report clean."
    bad=1
  fi
  for ff in $svgs; do
    nsvg=$((nsvg+1))
    # `git ls-files` is an INDEX listing. This gate's own item A1(ii) records the shape: a
    # tracked file deleted from the worktree stayed in the list, produced no match, and was
    # reported clean. Absence is an ERROR here, never a silent skip.
    if [ ! -f "$ff" ]; then
      echo "  [FAIL] $ff is tracked in git but absent from the worktree, so it was NOT scanned."
      bad=1; continue
    fi
    if grep -qE '<(text|tspan|title)[ />]' "$ff"; then
      ntext=$((ntext+1)); tbf="$tbf $ff"
    else
      nglyph=$((nglyph+1)); gsv="$gsv $ff"     # LEG 4 reads its label comments (Q-894)
    fi
  done
  echo "  [info] LEG 3 population: $nsvg tracked .svg — $ntext text-bearing (SCANNED),"
  echo "         $nglyph glyph-path (their label comments are SCANNED by LEG 4); plus $npng tracked"
  echo "         .png, which NO output leg reads — those rest on the generator legs above."
  if [ "$ntext" -eq 0 ] && [ "$nsvg" -gt 0 ]; then
    echo "  [note] LEG 3 scanned ZERO files: no tracked .svg carries renderable character data."
    echo "         Stated, not silent — this leg attests nothing this run."
  fi
  local -A _G6FOLD=()
  for ff in $tbf $gsv; do
    # Strip tags and unescape the entities that can split or hide a needle. Deliberately a
    # SUPERSET of the rendered text (style/CDATA character data comes along): a superset can
    # only over-report, and an over-report here is loud and one edit away from fixed, whereas
    # an element type this leg forgot to name would be silent. &amp; is unescaped LAST.
    # Q-965 (A05#12-14): the extraction goes through the shared normaliser. md_read folds CRLF, so a
    # label comment ending `-->\r` is still a label (it was invisible to the old `-->$` sed); every
    # entity is decoded, numeric ones too (`1.4&#x3c3;` rendered as 1.4σ and passed the named-entity
    # sed); and a text-bearing .svg contributes its COMMENTS as well as its character data, because a
    # `<title>` used to flip a glyph-path figure into LEG 3, whose tag-strip deleted the very label
    # comments LEG 4 reads. Line structure is kept, so a hit still names its line.
    case " $gsv " in *" $ff "*) _g6m=label ;; *) _g6m=text ;; esac
    xd=$(python3 -c "$(_md_norm_prelude)"'
import sys, re
t = md_read(sys.argv[1])
if sys.argv[2] == "label":   # LEG 4: label comments, one per rendered line
    out = [_mhtml.unescape(m.group(1)) for m in (re.match(r"^ *<!-- (.*) -->\s*$", l) for l in t.split("\n")) if m]
    sys.stdout.write("\n".join(out) + ("\n" if out else ""))
else:
    t = re.sub(r"<!--(.*?)-->", lambda m: " " + m.group(1) + " ", t, flags=re.S)
    t = re.sub(r"<[^>\n]*>", " ", t)   # per line, as the sed it replaces: a tag split over lines leaves its text in (a superset)
    sys.stdout.write(_mhtml.unescape(t))
' "$ff" "$_g6m") \
      || { echo "  [FAIL] LEG 3/4 could not extract text from $ff — NOTHING was scanned for it."; bad=1; continue; }
    nx=$(printf '%s' "$xd" | fold_variants | fold_join); case " $gsv " in *" $ff "*) nlab=$((nlab + $(printf '%s\n' "$xd" | grep -c .))) ;; esac
    # The allow column is ignored here for the same reason the generator leg ignores it: a
    # rendered figure carries no changelog row and no retraction narration to quote.
    while IFS=$'\t' read -r phrase allow note; do
      reg_row_kind quiet "$phrase" "$allow" "$note"; [ $? -eq 1 ] || continue   # Q-761
      local np3
      [ -n "${_G6FOLD[P$phrase]+x}" ] || _G6FOLD[P$phrase]=$(printf '%s' "$phrase" | fold_variants | fold_join)   # Q-965: fold each needle once, not once per .svg
      np3=${_G6FOLD[P$phrase]}
      if grep -qF -- "$np3" <<<"$nx"; then
        xln=$(printf '%s' "$xd" | fold_variants | grep -nF -- "$np3" | head -1 | cut -d: -f1)
        echo "  [FAIL] retracted phrasing RENDERED in a published figure: \"$phrase\""
        echo "         matched as the fixed string: \"$np3\"   ($note)"
        if [ -n "$xln" ]; then echo "      $ff:$xln  — fix the generator and regenerate"
        else echo "      $ff(spans-lines)  — fix the generator and regenerate"; fi
        bad=1
      fi
    done < "$reg"
    if [ -f "$figreg" ]; then
      while IFS=$'\t' read -r figure fignote; do
        reg_row_kind quiet "$figure" "$fignote"; [ $? -eq 1 ] || continue   # Q-761
        local nf3
        [ -n "${_G6FOLD[F$figure]+x}" ] || _G6FOLD[F$figure]=$(printf '%s' "$figure" | fold_variants | fold_join)
        nf3=${_G6FOLD[F$figure]}
        if grep -qF -- "$nf3" <<<"$nx"; then
          xln=$(printf '%s' "$xd" | fold_variants | grep -nF -- "$nf3" | head -1 | cut -d: -f1)
          echo "  [FAIL] retracted FIGURE rendered in a published figure: \"$figure\""
          echo "         matched as the fixed string: \"$nf3\"   ($fignote)"
          if [ -n "$xln" ]; then echo "      $ff:$xln  — fix the generator and regenerate"
          else echo "      $ff(spans-lines)  — fix the generator and regenerate"; fi
          bad=1
        fi
      done < "$figreg"
    fi
  done
  echo "GATE6_SVG_LABELS=$nlab"; if [ -n "$gsv" ] && [ "$nlab" -eq 0 ]; then echo "  [FAIL] LEG 4 read ZERO label comments from $nglyph glyph-path .svg — vacuous, treated as failure"; bad=1; fi
  if [ "$bad" -eq 0 ]; then
    echo "  [ok] $(echo $gens | wc -w) figure generator(s) — every tracked viz/*.py plus every"
    echo "       tracked .py that calls savefig — carry no registered retracted phrasing"
    echo "  [ok] ...and none of the $nfig registered retracted FIGURE(s) either (item A8)"
    echo "  [ok] LEG 3: $ntext text-bearing published .svg, and LEG 4: $nlab label comment(s) in $nglyph glyph-path .svg, carry neither a registered retracted"
    echo "       phrase nor a registered retracted FIGURE"
  fi
  return $bad
}

# ---------------------------------------------------------------------------
# GATE 7 — a run's status must not be frozen in the present tense, and a run
# must not be NAMED after a budget it never reached.
#
# Why: PASS1_TRAJECTORY_DETERMINISM.md — a doc CLAUDE.md lists under "Stable
# paper-citable findings" — described a run as "1000T (in flight)" and "3,666
# lines and growing" from 2026-04-24 until 2026-08-01. The run had stopped at
# ~154T on 2026-04-27. Worse, correcting the TENSE alone left the row labelled
# "Fresh 1000T": naming a run after a budget it never reached asserts the
# accomplishment just as strongly as the present tense did.
#
# HISTORY.md is exempt BY DESIGN. It is a dated narrative log; "the run is in
# flight as of this entry" is correct there and must not be rewritten. The
# whole point of that file is to preserve what was believed at the time.
gate_liveness() {
  echo "== GATE 7: no frozen present-tense run status; no run named after an unreached budget =="
  { _md_norm_prelude; cat <<'PY'
import re, glob, sys, os
LIVE = ['in flight', 'currently running', 'results pending', 'and growing',
        'is underway', 'awaiting results', 'run is ongoing']
# WORD-BOUNDARY KEYS (round 15, item R18). A bare substring test matched "concurrently
# running", which contains "currently running", and GATE 7 went FINDINGS rc=1 on a sentence
# that was making no liveness claim at all. The gate was right on its pattern and wrong on
# the meaning, and the corpus was reworded to satisfy it — which is the worst way to pay for
# a false positive, because it edits the record to please the instrument.
#
# A BLANKET \b ON EVERY KEY IS WRONG, and this was MEASURED rather than assumed before the
# narrow form was chosen. Two keys legitimately match mid-word: 'is underway' inside
# "analysis underway", and 'run is ongoing' inside "overrun is ongoing". Both are real
# liveness claims that a blanket boundary would stop catching — a recall loss, in the
# direction this gate exists to prevent. Only keys whose FIRST TOKEN is a proper suffix of
# an ordinary English word need the boundary, and 'currently' ({con,re}currently) is the
# one such key. The rest keep the substring test deliberately.
#
# WHY THIS IS NOT "LOOSENING": \b removes ONLY matches where the key is preceded by a word
# character, i.e. where it is part of a longer token. A genuine "currently running" always
# begins at a boundary, including after a hyphen or an em dash. There is no case this
# suppresses that the gate should have caught.
#
# MEASURED POPULATION at the time of the fix: the gated corpus carries 18 `concurrent*`
# tokens and 3 `concurrently`, none currently adjacent to "running" — so this is a live
# near-miss, not a hypothetical one, in a corpus whose own subject matter is concurrency.
WORDSTART = {'currently running'}
# Words that mean the status IS qualified rather than frozen, or that the text is
# quoting/correcting an old claim rather than making one.
# Each entry must describe an OUTCOME or mark the text as quoted/hypothetical.
# The first draft included 'budget', 'if ', 'would' and 'example' — far too generic.
# 'budget' alone made the gate VACUOUS on its own motivating example, because the
# stale table had a "Budget" column header three lines above the frozen status. A
# suppression list that matches ordinary prose suppresses everything; this is the
# same defect as a scrub that samples zero items and reports PASS.
DISPO = ['stopped at', 'was stopped', 'completed', 'requested', 'never reached',
         'never carried out', 'superseded', 'aborted', 'cancelled', 'partial',
         'previously read', 'corrected', 'no longer', 'observed scenario',
         'hypothetical', 'as of this', 'at the time']
# NARRATION MARKERS — deliberately SAME-LINE scope, not the ±4/+3 window DISPO uses.
#
# Added 2026-09-02. GATE 7 fired on documentation/CORRECTIONS.md:5687, a correction entry
# NARRATING a frozen status it had just withdrawn: "the sentence was written 2026-06-13 with
# the re-derive described as *in flight*". A report ABOUT a defect is not an instance of it,
# and because `all` is the blocking pre-push leg this false positive blocked EVERY PUSH. It
# also gets louder every time the prose lane does its job, since each new correction that
# documents a frozen status re-triggers it — the wrong gradient.
#
# 🔴 WHY LINE SCOPE AND NOT DISPO. Adding these to DISPO was tried first and MEASURED: with
# the ±4/+3 window, a genuine "the 4000T ladder build is in flight" was suppressed by an
# unrelated "was withdrawn last week" on the preceding line. That is a recall loss in exactly
# the direction this gate exists to prevent, and the corpus makes it reachable — 7 files carry
# a liveness keyword and 37 carry one of these markers. On the same LINE the association is
# grammatical rather than coincidental, and the real case satisfies it: 'described as' sits in
# the same sentence as 'in flight'. Re-tested after the change: the narration case passes, and
# BOTH genuine cases fire again, including the one the window had suppressed.
NARRATION = ['withdrawn', 'described as', 'retired wording']
bad = 0
# The registry is the authority on which budgets were actually REACHED. A run named
# after a budget in the registry is named correctly; one named after a budget that
# is NOT in the registry is asserting an accomplishment that may never have happened.
# Pattern-matching alone cannot tell those apart, and a gate that flags the correct
# ones too is a gate that gets ignored — the mistake GATE 4 of ops_gates.sh made.
# OPERATOR RULE (2026-08-01): "if you ever need to know if a large enumeration
# completed, it should be cataloged with a sha256 as a canonical hash." So the
# authority is not the mere APPEARANCE of a budget in the registry — it is a
# budget that carries a sha256. The first version of this gate took any <N>T
# token from the file, which silently admitted 1120T (mentioned only in a
# power-law extrapolation sentence, and CANCELLED on 2026-08-01) and 900T. A doc
# could then have said "the 1120T run" and passed. Require a sha in the vicinity.
reg = open('documentation/CANONICAL_HASHES.md', errors='replace').read()
REACHED = set()
MENTIONED = set()          # appears in the registry at all — but appearing is not attesting
# Q-967 (Q-835 A05#16): the sha must be the BUDGET'S OWN, not any sha within 600 characters. A
# cancelled "9999T" line placed under another run's sha line was attested by it. A budget is
# REACHED when (a) a registry table row names it in its FIRST cell and carries a backticked sha
# (a prefix of >= 8 hex, as the Quick reference writes them) in the same row, or (b) a heading
# names it and that heading's own section, up to the next heading, carries a full-length sha.
for m in re.finditer(r'\b([0-9.]+T)\b', reg):
    MENTIONED.add(m.group(1))
_lines = reg.split('\n')
for l in _lines:
    if l.lstrip().startswith('|'):
        cells = [c for c in re.split(r'(?<!\\)\|', l.strip().strip('|'))]
        if len(cells) > 1 and re.search(r'`[0-9a-f]{8,64}…?`', l):
            for b in re.findall(r'\b([0-9.]+T)\b', cells[0]):
                REACHED.add(b)
_heads = [i for i, l in enumerate(_lines) if re.match(r'^#{2,6} ', l)] + [len(_lines)]
for a, b in zip(_heads, _heads[1:]):
    body = '\n'.join(_lines[a + 1:b])
    if re.search(r'\b[0-9a-f]{64}\b', body):
        for bud in re.findall(r'\b([0-9.]+T)\b', _lines[a]):
            REACHED.add(bud)
# Q-967 (Q-835 A05#17): a disposition word counts only in the SAME SCOPE UNIT as the claim it
# disposes of: the sentence that carries it (a hard-wrapped sentence spans lines; a list item, a
# heading and a table row are units of their own). It was any DISPO word in a ±4/+3-line window
# (and ±400 characters for a budget-named run), so "A separate test completed yesterday." excused
# "The ladder build is in flight." on the next line.
_SB = re.compile(r'[.!?][*_)`\]"”’\']*\s+(?=\S)')
_ABBR = re.compile(r'(?:\b(?:e\.g|i\.e|vs|cf|al|approx|ca|resp|p|pp|no|Fig|Eq|Sec|Ch)|(?<![\w.])[A-Z])\.[*_)`\]"”’\']*$')
_UNIT_START = re.compile(r'^\s*(?:[-*+]\s|\d+[.)]\s|#{1,6}\s|\||>\s*[-*+]\s)')
# A key QUOTED in its unit, where the unit outside the quotation names what it is quoting, is
# narration of an old status ('was labelled "1000T (in flight)"'), not a status. Quotation marks
# alone are not enough (Q-835 A08#15 is the same class in GATES 30/31/33/38).
_QSPAN = re.compile(r'"[^"\n]*"|“[^”\n]*”')
_QVERB = re.compile(r'\b(?:labell?ed|read|reads|said|says|described|called|written|wrote|quoted?|phrase|wording)\b', re.I)
def quoted_narration(unit, key):
    spans = [m.span() for m in _QSPAN.finditer(unit)]
    k = unit.lower().find(key)
    if k < 0 or not any(a <= k < b for a, b in spans):
        return False
    return bool(_QVERB.search(_QSPAN.sub(' ', unit)))
# A dated revision-table row (`| v1.2 | 2026-07-05 | ... |`) is a record of the state AT that
# version, the role HISTORY.md plays for the whole corpus, so its tense is not a frozen status.
_REVROW = re.compile(r'^\s*\|\s*\*{0,2}v?\d+(?:\.\d+)*[^|]*\|\s*\*{0,2}20\d\d-\d\d-\d\d\*{0,2}\s*\|')
def unit_at(text, pos):
    """The scope unit (sentence, table row, heading, list item) of `text` holding offset `pos`."""
    ls = text.rfind('\n', 0, pos) + 1
    le = text.find('\n', pos); le = len(text) if le < 0 else le
    line = text[ls:le]
    if line.lstrip().startswith('|') or re.match(r'^#{1,6}\s', line):
        return line
    a = ls                                   # walk back to the paragraph / list-item start
    while a > 0:
        p = text.rfind('\n', 0, a - 1) + 1
        prev = text[p:a - 1]
        if not prev.strip() or prev.lstrip().startswith('|') or re.match(r'^#{1,6}\s', prev) or _UNIT_START.match(text[a:text.find('\n', a) if text.find('\n', a) >= 0 else len(text)]):
            break
        a = p
    b = le                                   # walk forward to the paragraph / list-item end
    while b < len(text):
        n = text.find('\n', b + 1); n = len(text) if n < 0 else n
        nxt = text[b + 1:n]
        if not nxt.strip() or _UNIT_START.match(nxt):
            break
        b = n
    para = text[a:b]
    off = pos - a
    masked = re.sub(r'`[^`\n]*`', lambda mm: 'x' * len(mm.group(0)), para)   # no sentence ends inside a code span
    cuts = [0] + [m.end() for m in _SB.finditer(masked) if not _ABBR.search(masked[:m.end()].rstrip())] + [len(para)]
    for x, y in zip(cuts, cuts[1:]):
        if x <= off < y:
            return para[x:y]
    return para
def unit_of(u, p):
    """unit_at for an md_parse block `u` (integration, batch 40). Q-965 joins a paragraph's lines with
    one space, drops list markers and removes backticks, so unit_at's own code-span mask cannot see
    them: the list item holding offset `p` is cut here, and a code span's text (taken from the RAW
    lines of that item) is masked before the sentence cut, as unit_at does on raw text -- else
    "`scp .../data/...`" ends a sentence at its "..." (DEVELOPMENT.md:1956)."""
    t = u['text']
    xs = [0] + [x for x in range(1, len(u['lines'])) if _MD_LIST.match(md_body(u['lines'][x][1]))] + [len(u['lines'])]
    for xa, xb in zip(xs, xs[1:]):
        a = u['starts'][xa]
        b = u['starts'][xb] - 1 if xb < len(u['lines']) else len(t)
        if a <= p <= b:
            break
    else:
        xa, xb, a, b = 0, len(u['lines']), 0, len(t)
    seg, off = t[a:b], p - a
    if seg.lstrip().startswith('|') or re.match(r'^#{1,6}\s', seg):
        return seg
    masked = seg
    for _ln, raw in u['lines'][xa:xb]:
        for cm in re.finditer(r'(`+)([^`\n]+?)\1', raw):
            c = md_inline(cm.group(2))
            if not re.search(r'[.!?]', c) or not re.search(r'[^.!?\s]', c): continue   # Fable B40 FIX 2: a span with no sentence-ender cannot hide a cut, and a bare `.` span must not mask every period
            q = seg.find(c) if c else -1      # found in seg, masked in `masked`: an earlier, shorter
            while q >= 0:                     # span ("/data") must not hide a longer one that holds it
                masked = masked[:q] + 'x' * len(c) + masked[q + len(c):]
                q = seg.find(c, q + len(c))
    cuts = [0] + [m.end() for m in _SB.finditer(masked) if not _ABBR.search(masked[:m.end()].rstrip())] + [len(seg)]
    for x, y in zip(cuts, cuts[1:]):
        if x <= off < y:
            return seg[x:y]
    return seg
import subprocess   # Q-969 (A05#19): the population is EVERY tracked .md, nested ones included (`git ls-files`, recursive); the old one-level globs never read reports/evidence/f1/README.md
files = [f for f in subprocess.run(['git', 'ls-files', '*.md'], capture_output=True, text=True, check=True).stdout.split('\n')
         if f and os.path.isfile(f) and f not in ('documentation/HISTORY.md', 'documentation/HISTORY_INDEX.md')]
if len(files) < 50: print(f"  [FAIL] GATE 7 population is {len(files)} tracked .md file(s) (floor 50): nothing like the corpus was read"); sys.exit(1)   # dated narrative is exempt by design; HISTORY_INDEX.md only quotes its headings, and GATE 91 proves it is a fresh generation from it (Q-686)
# Codex N10 finding 1: the exemption was `'HISTORY.md' not in f`, a SUBSTRING test, so it
# also exempted documentation/PERFORMANCE_HISTORY.md -- and anything else ending in the same
# eleven characters. That file said a 1T enumeration was "in flight" at line 352 while the
# same entry gave its FINAL ACCOUNTING at line 362, and this gate printed ok. The exemption
# is for ONE named file and is now written that way. (A second exact name since Q-686, 2026-09-26: the generated HISTORY_INDEX.md.)
for f in files:
    text = open(f, errors='replace').read()
    lines = text.split('\n')
    # Q-965 (A05#18): a status phrase is matched on the LOGICAL line -- a whole paragraph, md_inline'd
    # (emphasis, backticks, entities and runs of spaces folded) -- because "in\nflight." and
    # "in **flight**" are the same frozen status to a reader. Every other block kind is read per line.
    # NARRATION is read on the source line(s) the match spans; DISPO in the claim's own scope unit
    # (Q-967, below).
    _L, _k, blocks, _u = md_parse(text)
    units = []
    for b in blocks:
        if b['kind'] == 'para':
            units.append(b)
        else:
            for ln_, raw in (b.get('lines') or [(b['start'], lines[b['start'] - 1])]):
                units.append(md_para([(ln_, raw)]))
    for u in units:
        low = u['text'].lower()
        found = set()
        for k in LIVE:
            for mk in re.finditer(re.escape(k), low):
                p = mk.start()
                if k in WORDSTART and p > 0 and (low[p - 1].isalnum() or low[p - 1] == '_'):
                    continue
                # A program's own work units "in flight" (one block in flight, the cells in flight) are
                # not a run status. Measured when the paragraph join landed: the only two new matches in
                # the public corpus were exactly these, SOLVE_C_CLI.md ("one block in\nflight") and a
                # CORRECTIONS.md entry ("the cells in\nflight"), both hidden by their wraps before.
                if k == 'in flight' and re.search(r'\b(?:blocks?|cells?)\s+$', low[max(0, p - 12):p]):
                    continue
                # Q-969: the nested-doc population (reports/evidence/**) brought one PAST-tense use, "while these
                # runs were in flight" (wrap_mass_reseed/README.md). "was/were in flight" narrates; it is not a frozen status.
                if k == 'in flight' and re.search(r'\b(?:was|were)\s+$', low[max(0, p - 6):p]):
                    continue
                # (integration, batch 40) a NEGATED status claims nothing live: "The run is not in\nflight --
                # it landed 2026-07-16" (TR-11:332), visible only once Q-965 joined the wrap.
                if re.search(r'\b(?:not|never|no longer)\s+$', low[max(0, p - 11):p]):
                    continue
                i, j = md_lno(u, p), md_lno(u, mk.end() - 1)
                if i in found:
                    continue
                span = md_inline(' '.join(lines[i - 1:j])).lower()
                if any(n in span for n in NARRATION):
                    continue
                # Q-967 (A05#17): DISPO and the quoted-narration rule are read from the claim's OWN
                # scope unit (unit_of: its sentence, list item, table row or heading), no longer the
                # -4/+2 raw-line window; a dated revision-table row is a record as of its version.
                if _REVROW.match(lines[i - 1]):
                    continue
                ctx = unit_of(u, p).lower()
                if any(d in ctx for d in DISPO) or quoted_narration(ctx, k):
                    continue
                print(f"  [FINDING] {f}:{i} — status frozen in the present tense: \"{k}\"")
                print(f"            {lines[i - 1].strip()[:110]}")
                bad = 1
                found.add(i)
    # Q-965 (A05#18): "9999T  run" (two spaces) and a wrapped "9999T\nrun" read as the run name they are.
    # (integration, batch 40) the joins become '\n', one character like the ' ' they replace, so
    # offsets and md_lno are unchanged and Q-967's unit_at still sees row, heading and list-item lines.
    text, _starts = md_flatten(text)
    _tl = list(text)
    for _q in _starts[1:]:
        _tl[_q - 1] = '\n'
    text = ''.join(_tl)
    for m in re.finditer(r'\b(\d+(?:\.\d+)?T)\s+(run|campaign|enumeration)\b', text):
        if m.group(1) in REACHED:
            continue                      # budget was actually reached — correct name
        if m.group(1) not in MENTIONED and re.search(r'(?:~|≈|about |approximately )$', text[max(0, m.start() - 14):m.start()]):
            continue                      # "the ~154T run": a measured extent, not a budget it is named after; a MENTIONED budget ("~1120T run", the #65 shape) is still judged (Fable B40 FIX 1)
        para = unit_at(text, m.start()).lower()
        if any(d in para for d in DISPO):
            continue                      # disposition is stated nearby
        ln = md_lno(_starts, m.start())
        # SAY WHY IT IS NOT ATTESTED (2026-08-02, #65). "not a budget any canonical reached"
        # states the verdict but hides the test, and the two ways of failing that test need
        # different fixes: a budget absent from the registry may be a typo or an invented run,
        # while one PRESENT but sha-less is the 1120T shape — a real number quoted from a
        # projection sentence and then written up as though it had been run. Operator rule:
        # completion is attested by a sha256 in CANONICAL_HASHES.md, nothing weaker.
        why = ("appears in documentation/CANONICAL_HASHES.md but with no sha of its own (no table "
               "row naming it beside a sha, no section headed by it holding one) — mentioned is not attested"
               if m.group(1) in MENTIONED else
               "does not appear in documentation/CANONICAL_HASHES.md at all")
        print(f"  [FINDING] {f}:{ln} — \"{m.group(0)}\" names a run after budget {m.group(1)}, which")
        print(f"            {why}, and no disposition is stated nearby.")
        print(f"            sha-attested budgets: {', '.join(sorted(REACHED)) or '(none)'}")
        bad = 1
if not bad:
    print("  [ok] no frozen run status; every budget-named run carries a disposition")
sys.exit(bad)
PY
} | python3 -
}

# ---------------------------------------------------------------------------
# GATE 9 — the technical-report banner must be byte-identical across every TR,
# and must not re-assert the over-claim it replaced.
#
# WHY (2026-08-01, unit d72-banner): all 11 reports opened with
#   "Every claim is machine-verifiable; see the Verification Guide."
# which is FALSE as written — TR-8 says so about ITSELF in its executive summary's
# "Reproducibility flag": the dof-matched baseline has no artifact, command, seed or code
# path anywhere in the repo. reports/README.md had already been corrected to
# disclose the exceptions, so the suite was publishing one standard in its index
# and a stronger, false one on all 11 covers.
#
# The banner is the single most-copied string in the corpus — exactly the shape
# that drifts silently. Before this gate existed it ALREADY had: TR-2 and TR-8
# carried "…see the Verification Guide below." while nine others did not, and
# nothing in the repo could see it. That two-variant split is this gate's
# known-answer anchor: it was verified to FAIL on the pre-fix tree, naming those
# two files, before the corrected banner was applied.
#
# Byte-identity ALONE is not enough — eleven files reverted together are still
# byte-identical. So the gate also pins the discriminating clause, bans the
# retracted over-claim, and holds reports/README.md to the same clause so the
# index cannot drift back to a blanket promise.
#
# SAFETY: fixed-string containment and endswith() only — no regex at all.
# ITEM A2 (2026-08-02) — THE TWO QUESTIONS. GATE 9 does not normalise at all: the blocks
# are compared byte-for-byte. Its normalisation-equivalent is the SEGMENTATION rule — which
# lines count as "the banner" — and that carries exactly the same kind of claim.
#
# Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? Nothing inside the block; the comparison is
#     byte-wise. What it erases is everything OUTSIDE it. The block starts at the single
#     line containing "not peer-reviewed" and ends at the first line whose text ends in `*`.
#
# Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? Any divergent sentence placed AFTER
#     that closing italic. MEASURED across the suite (re-derived 2026-08-03, authorship-disclosure
#     banner): every one of the 11 TR banner blocks is exactly 6 lines (cap 8) and the index's is
#     15 (cap 24) — so no block is being
#     truncated by an early `*` today. But TR-10 carries its own italic *Scope note (F-34)*
#     paragraph on the very next line, and that paragraph is invisible to this gate. That is
#     correct behaviour (a per-report scope note is not banner drift) and it is also the
#     demonstration: "byte-identical across every report" is a claim about the 3 lines this
#     rule selects, not about what a reader sees under the heading.
gate_banner() {
  echo "== GATE 9: report banner byte-identical across all TRs =="
  { _md_norm_prelude; cat <<'PY'
import glob, sys

MARK    = 'not peer-reviewed'
KEEP    = 'argued, not verified'          # the discriminating scope clause
RETRACT = 'Every claim is machine-verifiable'
MAXBLK  = 8                               # a REPORT banner is a short italic block
MAXIDX  = 24                              # the INDEX banner also enumerates the exceptions

def block(path, cap=MAXBLK):
    """Return (block_text, marker_line_count, 1-based line no) for the banner.

    `cap` is per-role and not cosmetic. The first version of this gate used the
    tight report cap of 8 for reports/README.md too; the index banner is 11+
    lines because it names each disclosed exception, so the gate reported it as
    "never closed its italic" and the index check never actually ran. It looked
    like a finding and was a bug in the checker — caught only because the gate
    was run against its known-answer anchor before being trusted.
    """
    lines = open(path, errors='replace').read().split('\n')
    hits = [i for i, l in enumerate(lines) if MARK in l]
    if len(hits) != 1:
        return None, len(hits), 0
    i = hits[0]
    blk = []
    for l in lines[i:i + cap]:
        blk.append(l)
        # Q-965 (A05#20): a line ending in a BOLD close (`**argued, not verified**`) does not close
        # the italic. Ending the block there let every line after it, the retracted over-claim
        # included, sit outside the block this gate compares and checks. Drop `**` runs first.
        if l.rstrip().replace('**', '').endswith('*'):      # closing italic marker
            return '\n'.join(blk), 1, i + 1
    return None, -1, i + 1                # never closed its italic within `cap`

trs = sorted(glob.glob('reports/TR*.md'))
bad = 0
variants = {}                             # block text -> [file:line]
if not trs:
    print('  [FAIL] no reports/TR*.md found — wrong working directory?')
    sys.exit(1)

for f in trs:
    blk, n, ln = block(f)
    if blk is None:
        bad = 1
        if n == -1:
            print(f'  [FAIL] {f}:{ln} — banner never closes its italic within {MAXBLK} lines')
        else:
            print(f'  [FAIL] {f} — expected exactly 1 line containing "{MARK}", found {n}')
        continue
    variants.setdefault(blk, []).append(f'{f}:{ln}')

print(f'  scanned {len(trs)} reports/TR*.md; {len(variants)} distinct banner(s)')

if len(variants) > 1:
    bad = 1
    print(f'  [FAIL] the banner is NOT byte-identical: {len(variants)} variants in use')
    ranked = sorted(variants.items(), key=lambda kv: -len(kv[1]))
    for n, (blk, files) in enumerate(ranked, 1):
        print(f'    variant {n} — {len(files)} report(s): {", ".join(files)}')
        for l in blk.split('\n'):
            print(f'        | {l}')
    # WHY it fired, not just THAT it fired: name the line where two variants diverge.
    a = ranked[0][0].split('\n')
    b = ranked[1][0].split('\n')
    for i in range(max(len(a), len(b))):
        x = a[i] if i < len(a) else '<no line>'
        y = b[i] if i < len(b) else '<no line>'
        if x != y:
            print(f'    first divergence at block line {i + 1}:')
            print(f'        variant 1 > {x}')
            print(f'        variant 2 > {y}')
            break

# Q-965 (A05#21): the scope clause and the over-claim are matched on the NORMALISED block (md_inline:
# hard wraps, emphasis, backticks, entities and curly quotes folded), so "Every claim is\nmachine-
# verifiable" is the over-claim it reads as. Byte-identity above still compares the raw block.
for blk, files in variants.items():
    if RETRACT in md_inline(blk):
        bad = 1
        print(f'  [FAIL] the retracted over-claim "{RETRACT}" is back in: {", ".join(files)}')
    if KEEP not in md_inline(blk):
        bad = 1
        print(f'  [FAIL] banner lacks its scope clause "{KEEP}" in: {", ".join(files)}')

# The index must not promise more than the covers do.
idx = 'reports/README.md'
iblk, n, ln = block(idx, MAXIDX)
if iblk is None:
    bad = 1
    print(f'  [FAIL] {idx} — no single well-formed banner block (marker lines: {n})')
elif RETRACT in md_inline(iblk):
    bad = 1
    print(f'  [FAIL] {idx}:{ln} — index banner re-asserts "{RETRACT}"')
elif KEEP not in md_inline(iblk):
    bad = 1
    print(f'  [FAIL] {idx}:{ln} — index banner lacks "{KEEP}"; the index may not')
    print(f'         promise more than the {len(trs)} report covers do')

if not bad:
    first = next(iter(variants)).split('\n')[0]
    print(f'  [ok] all {len(trs)} TR banners byte-identical; scope clause present; index aligned')
    print(f'       | {first}')
sys.exit(bad)
PY
} | python3 -
}

# ---------------------------------------------------------------------------
# GATE 12 — a TR's revision history must be well-formed.
#
# WHY (item A4, filed round 1, written round 5 against MEASURED data): TR-1 shipped two
# rows both numbered v1.21 for a day and nothing in the repo could see it. The revision
# table is how every correction in this suite is attested, so a malformed one breaks the
# audit trail the corrections ledger and GATES 3/3b/10/11 all lean on.
#
# THE GATE FOUND TWO LIVE INSTANCES THE MOMENT IT WAS WRITTEN, both the same mistake and
# both PRE-EXISTING (neither introduced by this unit):
#   reports/TR8_REORDERING_REVISITED.md — `85d3b2c` added v1.11 by REPLACING the v1.10
#     line and re-adding v1.10 underneath, so the newest row was PREPENDED: dates ran
#     2026-08-02 then 2026-08-01, and `*(current)*` was not the last row.
#   reports/TR4_SIZE_OF_THE_SPACE.md — same shape, v1.16 above v1.15. Its two dates are
#     BOTH 2026-08-01, so the date leg alone does NOT see it; that is why the version-order
#     and current-is-last legs exist rather than the single "dates ascending" the item asked
#     for. A gate written to the item's letter would have cleared TR-4.
#
# SCOPE, and why it is exactly this: `git ls-files 'reports/TR*.md'`. Measured 2026-08-02 —
# all 11 TRs carry exactly one `## Revision history` heading; no file under documentation/
# carries one at all; reports/METHODS.md and reports/README.md have no revision rows and are
# not TRs. Rows are read only AFTER that heading, so a table elsewhere in the file whose
# first cell happens to start with `v` cannot be mistaken for a revision row.
#
# THE ONE TOLERATED DUPLICATE, measured not assumed: TR-11 carries three `v1.0-draft` rows
# (its lines 630-632), which are legitimate — a draft label is not a released version
# number. The exemption is therefore keyed on the SUFFIX (`v1.0-draft` vs `v1.0`), not on a
# filename or a line number, so it cannot silently widen. A repeat of a RELEASED number is a
# FAIL and is mutation-tested below.
#
# WHAT THIS GATE CANNOT SEE, stated rather than implied. (i) A revision row whose PROSE
# misdescribes what changed — it checks the table's shape, never its truthfulness; the
# defect TR-11 v1.15 records (a row asserting a propagation that had not happened) is
# invisible here. (ii) A missing row: a body edit that never got a revision entry at all
# leaves a perfectly well-formed table. (iii) TR-9's revision block is interrupted by a
# stray `*Draft-stage corrections (2026-07-04)*` paragraph between v1.10 and v1.11 (an
# already-filed operator item); this gate reads rows, not contiguity, so it does not fire on
# that and must not be read as clearing it.
gate_revhist() {
  echo "== GATE 12: TR revision histories (versions, dates, one current) =="
  { _md_norm_prelude; cat <<'PY'
import re, subprocess, sys

HEAD = '## Revision history'
ROW  = re.compile(r'^\|\s*(v[0-9][^|]*?)\s*\|\s*([^|]*?)\s*\|')
VER  = re.compile(r'^v(\d+)\.(\d+)(.*)$')
DRAFT = re.compile(r'^-draft$', re.I)
DATE = re.compile(r'^\d{4}-\d{2}-\d{2}$')

out = subprocess.run(['git', 'ls-files', 'reports/TR*.md'],
                     capture_output=True, text=True)
trs = sorted(p for p in out.stdout.split('\n') if p)
bad = 0
# ROW CENSUS (item B9, round 9, 2026-08-02). The pass line counted FILES, and the file count
# does not move when a row is added — so GATE 12's negative control ("a repeated DRAFT label
# is exempt") could pin only `no repeated released version`, a phrase printed whenever the
# leg runs at all. The control INSERTS a revision row; a row count moves with it, and its
# ERE now pins the post-injection total. What it still cannot prove is that the inserted row
# was checked for the DRAFT-suffix exemption specifically — only that it was parsed as a row.
rows_seen = 0
if not trs:
    print('  [FAIL] git tracks no reports/TR*.md — wrong working directory, or the suite is gone')
    sys.exit(1)

for f in trs:
    # Enumerated from the INDEX, opened from the WORKTREE (item A1, hole (b)). A tracked TR
    # deleted from the tree would otherwise vanish from a glob and be reported as nothing at
    # all. The corpus preflight also catches this; the message is worded differently on
    # purpose so a fire-proof can tell the two apart.
    try:
        lines = open(f, encoding='utf-8', errors='replace').read().split('\n')
    except OSError as e:
        print(f'  [FAIL] {f} is tracked but could not be read ({e.__class__.__name__}) —')
        print('         a revision history that cannot be opened has not been checked')
        bad = 1
        continue

    start = next((i for i, l in enumerate(lines) if l.strip() == HEAD), None)
    if start is None:
        print(f'  [FAIL] {f} — no "{HEAD}" heading; every TR must carry one')
        bad = 1
        continue

    rows = []                       # (1-based line, version cell, date cell)
    # Q-965 (A05#22): rows come from the shared normaliser's tables, so a row indented one space or
    # written without edge pipes is a row (` | v1.0 | ... |` passed as invisible before).
    for blk in md_parse('\n'.join(lines))[2]:
        if blk['kind'] != 'table' or blk['start'] <= start:
            continue
        for ln, cells in [blk['header']] + blk['rows']:
            if len(cells) >= 2 and re.match(r'v[0-9]', cells[0]):
                rows.append((ln, cells[0].strip(), cells[1].strip()))
    if not rows:
        print(f'  [FAIL] {f}:{start + 1} — "{HEAD}" heading with no version rows under it')
        bad = 1
        continue
    rows_seen += len(rows)

    keys, released, prev_date, prev_key = [], [], None, None
    for ln, ver, date in rows:
        plain = ver.replace('*(current)*', '').strip()
        m = VER.match(plain)
        if not m:
            print(f'  [FAIL] {f}:{ln} — version cell "{plain}" is not vN.N')
            bad = 1
            keys.append(None)
            continue
        key, suffix = (int(m.group(1)), int(m.group(2))), m.group(3).strip()
        keys.append(key)
        # SUFFIX-KEYED exemption: `v1.0-draft` is a draft label, not a released number, so
        # repeats of it are legitimate (TR-11 x3). `v1.0` repeated is not.
        # 🔴 Q-283 / Codex N10 finding 7 — reproduced on the PUBLISHED suite 2026-08-27. This read
        # `if not suffix:`, so a version was checked for duplication ONLY when it had no suffix at
        # all — meaning EVERY suffix (`-rc1`, `-final`, anything) silently exempted it. Measured:
        # two identical `v1.21-rc1` rows planted in TR9 left GATE 12 reporting
        #   [ok] ... no repeated released version
        # at rc=0, asserting exactly what was false. Only the DRAFT label may repeat.
        if not DRAFT.match(suffix):
            released.append((plain, ln))
        if not DATE.match(date):
            print(f'  [FAIL] {f}:{ln} — date cell "{date}" is not YYYY-MM-DD, so this row\'s')
            print('         position in the history cannot be checked')
            bad = 1
        else:
            if prev_date and date < prev_date:
                print(f'  [FAIL] {f}:{ln} — dates run BACKWARDS: {prev_date} (row above) then {date}')
                print('         A revision table is chronological; a newer row was prepended, not appended.')
                bad = 1
            prev_date = date
        if prev_key and key < prev_key:
            print(f'  [FAIL] {f}:{ln} — versions run BACKWARDS: v{prev_key[0]}.{prev_key[1]}'
                  f' (row above) then {plain}')
            bad = 1
        prev_key = key

    seen = {}
    for plain, ln in released:
        if plain in seen:
            print(f'  [FAIL] {f}:{ln} — released version {plain} is already used at line {seen[plain]}')
            print('         (only the draft label -draft may legitimately repeat; every other')
            print('          version, suffixed or not, is a released number and must be unique)')
            bad = 1
        else:
            seen[plain] = ln

    cur = [(ln, ver) for ln, ver, _ in rows if '(current)' in ver]
    if len(cur) != 1:
        where = ', '.join(f'{f}:{ln}' for ln, _ in cur) or 'nowhere'
        print(f'  [FAIL] {f} — expected exactly one *(current)* row, found {len(cur)} ({where})')
        bad = 1
    elif cur[0][0] != rows[-1][0]:
        print(f'  [FAIL] {f}:{cur[0][0]} — *(current)* is not the LAST revision row '
              f'(last is line {rows[-1][0]}, {rows[-1][1]})')
        print('         The current version is by definition the newest; a table whose newest')
        print('         row is not at the bottom was appended to in the wrong place.')
        bad = 1

if not bad:
    print(f'  [ok] {len(trs)} TR revision histories, {rows_seen} revision row(s) checked: '
          'one *(current)* each and last, '
          'no repeated released version, dates and versions ascending')
sys.exit(bad)
PY
} | python3 -
}

# ----------------------------------------------------------------------------------
# GATE 13 — a TR body edit must carry a revision row. REPORT-ONLY, and the measurement
# below is the reason it is report-only rather than the reason it might become blocking.
#
# WHY (item A4, filed round 5 in GATE 12's own header as the LARGER hole): GATE 12 checks a
# revision table's SHAPE. Its stated blindness (ii) is "a missing row: a body edit that never
# got a revision entry at all leaves a perfectly well-formed table". That is not theoretical —
# reports/TR4_SIZE_OF_THE_SPACE.md v1.13 exists ONLY to record, after the fact, a §3 edit that
# shipped with no row. This gate looks for that shape directly: a commit (or a working tree)
# that changes a TR's body and adds no `| vN.N |` row to the same file.
#
# MEASURED BEFORE WRITING A SINGLE VERDICT, over every commit that touched reports/TR*.md
# as of `2231e5e`: **102 of 131 would be flagged.** Not a long tail either — they clustered
# in the suite's most recent working days. A BLOCKING gate here would not be enforcing this
# suite's rule; it would be announcing that the suite has never followed it. So this gate
# returns 0 unconditionally and prints `[note]`, in the same class as GATES 1, 5 and 5b.
# **Escalating it to [FAIL] is an operator decision and needs that ratio RE-DERIVED, not
# this one**, together with a decision about the three false-positive classes below — it is
# not a drain unit's call and was not taken as one.
#
# THE RATIO IS PINNED TO A SHA BECAUSE THE DENOMINATOR ONLY GROWS, and this comment is its
# own evidence. It shipped at `2231e5e` as "all 131 commits", with the tail spelled out as
# "13 are dated 2026-08-02 and 10 are 2026-08-01". 131 was exact at that commit. By round
# 12 the denominator had moved and the 2026-08-01 bucket had MORE THAN DOUBLED — a bucket
# for a date already in the PAST, which is the counter-intuitive part and the reason no
# LIVE bucket is stated any more (the two superseded ones are quoted above only to name
# what drifted): commits carrying that author date kept landing after the measurement was
# taken, so the tail is not stable even for a day that has closed.
# Re-derive the denominator and the tail with
#   git log --format=%H -- 'reports/TR*.md' | wc -l
#   git log --format='%ad' --date=short -- 'reports/TR*.md' | sort | uniq -c
# The NUMERATOR is deliberately not given a one-liner: it needs THIS gate's per-commit rule
# replayed over that list, and an escalation decision should pay for that rather than read a
# frozen number off a comment. SAID PLAINLY: round 12 drain-3 re-derived the DENOMINATOR and
# the buckets and did NOT re-derive the 102 — so 102 is carried forward on `2231e5e`'s
# authority, which is the whole reason it is now pinned to that sha instead of floating.
# Found by round 12 drain-3's `R11` sweep.
#
# THE THREE THINGS A `[note]` DOES NOT MEAN, all measured on real commits, not imagined:
#   (i)  A CROSS-CUTTING EDIT RECORDED IN THE LEDGER INSTEAD. `14d8751` rewrote the
#        not-peer-reviewed banner on all ELEVEN report covers and added no revision row to
#        any of them — and it is properly recorded, as CORRECTIONS.md CX-16 / RP-a823340f.
#        This gate reads diffs, never the ledger, so it notes all eleven. That single commit
#        is 11 of the 102.
#   (ii) A ROW THAT LANDS IN THE NEXT COMMIT. The check is per-commit: edit the body, commit,
#        then add the row, and the first commit is noted for a rule that was ultimately kept.
#   (iii) A ROW THAT LIES. GATE 12's blindness (i) is untouched here — TR-11 v1.15 records a
#        row that ASSERTED a propagation which had not happened, and a row like that satisfies
#        this gate completely. Presence is all that is checked. Nothing in this suite reads a
#        revision row's prose against the diff it claims to describe.
#
# SCOPE, and why two legs rather than one:
#   WORKTREE — `git diff HEAD -- reports/TR*.md`. This is the only leg that can PREVENT the
#     defect rather than record it, because it is the one that runs before the commit exists.
#     It costs nothing on a clean tree, which is most runs.
#   BATCH — a commit range, default `origin/main..HEAD` (the stack not yet pushed, i.e. the
#     one still under review) and overridable with $DOC_GATE_REVROW_RANGE. Merges are skipped:
#     `git show` on a merge prints a combined diff that is empty by default, so a merge would
#     be silently classified as "no body change" and the skip is stated rather than implied.
#     With no `origin/main` — a fresh clone, a detached checkout — the leg says so and does
#     not run; it does not pretend to have checked.
#
# COST FORMULA, evaluated before writing it (box rule): C commits in range x F touched TRs,
# one single-file `git show` each, F <= 11. Default C is the unpushed stack (single digits
# today); the self-test's ranges are one commit each, so <= 12 subprocess calls per assertion.
# Nothing accumulates across iterations.
gate_revrows() {
  echo "== GATE 13: TR body edits carry a revision row (REPORT-ONLY) =="
  python3 - <<'PY'
import os, re, subprocess, sys

ROW = re.compile(r'^([+-])\|\s*v\d+\.\d+')

def sh(*a):
    return subprocess.run(list(a), capture_output=True, text=True).stdout

def classify(diff):
    """(added revision rows, changed body lines) for ONE file's diff.

    Classification starts only after the first @@ hunk header, so the `---`/`+++` file
    headers can never be mistaken for content — a removed markdown rule (`---`) appears
    as `----` and would otherwise be indistinguishable from the header by prefix alone.
    Blank-only changes are not body changes; a revision row is counted on the + side only.
    """
    rows = body = 0
    in_hunk = False
    for l in diff.split('\n'):
        if l.startswith('@@'):
            in_hunk = True
            continue
        if not in_hunk or l.startswith('\\'):
            continue
        if l[:1] in '+-':
            if ROW.match(l):
                if l[0] == '+':
                    rows += 1
                continue
            if l[1:].strip():
                body += 1
    return rows, body

notes = []

# --- LEG 1: the working tree, the only leg that can catch this before it is committed.
wt = [f for f in sh('git', 'diff', '--name-only', 'HEAD', '--', 'reports/TR*.md').split('\n') if f]
for f in wt:
    rows, body = classify(sh('git', 'diff', '--unified=0', 'HEAD', '--', f))
    if body and not rows:
        notes.append(f'  [note] WORKTREE {f} — {body} body line(s) changed vs HEAD, no revision row added')
if not wt:
    print('  [ok] working tree: no uncommitted TR edit')

# --- LEG 2: a commit range. Default is the stack that is not yet pushed.
rng = os.environ.get('DOC_GATE_REVROW_RANGE', '').strip()
if not rng:
    if subprocess.run(['git', 'rev-parse', '--verify', '--quiet', 'origin/main'],
                      capture_output=True).returncode == 0:
        rng = 'origin/main..HEAD'
    else:
        print('  [note] no origin/main in this clone, so the BATCH leg did NOT run.')
        print('         Set DOC_GATE_REVROW_RANGE=<rev-range> to check a range explicitly.')
        rng = None

if rng:
    commits = [c for c in sh('git', 'rev-list', '--no-merges', rng).split('\n') if c]
    print(f'  [ok] batch leg range {rng}: {len(commits)} non-merge commit(s) examined'
          if commits else f'  [ok] batch leg range {rng}: no non-merge commits to examine')
    for c in commits:
        files = [f for f in sh('git', 'show', '--name-only', '--format=', c,
                               '--', 'reports/TR*.md').split('\n') if f]
        for f in files:
            rows, body = classify(sh('git', 'show', '--unified=0', '--format=', c, '--', f))
            if body and not rows:
                notes.append(f'  [note] {c[:8]} {f} — {body} body line(s) changed, no revision row added')

CAP = 25
for n in notes[:CAP]:
    print(n)
if len(notes) > CAP:
    print(f'  [note] ... and {len(notes) - CAP} more (capped at {CAP}; widen the range deliberately)')
if notes:
    print('  (report-only. A note is a QUESTION — "was this edit meant to be recorded?" — not a')
    print('   verdict. It cannot see a change recorded in CORRECTIONS.md instead, a row added in')
    print('   the NEXT commit, or a row whose prose misdescribes the edit it claims to record.)')
else:
    print('  [ok] every examined TR body edit carries a revision row in the same commit')
sys.exit(0)   # report-only gate — never blocks
PY
  return 0
}

