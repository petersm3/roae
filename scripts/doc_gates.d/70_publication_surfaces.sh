#@ scripts/doc_gates.d/70_publication_surfaces.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATES 19-24, 79 and 81-89: branch registry, publication state, script paths, hex prefixes, surfaces, invariants, value domains.
#@ Lines 11893-14246 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ---------------------------------------------------------------------------
# GATE 19 — published branches must be DECLARED.
#
# THE HOLE THIS CLOSES. Every other gate in this file reads the WORKING TREE. The only
# place `origin/main` appears is as a COMMIT RANGE (origin/main..HEAD, the unpushed stack) —
# no gate has ever read another branch's CONTENT. So on 2026-08-08 all five non-main public
# branches carried a sentence retracted on main by CX-30 (a figure wrong by ~29 orders of
# magnitude, in the flattering direction) and the entire suite was green throughout. That is
# not a missed run; it is an uncovered surface.
#
# WHAT IT ENFORCES, and what it deliberately does NOT. It does not diff branch prose against
# main's corrections — that check is unbounded and, tried crudely, is actively misleading:
# counting retracted phrases per branch scored MAIN HIGHEST, because main carries the
# correction text. Measuring narration is not measuring defects. Instead this enforces the
# DECLARATION: every published branch must appear in documentation/BRANCH_REGISTRY.tsv with a
# status, so a reader is told which refs are authoritative and which are frozen snapshots that
# may contain since-corrected claims. A new undeclared branch fails the gate.
#
# SUBJECT = THE REMOTE, NOT THE CACHE (V-2, 2026-09-02). Until this date the gate read
# refs/remotes/origin/* — whatever this clone last fetched, with no fetch or prune — and so
# certified a CACHE. Measured in a scratch clone against a local bare remote: delete one cached
# ref and its registry row and the old form printed "[ok] 4 published branch(es)" rc 0 while
# `git ls-remote --heads origin` still listed that branch, undeclared; the mirror image, an
# unpruned ref for a branch deleted days earlier, FAILED a clean remote — the false positive a
# reviewer filed (Codex V2-L15 #1). In this clone cache happened to equal remote, so the live
# verdict was right by accident. Now `git ls-remote --heads origin` is the subject (one network
# round-trip, ~1 s measured to GitHub), the local cache is diffed against it and every drift is
# printed as a [note], and a remote that cannot be listed is a FAILED MEASUREMENT (rc 1), not a
# pass. Two knobs, documented HERE and deliberately NOT in the failure text — an escape hatch
# printed beside the failure it silences becomes the fix:
#   DOC_GATES_LS_REMOTE_TIMEOUT=<seconds>  give up on ls-remote after this long (default 25)
#   DOC_GATES_ALLOW_STALE_REMOTE=1         OFFLINE OPT-IN: certify the local cache instead. Prints
#                                          BRANCH_REGISTRY_SOURCE=local-cache and the fetch time,
#                                          so the verdict says what it is about.
# A clone with NO origin remote configured is a genuine empty subject and passes with a [note];
# an origin that is configured but yields no refs is a failed enumeration and fails.
gate_branch_registry() {
  echo "== GATE 19: every published branch is declared in the branch registry =="
  local REG=documentation/BRANCH_REGISTRY.tsv rc=0
  if [ ! -r "$REG" ]; then
    echo "  [FAIL] $REG is missing — the registry IS the fix; without it nothing tells a"
    echo "         reader which refs are authoritative."
    return 1
  fi
  local declared remotes b st n
  declared=$(awk -F'\t' '$1 == "#" || $1 ~ /^# / {next} NF && $1 != "" {print $1}' "$REG")  # Q-773: git allows a branch "#7"; a comment is col 1 "#" or "# ..."
  # CODEX N10 FINDING 10, adjudicated 2026-09-03: THE CLAIM EXCEEDED THE CHECK. The header
  # thirty lines above promises "every published branch must appear in
  # documentation/BRANCH_REGISTRY.tsv WITH A STATUS", and the extraction above reads column 1
  # and nothing else. A one-column row, or a row whose status is `nonsense`, satisfied the gate
  # and the [ok] line still said the branches were declared. The status IS the disclosure —
  # `snapshot` is what tells a reader the ref may carry claims since corrected on main — so a
  # row without one declares a name and no fact.
  #
  # THE VOCABULARY IS ASSERTED HERE, IN THE ENFORCER, NOT READ FROM THE SUBJECT. A gate that
  # learns its accepted values from the file it is checking can be widened by editing that
  # file, which is the verifier-closure defect (a witness derived from its own target). The
  # registry's own header ALSO declares the set, so the two are cross-checked and a drift
  # between them is itself a failure: widening the vocabulary now takes a deliberate edit in
  # both places.
  # `retired` added 2026-09-04, deliberately and in BOTH places, because this gate refuses a
  # vocabulary widened in only one — a rule a gate reads from its own subject could otherwise be
  # widened by editing the subject. It earned its keep the same day: it caught exactly that.
  # WHY the status is needed: four public branches were deleted on 2026-09-04 (three merged into
  # main, one — orbit-port-188-candidate — tag-preserved without merging). Their rows STAY, because
  # this file is how a reader holding a citation to a deleted ref learns where it went: column 4
  # names the tag that still pins the commit. Removing the rows would leave that reader nothing.
  local G19_VOCAB="authoritative snapshot merged retired" _g19hdr _g19bad
  _g19hdr=$(grep -m1 -oE 'status: [a-z]+( \| [a-z]+)*' "$REG" | sed 's/^status: //; s/ *| */ /g')
  if [ "$_g19hdr" != "$G19_VOCAB" ]; then
    echo "  [FAIL] $REG's own header declares the status vocabulary as"
    echo "         '${_g19hdr:-(no \"status: a | b | c\" line found)}' but this gate enforces '$G19_VOCAB'."
    echo "         One of the two moved. Change BOTH deliberately or neither: a vocabulary a"
    echo "         gate reads from its own subject can be widened by editing the subject."
    rc=1
  fi
  _g19bad=$(awk -F'\t' -v vocab="$G19_VOCAB" '
      BEGIN { n = split(vocab, v, " "); for (i = 1; i <= n; i++) ok[v[i]] = 1 }
      $1 == "#" || $1 ~ /^# / { next } !NF { next } $1 == "" { next }
      (NF < 2 || !($2 in ok)) {
        printf "%d\t%s\t%s\n", FNR, $1, (NF < 2 ? "(no status column at all)" : "\"" $2 "\"")
      }' "$REG")
  if [ -n "$_g19bad" ]; then
    while IFS=$'\t' read -r _ln _br _st; do
      echo "  [FAIL] $REG:$_ln declares branch '$_br' with status $_st, which is not one of"
      echo "         { $G19_VOCAB }. The status is the disclosure this registry exists to make;"
      echo "         a row without a valid one names a branch and tells a reader nothing about it."
    done <<< "$_g19bad"
    rc=1
  fi
  # Filter refs/remotes/origin/HEAD by its FULL refname, not its short form. Its short form is
  # bare "origin" (not "HEAD"), so a `grep -v '^HEAD$'` on the shortened name never matches it
  # and the symbolic default-branch pointer gets reported as an undeclared branch. This gate's
  # first live run did exactly that — caught here rather than shipped.
  local cache
  cache=$(git for-each-ref --format='%(refname)' refs/remotes/origin/ 2>/dev/null \
            | grep -v '^refs/remotes/origin/HEAD$' | sed 's|^refs/remotes/origin/||')
  # V-2 (Codex V2-L15 #1 residue, 2026-09-02): refs/remotes/origin/* is a CACHE of whatever
  # this clone last fetched, not the remote. Measured in a scratch clone: delete the cached
  # ref of a real published branch and drop its registry row -> the old form printed [ok]
  # rc=0 while `git ls-remote --heads origin` still listed that branch, undeclared. The
  # reviewer's own FALSE charge was the mirror image (unpruned refs for branches deleted
  # days earlier). Neither state is visible to a reader of the cache. So the subject is
  # read from the remote when it can be, the cache is compared against it and any drift is
  # printed, and a remote that cannot be reached is a FAILED measurement, not a pass
  # (an explicit opt-in for offline runs is documented in the gate header, not here).
  local live src=local-cache
  remotes=""
  if git remote get-url origin >/dev/null 2>&1; then
    if live=$(timeout "${DOC_GATES_LS_REMOTE_TIMEOUT:-25}" git ls-remote --heads origin 2>/dev/null); then
      remotes=$(printf '%s\n' "$live" | awk 'NF==2 {print $2}' | sed 's|^refs/heads/||')
      src=remote; echo "  BRANCH_REGISTRY_SOURCE=remote"
      local _c
      for _c in $cache; do
        grep -qxF "$_c" <<<"$remotes" \
          || echo "  [note] local cache ref origin/$_c is NOT on the remote — a stale remote-tracking ref (git fetch --prune); it is NOT counted"
      done
      for _c in $remotes; do
        grep -qxF "$_c" <<<"$cache" \
          || echo "  [note] remote branch '$_c' is absent from the local cache (git fetch); it IS counted"
      done
    elif [ "${DOC_GATES_ALLOW_STALE_REMOTE:-0}" = "1" ]; then
      remotes=$cache
      echo "  BRANCH_REGISTRY_SOURCE=local-cache"
      echo "  [note] the remote could not be listed; certifying the LOCAL CACHE as of $(stat -c '%y' .git/FETCH_HEAD 2>/dev/null || echo 'an unknown fetch time'),"
      echo "         which is NOT a statement about what is published now."
    else
      echo "  [FAIL] an 'origin' remote IS configured but 'git ls-remote --heads origin' failed or"
      echo "         timed out, so the set of PUBLISHED branches could not be measured. A verdict"
      echo "         drawn from the local refs/remotes cache would certify a cache, not the remote."
      return 1
    fi
  fi
  # Codex v2: this enumerated ONLY branches that already exist on the remote, so a
  # branch being published for the FIRST TIME could never be caught -- the gate ran
  # after the fact, never before. DOC_GATES_PENDING_BRANCHES lets the pre-push hook
  # name refs it is about to create, so they are declared BEFORE they are published,
  # which is the only moment the check is worth anything.
  if [ -n "${DOC_GATES_PENDING_BRANCHES:-}" ]; then
    local _p
    for _p in $DOC_GATES_PENDING_BRANCHES; do
      _p=${_p#refs/heads/}
      # $remotes is NEWLINE-separated. This was `case " $remotes " in *" $_p "*)`, a SPACE-delimited
      # membership test that never matched, so an already-published name was appended AGAIN.
      # Measured 2026-09-02 (pre-push hook, 5 real branches): "[ok] 10 published branch(es)" and
      # a false "registry row 'v4-query-program' matches no published branch" note, because the
      # appended names shared one line with the last real one. The per-branch verdict loop
      # word-splits and was unaffected; the printed population was wrong by 2x.
      if ! grep -qxF "$_p" <<<"$remotes"; then
        remotes="${remotes:+$remotes
}$_p"; echo "  [pending] also checking branch about to be published: $_p"
      fi
    done
  fi
  # NO SUBJECT vs CANNOT SEE THE SUBJECT — two states this used to report as one, and only
  # one of them may pass (swept 2026-09-02 alongside Codex v2 charge 5, which is about this
  # same gate). A tree with no `origin` remote CONFIGURED has nothing published to check and
  # is a legitimate pass; a tree that HAS an `origin` remote but from which no ref could be
  # enumerated is an enumeration that failed, and "no undeclared branches" would then be a
  # statement about data nobody read. The old branch printed a [note] and returned 0 for
  # both, which is the class root exactly: absence of evidence read as evidence.
  if [ -z "$remotes" ]; then
    if git remote get-url origin >/dev/null 2>&1; then
      echo "  [FAIL] an 'origin' remote IS configured but NO refs/remotes/origin/* could be"
      echo "         enumerated. That is a failed enumeration, not an empty remote — this gate"
      echo "         cannot certify branches it was unable to list. (git fetch, or check that"
      echo "         'git for-each-ref refs/remotes/origin/' works here.)"
      return 1
    fi
    echo "  [note] no 'origin' remote is configured in this clone, so there are no published"
    echo "         branches for this leg to check. That is a genuine empty subject (a tarball"
    echo "         or 'git init' tree), not a clean bill of health about any remote."
    return 0
  fi
  n=0
  for b in $remotes; do
    if ! grep -qxF "$b" <<<"$declared"; then
      echo "  [FAIL] published branch '$b' is NOT declared in $REG."
      echo "         Add it as 'authoritative' or 'snapshot'. An undeclared public branch is"
      echo "         exactly how CX-30 stayed visible on five refs after main had retracted it."
      rc=1
    else
      n=$((n+1))
    fi
  done
  # A registry row for a branch that no longer exists is stale, not dangerous — report, do not fail.
  for b in $declared; do
    grep -qxF "$b" <<<"$remotes" || awk -F'\t' -v b="$b" '$1 == b && $2 == "retired" {f = 1} END {exit !f}' "$REG" || echo "  [note] registry row '$b' matches no published branch (deleted?) — mark it 'retired' (the file keeps retired rows; Q-763)."
  done
  # The snapshot declaration is worthless if the reader is never pointed at it.
  if ! grep -qF 'BRANCH_REGISTRY.tsv' README.md 2>/dev/null; then
    echo "  [FAIL] README.md does not point at $REG, so the declaration is unreachable from the"
    echo "         entry point. A notice nobody is routed to is not a disclosure."
    rc=1
  fi
  [ "$rc" -eq 0 ] && echo "  [ok] $n published branch(es) declared (source: $src); README routes readers to the registry"
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 20 — the published corpus must not say it is unfinished.
#
# THE DEFECT. On 2026-08-08, documentation/CAMPAIGN_METHODOLOGY.md — a PUBLISHED
# document — carried a live "Pre-publish TODO (operator review): … genericize
# before publishing (this is a public doc)" and a "## DRAFT TODO before porting
# to public" section with ~16 unchecked boxes, one of which read "delete
# LARGE_SCALE_CAMPAIGNS.md". A reader is told, correctly, that the document is
# not finished being published. Worse, that draft section's central premise was
# FALSE, and following it would have deleted a candid limitation disclosure.
#
# THE HARD PART IS THE FALSE POSITIVE, and it is why this gate is narrow.
# `- [ ]` has a legitimate use: a checklist FOR THE READER to tick.
# documentation/DEPLOYMENT.md §"Pre-launch checklist" has 15 such boxes and is
# correct markdown — a replicator ticks them off before launching. A gate that
# banned unchecked boxes outright would fire on the single best-designed
# checklist in the corpus, be silenced with an exemption, and thereafter catch
# nothing. So:
#   * unchecked boxes UNDER A "checklist" HEADING  -> allowed (reader-facing)
#   * unchecked boxes ANYWHERE ELSE               -> FAIL (internal TODO)
#   * HEADING-form draft markers                  -> FAIL always
#   * the same words INLINE in a sentence         -> allowed (narration of a
#     past defect is how CORRECTIONS.md works; banning it would forbid the
#     corpus from describing its own history)
gate_publication_state() {
  echo "== GATE 20: no live pre-publish / draft markers in the published corpus =="
  local rc=0 f hits n
  # (a) heading-form draft markers — never legitimate in a published doc.
  # Matched as a CLASS, not as a list of the specific strings that happened to be
  # found once. The first cut of this leg enumerated three literal phrases
  # ("DRAFT TODO", "Before porting to public", "Pre-publish TODO") plus a fourth
  # alternative, '^#+[[:space:]]*WIP', whose '^' sat mid-pattern after '.*' and so
  # could never match — a dead branch. It therefore passed a document carrying a
  # bare '## DRAFT', the most obvious form of the defect it names (measured
  # 2026-08-09 by appending exactly that to a published report). An enumeration of
  # variants already seen cannot refuse a class; that is the retrospective-gate
  # failure the registry's own history keeps producing.
  # The all-caps forms are required to BE all-caps: DRAFT/WIP/TODO/FIXME/UNPUBLISHED
  # are marker conventions, while lowercase "draft" is ordinary narration — e.g.
  # CORRECTIONS.md's "TR-9's draft-stage note", which must not fire. The multi-word
  # phrases are matched case-insensitively because they are never conventions.
  # Measured at adoption: zero hits across the tracked markdown corpus.
  # 🔴 Q-284: this re-enumerated the corpus with its own unguarded `git ls-files ... || true`,
  # so a failed enumeration produced an empty $hits and the gate announced the published
  # corpus free of draft markers having read nothing. Consume the guarded $DOCS instead:
  # one enumeration, one guard, and no second place for this to go wrong.
  hits=$(printf '%s\n' "$DOCS" | xargs grep -nE '^#{1,6}[[:space:]].*(\<(DRAFT|WIP|TODO|FIXME|UNPUBLISHED)\>|[Nn]ot for publication|[Dd]o not publish|[Pp]re-publish|[Bb]efore porting to public)' 2>/dev/null)
  # Q-965 (A07#4): the grep above reads column-0 ATX lines only, so "   ## DRAFT" (indented 1-3
  # spaces, still a heading) and a setext "DRAFT\n=====" passed. The shared normaliser's headings add
  # those forms, outside code fences; a heading inside a `>` block quote is a quotation and is left out
  # (measured: QUERY_INVENTORY.md:3 is the one such line, "> ### PUBLIC DRAFT", not an R1 form).
  local hits2
  hits2=$(printf '%s\n' "$DOCS" | python3 -c "$(_md_norm_prelude)"'
import sys, re
MK = re.compile(r"\b(?:DRAFT|WIP|TODO|FIXME|UNPUBLISHED)\b|[Nn]ot for publication|[Dd]o not publish|[Pp]re-publish|[Bb]efore porting to public")
for f in (l.strip() for l in sys.stdin):
    if not f:
        continue
    try:
        L, kind, blocks, unc = md_parse(md_read(f))
    except OSError as e:
        print("%s:0:could not be read (%s), so it was NOT scanned" % (f, e)); continue
    for b in blocks:
        raw = L[b["start"] - 1]
        if b["kind"] != "heading" or re.match(r"#{1,6}[ \t]", raw) or raw.lstrip().startswith(">"):
            continue
        if MK.search(b["title"]):
            print("%s:%d:%s" % (f, b["start"], raw))
') || { echo "  [FAIL] GATE 20's heading scanner failed — NOTHING was checked."; rm -f "${_G20_OUT:-}"; return 1; }
  hits=$(printf '%s\n%s\n' "$hits" "$hits2" | grep .)
  if [ -n "$hits" ]; then
    echo "$hits" | sed 's/^/  [FAIL] heading-form draft marker: /'
    echo "         A published document must not carry a section announcing it is unpublished."
    echo "         Resolve it (state the decision) or delete it — do not leave it addressed to a future self."
    rc=1
  fi
  # (b) unchecked boxes outside a reader checklist
  # mktemp is CHECKED: a gate that cannot create its own scratch file must not proceed
  # to report "clean". TMPDIR-honouring rather than hardcoded /tmp.
  _G20_OUT=$(mktemp) || { echo "  [FAIL] GATE 20 could not create a temp file"; return 1; }
  n=0
  # Codex v2 charge 2/3, SIBLING FOUND WHILE SWEEPING (2026-09-02). The charge closed the
  # SCRATCH-FILE carrier (unchecked `> /tmp/g20_$$`); it did not close the SCANNER carrier,
  # which is the same defect one level in. `awk` is invoked once per file with its exit
  # status discarded, so an awk that cannot run — absent, broken, or erroring on a file —
  # produces NO output, and no output was read as "no unchecked boxes". MEASURED: with a
  # shim `awk` that exits 127 and a planted `- [ ]` outside any checklist heading in
  # documentation/DEPLOYMENT.md, this gate printed "[ok] ... every unchecked box sits under
  # a reader checklist" and exited 0 — the exact sentence it exists to be able to refuse.
  #
  # THE FIX IS A POSITIVE ATTESTATION, not another rc check: awk stamps a ##SCANNED line
  # for every file it reaches the END of, and the shell requires one stamp per corpus file.
  # An rc check alone would still miss a partial write; a per-file receipt cannot be
  # forged by silence, which is the property the whole class is short of.
  local _g20_docs _g20_scanned
  _g20_docs=$(printf '%s\n' "$DOCS" | grep -c .)
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    awk -v FN="$f" '
      /^ {0,3}#{1,6}[[:space:]]/ { inck = (tolower($0) ~ /checklist/) ? 1 : 0 }
      /^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]+\[ \]/ { if (!inck) printf "  [FAIL] %s:%d unchecked box outside a reader checklist: %s\n", FN, NR, substr($0, 1, 72) }
      END { printf "##SCANNED\t%s\n", FN }
    ' "$f" || printf '##AWKFAIL\t%s\n' "$f"
  done < <(printf '%s\n' "$DOCS") > "$_G20_OUT" 2>/dev/null   # Q-284: guarded $DOCS, not a second unguarded enumeration
  # Codex v2 / fail-open class: this wrote to /tmp/g20_$$ with the redirect UNCHECKED
  # and stderr discarded. If the redirect failed -- unwritable /tmp, full disk -- the
  # file never existed, `[ -s ... ]` was false, and the gate printed "[ok] every
  # unchecked box sits under a reader checklist" having recorded nothing. Replicated
  # with an unwritable dir plus a planted finding. ABSENT and EMPTY are now
  # distinguished: absent is an ERROR, empty is genuinely clean.
  if [ ! -f "$_G20_OUT" ]; then
    echo "  [FAIL] GATE 20 could not write its findings file ($_G20_OUT)"
    echo "         The scan did not run to completion, so 'no findings' would be a lie."
    rm -f "$_G20_OUT"
    return 1
  fi
  # THE RECEIPTS, checked BEFORE the findings are read. If the scan did not cover the
  # corpus, "no findings" is not a result — the count must match or this gate has nothing
  # to say, and saying nothing must be loud.
  if grep -q '^##AWKFAIL	' "$_G20_OUT" 2>/dev/null; then
    echo "  [FAIL] GATE 20's per-file scanner FAILED on:"
    grep '^##AWKFAIL	' "$_G20_OUT" | cut -f2 | sed 's/^/           /'
    echo "         Those files were NOT scanned, so this gate cannot report them clean."
    rm -f "$_G20_OUT"
    return 1
  fi
  _g20_scanned=$(grep -c '^##SCANNED	' "$_G20_OUT" 2>/dev/null); _g20_scanned=${_g20_scanned:-0}
  if [ "$_g20_scanned" -ne "${_g20_docs:-0}" ]; then
    echo "  [FAIL] GATE 20 scanned $_g20_scanned of ${_g20_docs:-0} corpus files."
    echo "         A partial scan cannot certify the corpus. This is the fail-open shape the"
    echo "         mktemp guard above was added for, one level in: an empty findings file is"
    echo "         indistinguishable from a scanner that never ran unless every file leaves a"
    echo "         receipt. Do not read this as zero findings."
    rm -f "$_G20_OUT"
    return 1
  fi
  if grep -v '^##' "$_G20_OUT" | grep -c . >/dev/null; then
    grep -v '^##' "$_G20_OUT"
    echo "         An unchecked box in published prose is an obligation the document has not met."
    echo "         Reader-facing checklists are exempt — put them under a heading containing 'checklist'."
    rc=1
  fi
  rm -f "$_G20_OUT"
  [ "$rc" -eq 0 ] && echo "  [ok] no heading-form draft markers; every unchecked box in all $_g20_scanned scanned corpus file(s) sits under a reader checklist"
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 21 — backticked repo paths (top-level dirs, `roae-private/`, `roae/`) must
# resolve, or be declared narration.
#
# WHAT IT CAUGHT. Markdown LINKS are gated (GATE 4). Code-font PATHS were not.
# On 2026-08-09 that gap was holding four references to
# `scripts/d128_preflight_throttle_probe.sh` — a file that exists in NEITHER
# repository NOR anywhere on disk, never written — one of which told the reader
# imperatively to RUN it before a paired bench. The real check was always
# `./solve --cpu-freq`, which is what the project's own launcher calls.
#
# WIDENED 2026-08-21 (Unit B, Q29-G) from the original `scripts/…`-only leg to the
# path conventions the corpus actually uses, prefix-scoped and GENERATIVE:
#   (a) any token under a CURRENT top-level tracked directory — computed from
#       `git ls-tree` at runtime, never hardcoded, so new directories are covered
#       automatically (this subsumes the original `scripts/` leg);
#   (b) `roae-private/…`-qualified pointers, checked against the private checkout;
#   (c) `roae/…` repo-name-prefixed tokens, checked after stripping the prefix.
# Measured on the 2026-08-21 tree: 175 tokens matched; the widening would have
# caught 8 of that day's 14 fix-sites plus the FLAG-1 dangle mechanically, with
# zero false positives beyond one narration allowlist row (`roae/findings/`).
#
# SCOPE LIMITS — stated here so a PASS is never read as more coverage than it has:
#   * NOT all slash tokens. Of the 186 backticked slash-containing tokens measured
#     2026-08-21, at least 40 are legitimate non-paths (fractions, exact rationals,
#     macro families like PAIR_MASK_SET/CLR, git refs, GitHub slugs, figure
#     shorthand). A whole-class gate would be a standing false-positive generator —
#     worse than the retrospective enumeration it replaces. Do NOT widen it there.
#   * CANNOT see unprefixed strays: `x/roae/…` local-workspace prefixes, bare
#     `560t_scripts/…`, and `owner/repo:path` notation match no prefix rule —
#     5 of the 2026-08-21 fix-sites were of these shapes. That residue is bounded
#     by Unit B's one-time full 186-token classification
#     (roae-private/PRECODEX_UNITB_Q29G_PATHS.md §6) and by fresh-eyes review,
#     not by this gate.
#
# THREE FAILURE SHAPES, NOT ONE. A token that resolves in roae-private but not
# here is NOT the same defect as one that resolves nowhere:
#   * DANGLE        — points at nothing. Fix the text.
#   * COLLISION     — the prefix IS a real published directory (e.g. `scripts/`),
#     so the reader follows the path into a directory that exists and lacks the
#     file. The fix is the `roae-private/` prefix, which HISTORY.md already used
#     correctly 69 times when the gate was born. Two such collisions were live on
#     2026-08-09.
#   * STALE-PRIVATE — a correctly `roae-private/`-qualified pointer whose target
#     moved INSIDE roae-private (the 2026 reorganizations into campaigns/,
#     results/, validation/). The fix recipe differs from DANGLE: find the moved
#     file and update the pointer — do not rewrite the prose.
# The private-checkout legs (COLLISION, STALE-PRIVATE) need the private repo, so
# they are SKIPPED-WITH-NOTICE when absent: a fresh clone or third-party
# replicator still gets the dangle leg, and is told plainly which legs did not
# run rather than shown a bare green.
# WHERE THE PRIVATE CHECKOUT IS (Q-861, 2026-09-27). Until then this function
# hardcoded the operator's absolute checkout path, a private path in a public
# script. It now comes ONLY from the environment, with no default:
#   ROAE_PRIVATE_DIR=<dir>   the private checkout the two legs resolve against.
# Unset, empty, or not a directory: the two legs are SKIPPED and the gate prints
# the whole line DOC_GATE_SCRIPT_PATHS_PRIVATE=SKIP:<reason>, <reason> one of
# ROAE_PRIVATE_DIR-unset | ROAE_PRIVATE_DIR-not-a-directory. When they run it
# prints DOC_GATE_SCRIPT_PATHS_PRIVATE=RAN. The token says which legs RAN; the
# exit code alone cannot, since a skipped leg finds nothing to fail on.
#
# ALLOWLIST = NARRATION, and every row must say why. Most rows are CORRECT prose
# describing files deliberately removed (the 2026-04-21 consolidation into
# solve.py) or a retraction naming a phantom in order to withdraw it. Banning
# those would forbid the corpus from describing its own history — the same
# mistake as banning inline mention of a retracted phrase. One row (Q28-A2) is
# TEMPORARY and loudly says so: a green does not bless that pointer.
gate_script_paths() {
  echo "== GATE 21: backticked repo paths (top-level dirs, roae-private/, roae/) resolve, or are declared narration =="
  local rc=0 t priv="${ROAE_PRIVATE_DIR:-}" privrun=0 privwhy=""
  if [ -z "$priv" ]; then privwhy="ROAE_PRIVATE_DIR-unset"
  elif [ ! -d "$priv" ]; then privwhy="ROAE_PRIVATE_DIR-not-a-directory"
  else privrun=1; fi
  # (token, why-it-is-narration) — extend ONLY with a reason.
  # 🔴 Q-966 (A07#6): a row is bound to the DOCUMENTS that narrate the path, not to the token. Keyed on
  # the token alone, "Run `scripts/d128_preflight_throttle_probe.sh` before every bench." in README.md
  # passed on the strength of LARGE_SCALE_CAMPAIGNS.md's retraction. `at` lists the files a row waives
  # (measured 2026-10-03; case patterns); the two append-only ledgers, CORRECTIONS.md and HISTORY.md,
  # are in every row because quoting a withdrawn path verbatim is what they are for.
  allow() { local at=() _p; _why=""; case "$1" in   # $1 token, $2 the file citing it; sets _why
    reviewer/MANIFEST.sha256|reviewer/PACKAGE_VERSION)
      at=(reviewer/README.md)
      _why="written into the reviewer bundle by reviewer/make_package.sh at release time and untracked by design; reviewer/README.md describes them for the unpacked package (2026-10-03, CX-284)";;
    scripts/compute_stats.py|scripts/p2_marginals.py|scripts/p2_bivariate.py|scripts/p2_joint_density.py)
      at=(CLAUDE.md documentation/DISTRIBUTIONAL_ANALYSIS.md)
      _why="narrating the 2026-04-21 consolidation into solve.py (file deliberately removed)";;
    scripts/d128_preflight_throttle_probe.sh)
      at=(documentation/LARGE_SCALE_CAMPAIGNS.md)
      _why="retraction text naming the phantom in order to withdraw it (2026-08-09)";;
    scripts/atlas_queries.py)
      at=(documentation/QUERY_INVENTORY.md)
      _why="QUERY_INVENTORY.md narrating a planned path that was never created: the atlas consumer landed inside solve.py (git grep -n \"def atlas_queries\" -- solve.py), and the file names the wrong path in order to correct it. Same shape as the d128 row above -- a correction that cannot name its own subject is unreadable";;
    example/report.pdf)
      _why="CORRECTIONS.md's 2026-09-04 withdrawal entry naming the artifact it withdraws; the ledger is append-only so the text cannot be rewritten, and a withdrawal that could not name its own subject would be unreadable";;
    tr12/q9_negatives.md)
      at=(reports/TR12_QUERY_PROGRAM.md)
      _why="a deliverable that was specified and NEVER created, now named only by the two texts that WITHDRAW it: CX-73 in CORRECTIONS.md (append-only, so the wording cannot be rewritten) and TR-12 v1.9's revision-history row recording that same correction. Same shape as the d128 and example/report.pdf rows above -- a correction that cannot name its own subject is unreadable. The two LIVE pointers that once sent a reader here (QUERY_INVENTORY.md rows Q9 and LS-forced8) were repointed to \$OUT/q9_negatives.md on 2026-09-23, so nothing remaining is an instruction to open this path";;
    tr12/*)
      at=('*')   # (batch 40) any file: the binding is the moved file's existence below, not a document list (CX-233; TestTr12TablesMovedUnderReports)
      # CX-233 (2026-09-29): the TR-12 tables moved from a top-level tr12/ to reports/tr12/. A
      # tr12/ name is the files' location before that day, kept verbatim by the append-only
      # ledgers and the banked evidence; it is narration only while the same file is tracked
      # under reports/tr12/ (live docs are held to the new prefix by tr12_output_paths_gate.sh).
      if git ls-files --error-unmatch "reports/$1" >/dev/null 2>&1; then
        _why="historical location of reports/$1 before CX-233 (2026-09-29)"
      else _why=""; fi;;
    roae-private/FILE)
      # Q-919 (2026-10-02): a PLACEHOLDER, not a pointer. CORRECTIONS.md CX-203 (~:20165,
      # landed 5ad06afa) lists "Five repo-relative `roae-private/FILE` pointers" -- FILE stands
      # for "some file", naming the SHAPE of the five pointers it corrects. The ledger is
      # append-only, so the text cannot be rewritten. Exact token only: a real
      # `roae-private/<x>` pointer is still held to the STALE-PRIVATE leg.
      _why="placeholder naming the shape of a corrected pointer (CORRECTIONS.md CX-203, append-only), not a path";;
    roae/findings/)
      _why="dated HISTORY narration of the pre-2026-06 findings/ layout (consolidation recorded at HISTORY.md ~:4875)";;
    runs/20260420_singlebranch1T_d32westus3/)
      at=(runs/20260422_passA_10T_d64_laggard/README.md)
      _why="TEMPORARY: known defect Q28-A2, operator-gated publish/boundary decision — REMOVE THIS ROW when Q28 lands; a green here does NOT bless the pointer";;
    *) _why="";; esac
    [ -n "$_why" ] || return 0
    for _p in "${at[@]}" documentation/CORRECTIONS.md documentation/HISTORY.md; do
      case "$2" in $_p) return 0;; esac
    done
    _why=""; }
  local seen=0 dang=0 coll=0 stale=0
  local topdirs; topdirs=$(git ls-tree -d --name-only HEAD | paste -sd'|')
  local pairs f; pairs=$(git grep -oE "\`(roae-private|roae|$topdirs)/[A-Za-z0-9_./-]+\`" -- '*.md' 2>/dev/null | tr -d '`' | sort -u)
  seen=$(printf '%s\n' "$pairs" | sed -n 's/^[^:]*://p' | sort -u | grep -c .)
  while read -r t; do
    [ -n "$t" ] || continue
    f=${t%%:*}; t=${t#*:}     # Q-966: (file, token) pairs, so an allowance binds to its documents
    case "$t" in
      roae-private/*)  # private-qualified pointer: must exist in the private checkout
        if [ "$privrun" = 1 ]; then [ -e "$priv/${t#roae-private/}" ] && continue
        else continue; fi ;;  # covered by the skip-with-notice line below
      roae/*)          # repo-name-prefixed: resolve after stripping the prefix
        git ls-files --error-unmatch "${t#roae/}" >/dev/null 2>&1 && continue ;;
      *)               # top-level-dir tokens (includes the original scripts/ leg)
        git ls-files --error-unmatch "$t" >/dev/null 2>&1 && continue ;;
    esac
    allow "$t" "$f"
    if [ -n "$_why" ]; then continue; fi
    case "$t" in
      roae-private/*)
        echo "  [FAIL] STALE-PRIVATE: \`$t\` ($f) is correctly qualified but its target is absent from"
        echo "         the roae-private checkout — past instances were reorganizations into"
        echo "         campaigns/, results/, validation/. Find the moved file and update the"
        echo "         pointer; do not rewrite the prose."
        stale=$((stale+1)); rc=1 ;;
      *)
        if [ "$privrun" = 1 ] && [ -e "$priv/$t" ]; then
          echo "  [FAIL] COLLISION: \`$t\` ($f) resolves in roae-private but NOT here."
          echo "         Its prefix is a real published directory, so a reader follows this into"
          echo "         a directory that exists and lacks the file. Prefix it: \`roae-private/$t\`."
          coll=$((coll+1)); rc=1
        else
          echo "  [FAIL] DANGLE: \`$t\` ($f) resolves nowhere — not tracked here, not in roae-private."
          echo "         Fix the text, or add an allowlist row SAYING WHY it is narration."
          dang=$((dang+1)); rc=1
        fi ;;
    esac
  done <<<"$pairs"
  if [ "$privrun" = 1 ]; then
    echo "DOC_GATE_SCRIPT_PATHS_PRIVATE=RAN"
  else
    echo "  [SKIP] private checkout not available ($privwhy): the COLLISION leg and the roae-private/"
    echo "         pointer leg did NOT run. Dangle leg did. Set ROAE_PRIVATE_DIR to run them."
    echo "DOC_GATE_SCRIPT_PATHS_PRIVATE=SKIP:$privwhy"
  fi
  if [ "$rc" -eq 0 ]; then
    echo "  [ok] $seen distinct prefixed path token(s); all resolve or are declared narration"
    echo "       (scope: prefix-matched tokens only — NOT all slash tokens, and unprefixed strays"
    echo "        like \`x/roae/…\`, bare \`560t_scripts/…\` or repo:path notation are invisible here)"
  fi
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 22 — an ellipsis-truncated hex token must be a PREFIX of some 64-nibble
# hex string in the tree. The universe is every 64-nibble hex string the corpus
# contains, not "every real sha": a truncated citation of a documented NON-sha
# that is itself published at full length resolves clean.
#
# THE LIVE DEFECT. Two paper-citable documents cited the d2 10T canonical as
# `a09280fbf…` against a registry value of
# a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2 — the NINTH
# nibble is wrong (f, not 8). A reviewer who greps the published prefix gets
# nothing back and cannot tell a typo from a withdrawn anchor. That instance is
# already fixed (BOUNDARY_MINIMUM.md:29 now reads `a09280fb8…`); this gate is
# what stops the class returning.
#
# TWO LEGS, and the second exists BECAUSE the first has an allowlist.
#   LEG A — NEAR MISS, ALLOWLIST-PROOF. A non-resolving token that agrees with
#     some 64-nibble string in the tree on its first NEAR_MIN nibbles is a
#     mistyped anchor, not a narrative identifier, and no allowlist row waives it. This
#     is exactly the `a09280fbf…` shape (agreement 8).
#   LEG B — RESOLVABILITY. Every remaining token must be a prefix of some
#     64-nibble string in the tree, or carry a row saying why it cannot expand.
#
# THE THRESHOLD IS MEASURED, NOT PICKED. Over the whole tracked corpus on
# 2026-08-09: of the 33 tokens that do not resolve, the LARGEST agreement with
# any 64-nibble string in the tree is 2 nibbles. The defect's was 8. NEAR_MIN=7
# sits in that gap with clearance on both sides — it is not tuned to today's tree, and
# LEG A therefore fires today on nothing and would have fired on the defect.
#
# THE ALLOWLIST IS 33 ROWS, NOT 3 — stated rather than left to read as
# oversight. The brief for this gate expected three (the run identifiers
# HISTORY.md itself declares at 2269-2272). Measured, the corpus carries 33
# truncated hex tokens with no expansion anywhere: 24 are the sha256 of a build
# artifact, an intermediate run or a --selftest output that was never published
# in full, 6 are not sha256 at all, and 3 are the declared run identifiers.
# Each class carries its own reason below; none is exempted silently.
#
# WHAT LEG B COSTS, said plainly because it is a standing tax and not a one-off:
# it fails EVERY future truncated hex citation whose full value is not in the
# tree, so a new run narrative must either publish the 64 nibbles or add a row.
# That friction is LEG B's whole purpose, and it is also how a gate gets
# silenced by reflex — which is why the instance that occurred, and any mistyped
# nibble at position 8 or later, is carried by LEG A, where adding a row does
# nothing. A typo EARLIER than nibble 8 leaves agreement below NEAR_MIN and falls
# to LEG B, where a row does waive it (measured: `a09280fbf` NEAR at 8,
# `a09280fc` NEAR at 7, `a0928cfb8` DANGLE at 5, `b09280fb8` DANGLE at 1).
#
# SCOPE — three limits.
#   * TOKEN LENGTH 7-63, not the 7-16 originally specified. HISTORY.md:4804 and
#     :4806 cite `0c0fe37cf449cbc6e275...` at 20 nibbles, and a 16-cap would
#     have skipped both without saying so. 64 is excluded: that is a full-length
#     string, not a prefix of one.
#   * THE UNIVERSE IS HEAD, plus tracked files that DIFFER from HEAD. HEAD alone
#     is the reader-facing question ("can someone who clones expand this?"), but
#     HEAD alone would false-fail an uncommitted edit that introduces a sha and
#     its own truncated citation together. At pre-push the tree is a clean temp
#     worktree, so the union collapses back to HEAD and the strict reading is
#     what actually blocks the publish.
#   * BINARY CONTENT IS NOT SCANNED for the universe (`git grep -I`). Four .gz
#     DRAT certificates are tracked; a sha reachable only inside compressed
#     bytes is not one a reader could grep for either.
gate_hex_prefix() {
  echo "== GATE 22: ellipsis-truncated hex tokens are prefixes of a 64-nibble string in the tree =="
  local rc=0 NEAR_MIN=7
  # (token, why-it-cannot-expand) — extend ONLY with a reason. LEG A ignores this list.
  # NAMED hex_allow, not allow: bash function definitions are GLOBAL, and GATE 21
  # already defines an allow() inside gate_script_paths.
  hex_allow() { case "$1" in
    e31ef86a|c247b9f9|467025fe)
      echo "declared narrative run identifier — HISTORY.md:2299-2302 states no 64-hex expansion exists";;
    0004080c|00040a0c)
      echo "not a sha: the head of an elided 32-byte solution RECORD (HISTORY.md:2268-2269)";;
    325025987)
      echo "not hex: the tail of the decimal x23.325025987... (DESCRIPTION_LENGTH.md:74)";;
    d63bb25c)
      echo "not a sha256: an ext4 filesystem UUID (HISTORY.md:1907)";;
    43745021|5f9dcb7d)
      echo "not a sha256: the two ext4 filesystem UUIDs from the 2026-09-19 non-tty mkfs reproduction, quoted in CLAUDE.md §Disk-handling safety rule 1 to show a live ext4 was silently reformatted WITHOUT -F — same class as d63bb25c above";;
    5640d0cd)
      echo "a SUPERSEDED artifact digest, quoted in the very record that replaced it — CORRECTIONS.md CX-55 cites the pre-regeneration PNG sha to prove the post-cure change was the edit and not renderer drift, so by construction no 64-nibble expansion survives in the tree. Same shape as d63bb25c above: a real hex string that is not a live sha";;
    5450b53e)
      echo "not a sha256: the mathlib git revision pinned by lake-manifest.json (lean/README.md:652)";;
    df3d92ba)
      echo "not a real sha: the head of the elided trailing 56 characters of the HALLUCINATED phantom 11.2T value, which HISTORY.md:4804 states correspond to no artifact anywhere";;
    0d10944dda|10aa1f84|163a7660|188ce945|1ce20ff3|2954b271|2db60543|4ad70a0f|4ad70a0fb9|4f1cd8b3|76ada31e|86a74da5|8c35a854|95c2f8f0|98b8c0ef|9ab1cd08|b415c8ec|b82a2f48|daab1c48|e353086e|e5cfc6cd|f6b554ea|fc1e921e|fe98e58a)
      echo "sha256 of a build artifact / intermediate run / --selftest output, published only in truncated form";;
    *) echo "";; esac; }
  local d; d=$(mktemp -d) || { echo "  [FAIL] GATE 22: mktemp failed, so nothing was checked."; return 1; }
  # UNIVERSE. `[0-9a-f]+` is unbounded on a CHARACTER CLASS, then length-filtered in awk —
  # deliberately not `[0-9a-f]{64}`, so this file's own no-bounded-repetition rule holds.
  # 🔴 THIS FILE IS EXCLUDED FROM ITS OWN UNIVERSE — the verifier-closure invariant, closed once as
  # Codex N07 in 130479f8 and never merged to main, so it regressed here. doc_gates.sh embeds full
  # 64-nibble hashes in its own allowlist comments. Counting them means a token can "resolve" against
  # the checker's own narration: delete every independent expansion from the corpus and this gate
  # still reports OK. A verifier must be FALSE when its target is absent, and it cannot supply the
  # witness from its own text.
  # Q-887 (2026-10-01, minor sibling): the tracked-tree universe grep below ran `2>/dev/null` with no
  # rc check, so a git grep that FAILED (rc >= 2) contributed nothing and was indistinguishable from
  # a tree with no hashes. It now writes to a file, its rc is captured, and rc >= 2 is a FAIL naming
  # the producer (rc 1, no match, falls through to the zero-universe FAIL just below). The
  # working-tree leg is unchanged: a deleted-but-unstaged path legitimately makes its grep exit 2.
  # Q-968 (A07#8): HEX IS CASE-INSENSITIVE. Both producers and the token pattern read [0-9a-fA-F] and
  # every token is lower-cased before it is resolved, so an upper-case prefix such as "A09280FB0…" is
  # judged like its lower-case spelling; until Q-968 only [0-9a-f] was read, the upper-case run was not
  # a token at all, and only its short "0…" tail was seen (and dropped as < 7 nibbles).
  local g22urc=0; git grep -ohIE '[0-9a-fA-F]+' HEAD -- ':!scripts/doc_gates.sh' ':!scripts/doc_gates.d' 2>"$d/univ.err" > "$d/univ.head" || g22urc=$?
  if [ "$g22urc" -ge 2 ]; then echo "  [FAIL] GATE 22: the universe producer (git grep over HEAD) failed rc $g22urc, so the 64-nibble universe is UNMEASURED and nothing was checked: $(head -c 300 "$d/univ.err" | tr '\n' ' ')"; rm -rf "$d"; return 1; fi
  { cat "$d/univ.head"
    git diff -z --name-only HEAD 2>/dev/null | grep -zvE '^scripts/doc_gates(\.sh$|\.d/)' \
      | xargs -0 -r grep -ohIE '[0-9a-fA-F]+' 2>/dev/null
  } | awk 'length($0)==64' | tr 'A-F' 'a-f' | sort -u > "$d/univ"
  if [ ! -s "$d/univ" ]; then
    echo "  [FAIL] zero 64-nibble strings found in the tree. That is a broken scan, not a"
    echo "         clean corpus — every token would 'fail to resolve' and the report would be"
    echo "         noise. Re-anchor this gate, do not silence it."
    rm -rf "$d"; return 1
  fi
  # TOKENS, NOW WITH THEIR LINE CONTEXT. `-o` alone discards the line, and the NEAR leg needs it:
  # a mistyped anchor QUOTED INSIDE A CORRECTION ENTRY is the ledger doing exactly its job, while the
  # same token in ordinary prose is the defect. Only the line separates them. Four gates in this file
  # already carve out this case (3b, 26, 27, 29); GATE 22 was the fifth and had no mechanism, which
  # made a faithful CORRECTIONS.md entry literally unpublishable.
  # 🔴 THE EXEMPTION IS PER-TOKEN AND UNANIMOUS, NOT PER-LINE. A token is narration ONLY if EVERY
  # one of its occurrences sits in a marker; one loose occurrence in plain prose and it is PROSE
  # again and still fails. A per-line waiver would let a real typo hide behind one tidy citation.
  local g22rc=0 G22_FLOOR=100; git grep -nHE '[0-9a-fA-F]+(…|\.\.\.)' -- '*.md' 2>"$d/hits.err" > "$d/hits" || g22rc=$?; if [ "$g22rc" -ge 2 ]; then echo "  [FAIL] GATE 22: the token producer (git grep over tracked *.md) failed rc $g22rc, so the population is UNMEASURED and nothing was checked: $(head -c 300 "$d/hits.err" | tr '\n' ' ')"; rm -rf "$d"; return 1; fi  # Q-883 (2026-09-27): git grep rc 1 = no match (legitimate, and then the floor below fails it); rc >= 2 = the producer failed. This line read `2>/dev/null > hits || true` until Q-883, and a PATH git shim failing only this grep printed `[ok] 0 truncated hex token(s)` and DOC GATES: PASS (Fable E4).
  python3 - "$d/hits" "$d/tok" "$d/narr" <<'PYTOK'
import re, sys
hits, tokf, narrf = sys.argv[1], sys.argv[2], sys.argv[3]
TOK  = re.compile(r'[0-9a-fA-F]+(?:\u2026|\.\.\.)')
# Same marker vocabulary GATE 27 uses, plus the CORRECTIONS.md entry shape itself. \s+ not " ":
# a marker wrapping as "[CORRECTED\n2026-08-28" is the normal case in this corpus.
# Q-966 (A07#9): the markers are WHOLE WORDS and a NEGATED one is no marker, via the shared matcher
# (scripts/doc_gates.d/word_match.sh). As a bare substring, "Current digest (not a typo): a09280fb0..."
# declared its own mistyped prefix narration, and "unretracted" counted as "retract".
import subprocess as _sp
exec(_sp.run(["bash", "-c", ". scripts/doc_gates.d/word_match.sh && _wm_prelude"],
             capture_output=True, text=True, check=True).stdout)
MARK = wm_re(r'withdrawn|label\s+corrected|corrected\s+20\d\d|scoped\s+20\d\d|superseded|retract\w*'
             r'|\*\*before:\*\*|\*\*now:\*\*|typos?')
seen, prose = set(), set()
try:
    fh = open(hits, encoding='utf-8', errors='replace')
except OSError:
    fh = []
for line in fh:
    parts = line.split(':', 2)
    body = parts[2] if len(parts) == 3 else line
    narr = wm_has(body, MARK)
    for m in TOK.finditer(body):
        t = m.group(0).rstrip('\u2026').rstrip('.').lower()
        if 7 <= len(t) <= 63:
            seen.add(t)
            if not narr:
                prose.add(t)
open(tokf,  'w').write(''.join(t + '\n' for t in sorted(seen)))
open(narrf, 'w').write(''.join(t + '\n' for t in sorted(seen - prose)))
PYTOK
  awk -v near="$NEAR_MIN" '
    NR==FNR { U[++n]=$0; next }
    { t=$0; best=0; bu=""
      for (i=1;i<=n;i++) {
        u=U[i]
        if (substr(u,1,length(t))==t) { print "OK\t" t; next }
        L=0
        while (L<length(t) && substr(t,L+1,1)==substr(u,L+1,1)) L++
        if (L>best) { best=L; bu=u }
      }
      if (best>=near) printf "NEAR\t%s\t%s\t%d\n", t, bu, best
      else print "DANGLE\t" t
    }' "$d/univ" "$d/tok" > "$d/class"
  local seen=0 declared=0 kind t u n why
  while IFS=$'\t' read -r kind t u n; do
    [ -n "$kind" ] || continue
    seen=$((seen+1))
    case "$kind" in
      OK) ;;
      NEAR)
        # NARRATION WAIVER — narrow by construction, and NOT a filename allowlist (GATE 3b measured
        # that coarseness and rejected it). The token qualifies only if EVERY occurrence of it in the
        # corpus sits in a correction marker or revision row. A typo quoted by the ledger that
        # records the typo is the ledger working; the same token loose in prose still fails below.
        if grep -qxF "$t" "$d/narr" 2>/dev/null; then declared=$((declared+1)); continue; fi
        echo "  [FAIL] NEAR MISS: \`$t…\` is a prefix of NO 64-nibble string in the tree, but agrees with"
        echo "         $u for $n nibbles. That is a mistyped anchor, not a"
        echo "         narrative identifier: a reviewer's prefix grep returns nothing. Fix the"
        echo "         digits against the registry. Only a correction marker or revision row waives"
        echo "         this leg, and only when EVERY occurrence of the token carries one."
        rc=1;;
      DANGLE)
        why=$(hex_allow "$t")
        if [ -n "$why" ]; then declared=$((declared+1)); continue; fi
        echo "  [FAIL] UNRESOLVABLE: \`$t…\` is a prefix of no 64-nibble string in the tree."
        echo "         Publish the full sha somewhere a reader can reach, or add an allowlist"
        echo "         row SAYING WHY it cannot expand."
        rc=1;;
    esac
  done < "$d/class"
  rm -rf "$d"
  echo "GATE22_HEX_TOKENS=$seen"; if [ "$seen" -lt "$G22_FLOOR" ]; then echo "  [FAIL] GATE 22: only $seen truncated hex token(s) measured, below the population floor $G22_FLOOR. A lost, renamed or narrowed population is a broken scan, not a clean corpus."; rc=1; fi; [ "$rc" -eq 0 ] && echo "  [ok] $seen truncated hex token(s); all resolve or are declared ($declared declared)"  # Q-883 (2026-09-27): the receipt and the floor. Floor 100 against 129 measured on 2026-09-27 (37 declared): room to retire ~29 citations without an edit here, while a producer that returns nothing or a handful reads FAIL, not ok.
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 23 — no tracked file may also be ignored.
#
# A path that is BOTH tracked and matched by an ignore rule is a silent
# partial-publication hazard. The file already in the index keeps shipping, so
# nothing looks wrong; but the NEXT sibling added to that directory is skipped
# by `git add` without warning, and the omission surfaces only when a reader
# follows a link into a half-published directory. There is no legitimate use of
# this state in this repo, so the gate has NO allowlist: the fix is always to
# narrow the ignore rule or to untrack the file deliberately.
#
# THE COMMAND IS THE CHECK, so a command that does not run must not read as
# clean. `git ls-files -i` REQUIRES `-c` or `-o`; older git errors out instead
# of defaulting. Empty output plus a non-zero exit is indistinguishable from
# "nothing found" unless the exit status is inspected, so it is — a checker
# that finds nothing must never report [ok].
# ---------------------------------------------------------------------------
# GATE 79 — a documented memory-knob EXAMPLE must fit the box the sentence sizes.
#
# WHY THIS EXISTS (measured, Codex V2 `TR11:471`, fixed 2026-09-03). TR-11's commodity
# recipe read `raise SOLVE_F1_OOC_SCRATCH_MB (e.g. 61440 on a 64 GiB box)`. The solver's
# own documented model, stated in three places, is that TOTAL RSS is ~2.2x that value.
# 2.2 x 60 GiB = 132 GiB, on the 64 GiB box the same sentence sizes. Even the bare floor,
# scratch + staging, is 130 GiB before read windows. The recipe OOMs by its own
# documentation, and a resume repeats the OOM until someone edits the env var.
#
# Root cause was not a typo: 61440 is the PRODUCTION 256-GiB D128 setting from TR-11 section 8,
# copied into the commodity recipe. Both numbers are correct for their own host, which is
# exactly why prose review did not catch it -- the value is defensible in isolation and
# wrong only against the box named beside it. Nothing in the corpus compared the two.
#
# TWO LEGS, because one instance had two independent defects:
#   1. ARITHMETIC  -- 2.2 x N MiB must be <= the Y GiB the same phrase names.
#   2. CROSS-DOC   -- two documents giving an example for the SAME box size must agree.
#      TR-11 said 61440 where SOLVE_C_CLI.md said 16384 for the identical 64 GiB box, and
#      the disagreement itself was the tell. A reader following either document alone
#      cannot see it.
#
# SCANNER, NOT REGISTRY, and deliberately so: the pattern is narrow enough
# ("e.g. N on a Y GiB box") that a false positive would have to be prose that means
# precisely this and is wrong anyway. The RSS multiplier is pinned in one place below;
# if solve.c's staging model changes, this constant must move with it.
RSS_MULTIPLIER_TENTHS=22   # 2.2x, from SOLVE_C_CLI.md's env table and solve.c's block comment
gate_scratch_examples() {
  echo "== GATE 79: documented memory-knob examples fit the box they name =="
  local hits n bad=0 f ln val box need
  # A file: prefixed grep over TRACKED markdown only -- an untracked scratch note must not
  # gate a push, and an unreadable corpus must ERROR rather than report a clean bill.
  if ! hits=$(git ls-files '*.md' 2>/dev/null | xargs -r grep -noE "e\.g\.,? \*{0,2}[0-9]{3,6}\*{0,2} on a [0-9]+ ?GiB box" 2>/dev/null); then
    : # grep exits 1 when there are no matches; that is not an error here
  fi
  n=$(printf '%s' "$hits" | grep -c . || true)
  if [ "${n:-0}" -eq 0 ]; then
    echo "  [FAIL] zero sites matched the example pattern across tracked *.md."
    echo "         This gate has never legitimately measured zero -- the corpus carries at least"
    echo "         two such examples. Zero means the pattern or the file list broke, and a check"
    echo "         that cannot see its target must not report OK."
    return 1
  fi
  # LEG 1 -- arithmetic
  local -a boxes=() vals=() srcs=()
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    f=${h%%:*}; ln=$(printf '%s' "$h" | cut -d: -f2)
    # 🔴 STRIP THE file:line: PREFIX BEFORE EXTRACTING THE NUMBER. The first cut of this leg
    # ran the digit regex over the whole grep -n line, so it captured the LINE NUMBER as the
    # example value and reported "SOLVE_C_CLI.md:<N> says <N>" (N = the grep line number itself, 1779 in that run). Caught on the first real run
    # rather than by reading, which is the only reason it is not in the corpus now.
    local body; body=$(printf '%s' "$h" | cut -d: -f3-)
    val=$(printf '%s' "$body" | grep -oE "[0-9]{3,6}" | head -1)
    box=$(printf '%s' "$body" | grep -oE "on a [0-9]+ ?GiB" | grep -oE "[0-9]+")
    [ -n "$val" ] && [ -n "$box" ] || continue
    need=$(( val * RSS_MULTIPLIER_TENTHS / 10 ))          # MiB of RSS the model predicts
    if [ "$need" -gt $(( box * 1024 )) ]; then
      echo "  [FAIL] $f:$ln — example $val MiB on a $box GiB box needs ~$(( need / 1024 )) GiB RSS"
      echo "         at the documented ${RSS_MULTIPLIER_TENTHS}/10x multiplier. The recipe OOMs by its own model."
      bad=1
    fi
    boxes+=("$box"); vals+=("$val"); srcs+=("$f:$ln")
  done <<< "$hits"
  # LEG 2 -- cross-document agreement for the same box size
  local i j
  for (( i=0; i<${#boxes[@]}; i++ )); do
    for (( j=i+1; j<${#boxes[@]}; j++ )); do
      if [ "${boxes[$i]}" = "${boxes[$j]}" ] && [ "${vals[$i]}" != "${vals[$j]}" ]; then
        echo "  [FAIL] two documents disagree for the same ${boxes[$i]} GiB box:"
        echo "         ${srcs[$i]} says ${vals[$i]}; ${srcs[$j]} says ${vals[$j]}."
        echo "         A reader following either alone cannot see the disagreement."
        bad=1
      fi
    done
  done
  [ "$bad" -ne 0 ] && return 1
  echo "  [ok] $n documented example(s) fit their named box at ${RSS_MULTIPLIER_TENTHS}/10x RSS, and agree across documents"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 86 — a published pre-registration must have its digest on the escrow page
# (`prereg-escrow`).
#
# 🔴 WHY. documentation/PREREGISTRATION_ESCROW.md publishes the sha256 of frozen pre-registration
# files so that, if one is ever disclosed, a reader can hash it and check it. The failure this closes
# is a file being disclosed WITHOUT that happening — shipped in the public tree while the page says
# nothing about its actual content.
#
# It is not hypothetical. reports/evidence/f11halfb/PREREGISTRATION_EXTENDED.md has been public since
# 2026-08-04, EIGHTEEN DAYS BEFORE the escrow page was published, and it does NOT verify against its
# escrowed row: 3,986 bytes hashing to 1dedbda1… against the escrowed 3,965 / 09d711c3…. That is
# legitimate — the two copies are the same 81-line document differing in exactly one line, where a
# name identifying operator-held infrastructure was replaced before publication, and the escrowed
# digest is of the unredacted private original. It is legitimate BECAUSE the page says so. Nothing
# made it say so, and nothing would have noticed had it not.
#
# THE RULE, and it is decidable rather than a judgement: every tracked public pre-registration file's
# sha256 must appear somewhere on the escrow page. Two ways satisfy it, which is the point —
#   * it equals an escrowed table row: published unredacted, and it verifies; or
#   * the page publishes the file's TRUE digest in its disclosure prose: published redacted or
#     outside the table, with the reader told exactly what they can and cannot check.
# Both are honest. What fails is a public pre-registration whose real digest appears nowhere, which
# is the only case where a reader hashing the file learns nothing.
#
# Measured at the time of writing: four tracked public pre-registrations, all four covered — two
# verifying against rows (VMATCHED 37ee9eee…, H1_H3 ab09648c…) and two disclosed with their true
# digests (EXTENDED 1dedbda1…, f11/PREREGISTRATION 51b78890…).
#
# This is leg (c) of the three the adjudication specified, the one recorded as having teeth. Leg (a)
# (freeze-timing conversions must state a date direction) and leg (b) (the page must not claim a
# complete population) were both fixed in PROSE on 2026-09-02 and the six files leg (b) named were
# escrowed on 2026-09-04, so their red tests no longer reproduce; only this leg needed enforcement.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# GATE 87 — the TR-12 figure generator's shape guards are shown able to FAIL
# (`viz-shape`).
#
# WHY. Q-307 (D6 review 2026-08-27, VIZ_PROGRAM_DESIGN_REVIEW_2026_08_27.md sec.6): the V1..V5
# generators read their TSVs with `dict(zip(header, fields))` and did no shape check at all, so a
# TRUNCATED v1_field.tsv rendered a perfectly plausible heat map over a smaller grid -- no error, no
# clue, and an output that LOOKS like evidence. viz/report_figures.py now refuses an incomplete,
# duplicated, torn or column-short table and stamps each TR-12 figure with the sha256 of the TSV it
# came from.
#
# WHY A GATE AND NOT A ONE-OFF CHECK. A shape assertion that has never been shown to refuse anything
# is indistinguishable from no assertion, and the guards live in a file no test imports (matplotlib
# and numpy are external and are not dependencies of roae.py or solve.c, so tests.py cannot reach
# them). The generator therefore carries its own `--selftest`: eight synthetic-table arms, four
# provenance arms and two constant-observable arms, each asserting a VERDICT rather than an output
# shape. MUTATION-TESTED before landing: defanging the completeness test, the field-count test and
# the constant-observable rule each turned the selftest RED.
#
# The absent-matplotlib arm SKIPS rather than passing quietly, and says so on its own line: viz/ is
# an optional surface and a reviewer without matplotlib is not a defect, but a silent green would be.
gate_viz_shape() {
  echo "== GATE 87: viz/report_figures.py's TSV shape guards are shown able to fail =="
  local G=viz/report_figures.py
  require_tracked "$G" "The TR-12 figure generator IS this gate; with it gone, nothing is checked."
  case $? in 1) return 0;; 2) return 1;; esac
  if ! python3 -c 'import matplotlib, numpy' >/dev/null 2>&1; then
    echo "  [skip] matplotlib/numpy absent — viz/ is an optional external surface, not part of the"
    echo "         core toolchain. NOTHING was checked here; this is a skip, not a pass."
    return 0
  fi
  local out rc
  out=$(python3 "$G" --selftest 2>&1); rc=$?
  # Q-952: rc 0 AND exactly one VIZ_SHAPE_SELFTEST= line AND it is PASS (require_pass_token, doc_gates.sh).
  if ! require_pass_token VIZ_SHAPE_SELFTEST PASS "$out" "$rc"; then
    printf '%s\n' "$out" | sed 's/^/     /'
    echo "  [FAIL] $G --selftest did not give a clean VIZ_SHAPE_SELFTEST=PASS (rc $rc)"
    return 1
  fi
  echo "  [ok]   $G --selftest: $(printf '%s\n' "$out" | grep -c '^  \[ok\]') arm(s) green, VIZ_SHAPE_SELFTEST=PASS"
  return 0
}

# GATE 88 — the approved-separates census: `git ls-files '*.py' '*.c'` may not exceed the list
# CLAUDE.md enumerates, AND the counts CLAUDE.md states about that list must be true.
#
# 🔴 WHY BOTH LEGS. The standing rule is that all C lives in solve.c and all Python in solve.py,
# "except for the approved separates enumerated below", and adding a file outside that list is an
# operator decision. Nothing enforced it. Codex raised this as V2-F56 #3.
#
# 🔴 THE ROW SAT BLOCKED ON A COST THAT BELONGED TO A DIFFERENT ROW. Its blocker cell read
# "hours-scale many-core Spot run, NOT approved by this note" -- character-for-character the blocker
# of backlog row 102, the wrap-mass reseed, a genuine 2x10^10-probe estimator job. A `git ls-files`
# set-containment test cannot share a cost profile with that, and the adjudication that raised the
# charge said "Zero compute." in its own remediation column. Measured on this orchestrator: 0.09 s
# wall, 0.05 core-seconds, 5.5 MB peak -- about one eighteenth of an average gate here, and 0.07% of
# a full run. A cost inherited from the wrong instrument is this project's recorded failure; this one
# was inherited from the wrong ROW.
#
# LEG 2 exists because LEG 1 cannot catch what actually rotted. Subset-containment tests the GLOB,
# and on 2026-09-04 the glob was right while the human count beside it was stale by one file and one
# whole directory -- CLAUDE.md said "11 files under f1/, f5/, f11/, r11/" when the tree held 12 across
# five directories. Leg 1 passed then and would pass now. So leg 2 asserts the STATED count and the
# STATED directory list against the filesystem, which is the only part a reader actually relies on.
gate_separates_census() {
  echo "== GATE 88: approved-separates census (CLAUDE.md vs git ls-files) =="
  local rc=0 md=CLAUDE.md
  [ -r "$md" ] || { echo "  [FAIL] $md unreadable"; return 1; }

  # LEG 1 -- containment. Every tracked .py/.c must be named by the list, either literally or by the
  # one glob the list sanctions (reports/evidence/**/*.py).
  local census; census=$(git ls-files '*.py' '*.c' 2>/dev/null)
  local n; n=$(printf '%s\n' "$census" | grep -c .)
  # 🔴 VERIFIER-CLOSURE GUARD. An empty census would make every containment test vacuously true, so
  # a gate that could not see the tree would report the tree conformant. Absence of files is not
  # evidence of conformance; it is evidence the measurement failed.
  if [ "${n:-0}" -lt 10 ]; then
    echo "  [FAIL] census floor: git ls-files returned $n source file(s) — refusing to pass vacuously"
    return 1
  fi
  # 🔴 Q-966 (A07#12): "named by the list" means named IN THE LIST, as an approved entry. This read
  # `grep -qF` over all of CLAUDE.md, so "Do not approve `q835_unapproved.py`." anywhere in the file
  # approved it. The list is the run of bullets right after the "**The approved separates" paragraph,
  # up to the first blank line; an entry is a backticked name inside a **bold** span of it (each
  # bullet leads with its approved names in bold). Matched as exact names, not substrings.
  local approved; approved=$(python3 - "$md" <<'PYSEP'
import re, sys
L = open(sys.argv[1], encoding="utf-8", errors="replace").read().split("\n")
h = [i for i, l in enumerate(L) if "**The approved separates" in l]
if len(h) != 1:
    print("ERROR\t'**The approved separates' found %d time(s) (need exactly 1)" % len(h)); sys.exit(0)
i = h[0]
while i < len(L) and not L[i].startswith("- "): i += 1
j = i
while j < len(L) and L[j].strip(): j += 1
names = set()
for b in re.findall(r"\*\*(.+?)\*\*", " ".join(L[i:j]), re.S):
    names.update(re.findall(r"`([^`\s]+)`", b))
if not names:
    print("ERROR\tthe approved-separates list under line %d parsed to zero names" % (h[0] + 1)); sys.exit(0)
for n in sorted(names): print("NAME\t" + n)
for n in sorted(set(re.findall(r"`([^`\s]+)`", " ".join(L[i:j])))): print("TOK\t" + n)
PYSEP
)
  if ! grep -q $'^NAME\t' <<<"$approved" || grep -q $'^ERROR\t' <<<"$approved"; then
    echo "  [FAIL] could not read the approved-separates list out of $md: $(sed -n 's/^ERROR\t//p' <<<"$approved")"
    return 1
  fi
  local f miss=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in reports/evidence/*/*.py) continue;; esac      # the sanctioned glob
    if ! grep -qxF -- "$(printf 'NAME\t%s' "$f")" <<<"$approved"; then
      echo "  [FAIL] tracked source '$f' is NOT named in $md's approved-separates list"
      echo "         Adding a .py/.c outside that list is an operator decision, not an implementation detail."
      miss=$((miss+1))
    fi
  done <<EOF
$census
EOF
  [ "$miss" -eq 0 ] && echo "  [ok] all $n tracked .py/.c named by the list (or under the sanctioned reports/evidence glob)"
  [ "$miss" -gt 0 ] && rc=1

  # LEG 2 -- the stated numbers. CLAUDE.md asserts a COUNT and a DIRECTORY LIST for the glob.
  local ev_n ev_dirs stated_n
  ev_n=$(git ls-files 'reports/evidence/**/*.py' 2>/dev/null | grep -c .)
  ev_dirs=$(git ls-files 'reports/evidence/**/*.py' 2>/dev/null \
            | sed 's#reports/evidence/\([^/]*\)/.*#\1#' | sort -u)
  # The bullet reads: - **`reports/evidence/**/*.py`** (**N** files under `a/`, `b/` ... )
  stated_n=$(grep -oE '\*\*`reports/evidence/\*\*/\*\.py`\*\* \(\*\*[0-9]+\*\*' "$md" \
             | grep -oE '[0-9]+' | head -1)
  if [ -z "$stated_n" ]; then
    echo "  [FAIL] could not find the stated evidence-file COUNT in $md — the bullet's shape changed"
    rc=1
  elif [ "$stated_n" != "$ev_n" ]; then
    echo "  [FAIL] $md states $stated_n evidence .py file(s); the tree has $ev_n"
    rc=1
  else
    echo "  [ok] stated evidence count $stated_n matches the tree"
  fi
  local d
  for d in $ev_dirs; do
    if ! grep -qxF -- "$(printf 'TOK\t%s/' "$d")" <<<"$approved"; then   # Q-966: in the list, not anywhere
      echo "  [FAIL] evidence directory '$d/' holds tracked .py but is NOT named in $md's bullet"
      echo "         This is the half that rotted on 2026-09-04: the glob was right, the prose was not."
      rc=1
    fi
  done
  [ "$rc" -eq 0 ] && echo "  [ok] every evidence directory holding tracked .py is named in $md"
  return $rc
}

