#@ scripts/doc_gates.d/40_generated_appendonly_ledger_regdupes.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATE 8 (generated), 10a/10b (appendonly), 11 (ledger), 14 (regdupes).
#@ Lines 7887-9189 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ---------------------------------------------------------------------------
# GATE 8 — generated artifacts must match their generator.
#
# WHY (2026-08-01, two independent instances in one day):
#  (a) example/README.md was a hand-edited copy of example/report.md. They
#      differed by exactly one line — "keeps COMPLEMENTS unusually near one
#      another" where roae.py:774 emits "OPPOSITES". Someone edited the artifact
#      instead of the source, and it survived indefinitely.
#  (b) I did the same thing while fixing the C8 defect: patched roae.py AND
#      string-patched the four shipped artifacts, two independent routes to the
#      same text. Committed in dbba77d, caught by the operator, reverted.
#
# No other gate covers this. Retraction, link, status, number and liveness gates
# all pass on a hand-edited artifact, because the text is not retracted, the
# links resolve and the numbers are self-consistent. The defect is only visible
# by RE-RUNNING THE GENERATOR.
#
# Comparison is BYTE-EXACT since 2026-09-04, on all eleven tracked example/ artifacts.
# It was DIGIT-STRIPPED for the four report artifacts until then, and the reason was real:
# roae.py seeded nothing by default, so its Monte Carlo figures legitimately changed every
# run and a byte-diff would have failed always — a gate that goes red on correct artifacts
# is a gate that gets switched off. THE PREMISE IS GONE, not the reasoning. example/ is now
# regenerated and shipped under `--seed $ROAE_EXAMPLE_SEED` (declared once, just above
# gate_generated), and every regeneration in this gate passes the same seed, so the shipped
# artifact and the fresh run agree byte for byte on a correct tree. The digit-stripped
# comparison survives as a DIAGNOSTIC that classifies a failure (numeric-only vs prose), not
# as the verdict.
#
# WHAT THAT BOUGHT, in one sentence, because this is the whole point of the change: a
# hand-edited NUMBER in example/report.txt, report.md, README.md or report.html now fires.
# Before it, report.txt and report.html were covered by NOTHING — measured on the live tree
# the same morning, `8x8 = 64` -> `65` in example/report.html left `doc_gates.sh generated`
# at rc 0, PASS — and the README/report.md pair was covered by leg 6 alone.
#
# WHAT IT COSTS, stated because the seed is not free: every number in example/ is now ONE
# FIXED DRAW rather than a fresh sample per run. No CLAIM depends on those figures (they are
# an example bundle, not evidence), but a reader must not read a frozen draw as a converged
# value. roae.py prints the seed INTO the three report artifacts for exactly that reason, and
# documentation/CORRECTIONS.md carries the entry.
#
# COVERAGE, stated exactly (extended 2026-08-02, item A2; narrowed 2026-09-04 by LEG 5's
# retirement; widened to byte-exact the same day by the seed). Until
# 2026-08-02 the gate covered report.txt, report.md and README.md only — example/report.html
# and example/report.pdf were shipped generator-derived artifacts with NO generator-match
# check of any kind, and report.html is the file that was hand-patched in dbba77d. Item A2
# covered both, by two DIFFERENT strategies, because a PDF cannot be line-diffed:
#
#   report.html  -> compared against a fresh `roae.py --html --seed $ROAE_EXAMPLE_SEED`
#                   (like-for-like, same as the other three: BYTE-EXACT since 2026-09-04,
#                   digit-stripped line diff in both directions before that).  LIVE.
#   report.pdf   -> LEG 5, RETIRED 2026-09-04 with the artifact itself. It compared the
#                   PDF against the SHIPPED example/report.html, by extracting the PDF's
#                   text with pdftotext and the HTML's text by tag-stripping, then
#                   comparing the two as MULTISETS of lines WITH DIGITS INTACT.
#
# WHY IT IS GONE AND WHAT WENT WITH IT. example/report.pdf was deleted from the repository
# on 2026-09-04: wkhtmltopdf embeds the fonts it renders with, and `pdffonts` on the shipped
# artifact reported DejaVuSans, DejaVuSans-Bold and DejaVuSansMono, all `emb yes sub no` —
# the complete unsubsetted font programs, inside a tracked file, in a repository that is
# otherwise public domain. That made the project a redistributor of font software under the
# Bitstream Vera terms, whose grant is conditioned on the notice travelling with any copy.
# roae.py's export_html no longer shells out to wkhtmltopdf, so nothing produces a PDF to
# compare. The leg's ARGUMENT was sound and is recorded because it is the argument any
# replacement would have to reproduce: wkhtmltopdf(report.html) was the ONLY route by which
# report.pdf was produced, inside ONE `--html` invocation, so "the PDF's text equals the
# shipped HTML's text" was exactly the derivation invariant — deterministic, costing no
# regeneration, and strict about DIGITS where legs 1-4 cannot be. (Regenerating a PDF and
# diffing it would instead have compared two renderings whose page breaks move whenever a
# Monte Carlo figure changes width — a gate that fails for reasons nobody can act on.)
# MEASURED at the time it shipped: on the artifacts as committed the two bags differed by
# exactly ZERO lines once <title>/<style>/<script> were stripped.
#
# 🔴 THE COST OF LEG 5's RETIREMENT, AND ITS CLOSE — BOTH ON THE SAME DAY, AND THE COST IS
# LEFT WRITTEN because a hole that was real for a few hours is not made unreal by having been
# closed. LEG 5 was the ONLY check that compared example/report.html digit-for-digit; when it
# went, report.html became digit-blind like report.txt and report.md and a hand-edited NUMBER
# in it was caught by nothing — the dbba77d class, uncovered again, and MEASURED as such
# (`8x8 = 64` -> `65`, `doc_gates.sh generated` rc 0, PASS). The close is the one this note
# named as an operator decision: example/ was regenerated and reshipped under
# `--seed $ROAE_EXAMPLE_SEED` that afternoon, and legs 1-4 are byte-exact against a
# same-seed regeneration. The coverage came back through the PRIMARY comparison rather than
# through a second artifact of the same invocation, which needs no PDF, no second renderer,
# and no embedded font programs on the machine running the gate. Digit coverage across the
# four report artifacts is now ALL FOUR, each against its own generator.
#
# Cost: three roae.py runs (~45 s each, measured 2026-08-02 at 31 MB peak RSS), so this
# is NOT part of `all`. Run it before publishing. See DOC_GATES_GEN_CACHE below for how
# the self-test pays that cost ONCE across multiple invocations.
#
# DOC_GATES_GEN_CACHE (added 2026-08-02, item A1): a caller may name a directory to hold
# the regenerated reference artifacts. If it already holds a complete set generated from
# the CURRENT roae.py, it is reused instead of regenerating. This exists so the self-test
# can run several mutation cases for one regeneration; it is opt-in precisely because a
# silently-reused stale cache would be a false clear, and it self-invalidates on the only
# input that can change the answer — roae.py's own sha256.
# THE SEED example/ IS SHIPPED UNDER (2026-09-04). It is declared ONCE, here, and every
# regeneration below passes it, because a gate that regenerated under a different seed than
# the artifacts were published under would be red on a correct tree — the exact failure mode
# ("a gate that goes red at random on correct artifacts is a gate that gets switched off")
# this file already records for the digit-stripping. The value is the ISO date of the
# regeneration pass, chosen and written down BEFORE the first seeded run so it cannot have
# been picked for the figures it produces; it is published in documentation/ROAE_PY_CLI.md
# and printed INTO the report artifacts by roae.py's _seed_note(), so a reader holding
# example/report.md can read the seed off the file itself.
ROAE_EXAMPLE_SEED=20260904

