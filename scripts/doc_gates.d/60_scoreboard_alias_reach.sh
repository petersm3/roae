#@ scripts/doc_gates.d/60_scoreboard_alias_reach.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATE 17 (scoreboard), GATE 18 (alias-reach).
#@ Lines 11217-11822 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ----------------------------------------------------------------------------------
# GATE 17 — every registry rule reaches the published scoreboard, and its data-like /
# principled verdict is findable AT ITS ROW ID (round-7 brief item 6, 2026-08-02).
#
# WHY THIS EXISTS. Twice now a load-bearing scoreboard row has been carried unclassified
# for weeks and been found only because a human named it:
#   * `d7` — unclassified until 2026-08-01, found because the operator asked about it.
#   * `ccn4` — classified data-like since 2026-07-03, but the verdict was written next to
#     the DESCRIPTION ("Schulz's S25-28 trigram configuration") and never next to the id.
#     TR-1 v1.23 records what that cost: the 2026-08-01 sweep that concluded d7 was "the
#     last unclassified load-bearing row" matched id tokens, could not see the ccn4 verdict,
#     and so carried THE MOST-CITED ROW ON THE BOARD (2x10^-8, the strongest discriminator)
#     as unclassified. The sweep's conclusion was wrong in both directions at once.
# Two instances, one shape: a verdict is findable by description but not by id, and the only
# instrument that has ever looked was a human reading prose. TR-1 v1.23 states the residue in
# prose — "`ccn8` and the remaining SAMPLED rows carry no verdict" — which is honest but is a
# sentence about a sample, written on 2026-08-02, that ages the moment a rule is added.
#
# WHAT IT DOES, and the split between the two halves is the whole design:
#   LEG A (HARD).   Every id in solve.py's REGISTRY_KW_EXPECTED must appear as a row on the
#                   published board in BOTH files that carry it, and no board row may name a
#                   rule the registry does not have. This is mechanical and has one right
#                   answer, so it FAILS.
#   LEG B (REPORT-ONLY). For each id, is a data-like / principled verdict findable within
#                   that id's own board entry? Printed as a per-row ledger with counts. This
#                   does NOT fail: 21 rows carry no verdict today, and whether they need one
#                   is a METHODS judgment routed to the operator (inbox O2), not a gate's
#                   call. A gate that declared two thirds of a published table in violation
#                   would be turned off within the day — the same reasoning that ships
#                   GATE 13 report-only.
#
# WHAT IT CANNOT SEE, said plainly, because a clear from this gate is weaker than a failure:
#   (a) It cannot see a verdict written ANYWHERE BUT the id's own board entry. That is not a
#       limitation to apologise for, it is the measurement: the ccn4 defect WAS a verdict
#       that existed elsewhere. A row this gate calls "silent" may well be classified in
#       prose two paragraphs up. The ledger says "no verdict at the id", never "unclassified".
#   (b) It cannot judge whether a verdict is CORRECT, or whether the dof count behind it is
#       right. reg_d7's verdict was wrong for weeks while being present.
#   (c) "(theorem)" rows are counted in their own bucket, not as classified. Whether a rule
#       that measures at 1.0 of canonical mass — a forced consequence, which discriminates
#       nothing — even admits a data-like/principled verdict is exactly the sort of judgment
#       (c) says this gate does not make.
#
# COST: two file reads and 31 substring searches. Milliseconds; it is in `all`.
gate_scoreboard_verdicts() {
  echo "== GATE 17: every registry rule is on the scoreboard, verdict findable at its id =="
  python3 - <<'PY'
import re, sys
sys.path.insert(0, '.')
try:
    import solve
except Exception as exc:                       # noqa: BLE001 — any import failure is a FAIL
    print("  [FAIL] cannot import solve.py, so ZERO rules were checked: %s" % exc)
    print("         A gate that cannot load its subject has checked nothing.")
    sys.exit(1)

ids = [r for r, _ in solve.REGISTRY_KW_EXPECTED]
# Same vacuity guard as GATE 14, and for the same measured reason: an emptied or renamed
# REGISTRY_KW_EXPECTED otherwise yields "[ok] 0 rules checked" and exit 0.
if not ids:
    print("  [FAIL] REGISTRY_KW_EXPECTED holds no rules, so this gate checked NOTHING")
    sys.exit(1)

# The two files that publish the board. Both must carry every rule: they are hand-maintained
# copies of one table, so a rule added to one and not the other is precisely the drift a
# reader comparing the report against the documentation would hit.
BOARDS = [
    "reports/TR1_EIGHT_CENTURIES_MEASURED.md",
    "documentation/LITERATURE_RULES_POPULATION_TESTS.md",
]
# PHASE-4 ON THIS GATE'S OWN BATCH. Shortening BOARDS to one path was a green run with half
# the check switched off: `len(regions) != len(BOARDS)` still held, the summary printed
# "present on 1 board(s)", and the second published copy silently stopped being compared. The
# count was there to read and nothing required it to be two. This is the same defect the
# suite already recorded once — GATE 16's "one preflight going quiet is a FAIL, not a smaller
# count" — so it gets the same answer rather than a note.
if len(BOARDS) < 2:
    print("  [FAIL] the board list holds %d file(s); leg A exists to compare the REPORT's copy"
          " of the table against the DOCUMENTATION's" % len(BOARDS))
    print("         A single board cannot disagree with anything. Restore the second path.")
    sys.exit(1)

OPEN_ANCHOR = "Full table (fraction of canonical mass"
# The board's FIRST entry (rs1) does not begin a "·"-separated chunk — it follows the
# table's introductory clause on the same run of prose. MEASURED, not anticipated: the
# first live run of this gate reported rs1 missing from BOTH files and reported a phantom
# orphan row "Full", because the opening chunk began "Full table (fraction ...". Both
# findings were defects in this parser, not in the corpus. So the region starts AFTER the
# clause's closing "estimates):", and failing to find it is a FAIL like any moved anchor.
TABLE_ANCHOR = "estimates):"
CLOSE_ANCHOR = "Wrap-distance finals"

bad = 0
regions = {}
for path in BOARDS:
    try:
        text = open(path, encoding="utf-8").read()
    except OSError as exc:
        print("  [FAIL] %s cannot be read, so its board was not checked: %s" % (path, exc))
        bad = 1
        continue
    i = text.find(OPEN_ANCHOR)
    k = text.find(TABLE_ANCHOR, i) if i >= 0 else -1
    j = text.find(CLOSE_ANCHOR, k + 1) if k >= 0 else -1
    # THE ANCHOR-MOVED BRANCH IS THE GATE'S OWN FAILURE MODE, not a corner case. If the
    # prose is rewritten and either anchor moves, a naive scan returns an empty region, every
    # id reads as missing OR (worse, if the scan is written the other way) nothing reads as
    # missing at all, and the run is green with the instrument switched off. Finding no
    # region is therefore a FAIL that names the anchor, exactly as GATE 15's header requires.
    if i < 0 or k < 0 or j < 0:
        print("  [FAIL] %s — the board region could not be located (open anchor %s, table"
              " anchor %s, close anchor %s)"
              % (path, "FOUND" if i >= 0 else "MISSING", "FOUND" if k >= 0 else "MISSING",
                 "FOUND" if j >= 0 else "MISSING"))
        print("         The anchors are prose and prose gets rewritten. Re-point them at the")
        print("         table; do NOT let this gate scan an empty region and report [ok].")
        bad = 1
        continue
    regions[path] = text[k + len(TABLE_ANCHOR):j]

if len(regions) != len(BOARDS):
    sys.exit(1)

# A board entry is "<id> <mass>[ (annotation)]", entries separated by " \xb7 ". Split on the
# separator so an annotation is attributed to the id it follows and to no other -- the whole
# point is that ccn4's verdict must not be credited to ccn3 because they share a line.
ID_AT_START = re.compile(r"^\**([A-Za-z][A-Za-z0-9]*)\b")
# AND AN ENTRY ENDS AT ITS SENTENCE, which is not a refinement but a fix for a defect this
# gate's own NEGATIVE CONTROL caught. The LAST entry on the board has no "·" after it, so it
# ran to the close anchor and swallowed every word in between: leg 5 inserted the sentence
# "These are principled, data-like rows." before "Wrap-distance finals" and `c2` -- a forced
# constant -- was reported as carrying a verdict. The live corpus has nothing in that gap, so
# every positive leg passed and only the control saw it. No board entry contains ". " (masses
# are "6.6×10⁻⁴", decimals are digit.digit), so truncating each chunk at its first sentence
# break bounds the last row without touching any other.
SENTENCE_END = re.compile(r"\.(\s|$)")


# ONE parser, used by BOTH legs. It was written twice in the first draft, which is the
# duplicated-predicate hazard GATE 14 exists for, arriving inside GATE 14's own suite: legs A
# and B would have disagreed about what an entry IS the moment either was touched.
def entries_of(region):
    out = {}
    for chunk in region.split("·"):
        body = chunk.strip()
        m = ID_AT_START.match(body)
        if m:
            cut = SENTENCE_END.search(body)
            out.setdefault(m.group(1), []).append(body[:cut.start()] if cut else body)
    return out


for path, region in sorted(regions.items()):
    entries = entries_of(region)
    missing = [r for r in ids if r not in entries]
    if missing:
        print("  [FAIL] %s — %d registry rule(s) never reach the published board: %s"
              % (path, len(missing), ", ".join(missing)))
        print("         A rule that is measured but not published is invisible to every")
        print("         reader who audits the table instead of the code.")
        bad = 1
    known = set(ids)
    # Wrap-distance finals (d1/d3/d5) are NOT registry rules and are published in the
    # following sentence, outside the close anchor; anything else with a mass on the board
    # and no rule behind it is a row nobody can reproduce.
    orphans = [r for r in sorted(entries) if r not in known]
    if orphans:
        print("  [FAIL] %s — board row(s) with no registry rule behind them: %s"
              % (path, ", ".join(orphans)))
        bad = 1

if bad:
    sys.exit(1)

# LEG B — report-only ledger, printed PER BOARD rather than once. The two files are
# hand-maintained copies, so a verdict added to the report and not to the documentation is a
# real divergence; collapsing them into one ledger would hide exactly that.
VERDICT = re.compile(r"data-like|principled", re.I)
THEOREM = re.compile(r"\(theorem\)")
for path, region in sorted(regions.items()):
    entries = entries_of(region)
    at_id, theorem, silent = [], [], []
    for r in ids:
        blob = " ".join(entries[r])
        if VERDICT.search(blob):
            at_id.append(r)
        elif THEOREM.search(blob):
            theorem.append(r)
        else:
            silent.append(r)
    print("  [note] %s: %d/%d rule(s) carry a verdict at the id (%s)"
          % (path, len(at_id), len(ids), ", ".join(at_id) or "none"))
    print("  [note] %s: %d forced-constant row(s) marked (theorem) — bucket, not a verdict (%s)"
          % (path, len(theorem), ", ".join(theorem) or "none"))
    print("  [note] %s: %d row(s) carry NO verdict at the id (%s)"
          % (path, len(silent), ", ".join(silent) or "none"))
print("  [note] REPORT-ONLY: 'no verdict at the id' is NOT 'unclassified' — this gate cannot")
print("         see a verdict written next to the row's DESCRIPTION, which is exactly how the")
print("         ccn4 verdict hid from the 2026-08-01 sweep. Classifying these rows is a")
print("         METHODS judgment (inbox O2), not a gate change.")
print("  [ok] %d registry rule(s) present on %d board(s); verdict ledger above is report-only"
      % (len(ids), len(regions)))
sys.exit(0)
PY
}

