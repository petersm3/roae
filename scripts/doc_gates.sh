#!/usr/bin/env bash
# doc_gates.sh — mechanical documentation-integrity gates.
#
# WHY THIS EXISTS
#   The code layer has hard gates (canonical sha, compile gate, tests.py, DRAT certs).
#   The DOC layer had none, so doc-level defects depended on review luck. On 2026-08-01
#   two full adversarial AI review passes cleared the repo and a third found ~20 real
#   defects — including a retracted claim still stated on the README front page, hidden
#   because a revision entry *asserted* the correction had propagated. These gates turn
#   that class of failure from "hope a reviewer notices" into "the script fails".
#
# USAGE
#   scripts/doc_gates.sh numbers    # cross-file numeric consistency (long integers)
#   scripts/doc_gates.sh cli        # CLI flags live in code but absent from the CLI docs
#   scripts/doc_gates.sh retract    # GATE 3: retracted phrasings that still survive in the corpus
#   scripts/doc_gates.sh retract-figures  # GATE 3b: retracted FIGURES (statistics) restated with no
#                                   # supersession marker; content-anchored allowlist, no auto-exemption
#   scripts/doc_gates.sh links      # GATE 4 + 4b: internal markdown links/#anchors, then section refs
#   scripts/doc_gates.sh links-internal   # GATE 4 ALONE — internal links/#anchors (self-test target)
#   scripts/doc_gates.sh secrefs    # GATE 4b ALONE — plain-text `FILE.md §"..."` references (self-test target)
#   scripts/doc_gates.sh status     # GATE 5: canonical quantities whose exact/estimate status
#                                   # drifted, + GATE 5b: a canonical quantity restated with NO
#                                   # marker among siblings that carry one
#   scripts/doc_gates.sh figures    # retracted phrasing in figure GENERATORS (rendered text is ungreppable)
#   scripts/doc_gates.sh liveness   # frozen present-tense run status; runs named after unreached budgets
#   scripts/doc_gates.sh banner     # the TR banner is byte-identical across every report + index-aligned
#   scripts/doc_gates.sh appendonly # GATE 10a + 10b: CORRECTIONS.md has lost no committed line
#   scripts/doc_gates.sh appendonly-head    # GATE 10a ALONE — vs HEAD (self-test target)
#   scripts/doc_gates.sh appendonly-history # GATE 10b ALONE — vs every historical/published
#                                   # version, not just HEAD (self-test target)
#   scripts/doc_gates.sh ledger     # every RETRACTED_PHRASES.tsv row, and every
#                                   # RETRACTED_FIGURES.tsv row, is recorded in CORRECTIONS.md
#   scripts/doc_gates.sh ledger-figures  # GATE 11's FIGURES pass ALONE (self-test target)
#   scripts/doc_gates.sh ledger-phrases  # GATE 11's PHRASES pass ALONE (self-test target)
#   scripts/doc_gates.sh revrows    # GATE 13: a TR body edit carries a revision row (REPORT-ONLY)
#   scripts/doc_gates.sh revhist    # GATE 12: TR revision tables — one *(current)* and last, no repeated
#                                   # released version, dates and versions ascending
#   scripts/doc_gates.sh regdupes   # GATE 14: two literature-registry rules that are the same predicate
#   scripts/doc_gates.sh instruments # GATE 15: a --selftest instrument with no declared fire-proof,
#                                   # and (LEG 2) a fire-proof its own source text could satisfy
#   scripts/doc_gates.sh collisions # GATE 16: a per-gate assertion a PREFLIGHT could satisfy,
#                                   # and (LEG 2) a fire-proof naming a dispatch that runs
#                                   # more than one gate
#   scripts/doc_gates.sh alias-reach # GATE 18: a ruled "read X as Y" / legacy-naming alias
#                                   # used with no same-line path to the ruling that resolves
#                                   # it — or (kind `attrib`, 2026-08-06) a SUPERSEDED
#                                   # ATTRIBUTION restated with no path to its correction;
#                                   # registry-driven, open-backlog adjudicated
#   scripts/doc_gates.sh branch-registry # GATE 19: every branch ON THE REMOTE (git ls-remote, not
#                                   # the refs/remotes cache) is declared in
#                                   # documentation/BRANCH_REGISTRY.tsv; a remote that cannot be
#                                   # listed FAILS (offline opt-in documented in the gate header)
#   scripts/doc_gates.sh repro-reach # GATE 25: LEG 1 (hard) a documented reproduction command
#                                   # naming a flag that does not exist — the doc->code direction
#                                   # GATE 2 misses; and LEG 2 (REPORT-ONLY, never affects rc) a
#                                   # doc that publishes a measured figure and names no way to
#                                   # re-derive it. NOT in `all` — by caution, per its header.
#   scripts/doc_gates.sh withdrawn-markers # GATE 27: a registered WITHDRAWN figure restated with
#                                   # no supersession marker — table rows judged PER ROW, prose per
#                                   # blank-line paragraph (a marker on the wrapped next line
#                                   # counts); the judged population is printed and zero FAILS
#   scripts/doc_gates.sh rotation-c3      # GATE 30: a pair-slot rotation-symmetry claim that
#                                   # does not name C3 (flattened; claim SHAPE, not a string)
#   scripts/doc_gates.sh sk-gains   # GATE 31: the S(k) gain lists must agree on their maximum,
#                                   # the divisor must BE that maximum, and a first/greedy
#                                   # maximum claim must say "unconditional"
#   scripts/doc_gates.sh fiber-anchor # GATE 32: the orientation-fiber anchors — a published
#                                   # factorization/sum must equal what its own sentence states,
#                                   # and the per-key orientation exponent is 2^31, not 2^32
#   scripts/doc_gates.sh superlative # GATE 33: "strongest measured ... discriminator" with no
#                                   # temporal or category qualifier (flattened; the qualified
#                                   # twin in CITATIONS.md spans a hard wrap)
#   scripts/doc_gates.sh printed-quotient # GATE 34: a published xratio must equal the quotient
#                                   # printed beside it, at the ratio's own precision
#   scripts/doc_gates.sh stale-status # GATE 35: a pending-status word surviving beside the dated
#                                   # update that completed it. POPULATION = ONE heading today
#   scripts/doc_gates.sh se-vs-ci   # GATE 37: a relative STANDARD ERROR published as a +- band,
#                                   # caught by arithmetic: the band equals log2(1+r), not log2(1+1.96r)
#   scripts/doc_gates.sh dvd24-scope # GATE 38: a mod-24 divisibility claim stated as an
#                                   # UNRESTRICTED UNIVERSAL. The theorem quantifies over a
#                                   # duplicate-free complete listing of the RECORD-level set;
#                                   # sequence-level counts sit in orbits of 48
#   scripts/doc_gates.sh p14-claims # GATE 39: the four claim-to-artifact legs Codex V2
#                                   # prescribed — LEG 1 cert-claims-shipped (every named
#                                   # .drat is archived AND in verify_all.sh's map), LEG 2
#                                   # four-five-labels (grander-strict is five rules,
#                                   # grand-ccn4 four), LEG 3 se-claims-have-se (an SE claim
#                                   # must be true of the evidence file it names), LEG 4 the
#                                   # n-ladder integers are orientation-explicit, not canonical
#   scripts/doc_gates.sh mi-disambig # GATE 40: a --mutual-info citation explained by the
#                                   # complete Latin square must name the STATIC 8-state MI —
#                                   # the square forces that one and not the transition MI
#   scripts/doc_gates.sh cell-space # GATE 41: 65,281 is the PRODUCTIVE 41.2% subset, not the
#                                   # 158,364-cell depth-3 space, and is not G-closed
#   scripts/doc_gates.sh band-status # GATE 42: the x15-17 weakest-remaining-boundary band must
#                                   # be labelled illustrative everywhere it is published, the
#                                   # figure GENERATOR included (rendered legends are ungreppable).
#                                   # NOT the literal-presence check charge 14 prescribed — that
#                                   # shape inverts on its own inputs; see the gate's header
#   scripts/doc_gates.sh anchor-coverage # GATE 43: an exact estimator-calibration anchor cannot
#                                   # land in METHODS without moving TR-4's live "Coverage: N of N"
#   scripts/doc_gates.sh report-verdict # GATE 44: a null spectrum verdict contradicted by the
#                                   # report shipped beside it. Reads example/report.txt as an
#                                   # INPUT (the corpus widening the charge asked for); ERRORs
#                                   # rather than passing if that summary line cannot be read
#   scripts/doc_gates.sh net-brackets # GATE 45: a ledger row's published Net bracket must be its
#                                   # compression minus each of its cost figures, at the row's own
#                                   # printed precision (TR-9 + DESCRIPTION_LENGTH ledgers)
#   scripts/doc_gates.sh history-scope # GATE 46: HISTORY.md's findings table may not carry a
#                                   # scope-free universal Status against 31.6M-dataset Evidence
#                                   # (a Status that scopes itself, or is superseded, passes)
#   scripts/doc_gates.sh code-needles # GATE 47: the registry's retracted phrasings in every tracked
#                                   # NON-markdown text file (solve.c, *.py, *.sh, *.lean, data) —
#                                   # the 128-file corpus GATE 3 never scanned; allowances name
#                                   # file + phrase + max count + withdrawal anchor
#                                   # (documentation/DOC_GATE_CODE_NEEDLE_ALLOW.tsv); an unused
#                                   # allowance FAILS
#   scripts/doc_gates.sh sha-prediction # GATE 48: a sha change asserted for a NAMED prune must be
#                                   # hedged (can/may) or evidenced (byte-identical / a sha)
#   scripts/doc_gates.sh parity-figures # GATE 49: every figure in PARITY_ALTERNATION.md is printed
#                                   # by --check-parity-alternation (run here) or sits beside its
#                                   # named reproducer / CITATIONS source
#   scripts/doc_gates.sh file-drawer # GATE 50: a document pricing C(91,k)/C(95,k) against the
#                                   # observable ledger cites METHODS §The file drawer
#   scripts/doc_gates.sh seed-provenance # GATE 51: a positive "independent draws/seeds" claim in a
#                                   # report cites evidence whose SEED OVERRIDE bases differ
#   scripts/doc_gates.sh unrepeatable-cite # GATE 52: a CITATIONS entry recorded as 404 + zero
#                                   # captures is hedged in every paragraph that cites it
#   scripts/doc_gates.sh branch-list # GATE 53: LARGE_SCALE_CAMPAIGNS.md's (pair, orient) split sums
#                                   # to 56 and names no dead pair (0, 4, 6, 21)
#   scripts/doc_gates.sh index-fidelity # GATE 54: every tracked documentation/*.md is an index-row
#                                   # link target in documentation/README.md; reading times >= words/300
#   scripts/doc_gates.sh sha-tuple  # GATE 55: a "function of (...)" enumeration of the sha inputs
#                                   # names all four registry inputs (CANONICAL_HASHES §Reproducibility)
#   scripts/doc_gates.sh log-derived-figures # GATE 56: a figure a doc attributes to a tracked
#                                   # analyze log's §[3]/§[6]/§[9] is that log's own figure (dataset-keyed)
#   scripts/doc_gates.sh nontrivial-display # GATE 57: an indented/fenced display equation never has identical sides (x = x)
#   scripts/doc_gates.sh witness-count    # GATE 58: '(N independent paths):' equals its table's row count; 11.2T restatements agree
#   scripts/doc_gates.sh baseline-arithmetic # GATE 59: 'K of the N … ineligible, so the baseline is 1/M' has M = N-K; adjudicated-open sites in DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv print [OPEN]
#   scripts/doc_gates.sh derived-coefficient # GATE 60: CAMPAIGN_METHODOLOGY's zero-cell % and .bin-per-cell coefficient equal its own actuals table
#   scripts/doc_gates.sh cpu-vendor       # GATE 61: a CPU vendor is paired only with its own microarchitecture family (no 'Intel Zen')
#   scripts/doc_gates.sh az-name-closure  # GATE 62: every az resource DEPLOYMENT.md shows/deletes/attaches was created in its section or is pre-existing
#   scripts/doc_gates.sh glossary-consistency # GATE 63: every definition of 'node' in BRANCHES_EXPLAINED.md names the frame (registered-term list)
#   scripts/doc_gates.sh identifying-set-arity # GATE 64: 'C1–C5/C1–C7 plus N' agrees with BOUNDARY_MINIMUM.md's greedy-set sizes (C6/C7 are inside them)
#   scripts/doc_gates.sh stdlib-claims    # GATE 65: a 'stdlib only' claim naming a file with third-party imports carries a scope word
#   scripts/doc_gates.sh lean-header-verbatim # GATE 66: TRIGRAM_STRUCTURE.md's 'verbatim' ledger block IS lean/TrigramTheorems.lean's header
#   scripts/doc_gates.sh evidence-type-vocabulary # GATE 67: PARTITION_INVARIANCE.md evidence types from a closed vocabulary; 'every scale' needs every row direct
#   scripts/doc_gates.sh theorem-vs-slice # GATE 68: SPECIFICATION.md's '(d=1 vs d=3)' wrap enumeration names d=5 or scopes itself to the slice
#   scripts/doc_gates.sh chronology-access # GATE 69: a CITATIONS.md 'could not have read' clause never rests on a year inside the author's life-range
#   scripts/doc_gates.sh viz-shape        # GATE 87: viz/report_figures.py --selftest -- the TR-12 TSV shape guards fire
#   scripts/doc_gates.sh layer-profile    # GATE 70: TR-11's per-layer footprint table equals FULL31_EXACT_AGGREGATES.md's layer GB at printed precision
#   scripts/doc_gates.sh boundary-scope   # GATE 75: a mandatoriness claim over boundary SETS is scoped to the subset size actually exhausted (C(31,4)), not to depth
#   scripts/doc_gates.sh merge-semantics  # GATE 76: prose may not deny a merge capability solve.c's env surface (SOLVE_MERGE_MODE/CHUNK_GB) provides
#   scripts/doc_gates.sh cert-inventory   # GATE 77: certificates/README.md's "Full inventory: N certificates" equals the archived .drat corpus, and verify_all.sh's CERT_FLOOR equals it too
#   scripts/doc_gates.sh atlas-probe-tokens # GATE 90: SOLVE_PY_CLI.md's --atlas-probe token list equals atlas_probe()'s tok()/gate() names in print order (verdict ATLAS_PROBE_TOKEN_LIST)
#   scripts/doc_gates.sh history-index # GATE 91: documentation/HISTORY_INDEX.md is a fresh output of scripts/history_index.sh, and that script's --selftest mutants fire, as do history_currency_gate.sh --selftest's (verdicts HISTORY_INDEX, HISTORY_CURRENCY_SELFTEST)
#   scripts/doc_gates.sh claim-ledger # GATE 92: every row of documentation/CLAIMS.tsv (the typed claim ledger, Q-296; TR-12's headline figures) is on its cited line and re-derived by its evidence, a conditional-on figure carries its premise in the same sentence, and scripts/claim_ledger.sh --selftest's mutants fire (verdicts CLAIM_LEDGER, CLAIM_LEDGER_SELFTEST)
#   scripts/doc_gates.sh lsd-text # GATE 93: the TEXT fixes of the Codex Lean/SAT/DRAT adversarial review (CX-232) stay fixed: retired wordings absent from scripts, a golden, solve.c and a run page; scoping clauses and citations present on the lines that need them; TR-2's certificate count equals the directory (verdict LSD_TEXT_GATE)
#   scripts/doc_gates.sh retract-derived # GATE 94 (ADVISORY, REPORT-ONLY, Q-884 GAP-1): quoted withdrawn phrasings derived from CORRECTIONS.md that RETRACTED_PHRASES.tsv does not register; verdict RETRACT_DERIVED=PASS|ADVISORY n=<k>; never affects the exit status
#   scripts/doc_gates.sh transcripts # GATE 95 (review-loop Q29, leg I): every shell transcript (a `$ ` prompt line plus output in a fenced block) in a tracked *.md outside example/ has a row in documentation/DOC_GATE_TRANSCRIPTS.tsv that classifies it, and every row matches a block (verdicts TRANSCRIPTS_N, TRANSCRIPTS_GATE)
#   scripts/doc_gates.sh generated  # generated artifacts still match their generator (3 roae.py runs,
#                                   # ~67 s measured 2026-08-07, ~107-135 s on earlier recorded runs;
#                                   # NOT in `all` — by cost; the PASS banner states what that excludes,
#                                   # and pre_push_gate.sh runs this leg when the pushed range touches
#                                   # roae.py or example/)
#   scripts/doc_gates.sh all        # run every cheap gate; `generated` is separate by cost.
#                                   # DE-NUMBERED, round 17. This read "all fifteen cheap gates
#                                   # (1-7 incl. 3b, 9, 10, 11, 12, 13, 14, 15, 16)" and was wrong
#                                   # on BOTH available counting units, omitting 4b, 5b and 17.
#                                   # There is no single right number to substitute, and that is
#                                   # the point: a `gate_` FUNCTION and a `== GATE` BANNER are
#                                   # different counting units and their totals differ. Count
#                                   # whichever one you actually mean:
#                                   #   awk '/^  all\)/,/;;$/' scripts/doc_gates.sh \
#                                   #     | grep -oE 'gate_[a-z_]+' | sort -u | wc -l
#                                   #   scripts/doc_gates.sh all \
#                                   #     | grep -oE '^== GATE [0-9a-b]+' | sort -u | wc -l
#                                   # The dispatch arm at the foot of this file is the only list.
#   scripts/doc_gates.sh --selftest # mutation-test the gates themselves (requires a clean tree)
#
# EXIT: 0 = clean, 1 = findings. Report-only classes print [WARN]; hard failures print [FAIL].
# SOME GATES ARE REPORT-ONLY by construction — they always `return 0` / `sys.exit(0)`, so their
# findings never reach RC and are NOT covered by the "DOC GATES: PASS" banner. WHICH ones is
# deliberately NOT listed here: the banner literal at the foot of this file is the maintained
# copy, and unlike a comment it is EXECUTED on every green `all` run, so it cannot drift unseen.
# (This read "GATES 1 and 5" until round 17 and had not moved when 5b, 13 and GATE 17's LEG B
# joined the set — the same drift as "GATE 8's five legs" below, and it pointed at a banner that
# already said something wider.)
#
# SAFETY: index-based (`git ls-files`/`git grep`) and fixed-string matching only.
#   No `find` over trees, no bounded-repetition regex (`.{0,N}`) — a pathological
#   `grep -oE ".{0,80}X.{0,60}"` hung the 2-core orchestrator on a 381-byte input
#   (2026-08-01); cost lives in the PATTERN, not only the data.

#@ Q-797 (2026-09-25): THIS FILE IS SPLIT, and it is still the only entry point.
#@ The gate functions live in scripts/doc_gates.d/NN_*.sh; each `. scripts/doc_gates.d/... # DG-MODULE`
#@ line below sources one of them at the exact position its text used to occupy. `#@` lines like
#@ these are split commentary. The LOGICAL SOURCE -- this file with every DG-MODULE line replaced by
#@ its module and every `#@` line dropped -- is what the self-reading gates (15, 16, 47, 83, 89) and
#@ the --selftest fire-proofs read, and it is line-for-line the pre-split file: print it with
#@   bash scripts/doc_gates.d/logical_source.sh
#@ A line number quoted by a gate as `scripts/doc_gates.sh:N` is a line of the logical source.
#@ Q-971 (c) (2026-10-03, batch 40): GIT_NO_REPLACE_OBJECTS=1 is exported on the `set` line so a
#@ refs/replace/* entry cannot change what any gate reads from git (see scripts/pre_push_gate.sh,
#@ "Q-971 (c)"); same line, so the logical source keeps its line numbers.
set -uo pipefail; export GIT_NO_REPLACE_OBJECTS=1
cd "$(dirname "$0")/.." || exit 2
RC=0

# example/ was excluded here until 2026-08-01. That is a CONTAINER-level exemption — the same
# construction that let the retracted "hard floor k >= 13" survive in TR-4's body while its
# changelog narrated the retraction. Exempt a construction, never a directory.
# 🔴 Q-284. This was `DOCS=$(git ls-files '*.md' || true)`. A failed enumeration left DOCS
# EMPTY and every consumer then saw a corpus of zero documents and reported it clean -- and
# DOCS feeds ten sites across GATES 1, 3, 8 and 13, so ONE failure silently disarms four
# gates at once. Measured with a stand-in `git` that exits 128 on ls-files: the gates examine
# zero files and report clean. `|| true` cannot distinguish "the corpus contains no markdown"
# from "the corpus could not be read", and only one of those is a passing condition.
DOCS=$(git ls-files '*.md')
if [ $? -ne 0 ]; then
  echo "  [FAIL] cannot enumerate the markdown corpus (git ls-files failed) — NOTHING was checked." >&2
  exit 2
fi
if [ -z "$DOCS" ]; then
  echo "  [FAIL] the markdown corpus is EMPTY — that is not a clean tree, it is an unreadable one." >&2
  exit 2
fi

# ----------------------------------------------------------------------------------
# ITEM A1 (2026-08-02) — WHAT EVERY GATE DOES WITH A MISSING INPUT.
#
# EVERY LEG OF GATE 8 used to `[skip]` a deleted git-tracked artifact, so `rm example/report.pdf`
# passed in silence. (This sentence read "GATE 8's five legs" until round 15 drain-3, then six,
# and the legs are named rather than counted because a bare multiplicity is not checkable by a
# reader against the code and a named list is: legs 1-4 are `_cmp` on example/report.txt,
# report.md, README.md and report.html; LEG 6 is README.md as a byte-identical copy of
# report.md; LEG 7 is the seven non-report artifacts under example/, byte-exact. LEG 6 arrived
# with item A2 on the SAME DAY this sentence was written and the tally never moved with it;
# LEG 7 landed 2026-09-02 and it did not move either. De-numbered, not bumped.
#   LEG 5 IS RETIRED, 2026-09-04. It compared example/report.pdf against example/report.html
#   by multiset. The PDF was deleted from the repository that day because wkhtmltopdf embedded
#   the COMPLETE UNSUBSETTED DejaVu font programs in it (`pdffonts`: DejaVuSans,
#   DejaVuSans-Bold, DejaVuSansMono, all `emb yes sub no`), which made a public-domain
#   repository a redistributor of font software under the Bitstream Vera terms; roae.py's
#   export_html no longer shells out to wkhtmltopdf, so no PDF is produced to compare.
#   THE NUMBER 5 IS NOT REUSED: leg numbers here are identifiers that fire-proof labels and
#   this header both cite, and renumbering 6 and 7 down would silently repoint every one of
#   those citations at a different check. A gap in the numbering is the cheaper signal.
#   WHAT THE RETIREMENT COST, stated because a removal that only says what it deleted is the
#   over-attestation this file exists to refuse: LEG 5 was the ONLY leg that compared
#   example/report.html DIGIT-FOR-DIGIT. It could be strict where legs 1-4 then could not,
#   because it compared two artifacts of ONE `--html` invocation rather than a shipped
#   artifact against a fresh UNSEEDED run. report.html therefore joined report.txt and
#   report.md as digit-blind, and a hand-edited number in it was caught by nothing -- the
#   dbba77d class returning, measured on the live tree (`8x8 = 64` -> `65`, rc 0, PASS).
#   AND WHAT CLOSED IT, THE SAME DAY: the fix named under Q2 at LEG 5's old site was an
#   operator decision about published artifacts, and the operator took it. example/ was
#   regenerated and reshipped under `--seed 20260904`; legs 1-4 are BYTE-EXACT against a
#   same-seed regeneration; self-test CASE 6 is reinstated on the identical mutation, now
#   asserting leg 4 rather than the deleted leg 5. The cost paragraph is left standing rather
#   than deleted because the hole was real while it lasted, and because the close is the
#   evidence that this file's habit of writing gaps down is what got them fixed.)
# That was fixed and proven on 2026-08-02; the same question was then asked
# of GATES 2, 3, 3b, 6, 10a, 10b and 11, and every one of them had the same shape. MEASURED,
# not reasoned: with `documentation/CORRECTIONS.md` deleted from the working tree,
#   scripts/doc_gates.sh retract  ->  "DOC GATES: PASS (retract)", rc 0
#   scripts/doc_gates.sh ledger   ->  "[skip] ... absent" then "DOC GATES: PASS", rc 0
# GATE 3's only trace was a bash redirect error on stderr (line 145), and the self-test harness
# runs each gate with `2>&1 >/dev/null` — so that trace is invisible to the one instrument that
# would have caught it.
#
# TWO SEPARATE HOLES, and the second is the one that matters:
#   (a) PER-GATE. Each gate that opens a named registry or ledger skipped on `! -f`.
#       `require_tracked` below turns that into a FAIL when git tracks the path.
#   (b) CORPUS-WIDE, and INVISIBLE. `$DOCS` is `git ls-files '*.md'` — an INDEX listing. A
#       tracked .md deleted from the working tree stays in `$DOCS`, and its consumers do NOT
#       all fail the same way — so this paragraph deliberately names NO list and gives NO
#       tally. The dispositions are maintained in exactly ONE place, `preflight_tracked_docs`'s
#       header below, and each of them was measured rather than read off the code.
#       (Until round 17 this read "every consumer (GATES 3, 3b, 4, 4b, 5, 5b, 9) then reads it
#       as EMPTY ... one deletion blinds seven gates at once". That is the PRE-round-16 list.
#       Round 16 measured it wrong in both directions and corrected the message the preflight
#       PRINTS — but not this copy, nor the one at the `collisions` fire-proof, because no
#       census query could see a hardcoded list written NOUN-FIRST. A third copy is exactly how
#       it drifted; there is now one.)
#       The reason this is a corpus-level preflight rather than per-gate `[ -f ]` tests is
#       GATE 1: it reads a missing file as empty SILENTLY, so it is the consumer for which
#       nobody would have thought to write a per-gate test.
#
# WHAT THIS STILL CANNOT SEE, stated rather than implied: absence of a TOOL.
# `python3` and `sha256sum` absence are FAILs because each voids a whole gate, but neither
# carries a mutation fire-proof — hiding one tool from `$PATH` without also hiding `git`,
# `grep` and `cut` cannot be done cleanly, so those two legs are asserted by reading, not by
# running. That is a weaker warrant than every other leg here and is recorded as such.
#   THE ONE TOOL-ABSENCE `[skip]` THIS PARAGRAPH USED TO NAME IS GONE, and it went in the
#   direction the paragraph wanted: it read "`pdftotext` absence remains a `[skip]` (poppler
#   is not part of the toolchain this repo requires)", and the only caller of pdftotext was
#   GATE 8 LEG 5, retired 2026-09-04 with example/report.pdf. No gate now degrades to a
#   `[skip]` on a missing tool. That is a narrowing of this caveat, NOT a widening of
#   coverage — LEG 5's checking went with it; see the gate's own header for what it cost.
#
# require_tracked <path> [remedy-line]
#   rc 0 = present; rc 1 = absent and NOT tracked (a legitimate skip, printed); rc 2 = tracked
#   but absent (a FAIL, printed). Callers must map rc 2 onto their own failure variable.
# 🔴 THE RESIDUAL HOLE, closed 2026-09-05 (fail-open class sweep, S-01). "Not tracked" was read as
# "never shipped", but a COMMITTED rename or `git rm` also leaves the path untracked — and from
# that commit on, every gate anchored to the old name printed `[skip]` and `DOC GATES: PASS`,
# forever. Measured before the fix in a scratch clone: `git mv documentation/CITATIONS.md
# documentation/CITATIONS_v2.md && git commit`, then `doc_gates.sh chronology-access` -> [skip] +
# rc 0. That is the anchor-moved fail-open, at one helper with ~46 call sites. The distinction
# that matters is HISTORY, not the index: a path that has ever been committed and is now gone
# was retired or renamed, and the gate that names it must be retargeted or retired WITH it.
# `git log -- <path>` answers that in one call; a path with no history at all (a fresh fixture
# tree, a skeleton) is still a legitimate skip.
#   KNOWN LIMITATION: a shallow clone (`--depth N`) truncates history, so a path deleted before
#   the shallow boundary reads as never-tracked and skips. Fresh full clones and the working
#   clones this project runs are not shallow; `git rev-parse --is-shallow-repository` tells.
require_tracked() {
  [ -f "$1" ] && return 0
  if git ls-files --error-unmatch -- "$1" >/dev/null 2>&1; then
    echo "  [FAIL] $1 is tracked in git but missing from the working tree"
    echo "         ${2:-A gate whose input is absent has checked nothing. Absence of a tracked input is the strongest possible mismatch, not a reason to skip.}"
    return 2
  fi
  local _last
  _last=$(git log -1 --format='%h %ad' --date=short -- "$1" 2>/dev/null)
  if [ -n "$_last" ]; then
    echo "  [FAIL] $1 is absent AND untracked, but it HAS history (last touched $_last): it was"
    echo "         renamed or removed in a commit. The gate that names it has been checking nothing"
    echo "         since. Retarget the gate to the new path, or retire the gate in the same commit."
    return 2
  fi
  echo "  [skip] $1 absent (never tracked in this clone's history, so nothing shipped is being checked)"
  return 1
}

# 🔴 Q-283 / Codex N10 finding 4 — reproduced on the PUBLISHED suite 2026-08-27. require_tracked
# proves a registry EXISTS; it does not prove the registry has any ROWS, and the shared newline
# guard explicitly accepts an empty file. So emptying a registry makes its gate iterate nothing and
# return clean. Measured: with a zero-row RETRACTED_PHRASES.tsv, GATE 3 printed its header and
# NOTHING ELSE — not "[ok]", not "[FAIL]" — and the suite exited 0. That is worse than a false
# "[ok]": in a long log a silent gate reads as one that ran and had nothing to say.
# A registry is never legitimately empty here (23 / 11 / 61 rows today), so zero rows is a defect.
require_rows() { # $1=registry  $2=why it matters
  local f="$1" n
  # 🔴 Q-702 (2026-09-24, Fable K). Every call site of this guard runs it BEFORE `require_tracked`,
  # and on a MISSING file `grep -c` reports 0 — so a tracked registry deleted from the worktree
  # was reported as "has ZERO rows", and the A1 arm ("is tracked in git but missing") that
  # GATE 3's and 3b's (A1) fire-proofs assert on was unreachable at every site (GATES 3, 3b, 27,
  # 47 and alias-reach; GATE 27 has no require_tracked call at all). Measured on 5c296837: both
  # (A1) legs RED with `never names "... is tracked in git but missing"`. The fix is here rather
  # than a re-ordering at five sites, so the next site cannot get the order wrong: an ABSENT
  # file is require_tracked's question, not a row count. Only a tracked-or-historical absence is
  # delegated (rc 2 there); a file that never existed still reads as ZERO rows, exactly as before.
  if [ ! -f "$f" ]; then
    local _rt
    require_tracked "$f" "$2"; _rt=$?
    [ "$_rt" -eq 2 ] && return 1
    # _rt = 1: never tracked, [skip] already printed — fall through to the ZERO-rows verdict.
  fi
  # A row is what reg_row_kind calls one (Q-773 follow-up): not blank, and column 1 (leading tabs dropped, as
  # `read` drops them) is neither exactly `#` nor starts `# `. A row starting `#7` counts; the old `grep -cvE` count dropped it.
  n=$(reg_rows_count "$f")
  if [ "${n:-0}" -eq 0 ]; then
    echo "  [FAIL] $f has ZERO rows. A registry with no rows SILENCES its gate rather than"
    echo "         passing it: the loop iterates nothing and returns clean. $2"
    return 1
  fi
  return 0
}

# reg_rows_count <registry> — the row count require_rows judges, as one number (0 for an unreadable file).
#   Q-969 (R5 of the Q-962 adjudication, Codex Q835 lens A): a parser that drops a row it cannot read
#   (a one-column row, a `#rule` row, an extra cell) still let require_rows count it, so the floor passed
#   while the leg checked less than the file holds. A reader that consumes a registry passes this count
#   in (as argv[1]) and FAILS when the rows it ACCEPTED differ from it; see reg_accepted_check.
reg_rows_count() {
  local n
  n=$(awk -F'\t' '{ s = $0; sub(/^\t+/, "", s); split(s, c, "\t") } s ~ /^[[:space:]]*$/ { next } c[1] == "#" || c[1] ~ /^# / { next } { n++ } END { print n + 0 }' "$1" 2>/dev/null)
  echo "${n:-0}"
}
# reg_accepted_check <registry> <accepted> <gate> — rc 0 when a parser accepted exactly the rows
#   reg_rows_count sees; otherwise a [FAIL] naming both counts, rc 1. A row the parser could not read
#   is a row the gate silently stopped enforcing, so the mismatch is the defect, not a warning.
reg_accepted_check() {
  local want; want=$(reg_rows_count "$1")
  [ "$2" = "$want" ] && return 0
  echo "  [FAIL] Q-969: $3 accepted $2 row(s) of $1, which holds $want data row(s). A row the parser"
  echo "         cannot read is one this gate stopped checking; fix the row (or the parser), do not drop it."
  return 1
}

# reg_row_kind <loud|quiet> <col1> [col2 ...]
#   Q-761 (2026-09-24, Opus FF). What is a COMMENT in the two retracted-string registries
#   (RETRACTED_PHRASES.tsv, RETRACTED_FIGURES.tsv, and the figure open-list keyed on them)?
#   Every consumer here asked `case "$phrase" in '#'*) continue`, i.e. "does the NEEDLE start
#   with #". So a registered retraction whose needle begins with a hexagram number ('#7/#8, ...')
#   was skipped as a comment: GATE 3 printed no `[ok] retracted` line for it, GATE 11 printed no
#   `RP-... recorded` line, and the run was RC 0. Opus DD's first needle was ignored exactly so.
#
#   "A comment is a line whose WHOLE LINE starts with #" cannot separate the two, because the
#   needle IS the start of the line. The files' own header convention does: all 101 comment
#   lines in RETRACTED_PHRASES.tsv and all of RETRACTED_FIGURES.tsv's are `#` alone or `# `
#   (hash, SPACE) — measured 2026-09-24, zero exceptions. So:
#     comment  = column 1 is exactly `#`, or starts with `# `
#     data row = anything else, INCLUDING a needle starting `#7`, `#12`, `#` + non-space
#   The one form still indistinguishable is a needle that itself starts `# ` (a markdown heading
#   marker). That cannot be matched, so it is made LOUD instead: a `# `-shaped line carrying a
#   later tab-separated column that is not a `<placeholder>` (the header's own FORMAT template,
#   `#   <retracted fixed string>\t<file ...>\t<note>`, is all placeholders) is a data row written
#   in comment shape, and in `loud` mode it is a [FAIL]. Register such a needle without the `# `.
#   Returns 0 = skip (blank or comment), 1 = data row, 2 = ambiguous (skip; FAIL printed if loud).
reg_row_kind() {
  local mode="$1" c1="$2" c; shift 2
  [ -z "$c1" ] && return 0
  case "$c1" in
    '#'|'# '*)
      for c in "$@"; do
        case "$c" in ''|'<'*'>') ;;
          *) if [ "$mode" = loud ]; then
               echo "  [FAIL] Q-761: a registry line is comment-shaped (\"# ...\") but carries data column(s):"
               echo "         \"$c1\"  ->  \"$c\""
               echo "         A needle starting with \"# \" cannot be told from a comment, so it is not checked."
               echo "         Register it without the leading \"# \", or drop the tab-separated columns."
             fi
             return 2 ;;
        esac
      done
      return 0 ;;
  esac
  return 1
}

# HASHED NEEDLES (CX-230, 2026-09-29). A retracted phrase that carries a dollar figure is
# registered in RETRACTED_PHRASES.tsv as `sha256:<64 hex>/<n>` rather than as text: the digest of
# the phrase (UTF-8, no newline) and its length in characters. The dollar figures left the current
# tree on the operator's decision, and a fixed-string row would restate one. The RP key is the
# first 8 hex digits of that digest, which is the key the text row had, so GATE 11 finds the same
# ledger entry. hashed_needle_hits scans whitespace-flattened text and hashes the n-character span
# that starts at every dollar sign, so a hashed phrase must begin with `$`. Unlike a text row it
# matches the exact registered spelling only (fold_variants is not applied: the needle is not
# available to fold). GATE 3 and GATE 47 read hashed rows; every other reader sees a needle that
# occurs nowhere.
# hashed_row_parse <col1> — rc 0 and prints "<hex> <n>" for a hashed row; rc 1 for a text row.
hashed_row_parse() {
  case "$1" in sha256:*/*) ;; *) return 1;; esac
  local h="${1#sha256:}" n; n="${h#*/}"; h="${h%%/*}"
  [[ "$h" =~ ^[0-9a-f]{64}$ && "$n" =~ ^[1-9][0-9]*$ ]] || return 1
  printf '%s %s\n' "$h" "$n"
}
# hashed_needle_hits <hex> <n> <file>... — prints `file:line` for every hit, `file(unreadable)` for a
#   file it could not read. Lines are those of the unflattened file.
hashed_needle_hits() {
  python3 - "$@" <<'PY'
import hashlib, sys
h, n, files = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
for f in files:
    try:
        raw = open(f, encoding="utf-8", errors="surrogateescape").read()
    except OSError:
        print("%s(unreadable)" % f); continue
    if "$" not in raw: continue
    flat, where, ln, prev = [], [], 1, ""   # the gates' flatten: newline -> space, runs of spaces collapse
    for ch in raw:
        c = " " if ch == "\n" else ch
        if not (c == " " and prev == " "): flat.append(c); where.append(ln)
        prev = c
        if ch == "\n": ln += 1
    s = "".join(flat); i = s.find("$")
    while i >= 0:
        if hashlib.sha256(s[i:i + n].encode("utf-8", "surrogateescape")).hexdigest() == h:
            print("%s:%d" % (f, where[i]))
        i = s.find("$", i + 1)
PY
}

# require_final_newline <path>
#   Every registry in this suite is consumed by `while read`, and `read` returns non-zero on
#   a final line with no terminator — so the shell loop DROPS it. A registered retraction or
#   figure appended without a trailing newline would silently stop being checked, and the
#   gate would print [ok] with a smaller count than the file has rows. Nobody reads the
#   count. MEASURED 2026-08-02: all three registries currently end in \n, so this guard is a
#   tripwire on a hazard that has not fired yet, not a fix for a live defect.
#   rc 0 = terminated; rc 1 = not (printed as a FAIL by the caller's rc mapping).
#
#   SECOND ARGUMENT `quiet` (item A6, 2026-08-02) suppresses the message so a caller can
#   print its own. It exists for exactly one reason and the reason is load-bearing: the
#   A6 preflight below checks every support file, INCLUDING the two registries GATE 11
#   checks itself, and GATE 11's fire-proof asserts on the literal string
#   "RETRACTED_FIGURES.tsv does not end with a newline". If the preflight printed that same
#   sentence, the assertion would be satisfied by the preflight and would no longer prove
#   GATE 11's leg fired at all — the shared-dispatch defect that item A3 fixed for GATE 4b
#   and item A7 for GATE 10a, reintroduced through a shared MESSAGE instead of a shared exit
#   code. The preflight's wording ("gate-support file has no final newline: <f>") therefore
#   shares no substring with this one.
require_final_newline() {
  [ -f "$1" ] || return 0                     # absence is require_tracked's business
  [ -s "$1" ] || return 0
  if [ "$(tail -c1 "$1" | od -An -c | tr -d ' \n')" = '\n' ]; then
    return 0
  fi
  [ "${2:-}" = quiet ] && return 1
  echo "  [FAIL] $1 does not end with a newline"
  echo "         Its last row is dropped by every \`while read\` that consumes it, so that"
  echo "         row is registered and unchecked. Append a newline."
  return 1
}

# Q-952 (Codex push-path review Q835, P-05, 2026-10-03) — THE VERDICT READER for a child gate.
# The wrappers in doc_gates.d/ read `grep -qx 'KEY=PASS' <<<"$out"` and nothing else, so a child
# that printed its PASS line and then crashed (rc 139), was killed (137), timed out (124), or
# printed a later KEY=FAIL still read as PASS. PASS now needs all three: the child exited 0, it
# printed exactly one ^KEY= line, and that line is KEY=<want>.
#   $1 KEY   $2 the wanted value (PASS, CURRENT)   $3 the captured output   $4 the child's rc
#   rc 0 PASS.  rc 1 not PASS; when the token alone does not say why, one "[verdict]" line does.
#   rc 2 the child was killed or timed out (rc 124 or >= 128): HARNESS_BROKEN, never PASS.
# The diagnosis is a log line, not a KEY=value token (GATE 89 requires every token be documented).
require_pass_token() {
  local key=$1 want=$2 out=$3 crc=$4 n
  n=$(printf '%s\n' "$out" | grep -cE "^${key}=") || true
  case "$crc" in ''|*[!0-9]*) crc=255 ;; esac
  if [ "$crc" -eq 124 ] || [ "$crc" -ge 128 ]; then
    echo "  [verdict] ${key}: HARNESS_BROKEN -- the producer was killed or timed out (rc $crc) after"
    echo "            printing ${n:-0} ${key}= line(s); nothing it printed is believed"
    return 2
  fi
  if [ "${n:-0}" != 1 ]; then
    echo "  [verdict] ${key}= emitted ${n:-0} time(s), rc $crc; exactly 1 is required -- none believed"
    return 1
  fi
  grep -qx -- "${key}=${want}" <<<"$out" || return 1
  if [ "$crc" -ne 0 ]; then
    echo "  [verdict] ${key}=${want} was printed but the producer exited $crc -- not a PASS"
    return 1
  fi
  return 0
}

# ITEM A6 (2026-08-02) — THE SILENT-DROP GUARD, APPLIED TO EVERY SUPPORT FILE AT ONCE.
#
# require_final_newline was added for three registries one at a time. The item that raised it
# asked for one mechanical pass instead, and named six more files said to share "the same
# reader shape". THE PREMISE IS WRONG FOR ALL SIX, and that is worth recording rather than
# quietly acting on, because acting on it would have shipped six guards against a hazard
# those files do not have — and a guard whose motivating example is imaginary is the shape
# this suite keeps catching elsewhere. MEASURED, each at its consumption site:
#   (Each row names its READER, not a line number. All five carried line numbers until
#   2026-08-02 and ALL FIVE had drifted — by 82, 115, 140, 234 and 234 lines — in a block
#   whose own first sentence says "MEASURED, each at its consumption site". Nothing reads a
#   comment, so the pointers rotted silently while the measurement they cite stayed true.
#   Round 8, drain-3, found while re-checking two line citations of its own that were stale
#   within the hour. Names do not drift; that is the whole reason for the change.)
#   DOC_GATE_FIGURE_ALLOWLIST.txt   gate_retract_figures, `ALLOW =` — python `for ln in open(...)`
#   DOC_GATE_SECREF_ALLOWLIST.txt   gate_secrefs, `ALLOW  =`        — python `for ln in open(...)`
#   DOC_GATE_STATUS_ALLOWLIST.txt   gate_status, `allow =`          — python `for l in open(...)`
#   DOC_GATE_UNMARKED_ALLOWLIST.txt gate_status, `alw5b =` (5b)     — python `for l in open(...)`
#   DOC_GATE_NUMBER_ALLOWLIST.txt   gate_numbers, `allow=`          — `grep -qxF -- "$key" "$allow"`
#   CORRECTIONS_INVENTORY.tsv       no consumer in this suite at all; it is WRITTEN by
#                                   scripts/corrections_inventory.sh, and the only documented
#                                   reader is the `awk` recipe at CORRECTIONS.md:52
# Python file iteration, grep and awk all yield an unterminated final line. `while read` is
# the one reader that drops it, and today it is used on exactly the three files already
# guarded. So SIX guards would have been six no-ops.
#
# WHAT IS SHIPPED INSTEAD, and why it is not the same no-op: the guard is applied to every
# support file by CONSTRUCTION rather than to a hand-listed six, because the hazard is not a
# property of the file — it is a property of whichever reader a future gate happens to use.
# The next gate to consume an allowlist with `while read` inherits the protection instead of
# rediscovering the defect. The list is a `git ls-files` glob, so a support file added
# tomorrow is covered without anyone remembering this note.
#
# WHAT IT CANNOT SEE, stated because a clear from a guard I wrote is worth less than a
# failure: it covers documentation/DOC_GATE_*.txt and documentation/*.tsv only — a support
# file placed anywhere else, or given another extension, is outside it. And it addresses ONE
# way a reader silently drops a row; a `while read` without `-r`, or with unset IFS, mangles
# rows it does not drop, and nothing here looks for that.
#
# ITEM A9 — THE OTHER SUPPORT-FILE HAZARD, MEASURED AND DELIBERATELY NOT GATED (2026-08-02).
# A9 asked for an instrument against PROSE COUNTS in support-file headers going stale, after
# DOC_GATE_FIGURE_LEDGER_OPEN.txt shipped saying "the ELEVEN missing ledger entries" over a
# file holding SEVEN rows while its sibling RETRACTED_FIGURES.tsv already said seven
# (corrected at `c737858`). Every DOC_GATE_*.txt file and every .tsv registry then tracked
# was swept for header numbers that are snapshots of a live measurement. FOUR existed at
# `834448a`, cited by the sentence they sit in rather than by line, because a header is
# edited more often than it is renamed:
#   DOC_GATE_FIGURE_LEDGER_OPEN.txt  "the gate prints '4 recorded, 7 open', and this file
#       holds SEVEN rows"  — three coupled counts
#   DOC_GATE_UNMARKED_ALLOWLIST.txt  "64 of 127 ... and 0 of those"
#   DOC_GATE_FIGURE_ALLOWLIST.txt    "There are none today."
#   RETRACTED_FIGURES.tsv            the "CHOOSING THE STRING" paragraph's match counts
# Of the four, exactly ONE restated a number a gate recomputes on every run. The other three
# were one-off corpus measurements that nothing recalculates, so a "does the stated count
# match the computed one" gate had a live corpus of one — and would have to find its number
# by regex over free prose that also contains dates, gate numbers, version strings, line
# numbers and ratios. That is the shape drain-1 measured and rejected for GATE 4b's coverage
# floor on the same day: an instrument whose false-positive rate exceeds its yield.
# NOT SHIPPED, therefore, and the choice among (i) a computed-vs-stated [note], (ii) a
# convention that support-file counts are written "as of <date>", and (iii) nothing, on the
# grounds that headers are commentary, is left open with this measurement attached to it.
#
# RE-SWEPT 2026-08-02 (round 12 drain-3, item `R11`). THE POPULATION HAD GROWN AND TWO OF
# THE FOUR SITES HAD ROTTED — which is evidence bearing on (i)/(ii)/(iii), and is why the
# paragraph above is now in the past tense and its closing "the four sites above are the
# whole surface" is gone. That sentence was true of a corpus that no longer exists: the
# sweep ran over the six DOC_GATE_*.txt files tracked at `834448a`, and
#   git ls-files 'documentation/DOC_GATE_*.txt' 'documentation/*.tsv'
# now lists more. DOC_GATE_REGISTRY_DUPLICATES.txt and DOC_GATE_SELFTEST_INSTRUMENTS.txt
# were added afterwards and were never in the swept population. Re-running the sweep over
# the current one moves the decision's inputs in BOTH directions:
#   - DOC_GATE_REGISTRY_DUPLICATES.txt states the SAMPLE SIZE its caveats reason about,
#     and GATE 14 prints that same number every run. It is correct today — verified
#     against the live [ok] line, not against the generator, after a partial read of the
#     generator produced a false positive. Counted as BORDERLINE rather than as a fifth
#     site: a configured parameter is not a snapshot of a corpus measurement, and it moves
#     only when someone edits the sampler. Anyone taking decision (i) should decide
#     whether that class is in or out; this unit did not.
#   - DOC_GATE_SELFTEST_INSTRUMENTS.txt IS a fifth site AND IT WAS STALE. Its BLOCK
#     paragraph froze the per-row distances GATE 15 LEG 3 prints on every run, and
#     `f5fac73` moved one of them — rebinding the distance from the first qualifying
#     occurrence to the assertion's report line — without touching the header. So the
#     class "restates a number a gate recomputes on every run" is TWO sites, not one, and
#     its observed defect rate is 1 in 2 rather than 0 in 1. That is the class a
#     computed-vs-stated [note] could actually reach, and the yield argument above was
#     built on a population of one.
#   - RETRACTED_FIGURES.tsv's own paragraph had drifted on two of its three counts, in the
#     one-off class the argument above says nothing recalculates. It does not — which is
#     exactly why it rotted.
# BOTH STALE SITES ARE FIXED IN THIS COMMIT, THE DECISION IS NOT TAKEN. (i)/(ii)/(iii)
# remain open and remain the operator's; no instrument shipped.
#
# ITEM R12 — THE UNSTAMPED COMPLEMENT WAS SWEPT AND CAME BACK CLEAN (2026-08-02, round 13
# drain-1; denominator corrected by round 13 drain-2, see HOW MANY SITES below). MEASURED
# REFUSAL: every sampled site reproduced, 0 stale. NO INSTRUMENT SHIPPED, and no
# number is copied out of any of them into this paragraph — that is the point of item R3,
# and copying them here is the one way this block goes stale in silence. Each site is named
# by the sentence it lives in; run the command beside it if you want the value.
#   GATE 6's WHY header, the unscannable-asset description  — `git ls-files '*.svg'
#       '*.png'` (the gate's OWN population), then grep -c '<text' over the SVGs. The
#       <text> and <use> counts it quotes for fig_tr4_boundary_information.svg
#       re-derive. CORRECTED 2026-09-04 TWICE OVER: this recipe used to say
#       `grep -iE '\.(svg|png|pdf)$'`, which is NOT what the gate counts — it included
#       example/report.pdf and so returned 40 where `$nimg` was 39, and the header's
#       quoted "N of M" was taken from the recipe rather than from the gate. That PDF was
#       removed from the repository on 2026-09-04 (embedded DejaVu font programs), so the
#       two populations would now agree by accident; the recipe is corrected anyway,
#       because agreeing by accident is how the disagreement went unnoticed. The header
#       no longer quotes a tally at all.
#   GATE 12's SCOPE paragraph, the per-TR `## Revision history` census  — grep -c over
#       git ls-files 'reports/TR*.md' plus the documentation/ negative.
#   GATE 9's Q2 answer, the banner-block line counts against MAXBLK/MAXIDX  — re-derive
#       with the gate's own rule (open at "not peer-reviewed", close at the first line
#       ending in `*`); the caps are the constants a few lines below it.
#   EVERY `X -> X+1` pin listed in `assert_stays_clean_why`'s STRENGTH VARIES BY CALLER
#       block  — run modes `cli`, `retract-figures` and `revhist` and read the [ok] lines.
#       Mode `cli` carries TWO of them: the solve.py flag pair, and item A4's commented-out-
#       declaration pin. No total is written here on purpose — count the pins in that block.
#   the `_selftest_revert` call-site count in GATE 15's THE CALL-SITE RULE paragraph, the one
#       that says the rule CORRECTED the hand audit  — apply the command-position rule stated
#       in the paragraph directly above it.
# HOW MANY SITES: one per bullet, except the pins bullet, which covers every pin in that
# block. THE ORIGINAL WRITE-UP GOT ITS OWN DENOMINATOR WRONG. It said "FIVE BULLETS, SEVEN
# SITES: the pins bullet covers three separate counts". The STRENGTH VARIES BY CALLER block
# listed FOUR pins at this commit, not three — count them there rather than trusting this
# sentence, which is the whole point of the item. The fourth is item A4's `0 -> 1`
# commented-out-declaration pin, which shares mode `cli` with the flag pair and so was run
# but never counted at all, so the sweep's real sample was EIGHT sites, not seven.
# Measured by round 13 drain-2, which also re-derived the fourth pin's
# clean value (`0 commented-out declaration(s) dropped` on a clean `cli` run): it reproduces,
# so the VERDICT did not move. The denominator of a refusal is load-bearing, though, and this
# one was understated by its own author.
# AND THE OFF-BY-ONE IS NOT THE FINDING. This block's opening sentence declares that no number
# may be copied into it. The original write-up then copied its own bookkeeping numbers in
# anyway — the pin count, the site total, and a "0 of N" headline restated twice below it.
# The rule was written for the SWEPT values and silently exempted for the sweep's OWN
# meta-counts, and that exemption is exactly where it rotted: inside a single commit, before
# any other reader saw it. O6/R3 does not stop at the corpus. It reaches the paragraph that
# announces the rule, and it reached this one.
# WHAT SURVIVES IS NAMED, NOT TALLIED (round 13 drain-3, 2026-08-02). The pin count and the
# site total are still written above and cannot be removed: the correction cannot be stated
# without naming what was wrong with them. Each is a closed fact about what drain-1's sweep
# sampled rather than a live value, and the pins bullet tells you to count the pins in that
# block instead of trusting either. What WAS removed is every restatement of the site total as
# a LIVE figure. The first version of this sentence went further and said that exactly ONE
# total survived; the paragraph it describes falsifies that, since the pin count is sitting in
# it. NO REPLACEMENT TALLY IS WRITTEN HERE, on purpose — a tally of a paragraph's own
# meta-counts is the next rung of the same ladder and would rot the same way. This is
# O-metacount's own shape, reintroduced by the pass that filed O-metacount, which is the
# strongest thing anyone has said about how far up that class reaches.
# WHY THE CLASS IS CLEAN, which matters more than the count: those pins are NOT
# unguarded prose. Each writes a clean value whose POST-injection partner is the literal an
# assert_stays_clean_why ERE matches on, so a corpus change that moved the clean value moves
# the asserted one too and turns `--selftest` RED. They were never in the invisible class;
# they only look unstamped. That mechanism, not luck, is most of the clean result — and it
# covers half the sample once the fourth pin is counted, which strengthens the argument
# against building anything here rather than weakening it.
# PHASE-4 NOTE, KEPT BECAUSE IT IS THE FINDING: the first draft of THIS BLOCK attributed two
# of the sites above to the wrong leg — "GATE 15 LEG 3's caveat-4 census" (it belongs to
# `assert_stays_clean_why`, which only CITES LEG 3 as the authority) and "GATE 15 LEG 2's
# evidence block" (it sits above LEG 3's own marker). Round 12 shipped the same class of error
# one function boundary wide. Citing by CONTENT is what fixed it, and it is why nothing above
# names a leg it did not verify.
# WHAT THE SWEEP CANNOT SEE, and it is a lot: the population was reached by a hand-written
# list of corpus nouns over `#` comment lines, so it misses a load-bearing count whose noun
# is not on the list, one spelled in words, one inside a heredoc or a printed message rather
# than a comment, and one whose number and noun straddle a line break — GATE 6's own site was
# caught only because the noun half landed on the second line. It is a sample of a population
# that was never enumerated; it is not a clearance of the class.
# ITEM R13 — THOSE THREE BLIND CLASSES ARE NOW PROBED, AND ALL THREE ARE NON-EMPTY (round 14,
# drain-2). The sentence above named what the sweep could not see; until now nothing had
# checked whether those classes contained anything, so "not a clearance" was an argument
# rather than a measurement. A read-only probe over this file was fire-proved against a REAL
# missed site BEFORE its output was trusted: run against the parent of the commit that fixed
# it, it catches the coverage-gap `[note]` echo near the end of the --selftest, which PRINTED
# a census count that item A4 had falsified. That is class (b), a count inside a printed
# message string, and it was a genuine stale census — so class (b) is not merely non-empty,
# it held a live defect of exactly the kind R12 refused on, in the one place no
# comment-line query can reach.
#   (a) count spelled in WORDS, not digits — non-empty, and much the largest of the three.
#   (b) count inside a printed message or a heredoc — non-empty; held the R14 defect above.
#   (c) number and noun straddling a line break — non-empty. Genuine straddles include
#       "Item A2 lists five / instances", "TR-1 shipped two / rows" and "TR-9's ... carried
#       two / figures". A2's enumeration was checked and CLOSES: five named, five listed.
# WHAT THE PROBE CANNOT SEE, which is the same shape as the query it was written to test:
# its noun list is hand-written too, so its yield is a LOWER BOUND, and most of its hits are
# ordinary prose ("one of the two published boards") rather than censuses. It is a one-off
# fire-proof that these classes are non-empty. IT IS NOT AN INSTRUMENT, it ships nothing, and
# NO ROUND MAY CITE IT AS A CLEARANCE OF ANY CLASS.
# TWO STRUCTURAL FINDINGS, neither of which is a defect to fix:
#   (1) THE STAMPED/UNSTAMPED SPLIT IS PER-LINE AND THE STAMPS ARE NOT. GATE 12's census is
#       stamped `Measured <date>` on the line ABOVE its numbers, so it is invisible to a
#       stamp query keyed line-wise and appears in BOTH populations. R11's swept population
#       and this one therefore overlap at the boundary, and neither is exactly the class it
#       named. Anyone taking decision (i) should key on the paragraph, not the line.
#   (2) A NAIVE RE-RUN CHECK WOULD FALSE-POSITIVE HERE FOR THE REASON IT DID FOR R9. The
#       ITEM N1 citation-form census below carries its own historicity in prose — it says in
#       terms that its populations will NOT re-measure and must not be reconciled against.
#       And the evidence block for `_selftest_revert`'s two call forms QUOTES both forms, so
#       a `grep -c` verifier of that sentence counts the sentence itself and reports the
#       prose stale when it is correct. Same shape as O6/R3, aimed at the checker this time.
#
# ITEM N1 — CITATION-BY-LINE: ALL THREE FORMS NOW COUNTED, AND ONLY TWO ARE GATEABLE
# (2026-08-02, unit drain-1). Round 9 adjudicated `name.ext:N` — 72 citations, 4 stale. It
# recorded that two other forms had been SAMPLED, not counted. Both are counted now, over
# `git ls-files`. THE POPULATIONS BELOW ARE AS OF THAT CENSUS AND WILL NOT RE-MEASURE TO
# THE SAME NUMBERS: this batch's four fixes removed four form-3 occurrences after it was
# taken, and prose ABOUT a citation form is itself an instance of it — the two "lines 2-4"
# examples further down are two more. Re-run the census; do not reconcile against these.
#   FORM 2, bare `:NNN` — 15 lines. 7 in this file (GATE 5's "WHY the anchor is now the
#     PRIMARY key" block, its item-A8 fire-proof header, and its drift-immunity [ok]
#     message), 3 in DOC_GATE_STATUS_ALLOWLIST.txt, 2 in CORRECTIONS_INVENTORY.tsv: every
#     one NARRATES a past anchor drift or a synthetic move, so round 9's "all narrative"
#     verdict holds on the population and not only on its sample. 2 are numpy slices in
#     solve.py and viz/visualize.py. The ONE live pointer — the "Checked and needing
#     nothing" bullet in CORRECTIONS.md, chaining three notes in DESCRIPTION_LENGTH.md,
#     resolves — as does the alias sub-form `TR-n:NNN` (4 sites).
#   FORM 3, `line NNN` — 122 lines / 138 occurrences, and 92 of those lines are the DOMAIN
#     sense: "Line 3" of a hexagram, "lines 2-4" of a nuclear trigram. 2 more describe a
#     file FORMAT or a manifest's data line. Only 28 lines cite anything, 15 of them dated
#     changelog rows. Of the 13 live pointers, FOUR were stale and are fixed at `2f976d3`.
# NOT SHIPPED, and this one is not a close call: no mechanical test separates "lines 2-4 of
# a hexagram" from "lines 2-4 of a file", so a form-3 gate is ~75% false positives — which
# is how a real hit later gets ignored. The gateable forms are `name.ext:N` and `TR-n:NNN`,
# both already resolvable. THE CONVENTION IS THE FIX: cite the SYMBOL and it cannot drift.
# solve.c is excluded by the sha anchor, not by policy — it carries 5 live self-pointers
# and all 5 are stale; they belong to the solve.c correction batch, not to a gate.
# RE-CENSUSED 2026-08-02 (round 12, item R8) — THE FIVE-COUNT IS EXACT ONLY UNDER THE
# PRESENT-TENSE FILTER, AND THAT FILTER WAS NEVER STATED BESIDE IT, WHICH IS THE SAME DEFECT
# THIS BLOCK IS ABOUT. The detector is
#   grep -nEi '\blines? +[0-9][0-9][0-9]+' solve.c
# and it returns SIX lines, not five. The five above are the present-tense pointers. The
# sixth is the `all_top` stack-sizing comment in the full-enum merge of main(), which reads
# "Earlier 64*TOP_N produced a stack-buffer-overflow at line 12058": past tense, so the
# census dropped it as NARRATIVE, the same class as this file's own past-tense drift
# notes. That call is defensible and this re-census does NOT overturn it — but the narrative
# cases elsewhere say IN THE SENTENCE that the number is historical, and this one does not,
# while the line it cites has drifted clean out of every function: today that line is the
# BLANK one between the `SymEntry` typedef and symmetry_phase3()'s leading doc comment, inside
# no function body at all. (This sentence first read "lands in symmetry_phase3()'s stdin
# parser" — off by a function boundary, written the same hour, in the block about stale
# pointers, and caught only because round 12 drain-2 sampled the claim rather than reading it.
# The true fact is the STRONGER one for the argument here, which is why the correction earns
# its lines.) Cited by CONTENT throughout — a solve.c line number written into this file would
# itself drift the moment #67's cycle runs, and the number quoted above is a QUOTE of the stale
# comment's own text, not a pointer this file is making.
# The first draft of THIS BLOCK cited three of its own form-2 sites by line, and inserting
# the block moved all three by 22 — the census demonstrated on the census, caught by the
# Phase-4 pass and not by any gate. That is the argument for the convention, in one line.
preflight_support_newlines() {
  local f bad=0
  for f in $(git ls-files 'documentation/DOC_GATE_*.txt' 'documentation/*.tsv' 2>/dev/null); do
    require_final_newline "$f" quiet && continue
    if [ "$bad" -eq 0 ]; then
      echo "== PREFLIGHT: every gate-support file must end with a newline =="
    fi
    echo "  [FAIL] gate-support file has no final newline: $f"
    bad=1
  done
  if [ "$bad" -ne 0 ]; then
    echo "         A gate-support file's last row is invisible to any \`while read\` consumer,"
    echo "         and the gate would still print [ok] with a count nobody reads."
    echo
    return 1
  fi
  return 0
}

# Corpus preflight — hole (b). Runs before every mode (see the dispatch at the foot of the
# file) and DOES NOT short-circuit: it sets RC and lets the gates run anyway, so a per-gate
# fire-proof can still tell its own leg's message from this one. The two messages are
# deliberately worded differently for exactly that reason.
#
# THE CONSUMER LIST WAS WRONG IN BOTH DIRECTIONS UNTIL ROUND 16 (item N-emitdigit).
# It read: "GATES 3, 3b, 4, 4b, 5, 5b and 9 all iterate this list and would read each missing
# file as EMPTY — reporting [ok] on a document they never opened." Two defects, and the
# expensive one is the omission:
#
#   * GATE 1 WAS NOT NAMED, and it is the only consumer that does the described thing
#     SILENTLY. gate_numbers iterates `$DOCS` and greps each file with `2>/dev/null`, so a
#     missing file contributes no integers, produces no diagnostic, and the gate reports on a
#     document it never opened. A maintainer reading the old message concluded GATE 1 was
#     unaffected — a false clear manufactured by the message, which is the class this file
#     keeps re-learning.
#   * SIX OF THE SEVEN NAMED GATES DO NOT DO WHAT THE MESSAGE SAID. Of the seven it named,
#     only GATE 3 reads a missing file as empty (its `tr ... < "$f"` redirection fails and the
#     pipeline sees EOF); GATE 1, unnamed, does the same thing and does it silently.
#     GATES 3b/4/4b/5/5b re-derive the listing in python and `open()` it unguarded, so they
#     raise FileNotFoundError — loud, and the safe direction. GATE 9 uses
#     `glob.glob('reports/TR*.md')`, a WORKING-TREE glob, so a deleted file leaves the
#     population entirely rather than being read as empty; that is still a hazard ("a FAIL,
#     not a smaller count") but a different one, and the message named the wrong mechanism.
#     Phase-4 correction to this batch's own first draft: the replacement message said GATE 9
#     shrinks "without saying so". MEASURED FALSE against a real `all` run — it prints
#     "scanned 11 reports/TR*.md" and would print 10. The defect is that it then PASSES, not
#     that it is silent, and the first draft of a fix for an inaccurate message was itself
#     inaccurate about a sibling gate. Caught by reading the gate's real output, not by a gate.
#
# MEASURED, NOT READ OFF THE CODE. Each of the four dispositions was driven in a throwaway
# git repo holding one tracked .md, deleted from the working tree only: the GATE 1 shape
# returned rc=0 with zero output; the GATE 3 shape reported no-match plus one stderr line;
# the python `open()` shape raised FileNotFoundError with rc=1; `glob.glob` returned [].
# The population itself was re-derived by function bounds (`$DOCS` or a `git ls-files '*.md'`
# of the consumer's own) rather than trusted from the old sentence.
#
# WHAT THIS NOTE CANNOT SEE. The list is hand-maintained and nothing checks it: a gate added
# later that iterates the corpus would not appear here, and no gate reads this message against
# the code it describes. That is the same standing question as O6/O-census and no instrument
# is proposed for it here.
preflight_tracked_docs() {
  local f missing=0
  for f in $DOCS; do
    [ -f "$f" ] && continue
    if [ "$missing" -eq 0 ]; then
      echo "== PREFLIGHT: every tracked .md must exist in the working tree =="
    fi
    echo "  [FAIL] tracked markdown missing from the working tree: $f"
    missing=$((missing+1))
  done
  if [ "$missing" -ne 0 ]; then
    echo "         WHAT EACH CONSUMER DOES WITH IT — named, not counted, and each disposition"
    echo "         measured rather than read off the code (see this function's header):"
    echo "         GATES 1 and 3 iterate this list and read a missing file as EMPTY —"
    echo "         reporting [ok] on a document they never opened. GATE 1 is the SILENT one"
    echo "         (its grep runs 2>/dev/null); GATE 3's redirection leaves a stderr line."
    echo "         GATES 3b, 4, 4b, 5 and 5b re-derive the same index listing in python and"
    echo "         raise FileNotFoundError instead, which is loud, not a false clear."
    echo "         GATE 9 globs the WORKING TREE, so the file simply leaves its population."
    echo "         It does PRINT the reduced tally (\"scanned N reports/TR*.md\") and then"
    echo "         passes — a smaller count rather than a FAIL, which is the weaker refusal."
    echo "         Restore it (git checkout -- <path>) or remove it from the index."
    echo
    return 1
  fi
  return 0
}

. scripts/doc_gates.d/10_numbers_cli_citations.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/10_numbers_cli_citations.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
# ----------------------------------------------------------------------------------
# CHARACTER-VARIANT FOLD (2026-08-06) — GATE 3's bash port of the canon() fold GATEs 3b
# and 18 apply in python (same table; keep the three in step). PROVEN LIVE for THIS gate
# before it shipped: the registry row "the exact C1–C7 enumeration" (en-dash, U+2013)
# did NOT match the restatement "the exact C1-C7 enumeration" (ASCII hyphen) — a
# retracted phrase could survive, and the gate stay green, purely by typing a different
# dash. The registry itself already carries the scar tissue of doing this by hand: four
# separate rows for the ONE withdrawn hard-floor claim ("k ≥ 13" / "k>=13" / "≥13" /
# "k >= 13"); this fold makes such hand-multiplication unnecessary for the character
# families it covers. Needle and haystack are both folded, so every current match is
# preserved and only variant forms are added. ONE deliberate divergence from the python
# canon(): '*' is DELETED rather than also tried as 'x' — GATE 3's needles are word
# phrases, where '*' is only ever markdown emphasis splitting a span ("hard floor
# **k ≥ 13**"), never a multiplication sign. sed with literal substitutions only (the
# digit-comma rule uses the class [0-9]; no repetition operators of any kind).
#
# QUOTE FOLD (2026-09-02, batch C9) — the fourth character family, and the one this table
# was measured to be MISSING. Variant 3 of the needle-reachability class: a registry needle
# carrying an ASCII apostrophe cannot reach a typographic one, and vice versa. PROVEN LIVE
# before the fix, on a scratch copy of this tree: the registered row "C4's attested
# orientation" was planted into documentation/GUIDE.md spelled C4<U+2019>s, GATE 3 printed
# [ok] for that row and PASS overall; the same sentence planted with an ASCII apostrophe
# fired [FAIL] immediately. The character was the whole difference. Batch P54 had already
# paid for this by hand — it took TWO narrow needles instead of the one covering phrase,
# because the covering phrase contained an apostrophe and would have been defeated here.
#
# BLAST RADIUS, MEASURED rather than argued (the registry is 174 phrase rows + 14 figure
# rows = 188 needles, all of them run through this function by GATE 3 and GATE 6). The
# per-(needle, corpus-file) match set was captured before and after over the FULL corpus —
# every tracked .md, the non-md half of reports/evidence/**, the figure generators and the
# text-bearing .svg — 77 (needle, file) matches, and the before/after diff is EMPTY. The
# fold folds needle and haystack alike, so it can only ADD matches; it added none here,
# because zero registered needles and only 31 corpus characters carry a curly quote.
#
# BACKTICK IS DELIBERATELY NOT FOLDED, and this is the measured half of the decision, not
# taste. (a) NO TRUE POSITIVE EXISTS: every backtick-followed-by-letter site in the corpus
# is a code-span opener (`v4-canonical, `d683794`, `example`s) — not one is a possessive,
# so folding ` to ' cannot recover a single real survivor. (b) A FALSE POSITIVE DOES EXIST
# and was reproduced on real corpus bytes: with ` folded, the needle "example's" goes from
# 1 matching file to 2, the extra being lean/README.md's "anonymous `example`s" — a code
# span naming the Lean `example` keyword, pluralised. That is precisely a needle matching a
# LITERAL rather than a claim. (c) The perturbation is 1,155x larger: 35,817 corpus
# backticks against 31 curly quotes, and this file's GATE 21 keys on backticks as
# STRUCTURE (backticked repo paths), so the character is load-bearing markup here, not an
# alternative spelling of a glyph. Ellipsis (U+2026 -> "...") is the same shape and is also
# NOT folded: 812 in the corpus but ZERO needles carry either spelling, so it has no
# populated needle side and no red test. Both are recorded as measured, unfixed siblings.
fold_variants() {
  # The four space variants are spelled as $'\u..' escapes, not embedded literally —
  # an invisible character pasted into a sed script is unreviewable and un-diffable.
  # The four QUOTE variants are spelled the same way for a SHARPER version of that reason:
  # ' and ’ are both VISIBLE and near-identical at a review font size, so a literal
  # pasted here would not be unreadable, it would be MISREADABLE as the ASCII character it
  # folds to — a reviewer would see s/'/'/g and read it as a no-op.
  local NB=$'\u00a0' FS=$'\u2007' TS=$'\u2009' NN=$'\u202f'
  local RSQ=$'\u2019' LSQ=$'\u2018' LDQ=$'\u201c' RDQ=$'\u201d'
  sed -e 's/×/x/g; s/✕/x/g; s/⨯/x/g' \
      -e 's/–/-/g; s/—/-/g; s/−/-/g' \
      -e 's/≥/>=/g; s/≤/<=/g; s/＋/+/g' \
      -e "s/$NB/ /g; s/$FS/ /g; s/$TS/ /g; s/$NN/ /g" \
      -e "s/$RSQ/'/g; s/$LSQ/'/g; s/$LDQ/\"/g; s/$RDQ/\"/g" \
      -e 's/\*//g' \
      -e 's/\([0-9]\),\([0-9]\)/\1\2/g' \
      -e 's/\r$//; s/\t/ /g; s/ *+ */+/g'   # Q-965: CR, tabs, RUNS of spaces around + (fold_join: doc_gates.d/md_normalise.sh)
}

. scripts/doc_gates.d/20_retract_links_status.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/20_retract_links_status.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/30_figures_liveness_banner_revisions.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/30_figures_liveness_banner_revisions.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
# ===========================================================================
# SELF-TEST — mutation testing. Run: scripts/doc_gates.sh --selftest
#
# WHY (2026-08-01): these seven gates had never been observed to FAIL. GATE 7
# was VACUOUS on the day it was written — its suppression list contained the
# word "budget", and the stale table it was built for has a "Budget" column
# header three lines above the frozen status, so it passed cleanly on its own
# motivating defect. A gate nobody has watched fire is an untested test, and
# a green row of [ok] from an untested gate reads as coverage while providing
# none. That is the same failure as verify_archive.sh sampling zero shards and
# reporting PASS.
#
# METHOD: inject one known defect at a time into the real tree, run only the
# gate that should catch it, assert it FAILS, then revert with git checkout.
# Mutation testing rather than synthetic fixtures, deliberately: the gates read
# real paths (CANONICAL_HASHES.md, solve.py, viz/), so a fixture would test a
# different program than the one that runs in anger.
#
# SAFETY: refuses to run unless the tree is clean, so it can never destroy
# uncommitted work; every mutation is reverted immediately after its assertion,
# including on failure.
#
# ITEM A3 (2026-08-02) — TWO WAYS THE ABOVE WAS NOT TRUE, both met in the wild.
#
#  (1) NO MUTUAL EXCLUSION. Two --selftests could run at once. Observed: a background
#      --selftest's `git checkout -- .` discarded uncommitted edits to this very file and
#      left example/report.html sitting mutated. The clean-tree refusal cannot help — it is
#      a check at START, and the second runner passes it because the first has already
#      reverted its current mutation. Fixed below with an atomic `mkdir` lock in $GIT_DIR
#      (not the working tree, so the lock can never dirty the tree it is protecting, and
#      not /tmp).
#
#  (2) NO SIGNAL HANDLER. Every assertion helper reverts after each case, but a SIGTERM or
#      Ctrl-C between the mutation and the revert left the mutated file in place. That is
#      how example/report.html came to be mutated on disk with no run in progress. Fixed
#      below: INT and TERM restore and release before exiting, and an EXIT trap catches
#      every other path out.
#
# WHAT A3 DOES *NOT* FIX, stated rather than implied: a writer that is not a --selftest
# arriving mid-run. The lock only excludes other --selftests. An editor saving a file while
# assertions are in flight still loses that save to the next `git checkout -- .`, because the
# harness cannot distinguish its own mutation from someone else's edit. The only real
# protection there is not to edit the tree while the self-test runs; the round-4 workaround
# (commit first, then self-test) remains the operating procedure, and this note is here so
# that procedure is not mistaken for a guarantee the code provides.
#
# ITEM A1 + A2 (2026-08-02) — PREVENTION IS STILL ABSENT; RECOVERY IS NOT. The paragraph
# above stood for a round while the same idiom destroyed work twice more, so the answer is
# no longer only procedural: every revert in this harness now snapshots the whole dirty tree
# into refs/doc-gates/selftest-revert first (see `_selftest_revert` below). A discarded save
# is still discarded — but it is reachable through that ref's reflog instead of gone. Read
# the helper's header for the recovery commands; do NOT read this as making the tree safe to
# edit mid-run.
#
# A THIRD WAY, met 2026-08-02 while building legs 5 and 6 below, and the cheapest to warn
# about: the revert idiom itself gets COPIED. Taking a fire-proof by hand means running the
# mutation and then the harness's own `git checkout -- .` — which reverts the WHOLE tree,
# including the uncommitted edit to this script that the fire-proof was testing. That is
# what happened: two new legs and their self-test cases were written, proven to fire by
# hand, and then destroyed by the copied revert, with no --selftest involved at all. The
# harness is not what has to change (its `-- .` is load-bearing; see `_selftest_revert`). What
# changes is the procedure, and it is the same one as above, for a second reason: COMMIT
# FIRST, then mutate — by hand or by harness. `git checkout -- <path>` naming only the
# mutated file is the safe hand form.
#
# THE ORDER BELOW IS LOAD-BEARING: clean-tree check FIRST, then lock, then trap. Installing
# a restoring EXIT trap before the clean-tree check would make the dirty-tree refusal itself
# run `git checkout -- .` and destroy exactly the uncommitted work it exists to protect.
#
# Q-911 (2026-09-30, CX-243) — THE SELF-TEST NO LONGER MUTATES THE TREE IT WAS CALLED IN.
# Every guard above (lock, INT/TERM/EXIT traps, the snapshot ref) protects the tree only while
# this process is alive to run its trap. SIGKILL cannot be trapped, a hang-up was not trapped,
# and a reader who looks at the tree mid-run (or a `git pull` that lands mid-run) sees the
# planted defects as real edits. On 2026-09-29 a ledger proof command that ran
# `cd <the main public checkout> && bash scripts/doc_gates.sh --selftest` was found with the
# Q-761 needle planted in that checkout's RETRACTED_PHRASES.tsv and GUIDE.md. So an ordinary
# call now copies the committed HEAD into a scratch clone (`git clone --shared`, the same form
# the pre-push leg has used since Q-720, so `.git/..` is the tree root and GATE 19 sees the
# same origin refs) and runs the unchanged suite THERE, with DOC_GATES_SELFTEST_INPLACE=1.
# The caller's tree is never written, whatever signal ends the run; what a SIGKILL can leave
# behind is a scratch directory under $TMPDIR, never a planted file in a checkout.
# The clean-tree refusal stays, for a new reason: with uncommitted edits the scratch copy
# would test HEAD rather than the tree you are looking at, and a PASS would describe the
# wrong program. DOC_GATES_SELFTEST_INPLACE=1 is for a caller that is ALREADY a throwaway
# clone (pre_push_gate.sh); set by hand on a real checkout it restores the old in-place run.
if [ "${1:-}" = --selftest ] && [ -z "${DOC_GATES_SELFTEST_INPLACE:-}" ]; then
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "REFUSING: working tree is not clean. The self-test runs on a scratch clone of HEAD"
    echo "(Q-911), so with uncommitted edits it would test a different tree from this one."
    exit 2
  fi
  _ST_HEAD=$(git rev-parse --verify -q HEAD) || { echo "REFUSING: no HEAD commit to self-test."; exit 2; }
  _ST_BASE=$(mktemp -d "${TMPDIR:-/tmp}/doc_gates_selftest.XXXXXX") \
    || { echo "REFUSING: mktemp failed, and the self-test never runs in place (Q-911)."; exit 2; }
  _ST_PID=""
  trap 'rm -rf "$_ST_BASE"' EXIT
  trap '[ -n "$_ST_PID" ] && kill -TERM "$_ST_PID" 2>/dev/null && wait "$_ST_PID"; rm -rf "$_ST_BASE"; exit 130' INT
  trap '[ -n "$_ST_PID" ] && kill -TERM "$_ST_PID" 2>/dev/null && wait "$_ST_PID"; rm -rf "$_ST_BASE"; exit 143' TERM
  trap '[ -n "$_ST_PID" ] && kill -TERM "$_ST_PID" 2>/dev/null && wait "$_ST_PID"; rm -rf "$_ST_BASE"; exit 129' HUP
  if ! ( env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE sh -c '
           git clone -q --shared --no-checkout "$1" "$2" &&
           git -C "$2" remote remove origin &&
           git -C "$2" fetch -q "$1" "+refs/remotes/origin/*:refs/remotes/origin/*" &&
           git -C "$2" checkout -q --detach "$3"' _ "$PWD" "$_ST_BASE/tree" "$_ST_HEAD" ) >/dev/null 2>&1 \
     || [ ! -f "$_ST_BASE/tree/scripts/doc_gates.sh" ]; then
    echo "REFUSING: could not check HEAD out into a scratch clone (Q-911); nothing was tested."
    exit 2
  fi
  echo "  [note] Q-911: self-testing HEAD ${_ST_HEAD:0:12} in the scratch clone $_ST_BASE/tree; this tree is not written"
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE DOC_GATES_SELFTEST_INPLACE=1 \
    bash "$_ST_BASE/tree/scripts/doc_gates.sh" "$@" &
  _ST_PID=$!
  wait "$_ST_PID"; _ST_RC=$?
  _ST_PID=""
  exit "$_ST_RC"
fi
if [ "${1:-}" = "--selftest" ]; then
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || exit 1
  if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "REFUSING: working tree is not clean. This self-test mutates real files and"
    echo "reverts them with 'git checkout --'; that would discard your uncommitted work."
    exit 2
  fi
  # Q-914 (CX-246; the Fable batch-29 pre-publication review, item U2). This in-place branch is
  # reached only with DOC_GATES_SELFTEST_INPLACE set. Its two legitimate callers, the scratch clone
  # above and pre_push_gate.sh's clone, both check out a DETACHED HEAD. A HEAD on a branch means a
  # real checkout (the variable set by hand, or left exported in a shell), which is the Q-911
  # incident class: refuse it here, before the lock and before any plant, with nothing written.
  if git symbolic-ref -q HEAD >/dev/null 2>&1; then
    echo "REFUSING: DOC_GATES_SELFTEST_INPLACE is set but HEAD is a branch ($(git symbolic-ref -q --short HEAD 2>/dev/null)), so this is a real checkout. The in-place self-test runs only in a detached throwaway clone (Q-911, Q-914); unset DOC_GATES_SELFTEST_INPLACE."
    exit 2
  fi

  # --- A3 (1): mutual exclusion. `mkdir` is atomic on every POSIX filesystem; a lockFILE
  # written with `>` is not. The holder's pid goes inside so a lock left behind by `kill -9`
  # (which no trap can catch) can be identified as stale and broken, loudly, rather than
  # wedging the suite until someone deletes it by hand.
  SELFTEST_LOCK="$(git rev-parse --git-dir 2>/dev/null || echo .git)/doc_gates_selftest.lock"
  if ! mkdir "$SELFTEST_LOCK" 2>/dev/null; then
    _holder=$(cat "$SELFTEST_LOCK/pid" 2>/dev/null || echo '?')
    if [ "$_holder" != '?' ] && ! kill -0 "$_holder" 2>/dev/null; then
      echo "  [note] breaking a STALE self-test lock: pid $_holder is gone (kill -9 leaves no"
      echo "         chance to release). If that run was interrupted mid-mutation, check"
      echo "         'git status' before trusting this one."
      rm -rf "$SELFTEST_LOCK"
      mkdir "$SELFTEST_LOCK" 2>/dev/null || { echo "REFUSING: cannot acquire $SELFTEST_LOCK"; exit 2; }
    else
      echo "REFUSING: another --selftest is running (pid $_holder, lock $SELFTEST_LOCK)."
      echo "Two concurrent self-tests revert each other's mutations with 'git checkout -- .',"
      echo "so one of them reverts the OTHER's injected defect and reports [ok] on a gate that"
      echo "never saw it — and any uncommitted edit made meanwhile is discarded."
      exit 2
    fi
  fi
  echo $$ > "$SELFTEST_LOCK/pid" 2>/dev/null

  # RECURSION STOP, reached only if the lock above is broken. The A3 fire-proof below calls
  # `bash "$0" --selftest` from inside a live run and expects the LOCK to refuse it; if the
  # lock ever stops working, that call would otherwise run the whole suite recursively. This
  # guard is deliberately placed AFTER the lock so that on a healthy system the lock message
  # is the one that prints (and the fire-proof asserts on that message, so a depth-guard
  # refusal correctly reads as a FAILURE of the lock rather than a pass).
  if [ "${DOC_GATES_SELFTEST_DEPTH:-0}" -ge 1 ]; then
    echo "REFUSING: nested --selftest reached the depth guard, which means the lock did NOT"
    echo "hold. Fix the lock; this guard exists only to stop unbounded recursion."
    rm -rf "$SELFTEST_LOCK" 2>/dev/null
    exit 2
  fi
  export DOC_GATES_SELFTEST_DEPTH=1; _DG_SRC="$(git rev-parse --git-dir)/doc_gates_logical_src.sh"; bash scripts/doc_gates.d/logical_source.sh > "$_DG_SRC" || { echo "REFUSING: could not assemble the logical source of scripts/doc_gates.sh from scripts/doc_gates.d/ (Q-797 split)."; rm -rf "$SELFTEST_LOCK" "$_DG_SRC"; exit 2; }

  # --- ITEM A1 + A2 (2026-08-02): every revert below is now RECOVERABLE.
  #
  # A1 records that `git checkout -- .` has destroyed uncommitted work THREE times by three
  # independent routes: a concurrent self-test (fixed by the lock), a SIGTERM between mutate
  # and revert (fixed by the traps), and — the one no code change reaches — the idiom being
  # COPIED into a by-hand fire-proof, which reverted the whole tree including the edits the
  # proof was testing. A2 is the residual the lock cannot close: an editor saving a file
  # while assertions are in flight is indistinguishable from the harness's own mutation, so
  # that save is discarded. Both were answered with PROCEDURE ("commit first"), and procedure
  # is exactly what failed, twice in one round.
  #
  # WHAT THIS CHANGES AND WHAT IT DOES NOT — stated rather than implied, because the previous
  # note's "can never destroy uncommitted work" is the claim that turned out to be false.
  # It does NOT prevent the discard. Nothing here can: `-- .` is load-bearing (see
  # the GATE 6 glob note further down this header), and the harness genuinely cannot tell whose edit
  # it is. What it does is make the discard RECOVERABLE. `git stash create` writes the entire
  # dirty tree to a commit object and returns its sha WITHOUT touching the working tree or
  # the index; `git update-ref` then anchors that object so gc cannot collect it. The ref's
  # REFLOG is the real record — one entry per revert, so the third-from-last revert is still
  # reachable, not merely the most recent.
  #
  # Recovery, worth reading before you need it:
  #     git reflog refs/doc-gates/selftest-revert       # every revert, newest first
  #     git show   refs/doc-gates/selftest-revert@{3}   # what that one threw away
  #     git checkout refs/doc-gates/selftest-revert@{3} -- <path>
  #
  # LOCAL AND EXPIRING BY CONSTRUCTION. refs/doc-gates/ is neither refs/heads nor refs/tags,
  # so no default push refspec carries it, it is empty in a fresh clone, and its reflog
  # expires on git's normal schedule. That is deliberately the same shape the GATE 10b
  # boundary note proposes for its own tripwire.
  #
  # WHY NOT `git stash push`: push MODIFIES the working tree (reverting is its side effect)
  # and rewrites the index. `create` is pure — it records and returns a sha and changes
  # nothing — so the revert that follows is still the plain, auditable `git checkout`, and
  # this wrapper cannot alter WHICH files come back. Scope matches too: `stash create`
  # captures tracked modifications, including a tracked file deleted by `os.remove`, and
  # tracked files are exactly what `checkout -- .` restores.
  #
  # WHAT IT STILL CANNOT SEE: an UNTRACKED file. `stash create` does not capture one and
  # `checkout -- .` does not delete one, so the two agree — but a human's brand-new,
  # never-added file is outside this safety net in both directions.
  #
  # WHY THE DEFAULT IS `-- .` AND NOT `-- "$file"` (corrected 2026-08-01, same-day
  # re-review; the note used to live on the deleted `assert_fires` helper and is kept here
  # because two comments above still point at it). The GATE 6 case mutates whatever
  # `glob('viz/*.py')` returns first — a path the caller cannot name, and glob order is not
  # guaranteed — while its documented <file> column said viz/README.md. So that mutation was
  # never reverted by its own assertion; only the blanket `git checkout -- .` after the last
  # case cleaned it up, leaving every later assertion running against a mutated tree.
  # Reverting everything is correct here and costs nothing: the self-test refuses to start
  # unless the tree is already clean, so there is never uncommitted work for `-- .` to
  # discard. The optional argument narrows it where a caller genuinely can name its target.
  _selftest_revert() {
    local snap
    snap=$(git stash create 2>/dev/null)
    if [ -n "$snap" ]; then
      # `--create-reflog` IS LOAD-BEARING AND WAS MISSING FOR ONE COMMIT (fbdbe26, fixed
      # same day). git's `core.logAllRefUpdates=true` — the default — writes reflogs ONLY
      # for refs/heads, refs/remotes, refs/notes and HEAD. refs/doc-gates/ is none of those,
      # so without this flag `update-ref` silently kept just the LATEST snapshot: the ref
      # resolved, `git show <ref>:<path>` worked, and every recovery command in the header
      # above appeared to function — while `@{1}` and older were never written at all.
      # MEASURED after a full 57-assertion run: `git rev-parse` resolved the ref and
      # `git reflog refs/doc-gates/selftest-revert` printed ZERO lines. A clear taken by
      # reading the code would have missed this; only running it and counting the entries
      # found it.
      git update-ref --create-reflog \
        -m "doc_gates --selftest revert $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        refs/doc-gates/selftest-revert "$snap" 2>/dev/null
    fi
    git checkout -- "${1:-.}" 2>/dev/null
  }

  # --- A3 (2): restore on every exit path, including signals. Installed only now, with the
  # tree already proven clean and the lock already held, so it can never discard real work.
  _selftest_release() {
    _selftest_revert
    rm -rf "$SELFTEST_LOCK" "${_DG_SRC:-}" 2>/dev/null
  }
  trap '_selftest_release; echo; echo "DOC GATES SELF-TEST: INTERRUPTED (tree restored, lock released)"; exit 130' INT
  trap '_selftest_release; echo; echo "DOC GATES SELF-TEST: TERMINATED (tree restored, lock released)"; exit 143' TERM
  # Q-911: a hang-up (a closed terminal or session) was the one catchable signal left untrapped.
  trap '_selftest_release; echo; echo "DOC GATES SELF-TEST: HUNG UP (tree restored, lock released)"; exit 129' HUP
  trap '_selftest_release' EXIT

  PASS=0

  # THERE IS NO EXIT-CODE-ONLY FIRE-PROOF HELPER IN THIS HARNESS (item A1, round 8,
  # 2026-08-02). `assert_fires <label> <file> <gate> <mutation>` used to live here and
  # asserted on the gate's EXIT CODE and nothing else. It is DELETED, and its six callers
  # were converted to `assert_fires_why` below. Read this before writing another one.
  #
  # WHY DELETED RATHER THAN DOCUMENTED. Both corpus preflights run before EVERY mode and
  # both return non-zero, so an exit-code assertion is satisfied by a preflight firing on a
  # defect that has nothing to do with the injected one. That is precisely the class GATE 16
  # was built for — arriving through the helper GATE 16 structurally could not examine,
  # since GATE 16 scans `assert_fires_why` invocations for their evidence-ERE and an
  # exit-code helper has none to scan. The weakness was written into GATE 16's own
  # "what it cannot see" note rather than fixed, for a round. Leaving the helper defined but
  # uncalled would have kept a working example of "an exit code is enough" in the file.
  #
  # THE CONVERSION FOUND TWO LIVE DEFECTS, not only the theoretical one. Two of the six
  # were dispatched to a COMBINED gate name, so each was satisfiable by the half that was
  # never in question:
  #   * "GATE 4 internal links" ran `links`, which is gate_links_and_secrefs — GATE 4 AND
  #     GATE 4b. A GATE 4b failure satisfied an assertion written about GATE 4.
  #   * "GATE 11 ledger completeness" ran `ledger`, which is gate_ledger_phrases AND
  #     gate_ledger_figures, and the figures pass already carries [OPEN] rows.
  # This is the same shared-dispatch class that got GATES 10a, 10b and 11-figures their own
  # dispatch names; these two were missed at the time. Asserting on each leg's own MESSAGE
  # pins the leg without needing a third and fourth dispatch name.
  #
  # EVERY EVIDENCE-ERE BELOW WAS TAKEN FROM A REAL RUN of its own mutation — inject, run the
  # gate, read the [FAIL] line, revert — never written from reading the gate's source. GATE
  # 8's hand-taken proof is why that is written down instead of assumed.
  #
  # ITEM A5 (2026-08-02) — A MOVED ANCHOR IS A FAILURE, NOT A SKIP, and that rule outlived
  # the helper it was written on. The deleted helper used to `return` after printing [SKIP],
  # leaving PASS untouched, so the suite reported "DOC GATES SELF-TEST: PASS" with the
  # assertion never having run. Its callers all pin HARDCODED CORPUS TEXT — GATE 9's two
  # banner sentences, GATE 10a's `len(L) > 60`, GATE 10b's "a line of the oldest version
  # survives" — every one of which a normal edit can move. Same shape as GATE 5b's first
  # run, which printed "[SKIP] anchor moved" because of a `%%` typo and was recorded as a
  # pass. MEASURED before that change: two helpers printed [SKIP] and left PASS alone while
  # four set PASS=1 on the identical condition — drift, not design. All surviving helpers
  # say failure.

  # assert_fires_why <label> <gate-name> <evidence-ERE> <python-mutation>
  #
  # ITEM A5 (task #65, the assertion half). An exit code cannot tell "the gate fired for the
  # reason I injected" from "the gate fired for some unrelated reason and my mutation was
  # never seen". Every classifier gate now prints the token/anchor/registry note that drove
  # its verdict; this harness is what makes that printing load-bearing instead of
  # decorative — the assertion FAILS if the WHY line does not name the injected thing.
  # Modelled on assert_gen_fires, which already did this for GATE 8; generalised here so
  # every classifier class can carry one, and since round 8 it is the ONLY fire helper.
  #
  # ITS INVOCATIONS ARE PARSED BY GATE 16, which extracts the evidence-ERE from each one and
  # refuses any ERE a preflight could emit. That parser requires the shape used below: the
  # call line starts with exactly two spaces, the label is the first double-quoted token on
  # it, the ERE is the first single-quoted token in the argument list, and the mutation body
  # opens at column 0. Keep the shape or GATE 16's per-invocation vacuity guard fails.
  assert_fires_why() {
    local label="$1" gate="$2" want="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped assertion is not a pass."
                           PASS=1; _selftest_revert; return; }
    out=$(bash "$0" "$gate" 2>&1); rc=$?
    _selftest_revert
    # Q-954 sibling sweep (Codex Q835 P-07 (e) shape): any rc != 0 used to count as firing, so a
    # refusal (2) or a kill (124/137/143) passed here whenever the ERE below happened to be printed
    # first. A mode run fires with rc 1 and refuses with rc 2, so the fire is rc 1 exactly.
    if [ "$rc" -ne 1 ]; then
      echo "  [FAIL] $label — $gate did NOT fire (rc 1) on an injected defect; rc=$rc"; PASS=1; return
    fi
    # 🔴 Q-799 (2026-09-25): a HERE-STRING, never `printf '%s' "$out" | grep -qE`. Under this
    # file's `set -o pipefail` that pipe is a RACE: grep -q exits at its first match, the printf
    # builtin takes SIGPIPE on its next buffered write, the pipeline status is 141, and a MATCH reads
    # as "never names". GATE 10b's output (~52 KB, 121 ledger blobs, the match on line 3) is what
    # tripped it: measured on one pinned CPU, 7-8 of 300 pipe runs gave PIPESTATUS "141 0" and 0 of
    # 300 here-string runs failed. Neither the gate's message nor this ERE had drifted. The same
    # construct was replaced at every site where the match can land before the end of a multi-line,
    # multi-KB string. A string flattened to ONE line (tr '\n' ' ') is immune and was left alone:
    # grep cannot match a line before reading all of it, so the writer always finishes first. MEASURED 2026-09-25 (Opus AY, every site's string length logged over one full --selftest): seven more pipe sites carried 3.7-20.9 KB and are here-strings now (G1OUT, _Q761_OUT x3, A7OUT x2, B1OUT); every other `printf | grep -q` in this file carried at most 2.8 KB, below one 4 KiB stdio write, so its writer finishes before grep reads.
    if grep -qE -- "$want" <<<"$out"; then
      echo "  [ok]   $label — $gate fires, and WHY names: $want"
    else
      echo "  [FAIL] $label — $gate fired, but its output never names \"$want\","
      echo "         so the assertion cannot tell this firing from an unrelated one."
      PASS=1
    fi
  }

  # assert_stays_clean_why <label> <gate-name> <evidence-ERE> <python-mutation>
  #
  # The other half of any gate that EXEMPTS or COMPARES: proof that the silence is driven by
  # what it claims to be driven by. Without it, a green gate is equally consistent with "the
  # exemption is correct" and "the exemption swallows the whole file".
  #
  # ITS [ok] MESSAGE NAMED THE WRONG MECHANISM until 2026-08-02 (item A3's review). It read
  # "exempted, as the ALLOWLIST says it should be" for all callers, and most of them consult
  # no allowlist at all: GATE 12's draft-label exemption is SUFFIX-keyed, and GATE 2's two
  # negative controls are a comm(1) comparison and a comment filter with no allowlist
  # anywhere in either. A message that attributes a verdict to a mechanism that was not
  # consulted is a small false attestation of exactly the kind this file exists to refuse, so
  # it now says only what it knows. (The original wording of this note counted "two of the
  # six"; the count is deliberately not restated, because a hand-taken tally in a comment is
  # the caveat-4 shape and it went stale the moment a seventh caller landed. The per-caller
  # strength lines below are the authority.)
  #
  # THE EVIDENCE ARGUMENT (item A1's residue, round 8 drain-3, 2026-08-02). This helper
  # asserted on rc 0 ALONE until now, which is the negative-control mirror of the defect that
  # deleted `assert_fires`: an exit code cannot tell "the gate looked at the injected case and
  # correctly stayed silent" from "the gate never looked at it", and it cannot tell either
  # from "the leg that would have looked was skipped". All three exit 0. The mutation is
  # reverted immediately afterwards, so nothing downstream ever notices which of the three
  # happened. It must now also match an ERE on the gate's OWN OUTPUT — a line that a run which
  # never reached the mutated file could not print.
  #
  # STRENGTH VARIES BY CALLER AND IS RECORDED AT EACH CALL, because a uniform claim here would
  # be the over-attestation this file exists to refuse. RE-TAKEN 2026-08-02 (round 9, item
  # B9), which is what moved the numbers below — round 8 shipped this helper with ONE measured
  # discriminator out of six, and said so. FOUR are now measured DISCRIMINATORS, meaning the
  # pinned number differs between the mutated run and a run that never read the injection,
  # each verified by running the mode BOTH ways. THE TOTAL IS DELIBERATELY NOT RESTATED HERE:
  # this sentence said "SEVEN callers" and was stale within the hour, because the same batch
  # that wrote it added an eighth call site — the caveat-4 shape, in the comment that names
  # caveat 4. The authority is the machine-read `callers=N` on this helper's row in
  # documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt, which GATE 15 LEG 3 re-derives every run:
  #   GATE 3b  meta-mention count 45 -> 46                              ** ABSOLUTE **
  #   GATE 2   flags/documented base -> base+1 (a flag added to both sides)     RELATIVE
  #   GATE 2   commented-out declarations dropped 0 -> 1, census base   RELATIVE
  #   GATE 12  revision rows checked base -> base+1                     RELATIVE
  #   GATE 25  documented command-flag uses base -> base+1              RELATIVE
  #   GATE 14  adjudicated pairs `1 ... 0 new`                          ** ABSOLUTE **
  #   GATE 15  `12 instrument(s) in the --selftest region`              ** ABSOLUTE **
  #   GATE 15 LEG 3  `claims column: 8 kind=INVOCATION`                 ** ABSOLUTE **
  #   GATE 59  59a  the seeded figure printed [OPEN] WITH its adjudication reason  DISCRIMINATOR
  #   GATE 5b  5b-i   mixed-table class census 0 -> 2 (both twins)      ** ABSOLUTE **
  #   GATE 5b  5b-ii  mixed-table class census 0 -> 1 (one allow-rowed) ** ABSOLUTE **
  #   GATE 5b  5b-iii the NON-allow-rowed twin's own line                DISCRIMINATOR
  #   GATE 5b  5b-iv  the allowlist audit's COMPUTED `exemption live` line  DISCRIMINATOR
  # THE FIVE ADDED 2026-09-03 are the two zero-row registries' pairs. Three pin a line the run
  # can only print having READ the seeded registry row, which is the discriminator form. TWO
  # ARE ABSOLUTE AND SAY SO AT THEIR CALL SITES: 5b-i and 5b-ii pin the seed's contribution
  # (+2 and +1) on top of a live mixed-table census of ZERO, so the next live 5b finding turns
  # both red. That is a rot hazard, not a design, and the re-take recipe is written beside
  # them rather than left to be rediscovered.
  #
  # SCOREBOARD, 2026-08-11: FOUR of these are now RELATIVE (GATE 12 and GATE 25 converted
  # first; GATE 2's two converted the same night after they went RED). FOUR REMAIN ABSOLUTE
  # and each is a live rot hazard, not a design:
  #   GATE 3b      breaks when the corpus gains an allowlisted narration
  #   GATE 14      breaks on a 2nd adjudicated allowlist pair
  #   GATE 15      breaks on instrument #13
  #   GATE 15 L3   breaks on a 9th kind=INVOCATION row
  #   GATE 5b 5b-i breaks on the FIRST live mixed-table 5b finding (census 0 -> 1)
  #   GATE 5b 5b-ii breaks on that same event, for the same reason
  # SIX REMAIN ABSOLUTE as of 2026-09-03, not four. The number is restated ONLY because the
  # two new ones landed in the SAME change as this line, which is the one condition under
  # which restating a count in a comment is not the caveat-4 shape this block is about.
  # WHY THIS LIST WAS WRONG BEFORE, which is the argument for keeping it exact: it said
  # "44 -> 45" (live ERE is 45 -> 46), listed GATE 2's two pins as absolute after they had
  # been converted, said "THE LAST TWO ARE RELATIVE" when four were, and named only three
  # hazards when there are four. A disclosure block that under-reports its own debt is the
  # same defect the suite exists to catch — and this one drifted twice in one night, once by
  # the corpus moving and once by a fix landing without updating it.
  # The conversion recipe is at GATE 12's control. The four survivors are green TODAY and are
  # left converted-not-yet on a deliberate risk judgement — a currently-green leg is a worse
  # place to apply a technique unsupervised than a currently-red one — NOT because the pins
  # are sound. They are not.
  # The last three pin a COUNT THAT THE DEFECT THE CONTROL IS ABOUT WOULD MOVE, which is
  # weaker than a discriminator but still strictly stronger than rc 0: GATE 14's
  # adjudicated-pair count, GATE 15's instrument count, and GATE 15 LEG 3's claims census.
  # NONE now pins only "the leg ran".
  #
  # NOT SCANNED BY GATE 16, and that is a reasoned exemption rather than an oversight: a
  # preflight-emittable ERE cannot produce a false [ok] here, because both preflights set
  # RC=1 at their `preflight_tracked_docs || RC=1` / `preflight_support_newlines || RC=1` call
  # sites, so a firing preflight fails this assertion at the rc test before the ERE is
  # consulted at all. See GATE 16's caveat (a). (Cited by NAME, not line number: a same-file
  # line citation drifts on every insertion above it, and both of these were stale within
  # the hour they were written — caught by this batch's own Phase-4 pass.)
  assert_stays_clean_why() {
    local label="$1" gate="$2" want="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject; assertion did NOT run."
                           PASS=1; _selftest_revert; return; }
    out=$(bash "$0" "$gate" 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -ne 0 ]; then
      echo "  [FAIL] $label — $gate fired on a case it is supposed to leave alone"
      PASS=1; return
    fi
    if grep -qE -- "$want" <<<"$out"; then
      echo "  [ok]   $label — stays green, and its output names: $want"
    else
      echo "  [FAIL] $label — $gate stayed green, but its output never names \"$want\","
      echo "         so this assertion cannot tell an exemption that ran from a leg that"
      echo "         never looked. If the corpus moved a pinned COUNT, re-take the number"
      echo "         from a real run under this mutation; do not weaken the ERE."
      PASS=1
    fi
  }

  echo "== DOC GATES SELF-TEST (mutation) =="

  # ITEM A3 FIRE-PROOF (the mutual-exclusion half), IN-HARNESS and re-proven every run.
  #
  # This is here rather than in a note because of what happened to GATE 8's: its fire-proof
  # was taken by hand, never re-run after its invocation was rewritten, and a one-directional
  # comparison shipped behind it. A lock asserted only in a commit message decays the same
  # way. So the assertion runs from INSIDE a live self-test, where the lock is held: the
  # nested call must be refused, and refused FOR THE LOCK REASON. Asserting only on rc 2
  # would be satisfied by the dirty-tree refusal, the depth guard, or a missing file — three
  # different ways to pass without the lock working at all. The tree is clean at this point
  # (it is the harness's own precondition and no mutation has run yet), so the dirty-tree
  # branch cannot be what answers.
  _a3_out=$(bash "$0" --selftest 2>&1); _a3_rc=$?
  if [ "$_a3_rc" -eq 2 ] && grep -q 'another --selftest is running' <<<"$_a3_out"; then
    echo "  [ok]   A3 lock — a concurrent --selftest is refused, and the refusal names the lock"
  else
    echo "  [FAIL] A3 lock — a concurrent --selftest was not refused for the LOCK reason (rc=$_a3_rc)"
    printf '%s\n' "$_a3_out" | head -3 | sed 's/^/           > /'
    PASS=1
  fi

  # ITEM R15 FIRE-PROOF (round 14) — the advisory that covers the case the A3 lock does NOT.
  # Placed here, immediately after A3 and BEFORE any mutation, for the same reason A3 is here:
  # the lock is genuinely held by this process right now, so the motivating example can be RUN
  # rather than described, and the tree is still clean so nothing else can be what answers.
  #
  # THE MOTIVATING EXAMPLE IS "a gate run started by somebody else while a self-test holds the
  # lock". `env -u DOC_GATES_SELFTEST_DEPTH` is what that looks like from this side: an
  # invocation that did not inherit the descendant marker. Asserting on rc would prove
  # nothing — the advisory deliberately leaves RC alone — so the assertion is on the message
  # AND on the holder pid it names, which is $$ and no other number.
  #
  # THE NEGATIVE CONTROL IS THE HALF THAT COSTS SOMETHING, and it is why this shipped at all.
  # The identical command WITH the marker inherited (i.e. exactly how this harness invokes
  # every gate) must stay SILENT. Without that suppression the advisory prints into every
  # nested run whose stdout another assertion greps, and this suite fails for reasons having
  # nothing to do with the gate under test — which is precisely why a first attempt at R15 was
  # worked and withheld. A one-directional fire-proof is GATE 8's shipped defect; both
  # directions run here, every run, from the same lock.
  #
  # WHAT THIS CANNOT SEE: it proves the advisory fires and suppresses correctly for THIS
  # probe's single-gate dispatch. It does not prove the message is readable in the `generated`
  # dispatch that motivated R15 (too costly to run twice inside the self-test), and it says
  # nothing about whether a hard refusal would be better than a note — that is the operator
  # call recorded at the advisory's definition.
  _r15_gate=regdupes
  _r15_indep=$(env -u DOC_GATES_SELFTEST_DEPTH bash "$0" "$_r15_gate" 2>&1)
  _r15_desc=$(bash "$0" "$_r15_gate" 2>&1)
  if grep -q 'DO NOT TRUST THIS VERDICT' <<<"$_r15_indep" \
     && grep -q "pid $$" <<<"$_r15_indep" \
     && ! grep -q 'DO NOT TRUST THIS VERDICT' <<<"$_r15_desc"; then
    echo "  [ok]   R15 concurrency advisory — an independent '$_r15_gate' run started against"
    echo "         this live lock is warned and names the holder (pid $$); the same run as a"
    echo "         descendant of the lock holder stays silent, so the harness's own captured"
    echo "         gate output is unaffected"
  else
    echo "  [FAIL] R15 concurrency advisory — the advisory did not behave in BOTH directions."
    grep -q 'DO NOT TRUST THIS VERDICT' <<<"$_r15_indep" \
      || echo "         independent run: NOT warned — the concurrency hole is open again"
    grep -q "pid $$" <<<"$_r15_indep" \
      || echo "         independent run: warned, but never named the holder pid $$ — so this"
    grep -q "pid $$" <<<"$_r15_indep" \
      || echo "         assertion could not tell the advisory from any other note"
    grep -q 'DO NOT TRUST THIS VERDICT' <<<"$_r15_desc" \
      && echo "         descendant run: WARNED — suppression is OFF. DOC_GATES_SELFTEST_DEPTH"
    grep -q 'DO NOT TRUST THIS VERDICT' <<<"$_r15_desc" \
      && echo "         is the key; it stopped being exported by --selftest or inherited here."
    PASS=1
  fi

  # ITEM A1 FIRE-PROOF — the snapshot must be WRITTEN and READABLE BACK, asserted in-harness
  # and re-proven every run.
  #
  # THIS ASSERTION EXISTS BECAUSE ITS ABSENCE ALREADY COST A SHIPPED DEFECT. `_selftest_revert`
  # went out at fbdbe26 with a commit message claiming "the ref's reflog keeps one entry per
  # revert, so the third-from-last is still reachable". After a full 57-assertion run the ref
  # RESOLVED and its reflog held ZERO entries: git's default core.logAllRefUpdates writes
  # reflogs only for refs/heads, refs/remotes, refs/notes and HEAD, so every revert but the
  # last had been overwritten with no record. Reading the code could not show that — `git
  # update-ref` succeeds either way and every documented recovery command still appeared to
  # work. Only running it and COUNTING found it, which is why the count is now the assertion.
  #
  # It asserts TWO things, because either alone is satisfiable by a broken snapshot: the
  # reflog GREW (so history is retained, not just the latest value) and the discarded text is
  # actually readable out of @{0} (so the object holds the pre-revert tree, not an empty one).
  _A1_REF=refs/doc-gates/selftest-revert
  _a1_before=$(git reflog "$_A1_REF" 2>/dev/null | wc -l)
  if python3 -c "open('documentation/GUIDE.md','a',encoding='utf-8').write(
chr(10)+'<!-- A1 snapshot probe: this line is discarded and must stay recoverable -->'+chr(10))" 2>/dev/null; then
    _selftest_revert documentation/GUIDE.md
    _a1_after=$(git reflog "$_A1_REF" 2>/dev/null | wc -l)
    if [ "$_a1_after" -gt "$_a1_before" ] \
       && git show "$_A1_REF@{0}:documentation/GUIDE.md" 2>/dev/null | grep -c 'A1 snapshot probe' >/dev/null; then
      echo "  [ok]   A1 snapshot — a reverted edit is read back from $_A1_REF@{0}, and the"
      echo "         reflog grew ($_a1_before -> $_a1_after), so earlier reverts survive too"
    else
      echo "  [FAIL] A1 snapshot — the discarded edit is NOT recoverable (reflog $_a1_before ->"
      echo "         $_a1_after). Every revert in this harness is silently unrecoverable; check"
      echo "         that update-ref still passes --create-reflog."
      PASS=1
    fi
  else
    echo "  [FAIL] A1 snapshot — could not inject the probe, so the assertion did NOT run."
    PASS=1
  fi
  # THE SIGNAL HALF CANNOT BE ASSERTED HERE — a case that TERMs the self-test kills the
  # harness that would report on it. It was proven externally and deterministically on
  # 2026-08-02: with a run live and holding the lock, a marker line was appended to
  # example/report.html FROM OUTSIDE, then SIGTERM sent. Result: rc 143, final line
  # "DOC GATES SELF-TEST: TERMINATED (tree restored, lock released)", marker gone, lock
  # gone, `git status --porcelain` empty. An earlier version of that proof TERM'd before any
  # mutation existed and was therefore VACUOUS — "tree restored" was true of a tree that had
  # never been dirtied. The recorded proof is the second, non-vacuous one.

  # GATE 1 is REPORT-ONLY (`return 0`) and only inspects integers of >=12 digits. Asserting a
  # non-zero exit was wrong twice over: it can never exit non-zero, and the number I first
  # mutated has 10 digits so the gate would not look at it either way. Assert on its OUTPUT.
  # This also means "DOC GATES: PASS" has never included gate 1's findings — a real limit on
  # what that banner attests, now stated in the banner itself.
  # Anchor: the |C1nC2nC4nC5| exact count in README.md — 40 digits, non-round, and present
  # in more than one doc, which is exactly the shape gate 1 looks for. Flipping its last
  # digit creates a same-length near-twin sharing the first 10 digits: the corrupted-digit
  # case the gate exists to catch.
  python3 -c "s=open('README.md').read()
a='1,097,051,278,789,181,790,036,112,071,176,579,186,688'
assert a in s, 'anchor moved'
open('README.md','w').write(s.replace(a, a[:-1]+'9', 1))" 2>/dev/null \
    && { G1OUT=$(bash "$0" numbers 2>&1); G1RC=$?
         # Q-954 (a) (Codex Q835 P-07, A11#6): this was `grep -q 'WARN'`, which the numbers-mode
         # footer ("Read its [WARN]/[note] lines above") always satisfies, and key 40:1097051278
         # already WARNs on the unmutated tree (README's N beside QUERY_INVENTORY's N-1). Either
         # made the leg green with gate_numbers a no-op. It now requires the INJECTED value itself,
         # listed under a near-twin WARN as coming from README.md, and rc 0 (report-only).
         if [ "$G1RC" -eq 0 ] \
            && grep -qE '^  \[WARN\] near-twin long integers .* key 40:1097051278:$' <<<"$G1OUT" \
            && grep -qE '^ +1097051278789181790036112071176579186689 +<- README\.md$' <<<"$G1OUT"; then
           echo "  [ok]   GATE 1 cross-file numbers — lists the injected near-twin under its WARN (report-only gate)"
         else
           echo "  [FAIL] GATE 1 cross-file numbers — the injected near-twin is not listed under a WARN (rc=$G1RC)"
           printf '%s\n' "$G1OUT" | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert README.md; } \
    || { echo "  [FAIL] GATE 1 — the 40-digit |C1nC2nC4nC5| anchor is no longer in README.md,"
         echo "         so the assertion did NOT run (item A5). Re-anchor it on a non-round"
         echo "         integer of >=12 digits that appears in more than one doc."
         PASS=1; }

  # GATE 2's FLAG-DRIFT CLASSIFIER (item A3, 2026-08-02). Until now the only GATE 2
  # assertions were the A1 missing-INPUT legs — delete sat.py, delete SAT_CLI.md — which
  # prove the gate notices its inputs are gone and nothing at all about whether it can still
  # spot an undocumented flag. That is the leg that has fired in anger (13 undocumented
  # flags, 2026-07/08), and it was the one thing GATE 2 exists for that no assertion touched.
  #
  # THE STATED BLOCKER WAS WRONG, and the correction is the point. The coverage note said
  # injecting a flag "would mutate solve.py, a costlier revert than the assurance is worth".
  # The revert is `_selftest_revert`'s `git checkout -- .`, which restores a modified
  # solve.py at exactly the cost it restores a modified GUIDE.md — the A1 legs already
  # `os.remove` a tracked source file and restore it the same way. The cost claim was
  # inherited, never measured, and it kept the gate's only real leg unproven for a round.
  #
  # BOTH EXTRACTORS, because they are two different regexes and only one is exercised per
  # pair: `add_argument\("--...` for py mode (roae.py, solve.py) and a bare quoted `"--..."`
  # for c mode (solve.c, sat.py). A fire-proof on one says nothing about the other. c mode is
  # injected into sat.py, not solve.c: solve.c is sha-anchored, and sat.py already carries
  # the A1 legs, so it is the established mutation target for this pair's shape.
  #
  # EACH INJECTION IS SYNTACTICALLY VALID PYTHON, deliberately. A comment carrying the same
  # text would satisfy the grep just as well — the gate never imports the file — but then a
  # revert that failed would leave a broken module behind, and the assertion would prove the
  # extractor sees TEXT rather than that it sees a FLAG. (That the two are the same thing to
  # this gate is a real property of it: a commented-out `add_argument("--x"` WOULD be
  # reported as undocumented. Recorded, not fixed; widening is not a fire-proof's business.)
  #
  # THE FLAG NAMES DIFFER PER ASSERTION (-py, -c, -neg) so the evidence ERE identifies which
  # extractor answered. An ERE naming only the file pair would be satisfied by any unrelated
  # drift in the same file, which is the class of false clear this harness exists to refuse.
  assert_fires_why "GATE 2 flag drift — undocumented flag, py extractor (solve.py)" cli \
    '--doc-gates-fireproof-py' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    parser.add_argument(\"--doc-gates-fireproof-py\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  assert_fires_why "GATE 2 flag drift — undocumented flag, c extractor (sat.py)" cli \
    '--doc-gates-fireproof-c' \
"p='sat.py'
a='    if \"--with-c3\" in args:'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    _doc_gates_fireproof = \"--doc-gates-fireproof-c\" in args\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  # THE NEGATIVE CONTROL, and it is not optional. The two assertions above are equally
  # consistent with "the gate compares code against doc" and with "the gate fails on any
  # flag name it has not seen before". Adding the SAME flag to both sides must leave it
  # silent; if this one ever fires, the comparison has stopped being a comparison.
  # EVIDENCE (round 8 drain-3, UPGRADED round 9 item B9): `solve.py fully documented` is
  # GATE 2's per-file pass line, so a green run that never reached the
  # solve.py<->SOLVE_PY_CLI.md comparison cannot print it. That pinned only that the LEG RAN
  # — round 8 said so plainly, and B9 is the fix rather than a re-statement. The pass line
  # now carries a census, and this ERE pins the POST-INJECTION values: clean, solve.py is
  # `78 flag(s) compared against 95 documented`; under this mutation both sides gain exactly
  # one, so a run that did not re-read either file prints 78/95 and this leg goes RED.
  # MEASURED under this very mutation, not arithmetic off the clean run.
  # RELATIVIZED 2026-08-11 (same class as GATE 12 / GATE 25's converted controls). These two
  # legs pinned ABSOLUTE censuses — `79 … 96` and `78 … 95` — and both went RED the moment a
  # sibling change added 12 flags to solve.py, moving the live census to 90/107. That is the
  # third and fourth instance of this rot found in one night; the base is now read at runtime
  # so the corpus can move without falsifying a leg that is still testing the right thing.
  # GATE 16 SEES ONLY THE FRAGMENT ` flag\(s\) compared against ` here, for the piecewise-
  # quoting reason recorded at GATE 25's converted control: the real ERE contains it, so a
  # fragment no preflight can emit guarantees an ERE no preflight can emit.
  _G2_BASE=$(bash "$0" cli 2>&1)
  _G2_LINE=$(printf '%s' "$_G2_BASE" | grep -F 'solve.py fully documented in documentation/SOLVE_PY_CLI.md' | head -1)
  _G2_F=$(printf '%s' "$_G2_LINE" | grep -oE '\([0-9]+ flag' | grep -oE '[0-9]+')
  _G2_D=$(printf '%s' "$_G2_LINE" | grep -oE 'against [0-9]+ documented' | grep -oE '[0-9]+')
  if [ -z "$_G2_F" ] || [ -z "$_G2_D" ]; then
    echo "  [FAIL] GATE 2 negative controls — the base 'cli' run printed no solve.py census"
    echo "         line, so the two controls below have no base to compare against. A leg that"
    echo "         cannot read its own base is silent, not clean."
    PASS=1; _G2_F=-1; _G2_D=-1
  fi
  assert_stays_clean_why "GATE 2 — a flag added to BOTH solve.py and its CLI doc stays silent" cli \
    'solve\.py fully documented in documentation/SOLVE_PY_CLI\.md \('"$((_G2_F + 1))"' flag\(s\) compared against '"$((_G2_D + 1))"' documented' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    parser.add_argument(\"--doc-gates-fireproof-neg\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))
d='documentation/SOLVE_PY_CLI.md'
t=open(d,encoding='utf-8').read()
open(d,'w',encoding='utf-8').write(t+'\ndoc_gates selftest injection: --doc-gates-fireproof-neg (reverted by the harness)\n')"

  # ITEM A4 (2026-08-02) — THE COMMENTED-OUT DECLARATION, PROVEN AS A MATCHED PAIR.
  #
  # The round-6 note recorded that a commented-out `# parser.add_argument("--x"` was emitted
  # as an undocumented flag (measured: it returned --commented-out-flag), and asked for a
  # decision rather than a rediscovery. Decided: NARROW — the reasoning is at the extractor.
  #
  # TWO LEGS WITH ONE FLAG NAME, and the pairing is the point. "Stays green" is also what a
  # gate prints when the injection never landed, when the extractor stopped working, and
  # when the whole comparison was silently disabled — so a lone negative control here would
  # be indistinguishable from the filter swallowing every flag in solve.py. The fire leg
  # injects `--doc-gates-fireproof-cmt` UNCOMMENTED and requires GATE 2 to name it; the
  # clean leg injects the SAME text COMMENTED OUT, one `# ` apart, and requires silence. The
  # only difference between the two runs is the comment marker, so the silence is
  # attributable to the marker and to nothing else.
  assert_fires_why "GATE 2 (A4) a LIVE declaration of the paired flag is still reported" cli \
    '--doc-gates-fireproof-cmt' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    parser.add_argument(\"--doc-gates-fireproof-cmt\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  # EVIDENCE (item B9): this is the leg a FLAG count could never discriminate — the whole
  # property under test is that the injected line does NOT become a flag, so `78 flag(s)
  # compared against 95 documented` is what a run that never looked would print too. The
  # census therefore carries a THIRD number for exactly this leg: commented-out declarations
  # DROPPED by the item-A4 filter, which is 0 on a clean tree and 1 under this mutation. The
  # ERE pins all three, so it now proves the line was read AND classified as a comment,
  # rather than that the mode exited 0.
  assert_stays_clean_why "GATE 2 (A4) the SAME declaration commented out is not a flag" cli \
    'solve\.py fully documented in documentation/SOLVE_PY_CLI\.md \('"$_G2_F"' flag\(s\) compared against '"$_G2_D"' documented, 1 commented-out declaration\(s\) dropped\)' \
"p='solve.py'
a='    parser.add_argument(\"--pairs\", action=\"store_true\",'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
n='    # parser.add_argument(\"--doc-gates-fireproof-cmt\", action=\"store_true\", help=\"doc_gates --selftest injection; reverted by the harness\")\n'
open(p,'w',encoding='utf-8').write(s.replace(a,n+a,1))"

  # Q-748 (a) — GATE 2 (BLOCKING) MUST FAIL WHEN IT CANNOT MAKE ITS TEMP FILES. RED BEFORE,
  # measured 2026-09-24 (Opus FF) on the batch-1..4 staged tree: `TMPDIR=/dev/null ... cli`
  # printed five `[FAIL] GATE 2: mktemp failed, so NOTHING was checked.` lines and then
  # `DOC GATES: PASS  (cli)`, rc 0 — check_pair returned 1 without bad=1 and no caller reads
  # check_pair's status. The printed [FAIL] is therefore NOT evidence; the leg asserts on rc AND
  # on the WHY line together, because the before-copy prints the same WHY line at rc 0.
  # Written inline, not through assert_fires_why: there is no file to mutate (the environment
  # is the defect), and the helper's callers=N is pinned in DOC_GATE_SELFTEST_INSTRUMENTS.txt.
  _Q748_OUT=$(TMPDIR=/dev/null bash "$0" cli 2>&1); _Q748_RC=$?
  if [ "$_Q748_RC" -eq 1 ] \
     && grep -qF '[FAIL] GATE 2: mktemp failed, so NOTHING was checked.' <<<"$_Q748_OUT" \
     && ! grep -qE '^DOC GATES: PASS' <<<"$_Q748_OUT"; then
    echo "  [ok]   GATE 2 (Q-748a) mktemp failure under TMPDIR=/dev/null is a FAIL (rc=$_Q748_RC), not a PASS"
  else
    echo "  [FAIL] GATE 2 (Q-748a) — with mktemp failing, GATE 2 compared NOTHING and returned rc=$_Q748_RC"
    printf '%s\n' "$_Q748_OUT" | grep -E 'GATE 2|DOC GATES' | sed 's/^/           > /' | head -4
    PASS=1
  fi

  # A5/#65: assert the MATCHED STRING, not just the exit code. GATE 3's registry holds
  # morphology-independent stems, so several rows can be live at once and an exit code alone
  # cannot say which one saw the injection.
  assert_fires_why "GATE 3 retracted phrasing" retract \
    'matched as the fixed string: "hard floor k>=13"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ordering has a hard floor k>=13 by construction.\n')"

  # Q-761 — A REGISTERED NEEDLE THAT STARTS WITH `#` IS A ROW, NOT A COMMENT. RED BEFORE,
  # measured 2026-09-24 (Opus FF) on the batch-1..4 staged tree: every leg below went RED,
  # because GATE 3 and GATE 11 skipped any row whose PHRASE began with `#` (`case '#'*`), so
  # the planted needle was never searched for and never ledger-checked, at rc 0. The needle
  # starts `#7/#8` because that is the shape that was lost (Opus DD's hexagram-number needle).
  # Inline, not assert_fires_why, for the callers=N reason given at the Q-748 leg above; the
  # revert is a plain `git checkout --` of exactly the two files touched.
  _Q761_N='#7/#8 doc-gates Q-761 synthetic retracted needle'
  _Q761_K="RP-$(printf '%s' "$_Q761_N" | sha256sum | cut -c1-8)"
  # LEG 1 — GATE 3 must SEARCH for it: planted in a doc, it must FAIL naming the needle.
  printf '%s\t%s\t%s\n' "$_Q761_N" '__none__' 'Self-test row (Q-761); reverted by the harness.' \
    >> documentation/RETRACTED_PHRASES.tsv
  printf '\n\nSelf-test sentence: %s here.\n' "$_Q761_N" >> documentation/GUIDE.md
  _Q761_OUT=$(bash "$0" retract 2>&1); _Q761_RC=$?
  git checkout -- documentation/RETRACTED_PHRASES.tsv documentation/GUIDE.md 2>/dev/null
  if [ "$_Q761_RC" -eq 1 ] \
     && grep -qF "retracted phrasing still present: \"$_Q761_N\"" <<<"$_Q761_OUT"; then
    echo "  [ok]   GATE 3 (Q-761) a registered needle starting with '#' is searched for, and FIRES when planted"
  else
    echo "  [FAIL] GATE 3 (Q-761) — a needle starting with '#' planted in GUIDE.md was not reported"
    echo "         (rc=$_Q761_RC): the row was read as a comment and never searched for."
    PASS=1
  fi
  # LEG 2 — GATE 11 must LEDGER-CHECK it: registered with no CORRECTIONS entry, it must FAIL
  # naming its own RP key (computed here, never copied from a run).
  printf '%s\t%s\t%s\n' "$_Q761_N" '__none__' 'Self-test row (Q-761); reverted by the harness.' \
    >> documentation/RETRACTED_PHRASES.tsv
  _Q761_OUT=$(bash "$0" ledger-phrases 2>&1); _Q761_RC=$?
  git checkout -- documentation/RETRACTED_PHRASES.tsv 2>/dev/null
  if [ "$_Q761_RC" -eq 1 ] && grep -qF "[FAIL] $_Q761_K has NO entry" <<<"$_Q761_OUT"; then
    echo "  [ok]   GATE 11 (Q-761) a registered needle starting with '#' is ledger-checked ($_Q761_K)"
  else
    echo "  [FAIL] GATE 11 (Q-761) — a registered needle starting with '#' got no $_Q761_K verdict"
    echo "         (rc=$_Q761_RC): skipped as a comment."
    PASS=1
  fi
  # LEG 3 — the one indistinguishable form (`# ` + needle, WITH data columns) must be LOUD.
  printf '# %s\t%s\t%s\n' 'doc-gates Q-761 heading-shaped needle' '__none__' 'Self-test row (Q-761).' \
    >> documentation/RETRACTED_PHRASES.tsv
  _Q761_OUT=$(bash "$0" ledger-phrases 2>&1); _Q761_RC=$?
  git checkout -- documentation/RETRACTED_PHRASES.tsv 2>/dev/null
  if [ "$_Q761_RC" -eq 1 ] \
     && grep -qF 'Q-761: a registry line is comment-shaped' <<<"$_Q761_OUT"; then
    echo "  [ok]   GATE 11 (Q-761) a comment-shaped line carrying data columns is a FAIL, not a skip"
  else
    echo "  [FAIL] GATE 11 (Q-761) — a '# '-shaped row with data columns was silently skipped (rc=$_Q761_RC)"
    PASS=1
  fi

  # GATE 3b — THREE cases, and the positive one is its OWN MOTIVATING EXAMPLE rather than a
  # synthetic string. reports/evidence/r11/PHASE2_README.md is the artifact that actually
  # carried an uncorrected "1.4σ above" after TR-2 v1.19 retracted it, surviving until a
  # human read it on 2026-08-02 (TR-2 v1.23). The mutation puts that sentence back, as a bare
  # assertion with none of the narration the allowlist anchors on.
  assert_fires_why "GATE 3b retracted figure restated (its own motivating example)" \
    retract-figures 'retracted figure "1\.4σ" restated' \
"p='reports/evidence/r11/PHASE2_README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nThe pooled value sits 1.4σ above the Phase-1 single run.\n')"

  # GATE 3b, LINE-BREAK EVASION. GATE 3's hardening note (a) records that a retracted phrase
  # once hid inside a hard wrap where line-based grep could not see it. GATE 3b matches
  # per-line so it can anchor exemptions, which reintroduces that exposure — the normalised
  # whole-file pass is the compensating branch, and this is the only thing that exercises it.
  assert_fires_why "GATE 3b retracted figure split across a hard wrap" \
    retract-figures 'spans a hard wrap' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nThe ledger prices C2 at marginal\n4.6 bits under that convention.\n')"

  # GATE 3b NEGATIVE CONTROL — the exemption must be driven by the ANCHOR, not by the file.
  # Same file as an existing allowlist row, same figure, and the row's anchor text present:
  # this must NOT fire. Without it, the [ok] above is equally consistent with the allowlist
  # having quietly exempted reports/evidence/ wholesale.
  # EVIDENCE (round 8 drain-3) — THE ONE MEASURED DISCRIMINATOR IN THE SIX. GATE 3b prints its
  # allowlisted-narration census, and that census MOVES when this injection is read: clean it
  # says `(1 historical, 1 literal, 45 meta-mention)`, under this mutation `46`. Both numbers were taken
  # from real runs in a scratch clone. So matching 45 proves the injected line was SEEN and
  # then EXEMPTED, which is the whole content of the claim; rc 0 alone is equally consistent
  # with the file having dropped out of the 79-file scan entirely.
  # 🔴 Q-702 (2026-09-24, Fable K): THE PIN ROTTED, AS GATE 12 (6)'s DID. It said 46 against a live
  # 63 (clean census 62) at 5c296837, so this control was RED for seventeen allowlisted narrations
  # the corpus gained since — not for anything about the gate. The count is now COMPARED, not
  # pinned: the clean census is taken from a real run first and the mutated run must print
  # exactly base+1. That is the same property ("the injected line was SEEN and then EXEMPTED")
  # with nothing to re-measure when the corpus grows, and it is strictly narrower than a range
  # ERE — base+1 is one number. A base run that prints no census is a FAIL, not a skip.
  _G3B_N=$(bash "$0" retract-figures 2>&1 | grep -oE '[0-9]+ meta-mention' | grep -oE '^[0-9]+')
  if [ -z "$_G3B_N" ]; then
    echo "  [FAIL] GATE 3b negative control — the clean retract-figures run printed no"
    echo "         'N meta-mention' census, so the control below has no base to compare"
    echo "         against. A control that cannot read its own base is silent, not clean."
    PASS=1; _G3B_N=-1
  fi
  assert_stays_clean_why "GATE 3b negative control — an anchored narration is exempt" \
    retract-figures "$((_G3B_N + 1))"' meta-mention' \
"p='reports/evidence/r11/README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nRestated for the index: this figure read 1.4σ until 2026-08-02.\n')"

  # FIRE-PROOF OF THE EVIDENCE HALF ITSELF (round 8 drain-3, item A1's residue). The six
  # negative controls above now claim to assert more than an exit code. Nothing above proves
  # that claim: all six are expected to pass, so all six would look identical if the ERE test
  # were inert — an `if` that never fails is exactly the shape GATE 8's one-directional
  # comparison had, and it survived because its fire-proof was taken by hand and never re-run.
  # So the failing direction runs here, every run.
  #
  # IT IS THE MOTIVATING DEFECT, NOT A STYLISED ONE. Same gate, same mutation, same green
  # run — scored against `44`, the census a run that NEVER READ the injected line prints.
  # That is precisely the state the corpus would be in if reports/evidence/r11/README.md were
  # renamed out of the 79-file scan: rc 0, [ok] under the old helper, and a negative control
  # that had silently stopped controlling anything.
  #
  # THE ASSERTION IS ON THE MESSAGE, NOT ON [FAIL]. A [FAIL] alone would also be produced by
  # the rc branch ("fired on a case it is supposed to leave alone"), so grepping for [FAIL]
  # would let a gate that broke for an unrelated reason stand in for the proof. It matches the
  # evidence branch's own sentence instead.
  #
  # PASS IS NOT CLOBBERED because the call runs inside a command substitution: the helper's
  # `PASS=1` dies with the subshell, while its `_selftest_revert` acts on the real tree and
  # persists. The expected [FAIL] text is captured, never printed.
  #
  # THE TWO NUMBERS MOVE TOGETHER, and since Q-702 neither is written down: the probe scores
  # against the CLEAN census the live assertion above measured (base), the assertion against
  # base+1. A mutated run that prints base is a run that never read the injection.
  _asc_probe=$(assert_stays_clean_why \
    "PROBE (expected to FAIL) — a green run scored against the census of a run that never read the injection" \
    retract-figures "$_G3B_N"' meta-mention' \
"p='reports/evidence/r11/README.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nRestated for the index: this figure read 1.4σ until 2026-08-02.\n')")
  if grep -q 'stayed green, but its output never names' <<<"$_asc_probe"; then
    echo "  [ok]   assert_stays_clean_why — a gate that stays green WITHOUT printing the"
    echo "         evidence line is a FAIL, so every negative control on it asserts more than"
    echo "         rc 0 (the COUNT is not restated here — it said six against a live seven,"
    echo "         and a stale number in PRINTED output is worse than one in a comment; the"
    echo "         authority is callers=N in DOC_GATE_SELFTEST_INSTRUMENTS.txt)"
  else
    echo "  [FAIL] assert_stays_clean_why — the evidence half is INERT. A green run that never"
    echo "         read the injected case was accepted, so every negative control in this"
    echo "         harness is back to asserting an exit code. Probe output:"
    printf '%s\n' "$_asc_probe" | head -3 | sed 's/^/           > /'
    PASS=1
  fi

  # DISPATCH NOTE (item A1, round 8; CORRECTED item B2, round 9, 2026-08-02). `links` is
  # gate_links_and_secrefs, i.e. GATE 4 AND GATE 4b behind one exit code. This used to be an
  # exit-code assertion and was therefore satisfied by a GATE 4b failure — the shared-dispatch
  # class GATES 10a/10b and 11-figures each got their own dispatch name for. Round 8 answered
  # that with an ERE instead of a dispatch name — "GATE 4's OWN line for the injected target,
  # so no third dispatch name is needed" — and the argument was TRUE and MEASURED (drain-2
  # confirmed the string is emitted nowhere in gate_secrefs, which is why this was latent and
  # not a live defect). It is retired anyway, because it was an argument about wording holding
  # a structural property: reword GATE 4b's finding line into the same shape and the assertion
  # silently stops distinguishing the two, with nothing looking. It now runs `links-internal`,
  # GATE 4 alone, and GATE 16 LEG 2 refuses a fire-proof on a combined name mechanically.
  assert_fires_why "GATE 4 internal links (documentation/GUIDE.md)" links-internal \
    'documentation/GUIDE\.md -> NO_SUCH_FILE_XYZ\.md +\(no such file\)' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nSee [the missing doc](NO_SUCH_FILE_XYZ.md).\n')"

  # GATE 4b, in the EXACT shape of its motivating defect: the link target resolves
  # (CRITIQUE.md exists, so phase 1 stays green) and only the section half is dead.
  # If this assertion ever passes-through, the extension has stopped seeing the one
  # class it was written for. The quoted form §\"...\" was verified by the same
  # method when the gate was written.
  #
  # DISPATCH (corrected 2026-08-02, item A3): this used to run `links`, which is GATE 4
  # AND 4b behind one exit code — so a phase-1 failure for any unrelated reason would
  # have satisfied the assertion with 4b never fired, printing [ok] for an unexercised
  # gate. It now runs `secrefs`, which is 4b alone; no other gate can supply that
  # exit code. (Compensated manually once, with phase 1 verified green by hand — a
  # by-hand guarantee the permanent assertion did not carry, which is the same shape as
  # GATE 8's hand-taken fire-proof going stale across a refactor.)
  # A5/#65: also assert the WHY line, which names the target file and the normalised text
  # that failed to resolve. 4b has an allowlist, so an exit code alone cannot distinguish
  # "fired on my injection" from "fired on a pre-existing entry that fell out of the list".
  # ERE re-anchored 2026-08-02 (item B1) because the WHY line changed when the gate learned a
  # second anchor form: it no longer says "no heading", it says nothing is NAMED that, and the
  # distinction is the whole point of the change. Re-proven by running --selftest after the
  # rewrite — the exact failure mode GATE 8's stale hand-taken proof is on record for.
  assert_fires_why "GATE 4b dangling section ref" secrefs \
    'WHY: nothing in documentation/CRITIQUE\.md is named "q7"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nPriced as data ([CRITIQUE.md](CRITIQUE.md) Q7).\n')"

  # ITEM A7 — GATE 4b's AMBIGUITY note, proven on the corpus's own weakest reference.
  #
  # documentation/HISTORY.md:5052 carries `MCKENNA.md §"Rule 2"`, which today resolves against
  # exactly one heading ("mckenna's rule 2 - declined for promotion to formal c-rule",
  # coverage ratio 0.10 — the weakest in the corpus). A7's hazard is stated in exactly these
  # terms: `§"Rule 2"` would ALSO resolve against a heading `"Rule 25"`. So the mutation adds
  # that heading and nothing else, and the note must appear.
  #
  # WHY THIS IS AN OUTPUT ASSERTION, not assert_fires_why: the note is REPORT-ONLY by design
  # (see the gate's A7 block), so `secrefs` still exits 0 and an rc-based assertion would fail
  # on a working gate. The injected heading creates no dangling reference, so rc 0 is also the
  # correct verdict — asserting on rc would prove the opposite of what is wanted.
  python3 -c "p='documentation/MCKENNA.md'
s=open(p,encoding='utf-8').read()
import re
h=[x for x in re.findall(r'^#+\s+(.*?)\s*\$', s, re.M) if 'Rule 2' in x]
assert len(h)==1, 'anchor moved: %d headings contain \"Rule 2\", expected exactly 1' % len(h)
open(p,'w',encoding='utf-8').write(s+chr(10)+chr(10)+'## McKenna Rule 25 (self-test heading)'+chr(10))" 2>/dev/null \
    && { A7OUT=$(bash "$0" secrefs 2>&1); A7RC=$?
         if [ "$A7RC" -eq 0 ] \
            && grep -q 'resolves against 2 headings, so it does' <<<"$A7OUT" \
            && grep -q 'mckenna rule 25 (self-test heading)' <<<"$A7OUT"; then
           echo "  [ok]   GATE 4b ambiguity note — a second matching heading is reported, and named"
         else
           echo "  [FAIL] GATE 4b did not note an ambiguous resolution (rc=$A7RC). A reference that"
           echo "         matches two headings identifies neither, which is the A7 hazard."
           printf '%s\n' "$A7OUT" | grep -E 'note|FAIL' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/MCKENNA.md; } \
    || { echo "  [FAIL] GATE 4b ambiguity case — could not inject; assertion did NOT run."; PASS=1; }

  # ITEM B1 (2026-08-02, drain-2) — SIX LEGS, EACH PROVEN LOAD-BEARING BY A MUTATION THAT
  # MUST CHANGE THE VERDICT. Three of them WIDEN the gate (legs 1, 3, 4), and a widened gate
  # is how a false clear gets built, so none of them is asserted by "the corpus is green
  # now" — each is asserted by a mutation that must turn it red.
  #
  # NAMED, NOT TALLIED (round 15, item R16). This header read "FOUR LEGS" while the block
  # below owned six, and the count was not re-derived when the block grew: legs 1-5 shipped
  # with B1's own commit (leg 5's comment says "this commit retired 19 of 22 rows"), and
  # LEG 6 was added by B1's PHASE-4 on its own batch. Nothing moved the number — the same
  # shape as GATE 17's "FIVE LEGS" against six (fixed at fa6ea90d) and as the five instances
  # recorded in the covered-list block below. A bare multiplicity cannot be checked by a
  # reader against reality; a named list can, which is the one property that distinguished
  # the censuses that survived from the ones that rotted. So:
  #   LEG 1 bold anchors are load-bearing      LEG 4 a hard wrap no longer hides a reference
  #   LEG 2 mid-line bold is NOT an anchor     LEG 5 an allowlist row exempting nothing
  #   LEG 3 a backticked path                  LEG 6 a bold-anchor resolution is REPORTED
  # LEG 7 is NOT B1's — it is item B4 (drain-1) and carries its own header below.

  # LEG 1, the bold-anchor form, proven on its own motivating example and in the DIRECTION
  # that matters. Asserting that METHODS.md §"Global observable ledger" resolves would be
  # satisfied by a gate that resolves everything; instead the anchor's `**` markers are
  # STRIPPED, which must break the five references that depend on them. If this ever stops
  # firing, the bold leg has become decorative and those five are resolving some other way.
  assert_fires_why "GATE 4b LEG 1: bold anchors are load-bearing (strip METHODS' label)" secrefs \
    'nothing in reports/METHODS\.md is named "global observable ledger"' \
"p='reports/METHODS.md'
s=open(p,encoding='utf-8').read()
a='- **Global observable ledger (enterprise-wide multiple comparisons).**'
assert s.count(a)==1, 'anchor moved: found %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'- Global observable ledger (enterprise-wide multiple comparisons).',1))"

  # LEG 2, the SCOPE of leg 1 — the negative control without which leg 1's [ok] is equally
  # consistent with "any bold text anywhere is an anchor". A line-leading label is an anchor;
  # emphasis in the middle of a sentence is not, and the corpus is full of the latter. Same
  # bold text, same file, mid-line: this must still be reported dangling.
  assert_fires_why "GATE 4b LEG 2: mid-line bold is NOT an anchor" secrefs \
    'nothing in documentation/GUIDE\.md is named "frobnicate the widget xyz"' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'Prose that mentions **Frobnicate the widget xyz** part-way through a sentence.'+chr(10)+chr(10)+'See [GUIDE.md](GUIDE.md) '+chr(167)+'\"Frobnicate the widget xyz\" for that.'+chr(10))"

  # LEG 3, the backtick path. Before this commit `\s*` could not cross the closing backtick,
  # so a reference written `` `documentation/X.md` §\"...\" `` was not extracted AT ALL — not
  # passed, not failed, invisible. One of the corpus's two was dead
  # (PARTITION_STABILITY_BOUNDARIES.md:83, pointing at a section de3422b had relocated).
  assert_fires_why "GATE 4b LEG 3: a backticked path no longer hides a dead reference" secrefs \
    'nothing in documentation/CRITIQUE\.md is named "no such section zzz"' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'See \`documentation/CRITIQUE.md\` '+chr(167)+'\"no such section zzz\" for that.'+chr(10))"

  # LEG 4, the two-line window. Same invisibility, different mechanism: the scan was
  # line-at-a-time, so a hard wrap between the file name and its §\"…\" hid the reference
  # completely. GATE 3's hardening note (a) records the identical evasion for a different
  # gate; MEASURED here, it was hiding 15 of 85 references, one of them dead
  # (SYMMETRY_SEARCH.md:275).
  assert_fires_why "GATE 4b LEG 4: a hard wrap no longer hides a dead reference" secrefs \
    'nothing in documentation/CRITIQUE\.md is named "no such wrapped section qqq"' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'See [CRITIQUE.md](CRITIQUE.md)'+chr(10)+chr(167)+'\"no such wrapped section qqq\" for that.'+chr(10))"

  # LEG 5, STALE ALLOWLIST ROWS. This commit retired 19 of 22 rows at once, which is exactly
  # the moment a dead exemption gets left behind — so the check against that ships with it.
  # The injected row exempts a reference that does not exist, which is what a row left over
  # from a fixed defect looks like, and it must be refused rather than quietly carried.
  assert_fires_why "GATE 4b LEG 5: an allowlist row that exempts nothing is refused" secrefs \
    'stale allowlist row: documentation/GUIDE\.md -> documentation/CRITIQUE\.md' \
"p='documentation/DOC_GATE_SECREF_ALLOWLIST.txt'
s=open(p,encoding='utf-8').read()
t=chr(9)
open(p,'w',encoding='utf-8').write(s+'documentation/GUIDE.md'+t+'documentation/CRITIQUE.md'+t+'a section nobody cites'+t+'self-test: exempts nothing'+chr(10))"

  # ITEM B1, PHASE-4 ON THIS UNIT'S OWN BATCH. Legs 1-5 all assert that the gate goes RED when
  # something is broken. NONE of them asserts the promise the bold leg was allowed to ship on:
  # that a bold-anchor resolution is PRINTED rather than cleared. Delete the [bold-anchor] loop
  # and every leg above still passes, while eighteen weak resolutions become invisible — the
  # exact "clears are weaker than failures" outcome the leg's own comment argues against.
  #
  # So this asserts the REPORT, on a reference the corpus has never contained: the gate must
  # stay GREEN (it resolves) and must NAME it. Both halves are load-bearing — rc alone would be
  # satisfied by a gate that skipped the reference entirely, and the grep is anchored to
  # GUIDE.md because the same bold label is already reported for two other files, so an
  # unanchored match would be satisfied by output that has nothing to do with the injection.
  #
  # PROVEN DISCRIMINATING, not assumed (2026-08-02): the same injection was run against a COPY
  # of this script with the [bold-anchor] print loop deleted and nothing else changed. The
  # anchored grep counted 1 against the live script and 0 against the copy, while the copy
  # still exited 0 — i.e. the deletion produces exactly the silent green this asserts against.
  # An assertion that has never been shown to fail is not a proof, which is the whole reason
  # GATE 8 shipped a one-directional comparison.
  python3 -c "p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'See [CRITIQUE.md](CRITIQUE.md) '+chr(167)+'\"Per-branch yield labels in the canonical\" for that.'+chr(10))" 2>/dev/null \
    && { B1OUT=$(bash "$0" secrefs 2>&1); B1RC=$?
         if [ "$B1RC" -eq 0 ] \
            && grep -qE '\[bold-anchor\] documentation/GUIDE\.md:[0-9]+ -> documentation/CRITIQUE\.md' <<<"$B1OUT"; then
           echo "  [ok]   GATE 4b LEG 6: a bold-anchor resolution is REPORTED, not cleared"
         else
           echo "  [FAIL] GATE 4b LEG 6 — a reference resolving only via the weaker anchor form was"
           echo "         not named in the output (rc=$B1RC). Resolving it silently is the clear"
           echo "         this leg was allowed to ship on the promise of never producing."
           printf '%s\n' "$B1OUT" | grep -E 'bold-anchor|FAIL' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/GUIDE.md; } \
    || { echo "  [FAIL] GATE 4b LEG 6 — could not inject; assertion did NOT run."; PASS=1; }

  # ITEM B4 (2026-08-02, drain-1) — LEG 7, the PREFIX RULE, proven on the REAL defect that
  # motivated it rather than on a synthesised one. `f3179f8` measured prefix anchoring at 1 of
  # 18 and then FIXED that one, so by the time the rule shipped its population was 0 — which is
  # exactly the situation in which a new gate can ship decorative and nobody notices. The
  # mutation therefore re-injects the historical defect verbatim: CITATIONS.md's reference to
  # SPECIFICATION.md's wrap-around-parity theorem, narrowed back to the form that resolved at
  # OFFSET 9 inside "theorem (wrap-around parity is odd)".
  #
  # BOTH HALVES ARE LOAD-BEARING. rc alone would be satisfied by any unrelated failure the
  # mutation happened to cause, so the ERE pins the gate's own WHY on this exact target.
  #
  # WHICH CLAUSE IS LOAD-BEARING WAS RE-VERIFIED 2026-08-02 (round 10, drain-2), AND THE
  # STANDING MAINTENANCE NOTE CARRIED INTO ROUND 10 NAMED THE WRONG ONE. That note said this
  # proof is meaningful only while the ERE remains the gate's FAIL wording "no line-leading
  # bold label BEGINS with it". IT IS NOT THAT STRING. That phrase occurs exactly ONCE in
  # this file, in the WHY message itself, and NO assertion anywhere asserts on it. The ERE
  # below is the message's FIRST clause, `nothing in <doc> is named "<normalised section>"`,
  # and what makes it unprintable by a build without the prefix rule is not its wording but
  # its TARGET: without the rule the mutated reference RESOLVES, at offset 9 inside a bold
  # label, so the gate prints nothing about it at all.
  #
  # THE MAINTENANCE CONDITION IS THEREFORE, EXACTLY: re-take this proof from a run if the
  # `nothing in {d} is named "{norm(s)}"` clause is reworded, if `norm()` changes what the
  # section title normalises to, or if this reference gains an allowlist row (which would
  # route it to [OPEN] instead of [FAIL]). Rewording the prefix-rule clause does NOT void it.
  # Recording the wrong trigger is worse than recording none: it invites a future unit to
  # rewrite the clause that IS load-bearing believing the proof does not depend on it.
  #
  # WHAT IT DOES NOT PROVE, both directions: that no OTHER weak resolution exists — the leg
  # covers the one form the corpus is known to have produced; and that no OTHER finding in
  # the same `secrefs` output could print the same line. The second rests on GATE 4b being
  # GREEN on the clean tree, so the mutated reference is the only unresolved citation of that
  # target in the run. That is a real argument and it is a standing one, re-established by
  # every green `all`, but it is an argument about the corpus rather than a check.
  assert_fires_why "GATE 4b LEG 7: a bold label matched mid-text is not an anchor" secrefs \
    'nothing in documentation/SPECIFICATION\.md is named "wrap-around parity"' \
"p='documentation/CITATIONS.md'
s=open(p,encoding='utf-8').read()
a='[SPECIFICATION.md](SPECIFICATION.md) '+chr(167)+'\"Theorem (Wrap-around parity is odd)\"'
assert s.count(a)==1, 'anchor moved: found %d occurrences' % s.count(a)
b='[SPECIFICATION.md](SPECIFICATION.md) '+chr(167)+'\"wrap-around parity\"'
open(p,'w',encoding='utf-8').write(s.replace(a,b,1))"

  # ITEM A6 — the corpus-wide final-newline PREFLIGHT, proven on a file whose own gate does
  # NOT check it. RETRACTED_FIGURES.tsv would be the obvious target and is the wrong one:
  # GATE 11 already guards it, so the case would pass with the preflight deleted.
  # DOC_GATE_SECREF_ALLOWLIST.txt has no such guard, and — measured — is read by python file
  # iteration, which does not drop an unterminated line, so NOTHING but the preflight can be
  # what answers here. The ERE is the preflight's own wording, which deliberately shares no
  # substring with require_final_newline's ("does not end with a newline"), so GATE 11's
  # fire-proof and this one cannot be satisfied by each other's output.
  assert_fires_why "A6 preflight: a gate-support file loses its final newline" secrefs \
    'gate-support file has no final newline: documentation/DOC_GATE_SECREF_ALLOWLIST\.txt' \
"p='documentation/DOC_GATE_SECREF_ALLOWLIST.txt'
s=open(p,encoding='utf-8').read()
assert s.endswith(chr(10)), 'anchor moved: the file does not currently end with a newline'
open(p,'w',encoding='utf-8').write(s[:-1])"

  # A5/#65: assert the matched string AND that a file:line is cited (the location GATE 6
  # did not print until 2026-08-02). `\.py:[0-9]` is what proves the location half.
  assert_fires_why "GATE 6 figure generators" figures \
    'matched as the fixed string: "hard floor k>=13"' \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  # ITEM A8: the FIGURE half of GATE 6. The phrase assertions above cannot cover it — they
  # inject a registered PHRASE, which the phrase loop would catch whether or not the figure
  # loop exists. This injects a registered STATISTIC, which nothing in this repo could see
  # before today: GATE 3b is markdown-only, and matplotlib renders the annotation to glyph
  # paths. The assertion names the registry's own string so it cannot be satisfied by the
  # phrase leg firing.
  assert_fires_why "GATE 6 a retracted FIGURE annotated into a generator (item A8)" figures \
    'retracted FIGURE in a figure generator: "~5,500×"' \
"import glob,sys
c=sorted(glob.glob('viz/*.py'))
sys.exit(1) if not c else None
s=open(c[0],encoding='utf-8').read()
open(c[0],'w',encoding='utf-8').write(s+chr(10)+'# annotate(\"rarer by ~5,500× than chance\")'+chr(10))"

  # ITEM A8 + A1: the figure registry's own missing-input leg. Absent registry, absent check
  # — and the message must name THIS registry, not the phrase one, or a maintainer restores
  # the wrong file.
  assert_fires_why "GATE 6 (A1) figure registry deleted" figures \
    'RETRACTED_FIGURES\.tsv is tracked in git but missing from the working tree' \
"import os
f='documentation/RETRACTED_FIGURES.tsv'
assert os.path.exists(f), 'anchor moved'
os.remove(f)"

  assert_fires_why "GATE 6 figure generators name the LINE, not just the file" figures \
    'viz/.*\.py:[0-9]+  — regenerate' \
"import glob,sys
c=[f for f in glob.glob('viz/*.py')]
sys.exit(1) if not c else None
s=open(c[0]).read()
open(c[0],'w').write(s+'\n# hard floor k>=13\n')"

  # A5/#65: GATE 7's LIVE list has seven keywords and its DISPO suppression list has
  # sixteen; the finding line names the keyword that matched, and that is what this asserts.
  assert_fires_why "GATE 7 frozen run status" liveness \
    'status frozen in the present tense: "in flight"' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe ladder build is in flight and the log is 3,666 lines and growing.\n')"

  # A5/#65: 1120T is the MENTIONED-but-sha-less shape, not the absent-from-registry shape, and the two need different fixes — so assert the branch, not just the failure; a "~" (Fable B40 FIX 1) does not make it a measured extent.
  assert_fires_why "GATE 7 approximate mentioned budget" liveness 'mentioned is not attested' "s=open('documentation/GUIDE.md').read(); open('documentation/GUIDE.md','w').write(s+'\n\nThe ~1120T run reproduced the published ladder exactly.\n')"
  assert_fires_why "GATE 7 unreached budget" liveness \
    'with no sha of its own' \
"s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+'\n\nThe 1120T run reproduced the published ladder exactly.\n')"

  # GATE 7's FIRST NEGATIVE CONTROL (item R18, round 15 drain-1). Until this leg, BOTH of
  # GATE 7's fire-proofs were assert_fires_why — a gate proven only to fire cannot tell
  # "correctly silent" from "silently broken", which is the argument the GATE 2 (A4) pair
  # above makes for its own two legs.
  #
  # IT ASSERTS THE R18 FIX ON ITS OWN MOTIVATING TEXT. GATE 7 fired on the phrase
  # "concurrently running", which contains the LIVE key "currently running" across a word
  # boundary; `all` went FINDINGS rc=1 and the corpus was reworded to satisfy it. The
  # injection is that exact phrase. Before the WORDSTART boundary this mutation turned
  # `liveness` red — that is what the item is — so this leg fails on a revert of the fix
  # rather than merely accompanying it.
  #
  # BOTH HALVES ARE LOAD-BEARING. rc alone would be satisfied by a gate that had stopped
  # reading the corpus at all, so the ERE pins GATE 7's own clean verdict, which it prints
  # only after walking every file. That string is not emittable by either preflight.
  #
  # WHAT IT DOES NOT PROVE: that the OTHER six LIVE keys are boundary-safe. They are
  # deliberately not — 'is underway' must keep matching inside "analysis underway" — so
  # there is nothing here to assert for them. It also does not prove the phrase is absent
  # from the corpus; the corpus carries 18 `concurrent*` tokens and this leg is why one of
  # them may sit next to "running" again without re-costing a reword.
  assert_stays_clean_why "GATE 7 negative control — \"concurrently running\" is not a liveness claim" \
    liveness 'no frozen run status; every budget-named run carries a disposition' \
"s=open('documentation/GUIDE.md',encoding='utf-8').read()
open('documentation/GUIDE.md','w',encoding='utf-8').write(s+'\n\nThe two shards were concurrently running on one host, which is why the ladder above is not a timing baseline.\n')"

  # GATE 9, in the EXACT shape the operator specified: a SYNTHETIC SINGLE-FILE EDIT.
  # The injected change is one space — whitespace only, still valid markdown, still
  # closing its italic, and semantically identical. A gate that normalised whitespace
  # (the obvious "robustness" tweak) would pass this and would not be a byte-identity
  # gate at all. If this assertion ever stops firing, the gate has stopped being one.
  # The ERE names the byte-identity verdict AND its variant COUNT: one mutated cover means
  # exactly 2 variants, so a gate that had stopped comparing and failed for some other
  # reason (a missing marker, an unclosed italic) cannot satisfy this.
  # ANCHOR RE-DERIVED 2026-08-07. The original anchored on `…argued, not verified.*` —
  # the banner USED to end at that sentence, so the closing italic sat right after it and
  # the mutation was "insert one space before the `*`". The banner has since grown three
  # more sentences (the authorship disclosure), the `*` moved to the end of line 7, and the
  # anchor stopped matching: the assertion went RED with "could not inject (anchor moved)",
  # which is the correct fail-closed behaviour and is how this was found.
  # The replacement is a STRICTLY BETTER mutation for what this leg tests. Doubling an
  # interior space is whitespace-only, unambiguously valid markdown, semantically identical,
  # and — unlike the old one — does not sit adjacent to the emphasis delimiter, where a space
  # before a closing `*` would not close the italic at all under CommonMark's right-flanking
  # rule. So the old fixture was also mildly wrong about "still closing its italic".
  # A gate that normalised whitespace would pass this and would not be a byte-identity gate.
  assert_fires_why "GATE 9 banner drift (1 byte, 1 file)" banner \
    'the banner is NOT byte-identical: 2 variants in use' \
"s=open('reports/TR5_SYMMETRY.md').read()
a='not peer-reviewed. Every MEASURED'
assert s.count(a)==1, 'anchor moved'
open('reports/TR5_SYMMETRY.md','w').write(s.replace(a,'not peer-reviewed.  Every MEASURED',1))"

  # GATE 9's second branch: the 11 covers can be perfectly uniform while the INDEX
  # drifts back to a blanket promise. Byte-identity across the reports cannot see
  # that, so the branch is exercised separately — an unexercised branch is untested.
  # The ERE names the INDEX leg specifically. Both GATE 9 branches live behind one dispatch
  # name and one exit code, so an exit-code assertion here was satisfiable by the cover
  # byte-identity branch above — the two assertions could not be told apart.
  assert_fires_why "GATE 9 index drops the scope clause" banner \
    'reports/README\.md:[0-9]+ — index banner lacks "argued, not verified"' \
"s=open('reports/README.md').read()
a='interpretation are argued, not verified.'
assert a in s, 'anchor moved'
open('reports/README.md','w').write(s.replace(a,'interpretation are sound.',1))"

  # GATE 10 POSITIVE: deleting a committed line from the corrections ledger must fire it.
  # The deleted line is chosen from the middle of the file rather than the end, so the
  # assertion cannot be satisfied by a "file got shorter" check that would miss a
  # reword-in-place — the defect this gate actually exists for.
  # DISPATCH (2026-08-02, item A7): `appendonly-head`, not `appendonly`. Since 10b landed,
  # `appendonly` is two gates behind one exit code and this assertion would be satisfiable
  # by either — the same untested-test shape A3 fixed for GATE 4b.
  # Q-251 (2026-09-03) TOUCHED BOTH HALVES OF THIS ASSERTION. The ERE moved because 10a's
  # FAIL text now says which CLASS the missing line is in; and the mutation now picks the
  # first NON-BLANK line at or after the midpoint. `del L[len(L)//2]` could land on a blank
  # line — it does not today, checked — and a removed blank line carries no content, so under
  # the new classification it would report as a re-wrap and this assertion would go red for a
  # reason that has nothing to do with the leg. A fixture whose class depends on where the
  # midpoint happens to fall is the "fails for the wrong reason" shape; it is pinned now.
  # 🔴 Q-702 (2026-09-24, Fable K): THE PIN ABOVE WAS NOT ENOUGH. At 5c296837 the first non-blank
  # line at the midpoint was the one-word wrap `this.`, whose collapsed text is a substring of
  # the rest of the ledger, and the substring rule of the day labelled its deletion a RE-WRAP.
  # Q-718 (2026-09-25) replaced that rule with word alignment inside the diff hunk, and this leg
  # now SELECTS exactly that shape on purpose: a short line (<= 20 chars) whose collapsed text
  # still occurs elsewhere in the file. The substring rule labels its deletion a re-wrap, so
  # this leg is red under it; the alignment rule labels it LOST.
  assert_fires_why "GATE 10a append-only vs HEAD (committed line deleted)" appendonly-head \
    'missing committed line\(s\) are LOST' \
"import re
L=open('documentation/CORRECTIONS.md').read().split(chr(10))
assert len(L) > 60, 'ledger too short to mutate meaningfully'
i=len(L)//2
while i < len(L):
    t=re.sub(r'\s+',' ',L[i]).strip()
    if t and len(t) <= 20 and t in re.sub(r'\s+',' ',chr(10).join(L[:i]+L[i+1:])): break
    i+=1
assert i < len(L), 'no short line at or after the midpoint whose text also occurs elsewhere in the ledger'
del L[i]
open('documentation/CORRECTIONS.md','w').write(chr(10).join(L))"

  # Q-251 FIRE-PROOF — a RE-WRAP must be reported as a re-wrap, not as a deletion.
  #
  # THE DEFECT: this gate compares LINES, so re-flowing a committed paragraph reported every
  # one of its old lines as "removed or reworded" while not one word had gone. Measured before
  # the fix, on a three-line reflow: 1 [FAIL] here and 73 in 10b, one per historical blob.
  # The hazard is the REMEDY — a maintainer goes looking for content that was never deleted,
  # or concludes a published append-only ledger was tampered with.
  #
  # ANCHOR-FREE BY CONSTRUCTION. The mutation FINDS a run of three consecutive committed prose
  # lines rather than naming one, so it cannot go stale as the ledger grows, and it asserts
  # that its own re-flow is loss-free (flattened text identical) BEFORE writing — a fixture
  # that accidentally dropped a word would be proving the LOST branch instead. `break_on_
  # hyphens=False` is load-bearing for that: splitting `machine-enforced` across lines inserts
  # a space into the flattened text and is a genuine content change, which the first cut of
  # this fixture did and which the pre-write assert would now catch.
  #
  # THE VERDICT IS UNCHANGED (rc=1 either way) — only the classification and the message move,
  # which is why the companion assertion this needs is the LOST one directly above: together
  # they show the two classes are distinguished and neither swallows the other.
  assert_fires_why "GATE 10a a re-wrapped paragraph is reported as a RE-WRAP, not a deletion" appendonly-head \
    'missing committed line\(s\) are RE-WRAPS, not deletions' \
"import re, textwrap
p='documentation/CORRECTIONS.md'
L=open(p,encoding='utf-8').read().split(chr(10))
def prose(x): return bool(x) and not x.startswith(('#','|','-','*','>','\u0060','    ')) and len(x)>60
blk=None
for i in range(len(L)-3):
    if all(prose(L[j]) for j in (i,i+1,i+2)) and not prose(L[i+3]):
        blk=L[i:i+3]; break
assert blk, 'no run of three consecutive committed prose lines to re-flow'
joined=' '.join(x.strip() for x in blk)
new=textwrap.wrap(joined,width=72,break_on_hyphens=False,break_long_words=False)
assert re.sub(r'\s+',' ',' '.join(new)).strip()==re.sub(r'\s+',' ',joined).strip(), 'the re-flow was not loss-free'
assert new!=blk, 'the re-flow changed no line'
L[i:i+3]=new
open(p,'w',encoding='utf-8').write(chr(10).join(L))"

  # GATE 10 NEGATIVE CONTROL. An APPEND must NOT fire it. Without this the [ok] above
  # proves only that the gate is capable of failing, not that it is capable of passing
  # — and a gate that always fails is turned off within a day, which is how the
  # container-level exemptions in this file got there in the first place.
  python3 -c "open('documentation/CORRECTIONS.md','a').write(chr(10)+'### CX-selftest — an appended line.'+chr(10))" 2>/dev/null \
    && { if bash "$0" appendonly >/dev/null 2>&1; then
           echo "  [ok]   GATE 10 negative control — a pure APPEND does not fire it"
         else
           echo "  [FAIL] GATE 10 fired on a pure append; it is not an append-only gate"
           bash "$0" appendonly 2>&1 | sed 's/^/           > /' | head -5
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 10 negative control — could not append to the ledger, so the"
         echo "         assertion did NOT run (item A5)."; PASS=1; }

  # =========================================================================
  # GATE 10b — THREE assertions (added 2026-08-02, item A7), because they prove three
  # different things and the first one alone would have passed on the BROKEN gate.
  #
  # (i) runs in the real tree and proves the DETECTOR works. It is dispatched to
  #     `appendonly-history`, which is 10b alone — the A3 lesson applied here, since a
  #     deleted line fires 10a too and a shared dispatch name would let the assertion be
  #     satisfied by the half that was never in question.
  #
  # (ii) and (iii) are the DIFFERENTIATORS, and they cannot be staged in this repo: the
  #     defect A7 reports only exists once the removal has been COMMITTED (ii) or the
  #     history REWRITTEN (iii), and the self-test may do neither to the real tree. They
  #     are staged in throwaway repos built by `cp "$0"` — so they exercise THIS script,
  #     not a re-implementation of it, which is the difference between a fire-proof and a
  #     clever proxy.
  assert_fires_why "GATE 10b vs history (a line of the OLDEST committed version deleted)" \
    appendonly-history '1 line\(s\) present in .* are absent from the working copy' \
"import subprocess
f='documentation/CORRECTIONS.md'
revs=subprocess.run(['git','rev-list','HEAD','--',f],capture_output=True,text=True).stdout.split()
assert revs, 'the ledger has no history to test against'
old=subprocess.run(['git','show',revs[-1]+':'+f],capture_output=True,text=True).stdout.split(chr(10))
cur=open(f,encoding='utf-8').read().split(chr(10))
cand=[l for l in old if l.strip() and l in cur]
assert cand, 'no line of the oldest committed version survives to delete'
cur.remove(cand[len(cand)//2])
open(f,'w',encoding='utf-8').write(chr(10).join(cur))"

  # scratch_appendonly <label> <setup-shell-run-inside-the-scratch-repo>
  #   Asserts BOTH verdicts at once: 10a must be GREEN (that is the blindness A7 reports)
  #   and 10b must be RED (that is the fix). Asserting only 10b would still pass in a
  #   world where 10a had caught it — and "10a does not catch it" is the whole claim.
  scratch_appendonly() {
    local label="$1" setup="$2" d rcA rcB rcS
    d=$(mktemp -d) || { echo "  [SKIP] $label — no tmpdir"; return; }
    ( set -e
      mkdir -p "$d/scripts" "$d/documentation"
      cp "$0" "$d/scripts/doc_gates.sh"; cp -R "$(dirname "$0")/doc_gates.d" "$d/scripts/"
      cd "$d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .
      git symbolic-ref HEAD refs/heads/main
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\n' \
        > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: three entries'
      eval "$setup" ) >/dev/null 2>&1; rcS=$?
    # ITEM A5: rc 3 is the ONE designed skip in this suite — case (iii) exits 3 when its
    # premise (the pre-rewrite commit is no longer an ancestor of HEAD) does not hold, and
    # skipping is then correct because the scenario would be testing nothing. Every OTHER
    # non-zero rc means `git init`, the seed commit or the setup itself broke, which is a
    # fire-proof that did not run. Those two were conflated behind one [SKIP] and one
    # message that ASSERTED the premise reading for both.
    if [ "$rcS" -eq 3 ]; then
      echo "  [SKIP] $label — premise does not hold here (setup exited 3 by design), so the"
      echo "         scenario would test nothing"
      rm -rf "$d"; return
    elif [ "$rcS" -ne 0 ]; then
      echo "  [FAIL] $label — scratch setup broke (rc=$rcS), so the assertion did NOT run"
      PASS=1; rm -rf "$d"; return
    fi
    ( cd "$d" && bash scripts/doc_gates.sh appendonly-head    >/dev/null 2>&1 ); rcA=$?
    ( cd "$d" && bash scripts/doc_gates.sh appendonly-history >/dev/null 2>&1 ); rcB=$?
    rm -rf "$d"
    # Q-954 (e) (Codex Q835 P-07, A05#23): 10b used to count as firing on ANY rc != 0, so a
    # refusal (2), a timeout (124) or a kill (137/143) read as the fix working. A mode run exits
    # 1 when a gate fires (RC=1) and 2 only when it refuses to run, so the fire is rc 1 exactly.
    if [ "$rcA" -eq 0 ] && [ "$rcB" -eq 1 ]; then
      echo "  [ok]   $label — 10a green on it (the blindness), 10b fires (the fix)"
    else
      echo "  [FAIL] $label — expected 10a rc=0 and 10b rc=1; got 10a rc=$rcA, 10b rc=$rcB"
      PASS=1
    fi
  }

  # (ii) COMMIT THE REMOVAL — no unusual git required, which is why it is the likelier of
  #      the two. After the second commit the working copy and HEAD agree perfectly.
  scratch_appendonly "GATE 10b vs a COMMITTED removal (working copy == HEAD)" \
"printf 'CX-1 first entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
git add -A && git commit -qm 'tidy: drop CX-2'"

  # (iii) HISTORY REWRITE. This is the case an ancestor-walk alone CANNOT close, and the
  #       setup asserts that premise rather than assuming it: if the pre-rewrite commit
  #       were still an ancestor of HEAD the walk would see it, the scenario would be
  #       testing nothing, and the setup exits 3 so the case reports [SKIP] instead of a
  #       false [ok]. With the premise held, refs/remotes/origin/main is the only baseline
  #       still holding the dropped line.
  scratch_appendonly "GATE 10b vs an AMEND that drops a PUBLISHED line" \
"git update-ref refs/remotes/origin/main HEAD
orig=\$(git rev-parse HEAD)
printf 'CX-1 first entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
git add -A && git commit -q --amend -m 'ledger: three entries'
if git merge-base --is-ancestor \"\$orig\" HEAD; then exit 3; fi"

  # 🔴 Q-702 (2026-09-24, Fable K) — NEGATIVE CONTROL for the arm that made (iii) green. The fix
  # distinguishes "on THIS branch's published lineage" (FAIL) from "on some OTHER remote branch"
  # (Q-283's MERGE GAP, a [note]). Without this control, (iii) is equally consistent with the
  # arm having simply reverted Q-283 — every non-ancestor a FAIL — which would re-open the
  # v4-query-program false positive Q-283 measured (441 commits divergent, 3 lines that never
  # arrived). Same scratch shape as scratch_appendonly, written INLINE because every helper's
  # callers=N is pinned in documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt and this lane does
  # not own that file. Scenario: main is published (refs/remotes/origin/main == HEAD) and a
  # topic branch, published ONLY as refs/remotes/origin/topic, holds an extra ledger line that
  # main never had. 10b must print the lineage it holds main to, report the topic line as a
  # MERGE GAP, and exit 0.
  _g10c_d=$(mktemp -d) || { echo "  [FAIL] GATE 10b (Q-702) merge-gap control — no tmpdir"; PASS=1; }
  if [ -n "${_g10c_d:-}" ] && [ -d "$_g10c_d" ]; then
    mkdir -p "$_g10c_d/scripts" "$_g10c_d/documentation"
    cp "$0" "$_g10c_d/scripts/doc_gates.sh"; cp -R "$(dirname "$0")/doc_gates.d" "$_g10c_d/scripts/"
    ( set -e; cd "$_g10c_d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .; git symbolic-ref HEAD refs/heads/main
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: three entries'
      git update-ref refs/remotes/origin/main HEAD
      git checkout -q -b topic
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\nCX-4 topic-only entry.\n' > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: topic-only fourth entry'
      git update-ref refs/remotes/origin/topic HEAD
      git checkout -q main; git branch -q -D topic
      # premise: the topic commit is NOT an ancestor of main and NOT reachable from origin/main
      if git merge-base --is-ancestor refs/remotes/origin/topic HEAD; then exit 3; fi
      if git merge-base --is-ancestor refs/remotes/origin/topic refs/remotes/origin/main; then exit 3; fi
    ) >/dev/null 2>&1; _g10c_rcS=$?
    if [ "$_g10c_rcS" -ne 0 ]; then
      echo "  [FAIL] GATE 10b (Q-702) merge-gap control — scratch setup broke or its premise failed (rc=$_g10c_rcS), so the assertion did NOT run"
      PASS=1
    else
      _g10c_out=$(cd "$_g10c_d" && bash scripts/doc_gates.sh appendonly-history 2>&1); _g10c_rc=$?
      if [ "$_g10c_rc" -eq 0 ] \
         && grep -qF 'published lineage of this branch: refs/remotes/origin/main' <<<"$_g10c_out" \
         && grep -qF 'MERGE GAP, not a lost line' <<<"$_g10c_out" \
         && grep -qF 'CX-4 topic-only entry.' <<<"$_g10c_out"; then
        echo "  [ok]   GATE 10b (Q-702) merge-gap control — a line published only on ANOTHER remote branch"
        echo "         stays a [note] (rc 0) while main's lineage is named as the hard baseline"
      else
        echo "  [FAIL] GATE 10b (Q-702) merge-gap control — expected rc 0 with the lineage line, a MERGE GAP"
        echo "         note and the topic line quoted; got rc=$_g10c_rc:"
        printf '%s\n' "$_g10c_out" | grep -E '\[(FAIL|note|ok)\]|published lineage' | sed 's/^/           > /' | head -4
        PASS=1
      fi
    fi
    rm -rf "$_g10c_d"
  fi

  # 🔴 S3 (2026-09-24, batch-2 pre-publication review, Fable P) — the published-lineage arm
  # must NOT fire on a feature branch created with `git checkout -b feat origin/main`. That
  # layout is git's default (branch.autoSetupMerge) and makes @{upstream} = origin/main for a
  # branch that will never push to main; the first cut of the Q-702 arm took @{upstream}
  # unconditionally and hard-FAILED it as soon as origin/main gained a line. Inline for the
  # callers=N reason above. Scenario: feat branches from origin/main with that upstream and
  # APPENDS a ledger line of its own; main then publishes a different fourth line, so the two
  # have DIVERGED (the shape the first cut hard-FAILED; a feat with no commit of its own is
  # merely BEHIND origin/main, which even the first cut reported as a [note], so that shape
  # would not distinguish the two). On feat, 10b must find NO baseline (git refuses @{push}
  # under push.default=simple, there is no origin/feat, and the upstream's short name is main,
  # not feat), report main's later line as a MERGE GAP, and exit 0. push.default is pinned to
  # simple INSIDE the scratch repo so a developer's global push.default=upstream — under which a
  # FAIL would be correct, since a push really would land on main — cannot change what this leg
  # measures. The amend leg (iii) above keeps proving the arm still FIRES. Mutation-tested
  # 2026-09-24: with step 3's same-name condition removed the leg reports rc=1 and the hard FAIL.
  _g10d_d=$(mktemp -d) || { echo "  [FAIL] GATE 10b (S3) feature branch tracking origin/main — no tmpdir"; PASS=1; }
  if [ -n "${_g10d_d:-}" ] && [ -d "$_g10d_d" ]; then
    mkdir -p "$_g10d_d/scripts" "$_g10d_d/documentation"
    cp "$0" "$_g10d_d/scripts/doc_gates.sh"; cp -R "$(dirname "$0")/doc_gates.d" "$_g10d_d/scripts/"
    ( set -e; cd "$_g10d_d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .; git symbolic-ref HEAD refs/heads/main
      git config push.default simple
      git remote add origin /nonexistent-doc-gates-selftest-remote
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\n' > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: three entries'
      git update-ref refs/remotes/origin/main HEAD
      git checkout -q -b feat origin/main
      git checkout -q main
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\nCX-9 main-later.\n' > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: fourth entry, published on main after feat branched'
      git update-ref refs/remotes/origin/main HEAD
      git checkout -q feat
      printf 'CX-1 first entry.\nCX-2 second entry.\nCX-3 third entry.\nCX-5 feat-only entry.\n' > documentation/CORRECTIONS.md
      git add -A && git commit -qm 'ledger: a feat-only fifth entry (feat and origin/main now diverge)'
      # premises: feat's upstream IS origin/main, @{push} does NOT resolve, and the two have DIVERGED
      [ "$(git rev-parse --symbolic-full-name '@{upstream}')" = refs/remotes/origin/main ]
      if git rev-parse --symbolic-full-name '@{push}' >/dev/null 2>&1; then exit 4; fi
      if git merge-base --is-ancestor refs/remotes/origin/main HEAD; then exit 4; fi
      if git merge-base --is-ancestor HEAD refs/remotes/origin/main; then exit 4; fi
    ) >/dev/null 2>&1; _g10d_rcS=$?
    if [ "$_g10d_rcS" -ne 0 ]; then
      echo "  [FAIL] GATE 10b (S3) feature branch tracking origin/main — scratch setup broke or a premise failed (rc=$_g10d_rcS), so the assertion did NOT run"
      PASS=1
    else
      _g10d_out=$(cd "$_g10d_d" && bash scripts/doc_gates.sh appendonly-history 2>&1); _g10d_rc=$?
      if [ "$_g10d_rc" -eq 0 ] \
         && grep -qF "branch 'feat' has no @{push}, no same-named remote branch and no" <<<"$_g10d_out" \
         && grep -qF 'NO baseline here' <<<"$_g10d_out" \
         && grep -qF 'MERGE GAP, not a lost line' <<<"$_g10d_out" \
         && grep -qF 'CX-9 main-later.' <<<"$_g10d_out" \
         && ! grep -qF 'published lineage of this branch:' <<<"$_g10d_out" \
         && ! grep -qF '[FAIL]' <<<"$_g10d_out"; then
        echo "  [ok]   GATE 10b (S3) feature branch tracking origin/main — no baseline is claimed, the"
        echo "         later main line is a MERGE GAP [note], rc 0 (the amend leg above still fires)"
      else
        echo "  [FAIL] GATE 10b (S3) feature branch tracking origin/main — expected rc 0, the no-baseline"
        echo "         note, a MERGE GAP note quoting the main-later line and NO [FAIL]; got rc=$_g10d_rc:"
        printf '%s\n' "$_g10d_out" | grep -E '\[(FAIL|note|ok)\]|published lineage|no @\{push\}' | sed 's/^/           > /' | head -5
        PASS=1
      fi
    fi
    rm -rf "$_g10d_d"
  fi

  # GATE 11: a registry row with no ledger entry must fire it. Injected as a NEW registry
  # row rather than by deleting a ledger entry, because deletion would fire GATE 10 and
  # the assertion would pass for the wrong reason — the two gates must be shown to be
  # independent, not merely both red.
  # DISPATCH NOTE (item A1, round 8; RE-POINTED item B2, round 9): `ledger` is phrases AND
  # figures behind one exit code, and the figures pass already carries [OPEN] rows — so an
  # exit-code assertion here was satisfiable by the figures half and would have stayed green
  # with the phrases pass deleted. Round 8 defended that with the ERE alone (it names the
  # PHRASES leg's own line, which the figures leg cannot print). Round 9 added the LEAF
  # dispatch name `ledger-phrases`, so the defence is now structural as well: this assertion
  # runs one gate function, and a reader does not have to verify an ERE's provenance to see
  # it. The RP key is matched as a pattern, never hardcoded: a sha copied out of a run into a
  # fire-proof is the shape this project bans everywhere else, and the registry note is
  # deliberately NOT in the ERE, since that string is the mutation's own source text.
  assert_fires_why "GATE 11 ledger completeness (unrecorded retraction)" ledger-phrases \
    'RP-[0-9a-f]+ has NO entry in documentation/CORRECTIONS\.md' \
"open('documentation/RETRACTED_PHRASES.tsv','a').write(
 'a synthetic phrasing that was never published'+chr(9)+'__none__'+chr(9)+'Self-test row: no ledger entry exists for it, so GATE 11 must fail.'+chr(10))"

  # GATE 11 FIGURES PASS — three fire-proofs (item A5, 2026-08-02).
  #
  # Each targets `ledger-figures`, not `ledger`. The combined dispatch runs BOTH passes, so
  # an assertion on its exit code is satisfied by the phrases pass failing and would stay
  # green if this whole pass were deleted — the GATE 4b lesson, applied at the point where
  # it would otherwise be repeated.
  #
  # CASE 1 is the item's own concern: a figure registered TODAY, with nobody having written
  # anything anywhere, must fail. CASE 2a/2b prove what an open-list row is DOING. CASE 3 is
  # the missing-input class.
  assert_fires_why "GATE 11 (figures) a newly registered figure nobody recorded" ledger-figures \
'"a synthetic figure 9\.99sigma" has NO entry' \
"open('documentation/RETRACTED_FIGURES.tsv','a').write(
 'a synthetic figure 9.99sigma'+chr(9)+'Self-test row: no ledger entry and no open-list row, so the figures pass must fail.'+chr(10))"

  # CASE 2 — REBUILT SELF-SEEDING 2026-09-03 (Q-237). WHAT IT USED TO BE AND WHY THAT COULD
  # NOT SURVIVE SUCCESS. The old case deleted the row beginning `+125<TAB>` from
  # documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt to show the file is load-bearing. Its
  # precondition was therefore an OUTSTANDING DEFECT: the open list is a BACKLOG, every row
  # in it is a ledger entry somebody still owes, and the file reaches ZERO rows exactly when
  # the corpus is finished. It is at zero today — 52 lines, all comment or blank — so the
  # injection asserted out with "anchor moved: 0 rows" and the assertion did NOT run, on a
  # file BYTE-IDENTICAL to main. Not branch staleness; the fixture.
  #
  # THIS IS A CLASS, NOT AN INSTANCE, and the class was censused before rewriting one member.
  # Three registries stand at zero data rows today — DOC_GATE_FIGURE_LEDGER_OPEN.txt,
  # DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv and DOC_GATE_UNMARKED_ALLOWLIST.txt — and this was
  # the ONLY fixture anchored on any of them (the other two carried no fixture at all, which
  # was a coverage gap of a different kind and was reported rather than fixed here).
  # 🟢 THAT GAP IS CLOSED as of 2026-09-03: both now carry a self-seeding pair, immediately
  # below this block (labels "GATE 59 (baseline, 59a/59b)" and "GATE 5b (5b-i…iv)"). This
  # sentence is corrected rather than deleted because the census it records is the reason the
  # pairs exist, and a note reporting a gap it no longer has is the stale-claim shape. The house
  # pattern already existed twenty lines from a sibling: GATE 18's ratchet CASE 1 seeds its own
  # registry row and its own anchor, and its comment says why — "ANCHOR-FREE ON THE REGISTRY
  # SIDE: the row is APPENDED, and the planted sentence is its own anchor".
  #
  # 2a IS THE LOAD-BEARING HALF and 2b is its reaction. 2a seeds a figure AND an open row and
  # asserts the gate STAYS GREEN while naming that figure as [OPEN] — a line it can only print
  # having read BOTH files, which is the claim no other assertion in this pass makes: the open
  # row is what holds the figure. 2b seeds TWO figures with two open rows, deletes ONE, and
  # asserts the FAIL names the one whose row went. The two-figure form is deliberate: with a
  # single figure, 2b's post-mutation tree is byte-for-byte what CASE 1 already builds and it
  # would prove the reaction without proving the mechanism. With two, one figure is still held
  # [OPEN] in the same run, so the gate is demonstrably discriminating between them.
  #
  # NEITHER KEY IS HARDCODED. `RF-<sha8>` is matched as a pattern, for the reason the phrases
  # fixture above states: a sha copied out of a run into a fire-proof is the shape this project
  # bans everywhere else.
  assert_stays_clean_why "GATE 11 (figures, 2a) a seeded open-list row HOLDS its seeded figure" ledger-figures \
'RF-[0-9a-f]+ "a synthetic OPEN-LIST figure 8\.88sigma".*no ledger entry yet' \
"r='documentation/RETRACTED_FIGURES.tsv'
o='documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt'
fig='a synthetic OPEN-LIST figure 8.88sigma'
s=open(r,encoding='utf-8').read()
assert s.endswith(chr(10)), 'the figure registry does not end with a newline'
assert fig not in s, 'the synthetic figure is already registered'
open(r,'a',encoding='utf-8').write(fig+chr(9)+'Self-test row: held green ONLY by the open-list row seeded beside it.'+chr(10))
t=open(o,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the open list does not end with a newline'
assert fig not in t, 'the synthetic open row is already present'
open(o,'a',encoding='utf-8').write(fig+chr(9)+'Self-test open row: seeded so this leg is proven in the HEALTHY state.'+chr(10))"

  assert_fires_why "GATE 11 (figures, 2b) deleting one seeded open row fails ONLY that figure" ledger-figures \
'RF-[0-9a-f]+ "a synthetic OPEN-LIST figure 8\.88sigma" has NO entry' \
"r='documentation/RETRACTED_FIGURES.tsv'
o='documentation/DOC_GATE_FIGURE_LEDGER_OPEN.txt'
gone='a synthetic OPEN-LIST figure 8.88sigma'
kept='a synthetic STILL-OPEN figure 7.77sigma'
s=open(r,encoding='utf-8').read()
assert s.endswith(chr(10)), 'the figure registry does not end with a newline'
assert gone not in s and kept not in s, 'a synthetic figure is already registered'
open(r,'a',encoding='utf-8').write(
 gone+chr(9)+'Self-test row: its open-list row is deleted below, so it must FAIL.'+chr(10)+
 kept+chr(9)+'Self-test row: its open-list row survives, so it must stay [OPEN].'+chr(10))
t=open(o,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the open list does not end with a newline'
open(o,'a',encoding='utf-8').write(
 gone+chr(9)+'Self-test open row: about to be deleted by this same injection.'+chr(10)+
 kept+chr(9)+'Self-test open row: kept, so the gate must discriminate between the two.'+chr(10))
L=open(o,encoding='utf-8').read().split(chr(10))
h=[i for i,x in enumerate(L) if x.startswith(gone+chr(9))]
assert len(h)==1, 'the injection just seeded exactly one row for it; found %d' % len(h)
del L[h[0]]
open(o,'w',encoding='utf-8').write(chr(10).join(L))"

  # CASE 4 — the SILENT DROP. `while read` returns non-zero on an unterminated final line,
  # so a row appended without a trailing newline is registered and never checked, and the
  # gate prints [ok] with a count nobody compares against the file. Found by asking the
  # missing-input question of the READER rather than of the file. No live instance: all
  # three registries end in \n today, which is why this is a tripwire and is asserted here
  # rather than described in a comment.
  assert_fires_why "GATE 11 (figures) registry with no final newline drops its last row" ledger-figures \
'RETRACTED_FIGURES\.tsv does not end with a newline' \
"p='documentation/RETRACTED_FIGURES.tsv'
s=open(p,encoding='utf-8').read()
assert s.endswith(chr(10)), 'anchor moved: already unterminated'
open(p,'w',encoding='utf-8').write(s.rstrip(chr(10)))"

  assert_fires_why "GATE 11 (figures, A1) figure registry deleted" ledger-figures \
'RETRACTED_FIGURES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_FIGURES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_FIGURES.tsv')"

  # -----------------------------------------------------------------------
  # GATE 59 and GATE 5b — THE OTHER TWO ZERO-ROW REGISTRIES (2026-09-03, fixtures lane).
  #
  # CASE 2 above censused three registries standing at zero data rows and said of the other
  # two that they "carry no fixture at all, which is a coverage gap of a different kind and
  # is reported rather than fixed here". This is that gap closed. Both pairs are SELF-SEEDING
  # for CASE 2's reason and not by preference: each of these tables reaches zero rows exactly
  # when the corpus is finished, so a fixture whose precondition is an outstanding defect
  # cannot survive success — and GATE 5b's only live candidate was adjudicated and fixed the
  # same day these landed (reports/METHODS.md:71), which is that hazard arriving in the hour.
  #
  # EVERY ERE BELOW WAS TAKEN FROM A RUN, not from the patch that proposed them: the two
  # pairs were handed on as exact patches in roae-private/LANE_SWEEP_2026_09_03.md and each
  # was re-measured against the live gate before being written here, mutations reverted by
  # `cp` from a saved copy and both target files confirmed sha-identical afterwards.

  # GATE 59 (baseline-arithmetic). 59a IS THE LOAD-BEARING HALF: it asserts the gate STAYS
  # GREEN while naming the seeded figure as [OPEN] — a line it can only print having read
  # BOTH the doc and the registry, so the row is what HOLDS the figure. Measured: rc 0,
  # "3 eligibility-baseline sentence(s) across 93 docs; 2 self-consistent, 1 adjudicated-open".
  assert_stays_clean_why "GATE 59 (baseline, 59a) a seeded open row HOLDS its seeded defect" baseline-arithmetic \
'7 of 31 ineligible -> 1/97 \(arithmetic gives 1/24\) — adjudicated open' \
"d='documentation/LITERATURE_RULES_POPULATION_TESTS.md'
a='documentation/DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv'
s=open(d,encoding='utf-8').read()
assert s.endswith(chr(10)), 'the doc does not end with a newline'
assert '1/97' not in s, 'the synthetic sentence is already present'
open(d,'a',encoding='utf-8').write(chr(10)+'Self-test paragraph A. 7 of the 31 synthetic candidates are ineligible, so the baseline is 1/97.'+chr(10))
t=open(a,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the registry does not end with a newline'
open(a,'a',encoding='utf-8').write(d+chr(9)+'7'+chr(9)+'31'+chr(9)+'97'+chr(9)+'Self-test row A.'+chr(10))"

  # 59b IS ITS REACTION, and it seeds TWO figures so the gate is shown DISCRIMINATING rather
  # than merely reactive: two rows are seeded, ONE is deleted, and the same run must FAIL on
  # the deleted one WHILE STILL PRINTING the other as [OPEN]. The two-sentence form is
  # deliberate for CASE 2b's reason — with one sentence the post-deletion tree is
  # byte-for-byte what an unregistered defect already produces, which proves the reaction
  # without proving the mechanism. Measured: rc 1, both lines present in one run.
  assert_fires_why "GATE 59 (baseline, 59b) deleting ONE open row fails ONLY that figure" baseline-arithmetic \
'8 of 31 ineligible -> baseline 1/98, but N-K arithmetic gives 1/23' \
"d='documentation/LITERATURE_RULES_POPULATION_TESTS.md'
a='documentation/DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv'
s=open(d,encoding='utf-8').read()
assert s.endswith(chr(10)), 'the doc does not end with a newline'
assert '1/97' not in s and '1/98' not in s, 'a synthetic sentence is already present'
open(d,'a',encoding='utf-8').write(chr(10)+'Self-test paragraph A. 7 of the 31 synthetic candidates are ineligible, so the baseline is 1/97.'+chr(10)+chr(10)+'Self-test paragraph B. 8 of the 31 synthetic candidates are ineligible, so the baseline is 1/98.'+chr(10))
t=open(a,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the registry does not end with a newline'
open(a,'a',encoding='utf-8').write(
 d+chr(9)+'7'+chr(9)+'31'+chr(9)+'97'+chr(9)+'Self-test row A: survives, so its figure must still print [OPEN].'+chr(10)+
 d+chr(9)+'8'+chr(9)+'31'+chr(9)+'98'+chr(9)+'Self-test row B: deleted below, so its figure must FAIL.'+chr(10))
L=open(a,encoding='utf-8').read().split(chr(10))
h=[i for i,x in enumerate(L) if x.startswith(d+chr(9)+'8'+chr(9)+'31'+chr(9)+'98'+chr(9))]
assert len(h)==1, 'the injection just seeded exactly one row for it; found %d' % len(h)
del L[h[0]]
open(a,'w',encoding='utf-8').write(chr(10).join(L))"

  # GATE 5b (inside `status`). 🔴 BOTH HALVES ARE assert_stays_clean_why BY MEASUREMENT, NOT
  # BY PREFERENCE, and the handed-on framing ("neither gate has ever demonstrated it can
  # fail") is half wrong here: GATE 5b CANNOT FAIL AT ALL. Its python ends `sys.exit(0)`
  # unconditionally and a finding prints [WARN] plus "(report-only: ...)" while setting no
  # rc, so `assert_fires_why` has nothing to catch and is UNUSABLE on this gate. The
  # discrimination is therefore asserted on the PRINTED lines, which are the only signal 5b
  # has. That is the honest answer to "why does the GATE 11 shape not fit here".
  #
  # THE SEED DERIVES ITS VALUE FROM documentation/CANONICAL_VALUE_STATUS.tsv rather than
  # hardcoding one, by the gate's OWN selection rule (a plain-numeric, comma-free row whose
  # status is `estimate`). The patch that proposed this pair hardcoded 1.3287 and flagged the
  # hardcoding as its own weakness; deriving it means the seed cannot drift from the registry,
  # and it asserts out loudly if the registry ever declares no such value. The exponent is
  # written `×10^SYNTHETIC` on purpose: 5b keys only on `<value>×10`, so a real magnitude is
  # not needed, and a magnitude that is not a real one cannot be misread as a canonical claim
  # if a reader ever sees the mutated tree.
  #
  # The seeded table carries ONE marked sibling and TWO unmarked twins whose lines differ
  # textually, because the allowlist anchor is a literal substring of the line and identical
  # twins would give one anchor two homes (the audit reports that case rather than resolving it).
  _5b_seed="import re
d='documentation/LITERATURE_RULES_POPULATION_TESTS.md'
r='documentation/CANONICAL_VALUE_STATUS.tsv'
v=[p[0].strip() for p in (l.split(chr(9)) for l in open(r,encoding='utf-8') if l.strip() and not l.lstrip().startswith('#')) if len(p)>1 and p[1].strip()=='estimate' and re.fullmatch(r'[\d.]+',p[0].strip()) and ',' not in p[0]]
assert v, 'the registry declares no plain-numeric estimate value; the seed cannot be derived'
val=v[0]
s=open(d,encoding='utf-8').read()
assert s.endswith(chr(10)), 'the doc does not end with a newline'
assert 'synthetic unmarked alpha' not in s, 'the synthetic table is already present'
open(d,'a',encoding='utf-8').write(chr(10)+'## Self-test table (5b fixture)'+chr(10)+chr(10)+'| synthetic item | value |'+chr(10)+'|---|---|'+chr(10)+'| synthetic marked sibling | '+val+chr(215)+'10^SYNTHETIC (estimate) |'+chr(10)+'| synthetic unmarked alpha | '+val+chr(215)+'10^SYNTHETIC |'+chr(10)+'| synthetic unmarked beta | '+val+chr(215)+'10^SYNTHETIC |'+chr(10))"

  # 5b-i — the ACHIEVABILITY control and the first half of the discriminator. With no
  # allowlist entry, BOTH seeded twins land in the reported class. The pinned count is what
  # makes 5b-ii mean anything: without it, 5b-ii's silence about alpha is equally consistent
  # with "the entry suppressed it" and "the seed never produced it".
  assert_stays_clean_why "GATE 5b (5b-i) both seeded twins enter the reported class with no allowlist entry" status \
'3 of those are in a MIXED table' \
"$_5b_seed"

  # 5b-ii — THE DISCRIMINATOR. Same seed, plus ONE allowlist entry anchored on ONE twin. The
  # class census must fall by EXACTLY ONE, 3 -> 2, in a gate that cannot signal through rc.
  # 🔴 THIS IS AN ABSOLUTE PIN and it is a live rot hazard, declared rather than hidden: the
  # numbers 3 and 2 are the seed's 2 and 1 ON TOP OF a live mixed-table census of ONE (re-taken 2026-10-04, Q-968); ZERO when
  # measured 2026-09-03 immediately after reports/METHODS.md:71 was labelled. The next live
  # 5b finding turns both EREs red. RE-TAKE RECIPE, not a reason to weaken them: run
  # `bash scripts/doc_gates.sh status`, read the "N of those are in a MIXED table" figure,
  # and rewrite these two as N+2 and N+1.
  assert_stays_clean_why "GATE 5b (5b-ii) one allowlist entry removes exactly ONE occurrence from the class" status \
'2 of those are in a MIXED table' \
"$_5b_seed
a='documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt'
t=open(a,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the allowlist does not end with a newline'
open(a,'a',encoding='utf-8').write(d+chr(9)+'synthetic unmarked alpha'+chr(10))"

  # 5b-iii — WHICH twin survived, in the SAME tree state as 5b-ii. 5b-ii proves one
  # occurrence left the class; this proves the one still in it is the twin with NO entry, so
  # the entry cannot be swallowing the table. Relative to nothing and immune to the corpus
  # moving, which is why the absolute pin above is not asked to carry this claim as well.
  assert_stays_clean_why "GATE 5b (5b-iii) the twin with NO entry is still reported in that same run" status \
'\| synthetic unmarked beta \|' \
"$_5b_seed
a='documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt'
t=open(a,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the allowlist does not end with a newline'
open(a,'a',encoding='utf-8').write(d+chr(9)+'synthetic unmarked alpha'+chr(10))"

  # 5b-iv — the REGISTRY names itself. The allowlist audit prints `exemption live` only when
  # the anchor resolves to EXACTLY ONE line (zero matches and >1 match each print a different
  # [note]), and it prints the line number it COMPUTED. This is the assertion the file's own
  # header claim rests on: an empty registry and a dead registry look identical from the file,
  # and this is the run that tells them apart.
  assert_stays_clean_why "GATE 5b (5b-iv) the allowlist audit resolves the seeded anchor to one live line" status \
'DOC_GATE_UNMARKED_ALLOWLIST\.txt: documentation/LITERATURE_RULES_POPULATION_TESTS\.md:[0-9]+ exemption live' \
"$_5b_seed
a='documentation/DOC_GATE_UNMARKED_ALLOWLIST.txt'
t=open(a,encoding='utf-8').read()
assert t.endswith(chr(10)), 'the allowlist does not end with a newline'
open(a,'a',encoding='utf-8').write(d+chr(9)+'synthetic unmarked alpha'+chr(10))"

  # -----------------------------------------------------------------------
  # GATE 12 — FIVE fire-proofs and ONE negative control (2026-08-02, item A4).
  #
  # The gate has five independent legs and they do NOT subsume one another; the tree it was
  # written against proves it. TR-8's misordering broke the DATE order, TR-4's broke only
  # the VERSION order (both of its rows read 2026-08-01, because `a15c6dd` had already
  # corrected v1.16's future-dated stamp). A gate built to item A4's literal wording — "no
  # duplicate version number, exactly one *(current)*, dates ascending" — would have cleared
  # TR-4. So each leg gets its own assertion, and each mutation is chosen to fire ONE leg:
  # a duplicate that is also a version regression would pass an assertion that never
  # exercised the duplicate check.
  #
  # Every case asserts WHY (item A5 / #65). The negative control is not optional here — the
  # duplicate leg carries a suffix-keyed exemption, and without a control a green gate is
  # equally consistent with "the exemption is precise" and "the exemption swallows the
  # table".
  #
  # (1) DUPLICATE RELEASED VERSION — the motivating example: TR-1 shipped two v1.21 rows for
  #     a day. The mutation copies the PENULTIMATE row's version onto the last row, which
  #     leaves the order non-descending (equal, not backwards), the date untouched and the
  #     marker in place, so ONLY the duplicate leg can fire.
  #
  #     ANCHOR-FREE ON PURPOSE, and this is not a stylistic preference. The first version
  #     hardcoded `| v1.22 *(current)* |`, and four commits later the same unit appended TR-1
  #     v1.23 — the anchor was gone and the assertion could no longer inject. It reported
  #     [FAIL] rather than a silent pass, which is the harness working, but the fix is to stop
  #     writing a version number into a fire-proof for a table whose whole purpose is to grow.
  #     The evidence ERE is generic for the same reason; no other leg prints this sentence.
  assert_fires_why "GATE 12 duplicate released version (TR-1's real two-v1.21 defect)" revhist \
    'released version v[0-9.]+ is already used at line' \
"f='reports/TR1_EIGHT_CENTURIES_MEASURED.md'
lines=open(f,encoding='utf-8').read().split(chr(10))
h=[n for n,l in enumerate(lines) if l.strip()=='## Revision history']
assert len(h)==1, 'no single revision-history heading'
rows=[n for n in range(h[0],len(lines)) if lines[n].startswith('| v')]
assert len(rows)>=2, 'need two rows to duplicate one onto the other'
prev=lines[rows[-2]].split('|')[1].strip()
last=lines[rows[-1]].split('|')
assert '(current)' in last[1], 'the last row is not the current one'
last[1]=' '+prev+' *(current)* '
lines[rows[-1]]='|'.join(last)
open(f,'w',encoding='utf-8').write(chr(10).join(lines))"

  # (2) DATES BACKWARDS — TR-8's shape. Back-date the last row only; its version stays the
  #     highest and the marker stays last, so no other leg can account for the firing.
  # ANCHOR RE-DERIVED 2026-08-07, and made DRIFT-PROOF. The original hardcoded
  # `| v1.9 *(current)* | 2026-08-01 |`; TR-3 then shipped v1.10 (2026-08-06), the literal
  # stopped matching, and the assertion went RED with "could not inject (anchor moved)".
  # It now derives the last row the way case (1) does — every future revision row moves the
  # anchor with it, so this fixture cannot go stale again for that reason.
  # THE ERE WAS DELIBERATELY LOOSENED on the row-above date, which used to be hardcoded to
  # 2026-07-31 and was the OTHER half of the same staleness. `2026-[0-9-]+` still pins that
  # the gate read a real neighbouring row, and `2020-01-01` — a sentinel no real row could
  # carry — still pins that it read THIS injection. What is given up is the ability to catch
  # a gate that names the wrong neighbour but gets the direction right; that is a smaller
  # loss than a fixture that fails for calendar reasons every few days.
  assert_fires_why "GATE 12 a row dated before the row above it" revhist \
    'dates run BACKWARDS: 2026-[0-9-]+ \(row above\) then 2020-01-01' \
"f='reports/TR3_REPRODUCIBLE_ENUMERATION.md'
lines=open(f,encoding='utf-8').read().split(chr(10))
rows=[n for n,l in enumerate(lines) if l.startswith('| v')]
assert len(rows)>=2, 'anchor moved: need two revision rows'
cells=lines[rows[-1]].split('|')
assert '(current)' in cells[1], 'anchor moved: the last row is not the current one'
cells[2]=' 2020-01-01 '
lines[rows[-1]]='|'.join(cells)
open(f,'w',encoding='utf-8').write(chr(10).join(lines))"

  # (3) VERSIONS BACKWARDS — TR-4's shape, the one the date leg is blind to. Raising an
  #     EARLY row above its successor (v1.2 -> v1.9 in a file that stops at v1.7) keeps every
  #     date untouched and introduces no duplicate, so this fires the version leg alone.
  assert_fires_why "GATE 12 versions out of order with every date legitimate" revhist \
    'versions run BACKWARDS: v1\.9 \(row above\) then v1\.3' \
"f='reports/TR6_PARITY_SKELETON.md'
s=open(f,encoding='utf-8').read()
a='| v1.2 | 2026-07-04 | Figures added |'
assert a in s, 'anchor moved'
open(f,'w',encoding='utf-8').write(s.replace(a,'| v1.9 | 2026-07-04 | Figures added |',1))"

  # (4) *(current)* NOT LAST — the leg that caught TR-4. Moving the marker up one row keeps
  #     the count at exactly one, so the count leg cannot be what fires.
  # 🔴 Q-702 (2026-09-24, Fable K): the anchors were the LITERAL rows `| v2.2 *(current)* |` and
  # `| v2.1 |`; TR-7 is at v2.5 and this leg had been "could not inject (anchor moved)" since
  # v2.3 landed. A fixture keyed to a report's version number rots on every revision of that
  # report. It now finds the ONE row carrying the marker and the row immediately above it, and
  # asserts both (exactly one marker; a `| vX.Y |` row directly above) before writing.
  assert_fires_why "GATE 12 the *(current)* marker is not on the last row" revhist \
    'is not the LAST revision row' \
"import re
f='reports/TR7_CIRCULAR_READING.md'
L=open(f,encoding='utf-8').read().split(chr(10))
cur=[i for i,l in enumerate(L) if re.match(r'\| v[0-9.]+ \*\(current\)\* \|', l)]
assert len(cur)==1, 'anchor moved: %d *(current)* rows' % len(cur)
i=cur[0]
assert i>0 and re.match(r'\| v[0-9.]+ \|', L[i-1]), 'anchor moved: no plain version row above the marker'
L[i]=L[i].replace(' *(current)* |',' |',1)
L[i-1]=L[i-1].replace(' |',' *(current)* |',1)
open(f,'w',encoding='utf-8').write(chr(10).join(L))"

  # (5) MISSING INPUT (item A1's class, applied to the new gate before it can grow the
  #     hole). The gate enumerates from `git ls-files` and opens from the worktree, so a
  #     deleted tracked TR is a FAIL naming the file — NOT a silently shorter list. The
  #     corpus preflight also fires here; the assertion targets GATE 12's own wording so it
  #     cannot be satisfied by the preflight's.
  assert_fires_why "GATE 12 (A1) a tracked TR deleted from the worktree" revhist \
    'TR6_PARITY_SKELETON\.md is tracked but could not be read' \
"import os
f='reports/TR6_PARITY_SKELETON.md'
assert os.path.exists(f), 'anchor moved'
os.remove(f)"

  # (6) NEGATIVE CONTROL for the duplicate leg's exemption. TR-11 legitimately carries three
  #     `v1.0-draft` rows; a FOURTH must still be clean, and the exemption must be doing that
  #     because of the SUFFIX. Case (1) above is the other half: strip the suffix and the
  #     same duplicate is a FAIL.
  # EVIDENCE (round 8 drain-3, UPGRADED round 9 item B9): the duplicate-version clause of
  # GATE 12's own pass line pinned that the leg which WOULD have flagged this row ran, and
  # nothing more — GATE 12 counted FILES, and a file count does not move when a row is
  # inserted. It now counts ROWS, and this mutation inserts exactly one, so a run that never
  # re-read TR-11 goes RED.
  #
  # THE PIN WAS ABSOLUTE AND IT ROTTED — CONVERTED TO A COMPARISON 2026-08-11. Its history is
  # the argument: 158/159 when written, re-measured to 172/173 on 2026-08-07 (8bddd2cd), and
  # RED again four days later. The drift was RECONSTRUCTED commit by commit rather than
  # guessed, by running `bash scripts/doc_gates.sh revhist` at each commit that touched
  # reports/TR*.md since the pin was last taken:
  #     8bddd2cd 172 (pin correct)   0d02ccf4 172   8849f250 172
  #     1229cfb5 173 (pin now STALE) 30b0c7aa 174   5d04b8d6 174   afd76fc6 174
  #     93878a18 175 (TR-11 v1.19)   a23d82a9 175
  # So the pin first went stale at 1229cfb5, TWO commits and two rows before 93878a18 — the
  # commit that landed TR-11 v1.19 contributed exactly ONE row of a three-row gap and did not
  # break this leg. Recorded because "which commit broke it" is the question a red assertion
  # provokes, and here the honest answer is that nothing did: an absolute count in an
  # assertion over a corpus whose whole purpose is to GROW breaks on a schedule.
  #
  # THE TECHNIQUE IS GATE 25 LEG 2's, and the same conversion was applied to GATE 25's own
  # negative control in the same pass: take the census on the CLEAN tree, then require the
  # mutated run to read base + 1 rows. The TR-file count is pinned to base EXACTLY — it must
  # NOT move, since this mutation adds a row to an existing file — so a run that read fewer
  # revision histories is still RED. Nothing here needs re-measuring when a TR ships a row.
  # If the base census cannot be read the leg FAILS and says so; the sentinel then fails the
  # assertion too, so a base that could not be taken never reads as a base that agreed.
  # WHAT IT STILL DOES NOT PROVE, since a clear is weaker than a failure: that the inserted
  # row was tested for the DRAFT-suffix exemption specifically. It proves it was PARSED as a
  # row and that no duplicate-release finding came out of the file it went into.
  # GATE 16 SEES ONLY THE FRAGMENT ` TR revision histories, ` here, for the piecewise-quoting
  # reason recorded in full at GATE 25's converted control: the real ERE contains it, so a
  # fragment that no preflight can emit guarantees an ERE that no preflight can emit.
  _G12_BASE=$(bash "$0" revhist 2>&1)
  _G12_T=$(printf '%s' "$_G12_BASE" | grep -oE '[0-9]+ TR revision histories' | grep -oE '^[0-9]+')
  _G12_R=$(printf '%s' "$_G12_BASE" | grep -oE '[0-9]+ revision row\(s\) checked' | grep -oE '^[0-9]+')
  if [ -z "$_G12_T" ] || [ -z "$_G12_R" ]; then
    echo "  [FAIL] GATE 12 negative control — the base revhist run printed no census line, so"
    echo "         the control below has no base to compare against. A leg that cannot read"
    echo "         its own base is silent, not clean."
    PASS=1; _G12_T=-1; _G12_R=-1
  fi
  assert_stays_clean_why "GATE 12 a repeated DRAFT label is exempt (suffix-keyed, not file-keyed)" revhist \
    "$_G12_T"' TR revision histories, '"$((_G12_R + 1))"' revision row\(s\) checked: .* no repeated released version' \
"f='reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md'
lines=open(f,encoding='utf-8').read().split(chr(10))
i=[n for n,l in enumerate(lines) if l.startswith('| v1.0-draft | 2026-07-05 |')]
assert len(i)==1, 'anchor moved'
lines.insert(i[0]+1,'| v1.0-draft | 2026-07-05 | Self-test row: a repeated DRAFT label is legitimate. |')
open(f,'w',encoding='utf-8').write(chr(10).join(lines))"

  # GATE 13 (item A4). Four assertions, and the third is the one that matters: it is not a
  # mutation at all but a REAL COMMIT — `b5bcff7c`, the 2026-07-25 one-line edit to TR-4 §3
  # that shipped with no revision row and that TR-4 v1.13 exists to record after the fact.
  # A synthetic injection proves the classifier reacts to something; pointing the gate at the
  # defect it was written for proves it reacts to THAT. Both directions are asserted, because
  # a one-directional fire-proof is exactly what GATE 8 shipped behind (see this file's
  # header) — 00c0db0 touched the same two TRs and gave BOTH a row, so it must stay silent.
  #
  # THE RANGE IS PINNED ON EVERY ASSERTION, including the worktree ones, where it is set to
  # the empty range HEAD..HEAD. Without that the batch leg would also run and its output could
  # satisfy — or mask — an assertion written about the worktree leg. That is the GATE 4b
  # lesson (an assertion aimed at a combined dispatch cannot say which half answered), applied
  # before it can bite rather than after.
  #
  # ASSERT ON OUTPUT, never on rc: GATE 13 is report-only and returns 0 by design.
  _g13() { DOC_GATE_REVROW_RANGE="$1" bash "$0" revrows 2>&1; }

  if python3 -c "f='reports/TR6_PARITY_SKELETON.md'
s=open(f,encoding='utf-8').read()
open(f,'w',encoding='utf-8').write(s+chr(10)+'Self-test body sentence with no revision row.'+chr(10))" 2>/dev/null; then
    G13OUT=$(_g13 'HEAD..HEAD')
    if grep -qE 'WORKTREE reports/TR6_PARITY_SKELETON\.md — 1 body line' <<<"$G13OUT"; then
      echo "  [ok]   GATE 13 worktree — an uncommitted TR body edit with no revision row is noted"
    else
      echo "  [FAIL] GATE 13 worktree — a body edit with no revision row was NOT noted."
      printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 13 worktree — could not inject, so the assertion did NOT run."; PASS=1
  fi
  _selftest_revert

  # The negative control for the worktree leg. Without it, "notes a body edit" is equally
  # consistent with "notes ANY edit to a TR", which would make the gate pure noise.
  if python3 -c "f='reports/TR6_PARITY_SKELETON.md'
s=open(f,encoding='utf-8').read()
open(f,'w',encoding='utf-8').write(s+chr(10)+'Self-test body sentence, recorded below.'+chr(10)+'| v9.99 | 2026-08-02 | Self-test revision row. |'+chr(10))" 2>/dev/null; then
    G13OUT=$(_g13 'HEAD..HEAD')
    # THE VACUITY GUARD, and it is not decoration. "No WORKTREE note" is also what a run
    # prints when the injection never reached the tree — the gate would then say
    # "working tree: no uncommitted TR edit" and this assertion would pass having tested
    # nothing. Requiring that line to be ABSENT is what makes the silence mean something.
    if grep -qE 'no uncommitted TR edit' <<<"$G13OUT"; then
      echo "  [FAIL] GATE 13 worktree negative control — the gate saw a CLEAN tree, so the"
      echo "         injection never landed and the silence proves nothing (vacuous pass)."
      PASS=1
    elif grep -qE 'WORKTREE' <<<"$G13OUT"; then
      echo "  [FAIL] GATE 13 worktree negative control — a body edit that DID get a row was noted."
      printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -5
      PASS=1
    else
      echo "  [ok]   GATE 13 worktree negative control — a body edit WITH a revision row is silent"
    fi
  else
    echo "  [FAIL] GATE 13 worktree negative control — could not inject; assertion did NOT run."; PASS=1
  fi
  _selftest_revert

  G13OUT=$(_g13 'b5bcff7c^..b5bcff7c')
  if grep -qE 'b5bcff7c reports/TR4_SIZE_OF_THE_SPACE\.md' <<<"$G13OUT"; then
    echo "  [ok]   GATE 13 batch — fires on b5bcff7c, the real silent TR-4 edit v1.13 records"
  else
    echo "  [FAIL] GATE 13 batch — b5bcff7c is the commit this gate was written for (TR-4 §3"
    echo "         edited, no revision row; recorded after the fact as v1.13) and it was NOT"
    echo "         noted. If that commit has been rewritten, re-anchor on another real one."
    printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -6
    PASS=1
  fi

  G13OUT=$(_g13 '00c0db0^..00c0db0')
  # THE SAME VACUITY GUARD. If that sha is ever rewritten or unreachable, `git rev-list`
  # returns nothing, the gate reports zero commits examined, and "no note was printed"
  # becomes true for a reason that has nothing to do with the gate working. Assert the
  # commit was actually READ before reading anything into its silence.
  if ! grep -qE '1 non-merge commit\(s\) examined' <<<"$G13OUT"; then
    echo "  [FAIL] GATE 13 batch negative control — the range 00c0db0^..00c0db0 resolved to no"
    echo "         commit, so the absence of a note proves nothing (vacuous pass). Re-anchor"
    echo "         on a reachable commit that gives every TR it touches a revision row."
    printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -4
    PASS=1
  elif grep -qE '\[note\] 00c0db0' <<<"$G13OUT"; then
    echo "  [FAIL] GATE 13 batch negative control — 00c0db0 gave BOTH TRs it touched a revision"
    echo "         row and must be silent. A gate that notes a compliant commit is noise."
    printf '%s\n' "$G13OUT" | sed 's/^/           > /' | head -6
    PASS=1
  else
    echo "  [ok]   GATE 13 batch negative control — 00c0db0 gave both its TRs a row, and is silent"
  fi

  # GATE 5, added 2026-08-02 with the #65 work. The old note said this gate could not be
  # mutation-tested because doing so "would require editing a canonical quantity" — which
  # was true only of the mutation shape assumed. APPENDING a new sentence that quotes 5.21
  # with the wrong status edits no existing value at all, and reverts like every other
  # GUIDE.md mutation here. The stated reason for a coverage gap is worth re-testing, not
  # just inheriting: that is the same "recorded state that was not true" class this suite
  # exists for. Assert on OUTPUT, like GATE 1: gate 5 is report-only and always exits 0.
  # The assertion is on the WHY text, not merely on the presence of a WARN — a gate that
  # fires without saying what it matched is the defect #65 was raised to fix.
  python3 -c "s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+chr(10)+'The exact figure 5.21 x 10^31 is a proven count.'+chr(10))" 2>/dev/null \
    && { G5OUT=$(bash "$0" status 2>&1)
         if grep -q "carries exact/proven token(s)" <<<"$G5OUT"; then
           echo "  [ok]   GATE 5 epistemic status — WARNs and names the tokens it matched"
         else
           echo "  [FAIL] GATE 5 did not fire, or fired without naming what it matched"
           printf '%s\n' "$G5OUT" | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/GUIDE.md; } \
    || { echo "  [FAIL] GATE 5 — could not append to GUIDE.md, so the assertion did NOT run"
         echo "         (item A5)."; PASS=1; }

  # GATE 5 TOKENISER (Q-604, 2026-09-26) — TWO ASSERTIONS FROM ONE INJECTION. The EX
  # alternation used to anchor only the START of each word, so "exactly" read as "exact" and
  # "provenance" as "proven" anywhere on a registry-value line. It is now boundaried at both
  # ends, and "exactly" counts only when ADJACENT to the figure (see exly_near in GATE 5).
  # Lines B and C are the positive half, one per word order: "exactly 5.21 x 10^31" IS an
  # exactness claim, and a blanket trailing boundary would silently drop it — that is the
  # mutant this half is for; C also needs the value's own x10^k tail skipped. Line A is
  # the negative half and carries every loose form at once ("exactly" far from the figure,
  # "provenance", "exactness"); the prefix tokeniser WARNs on it. Line A is asserted only in a
  # run where line C DID warn, so its silence cannot be the silence of a line never scanned.
  python3 -c "p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
s=s+chr(10)+'Self-test Q-604 line A: the figure 5.21 x 10^31 sits beside a sort that matches King Wen exactly; its provenance and exactness are recorded elsewhere.'+chr(10)
s=s+'Self-test Q-604 line B: the count is exactly 5.21 x 10^31 here.'+chr(10)
s=s+'Self-test Q-604 line C: the count 5.21 x 10^31 exactly, the other word order.'+chr(10)
open(p,'w',encoding='utf-8').write(s)" 2>/dev/null \
    && { _q604_n=$(wc -l < documentation/GUIDE.md)
         G5QOUT=$(bash "$0" status 2>&1)
         if grep -qE "GUIDE\.md:$_q604_n — quantity 5\.21 .*token\(s\) \"exactly\"" <<<"$G5QOUT" \
            && grep -qE "GUIDE\.md:$((_q604_n-1)) — quantity 5\.21 .*token\(s\) \"exactly\"" <<<"$G5QOUT"; then
           echo "  [ok]   GATE 5 (Q-604) an 'exactly' ADJACENT to the figure still counts — WARNs, naming \"exactly\""
         else
           echo "  [FAIL] GATE 5 (Q-604) 'exactly 5.21 x 10^31' or '5.21 x 10^31 exactly' was not reported as an exactness claim"
           printf '%s\n' "$G5QOUT" | grep -F 'GUIDE.md' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         if grep -qE "GUIDE\.md:$_q604_n — " <<<"$G5QOUT" \
            && ! grep -qE "GUIDE\.md:$((_q604_n-2)) — " <<<"$G5QOUT"; then
           echo "  [ok]   GATE 5 (Q-604) a non-adjacent 'exactly', 'provenance' and 'exactness' carry no status"
         else
           echo "  [FAIL] GATE 5 (Q-604) line A warned (a prefix match read as a status token), or"
           echo "         line C did not, so line A's silence proves nothing"
           printf '%s\n' "$G5QOUT" | grep -F 'GUIDE.md' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/GUIDE.md; } \
    || { echo "  [FAIL] GATE 5 (Q-604) — could not append to GUIDE.md, so the assertions did NOT run"
         PASS=1; }

  # GATE 5 EST TOKENISER (2026-09-26, the sibling of Q-604) — TWO ASSERTIONS FROM ONE
  # INJECTION. EST anchored neither end of four of its words, so an identifier or a longer
  # word that merely CONTAINED one (knuth_whole_tree, SOLVE_KNUTH_*, underestimate, Montel)
  # read as an estimate marker, and on a line that also says "exact" about an ESTIMATE-status
  # figure it SUPPRESSED the WARN. Line A (the last line appended) carries an exactness token
  # and ONLY loose forms, one per boundary the regex has -- leading and trailing for estimate,
  # Knuth, confidence and Monte -- so loosening ANY single boundary silences it: that is the
  # negative half, and it must WARN naming "exact". Lines B-G are the positive half, one
  # genuine marker form each (Knuth's, estimates, Monte Carlo, 95% CI, confidence, estimated):
  # an over-tightened EST that dropped a real form would WARN on its line. The positive half is
  # asserted only in a run where line A DID warn, so its silence cannot be the silence of a
  # file never scanned.
  python3 -c "p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()+chr(10)
for w in (\"against Knuth's value\",'and two estimates of it','beside a Monte Carlo run','inside its 95% CI','reported with confidence','as it was estimated'):
    s=s+'Self-test EST line B-G: the exact figure 5.21 x 10^31 '+w+'.'+chr(10)
s=s+'Self-test EST line A: the exact figure 5.21 x 10^31 per underestimate, estimate_total, SOLVE_KNUTH_MODE, knuth_whole_tree, noconfidence, confidence_level, Piemonte, Montel.'+chr(10)
open(p,'w',encoding='utf-8').write(s)" 2>/dev/null \
    && { _est_n=$(wc -l < documentation/GUIDE.md)
         G5EOUT=$(bash "$0" status 2>&1)
         if grep -qE "GUIDE\.md:$_est_n — quantity 5\.21 .*token\(s\) \"exact\"" <<<"$G5EOUT"; then
           echo "  [ok]   GATE 5 (EST) an identifier or longer word containing an estimate word is no marker — WARNs"
           _est_bad=0
           for _k in 1 2 3 4 5 6; do
             grep -qE "GUIDE\.md:$((_est_n-_k)) — " <<<"$G5EOUT" && _est_bad=1
           done
           if [ "$_est_bad" -eq 0 ]; then
             echo "  [ok]   GATE 5 (EST) Knuth's, estimates, Monte Carlo, CI, confidence and estimated still mark an estimate"
           else
             echo "  [FAIL] GATE 5 (EST) a genuine estimate marker (lines B-G) no longer counts"
             printf '%s\n' "$G5EOUT" | grep -F 'GUIDE.md' | sed 's/^/           > /' | head -6
             PASS=1
           fi
         else
           echo "  [FAIL] GATE 5 (EST) line A did not WARN: a loose form (identifier or longer word)"
           echo "         read as an estimate marker, so lines B-G were NOT asserted"
           printf '%s\n' "$G5EOUT" | grep -F 'GUIDE.md' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert documentation/GUIDE.md; } \
    || { echo "  [FAIL] GATE 5 (EST) — could not append to GUIDE.md, so the assertions did NOT run"
         PASS=1; }

  # -----------------------------------------------------------------------
  # GATE 5's ALLOWLIST — three assertions (2026-08-02, item A8). Re-keying the allowlist on
  # (file, anchor) alone deleted the drift branch that had a live negative control (an
  # entry recorded at line 9999 fired it). Deleting a branch deletes its proof, so the
  # replacement proofs are written here rather than assumed. All three are OUTPUT
  # assertions: GATE 5 is report-only and always exits 0.
  #
  # (1) DRIFT IMMUNITY — the whole point of A8. Insert a line ABOVE the anchored TR-4
  #     sentence. The exemption must still resolve (to a line one greater) and the run must
  #     produce NO [note] at all: under the old scheme this exact edit produced one.
  #     THE EXPECTED LINE IS MEASURED FIRST, NOT PINNED (2026-08-07). It was hardcoded
  #     ":123 -> :124"; TR-4 grew, the row moved to :136, and this printed "GATE 5 allowlist
  #     did not survive an insertion above its anchor" — an accusation against a gate that
  #     was working. The clean position is now read from GATE 5's own output and the
  #     assertion is that it lands at exactly clean+1. That is a STRICTER claim than the old
  #     literal: it pins the DISPLACEMENT, which is the property A8 is about, instead of a
  #     coordinate that any edit above the table invalidates.
  A8BASE=$(bash "$0" status 2>&1 | sed -n 's/.*TR4_SIZE_OF_THE_SPACE\.md:\([0-9][0-9]*\) exemption live.*/\1/p' | head -1)
  python3 -c "s=open('reports/TR4_SIZE_OF_THE_SPACE.md').read()
a='*none — no exact value exists*'
assert a in s, 'anchor moved'
i=s.index(a); j=s.rindex(chr(10), 0, i)
open('reports/TR4_SIZE_OF_THE_SPACE.md','w').write(s[:j]+chr(10)+'<!-- selftest: a line inserted above the anchored row -->'+s[j:])" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if [ -n "$A8BASE" ] \
            && grep -q "TR4_SIZE_OF_THE_SPACE.md:$((A8BASE+1)) exemption live" <<<"$A8OUT" \
            && ! grep -q '\[note\] allowlist' <<<"$A8OUT"; then
           echo "  [ok]   GATE 5 allowlist drift immunity — anchor moved :$A8BASE -> :$((A8BASE+1)), still live, no [note]"
         else
           echo "  [FAIL] GATE 5 allowlist did not survive an insertion above its anchor"
           printf '%s\n' "$A8OUT" | grep -E 'allowlist' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 5 allowlist drift case — could not inject; assertion did NOT run."; PASS=1; }

  # (2) DEAD ANCHOR still audited. This is the branch A8's option (ii) was said to cost,
  #     and it does not: it never read the line number.
  python3 -c "open('documentation/DOC_GATE_STATUS_ALLOWLIST.txt','a').write(
'documentation/HISTORY.md'+chr(9)+'a sentence that appears nowhere in the corpus'+chr(10))" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if grep -q 'anchor no longer appears in the file' <<<"$A8OUT"; then
           echo "  [ok]   GATE 5 allowlist dead-anchor audit — fires, and says prune it"
         else
           echo "  [FAIL] GATE 5 allowlist accepted an anchor matching nothing, silently"
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 5 dead-anchor case — could not inject; assertion did NOT run."; PASS=1; }

  # (3) AN UNANCHORED ENTRY SUPPRESSES NOTHING. Under the old scheme it suppressed by line
  #     number, which is the direction that let an unreviewed line inherit somebody else's
  #     exemption. The entry injected here names the exact file:line GATE 5 warns about in
  #     assertion (1) above, so if it still suppressed, the WARN would vanish.
  python3 -c "s=open('documentation/GUIDE.md').read()
open('documentation/GUIDE.md','w').write(s+chr(10)+'The exact figure 5.21 x 10^31 is a proven count.'+chr(10))
n=len(open('documentation/GUIDE.md').read().split(chr(10)))-1
open('documentation/DOC_GATE_STATUS_ALLOWLIST.txt','a').write('documentation/GUIDE.md:%d'%n+chr(10))" 2>/dev/null \
    && { A8OUT=$(bash "$0" status 2>&1)
         if grep -q 'SUPPRESSES NOTHING' <<<"$A8OUT" \
            && grep -q "carries exact/proven token(s)" <<<"$A8OUT"; then
           echo "  [ok]   GATE 5 unanchored allowlist entry — reported AND inert"
         else
           echo "  [FAIL] GATE 5 unanchored entry suppressed a WARN, or was not reported"
           printf '%s\n' "$A8OUT" | grep -E 'allowlist|WARN' | sed 's/^/           > /' | head -4
           PASS=1
         fi
         _selftest_revert; } \
    || { echo "  [FAIL] GATE 5 unanchored case — could not inject; assertion did NOT run."; PASS=1; }

  # GATE 5b (item A4), asserted against ITS OWN MOTIVATING EXAMPLE rather than a synthetic
  # table: the mutation reverts TR-9's C3 ledger cell to the bare-number form it carried
  # before #23 fixed it. That is the defect the class exists for, and TR-9 v1.19 states
  # that GATE 5 could not see it. Report-only, so the assertion is on the OUTPUT.
  #
  # WHY THE ASSERTION NAMES THE FILE AND THE WORD "NO status marker": 5b was narrowed TWICE
  # after its first run — a column-aware header exemption and a changelog-row exemption,
  # which between them took its live findings from 6 to 0. A gate narrowed to silence is
  # indistinguishable from a gate narrowed to precision unless something re-proves it still
  # fires, and neither narrowing may be allowed to swallow this case.
  # A DRIFTED ANCHOR IS A FAILURE HERE, NOT A SKIP. Written as a [SKIP] first, and the very
  # first run printed "[SKIP] GATE 5b — anchor moved" because the injector's `%` had been
  # written `%%` (a printf habit; this is a plain double-quoted bash string). The assertion
  # never ran and the suite still reported PASS — GATE 8's failure exactly, reproduced
  # within an hour of writing the rule down. So: no silent skip. If TR-9's cell is legitimately
  # reworded, this must go red and be re-anchored by hand, because a fire-proof that opts
  # itself out is not a proof.
  #
  # The mutation is NOT injected via `python3 -c` for the same reason: the shell layer is
  # where the escaping went wrong. It is written to a file and run, so the string reaching
  # python is the string in this script.
  # THE LINE NUMBER IS DERIVED, NOT PINNED (2026-08-07). It was hardcoded as line 70; TR-9 grew
  # and the cell moved to :78, so the grep missed and this printed "GATE 5b did not fire on
  # the defect it was written for" — which was FALSE. The gate fired correctly; the fixture's
  # expectation was stale. That is a worse failure mode than a missed anchor: it accuses a
  # working gate. The mutator now reports the line it actually edited and the assertion is
  # built from that, so the check is "5b names the cell I just broke", which is the real
  # claim, and it cannot drift. The anchor STRING is still pinned and still asserted unique —
  # the drift-proofing is on the coordinate, not on the identity of the defect.
  # 🔴 Q-283 / Codex N10 finding 3, same class (GATE 13 is report-only, which changes the
  # severity of its FINDINGS and not its obligation to be able to run).
  G5BMUT=$(mktemp) || { echo "  [FAIL] GATE 13: mktemp failed, so NOTHING was checked."; return 1; }
  G5BLINEF=$(mktemp) || { rm -f "$G5BMUT"; echo "  [FAIL] GATE 13: mktemp failed, so NOTHING was checked."; return 1; }
  cat > "$G5BMUT" <<'G5BPY'
import os, sys
p = 'reports/TR9_PRICING_THE_CONSTRAINTS.md'
a = '1.3287×10³⁸ (**estimate** — Knuth random-probe, 95% CI [1.3283, 1.3292]×10³⁸, 0.02%)'
s = open(p, encoding='utf-8').read()
if s.count(a) != 1:
    raise SystemExit('anchor moved: found %d occurrences' % s.count(a))
lines = s.split(chr(10))
hits = [n for n, l in enumerate(lines) if a in l]
if len(hits) != 1:
    raise SystemExit('anchor spans lines or repeats')
open(os.environ['G5BLINEF'], 'w').write(str(hits[0] + 1))
open(p, 'w', encoding='utf-8').write(s.replace(a, '1.3287×10³⁸', 1))
G5BPY
  if G5BLINEF="$G5BLINEF" python3 "$G5BMUT" 2>&1; then
    G5BLINE=$(cat "$G5BLINEF")
    G5BOUT=$(bash "$0" status 2>&1)
    if [ -n "$G5BLINE" ] && grep -q "TR9_PRICING_THE_CONSTRAINTS.md:$G5BLINE .* carries NO status marker" <<<"$G5BOUT"; then
      echo "  [ok]   GATE 5b unmarked-among-marked — fires on the pre-#23 TR-9 ledger cell"
    else
      echo "  [FAIL] GATE 5b did not fire on the defect it was written for"
      printf '%s\n' "$G5BOUT" | sed 's/^/           > /' | head -6
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 5b — could not inject its anchor, so the assertion did NOT run."
    echo "         Re-anchor it against TR-9's C3 ledger cell; a skipped fire-proof is not a proof."
    PASS=1
  fi
  rm -f "$G5BMUT" "$G5BLINEF"
  _selftest_revert reports/TR9_PRICING_THE_CONSTRAINTS.md

  # =========================================================================
  # GATE 8 — THREE mutation cases, ONE regeneration (added 2026-08-02, item A1).
  #
  # WHY THIS IS HERE AT ALL. GATE 8's fire-proof was taken BY HAND at df4ddc9. Its
  # invocation was rewritten hours later at 91129a4 and the proof was never re-run —
  # which is exactly how a ONE-DIRECTIONAL comparison shipped and attested "matches
  # exactly" over a DELETED line (b0ee2f8). A hand-taken proof is not a proof of the
  # code that ships; only an assertion that re-runs is.
  #
  # WHY IT ASSERTS ON THE EVIDENCE, NOT THE EXIT CODE. The bug it exists to catch —
  # comparing in one direction only — still exits non-zero on a SUBSTITUTION, because a
  # substitution leaves an added line behind as well. An exit-code assertion would have
  # passed on the broken gate. Each case therefore names the exact counted verdict
  # GATE 8 must print, so "0 added, 1 missing" (deletion, the direction that was
  # missing) is asserted as a number and cannot be satisfied by any other finding.
  #
  # THE COST, AND WHAT PAYS IT. Each GATE 8 invocation regenerates example/ from
  # roae.py — three runs, ~45 s each, so three naive cases would cost ~7 minutes. They
  # share ONE regeneration through DOC_GATES_GEN_CACHE, keyed on roae.py's sha256:
  # measured 135 s for the first case and 0.08 s for each of the others.
  GEN_CACHE=$(mktemp -d) || { echo "  [FAIL] GATE 13: mktemp -d failed, so NOTHING was checked."; return 1; }

  # assert_gen_fires <label> <evidence-ERE> <python-mutation>
  #   <evidence-ERE> must match a line of GATE 8's output.
  # ITEM A5: [FAIL], not [SKIP] — see the moved-anchor note at the head of the harness. This
  # one matters most of the helpers:
  # every one of its cases anchors on shipped content in example/ ('terminal attractor', the
  # "organizing feature" sentence, one byte of wave.mid), and example/ is REGENERATED
  # output, so a legitimate roae.py change moves those anchors without anyone editing a
  # fire-proof. GATE 8 is also the gate whose hand-taken proof already went stale once.
  # (The anchor list said "all four of its cases" and named report.pdf's existence until
  # 2026-09-04, when CASES 3 and 4 were retired with GATE 8 LEG 5 and the artifact they
  # mutated. The count is not restated: `callers=N` on this helper's row in
  # documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt is the machine-read authority, and
  # GATE 15 LEG 3 re-derives it every run.)
  assert_gen_fires() {
    local label="$1" want="$2" mut="$3" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped fire-proof is not a proof."
                           PASS=1; _selftest_revert; return; }
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -ne 1 ]; then   # Q-954 sweep: rc 1 is the fire; 2/124/137/143 is not
      echo "  [FAIL] $label — GATE 8 did NOT fire (rc 1) on an injected defect; rc=$rc"
      PASS=1; return
    fi
    if grep -Eq -- "$want" <<<"$out"; then
      echo "  [ok]   $label — GATE 8 fires, and WHY matches: $want"
    else
      echo "  [FAIL] $label — GATE 8 fired, but not for the asserted reason"
      echo "         expected a line matching: $want"
      printf '%s\n' "$out" | grep -E '\[FAIL\]' | head -3 | sed 's/^/           got > /'
      PASS=1
    fi
  }

  # CASE 1 — DELETION, the direction the shipped comparison could not see, in the exact
  # shape of the 2026-08-01 demonstration: remove the nuclear-attractor line from
  # example/report.txt. 0 added / 1 missing is the whole point — a `comm -13`-only gate
  # scores 0 added and reports [ok].
  # RE-ANCHORED 2026-09-04, when legs 1-4 became byte-exact under the shipped seed. The
  # VERDICT line no longer carries the normalised counts — `cmp` decides now — so the ERE is
  # moved onto the digit-stripped DIAGNOSTIC line, which still prints those counts and is
  # still the thing that distinguishes a deletion from an addition. The both-directions
  # property this case exists for is therefore still asserted, on the same numbers.
  assert_gen_fires "GATE 8 deletion from a shipped artifact" \
'example/report\.txt digit-stripped: 0 added, 1 missing' \
"p='example/report.txt'
L=open(p,encoding='utf-8').read().split(chr(10))
h=[i for i,x in enumerate(L) if 'terminal attractor' in x]
assert len(h)==1, 'anchor moved'
del L[h[0]]
open(p,'w',encoding='utf-8').write(chr(10).join(L))"

  # CASE 2 — SUBSTITUTION, the shape of defect (a): example/README.md was a hand-edited
  # copy of report.md differing by one word. One letter, in a line roae.py prints
  # UNCONDITIONALLY (print_complements' static preamble), so the case cannot be flaked by
  # a Monte Carlo verdict landing in a different branch.
  assert_gen_fires "GATE 8 one-word substitution in a shipped artifact" \
'example/README\.md digit-stripped: 1 added, 1 missing' \
"p='example/README.md'
a=\"is an organizing feature of the sequence's structure\"
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(a,a.replace('organizing','organising'),1))"

  # CASES 3 AND 4 — RETIRED 2026-09-04, WITH GATE 8 LEG 5 AND THE ARTIFACT THEY MUTATED.
  # Both were fire-proofs for the PDF leg: CASE 3 mutated example/report.html and asserted
  # LEG 5's OWN verdict line (so that a red gate could not be scored by leg 4 firing for its
  # own reason), and CASE 4 deleted example/report.pdf outright, which is the case that
  # PROVED a deleted tracked artifact FAILS rather than [skip]s — `rm example/report.pdf`
  # passing in silence is the defect this whole harness section was built around.
  #
  # THE DELETION-IS-NOT-A-SKIP PROPERTY IS NOT LOST WITH THEM, and this is the one thing a
  # reader must be able to check rather than take on trust. It never lived in CASE 4: it
  # lives in `require_tracked` at the head of this file, which GATE 8's `_present` calls for
  # EVERY leg, and in the corpus-wide `preflight_tracked_docs`. Both are still asserted here
  # — see the "PREFLIGHT (A1) a tracked .md deleted blinds every DOCS-iterating gate"
  # assertion, which fires on exactly this shape. What CASE 4 added on top was one END-TO-END
  # demonstration on a real tracked artifact, and that demonstration was written against a
  # file that no longer exists: example/report.pdf was removed on 2026-09-04 because
  # wkhtmltopdf embedded the complete unsubsetted DejaVu font programs in it.
  #
  # WHY NOT RE-POINT CASE 4 AT ANOTHER example/ ARTIFACT instead of retiring it. Considered
  # and rejected: `_selftest_revert` restores the tree with git, so a case that DELETES a
  # tracked file is only safe for a file the revert provably restores, and every candidate
  # (report.txt/.md/.html, README.md, the LEG 7 seven) is already covered by a case that
  # MUTATES it — a deletion adds a second path into the same `require_tracked` call. The
  # honest statement is that the end-to-end demonstration is gone and the implementation it
  # demonstrated is still asserted, not that nothing changed.

  # CASE 5 — THE NEGATIVE CONTROL, REBUILT 2026-09-04 WHEN ITS OLD SUBJECT CEASED TO EXIST.
  #
  # WHAT IT USED TO BE, and why it is not that any more. Until today legs 1-4 stripped digits,
  # and this case existed to pin the 2026-08-02 false FAIL: roae.py:1458 formats with
  # `{ratio:,}`, the normaliser stripped digits but not the group separator, and
  # `doc_gates.sh generated` printed
  #   +added   > Approximately in random orderings share this property.
  #   -missing > Approximately in , random orderings share this property.
  # on artifacts that were CORRECT. The case injected a comma-grouped figure into the
  # REGENERATED REFERENCE and asserted the gate stayed GREEN. That assertion is now FALSE BY
  # DESIGN: example/ ships under `--seed $ROAE_EXAMPLE_SEED`, the reference is regenerated
  # under the same seed, and a changed figure in either side is exactly what legs 1-4 must now
  # go red on. Keeping the old case would have asserted the opposite of the new contract.
  # THE NORMALISER IS STILL THERE and still fixed — it prints the digit-stripped diagnostic
  # counts that CASES 1 and 2 assert on — so the round-4 defect remains covered, one level
  # down, by the two cases that read those counts.
  #
  # WHAT IT IS NOW, and why the gate still needs one. Every other GATE 8 case proves the gate
  # goes RED. None of them can tell a working gate from one that is red on everything —
  # and byte-exactness is precisely the change that could make a gate red on a correct tree
  # (a seed mismatch between the shipped artifacts and the regeneration would do it, silently,
  # and every firing case would still pass). So the control runs GATE 8 on the UNMUTATED tree
  # and requires rc 0 AND each of the four byte-exact [ok] lines by name. Naming them
  # individually is the load-bearing part: an rc-only assertion is satisfied by a leg that
  # skipped, which is the `[skip]`-is-not-a-pass shape this whole gate was rebuilt around.
  #
  # assert_gen_clean <label> <ere> [<ere> ...]
  assert_gen_clean() {
    local label="$1"; shift
    local out rc want
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    if [ "$rc" -ne 0 ]; then
      echo "  [FAIL] $label — GATE 8 is RED on the UNMUTATED tree (rc=$rc). Every firing case"
      echo "         in this harness would still pass; this is the only one that can see it."
      printf '%s\n' "$out" | grep -E '\[FAIL\]' | head -4 | sed 's/^/           got > /'
      PASS=1; return
    fi
    for want in "$@"; do
      if ! grep -Eq -- "$want" <<<"$out"; then
        echo "  [FAIL] $label — GATE 8 exited 0 but never printed the byte-exact verdict for one"
        echo "         of its legs, so that leg did not compare anything."
        echo "         expected a line matching: $want"
        PASS=1; return
      fi
    done
    echo "  [ok]   $label — GATE 8 is green on the shipped tree and all four report legs"
    echo "         reported BYTE-IDENTICAL rather than skipping"
  }

  assert_gen_clean "GATE 8 stays green on the shipped tree, byte-exact and not skipped" \
'\[ok\] +example/report\.txt is BYTE-IDENTICAL to a fresh roae\.py --all --seed [0-9]+' \
'\[ok\] +example/report\.md is BYTE-IDENTICAL to a fresh roae\.py --markdown --seed [0-9]+' \
'\[ok\] +example/README\.md is BYTE-IDENTICAL to a fresh roae\.py --markdown --seed [0-9]+' \
'\[ok\] +example/report\.html is BYTE-IDENTICAL to a fresh roae\.py --html --seed [0-9]+'

  # CASES 6 and 7 — THE DIGIT LEGS (item A2 residual, 2026-08-02). CASE 6 IS RETIRED, see
  # below; everything this paragraph says about "these two" is now carried by CASE 7 alone,
  # and the leg-5 half of it is history rather than a description of the harness.
  #
  # These assert something the other cases cannot: that the firing is PER FILE rather than a
  # gate that went red across the board. Every case above is satisfied by ANY leg going red,
  # so a case that merely proved "GATE 8 fires" would still be green if a leg were deleted
  # tomorrow and some other leg fired for its own reason. Each of these therefore asserts TWO
  # lines: the named leg's own verdict, AND a NAMED SIBLING's [ok] in the same run.
  # RE-POINTED 2026-09-04: the sibling used to be "the digit-BLIND leg's [ok] on the SAME
  # file", which proved the coverage was NEW. With legs 1-4 byte-exact there is no digit-blind
  # leg left, so the sibling is now a DIFFERENT FILE the mutation does not touch — which
  # proves per-file discrimination instead. That is a different property, weaker in one
  # direction and stronger in another, and it is named rather than swapped in silently.
  # That is the shape GATE 8's own history argues for: its first fire-proof was taken by hand,
  # was satisfied by an exit code, and a one-directional comparison shipped behind it.
  #
  # THE MUTATION IS ONE DIGIT in a line roae.py prints unconditionally (the static preamble),
  # so no Monte Carlo branch can flake it, and 64 -> 65 keeps the line's length and every
  # non-digit character identical — which is exactly why the digit-stripped legs cannot see
  # it, and is the point being proven.
  #
  # assert_gen_fires_only <label> <new-leg-ERE> <other-leg-stays-ok-ERE> <mutation>
  assert_gen_fires_only() {
    local label="$1" want="$2" alsowant="$3" mut="$4" out rc
    python3 -c "$mut" || { echo "  [FAIL] $label — could not inject (anchor moved), so the"
                           echo "         assertion did NOT run. A skipped fire-proof is not a proof."
                           PASS=1; _selftest_revert; return; }
    out=$(DOC_GATES_GEN_CACHE="$GEN_CACHE" bash "$0" generated 2>&1); rc=$?
    _selftest_revert
    if [ "$rc" -eq 0 ]; then
      echo "  [FAIL] $label — GATE 8 did NOT fire on a hand-edited digit"; PASS=1; return
    fi
    if ! grep -Eq -- "$want" <<<"$out"; then
      echo "  [FAIL] $label — GATE 8 fired, but not on the digit leg"
      echo "         expected a line matching: $want"
      printf '%s\n' "$out" | grep -E '\[FAIL\]' | head -3 | sed 's/^/           got > /'
      PASS=1; return
    fi
    if ! grep -Eq -- "$alsowant" <<<"$out"; then
      echo "  [FAIL] $label — the digit leg fired, but the digit-BLIND leg did not report [ok],"
      echo "         so this case does not prove the new leg is what caught it."
      echo "         expected a line matching: $alsowant"
      PASS=1; return
    fi
    echo "  [ok]   $label — only the digit leg sees it: \"$want\" while \"$alsowant\""
  }

  # CASE 6 — REINSTATED 2026-09-04, LATER THE SAME DAY IT WAS RETIRED, BY A DIFFERENT LEG.
  #
  # WHAT IT WAS AND WHAT KILLED IT: it mutated one digit in example/report.html and asserted
  # that GATE 8 LEG 5 caught it while the digit-BLIND leg 4 still reported [ok] on the same
  # file. LEG 5 compared report.pdf against report.html with digits intact, and it went with
  # example/report.pdf when that artifact was deleted for embedding the complete unsubsetted
  # DejaVu font programs. For a few hours the dbba77d class — a hand-edited number in
  # example/report.html, the file that WAS hand-patched once and was caught by the operator
  # rather than by a gate — was covered by nothing, and this file said so.
  #
  # WHAT BRINGS IT BACK is the close that the retirement note itself named: example/ is now
  # generated under `--seed $ROAE_EXAMPLE_SEED`, so leg 4 compares report.html BYTE-EXACT
  # against a reference generated under the same seed and sees the digit directly. The
  # coverage returns through the PRIMARY comparison rather than through a second artifact of
  # the same invocation, which is strictly better: it needs no PDF, no second renderer, and no
  # font programs on the machine that runs the gate.
  #
  # THE MUTATION IS THE ONE THAT WAS MEASURED TO PASS. On the live tree on 2026-09-04, before
  # the seed landed, `8x8 = 64` -> `65` in example/report.html left `doc_gates.sh generated` at
  # rc 0 and PASS. It is one digit in a line roae.py prints UNCONDITIONALLY (print_table's
  # static preamble), so no Monte Carlo branch can flake it, and it changes no non-digit
  # character — which is exactly why the pre-seed digit-stripped leg could not see it.
  #
  # THIS CASE IS assert_gen_fires, NOT assert_gen_fires_only: with legs 1-4 byte-exact there is
  # no longer a digit-BLIND sibling leg on report.html for a "the OTHER leg stayed green"
  # clause to name. The per-file discrimination that clause used to buy is asserted by CASE 7
  # (README.md mutated, report.md still [ok]) and by CASE 8 (csv mutated, json still [ok]).
  assert_gen_fires "GATE 8 hand-edited DIGIT in report.html (the dbba77d class, leg 4 byte-exact)" \
'example/report\.html differs BYTE-FOR-BYTE from a fresh roae\.py --html' \
"p='example/report.html'
a='giving 8x8 = 64 possible hexagrams'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'giving 8x8 = 65 possible hexagrams',1))"

  # CASE 7 — a hand-edited digit in example/README.md. Before leg 6 the two shipped copies
  # could disagree on every number in the corpus and the gate printed [ok] twice; leg 6 closed
  # that by comparing them to each other byte-exact.
  # RE-POINTED 2026-09-04. The sibling clause used to name leg 3's digit-BLIND [ok] on the same
  # file, which is what proved leg 6 was the only thing that saw the digit. Legs 1-4 are
  # byte-exact now, so leg 3 sees it too and that [ok] no longer exists; the clause is
  # re-pointed at example/report.md, the file the mutation did NOT touch. It proves a
  # different and still necessary thing: that the comparison is PER FILE and the gate did not
  # simply go red across the board. The label keeps its identity minus the stale "(leg 6
  # only)", which stopped being true today.
  assert_gen_fires_only "GATE 8 hand-edited DIGIT in README.md (leg 6, per-file)" \
'example/README\.md is not byte-identical to example/report\.md' \
'\[ok\] +example/report\.md is BYTE-IDENTICAL to a fresh roae\.py --markdown --seed [0-9]+' \
"p='example/README.md'
a='giving 8x8 = 64 possible hexagrams'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'giving 8x8 = 65 possible hexagrams',1))"

  # CASES 8 and 9 — LEG 7, THE SEVEN NON-REPORT ARTIFACTS (item 2477, 2026-09-03, wave-4
  # lane A2). LEG 7 landed 2026-09-02 for Codex v2 charge 6 with a red test taken BY HAND in
  # a scratch clone and nothing wired into the harness. That is the exact configuration this
  # file's own header calls the GATE 8 defect — "the gate whose hand-taken proof already went
  # stale once" — reproduced on the same gate one leg later. A hand-taken proof does not
  # re-run, and LEG 7 compares REGENERATED output, so the anchors it depends on move whenever
  # roae.py does.
  #
  # TWO CASES, NOT ONE, because LEG 7 has two output paths and only one of them is textual.
  # `_cmp_exact`'s failure branch forks on `grep -qI .`: a text artifact gets a `diff` excerpt
  # and a binary one gets `cmp`'s byte offset. A single csv case leaves the binary arm — the
  # arm that carries example/wave.mid and the two graphviz renderings, i.e. 3 of the 7 files —
  # proven by nothing.
  #
  # CASE 8 uses assert_gen_fires_only rather than assert_gen_fires, and the sibling clause is
  # the load-bearing half: LEG 7's seven comparisons share one loop and one helper, so "the
  # gate fired" is equally consistent with "the loop went red for all seven". MEASURED on the
  # injection below: hexagrams.csv FAILS while the other six print [ok] BYTE-IDENTICAL, so the
  # comparison is per-artifact. The sibling asserted is hexagrams.json — the nearest neighbour,
  # written by the same export path in the same generator run.
  #
  # THE INJECTION IS A SINGLE DIGIT, deliberately: legs 1-4 stripped digits when this case was
  # written (roae.py's Monte Carlo output moved every run), and LEG 7's whole reason to exist
  # was that these seven carry no Monte Carlo output and so can be compared byte-exact. Legs
  # 1-4 are byte-exact too since 2026-09-04, so a digit is no longer a mutation ONLY LEG 7
  # could see — but it is still a mutation only LEG 7 sees IN THESE SEVEN FILES, which is
  # what the case asserts, and the sibling clause below is what proves it per-artifact.
  assert_gen_fires_only "GATE 8 LEG 7 hand-edited DIGIT in example/hexagrams.csv (byte-exact leg, per-artifact)" \
'example/hexagrams\.csv differs BYTE-FOR-BYTE from a fresh roae\.py --csv' \
'\[ok\] +example/hexagrams\.json is BYTE-IDENTICAL to a fresh roae\.py --json' \
"p='example/hexagrams.csv'
a='3,\u4dc2,010001,17,'
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'anchor moved: %d occurrences' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'3,\u4dc2,010001,18,',1))"

  # CASE 9 — THE BINARY ARM. One byte flipped at the end of example/wave.mid. The evidence ERE
  # requires the `(binary; first difference: ...)` sentence, which only the `grep -qI .` branch
  # can print, so a run that took the text branch on a binary file cannot satisfy it. The
  # mutation is arithmetic on the last byte rather than a literal, because a literal byte value
  # would be an anchor into generated MIDI and would move the day roae.py's --midi output does.
  assert_gen_fires "GATE 8 LEG 7 one flipped byte in example/wave.mid (binary arm)" \
'example/wave\.mid differs BYTE-FOR-BYTE from a fresh roae\.py --midi' \
"p='example/wave.mid'
b=bytearray(open(p,'rb').read())
assert len(b)>0, 'anchor moved: wave.mid is empty'
b[-1]=(b[-1]+1)%256
open(p,'wb').write(bytes(b))"

  rm -rf "$GEN_CACHE"

  # ITEM A1 — THE MISSING-INPUT CLASS, for every gate that has one.
  #
  # GATE 8's leg above ("shipped artifact deleted outright") was the first of these. The same
  # question — what does this gate do when its input is not there? — was then asked of GATES
  # 2, 3, 3b, 6, 10a, 10b and 11, and all seven answered `[skip]` + rc 0. MEASURED before the
  # fix: with documentation/CORRECTIONS.md deleted, `doc_gates.sh retract` printed
  # "DOC GATES: PASS (retract)" and exited 0, its only trace a bash redirect error on stderr —
  # which this very harness discards (`>/dev/null 2>&1`).
  #
  # The mutation is `os.remove`, and the revert is the harness's own `git checkout -- .`,
  # which restores a deleted tracked file exactly as it restores a modified one. So this
  # whole class is cheap: no regeneration, no scratch clone, no history rewrite.
  #
  # TWO DISTINCT MESSAGES, deliberately. The corpus preflight fires on any missing tracked
  # .md, so the CORRECTIONS.md cases below trip it as well as the gate's own leg. The
  # evidence ERE names the GATE's wording ("<f> is tracked in git but missing"), never the
  # preflight's ("tracked markdown missing from the working tree: <f>"), so each assertion
  # still proves the leg it was written for and not the preflight standing behind it.
  assert_fires_why "GATE 2 (A1) source file deleted" cli \
    'sat\.py is tracked in git but missing' \
"import os
assert os.path.exists('sat.py'), 'anchor moved'
os.remove('sat.py')"

  assert_fires_why "GATE 2 (A1) CLI doc deleted" cli \
    'SAT_CLI\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/SAT_CLI.md'), 'anchor moved'
os.remove('documentation/SAT_CLI.md')"

  assert_fires_why "GATE 3 (A1) retraction registry deleted" retract \
    'RETRACTED_PHRASES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_PHRASES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_PHRASES.tsv')"

  assert_fires_why "GATE 3b (A1) figure registry deleted" retract-figures \
    'RETRACTED_FIGURES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_FIGURES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_FIGURES.tsv')"

  assert_fires_why "GATE 6 (A1) retraction registry deleted" figures \
    'RETRACTED_PHRASES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_PHRASES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_PHRASES.tsv')"

  # The worse of GATE 6's two: `gens` is `git ls-files`, an INDEX listing, so a deleted
  # generator stayed in the list, `tr < "$f"` failed to stderr, no phrase matched, and the
  # gate reported [ok] on a file it never opened. The `-n "$gens"` guard cannot see this —
  # the list was never empty. Anchored on viz/growth_curve.py, a real tracked generator.
  assert_fires_why "GATE 6 (A1) tracked generator deleted from the worktree" figures \
    'viz/growth_curve\.py is tracked in git but missing' \
"import os
assert os.path.exists('viz/growth_curve.py'), 'anchor moved'
os.remove('viz/growth_curve.py')"

  # Deleting the ledger is the LIMITING CASE of what 10a and 10b forbid: every committed
  # line lost at once. It was the one edit that made both halves report nothing.
  assert_fires_why "GATE 10a (A1) ledger deleted" appendonly-head \
    'CORRECTIONS\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/CORRECTIONS.md'), 'anchor moved'
os.remove('documentation/CORRECTIONS.md')"

  assert_fires_why "GATE 10b (A1) ledger deleted" appendonly-history \
    'CORRECTIONS\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/CORRECTIONS.md'), 'anchor moved'
os.remove('documentation/CORRECTIONS.md')"

  # GATE 11 named both files in ONE skip line, so it needs BOTH cases: an assertion on the
  # registry alone would pass against a gate that still skipped silently on a missing ledger.
  #
  # RE-POINTED FROM `ledger` TO `ledger-phrases` (item B2, round 9, 2026-08-02), and the
  # SECOND of these two was a LIVE instance of the class, not a tidy-up. Its ERE,
  # `CORRECTIONS.md is tracked in git but missing`, is emitted by `require_tracked "$f"` in
  # gate_ledger_phrases AND by the identical call in gate_ledger_figures — both halves guard
  # the same ledger. Under the combined `ledger` dispatch either one satisfied it, so the
  # assertion labelled "GATE 11 (A1) ledger deleted" could not say which half answered, and
  # deleting the phrases guard would have left it green. That is the fifth sighting of the
  # class GATE 4/4b, GATE 10a/10b and GATE 11-figures were each hand-fixed for. The first of
  # the two was never ambiguous (only the phrases half reads RETRACTED_PHRASES.tsv) and is
  # re-pointed for uniformity, so a future reader does not have to re-derive which is which.
  assert_fires_why "GATE 11 (A1) registry deleted" ledger-phrases \
    'RETRACTED_PHRASES\.tsv is tracked in git but missing' \
"import os
assert os.path.exists('documentation/RETRACTED_PHRASES.tsv'), 'anchor moved'
os.remove('documentation/RETRACTED_PHRASES.tsv')"

  assert_fires_why "GATE 11 (A1) ledger deleted" ledger-phrases \
    'CORRECTIONS\.md is tracked in git but missing' \
"import os
assert os.path.exists('documentation/CORRECTIONS.md'), 'anchor moved'
os.remove('documentation/CORRECTIONS.md')"

  # THE CORPUS PREFLIGHT — hole (b), and the one that made this item worth doing. `$DOCS` is
  # an index listing, so a tracked .md deleted from the working tree stays in it. WHICH gates
  # are blinded by that, and HOW each one fails, is maintained ONLY at
  # `preflight_tracked_docs`'s header and is deliberately not restated here. (This comment
  # carried the pre-round-16 list — "read as EMPTY by GATES 3, 3b, 4, 4b, 5, 5b and 9
  # simultaneously; each then reports [ok] on a document it never opened" — until round 17.
  # Round 16 corrected the printed message and left this copy and the file header behind it.)
  # Asserted through `retract`, a gate with NO input of its own missing, so the
  # only thing that can make it fail here is the preflight.
  assert_fires_why "PREFLIGHT (A1) a tracked .md deleted blinds every DOCS-iterating gate" \
    retract 'tracked markdown missing from the working tree: documentation/GUIDE\.md' \
"import os
assert os.path.exists('documentation/GUIDE.md'), 'anchor moved'
os.remove('documentation/GUIDE.md')"

  # GATE 14 FIRE-PROOFS (item A6, 2026-08-02) — FIVE legs plus one negative control, NAMED
  # below rather than tallied here, and the split is deliberate.
  #
  # The suite's own header records GATE 8 shipping a ONE-DIRECTIONAL comparison behind a
  # fire-proof that was taken by hand and never re-run. A duplicate-detector has exactly the
  # same shape of hole: an assertion that only removes the allowlist row proves the ALLOWLIST
  # is load-bearing and says nothing about whether the gate can find a duplicate it has never
  # been told about. So the legs are split by what each one can fail on its own:
  #   (1) the MOTIVATING EXAMPLE — drop the r3/p1c4 row and the real pair must be reported;
  #   (2) a NEW pair the allowlist has never seen — reg_c1's body replaced by reg_r4's, so
  #       two rules that were plainly different become identical. Leg 1 passes even if the
  #       allowlist is the only thing the gate consults; leg 2 does not;
  #   (3) the BLIND-SPOT detector — reg_r4 pinned to its KW constant, which is precisely the
  #       state MM-T5 was in before the witnesses were added. A gate that reported [ok] on an
  #       uncomparable rule would be a false clear of the exact kind that hid a Lean defect
  #       for twelve hours on 2026-08-01; this leg makes the refusal load-bearing;
  #   (4) the VACUITY leg — an EMPTIED registry must be a finding, not a clean run. Added by
  #       PHASE-4 on this batch (see its own comment below), because the first draft printed
  #       "[ok] 0 rules, 0 pairs compared" and exited 0;
  #   (5) the MISSING-INPUT leg (item A1's class) — allowlist deleted.
  # Plus a negative control: a comment appended to the allowlist must change nothing, or the
  # parser is failing closed on its own file format and legs 1-5 prove less than they look.
  #
  # THIS HEADER SAID "FOUR legs, and the count is deliberate" FROM ae2c705b UNTIL ROUND 16,
  # while enumerating only (1)-(4)-as-missing-input and standing over FIVE legs plus the
  # control. The vacuity leg was added by this batch's OWN Phase-4 and nothing moved the
  # count — the identical shape to ITEM B1's header above and to GATE 17's "FIVE LEGS"
  # against six.
  #
  # THE ROUND-15 FIX LANDED ON THE ENUMERATION AND NOT ON THE HEADER, AND THIS PARAGRAPH
  # ASSERTED OTHERWISE FOR A FULL ROUND. Round 15's item R16 (d9d5d30d) rewrote (1)-(5),
  # added the control sentence and wrote "UNTIL ROUND 15" here — twenty-two lines above the
  # header it was describing, which still read FOUR. A retrospective is a CLAIM about a
  # sibling line, and nothing checks that the sibling moved. Corrected round 16 drain-1 by
  # reading the block, having arrived at it from the census query rather than from this note.
  #
  # WHY THE SWEEP THAT WROTE THAT SENTENCE COULD NOT SEE THE LINE IT DESCRIBED: round 15's
  # census query was case-SENSITIVE, the header READ "FOUR legs" in uppercase, and the
  # query's alternation is lowercase. MEASURED on the pre-fix file: the case-sensitive form
  # returned 0 on that line while returning 12 rows across the whole 2400-7700 window; the
  # case-insensitive form returns it. The header sat inside the swept LINE RANGE the entire
  # time and outside the swept ALPHABET.
  #
  # PAST TENSE ON PURPOSE, and the first draft of this paragraph got it wrong. It said "this
  # header reads FOUR legs" — present tense — in the same commit that changed the header to
  # read FIVE, i.e. it shipped a stale claim about a sibling line inside the fix for a stale
  # claim about a sibling line. Caught by this batch's own Phase-4, not by a gate; no gate
  # here reads a comment's tense against the line it describes, and none is proposed.
  #
  # ITEM A2 CHECKED BEFORE THESE WERE WRITTEN, not after: neither preflight can emit any of
  # the EREs below. preflight_tracked_docs prints only "tracked markdown missing from
  # the working tree", preflight_support_newlines only "gate-support file has no final
  # newline" — and DOC_GATE_REGISTRY_DUPLICATES.txt matches preflight_support_newlines'
  # `documentation/DOC_GATE_*.txt` glob, so that check was necessary rather than pro forma.
  #
  # THE `reg_` ARGUMENT COVERS LEGS 1-3 ONLY, and saying otherwise was the second half of
  # this census's rot. It read "Every ERE here contains a `reg_` rule id, which no preflight
  # ever prints" — MEASURED FALSE for three of the six EREs: leg 4's is
  # 'fewer than two cannot form a pair', leg 5's is 'DOC_GATE_REGISTRY_DUPLICATES\.txt is
  # tracked in git but missing', and the control's is '1 adjudicated pair\(s\), 0 new'.
  # What actually holds legs 4 and 5 is not this comment but GATE 16 (`collisions`), which
  # extracts the ERE from every assert_fires_why invocation and fails if any of them matches
  # a preflight-emittable line. So the property is checked mechanically, not argued.
  # WHAT NEITHER COVERS: the negative control is an assert_stays_clean_why, and GATE 16's
  # extractor reads only `assert_fires_why` — measured. Its ERE is safe by inspection, not
  # by any check, and that gap is a property of all seven stays_clean assertions in this
  # file, not of this one.
  assert_fires_why "GATE 14 duplicate predicates — the r3/p1c4 pair the gate was built for" \
    regdupes 'reg_p1c4 and reg_r3 return the SAME value' \
"p='documentation/DOC_GATE_REGISTRY_DUPLICATES.txt'
s=open(p,encoding='utf-8').read()
assert s.count(chr(10)+'r3'+chr(9)+'p1c4'+chr(9))==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(
    ''.join(l for l in s.splitlines(True) if not l.startswith('r3'+chr(9))))"

  assert_fires_why "GATE 14 a NEW duplicate the allowlist has never seen (reg_c1 := reg_r4)" \
    regdupes 'reg_c1 and reg_r4 return the SAME value' \
"p='solve.py'
a='    return sum(abs(sum(_reg_hw(h) for h in seq[i:i + 4]) - 12)'+chr(10)+'               for i in range(0, 64, 4))'+chr(10)
b='    return sum(bit_diff(seq[2 * k], seq[2 * k + 1]) for k in range(32))'+chr(10)
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'reg_c1 body anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,b,1))"

  assert_fires_why "GATE 14 a rule that cannot be compared is a FAIL, not a silent pass" \
    regdupes 'reg_r4 takes ONE value across all' \
"p='solve.py'
a='    return sum(bit_diff(seq[2 * k], seq[2 * k + 1]) for k in range(32))'+chr(10)
s=open(p,encoding='utf-8').read()
assert s.count(a)==1, 'reg_r4 body anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'    return 120'+chr(10),1))"

  # PHASE-4 ON THIS BATCH, not a later thought: the first draft printed
  # "[ok] 0 rules, 0 pairs compared" and exited 0 if REGISTRY_KW_EXPECTED were emptied or
  # renamed. Both new gates in this batch had a way to be green having compared nothing,
  # which is the failure mode they were written to refuse, so both guards are asserted here
  # rather than reasoned about in a comment.
  assert_fires_why "GATE 14 an emptied registry is a finding, not a clean run" regdupes \
    'fewer than two cannot form a pair' \
"p='solve.py'
s=open(p,encoding='utf-8').read()
a='REGISTRY_KW_EXPECTED = ['
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
i=s.index(a); j=s.index(chr(10)+']'+chr(10), i)
open(p,'w',encoding='utf-8').write(s[:i]+'REGISTRY_KW_EXPECTED = [(\"r3\", True),'+s[j:])"

  assert_fires_why "GATE 14 (A1) duplicate allowlist deleted" \
    regdupes 'DOC_GATE_REGISTRY_DUPLICATES\.txt is tracked in git but missing' \
"import os
p='documentation/DOC_GATE_REGISTRY_DUPLICATES.txt'
assert os.path.exists(p), 'anchor moved'
os.remove(p)"

  # EVIDENCE (round 8 drain-3): the adjudicated-pair count is exactly the number the defect
  # this control is about would move — a comment line parsed as a pair makes it 2, or breaks
  # the parse outright. Pinning `1 adjudicated pair(s), 0 new` therefore covers the failure
  # the control names, without proving the appended line was read.
  assert_stays_clean_why "GATE 14 a comment appended to the allowlist changes nothing" regdupes \
    '1 adjudicated pair\(s\), 0 new' \
"open('documentation/DOC_GATE_REGISTRY_DUPLICATES.txt','a',encoding='utf-8').write(
    '# GATE 14 negative control: a comment line must not be parsed as a pair.'+chr(10))"

  # GATE 15 FIRE-PROOFS (item A1, 2026-08-02) — the instrument that catches an undeclared
  # instrument, which had better be able to catch one.
  #
  # THE MOTIVATING MUTATION MUTATES THIS FILE, so it mutates a COPY. `_selftest_revert`
  # restores tracked files with `git checkout -- .`, and doc_gates.sh is the script bash is
  # executing; task #77 is open on precisely that hazard. The gate's source seam is
  # read-only and announces itself, so the leg below tests the shipped code path on a
  # mutated input — which is what every other assertion here does, the input just happens to
  # be the program. The three legs that mutate only the TABLE need no copy and use none.
  _gsrc() { DOC_GATES_SRC_OVERRIDE="$1" bash "$0" "$2" 2>&1; }

  _G15_COPY=$(git rev-parse --git-dir)/doc_gates_g15_copy.sh
  # ANCHOR RE-POINTED 2026-08-02 (item A1, round 8): this used to inject above
  # `  assert_fires() {`, and that helper was deleted with the item.
  #
  # THE GUARD BELOW WAS `grep -qF`, AND IT WAS DEFEATED BY ITS OWN SOURCE TEXT (item A2,
  # round 8 drain-2, 2026-08-02). The comment here used to claim that a moved anchor "would
  # have taken the else branch — a LOUD failure, not a silent pass". MEASURED, and the claim
  # was false in the direction that matters. `sed` reads THIS FILE and writes the copy, so
  # the sed EXPRESSION on the line below — which contains the literal
  # `_fireproof_undeclared_instrument() { :; }` mid-line — is itself copied verbatim into
  # `$_G15_COPY`. An unanchored `grep -qF` for that literal therefore succeeds on a copy in
  # which NOTHING was injected: re-pointing the sed at a non-existent anchor produced a copy
  # byte-identical to the source (`diff -q` reported identical) and the guard still took the
  # THEN branch. The leg would then have run GATE 15 against an unmutated file and reported
  # its real, correct output as if it were the mutation's — a fire-proof passing with the
  # injection switched off, which is the exact class this file's LEG-6 header states as
  # "a fire-proof searching its own source file must match on a form its own text cannot
  # take". Third instance of that class in two days, and the first one that was LIVE.
  #
  # THE FIX IS THAT FORM. `^  ` + the literal + `$` matches the injected line, which `sed`
  # writes at column 0 with exactly two leading spaces, and matches NO line of this
  # fire-proof: the sed line starts `  if sed 's|...` and this grep line starts `     && `.
  # Proven in both directions before it was written: with the real anchor the copy has
  # exactly ONE matching line; with the anchor deliberately moved it has zero. The
  # generic check that no OTHER copy-guard can regress this way is the second half of
  # gate_selftest_instruments (GATE 15 LEG 2).
  if sed 's|^  assert_fires_why() {$|  _fireproof_undeclared_instrument() { :; }\n  assert_fires_why() {|' \
       "$_DG_SRC" > "$_G15_COPY" \
     && grep -qE '^  _fireproof_undeclared_instrument\(\) \{ :; \}$' "$_G15_COPY"; then
    G15OUT=$(_gsrc "$_G15_COPY" instruments); G15OUT_RC=$?
    if [ "$G15OUT_RC" -eq 1 ] && grep -qF '_fireproof_undeclared_instrument() is defined at' <<<"$G15OUT"; then
      echo "  [ok]   GATE 15 an undeclared instrument in the --selftest region — fires, and names it"
    else
      echo "  [FAIL] GATE 15 — a new function in the --selftest region declared in NO row was"
      echo "         not reported. That is the fbdbe26 defect this gate exists for."
      printf '%s\n' "$G15OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 15 — could not build the mutated copy (the \`  assert_fires_why() {\`"
    echo "         anchor moved), so the assertion did NOT run."
    PASS=1
  fi
  rm -f "$_G15_COPY"

  # GATE 15 LEG 2 FIRE-PROOFS (item A2, round 8 drain-2, 2026-08-02) — the check that no
  # copy-confirmation guard can be satisfied by the fire-proof's own source text. TWO legs,
  # one per clause, because a single leg would prove one direction and the shipped comment
  # would claim both — which is the GATE 8 defect this whole file exists to stop repeating.
  #
  # CLAUSE (1)'s MUTATION IS THE PRE-FIX LINE VERBATIM. It reconstructs the `grep -qF` guard
  # that was LIVE in this file until this commit, so the leg is proven against the real
  # defect rather than a stylised one.
  #
  # THE MUTATION STRINGS ARE SPLIT (`'grep '+'-qF '`), and that is item A2 applied to this
  # fire-proof itself: written whole, the line below would be a copy-guard in the --selftest
  # region and the gate would flag ITS OWN mutation string on the live tree. The split is not
  # trusted, it is PROVEN CONTINUOUSLY — `instruments` runs in `all` and would be RED right
  # now if any line here matched, so a green `all` is the standing proof that it held.
  _G15B_COPY=$(git rev-parse --git-dir)/doc_gates_g15b_copy.sh
  for _g15b in unanchored fixedstring; do
    if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
g='grep '+'-qE '
t=[i for i,l in enumerate(L) if l.strip().startswith('&& '+g) and '_G15_COPY' in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
if '$_g15b'=='unanchored':
    L[t[0]]=L[t[0]].replace(chr(39)+'^  _fireproof', chr(39)+'  _fireproof', 1)
    assert chr(39)+'^  _fireproof' not in L[t[0]], 'the anchor was not stripped'
else:
    L[t[0]]='     && '+'grep '+'-qF '+chr(39)+'_fireproof_undeclared_instrument() { :; }'+chr(39)+' \"\$_G15_COPY\"; then'+chr(10)
open('$_G15B_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
      G15BOUT=$(_gsrc "$_G15B_COPY" instruments); G15BOUT_RC=$?
      case "$_g15b" in
        unanchored)  _g15bwhy='this guard'"'"'s ERE is not anchored at line start' ;;
        fixedstring) _g15bwhy='with a FIXED string' ;;
      esac
      if [ "$G15BOUT_RC" -eq 1 ] && grep -qF "$_g15bwhy" <<<"$G15BOUT"; then
        echo "  [ok]   GATE 15 LEG 2 a copy-confirmation guard satisfiable by its own source ($_g15b) — fires, and says why"
      else
        echo "  [FAIL] GATE 15 LEG 2 — a $_g15b copy guard was NOT reported. That guard passes"
        echo "         with the injection switched off (item A2, five instances in two days)."
        printf '%s\n' "$G15BOUT" | sed 's/^/           > /' | head -5
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 15 LEG 2 ($_g15b) — could not build the mutated copy (the anchored"
      echo "         \`&& grep -qE ... \$_G15_COPY\` line moved), so the assertion did NOT run."
      PASS=1
    fi
  done
  rm -f "$_G15B_COPY"

  # THE LABEL CHECK IS THE HALF THAT MAKES THIS MORE THAN A CHECKLIST. Without it a row could
  # name any string at all and the table would degrade into a list of names — which is how
  # "documented" becomes indistinguishable from "proven".
  #
  # ROW RE-POINTED 2026-08-02 (item A1, round 8): this leg used to mutate the `assert_fires`
  # row, and that helper — and therefore its row — was deleted with the item. It now mutates
  # the `assert_stays_clean_why` row. The `s.count(a)==1` guard is what makes the re-point
  # safe: had it been left pointing at a row that no longer exists, the leg would have
  # reported "anchor moved" and PASS=1, never a quiet skip. RE-POINTED AGAIN the same day
  # (A1's residue, drain-3) when that helper gained its evidence argument and was renamed.
  # AND THE RENAME COULD NOT HAVE LANDED SILENTLY EITHER WAY, which was measured rather than
  # assumed: with the script renamed and the table row left at the old key, `doc_gates.sh
  # instruments` FAILS first, naming assert_stays_clean_why as declared in no row. So a
  # forgotten row key is caught by the gate before this leg's guard is even reached, and the
  # guard is the second line, not the only one.
  #
  # THE ANCHORED LABEL IS ALSO SPLIT, and that is the item-A2 form applied one level deeper
  # than the substitute label below. The old version carried its anchor label as ONE literal,
  # so the label the gate searches doc_gates.sh for occurred TWICE in doc_gates.sh — once in
  # the real assertion and once inside this mutation string. Delete the real assertion and
  # GATE 15 would still have found the label, in this fire-proof's own source. Splitting the
  # literal makes the two disjoint, and `src.count(lbl)==1` asserts the split actually held
  # rather than trusting that it did — the count is the fire-proof of the fire-proof.
  #
  # THE SUBSTITUTE LABEL IS ASSEMBLED FROM FRAGMENTS, and that is not stylistic. The first
  # version of this leg injected the literal 'GATE 9 banner drift that nobody ever wrote' —
  # and FAILED in the harness, because writing that literal into the mutation string put it
  # into doc_gates.sh, which is the very file the gate searches. The fire-proof satisfied the
  # condition it was testing for. That is the A2 shared-message class arriving through an
  # assertion's own source text, it was caught by running the suite rather than by reading
  # it, and it is the reason this comment exists instead of a tidier one-liner.
  assert_fires_why "GATE 15 a row naming an assertion nobody wrote" instruments \
    'that label does not occur' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
row='assert_stays_clean_why'+chr(9)
lbl='GATE 12 a repeated DRAFT label is'+' exempt (suffix-keyed, not file-keyed)'
a=row+lbl+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
src=open('$_DG_SRC',encoding='utf-8').read()
assert src.count(lbl)==1, \\
    'the anchored label occurs %d times in the source; splitting it failed' % src.count(lbl)
lab='ZZ'+chr(45)+'no-such-assertion-label'
assert lab not in src, \\
    'the substitute label leaked into the source; the leg would test nothing'
open(p,'w',encoding='utf-8').write(s.replace(a, row+lab+chr(9), 1))"

  assert_fires_why "GATE 15 a row for a function that no longer exists" instruments \
    'which is no longer defined in the --selftest' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
assert s.count(chr(10)+'_g13'+chr(9))==1, 'anchor moved'
open(p,'w',encoding='utf-8').write(s.replace(
    chr(10)+'_g13'+chr(9), chr(10)+'_g13_deleted_long_ago'+chr(9), 1))"

  assert_fires_why "GATE 15 (A1) instrument declaration table deleted" instruments \
    'DOC_GATE_SELFTEST_INSTRUMENTS\.txt is tracked in git but missing' \
"import os
p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
assert os.path.exists(p), 'anchor moved'
os.remove(p)"

  # EVIDENCE (round 8 drain-3): same shape as GATE 14's — the instrument count is what a
  # comment mis-parsed as a row would move. RE-TAKEN 10 -> 11 (round 9, item B2) when _g16b
  # was declared, and 11 -> 12 (round 10, item N4) when _g15d was: each number came from
  # running `instruments` under this exact mutation, not from adding one to the old ERE,
  # which is the difference this control exists to enforce. TWICE IN TWO ROUNDS IS THE
  # EVIDENCE THAT THE CONTROL IS LOAD-BEARING: a batch that declares an instrument SHOULD
  # trip it, and a batch that trips nothing has probably pinned nothing.
  assert_stays_clean_why "GATE 15 a comment appended to the table changes nothing" instruments \
    '12 instrument\(s\) in the --selftest region, all declared' \
"open('documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt','a',encoding='utf-8').write(
    '# GATE 15 negative control: a comment line declares nothing and breaks nothing.'+chr(10))"

  # GATE 15 LEG 3 FIRE-PROOFS (items B8 + B3, round 9 drain-2, 2026-08-02) — the claims
  # column. THE FIRST LEG IS THE MOTIVATING EXAMPLE ITSELF, NOT A SYNTHETIC ONE: it puts the
  # `scratch_appendonly` row back to the exact label it carried from 6d93ed5 to b4442cf —
  # "GATE 10b vs history (…)" — which is a REAL assertion in this file that never calls
  # scratch_appendonly. That row was green under LEG 1 for the whole of its life, because
  # LEG 1 asks only whether the label exists somewhere in doc_gates.sh, and it does — it is
  # the label of the live "GATE 10b vs history" assert_fires_why (named, not cited by line:
  # a same-file line citation rots on the next insertion above it, item B1).
  # So this leg proves the new check catches the defect the old check shipped.
  #
  # THE HISTORICAL LABEL IS ASSEMBLED FROM TWO FRAGMENTS, and the leg asserts the assembled
  # form occurs exactly ONCE in the source before mutating. That is the item-A2 discipline:
  # written as one literal, this mutation string would itself become a second occurrence, and
  # a future reader could not tell whether LEG 1 was satisfied by the real assertion or by
  # this fire-proof's own source text (caveat 1a of the table).
  assert_fires_why "GATE 15 LEG 3 the historical scratch_appendonly misdeclaration" instruments \
    'declares kind=INVOCATION for scratch_appendonly\(\), but no line of' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
row='scratch_appendonly'+chr(9)
cur='GATE 10b vs a COMMITTED removal (working copy == HEAD)'
a=row+cur+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
old='GATE 10b vs history (a line of the '+'OLDEST committed version deleted)'
src=open('$_DG_SRC',encoding='utf-8').read()
assert src.count(old)==1, \\
    'the historical label occurs %d times in the source; splitting it failed' % src.count(old)
open(p,'w',encoding='utf-8').write(s.replace(a, row+old+chr(9), 1))"

  # A ROW MAY NOT DOWNGRADE ITS OWN KIND. Without this direction the claims column is an
  # opt-out: any row failing the INVOCATION check could relabel itself BLOCK and go green,
  # which is the ratchet every report-only gate in this file has had to argue about.
  #
  # THE ANCHOR CARRIES THE ROW KEY, and it did not on this leg's first run. Anchored on the
  # claims field alone (`kind=INVOCATION callers=2`) it matched TWO rows — scratch_appendonly
  # and assert_gen_fires_only both have two callers — and the `count(a)==1` guard refused to
  # inject and reported PASS=1. That is the guard working: a fire-proof that had silently
  # mutated whichever row came first would have been asserting about a row nobody chose.
  assert_fires_why "GATE 15 LEG 3 a row downgrading INVOCATION to BLOCK" instruments \
    'declares kind=BLOCK for scratch_appendonly\(\), but the INVOCATION form holds' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a=('scratch_appendonly'+chr(9)+'GATE 10b vs a COMMITTED removal (working copy == HEAD)'
   +chr(9)+'kind='+'INVOCATION callers=2'+chr(9))
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a, a.replace(
    'kind=INVOCATION callers=2', 'kind=BLOCK callers=2'), 1))"

  # A BLOCK ROW MAY NOT BE PROVEN BY A STRING THE HARNESS NEVER PRINTS (item N3, round 10
  # drain-3, 2026-08-02). THIS MUTATION IS THE LIVE DEFECT, NOT A SYNTHETIC ONE. The
  # `_selftest_revert` row's label is "A1 snapshot"; below the one call that is the assertion
  # sits `… | grep -q 'A1 snapshot probe'`, the marker text the assertion searches FOR. That
  # line is not an echo, and until today it was what satisfied the row: as measured on
  # 2026-08-02 the `+3` the gate printed was the distance to that grep, and the `[ok]` line
  # was at `+4`. The live distance is on the gate's own [ok] line every run; those two are a
  # dated observation, not a standing claim about where the lines are.
  #
  # THE LEG SETS THE LABEL TO THE FULL MARKER, and what makes that fire is that the marker is
  # ECHOED NOWHERE — not that it is rare. MEASURED against the pre-fix code before the fix was
  # written: LEG 3 stayed GREEN and printed the identical `_selftest_revert +3`. So this leg
  # fires on the fix and only on the fix.
  #
  # THE GUARDS ASSERT THE PROPERTY, NOT A COUNT, AND THAT IS THIS BATCH'S OWN LESSON. The
  # first draft of this comment said the marker "occurs in this file ONLY as the injected
  # probe text and as that grep pattern" — and the commit that wrote the sentence added three
  # more occurrences, in comments, one of them the sentence itself. A count-based guard would
  # have shipped RED or, worse, been "fixed" by bumping the number. `echoed == []` cannot rot
  # that way: prose about the marker is not an echo of it, so this paragraph may grow freely.
  #
  # THE LITERAL IS STILL SPLIT, for the reason at the scratch_appendonly leg above: written
  # whole, the mutation string would be an occurrence a reader could confuse with the probe's.
  # Splitting it keeps the MUTATION out of the source; it does not, and cannot, keep the
  # surrounding prose out.
  assert_fires_why "GATE 15 LEG 3 a BLOCK row proven by a string the harness never prints" \
    instruments \
    'declares kind=BLOCK for _selftest_revert\(\), but no \[ok\]/\[FAIL\] REPORT line' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a='_selftest_revert'+chr(9)+'A1 snapshot'+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
marker='A1 snapshot'+' probe'
src=open('$_DG_SRC',encoding='utf-8').read().splitlines()
echoed=[i+1 for i,l in enumerate(src) if marker in l and l.lstrip().startswith('echo \"')]
assert not echoed, 'the marker IS echoed at %r, so this leg would fire vacuously' % echoed
assert any(marker in l for l in src), 'the marker is gone from the source entirely'
open(p,'w',encoding='utf-8').write(s.replace(a, '_selftest_revert'+chr(9)+marker+chr(9), 1))"

  # THE OTHER ARM OF THE SAME FAIL (item R6, round 11 drain-1, 2026-08-02). The kind=BLOCK
  # FAIL above branches on WHY it fired: an occurrence that is not a report line, or no
  # occurrence at all. The leg shipped in f5fac73 exercises the first arm only. The second is
  # PRE-EXISTING text — exposure is unchanged rather than new — but by this file's own rule an
  # unexercised arm is an untested arm. What it prints for is a row whose label is still in the
  # file but no longer anywhere below a call site, which is the drift a rename leaves behind.
  #
  # IT ASSERTS ON THE `WHY` LINE, NOT ON THE FAIL HEADER, because the header is identical for
  # both arms: an ERE taken from it would be satisfied by the arm already proven, and this leg
  # would then be proof of nothing. That is the same SHAPE GATE 16 LEG 3 refuses one commit
  # above — and LEG 3 does NOT cover this population (its caveat (h): it reads the
  # parameterised drivers, not assert_fires_why's evidence-EREs), so the disambiguation here
  # had to be done by hand and by running. The mechanism has not reached this class yet.
  #
  # THE OBVIOUS MUTATION DOES NOT ISOLATE THIS ARM, WHICH WAS MEASURED, NOT REASONED. R6 says
  # to "point the label at a string that occurs nowhere". Run: that ALSO trips GATE 15's
  # label-EXISTENCE leg, which fires first with `The declared proof does not exist`, so the
  # run proves both arms at once and neither on its own — a fire-proof that cannot say which
  # check caught the defect is the ambiguity GATE 16 LEG 3 refuses one commit above.
  #
  # SO THE LABEL MUST EXIST AND BE OUT OF WINDOW. It is pointed at a marker that occurs in this
  # script but far from every `_g13` mention, which leaves the existence leg green and reaches
  # the `no occurrence in window` arm alone. The mutation ASSERTS BOTH HALVES of that premise
  # before writing — the marker is present, and no occurrence of it is within 40 lines of any
  # `_g13` line, a deliberately looser bound than BLOCK_WINDOW so a small drift aborts the
  # mutation with a named reason instead of silently proving the other arm.
  assert_fires_why "GATE 15 LEG 3 a BLOCK row whose label exists but never below a call site" \
    instruments \
    'WHY: the label does not occur in' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a='_g13'+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
i=s.index(a)+len(a)
j=s.index(chr(9), i)
mark='preflight_support'+'_newlines'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines()
hits=[k for k,l in enumerate(L) if mark in l]
near=[k for k,l in enumerate(L) if '_g13' in l]
assert hits and near, 'marker or _g13 gone from the script: %d/%d' % (len(hits),len(near))
assert min(abs(h-n) for h in hits for n in near) > 40, \\
    'the marker moved next to a _g13 line, so the in-window arm would answer instead'
open(p,'w',encoding='utf-8').write(s[:i]+mark+s[j:])"

  # THE CALLERS COUNT IS CHECKED, WHICH IS THE HALF OF CAVEAT (4) A MACHINE CAN HOLD TRUE.
  # The row that motivated caveat (4) said "four callers" against six and no gate noticed for
  # a round; this leg is that failure made loud.
  assert_fires_why "GATE 15 LEG 3 a callers count that drifted" instruments \
    'has callers=9; the rule in this table.s header counts 1' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a=chr(9)+'kind='+'INVOCATION callers=1'+chr(9)
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a, chr(9)+'kind=INVOCATION callers=9'+chr(9), 1))"

  # EVIDENCE (B9's lesson applied at birth): the pinned census MOVES if any row's kind
  # changes or a row is dropped, so it proves the claims leg ran and produced its
  # classification — not merely that the mode exited 0. What it deliberately does NOT prove
  # is that the mutated NOTE was read, because it was not read: that is caveat (4), and this
  # control is the standing demonstration of it rather than a sentence asserting it.
  # RE-TAKEN 6 -> 7 kind=INVOCATION (round 9, item B2) when _g16b's row landed, and 7 -> 8
  # (round 10, item N4) when _g15d's did; each taken from a run under this mutation, and it
  # is the census MOVING that made the re-take necessary, which is the property being
  # asserted.
  # 🔴 Q-702 (2026-09-24, Fable K): the anchor was the note's first CLAUSE (`GATE 8's negative
  # control: proves`); the row's note was reworded to `...: the only case in this harness that`
  # and this leg read "could not inject" ever since (0 matches at 5c296837). The anchor is now
  # the tab plus the note's opening label up to the colon, and the rewrite replaces only that
  # label — the clause after the colon is free to change without moving this fixture.
  assert_stays_clean_why "GATE 15 LEG 3 a rewritten note changes no claim" instruments \
    'claims column: 8 kind=INVOCATION' \
"p='documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt'
s=open(p,encoding='utf-8').read()
a=chr(9)+\"GATE 8's negative control:\"
assert s.count(a)==1, 'anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(
    a, chr(9)+'This sentence is false and no machine reads it:', 1))"

  # GATE 15 LEG 4 FIRE-PROOFS (item N4, round 10 drain-2, 2026-08-02) — THREE LEGS, ALL RUN.
  #
  # LEG 4 is a COVERAGE rule, and the instruction it was left under says why it needs three
  # rather than one: shipping a coverage rule in the same pass that grew the population it
  # counts is how a gate ends up proven against its own arithmetic instead of against a
  # defect. So none of these asserts on a COUNT. Each removes one confirmation and requires
  # the leg to name the builder that lost it:
  #   (a) the SHELL form  — the anchored guard after a `> "$_X_COPY"` redirect is stripped;
  #   (b) the PYTHON form — the `assert` before an `open(…,'w')` is stripped;
  #   (c) the CROSS-CHECK — the guard is left in place but rewritten to a shape LEG 2's
  #       extractor cannot read (an UNQUOTED pattern). LEG 2 then silently checks one guard
  #       instead of two and still prints [ok] with a smaller number, which is precisely the
  #       count-nobody-reads failure caveat (vi) has recorded since round 8. Without (c) this
  #       vacuity guard would be the untested half of the pair, and the untested half is what
  #       rots — GATE 8 shipped a one-directional comparison for exactly that reason.
  #
  # EACH LEG ASSERTS ON A SUBSTRING ONLY LEG 4 PRINTS, and the three are mutually distinct:
  # (a) names the shell wording, (b) the python wording, (c) the cross-check wording. If any
  # of those three FAIL messages is reworded, ITS PROOF MUST BE RE-TAKEN FROM A RUN — the
  # standing hazard item N2 names for GATE 4b LEG 7, and it applies here identically because
  # the same thing makes the proof meaningful: the string is what a build without the rule
  # cannot print.
  #
  # THE MUTATIONS CARRY NO SHELL METACHARACTERS. Every `$` and `"` they must write is built
  # with chr(36)/chr(34), and every anchor is assembled from fragments, so (i) this
  # fire-proof's own source cannot satisfy the anchor it searches for (item A2) and (ii)
  # nothing here is expanded by the shell before python sees it.
  _G15D_COPY=$(git rev-parse --git-dir)/doc_gates_g15d_copy.sh

  _g15d() {  # <label> <expected-substring> <python-mutation>
    if _G15D_COPY="$_G15D_COPY" python3 -c "$3" 2>/dev/null; then
      _G15DOUT=$(_gsrc "$_G15D_COPY" instruments); _G15DOUT_RC=$?
      if [ "$_G15DOUT_RC" -eq 1 ] && grep -qF "$2" <<<"$_G15DOUT"; then
        echo "  [ok]   GATE 15 LEG 4 $1 — fires"
      else
        echo "  [FAIL] GATE 15 LEG 4 $1 — NOT reported, so an unconfirmed copy would ship"
        printf '%s\n' "$_G15DOUT" | sed 's/^/           > /' | head -6
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 15 LEG 4 $1 — could not build the mutated copy (anchor moved), so"
      echo "         the assertion did NOT run. A skipped assertion is not a pass."
      PASS=1
    fi
  }

  _g15d "a shell-redirect copy whose anchored guard was stripped" \
        'and no anchored guard within' "
import os
G='&& '+'grep '+'-qE '+chr(39)+'^  _fireproof_undeclared_instrument'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip().startswith(G)]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]='     && '+'true; then'+chr(10)
assert 'grep' not in L[t[0]], 'the guard survived the substitution'
open(os.environ['_G15D_COPY'],'w',encoding='utf-8').writelines(L)"

  _g15d "a python builder whose assert was stripped" \
        'with no assert earlier in the same' "
import os
W='.write'+'lines(out)'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if W in l]
assert len(t)==1, 'builder anchor moved: %d' % len(t)
a=[i for i in range(t[0]-1,0,-1) if L[i].startswith('assert'+' ')]
assert a and t[0]-a[0] < 12, 'no assert in the builder-s own program: %s' % a[:1]
L[a[0]]='pass'+chr(10)
open(os.environ['_G15D_COPY'],'w',encoding='utf-8').writelines(L)"

  _g15d "a guard LEG 2's extractor can no longer read" \
        'and LEG 2 did not extract' "
import os
G='&& '+'grep '+'-qE '+chr(39)+'^  _fireproof_undeclared_instrument'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip().startswith(G)]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=('     && '+'grep '+'-qE X '+chr(34)+chr(36)+'_G15_COPY'+chr(34)+'; then'+chr(10))
assert chr(39) not in L[t[0]], 'the pattern is still quoted, so LEG 2 would still read it'
open(os.environ['_G15D_COPY'],'w',encoding='utf-8').writelines(L)"

  rm -f "$_G15D_COPY"

  # GATE 16 FIRE-PROOFS (item A2, 2026-08-02) — REPRODUCE THE A6 NEAR-MISS, do not describe it.
  #
  # The motivating leg rewrites GATE 3's evidence-ERE to the corpus preflight's wording. That
  # is precisely what item A6 nearly shipped: an assertion about one gate that the preflight —
  # which runs before EVERY mode — would satisfy on its own, leaving the named gate free to
  # stop working unnoticed. Both legs mutate a COPY through the shared read-only source seam,
  # because the file to mutate is the one bash is executing (task #77, same reasoning as
  # GATE 15's).
  #
  # THE SECOND LEG IS THE VACUITY GUARD MADE LOAD-BEARING. A parser that silently skipped an
  # assert_fires_why invocation would leave that assertion unchecked forever and still print
  # [ok] with a smaller count than the file has calls — nobody reads counts. Deleting an
  # ERE argument must therefore be a FAIL, not a quieter [ok].
  #
  # BOTH COPIES ARE BUILT LINE-ANCHORED, IN PYTHON, AND THAT IS A CORRECTION. The first
  # version used `sed` plus a `grep -F` build check, and the vacuity leg FAILED in the
  # harness: its check asked whether the string `'spans a hard wrap'` had disappeared from
  # the copy, and that string still occurred — inside this fire-proof's own sed expression
  # and inside its own failure message. The build check could never succeed. Same shape as
  # GATE 15's first fire-proof (an assertion satisfied by its own source text), reached from
  # the opposite direction: there the injected string was found where it should not have
  # been, here it was found where its absence was the test. Both legs now match a WHOLE
  # STRIPPED LINE and assert the exact number of anchors found, so no other occurrence of
  # the text — comment, message, or the mutation itself — can participate.
  _G16_COPY=$(git rev-parse --git-dir)/doc_gates_g16_copy.sh

  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L)
   if l.strip()==chr(39)+'matched as the fixed string: \"hard floor k>=13\"'+chr(39)+' '+chr(92)]
assert len(t)==2, 'anchor moved: %d (GATE 3 and GATE 6 share this ERE)' % len(t)
L[t[0]]='    '+chr(39)+'tracked markdown missing from the working tree'+chr(39)+' '+chr(92)+chr(10)
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'is satisfied by a PREFLIGHT line' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 an assertion reworded onto the preflight's wording — fires (the A6 near-miss)"
    else
      echo "  [FAIL] GATE 16 — a per-gate assertion whose ERE the corpus preflight emits was"
      echo "         NOT reported. That assertion would pass with its gate switched off."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 — could not build the mutated copy (GATE 3's ERE line anchor"
    echo "         moved), so the assertion did NOT run."
    PASS=1
  fi

  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L)
   if l.strip()=='retract-figures '+chr(39)+'spans a hard wrap'+chr(39)+' '+chr(92)]
assert len(t)==1, 'anchor moved: %d' % len(t)
del L[t[0]]
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'no evidence-ERE could be extracted' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 an assert_fires_why whose ERE cannot be extracted — fires, not skipped"
    else
      echo "  [FAIL] GATE 16 — an invocation with no extractable ERE was passed over in"
      echo "         silence. The scan would under-report and still say [ok]."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 vacuity guard — could not build the mutated copy (the"
    echo "         'spans a hard wrap' anchor moved), so the assertion did NOT run."
    PASS=1
  fi

  # GUARD (7) FIRE-PROOFS (round 16 drain-1) — BOTH DIRECTIONS OF THE POPULATION DEFECT.
  #
  # Guard (7) widened LEG 1's population from `startswith("  assert_fires_why ")` to LEG 2's
  # call-position rule over BOTH helpers. Two things were outside the old rule, so there are
  # two legs, and each mutates the copy at a site the OLD scan could not have reached.
  #
  # LEG A — a NEGATIVE CONTROL reworded onto the corpus preflight's wording. This is the A6
  # near-miss on the half of the population that was never scanned. Under the old rule the
  # gate printed [ok] on this mutation, because assert_stays_clean_why was not in `calls` at
  # all; the ERE it would have collided with was never compared against anything.
  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
A='retract-figures '+chr(34)+chr(36)+'((_G3B_N + 1))'+chr(34)+chr(39)+' meta-mention'+chr(39)+' '+chr(92)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]='    retract-figures '+chr(39)+'tracked markdown missing from the working tree'+chr(39)+' '+chr(92)+chr(10)
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'an anchored narration is exempt" is satisfied by a PREFLIGHT line' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 guard (7) a NEGATIVE CONTROL reworded onto a preflight line — fires"
    else
      echo "  [FAIL] GATE 16 guard (7) — a negative control whose evidence-ERE the corpus"
      echo "         preflight emits was NOT reported, so the half of the population where the"
      echo "         ERE is the ONLY proof the exemption ran is still unscanned."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (7) leg A — could not build the mutated copy (the GATE 3b"
    echo "         negative control's '\"\$((_G3B_N + 1))\"'\'' meta-mention' anchor moved — Q-702"
    echo "         re-keyed it from the pinned '46 meta-mention'), so it did NOT run."
    PASS=1
  fi

  # LEG B — an invocation the scan can no longer REACH. `eval` in front of a call is guard
  # (4)'s stated blind spot borrowed as a mutation: it is a real shape, and it removes the
  # call from the population without touching its ERE, its label or its dispatch name. The
  # old vacuity check could not have caught this — `len(found) != len(calls)` compared a list
  # against the list it was built from and was False on every possible input. What catches it
  # is callers=N, derived by a different rule over the whole file.
  #
  # LEG 2 ALSO FIRES ON THIS COPY, and that is stated rather than hidden: both legs now read
  # the same population, so both notice it shrink. The substring asserted below is printed
  # ONLY by guard (7) — LEG 2's wording is "this leg resolved N invocation(s);" with no helper
  # name after the count — so a green LEG 2 could not satisfy this assertion on its own.
  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
A='assert_fires_why \"GATE 3b retracted figure split across a hard wrap\" '+chr(92)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace('assert_fires_why','eval assert_fires_why',1)
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'invocation(s) of assert_fires_why; documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt declares callers=' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 guard (7) an invocation the scan cannot reach — FAIL, not a smaller count"
    else
      echo "  [FAIL] GATE 16 guard (7) — the collision scan lost an invocation and still"
      echo "         reported a count instead of a failure. An assertion nobody compared is"
      echo "         not an assertion that passed."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (7) leg B — could not build the mutated copy (the 'GATE 3b"
    echo "         retracted figure split across a hard wrap' anchor moved), so it did NOT run."
    PASS=1
  fi

  # PHASE-4, the GATE 16 half: the "no templates at all" guard could not see ONE preflight
  # going quiet. A rewrite from `echo` to `printf` in either function would silently drop its
  # lines from the comparison, leave the other's, and print a plausible count nobody reads.
  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
out=[]; n=0; inb=False
for l in L:
    if l.startswith('preflight_support_newlines() {'): inb=True
    elif inb and l=='}'+chr(10): inb=False
    if inb and l.lstrip().startswith('echo '+chr(34)):
        l=l.replace('echo '+chr(34), 'printf '+chr(34)+'%s'+chr(92)+chr(92)+'n'+chr(34)+' '+chr(34), 1); n+=1
    out.append(l)
assert n>0, 'no echo lines found in preflight_support_newlines'
open('$_G16_COPY','w',encoding='utf-8').writelines(out)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'preflight_support_newlines() contributed ZERO message templates' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 one preflight going quiet is a FAIL, not a smaller count"
    else
      echo "  [FAIL] GATE 16 — a preflight whose messages the extractor can no longer read was"
      echo "         not reported; its output would silently stop being compared."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 per-preflight guard — could not build the mutated copy, so the"
    echo "         assertion did NOT run."
    PASS=1
  fi
  # GUARD (4) FIRE-PROOFS (round 15 drain-2) — TWO LEGS, BOTH RUN, one per direction.
  #
  # THE MOTIVATING EXAMPLE IS REAL AND IT IS NAMED. Round 14 shipped a third function that
  # runs before every mode (doc_gates_concurrency_advisory) and nothing here noticed; guard
  # (4) derives the emitter population from the dispatch region instead of declaring it.
  # Leg A is that exact shape: a fourth emitter appears and must be REFUSED, not absorbed.
  # Leg B is the other direction, and it is not decoration — a census that only complains
  # about new names would go quiet the moment the region scan stopped finding the OLD ones,
  # which is precisely how an inert scan prints [ok]. Indenting a call is the cheapest way to
  # make the region scan miss it while the file still parses.
  #
  # BOTH ANCHORS ARE WHOLE STRIPPED LINES with an exact-count assert, for the reason recorded
  # at the head of this region: `preflight_tracked_docs || RC=1` also occurs inside a comment
  # and inside these two mutations' own source text, and a substring anchor would find those.
  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.rstrip()=='preflight_support_newlines || RC=1']
assert len(t)==1, 'anchor moved: %d' % len(t)
L.insert(t[0]+1,'preflight_fireproof_fourth_emitter || RC=1'+chr(10))
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'preflight_fireproof_fourth_emitter() before EVERY mode' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 a fourth pre-dispatch emitter — refused, not absorbed"
    else
      echo "  [FAIL] GATE 16 guard (4) — a function added before the dispatch was neither"
      echo "         scanned nor reported. Its messages could satisfy any assertion silently."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (4) leg A — could not build the mutated copy (the"
    echo "         'preflight_support_newlines || RC=1' anchor moved), so it did NOT run."
    PASS=1
  fi

  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.rstrip()=='preflight_tracked_docs || RC=1']
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]='  '+L[t[0]]
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'preflight_tracked_docs() is declared to this gate but is not called' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 a scanned emitter the region scan can no longer see — FAIL, not [ok]"
    else
      echo "  [FAIL] GATE 16 guard (4) — a declared emitter that the dispatch no longer calls"
      echo "         was not reported, so the census can describe a run that never happens."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (4) leg B — could not build the mutated copy (the"
    echo "         'preflight_tracked_docs || RC=1' anchor moved), so it did NOT run."
    PASS=1
  fi

  # GUARD (5) FIRE-PROOFS (round 15 drain-3) — THREE LEGS, ALL RUN, one per direction.
  #
  # THE MOTIVATING EXAMPLE IS LIVE AND NAMED, and it is the reason leg B is the sharp one.
  # preflight_support_newlines calls require_final_newline, whose non-quiet branch prints
  # a line that — expanded over documentation/RETRACTED_FIGURES.tsv — IS the evidence-ERE of
  # the checked assertion "GATE 11 (figures) registry with no final newline drops its last
  # row". The literal `quiet` at that one call site is the whole of what keeps it out of this
  # gate's candidate set, and guard (4) does not read call sites inside a function at all.
  #   leg A — a pre-dispatch function grows a callee nobody declared: REFUSED, not absorbed.
  #   leg B — the suppression the declaration rests on is deleted: REFUSED. This is the live
  #           defect the guard exists for; the other two protect it from going inert.
  #   leg C — the declared callee is no longer called: REFUSED. A census that only complains
  #           about NEW names goes quiet the moment its scan stops finding the old ones.
  #
  # THE ANCHORS CARRY NO `$` AND NO `"`, deliberately: these mutations run inside a
  # double-quoted `python3 -c`, where either character would be interpreted by the shell
  # before python ever saw it. The call-site anchor is a stripped-prefix match PLUS the
  # literal, because `require_final_newline ` alone matches FOUR lines (three are GATE 11's
  # own call sites) — measured, not assumed.
  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.rstrip()=='preflight_tracked_docs() {']
assert len(t)==1, 'anchor moved: %d' % len(t)
L.insert(t[0]+1,'    require_tracked notes.md || missing=1'+chr(10))
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'preflight_tracked_docs() calls require_tracked() one level down' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 guard (5) an undeclared callee one level down — refused"
    else
      echo "  [FAIL] GATE 16 guard (5) leg A — a function called from INSIDE a pre-dispatch"
      echo "         emitter was neither scanned nor declared, and nothing said so."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (5) leg A — could not build the mutated copy (the"
    echo "         'preflight_tracked_docs() {' anchor moved), so it did NOT run."
    PASS=1
  fi

  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip().startswith('require_final_newline ') and 'quiet' in l]
assert len(t)==1, 'call-site anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(' quiet ',' ',1)
assert 'quiet' not in L[t[0]], 'the suppressing argument survived the substitution'
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'and the ONLY thing keeping that callee out of this' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 guard (5) the suppression its exemption rests on, deleted — refused"
    else
      echo "  [FAIL] GATE 16 guard (5) leg B — the argument that keeps a nested callee's"
      echo "         messages out of this scan was removed and the gate still passed. That"
      echo "         is the live A6 shape, one level down: GATE 11's own fire-proof becomes"
      echo "         satisfiable by a preflight line with nothing reporting it."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (5) leg B — could not build the mutated copy (the"
    echo "         require_final_newline call-site anchor moved), so it did NOT run."
    PASS=1
  fi

  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip().startswith('require_final_newline ') and 'quiet' in l]
assert len(t)==1, 'call-site anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace('require_final_newline','true',1)
assert 'require_final_newline' not in L[t[0]], 'the call survived the substitution'
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'require_final_newline() is declared to guard (5) but is not called' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 guard (5) a declared callee the scan can no longer see — FAIL, not [ok]"
    else
      echo "  [FAIL] GATE 16 guard (5) leg C — a declared nested callee that is no longer"
      echo "         called was not reported, so the declaration can describe a run that"
      echo "         never happens and the scan can go inert while printing [ok]."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (5) leg C — could not build the mutated copy (the"
    echo "         require_final_newline call-site anchor moved), so it did NOT run."
    PASS=1
  fi

  # GUARD (6) FIRE-PROOF (round 15 drain-3) — ONE LEG, and it drives the only direction the
  # guard has. body() stops at the first column-0 "}", which is exact for a shell function and
  # wrong inside a heredoc. This mutation gives preflight_support_newlines a heredoc whose
  # quoted text is a bare "}", so body() truncates immediately and every message and nested
  # call after the cut disappears. The other guards would report a preflight at ZERO templates;
  # only guard (6) says WHY, and only guard (6) fires when the truncation is partial.
  if python3 -c "
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.rstrip()=='preflight_support_newlines() {']
assert len(t)==1, 'anchor moved: %d' % len(t)
L.insert(t[0]+1,'  cat <<'+chr(39)+'XEOF'+chr(39)+' >/dev/null'+chr(10))
L.insert(t[0]+2,'}'+chr(10))
L.insert(t[0]+3,'XEOF'+chr(10))
open('$_G16_COPY','w',encoding='utf-8').writelines(L)" 2>/dev/null; then
    G16OUT=$(_gsrc "$_G16_COPY" collisions); G16OUT_RC=$?
    if [ "$G16OUT_RC" -eq 1 ] && grep -qF 'body() cannot be trusted on preflight_support_newlines()' <<<"$G16OUT"; then
      echo "  [ok]   GATE 16 guard (6) a heredoc brace truncating the shared reader — refused"
    else
      echo "  [FAIL] GATE 16 guard (6) — a column-0 '}' inside a heredoc silently truncated"
      echo "         body(), the reader guards (2) and (5) both depend on, and nothing said"
      echo "         so. Past the cut, a nested call simply is not there to be censused."
      printf '%s\n' "$G16OUT" | sed 's/^/           > /' | head -5
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 16 guard (6) — could not build the mutated copy (the"
    echo "         'preflight_support_newlines() {' anchor moved), so it did NOT run."
    PASS=1
  fi
  rm -f "$_G16_COPY"

  # GATE 16 LEG 2 FIRE-PROOFS (item B2, round 9, 2026-08-02) — FOUR LEGS, ALL RUN.
  #
  # THE FIRST TWO ARE THE REAL HISTORICAL TEXT, not a synthesis. B2 expected to need a
  # synthesised motivating example because the two live instances round 8 found were fixed by
  # hand the same day; drain-2 then found a fifth, and this batch a sixth, so the leg is
  # proven against the exact lines that shipped:
  #   (1) `ledger` on "GATE 11 (A1) ledger deleted" — live from 3ab5161 to 8f2aed2. Both
  #       halves of GATE 11 require_tracked the same file, so the ERE was emitted by the
  #       FIGURES half and the leg stayed green with the PHRASES guard deleted.
  #   (2) `links` on "GATE 4 internal links" — live until this batch. That one was LATENT, not
  #       broken: its ERE really is emitted only by GATE 4. It is here because a fire-proof
  #       held to its gate by a wording argument is held by nothing a machine reads.
  # The other two are the vacuity guards, and they are the reason this leg's [ok] means
  # anything: (3) an invocation the extractor cannot see must be a FAIL rather than a smaller
  # total, and (4) a call-graph reader that has gone blind must be a FAIL rather than a
  # corpus in which nothing fans out.
  #
  # ALL FOUR MUTATE A COPY through the read-only source seam (task #77 — the file to mutate
  # is the one bash is executing), and each asserts the EXACT number of whole-stripped-line
  # anchors it found before writing. The anchors below occur in this comment's own vicinity
  # as python string literals; whole-line matching is what keeps a fire-proof from being
  # satisfied by its own source text, which this file has now recorded three times.
  _G16B_COPY=$(git rev-parse --git-dir)/doc_gates_g16b_copy.sh
  _g16b() {  # <label> <expected-substring> <python-mutation>
    if _G16B_COPY="$_G16B_COPY" python3 -c "$3" 2>/dev/null; then
      # Q-954 (d) (Codex Q835 P-07, A06#13): the rc was never read, so a run that printed the
      # finding and then exited 0 (or died) still passed. The fire is rc 1 AND the finding.
      _G16BOUT=$(_gsrc "$_G16B_COPY" collisions); _G16BRC=$?
      if [ "$_G16BRC" -eq 1 ] && grep -qF "$2" <<<"$_G16BOUT"; then
        echo "  [ok]   GATE 16 $1 — fires"
      else
        echo "  [FAIL] GATE 16 $1 — NOT reported with rc 1 (rc=$_G16BRC), so the leg would stay green on it"
        printf '%s\n' "$_G16BOUT" | sed 's/^/           > /' | head -6
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 16 $1 — could not build the mutated copy (anchor moved), so"
      echo "         the assertion did NOT run. A skipped assertion is not a pass."
      PASS=1
    fi
  }
  _g16b "LEG 2: the historical ledger dispatch on GATE 11's (A1) fire-proof" \
        'is 2 gates behind one exit code' "
import os
A='assert_fires_why \"GATE 11 (A1) ledger deleted\" ledger-phrases \\\\'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(' ledger-phrases ',' ledger ')
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"
  _g16b "LEG 2: the historical links dispatch on GATE 4's fire-proof" \
        'is 2 gates behind one exit code' "
import os
A='assert_fires_why \"GATE 4 internal links (documentation/GUIDE.md)\" links-internal \\\\'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(' links-internal ',' links ')
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"
  _g16b "LEG 2: an invocation the extractor can no longer see" \
        'One of the two extractors is wrong' "
import os
A='assert_stays_clean_why \"GATE 15 LEG 3 a rewritten note changes no claim\" instruments \\\\'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.strip()==A]
assert len(t)==1, 'anchor moved: %d' % len(t)
del L[t[0]]
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"
  _g16b "LEG 2: a call graph that can no longer see one gate calling another" \
        'the call graph is' "
import os,re
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
n=0
for i,l in enumerate(L):
    if re.match(r'^\s+gate_[a-z0-9_]+\s*\|\|', l):
        L[i]=l.replace('gate_','command gate_',1); n+=1
assert n>0, 'no in-function gate call lines found'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  # GATE 16 LEG 3 FIRE-PROOFS (item R4, round 11 drain-1, 2026-08-02) — BOTH DIRECTIONS.
  #
  # LEG 3 refuses a fire-proof substring that resolves to anything other than exactly one
  # message template, so it has two failure directions and both are exercised. Proving only
  # the rewording arm would ship the ambiguity arm untested, and item R7 says in as many words
  # that a matcher accepting too much is how the ORIGINAL defect (f5fac73) got in.
  #
  # THEY REUSE _g16b RATHER THAN ADDING A DRIVER, which is why `_g16b` is now the driver with
  # the larger caller count. That is deliberate: a third driver would be a third row to keep,
  # and LEG 3's own guard 2 requires every fixed-`$2` assertion to live inside a driver it can
  # read — so the cheapest way to keep that guard honest is to not multiply drivers.
  #
  # ARM 1 REWORDS A LIVE MESSAGE. It renames one word of GATE 15 LEG 4's shell-form finding in
  # the copy, which orphans the substring `_g15d`'s first leg asserts on. That is item N2's
  # hazard reproduced rather than described: N2 was a maintenance note naming a string no
  # assertion asserted on, and this is the same drift caught from the assertion's side.
  #
  # ARM 2 ADDS A SECOND PRINTER of the same wording — a decoy `echo` — so the substring becomes
  # producible by two templates and can no longer say which finding satisfied it.
  #
  # BOTH ANCHORS ARE ASSEMBLED FROM FRAGMENTS (item A2). Written whole, either would occur in
  # this fire-proof's own source, and arm 1's anchor would then match two lines and abort as
  # `anchor moved` instead of running. The split is load-bearing, not style.
  _g16b "LEG 3: a message reworded out from under a fire-proof's substring" \
        'no message template can produce' "
import os
A='and no anchored '+'guard within %d line(s)'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if A in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(A, 'and no anchored '+'sentinel within %d line(s)')
assert A not in L[t[0]], 'the wording survived the substitution'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"
  _g16b "LEG 3: a second message able to produce the same substring" \
        'message templates can produce' "
import os
A='echo '+chr(34)+'-- GATE 16 LEG 3: '
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if l.lstrip().startswith(A)]
assert len(t)==1, 'anchor moved: %d' % len(t)
D='  echo '+chr(34)+'  [note] decoy: and no anchored '+'guard within lines'+chr(34)+chr(10)
L.insert(t[0], D)
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  # LEG 3's VARIABLE-CARRIED HALF (round 11 drain-2, 2026-08-02). THE ARMS BELOW PROVE
  # DIFFERENT PROPERTIES, which is the whole reason there is more than one of them.
  #
  # ARM 1 PROVES THE SITE IS SEEN. It renames the variable at the assertion only, so the
  # assignments still exist under the old name and the asserted name has none. Without this
  # arm, a sort that silently dropped the variable form would still print [ok].
  #
  # ARM 2 PROVES THE LITERALS ARE ACTUALLY RESOLVED. Seeing the site and comparing the string
  # it carries are separate properties, and arm 1 alone would leave the second untested — the
  # asymmetric-pair shape this file's history says rots on the untested side. It rewords GATE
  # 15 LEG 2's live unanchored-guard finding, which is what the `case`'s first arm asserts on,
  # so that literal resolves to zero templates. MEASURED BEFORE WRITING: that wording occurs
  # exactly once in the file, and no driver substring contains it, so the mutation cannot
  # orphan a second assertion and satisfy this arm by the other one.
  #
  # THE ARMS ASSERT ON THE VARIABLE HALF'S OWN MESSAGE, not on the driver half's. That is why
  # the variable half prints its own verdict line: an arm asserting `no message template can
  # produce` would be satisfiable by the driver-side finding the leg above already covers, and
  # a fire-proof satisfiable by the check it is not testing proves nothing about the one it is.
  #
  # BOTH ANCHORS ARE SPLIT (item A2). Written whole, arm 1's would occur in its own source and
  # match two lines; arm 2's would put a second contiguous copy of a live message in the file,
  # which is a second template and would make LEG 3 fail itself.
  _g16b "LEG 3: a fire-proof asserting on a variable with no resolvable literal" \
        'a variable this leg found no literal assignment for' "
import os
A='grep '+'-qF '+chr(34)+'\$_g15b'+'why'+chr(34)
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if A in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(A, 'grep '+'-qF '+chr(34)+'\$_g15b'+'whyZZ'+chr(34))
assert A not in L[t[0]], 'the asserted name survived the substitution'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"
  _g16b "LEG 3: a message reworded out from under a variable-carried substring" \
        'carries a fire-proof literal' "
import os
A='this guard'+chr(39)+'s ERE is not anchored '+'at line start'
L=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)
t=[i for i,l in enumerate(L) if A in l]
assert len(t)==1, 'anchor moved: %d' % len(t)
L[t[0]]=L[t[0]].replace(A, 'this guard'+chr(39)+'s ERE is not anchored '+'at the head of a line')
assert A not in L[t[0]], 'the wording survived the substitution'
open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  # LEG 3's MIXED BIN (Q-773 follow-up): a planted -qF pattern with text around an expansion fits ZERO templates alone, TWO beside two decoy echoes (item A2 fragments).
  # Q-954 (2026-10-03): the planted pattern was `zqmix $zq planted`, whose two END words each fit a field
  # by end absorption, so it fit 96_transcripts.sh's `[ok]   %s:%d %s %s (%s)` print as well: zero decoys
  # gave 1 template (no finding, rc 0) and two gave 3. Both legs have been red since that print landed.
  # The trailing literal `here` keeps `planted` interior, where no field can absorb it.
  _g16b "LEG 3: a mixed assertion that fits no message template" 'and fits 0 message template(s)' "
assert (L:=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)) and len(t:=[i for i,l in enumerate(L) if l.lstrip().startswith('echo '+chr(34)+'-- GATE 16 LEG 3: ')])==1, 'anchor moved'; L.insert(t[0], '  grep '+'-qF '+chr(34)+'zqmix \$zq planted here'+chr(34)+' /dev/null'+chr(10))
import os; open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"
  _g16b "LEG 3: a mixed assertion that fits two message templates" 'and fits 2 message template(s)' "
assert (L:=open('$_DG_SRC',encoding='utf-8').read().splitlines(True)) and len(t:=[i for i,l in enumerate(L) if l.lstrip().startswith('echo '+chr(34)+'-- GATE 16 LEG 3: ')])==1, 'anchor moved'; L[t[0]:t[0]]=['  grep '+'-qF '+chr(34)+'zqmix \$zq planted here'+chr(34)+' /dev/null'+chr(10)]+2*['  echo '+chr(34)+'  [note] zqmix \$zq planted here'+chr(34)+chr(10)]
import os; open(os.environ['_G16B_COPY'],'w',encoding='utf-8').writelines(L)"

  rm -f "$_G16B_COPY"
  # ------------------------------------------------------------------------------
  # GATE 17 FIRE-PROOFS (round-7 brief item 6, 2026-08-02). NO COUNT IS WRITTEN HERE, on
  # purpose (round 14 ledger, item R14 continued). The population is the assertions below
  # whose label begins "GATE 17 LEG ", and a reader can derive it by reading them. A number
  # written here could not be derived, and it rotted.
  #
  # IT READ "FIVE LEGS", AND THE SENTENCE BELOW ENUMERATED FIVE TO MATCH. LEG 6 was added by
  # ddad7b81 ("Phase-4: GATE 17 could compare one board and call it a pass"); neither the
  # count nor the enumerating prose was touched by it. The `covered:` list in the coverage-gap
  # block further down counts this SAME bucket and had it right — four fire legs, one negative
  # control, one phase-4 leg — so two censuses over one bucket disagreed with each other while
  # both stayed green. That is the shape round 14's R14 fix and its fifth member describe, and
  # this is a SIXTH member found; like the fifth, "sixth found" is not a claim about how many
  # exist. It hid from both earlier sweeps because it is not in the coverage-gap block at all:
  # it is a census in a fire-proof's OWN header, and neither sweep's population included those.
  #
  # The first two REPRODUCE the two historical defects rather than describing them: ccn4's
  # verdict written by description and not at the id, and a load-bearing row nobody was
  # looking at. The rest exist because this gate's own first live run was WRONG in both
  # directions at once — it reported rs1 missing from both published boards and invented an
  # orphan row "Full", the fault entirely in the parser — plus the phase-4 leg that caught the
  # gate comparing ONE board and calling it a pass. A gate whose first run mis-parsed the
  # corpus does not get to be trusted on a green run.
  _G17_TR=reports/TR1_EIGHT_CENTURIES_MEASURED.md

  # LEG 1 — THE MOTIVATING EXAMPLE, and it is a LEG-B (report-only) case, so it asserts on
  # OUTPUT and requires rc 0. Stripping ccn4's inline verdict recreates the corpus exactly as
  # it stood before TR-1 v1.23: the row IS classified, in prose, next to its description --
  # and this gate must nonetheless move it into the "no verdict at the id" bucket, because
  # that bucket is about FINDABILITY BY ID and nothing else. If this leg ever stops firing,
  # the gate has started crediting a verdict to a row that does not carry one, which is the
  # false clear that let the 2026-08-01 sweep call d7 "the last unclassified row".
  if python3 -c "
p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a=' (*data-like* — see headline 1)'
assert s.count(a)==1, 'ccn4 inline-verdict anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'',1))" 2>/dev/null; then
    G17OUT=$(bash "$0" scoreboard 2>&1); G17RC=$?
    if [ "$G17RC" -eq 0 ] \
       && grep -qF 'TR1_EIGHT_CENTURIES_MEASURED.md: 1/31 rule(s) carry a verdict at the id (d7)' <<<"$G17OUT" \
       && grep -qE 'TR1_EIGHT_CENTURIES_MEASURED\.md: 22 row\(s\) carry NO verdict at the id \(rs1, rs2, ccn1, ccn2, ccn3, ccn4,' <<<"$G17OUT"; then
      echo "  [ok]   GATE 17 LEG 1: ccn4's verdict stripped from the id — 2/31 becomes 1/31 and ccn4 joins the silent bucket (the pre-v1.23 corpus)"
    else
      echo "  [FAIL] GATE 17 LEG 1 — the ccn4 row kept its verdict after the verdict was deleted"
      echo "         (rc=$G17RC). That is the ccn4 defect, inverted: the ledger would report a"
      echo "         classification nobody wrote."
      printf '%s\n' "$G17OUT" | grep -E 'TR1_EIGHT' | sed 's/^/           > /' | head -3
      PASS=1
    fi
    _selftest_revert "$_G17_TR"
  else
    echo "  [FAIL] GATE 17 LEG 1 — could not inject; the assertion did NOT run."; PASS=1
  fi

  # LEG 2 — LEG A, hard, on the other historical row. d7 was unclassified for weeks and was
  # found because a human named it; deleting its board entry outright is the coarsest version
  # of the same invisibility, and must be a FAIL naming d7 rather than a note.
  assert_fires_why "GATE 17 LEG 2: a registry rule deleted from the published board (d7)" \
    scoreboard 'registry rule\(s\) never reach the published board: d7' \
"p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a=' · d7 1.7×10⁻⁴'
assert s.count(a)==1, 'd7 board-entry anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'',1))"

  # LEG 3 — THE VACUITY GUARD, and the one this gate most needs. If an anchor moves, the
  # naive outcome is an empty region: every id reads as missing, or (had the scan been written
  # the other way) nothing reads as missing and the run is GREEN with the instrument switched
  # off. That second outcome is the 2026-08-01 false clear exactly. The mutation breaks the
  # TABLE anchor specifically — the one added AFTER the first live run mis-parsed rs1 — so
  # this leg also pins the fix that run forced.
  assert_fires_why "GATE 17 LEG 3: the table anchor moved — an unlocatable board is a FAIL, not an empty scan" \
    scoreboard 'table anchor MISSING' \
"p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a='estimates): rs1'
assert s.count(a)==1, 'table anchor already absent or duplicated: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'estimates) : rs1',1))"

  # LEG 4 — PROVES THE GATE READS THE REGISTRY, not a list transcribed into this script. A
  # gate that hard-coded the 31 ids would pass legs 1-3 unchanged and would be silent on the
  # only event it exists to catch: a rule added to solve.py that never reaches the board.
  # This is the same distinction GATE 14's "a NEW pair the allowlist has never seen" leg
  # draws, and it is the leg a refactor is most likely to quietly invalidate.
  assert_fires_why "GATE 17 LEG 4: a NEW registry rule that never reaches the board (proves the id list is derived, not transcribed)" \
    scoreboard 'never reach the published board: zzselftest' \
"p='solve.py'
s=open(p,encoding='utf-8').read()
a='REGISTRY_KW_EXPECTED = ['
assert s.count(a)==1, 'registry anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,a+chr(10)+'    (\"zzselftest\", 0),',1))"

  # LEG 5 — NEGATIVE CONTROL, and it targets the boundary rather than the happy path. The
  # word "principled" is inserted AFTER the close anchor, i.e. outside the table. A gate that
  # grepped the file instead of the bounded region would credit some row with a verdict it
  # does not have; the counts must not move. Without this leg, legs 1-4 are equally consistent
  # with a scan that reads the whole document.
  if python3 -c "
p='$_G17_TR'
s=open(p,encoding='utf-8').read()
a='Wrap-distance finals:'
assert s.count(a)==1, 'close anchor moved: %d' % s.count(a)
open(p,'w',encoding='utf-8').write(s.replace(a,'These are principled, data-like rows. '+a,1))" 2>/dev/null; then
    G17OUT=$(bash "$0" scoreboard 2>&1); G17RC=$?
    if [ "$G17RC" -eq 0 ] \
       && grep -qF 'TR1_EIGHT_CENTURIES_MEASURED.md: 2/31 rule(s) carry a verdict at the id (ccn4, d7)' <<<"$G17OUT"; then
      echo "  [ok]   GATE 17 LEG 5: a verdict word OUTSIDE the close anchor changes no count — the region bounds the scan"
    else
      echo "  [FAIL] GATE 17 LEG 5 — text outside the board moved the verdict ledger (rc=$G17RC),"
      echo "         so the gate is grepping the document, not reading the table."
      printf '%s\n' "$G17OUT" | grep -E 'TR1_EIGHT' | sed 's/^/           > /' | head -3
      PASS=1
    fi
    _selftest_revert "$_G17_TR"
  else
    echo "  [FAIL] GATE 17 LEG 5 — could not inject; the assertion did NOT run."; PASS=1
  fi

  # LEG 6 — PHASE-4 ON THIS UNIT'S OWN BATCH, and it is here because the first draft failed
  # it. Shortening BOARDS to a single path left `len(regions) != len(BOARDS)` satisfied, so
  # the gate printed "present on 1 board(s)" and exited 0 with the report-vs-documentation
  # comparison switched off entirely. A count nobody is required to read is not a check. The
  # mutation removes the documentation copy from the list and the gate must REFUSE.
  #
  # THIS LEG'S OWN FIRST RUN FAILED, and for the reason GATE 15's header already records:
  # the confirmation searched for the bare literal, which THESE VERY LINES write into
  # doc_gates.sh, so the copy always "still contained" the path and the leg reported it could
  # not build. The check is therefore anchored at line start (`^    "docum...`), which the
  # BOARDS entry matches and no line of this fire-proof does. Second instance of the class in
  # two days; the general lesson is that a fire-proof searching its own source file must
  # match on a form its own text cannot take.
  #
  # Q-748 (b) (V3A-111#3; mechanism Opus CC; fixed 2026-09-24 Opus FF). The copy was written to
  # $(git rev-parse --git-dir), and UNLIKE the GATE 15/16 copies (read via DOC_GATES_SRC_OVERRIDE,
  # location-free) this one is RUN, so its own `cd "$(dirname "$0")/.."` decides the tree it
  # checks. In a normal clone git-dir is `.git` and `.git/..` is the root, by luck. In a LINKED
  # worktree git-dir is `<main>/.git/worktrees/<name>`, the copy cd'd into `.git/worktrees`, and
  # the leg failed there on every run. The copy now lives in scripts/ itself (mktemp, so two
  # clones or a stale file cannot collide), which makes `dirname/..` the root in BOTH layouts.
  _G17_COPY=$(mktemp scripts/.doc_gates_g17_copy.XXXXXX) || _G17_COPY=""
  if [ -n "$_G17_COPY" ] && grep -v '^    "documentation/LITERATURE_RULES_POPULATION_TESTS.md",$' \
       "$_DG_SRC" > "$_G17_COPY" \
     && ! grep -qE '^    "documentation/LITERATURE_RULES_POPULATION_TESTS\.md",$' "$_G17_COPY"; then
    G17OUT=$(bash "$_G17_COPY" scoreboard 2>&1); G17RC=$?
    if [ "$G17RC" -eq 1 ] \
       && grep -qF 'the board list holds 1 file(s)' <<<"$G17OUT"; then
      echo "  [ok]   GATE 17 LEG 6: one of the two published boards dropped from the list is a FAIL, not a smaller count"
    else
      echo "  [FAIL] GATE 17 LEG 6 — the gate ran against ONE board and reported success"
      echo "         (rc=$G17RC). The report's copy of the table and the documentation's could"
      echo "         then diverge without anything noticing."
      printf '%s\n' "$G17OUT" | sed 's/^/           > /' | head -4
      PASS=1
    fi
  else
    echo "  [FAIL] GATE 17 LEG 6 — could not build the mutated copy (the BOARDS entry anchor"
    echo "         moved, or mktemp in scripts/ failed), so the assertion did NOT run."
    PASS=1
  fi
  [ -n "$_G17_COPY" ] && rm -f "$_G17_COPY"

  # GATE 25 FIRE-PROOF (2026-08-11, the day after the gate landed). GATE 25 shipped at
  # a23d82a9 with NO assertion of any kind, so nothing in this harness could separate a gate
  # that reads the corpus from one that reads nothing: a green `repro-reach` attested that
  # every documented reproduction command resolves to a real flag, and the whole evidence for
  # that attestation was its own exit code. That is precisely the shape GATE 15 refuses for an
  # INSTRUMENT, and it was live for a GATE — over-attestation of the kind this suite exists to
  # catch, not a missing nicety.
  #
  # THE DISPATCH IS THE LEAF NAME `repro-reach`, which runs gate_repro_reach and nothing else.
  # GATE 16 LEG 2 refuses a fire-proof written against a combined dispatch name outright, so
  # this is satisfied structurally rather than by an argument about wording — the correction
  # that retired the `links` and `ledger` fire-proofs (item B2, round 9).
  #
  # THE TWO LEGS ARE A MATCHED PAIR, and neither is worth much alone. Same file, same
  # appended sentence, same mutation shape; the ONLY difference is whether the cited flag
  # exists in verify.py. "It fires" on its own is equally consistent with a gate that rejects
  # any flag name it has not seen before — which would make the next reproduction command
  # anyone documents a false [FAIL] on a BLOCKING pre-push hook. "It stays silent" on its own
  # is equally consistent with a gate that never opened the file. Run together, the verdict is
  # attributable to the flag's existence and to nothing else, which is the same argument item
  # A4's live/commented GATE 2 pair is built on.
  assert_fires_why "GATE 25 a reproduction command citing a flag that does not exist" \
    repro-reach 'verify\.py --doc-gates-fireproof-reach — not a flag of verify\.py' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nReproduce: python3 verify.py --doc-gates-fireproof-reach\n')"

  # THE CENSUS IS COMPARED, NOT PINNED — CONVERTED 2026-08-11, the day after this leg
  # shipped, and the conversion is the point rather than the number.
  #
  # IT SHIPPED PINNING `807 documented command-flag use(s)` AND WENT STALE WITHIN THE HOUR.
  # (An earlier revision of this comment claimed it was "already wrong when it shipped, the
  # clean census is 811" — THAT WAS FALSE and is retracted here. Measured on the COMMITTED
  # tree at a23d82a9: the census is 806, so 807 = 806 + 1 was CORRECT as written. The 811
  # reading came from the WORKING tree, i.e. a23d82a9 plus an uncommitted VERIFY.md that had
  # added 5 more uses. Diagnosing a stale pin from a dirty tree and reporting it as "wrong at
  # the commit" is the same single-source error the pin itself illustrates.)
  # What actually happened is worse for the absolute-pin case, not better: the number was
  # right at the commit and was falsified by a CONCURRENT EDIT while the leg was being
  # written. Its own comment recorded the census moving 806 -> 809 -> 810 -> 811 across
  # twenty minutes while a concurrent
  # verify.py/VERIFY.md edit was being written, and then pinned a number anyway with an
  # instruction to RE-TAKE it by hand. That instruction is the defect, not the cure: an
  # ABSOLUTE corpus-derived count in an assertion is guaranteed to rot, it rots in the
  # direction that matters — a corpus that GREW and a leg that stopped reading the corpus are
  # indistinguishable at a fixed number — and the only remedy on offer is a fresh number with
  # the same expiry. Replacing 807 with 812 would have been exactly that, one round later.
  #
  # THE TECHNIQUE IS THE ONE LEG 2's INLINE LEGS BELOW ALREADY USE, applied here rather than
  # invented: take the census on the CLEAN tree, then require the mutated run to read
  # base + 1. This mutation appends exactly ONE reproduction command to documentation/GUIDE.md,
  # so base + 1 is the entire claim and nothing here needs re-measuring when the corpus moves.
  # The waiver count is pinned to base EXACTLY (it must not move), for the reason the pinned
  # version already gave: a NARRATION row silently swallowing this flag is the one other way
  # the leg could go green without the comparison working. The `scanned N docs` half stays out
  # of the ERE — it moves on any new .md and discriminates nothing here.
  #
  # IT IS STILL A DISCRIMINATOR, which is the whole property a relative form must not trade
  # away. Three ways this leg could go green with the gate broken, each refused by a different
  # half of the assertion, and the second was PROVEN BY SABOTAGE on 2026-08-11 rather than
  # argued:
  #   * a run that never re-read documentation/GUIDE.md prints base, not base + 1 -> RED;
  #   * a gate that stops telling a REAL flag from a fake one in the direction this control
  #     owns — i.e. reports `--recount` as missing — exits non-zero, and assert_stays_clean_why
  #     fails at the rc test before the ERE is consulted. SABOTAGE RUN: delete the
  #     `if fl in have[tool]: continue` line from gate_repro_reach and this leg goes [FAIL]
  #     while its paired assert_fires_why above stays [ok]. The opposite sabotage (every flag
  #     treated as present) is what that paired fire-proof owns; neither leg covers both
  #     directions alone, which is why they are a matched pair;
  #   * a NARRATION waiver absorbing the injection moves the waiver count -> RED.
  #
  # THE BASE RUN IS THIS LEG'S OWN, not LEG 2's, deliberately. LEG 2 takes its base after
  # several mutations have been injected and reverted; a base a failed revert could have moved
  # is not a base. If the census cannot be read at all the leg says so and FAILS — a leg that
  # cannot read its own base is silent, not clean — and the sentinel makes the assertion below
  # fail too, so that failure cannot be one line nobody greps.
  #
  # WHAT THIS COSTS GATE 16, stated rather than left to be found. GATE 16 extracts an
  # assertion's evidence-ERE as the FIRST SINGLE-QUOTED token after the label, so an ERE
  # carrying a shell variable can only be quoted piecewise, and what GATE 16 scans here is the
  # literal fragment ` documented command-flag use\(s\), ` rather than the whole ERE. That is
  # SOUND but weaker, and the soundness is the reason it is acceptable: the real ERE contains
  # the fragment as a substring, so any line matching the real ERE also matches the fragment —
  # if the fragment is not preflight-emittable, neither is the ERE. What is given up is
  # precision in GATE 16's report, not safety in its verdict.
  _G25_CBASE=$(bash "$0" repro-reach 2>&1)
  _G25_CU=$(printf '%s' "$_G25_CBASE" | grep -oE '[0-9]+ documented command-flag use' | grep -oE '^[0-9]+')
  _G25_CW=$(printf '%s' "$_G25_CBASE" | grep -oE '[0-9]+ declared-narration waiver' | grep -oE '^[0-9]+')
  # The PROPOSAL count is pinned too (added 2026-09-02, batch C7). Without it this control had
  # a new way to go green with the gate broken, and the comment above already names the shape:
  # "a NARRATION waiver absorbing the injection moves the waiver count -> RED". A PROPOSAL
  # waiver absorbing it would have moved no number this assertion read. Pinned, not added as a
  # new caller: `documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt` machine-reads `callers=N` for
  # both helpers and GATE 15 LEG 3 re-derives it, so a new invocation is a two-file change.
  _G25_CP=$(printf '%s' "$_G25_CBASE" | grep -oE '[0-9]+ proposal-marker waiver' | grep -oE '^[0-9]+')
  if [ -z "$_G25_CU" ] || [ -z "$_G25_CW" ] || [ -z "$_G25_CP" ]; then
    echo "  [FAIL] GATE 25 negative control — the base repro-reach run printed no census line,"
    echo "         so the control below has no base to compare against. A leg that cannot read"
    echo "         its own base is silent, not clean."
    PASS=1; _G25_CU=-1; _G25_CW=-1; _G25_CP=-1
  fi
  assert_stays_clean_why "GATE 25 the same sentence citing a flag that DOES exist stays silent" \
    repro-reach "$((_G25_CU + 1))"' documented command-flag use\(s\), '"$_G25_CW"' declared-narration waiver\(s\), '"$_G25_CP"' proposal-marker waiver\(s\)' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+'\n\nReproduce: python3 verify.py --recount\n')"

  # 🔴 Q-703 (2026-09-24, Fable K) — GATE 25's POPULATION IS $DOCS, proven on the case the old
  # hand-written glob list could not see. A scratch tree (real sources symlinked, so `have[]` is
  # the live flag set) tracks TWO markdown files: documentation/CLEAN.md with a real flag, and
  # viz/README.md with a flag solve.c does not have. The shipped population (documentation/,
  # reports/, *.md) never read viz/ — measured at 5c296837: 83 docs scanned, rc 0, while the
  # same gate over $DOCS scanned 97 and fired on viz/viz_kc_spectrum.md — so on this fixture the
  # OLD gate exits 0 and the NEW one must fire, name the flag, name viz/README.md, and print the
  # population token for exactly the two tracked files. Inline for the callers=N reason above.
  _g25p_d=$(mktemp -d) || { echo "  [FAIL] GATE 25 (Q-703) population from \$DOCS — no tmpdir"; PASS=1; }
  if [ -n "${_g25p_d:-}" ] && [ -d "$_g25p_d" ]; then
    mkdir -p "$_g25p_d/scripts" "$_g25p_d/documentation" "$_g25p_d/viz"
    cp "$0" "$_g25p_d/scripts/doc_gates.sh"; cp -R "$(dirname "$0")/doc_gates.d" "$_g25p_d/scripts/"
    for _g25p_f in solve.c verify.c solve.py verify.py sat.py roae.py; do ln -s "$PWD/$_g25p_f" "$_g25p_d/$_g25p_f"; done
    ( set -e; cd "$_g25p_d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .; git symbolic-ref HEAD refs/heads/main
      printf 'Run `solve --selftest` first.\n' > documentation/CLEAN.md
      printf 'Then run `solve --no-such-flag-fablek`.\n' > viz/README.md
      git add -A && git commit -qm 'two docs'
      grep -q '"--selftest"' solve.c            # premise: the CLEAN flag really is a solve.c flag
      ! grep -q -- '--no-such-flag-fablek' solve.c   # premise: the viz flag really is not
    ) >/dev/null 2>&1; _g25p_rcS=$?
    if [ "$_g25p_rcS" -ne 0 ]; then
      echo "  [FAIL] GATE 25 (Q-703) population from \$DOCS — scratch setup broke or a premise failed (rc=$_g25p_rcS), so the assertion did NOT run"
      PASS=1
    else
      _g25p_out=$(cd "$_g25p_d" && bash scripts/doc_gates.sh repro-reach 2>&1); _g25p_rc=$?
      if [ "$_g25p_rc" -eq 1 ] \
         && grep -qx 'GATE25_POPULATION_FROM_DOCS=2' <<<"$_g25p_out" \
         && grep -qF '[FAIL] solve --no-such-flag-fablek — not a flag of solve.c' <<<"$_g25p_out" \
         && grep -qF 'cited in viz/README.md' <<<"$_g25p_out" \
         && ! grep -qF 'solve --selftest' <<<"$_g25p_out"; then
        echo "  [ok]   GATE 25 (Q-703) population from \$DOCS — a bad flag in viz/README.md fires the gate"
        echo "         (the old glob list never read viz/), the population token counts both tracked"
        echo "         docs, and the real flag in documentation/ is not named"
      else
        echo "  [FAIL] GATE 25 (Q-703) population from \$DOCS — expected rc!=0, GATE25_POPULATION_FROM_DOCS=2,"
        echo "         the viz/README.md flag named and the documentation/ flag silent; got rc=$_g25p_rc:"
        printf '%s\n' "$_g25p_out" | grep -E 'GATE25_POPULATION|\[FAIL\]|\[ok\]|cited in' | sed 's/^/           > /' | head -5
        PASS=1
      fi
    fi
    rm -rf "$_g25p_d"
  fi

  # 🔴 S2 (2026-09-24, batch-2 pre-publication review, Fable P) — the PROPOSAL markers must not
  # waive a broken command because the word 'pending' is nearby as ordinary prose. The bare
  # marker Q-703 shipped did exactly that (measured: two misspelt flags, [prop], rc 0). Same
  # scratch shape as the Q-703 leg (real sources symlinked, so `have[]` is the live flag set),
  # inline for the callers=N reason above. Two tracked docs: documentation/PROBE.md is the
  # reviewer's probe — "pending review" as a fence caption and "(the pending rerun)" in a
  # sentence, each beside a flag solve.c does not have — and viz/PROP.md is the CONTROL, the two
  # marker forms the viz/ pages really use ("### PENDING flag (...)" caption, "(PENDING --x)" on
  # the line before the command), each beside another absent flag. The gate must FAIL the two
  # probe flags, waive the two control flags as [prop] naming the marker and its scope, and
  # never cross them: a leg that only checked the FAIL half could pass with the marker list
  # emptied, and one that only checked the [prop] half could pass with the bare marker back.
  _g25q_d=$(mktemp -d) || { echo "  [FAIL] GATE 25 (S2) ordinary 'pending' prose does not waive — no tmpdir"; PASS=1; }
  if [ -n "${_g25q_d:-}" ] && [ -d "$_g25q_d" ]; then
    mkdir -p "$_g25q_d/scripts" "$_g25q_d/documentation" "$_g25q_d/viz"
    cp "$0" "$_g25q_d/scripts/doc_gates.sh"; cp -R "$(dirname "$0")/doc_gates.d" "$_g25q_d/scripts/"
    for _g25q_f in solve.c verify.c solve.py verify.py sat.py roae.py; do ln -s "$PWD/$_g25q_f" "$_g25q_d/$_g25q_f"; done
    ( set -e; cd "$_g25q_d"
      export GIT_AUTHOR_NAME=selftest GIT_AUTHOR_EMAIL=selftest@invalid
      export GIT_COMMITTER_NAME=selftest GIT_COMMITTER_EMAIL=selftest@invalid
      git init -q .; git symbolic-ref HEAD refs/heads/main
      printf 'Results are pending review:\n\n```\nsolve --kc-scann --kc-limit 1\n```\n\nSee `solve --verifyy PATH` (the pending rerun).\n' > documentation/PROBE.md
      printf '### PENDING flag (proposed name)\n\n```\nsolve --kc-nonesuch-fablep FDIR\n```\n\n```bash\n# 1. the grid  (PENDING --kc-nonesuch-fablep2)\nsolve --kc-nonesuch-fablep2 FDIR\n```\n' > viz/PROP.md
      git add -A && git commit -qm 'probe and control'
      for _g25q_flag in '--kc-scann' '--verifyy' '--kc-nonesuch-fablep' '--kc-nonesuch-fablep2'; do
        if grep -q -- "$_g25q_flag" solve.c; then exit 4; fi   # premise: none of the four is a real flag
      done
    ) >/dev/null 2>&1; _g25q_rcS=$?
    if [ "$_g25q_rcS" -ne 0 ]; then
      echo "  [FAIL] GATE 25 (S2) ordinary 'pending' prose does not waive — scratch setup broke or a premise failed (rc=$_g25q_rcS), so the assertion did NOT run"
      PASS=1
    else
      _g25q_out=$(cd "$_g25q_d" && bash scripts/doc_gates.sh repro-reach 2>&1); _g25q_rc=$?
      if [ "$_g25q_rc" -eq 1 ] \
         && grep -qF '[FAIL] solve --kc-scann — not a flag of solve.c' <<<"$_g25q_out" \
         && grep -qF '[FAIL] solve --verifyy — not a flag of solve.c' <<<"$_g25q_out" \
         && grep -qF "[prop] solve --kc-nonesuch-fablep — viz/PROP.md:" <<<"$_g25q_out" \
         && grep -qF "('pending flag' in the fence caption)" <<<"$_g25q_out" \
         && grep -qF "[prop] solve --kc-nonesuch-fablep2 — viz/PROP.md:" <<<"$_g25q_out" \
         && grep -qF "('pending --' in the sentence)" <<<"$_g25q_out" \
         && ! grep -qF '[prop] solve --kc-scann' <<<"$_g25q_out" \
         && ! grep -qF '[prop] solve --verifyy' <<<"$_g25q_out" \
         && ! grep -qF '[FAIL] solve --kc-nonesuch-fablep' <<<"$_g25q_out"; then
        echo "  [ok]   GATE 25 (S2) ordinary 'pending' prose does not waive — both probe flags FAIL while"
        echo "         the two real marker forms still waive as [prop], each naming its marker and scope"
      else
        echo "  [FAIL] GATE 25 (S2) ordinary 'pending' prose does not waive — expected rc!=0, [FAIL] for"
        echo "         --kc-scann and --verifyy, [prop] for the two control flags, no crossing; got rc=$_g25q_rc:"
        printf '%s\n' "$_g25q_out" | grep -E '\[FAIL\]|\[prop\]|\[ok\]' | sed 's/^/           > /' | head -6
        PASS=1
      fi
    fi
    rm -rf "$_g25q_d"
  fi

  # GATE 25 LEG 2 (REPORT-ONLY) — PROVEN ON OUTPUT AND ON rc NOT MOVING, never on rc alone.
  #
  # It cannot use assert_fires_why: that helper FAILS the assertion unless the gate exits
  # non-zero, and a non-zero exit is the one thing this leg must never cause. Same reason GATE
  # 1's and GATE 13's legs are written inline — "ASSERT ON OUTPUT, never on rc: GATE 13 is
  # report-only and returns 0 by design". A report-only leg with no proof at all is the
  # unfalsifiable-instrument shape this suite exists to refuse, so it gets one anyway.
  #
  # THE COUNT IS COMPARED, NOT PINNED, and that is a deliberate departure from the pinned
  # censuses above. LEG 2's population is a function of the whole corpus, so an absolute
  # number here would go stale on any new doc — and it would go stale SILENTLY in the
  # direction that matters, since a corpus drift and a broken leg look identical at a fixed
  # number. The base run is taken first and the mutated run must be base+1 (fire) and base
  # exactly (control). Nothing here needs re-measuring when the corpus moves.
  #
  # rc IS COMPARED TO ITS OWN PRE-MUTATION VALUE, not asserted to be 0. Asserting 0 would
  # bind this leg to LEG 1 being clean on whatever tree it runs against; a real LEG 1 finding
  # committed by someone else would then fail THIS assertion for a reason that has nothing to
  # do with LEG 2. Equality with the base rc is the property actually claimed: LEG 2 changed
  # the exit code by nothing, whatever it was.
  #
  # THE TARGET IS THE FILE THAT MOTIVATED THE GROUPING RULE. documentation/GT_LADDER_FORMAT.md
  # carries `1,2,3,4,6` — list syntax, not a figure — and it is one of the three files the
  # loose "comma between digits" reading falsely flagged (measured, recorded at LEG 2's
  # definition). Injecting a REAL grouped figure into that same file proves the narrowed rule
  # still ADMITS a figure in the very file whose punctuation it learned to ignore, which a
  # synthetic target could not show.
  # NO HELPER FUNCTION IS DEFINED FOR THE CENSUS EXTRACTION, deliberately. Every function
  # declared in this region is an INSTRUMENT and must carry a row in
  # documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt or GATE 15 fails — and the only kind a
  # `$( ... "$var")` wrapper could claim is kind=BLOCK, the weakest one, whose own row already
  # says a report line is proximity and not reachability. Three inline pipelines are worth
  # more than a fourth BLOCK row.
  _G25_BASE=$(bash "$0" repro-reach 2>&1); _G25_BASERC=$?
  _G25_N=$(printf '%s' "$_G25_BASE" | grep -oE '; [0-9]+ publish' | grep -oE '[0-9]+')
  # 🔴 Q-702 (2026-09-24, Fable K): THE TARGET'S OWN STATE IS PART OF THE BASE. At 5c296837
  # GT_LADDER_FORMAT.md already carries ONE grouped figure (`26,112`) and names no command, so it
  # was already among the noted files: the fire case could not add a file (5 -> 5) and the control
  # REMOVED one (5 -> 4), and both legs were RED with the leg itself working exactly as specified.
  # The expectation is now derived from the target's base state K (its figure count in the base
  # note list, 0 when absent): the fire case must report the file with K+1 figures and the
  # injected one as `largest`, moving the file count by +1 only when K was 0; the control must
  # drop the file from the list, moving the count by -1 only when K was > 0. Preconditions:
  # the injected figure must exceed the file's current largest, or `largest` could not name it.
  _G25_K=$(printf '%s' "$_G25_BASE" | grep -oE 'documentation/GT_LADDER_FORMAT\.md — [0-9]+ figure' | grep -oE '[0-9]+')
  _G25_K=${_G25_K:-0}
  _G25_KL=$(printf '%s' "$_G25_BASE" | grep -oE 'documentation/GT_LADDER_FORMAT\.md — [0-9]+ figure\(s\), largest [0-9,]+' | grep -oE '[0-9,]+$' | tr -d ,)
  if [ -z "$_G25_N" ]; then
    echo "  [FAIL] GATE 25 LEG 2 — the base run printed no '; N publish' census, so neither"
    echo "         leg below could be scored. LEG 2 is report-only: a leg that cannot read"
    echo "         its own census is silent, not clean."
    PASS=1
  elif [ -n "$_G25_KL" ] && [ "$_G25_KL" -ge 98765432109876 ]; then
    echo "  [FAIL] GATE 25 LEG 2 — precondition: GT_LADDER_FORMAT.md's largest grouped figure is"
    echo "         already $_G25_KL >= 98,765,432,109,876, so the injected figure could not be named as"
    echo "         largest and neither leg below can discriminate. Raise the injected figure."
    PASS=1
  else
    _G25_FEXP=$((_G25_N + (_G25_K == 0 ? 1 : 0)))
    _G25_CEXP=$((_G25_N - (_G25_K > 0 ? 1 : 0)))
    if python3 -c "
p='documentation/GT_LADDER_FORMAT.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'The ladder pass emitted 98,765,432,109,876 rows.'+chr(10))" 2>/dev/null; then
      _G25_F=$(bash "$0" repro-reach 2>&1); _G25_FRC=$?
      _selftest_revert documentation/GT_LADDER_FORMAT.md
      _G25_FN=$(printf '%s' "$_G25_F" | grep -oE '; [0-9]+ publish' | grep -oE '[0-9]+')
      if [ "$_G25_FN" = "$_G25_FEXP" ] \
         && grep -qF "documentation/GT_LADDER_FORMAT.md — $((_G25_K + 1)) figure(s), largest 98,765,432,109,876" <<<"$_G25_F" \
         && [ "$_G25_FRC" -eq "$_G25_BASERC" ]; then
        echo "  [ok]   GATE 25 LEG 2 fires: a grouped figure in a file with no reproduction"
        echo "         command is reported (file count $_G25_N -> $_G25_FN; the file's figures"
        echo "         $_G25_K -> $((_G25_K + 1)), largest = the injected one), and the exit code"
        echo "         does NOT move (rc $_G25_BASERC both runs)"
      else
        echo "  [FAIL] GATE 25 LEG 2 — an injected figure in a command-less file was not"
        echo "         reported (file count $_G25_N -> $_G25_FN, expected $_G25_FEXP; the file"
        echo "         must show $((_G25_K + 1)) figure(s), largest 98,765,432,109,876), or MOVED THE"
        echo "         EXIT CODE (rc $_G25_BASERC -> $_G25_FRC). The last of those is the"
        echo "         serious one: LEG 2 is report-only and a blocking pre-push hook runs it."
        printf '%s\n' "$_G25_F" | grep -E 'LEG 2|GT_LADDER' | sed 's/^/           > /' | head -3
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 25 LEG 2 — could not inject the fire case; assertion did NOT run."
      PASS=1
    fi

    # THE CONTROL, and without it the leg above is equally consistent with "any file carrying
    # a grouped figure is reported" — which would make LEG 2 a note on most of the corpus and
    # therefore a note nobody reads. Same file, same figure, one line apart: the only
    # difference is that the file now names a way to re-derive it.
    if python3 -c "
p='documentation/GT_LADDER_FORMAT.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'The ladder pass emitted 98,765,432,109,876 rows.'+chr(10)
                                    +'Reproduce: python3 verify.py --recount'+chr(10))" 2>/dev/null; then
      _G25_C=$(bash "$0" repro-reach 2>&1); _G25_CRC=$?
      _selftest_revert documentation/GT_LADDER_FORMAT.md
      _G25_CN=$(printf '%s' "$_G25_C" | grep -oE '; [0-9]+ publish' | grep -oE '[0-9]+')
      if [ "$_G25_CN" = "$_G25_CEXP" ] \
         && ! grep -qF 'documentation/GT_LADDER_FORMAT.md — ' <<<"$_G25_C" \
         && [ "$_G25_CRC" -eq "$_G25_BASERC" ]; then
        echo "  [ok]   GATE 25 LEG 2 negative control: the SAME figure in the SAME file, beside a"
        echo "         reproduction command, is not reported (file count $_G25_N -> $_G25_CN, the"
        echo "         file leaves the list) — the note is driven by the ABSENCE of a command, not"
        echo "         by the figure"
      else
        echo "  [FAIL] GATE 25 LEG 2 negative control — a file that DOES name a reproduction"
        echo "         command was still reported (file count $_G25_N -> $_G25_CN, expected"
        echo "         $_G25_CEXP; rc $_G25_BASERC -> $_G25_CRC). LEG 2 is then a note on the"
        echo "         corpus at large, which is how a report-only leg stops being read."
        printf '%s\n' "$_G25_C" | grep -E 'LEG 2|GT_LADDER' | sed 's/^/           > /' | head -3
        PASS=1
      fi
    else
      echo "  [FAIL] GATE 25 LEG 2 control — could not inject; assertion did NOT run."
      PASS=1
    fi
  fi

  # THE COVERAGE GAP, STATED IN FULL. One gate is not mutation-tested here (TWO since
  # 2026-08-06: GATE 18 joined uncovered, with hand-run fire-proofs — see its own
  # NOT-covered-YET entry at the foot of this list), and until
  # 2026-08-02 this note named only one gap at a time -- it said "GATE 2 + GATE 5" and
  # silently omitted GATE 8. A self-test that under-reports its own gap is the defect it
  # tests for, so the list is enumerated against the assertion calls above:
  #   THE COUNTING UNIT (Q-473, 2026-09-26), established from the assertion code and not from
  #            the labels: ONE ASSERTION = ONE `[ok]` VERDICT LINE ON A GREEN RUN. Each of the
  #            five shared helpers, the gate-local helpers (`_g16b`, GATE 15 LEG 4's) and
  #            every inline leg prints exactly ONE line beginning `  [ok]   ` on its passing
  #            path, in an if/else with the `[FAIL]` path, and any second line of the message
  #            is indented, not a second `[ok]`. A helper called N times is N assertions. A
  #            negative control, an A1 leg, a probe and a Q-604 pair are assertions like any
  #            other and count INLINE in the gate their label names. So a gate's multiplicity
  #            is the number of `[ok]` lines labelled `GATE <n>` in a green --selftest, and it
  #            is DERIVED, never written into this list:
  #              bash scripts/doc_gates.sh --selftest 2>&1 \
  #                | sed -nE 's/^  \[ok\]   GATE ([0-9]+[a-z]?)[ :(].*/\1/p' | sort -V | uniq -c
  #            A leg whose label names no gate (the A3 lock, R15's advisory, the A1 snapshot,
  #            the assert_stays_clean_why probe, the A6 preflight legs) is in the total
  #            `grep -c '^  \[ok\]   '` and in no gate's figure.
  #            THE `xN` MULTIPLICITIES THIS LIST CARRIED WERE REMOVED, NOT CORRECTED (all but
  #            GATE 8's x7, which alone was derived; see its entry). MEASURED 2026-09-26 on the
  #            batch-15 tree, before the Q-604 legs landed, reading each entry's "xN +
  #            controls" as legs and a bare number as one: 9 of the 20 comparable entries
  #            agreed with the census and 11 did not (3, 4b, 5b, 6, 7, 10a, 10b, 11, 14, 15,
  #            25), and the census named a gate this list omitted outright, GATE 59, now
  #            added. An entry that named some legs and wrote "x3" beside them could not be
  #            checked by anyone, because it never said which legs it counted. What follows
  #            each gate number now NAMES what its legs prove; it is not a census, and a gate
  #            named here with one description may have many legs.
  #   covered: 1 (output), 3, 3b (+negative control), 4, 4b, 5 (output) + its
  #            ALLOWLIST (drift immunity, dead anchor, unanchored-and-inert) + its Q-604
  #            tokeniser pair and its EST tokeniser pair, 5b (output), 6 (phrase legs + the FIGURE leg, item A8), 7,
  #            8 x7 — the four assert_gen_fires legs, the assert_gen_clean NEGATIVE
  #            control (rebuilt 2026-09-04; it was x6 for part of that day, between LEG 5's
  #            retirement taking two assert_gen_fires callers and the seeded reshipping
  #            adding one back, and this line said x7 throughout that window — which is
  #            exactly the rot the "not a hand count" sentence below claims immunity from,
  #            and it is recorded rather than quietly corrected, because the immunity is
  #            real for the THREE FIELDS and not for this prose that sums them),
  #            control, and the TWO assert_gen_fires_only legs the one-directional-comparison
  #            fix added. [The x7 on this entry is kept, not removed with the others under
  #            Q-473, because it is the one multiplicity that was DERIVED; see next.] This
  #            entry read "8 x5 (4 fire + 1 NEGATIVE control)" until round 14
  #            (item R14): the two gen_fires_only legs use a THIRD helper in the same GATE 8
  #            bucket, and a census bucketed by gate could not see them. x7 is the one
  #            multiplicity in this list that is not a hand count — it is the sum of three
  #            callers=N fields (assert_gen_fires, assert_gen_clean, assert_gen_fires_only)
  #            in documentation/DOC_GATE_SELFTEST_INSTRUMENTS.txt, which GATE 15 LEG 3
  #            re-derives every run, so it cannot rot the way the rest of this list can.
  #            THE LIMIT OF THAT, stated rather than left to be discovered: the sum equals
  #            GATE 8's count only because every caller of all three helpers is a GATE 8 leg
  #            today. A call to any of them from another gate would break the identity
  #            silently, and nothing checks the identity — only the three fields.
  #            9,
  #            10a (+negative control), 10b, 11, 12 (+ a NEGATIVE control),
  #            13 (worktree + batch) each with its own NEGATIVE control, and the batch
  #            one anchored on a REAL commit (b5bcff7c) rather than on an injection,
  #            14 (the motivating r3/p1c4 pair, a NEW pair the allowlist has never seen,
  #            the uncomparable-rule refusal, and the A1 missing-input leg) + a negative
  #            control, 15 (undeclared instrument, a row naming an assertion nobody
  #            wrote, a row for a function that no longer exists, and LEG 2's two clauses —
  #            a copy-confirmation guard written as an unanchored ERE and as the fixed
  #            string that was LIVE here until item A2) + its A1 leg + a negative
  #            control,
  #            16 — NO NUMBER IS WRITTEN HERE, and that is not shorthand: the two available
  #            counts DIFFER BY SEVEN. GATE 16 WAS ABSENT FROM THIS LIST ENTIRELY until
  #            round 17's ledger unit added this entry, and it is the file's single largest
  #            self-test contributor (19 of 124 legs; the next is GATE 15 at 16). It is
  #            PRE-EXISTING and the dates say how it happened: 489b75c6 wrote the header
  #            above that calls this inventory "STATED IN FULL"; 47fc740e then added GATE
  #            16's legs and joined them to nothing. Both 2026-08-02, neither a round-17
  #            commit. IT HID BY CONSTRUCTION: GATE 16 calls NONE of the five shared
  #            assertion helpers — its legs go through the gate-LOCAL helper `_g16b` and
  #            through literal echoes — and this list was built, in the header's own words,
  #            "enumerated against the assertion calls above". A census keyed on `assert_*`
  #            cannot see a gate that uses its own helper, which is the sibling of the
  #            "one bucket, two censuses" shape recorded below.
  #            THE TWO COUNTING UNITS, GATE 14's doctrine turned on this file's own
  #            bookkeeping. Both measured 2026-08-03:
  #              EMITTERS  grep -cE '^ +echo "  \[ok\]   GATE 16 ' scripts/doc_gates.sh -> 12
  #              LEGS      scripts/doc_gates.sh --selftest \
  #                          | grep -cF '  [ok]   GATE 16 '                             -> 19
  #            THE EMITTER COMMAND IS ANCHORED ON `^ +echo "` FOR A REASON, and it is this
  #            file's own recorded shape caught a fourth time. Written first as the obvious
  #            grep -cF over the label alone, it returned FOURTEEN — the extra two being
  #            THESE VERY COMMENT LINES, which contain the label because they quote the
  #            command. A count written into prose becomes part of its own corpus on the
  #            commit that records it. The anchor excludes comments by construction (a
  #            comment line starts `  #`, never `  echo`), and it was RE-RUN after the edit
  #            that introduced the self-reference, not before it. Cf. the note beside `_g16b`
  #            below: "whole-line matching is what keeps a fire-proof from being satisfied by
  #            its own source text".
  #            They differ because ELEVEN emitters are literal and the twelfth is `_g16b`,
  #            called eight times (LEG 2 x4, LEG 3 x4): 11 + 8 = 19. A hand count of source
  #            lines under-reports the legs by exactly those seven, which is why the rule
  #            and not either number is what is recorded here.
  #            WHAT THIS ENTRY DOES NOT SETTLE. Adding 16 closes the ABSENCE only. The
  #            per-gate MULTIPLICITIES in this list were not audited against the run, and a
  #            spot check says at least some do not agree with it — the `--selftest` label
  #            census gives 4b 9 legs and 15 16 legs against `4b` and `15 x5 + A1 + 1
  #            control` written here. That is NOT reported as a defect, because this list's
  #            counting UNIT was never stated and a printed [ok] label is not obviously the
  #            unit it counts. Settling that requires establishing the unit first; it is
  #            filed for round 18 rather than fixed by guess. [SETTLED 2026-09-26 by Q-473:
  #            the unit is LEGS, the `[ok]` census; see THE COUNTING UNIT at the head of this
  #            list. EMITTERS count source lines and are not the unit.]
  #            17 (LEG B's motivating ccn4 case, a registry rule deleted from the board,
  #            the moved-anchor vacuity guard, and a NEW registry rule proving the id list is
  #            derived from solve.py rather than transcribed) + a NEGATIVE control that puts a
  #            verdict word OUTSIDE the close anchor and requires the counts not to move
  #            + a PHASE-4 leg (one of the two published boards dropped from the list must be
  #            a FAIL, not a smaller count)
  #            25 — LEG 1 (a doc citing a flag that does not exist) + a NEGATIVE control
  #            (the same sentence citing a flag that DOES exist stays silent, pinned on the
  #            census the injection moves), and LEG 2 + a NEGATIVE control, both written
  #            INLINE because LEG 2 is report-only and assert_fires_why requires a non-zero
  #            exit — the same reason GATES 1 and 13 are inline. Added 2026-08-11, the day
  #            after the gate landed with no assertion at all; every leg dispatches the LEAF
  #            name `repro-reach`.
  #            59 (baseline-arithmetic: 59a, a seeded open row HOLDS its seeded defect, and
  #            59b, deleting one open row fails only that figure) — absent from this list
  #            until Q-473's census found it (2026-09-26).
  #   plus the MISSING-INPUT class (item A1, 2026-08-02): every assertion whose LABEL
  #            carries the `A1)` marker, each asserting WHY. NO PER-GATE TALLY AND NO
  #            TOTAL ARE WRITTEN HERE, on purpose. The population is derivable from the
  #            labels; a hand tally over it was not, and it rotted TWICE the same way.
  #            It read "2 x2, 3, 3b, 6 x2, 10a, 10b, 11 x2, 12, and the corpus preflight
  #            x1 -- 13 assertions", and its own enumerated items summed to TWELVE against
  #            that stated total of THIRTEEN. GATE 6 had gained a third A1 leg (its FIGURE
  #            registry, item A8) and the total alone was bumped, by an appended
  #            parenthetical that never touched the `6 x2` it was correcting. GATE 11 had
  #            gained a third too — `GATE 11 (figures, A1) figure registry deleted`, mode
  #            ledger-figures, cited by CONTENT because it does not sit in the A1 block —
  #            and nothing counted it at all, so the real population matched neither number.
  #            BOTH ARE ONE ERROR: a census bucketed by GATE cannot see a second or third
  #            leg sharing a bucket. Round 13's pins bullet failed identically one function
  #            away, where two pins shared invocation mode `cli` and the write-up counted
  #            MODES rather than PINS. That is why this bullet now states the RULE and not a
  #            number (round 14, item R14).
  #            SCOPE, and it is why no total here could be a total of the class anyway:
  #            GATE 14's and GATE 15's A1 legs carry the same marker and are counted in
  #            their own rows ABOVE, and GATE 8's deleted-artifact leg — the first of the
  #            class, and the reason it exists — is in the `covered` list above, in the GATE
  #            8 entry, with no marker on its label at all. (That entry was cited here as
  #            "`8 x5`" by the same commit that renamed it to `8 x7`: a pointer written to a
  #            token its own commit had just deleted. Cited by CONTENT now, because a
  #            same-file citation to a same-file token drifts on the very edit that moves
  #            it — round 14 drain-3.) THE MARKER RULE CANNOT SEE THAT LAST ONE,
  #            which is the limit a reader has to be told rather than left to discover.
  #   Of those, the ones asserting WHY and not merely an exit code (item A5 / #65):
  #            ALL OF THEM — DERIVED, NOT TALLIED (round 14 drain-3, item R14 continued).
  #            Every assertion helper in this harness takes an evidence argument and greps
  #            for it: assert_fires_why, assert_stays_clean_why, assert_gen_fires,
  #            assert_gen_clean and assert_gen_fires_only are the five, and the inline legs
  #            assert on message content rather than on rc (the one rc-only inline leg, GATE
  #            10's append control, is a structural gate's, excluded below). WHICH LEGS ARE
  #            INLINE IS A RULE, NOT A LIST (Q-475): an `[ok]` emitter in the --selftest
  #            region whose label is a LITERAL, not a helper's `$label` or `$1`. Derive them:
  #              sed -n '/^if \[ "\${1:-}" = "--selftest" \]; then$/,/^  exit "\$PASS"$/p' \
  #                scripts/doc_gates.sh | grep -E '^ +echo "  \[ok\]   ' | grep -vE '\$label|\$1 '
  #            (a hand-list, "the A3 lock, the A1 snapshot, R15's advisory", stood here and
  #            named only the members whose labels name no gate). So this bullet's population IS the `covered` list above
  #            minus the exclusions named next. It is not a second census and must not be
  #            rewritten as one.
  #            IT WAS A SECOND CENSUS UNTIL NOW, AND IT HAD ROTTED THE WAY A SECOND CENSUS
  #            DOES. It read "3, 3b x2, 4b, 6 x3, 7 x2, 8 x5, 11, 12 x5, and the whole A1
  #            class". `8 x5` contradicted the GATE 8 entry in the covered list above, and
  #            `3b x2` contradicted the GATE 3b entry there — both cited by CONTENT, not by
  #            their current values, because freezing a value here is the defect being fixed
  #            and this paragraph's own bookkeeping is not exempt from it. `8 x5` was right when
  #            GATE 8 had four fire legs and one negative control; the two
  #            assert_gen_fires_only legs then joined the bucket and ONLY the covered list
  #            was corrected — corrected by round 14's own R14 fix, which reported four
  #            members of exactly this shape in exactly this block and did not count this
  #            one. THIS IS A FIFTH MEMBER — fifth FOUND, which is not a claim about how
  #            many exist. It hid because that sweep swept the censuses it had already
  #            listed rather than the BUCKETS those censuses count, so a second census over
  #            the same buckets was never in its population. THAT is the residual R14 leaves:
  #            the shape is "one bucket, two censuses", and only a census that knows about
  #            its sibling can close it. Removing the numbers here closes it for this bullet
  #            by making it derived; it does not close it anywhere else in the corpus.
  #            GATES 1, 5, 5b and 13
  #            are report-only and already assert on output. GATES 4, 9, 10a/10b are
  #            structural, not classifier-driven: there is no matched token for them to name.
  #            GATE 13 JOINED THAT FIRST GROUP IN ROUND 17 (drain-3); it had been absent
  #            since the group was written. THE GROUP IS DERIVABLE, so do not remember it —
  #            but it takes TWO conditions, and round 17's LEDGER unit had to add the second
  #            because the first stopped selecting four the moment the `covered` list above
  #            was completed. Condition (i): the gate calls NONE of the five shared helpers,
  #            so its legs are written inline or in a gate-local helper and can only assert
  #            on output. Condition (ii): the gate is REPORT-ONLY — it is named as such in
  #            the banner literal at the foot of this file. For each gate g named in
  #            `covered`, ask whether
  #            grep -cE 'assert_[a-z_0-9]+ +"GATE <g> ' over this file returns 0; on
  #            2026-08-03 that returns 0 for FIVE of them — 1, 5, 5b, 13 and 16 — and GATE
  #            16 is a HARD gate, named in the PASS banner's hard-gate list. Condition (ii)
  #            is what removes it. STATED AS ONE CONDITION, AS IT WAS WHEN drain-3 WROTE IT,
  #            THE RULE WAS CORRECT ONLY BECAUSE `covered` OMITTED GATE 16 — the entry for
  #            16 added above would have falsified it on the same commit that completed the
  #            list. That is the hazard of deriving a rule over a population nobody has
  #            checked is complete, and it is a different failure from the hand-list this
  #            bullet was written to replace: the MEMBERSHIP it produced was right, the
  #            REASON was not, and no gate reads either. GATE 13 meets the stated
  #            criterion verbatim and its own body says so: "ASSERT ON OUTPUT, never on rc:
  #            GATE 13 is report-only and returns 0 by design", and each of its four legs
  #            greps G13OUT for content. NOTHING WENT RED, because the sentence's CLAIM
  #            stayed true of the three it named — only its MEMBERSHIP was wrong, and no
  #            gate reads membership.
  #            WHY IT SURVIVED, and it is the reason this bullet states rules and not lists:
  #            round 17's drain-1 found it by eye and could not adjudicate it; drain-2 then
  #            deferred it on a reading of the `covered` list taken over a window that
  #            stopped before that list ends, which made `covered` appear to omit 9, 10a/10b
  #            and 13 when in fact it names all four. A TRUNCATED READ OF A LIST IS
  #            INDISTINGUISHABLE FROM A SHORT LIST. Only re-deriving the population
  #            separated them; re-reading either text would not have.
  #            WHAT THIS DOES NOT SETTLE, stated rather than left to be discovered. The
  #            derivation keys on a label spelled "GATE <n> " at an assert_ call, so a helper
  #            leg labelled any other way would read as inline and be wrongly admitted here.
  #            And the inline-leg parenthetical above was STILL A HAND-LIST: gates that mix
  #            helper and inline legs — 4b, 10, 15 and 17 among those named in `covered` —
  #            contribute gate-labelled inline legs that it does not name, so adding 13
  #            corrected the membership of THIS group only. [Q-475, 2026-09-26: the
  #            parenthetical is now the literal-label RULE and its derivation command, which
  #            returns the gate-labelled inline legs as well.] NO GATE ENFORCES ANY OF THIS; it
  #            is documentation.
  #            AS OF 2026-08-02 (item A1's residue, round 8) THIS LIST IS EVERY ASSERTION IN
  #            THE HARNESS: the last exit-code-only helper, assert_stays_clean, became
  #            assert_stays_clean_why and its negative controls each carry an evidence-ERE
  #            measured under their own mutation. THE STRENGTH TALLY IS NOT RESTATED HERE and
  #            the count of callers is not either — see assert_stays_clean_why's own header for
  #            the tally, and the machine-read `callers=N` on its row in
  #            DOC_GATE_SELFTEST_INSTRUMENTS.txt for the count. This sentence used to carry both
  #            ("only ONE of the six ... two ... three pin only that the leg ran") and round 9
  #            item B9 falsified every number in it in one commit (4e7fb94): four are now
  #            measured discriminators, three pin a count the control's own defect would move,
  #            and NONE pins only that the leg ran. Round 9 item B2 then marked the TOTAL stale
  #            here but left the 1/2/3 breakdown standing, so this file stated two contradictory
  #            tallies until the ledger unit read both. Strength is recorded AT EACH CALL SITE,
  #            because "they all assert WHY" would otherwise read as equal proofs; a second copy
  #            of the distribution in this inventory is a copy that nothing reads and nothing
  #            updates. That is caveat (4)'s class applied to this comment itself.
  #   plus 1 PROBE beside the GATE 3b control (round 8 drain-3) that exercises the FAILING
  #            direction of assert_stays_clean_why — the only leg here expected to fail, run in
  #            a command substitution so its PASS=1 cannot escape, and asserted on the evidence
  #            branch's own sentence rather than on [FAIL], which the rc branch also prints.
  #   NOW COVERED (item A3, 2026-08-02), and this entry is left in place rather than deleted
  #            because the reason it was uncovered is the useful part. It read: "Injecting a
  #            flag would mutate solve.py, a costlier revert than the assurance is worth."
  #            That was never measured. The revert is the same `git checkout -- .` the A1
  #            legs already use to restore an `os.remove`d sat.py, so the cost was identical
  #            to every other case in this file and the only real leg of a gate that has
  #            FIRED IN ANGER (13 undocumented flags, 2026-07/08) went unproven for a round
  #            behind an inherited cost claim. The assertions now, NAMED rather than
  #            tallied: the py extractor, the c extractor, a negative control proving the
  #            comparison is a comparison, and item A4's pair — a LIVE declaration of the
  #            paired flag still reported, and the SAME declaration commented out staying
  #            silent. This sentence said "Three assertions now" until round 14 (item R14)
  #            and named the first three; A4 then landed TWO more in the same GATE 2 bucket
  #            and nothing moved the count. That is the same error as the covered list's
  #            GATE 8 entry and the two in the MISSING-INPUT bullet, both ABOVE — and as the
  #            "asserting WHY" bullet, which round 14's R14 fix did not reach and round 14
  #            drain-3 did. FIVE instances found, one shape, all in this block: a census
  #            bucketed by GATE is blind to a sibling leg joining a bucket, exactly as round
  #            13's pins bullet was blind to a second pin sharing invocation mode `cli`.
  #            (The GATE 8 entry is named by CONTENT here. It was named "`8 x5`" — the value
  #            the same commit replaced — which is the citation half of the identical defect.)
  #   NOT covered, no fire-proof possible here: the TOOL-absence legs (GATE 8's python3,
  #            GATE 11's sha256sum), both converted from [skip] to [FAIL] under A1. Hiding
  #            one tool from $PATH cannot be done without also hiding git, grep and cut, so
  #            the gate would then fail for the wrong reason and the assertion would prove
  #            nothing. Those two legs are warranted by reading, not by running.
  #   NOT covered YET: GATE 18 (alias-reach), added 2026-08-06 on a tree this harness
  #            refuses (uncommitted work; a --selftest run would `git checkout -- .` it
  #            away), so no in-harness leg could be written AND RUN, and an assertion that
  #            has never been run is this file's own definition of rot (GATE 8's defect).
  #            Its two fire-proofs were taken BY HAND at seeding and their transcripts are
  #            in the seeding report: (i) deleting one `open` row from
  #            DOC_GATE_ALIAS_REACH.tsv turns that site into a [FAIL] and rc 1 — the
  #            adjudication mechanism is load-bearing, not decorative; (ii) a row with a
  #            misspelled kind (`alow`) is a [FAIL] and rc 1, not a silent skip. A hand
  #            fire-proof decays (that is GATE 8's lesson), so the debt recorded here is:
  #            first clean-tree --selftest maintenance pass should add legs for (i) and
  #            (ii) plus a NEGATIVE control that a `+`-followed occurrence (C1+C2+C3+C4+C5)
  #            and an `allow literal` row stay silent — the two-sense trap is the leg most
  #            worth pinning, because it is the false-positive mode that kills gates.
  #            THE `attrib` KIND (2026-08-06, same day) took the same three BY HAND, on the
  #            still-uncommitted tree, transcripts in ITS seeding report: (a) the seeded
  #            Zheng Qiao rule with NO adjudication rows fired [FAIL]+rc 1 on all 13 name
  #            sites and passed the one token-carrying line (CITATIONS.md "corrected
  #            2026-07-30") — the attrib [FAIL] wording branch is live; (b) deleting the
  #            SOLVE_C_CLI `open` row re-fired that site; (c) kind `atrib` and allow class
  #            `other-contrib` are each malformed-row [FAIL]s. Registry restored
  #            byte-identical (sha-checked) after each mutation. Same clean-tree debt:
  #            in-harness legs for (a)-(c) plus a negative control that the five
  #            resolution-note/historical allow rows stay silent.
  #   NOT covered YET, THE REST OF THE TAIL — GATES 19, 21, 23 and 24 (GATE 22 left 2026-09-27, Q-883, PARTLY: its producer rc and population floor only). This bullet
  #            named GATE 18 ALONE until 2026-08-11, which read as "18 is the gap" when it was
  #            only the gap that had been WRITTEN DOWN; six more gates had landed behind it and
  #            joined nothing. MEASURED that day, two ways, because one of them keys on a
  #            spelling: `grep -cE 'assert_[a-z_0-9]+ +"GATE <g> '` over this file returns 0
  #            for each of 18-24, AND `grep -nE '\[ok\] +GATE (1[89]|2[0-4])'` returns no line
  #            at all, so they have no helper leg and no inline-echo leg either. GATE 25 was
  #            the seventh member of that set for one day and is now in `covered` above.
  #            GATES 18 AND 20 LEFT THIS SET 2026-09-03 (item 2477, wave-4 lane A2), and only
  #            PARTLY: what joined the harness is GATE 18's RATCHET (both counters, one case
  #            each) and GATE 20's per-file RECEIPTS plus a heading-keyed negative control.
  #            GATE 18's main alias-reach leg, its whitespace-wrap leg and its `attrib` kind
  #            are still proven only by the by-hand transcripts named in the bullet above, and
  #            GATE 20's two SCANNING legs — heading-form draft markers, and an unchecked box
  #            outside a checklist — have no fire-proof at all. Naming a gate "covered" on the
  #            strength of one leg is the census error this whole block keeps recording, so it
  #            is not done here.
  #            THIS IS A DEBT, NOT A DISPOSITION: no claim is made here that a fire-proof for
  #            any of the five is impossible or unwarranted, only that none exists and that a
  #            green --selftest attests nothing whatever about them.
  # ==========================================================================
  # ITEM 2477 (2026-09-03, wave-4 lane A2) — FIRE-PROOFS FOR THREE LEGS THAT SHIPPED WITH
  # A HAND-TAKEN RED TEST AND NOTHING WIRED INTO THE HARNESS.
  #
  # P74 landed GATE 8 LEG 7, GATE 20's per-file receipts and GATE 18's escalation ratchet on
  # 2026-09-02, each red-tested directly and none of them joined to anything that re-runs. A
  # direct red test is a measurement of one tree at one moment; the note two screens below
  # ("no mutation-test leg AT ALL: GATES 18, 19, 20, ...") is what a green self-test was
  # actually attesting about them, which is nothing. GATE 8's cases are with the other GATE 8
  # cases above, where the regeneration cache is; GATE 18's and GATE 20's are here.
  #
  # NONE OF THESE WERE PROVEN BY RUNNING --selftest. This lane was forbidden to run it (it
  # executes `git checkout -- .` and three other lanes held uncommitted work in the tree), so
  # every injection below was first executed BY HAND against a real tree in a detached scratch
  # worktree — `git worktree add --detach <scratch> HEAD` with the current doc_gates.sh copied
  # in — and the gate's output captured to a FILE and grepped from the file, never through a
  # pipe whose exit status is the pipe's. The measured result of each is quoted at the case.
  # What is NOT claimed: that these cases have run inside a live --selftest. They are written
  # to the harness contract and each has been shown to fire against the same tree the harness
  # would mutate, which is the strongest thing available without running the forbidden command.

  # GATE 18 RATCHET, CASE 1 — THE ESCALATION ITSELF.
  #
  # The ratchet exists because a future genuine [FAIL] could be silenced by ADDING an `open`
  # row, with no correction anywhere and no change in exit status. This case performs exactly
  # that in two steps: plant a NEW use of the ruled alias out of reach of its ruling (a [FAIL]
  # by GATE 18's main leg), then adjudicate it away with a new `open` row. Under the shipped
  # gate that pair exits 0. The ratchet must refuse it.
  #
  # THE EVIDENCE ERE NAMES THE SITE HALF, `2 adjudicated-open SITE\(s\), budget 1`, and not
  # the whole message: this injection moves BOTH counters (a new row that matches is also a
  # new site), so an ERE on the joint text could be satisfied by the row half alone and case 2
  # below would then be proving something case 1 had already covered. MEASURED, one line:
  #   [FAIL] the adjudicated-open backlog GREW: 2 adjudicated-open SITE(s), budget 1;
  #          2 `open` registry ROW(s), budget 1   (budgets 2 -> 1, Q-763)          rc=1
  #
  # ANCHOR-FREE ON THE REGISTRY SIDE: the row is APPENDED, and the planted sentence is its own
  # anchor, so neither half can go stale when the registry gains or loses rows. The planted
  # line is appended to documentation/GUIDE.md, which already carries the alias legitimately
  # (an inline glossary token and an `allow literal` row) — so this case also shows the
  # ratchet firing in a file where the alias is NOT globally forbidden.
  assert_fires_why "GATE 18 ratchet: a new defect silenced by a new open row (the escalation)" \
    alias-reach '2 adjudicated-open SITE\(s\), budget 1' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'Self-test line: the C1+C2+C3 canonical, stated with no path to its ruling.'+chr(10))
r='documentation/DOC_GATE_ALIAS_REACH.tsv'
t=open(r,encoding='utf-8').read().rstrip(chr(10))
assert t.count(chr(9)) > 0, 'anchor moved: the registry is not tab-separated'
open(r,'w',encoding='utf-8').write(t+chr(10)+chr(9).join(['open','documentation/GUIDE.md','C1+C2+C3','stated with no path to its ruling','Self-test escalation row.'])+chr(10))"

  # GATE 18 RATCHET, CASE 2 — THE ROW HALF, ISOLATED.
  #
  # OPEN_ROW_BUDGET is a SEPARATE counter from OPEN_SITE_BUDGET and case 1 cannot prove it,
  # for the reason case 1's own note gives. Isolating it needs a row that adds no site, which
  # sounds impossible — a row that matches is a site — and is not: the gate collects ALL
  # anchors matching a line into `used_open` but appends to `openhits` ONCE per line. So a
  # SECOND anchor keyed to an ALREADY-open line raises the row count while leaving the site
  # count exactly where it was. MEASURED, and note the message carries only one clause:
  #   [FAIL] the adjudicated-open backlog GREW: 2 `open` registry ROW(s), budget 1     rc=1
  #
  # WHY THE ROW HALF IS WORTH ITS OWN CASE: a speculative pre-emptive hatch — a row planted
  # against a defect that has not been written yet — is invisible to the site counter by
  # construction, because it matches nothing on the day it lands. That is the one form of
  # escalation the site budget alone cannot see.
  #
  # THE `backlog GREW: ` PREFIX IN THE ERE IS THE ISOLATION PROOF, not decoration. The two
  # clauses are joined with `; ` in the order SITE-then-ROW, so a message that also moved the
  # site counter reads `GREW: N adjudicated-open SITE(s)...; N \`open\` registry ROW(s)...` and
  # this ERE does NOT match it. Requiring the ROW clause to sit IMMEDIATELY after `GREW: ` is
  # what makes this case fail if it ever stops being isolated — without the prefix it would be
  # satisfied by case 1's output and would be proving nothing case 1 had not already proved.
  #
  # THE SECOND ANCHOR IS DERIVED, NOT WRITTEN: the injection reads the live registry's own
  # first `open` row, opens the file it names, finds the line its anchor sits on, and takes a
  # DIFFERENT substring of that same line. Hardcoding a substring of CRITIQUE.md:137 would be
  # an anchor into adjudicated prose that the #146 fix is expected to rewrite; deriving it
  # means this case survives the row set changing and fails loudly if it cannot build.
  assert_fires_why "GATE 18 ratchet: an extra open row on an already-open line (row budget, isolated)" \
    alias-reach 'backlog GREW: [0-9]+ .open. registry ROW\(s\), budget' \
"r='documentation/DOC_GATE_ALIAS_REACH.tsv'
rows=[l.split(chr(9)) for l in open(r,encoding='utf-8').read().split(chr(10)) if l.startswith('open'+chr(9))]
assert rows, 'anchor moved: the registry carries no open rows'
pick=None
tried=[]
for row in rows:
    f,alias,anchor=row[1],row[2],row[3]
    try:
        hits=[l for l in open(f,encoding='utf-8').read().split(chr(10)) if anchor in l]
    except OSError as e:
        tried.append('%s unreadable' % f); continue
    if len(hits)!=1:
        tried.append('%s: %d line(s) carry the anchor' % (f,len(hits))); continue
    line=hits[0]; i=line.find(anchor)
    rest=(line[:i]+line[i+len(anchor):]).strip()
    post=line[i+len(anchor):].strip(); pre=line[:i].strip(); alt=post[:40] if len(post)>=12 else (pre[-40:] if len(pre)>=12 else '')  # a CONTIGUOUS substring either side of the anchor (Q-763: the rest[-40:] splice was not one when the anchor sits mid-line)
    if alt and alt in line and anchor not in alt and alt!=anchor:
        pick=(f,alias,alt); break
    tried.append('%s: no distinct second substring on the line' % f)
assert pick, 'could not derive a second anchor on any already-open line: ' + '; '.join(tried)
f,alias,alt=pick
t=open(r,encoding='utf-8').read().rstrip(chr(10))
open(r,'w',encoding='utf-8').write(t+chr(10)+chr(9).join(['open',f,alias,alt,'Self-test second anchor on an already-open line.'])+chr(10))"

  # GATE 20 RECEIPTS — A CORPUS FILE THE SCANNER CANNOT READ.
  #
  # THE DEFECT THE RECEIPTS CLOSE, quoted from GATE 20's own header: an `awk` that cannot run
  # "produces NO output, and no output was read as no unchecked boxes" — measured with a shim
  # awk exiting 127, which made the gate print "[ok] ... every unchecked box sits under a
  # reader checklist" and exit 0. The fix was a positive per-file receipt. Nothing proved the
  # receipt could fail.
  #
  # WHY THIS IS HAND-ROLLED AND NOT AN assert_fires_why CALL. The natural injection —
  # `chmod 000` on a corpus file — is NOT reverted by `_selftest_revert`. git records only the
  # executable bit, so a 000 file whose content is unchanged is not a modification git can see
  # and `git checkout -- .` leaves it unreadable. Routed through the helper, this case would
  # poison every later assertion in the run with an unreadable GUIDE.md. So the mode is
  # restored HERE, on every path including the could-not-inject path, before anything else
  # runs. (The obvious alternative, deleting the file, does NOT reach this leg: the tracked-md
  # PREFLIGHT catches a missing corpus file first and returns before GATE 20's scanner is
  # entered — measured, rc 1 with the preflight's wording and no GATE 20 line at all. Same for
  # replacing the file with a directory. Unreadable-but-present is the only shape that reaches
  # the receipt.)
  #
  # MEASURED (uid 1000, so mode 000 genuinely denies read):
  #   == GATE 20: no live pre-publish / draft markers in the published corpus ==
  #     [FAIL] GATE 20's per-file scanner FAILED on:
  #              documentation/GUIDE.md
  #            Those files were NOT scanned, so this gate cannot report them clean.   rc=1
  #
  # THE ROOT CAVEAT, stated rather than discovered later: run as uid 0, chmod 000 denies
  # nothing and awk reads the file fine. This case would then find no defect and report
  # [FAIL] — the honest direction — rather than passing vacuously.
  # THE ORIGINAL MODE IS READ BACK, NOT ASSUMED. A first cut restored 644 unconditionally and
  # silently dropped the group-write bit from a 664 file. git records neither bit, so nothing
  # would ever have reported it — a fire-proof quietly editing the tree it is supposed to leave
  # alone, which is the same class as `_selftest_revert` not reaching this case at all.
  _G20_VICTIM=documentation/GUIDE.md
  _G20_MODE=$(stat -c %a "$_G20_VICTIM" 2>/dev/null)
  if [ -n "$_G20_MODE" ] && [ -r "$_G20_VICTIM" ] && chmod 000 "$_G20_VICTIM" 2>/dev/null; then
    G20OUT=$(bash "$0" publication-state 2>&1); G20RC=$?
    chmod "$_G20_MODE" "$_G20_VICTIM"
    if [ "$G20RC" -eq 1 ] && grep -qF "GATE 20's per-file scanner FAILED on" <<<"$G20OUT"; then
      echo "  [ok]   GATE 20 receipts — a corpus file the scanner could not read is a FAIL, not a clean scan"
    else
      echo "  [FAIL] GATE 20 receipts — an unreadable corpus file did NOT stop the gate reporting"
      echo "         clean (rc=$G20RC). That is the fail-open shape the per-file receipt was"
      echo "         added for. If this box runs as root, chmod denies nothing and this case"
      echo "         cannot inject — which is still a failure to prove, never a pass."
      printf '%s\n' "$G20OUT" | head -3 | sed 's/^/           > /'
      PASS=1
    fi
  else
    [ -n "$_G20_MODE" ] && chmod "$_G20_MODE" "$_G20_VICTIM" 2>/dev/null
    echo "  [FAIL] GATE 20 receipts — could not inject (chmod refused, $_G20_VICTIM moved, or"
    echo "         its mode could not be read back for restoration),"
    echo "         so the assertion did NOT run. A skipped fire-proof is not a proof."
    PASS=1
  fi

  # GATE 20 RECEIPTS — NEGATIVE CONTROL, and it is the half that makes the count mean
  # something. The case above proves a receipt can be MISSING. It does not prove the receipt
  # count is the CORPUS count rather than some smaller number the scanner happens to reach; a
  # gate that stamped one receipt and compared it to one would pass both.
  #
  # The control appends an unchecked box UNDER a heading containing "checklist" — legitimate
  # reader-facing content, which GATE 20 must stay silent about — and requires the [ok] line
  # to name a scanned count EQUAL to the base run's. RELATIVE, not absolute, per GATE 12's
  # converted control: the corpus grows, and an absolute census pinned in a fire-proof breaks
  # on a schedule (that comment's own reconstruction of 158 -> 172 -> 175 is the argument).
  # The count must NOT move here, since the mutation adds a line to an existing file and no
  # file to the corpus — so a run that scanned fewer files is RED even though it found nothing.
  _G20_BASE=$(bash "$0" publication-state 2>&1)
  _G20_N=$(printf '%s' "$_G20_BASE" | grep -oE 'in all [0-9]+ scanned corpus file' | grep -oE '[0-9]+')
  if [ -z "$_G20_N" ]; then
    echo "  [FAIL] GATE 20 negative control — the base run printed no scanned-file census, so"
    echo "         the control has no base to compare against. A leg that cannot read its own"
    echo "         base is silent, not clean."
    PASS=1; _G20_N=-1
  fi
  assert_stays_clean_why "GATE 20 an unchecked box under a reader checklist heading is exempt (heading-keyed)" \
    publication-state 'every unchecked box in all '"$_G20_N"' scanned corpus file\(s\) sits under a reader checklist' \
"p='documentation/GUIDE.md'
s=open(p,encoding='utf-8').read()
open(p,'w',encoding='utf-8').write(s+chr(10)+'## Self-test reader checklist'+chr(10)+chr(10)+'- [ ] a reader-facing unchecked box, which is exempt by heading.'+chr(10))"

  # GATE 22 PRODUCER RECEIPT AND FLOOR (Q-883, 2026-09-27, lane HAG; Fable E4 FIX-1).
  #
  # THE DEFECT. GATE 22's token population came from `git grep ... 2>/dev/null > hits || true`.
  # Fable E4 put a `git` on PATH that passed every subcommand through except `grep` (exit 2):
  # the gate printed `[ok] 0 truncated hex token(s)` and DOC GATES: PASS, rc 0, while the 129
  # truncated sha citations it exists to check went unexamined. The fix captures the producer's
  # rc (>= 2 is a FAIL naming the producer), prints GATE22_HEX_TOKENS=N, and fails below a floor.
  #
  # HAND-ROLLED, NOT assert_fires_why, because the injection is a PATH shim, not a file
  # mutation: nothing in the tree changes, so there is nothing for _selftest_revert to undo.
  # THE SHIM REFUSES ONLY THE POPULATION GREP, keyed on its exact pattern argument. A shim that
  # refused every `git grep` would also empty GATE 22's UNIVERSE, whose own empty-universe
  # [FAIL] would then answer instead — the assertion could not tell which check fired. The
  # shim touches a marker file when it acts, and each case first asserts the marker exists:
  # a shim that PATH never reached proves nothing (precondition, not assumption).
  #   CASE 1 (baseline): unshimmed, rc 0, a GATE22_HEX_TOKENS receipt at or above the floor
  #          and the [ok] line carrying the same count.
  #   CASE 2 (producer fails): the population grep exits 2 -> rc non-zero and the [FAIL] names
  #          the producer. Kills the mutant that restores `|| true`.
  #   CASE 3 (population collapses): the population grep succeeds but returns 3 lines -> rc
  #          non-zero, the receipt reads below the floor, and the floor [FAIL] is printed.
  #          Kills the mutant that drops the floor.
  _G22_GIT=$(command -v git); _G22_D=$(mktemp -d 2>/dev/null)
  if [ -n "$_G22_GIT" ] && [ -n "$_G22_D" ] && [ -d "$_G22_D" ]; then
    cat > "$_G22_D/git" <<G22SHIM
#!/usr/bin/env bash
for a in "\$@"; do
  if [ "\$a" = '[0-9a-fA-F]+(…|\\.\\.\\.)' ]; then
    touch "$_G22_D/acted"
    if [ "\${G22_SHIM_MODE:-}" = fail ]; then echo "g22 shim: git grep refused" >&2; exit 2; fi
    "$_G22_GIT" "\$@" | head -n 3; exit 0
  fi
done
exec "$_G22_GIT" "\$@"
G22SHIM
    chmod +x "$_G22_D/git"
    _G22_OUT=$(bash "$0" hex-prefix 2>&1); _G22_RC=$?
    _G22_N=$(grep -oxE 'GATE22_HEX_TOKENS=[0-9]+' <<<"$_G22_OUT" | cut -d= -f2)
    if [ "$_G22_RC" -eq 0 ] && [ -n "$_G22_N" ] && [ "$_G22_N" -ge 100 ] \
       && grep -qE "\[ok\] $_G22_N truncated hex token\(s\)" <<<"$_G22_OUT"; then
      echo "  [ok]   GATE 22 producer baseline — rc 0, GATE22_HEX_TOKENS=$_G22_N at or above the floor 100"
    else
      echo "  [FAIL] GATE 22 producer baseline — the unshimmed run did not give rc 0 with a receipt"
      echo "         at or above 100 and a matching [ok] line (rc=$_G22_RC, receipt='$_G22_N'). Every"
      echo "         case below compares against this one, so none of them can run."
      PASS=1
    fi
    rm -f "$_G22_D/acted"
    _G22_OUT=$(G22_SHIM_MODE=fail PATH="$_G22_D:$PATH" bash "$0" hex-prefix 2>&1); _G22_RC=$?
    if [ ! -e "$_G22_D/acted" ]; then
      echo "  [FAIL] GATE 22 producer fails — the PATH shim was never reached, so nothing was injected."
      PASS=1
    elif [ "$_G22_RC" -eq 1 ] && grep -qE 'GATE 22: the token producer \(git grep over tracked \*\.md\) failed rc 2' <<<"$_G22_OUT"; then
      echo "  [ok]   GATE 22 producer fails — a population grep exiting 2 is a FAIL naming the producer"
    else
      echo "  [FAIL] GATE 22 producer fails — a population grep that exited 2 did not produce a"
      echo "         FAIL naming the producer (rc=$_G22_RC). That is the Q-883 fail-open shape."
      printf '%s\n' "$_G22_OUT" | grep -E 'GATE 22|GATE22_' | head -3 | sed 's/^/           > /'
      PASS=1
    fi
    rm -f "$_G22_D/acted"
    _G22_OUT=$(G22_SHIM_MODE=short PATH="$_G22_D:$PATH" bash "$0" hex-prefix 2>&1); _G22_RC=$?
    _G22_M=$(grep -oxE 'GATE22_HEX_TOKENS=[0-9]+' <<<"$_G22_OUT" | cut -d= -f2)
    if [ ! -e "$_G22_D/acted" ]; then
      echo "  [FAIL] GATE 22 population floor — the PATH shim was never reached, so nothing was injected."
      PASS=1
    elif [ "$_G22_RC" -eq 1 ] && [ -n "$_G22_M" ] && [ "$_G22_M" -lt 100 ] \
         && grep -qE "GATE 22: only $_G22_M truncated hex token\(s\) measured, below the population floor 100" <<<"$_G22_OUT"; then
      echo "  [ok]   GATE 22 population floor — a population of $_G22_M token(s) is a FAIL below the floor 100"
    else
      echo "  [FAIL] GATE 22 population floor — a population collapsed to 3 grep lines did not"
      echo "         FAIL at the floor (rc=$_G22_RC, receipt='$_G22_M')."
      printf '%s\n' "$_G22_OUT" | grep -E 'GATE 22|GATE22_' | head -3 | sed 's/^/           > /'
      PASS=1
    fi
    rm -rf "$_G22_D"
  else
    [ -n "$_G22_D" ] && rm -rf "$_G22_D"
    echo "  [FAIL] GATE 22 producer — could not build the git shim (no git on PATH or mktemp failed),"
    echo "         so the assertion did NOT run. A skipped fire-proof is not a proof."
    PASS=1
  fi

  # The old note said GATE 8 was excluded because ~90s regeneration "exceeds the
  # orchestrator's budget". MEASURED 2026-08-02 on the orchestrator: 45 s and 31 MB peak
  # RSS per run. The budget claim was inherited, not measured, and it was wrong; the
  # shared cache makes the marginal case free regardless.
  echo "  [note] not mutation-tested: the two tool-absence legs (GATE 8's python3, GATE 11's"
  echo "         sha256sum), which cannot be isolated from \$PATH without breaking the gate"
  echo "         for an unrelated reason. GATE 2's flag-drift classifier LEFT this list on"
  echo "         2026-08-02 (item A3) — both extractors, a negative control, and item A4's"
  echo "         live/commented declaration pair. Named, not counted: this line carried a"
  echo "         count that item A4 falsified without moving it (round 14, item R14)."
  # PRINTED, not only commented, for the reason the PASS banner's own exclusions are printed:
  # a gap recorded in a comment is invisible to the person reading a green run. GATE 25 LEFT
  # this line on 2026-08-11 when its two legs landed; the rest of the tail is still on it.
  echo "  [note] no mutation-test leg AT ALL: GATES 19, 21, 23, 24. A green"
  echo "         SELF-TEST attests nothing about them — they are dispatched and run, but"
  echo "         nothing here has ever proven any of them CAN fail."
  # GATES 18 and 20 came off the line above on 2026-09-03 (item 2477) and are printed
  # SEPARATELY rather than silently dropped, because what they gained is one leg each and
  # the difference between "has a fire-proof" and "is fire-proofed" is the census error the
  # comment block above this note exists to record.
  echo "  [note] PARTIALLY mutation-tested: GATE 18 (the escalation RATCHET only — both"
  echo "         counters; its main alias-reach leg, its hard-wrap leg and the \`attrib\` kind"
  echo "         are proven only by by-hand transcripts) and GATE 20 (the per-file RECEIPTS"
  echo "         only; neither of its two SCANNING legs has ever been shown to fire) and GATE 22 (its token PRODUCER's rc and population FLOOR only, Q-883; its NEAR and UNRESOLVABLE legs have never been shown to fire)."

  _selftest_revert
  echo
  [ "$PASS" -eq 0 ] && echo "DOC GATES SELF-TEST: PASS" || echo "DOC GATES SELF-TEST: FAIL"
  # Q-702 (2026-09-24, Fable K): a bare KEY=value verdict for `grep -qx`, so a pre-push leg can
  # read the outcome without parsing the banner. Both lines are printed; the token is the contract.
  [ "$PASS" -eq 0 ] && echo "DOC_GATES_SELFTEST=PASS" || echo "DOC_GATES_SELFTEST=FAIL"
  exit "$PASS"
fi

. scripts/doc_gates.d/40_generated_appendonly_ledger_regdupes.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/40_generated_appendonly_ledger_regdupes.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/50_instruments_collisions.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/50_instruments_collisions.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/60_scoreboard_alias_reach.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/60_scoreboard_alias_reach.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
MODE="${1:-all}"

# ITEM R15 (round 14) — A CONCURRENT --selftest MAKES THIS RUN'S VERDICT MEANINGLESS, AND
# UNTIL NOW NOTHING SAID SO.
#
# The mutual-exclusion lock taken in the --selftest branch above refuses A SECOND --selftest
# and nothing else. Both the clean-tree check and the `mkdir` lock sit INSIDE that branch, so
# a plain `all` / `generated` / single-gate run started while a self-test holds the lock was
# not refused, not warned, and read a tree the self-test was actively mutating. REPRODUCED,
# NOT THEORISED: `generated` run against a live --selftest returned "DOC GATES: FINDINGS (see
# above)"; run serially the same command returns rc=0 and "DOC GATES: PASS (generated)".
# The lock's own refusal text already names the worse direction — "any uncommitted edit made
# meanwhile is discarded" — because `git checkout -- .` does not care who wrote the edit. The
# guard did not reach the case that produces its own stated harm.
#
# ADVISORY, NOT REFUSAL, DELIBERATELY. It prints and returns; it does not touch RC and does
# not stop the run. Whether this should instead be a hard refusal is an OPERATOR call (it
# would make one unit's self-test able to block another unit's gate run outright), and this
# change does not pre-empt it. It prints to stdout, not stderr, so the note travels with the
# verdict line it discredits rather than being lost by a `>log` that keeps only stdout.
#
# WHY DESCENDANTS ARE SUPPRESSED — the part R15's own write-up did not specify, and the
# reason the first attempt at this was worked and deliberately NOT shipped. The --selftest
# runs the gates by re-invoking this script (`bash "$0" <gate>`), and most of those nested
# runs have their output CAPTURED and grepped by an assertion. The parent holds the lock for
# its whole run, so an unconditional advisory would print into every one of those captures
# and fail assertions that have nothing to do with concurrency. The suppression key is
# DOC_GATES_SELFTEST_DEPTH, exported by the --selftest branch above and inherited by every
# descendant process: SET means "I am part of the run that holds the lock"; UNSET means "I am
# independent", which is exactly the case this note exists for. (The three nested runs that
# `cd` into a COPIED repo are safe twice over — they inherit the marker AND their git-dir
# resolves elsewhere, so the lock path does not exist for them.)
#
# COUPLING, STATED RATHER THAN LEFT TO CARE: reusing the depth guard's variable means that
# deleting or renaming DOC_GATES_SELFTEST_DEPTH silently switches this suppression off. That
# is not defended by a comment — the fire-proof labelled "R15 concurrency advisory" in the
# --selftest region has a NEGATIVE control that fails the moment a descendant starts printing
# the note, and it runs on every self-test rather than once by hand. A guard whose fire-proof
# is taken by hand and never re-run after a refactor is GATE 8's defect; this one cannot decay
# that way because it is re-proven in-harness, in both directions, every run.
doc_gates_concurrency_advisory() {
  if [ -n "${DOC_GATES_SELFTEST_DEPTH:-}" ]; then return 0; fi
  local lock holder
  lock="$(git rev-parse --git-dir 2>/dev/null || echo .git)/doc_gates_selftest.lock"
  if [ ! -d "$lock" ]; then return 0; fi
  holder="$(cat "$lock/pid" 2>/dev/null || true)"
  case "$holder" in ''|*[!0-9]*) return 0 ;; esac
  if ! kill -0 "$holder" 2>/dev/null; then return 0; fi
  echo "  [note] DO NOT TRUST THIS VERDICT — a doc_gates --selftest (pid $holder) is running."
  echo "         WHY THIS FIRED: $lock exists, its pid file"
  echo "         names a LIVE process, and this run is not a descendant of it"
  echo "         (DOC_GATES_SELFTEST_DEPTH is unset). That self-test mutates tracked files and"
  echo "         reverts them with 'git checkout -- .', so whatever is reported below is about"
  echo "         a tree in mid-mutation, and any uncommitted edit of yours may be discarded."
  echo "         Advisory only: the gates still run and RC is unchanged. Re-run serially."
}
doc_gates_concurrency_advisory

# ITEM A1, hole (b) — runs for EVERY mode, including the single-gate invocations the
# self-test uses. Deliberately does NOT short-circuit: RC is set and the requested gate still
# runs, so a per-gate fire-proof can distinguish its own leg's message ("<f> is tracked in git
# but missing from the working tree") from this one ("tracked markdown missing from the
# working tree: <f>"). Placed after the --selftest block above, which exits before reaching it.
preflight_tracked_docs || RC=1
# ITEM A6: same placement and the same non-short-circuiting contract, for the same reason —
# GATE 11's own final-newline leg must still be able to fire and be told apart from this one.
# The two messages differ: this one names the file and says "does not end with a newline"
# via require_final_newline; GATE 11's names the registry AND the figure it dropped.
preflight_support_newlines || RC=1

. scripts/doc_gates.d/70_publication_surfaces.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/70_publication_surfaces.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/80_repro_reach_claim_shapes.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/80_repro_reach_claim_shapes.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/90_claim_artifacts.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/90_claim_artifacts.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/95_derived_figures_scope.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/95_derived_figures_scope.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/97_atlas_probe_tokens.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/97_atlas_probe_tokens.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/98_history_index.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/98_history_index.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/99_claim_ledger.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/99_claim_ledger.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/99_lsd_text.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/99_lsd_text.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/99_retract_derived.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/99_retract_derived.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/96_transcripts.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/96_transcripts.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/md_normalise.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/md_normalise.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/word_match.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/word_match.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
. scripts/doc_gates.d/src_parse.sh || { echo "doc_gates.sh: cannot load scripts/doc_gates.d/src_parse.sh -- NOTHING was checked." >&2; exit 2; }  # DG-MODULE
case "$MODE" in
  author-directives) gate_author_directives || RC=1 ;;
  npath) gate_npath || RC=1 ;;
  mi-disambig) gate_mi_disambig || RC=1 ;;
  cell-space) gate_cell_space || RC=1 ;;
  band-status) gate_band_status || RC=1 ;;
  anchor-coverage) gate_anchor_coverage || RC=1 ;;
  report-verdict) gate_report_verdict || RC=1 ;;
  net-brackets) gate_net_brackets || RC=1 ;;
  history-scope) gate_history_scope || RC=1 ;;
  code-needles) gate_code_needles || RC=1 ;;
  sha-prediction) gate_sha_prediction || RC=1 ;;
  parity-figures) gate_parity_figures || RC=1 ;;
  file-drawer) gate_file_drawer || RC=1 ;;
  seed-provenance) gate_seed_provenance || RC=1 ;;
  unrepeatable-cite) gate_unrepeatable_cite || RC=1 ;;
  branch-list) gate_branch_list || RC=1 ;;
  index-fidelity) gate_index_fidelity || RC=1 ;;
  sha-tuple) gate_sha_tuple || RC=1 ;;
  log-derived-figures) gate_log_derived_figures || RC=1 ;;
  nontrivial-display) gate_nontrivial_display || RC=1 ;;
  witness-count) gate_witness_count || RC=1 ;;
  baseline-arithmetic) gate_baseline_arithmetic || RC=1 ;;
  derived-coefficient) gate_derived_coefficient || RC=1 ;;
  cpu-vendor) gate_cpu_vendor || RC=1 ;;
  az-name-closure) gate_az_name_closure || RC=1 ;;
  glossary-consistency) gate_glossary_consistency || RC=1 ;;
  identifying-set-arity) gate_identifying_set_arity || RC=1 ;;
  stdlib-claims) gate_stdlib_claims || RC=1 ;;
  lean-header-verbatim) gate_lean_header_verbatim || RC=1 ;;
  evidence-type-vocabulary) gate_evidence_type_vocabulary || RC=1 ;;
  theorem-vs-slice) gate_theorem_vs_slice || RC=1 ;;
  chronology-access) gate_chronology_access || RC=1 ;;
  layer-profile) gate_layer_profile || RC=1 ;;
  arrivals-sync) gate_arrivals_sync || RC=1 ;;
  scorecard-repro) gate_scorecard_repro || RC=1 ;;
  scorecard-attribution) gate_scorecard_attribution || RC=1 ;;

  summary-scope) gate_summary_scope || RC=1 ;;
  boundary-scope) gate_boundary_scope || RC=1 ;;
  merge-semantics) gate_merge_semantics || RC=1 ;;
  rec-scope) gate_rec_scope || RC=1 ;;
  p14-claims) gate_p14_claims || RC=1 ;;
  dvd24-scope) gate_dvd24_scope || RC=1 ;;
  se-vs-ci) gate_se_vs_ci || RC=1 ;;
  rotation-c3) gate_rotation_c3 || RC=1 ;;
  sk-gains) gate_sk_gains || RC=1 ;;
  fiber-anchor) gate_fiber_anchor || RC=1 ;;
  superlative) gate_superlative || RC=1 ;;
  printed-quotient) gate_printed_quotient || RC=1 ;;
  stale-status) gate_stale_status || RC=1 ;;
  framing-era) gate_framing_era || RC=1 ;;
  repro-reach) gate_repro_reach || RC=1 ;;
  canonical-ceiling) gate_canonical_ceiling || RC=1 ;;
  withdrawn-markers) gate_withdrawn_markers || RC=1 ;;
  value-domains) gate_value_domains || RC=1 ;;
  hex-prefix) gate_hex_prefix || RC=1 ;;
  tracked-ignored) gate_tracked_ignored || RC=1 ;;
  script-paths) gate_script_paths || RC=1 ;;
  publication-state) gate_publication_state || RC=1 ;;
  branch-registry) gate_branch_registry || RC=1 ;;
  numbers) gate_numbers || RC=1 ;;
  cli)     gate_cli     || RC=1 ;;
  citation-lines) gate_citation_lines || RC=1 ;;
  retract) gate_retract || RC=1 ;;
  retract-figures) gate_retract_figures || RC=1 ;;
  links)   gate_links_and_secrefs || RC=1 ;;
  # LEAF DISPATCH NAME (item B2, round 9, 2026-08-02) — the FIFTH hand application of this
  # one fix, and the last one that was live. `links` is gate_links_and_secrefs, i.e. GATE 4
  # AND GATE 4b behind a single exit code; the "GATE 4 internal links" fire-proof ran on it
  # and was argued safe because its evidence-ERE is GATE 4's own line. That argument was
  # correct and it was also the only thing holding the assertion to GATE 4 — reword either
  # gate and it stops holding, silently. GATE 16 LEG 2 below now REFUSES a fire-proof on a
  # combined dispatch name outright, which is only possible because this name exists.
  links-internal) gate_links || RC=1 ;;
  secrefs) gate_secrefs || RC=1 ;;
  status)  gate_status  || RC=1 ;;
  figures) gate_figures || RC=1 ;;
  liveness) gate_liveness || RC=1 ;;
  banner)  gate_banner   || RC=1 ;;
  generated) gate_generated || RC=1 ;;
  appendonly) gate_appendonly || RC=1 ;;
  appendonly-head)    gate_appendonly_head    || RC=1 ;;
  appendonly-history) gate_appendonly_history || RC=1 ;;
  ledger)  gate_ledger  || RC=1 ;;
  ledger-figures) gate_ledger_figures || RC=1 ;;
  # LEAF DISPATCH NAME (item B2, round 9, 2026-08-02). `ledger` runs BOTH halves, so an
  # assertion written against it cannot say which half answered — measured live at
  # "GATE 11 (A1) ledger deleted", whose ERE `CORRECTIONS.md is tracked in git but
  # missing` is emitted by gate_ledger_phrases AND by gate_ledger_figures, both of which
  # require_tracked the same ledger. This is the fourth hand application of one fix:
  # GATE 10a/10b, GATE 4/4b and GATE 11-figures each got a leaf name for the same reason.
  ledger-phrases) gate_ledger_phrases || RC=1 ;;
  revhist) gate_revhist || RC=1 ;;
  revrows) gate_revrows || RC=1 ;;
  regdupes) gate_registry_dupes || RC=1 ;;
  instruments) gate_selftest_instruments || RC=1 ;;
  collisions) gate_preflight_collisions || RC=1 ;;
  scoreboard) gate_scoreboard_verdicts || RC=1 ;;
  alias-reach) gate_alias_reach || RC=1 ;;
  scratch-examples) gate_scratch_examples || RC=1 ;;
  tree-invariants) gate_tree_invariants || RC=1 ;;
  quotient-frame-isolation) gate_quotient_frame_isolation || RC=1 ;;
  dispatch-alignment) gate_dispatch_alignment || RC=1 ;;
  env-surface) gate_env_surface || RC=1 ;;
  emitted-surface) gate_emitted_surface || RC=1 ;;
  completion-semantics) gate_completion_semantics || RC=1 ;;
  prereg-escrow) gate_prereg_escrow || RC=1 ;;
  viz-shape) gate_viz_shape || RC=1 ;;
  separates-census) gate_separates_census || RC=1 ;;
  cert-inventory) gate_cert_inventory || RC=1 ;;
  atlas-probe-tokens) gate_atlas_probe_tokens || RC=1 ;;
  history-index) gate_history_index || RC=1 ;;
  claim-ledger) gate_claim_ledger || RC=1 ;;
  lsd-text) gate_lsd_text || RC=1 ;;
  retract-derived) gate_retract_derived || RC=1 ;;  # ADVISORY: the function always returns 0 (Q-884 GAP-1)
  transcripts) gate_transcripts || RC=1 ;;
  all)     gate_numbers || RC=1; echo; gate_cli || RC=1
           echo; gate_citation_lines || RC=1; echo; gate_retract || RC=1
           echo; gate_retract_figures || RC=1
           echo; gate_links_and_secrefs || RC=1; echo; gate_status || RC=1
           echo; gate_figures || RC=1
           echo; gate_liveness || RC=1
           echo; gate_banner || RC=1
           echo; gate_appendonly || RC=1
           echo; gate_ledger || RC=1
           echo; gate_revhist || RC=1
           echo; gate_revrows || RC=1
           echo; gate_registry_dupes || RC=1
           echo; gate_selftest_instruments || RC=1
           echo; gate_preflight_collisions || RC=1
           echo; gate_scoreboard_verdicts || RC=1
           echo; gate_alias_reach || RC=1
           echo; gate_branch_registry || RC=1
           echo; gate_publication_state || RC=1
           echo; gate_script_paths || RC=1
           echo; gate_hex_prefix || RC=1
           echo; gate_tracked_ignored || RC=1
           echo; gate_value_domains || RC=1
           echo; gate_scratch_examples || RC=1
           echo; gate_tree_invariants || RC=1
           echo; gate_quotient_frame_isolation || RC=1
           echo; gate_dispatch_alignment || RC=1
           echo; gate_env_surface || RC=1
           echo; gate_completion_semantics || RC=1
           echo; gate_prereg_escrow || RC=1
           echo; gate_separates_census || RC=1
           echo; gate_viz_shape || RC=1
           echo; gate_canonical_ceiling || RC=1
           echo; gate_withdrawn_markers || RC=1
           echo; gate_framing_era || RC=1
           echo; gate_author_directives || RC=1
           echo; gate_rotation_c3 || RC=1
           echo; gate_sk_gains || RC=1
           echo; gate_fiber_anchor || RC=1
           echo; gate_repro_reach || RC=1
           echo; gate_superlative || RC=1
           echo; gate_printed_quotient || RC=1
           echo; gate_stale_status || RC=1
           echo; gate_npath || RC=1
           echo; gate_se_vs_ci || RC=1
           echo; gate_dvd24_scope || RC=1
           echo; gate_p14_claims || RC=1
           echo; gate_mi_disambig || RC=1
           echo; gate_cell_space || RC=1
           echo; gate_band_status || RC=1
           echo; gate_anchor_coverage || RC=1
           echo; gate_report_verdict || RC=1
           echo; gate_net_brackets || RC=1
           echo; gate_history_scope || RC=1
           echo; gate_code_needles || RC=1
           echo; gate_sha_prediction || RC=1
           echo; gate_parity_figures || RC=1
           echo; gate_file_drawer || RC=1
           echo; gate_seed_provenance || RC=1
           echo; gate_unrepeatable_cite || RC=1
           echo; gate_branch_list || RC=1
           echo; gate_index_fidelity || RC=1
           echo; gate_sha_tuple || RC=1
           echo; gate_log_derived_figures || RC=1
           echo; gate_nontrivial_display || RC=1
           echo; gate_witness_count || RC=1
           echo; gate_baseline_arithmetic || RC=1
           echo; gate_derived_coefficient || RC=1
           echo; gate_cpu_vendor || RC=1
           echo; gate_az_name_closure || RC=1
           echo; gate_glossary_consistency || RC=1
           echo; gate_identifying_set_arity || RC=1
           echo; gate_stdlib_claims || RC=1
           echo; gate_lean_header_verbatim || RC=1
           echo; gate_evidence_type_vocabulary || RC=1
           echo; gate_theorem_vs_slice || RC=1
           echo; gate_chronology_access || RC=1
           echo; gate_layer_profile || RC=1
           echo; gate_arrivals_sync || RC=1
           echo; gate_scorecard_repro || RC=1
           echo; gate_scorecard_attribution || RC=1
           echo; gate_summary_scope || RC=1
           echo; gate_boundary_scope || RC=1
           echo; gate_merge_semantics || RC=1
           echo; gate_rec_scope || RC=1
           echo; gate_cert_inventory || RC=1
           echo; gate_atlas_probe_tokens || RC=1
           echo; gate_history_index || RC=1
           echo; gate_claim_ledger || RC=1
           echo; gate_lsd_text || RC=1
           echo; gate_retract_derived || RC=1  # GATE 94, ADVISORY: always returns 0
           echo; gate_transcripts || RC=1  # GATE 95, review-loop Q29 leg I
           # 🔴 GATE 89, added to `all` 2026-09-08. It was deliberately held OUT while its
           # allowance table (documentation/DOC_GATE_EMITTED_SURFACE_OPEN.tsv) was untracked:
           # `all` runs in a detached worktree of the PUSHED sha, and the gate ERRORs without
           # that file, so wiring it early would have broken every push. The table is committed
           # with this change, so the exclusion's stated reason has expired -- and an exclusion
           # that outlives its reason is the defect this repo spent 2026-09-08 removing.
           # Cost measured: ~2.5 s against a suite that already runs ~35 min.
           echo; gate_emitted_surface || RC=1 ;;
  *) echo "usage: $0 {numbers|cli|citation-lines|retract|retract-figures|links|links-internal|secrefs|status|figures|liveness|banner|appendonly|appendonly-head|appendonly-history|ledger|ledger-figures|ledger-phrases|revhist|revrows|regdupes|instruments|collisions|scoreboard|alias-reach|branch-registry|publication-state|script-paths|hex-prefix|tracked-ignored|generated|value-domains|repro-reach|canonical-ceiling|withdrawn-markers|framing-era|author-directives|rotation-c3|sk-gains|fiber-anchor|superlative|printed-quotient|stale-status|npath|se-vs-ci|dvd24-scope|p14-claims|mi-disambig|cell-space|band-status|anchor-coverage|report-verdict|net-brackets|history-scope|code-needles|sha-prediction|parity-figures|file-drawer|seed-provenance|unrepeatable-cite|branch-list|index-fidelity|sha-tuple|log-derived-figures|nontrivial-display|witness-count|baseline-arithmetic|derived-coefficient|cpu-vendor|az-name-closure|glossary-consistency|identifying-set-arity|stdlib-claims|lean-header-verbatim|evidence-type-vocabulary|theorem-vs-slice|chronology-access|layer-profile|arrivals-sync|scorecard-repro|scorecard-attribution|summary-scope|boundary-scope|merge-semantics|rec-scope|cert-inventory|scratch-examples|tree-invariants|quotient-frame-isolation|dispatch-alignment|env-surface|emitted-surface|completion-semantics|prereg-escrow|viz-shape|separates-census|atlas-probe-tokens|history-index|claim-ledger|lsd-text|retract-derived|transcripts|all}"; exit 2 ;;
esac

echo
# State what the banner does NOT attest. The report-only set and the excluded-by-cost set are
# NOT restated here — the banner literal below is the maintained copy, and unlike a comment it
# is EXECUTED, so it cannot drift out of sight. A green banner that covers less than it appears
# to reads as more coverage than it has, which is the over-attestation this suite exists to
# catch. (The self-test's own comment asserted this was "stated in the banner itself" before it
# was; written into the banner 2026-08-01 on same-day re-review.)
#
# TWO STALE HARDCODED CLAIMS WERE REMOVED FROM THIS BLOCK, round 17. Both PRE-EXISTING
# (91129a4e), both of the N-nounfirst class, and the first is a false clear in the DANGEROUS
# direction:
#   * "GATES 1 and 5 are report-only" — the banner below also names 5b, 13 and GATE 17's LEG B.
#     `gate_revrows` ends `sys.exit(0)  # report-only gate — never blocks`, so a reader who
#     trusted this comment would believe a missing revision row fails the build. It does not.
#   * "a green banner that silently covers only 5 of 8 gates" — stale on every counting unit;
#     the two counting commands are in the usage block at the top of this file. Recorded because
#     it bears on what a census is worth: `8 gates` sits INSIDE round 16's declared digit-census
#     pattern (`<digit> <noun>`, with `gates` in its noun list) and survived that round anyway.
#     ROUND 17 SETTLED WHY, by re-running each round-16 query against the tree it actually had
#     rather than reasoning about it:
#       - THE PATTERN IS NOT THE BLIND SPOT. The digit census's declared ERE, run over the
#         WHOLE FILE at 06fa085d^ (drain-2's own open tree), returns 19 rows and this site IS
#         one of them. So word order never excluded it.
#       - THE CORPUS WAS. 17 of those 19 rows are comments, this site among them, and that
#         census swept PRINTED counts.
#       - The comment census had the right corpus and missed it for TWO INDEPENDENT reasons:
#         it requires a SPELLED-OUT numeral, and `gates` is absent from its noun list
#         (`legs|assertions|clauses|controls|proofs`). That reconstruction is fire-proven,
#         not assumed: run verbatim it returns 37, the population drain-1 recorded at round
#         16's close, so it is that round's query and not a new one written to agree.
#     CONSEQUENCE: the uncovered class is not "noun-first". It is the cell COMMENT x
#     DIGIT-FORM, which no round-15/16 query reaches at ANY word order. `N-nounfirst`'s
#     premise was FALSIFIED, not merely narrowed — and the site it was filed from is the one
#     that falsifies it.
#     WHAT THIS CANNOT SEE, stated rather than left to be discovered: drain-2's exact corpus
#     FILTER was never written down — only its noun list was — so "printed counts" is read
#     off its own prose, not reproduced. An echo/print-restricted re-run of the ERE returns
#     0, which does NOT match its reported "only LEG labels", so the filter reconstruction is
#     approximate and a false clear there would be invisible to me. Only the load-bearing
#     half is proven: the PATTERN matches this site in the whole-file corpus, so whatever the
#     filter was, it excluded a line the pattern hits.
if [ "$RC" -ne 0 ]; then
  echo "DOC GATES: FINDINGS (see above)"
elif [ "$MODE" = all ]; then
  echo "DOC GATES: PASS  — hard gates only: 2, 2c, 3, 3b, 4 (incl. 4b), 6, 7, 9, 10 (a+b), 11, 12, 14, 15, 16, 17 (LEG A only), 18 (see the carve-out below), 19, 20, 21, 22 (both legs), 23, 24, 25 (LEG 1 ONLY), 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39 (all four legs), 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59 (see the carve-out below), 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 95. Gates 1, 5 (incl. 5b), 13, 94"
  echo "                   and GATE 17's LEG B (the verdict ledger) are REPORT-ONLY,"
  echo "                   so any [WARN]/[note] above is NOT covered by this verdict."
  # GATE 18's CARVE-OUT, made explicit 2026-09-02 (Codex v2 charge 4). Naming 18 as hard
  # without this line over-attested: its adjudicated-open sites are real DEFECTS and they
  # exit 0 by design, so "hard gate 18 passed" read as "no alias-reach defects" when it
  # means "no UNADJUDICATED ones". The backlog is not hidden — it prints as [OPEN] with a
  # count on every run — but a green banner must not imply it is empty.
  echo "                   GATE 18 IS HARD FOR UNADJUDICATED DEFECTS ONLY. Its [OPEN] rows"
  echo "                   are adjudicated-open DEFECTS that do NOT set this exit code; a"
  echo "                   green verdict means no NEW alias-reach defect, not none at all."
  echo "                   The [OPEN] set is ratcheted (it cannot grow without a budget"
  echo "                   change in this file), so it can no longer absorb a new [FAIL]."
  # GATE 59's CARVE-OUT, same shape as GATE 18's (2026-09-02): its adjudicated-open sites are
  # listed in documentation/DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv, print as [OPEN], and do not
  # set the exit code; an allowance that matches nothing FAILS, so a row cannot outlive its fix.
  echo "                   GATE 59 IS HARD FOR UNADJUDICATED DEFECTS ONLY. Its [OPEN] rows"
  echo "                   (documentation/DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv) are real"
  echo "                   arithmetic defects awaiting a prose-lane fix; a green verdict"
  echo "                   means no NEW one, not none at all."
  # GATE 8's exclusion made LOUD AND SPECIFIC, 2026-08-07 (gate-blind-spot closure #1).
  # The one-liner this replaces ("run it separately") named neither what was uncovered nor
  # the command, so an all-green run read as attesting example/report.pdf (removed
  # 2026-09-04) when it attested
  # nothing about it. DECIDED AGAINST folding GATE 8 into `all`, on measured numbers taken
  # that day: `all` = 17 s, `generated` = 67 s fresh regeneration (107-135 s on prior
  # recorded runs) — a 4-6x multiplier on the suite every blocking pre-push hook run and
  # every ad-hoc invocation pays, for artifacts most changes cannot touch. A hook that
  # slow invites --no-verify, which uncovers EVERYTHING. Instead the publish point is
  # covered conditionally: pre_push_gate.sh runs `generated` on the pushed tree exactly
  # when the pushed range touches roae.py or example/ (fail-closed when it has no base to
  # diff against), which is also the only way a hand-edited artifact committed with
  # `git commit --no-verify` can be on its way out.
  # GATE 24 WAS EXCLUDED UNTIL 2026-09-04 and is now in the hard list above. Until 2026-08-11
  # this banner named only GATE 8's exclusion — so a green `all` read as covering gates it had
  # never run; GATE 24 was then named here, and is now named only in its promotion line below.
  # Both statements are derived from the dispatch arm above, which is the only list.
  # GATE 25 WAS PROMOTED INTO `all` ON 2026-09-02 and is named in the hard list above; it is
  # LEG 1 ONLY, so its report-only half needs a line here for the same reason GATE 17's LEG B
  # and GATE 18's carve-out do. Both statements are derived from the dispatch arm above, which
  # is the only list: `all` calls gate_repro_reach, and since 2026-09-04 gate_value_domains too.
  echo "                   GATE 24 ('value-domains') IS in 'all' since 2026-09-04 and IS"
  echo "                   covered by this verdict. It sat out by caution from 2026-08-09;"
  echo "                   the exclusion was half of Codex A8R item 3 (a stale second"
  echo "                   'supported:' list that a singular re.search could not reach in a"
  echo "                   gate that did not run), so both halves were repaired together."
  echo "                   GATE 25 ('repro-reach') IS in 'all' since 2026-09-02, but its LEG 1"
  echo "                   ONLY — a documented reproduction command must resolve to a real"
  echo "                   flag. Its LEG 2 ([note] lines on figures with no re-derivation"
  echo "                   path) is REPORT-ONLY and is NOT covered by this verdict."
  echo "                   GATE 8 ('generated') is NOT in 'all' — by cost, not oversight."
  echo "                   This verdict attests NOTHING about the 11 tracked example/"
  echo "                   artifacts — the four reports (report.txt/.md/.html, README.md;"
  echo "                   report.pdf was the twelfth until 2026-09-04, when it was removed"
  echo "                   for embedding the DejaVu font programs, taking GATE 8 LEG 5 and"
  echo "                   report.html's only DIGIT check with it — restored the same day by"
  echo "                   reshipping example/ under --seed 20260904, which made legs 1-4"
  echo "                   BYTE-EXACT) AND, since 2026-09-02,"
  echo "                   hexagrams.{csv,json,svg}, wave.dot, wave.dot.png, wave.dot.svg"
  echo "                   and wave.mid (LEG 7, byte-exact):"
  echo "                       bash scripts/doc_gates.sh generated   # checks them; ~67-135 s, 3 roae.py runs"
  echo "                   (Enforced at pre-commit when roae.py/example/ is staged, and at"
  echo "                   pre-push when the pushed range touches roae.py or example/.)"
elif [ "$MODE" = repro-reach ]; then
  # GATE 25 IS TWO LEGS OF DIFFERENT STRENGTH BEHIND ONE VERDICT, so the verdict has to say
  # which one it is. LEG 1 (a documented flag must exist) is hard and sets RC. LEG 2 (a
  # published figure whose file names no way to re-derive it) is REPORT-ONLY by the same
  # argument GATE 24's header makes about scanning prose. That argument used to be stated here
  # as "doc_gates is wired into pre-push as BLOCKING, so a false positive stops a push", which
  # is true of `all` and NOT of this mode — corrected 2026-08-11, with the hook-by-hook
  # verification recorded at LEG 2's definition. TODAY nothing runs `repro-reach` but a person
  # typing it; the blocking argument is about the state after GATE 25 is promoted into `all`,
  # which its own header plans for. It is enumerated HERE rather than in
  # the `all` banner because GATE 25 is not in `all` and never runs there. An unlisted
  # report-only leg reads as covered by the PASS above it, which is the over-attestation
  # this suite exists to catch.
  echo "DOC GATES: PASS  (repro-reach) — LEG 1 ONLY: every documented reproduction command"
  echo "                   resolves to a real flag. GATE 25's LEG 2 is REPORT-ONLY and never"
  echo "                   affects this verdict — its [note] lines above are NOT attested."
elif [ "$MODE" = numbers ] || [ "$MODE" = status ] || [ "$MODE" = revrows ] || [ "$MODE" = retract-derived ]; then
  echo "DOC GATES: PASS  — NOTE: '$MODE' is a REPORT-ONLY gate and always exits 0."
  echo "                   Read its [WARN]/[note] lines above; this verdict does not."
else
  echo "DOC GATES: PASS  ($MODE)"
fi
exit $RC