gate_generated() {
  echo "== GATE 8: generated artifacts match their generator (seed $ROAE_EXAMPLE_SEED) =="
  # Compare LIKE FOR LIKE. The first draft diffed every artifact against `--all`
  # stdout, so the markdown files failed on their own headers -- a gate that
  # flags correct files gets switched off, which is the mistake ops_gates GATE 4
  # made the same day. Each artifact is now compared against the invocation that
  # actually produces it.
  #
  # BYTE-EXACT since 2026-09-04. This read "Digit-stripped: roae.py seeds nothing by default,
  # so Monte Carlo figures legitimately change every run" — true until example/ was reshipped
  # under `--seed $ROAE_EXAMPLE_SEED` and this gate started regenerating under the same seed.
  # Digit-stripping survives only as the failure classifier inside `_cmp`.
  local tmp rc=0 owned=0 cur_sha
  # ITEM A1 (tool half). This was a [skip], and roae.py IS python3 — without it the gate
  # regenerates nothing and compares nothing, while `generated` still exits 0. GATES 3b and 5
  # already invoke python3 with no guard at all, so a host without it cannot run this suite
  # anyway; saying so loudly beats attesting a comparison that never happened. NO FIRE-PROOF
  # COVERS THIS LEG — see the A1 note at the head of the file.
  command -v python3 >/dev/null 2>&1 || {
    echo "  [FAIL] python3 not on PATH — roae.py cannot be run, so nothing was regenerated"
    echo "         and nothing was compared. This is not a skip."
    return 1; }
  cur_sha=$(sha256sum roae.py 2>/dev/null | cut -d' ' -f1)
  # THE CACHE KEY CARRIES THE SEED AS WELL AS THE GENERATOR (2026-09-04). Before example/ was
  # seeded the only input that could change the reference was roae.py itself. It is not any
  # more: the same roae.py under a different --seed produces a DIFFERENT correct reference, so
  # a key on the sha alone would let a cache built at one seed clear a comparison at another —
  # a false clear of exactly the kind the sha key was introduced to prevent.
  local gen_key="${cur_sha}:seed=${ROAE_EXAMPLE_SEED}"

  if [ -n "${DOC_GATES_GEN_CACHE:-}" ]; then
    tmp="$DOC_GATES_GEN_CACHE"; mkdir -p "$tmp" || return 1
  else
    tmp=$(mktemp -d) || return 1; owned=1
  fi

  # Reuse only if the cache is COMPLETE and was built from THIS roae.py. A cache keyed on
  # nothing would turn a stale directory into a false clear — the failure mode this whole
  # suite exists to stop — so the key is the generator's own sha256, the only input that
  # can change what the reference should be.
  # 🔴 Q-971 (b) (2026-10-03, batch 40; Codex (gpt-6-astra), push-path review Q835, adjudicated
  # Q-962 R9). A miss used to remove only .roae_sha and regenerate OVER the old outputs, so an
  # exporter that wrote nothing left the previous run's report.md in place and it was compared
  # as if fresh (measured: PASS rc 0; the same break with no cache is rc 1). Now the key file
  # also records the sha256 of each output as it was generated, a reuse requires the key AND
  # every recorded digest to match the bytes on disk, and a miss removes ALL outputs before
  # regenerating, so an output the generator did not write this time is absent, not stale.
  # (Inheriting DOC_GATES_GEN_CACHE at push time is refused separately by pre_push_gate.sh's
  # Q-949 env guard, family DOC_GATES_*.)
  _gen_manifest() {   # the key, then one "sha256  name" line per output, in a fixed order
    printf '%s\n' "$gen_key"
    ( cd "$tmp" && sha256sum fresh.txt report.md report.html ) 2>/dev/null
  }
  if [ -s "$tmp/fresh.txt" ] && [ -s "$tmp/report.md" ] && [ -s "$tmp/report.html" ] \
     && [ -n "$cur_sha" ] && [ "$(cat "$tmp/.roae_sha" 2>/dev/null)" = "$(_gen_manifest)" ]; then
    echo "  reusing regeneration cache $tmp (roae.py sha256 $(printf '%.12s' "$cur_sha")… and seed $ROAE_EXAMPLE_SEED unchanged)"
  else
    # `--markdown` and `--html` are run WITHOUT `--all` and from inside $tmp, because that
    # is what the generator actually does: roae.py's main() short-circuits on args.markdown
    # (returns before the --all dispatch), and export_markdown()/export_html() open their
    # files in the CWD. Spelling it "--all --markdown > file" is the recipe that corrupted
    # example/ once already; the gate should not model it. (Function names, not line
    # numbers, on purpose — a recorded line number is the thing that drifts, cf. the
    # GATE 5 allowlist.)
    echo "  regenerating (3 runs, ~45s each, --seed $ROAE_EXAMPLE_SEED): --all to stdout, then --markdown and --html into a temp dir"
    rm -f "$tmp/.roae_sha" "$tmp/fresh.txt" "$tmp/report.md" "$tmp/report.html" || {
      echo "  [FAIL] could not clear the regeneration cache $tmp, so a stale output could be compared"
      [ "$owned" = 1 ] && rm -rf "$tmp"; return 1; }
    if ! timeout 300 python3 roae.py --all --seed "$ROAE_EXAMPLE_SEED" > "$tmp/fresh.txt" 2>/dev/null; then
      echo "  [FAIL] the generator itself did not run cleanly"; [ "$owned" = 1 ] && rm -rf "$tmp"; return 1
    fi
    # Codex v2 / fail-open class: these two runs had their exit status DISCARDED,
    # while the --all run above is checked. A failing --markdown then left no
    # report.md, and the "[skip] --markdown produced no report.md" arm below
    # returned 0 -- so a dead generator produced a PASS. Measured by stubbing
    # python3 to exit 1. Check both.
    if ! ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --markdown --seed "$ROAE_EXAMPLE_SEED" >/dev/null 2>&1 ); then
      echo "  [FAIL] the generator did not run cleanly for --markdown"
      [ "$owned" = 1 ] && rm -rf "$tmp"; return 1
    fi
    if ! ( cd "$tmp" && timeout 300 python3 "$OLDPWD/roae.py" --html --seed "$ROAE_EXAMPLE_SEED" >/dev/null 2>&1 ); then
      echo "  [FAIL] the generator did not run cleanly for --html"
      [ "$owned" = 1 ] && rm -rf "$tmp"; return 1
    fi
    [ -n "$cur_sha" ] && _gen_manifest > "$tmp/.roae_sha"
  fi
  # A missing artifact is NOT a skip. The generator was just run and checked, so an
  # absent report.md means the gate cannot see its target -- which must be an error,
  # never a pass. This arm returned 0 and was the second half of the same fail-open.
  [ -f "$tmp/report.md" ] || { echo "  [FAIL] --markdown produced no report.md — cannot compare what was not generated"; [ "$owned" = 1 ] && rm -rf "$tmp"; return 1; }

  # ITEM A2 (2026-08-02) — THE TWO QUESTIONS, ANSWERED BY RUNNING THE NORMALISER.
  # REWRITTEN 2026-09-04: the normaliser no longer decides any verdict, so Q1/Q2 are now
  # questions about a DIAGNOSTIC, and the answers that mattered are recorded as history
  # rather than as live caveats. What they were is kept, because the round-4 defect they
  # document is a live hazard for anyone who reaches for digit-stripping again.
  #
  # Q1. WHAT LEGITIMATE VARIATION DID IT ERASE? Every numeric difference, by design. roae.py
  #     seeded nothing by default (`_global_seed`, roae.py:23 — a `--seed` flag existed but
  #     the shipped artifacts were not produced with it), so Monte Carlo figures differed
  #     every run and a byte comparison would have failed always. THAT IS NO LONGER TRUE OF
  #     THIS GATE: example/ ships under `--seed $ROAE_EXAMPLE_SEED` and the regeneration above
  #     passes the same seed, so there is no legitimate numeric variation left to tolerate.
  #
  # Q2. WHAT ILLEGITIMATE VARIATION DID IT LET THROUGH? A HAND-EDITED NUMBER, and it was
  #     MEASURED twice, a month apart, on two different files:
  #       2026-08-02, example/report.txt: `111111` -> `911111`, rc 0, and the gate printed
  #         "[ok] example/report.txt matches roae.py --all exactly (digit-stripped, ...)"
  #       2026-09-04, example/report.html: `8x8 = 64` -> `65`, `doc_gates.sh generated` rc 0,
  #         PASS — taken AFTER LEG 5's retirement removed the only digit check on that file.
  #     GATE 1 covered neither: it iterates $DOCS = `git ls-files '*.md'`, and neither
  #     report.txt nor report.html is markdown. BOTH ARE NOW CAUGHT by the byte-exact
  #     comparison, and the second is CASE 6 in the self-test harness — the same mutation,
  #     wired in, so it cannot silently stop being caught.
  #
  # AN ATTEMPTED FIX THAT FAILED, recorded so it is not rebuilt — and it is worth MORE now
  # than when it was written, because it is the route somebody would try if the seed were
  # ever removed. Sample the generator TWICE and treat a line identical in both samples as
  # deterministic, requiring the artifact to match those lines with digits intact. IT
  # PRODUCES FALSE FAILS ON CORRECT ARTIFACTS. Measured: `Min pair-constrained observed:`
  # (roae.py:1413, `min(pair_totals)` over `random.random()` draws) read 192 in two
  # consecutive runs and 189 in the shipped artifact; three further samples gave 193, 190,
  # 192. A min over a narrow discrete range repeats often, so two agreeing samples are not
  # evidence of determinism, and no number of samples turns that into a sound inference. The
  # leg was written, run against the CORRECT artifacts, seen to fire, and reverted. It is only
  # because the negative control ran that this was caught before shipping. THE SEED IS THE
  # SOUND VERSION OF THE SAME IDEA: it does not INFER determinism, it IMPOSES it.
  #
  # WHAT CLOSED Q2 FOR EVERY LEG (2026-09-04) is the operator decision this note asked for:
  # ship example/ generated with `--seed`. It was taken, example/ was regenerated under
  # `--seed $ROAE_EXAMPLE_SEED`, and legs 1-4 are byte-exact. PROVEN BEFORE SWITCHING IT ON,
  # by running rather than by reasoning: two independent same-seed generations into scratch
  # directories were `cmp`-clean on all ELEVEN tracked example/ artifacts; a third generation
  # at a DIFFERENT seed differed on all FOUR report artifacts (and on none of the other
  # seven, which are closed-form) — the negative control without which byte-exactness could
  # have been an artefact of the seed never reaching the randomness at all.
  #
  # WHAT REMAINS UNCOVERED, kept in the place that used to list a longer set: an identical
  # hand-edit applied to BOTH example/report.md and example/README.md was invisible to leg 6,
  # which compares them only to each other. It is NOT invisible to legs 2 and 3, which now
  # compare each of them byte-exact against the generator, so that hole — named here since
  # 2026-08-02 — is closed too. What is left is the ordinary limit of every regeneration gate:
  # a defect introduced into roae.py ITSELF and then propagated into the artifacts is
  # consistent by construction and this gate cannot see it.
  #
  # THE DIGIT-STRIPPED NORMALISER IS RETAINED as a failure classifier only. `0 added,
  # 0 missing` after a byte mismatch means the prose is identical and only digits moved (a
  # hand-edit, or a regeneration under the wrong seed); non-zero counts mean the generator
  # changed. The GROUP-SEPARATOR fix below is load-bearing for that classifier and stays.
  #
  # THE GROUP SEPARATOR IS PART OF THE NUMBER (fixed 2026-08-02, round 4).
  # The first version stripped [0-9] and nothing else, so roae.py's `f"{ratio:,}"`
  # (roae.py:1458) left a bare comma behind whenever a Monte Carlo figure landed at
  # >= 1000 on one side of the comparison and < 1000 on the other:
  #     artifact  "Approximately 1 in 476 random orderings share this property."
  #               -> "Approximately in random orderings share this property."
  #     generator "Approximately 1 in 1,046 random orderings share this property."
  #               -> "Approximately in , random orderings share this property."
  # That was a FALSE FAIL and it fired in anger on `doc_gates.sh generated`. Digit-adjacent
  # commas are collapsed FIRST (the /g scan handles multi-group values: 1,234,567 -> 1234567),
  # then digits are stripped. Commas that are not between two digits — ordinary prose
  # punctuation — are untouched, so no sensitivity to hand-edited prose is given up.
  _norm() { sed -E 's/([0-9]),([0-9])/\1\2/g; s/[0-9]//g; s/[[:space:]]+/ /g' "$1" | grep -v '^ *$' | sort; }
  # BOTH DIRECTIONS. The first version compared one way only (`comm -13`: lines the
  # ARTIFACT has that the generator does not), so a pure DELETION from a shipped
  # artifact passed -- and passed while printing "matches ... exactly", which is the
  # same over-attestation this suite exists to catch. Demonstrated 2026-08-01 by
  # deleting the nuclear-attractor line from example/report.txt: the gate said [ok].
  # Substitutions were caught only because they leave an added line behind as well.
  # A MISSING shipped artifact is a FAILURE, not a skip (2026-08-02). Every leg below used
  # to `[skip]` on `! -f`, so `rm example/report.pdf` passed the gate in silence — the same
  # false-clear shape as the one-directional comparison, and reached the same way: by asking
  # what the gate does when its input is not there. (That artifact was itself removed on
  # 2026-09-04, and the rule is unchanged: it is `require_tracked`, keyed on what git tracks,
  # so it applies to whatever the legs below name TODAY. The sentence names report.pdf
  # because that is the file the defect was found on, not because the rule is about it.)
  # Absence is only a skip for an artifact git does not track; for a tracked one it is the
  # strongest possible mismatch.
  # Hoisted to the top of the file as `require_tracked` (item A1, 2026-08-02) once the same
  # shape was found in GATES 2, 3, 3b, 6, 10a, 10b and 11. One implementation, so a future
  # correction to the rule cannot land in six places and miss the seventh.
  _present() {   # <path>
    require_tracked "$1" "A shipped artifact that is absent is not a passing artifact — regenerate it."
  }
  # BYTE-EXACT SINCE 2026-09-04, AND THAT IS THE WHOLE POINT OF SEEDING example/.
  # Legs 1-4 stripped digits for as long as example/ was an UNSEEDED draw: roae.py re-sampled
  # its Monte Carlo figures every run, so a byte comparison would have been red on a correct
  # tree every time and the gate would have been switched off within a day. example/ is now
  # generated under --seed $ROAE_EXAMPLE_SEED, the regeneration above passes the same seed,
  # and the two are therefore equal BYTE FOR BYTE on a correct tree -- measured, not assumed,
  # before this was switched on (two independent seeded runs into scratch directories,
  # `cmp` clean on all eleven tracked example/ artifacts; a third run at a DIFFERENT seed
  # differed on all four report artifacts, which is what says the seed reaches the randomness
  # rather than the outputs merely being constant).
  #
  # WHAT THIS CLOSES, named because it is the defect the gate was built for: a hand-edited
  # NUMBER in example/report.txt, report.md, README.md or report.html. Until this change that
  # was caught by NOTHING for report.txt and report.html (measured on the live tree the same
  # day: `8x8 = 64` -> `65` in example/report.html left `doc_gates.sh generated` at rc 0,
  # PASS), and by leg 6 alone for the README/report.md pair. That is the dbba77d class, and it
  # is now caught four times over by the primary comparison itself.
  #
  # THE DIGIT-STRIPPED COMPARISON IS KEPT, DEMOTED TO A DIAGNOSTIC. It no longer decides the
  # verdict, but it is what tells a maintainer WHICH failure they have: `0 added, 0 missing`
  # after a byte mismatch means the prose is identical and only digits moved -- a hand-edited
  # number, or a regeneration under the wrong seed -- while non-zero counts mean the generator
  # itself changed. Deleting it would have thrown away the only cheap classifier this gate has.
  _cmp() {   # <artifact> <reference> <label>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    if cmp -s "$1" "$2"; then
      echo "  [ok]   $1 is BYTE-IDENTICAL to a fresh $3 --seed $ROAE_EXAMPLE_SEED (digits included)"
      return 0
    fi
    local extra missing
    extra=$(comm -13 <(_norm "$2") <(_norm "$1") | wc -l)
    missing=$(comm -23 <(_norm "$2") <(_norm "$1") | wc -l)
    echo "  [FAIL] $1 differs BYTE-FOR-BYTE from a fresh $3 --seed $ROAE_EXAMPLE_SEED -- hand-edited?"
    echo "         $1 digit-stripped: $extra added, $missing missing"
    if [ "$extra" -eq 0 ] && [ "$missing" -eq 0 ]; then
      echo "         The prose agrees in BOTH directions, so the difference is NUMERIC ONLY:"
      echo "         a hand-edited number, or a regeneration under a seed other than"
      echo "         $ROAE_EXAMPLE_SEED. Digits were not compared here before 2026-09-04."
    else
      comm -13 <(_norm "$2") <(_norm "$1") | head -3 | sed 's/^/           +added   > /'
      comm -23 <(_norm "$2") <(_norm "$1") | head -3 | sed 's/^/           -missing > /'
    fi
    diff "$2" "$1" | head -6 | sed 's/^/           /'
    echo "         Fix the SOURCE (roae.py) and regenerate; never edit the artifact."
    echo "         CAUTION (recipe corrected 2026-08-01): only --all writes to stdout."
    echo "         --markdown and --html OPEN THEIR OWN FILES in the cwd (roae.py's"
    echo "         export_markdown / export_html) and print only a status line, so"
    echo "         'roae.py --markdown > f' writes 'Markdown report written to"
    echo "         report.md' INTO f and leaves the real report at the repo root."
    echo "         Run them from example/ instead, AND PASS THE SEED -- an unseeded"
    echo "         regeneration will differ from the shipped artifacts on every"
    echo "         Monte Carlo figure and this gate will stay red:"
    echo "           python3 roae.py --all --seed $ROAE_EXAMPLE_SEED > example/report.txt"
    echo "           ( cd example && python3 ../roae.py --markdown --seed $ROAE_EXAMPLE_SEED )"
    echo "           cp example/report.md example/README.md"
    echo "           ( cd example && python3 ../roae.py --html --seed $ROAE_EXAMPLE_SEED )"
    return 1
  }
  _cmp example/report.txt  "$tmp/fresh.txt"   "roae.py --all"      || rc=1
  _cmp example/report.md   "$tmp/report.md"   "roae.py --markdown" || rc=1
  _cmp example/README.md   "$tmp/report.md"   "roae.py --markdown" || rc=1
  # Codex v2 charge 1, SIBLING SWEEP: the report.md arm of this pair was converted to a
  # [FAIL] (see the "A missing artifact is NOT a skip" note above) and this one was left
  # as a [skip] that does not move rc. Same carrier, same gate, one line apart: --html can
  # exit 0 and still leave no report.html (an exporter that catches its own error), and the
  # gate then attests report.html by not comparing it. Symmetric now.
  if [ -f "$tmp/report.html" ]; then
    _cmp example/report.html "$tmp/report.html" "roae.py --html"    || rc=1
  else
    echo "  [FAIL] --html produced no report.html — cannot compare what was not generated"
    echo "         example/report.html is shipped and tracked; an absent reference means this"
    echo "         leg did not run, which is a failure of the gate, not a pass for the file."
    rc=1
  fi

  # LEG 5 — RETIRED 2026-09-04, WITH example/report.pdf ITSELF.
  #
  # It compared example/report.pdf against example/report.html as MULTISETS of lines with
  # DIGITS INTACT, extracting the PDF's text with `pdftotext -layout` and the HTML's by
  # tag-stripping. It could be strict about digits — the only leg of this gate that was,
  # for report.html — because the two artifacts came out of ONE `roae.py --html`
  # invocation (export_html wrote the HTML and then shelled out to wkhtmltopdf to render
  # the PDF from it), so they agreed digit-for-digit BY CONSTRUCTION and any difference
  # was a hand-edit.
  #
  # WHY THE ARTIFACT WENT. wkhtmltopdf embeds the font programs it renders with. `pdffonts`
  # on the shipped example/report.pdf reported DejaVuSans, DejaVuSans-Bold and
  # DejaVuSansMono, every one `emb yes sub no` — the complete unsubsetted programs, not
  # subsets. A tracked file containing them makes this repository a redistributor of font
  # software under the Bitstream Vera terms, whose grant is conditioned on the notice
  # travelling with any copy, and that was the ONLY third-party obligation an otherwise
  # public-domain (Unlicense) project carried. Measured and rejected before the removal:
  # Symbola is licence-free and covers all 64 hexagram glyphs but is not monospaced (135
  # distinct advance widths in its first 399 glyphs) against 28 column-aligned <pre> blocks
  # totalling ~1,400 lines; naming Courier or generic `monospace` does not avoid embedding,
  # because wkhtmltopdf resolves through fontconfig and embedded DejaVuSansMono anyway
  # (tested); and no obligation-free monospace face exists on the reference host. So the
  # PDF was dropped rather than re-rendered, and roae.py's export_html no longer invokes
  # any PDF backend.
  #
  # 🔴 WHAT THIS LEG'S ABSENCE MEANT FOR THIS GATE'S VERDICT, kept in the past tense with the
  # hole it names, because a gap that was real for part of a day is not made unreal by being
  # closed later the same day: for a few hours example/report.html was compared by leg 4 ONLY,
  # which stripped digits, so a hand-edited NUMBER in it was caught by nothing. That is the
  # dbba77d class — the defect this leg was built for — and it was open again, MEASURED as
  # such (`8x8 = 64` -> `65`, rc 0, PASS). Its fire-proof (self-test CASE 6) was retired with
  # it, and the retirement was written at both sites rather than at one.
  #
  # WHAT CLOSED IT, the same afternoon and exactly as Q2 above predicted: example/ was
  # regenerated and reshipped under `--seed $ROAE_EXAMPLE_SEED`, legs 1-4 became byte-exact,
  # and no same-invocation partner is needed at all. CASE 6 is REINSTATED on the same
  # mutation, now asserting leg 4's byte-exact verdict instead of this leg's multiset one.
  # Rendering a PDF at gate time and comparing THAT would not have closed it — it
  # reintroduces the embedded font programs into the machine that runs the gate for no
  # coverage the seed does not give more cheaply, and it is the two-renderings comparison the
  # header rejects. The seed was the cheaper close and it is the one that was taken.
  #
  # THE NUMBER 5 IS LEFT UNUSED. Legs 6 and 7 keep their names; see the ITEM A1 note at the
  # head of this file for why a gap beats a renumbering.

  # LEG 6 — example/README.md is a COPY of example/report.md (item A2, 2026-08-02).
  #
  # Legs 2 and 3 compare each of them, separately, against a fresh `--markdown` run —
  # digit-stripped when this leg landed, byte-exact since 2026-09-04. Neither compares them TO
  # EACH OTHER, so before this leg the two shipped files could disagree on every number in the
  # corpus and this gate said [ok] twice. The production route is a copy — the gate's own
  # remediation text says `cp example/report.md example/README.md` — so the pair can be
  # compared BYTE-EXACT. MEASURED before switching it on: `cmp example/report.md
  # example/README.md` is byte-identical on the shipped tree.
  #
  # WHAT THIS LEG STILL CANNOT SEE, AND WHY THAT NO LONGER LEAVES A HOLE: an identical
  # hand-edit applied to BOTH files is invisible HERE, because this leg only asks whether the
  # two agree with each other. Until 2026-09-04 that was a real uncovered hole, since the only
  # other legs looking at these files were digit-blind. It is not one now: legs 2 and 3
  # compare each file byte-exact against the generator, so an edit present in both fires
  # twice over there. This leg's remaining value is that it names the DEFECT precisely — the
  # copy diverged from its original — rather than reporting two independent mismatches.
  _cmp_copy() {   # <copy> <original>
    _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
    _present "$2"; case $? in 1) return 0;; 2) return 1;; esac
    if cmp -s "$1" "$2"; then
      echo "  [ok]   $1 is BYTE-IDENTICAL to $2 (digits included)"
      return 0
    fi
    echo "  [FAIL] $1 is not byte-identical to $2, but its only production route is a copy"
    diff "$2" "$1" | head -6 | sed 's/^/           /'
    echo "         Regenerate the original and re-copy; never edit either one by hand:"
    echo "           ( cd example && python3 ../roae.py --markdown --seed $ROAE_EXAMPLE_SEED )"
    echo "           cp example/report.md example/README.md"
    return 1
  }
  _cmp_copy example/README.md example/report.md || rc=1

  # LEG 7 — the SEVEN non-report artifacts under example/ (Codex v2 charge 6, 2026-09-02).
  #
  # WHAT WAS WRONG. pre_commit_generated_gate.sh's WATCHED population had already been
  # widened from six hardcoded names to "roae.py plus every tracked example/ path", so
  # staging a corrupted example/hexagrams.csv now TRIGGERS the hook — and the hook then ran
  # this gate, which compared five report files and nothing else, printed PASS, and exited
  # 0. Widening the population is not widening the comparison; the hook even narrated the
  # hole in its own PASS message and shipped anyway. MEASURED 2026-09-02 in a scratch clone:
  # `sed -i '4s/$/,XCORRUPTX/' example/hexagrams.csv && git add` then the hook -> rc=0.
  #
  # WHY BYTE-EXACT AND NOT DIGIT-STRIPPED. (Written 2026-09-02, when this was the ONLY
  # byte-exact comparison in the gate. Legs 1-4 joined it on 2026-09-04 once example/ was
  # reshipped under a seed; the argument below is what they then reproduced for the reports.)
  # Legs 1-4 stripped digits because roae.py seeded
  # nothing and its Monte Carlo figures move every run. These seven carry NO Monte Carlo
  # output at all — they are pure functions of the 64-hexagram table (export_csv,
  # export_json, export_svg, print_graphviz, export_midi). MEASURED before switching this
  # on: all seven regenerate byte-identical on this host, so the comparison that catches a
  # hand-edited DIGIT — the hole legs 1-3 could not close at the time — is available here and
  # is used. Their route to the same strictness was the seed, not a different comparison.
  #
  # THE TWO RENDERED FILES. wave.dot.png and wave.dot.svg are graphviz renderings of
  # wave.dot, so their bytes depend on the installed `dot`, not only on roae.py. A renderer
  # upgrade will therefore turn this leg red WITHOUT any hand-edit. That is not a false
  # positive to be suppressed: it is the gate correctly reporting that the shipped artifacts
  # no longer match what this repo's toolchain produces, and the fix is to regenerate and
  # commit them (`cd example && python3 ../roae.py --dot --seed $ROAE_EXAMPLE_SEED`; the seed
  # changes nothing in these seven -- MEASURED across two seeds, all seven byte-identical --
  # and is passed only so one recipe covers every artifact). Stated here so a future
  # maintainer reaches for the regeneration rather than for a skip.
  #
  # AND `dot` ABSENT IS A FAIL, NOT A SKIP — the A1 rule this file already applies to
  # python3. Without graphviz the two rendered artifacts cannot be regenerated, so nothing
  # verifies bytes that are shipped and tracked; saying so loudly beats attesting a
  # comparison that never happened.
  local dtmp
  dtmp="$tmp/data"
  rm -rf "$dtmp"; mkdir -p "$dtmp" || { echo "  [FAIL] LEG 7 could not create its scratch dir"; rc=1; }
  if [ -d "$dtmp" ]; then
    # ~0.6 s for all five (measured), so unlike the report legs this is not cached: a cache
    # is one more thing that can go stale and clear the gate falsely, and it buys nothing.
    local _flag
    for _flag in csv json svg dot midi; do
      if ! ( cd "$dtmp" && timeout 300 python3 "$OLDPWD/roae.py" "--$_flag" --seed "$ROAE_EXAMPLE_SEED" >/dev/null 2>&1 ); then
        echo "  [FAIL] the generator did not run cleanly for --$_flag"
        rc=1
      fi
    done
    _cmp_exact() {   # <tracked artifact> <fresh reference> <flag that produces it>
      _present "$1"; case $? in 1) return 0;; 2) return 1;; esac
      if [ ! -f "$2" ]; then
        echo "  [FAIL] roae.py $3 produced no $(basename "$2") — cannot compare what was not"
        echo "         generated. $1 is tracked and shipped, so an absent reference is a"
        echo "         failure of this leg, never a pass for the artifact."
        return 1
      fi
      if cmp -s "$1" "$2"; then
        echo "  [ok]   $1 is BYTE-IDENTICAL to a fresh roae.py $3 (digits included)"
        return 0
      fi
      echo "  [FAIL] $1 differs BYTE-FOR-BYTE from a fresh roae.py $3 — hand-edited?"
      if ! LC_ALL=C grep -qI . "$1" 2>/dev/null; then
        echo "           (binary; first difference: $(cmp "$1" "$2" 2>&1 | head -1))"
      else
        diff "$2" "$1" | head -6 | sed 's/^/           /'
      fi
      echo "         Fix the SOURCE (roae.py) and regenerate; never edit the artifact:"
      echo "           ( cd example && python3 ../roae.py $3 --seed $ROAE_EXAMPLE_SEED )"
      return 1
    }
    _cmp_exact example/hexagrams.csv  "$dtmp/hexagrams.csv"  --csv   || rc=1
    _cmp_exact example/hexagrams.json "$dtmp/hexagrams.json" --json  || rc=1
    _cmp_exact example/hexagrams.svg  "$dtmp/hexagrams.svg"  --svg   || rc=1
    _cmp_exact example/wave.dot       "$dtmp/wave.dot"       --dot   || rc=1
    _cmp_exact example/wave.mid       "$dtmp/wave.mid"       --midi  || rc=1
    if command -v dot >/dev/null 2>&1; then
      _cmp_exact example/wave.dot.png "$dtmp/wave.dot.png"   --dot   || rc=1
      _cmp_exact example/wave.dot.svg "$dtmp/wave.dot.svg"   --dot   || rc=1
    else
      echo "  [FAIL] graphviz 'dot' is not on PATH, so example/wave.dot.png and"
      echo "         example/wave.dot.svg could not be regenerated and NOTHING compared them."
      echo "         They are tracked and shipped. This is not a skip — install graphviz"
      echo "         (apt-get install graphviz) or push with the bypass and say why."
      rc=1
    fi
    rm -rf "$dtmp"
  fi

  [ "$owned" = 1 ] && rm -rf "$tmp"
  return "$rc"
}

