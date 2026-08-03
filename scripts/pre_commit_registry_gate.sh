#!/bin/bash
# Pre-commit gate for the RETRACTION REGISTRY and the CORRECTIONS LEDGER (item R17).
#
# STATUS: WRITTEN, NOT INSTALLED. Read the INSTALL section before symlinking it.
#
# WHY THIS EXISTS — measured, not supposed.
#   The only pre-commit hook this repo had (scripts/pre_commit_generated_gate.sh,
#   task #85) has a WATCHED set of exactly roae.py plus the five example/ artifacts.
#   A commit touching documentation/RETRACTED_PHRASES.tsv, RETRACTED_FIGURES.tsv or
#   CORRECTIONS.md was therefore gated by NOTHING.
#
#   Round 14 (2026-08-02) landed THREE commits with a red floor, all in that hole:
#     316c6581  GATE 11 red — registry rows with no ledger entry
#     8f2f292c  GATE 11 red — five more of the same, from a different unit, 59 min later
#     bed707db  GATE 3  red — the fix for the above quoted all five retracted phrasings
#                             VERBATIM into the append-only ledger
#   A fourth, 728778e7, turned GATE 10b red by rewriting a committed CORRECTIONS.md
#   entry in place, deleting ten lines from a version that was already committed.
#   Each unit's own gate run was green at the moment it ran; the collisions were
#   between units. No per-unit discipline can catch that, which is what makes this
#   mechanical rather than advisory.
#
#   One of those commits produced a defect that can NEVER be removed, because the
#   ledger is append-only and the commit was subsequently pushed. This gate is aimed
#   squarely at that: the cost of a red registry/ledger commit is not "fix it next
#   time", it is permanent.
#
# WHAT IT RUNS, and why the union rather than a per-file selection.
#   All six leaf gates run whenever ANY of the three files is staged. That is a
#   correctness choice, not a convenience one: GATE 11 relates registry ROWS to
#   ledger ENTRIES, so editing either side can turn it red, and GATE 3's `allow`
#   column was re-scoped to CORRECTIONS.md (b4f20e2c) — which couples the ledger's
#   content to the retraction corpus scan. Selecting gates per-file would have to
#   re-derive that coupling and would rot when it changes.
#
#   Measured cost on this box, 2026-08-03, one run each:
#     retract 4.02s · retract-figures 0.16s · ledger-phrases 0.11s
#     ledger-figures 0.11s · appendonly-head + appendonly-history 0.17s combined
#   Total ~4.4s, against 62.2s for `generated`. The "only fires when the commit
#   touches the watched set" property of #85's hook is preserved, and even when it
#   does fire it costs seconds.
#
#   LEAF DISPATCH NAMES are used deliberately (item B2). `ledger` runs both halves
#   and `appendonly` runs both of its own, so a refusal reported against either
#   combined name could not say which half answered. Every name below is a leaf.
#
# FAIL DIRECTION: CLOSED, for the same reason #85's hook is closed. A false stop
#   costs one `git commit` retry. A false pass writes a permanent line into an
#   append-only ledger. The asymmetry is not close.
#
# NO BYPASS ENV VAR, deliberately, per #85's hook: `git commit --no-verify` already
#   exists, is standard, and stays visible in the operator's shell history.
#
# ---------------------------------------------------------------------------
# WHAT THIS GATE CANNOT SEE. Read this before trusting a PASS.
#
#   1. It checks the WORKING TREE, because doc_gates.sh does. It refuses when a
#      WATCHED path differs between index and working tree (below), so the watched
#      bytes are the committed bytes — but GATE 3 scans the WHOLE corpus, and an
#      unrelated dirty file elsewhere in documentation/ or reports/ is read in its
#      dirty state. A pass is a statement about the tree as it stands, not purely
#      about the commit. #85's hook has the identical limitation.
#   2. It cannot see a defect in the ENGLISH of a ledger entry. GATE 11 asks only
#      whether the RP-<sha> key appears in CORRECTIONS.md. An entry citing the right
#      key while describing the wrong thing passes. Round 14's CX-23 did exactly
#      that and needed CX-24 to correct it; no gate caught it, and this one would
#      not have either.
#   3. It does not decide whether a commit may land red AT ALL. That is the
#      operator's call (inbox O-redfloor). This script is the mechanism; it is
#      supplied uninstalled so that installing it remains a decision someone makes.
#
# ---------------------------------------------------------------------------
# INSTALL — READ THIS, a naive symlink SILENTLY DISABLES THE #85 GATE.
#
#   .git/hooks/pre-commit is ALREADY a symlink to pre_commit_generated_gate.sh.
#   Git runs exactly one pre-commit hook. Pointing that symlink here would remove
#   the generated-artifact gate without any message saying so. To run both, replace
#   the symlink with a two-line dispatcher:
#
#     rm .git/hooks/pre-commit
#     cat > .git/hooks/pre-commit <<'EOF'
#     #!/bin/bash
#     bash scripts/pre_commit_generated_gate.sh || exit 1
#     bash scripts/pre_commit_registry_gate.sh  || exit 1
#     EOF
#     chmod +x .git/hooks/pre-commit
#
#   Or invoke directly, without installing:
#     bash scripts/pre_commit_registry_gate.sh && git commit ...
set -u