gate_prereg_escrow() {
  echo "== GATE 86: every published pre-registration's digest is on the escrow page =="
  python3 - <<'PREREGPY' || return 1
import hashlib, subprocess, sys, re
PAGE = 'documentation/PREREGISTRATION_ESCROW.md'
try:
    page = open(PAGE, encoding='utf-8', errors='surrogateescape').read()
except OSError as e:
    print("  [FAIL] cannot read %s (%s) — NOTHING was checked." % (PAGE, e.strerror))
    print("     An unreadable escrow page is not an escrow page with nothing to hide.")
    sys.exit(1)
# TABLE-ROW digests and PROSE digests are different facts and must not be conflated: a file that
# VERIFIES against its escrowed row and one that is DISCLOSED as not verifying are opposite
# outcomes, and the escrow page marks them with a check and a cross. An earlier draft of this gate
# labelled every covered file "verifies against a row" because it matched against every 64-hex
# string on the page, which would have printed the exact opposite of what the page says about
# PREREGISTRATION_EXTENDED.md. Rows are parsed from the table only.
rows = set()
for _ln in page.split(chr(10)):
    if _ln.startswith('|'):
        rows.update(re.findall(r'\b[0-9a-f]{64}\b', _ln))
allhex = re.findall(r'\b[0-9a-f]{64}\b', page)
if len(rows) < 5 or len(allhex) < 5:
    print("  [FAIL] only %d table-row and %d total sha256 value(s) on the escrow page."
          % (len(rows), len(allhex)))
    print("     That means the page was gutted or the matcher stopped matching; either way this")
    print("     gate is measuring nothing and must not report OK.")
    sys.exit(1)
try:
    tracked = subprocess.run(['git','ls-files'], capture_output=True, text=True,
                             check=True).stdout.split('\n')
except Exception as e:
    print("  [FAIL] could not enumerate tracked files (%s) — NOTHING was checked." % e)
    sys.exit(1)
cands = [f for f in tracked
         if f and re.search(r'(^|/)PREREG', f, re.I) and not f.endswith('PREREGISTRATION_ESCROW.md')]
if not cands:
    print("  [FAIL] found ZERO tracked pre-registration files.")
    print("     The repository ships several; a zero here is a broken matcher, not a clean tree.")
    sys.exit(1)
bad = 0
for f in sorted(cands):
    try:
        d = hashlib.sha256(open(f,'rb').read()).hexdigest()
    except OSError as e:
        print("  [FAIL] %s is tracked but unreadable (%s)" % (f, e.strerror)); bad += 1; continue
    if d in page:
        kind = "VERIFIES against its escrowed row" if d in rows else "disclosed in prose (does not verify — by design)"
        print("  [ok]   %s  %s… %s" % (f, d[:12], kind))
    else:
        print("  [FAIL] %s hashes to %s and that digest appears NOWHERE on the escrow page." % (f, d))
        print("     A published pre-registration whose real digest is unpublished is one a reader")
        print("     can hash and learn nothing from. Either it must verify against its escrowed row,")
        print("     or the page must publish this digest and say why it differs.")
        bad += 1
if bad:
    print("  [FAIL] %d published pre-registration(s) undisclosed" % bad); sys.exit(1)
print("  [ok]   %d published pre-registration(s), every digest accounted for on the escrow page" % len(cands))
PREREGPY
}