# ----------------------------------------------------------------------------------
# GATE 18 — alias-reach (2026-08-06). The class the ~30-pass review campaign kept
# refinding, mechanised: a correct ruling applied to ONE line while every sibling use
# survives, with nothing to detect the gap.
#
# WHY. Every gate above catches forbidden text PRESENT. The campaign's deepest
# recurring defect is the opposite: required resolution ABSENT. CITATIONS.md item 3
# ruled "C1+C2+C3" legacy naming for the C1–C5 canonical (METHODS §"Legacy shorthand")
# and ruled "exhaustive" → "budgeted" — and at this gate's seeding, line 85 of the SAME
# FILE still carried both uncorrected forms, SOLVE.md stated "the intersection C1+C2+C3
# that solve.c enumerates" (flatly false under the ruling), and none of the documents
# using the aliases linked the note that resolves them. A ruling a reader cannot reach
# from the line that needs it might as well not exist.
#
# THE DETECTION RULE — "within one link", line-granular. For every `rule` row in the
# registry, every occurrence of the alias in every tracked .md must satisfy one of:
#   (1) its own line carries the rule's RESOLUTION TOKEN (a fixed substring only a line
#       narrating or citing the ruling carries — e.g. `Legacy shorthand`), or
#   (2) an explicit content-anchored `allow` row (GATE 3b's (file, alias, anchor) shape;
#       closed class vocabulary: resolution-note / literal / historical / meta-mention), or
#   (3) an `open` row — an ADJUDICATED-OPEN DEFECT, re-printed as [OPEN] every run with
#       a count (DOC_GATE_FIGURE_LEDGER_OPEN.txt's contract: a backlog that cannot go
#       invisible, owned by task #146, not an exemption).
# Anything else is a [FAIL]. File-granular reach ("the ruling is linked somewhere in
# this file") was considered and REJECTED: CITATIONS.md holds the ruling at one line
# and the defect 438 lines above it — the exact gap this gate exists to see.
#
# THE TWO-SENSE TRAP, and why the exemptions are curated rather than automatic.
# "C1+C2+C3" is BOTH the legacy alias for the C1–C5 canonical AND the literal
# three-predicate conjunction ("no null family simultaneously satisfies C1+C2+C3" —
# a true statement about C1, C2, C3 individually that must NOT be "corrected" to
# C1–C5). A gate that demanded corpus-wide replacement would introduce errors; the
# literal occurrences are explicit `allow literal` rows. Structural narrowing is used
# only where it is exact: an occurrence followed by `+` (registry stopchars) is the
# explicit conjunction C1+C2+C3+C4+C5 and is void, and the "exhaustive" rule registers
# the definite-article NAMING form ("the exhaustive enumeration", case-folded) because
# at seeding time that string separated the naming defect from the legitimate
# hypothetical/finite-complete senses ("under true exhaustive enumeration…",
# "exhaustive enumeration of all 2^27") with zero curated rows. Residuals of that
# narrowing (article-less naming uses: TR-11:45, CITATIONS.md:995 at 05a8d815, since removed) are stated in the
# registry header rather than left to be rediscovered.
#
# ORDER OF CHECKS IS LOAD-BEARING: token → open → allow → FAIL. `open` is checked
# BEFORE `allow` so a line carrying both senses (CRITIQUE.md's "Simultaneous C1+C2+C3
# satisfaction…" line: literal first use, alias second use) stays visibly [OPEN] until
# the alias half is fixed — its `allow literal` row takes over only after the open row
# dies. Exemption and adjudication are line-granular (GATE 3b's model); a per-
# occurrence classifier was considered and rejected as over-engineering with no live
# case it would decide differently once the open backlog drains.
#
# WHY-IT-FIRED (#65): every [FAIL] prints the alias, the ruling, where the ruling
# lives, and the line text. Every [OPEN] prints its adjudication. Dead allow/open rows
# are re-printed as [note] every run — the drift audit — so a fixed defect demands its
# row's deletion and a drifted anchor cannot rot silently. Malformed registry rows are
# a [FAIL], not a skip: a row the gate cannot parse is a row it silently stopped
# enforcing.
#
# THE ATTRIBUTION KIND (`attrib`, 2026-08-06) — same machinery, different semantics,
# and the placement was argued, not assumed. A superseded attribution (the 18:18
# hexagram-split credit moved from Zheng Qiao to Zhang Xingcheng + Zhu Xi on
# 2026-07-30, after the Li Shangxin 2008 first-hand pass found Zheng Qiao "does not
# appear" in the treatment) is WRONG AT EVERY LIVE CLAIM SITE — which sounds like
# GATE 3's class (forbidden text present). It is not, for two measured reasons:
#   (1) THE DETECTABLE STRING IS THE NAME, AND THE NAME HAS LIVE LEGITIMATE SENSES —
#       the correction's own narration (4 CITATIONS.md sites), dated revision-history
#       rows (TR-1 v1.17, append-only under GATE 10's model), and potentially the
#       person cited for a distinct still-credited contribution. That is this
#       registry's own distinguishing test verbatim: "if every occurrence of X is
#       wrong, register it there [GATE 3]; if X has a live legitimate sense that must
#       NOT be 'corrected', register it here." GATE 3's exemption is one file-substring
#       column per row — it cannot express per-site classes, and it has no [OPEN]
#       ledger, so 8 known-open defect sites would hold the suite at rc 1 with no
#       honest way back to 0 short of fixing prose this gate does not own (#157).
#   (2) CLAIM-PHRASE ROWS IN GATE 3 WOULD BE EVASION-SHAPED: the live defects spell
#       the credit five different ways ("begins with Zheng Qiao (~1150)", "from Zheng
#       Qiao", "(Zheng Qiao ~1150; Hu Yigui 1247", "Zheng Qiao ~1150 / Hu Yigui
#       1247", "Zheng Qiao/Hu Yigui trigram clustering") — the hard-floor saga in
#       RETRACTED_PHRASES.tsv needed FOUR rows for one claim and still missed forms.
#       Keying on the name catches every restatement; the price is the curated
#       classification of legitimate mentions, which is exactly the mechanism this
#       gate already carries and GATE 3 does not.
# The defect shape is also THIS gate's shape, not GATE 3's: a correction recorded in
# one place (CITATIONS.md, twice, with a revision note claiming both occurrences
# fixed) that never reached the sites depending on it — required resolution ABSENT.
# What an unexempted hit MEANS differs (a dead credit restated, not an unresolved
# alias), so `attrib` rows get their own [FAIL] wording and one added allow class,
# `other-contribution` (person cited for a distinct, still-supported claim); the
# detection loop, resolution token, stopchars, case fold, character-variant fold,
# open-before-allow ordering and drift audit are shared unchanged.
# WHAT `attrib` CANNOT CATCH, stated: a NAMELESS restatement of the dead claim ("the
# 12th-century identification of the 18:18 split") carries no registered string. The
# one live near-case (TR-1:43's "(~1150)" dating) is a hard-wrap continuation of a
# line that DOES carry the name, so it is reached; a future nameless site is not.
gate_alias_reach() {
  echo "== GATE 18: alias-reach — a ruled alias or superseded attribution used out of reach of its ruling =="
  # ITEM A1 at the bash level, GATE 3b's contract: the registry IS this gate. It holds
  # the rules AND the exemptions AND the open backlog in one file (kind column), so
  # losing it makes the gate BLIND, not stricter — it must be guarded, unlike 3b's
  # pure-exemption allowlist. (Until the file is first committed, require_tracked's
  # untracked-and-absent arm is the reachable one; after that, tracked-but-missing is
  # a FAIL like every other registry.)
  require_rows "documentation/DOC_GATE_ALIAS_REACH.tsv" "Zero rules makes the alias-reach gate claim every alias use is resolved." || return 1
  require_tracked "documentation/DOC_GATE_ALIAS_REACH.tsv" \
    "The alias-ruling registry IS this gate; with it gone, zero rulings are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  python3 - "$(reg_rows_count documentation/DOC_GATE_ALIAS_REACH.tsv)" <<'PY'   # argv[1] = require_rows' count (Q-969)
import os, subprocess, sys
REG = 'documentation/DOC_GATE_ALIAS_REACH.tsv'
if not os.path.exists(REG):
    # Unreachable in normal use (require_tracked returns first) but not left as a
    # skip — GATE 3b's lesson: a dead false-clear is still a false clear the moment
    # the guard above is edited out.
    print(f'  [FAIL] {REG} is absent, so this gate checked nothing'); sys.exit(1)

rules, allows, opens, cfgbad = [], {}, {}, []
stale = []   # GATE 18 LEG stale-registry-row, 2026-09-03 — see the leg comment below
nrows = 0   # Q-969: every data row this parser accepted OR rejected loudly (cfgbad)
for lno, ln in enumerate(open(REG, encoding='utf-8'), 1):
    if not ln.strip():
        continue
    if ln.startswith('#'):
        # Q-969 (A07#2): "#rule\t..." was skipped as a comment while require_rows counted it, so
        # prefixing every rule with "#" left 0 rules and rc 0. The header's comments carry no TAB
        # column (measured: none do), so a "#" line with a TAB-separated column is a row in comment shape.
        g = ln.rstrip('\n').split('\t')
        if any(c.strip() for c in g[1:]):
            cfgbad.append((lno, f'comment-shaped row carries TAB column(s) ({g[0][:30]!r}); a "#" line is a comment only without them'))
        continue
    nrows += 1
    f = ln.rstrip('\n').split('\t')
    kind = f[0]
    if kind in ('rule', 'attrib') and len(f) >= 7:
        # `attrib` (2026-08-06): same field layout as `rule`; the kind changes what an
        # unexempted hit MEANS (dead credit restated vs unresolved alias) — see the
        # header comment above and the registry's jurisdiction note.
        if f[2] not in ('exact', 'nocase'):
            cfgbad.append((lno, f'unknown mode "{f[2]}"')); continue
        rules.append({'kind': kind, 'alias': f[1], 'mode': f[2],
                      'stop': ('' if f[3] == '-' else f[3]),
                      'token': f[4], 'home': f[5], 'why': f[6]})
    elif kind == 'allow' and len(f) >= 6:
        if f[4] not in ('resolution-note', 'literal', 'historical', 'meta-mention',
                        'other-contribution'):
            # Closed vocabulary: an invented class is how an exemption mechanism
            # silently widens (GATE 3b's design note). FAIL, don't coerce.
            cfgbad.append((lno, f'unknown allow class "{f[4]}"')); continue
        allows[(f[1], f[2], f[3])] = (f[4], f[5])
    elif kind == 'open' and len(f) >= 5:
        opens[(f[1], f[2], f[3])] = f[4]
    else:
        cfgbad.append((lno, f'unrecognized kind or field count ({f[0]!r}, {len(f)} fields)'))
for lno, msg in cfgbad:
    print(f'  [FAIL] {REG}:{lno} — malformed registry row: {msg}')
    print(f'         A row this gate cannot parse is a row it silently stopped enforcing.')
if not rules:
    cfgbad.append((0, 'zero rule/attrib rows')); print(f'  [FAIL] Q-969: {REG} has ZERO rule/attrib rows, so no alias is checked.')
if nrows != int((sys.argv[1:] or ['-1'])[0] or '-1'):
    cfgbad.append((0, 'row count')); print(f'  [FAIL] Q-969: GATE 18 read {nrows} data row(s) of {REG}; require_rows counts {(sys.argv[1:] or ["?"])[0]}.')

def occ(hay, needle, stop):
    # Fixed-substring occurrence count with a void-if-followed-by-stopchar guard.
    # str.find only — no regex of any kind (box-safety rule at the top of this file).
    n, i = 0, hay.find(needle)
    while i >= 0:
        j = i + len(needle)
        if not (stop and j < len(hay) and hay[j] in stop):
            n += 1
        i = hay.find(needle, j)
    return n

# CHARACTER-VARIANT FOLD (2026-08-06) — GATE 3b's canon(), same table, same two-star
# contract; see the fold comment there for the full rationale and the deliberately
# unfolded families. PROVEN LIVE for THIS gate before it shipped: "C1 + C2 + C3"
# (spaced) and "c1+c2+c3" (lowercase, before rule 1 went nocase) both passed green
# while "C1+C2+C3" fired — a ruled alias could be restated out of reach of its ruling
# by a spacing or case variant. The '+'-spacing collapse is the load-bearing fold
# here, and it PRESERVES the stopchar contract: "C1 + C2 + C3 + C4" folds to
# "C1+C2+C3+C4", whose alias occurrence is voided by the '+' stopchar exactly as the
# unspaced conjunction is. Dash folding (en/em/minus -> '-') guards future dashed
# rules; it is inert for both current rules. Resolution TOKENS and allow/open ANCHORS
# keep matching the RAW line — adjudication machinery untouched, needle side widened.
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
    s = s.translate(FOLD1).replace('*', star)
    out = []
    for i, ch in enumerate(s):              # strip digit-group commas, no regex
        if ch == ',' and 0 < i < len(s) - 1 and s[i-1].isdigit() and s[i+1].isdigit():
            continue
        out.append(ch)
    return ''.join(out).replace(' +', '+').replace('+ ', '+')

mds = subprocess.run(['git', 'ls-files', '*.md'], capture_output=True, text=True).stdout.split()
# COST, evaluated before writing it (box-safety rule): canonicalisation is |mds| ~130
# files x ~500 lines x 2 star-readings of canon() (a translate + one linear scan each),
# then |rules| = 2 fixed-substring occ() searches per line per reading ~ 5e5 str.find
# calls over data already in memory, plus the flattened whole-text searches per
# (file, rule) for the hard-wrap check. No regex, no bounded repetition; `nocase` is
# str.lower(), not a pattern.
# The registry itself is .tsv, outside the '*.md' glob, so the gate cannot match its
# own rows (verified: same property GATE 3b states for its registries).
bad, spans, openhits, exempt, ninline = [], [], [], [], 0
used_allow, used_open = set(), set()
for m in mds:
    text = open(m, encoding='utf-8', errors='replace').read()
    lines = text.split('\n')
    # Canonicalise once per file, in both '*' readings; needle tests run against these,
    # while token/open/allow checks below keep matching the RAW `line`.
    clx = [canon(l, 'x') for l in lines]
    cld = [canon(l, '') for l in lines]
    for r in rules:
        calias = canon(r['alias'], '')     # no rule alias carries '*': one canon suffices
        needle = calias.lower() if r['mode'] == 'nocase' else calias
        n_online = 0
        for i, line in enumerate(lines, 1):
            hx = clx[i-1].lower() if r['mode'] == 'nocase' else clx[i-1]
            hd = cld[i-1].lower() if r['mode'] == 'nocase' else cld[i-1]
            c = max(occ(hx, needle, r['stop']), occ(hd, needle, r['stop']))
            if not c:
                continue
            n_online += c    # OCCURRENCES, not lines — GATE 3b's TR-2:650 lesson,
                             # so the wrap check below cannot report a phantom.
            if r['token'] and r['token'] in line:
                ninline += 1                      # within one link, by its own line
                continue
            oh = [a for (af, aa, a) in opens
                  if af == m and aa == r['alias'] and a in line]
            if oh:
                for a in oh:
                    used_open.add((m, r['alias'], a))
                openhits.append((m, i, r['alias'], opens[(m, r['alias'], oh[0])]))
                continue
            ah = [(a, allows[(af, aa, a)]) for (af, aa, a) in allows
                  if af == m and aa == r['alias'] and a in line]
            if ah:
                for a, _ in ah:
                    used_allow.add((m, r['alias'], a))
                exempt.append((m, i, r['alias'], ah[0][1][0], ah[0][1][1]))
                continue
            bad.append((m, i, r['alias'], r, line.strip()))
        # Hard-wrap evasion, GATE 3b's flat check: "the exhaustive enumeration" split
        # across a wrap is invisible line-by-line but visible after whitespace
        # normalisation. (For the space-free alias this leg is inert — markdown wraps
        # at spaces — but it costs one search and guards future space-carrying rules.)
        # Both sides use the same canon() fold, so a variant-form occurrence cannot
        # produce a phantom wrap.
        flat = ' '.join(text.split())
        fx = canon(flat, 'x'); fd = canon(flat, '')
        if r['mode'] == 'nocase':
            fx = fx.lower(); fd = fd.lower()
        if max(occ(fx, needle, r['stop']), occ(fd, needle, r['stop'])) > n_online:
            spans.append((m, r['alias'], r))

for m, i, alias, r, line in bad:
    if r['kind'] == 'attrib':
        print(f'  [FAIL] {m}:{i} — superseded attribution "{alias}" restated with no path to its correction')
        print(f'         CORRECTION: {r["why"]}')
        print(f'         LIVES AT: {r["home"]}')
        print(f'         LINE: {line[:150]}')
        print(f'         FIX: apply the corrected credit (or narrate the correction on this line),')
        print(f'         add an `allow` row — class other-contribution ONLY if the person is cited')
        print(f'         for a distinct, still-supported claim — or adjudicate it `open`; registry header.')
    else:
        print(f'  [FAIL] {m}:{i} — ruled alias "{alias}" used out of reach of its ruling')
        print(f'         RULING: {r["why"]}')
        print(f'         LIVES AT: {r["home"]}')
        print(f'         LINE: {line[:150]}')
        print(f'         FIX: apply the ruling to this line (or put a same-line pointer to the')
        print(f'         ruling), add an `allow` row with the right class if this is a legitimate')
        print(f'         sense, or adjudicate it `open` — see the registry header.')
for m, alias, r in spans:
    noun = 'superseded attribution' if r['kind'] == 'attrib' else 'ruled alias'
    print(f'  [FAIL] {m} — {noun} "{alias}" present only after whitespace')
    print(f'         normalisation, so it spans a hard wrap and cannot be line-classified.')
    print(f'         RULING: {r["why"]}')
for m, i, alias, why in openhits:
    print(f'  [OPEN] {m}:{i} "{alias}" — {why}')
if openhits:
    print(f'  [note] {len(openhits)} adjudicated-open site(s) above are DEFECTS, not exemptions')
    print(f'         (DOC_GATE_FIGURE_LEDGER_OPEN.txt contract). Each is closed by fixing the')
    print(f'         line and deleting its `open` row; a NEW unadjudicated use is a [FAIL].')
# GATE 18 LEG stale-registry-row (2026-09-03, wave-4 lane A2) — A NON-MATCHING ROW WAS A
# [note], AND A [note] IS NOT EVIDENCE OF ANYTHING.
#
# THE DEFECT, measured before the fix: 42 `open` rows in the registry, of which **40 matched
# nothing**. Every one had in fact been fixed — 15 anchors gone from the file entirely, 25
# with the anchor still present but the alias replaced (C1+C2+C3 -> C1–C5, "the exhaustive
# enumeration" -> "the budgeted enumeration", the Zheng Qiao credit amended) — but the gate
# could not say so, and neither could a reader: the two dispositions the note itself names,
# "fixed (delete the row)" and "the anchor drifted and the defect is now UNWATCHED", print
# identically and exit 0. A backlog inventory that rots silently is the same shape as an
# allowlist that widens silently, and this suite already refuses that shape twice (GATE 3b's
# closed allow-class vocabulary, GATE 59's unmatched-allowance FAIL).
#
# It is also what the OPEN_ROW_BUDGET ratchet below was quietly resting on. The ratchet
# counts ROWS, so 40 dead rows were holding the budget at 42 and buying 40 rows of headroom
# in which a genuinely new defect could be silenced without the count ever moving. Deleting
# them dropped the budget to 2; this leg is what keeps it there without anyone remembering.
#
# WHY IT IS SAFE TO MAKE IT A FAIL, measured rather than assumed: after the 40 resolved rows
# were deleted, live is 0 unmatched `open` rows and 0 unmatched `allow` rows (the `allow`
# side has been at 0 all along — 17 rows, all matching). So this leg is not red on correct
# content today, and the only way to turn it red is to fix a line and leave its row behind,
# which is exactly the event it exists to name.
#
# NOT self-witnessing (needle-reachability mechanism 7): the predicate is "this registry row
# matched no line", so the witness is the ABSENCE of a match in the corpus, never the row's
# own text. Perturbing the row's anchor cannot make the target vanish — it makes the row
# match nothing, which is the failure.
for k in [k for k in allows if k not in used_allow]:
    stale.append(('allow', k))
    print(f'  [FAIL] allow row matched nothing this run: {k[0]} "{k[1]}" @ "{k[2][:40]}"')
    print(f'         An exemption for text that is no longer there exempts nothing and')
    print(f'         hides the fact that it exempts nothing. Delete the row if the text was')
    print(f'         fixed; re-anchor it if the anchor drifted and the sense still needs the')
    print(f'         exemption. Leaving it is not a third option.')
for k in [k for k in opens if k not in used_open]:
    stale.append(('open', k))
    print(f'  [FAIL] open row matched nothing this run: {k[0]} "{k[1]}" @ "{k[2][:40]}"')
    print(f'         An `open` row is a DECLARED, UNFIXED defect. One that matches nothing is')
    print(f'         either a defect that WAS fixed — delete the row, the backlog count must')
    print(f'         shrink honestly and the ratchet budget below must come down with it — or')
    print(f'         an anchor that drifted off a defect which is now carried by no row and')
    print(f'         watched by nothing. The gate cannot tell those apart; a human must, and')
    print(f'         must then say which by editing the registry.')

# ---------------------------------------------------------------------------
# Codex v2 charge 4 (2026-09-02) — THE ESCALATION LOOPHOLE, and why it is closed with a
# ratchet rather than by folding openhits into nbad.
#
# THE CHARGE, verified live: `all`'s PASS banner named GATE 18 among the HARD gates while
# an [OPEN] row exits 0. Two consequences, and only the second is a real defect. The
# backlog itself is DECLARED and cannot go invisible — every row re-prints with a count
# and a "[note] ... DEFECTS, not exemptions" line every run — so a reader is not misled
# about the sites. But a future genuine [FAIL] could be silenced by ADDING an `open` row,
# with no correction anywhere and no change in exit status. That is an escape hatch that
# opens itself, which is the shape this suite exists to refuse.
#
# WHY NOT `nbad += len(openhits)`. It is the cleaner rule and it was rejected on measured
# grounds, not taste: there are 2 live open sites today, so switching it on turns `all`
# RED for every push until a #146/#157 adjudication lands that is not this lane's to make.
# A hard gate that is red for reasons the pusher cannot fix is a hook that gets bypassed
# with --no-verify, and --no-verify uncovers EVERYTHING (this file's own argument for
# keeping GATE 8 out of `all`). So the backlog stays declared and non-blocking, and the
# HATCH is what gets nailed shut.
#
# THE RATCHET. Both counts are budgeted, and a budget may only ever be LOWERED:
#   * OPEN_SITE_BUDGET  — sites actually silenced by an `open` row. Adding a row that
#     covers a NEW defect raises this and FAILS, which is precisely the escalation.
#   * OPEN_ROW_BUDGET   — rows in the registry. Adding a row that matches nothing (a
#     speculative pre-emptive hatch) raises this and FAILS too.
# Lowering a budget is a one-line diff in this gate, in the same commit as the fix, and
# is visible in review. Raising one is the same diff and is not something that can happen
# by accident or by silence — which is the whole difference from today.
#
# MEASURED at adoption, 2026-09-02: 2 open sites, 42 open rows.
# LOWERED 2026-09-03 (wave-4 lane A2): 40 of those 42 rows matched nothing and every one of
# them was a fix that had already landed — deleted, leaving 2 rows for the 2 live sites. The
# ratchet had been resting on 40 dead rows' worth of headroom; see GATE 18 LEG
# stale-registry-row above, which is what now keeps the two counts equal without anyone
# remembering to lower this line.
OPEN_SITE_BUDGET = 1  # LOWERED 2 -> 1 2026-09-25 (Q-763): the CRITIQUE.md:137 row became `allow literal`; one open site left
OPEN_ROW_BUDGET  = 1  # LOWERED 2 -> 1 in the same change; the Zheng Qiao row (#157) is the one open row
ratchet = []
if len(openhits) > OPEN_SITE_BUDGET:
    ratchet.append(f'{len(openhits)} adjudicated-open SITE(s), budget {OPEN_SITE_BUDGET}')
if len(opens) > OPEN_ROW_BUDGET:
    ratchet.append(f'{len(opens)} `open` registry ROW(s), budget {OPEN_ROW_BUDGET}')
if ratchet:
    print(f'  [FAIL] the adjudicated-open backlog GREW: ' + '; '.join(ratchet))
    print(f'         An `open` row is a DECLARED DEFECT carried from an adjudication, not a')
    print(f'         way to clear a new one. If a [FAIL] appeared and an `open` row was added')
    print(f'         to silence it, that is the escalation this ratchet exists to refuse: fix')
    print(f'         the line instead. If the backlog genuinely has to grow, raise the budget')
    print(f'         in scripts/doc_gates.sh IN THE SAME COMMIT, so the decision is reviewable')
    print(f'         rather than silent.')
# Under budget is the direction of travel, and it must not be silent either: a budget left
# above the true count is a hatch reopening by itself.
if len(openhits) < OPEN_SITE_BUDGET or len(opens) < OPEN_ROW_BUDGET:
    print(f'  [note] backlog SHRANK ({len(openhits)} site(s) / {len(opens)} row(s) vs budget '
          f'{OPEN_SITE_BUDGET}/{OPEN_ROW_BUDGET}) — lower the budget in scripts/doc_gates.sh')
    print(f'         so the ratchet keeps its grip. A budget above the true count is slack.')

nbad = len(bad) + len(spans) + len(cfgbad) + len(ratchet) + len(stale)
if not nbad:
    byclass = {}
    for _, _, _, cls, _ in exempt:
        byclass[cls] = byclass.get(cls, 0) + 1
    tally = ', '.join(f'{v} {k}' for k, v in sorted(byclass.items())) or 'none'
    nal = sum(1 for r in rules if r['kind'] == 'rule')
    print(f'  [ok] {nal} ruled alias(es) + {len(rules) - nal} superseded attribution(s); '
          f'every use in {len(mds)} markdown files is '
          f'within one link of its ruling ({ninline} inline), a curated legitimate sense '
          f'({tally}), or adjudicated open ({len(openhits)} [OPEN] above)')
sys.exit(1 if nbad else 0)
PY
}