REPO_ROOT="$(git rev-parse --show-toplevel)" || exit 1
cd "$REPO_ROOT" || exit 1

# The retraction registries and the append-only ledger they are checked against.
WATCHED="documentation/RETRACTED_PHRASES.tsv
documentation/RETRACTED_FIGURES.tsv
documentation/CORRECTIONS.md"

# DELETIONS ARE INCLUDED (D), unlike #85's hook, which uses ACM. Deleting the
# ledger or a registry is the maximal form of the defect this gate exists for, not
# an exemption from it; require_tracked inside GATE 11 is what catches it. R covers
# a rename, which reports the new path.
STAGED=$(git diff --cached --name-only --diff-filter=ACMRD)
[ -n "$STAGED" ] || exit 0

HITS=$(printf '%s\n' "$WATCHED" | grep -Fxf <(printf '%s\n' "$STAGED") 2>/dev/null || true)
[ -n "$HITS" ] || exit 0

echo "pre-commit: registry/ledger files touched by this commit:"
printf '  %s\n' $HITS

# The gates read the WORKING TREE; the commit records the INDEX. If those disagree
# for a watched path the gate would validate bytes this commit does not contain and
# report a pass for them. Same reasoning as #85's hook, same refusal.
DIRTY=""
for f in $HITS; do
  if ! git diff --quiet -- "$f" 2>/dev/null; then DIRTY="$DIRTY $f"; fi
done
if [ -n "$DIRTY" ]; then
  echo "pre-commit: REFUSING — these paths differ between the index and the working tree:"
  printf '  %s\n' $DIRTY
  echo "  The gates inspect the working tree, so they would be checking bytes this"
  echo "  commit will not contain. Stage them (git add) or stash the difference."
  exit 1
fi

if [ ! -f scripts/doc_gates.sh ]; then
  echo "pre-commit: REFUSING — scripts/doc_gates.sh is missing, so the registry and"
  echo "  ledger in this commit cannot be checked. That is a reason to stop, not to proceed."
  exit 1
fi

# Leaf dispatch names only (item B2): each entry names exactly one gate function, so
# a refusal below can say which gate answered.
GATES="retract retract-figures ledger-phrases ledger-figures appendonly-head appendonly-history"

FAILED=""
for g in $GATES; do
  echo "pre-commit: running doc_gates.sh $g ..."
  if ! bash scripts/doc_gates.sh "$g"; then
    FAILED="$FAILED $g"
  fi
done

if [ -z "$FAILED" ]; then
  echo "pre-commit: registry/ledger gates PASSED ($GATES)"
  echo "  NOTE: this checks that every registry row has a ledger entry citing its"
  echo "  RP-/RF- key, that no retracted phrasing appears in the corpus, and that no"
  echo "  committed CORRECTIONS.md line has been removed. It does NOT check that the"
  echo "  entry DESCRIBES the retraction correctly — round 14's CX-23 passed and was"
  echo "  still wrong."
  exit 0
fi

echo
echo "pre-commit: BLOCKED — registry/ledger gate(s) failed:$FAILED"
echo "  WHY THIS FIRED: this commit stages one or more of"
printf '    %s\n' $HITS
echo "  and the gate(s) named above returned non-zero against the resulting tree."
echo
echo "  If GATE 11 (ledger-phrases / ledger-figures) failed: you added a registry row"
echo "    with no matching entry in documentation/CORRECTIONS.md. Append an entry"
echo "    citing the RP-/RF- KEY. Cite the key, NEVER the retracted string — quoting"
echo "    the string puts it permanently into an append-only file (round 14, CX-23)."
echo "  If GATE 3 (retract / retract-figures) failed: a registered retracted phrasing"
echo "    is live somewhere in the corpus. Reword the corpus, do not widen the allow"
echo "    column to hide it."
echo "  If GATE 10b (appendonly-history) failed: this commit REMOVES a line that a"
echo "    previous commit's CORRECTIONS.md contained. The ledger is append-only over"
echo "    every committed version. Append a superseding entry instead of editing."
echo
echo "  If you are certain this is wrong, 'git commit --no-verify' bypasses it and"
echo "  leaves that decision visible in your shell history."
exit 1