# ---------------------------------------------------------------------------
# GATE 89 — every JSON key solve.c or solve.py EMITS, and every whole-line KEY=value verdict
# token solve.c or scripts/*.sh EMITS, must be named in documentation/ (`emitted-surface`).
#
# 🔴 WHY. Until this gate the code→doc PRESENCE family was exactly four checks and every one of them
# looks at an INPUT surface: GATE 2 (`cli`) the flag names plus a Usage-grammar leg, GATE 2c
# (`citation-lines`) the solve.c line citations, GATE 24 (`value-domains`) an explicitly DECLARED
# value registry, and GATE 84 (`env-surface`) the `getenv("SOLVE_*")` names. Nothing looked at what
# the program PRINTS. GATE 84's own header frames flags-vs-getenv as "the code's surface", which it
# is not: a reader consumes OUTPUT, and an emitted name no document defines is one they can only
# guess at.
#
# THE LIVE INSTANCE. The atlas `gates` JSON object shipped four keys that were REFERENCED in seven
# places across documentation/ and DEFINED in none. It went unnoticed until a person read the JSON;
# no gate in this ~19,000-line suite could see it, and the object has since been widened to seven
# keys. `grep -ni 'json key|json field|emitted key|output key|json output'` over this file returns
# zero. Prior art, checked before building: one UNBUILT proposal in the private adjudication record
# for a much narrower SEMANTIC check on a single field (`solutions_bin_bytes`), which would not have
# caught this; nothing in the backlog asks for the keys to be documented. Filed NEW, not KNOWN.
#
# MEASURED AT LANDING (2026-09-08, live working tree):
#   LEG 1  362 distinct JSON keys emitted by solve.c; 160 appear in NO documentation/ file.
#   LEG 2  120 distinct whole-line KEY=value verdict tokens (71 from scripts/*.sh, 49 from
#          solve.c); 70 appear in NO documentation/ file. (The 6 tokens this gate itself emits are
#          in that 120 and are documented, in documentation/DEVELOPMENT.md, by this same change.)
# Those 230 are a CENSUS, not a short holding set, and they are carried in
# documentation/DOC_GATE_EMITTED_SURFACE_OPEN.tsv as adjudicated-open rows that print [OPEN] and do
# NOT set the exit code. THE GATE IS THEREFORE HARD FOR *NEW* SURFACE ONLY — the GATE 18 / GATE 59
# carve-out shape, and it must be read that way: a green verdict means no NEWLY undocumented key or
# token, never that none exist. An allowance row that matches nothing FAILS, so a row cannot outlive
# its fix and the table cannot be padded with names the code does not emit.
#
# WHAT THIS DOES NOT COVER — stated here so the green is never read as more than it is, which is the
# mistake GATE 84's header invited by calling flags+getenv the complete code surface:
#   * PRESENCE, NOT ACCURACY. The name must appear; the sentence beside it is not read. Same
#     limitation and same reason as GATE 84 — accuracy is not mechanically decidable in general.
#   * WEAK CLEARS ON SHORT AND COMMON NAMES. `count`, `status`, `min`, `name`, `k`, `t` clear on any
#     word-anchored occurrence anywhere in the corpus, so their green means very little. The clear is
#     STRONG only for distinctive names — which is the class the live defect belonged to
#     (`per_layer_flow_eq_N`, `class_column_sums_eq_b0_N`). A [note] lists the names whose ONLY
#     evidence is a bare prose occurrence with no identifier context (backtick span, fenced block or
#     quoted string) anywhere in documentation/ — the weakest clears the corpus contains.
#   * LEG 3 (solve.py) IS AN APPROXIMATION THAT DECLARES ITS OWN BLIND SPOTS. solve.py assembles
#     its payloads as dicts built across many statements, so a literal scrape would be partial and
#     SILENTLY so — worse than absent. LEG 3 is therefore an `ast` pass that resolves the expression
#     flowing into every `json.dump`/`json.dumps` call: dict literals, `**` unpacking, `.update()`,
#     `d["k"] = v`, dict comprehensions with a literal key, `dict(...)`, if-expressions, containers
#     and comprehensions, name binding within the scope chain, the return expressions of a function
#     defined in the same file, and ONE level of parameter back-resolution from that function's call
#     sites. It does NOT model attribute or element types, does not element-type an iterable, and
#     does not enter an imported callable. EVERY position it cannot resolve is RECORDED, counted in
#     DOC_GATE_EMITTED_SURFACE_PY_UNRESOLVED and printed as a [note] with its site — the one thing
#     the scope-out was protecting against was a pass that drops what it cannot see, so this pass
#     must never do that. The count is RATCHETED against CEIL_PY_UNRESOLVED: if solve.py grows a
#     payload this pass cannot see into, the gate FAILS rather than quietly measuring less.
#   * THE REVERSE DIRECTION IS NOT CHECKED (documented-but-never-emitted), for GATE 84's measured
#     reason: prose legitimately names historical and private-repo keys, so that direction reports
#     noise, and a gate whose findings are usually noise gets ignored, then removed.
#   * KEY-LIKE STRINGS THAT ARE NOT KEYS. LEG 1 matches the literal `\"name\":` inside a C string
#     literal; a non-JSON C string of that shape would be counted. None is evident today, but the
#     extractor does not PROVE their absence.
#   * FRAGMENT-GENERATING ECHO LINES ARE DROPPED. LEG 2 rejects an emitted line whose value contains
#     `;` or opens with a quote — those are the `echo 'WORK=$(mktemp -d); RAW=...'` shell fragments
#     the d5_* harnesses write into generated scripts, not verdicts. 10 lines over 7 names are
#     dropped today and the DROPPED count is printed, so the filter cannot drift silently; a real
#     verdict token written only in that shape would still be invisible here. SAME DROP, DECLARED
#     (Q-795, 2026-09-25): an emitting line that ENDS in the comment `# not-a-verdict` is a harness
#     assignment by its author's say-so (e.g. `echo "Q7WIT_DIR=$d"  # not-a-verdict` written into a
#     generated script) and is dropped and counted in DROPPED like a fragment. The marker is a claim,
#     not a proof: it would hide a real verdict too, so it belongs only on lines no consumer greps.
#   * ONLY `scripts/*.sh` AND solve.c EMIT. Tokens emitted by *.py helpers, by lean/, or by scripts
#     in nested directories are not extracted.
#
# CLOSURE — the gate must not take its witness from itself. The corpus is documentation/ ONLY, and
# every documentation/DOC_GATE_* file — this gate's own allowance table included — is EXCLUDED from
# it. scripts/ is never read as documentation, so an emitting script's own header comment
# ("# Emits SIDECAR_SHA_GATE=OK|FAIL. Gate with `grep -qx`") does NOT absolve its own token; that is
# exactly the shape of the three self-absolving gates found on 2026-09-08 (one named its worked
# example in its header, one double-counted its own filename, one was satisfied by the explanatory
# comment beside the code it guarded). TWO LIVE PROOFS RUN ON EVERY INVOCATION:
#   SELF-1 CANARY. A literal that occurs ONLY in this file must be ABSENT from the corpus. If anyone
#          ever points the corpus at scripts/, or copies this gate's text into a document, the canary
#          appears and the gate FAILS.
#   SELF-2 FALSIFIABILITY (Codex finding N07). The matcher is run against an EMPTY corpus and must
#          report every name undocumented, then against a corpus containing every name and must
#          report none. A matcher that cannot come out FALSE has not been built.
# FLOORS, set from the 2026-09-08 measurement: >= 300 JSON keys (measured 362), >= 95 verdict tokens
# (120), >= 45 corpus files (54), >= 2,000,000 corpus bytes (4,957,627). reconcile_kc_hashes.sh once
# reported success while matching 0 of 91 rows; measuring nothing is an ERROR here, never a PASS.
# VERDICT TOKENS (whole line, matched with `grep -qx`): DOC_GATE_EMITTED_SURFACE=OK|FAIL|ERROR, plus
# DOC_GATE_EMITTED_SURFACE_{JSON_KEYS,TOKENS,NEW,OPEN,DROPPED}=n and, for LEG 3,
# DOC_GATE_EMITTED_SURFACE_PY_{JSON_KEYS,NEW,OPEN,UNRESOLVED}=n — each is -1 when nothing was
# measured, the LEDGER_ROWS_WITHOUT_RULE=-1 convention. LEG 3 got its OWN counters rather than
# widening JSON_KEYS/NEW/OPEN: those are pinned numbers other lanes read, and a count that silently
# changes what it counts is the same class of defect as a key no document names. They are documented in
# documentation/DEVELOPMENT.md, which is where LEG 2 then looks for them.
# IN `all` since 2026-09-08. It was held out only while its allowance table was untracked — `all`
# runs in a detached worktree of the PUSHED sha at pre-push and this gate ERRORs without that file
# — and it was wired in once the table was committed; the call site in the `all` block carries the
# reasoning. Also runnable by name:
#   bash scripts/doc_gates.sh emitted-surface     # ~2.5 s
# ---------------------------------------------------------------------------
gate_emitted_surface() {
  echo "== GATE 89: emitted JSON keys and verdict tokens are documented =="
  local out
  out=$( { _sp_prelude; cat <<'ESPY'
import ast, io, os, re, glob, subprocess, sys

ALLOW = "documentation/DOC_GATE_EMITTED_SURFACE_OPEN.tsv"
DOCROOT = "documentation"
SRC = "solve.c"
# A literal that exists ONLY in this file. If the corpus ever grows to include scripts/, or this
# gate's prose is pasted into a document, SELF-1 sees it and the gate fails. Never document it.
CANARY = "ROAE_GATE89_CANARY_NOT_DOCUMENTATION"
FLOOR_KEYS, FLOOR_TOKENS, FLOOR_FILES, FLOOR_BYTES = 300, 95, 45, 2000000
# LEG 3 floors and ratchet, set from the 2026-09-08 measurement: 87 keys over 9 json.dump call
# sites, 63 positions the pass could not resolve. Measuring nothing is an ERROR, never a PASS.
# 🔴 CEIL_PY_UNRESOLVED re-pinned 63 -> 72 on 2026-09-11, WITH THE REASON THE GATE ASKS FOR.
# A 320-line standalone detector script under scripts/ was folded into solve.py that day so it would
# not outlive the run as a deferred commitment. The detector builds its result dict from local
# variables and f-strings the AST pass cannot constant-fold, which is what it counts as
# unresolved. MEASURED before re-pinning rather than assumed: of the sites this gate flags,
# 6 fall inside the folded range and the rest are pre-existing and merely renumbered by the
# insertion. The keys those expressions produce are NOT hidden -- all 14 are enumerated in
# documentation/SOLVE_PY_CLI.md under `--kc-class-swap-detect`, which is what the census exists
# to protect. Raising a ratchet without establishing what grew is a rubber stamp; this is the
# note that makes it not one.
# 🔴 CEIL_PY_UNRESOLVED re-pinned 72 -> 89 on 2026-10-03 (CX-279, Q-932), MEASURED THE SAME WAY:
# this gate run on the pre-batch tree (f9b50120) reports 70 unresolved positions and on the staged
# tree 89, and the diff of the two site lists is exactly the code that batch added to make the TR-8
# sampler compute its frozen pre-registration: 8 subscript reads and one `get(...)` in
# tr8_replication_gate (the two pools' results.json values copied into replication.json), the 4
# tuple-unpacks of tr8_hb_band() in _tr8_finish (exp_hb, sigma, hb_lo, hb_hi), the `k_head`
# parameter of tr8_replication_gate, the computed key and `items(...)` of tr8_ensemble_context,
# a third pass-through of tr8_dof_sampler's `band` parameter (_tr8_floor_halt), and the two
# `args.tr8_dof_merge` / `args.tr8_dof_replicate` attribute reads that become `pool_a_dir` /
# `pool_b_dir`. Every key those expressions produce is named in documentation/SOLVE_PY_CLI.md
# (§"TR-8 SAMPLER — CX-279 ADDITIONS": replication.json's keys, `gates.h_b_band`,
# `statistics.h_threshold`, `d2_k16`, `ensemble_context`), which is what the census protects.
# 🔴 CEIL_PY_UNRESOLVED re-pinned 89 -> 91 on 2026-10-03 (Q-970, A07#14), MEASURED THE SAME WAY: the
# only change is that a BoolOp operand is now resolved (`a or b` evaluates to an operand, so a dict
# there is a payload). The two new positions are solve.py:6325 and :6328, where `solutions_bin` /
# `baseline_bin` are rebound to `_ctx.__enter__()` -- file paths, not payloads; the diff of the two
# site lists (35782834 scripts vs the staged ones) is exactly those two lines and nothing else.
FLOOR_PY_KEYS, FLOOR_PY_SITES, CEIL_PY_UNRESOLVED = 70, 8, 91
# 🔴 CEIL_SH_LEXONLY (Q-970, A07#13): verdict tokens the SHELL LEXER sees emitted and the line scan
# above never did (an echo after `then`/`&&`/`{`/`;`, a second echo on a line, a printf with several
# tokens or %s filled from a literal), and that no documentation/ file names. MEASURED 2026-10-03 on
# the staged tree: 18, each printed below as a [note] with its site. They are pre-existing surface
# made visible, NOT adjudicated -- 14 are real verdict/census tokens and 4 are generated-runner shell
# source (scripts/tr12_mint_state_gate.sh:97-98, written inside a redirected `{ }` group this lexer
# cannot see the redirection of); the decision is the operator's (Q-970 report). Until then this is
# a RATCHET: one more FAILS. Its stated weakness: a COUNT, so fixing one and adding another holds it.
CEIL_SH_LEXONLY = 18

def rec(*a):
    print("\t".join(str(x) for x in a))

# ---- extract LEG 1: JSON keys printed by solve.c ---------------------------------------------
try:
    src = io.open(SRC, encoding="utf-8", errors="surrogateescape").read()
except OSError as e:
    rec("ERROR", "cannot read %s (%s) — NOTHING was checked" % (SRC, e.strerror)); sys.exit(0)
keys = {}
for m in re.finditer(r'\\"([A-Za-z_][A-Za-z0-9_]*)\\"\s*:', src):
    keys.setdefault(m.group(1), "%s:%d" % (SRC, src.count("\n", 0, m.start()) + 1))

# ---- extract LEG 2: whole-line KEY=value verdict tokens --------------------------------------
toks, dropped, lexonly = {}, 0, {}
SH = re.compile(r"""^\s*(?:echo|printf)\s+(?:-e\s+|-n\s+)?(['"])([A-Z][A-Z0-9_]{2,})=(.*?)\1""")
for f in sorted(glob.glob("scripts/*.sh")):
    try:
        lines = (io.open(f, encoding="utf-8", errors="surrogateescape").read() if f != "scripts/doc_gates.sh" else subprocess.run(["bash", "scripts/doc_gates.d/logical_source.sh"], stdout=subprocess.PIPE, check=True).stdout.decode("utf-8", "surrogateescape")).split("\n")
    except OSError as e:
        rec("ERROR", "cannot read %s (%s) — refusing to report OK from a partly-read tree" % (f, e.strerror)); sys.exit(0)
    for i, ln in enumerate(lines, 1):
        m = SH.match(ln)
        if not m:
            continue
        val = m.group(3)
        # Fragment generation, not a verdict: `echo 'WORK=$(mktemp -d); RAW=...'` writes shell
        # source into a generated script. A verdict line is the WHOLE line and nothing else.
        # Q-795: a line ending in the literal comment `# not-a-verdict` is a harness ASSIGNMENT
        # (`echo "KEY=$v" >> gen.sh`), declared as such by its author; dropped and COUNTED alike.
        if ";" in val or val[:1] in ('"', "'") or ln.rstrip().endswith("# not-a-verdict"):
            dropped += 1
            continue
        toks.setdefault(m.group(2), "%s:%d" % (f, i))
    # Q-970 (A07#13, Q-835 Codex review; adjudicated Q-962): AN EMITTER IS A COMMAND, NOT A LINE THAT
    # STARTS WITH ONE. `if true; then echo "Q835_NEW_VERDICT=PASS"; fi` printed an undocumented
    # verdict and SH (anchored at the line start) never read it. The same file is now also read by
    # the shell lexer (scripts/doc_gates.d/src_parse.sh): every echo/printf COMMAND, wherever it sits
    # on its line, and inside $(..) too, with printf's %s/%d filled from literal arguments
    # (`printf 'K=%s\n' PASS` emits K). Fragments and `# not-a-verdict` lines are dropped as above
    # (and not counted twice). A file the lexer cannot read is an ERROR. NOT SEEN, stated: lines a
    # here-document feeds to `cat`, and output built in a variable and printed elsewhere.
    _marked = {k for k, l in enumerate(lines, 1) if l.rstrip().endswith("# not-a-verdict")}
    try:
        _cmds = sp_sh_commands("\n".join(lines))
    except SpError as e:
        rec("ERROR", "cannot lex %s (%s) — refusing to report OK from a partly-read tree" % (f, e)); sys.exit(0)
    for _ln, _w in _cmds:
        if _w[0].quoted or _w[0].value not in ("echo", "printf") or _ln in _marked:
            continue
        if any(o in (">", ">>", ">|", "&>", "&>>") and t is not None
               and t.value not in ("/dev/stdout", "/dev/stderr") for o, t in _w.redirs):
            continue        # written into a FILE (a fixture, a generated script), not emitted
        _a = [x.value for x in _w[1:]]
        if _w[0].value == "echo":
            while _a and re.fullmatch(r"-[neE]+", _a[0]):
                _a = _a[1:]
            _outs = " ".join(_a).split("\n")
        else:
            if not _a or _a[0] == "-v":
                continue
            if _a[0] == "--":
                _a = _a[1:]
            _fmt, _rest = (_a[0], _a[1:]) if _a else ("", [])
            _fmt = _fmt.replace("\\n", "\n").replace("%%", "\x00")
            _fmt = re.sub(r"%[-#0 +]*[0-9]*(?:\.[0-9]+)?[sdiuxXfgeqb]",
                          lambda m: _rest.pop(0) if _rest else "", _fmt)
            _outs = _fmt.replace("\x00", "%").split("\n")
        for _o in _outs:
            _m = re.match(r"([A-Z][A-Z0-9_]{2,})=(.*)$", _o)
            if not _m or ";" in _m.group(2) or _m.group(2)[:1] in ('"', "'"):
                continue
            lexonly.setdefault(_m.group(1), "%s:%d" % (f, _ln))
for pat in (r'\b(?:printf|puts)\s*\(\s*"([A-Z][A-Z0-9_]{2,})=',
            r'\bfprintf\s*\(\s*stdout\s*,\s*"([A-Z][A-Z0-9_]{2,})='):
    for m in re.finditer(pat, src):
        toks.setdefault(m.group(1), "%s:%d" % (SRC, src.count("\n", 0, m.start()) + 1))

for _n in [n for n in lexonly if n in toks]:
    del lexonly[_n]                     # the line scan saw it too: not lexer-only

# ---- LEG 3: JSON keys printed by solve.py, resolved with an `ast` pass -------------------------
# solve.py assembles its payloads as dicts built across many statements, so a literal scrape would
# be partial and SILENTLY so. py_extract() resolves the expression flowing into every json.dump /
# json.dumps call, and every place it CANNOT resolve is RECORDED, never dropped. Dropping is the
# exact defect that kept solve.py out of this gate, so SELF-3 below proves the pass still reports.
PYSRC = "solve.py"
PY_FUNCS = (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda)
PY_SCOPES = (ast.Module, ast.ClassDef) + PY_FUNCS
# Calls whose result cannot be a dict, so a value flowing out of one hides no JSON keys. Containers,
# comprehensions and dict() are resolved structurally; anything NOT listed here is REPORTED, not
# assumed harmless.
PY_SCALAR_CALLS = frozenset(
    "len round abs sum min max repr hex oct ord chr id divmod format bool int float str bin pow "
    "hash type all any sqrt ceil floor log log2 log10 exp isinstance gcd comb factorial range "
    "enumerate zip time monotonic getpid fsum prod".split())
PY_SCALAR_METHODS = frozenset(
    "join split strip lower upper replace rstrip lstrip hexdigest encode decode format isoformat "
    "total_seconds abspath basename dirname getsize exists isdir isfile startswith endswith find "
    "rfind count index splitlines zfill rjust ljust title strftime bit_length to_bytes digest "
    "getvalue".split())
PY_PASSTHRU_CALLS = frozenset("list tuple sorted set frozenset reversed copy deepcopy".split())
PY_ARITH = (ast.Sub, ast.Mult, ast.Div, ast.FloorDiv, ast.Mod, ast.Pow, ast.LShift, ast.RShift,
            ast.BitAnd, ast.BitXor, ast.MatMult)
PY_SCALARISH = (ast.Constant, ast.Compare, ast.UnaryOp, ast.JoinedStr, ast.Lambda)
PY_MAXDEPTH = 12
# A nested VALUE can hide a further JSON object only in these forms.
PY_VALUE_FORMS = (ast.Dict, ast.DictComp, ast.IfExp, ast.BoolOp, ast.List, ast.Tuple, ast.Set, ast.ListComp,
                  ast.SetComp, ast.GeneratorExp, ast.Starred, ast.Name, ast.BinOp, ast.Call,
                  ast.Subscript, ast.Attribute)

def py_extract(text, fname):
    """Resolve the payload of every json.dump/json.dumps call in TEXT.

    Returns (keys, unresolved, n_sites): keys maps a JSON key to "fname:line"; unresolved is a
    sorted list of (kind, site, detail) for every position the pass could NOT resolve. Raises
    SyntaxError, which the caller turns into an ERROR verdict — a source that will not parse must
    never be reported as a source with no keys.
    """
    tree = ast.parse(text, filename=fname)
    parent = {}
    for n in ast.walk(tree):
        for c in ast.iter_child_nodes(n):
            parent[c] = n

    def scope_of(node):
        p = parent.get(node)
        while p is not None and not isinstance(p, PY_SCOPES):
            p = parent.get(p)
        return p

    def chain(node):
        out, sc = [], scope_of(node)
        while sc is not None:
            out.append(sc); sc = scope_of(sc)
        return out

    binds, upd, sub, itr, fdefs, calls = {}, {}, {}, {}, {}, {}

    def bind(sc, name, val):
        binds.setdefault(id(sc), {}).setdefault(name, []).append(val)

    def bind_target(sc, t, val):
        if isinstance(t, ast.Name):
            bind(sc, t.id, val)
        elif isinstance(t, (ast.Tuple, ast.List)):
            if isinstance(val, (ast.Tuple, ast.List)) and len(val.elts) == len(t.elts):
                for tt, vv in zip(t.elts, val.elts):
                    bind_target(sc, tt, vv)
            else:
                for tt in t.elts:
                    for nn in ast.walk(tt):
                        if isinstance(nn, ast.Name):
                            itr.setdefault(id(sc), {})[nn.id] = ("tuple-unpack", val)
        elif isinstance(t, ast.Starred):
            bind_target(sc, t.value, val)

    for n in ast.walk(tree):
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)):
            fdefs.setdefault(n.name, []).append(n)
        if isinstance(n, ast.Call):
            f = n.func
            nm = f.id if isinstance(f, ast.Name) else getattr(f, "attr", None)
            if nm:
                calls.setdefault(nm, []).append(n)
        sc = scope_of(n)
        if sc is None:
            continue
        if isinstance(n, ast.Assign):
            for t in n.targets:
                bind_target(sc, t, n.value)
                if isinstance(t, ast.Subscript) and isinstance(t.value, ast.Name):
                    sub.setdefault(id(sc), {}).setdefault(t.value.id, []).append((t.slice, n.value))
        elif isinstance(n, ast.AnnAssign) and n.value is not None:
            bind_target(sc, n.target, n.value)
        elif isinstance(n, (ast.AugAssign, ast.NamedExpr)):
            bind_target(sc, n.target, n.value)
        elif isinstance(n, (ast.For, ast.AsyncFor)):
            for t in ast.walk(n.target):
                if isinstance(t, ast.Name):
                    itr.setdefault(id(sc), {})[t.id] = ("loop-target", n.iter)
        elif isinstance(n, ast.comprehension):
            for t in ast.walk(n.target):
                if isinstance(t, ast.Name):
                    itr.setdefault(id(sc), {})[t.id] = ("comprehension-target", n.iter)
        elif isinstance(n, ast.withitem) and n.optional_vars is not None:
            bind_target(sc, n.optional_vars, n.context_expr)
        elif isinstance(n, ast.Call) and isinstance(n.func, ast.Attribute) \
                and n.func.attr == "update" and isinstance(n.func.value, ast.Name):
            tgt = upd.setdefault(id(sc), {}).setdefault(n.func.value.id, [])
            tgt.extend(n.args)
            if n.keywords:
                tgt.append(n)

    def lookup(name, node):
        for sc in chain(node):
            d = binds.get(id(sc), {})
            if name in d:
                return sc, d[name], None
        for sc in chain(node):
            d = itr.get(id(sc), {})
            if name in d:
                return sc, None, d[name]
        return None, None, None

    def param_of(name, node):
        for sc in chain(node):
            if isinstance(sc, PY_FUNCS):
                a = sc.args
                pos = [x.arg for x in list(getattr(a, "posonlyargs", [])) + list(a.args)]
                if name in pos:
                    return sc, pos.index(name)
                if name in [x.arg for x in a.kwonlyargs] \
                        or (a.vararg and a.vararg.arg == name) or (a.kwarg and a.kwarg.arg == name):
                    return sc, None
        return None, None

    keys, unres, seen = {}, [], set()

    def site(n):
        return "%s:%d" % (fname, getattr(n, "lineno", 0))

    def blind(node, kind, detail):
        # NEVER make this a no-op. A pass that resolves what it can and drops what it cannot is
        # partial and silent, which is worse than no pass at all. SELF-3 proves it still reports.
        unres.append((kind, site(node), detail))

    def add(name, node):
        keys.setdefault(name, site(node))

    def obj(node, depth=0):
        """Resolve NODE as an expression that may carry JSON object keys."""
        if node is None or id(node) in seen:
            return
        if depth > PY_MAXDEPTH:
            blind(node, "depth-limit", "resolution exceeded %d levels" % PY_MAXDEPTH); return
        seen.add(id(node))
        d = depth + 1
        if isinstance(node, ast.Dict):
            for k, v in zip(node.keys, node.values):
                if k is None:
                    obj(v, d)                                   # **expr
                elif isinstance(k, ast.Constant) and isinstance(k.value, str):
                    add(k.value, k); val(v, d)
                else:
                    blind(k, "dynamic-key",
                          "dict key is a %s, not a string literal" % type(k).__name__)
                    val(v, d)
            return
        if isinstance(node, ast.DictComp):
            if isinstance(node.key, ast.Constant) and isinstance(node.key.value, str):
                add(node.key.value, node.key)
            else:
                blind(node.key, "dynamic-key",
                      "dict-comprehension key is computed (%s)" % type(node.key).__name__)
            val(node.value, d); return
        if isinstance(node, ast.IfExp):
            obj(node.body, d); obj(node.orelse, d); return
        # Q-970 (A07#14): `a or b` / `a and b` EVALUATES TO ONE OF ITS OPERANDS, so a dict operand is a
        # payload. BoolOp sat in PY_SCALARISH (read as a bool), and `json.dumps({"k": 1} or {})`
        # printed an undocumented key with this leg green. Every operand is resolved, like IfExp.
        if isinstance(node, ast.BoolOp):
            for v in node.values:
                obj(v, d)
            return
        if isinstance(node, (ast.List, ast.Tuple, ast.Set)):
            for e in node.elts:
                obj(e, d)
            return
        if isinstance(node, (ast.ListComp, ast.SetComp, ast.GeneratorExp)):
            obj(node.elt, d); return
        if isinstance(node, ast.Starred):
            obj(node.value, d); return
        if isinstance(node, ast.BinOp):
            if isinstance(node.op, (ast.BitOr, ast.Add)):
                obj(node.left, d); obj(node.right, d)
            elif not isinstance(node.op, PY_ARITH):
                blind(node, "unhandled", "binary operator %s" % type(node.op).__name__)
            return
        if isinstance(node, PY_SCALARISH):
            return
        if isinstance(node, ast.Name):
            sc, vals, it = lookup(node.id, node)
            if vals:
                for v in vals:
                    obj(v, d)
                for u in upd.get(id(sc), {}).get(node.id, []):
                    if isinstance(u, ast.Call):
                        for kw in u.keywords:
                            if kw.arg:
                                add(kw.arg, kw)
                            else:
                                obj(kw.value, d)
                    else:
                        obj(u, d)
                for kn, vn in sub.get(id(sc), {}).get(node.id, []):
                    s = kn.value if isinstance(kn, ast.Index) else kn
                    if isinstance(s, ast.Constant) and isinstance(s.value, str):
                        add(s.value, s); val(vn, d)
                    else:
                        blind(s, "dynamic-key",
                              "`%s[...]` is assigned under a computed key" % node.id)
                        val(vn, d)
                return
            if it:
                blind(node, it[0], "`%s` is bound by a %s; this pass does not element-type the"
                                   " iterable" % (node.id, it[0]))
                return
            fn, pos = param_of(node.id, node)
            if fn is not None:
                bound = False
                for c in calls.get(fn.name, []):
                    for kw in c.keywords:
                        if kw.arg == node.id:
                            obj(kw.value, d); bound = True
                    if pos is not None and pos < len(c.args):
                        obj(c.args[pos], d); bound = True
                if not bound:
                    blind(node, "parameter", "`%s` is a parameter of %s() and no call site binds it"
                                             " to a resolvable expression" % (node.id, fn.name))
                return
            blind(node, "unbound-name", "`%s` has no binding this pass can find" % node.id)
            return
        if isinstance(node, ast.Call):
            f = node.func
            fn = f.id if isinstance(f, ast.Name) else getattr(f, "attr", None)
            if fn == "dict":
                for kw in node.keywords:
                    if kw.arg:
                        add(kw.arg, kw)
                    else:
                        obj(kw.value, d)
                for a in node.args:
                    obj(a, d)
                return
            if fn in PY_PASSTHRU_CALLS:
                for a in node.args:
                    obj(a, d)
                return
            if fn in PY_SCALAR_CALLS or fn in PY_SCALAR_METHODS:
                return
            if isinstance(f, ast.Name) and fn in fdefs:
                for fd in fdefs[fn]:
                    rets = [r.value for r in ast.walk(fd)
                            if isinstance(r, ast.Return) and r.value is not None]
                    if not rets:
                        blind(node, "call", "`%s()` has no resolvable return expression" % fn)
                    for r in rets:
                        obj(r, d)
                return
            blind(node, "call",
                  "value flows from `%s(...)`, which this pass does not enter" % (fn or "?"))
            return
        if isinstance(node, ast.Attribute):
            blind(node, "attribute", "value read through attribute `.%s`; this pass does not model"
                                     " attribute types" % node.attr); return
        if isinstance(node, ast.Subscript):
            blind(node, "subscript", "value read through a subscript; this pass does not model"
                                     " element types"); return
        blind(node, "unhandled", "expression of type %s is not resolvable" % type(node).__name__)

    def val(node, depth):
        if isinstance(node, PY_VALUE_FORMS):
            obj(node, depth)

    # Q-970: the json module under ANY name -- `import json as j` (j.dumps) and `from json import dumps
    # [as d]` (d(...)) are the same call as json.dumps.
    jmods, jfuncs = {"json"}, {}
    for n in ast.walk(tree):
        if isinstance(n, ast.Import):
            jmods |= {a.asname or a.name for a in n.names if a.name == "json"}
        elif isinstance(n, ast.ImportFrom) and n.module == "json":
            jfuncs.update({a.asname or a.name: a.name for a in n.names if a.name in ("dump", "dumps")})
    dumps = sorted((n for n in ast.walk(tree)
                    if isinstance(n, ast.Call) and (
                        (isinstance(n.func, ast.Attribute) and n.func.attr in ("dump", "dumps")
                         and isinstance(n.func.value, ast.Name) and n.func.value.id in jmods)
                        or (isinstance(n.func, ast.Name) and n.func.id in jfuncs))),
                   key=lambda n: getattr(n, "lineno", 0))
    for c in dumps:
        if not c.args:
            blind(c, "no-arg", "json.%s() called with no positional payload"
                  % getattr(c.func, "attr", jfuncs.get(getattr(c.func, "id", ""), "dumps")))
        else:
            obj(c.args[0], 0)
    unres.sort()
    return keys, unres, len(dumps)

try:
    pytext = io.open(PYSRC, encoding="utf-8", errors="surrogateescape").read()
except OSError as e:
    rec("ERROR", "cannot read %s (%s) — NOTHING was checked" % (PYSRC, e.strerror)); sys.exit(0)
try:
    pykeys, pyunres, pysites = py_extract(pytext, PYSRC)
except SyntaxError as e:
    rec("ERROR", "%s does not parse (%s, line %s) — refusing to report OK from a source this gate"
                 " could not read" % (PYSRC, e.msg, e.lineno)); sys.exit(0)

# ---- corpus, with the closure exclusion --------------------------------------------------------
texts, nfiles, excluded, generated = [], 0, [], []
GENERATED = ("CORRECTIONS_INVENTORY.tsv", "CORRECTION_MARKER_INVENTORY.tsv")
if not os.path.isdir(DOCROOT):
    rec("ERROR", "%s/ is missing — NOTHING was checked" % DOCROOT); sys.exit(0)
for root, _d, files in os.walk(DOCROOT):
    for fn in sorted(files):
        if not fn.endswith((".md", ".tsv", ".txt")):
            continue
        p = os.path.join(root, fn)
        # CLOSURE EXCLUSION: the gate suite's own bookkeeping tables, including this gate's
        # allowance file, are not documentation of the code. Without this the allowance table
        # (which names every open finding) would absolve every one of them.
        if fn.startswith("DOC_GATE_"):
            excluded.append(p); continue
        # GENERATED-EVIDENCE EXCLUSION (Q-867, 2026-09-27). scripts/corrections_inventory.sh and
        # scripts/correction_marker_inventory.sh write these two tables by quoting lines verbatim
        # from every public file, reports/ and commit messages included. A name they quote is not
        # thereby documented under documentation/: regenerating the inventory quoted a
        # reports/TR12_QUERY_PROGRAM.md line naming `TR12_A*`, and this gate then called the
        # fixture-only token TR12_A "documented" and its adjudicated-open row stale.
        if fn in GENERATED:
            generated.append(p); continue
        try:
            texts.append(io.open(p, encoding="utf-8", errors="surrogateescape").read())
        except OSError as e:
            rec("ERROR", "could not read %s (%s) — refusing to report OK from a corpus this gate"
                         " could not fully read" % (p, e.strerror)); sys.exit(0)
        nfiles += 1
docs = "\n".join(texts)

# 🔴 HYPHENATED NAMES WERE UNDOCUMENTABLE BY CONSTRUCTION (fixed 2026-09-08).
# This vocabulary was [A-Za-z_][A-Za-z0-9_]* , which can never yield a token containing a
# hyphen. So header.json seed-purpose keys "bank-calibration" and "timing-probe" -- both
# named VERBATIM at documentation/SOLVE_PY_CLI.md:363 -- could not be cleared by any amount
# of writing, and sat OPEN as "undocumented". An instrument that cannot register a real fix
# sends the next reader to write prose that changes nothing. The second pattern adds the
# hyphen- and slash-separated compounds; it only ADDS to the vocabulary, so it can move a
# name from undocumented to documented and never the reverse.
def words_of(text):
    return (set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", text))
            | set(re.findall(r"[A-Za-z_][A-Za-z0-9_]*(?:[-/][A-Za-z0-9_]+)+", text)))

def undocumented(names, vocab):
    return [n for n in sorted(names) if n not in vocab]

vocab = words_of(docs)
# identifier-context vocabulary: names that appear inside a fenced block, an inline-code span or a
# double-quoted string. Used only for the WEAK-CLEAR note; it is not the pass/fail rule, because it
# false-positives on names documented in flowing prose (measured: campaign_wall_seconds,
# extensions_observed are documented at SOLVE_C_CLI.md and have no identifier context).
ctx = "\n".join(re.findall(r"```.*?```", docs, re.S)
                + re.findall(r"`[^`\n]*`", docs)
                + re.findall(r'"[^"\n]*"', docs))
ctxvocab = words_of(ctx)

# ---- SELF-1: the canary must be absent from the corpus -----------------------------------------
if CANARY in docs:
    rec("SELF", "FAIL", "the canary literal appears in the documentation corpus — the corpus now"
                        " contains this gate's own text, so its witness is its own closure")
else:
    rec("SELF", "OK", "canary absent from %d corpus file(s); %d DOC_GATE_* file(s) excluded;"
                      " %d generated inventory file(s) excluded" % (nfiles, len(excluded), len(generated)))

# ---- SELF-2: the matcher must be able to come out FALSE and TRUE -------------------------------
probe = sorted(keys)[:5] + sorted(toks)[:5] + sorted(pykeys)[:5]
if not probe:
    rec("SELF", "FAIL", "no names extracted at all, so falsifiability could not be exercised")
else:
    neg = undocumented(probe, words_of(""))
    pos = undocumented(probe, words_of(" ".join(probe)))
    if len(neg) != len(probe):
        rec("SELF", "FAIL", "against an EMPTY corpus the matcher cleared %d of %d probe name(s);"
                            " a matcher that cannot be FALSE has not been built"
                            % (len(probe) - len(neg), len(probe)))
    elif pos:
        rec("SELF", "FAIL", "against a corpus containing every probe name the matcher still"
                            " reported %d undocumented; it cannot be TRUE either" % len(pos))
    else:
        rec("SELF", "OK", "matcher is FALSE on an empty corpus (%d/%d) and TRUE on a full one"
                          % (len(neg), len(probe)))

# ---- SELF-3: LEG 3 must still REPORT what it cannot resolve ------------------------------------
# The mutation this catches: a pass that returns everything it CAN resolve and silently drops what
# it cannot. That is exactly why solve.py was scoped out of this gate before LEG 3 existed, and the
# ratchet below cannot catch it — a dropped blind spot makes the count FALL, not rise. So the pass
# is run live against two snippets whose answers are known: one it must fully resolve, and one it
# CANNOT resolve at all and must therefore report.
SELF3_OK = ('import json\n'
            'd = {"self3_alpha": 1}\n'
            'd.update({"self3_beta": 2})\n'
            'json.dump(d, None)\n')
SELF3_BLIND = ('import json\n'
               'json.dump(payload_from_somewhere_else(), None)\n')
try:
    _k3, _u3, _s3 = py_extract(SELF3_OK, "<self3-ok>")
    _kb, _ub, _sb = py_extract(SELF3_BLIND, "<self3-blind>")
except SyntaxError as e:
    _k3, _u3, _s3, _kb, _ub, _sb = {}, [], 0, {}, [], 0
    rec("SELF", "FAIL", "the LEG 3 self-proof snippets did not parse (%s)" % e.msg)
if _s3 != 1 or _sb != 1:
    rec("SELF", "FAIL", "LEG 3 found %d and %d json.dump call site(s) in one-call snippets; the"
                        " call-site finder is broken" % (_s3, _sb))
elif set(_k3) != set(("self3_alpha", "self3_beta")) or _u3:
    rec("SELF", "FAIL", "LEG 3 resolved %r with %d unresolved from a snippet whose keys are exactly"
                        " self3_alpha and self3_beta; the resolver is broken"
                        % (sorted(_k3), len(_u3)))
elif _kb or not _ub:
    rec("SELF", "FAIL", "LEG 3 reported %d key(s) and %d unresolved position(s) for a payload built"
                        " by a callable it cannot see. It is DROPPING what it cannot resolve, which"
                        " is the partial-and-silent failure LEG 3 exists to prevent"
                        % (len(_kb), len(_ub)))
else:
    rec("SELF", "OK", "LEG 3 resolves a known dict exactly (%d keys, 0 unresolved) and REPORTS a"
                      " payload it cannot resolve (%d key(s), %d unresolved)"
                      % (len(_k3), len(_kb), len(_ub)))

# ---- floors: measuring nothing is an ERROR, never a PASS ---------------------------------------
errs = []
if len(keys) < FLOOR_KEYS:
    errs.append("only %d JSON key(s) extracted from %s, floor is %d — the matcher stopped matching,"
                " not the engine stopped printing" % (len(keys), SRC, FLOOR_KEYS))
if len(toks) < FLOOR_TOKENS:
    errs.append("only %d verdict token(s) extracted from scripts/*.sh + %s, floor is %d"
                % (len(toks), SRC, FLOOR_TOKENS))
if pysites < FLOOR_PY_SITES:
    errs.append("only %d json.dump/json.dumps call site(s) found in %s, floor is %d — the AST pass"
                " stopped finding the calls, not %s stopped writing JSON"
                % (pysites, PYSRC, FLOOR_PY_SITES, PYSRC))
if len(pykeys) < FLOOR_PY_KEYS:
    errs.append("only %d JSON key(s) resolved from %s, floor is %d — an extractor that resolves"
                " nothing must ERROR, never report a clean tree"
                % (len(pykeys), PYSRC, FLOOR_PY_KEYS))
if nfiles < FLOOR_FILES:
    errs.append("only %d corpus file(s) under %s/, floor is %d" % (nfiles, DOCROOT, FLOOR_FILES))
if len(docs) < FLOOR_BYTES:
    errs.append("corpus is %d bytes, floor is %d — a corpus this small was not read" % (len(docs), FLOOR_BYTES))
if errs:
    for e in errs:
        rec("ERROR", e)
    sys.exit(0)

# ---- allowance table ---------------------------------------------------------------------------
allow = {}
try:
    araw = io.open(ALLOW, encoding="utf-8", errors="surrogateescape").read()
except OSError as e:
    rec("ERROR", "cannot read the allowance table %s (%s). Absent is NOT empty: without it every"
                 " pre-existing finding would read as new, and with it silently empty every finding"
                 " would read as a defect. Refusing to judge." % (ALLOW, e.strerror))
    for surface, d in (("json-key", keys), ("verdict-token", toks), ("py-json-key", pykeys)):
        for n in undocumented(d, vocab):
            rec("HIT", surface, n, d[n], "emitted here and named in no documentation/ file")
    sys.exit(0)
for line in araw.split("\n"):
    if not line.strip() or line.startswith("#"):
        continue
    c = line.split("\t")
    if len(c) < 4:
        rec("ERROR", "%s row has %d column(s), need 4 (surface, name, site, reason): %r"
                     % (ALLOW, len(c), line[:70])); sys.exit(0)
    if c[0] not in ("json-key", "verdict-token", "py-json-key"):
        rec("ERROR", "%s row names surface %r, which is none of json-key, verdict-token,"
                     " py-json-key" % (ALLOW, c[0])); sys.exit(0)
    allow[(c[0], c[1])] = [c[3], 0]

# ---- the two legs ------------------------------------------------------------------------------
# LEG 3's findings are counted in their OWN pair of counters. DOC_GATE_EMITTED_SURFACE_NEW and
# _OPEN keep exactly the scope and the meaning they had before LEG 3 existed — solve.c plus
# scripts/*.sh — because they are pinned numbers other lanes read. LEG 3 reports through
# _PY_NEW / _PY_OPEN, and the OK/FAIL verdict covers all three legs.
nnew = nopen = pynew = pyopen = 0
SURFACES = (("json-key", keys), ("verdict-token", toks), ("py-json-key", pykeys))
for surface, d in SURFACES:
    for n in undocumented(d, vocab):
        k = (surface, n)
        ispy = surface == "py-json-key"
        if k in allow:
            allow[k][1] += 1
            if ispy:
                pyopen += 1
            else:
                nopen += 1
            rec("OPEN", surface, n, d[n], allow[k][0])
        else:
            if ispy:
                pynew += 1
            else:
                nnew += 1
            rec("HIT", surface, n, d[n], "emitted here and named in no documentation/ file")
for (surface, n), (why, used) in sorted(allow.items()):
    if used:
        continue
    src_d = {"json-key": keys, "verdict-token": toks, "py-json-key": pykeys}[surface]
    emitted, where = n in src_d, src_d.get(n)
    if not emitted:
        rec("HIT", surface, n, ALLOW, "allowance row matches NOTHING — the code no longer emits"
                                      " this name; delete the row")
    else:
        rec("HIT", surface, n, where, "allowance row is stale — %s is now DOCUMENTED; delete the row"
                                      " so it cannot outlive its fix" % n)
    if surface == "py-json-key":
        pynew += 1
    else:
        nnew += 1

# ---- weak clears (report only) -----------------------------------------------------------------
weak = [(s, n) for s, d in SURFACES
        for n in sorted(d) if n in vocab and n not in ctxvocab]
for s, n in weak:
    rec("WEAK", s, n, "-", "cleared only by a bare prose occurrence — no backtick span,"
                           " fenced block or quoted string in documentation/ names it as an identifier")

# Every position LEG 3 could not resolve is PRINTED with its site. A count that is not visible
# is the silent partiality this leg exists to avoid.
for kind, site, detail in pyunres:
    rec("PYUNRES", "py-unresolved", kind, site, detail)
lexundoc = []
for n in undocumented(lexonly, vocab):
    if ("verdict-token", n) in allow:
        allow[("verdict-token", n)][1] += 1
        continue
    lexundoc.append(n)
for n in lexundoc:
    # Over the ceiling every one is a FAIL line (the new name is among them; a diff against the
    # 18 listed in the Q-970 report names it); at or under it they are notes.
    rec("HIT" if len(lexundoc) > CEIL_SH_LEXONLY else "LEXONLY", "verdict-token", n, lexonly[n],
        "emitted (seen by the shell lexer only, Q-970) and named in no documentation/ file; pending"
        " adjudication")
if len(lexundoc) > CEIL_SH_LEXONLY:
    rec("CEIL", "verdict-token", len(lexundoc), "scripts/*.sh",
        "the shell lexer sees %d undocumented verdict token(s) the line scan cannot, above the pinned"
        " ceiling of %d — a NEW one was emitted. Document it, or re-pin CEIL_SH_LEXONLY with the"
        " reason." % (len(lexundoc), CEIL_SH_LEXONLY))
if len(pyunres) > CEIL_PY_UNRESOLVED:
    rec("CEIL", "py-unresolved", len(pyunres), PYSRC,
        "the AST pass could not resolve %d expression(s), above the pinned ceiling of %d — %s grew"
        " a payload this pass cannot see into, so the key census is measuring LESS than it did."
        " Resolve it, or re-pin CEIL_PY_UNRESOLVED with the reason."
        % (len(pyunres), CEIL_PY_UNRESOLVED, PYSRC))
rec("POP", len(keys), len(toks), nfiles, len(docs), nopen, nnew, dropped, len(weak),
    pysites, len(pykeys), pyopen, pynew, len(pyunres), len(lexundoc))
ESPY
} | python3 - ) || { echo "  [FAIL] GATE 89 scanner crashed — NOTHING was checked."
       echo "DOC_GATE_EMITTED_SURFACE_JSON_KEYS=-1"; echo "DOC_GATE_EMITTED_SURFACE_TOKENS=-1"
       echo "DOC_GATE_EMITTED_SURFACE_NEW=-1"; echo "DOC_GATE_EMITTED_SURFACE_OPEN=-1"
       echo "DOC_GATE_EMITTED_SURFACE_DROPPED=-1"
       echo "DOC_GATE_EMITTED_SURFACE_PY_JSON_KEYS=-1"; echo "DOC_GATE_EMITTED_SURFACE_PY_NEW=-1"
       echo "DOC_GATE_EMITTED_SURFACE_PY_OPEN=-1"; echo "DOC_GATE_EMITTED_SURFACE_PY_UNRESOLVED=-1"; echo "DOC_GATE_EMITTED_SURFACE_LEXONLY=-1"
       echo "DOC_GATE_EMITTED_SURFACE=ERROR"; return 1; }

  # The self-tests and the floors are judged BEFORE the findings, so a broken extractor can never
  # be reported as a clean tree.
  local _self_fail; _self_fail=$(printf '%s\n' "$out" | awk -F'\t' '$1=="SELF" && $2=="FAIL"{print $3}')
  local _err;       _err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$_err" ] || [ -n "$_self_fail" ]; then
    printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{printf "  [FAIL] GATE 89 could not judge its subject: %s\n",$2}'
    printf '%s\n' "$out" | awk -F'\t' '$1=="SELF" && $2=="FAIL"{printf "  [FAIL] GATE 89 closure/falsifiability proof: %s\n",$3}'
    printf '%s\n' "$out" | awk -F'\t' '$1=="HIT"{printf "  [note] (%s) %s at %s — %s\n",$2,$3,$4,$5}'
    echo "DOC_GATE_EMITTED_SURFACE_JSON_KEYS=-1"; echo "DOC_GATE_EMITTED_SURFACE_TOKENS=-1"
    echo "DOC_GATE_EMITTED_SURFACE_NEW=-1"; echo "DOC_GATE_EMITTED_SURFACE_OPEN=-1"
    echo "DOC_GATE_EMITTED_SURFACE_DROPPED=-1"
    echo "DOC_GATE_EMITTED_SURFACE_PY_JSON_KEYS=-1"; echo "DOC_GATE_EMITTED_SURFACE_PY_NEW=-1"
    echo "DOC_GATE_EMITTED_SURFACE_PY_OPEN=-1"; echo "DOC_GATE_EMITTED_SURFACE_PY_UNRESOLVED=-1"; echo "DOC_GATE_EMITTED_SURFACE_LEXONLY=-1"
    echo "DOC_GATE_EMITTED_SURFACE=ERROR"
    return 1
  fi
  printf '%s\n' "$out" | awk -F'\t' '$1=="SELF"{printf "  [ok]   self-proof: %s\n",$3}'

  local pk pt pf pb po pn pd pw pys pyk pyo pyn pyu pl
  IFS=$'\t' read -r pk pt pf pb po pn pd pw pys pyk pyo pyn pyu pl < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11"\t"$12"\t"$13"\t"$14"\t"$15; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pk-}"; then
    echo "  [FAIL] GATE 89 printed no population census — nothing was measured."
    echo "DOC_GATE_EMITTED_SURFACE_JSON_KEYS=-1"; echo "DOC_GATE_EMITTED_SURFACE_TOKENS=-1"
    echo "DOC_GATE_EMITTED_SURFACE_NEW=-1"; echo "DOC_GATE_EMITTED_SURFACE_OPEN=-1"
    echo "DOC_GATE_EMITTED_SURFACE_DROPPED=-1"
    echo "DOC_GATE_EMITTED_SURFACE_PY_JSON_KEYS=-1"; echo "DOC_GATE_EMITTED_SURFACE_PY_NEW=-1"
    echo "DOC_GATE_EMITTED_SURFACE_PY_OPEN=-1"; echo "DOC_GATE_EMITTED_SURFACE_PY_UNRESOLVED=-1"; echo "DOC_GATE_EMITTED_SURFACE_LEXONLY=-1"
    echo "DOC_GATE_EMITTED_SURFACE=ERROR"
    return 1
  fi

  local rc=0 tag surface name site why
  while IFS=$'\t' read -r tag surface name site why; do
    case "$tag" in
      HIT)  echo "  [FAIL] ($surface) $name — $why [$site]"; rc=1 ;;
      OPEN) echo "  [OPEN] ($surface) $name at $site — adjudicated open: $why" ;;
      WEAK) echo "  [note] weak clear ($surface) $name — $why" ;;
      PYUNRES) echo "  [note] LEG 3 unresolved [$name] at $site — $why" ;;
      LEXONLY) echo "  [note] ($surface) $name at $site — $why" ;;
      CEIL) echo "  [FAIL] ($surface) $why"; rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")

  echo "  ---- GATE 89 census: $pk JSON key(s) + $pt verdict token(s) vs $pf documentation file(s)"
  echo "       ($pb bytes); $po adjudicated-open, $pn new, $pd fragment line(s) dropped, $pw weak clear(s)."
  echo "  ---- LEG 3 census: $pyk JSON key(s) resolved from $pys json.dump call site(s) in solve.py;"
  echo "       $pyo adjudicated-open, $pyn new, $pyu position(s) the AST pass could NOT resolve"
  echo "       (each printed above with its site; a non-zero count means the key census is a LOWER"
  echo "       BOUND, never that solve.py emits nothing)."
  echo "DOC_GATE_EMITTED_SURFACE_JSON_KEYS=$pk"
  echo "DOC_GATE_EMITTED_SURFACE_TOKENS=$pt"
  echo "DOC_GATE_EMITTED_SURFACE_NEW=$pn"
  echo "DOC_GATE_EMITTED_SURFACE_OPEN=$po"
  echo "DOC_GATE_EMITTED_SURFACE_DROPPED=$pd"
  echo "DOC_GATE_EMITTED_SURFACE_PY_JSON_KEYS=$pyk"
  echo "DOC_GATE_EMITTED_SURFACE_PY_NEW=$pyn"
  echo "DOC_GATE_EMITTED_SURFACE_PY_OPEN=$pyo"
  echo "DOC_GATE_EMITTED_SURFACE_PY_UNRESOLVED=$pyu"
  echo "DOC_GATE_EMITTED_SURFACE_LEXONLY=$pl"
  if [ "$rc" -ne 0 ]; then
    echo "DOC_GATE_EMITTED_SURFACE=FAIL"
    return 1
  fi
  echo "  [ok] GATE 89: no NEWLY undocumented emitted name. The $po + $pyo [OPEN] row(s) above are"
  echo "       real defects that do NOT set this exit code — green means no NEW one, not none."
  echo "DOC_GATE_EMITTED_SURFACE=OK"
  return 0
}