# ---------------------------------------------------------------------------
# GATE 10 — documentation/CORRECTIONS.md is APPEND-ONLY.
#
# WHY: a corrections ledger that can be edited is not a record, it is a draft. The
# failure mode is not malice — it is tidying: rewording an entry to read better,
# merging two entries, or dropping one that "was already fixed". Each of those makes
# the ledger agree with the present, which is exactly the property it must not have.
#
# WHAT IT CHECKS: every line of the LAST COMMITTED version must still be present, in
# order, in the working copy. `diff` is an LCS, so a moved or reworded line shows up as
# a deletion and fires — moving is not appending. Appending anywhere (including in the
# middle of the file, e.g. inserting a new entry between two existing ones) passes.
#
# NEGATIVE CONTROL: the self-test asserts BOTH halves — that a deleted line fires it and
# that a pure append does NOT. A gate with no negative control might simply always fail,
# and "it went red" would then be evidence of nothing.
#
# ITEM A2 (2026-08-02) — THE TWO QUESTIONS, for `diff`'s LCS.
#
# Q1. WHAT LEGITIMATE VARIATION DOES IT ERASE? Position. A line that survives anywhere in
#     the working copy, in the same relative order as its neighbours, is not a deletion —
#     which is what lets a new entry be inserted BETWEEN two existing ones without firing.
#     Nothing else: the comparison is line-exact, so whitespace, case and punctuation all
#     count, and a reworded entry is a deletion plus an addition.
#
# Q2. WHAT ILLEGITIMATE VARIATION DOES IT LET THROUGH? Two things, and both are real.
#     (i) INSERTION INSIDE AN ENTRY. "Append anywhere passes" is documented above as a
#     feature — it is how a new entry goes between two existing ones — but the same rule
#     lets a line be inserted in the MIDDLE of a committed entry, which can change what that
#     entry says while every one of its lines is still present and still in order. The gate
#     preserves lines; it does not preserve meanings.
#     (ii) DUPLICATION. Every committed line must still be PRESENT; nothing says it must be
#     present once. Appending a second copy of an existing entry passes, as it should, since
#     the file is append-only and a later entry may legitimately quote an earlier one.
#     GATE 10 is a preservation gate, not a uniqueness gate, and the [ok] wording says
#     "no committed line removed or reworded" rather than anything stronger.
#     BOTH WERE RUN, not reasoned (2026-08-02). Duplicating CX-07's heading line at EOF:
#     "[ok] no committed line removed or reworded (2 line(s) appended since HEAD)", rc 0.
#     Inserting a fresh bullet three lines INTO CX-07: same [ok], rc 0.
#
# ITEM A8 — THE MEASUREMENT A PER-ENTRY BOUNDARY RULE TURNS ON (2026-08-02). The proposal
# was "no insertion between an entry's own heading and the next heading". Before deciding,
# the question was measured over ALL 8 commits that have ever touched this file, comparing
# each CX entry's line block in parent and child:
#     121 entry-blocks unchanged
#       0 rewordings or removals inside a committed entry   <- GATE 10 is holding
#       1 mid-entry insertion: `2533bc89` added a bullet at offset 16 of CX-20's 30 lines
# SO THE RULE IS NOT FREE. That single insertion is legitimate and is the kind of edit this
# suite should want: a Phase-4 pass tightening its own "only such occurrence" claim to "the
# only one among the nine registered figures", added to the entry it qualifies, before push.
# A blanket boundary rule forbids it and pushes the qualification into a NEW entry that
# readers of CX-20 would never see.
#
# THREE OPTIONS, and the third did not exist when the item was filed: (a) forbid mid-entry
# insertion outright — costs the case above; (b) report-only [note] — cheap, no policy
# change; (c) forbid it only for entries that are ALREADY ON origin/main, which permits
# same-session tightening and still refuses to rewrite a published entry. (c) is the same
# published-vs-local distinction GATE 10b already draws against history, so the machinery
# exists. Which one applies is a closure call on a published append-only ledger and is
# deliberately NOT taken here.
#
# HOW THE MEASUREMENT WAS ARRIVED AT, because the number is only trustworthy with this
# attached: the first two versions of that checker were WRONG in the same direction. Both
# ended an entry at "the next `### CX-` heading or EOF", so the file's LAST entry absorbed
# everything after it — the trailing `<a id="gates"></a>` anchor and a whole following
# section — and every ordinary append to the file read as "an existing entry grew" or "an
# existing entry was reworded". v1 reported 4 mid-entry changes and v2 reported 2
# rewordings; both were artifacts, and GATE 10 would have had to be failing for either to
# be real. Only ending a block at the next heading OF ANY LEVEL gives the numbers above.
#
# CX-230 (2026-09-29) — THE ONE SANCTIONED IN-PLACE EDIT. The operator decided that dollar figures
# leave the current tree, the append-only ledgers included, with git history unchanged. In a ledger
# the edit is mechanical: a dollar-figure token becomes `[cost redacted]` and nothing else on the
# line moves. _g10_money_align reads a BASELINE version on stdin and writes it back with each line
# that differs from a working-copy line ONLY by such replacements swapped for that working-copy line,
# so 10a and 10b compare the redacted baseline and see no loss. Anything else on the line — a changed
# word, a changed amount, a dropped token, punctuation — leaves the baseline line as it was, and it
# fails as before. A token is `$` + a number (digit-group commas, a decimal part, an optional K/k/M)
# with an optional hyphen or en-dash range; the redaction left awk and shell `$1`-style fields alone,
# and the gate only ever ACCEPTS a replacement, so it needs no rule for them. $1 is the working copy.
# Tested in tests.py (TestQ903AppendOnlyMoneyRedaction): green on a pure token->marker change, red on
# the same change plus one reworded word, red on a changed amount.
# CX-242 (2026-09-29) — THE SAME EDIT FOR STORAGE DETAIL. Operational detail about where data copies
# are kept is outside the project's scope and left the current tree the same way: in a ledger, a
# span of it becomes `[storage detail redacted]` and nothing else on the line moves. Such a span has
# no fixed shape, so the rule is positional: the committed line must equal the working line with each
# marker standing for a non-empty span, every other character unchanged. A reworded word outside
# the spans still fails. A working line with fewer than 4 characters outside its markers anchors
# nothing and is never used, and a committed line still present verbatim is never re-aligned. Tested in tests.py (TestCX242AppendOnlyStorageRedaction).
_g10_money_align() {
  if ! grep -qF -e '[cost redacted]' -e '[storage detail redacted]' "$1" 2>/dev/null; then cat; return 0; fi
  DG_WORK="$1" python3 -c '
import os, re, sys
M = "[cost redacted]"
NUM = r"[0-9](?:[0-9,]*[0-9])?(?:\.[0-9]+)?(?:[KkM](?![A-Za-z]))?"
TOK = re.compile(r"\$" + NUM + r"(?:[-–]\$?" + NUM + r")?")
idx = {}
for w in open(os.environ["DG_WORK"], encoding="utf-8", errors="surrogateescape").read().split("\n"):
    if M in w:
        idx.setdefault(TOK.sub(M, w), []).append(w)
data = sys.stdin.buffer.read().decode("utf-8", "surrogateescape").split("\n")
for i, b in enumerate(data):
    if M in b and not TOK.search(b):
        continue
    ws = idx.get(TOK.sub(M, b)) if TOK.search(b) else None
    if not ws:
        continue
    parts, pos = [], 0
    for m in TOK.finditer(b):
        parts += [re.escape(b[pos:m.start()]), "(?:%s|%s)" % (re.escape(m.group(0)), re.escape(M))]
        pos = m.end()
    pat = re.compile("".join(parts) + re.escape(b[pos:]))
    for w in ws:
        if w != b and pat.fullmatch(w):
            data[i] = w
            break
# CX-242: a span of storage detail replaced by S. Each working line holding S is split on S; the
# committed line must be those literal pieces in order, the first a prefix and the last a suffix,
# with each S standing for a NON-EMPTY span (and a cost marker in a piece still standing for a
# token or itself). Every character outside the spans must match: a reworded word fails.
S = "[storage detail redacted]"
cands = {}
wall = open(os.environ["DG_WORK"], encoding="utf-8", errors="surrogateescape").read().split("\n")
wset = set(wall)
for w in wall:
    if S not in w:
        continue
    # a line that is nothing but markers would match ANY committed line: it anchors nothing
    if len("".join(w.split(S)).strip()) < 4:
        continue
    rx = []
    for k, piece in enumerate(w.split(S)):
        if k:
            rx.append("(?:.+?)")
        sub = piece.split(M)
        for j, q in enumerate(sub):
            if j:
                rx.append("(?:%s|%s)" % (re.escape(M), TOK.pattern))
            rx.append(re.escape(q))
    head = w.split(S, 1)[0][:12]
    cands.setdefault(head, []).append((w, re.compile("".join(rx), re.S)))
lens = sorted({len(h) for h in cands})
for i, b in enumerate(data):
    if S in b or b in wset:   # a committed line still present verbatim is never re-aligned
        continue
    for L in lens:
        for w, pat in cands.get(b[:L], ()):
            if w != b and pat.fullmatch(b):
                data[i] = w
                break
        else:
            continue
        break
sys.stdout.buffer.write("\n".join(data).encode("utf-8", "surrogateescape"))
'
}
gate_appendonly_head() {
  echo "== GATE 10a: CORRECTIONS.md is append-only vs HEAD =="
  local f="documentation/CORRECTIONS.md"
  # ITEM A1. Deleting the ledger is the LIMITING CASE of the thing this gate forbids —
  # every committed line is gone at once — and it used to be the one way to make the gate
  # report nothing.
  require_tracked "$f" "Deleting the ledger removes every committed line at once: the maximal append-only violation."
  case $? in 1) return 0;; 2) return 1;; esac
  if ! git cat-file -e "HEAD:$f" 2>/dev/null; then
    echo "  [ok] $f is not yet in HEAD — nothing committed to be append-only against"
    return 0
  fi
  local tmp gone
  tmp=$(mktemp) || return 1
  git show "HEAD:$f" 2>/dev/null | _g10_money_align "$f" > "$tmp"   # CX-230: token->marker only
  # ⚠ Q-284: the `|| true` here is CORRECT and must stay. `grep -c` exits 1 when the count
  # is ZERO, which is a normal result, not a failure. A sweep that strips every `|| true`
  # would break this gate. Two of the four sites found were real defects; these two are not.
  gone=$(diff "$tmp" "$f" | grep -c '^< ' || true)
  if [ "${gone:-0}" -eq 0 ]; then
    local added
    added=$(diff "$tmp" "$f" | grep -c '^> ' || true)
    echo "  [ok] no committed line removed or reworded ($added line(s) appended since HEAD)"
    rm -f "$tmp"; return 0
  fi
  # Q-251 (2026-09-03) — THE GATE IS RIGHT ABOUT THE LINES AND WAS WRONG TO IMPLY CONTENT
  # WAS LOST. This gate compares LINES, so re-flowing a committed paragraph at different
  # line breaks reports every one of its old lines as "removed or reworded" while not one
  # word has gone. MEASURED, on this file, in a scratch worktree: re-wrapping THREE
  # consecutive committed prose lines at width 72 — no word changed — produced
  # `[FAIL] 3 committed line(s) no longer present` here and SEVENTY-THREE `[FAIL]` blocks in
  # GATE 10b, one per historical blob. The hazard is the REMEDY: a maintainer goes looking
  # for deleted content that does not exist, or concludes the ledger was tampered with.
  #
  # THE VERDICT IS UNCHANGED AND DELIBERATELY SO. A reflow of published text really does
  # rewrite bytes of an append-only file; the lines DID change. What changes is that the two
  # classes are named separately, so the reader is told which remedy applies. NOTHING NEWLY
  # PASSES: both classes still set the exit code, so this cannot be a false clear.
  #
  # Q-718 (2026-09-25) — HOW A MISSING LINE IS CLASSIFIED. The first rule asked whether its
  # whitespace-collapsed text occurred ANYWHERE in the collapsed file, so deleting the one-word
  # line `this.` read as a re-wrap. Each `diff` hunk is now compared word by word: a missing
  # line is a RE-WRAP only when every one of its words is aligned, in order, with a word of the
  # text that replaced it in the SAME hunk. A deleted line (a hunk with no replacement), a
  # dropped word or duplicate, and a hyphen split (`machine-` then `enforced` is two words, not
  # `machine-enforced`) are LOST. A missing blank line has no words and stays a re-wrap.
  local missf
  missf=$(mktemp) || { echo "  [FAIL] GATE 10a: mktemp failed, so the finding could not be classified."; rm -f "$tmp"; return 1; }
  diff "$tmp" "$f" > "$missf"
  DG_MISS="$missf" DG_N="$gone" python3 - <<'PY'