# ---------------------------------------------------------------------------
# GATE 85 — a completion STATUS may not read as a completeness CLAIM
# (`completion-semantics`).
#
# 🔴 WHY. `SEARCH_COMPLETE` is emitted by solve.c at both of its sites as nothing more than the
# `else` branch of `if (global_timed_out)`. It means "this process reached its own end without
# hitting the wall clock". It has never meant "the search space was exhausted" — and since EVERY
# enumeration this project publishes is budgeted, with each cell stopping at its node allowance, a
# run that leaves an unexplored DFS suffix under every truncated sub-branch still reports
# SEARCH_COMPLETE. The name asserts more than the program knows.
#
# The sibling defect in the same corpus was already corrected on 2026-08-28: SOLUTIONS_FORMAT.md
# said the file "contains every unique pair ordering … that satisfies constraints C1-C5", with no
# budget qualifier anywhere in it — an unscoped completeness claim the rest of the corpus
# contradicts. Both are the same error wearing different clothes, which is why one gate covers both.
#
# THE TOKEN IS DELIBERATELY NOT RENAMED and this gate must never be read as asking for that.
# Monitors match it as a literal, and a completion-detection regex mismatch has already cost this
# project a run (HISTORY.md: the monitor grepped "SEARCH COMPLETE", the solver writes
# "SEARCH_COMPLETE"). The name is a compatibility surface; the prose is the semantics, and the prose
# is what this gate keeps in place.
# ---------------------------------------------------------------------------
gate_completion_semantics() {
  echo "== GATE 85: a completion status does not read as a completeness claim =="
  local rc=0 _cs _sfw
  if [ ! -r documentation/DEPLOYMENT.md ]; then
    echo "  [FAIL] documentation/DEPLOYMENT.md unreadable — cannot confirm the disambiguation"
    rc=1
  elif _cs=$(python3 -c "$(_md_norm_prelude; _wm_prelude)"'
import re
L = md_read("documentation/DEPLOYMENT.md").split("\n")
flat, starts = "", []
for l in L:
    starts.append(len(flat) + (1 if flat else 0)); flat = (flat + " " if flat else "") + md_inline(l)
P = re.compile(r"search\s+space\s+was\s+exhausted", re.I)
n = 0
for m in P.finditer(flat):
    n += 1
    if not wm_negated(flat, m.start(), 6):
        print("AFFIRM\t%d" % (sum(1 for s in starts if s <= m.start())))
print("N\t%d" % n)') && ! grep -q $'^N\t[1-9]' <<<"$_cs"; then
    echo "  [FAIL] DEPLOYMENT.md no longer says what SEARCH_COMPLETE does NOT assert."
    echo "     The token is emitted as the else-branch of a wall-clock timeout test. Without the"
    echo "     qualifier a reader takes a budgeted run for an exhaustive one."
    rc=1
  elif [ -z "$_cs" ] || grep -q $'^AFFIRM\t' <<<"$_cs"; then
    # Q-966 (A07#15): the phrase must be NEGATED where it stands ("It is NOT a claim that the search space
    # was exhausted"), every occurrence; the shared matcher's negation test, 6 words back in the clause.
    # A bare substring test passed "It is a claim that the search space was exhausted."
    echo "  [FAIL] documentation/DEPLOYMENT.md:$(sed -n 's/^AFFIRM\t//p' <<<"$_cs" | paste -sd, -) states that the search space was exhausted"
    echo "     without negating it (or the check could not run). SEARCH_COMPLETE is a lifecycle status, not exhaustion."
    rc=1
  else
    echo "  [ok]   DEPLOYMENT.md states that SEARCH_COMPLETE is not a claim of exhaustion"
  fi
  # 🔴 MATCH THE PROSE AS RENDERED, NOT AS REMEMBERED. Both of the checks below failed on their
  # first run against a file that says exactly the right thing: "within its node budget" is WRAPPED
  # across two source lines, and "lower bound" is written "**lower bound**". A line-oriented grep for
  # a remembered literal reports a correct document as defective — the same mistake GATE 82 leg 3
  # made an hour earlier against a bolded sentence. So the text is normalised first: whitespace
  # collapsed to single spaces and emphasis markers stripped.
  local _sf; _sf=$(tr -s '[:space:]' ' ' < documentation/SOLUTIONS_FORMAT.md 2>/dev/null | tr -d '*')
  if [ ! -r documentation/SOLUTIONS_FORMAT.md ]; then
    echo "  [FAIL] documentation/SOLUTIONS_FORMAT.md unreadable — cannot confirm the budget scope"
    rc=1
  elif ! _sfw=$(printf '%s' "$_sf" | python3 -c "$(_wm_prelude)"'
import sys, re
s = sys.stdin.read()
for k, p in (("budget", r"within\s+its\s+node\s+budget"), ("lower", r"lower\s+bound")):
    if wm_has(s, wm_re(p)): print(k)   # Q-966: present AND not negated ("not a lower bound" is not one)
') || ! grep -qx 'budget' <<<"$_sfw"; then
    echo "  [FAIL] SOLUTIONS_FORMAT.md lost its budget qualifier — the 2026-08-28 correction."
    rc=1
  elif ! grep -qx 'lower' <<<"$_sfw"; then
    echo "  [FAIL] SOLUTIONS_FORMAT.md no longer calls the record count a lower bound."
    rc=1
  else
    echo "  [ok]   SOLUTIONS_FORMAT.md scopes the file to its node budget and calls the count a lower bound"
  fi
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 84 — every SOLVE_* environment variable the engine reads is documented
# (`env-surface`).
#
# 🔴 WHY. GATE 2 (`cli`) compares the set of FLAG names in the code against the set documented, and
# it works — it is what caught `--kc-g-check-layer` and `--kc-g-status` existing in solve.c and in no
# documentation. But `getenv` is a second CLI surface and NOTHING checked it. Measured 2026-09-04:
# solve.c reads 122 distinct SOLVE_* variables and FIVE appeared in zero documentation files —
# SOLVE_KC_CACHE_MB, SOLVE_KC_G_HEARTBEAT_SEC, SOLVE_KC_G_STOP_AT_K, SOLVE_KC_T_STOP_AT_K and
# SOLVE_KC_SCRATCH. Two of those change what a long ladder build DOES (a probe that stops it early,
# leaving an incomplete ladder) and one sets the block-cache size, so this is not a cosmetic gap.
#
# The sharpest illustration is that the gap bit the same day it was found. A paragraph added to
# SOLVE_C_CLI.md that morning described the heartbeat as "off by default"; the code defaults it to
# 300 seconds and treats <= 0 as the disable. The flag-presence gate could never have seen that,
# because there is no flag — and no reader would have found the variable to check it against.
#
# WHAT THIS DOES NOT DO, stated so the green is not read as more than it is: it checks PRESENCE of
# the name in documentation, not the ACCURACY of the description beside it. Accuracy is Q-410 and is
# not mechanically decidable in general. Presence is decidable, so presence is what is enforced.
#
# THE REVERSE DIRECTION IS DELIBERATELY NOT CHECKED. Documented-but-unread looks like the natural
# other half and measures badly: prose legitimately writes wildcards (`SOLVE_F1_*`, `SOLVE_KNUTH_*`)
# and cross-references filenames (`SOLVE_PY_CLI`), all of which a name-extractor reads as phantom
# variables. Measured, all four hits in that direction were artifacts of the extractor and none was
# a real defect. A gate whose findings are usually noise gets ignored, then removed.
# ---------------------------------------------------------------------------
gate_env_surface() {
  echo "== GATE 84: every SOLVE_* env var the engine reads is documented =="
  { _wm_prelude; cat <<'ENVPY'
import re, os, sys
try:
    src = open('solve.c', encoding='utf-8', errors='surrogateescape').read()
except OSError as e:
    print("  [FAIL] cannot read solve.c (%s) — NOTHING was checked." % e.strerror)
    print("     An unreadable engine is not an engine with no env vars; refusing to report OK.")
    sys.exit(1)
# Q-970 (A07#16, Q-835 Codex review; adjudicated Q-962): EVERY SPELLING OF A READ. `getenv("X")` was
# the only one seen, so `getenv ( "SOLVE_X" )` -- the same call -- read an undocumented variable with
# this gate green. The engine is read with its comments blanked (word_match.sh's C lexer: a name in a
# comment is not a read), and a read is getenv/secure_getenv with any spacing, OR any "SOLVE_*" string
# literal at all: a literal is how a name reaches getenv through a table (`getenv(specs[i].name)`), a
# macro or a wrapper, none of which a call pattern can follow. The literal set is the UPPER BOUND, and
# it is the set that must be documented. Measured 2026-10-03: the two sets are equal today (133).
# NOT SEEN, stated: a name assembled at run time ("SOLVE_" "KC" or snprintf) is invisible to both.
code = wm_strip_comments(src, 'c')
calls = set(re.findall(r'\b(?:secure_)?getenv\s*\(\s*"(SOLVE_[A-Z0-9_]+)"\s*\)', code))
names = sorted(calls | set(re.findall(r'"(SOLVE_[A-Z0-9_]+)"', code)))
if not names:
    print("  [FAIL] extracted ZERO SOLVE_* getenv sites from solve.c.")
    print("     That means the matcher stopped matching, not that the engine reads no environment.")
    sys.exit(1)
docs = ""
missing_dir = True
for root, _dirs, files in os.walk('documentation'):
    missing_dir = False
    for fn in files:
        if fn.endswith('.md'):
            try:
                docs += open(os.path.join(root, fn), encoding='utf-8', errors='surrogateescape').read()
            except OSError:
                print("  [FAIL] could not read documentation/%s — refusing to report OK from a"
                      " corpus this gate could not fully read." % fn)
                sys.exit(1)
if missing_dir or not docs:
    print("  [FAIL] the documentation/ corpus is missing or empty — NOTHING was checked.")
    sys.exit(1)
# ANCHORED, not a plain substring test. Caught by the red test 2026-09-04: renaming the documented
# `SOLVE_KC_SCRATCH` to `SOLVE_KC_SCRATCHPAD_RENAMED` left the gate GREEN, because the original name
# is a PREFIX of the new one and `n in docs` was still true. A documented variable that merely starts
# with the same letters is not the documented variable, so the name must not be followed by another
# name character.
# Q-966 (A07#17): an EXACT token (shared matcher), bounded on BOTH sides. With a right boundary only,
# UNRELATED_SOLVE_X in a doc "documented" SOLVE_X.
undoc = [n for n in names if not wm_tok(docs, n)]
for n in undoc:
    line = code[:re.search(r'"%s"' % re.escape(n), code).start()].count(chr(10)) + 1
    print("  [FAIL] %s is read at solve.c:%d and appears in no documentation/*.md" % (n, line))
if undoc:
    print("  [FAIL] %d of %d SOLVE_* variable(s) undocumented" % (len(undoc), len(names)))
    sys.exit(1)
print("  [ok]   all %d SOLVE_* variables read by solve.c appear in documentation/" % len(names))
ENVPY
  } | python3 - || return 1
}

# ---------------------------------------------------------------------------
# GATE 83 — the dispatcher, the usage banner and the gate functions agree
# (`dispatch-alignment`).
#
# 🔴 WHY. Measured 2026-09-04: `claims-repro` and `source-scope` were advertised in this script's own
# usage banner and had NO dispatcher case, while `scorecard-repro` and `scorecard-attribution` had
# cases and appeared nowhere in the banner. Both pairs entered in the SAME commit, 3515441c — the
# usage entry and the `case` arm were written with different names on the same day, so those two
# gates have NEVER been reachable under the names this script tells you to use.
#
# It fails in the safe direction — an unknown name exits 2 with the banner, so nobody got a silent
# pass — and that is exactly why it survived: a caller who typed `claims-repro` saw a usage error and
# assumed a typo on their side. What it cost is discoverability. Two working gates were invisible to
# anyone reading the banner, which is the only inventory most callers ever consult.
#
# The check is a three-way bijection and entirely decidable, so there is no reason to trust care:
#   (1) every dispatcher case name appears in the usage banner,
#   (2) every usage name has a dispatcher case,
#   (3) every gate_* function defined is actually invoked somewhere.
# (3) is the one that catches a gate quietly dropped from `all` during a refactor — a gate that is
# defined, documented and never run reads as coverage and is not.
#
# ⚠ IT WAS ALMOST FILED WITH TWO FALSE FINDINGS, recorded because the class recurs. A first pass
# reported `gate_appendonly_head` as "defined but never invoked": the matcher required a single space
# in `gate_x || RC=1` and the dispatcher aligns its arms with several. A second reported an
# advertised-but-missing name as a SILENT PASS: that rc had been read from a pipeline ending in
# `head`, so it was head's status, not the script's. Measured directly it is 2. Both were caught by
# re-measuring rather than by review, which is the only thing that reliably catches them.
# ---------------------------------------------------------------------------
gate_dispatch_alignment() {
  echo "== GATE 83: dispatcher, usage banner and gate functions agree =="
  { _sp_prelude; cat <<'DISPATCH_PY'
import re, sys
src = open(sys.argv[1], encoding='utf-8', errors='surrogateescape').read()
# Anchor on the DISPATCHER'S DEFAULT ARM, not on the banner text alone. Measured 2026-09-04: this
# gate's own source quotes the banner in order to find it, that quotation sits ~6,000 lines EARLIER
# in the file than the banner itself, and a plain search for the banner text therefore found THIS
# FUNCTION and parsed its Python as the list of gate names -- 92 spurious "missing from the usage
# banner" findings on a file that had four real ones. A checker that matches itself is the same
# self-reference class this file already records elsewhere; the fix is to key on a string the
# checker does not contain.
# BUILT FROM PIECES ON PURPOSE. Writing the anchor as one literal puts that literal in this file,
# ~6,000 lines ahead of the real banner, and the search finds THIS FUNCTION instead -- which is
# exactly what happened twice while writing this gate (92 then 96 spurious findings). Concatenating
# two fragments means the full string never occurs in the source, so the only place it can match is
# the dispatcher arm it is meant to find. A checker must not be spellable inside itself.
ANCHOR = '*) echo "usage: $' + '0 {'
try:
    i = src.index(ANCHOR); j = src.index('}', i + len(ANCHOR))
except ValueError:
    print("  [FAIL] could not locate the usage banner's dispatcher arm — nothing to compare.")
    print("     A banner this gate cannot read is not a banner that agrees; refusing to report OK.")
    sys.exit(1)
listed = [x.strip() for x in re.split(r'[|\s"\\]+', src[i+len(ANCHOR):j]) if x.strip()]
cases  = set(re.findall(r'^\s*([a-z0-9-]+)\)\s+gate_\w+\s+\|\|\s+RC=1\s*;;', src, re.M))
# Q-970 (A07#18, Q-835 Codex review; adjudicated Q-962): DEFINED and INVOKED are read by the shell
# lexer (scripts/doc_gates.d/src_parse.sh), not by patterns over raw text. `used` was any
# `gate_x || RC=1` in the file, comments included, and a definition was `gate_x() {` on one line only.
# Now a definition is any spelling bash accepts, and a use is a gate_* COMMAND -- not a comment, not a
# here-document, not a quoted string. The old patterns stay as the cross-check: a definition they see
# that the lexer does not is a FAIL (the lexer under-reads).
try:
    _sp_defs = sp_sh_funcdefs(src)
    _sp_cmds = sp_sh_commands(src)
except SpError as e:
    print("  [FAIL] the logical source could not be lexed (%s) — nothing to compare." % e)
    sys.exit(1)
fns    = {n for n in _sp_defs if n.startswith('gate_')}
used   = {w[0].value for _l, w in _sp_cmds if w[0].value.startswith('gate_') and not w[0].quoted}
_rxfns = set(re.findall(r'^(gate_\w+)\(\)\s*\{', src, re.M))
if not _rxfns <= fns:
    print("  [FAIL] %d gate function(s) the line pattern sees and the lexer does not: %s"
          % (len(_rxfns - fns), ", ".join(sorted(_rxfns - fns))))
    sys.exit(1)
bad = 0
if not cases or not fns:
    print("  [FAIL] parsed %d dispatcher case(s) and %d gate function(s) — a zero here means the"
          % (len(cases), len(fns)))
    print("     patterns stopped matching, not that the file is empty. A broken check, not a pass.")
    sys.exit(1)
for n in sorted(set(listed) - cases - {'all'}):
    print("  [FAIL] usage advertises '%s' but no dispatcher case runs it" % n); bad += 1
for n in sorted(cases - set(listed)):
    print("  [FAIL] dispatcher case '%s' is missing from the usage banner (undiscoverable)" % n); bad += 1
for n in sorted(fns - used):
    print("  [FAIL] %s() is defined but never invoked — defined, documented and never run" % n); bad += 1
for n in sorted({x for x in listed if listed.count(x) > 1}):
    print("  [FAIL] usage lists '%s' more than once" % n); bad += 1
if bad:
    print("  [FAIL] %d dispatch/usage disagreement(s)" % bad); sys.exit(1)
print("  [ok]   %d usage names, %d dispatcher cases, %d gate functions — all three agree"
      % (len(set(listed)) - 1, len(cases), len(fns)))
DISPATCH_PY
  } | python3 - <(bash scripts/doc_gates.d/logical_source.sh) || return 1
  # LEG 4 (2026-09-26): the `all` PASS banner names every gate `all` runs. MEASURED that day: its
  # hard list stopped at 77 while `all` also ran 79-91, and it omitted 2c and 24 (24's own
  # promotion note below the banner said it was "in the hard list above"; it was not). A green
  # banner that names less than ran under-reports; one that names a gate `all` never runs (8,
  # or the unused number 78) over-attests. So the list is checked against the dispatcher:
  #   (a) every GATE id reached from the `all` arm (each called gate_* function's `== GATE <id>`
  #       header lines; a wrapper with no header resolves through the gate_* functions it calls)
  #       is named in the banner, as hard or as report-only;
  #   (b) every id the banner names is reached (a lettered id such as 5b counts when its base is
  #       reached; a base such as 10 counts when a lettered child such as 10a is);
  #   (c) no id is named both hard and report-only; every list item parses.
  # Then four in-memory mutants of the logical source must each be caught: the last id dropped from the
  # hard list, a new headed gate added to `all`, 78 added to the hard list, 13 added to it.
  { _sp_prelude; cat <<'BANNER_PY'
import re, sys
real = open(sys.argv[1], encoding='utf-8', errors='surrogateescape').read()
# Pieces, never whole: the whole strings must not occur in this file, or the search finds THIS
# code instead of the dispatcher (the self-reference trap recorded at LEG 1-3 above).
ALL_ARM = re.compile(r'^\s*' + 'all' + r'\)\s+gate_\w+', re.M)
USAGE = '*) echo "usage: $' + '0 {'
LIST = 'hard gates' + ' only: '
def ids_of(seg, where, bad):
    out = set()
    for item in [x.strip() for x in seg.split(',') if x.strip()]:
        m = re.fullmatch(r'(\d+[a-z]?)(?:\s*\((.*)\))?', item)
        if not m:
            bad.append("banner %s item %r does not parse as `<id>` or `<id> (<note>)`" % (where, item)); continue
        out.add(m.group(1)); note = (m.group(2) or '').strip()
        if note.startswith('incl.'):
            out |= set(re.findall(r'\b\d+[a-z]\b', note))
        elif re.fullmatch(r'[a-z](?:\+[a-z])+', note):
            out |= {m.group(1) + c for c in note.split('+')}
    return out
_CMDS = {}
def _cmds_of(text):
    if text not in _CMDS:
        try:
            _CMDS[text] = sp_sh_commands(text)
        except SpError as e:
            raise SystemExit("  [FAIL] LEG 4: could not lex a dispatcher body (%s)" % e)
    return _CMDS[text]
def check(src):
    bad = []
    arms = list(ALL_ARM.finditer(src))
    if len(arms) != 1:
        return ["found %d `all` dispatcher arm(s) where exactly 1 is expected" % len(arms)], None
    try:
        arm = src[arms[0].start():src.index(USAGE, arms[0].start())]
    except ValueError:
        return ["the `all` arm has no usage arm after it; cannot bound it"], None
    defs = [(m.group(1), m.start()) for m in re.finditer(r'^(gate_\w+)\(\)\s*\{', src, re.M)]
    body = {n: src[s:(defs[k + 1][1] if k + 1 < len(defs) else len(src))] for k, (n, s) in enumerate(defs)}
    # Q-970 (A07#18): the `all` arm and the bodies are read as COMMANDS (shell lexer): a commented-out
    # `# echo; gate_x || RC=1` in the arm ran nothing and still counted as reaching gate_x's id.
    def reach(fn, seen):
        if fn in seen or fn not in body:
            return set()
        seen.add(fn)
        cmds = _cmds_of(body[fn])
        own = {m.group(1) for _l, w in cmds if w[0].value == 'echo'
               for m in [re.match(r'== GATE (\d+[a-z]?)\b', " ".join(x.value for x in w[1:]))] if m}
        if own:
            return own
        r = set()
        for c in [w[0].value for _l, w in cmds if w[0].value.startswith('gate_')]:
            r |= reach(c, seen)
        return r
    reached = set()
    for fn in [w[0].value for _l, w in _cmds_of(arm) if w[0].value.startswith('gate_')]:
        got = reach(fn, set())
        if not got:
            bad.append("`all` calls %s, which has no `== GATE <id>` header, directly or through what it calls" % fn)
        reached |= got
    lines = [l for l in src.split('\n') if LIST in l and 'DOC GATES: PASS' in l]
    if len(lines) != 1:
        return bad + ["found %d PASS banner line(s) naming the hard list where exactly 1 is expected" % len(lines)], None
    head, _, tail = lines[0].partition(LIST)
    hard_seg, sep, ro_seg = tail.partition('. Gates ')
    if not sep:
        return bad + ["the banner's hard list is not followed by `. Gates <report-only list>`"], None
    hard = ids_of(hard_seg, 'hard-list', bad)
    ro = ids_of(ro_seg.rstrip('"').strip(), 'report-only', bad)
    if not reached or not hard:
        return bad + ["reached %d gate id(s), banner names %d hard: a zero is a broken parse, not agreement"
                      % (len(reached), len(hard))], None
    base = lambda x: re.match(r'\d+', x).group(0)
    named = hard | ro
    for x in sorted(reached, key=lambda v: (int(base(v)), v)):
        if x not in named and not (x != base(x) and base(x) in named and base(x) not in reached):
            bad.append("GATE %s runs in `all` but the PASS banner names it neither hard nor report-only" % x)
    for x in sorted(named, key=lambda v: (int(base(v)), v)):
        if x not in reached and base(x) not in reached and not any(base(r) == x for r in reached):
            bad.append("the PASS banner names GATE %s, which `all` does not run" % x)
    for x in sorted(hard & ro):
        bad.append("the PASS banner names GATE %s as hard AND as report-only" % x)
    return bad, (len(reached), len(hard), len(ro))
bad, n = check(real)
for b in bad:
    print("  [FAIL] LEG 4: " + b)
if bad:
    print("  [FAIL] LEG 4: %d disagreement(s) between the `all` arm and its PASS banner" % len(bad)); sys.exit(1)
print("  [ok]   LEG 4: `all` reaches %d gate id(s); the PASS banner names %d hard + %d report-only, and they agree" % n)
arm_at = ALL_ARM.search(real).start()
call = 'echo; gate_zz' + '_mutant || ' + 'RC=1\n           '
fn = '\ngate_zz' + '_mutant() {\n  echo "== GATE ' + '99: mutant =="\n}\n'
cut = real.index('\n', arm_at) + 1
line = [l for l in real.split('\n') if LIST in l and 'DOC GATES: PASS' in l][0]
# The anchor is the LAST id of the hard list, read from the line, not a literal: until 2026-09-26 it
# was ', 91. Gates', so adding GATE 92 to the banner made M1, M3 and M4 report "did not apply".
_last = re.search(r', (\d+)\. Gates', line)
_tail = ', %s. Gates' % _last.group(1) if _last else '\0no-anchor'
MUTANTS = [
    ("M1 the last hard gate (%s) dropped from the hard list" % (_last.group(1) if _last else '?'), real.replace(line, line.replace(_tail, '. Gates'))),
    ("M2 a new headed gate added to `all`", real[:cut] + '           ' + call + real[cut:] + fn),
    ("M3 78 added to the hard list", real.replace(line, line.replace(_tail, _tail[:-len('. Gates')] + ', 78. Gates'))),
    ("M4 report-only 13 added to the hard list", real.replace(line, line.replace(_tail, _tail[:-len('. Gates')] + ', 13. Gates'))),
]
miss = 0
for label, src in MUTANTS:
    if src == real:
        print("  [FAIL] LEG 4 %s: the mutation did not apply (its anchor moved); the mutant proves nothing" % label); miss += 1
    elif check(src)[0]:
        print("  [ok]   LEG 4 %s: caught" % label)
    else:
        print("  [FAIL] LEG 4 %s: NOT caught" % label); miss += 1
sys.exit(1 if miss else 0)
BANNER_PY
  } | python3 - <(bash scripts/doc_gates.d/logical_source.sh) || return 1
}

# ---------------------------------------------------------------------------
# GATE 82 — no published figure may be fed from the QUOTIENT marginal frame
# (`quotient-frame-isolation`).
#
# 🔴 WHY. The atlas publishes each layer's marginals in TWO frames, canonical-quotient and raw. The
# engine's own gate checks only that each frame's layer TOTAL equals N, and a total is blind to mass
# moved between pairs, so a quotient distribution can be wrong in every cell and still pass. The
# cross-frame oracle (`verify.py --check-atlas-orbit-frames`) closes part of this, but it compares
# ORBIT AGGREGATES: it catches mass moved ACROSS orbits and, by its own stated limit, NOT mass moved
# WITHIN one. So a quotient cell can be wrong with no instrument able to say so.
#
# Closing that properly needs an independent reimplementation of the canonical-quotient labelling —
# real mathematical software, not a script. Before paying for it, Q-57 asked the cheap question
# first: does any PUBLISHED figure actually read quotient cells? Measured 2026-09-04, none does, and
# the reason is stronger than a convention:
#
#   THE TWO FRAMES USE DISJOINT KEY NAMESPACES. A quotient cell is "q<N>"; a raw cell is "pair<N>".
#   V1, the positional-marginal field, is fed by `grep -o '"marginal_raw": {[^}]*}'` and extracts
#   '"pair[0-9]*"', so it is STRUCTURALLY incapable of reading a quotient cell — not merely
#   instructed not to. V5 and Q6 do match '"marginal_quotient"', but only as a LINE SELECTOR to pick
#   out layer objects; they then read `flow` and `by_class.dN`, each of which occurs exactly once per
#   layer line, so their greedy `.*` extractors are unambiguous.
#
# That measurement is a snapshot, and a snapshot is what this gate turns into a standing fact. The
# exposure is bounded only while V1's feeder stays `marginal_raw` and no figure extractor learns to
# read a "q<N>" key. Both are one careless edit away, and the failure would be silent: a contaminated
# field plots without complaint.
#
# NOTE ON SCOPE, because the gate must not be read as more than it is: this bounds the EXPOSURE, it
# does not verify the quotient frame. The within-orbit gap is real and stays open. What is asserted
# is only that nothing published depends on it.
# ---------------------------------------------------------------------------
gate_quotient_frame_isolation() {
  echo "== GATE 82: no published figure is fed from the quotient marginal frame =="
  local rc=0 f="scripts/tr12_repro.sh"
  if [ ! -r "$f" ]; then
    echo "  [FAIL] $f is unreadable — cannot check the figure feeders."
    echo "     An unreadable driver is not an absent risk; refusing to report OK."
    return 1
  fi

  # (1) V1's feeder must be the RAW frame. Look at the block, not the whole file: the header comment
  #     claiming RAW is not evidence, the `done < <(...)` line that actually feeds the loop is.
  local v1_feed
  v1_feed=$(awk '/row_begin c_v1/{i=1} i&&/done < </{print; exit}' "$f")
  if [ -z "$v1_feed" ]; then
    echo "  [FAIL] could not locate V1's feeder line in $f (block renamed or restructured?)"
    rc=1
  elif grep -q 'marginal_raw' <<<"$v1_feed"; then
    echo "  [ok]   V1 positional-marginal field is fed from marginal_raw"
  else
    echo "  [FAIL] V1's feeder is NOT marginal_raw:"
    echo "           $(printf '%s' "$v1_feed" | sed 's/^ *//')"
    echo "     V1 is the positional-marginal FIGURE. Fed from the quotient frame it would plot cells"
    echo "     that no instrument can check within an orbit (Q-57), and it would look correct."
    rc=1
  fi

  # (2) No figure extractor may read a quotient CELL key. The namespaces are disjoint — "q<N>" is
  #     quotient, "pair<N>" is raw — so this is a decidable check rather than a judgement call.
  #     Q-970 (A07#19, Q-835 Codex review; adjudicated Q-962): THE EXTRACTORS ARE READ AS COMMANDS AND
  #     THEIR PATTERNS ARE RUN. `grep -o[^|]*"q\[0-9\]` saw one spelling; `grep -Eo '"q[0-9]+"'`, `-oE`,
  #     `--only-matching`, `egrep -o`, `-e PAT` and `\d` all read the same cells unseen. Now every
  #     grep/egrep/fgrep/zgrep/rg command in the battery (shell lexer, src_parse.sh; comments are not
  #     commands; $(..) and <(..) are entered) that prints only the matching part has each of its
  #     patterns run by grep in the command's own dialect (-E/-P/-F/-G) against sample quotient
  #     cells, and a pattern that extracts a "q<N>" key is a HIT. NOT SEEN, stated: an expansion
  #     inside a pattern (it is replaced by a string that matches nothing, and COUNTED below), and
  #     extractors that are not grep (awk, sed, python, jq).
  local qcell
  qcell=$( { _sp_prelude; cat <<'QPY'
import re, subprocess, sys
try:
    cmds = sp_sh_commands(open(sys.argv[1], encoding="utf-8").read())
except (OSError, SpError) as e:
    print("ERROR\t%s" % e); sys.exit(0)
SAMPLES = '"q0"\n"q12": 3\n{"q31": 7, "q2": 1}\n'
# A pattern that ALSO extracts a raw cell or an ordinary key is a generic key reader, not a quotient
# reader (`grep -o '^[[:space:]]*"[A-Za-z0-9_]*":' "$cert"` lists a certificate's keys); only a
# pattern that extracts quotient cells and nothing of these is a HIT. Generic readers are out of scope.
GENERIC = '"pair12": 3\n"flow": 1\n{"pair3": 7, "by_class": 1}\n'
VALUED = set("mABCfd")
n = nexp = 0
for ln, w in cmds:
    tool = w[0].value.rsplit("/", 1)[-1]
    if w[0].quoted or tool not in ("grep", "egrep", "fgrep", "zgrep", "rg"):
        continue
    mode = {"egrep": "-E", "fgrep": "-F", "rg": "-P"}.get(tool, "-G")
    only, pats, rest, i, a = False, [], [], 0, w[1:]
    while i < len(a):
        v = a[i].value
        if v == "--":
            rest += a[i + 1:]; break
        if v in ("-e", "--regexp") and i + 1 < len(a):
            pats.append(a[i + 1]); i += 2; continue
        if v.startswith("--"):
            only |= v == "--only-matching"
            mode = {"--extended-regexp": "-E", "--perl-regexp": "-P", "--fixed-strings": "-F",
                    "--basic-regexp": "-G"}.get(v, mode)
        elif v.startswith("-") and len(v) > 1 and a[i].lit():
            for k, c in enumerate(v[1:]):
                only |= c == "o"
                mode = "-" + c if c in "EPFG" else mode
                if c == "e" or c in VALUED:
                    tail = v[k + 2:]
                    if c == "e":
                        pats.append(a[i + 1] if not tail and i + 1 < len(a) else None)
                    i += 0 if tail else 1
                    break
        else:
            rest.append(a[i])
        i += 1
    if not pats and rest:
        pats = [rest[0]]
    if not only:
        continue
    n += 1
    for pw in pats:
        if pw is None:
            continue
        if not pw.lit():
            nexp += 1
        pat = "".join(t if k == "lit" else "\x01\x02" for t, k in pw.parts)
        r = subprocess.run(["grep", mode, "-o", "--", pat], input=SAMPLES, capture_output=True, text=True)
        g = subprocess.run(["grep", mode, "-o", "--", pat], input=GENERIC, capture_output=True, text=True)
        if r.returncode == 2:
            print("HIT\t%d\tgrep cannot read this pattern, so what it extracts is unknown: %s" % (ln, pat))
        elif r.returncode == 0 and re.search(r'"q[0-9]+"', r.stdout) and g.returncode != 0:
            print("HIT\t%d\t%s" % (ln, " ".join(x.raw for x in w)[:160]))
print("POP\t%d\t%d" % (n, nexp))
QPY
  } | python3 - "$f")
  local qpop qexp
  IFS=$'\t' read -r _ qpop qexp < <(printf '%s\n' "$qcell" | grep '^POP' | head -1)
  if grep -q '^ERROR' <<<"$qcell"; then
    echo "  [FAIL] the figure feeders in $f could not be lexed: $(printf '%s\n' "$qcell" | grep '^ERROR' | cut -f2-)"
    rc=1
  elif ! grep -qxE '[0-9]+' <<<"${qpop:-}" || [ "$qpop" -lt 1 ]; then
    echo "  [FAIL] zero only-matching grep extractors found in $f — the reader stopped reading them"
    rc=1
  elif grep -q '^HIT' <<<"$qcell"; then
    echo "  [FAIL] a figure extractor reads quotient cell keys (\"q<N>\"):"
    printf '%s\n' "$qcell" | awk -F'\t' '$1=="HIT"{print "           '"$f"':" $2 ": " $3}'
    rc=1
  else
    echo "  [ok]   no figure extractor reads a \"q<N>\" quotient cell key ($qpop only-matching grep(s) run against sample cells; $qexp pattern(s) carry an expansion that was not followed)"
  fi

  # (3) The three standing prohibitions must still be present. They are how a future reader learns
  #     the rule at the point of use; deleting one is how the rule gets forgotten.
  # Written out one literal at a time, deliberately. A loop over "file:text" pairs would put the
  # assertion strings behind a variable, and GATE 16 caveat (k) is explicit that an assertion it
  # cannot read as a whole string literal is a FAIL — correctly, since a substring it cannot resolve
  # is a substring it cannot check for preflight collisions. Three lines of repetition is the price
  # of an auditable assertion, and it is worth paying. (Measured 2026-09-04: the loop form also
  # collided on the variable name `text`, putting 109 unrelated `$text` sites across this file under
  # the rule — the collision that caveat names, observed.)
  local missing=0
  if [ ! -r solve.py ]; then
    echo "  [FAIL] solve.py unreadable — cannot confirm its prohibition survives"; missing=1
  elif ! grep -qF 'marginal_quotient must NOT be plotted' solve.py; then
    echo "  [FAIL] solve.py no longer carries its prohibition"; missing=1
  fi
  if [ ! -r viz/viz_kc_grammar.md ]; then
    echo "  [FAIL] viz/viz_kc_grammar.md unreadable — cannot confirm its prohibition survives"; missing=1
  elif ! grep -qF 'Do not plot the quotient marginals' viz/viz_kc_grammar.md; then
    echo "  [FAIL] viz/viz_kc_grammar.md no longer carries its prohibition"; missing=1
  fi
  if [ ! -r viz/viz_kc_field.md ]; then
    echo "  [FAIL] viz/viz_kc_field.md unreadable — cannot confirm its prohibition survives"; missing=1
  elif ! grep -qF 'be plotted as this field' viz/viz_kc_field.md; then
    echo "  [FAIL] viz/viz_kc_field.md no longer carries its prohibition"; missing=1
  fi
  [ "$missing" -eq 0 ] && echo "  [ok]   all three in-tree prohibitions still present"
  [ "$missing" -ne 0 ] && rc=1
  return $rc
}

# ---------------------------------------------------------------------------
# GATE 81 — registered CONTENT invariants still hold (`tree-invariants`).
#
# WHY (measured 2026-09-04): the v4-query-program merge REVERTED a landed security fix and it sat on
# public main for ~3 hours. main had quoted `rm -rf '%s'` at all six regress sites in solve.c; the
# merge took OURS at two hunks and the unquoted form returned. Two independent post-merge analyses
# reported no such reversion, because both compared PATHS and solve.c is a changed path either way.
#
# A fix is a fact about CONTENT, so the check must be about content. This gate asserts registered
# facts directly against the tree and does not care how the tree got there. A merge cannot argue
# with a grep.
gate_tree_invariants() {
  echo "== GATE 81: registered content invariants still hold =="
  local REG=documentation/TREE_INVARIANTS.tsv bad=0 n=0
  if [ ! -r "$REG" ]; then
    echo "  [FAIL] $REG is unreadable — an unread invariant registry is NOT an empty one."
    return 1
  fi
  while IFS=$'\t' read -r pat max paths why; do
    case "${pat:-}" in ''|\#*) continue;; esac
    [ -n "${max:-}" ] && [ -n "${paths:-}" ] || { echo "  [FAIL] malformed row: ${pat:0:40}"; bad=1; continue; }
    n=$((n+1))
    # 🔴 THREE WAYS THIS GATE USED TO PASS WITHOUT MEASURING ANYTHING (Codex review A8R,
    # adjudicated 2026-09-04; all three reproduced before this block was written). A gate whose
    # ONLY job is to notice a silently reverted fix must never be satisfied by its own emptiness.
    #
    #   (i)  a `paths` value that selects no tracked file -> no grep runs -> got=0 -> "[ok]";
    #   (ii) a `pattern` that is not a valid ERE -> grep exits 2, prints nothing -> got=0 -> "[ok]";
    #   (iii) a `max` that is not a number -> `[ 0 -gt abc ]` errors and takes the ELSE branch.
    #
    # Each is now a FAIL, not a pass, and the [ok] line reports how many files were actually read
    # so the reader can see the measurement rather than infer it.
    case "$max" in ''|*[!0-9]*)
      echo "  [FAIL] invariant '${pat:0:40}': ceiling '$max' is not a number. \`[ -gt \`"
      echo "         errors on it and takes the OK branch, so the row would never fail."
      bad=1; continue;;
    esac
    local grc=0
    printf '' | grep -qE -- "$pat" 2>/dev/null || grc=$?
    if [ "$grc" -gt 1 ]; then
      echo "  [FAIL] invariant '${pat:0:40}': not a valid ERE (grep exit $grc). An uncompilable"
      echo "         pattern counts zero matches everywhere, which reads as a held invariant."
      bad=1; continue
    fi
    local files nfiles unread
    files=$(git ls-files -- $paths 2>/dev/null)
    if [ -z "$files" ]; then
      echo "  [FAIL] invariant '${pat:0:40}': paths '$paths' select ZERO tracked files."
      echo "         An invariant that examined no file is not an invariant that holds."
      bad=1; continue
    fi
    nfiles=$(printf '%s\n' "$files" | wc -l | tr -d ' ')
    unread=$(printf '%s\n' "$files" | while IFS= read -r f; do [ -r "$f" ] || printf 'x'; done | wc -c | tr -d ' ')
    if [ "$unread" -ne 0 ]; then
      echo "  [FAIL] invariant '${pat:0:40}': $unread of $nfiles selected file(s) unreadable."
      echo "         An unread file is NOT a file with no matches."
      bad=1; continue
    fi
    local got
    got=$(printf '%s\n' "$files" | xargs -r grep -cE -- "$pat" 2>/dev/null | awk -F: '{s+=$NF} END{print s+0}')
    case "${got:-}" in ''|*[!0-9]*) echo "  [FAIL] invariant '${pat:0:40}': could not count over '$paths'"; bad=1; continue;; esac
    if [ "$got" -gt "$max" ]; then
      echo "  [FAIL] invariant VIOLATED: '$pat' appears $got time(s) in $paths, ceiling $max"
      echo "         $why"
      echo "         🔴 Do NOT raise the ceiling to clear this. The ceiling is a census, not a budget."
      bad=1
    else
      echo "  [ok]   '$pat' — $got of at most $max across $nfiles file(s) in $paths"
    fi
  done < "$REG"
  # A registry that matched nothing is a gate that checks nothing. Say so rather than pass.
  if [ "$n" -eq 0 ]; then
    echo "  [FAIL] $REG declares zero invariants — this gate checked NOTHING."
    return 1
  fi
  [ "$bad" -eq 0 ] || return 1
  echo "  [ok] $n registered invariant(s) hold"
  return 0
}

gate_tracked_ignored() {
  echo "== GATE 23: no tracked file is also ignored =="
  local out rc n
  # stdout ONLY: a stderr warning on a SUCCESSFUL run must not be printed as a path.
  out=$(git ls-files -i -c --exclude-standard 2>/dev/null); rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "  [FAIL] 'git ls-files -i -c --exclude-standard' exited $rc — the check did NOT run,"
    echo "         so this is not a clean bill of health."
    git ls-files -i -c --exclude-standard 2>&1 >/dev/null | sed 's/^/           > /' | head -3
    return 1
  fi
  if [ -n "$out" ]; then
    n=$(printf '%s\n' "$out" | wc -l)
    printf '%s\n' "$out" | sed 's/^/  [FAIL] tracked AND ignored: /'
    echo "         $n path(s). Each keeps shipping while the next file added beside it is"
    echo "         skipped by 'git add' in silence — partial publication with no error."
    echo "         Narrow the ignore rule, or untrack the path on purpose."
    return 1
  fi
  echo "  [ok] no tracked path matches an ignore rule"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 24 — documented VALUE DOMAINS match the literal domain in code.
#
# WHY THIS EXISTS (measured, 2026-08-09). GATE 2 compares the SET OF FLAG NAMES in
# code against the set documented. It never inspects what VALUES a flag accepts.
# So when solve.c's f1c5_unions[] was extended from 9 to 18 rung sizes, three
# documented "N in {...}" sets went stale and `doc_gates.sh cli` returned PASS,
# rc=0, with all four files reported "fully documented". The defect was injected
# deliberately and the gate was watched not to fire; the stale sites were then
# found and fixed by hand. This gate closes that class.
#
# WHY IT IS A DECLARED REGISTRY, NOT A SCANNER. Auto-discovering every "X in {...}"
# in prose and hunting a matching literal in code is where false positives live:
# illustrative sets, ranges, ellipses, and sets that legitimately differ from code.
# doc_gates is wired into pre-push as BLOCKING, so a false positive does not annoy,
# it stops a push. Every pair checked here is therefore declared explicitly. A new
# domain is opted IN by adding a row; nothing is inferred.
#
# PROMOTED INTO 'all' ON 2026-09-04, and this is the note that used to say it sat out.
# It sat out "by caution, not oversight" from 2026-08-09, with the stated promotion
# criterion "observed silent across a full corpus for a while". That criterion is met:
# four weeks in-tree, silent, and re-derived twice since (Codex N10 finding 12 on
# 2026-09-03; Codex A8R item 3 on 2026-09-04).
#
# 🔴 THE EXCLUSION WAS HALF OF A LIVE DEFECT, WHICH IS WHY IT ENDS NOW. A8R found two
# `supported:` lists in solve.c that disagreed. This gate's check was a SINGULAR
# `re.search`, so it matched the first (correct) copy and could never reach the stale one
# — and it did not run on the default sweep, so it would not have looked either way. Both
# halves were repaired in one pass: the check is `re.findall` over every spelling of the
# domain, and the gate is in `all`. Fixing the string without fixing the gate would have
# left the next divergence exactly as invisible.
#
# COST: measured 0.10 s. It is a pure-Python read of solve.c and two markdown files, so it
# is not in GATE 8's excluded-by-cost class and never was.
gate_value_domains() {
  echo "== GATE 24: documented value-domain sets match the literal domain in code =="
  { _wm_prelude; cat <<'PY'
import re, sys

FAIL = 0

# --- the one declared domain ------------------------------------------------
# solve.c carries the accepted --f1-pairs domain in THREE places that must agree:
#   (a) the f1c5_unions[] table (all sizes except the full 31),
#   (b) the "supported: ..." error string printed when an unsupported N is given, and
#   (c) the SEPARATE BRANCH that admits the full pair set without a table row.
# The authoritative code-side domain is  table ∪ {whatever (c) admits}.
#
# CODEX N10 FINDING 12, adjudicated 2026-09-03: (c) USED TO BE THE LITERAL `{31}`, WRITTEN
# HERE. This gate's own title is "documented value-domain sets match the LITERAL DOMAIN IN
# CODE", and for the one value that is not a table row it supplied the answer itself instead of
# reading it. Codex demonstrated the consequence: change solve.c's branch to `npairs == 30`,
# leave the table, the error string and the docs untouched, and the gate still passed and still
# claimed 31 was accepted — a gate reporting on a code behaviour it had hardcoded, which is the
# verifier-closure defect (the witness came from the checker, not from the subject).
# The branch is now PARSED. If it cannot be found the gate FAILS rather than assuming a value:
# a domain this gate cannot locate is a domain it did not check.
try:
    src = open("solve.c", encoding="utf-8", errors="replace").read()
except OSError as exc:
    print("  [FAIL] cannot read solve.c, so ZERO domains were checked: %s" % exc)
    sys.exit(1)

m = re.search(r"f1c5_unions\[\]\s*=\s*\{(.*?)\n\};", src, re.S)
if not m:
    print("  [FAIL] f1c5_unions[] table not found in solve.c — this gate checked NOTHING.")
    print("         If the table was renamed, update this gate; do not delete the check.")
    sys.exit(1)
table = sorted(int(x) for x in re.findall(r"\{\s*(\d+)\s*,\s*\"", m.group(1)))
if not table:
    print("  [FAIL] f1c5_unions[] parsed to ZERO rows — vacuous, treated as failure.")
    sys.exit(1)

# CODEX A8R ITEM 3, adjudicated 2026-09-04: THIS WAS A SINGULAR `re.search`. solve.c carried
# SIX statements of this domain and FIVE of them were stale; a `re.search` matched the first
# (correct) one and stopped, so every disagreeing copy was invisible BY CONSTRUCTION. A8R found
# one of the five. The other four were found by sweeping the siblings while repairing it:
#
#   f1c5_exact_main() "supported:"   3,4,6,7,9,10,12,13,15,16,18,19,21,22,24,25,27,28,31  ok
#   kc_g_resolve_pairs() "supported:"          9,13,   16,18,19,21,22,24,25,27,28,31      stale
#   kc_resolve_pairs() "orbit-realizable"      9,13,   16,18,19,21,22                     stale
#   --f1-exact-c1c2c4c5 usage "N in {}"        9,13,   16,18,19,      24,25,27,28,31      stale
#   --f1-c3-hist usage "N in {}"               9,13,   16,18,19,      24,25,27,28,31      stale
#   the #221 header comment "N in {}"          9,13,   16,18,19,      24,25,27,28,31      stale
#
# FIVE of the six are now PRINTED from f1c5_unions[] by f1c5_fprint_npairs_domain() and cannot
# drift at all; the sixth is a comment, which cannot be printed, so it stays a literal and is
# enforced here. The gate therefore checks BOTH halves:
#   (i)  the printer exists and is wired to the table  -- a domain that is typed is a domain
#        that will drift, and its absence is a FAIL, not a pass; and
#   (ii) EVERY surviving literal set, found with re.findall in both spellings, agrees.
#
# LIMIT, STATED. (i) is a STRUCTURAL read of the printer's source, not an execution of it:
# this gate does not build solve.c. It asserts the loop is over f1c5_unions[], that the
# appended special value matches the branch parsed above, and that the cap parameter is
# honoured. A printer that satisfies all three and still mis-formats its output would pass
# here and fail a human reading `solve --f1-c3-hist`.
LITERALS = []          # (label, sorted values, source snippet)
for m2 in re.finditer(r'"supported:\s*([0-9,]+)\\n"', src):
    LITERALS.append(('"supported: ..." string', m2.group(1)))
for m2 in re.finditer(r"N\s*(?:∈|in)\s*\{([0-9,\s]+)\}", src):
    LITERALS.append(('"N in {...}" set', m2.group(1)))
for m2 in re.finditer(r"orbit-realizable n <= %?d?[^\"]*?:\s*([0-9][0-9,\s]*[0-9])\)", src):
    LITERALS.append(('"orbit-realizable ...: " set', m2.group(1)))

m4 = re.search(r"#define\s+KC_MEM_MAX_PAIRS\s+(\d+)", src)
if not m4:
    print("  [FAIL] KC_MEM_MAX_PAIRS was not found in solve.c. It is the one LEGITIMATE")
    print("         narrowing of this domain (the in-memory --kc-build ceiling), so without")
    print("         it a correct narrower list cannot be told from a stale one.")
    sys.exit(1)
mem_cap = int(m4.group(1))

# (c) the separate branch. `full<N> = (npairs == <V>)`: N is what the code CALLS the case and
# V is what it actually admits, so a mutation of the comparison alone (Codex's exact
# construction) shows up as the two disagreeing, and a mutation of both still moves the domain
# and is caught against the error string and the docs below.
m3 = re.search(r"int\s+full(\d+)\s*=\s*\(\s*npairs\s*==\s*(\d+)\s*\)\s*;", src)
if not m3:
    print("  [FAIL] the full-pair-set branch (`int full<N> = (npairs == <V>);`) was not found in")
    print("         solve.c, so the one domain value that is NOT a table row could not be read.")
    print("         This gate used to hardcode it. Re-anchor the pattern; do not restore a")
    print("         literal — a value supplied by the checker is not a measurement of the code.")
    sys.exit(1)
special_name, special = int(m3.group(1)), int(m3.group(2))
if special_name != special:
    print("  [FAIL] solve.c disagrees with ITSELF: the full-pair-set flag is named full%d but the"
          % special_name)
    print("         branch admits npairs == %d. One of the two was edited alone." % special)
    FAIL = 1

code_domain = sorted(set(table) | {special})
capped_domain = sorted(x for x in code_domain if x <= mem_cap)

# --- (i) the domain must be PRINTED from the table, not typed ---------------------------
mp = re.search(r"static void f1c5_fprint_npairs_domain\s*\([^)]*\)\s*\{(.*?)\n\}", src, re.S)
if not mp:
    print("  [FAIL] f1c5_fprint_npairs_domain() was not found in solve.c, so the accepted")
    print("         --f1-pairs domain is being TYPED at every site again. That is the exact")
    print("         state that let five of six copies go stale. If the printer was renamed,")
    print("         re-anchor this pattern; do not delete the check.")
    sys.exit(1)
body = wm_strip_comments(mp.group(1), "c")   # Q-966: every check below reads CODE, not comments
if "f1c5_unions" not in body:
    print("  [FAIL] f1c5_fprint_npairs_domain() does not read f1c5_unions[] -- it prints a")
    print("         domain from somewhere other than the table that defines it.")
    FAIL = 1
# Q-966 (A07#21): "cap-aware" means the cap FILTERS: a whole-word `cap` inside an `if (...)` whose body
# skips the row (continue / break / return), read from the comment-stripped body above. A bare
# substring test passed `... > cap) (void)0;`, which mentions cap and filters nothing.
if not re.search(r"\bif\s*\([^;{}]*\bcap\b[^;{}]*\)\s*(?:\{\s*)?(?:continue|break|return)\b", body):
    print("  [FAIL] f1c5_fprint_npairs_domain() ignores its `cap` argument, so --kc-build's")
    print("         in-memory ceiling of %d would be advertised as accepted." % mem_cap)
    FAIL = 1
mf = re.search(r'with_full31.*?"%s(\d+)"', body, re.S)
if not mf:
    print("  [FAIL] f1c5_fprint_npairs_domain() has no `with_full31` literal, so the one")
    print("         domain value that is NOT a table row is not printed at all.")
    FAIL = 1
elif int(mf.group(1)) != special:
    print("  [FAIL] the printer appends %s for the full pair set but the branch admits %d."
          % (mf.group(1), special))
    FAIL = 1
if not FAIL:
    print("  [ok] the --f1-pairs domain is PRINTED from f1c5_unions[] by"
          " f1c5_fprint_npairs_domain() (+%d, cap-aware), not typed" % special)

# --- (ii) every SURVIVING literal statement of the domain must agree --------------------
if not LITERALS:
    print("  [note] no literal --f1-pairs domain set survives in solve.c -- every statement is")
    print("         printed from the table. Nothing to compare; leg (i) is the whole check.")
for label, raw in LITERALS:
    got = sorted(int(x) for x in raw.replace(" ", "").split(",") if x.strip())
    if got == code_domain:
        print("  [ok] solve.c %s == f1c5_unions[] + the full-pair branch's {%d} (%d values)"
              % (label, special, len(got)))
    elif got == capped_domain:
        print("  [ok] solve.c %s == the domain capped at KC_MEM_MAX_PAIRS=%d (%d values)"
              % (label, mem_cap, len(got)))
    else:
        print("  [FAIL] solve.c disagrees with ITSELF: %s lists" % label)
        print("         %s" % ",".join(map(str, got)))
        print("         but f1c5_unions[] + the full-pair branch give")
        print("         %s" % ",".join(map(str, code_domain)))
        print("         (capped at KC_MEM_MAX_PAIRS=%d that would be %s)"
              % (mem_cap, ",".join(map(str, capped_domain))))
        FAIL = 1

# --- the doc sites that publish that domain ---------------------------------
# Declared explicitly. Each must contain the domain as a comma-separated set.
DOC_SITES = [
    "documentation/SOLVE_C_CLI.md",
    "reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md",
]
want = ",".join(map(str, code_domain))
checked = 0
for path in DOC_SITES:
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError as exc:
        print("  [FAIL] declared doc site unreadable: %s (%s)" % (path, exc))
        FAIL = 1
        continue
    # Any "N ∈ {...}" / "N in {...}" set of bare integers in this file is a
    # publication of the domain and must match it exactly.
    sets = re.findall(r"N\s*(?:∈|in)\s*\{([0-9,\s]+)\}", text)
    if not sets:
        print("  [FAIL] %s declares no 'N ∈ {...}' set — either the site moved (update this"
              % path)
        print("         registry) or the publication was dropped. Not silently tolerated:")
        print("         a declared site that matches nothing is how a gate checks nothing.")
        FAIL = 1
        continue
    for s in sets:
        got = ",".join(x.strip() for x in s.split(",") if x.strip())
        checked += 1
        if got != want:
            print("  [FAIL] %s publishes N ∈ {%s}" % (path, got))
            print("         but solve.c accepts   %s" % want)
            FAIL = 1

if not checked and not FAIL:
    print("  [FAIL] zero doc sets were compared — vacuous, treated as failure.")
    FAIL = 1

if not FAIL:
    print("  [ok] %d documented set(s) across %d declared site(s) match the code domain"
          % (checked, len(DOC_SITES)))
sys.exit(1 if FAIL else 0)
PY
  } | python3 -
  local rc=$?
  if [ "$rc" != "0" ]; then
    echo "  A documented value domain drifted from the code that enforces it."
    echo "  GATE 2 cannot see this: it compares flag NAMES, never accepted VALUES."
    return 1
  fi
  return 0
}