import os, re, sys, difflib
def classify(dt):  # Q-718: a normal-format diff -> (re-wrapped, lost) removed lines, judged hunk by hunk
    rew, lost = [], []
    for h in (h.split("\n") for h in re.split(r"(?m)^\d+(?:,\d+)?[acd]\d+(?:,\d+)?$", dt)):
        old = [d[2:] for d in h if d[:1] == "<"]; b = " ".join(d[2:] for d in h if d[:1] == ">").split()
        a = [(x, i) for i, l in enumerate(old) for x in l.split()]; m = min(len(a), len(b))
        p = next((k for k in range(m) if a[k][0] != b[k]), m); s = next((k for k in range(m - p) if a[-1 - k][0] != b[-1 - k]), m - p)
        ok = set(range(p)) | set(range(len(a) - s, len(a))) | {p + i + k for i, j, n in difflib.SequenceMatcher(None, [x for x, _ in a[p:len(a) - s]], b[p:len(b) - s], autojunk=False).get_matching_blocks() for k in range(n)}
        bad = {a[k][1] for k in range(len(a)) if k not in ok}
        for i, l in enumerate(old): (lost if i in bad else rew).append(l)
    return rew, lost
rew, lost = classify(open(os.environ["DG_MISS"], encoding="utf-8", errors="replace").read()); n = os.environ["DG_N"]
if lost:
    print("  [FAIL] %d of %s missing committed line(s) are LOST — their text is not in the file"
          % (len(lost), n))
    print("         at any line breaks. CORRECTIONS.md is append-only (first 5):")
    for l in lost[:5]:
        print("           " + l[:140])
    print("         If an entry is wrong, APPEND an entry saying so. Both stay.")
if rew:
    print("  [REWRAP] %d of %s missing committed line(s) are RE-WRAPS, not deletions: every"
          % (len(rew), n))
    print("           word survives, re-flowed at different line breaks (first 5):")
    for l in rew[:5]:
        print("             " + l[:140])
    print("           DO NOT go looking for deleted content and DO NOT conclude the ledger was")
    print("           tampered with. The remedy is to restore the FLOW you changed — a published")
    print("           append-only ledger is not re-flowed — not to rewrite any prose.")
PY
  rm -f "$tmp" "$missf"
  return 1
}

# ---------------------------------------------------------------------------
# GATE 10b — the SAME invariant against every version that ever existed, not just HEAD.
#
# WHY (2026-08-02, item A7). 10a's baseline is `git show HEAD:<f>`, which makes
# "append-only" mean "append-only since the last commit". Two ordinary operations
# reset it:
#
#   (1) COMMIT THE REMOVAL. Delete an entry, commit. 10a compared against the
#       pre-commit HEAD and fired — but on the very next run HEAD *is* the truncated
#       version, the working copy matches it, and the gate returns to [ok] forever.
#       The ledger is permanently shorter and the gate attests that it is intact.
#       This is the likelier of the two; it needs no unusual git at all.
#   (2) REWRITE THE HISTORY. amend / rebase / squash moves the baseline along with
#       the content it dropped.
#
# WHAT THIS HALF CHECKS: every non-blank line of every baseline version must still be
# present in the working copy, counting multiplicity. Baselines are (i) every commit
# reachable from HEAD that touched the file, and (ii) every remote-tracking ref's
# version of it.
#
# WHY (ii) IS NOT REDUNDANT, and it is the half that answers case (2): after an amend
# or a rebase the pre-rewrite commit is NO LONGER AN ANCESTOR OF HEAD, so walking
# `git rev-list HEAD` cannot see it — a walk alone would close case (1) and leave
# case (2) exactly as open as before. `refs/remotes/*` is not moved by a local
# rewrite, so anything already PUBLISHED stays a baseline whatever happens to the
# local history.
#
# WHAT THIS CANNOT SEE, stated rather than implied:
#   - a line committed locally and then amended away BEFORE it was ever pushed. It is
#     unreachable from HEAD and was never on a remote, so no baseline holds it. The
#     reflog does, but the reflog is local, expires, and is empty in a fresh clone —
#     it is not an invariant anything can be gated on.
#   - ORDER and BLANK LINES. This half is a multiset containment check, so a
#     re-ordering passes it. 10a is the order-sensitive half (diff is an LCS); the two
#     are complementary and both run. NOT COVERED BY EITHER (Q-971, A05#6): a reorder that is
#     already COMMITTED. 10a compares the working copy with HEAD, so it sees only an
#     uncommitted reorder; this half sees only lost lines.
#
# COST: B distinct blob versions x L lines; B = commits touching the file + remote-tracking refs,
# deduplicated by blob id. Neither is quoted here: a "Measured 2026-08-02" `B = 5, L = 525` was
# stale the same day. B is printed on the green [ok] line; L is `wc -l < documentation/CORRECTIONS.md`.
#
# BEHIND VERSUS DIVERGED (Q-702; documented under Q-719). The branch's published lineage is
# @{push}, else a same-named remote branch, else a same-named @{upstream}, and the gate prints
# which. A baseline commit on that lineage that is not an ancestor of HEAD is judged by HEAD:
#   - HEAD is an ancestor of the lineage ref (purely BEHIND): a [note]. The lines arrive with a
#     fast-forward, and a push from here is refused as non-fast-forward.
#   - HEAD is not (DIVERGED, which includes an amend, rebase or squash of a published commit):
#     a [FAIL] until the branch merges or rebases onto that ref. This holds mid-lane too: a local
#     commit made while behind a remote ledger append makes the checkout diverged, and it fails.
# A commit only on OTHER remote branches is a merge-gap [note]. A detached HEAD has no lineage,
# so this arm is off there (the pre-push hook's per-sha worktree is one), and the gate says so.
gate_appendonly_history() {
  echo "== GATE 10b: CORRECTIONS.md has lost no line from ANY committed or published version =="
  local f="documentation/CORRECTIONS.md"
  # ITEM A1, same limiting case as 10a and worse here: this half compares against every
  # PUBLISHED version, so a deleted working copy loses every line of all of them.
  require_tracked "$f" "Deleting the ledger loses every line of every published version at once."
  case $? in 1) return 0;; 2) return 1;; esac
  local cur tmp bad=0 n=0 blob src seen=""
  cur=$(mktemp) || return 1
  tmp=$(mktemp) || { rm -f "$cur"; return 1; }
  # Q-251: the accumulator for re-wrapped lines seen across every baseline. A three-line reflow
  # produced SEVENTY-THREE identical [FAIL] blocks here (one per historical blob); they are now
  # collected and reported once. Nothing newly passes: the accumulator sets `bad` too. Q-718:
  # $g10b_diff holds ONE baseline's `diff` against the working copy at a time, written in the
  # loop, and a missing line is classified by the 10a rule (word alignment within its hunk) on
  # that diff. When one text is removed in both classes, LOST is counted first.
  local g10b_diff g10b_rew
  g10b_diff=$(mktemp) || { rm -f "$cur" "$tmp"; return 1; }
  g10b_rew=$(mktemp)  || { rm -f "$cur" "$tmp" "$g10b_diff"; return 1; }
  local g10b_base
  g10b_base=$(mktemp) || { rm -f "$cur" "$tmp" "$g10b_diff" "$g10b_rew"; return 1; }
  grep -v '^[[:space:]]*$' "$f" | sort > "$cur"
  # Baselines, deduplicated by BLOB id: a commit that did not change the file, and a
  # remote ref pointing at a commit already walked, contribute nothing.
  # 🔴 Q-283 / Codex N10 finding 8 — reproduced on the PUBLISHED suite 2026-08-28. This walked
  # every commit reachable from HEAD, but of the remotes only each ref's CURRENT TIP — so a line
  # that existed in a remote-only commit and was later deleted was never examined, while the
  # success sentence claimed "ANY committed or published version".
  # Measured on THIS tree (the branch's own "2 of 24" is tree-specific and does not hold here):
  # HEAD reaches 22 commits touching the file and 23 distinct blobs; walking the remote HISTORIES
  # reaches 24 commits and 24 blobs. The one blob visible only with this fix, 2f14cc5f, contains
  # THREE lines absent from the current file — a live miss, not a constructible one.
  # Passing the remote refs to rev-list walks their history, and rev-list dedupes the overlap free.
  #
  # 🔴 Q-702 (2026-09-24, Fable K) — THE Q-283 SPLIT BELOW HAD RE-OPENED CASE (2). Its rule was
  # "not an ancestor of HEAD -> MERGE GAP, reported, never failed". But a commit that is not an
  # ancestor of HEAD is ALSO exactly what an amend/rebase leaves behind: the pre-rewrite commit
  # on refs/remotes/origin/main is no ancestor of the rewritten HEAD, so the one baseline this
  # half exists to hold (the header's "(ii) ... answers case (2)") was being reported as a merge
  # gap and the gate exited 0. Measured on 5c296837 with the harness's own scratch fixture (iii):
  # `[note] 1 line(s) exist in <orig> ... MERGE GAP ... Reported, not failed` then
  # `[ok] every line of all 2 distinct historical/published version(s) survives`, rc 0 — the
  # fire-proof "GATE 10b vs an AMEND that drops a PUBLISHED line" was RED for that reason.
  #
  # THE DISTINCTION THAT WAS MISSING is WHICH remote history holds the commit. Q-283's live case
  # (blob 2f14cc5f on v4-query-program, 441 commits divergent) is on a branch this lineage never
  # merged. The amend case is on THIS BRANCH'S OWN PUBLISHED HISTORY — what a push from here
  # would land on. Resolved in this order (batch-2 pre-publication review item S3, 2026-09-24,
  # Fable P; the first cut took `@{upstream}` unconditionally and was measured to hard-FAIL a
  # legitimate layout, below):
  #   1. `@{push}` — the push destination, which is what "a push from here" means. Under
  #      push.default=simple (git's default) it resolves only when the upstream has the same
  #      name as the branch; under push.default=upstream it resolves to the upstream, and a
  #      FAIL there is then correct, because a push really would land on it.
  #   2. the same-named branch under every remote (`refs/remotes/<remote>/<branch>`, which is
  #      what the scratch fixture and a fresh `git clone` both have).
  #   3. `@{upstream}`, ONLY when its short name (after the remote) equals the branch name.
  # WHY NOT `@{upstream}` ALONE: `git checkout -b feat origin/main` (the default
  # branch.autoSetupMerge) sets feat's upstream to refs/remotes/origin/main, for a branch that
  # will never push to main — git itself refuses `@{push}` there ("cannot resolve 'simple' push
  # to a single destination"). Measured on a scratch repo of that shape: once origin/main gained
  # a ledger line after feat branched, the unconditional-upstream arm printed `published lineage
  # of this branch: refs/remotes/origin/main` and hard-FAILED feat for a line nothing published
  # could lose. That layout is a [note] (merge gap) now, and stays fire-proven in --selftest.
  # A commit reachable from the resolved lineage's remote but not from HEAD is either a rewrite
  # that dropped it or a local branch that is behind/diverged from what it publishes — and in
  # both a push from here carries fewer published lines than the remote holds, which is the
  # append-only violation. Hard FAIL, with its own sentence so the two readings are not
  # conflated. Everything on OTHER remote branches keeps Q-283's [note].
  # A detached HEAD, or a branch with none of the three, has no published lineage here; that is
  # printed, not assumed, so a silent disarm is visible. THE PRE-PUSH HOOK RUNS `all` IN A
  # DETACHED PER-SHA WORKTREE, so this arm is disarmed there and says so; it is armed in a
  # developer's own checkout, where a manual run is what sees it.
  local _g10b_up="" _g10b_ref _g10b_rest _g10b_br _g10b_how=""
  _g10b_br=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  if _g10b_ref=$(git rev-parse --symbolic-full-name '@{push}' 2>/dev/null) && [ -n "$_g10b_ref" ]; then
    _g10b_up="$_g10b_ref"; _g10b_how="@{push}"
  elif [ -n "$_g10b_br" ]; then
    for _g10b_ref in $(git for-each-ref --format='%(refname)' refs/remotes 2>/dev/null); do
      _g10b_rest="${_g10b_ref#refs/remotes/}"
      [ "${_g10b_rest#*/}" = "$_g10b_br" ] && _g10b_up="$_g10b_up $_g10b_ref"
    done
    _g10b_up="${_g10b_up# }"
    if [ -n "$_g10b_up" ]; then
      _g10b_how="same-named remote branch"
    elif _g10b_ref=$(git rev-parse --symbolic-full-name '@{upstream}' 2>/dev/null) && [ -n "$_g10b_ref" ]; then
      _g10b_rest="${_g10b_ref#refs/remotes/}"
      if [ "${_g10b_rest#*/}" = "$_g10b_br" ]; then
        _g10b_up="$_g10b_ref"; _g10b_how="@{upstream}, same short name"
      fi
    fi
  fi
  if [ -n "$_g10b_up" ]; then
    echo "  published lineage of this branch: $_g10b_up [$_g10b_how] (a line there and not here is a hard FAIL)"
  else
    if [ -z "$_g10b_br" ]; then
      echo "  [note] detached HEAD (the pre-push hook's per-sha worktree is one), so the"
    else
      echo "  [note] branch '$_g10b_br' has no @{push}, no same-named remote branch and no"
      echo "         same-named upstream (an upstream of another name, e.g. origin/main under"
      echo "         'git checkout -b $_g10b_br origin/main', is not a push destination), so the"
    fi
    echo "         rewritten-published-history arm has NO baseline here; other remote branches"
    echo "         are still walked and reported as merge gaps."
  fi
  # 🔴 Q-971 (a) (2026-10-03, batch 40; Codex (gpt-6-astra), push-path review Q835, adjudicated
  # Q-962 R9). The walk below used to CLASSIFY and DEDUPLICATE in one pass, in rev-list order
  # (newest first), keyed on the blob alone. An unmerged remote commit that carried the SAME
  # ledger blob as an ancestor of HEAD was visited first, became a merge-gap [note], marked the
  # blob seen, and the ancestor's copy was skipped: a COMMITTED deletion went from FAIL to PASS
  # once such a ref was fetched (measured in a scratch clone). Now every (commit, blob) pair is
  # classified FIRST, the pairs are ordered strictest first (ancestor, published, behind,
  # unmerged; rev-list order kept within a class), and only then deduplicated by blob, so a blob
  # is always judged under the strictest verdict any commit holding it earns.
  local g10b_pairs _g10b_rank _g10b_seq=0
  g10b_pairs=$(mktemp) || { echo "  [FAIL] GATE 10b: mktemp failed, so nothing was classified."; rm -f "$cur" "$tmp" "$g10b_diff" "$g10b_rew" "$g10b_base"; return 1; }
  for src in $(git rev-list HEAD $(git for-each-ref --format='%(refname)' refs/remotes 2>/dev/null) \
               -- "$f" 2>/dev/null); do
    # 🔴 Q-283 finding 8, second half — a distinction the branch's fix does not draw and this tree
    # needs. Walking remote HISTORIES surfaces two different defects that must not share a verdict:
    #   * the blob's commit IS an ancestor of HEAD  -> a line vanished from OUR OWN lineage. That is
    #     the append-only violation this gate exists for, and it is a hard FAIL.
    #   * the blob's commit is NOT an ancestor      -> the content lives on an unmerged branch and
    #     was never in this lineage to lose. That is a MERGE GAP (Q-77 / A8), not a deletion.
    # Measured 2026-08-28: the only blob this fix newly reaches, 2f14cc5f from b2b8d0da, is on
    # v4-query-program ONLY — 441 commits divergent. Its 3 lines were never removed from main; they
    # never arrived. Reporting that as "a line was lost" would blame the wrong act and leave a hard
    # gate permanently red for a merge decision the gate cannot make.
    if git merge-base --is-ancestor "$src" HEAD 2>/dev/null; then
      _g10b_kind=ancestor
    else
      _g10b_kind=unmerged
      for _g10b_ref in $_g10b_up; do
        if git merge-base --is-ancestor "$src" "$_g10b_ref" 2>/dev/null; then
          # PURELY BEHIND vs REWRITTEN/DIVERGED. If HEAD is itself an ancestor of that upstream,
          # nothing was rewritten: the lines arrive with a fast-forward and a push from here is
          # refused as non-fast-forward anyway. That is a [note] (measured: a `git fetch` that
          # brought a ledger append would otherwise turn this gate red on an untouched tree).
          # If HEAD and the upstream have DIVERGED, the published commit was rewritten past or
          # a merge is pending that could drop it — the hard FAIL.
          if git merge-base --is-ancestor HEAD "$_g10b_ref" 2>/dev/null; then _g10b_kind=behind; else _g10b_kind=published; fi
          break
        fi
      done
    fi
    blob=$(git rev-parse --quiet --verify "$src:$f" 2>/dev/null) || continue
    [ -n "$blob" ] || continue
    case "$_g10b_kind" in ancestor) _g10b_rank=0;; published) _g10b_rank=1;; behind) _g10b_rank=2;; *) _g10b_rank=3;; esac
    _g10b_seq=$((_g10b_seq+1))
    printf '%s %s %s %s %s\n' "$_g10b_rank" "$_g10b_seq" "$src" "$_g10b_kind" "$blob"
  done > "$g10b_pairs"
  # Q-971 (a): strictest class first, then rev-list order; THEN the blob dedup. A failed sort is
  # a FAIL, never an empty walk (an empty walk prints "[ok] ... no baseline").
  sort -k1,1n -k2,2n -o "$g10b_pairs" "$g10b_pairs" || { echo "  [FAIL] GATE 10b: could not order the baselines, so nothing was classified."; rm -f "$cur" "$tmp" "$g10b_diff" "$g10b_rew" "$g10b_base" "$g10b_pairs"; return 1; }
  while read -r _g10b_rank _g10b_seq src _g10b_kind blob <&3; do
    case " $seen " in *" $blob "*) continue;; esac
    seen="$seen $blob"
    n=$((n+1))
    # CX-230: the baseline is aligned to the working copy's `[cost redacted]` lines first (see
    # _g10_money_align above); a pure token->marker line is then not a loss, anything else still is.
    git cat-file -p "$blob" 2>/dev/null | _g10_money_align "$f" > "$g10b_base"
    grep -v '^[[:space:]]*$' "$g10b_base" | sort > "$tmp"
    local lost
    lost=$(comm -23 "$tmp" "$cur" | wc -l)
    if [ "${lost:-0}" -ne 0 ]; then
      # Q-251 / Q-718: split into RE-WRAPS (accumulated, reported once below) and LOST lines.
      local g10b_lostf
      g10b_lostf=$(mktemp) || { echo "  [FAIL] GATE 10b: mktemp failed, so nothing was classified."; rm -f "$cur" "$tmp" "$g10b_diff" "$g10b_rew" "$g10b_base" "$g10b_pairs"; return 1; }
      diff "$g10b_base" "$f" > "$g10b_diff"; comm -23 "$tmp" "$cur" | DG_DIFF="$g10b_diff" DG_REW="$g10b_rew" python3 -c '
import os, re, sys, difflib, collections
def classify(dt):  # Q-718: a normal-format diff -> (re-wrapped, lost) removed lines, judged hunk by hunk
    rew, lost = [], []
    for h in (h.split("\n") for h in re.split(r"(?m)^\d+(?:,\d+)?[acd]\d+(?:,\d+)?$", dt)):
        old = [d[2:] for d in h if d[:1] == "<"]; b = " ".join(d[2:] for d in h if d[:1] == ">").split()
        a = [(x, i) for i, l in enumerate(old) for x in l.split()]; m = min(len(a), len(b))
        p = next((k for k in range(m) if a[k][0] != b[k]), m); s = next((k for k in range(m - p) if a[-1 - k][0] != b[-1 - k]), m - p)
        ok = set(range(p)) | set(range(len(a) - s, len(a))) | {p + i + k for i, j, n in difflib.SequenceMatcher(None, [x for x, _ in a[p:len(a) - s]], b[p:len(b) - s], autojunk=False).get_matching_blocks() for k in range(n)}
        bad = {a[k][1] for k in range(len(a)) if k not in ok}
        for i, l in enumerate(old): (lost if i in bad else rew).append(l)
    return rew, lost
R, L = map(collections.Counter, classify(open(os.environ["DG_DIFF"], encoding="utf-8", errors="replace").read())); rew = open(os.environ["DG_REW"], "a", encoding="utf-8")
for l in (x.rstrip("\n") for x in sys.stdin):
    if L[l] > 0 or R[l] == 0: L[l] -= 1; sys.stdout.write(l + "\n")
    else: R[l] -= 1; rew.write(l + "\n")
' > "$g10b_lostf"
      lost=$(wc -l < "$g10b_lostf")
    fi
    if [ "${lost:-0}" -ne 0 ]; then
      if [ "${_g10b_kind:-ancestor}" = ancestor ]; then
        echo "  [FAIL] $lost line(s) present in $src ($blob) are absent from the working copy"
        echo "         at any line breaks — their text is gone, not re-flowed."
        echo "         That version is committed or published; append-only means it can never lose a line."
        head -5 "$g10b_lostf" | cut -c1-140 | sed 's/^/           /'
        echo "         If an entry is wrong, APPEND an entry saying so. Both stay."
        bad=1
      elif [ "${_g10b_kind:-ancestor}" = published ]; then
        # Q-702: the commit is on THIS branch's published lineage and no longer an ancestor of
        # HEAD. Either the local history was rewritten past it (amend/rebase/squash — case (2)
        # of this gate's header) or this branch is behind/diverged from its own remote. In both,
        # a push from here loses a PUBLISHED line. That is not a merge gap: it is the case the
        # published-baseline half exists for.
        echo "  [FAIL] $lost line(s) present in the PUBLISHED lineage of this branch — $src ($blob)"
        echo "         — are absent from the working copy, and that commit is no longer an ancestor"
        echo "         of HEAD. Either the history was REWRITTEN past it (amend/rebase/squash) or"
        echo "         this branch is behind/diverged from what it publishes; either way a push"
        echo "         from here carries fewer published lines than the remote holds."
        head -5 "$g10b_lostf" | cut -c1-140 | sed 's/^/           /'
        echo "         Restore the line (merge/rebase onto the remote, or re-add it); never force-push over it."
        bad=1
      elif [ "${_g10b_kind:-ancestor}" = behind ]; then
        echo "  [note] $lost line(s) exist in $src ($blob) on this branch's published lineage, and this"
        echo "         checkout is purely BEHIND it (HEAD is an ancestor of the upstream): nothing was"
        echo "         rewritten, the lines arrive with a fast-forward, and a push from here is refused"
        echo "         as non-fast-forward. Reported, not failed. Remedy: git pull --ff-only."
        head -3 "$g10b_lostf" | cut -c1-140 | sed 's/^/           /'
      else
        # Q-283 finding 8: an UNMERGED branch commit. The content was never in this lineage, so it
        # was not lost — it never arrived. Reported, never a FAIL: the remedy is the merge (Q-77 /
        # A8), which this gate cannot perform and must not block on.
        echo "  [note] $lost line(s) exist in $src ($blob) but not here — that commit is NOT an"
        echo "         ancestor of HEAD, so this is a MERGE GAP, not a lost line. Remedy: the"
        echo "         Q-77 / A8 merge. Reported, not failed."
        head -3 "$g10b_lostf" | cut -c1-140 | sed 's/^/           /'
      fi
    fi
    [ -n "${g10b_lostf:-}" ] && rm -f "$g10b_lostf" && g10b_lostf=""
  done 3< "$g10b_pairs"
  rm -f "$g10b_pairs"
  # Q-251, the aggregate. Printed ONCE however many baselines carried the same re-flowed line.
  if [ -s "$g10b_rew" ]; then
    local nrew
    nrew=$(sort -u "$g10b_rew" | wc -l)
    echo "  [REWRAP] $nrew distinct committed line(s) are absent AS LINES but present AS TEXT —"
    echo "           re-flowed at different line breaks, with every word surviving (first 5):"
    sort -u "$g10b_rew" | head -5 | cut -c1-140 | sed 's/^/             /'
    echo "           This is NOT a lost line and NOT tampering. The remedy is to restore the FLOW"
    echo "           you changed; a published append-only ledger is not re-flowed. Do not go"
    echo "           looking for deleted content, and do not rewrite any prose to satisfy this."
    bad=1
  fi
  if [ "$n" -eq 0 ]; then
    echo "  [ok] $f has no committed or published version yet — no baseline to lose a line from"
  elif [ "$bad" -eq 0 ]; then
    echo "  [ok] every line of all $n distinct historical/published version(s) survives in the working copy"
  fi
  rm -f "$cur" "$tmp" "$g10b_diff" "$g10b_rew" "$g10b_base"
  return $bad
}

gate_appendonly() {
  local rc=0
  gate_appendonly_head    || rc=1
  echo
  gate_appendonly_history || rc=1
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 11 — every REGISTERED retraction has an entry in the corrections ledger.
#
# WHY: RETRACTED_PHRASES.tsv (gate 3) stops a retracted wording from REAPPEARING. It
# says nothing about whether the retraction was ever RECORDED. Those are different
# failures, and the second is the quieter one: the corpus goes clean, the gate goes
# green, and no reader ever learns the claim was published in the first place.
#
# INDEPENDENCE (the reason this gate is worth having): it is registry-driven and does
# NOT consult scripts/corrections_inventory.sh's classifier. That classifier's C1 rule
# deliberately requires a hard retraction token and therefore deliberately under-fires;
# this gate is the instrument that catches what it misses. Two instruments that share a
# failure mode are one instrument.
#
# KEYING: each row is keyed by RP-<first 8 hex of sha256 of the retracted string>. The
# ledger cites the KEY, never the string — quoting the string in CORRECTIONS.md would
# reintroduce into the corpus the exact wording gate 3 exists to keep out. A key also
# cannot be faked by paraphrase, and a truncated quote cannot satisfy it.
gate_ledger() {
  local rc=0
  gate_ledger_phrases || rc=1
  echo
  gate_ledger_figures || rc=1
  return $rc
}

# GATE 11, FIGURES PASS (item A5, 2026-08-02) — the partner GATE 3b never had.
#
# GATE 11's phrases pass proves every RETRACTED_PHRASES.tsv row reaches CORRECTIONS.md.
# RETRACTED_FIGURES.tsv had no equivalent, so a figure could be registered, gated by GATE 3b
# on every run, and never recorded — the quieter half of the failure GATE 11 exists for.
#
# IT KEYS ON `RF-<sha8>`, NOT ON THE FIGURE TEXT, and that is the whole design. MEASURED
# before writing it: of the eleven registered figures, six OCCUR somewhere in CORRECTIONS.md
# and only four are RECORDED there. `1.4σ` (line 542) and `≈10×` (line 541) both appear
# inside CX-19's "How it was found" paragraph, as examples of meta-mentions found elsewhere
# in the corpus — a text-presence gate would have cleared two unrecorded retractions and
# called it coverage.
#
# OWN DISPATCH NAME (`ledger-figures`), for the reason GATE 4b got one: a self-test that
# asserts on the COMBINED `ledger` exit code is satisfied by the phrases pass failing, and
# would stay green if this pass were deleted. `ledger` still runs both.
#
# THE OPEN LIST IS NOT AN ALLOWLIST. documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt holds the
# seven figures whose ledger entries have not been written; each prints as [OPEN] with a
# count every run, in the shape GATE 4b uses for dangling section refs. A figure registered
# from today on FAILS unless it is recorded or deliberately listed. The list is deliberately
# NOT guarded by require_tracked: losing it makes this gate STRICTER, not blinder, which is
# the fail-safe direction (same argument as GATE 3b's allowlist).
gate_ledger_figures() {
  echo "== GATE 11 (figures): registered retracted FIGURES are recorded in CORRECTIONS.md =="
  local reg="documentation/RETRACTED_FIGURES.tsv" f="documentation/CORRECTIONS.md"
  local open="documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt" rcr=0 rcf=0
  require_tracked "$reg" "With the figure registry gone this pass has zero figures to look for." || rcr=$?
  require_tracked "$f"   "With the ledger gone every registered figure is unrecorded by definition." || rcf=$?
  if [ "$rcr" -eq 2 ] || [ "$rcf" -eq 2 ]; then return 1; fi
  if [ "$rcr" -ne 0 ] || [ "$rcf" -ne 0 ]; then return 0; fi
  command -v sha256sum >/dev/null 2>&1 || {
    echo "  [FAIL] sha256sum not on PATH — the RF-<sha> keying this pass is built on cannot"
    echo "         be computed, so the pass can check nothing. This is not a skip."
    return 1; }
  local bad=0 n=0 nopen=0 key fig note why
  require_final_newline "$reg"  || bad=1
  require_final_newline "$open" || bad=1
  while IFS=$'\t' read -r fig note; do
    reg_row_kind loud "$fig" "$note"; case $? in 0) continue;; 2) bad=1; continue;; esac   # Q-761
    n=$((n+1))
    key="RF-$(printf '%s' "$fig" | sha256sum | cut -c1-8)"
    why=''
    if [ -f "$open" ]; then
      why=$(awk -F'\t' -v want="$fig" '$1==want {print $2; exit}' "$open")
    fi
    if grep -qF -- "$key" "$f"; then
      if [ -n "$why" ]; then
        echo "  [note] $key \"$fig\" is recorded in $f, but is still listed as open in"
        echo "         $open — delete that row."
      else
        echo "  [ok] $key \"$fig\" recorded"
      fi
    elif [ -n "$why" ]; then
      nopen=$((nopen+1))
      echo "  [OPEN] $key \"$fig\" — no ledger entry yet: $why"
    else
      echo "  [FAIL] $key \"$fig\" has NO entry in $f and is not listed in $open"
      echo "         registry note: $note"
      echo "         Either append an entry to $f citing $key, or add a row to $open"
      echo "         saying what still has to be adjudicated. Silence is not an option:"
      echo "         a figure can otherwise be registered, gated, and never recorded."
      bad=1
    fi
  done < "$reg"
  if [ -f "$open" ]; then
    while IFS=$'\t' read -r fig note; do
      reg_row_kind quiet "$fig" "$note"; [ $? -eq 1 ] || continue   # Q-761
      grep -qF -- "$(printf '%s\t' "$fig")" "$reg" || {
        echo "  [note] open-list row matches no registry row: \"$fig\""
        echo "         Either the figure was de-registered (delete the row) or the text drifted."; }
    done < "$open"
  fi
  if [ "$nopen" -ne 0 ]; then
    echo "  [note] $nopen registered figure(s) above are OPEN DEFECTS, not exemptions —"
    echo "         see $open. Writing those entries is an adjudication, not a gate change."
  fi
  [ "$bad" -eq 0 ] && echo "  [ok] all $n registered figure(s) accounted for ($((n-nopen)) recorded, $nopen open)"
  return $bad
}

gate_ledger_phrases() {
  echo "== GATE 11: registered retractions are recorded in CORRECTIONS.md =="
  local reg="documentation/RETRACTED_PHRASES.tsv" f="documentation/CORRECTIONS.md" rcr=0 rcf=0
  # ITEM A1. The old test named both files in ONE skip line, so a reader could not tell
  # which was missing; both are probed now and both verdicts print.
  require_tracked "$reg" "With the registry gone this gate has zero retractions to look for." || rcr=$?
  require_tracked "$f"   "With the ledger gone every registered retraction is unrecorded by definition." || rcf=$?
  if [ "$rcr" -eq 2 ] || [ "$rcf" -eq 2 ]; then return 1; fi
  if [ "$rcr" -ne 0 ] || [ "$rcf" -ne 0 ]; then return 0; fi
  # TOOL absence, not input absence: this was a [skip], which voided the whole gate while
  # the banner still said PASS. sha256sum is coreutils and is required by the keying scheme,
  # so its absence is a FAIL. NO FIRE-PROOF COVERS THIS LEG — see the A1 note at the head of
  # the file; hiding sha256sum from $PATH also hides git, grep and cut.
  command -v sha256sum >/dev/null 2>&1 || {
    echo "  [FAIL] sha256sum not on PATH — the RP-<sha> keying this gate is built on cannot"
    echo "         be computed, so the gate can check nothing. This is not a skip."
    return 1; }
  local bad=0 n=0 key _hr
  require_final_newline "$reg" || bad=1
  while IFS=$'\t' read -r phrase allow note; do
    # Q-761: was `case "$phrase" in ''|'#'*) continue` — a needle starting with # got no RP line.
    reg_row_kind loud "$phrase" "$allow" "$note"; case $? in 0) continue;; 2) bad=1; continue;; esac
    n=$((n+1))
    key="RP-$(printf '%s' "$phrase" | sha256sum | cut -c1-8)"
    # CX-230: a HASHED row already IS the phrase's digest; its key is that digest's first 8 digits,
    # the key the text row had.
    if _hr=$(hashed_row_parse "$phrase"); then key="RP-${_hr:0:8}"; fi
    if grep -qF -- "$key" "$f"; then
      echo "  [ok] $key recorded"
    else
      echo "  [FAIL] $key has NO entry in $f"
      echo "         registry note: $note"
      echo "         Add an entry to CORRECTIONS.md citing $key (append only)."
      bad=1
    fi
  done < "$reg"
  [ "$bad" -eq 0 ] && echo "  [ok] all $n registered retraction(s) accounted for"
  return $bad
}

# ----------------------------------------------------------------------------------
# GATE 14 — no two registry rules may be the same predicate (ITEM A6, 2026-08-02).
#
# WHY THIS EXISTS. `reg_r3` and `reg_p1c4` in solve.py are byte-distinct, separately
# attributed to two different authors, separately counted in a published total (EIGHT proven
# C1 constants — documentation/CLAIMS_DECIDED.md, TR-1 section 3) and separately proven in
# Lean 4 — and are the same function over orderings. That was found by hand on 2026-08-02.
# No gate looked for it, and nothing in the suite would have looked for the next one.
#
# WHAT IT DOES. Evaluates every rule in solve.py's REGISTRY_KW_EXPECTED over one SHARED,
# fully deterministic sample of orderings and compares the resulting value VECTORS. Two rules
# whose vectors are equal everywhere are reported; the adjudicated pairs live in
# documentation/DOC_GATE_REGISTRY_DUPLICATES.txt, and anything not there is a FAIL.
#
# COST, MEASURED NOT ESTIMATED (this is the reason it is in `all` and GATE 8 is not):
# 4,000 orderings x 31 rules = 124,000 rule evaluations, 4.4 s wall, a few MB resident —
# the sample is generated lazily and only 31 value-vectors are held. Sized as a formula
# before it was written, per the box-safety rule that a python DP's state key rebooted this
# orchestrator on 2026-08-01.
#
# THE SAMPLE IS THE INSTRUMENT, and a naive one would be worse than none. On UNIFORMLY
# RANDOM orderings nearly every boolean rule is False, so nearly every boolean PAIR would
# match and the gate would report ~200 duplicates, all spurious. The sample is therefore
# built where the rules are near their trip points:
#   * King Wen itself (every rule at its registry-expected value);
#   * ALL 2,016 single transpositions of KW — exhaustive, no sampling, no seed;
#   * 1,400 k-transposition perturbations, k = 2..8, seeded;
#   * 400 full shuffles, seeded, so a rule that only moves far from KW still moves;
#   * targeted MM-T5 witnesses (an ordering carrying the Qian-Kun-Zhen-Xun-Kan-Li-Gen-Dui
#     lower-trigram run in a window, at three offsets, plus 60 one-swap neighbours each).
# The witnesses are not decoration: WITHOUT them reg_mmt5 took ONE value across the whole
# sample, and a rule with one value is vacuously equal to every other constant rule and
# vacuously unequal to every varying one. Measured before and after.
#
# WHAT THIS GATE CANNOT SEE, said plainly rather than left to be inferred:
#   (a) It can prove two rules DIFFER. It cannot prove they are IDENTICAL — a finite sample
#       is a refutation instrument only. Every hit is a claim for a human to check, which is
#       exactly what the r3/p1c4 NOTEs in solve.py record having done.
#   (b) It compares VALUES, not attributions, not Lean theorems, not prose. Two rows can be
#       one ordering fact under two honest citations; that is O6/O2's question, not this
#       gate's.
#   (c) A rule that is constant on the sample is UNCOMPARABLE, and the gate FAILS on that
#       rather than passing quietly. A checker that reports [ok] on a rule it could not
#       examine is the false-clear class this suite exists to refuse.
gate_registry_dupes() {
  echo "== GATE 14: no two literature-registry rules are the same predicate =="
  local allow=documentation/DOC_GATE_REGISTRY_DUPLICATES.txt rca=0
  require_tracked "$allow" \
    "The allowlist IS half this gate: without it every adjudicated pair reads as new." || rca=$?
  [ "$rca" -eq 1 ] && return 0      # untracked and absent — nothing shipped is being checked
  [ "$rca" -eq 2 ] && return 1
  DOC_GATES_DUPE_ALLOW="$allow" python3 - <<'PY'
import itertools, os, random, sys
sys.path.insert(0, '.')
try:
    import solve
except Exception as exc:                       # noqa: BLE001 — any import failure is a FAIL
    print("  [FAIL] cannot import solve.py, so ZERO rules were compared: %s" % exc)
    print("         A gate that cannot load its subject has checked nothing.")
    sys.exit(1)

ids = [r for r, _ in solve.REGISTRY_KW_EXPECTED]
# PHASE-4 ON THIS GATE'S OWN FIRST DRAFT: without this, an emptied or renamed
# REGISTRY_KW_EXPECTED made the gate print "[ok] 0 rules, 0 pairs compared" and exit 0 — a
# green verdict from an instrument that compared nothing. Fewer than two rules cannot form a
# pair, so there is nothing this gate could have been doing.
if len(ids) < 2:
    print("  [FAIL] REGISTRY_KW_EXPECTED holds %d rule(s); fewer than two cannot form a pair,"
          " so this gate compared NOTHING" % len(ids))
    print("         A registry that shrank to nothing is a finding, not a clean run.")
    sys.exit(1)
kw = list(solve.binary_hexagrams)
# MM-T5's family order, quoted from reg_mmt5's own docstring so the witness cannot drift
# away from the rule silently.
FAMILY = [7, 0, 1, 6, 2, 5, 4, 3]


def witnesses():
    block = []
    for t in FAMILY:
        for h in range(64):
            if solve.lower_trigram(h) == t and h not in block:
                block.append(h)
                break
    rest = [h for h in kw if h not in block]
    for off in (0, 20, 49):
        yield rest[:off] + block + rest[off:]


def sample():
    yield list(kw)
    for i, j in itertools.combinations(range(64), 2):
        s = list(kw)
        s[i], s[j] = s[j], s[i]
        yield s
    rng = random.Random(20260802)
    for k in range(2, 9):
        for _ in range(200):
            s = list(kw)
            for _ in range(k):
                a, b = rng.randrange(64), rng.randrange(64)
                s[a], s[b] = s[b], s[a]
            yield s
    for _ in range(400):
        s = list(kw)
        rng.shuffle(s)
        yield s
    for w in witnesses():
        yield w
        for _ in range(60):
            s = list(w)
            a, b = rng.randrange(64), rng.randrange(64)
            s[a], s[b] = s[b], s[a]
            yield s


fns = [getattr(solve, "reg_" + r) for r in ids]
vecs = [[] for _ in ids]
n = 0
for seq in sample():
    if sorted(seq) != list(range(64)):
        print("  [FAIL] sample generator emitted a non-permutation at index %d" % n)
        sys.exit(1)
    n += 1
    # repr(), not the raw value, and the reason is a live hazard rather than tidiness:
    # `True == 1` in Python, so a boolean rule and a count rule that happened to return 1
    # would compare EQUAL under `==` and the gate would report a duplicate that is only a
    # type pun. registry_verify() guards the same confusion with `type(value) is
    # type(expected)`; this is the vector-comparison form of that check.
    for idx, fn in enumerate(fns):
        vecs[idx].append(repr(fn(seq)))

allow = {}
path = os.environ["DOC_GATES_DUPE_ALLOW"]
with open(path, encoding="utf-8") as fh:
    for lineno, line in enumerate(fh, 1):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        parts = line.rstrip("\n").split("\t")
        if len(parts) < 3 or not parts[2].strip():
            print("  [FAIL] %s:%d is not `a<TAB>b<TAB>note`, so the row exempts nothing"
                  " and names no reason" % (path, lineno))
            sys.exit(1)
        allow[tuple(sorted(parts[:2]))] = lineno

bad = 0
known = set(ids)
for pair, lineno in sorted(allow.items()):
    unknown = [r for r in pair if r not in known]
    if unknown:
        print("  [FAIL] %s:%d allowlists %s, which is not in REGISTRY_KW_EXPECTED"
              % (path, lineno, "/".join(unknown)))
        print("         A row keyed to a rule that no longer exists exempts nothing and"
              " hides that it exempts nothing.")
        bad = 1

flat = [ids[i] for i in range(len(ids)) if len(set(vecs[i])) < 2]
if flat:
    for r in flat:
        print("  [FAIL] reg_%s takes ONE value across all %d sampled orderings, so it cannot"
              " be compared" % (r, n))
    print("         An unvarying rule is vacuously equal to every other unvarying rule and"
          " vacuously")
    print("         unequal to every varying one, so its column of this gate is a false"
          " clear, not a pass.")
    print("         Add a targeted witness to the sample (see the MM-T5 witnesses) that"
          " makes it vary.")
    bad = 1

hits = []
for a, b in itertools.combinations(range(len(ids)), 2):
    if vecs[a] == vecs[b]:
        hits.append(tuple(sorted((ids[a], ids[b]))))

for pair in hits:
    if pair in allow:
        print("  [note] reg_%s and reg_%s agree on all %d sampled orderings — adjudicated at"
              " %s:%d" % (pair[0], pair[1], n, path, allow[pair]))
    else:
        print("  [FAIL] reg_%s and reg_%s return the SAME value on all %d sampled orderings"
              % (pair[0], pair[1], n))
        print("         Two registry rows that are one function are one ordering fact under"
              " two citations —")
        print("         separately attributed, separately counted in any published total,"
              " and separately")
        print("         proven. Check by hand, then record the verdict in %s." % path)
        bad = 1

stale = [(p, ln) for p, ln in sorted(allow.items())
         if p not in set(hits) and all(r in known for r in p)]
for pair, lineno in stale:
    print("  [FAIL] %s:%d allowlists reg_%s/reg_%s, but they now DIFFER on the sample"
          % (path, lineno, pair[0], pair[1]))
    print("         The exemption is stale: it would silently absolve a future duplication"
          " of the same")
    print("         pair that nobody adjudicated. Delete the row.")
    bad = 1

if not bad:
    print("  [ok] %d rules, %d pairs compared on %d orderings; %d adjudicated pair(s), 0 new"
          % (len(ids), len(ids) * (len(ids) - 1) // 2, n, len(hits)))
sys.exit(bad)
PY
}

