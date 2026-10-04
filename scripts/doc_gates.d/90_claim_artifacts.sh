#@ scripts/doc_gates.d/90_claim_artifacts.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATES 39-55: claim-to-artifact, scope and provenance gates.
#@ Lines 16413-18146 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# ----------------------------------------------------------------------------------
# GATE 39 — the four claim-to-artifact legs Codex V2 prescribed (P14's sheet).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, "the four doc_gates legs P14 prescribed
# (`cert-claims-shipped`, `four-five-labels`, `se-claims-have-se`, the 26,112/`canonical`
# pair leg)". Each leg's shape and red test are quoted from CODEX_V2_ADJUDICATION.md rows
# 1/2/5/3b. All four prose defects are FIXED at HEAD, so all four legs are REGRESSION
# GUARDS and their red tests are run against the pre-fix tree, not against HEAD.
#
# LEG 1 `cert-claims-shipped` (adjudication row 1 + row 8) — every `*.drat`/`*.drat.gz`
#   named in tracked markdown must exist under reports/certificates/ AND appear in
#   verify_all.sh's regeneration map. THE DEFECT: CLAIM_TO_ARTIFACT.md:35 and TR-2:313
#   cited `core_gender_ccn4_unsat.drat` — a fourth two-rule core certificate that existed
#   at no public ref — while verify_all.sh's completeness check ran ONE WAY (every archived
#   proof is mapped) and so could not notice a CLAIMED 22nd proof that was absent. 21/21
#   passed green while the fourth advertised core was never replayed. This leg is the other
#   direction: claimed ⊆ archived.
#   🔴 BRACE EXPANSION IS LOAD-BEARING. CLAIM_TO_ARTIFACT.md writes the set as
#   `core_{gender_ccn8,parity_ccn4,rhythm_ccn4,gender_ccn4}_unsat.drat.gz`. A plain
#   filename regex extracts `_unsat.drat` from that and checks NOTHING, so the one site
#   the leg exists for is invisible to it — measured: without expansion the four real names
#   never enter the population. One brace group per line is expanded before matching.
#   EXEMPT: command metavariables (`OUT.cnf.drat` at SAT_CLI.md:424 — a template, not a
#   claim). Declared as an ALL-CAPS stem segment, and counted.
#
# LEG 2 `four-five-labels` (row 2) — `grander-strict` is the FIVE-rule union and
#   `grand-ccn4` the FOUR-rule conflict theorem. THE DEFECT: CLAIM_TO_ARTIFACT.md:38 mapped
#   "The four literature rules are jointly unsatisfiable" to `grander_strict_unsat.drat.gz`
#   — a different formula (7249v/271066c vs 7035v/262093c), and UNSAT(F∧ccn8) does not
#   imply UNSAT(F). SAT_CLI.md:253@b9f0fd2c inverted the same pair.
#   🔴 IDENTIFIER MASKING IS LOAD-BEARING AND WAS MEASURED. The ruleset and certificate
#   names CONTAIN the words: `five_loo_ccn8_unsat.drat.gz`, `five-loo-ccn8`, `five-sub-…`.
#   certificates/README.md:131 reads "five_loo_ccn8_unsat.drat.gz | … (= grand-ccn4): still
#   UNSAT" — a CORRECT line that a bare `grand-ccn4` AND `five` needle fails. So identifier-
#   embedded four/five and code spans are masked before the PROSE words are read, while the
#   ruleset detection runs on the raw line. A line naming BOTH rulesets is exempt: that is
#   the "four- / five-rule conflict decisions" row, which is how the pair is stated correctly.
#
# LEG 3 `se-claims-have-se` (row 5) — a sentence claiming standard errors for a named
#   evidence file must be true of that file. THE DEFECT: CLAIM_TO_ARTIFACT.md:41 asserted
#   "masses now carry SEs" while naming `reports/evidence/dav_tier1.out`, which contains
#   ZERO `se=` fields (the delta-method emission landed 2026-08-28; the archived run is
#   2026-07-04). METHODS.md itself disclosed the gap the matrix row denied.
#
# LEG 4 the 26,112/`canonical` pair leg (row 3b) — the n-ladder integers 26,112 /
#   2,063,395,607,040 / 267,765,117,419,520 are ORIENTATION-EXPLICIT sequence counts.
#   THE DEFECT: CLAIM_TO_ARTIFACT.md:45 called 26,112 the "n=9 **canonical** count", and in
#   this repository "canonical" records collapse orientation (SOLUTIONS_FORMAT.md), so the
#   adjective states a different quantity. TR-11 v1.13 exists because the same conflation
#   was already caught once at the report level.
#
# 🔴 SENTENCE SCOPE, CELL-AWARE — AND THIS WAS SET BY MEASUREMENT, NOT TASTE. Legs 3 and 4
# were first written at LINE scope, which is what the adjudication rows say ("any tracked-md
# line …"). Measured, that produced FOUR false positives and no true one, all of the
# disclosure-penalising shape: TR-10:506 is a single revision row ~3,000 characters long in
# which the `se=` clause and the `dav_tier1.out` citation are unrelated neighbours (the
# files are cited for `threads=32`), and TR-11:746 pairs 26,112 with the boilerplate "No
# count, theorem, or canonical value changed". Failing either would be failing a revision
# row for narrating a correction. The fix is scope, not an exemption list: ` | ` is treated
# as a sentence boundary alongside `.!?`, so one table cell is one unit.
gate_p14_claims() {
  echo "== GATE 39: the four claim-to-artifact legs (cert / four-five / se / orientation) =="
  require_tracked "reports/certificates/verify_all.sh" "GATE 39 LEG 1" || return 1
  local FA=15 FB=15 FC=2 FD=15
  local out
  out=$( { _g1_prelude; cat <<'PY'
import os
fa, fb, fc, fd = (int(x) for x in sys.argv[1:5])
# Cell-aware sentence split: a markdown table cell is its own unit.
_CB = re.compile(r'(?<=[.!?])\s|\s\|\s')
def csent(flat, a, b):
    s = 0
    for m in _CB.finditer(flat, 0, a): s = m.end()
    m = _CB.search(flat, b)
    return flat[s:(m.start() if m else len(flat))]

# ---------- LEG 1: cert-claims-shipped ----------
BRACE = re.compile(r'\{([^{}]*,[^{}]*)\}')
TOK   = re.compile(r'[A-Za-z0-9][A-Za-z0-9_.\-]{2,}\.drat(?:\.gz)?')
META  = re.compile(r'(?:^|[._-])(?:OUT|DIR|FILE|NAME|PATH)(?:[._-]|$)')
named = {}
for f in corpus():
    t = read(f)
    if t is None: continue
    for i, l in enumerate(t.split("\n"), 1):
        outs = [l]
        m = BRACE.search(l)
        if m:
            outs = [l[:m.start()] + alt + l[m.end():] for alt in m.group(1).split(',')]
        for o in outs:
            for tok in TOK.findall(o):
                named.setdefault(tok[:-3] if tok.endswith('.gz') else tok, set()).add("%s:%d" % (f, i))
try:
    arch = {(x[:-3] if x.endswith('.gz') else x) for x in os.listdir('reports/certificates')
            if x.endswith('.drat') or x.endswith('.drat.gz')}
except OSError as e:
    print("ERROR\treports/certificates/ is unreadable (%s) - LEG 1 checked NOTHING" % e.strerror)
    arch = None
# Q-961 (Codex push-path review Q835, P-14): the regeneration map is the KEY SET of verify_all.sh's
# `declare -A CERTS=( ... )` literal, not the file's text. Read as text, a comment naming a
# certificate kept it "mapped" after its map entry was deleted. Exactly one CERTS literal, comments
# stripped, at least one key -- otherwise ERROR, never a silent pass.
vsrc = read('reports/certificates/verify_all.sh')
vmap = None
if vsrc is not None:
    blocks = re.findall(r'(?m)^declare -A CERTS=\(([^)]*)\)', vsrc)
    if len(blocks) != 1:
        print("ERROR\tverify_all.sh has %d 'declare -A CERTS=(' literal(s), expected 1 - LEG 1's map check checked NOTHING" % len(blocks))
    else:
        body = re.sub(r'(?m)(?:^|(?<=\s))#.*$', '', blocks[0])
        vmap = set(re.findall(r'\[([^\]\s]+)\]=', body))
        if not vmap:
            print("ERROR\tverify_all.sh's CERTS map parsed to 0 keys - LEG 1's map check checked NOTHING")
            vmap = None
if arch is not None and vmap is not None:
    ex_meta = 0
    for n in sorted(named):
        if META.search(n[:-5]):
            ex_meta += 1
            continue
        where = sorted(named[n])[0]
        if n not in arch:
            print("HIT1\t%s\t%s\tnamed in markdown but NOT archived under reports/certificates/" % (where, n))
        elif n[:-5] not in vmap:
            print("HIT1\t%s\t%s\tarchived but absent from verify_all.sh's regeneration map" % (where, n))
    print("POPA\t%d certificate filename(s) named in markdown, %d archived, %d command metavariable(s) exempt"
          % (len(named), len(arch), ex_meta))
    if len(named) - ex_meta < fa:
        print("ERROR\tonly %d claimed certificate name(s) (floor %d) - LEG 1 is measuring nothing" % (len(named) - ex_meta, fa))

# ---------- LEG 2: four-five-labels ----------
G4 = re.compile(r'grand-ccn4|grand_ccn4')
G5 = re.compile(r'grander-strict|grander_strict')
# 🔴 THE MASK MUST NOT EAT THE PROSE WORD IT IS LOOKING FOR. This first read
# `[A-Za-z0-9_]*(?:five|four)[A-Za-z0-9_.\-]*`, whose zero-length prefix and suffix make it
# match the bare word "four" as well as `five_loo_ccn8`. Measured against the pre-fix tree
# at 89e7a9a1, the leg went GREEN on CLAIM_TO_ARTIFACT.md:34 — the single site it was
# written for — because it masked the "four" in "The four literature rules". Code spans are
# masked (the rulesets are cited in backticks), then only IDENTIFIER forms of the words:
# `five_loo_ccn8`, `five-loo-ccn8`, `five-sub-gender+ccn4`. `four-rule` / `five-rule` are
# deliberately NOT masked — they are the prose labels this leg reads.
MASK = re.compile(r'`[^`]*`'
                  r'|\b(?:five|four)[_-](?:loo|sub|ccn|strict|rules?_)[A-Za-z0-9_.+\-]*'
                  r'|\b(?:five|four)_[A-Za-z0-9_.+\-]+')
W4 = re.compile(r'\bfour\b', re.I)
W5 = re.compile(r'\bfive\b', re.I)
popb = exb = exl = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    for i, l in enumerate(t.split("\n"), 1):
        h4, h5 = bool(G4.search(l)), bool(G5.search(l))
        if not (h4 or h5): continue
        popb += 1
        if h4 and h5:
            exb += 1
            continue          # states the pair — the correct form
        # The append-only ledger QUOTES the labels it retired: CORRECTIONS.md:7105 reads
        # 'Three sites nevertheless called the four-rule decision "five": the `grand-ccn4`
        # docstring …'. Failing a correction for naming the wording it withdrew is the
        # disclosure-penalising shape; a withdrawal has to quote what it withdrew, and the
        # ledger is append-only so it can never be reworded out of the way. Counted, so the
        # exemption cannot grow unseen.
        if f == 'documentation/CORRECTIONS.md':
            exl += 1
            continue
        m = MASK.sub(' ', l)
        if h5 and W4.search(m):
            print("HIT2\t%s:%d\tgrander-strict (the FIVE-rule union) labelled 'four'\t%s" % (f, i, " ".join(l.split())[:130]))
        if h4 and W5.search(m):
            print("HIT2\t%s:%d\tgrand-ccn4 (the FOUR-rule theorem) labelled 'five'\t%s" % (f, i, " ".join(l.split())[:130]))
print("POPB\t%d line(s) name a conflict ruleset, %d naming both (exempt), %d in the append-only ledger (exempt)" % (popb, exb, exl))
if popb < fb:
    print("ERROR\tonly %d conflict-ruleset mention(s) (floor %d) - LEG 2 is measuring nothing" % (popb, fb))

# ---------- LEG 3: se-claims-have-se ----------
# 🔴 ROW SCOPE, NOT CELL SCOPE — AND THE OPPOSITE CHOICE WAS MEASURED AND REJECTED. Legs 3
# and 4 share the cell-aware splitter above; LEG 3 must NOT use it. The defect lives in a
# CLAIM-TO-ARTIFACT matrix row whose artifact cell holds `reports/evidence/dav_tier1.out`
# and whose status cell holds "masses now carry SEs" — two different cells. Under cell
# scope the leg went green on its own pre-fix red-test site, which is the failure mode of
# a needle that cannot fire on the case it was written for. Binding a claim to an artifact
# is a ROW-level relation, so the row is the unit.
# The line-scope false positives that motivated cell scope came from REVISION-HISTORY rows
# (TR-10:506 is ~3,000 characters in which the `se=` clause and the `dav_tier1.out`
# citation are unrelated neighbours — the files are cited there for `threads=32`). Those
# are excluded by SHAPE, declared and counted, rather than by shrinking the scope until
# the real defect disappears with the false ones.
EV  = re.compile(r'([A-Za-z0-9_]+\.out)\b')
SE  = re.compile(r'\bse=|standard error|\bSEs\b', re.I)
# A sentence that says the file has NO SEs is disclosing the gap, not claiming it closed.
# 🔴 TIGHTENED AFTER A MEASURED NO-OP. This first read `\bno\b|carry|carries|predates?|...`,
# which exempted 8 of 8 population members — a leg that cannot fire. Worse, the PRE-FIX
# sentence it exists to catch ("masses now **carry** SEs") contains `carry`, so the leg
# would have gone green on its own red test. The negation must attach to the SE claim.
NEG = re.compile(r'no `?se=|carr(?:y|ies|ied) no|contains? no|zero `?se=|does not carry'
                 r'|predates?\b|no standard error|without `?se=|no PUBLISHED artifact', re.I)
REV = re.compile(r'^\s*\|\s*\*{0,2}v?\d+\.\d+[^|]*\|\s*20\d\d-\d\d-\d\d\s*\|')
popc = exc = exr = 0
_seen = {}
def has_se(n):
    if n not in _seen:
        p = 'reports/evidence/' + n
        try:
            _seen[n] = 'se=' in open(p, encoding='utf-8', errors='replace').read()
        except OSError:
            _seen[n] = None          # named file absent — reported, never silently passed
    return _seen[n]
for f in corpus():
    t = read(f)
    if t is None: continue
    for i, l in enumerate(t.split("\n"), 1):
        if not SE.search(l): continue
        names = set(EV.findall(l))
        if not names: continue
        if REV.match(l):
            exr += 1
            continue
        popc += 1
        if NEG.search(l):
            exc += 1
            continue
        for n in sorted(names):
            r = has_se(n)
            if r is None:
                print("HIT3\t%s:%d\t%s\tclaims standard errors for an evidence file that does not exist" % (f, i, n))
            elif not r:
                print("HIT3\t%s:%d\t%s\tclaims standard errors, but the named file contains no `se=` field" % (f, i, n))
print("POPC\t%d row(s) pair an SE claim with a named evidence file, %d disclosing the gap (exempt), %d revision-history row(s) excluded by shape" % (popc, exc, exr))
if popc < fc:
    print("ERROR\tonly %d SE/evidence-file row(s) (floor %d) - LEG 3 is measuring nothing" % (popc, fc))

# ---------- LEG 4: the n-ladder is orientation-explicit, not canonical ----------
LAD = re.compile(r'26,112|2,063,395,607,040|267,765,117,419,520')
CAN = re.compile(r'\bcanonical\b', re.I)
OE  = re.compile(r'orientation-explicit', re.I)
popd = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    for m in LAD.finditer(flat):
        popd += 1
        s = csent(flat, m.start(), m.end())
        if CAN.search(s) and not OE.search(s):
            print("HIT4\t%s:%d\t%s" % (f, lno(starts, m.start()), " ".join(s.split())[:150]))
print("POPD\t%d n-ladder integer mention(s)" % popd)
if popd < fd:
    print("ERROR\tonly %d n-ladder mention(s) (floor %d) - LEG 4 is measuring nothing" % (popd, fd))
PY
} | python3 - "$FA" "$FB" "$FC" "$FD" ) || { echo "  [FAIL] GATE 39 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 sawa="" sawb="" sawc="" sawd=""
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POPA)  sawa=1; echo "  [info] LEG 1 cert-claims-shipped: $a" ;;
      POPB)  sawb=1; echo "  [info] LEG 2 four-five-labels: $a" ;;
      POPC)  sawc=1; echo "  [info] LEG 3 se-claims-have-se: $a" ;;
      POPD)  sawd=1; echo "  [info] LEG 4 orientation-explicit: $a" ;;
      HIT1)  echo "  [FAIL] $a cites \`$b\` — $c"
             echo "         A CERTIFIED claim must name a proof object a third party can replay."
             rc=1 ;;
      HIT2)  echo "  [FAIL] $a $b"
             echo "         … $c"
             echo "         UNSAT of the five-rule union does not imply UNSAT of the four-rule theorem."
             rc=1 ;;
      HIT3)  echo "  [FAIL] $a names \`$b\` and $c"
             rc=1 ;;
      HIT4)  echo "  [FAIL] $a calls an n-ladder integer 'canonical'"
             echo "         $b"
             echo "         These are orientation-explicit SEQUENCE counts (TR-11 §2 precision note);"
             echo "         repository 'canonical' records collapse orientation."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  if [ -z "$sawa" ] || [ -z "$sawb" ] || [ -z "$sawc" ] || [ -z "$sawd" ]; then
    echo "  [FAIL] GATE 39 did not print all four census lines — a leg did not run, so it checked nothing."
    return 1
  fi
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every named certificate is archived and mapped; every conflict-ruleset label"
  echo "       matches its rule count; every SE claim is true of the file it names; every"
  echo "       n-ladder integer is labelled orientation-explicit rather than canonical."
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 40 — a `--mutual-info` citation may not be explained by the wrong MI.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P30 / Codex V2-F30 #6 — "any line citing
# `--mutual-info` must disambiguate" which of the two statistics it means.
# THE DEFECT (152c986c): MCKENNA.md:107@152c986c read "`--mutual-info` shows near-zero mutual
# information between upper and lower trigram **transitions**" and then explained that
# value with the complete Latin square. The analysis prints TWO figures and the explanation
# belongs to the other one: the TRANSITION MI (changed/unchanged indicators across the 63
# transitions) is 0.0078 bits at the 7th percentile and is NOT forced by the construction —
# random permutations contain the same 64 hexagrams and their transition MI varies. It is
# the STATIC 8-state MI over trigram identities that is exactly 0.000000 bits and IS forced,
# because all 64 (upper, lower) combinations appear exactly once.
#
# 🔴 TWO EARLIER SHAPES WERE BUILT, MEASURED AND DISCARDED — recorded so neither is
# re-proposed as an oversight:
#   (a) "every `--mutual-info` mention must disambiguate" returns 6 findings and 0 defects:
#       five are FLAG ENUMERATIONS (`--palindromes`, `--canons`, `--entropy`, `--path`,
#       `--mutual-info`, … in ROAE_PY_CLI.md's reseed census) and one is the ledger.
#       Citing a flag in a list of flags is not citing a figure.
#   (b) "…must disambiguate when it publishes a figure" scores ZERO on its own red-test
#       site, twice over: the pre-fix sentence publishes no numeral ("near-zero"), and it
#       CONTAINS the words "Latin square", which the first draft had in its disambiguation
#       vocabulary. The retired sentence would have exempted itself.
# What ships is the coupling the correction actually established: invoking the complete
# square is a claim about the STATIC MI, so a sentence that invokes it must name that one.
gate_mi_disambig() {
  echo "== GATE 40: a --mutual-info citation explained by the wrong mutual information =="
  local FLOOR=2
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor = int(sys.argv[1])
MI  = re.compile(r'--mutual-info|mutual information', re.I)
# The complete-Latin-square construction. It forces the STATIC 8-state MI and nothing else.
LSQ = re.compile(r'Latin square|complete square|all 64 \(upper|every \(upper, ?lower\) combination', re.I)
STATIC = re.compile(r'\bstatic\b|8-state|eight-state|trigram identit', re.I)
pop = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    for i, l in enumerate(t.split("\n"), 1):
        if not (MI.search(l) and LSQ.search(l)):
            continue
        pop += 1
        if STATIC.search(l):
            continue
        print("HIT\t%s\t%d\t%s" % (f, i, " ".join(l.split())[:150]))
print("POP\t%d site(s) explain a mutual-information figure with the complete-square construction" % pop)
if pop < floor:
    print("ERROR\tonly %d MI/complete-square site(s) (floor %d) - this gate is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 40 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 saw=""
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   saw=1; echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b explains a mutual-information figure with the complete Latin square"
             echo "         $c"
             echo "         The square forces the STATIC 8-state MI (0.000000 bits) only. The TRANSITION"
             echo "         MI (0.0078 bits, 7th percentile) is not forced and varies across permutations."
             echo "         Name which of the two the sentence means."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ -n "$saw" ] || { echo "  [FAIL] GATE 40 printed no census line — the scan did not complete."; return 1; }
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every complete-square explanation names the static 8-state MI it applies to"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 41 — 65,281 is the PRODUCTIVE subset, never the space.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P33 / Codex V2-F53 #2 — "cross-check
# 158,364 against 65,281 … fail any 'entire space'/'all-cells' wording that appears near
# 65,281".
# THE MEASURED FACTS (recomputed 2026-09-02, recorded in the backlog row): the depth-3
# C2/C5-feasible space is 158,364 cells in 4,382 ambient G-orbits (sizes {6:14, 12:270,
# 24:1736, 48:2362}), G-closed under all 48 sigma. The productive 65,281 are 41.2% of it
# and are NOT G-closed — so an orbit statement made over the 65,281 is a statement about a
# non-invariant subset, which is exactly the error the "all-cells orbit test" wording made.
#
# 🔴 THE ONE CANDIDATE IN THE CORPUS IS THE LEDGER QUOTING ITSELF, and it is exempted by
# CONTENT rather than by filename: CORRECTIONS.md:4001 carries the retired wording inside
# its own **BEFORE.** quotation, on a line that also says "measures 41.2% of the cells".
# The 41.2%/productive/158,364 vocabulary is what makes the sentence correct, so the same
# test that clears the correction is the test the corrected prose has to pass — no
# file-level carve-out, which would also clear a genuinely wrong sentence in that file.
gate_cell_space() {
  echo "== GATE 41: 65,281 described as the space rather than the productive subset =="
  local FLOOR=20
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor = int(sys.argv[1])
_CB = re.compile(r'(?<=[.!?])\s|\s\|\s')
def csent(flat, a, b):
    s = 0
    for m in _CB.finditer(flat, 0, a): s = m.end()
    m = _CB.search(flat, b)
    return flat[s:(m.start() if m else len(flat))]
N   = re.compile(r'65,281')
ALL = re.compile(r'all[- ]cells|entire space|whole space|all the cells|every cell|the full space', re.I)
# What makes such a sentence true: it names the AMBIENT count or the fraction, or states
# the non-closure. 🔴 `productive` AND `yield` WERE REMOVED AFTER A FAILED RED TEST, for
# the same reason GATE 38's restriction moved off sentence scope. The retired wording at
# SYMMETRY_SEARCH.md:177@b7ac534a reads "**All-cells orbit test:** the 65,281 **productive** 560T
# cells partition into 4,183 G-orbits … orbit-equal … across the entire space." The word
# `productive` is in its PREMISE; the defect is the conclusion generalising to the whole
# space from a subset that is 41.2% of it and not G-closed. With `productive` in this
# vocabulary the gate went green on all three of its own pre-fix sites.
OK  = re.compile(r'158,364|41\.2|non-empty|not G-closed', re.I)
pop = ex = 0
for f in corpus():
    t = read(f)
    if t is None: continue
    flat, starts = flatten(t)
    for m in N.finditer(flat):
        pop += 1
        s = csent(flat, m.start(), m.end())
        if not ALL.search(s):
            continue
        if OK.search(s):
            ex += 1
            continue
        print("HIT\t%s\t%d\t%s" % (f, lno(starts, m.start()), " ".join(s.split())[:150]))
print("POP\t%d mention(s) of 65,281; %d pair all-cells wording with the ambient count, the 41.2%% fraction or the non-closure" % (pop, ex))
if pop < floor:
    print("ERROR\tonly %d mention(s) of 65,281 (floor %d) - this gate is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 41 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 saw=""
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   saw=1; echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b calls the 65,281 productive cells the whole space"
             echo "         $c"
             echo "         The depth-3 C2/C5-feasible space is 158,364 cells (4,382 G-orbits, G-closed)."
             echo "         The 65,281 are its 41.2% productive subset and are NOT G-closed."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ -n "$saw" ] || { echo "  [FAIL] GATE 41 printed no census line — the scan did not complete."; return 1; }
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every all-cells statement about 65,281 names the ambient 158,364, the 41.2% fraction,"
  echo "       or the fact that the productive subset is not G-closed"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 42 — the x15-17 weakest-remaining-boundary band must be labelled illustrative
#           EVERYWHERE it is published, the figure generator included.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, charge 14's prescribed mechanisation — "every figure
# literal hard-coded in `viz/report_figures.py` must appear in a file under
# `reports/evidence/`".
#
# 🔴 THE PRESCRIBED GATE IS NOT WHAT SHIPPED, AND THE REASON IS MEASURED, NOT ARGUED. The
# literal-presence check was built first and INVERTS on its own inputs:
#     7.49e-4    (measured S(1), archived)      -> absent from reports/evidence/  [would FAIL]
#     9.39e-7, 4.27e-10, 6.34e-13 (measured)    -> absent from reports/evidence/  [would FAIL]
#     17.0, 15.0 (the two ILLUSTRATIVE literals -> present as substrings of unrelated
#                 this charge exists to catch)      evidence numerals             [would PASS]
# The archived S(k) artifacts record per-candidate `est=1.689464e+24` values; S(k) is a
# survival FRACTION derived from them, so it is nowhere in the files verbatim. A gate in the
# prescribed shape would fail the four numbers that are measured, pass the two that are not,
# and report a green tree as broken. Closing the gap properly means recomputing S(k) from
# the est values against a published definition of the candidate set — a numerical
# re-derivation, not a documentation gate, and the definition of "weakest" it needs is
# itself unpublished (that is charge 14's other half, still open).
#
# WHAT SHIPS INSTEAD is the invariant the 2026-09-02 correction actually established, and it
# is the half that is fully checkable: the band's STATUS must be identical everywhere it is
# published. THE DEFECT: the x15-17 bracket shipped for two months as MEASURED at three
# sites in TR-4, one in SEARCH_SPACE_SIZE.md and two literals in viz/report_figures.py,
# under a figure legend that said "(measured)". The tree ships two S(k) artifacts and both
# are greedy chains; no weakest-remaining chain, no command for one, and no definition of
# "weakest" is published.
#
# 🔴 IT SPANS MARKDOWN AND A GENERATOR, which is why it is not a GATE 3 registry row. The
# rendered legend text inside a PNG is ungreppable — the same reason GATE 6 exists — so the
# generator's own `label=` string is the only place the published wording can be checked.
gate_band_status() {
  echo "== GATE 42: the x15-17 weakest-remaining band must be labelled illustrative everywhere =="
  local FLOOR=5
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor = int(sys.argv[1])
files = corpus('*.md') + corpus('viz/*.py')
BAND = re.compile(r'(?:×|x)\s?15\s?[-–]\s?17|15\s?[-–]\s?17\s?(?:/|per )boundary|weakest[- ]remaining[- ]boundary', re.I)
# The status the correction fixed on. Any one of these marks the band as unreproduced.
MARK = re.compile(r'illustrative|not reproducible|NOT measured|no measurement behind', re.I)
# A revision row or the append-only ledger narrating the correction QUOTES the old status.
# 🔴 NARROWED AFTER A MEASURED FALSE CLEAR. This first read
# `published as measured|said|read|BEFORE\.|Registered as RP-|Corrected 20\d\d`. At block
# scope `Corrected 20\d\d` matches ANY dated correction anywhere in the paragraph, and
# SEARCH_SPACE_SIZE.md's pre-fix block carries an unrelated "corrected 2026-07-04" about
# the identifying-set size — so the gate cleared one of the five sites this charge exists
# to catch, silently. The narration marker has to be about THIS band's status, not about
# the paragraph having a correction somewhere in it.
NARR = re.compile(r'published as measured|was published as|BEFORE\.|Registered as RP-', re.I)
REV  = re.compile(r'^\s*\|\s*\*{0,2}v?\d+\.\d+[^|]*\|\s*20\d\d-\d\d-\d\d\s*\|')
# 🔴 CONTIGUOUS-BLOCK SCOPE, AND A LINE-SCOPE DRAFT WAS MEASURED FAILING BOTH ITS OWN
# SITES. The marker sits on the NEXT physical line at both places it matters:
# TR-4:174 ends "…reported roughly ×15–17 per boundary — but ⚠ **that" and :175 opens
# "band is not reproducible from published material"; report_figures.py:796 is the bracket
# comment and :797 the "ILLUSTRATIVE, not measured" one. A line-scope needle reports two
# [FAIL]s on correct prose — the hard-wrap blindness this suite has already been bitten by.
# The unit is the maximal run of non-blank lines: a paragraph, or a comment block and the
# call it annotates. That is a real syntactic unit, not a +-N line window.
def blocks(t):
    out, buf, start = [], [], 1
    for i, l in enumerate(t.split("\n"), 1):
        if l.strip():
            if not buf:
                start = i
            buf.append(l)
        elif buf:
            out.append((start, " ".join(" ".join(buf).split())))
            buf = []
    if buf:
        out.append((start, " ".join(" ".join(buf).split())))
    return out
pop = exn = 0
for f in files:
    t = read(f)
    if t is None: continue
    for i, blk in blocks(t):
        if not BAND.search(blk):
            continue
        pop += 1
        if MARK.search(blk):
            continue
        if REV.match(blk) or NARR.search(blk) or f == 'documentation/CORRECTIONS.md':
            exn += 1
            continue
        print("HIT\t%s\t%d\t%s" % (f, i, blk[:150]))
print("POP\t%d block(s) publish the x15-17 band, %d narrating the correction (exempt)" % (pop, exn))
if pop < floor:
    print("ERROR\tonly %d x15-17 band site(s) (floor %d) - this gate is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 42 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 saw=""
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   saw=1; echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b publishes the x15-17 band with no illustrative marker"
             echo "         $c"
             echo "         Both archived S(k) artifacts are GREEDY chains. No weakest-remaining chain,"
             echo "         no command for one, and no published definition of 'weakest' — the band is"
             echo "         not reproducible from published material and must say so."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ -n "$saw" ] || { echo "  [FAIL] GATE 42 printed no census line — the scan did not complete."; return 1; }
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every published x15-17 band site, figure generator included, is labelled illustrative"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 43 — an exact anchor cannot land in METHODS without moving TR-4's coverage line.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, charge 15's prescribed mechanisation — the exact
# integer at reports/METHODS.md:75 "should be tied to TR-4's coverage line so that a future
# exact anchor cannot land in METHODS without failing TR-4's 'Coverage: N of N'".
# THE DEFECT: |C1-C7| with C3 dropped became exact on 2026-07-25/26 (two instruments: an IE
# pinned-step recount and an independent mask-DP recount of a different algorithm class).
# METHODS labelled it a third independent estimator-calibration anchor. TR-4's calibration
# table kept "Coverage: 2 of 2" and "With n=2" for six weeks, until P34 found it by hand.
#
# 🔴 DERIVED VALUES ARE NOT ANCHORS, and the distinction is drawn from the row's own words.
# METHODS:79 publishes 45,710,469,949,549,241,251,504,669,632,357,466,112 as **exact** — it
# is |C1nC2nC4nC5|/24, "(= N/24 of the two-instrument count above)". Dividing an anchor by
# 24 does not calibrate an estimator against anything, and that integer correctly appears
# nowhere in TR-4's coverage table. A leg that required every **exact** integer in METHODS
# to appear in TR-4 reports it as a defect; measured, it is the gate's only false positive.
#
# 🔴 THE COVERAGE LINE MUST BE READ LIVE, NOT FROM THE REVISION HISTORY. TR-4 contains two
# `Coverage: N of M` strings: the live one at :174 ("3 of 3") and "2 of 2" inside v1.25's
# revision row, which is the row RECORDING this very correction. Reading the wrong one
# inverts the gate's verdict, so revision rows are excluded by shape before the match.
gate_anchor_coverage() {
  echo "== GATE 43: METHODS exact anchors vs TR-4's Coverage: N of N =="
  require_tracked "reports/METHODS.md" "GATE 43" || return 1
  require_tracked "reports/TR4_SIZE_OF_THE_SPACE.md" "GATE 43" || return 1
  local out
  out=$( { _g1_prelude; cat <<'PY'
INT = re.compile(r'\b\d{1,3}(?:,\d{3}){8,}\b')
# A row whose value is computed FROM another row is not an independent calibration anchor.
DERIV = re.compile(r'=\s*N\s*/\s*24|/24 of the|derived from|of the two-instrument count above', re.I)
REV   = re.compile(r'^\s*\|\s*\*{0,2}v?\d+\.\d+[^|]*\|\s*20\d\d-\d\d-\d\d\s*\|')
m_txt = read('reports/METHODS.md')
t_txt = read('reports/TR4_SIZE_OF_THE_SPACE.md')
if m_txt is None or t_txt is None:
    print("ERROR\tan input report is unreadable - NOTHING was checked")
    raise SystemExit(0)
anchors, derived = [], 0
for i, l in enumerate(m_txt.split("\n"), 1):
    if '**exact**' not in l or REV.match(l):
        continue
    for m in INT.finditer(l):
        if DERIV.search(l):
            derived += 1
        else:
            anchors.append((i, m.group(0)))
missing = [(i, v) for i, v in anchors if v not in t_txt]
for i, v in missing:
    print("HITA\tMETHODS.md\t%d\t%s" % (i, v))
# the LIVE coverage line only — revision rows quote the superseded one
cov = None
for i, l in enumerate(t_txt.split("\n"), 1):
    if REV.match(l):
        continue
    mm = re.search(r'Coverage:\s*(\d+)\s*of\s*(\d+)', l)
    if mm:
        cov = (i, int(mm.group(1)), int(mm.group(2)))
        break
if cov is None:
    print("ERROR\tTR-4 publishes no live 'Coverage: N of N' line - the gate's anchor is gone and it checked nothing")
else:
    i, n, d = cov
    if n != d:
        print("HITC\t%d\tCoverage: %d of %d - the two halves disagree" % (i, n, d))
    elif n != len(anchors):
        print("HITC\t%d\tCoverage: %d of %d, but METHODS publishes %d exact estimator-calibration anchor(s)" % (i, n, d, len(anchors)))
print("POP\t%d exact estimator-calibration anchor(s) in METHODS (%d derived value(s) excluded); TR-4 coverage %s"
      % (len(anchors), derived, ("%d of %d" % (cov[1], cov[2])) if cov else "ABSENT"))
if not anchors:
    print("ERROR\tMETHODS publishes no exact anchors (floor 1) - this gate is measuring nothing")
PY
} | python3 - ) || { echo "  [FAIL] GATE 43 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 saw=""
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      POP)   saw=1; echo "  [info] $a" ;;
      HITA)  echo "  [FAIL] reports/$a:$b publishes exact anchor $c"
             echo "         — it appears nowhere in TR-4, so TR-4's coverage line cannot account for it."
             rc=1 ;;
      HITC)  echo "  [FAIL] reports/TR4_SIZE_OF_THE_SPACE.md:$a $b"
             echo "         An exact anchor landing in METHODS must move this line in the same change."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  [ -n "$saw" ] || { echo "  [FAIL] GATE 43 printed no census line — the scan did not complete."; return 1; }
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] every exact estimator-calibration anchor in METHODS appears in TR-4, and TR-4's"
  echo "       live coverage line accounts for exactly that many"
  return 0
}

# ----------------------------------------------------------------------------------
# GATE 44 — a null verdict about an analysis the shipped report contradicts.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P30 / Codex V2-F30 #4. The row states the
# corpus-widening requirement in as many words: "`example/report.txt` is NOT in GATE 3's
# corpus (`DOCS=$(git ls-files '*.md')` plus `reports/evidence/**` non-markdown), so the
# corpus needs widening as part of this."
# THE DEFECT: MCKENNA.md:88 published "the `--fft` shows no frequencies above the white
# noise floor" while the report shipped IN THE SAME REPOSITORY printed floor 0.1741,
# magnitude 0.4266 at frequency 24 — 2.45x the floor — and summarised its own count as
# `Frequencies above 2x noise floor: 1/31`. Nothing in the suite compared the two.
#
# 🔴 THE REPORT IS AN INPUT, NOT A SCANNED DOCUMENT. The widening is deliberately narrow:
# example/report.txt is READ for its own summary line and never added to the prose corpus.
# Widening DOCS itself would put ~1,700 lines of generated analysis output under every
# needle in GATES 1, 3, 8 and 13, which is a different change with a different blast radius.
# The count is parsed from the report, so if the analysis ever legitimately finds nothing
# the gate stops demanding a hedge on its own — the verdict tracks the artifact.
#
# 🔴 FAIL-CLOSED ON AN UNREADABLE REPORT. If example/report.txt is missing, or its summary
# line is reworded, the gate ERRORs rather than reporting clean: a null-verdict scan whose
# contradicting evidence could not be loaded has checked nothing. This is the 46-instance
# fail-open class (roae-private FINDING_FAILOPEN_CLASS_2026_08_30.md) and the reason the
# parsed count is printed on every run.
gate_report_verdict() {
  echo "== GATE 44: a null verdict contradicted by the report shipped beside it =="
  require_tracked "example/report.txt" "GATE 44" || return 1
  # FLOOR 2 = the two surviving copies of the retired verdict inside the markers that
  # withdrew it (CORRECTIONS.md and MCKENNA.md's own "Corrected 2026-09-02" parenthetical).
  # MEASURED, not chosen: the corrected corpus states no live null verdict, so this gate is
  # a REGRESSION GUARD, and the floor is keyed to the narration copies because they are what
  # would have to disappear for the needle to have gone blind. Stated rather than averaged
  # away, exactly as GATE 35's one-heading population is.
  local FLOOR=2
  local out
  out=$( { _g1_prelude; cat <<'PY'
floor = int(sys.argv[1])
rep = read('example/report.txt')
if rep is None:
    print("ERROR\texample/report.txt is unreadable - the contradicting evidence could not be loaded, so NOTHING was checked")
    raise SystemExit(0)
m = re.search(r'Frequencies above 2x noise floor:\s*(\d+)\s*/\s*(\d+)', rep)
if not m:
    print("ERROR\texample/report.txt no longer prints its 'Frequencies above 2x noise floor: N/M' summary - this gate's evidence anchor is gone and it checked nothing")
    raise SystemExit(0)
hits, bins = int(m.group(1)), int(m.group(2))
floor_v = re.search(r'White noise floor:\s*([\d.]+)', rep)
print("EVID\t%d\t%d\t%s" % (hits, bins, floor_v.group(1) if floor_v else "?"))
# A NULL VERDICT about the spectrum: the analysis found nothing above the floor.
NULL = re.compile(r'(?:shows?|showed|showing|finds?|found|reveals?|with)\s+no\s+(?:significant\s+)?'
                  r'(?:frequenc\w+|peaks?|magnitudes?|periodicit\w+|structure)[^.]{0,60}?'
                  r'(?:above|over|exceed\w*)[^.]{0,30}?noise floor'
                  r'|nothing\s+(?:rises?|rose|is|was)?\s*above\s+the\s+(?:white\s+)?noise floor'
                  r'|no\s+frequenc\w+\s+above\s+the\s+(?:white\s+)?noise floor', re.I)
# A correction quoting the verdict it withdrew, or a hypothetical, is doing its job.
NARR = re.compile(r'Corrected 20\d\d|CORRECTED 20\d\d|said\b|used to claim|BEFORE\.|RP-[0-9a-f]{8}'
                  r'|may not\b|might not\b|even real\b|would not\b', re.I)
pop = ex = 0
if hits > 0:
    for f in corpus():
        t = read(f)
        if t is None: continue
        flat, starts = flatten(t)
        for mm in NULL.finditer(flat):
            pop += 1
            s = sent(flat, mm.start(), mm.end())
            if f == 'documentation/CORRECTIONS.md' or NARR.search(s) or quoted(s, s.find(mm.group(0)) + len(mm.group(0))):
                ex += 1
                continue
            print("HIT\t%s\t%d\t%s" % (f, lno(starts, mm.start()), " ".join(mm.group(0).split())[:130]))
print("POP\t%d null-spectrum verdict(s) in the corpus, %d narrating or hypothetical (exempt)" % (pop, ex))
# The needle must remain able to see SOMETHING. The corpus carries the retired verdict inside
# its correction markers; if even those vanish the vocabulary has drifted and the gate is blind.
if pop < floor:
    print("ERROR\tonly %d null-spectrum verdict(s) matched (floor %d) - the vocabulary has drifted out of this gate's reach and it is measuring nothing" % (pop, floor))
PY
} | python3 - "$FLOOR" ) || { echo "  [FAIL] GATE 44 scanner failed — NOTHING was checked."; return 1; }
  local rc=0 saw="" sawe=""
  while IFS=$'\t' read -r tag a b c; do
    case "$tag" in
      ERROR) echo "  [FAIL] $a"; rc=1 ;;
      EVID)  sawe=1
             echo "  [info] example/report.txt reports $a of $b frequency bins above 2x its white-noise floor of $c" ;;
      POP)   saw=1; echo "  [info] $a" ;;
      HIT)   echo "  [FAIL] $a:$b publishes a NULL spectrum verdict the shipped report contradicts"
             echo "         \"$c\""
             echo "         example/report.txt prints a magnitude above 2x its own noise floor and"
             echo "         summarises the count itself. The verdict must match the artifact, or say"
             echo "         why the artifact's own threshold does not support one."
             rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  if [ -z "$sawe" ]; then
    echo "  [FAIL] GATE 44 never read example/report.txt's summary — the evidence side did not run."
    return 1
  fi
  [ -n "$saw" ] || { echo "  [FAIL] GATE 44 printed no census line — the scan did not complete."; return 1; }
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] no document states a null spectrum verdict that the shipped report contradicts"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 45 — a published Net bracket must be the arithmetic of the cells beside it.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P31 / Codex V2-F11 #3 — "for every row
# publishing a Net bracket beside its own compression and cost cells, assert
# net_endpoint == compression − cost_endpoint".
# THE DEFECT (TR-9 v1.7, 2026-07-10, live until commit 6ffab778 on 2026-09-02): the C2
# sensitivity row published compression 4.5, cost `~2.6–4`, net `≈ 0 (+2.0 to −4)`. The −4 is
# the maximum COST with its sign flipped, not 4.5 − 4 = +0.5. Three rows, one table, and the
# same table mirrored in DESCRIPTION_LENGTH.md; nothing in the suite subtracted.
#
# WHAT IS JUDGED, exactly. Every markdown table whose header names a compression column, at
# least one cost column and a Net column. Per row: K = the FIRST number in the compression
# cell (DESCRIPTION_LENGTH's C1 cell is "146.3 (C1) + 6.0 (C4)" — the bold lead figure is the
# rule's compression, C4's 6.0 is a rider), costs = every number in every cost cell,
# net = the first "a to b" bracket in the Net cell, else its first number. Parenthetical
# asides are stripped from compression and cost cells before numbers are read (TR-9's C5
# cost reads "15.7 (marginal-consistent: 31 boundary transitions)" — the 31 is a count of
# transitions, not a price), but NOT from the Net cell, because DESCRIPTION_LENGTH writes its
# bracket inside one: "≈ 0 (+0.5 to +2.0)". U+2212 minus is a minus; an en-dash between two
# numbers is a range. The rule: every published net endpoint must equal K − c for some cost
# figure c, AND every K − c must be published — a bracket that drops an endpoint is as wrong
# as one that invents one. Tolerance is the half-unit of the last printed digit of each of
# the three figures summed, so "+133 to +146" against 146.3 − 13 = 133.3 passes on its own
# integer precision and "+2.0" against 4.5 − 2.6 = 1.9 passes on its one decimal; the
# sign-flipped "−4" against +0.5 is 4.5 off and cannot.
#
# ROWS THIS DOES NOT JUDGE, and prints as [note] so the exemption cannot grow unseen: a cost
# cell that says "underived" or "circular" (C3, C6+C7, the Schulz rule — a statement cost
# the corpus declines to price cannot be subtracted), and a row with no numeric compression,
# cost or net, and a Net cell whose bracket has a non-numeric endpoint ("≈ 0 to small +", the
# Schulz row in TR-9 — a qualitative bracket has no endpoint to subtract; it is printed, not
# judged). The judged population is printed and fewer than 3 rows is an ERROR: the two
# tables hold three priced rows each, so a smaller count means the parser lost a table.
#
# MEASURED BEFORE LANDING (2026-09-02, local clone overlaid with the tree's edits):
#   * the pre-fix TR-9 file (git show 6ffab778^) -> HIT on the C2 row, rc 1; a real
#     baseline, not a planted string;
#   * mutation: flip the sign of TR-9's live C5 bracket -> HIT, rc 1;
#   * mutation: delete the Net header word from both tables -> population 0 -> ERROR, rc 1
#     (a gate whose corpus silently emptied is a fail-open, not a pass);
#   * the live tree: TR-9's three rows pass; DESCRIPTION_LENGTH.md's C2 row FAILS — its cost
#     cell still reads "~3" while its bracket "+0.5 to +2.0" is 4.5 − {4, 2.585}, the TR-9
#     pair. The backlog row that queued this gate predicted exactly that ("it would still
#     fire today on DESCRIPTION_LENGTH.md", owned by Codex V2-F35 #3). The finding is real and
#     is reported, not exempted.
gate_net_brackets() {
  echo "== GATE 45: a Net bracket must equal compression minus each cost figure beside it =="
  local FLOOR=3 out
  out=$(printf '%s\n' "$DOCS" | python3 -c '
import sys, io, re
files=[l.strip() for l in sys.stdin if l.strip()]
if not files: print("EMPTY"); sys.exit(0)
PAREN=re.compile(r"\([^()]*\)")
NUM=re.compile(r"(?<![0-9.])([+-]?[0-9]+(?:\.[0-9]+)?)(?![0-9])")   # ASCII digits: a superscript footnote mark is not a digit
BR=re.compile(r"([+-]?[0-9]+(?:\.[0-9]+)?)\s*(?:to|–)\s*([+-]?[0-9]+(?:\.[0-9]+)?)")
UNPRICED=re.compile(r"underived|circular", re.I)
SPLIT=re.compile(r"(?<!\\)\|")
def norm(s): return s.replace("−","-").replace("**","").replace("~","")
def dec(s): return len(s.split(".")[1]) if "." in s else 0
def cells(line): return [p.strip() for p in SPLIT.split(line.strip().strip("|"))]
def tol(a,b,c): return 0.5*10**-dec(a)+0.5*10**-dec(b)+0.5*10**-dec(c)+1e-9
tables=0; judged=0; skipped=[]
for f in files:
    try: lines=io.open(f,encoding="utf-8").read().splitlines()
    except OSError as e: print("READFAIL\t%s\t%s"%(f,e)); continue
    i=0
    while i<len(lines):
        if not lines[i].lstrip().startswith("|"): i+=1; continue
        j=i
        while j<len(lines) and lines[j].lstrip().startswith("|"): j+=1
        block=lines[i:j]; lo=[h.lower() for h in cells(block[0])]
        ci=[k for k,h in enumerate(lo) if "compression" in h]
        ni=[k for k,h in enumerate(lo) if re.search(r"\bnet\b",h)]
        si=[k for k,h in enumerate(lo) if "cost" in h]
        if ci and ni and si and len(block)>2:
            tables+=1
            for r,row in enumerate(block[2:],start=i+3):
                c=cells(row)
                if len(c)<=max(ci[0],ni[0],max(si)): continue
                name=c[0][:60]
                ms=NUM.search(norm(PAREN.sub("",c[ci[0]])))
                costs=[]; unpriced=False
                for k in si:
                    if UNPRICED.search(c[k]): unpriced=True
                    costs+=NUM.findall(norm(PAREN.sub("",c[k])))
                if unpriced: skipped.append((f,r,name,"cost cell says underived/circular")); continue
                if not ms or not costs: skipped.append((f,r,name,"no numeric compression or cost figure")); continue
                net_s=norm(c[ni[0]]); mb=BR.search(net_s)
                if mb: nets=[mb.group(1),mb.group(2)]
                elif re.search(r"\bto\b",net_s): skipped.append((f,r,name,"qualitative net bracket (\"%s\" has a non-numeric endpoint)"%net_s[:40])); continue
                else:
                    mn=NUM.search(PAREN.sub("",net_s))
                    if not mn: skipped.append((f,r,name,"no numeric net")); continue
                    nets=[mn.group(1)]
                judged+=1
                K=ms.group(1); exp=[(float(K)-float(x),x) for x in costs]
                bad=[n for n in nets if not any(abs(float(n)-e)<=tol(n,x,K) for e,x in exp)]
                miss=[x for e,x in exp if not any(abs(float(n)-e)<=tol(n,x,K) for n in nets)]
                if bad or miss:
                    print("HIT\t%s\t%d\t%s\tcompression %s, cost {%s} -> expected net {%s}; published {%s}; published-but-unexplained {%s}; expected-but-unpublished {%s}"%(
                        f,r,name,K,", ".join(costs),", ".join("%.1f"%e for e,x in exp),", ".join(nets),", ".join(bad) or "-",", ".join("%.1f"%(float(K)-float(x)) for x in miss) or "-"))
        i=j
for s in skipped: print("SKIP\t%s\t%d\t%s\t%s"%s)
print("POP\t%d\t%d\t%d"%(tables,judged,len(skipped)))
') || { echo "  [FAIL] GATE 45 scanner failed — NOTHING was checked."; return 1; }
  grep -qx 'EMPTY' <<<"$out" && { echo "  [FAIL] corpus reached GATE 45 empty."; return 1; }
  local pt pj ps
  IFS=$'\t' read -r pt pj ps < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pj:-}"; then
    echo "  [FAIL] GATE 45 printed no population census — the scan did not complete."; return 1
  fi
  if [ "$pj" -lt "$FLOOR" ]; then
    echo "  [FAIL] GATE 45 judged only $pj priced ledger row(s) across $pt table(s) (floor $FLOOR). The"
    echo "         TR-9 and DESCRIPTION_LENGTH ledgers hold three priced rows each; a smaller count"
    echo "         means a table lost its Compression/cost/Net header or a cell stopped parsing, and"
    echo "         a gate whose population silently shrank has not cleared what it no longer reads."
    return 1
  fi
  local rc=0 tag f ln name detail
  while IFS=$'\t' read -r tag f ln name detail; do
    case "$tag" in
      HIT)  echo "  [FAIL] $f:$ln  row '$name': $detail"; rc=1 ;;
      READFAIL) echo "  [FAIL] $f could not be read ($ln) — a file this gate cannot read is not a file it cleared."; rc=1 ;;
      SKIP) echo "  [note] $f:$ln  row '$name' NOT judged: $detail" ;;
    esac
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         A net endpoint is compression minus a cost endpoint, at the row's own printed"
    echo "         precision. Fix the cell that is wrong (TR-9 2026-09-02 restated the C2 net as"
    echo "         +0.5 to +2.0 = 4.5438 − {4, 2.585}); do not widen the tolerance."
    return 1
  fi
  echo "  [ok] every published Net bracket is compression minus its cost figures — $pj priced row(s)"
  echo "       across $pt ledger table(s) judged, $ps row(s) skipped as unpriced/non-numeric (listed above)"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 46 — HISTORY.md's findings table may not hold a scope-free universal on the 31.6M dataset.
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P43 / Codex V2-F12 #2 — inside
# documentation/HISTORY.md's "What actually advanced understanding" table, a Status cell
# containing "universally"/"always"/"proven" whose Evidence cell names the 31.6M dataset
# must FAIL.
# THE DEFECT (live until commit 4b320e5c, 2026-09-02): the "Shift pattern (2 options at
# positions 3-19)" row carried Status "Observed universally; driven by C3 not budget" against
# Evidence "Analysis of 31.6M solutions" — a dataset the SAME table records as undersampled by
# the file-collision bug. On the corrected 742M only 2.926% conform.
#
# THE DESIGN HAZARD THE BACKLOG ROW NAMED, cleared here rather than encoded: the table has a
# live, CORRECT row whose Status reads "Proven for 31.6M dataset" — it contains both the status
# word and the dataset token, because it scopes itself in the Status cell. So the predicate is
# NOT `status-word AND 31.6M`. It is: the Evidence cell names a corrupted dataset (31.6M) AND
# the Status cell asserts a universal (universally/universal/always/proven/proved) AND the
# Status cell carries NO scope of its own (no "<n>M" dataset token and no word "dataset") AND
# the Status cell carries no supersession marker (superseded/corrected/retract/withdrawn — the
# corrected row quotes the withdrawn wording inside its own correction, and a correction is
# doing its job). The corrupted-dataset token list is hard-coded to 31.6M from the charge and
# printed with the population; widening it is a one-line edit that the [ok] line will show.
#
# POPULATION, printed and floored: the table must parse to >= 10 rows and >= 1 row whose
# Evidence names 31.6M, else ERROR — a heading rename or a column reorder would otherwise turn
# this into a gate over nothing.
#
# MEASURED BEFORE LANDING (2026-09-02, local clone): pre-P43 HISTORY.md (git show 4b320e5c^)
# -> HIT on the shift-pattern row, rc 1; live tree rc 0 with the "Proven for 31.6M dataset" row
# passing on its own scope; mutation (row "No scalar property uniquely identifies KW" given
# Evidence "...over 31.6M solutions" and Status "Proven") -> HIT rc 1; the same mutation with
# Status "Proven for 31.6M dataset" -> rc 0 (the hazard row, by construction); heading
# removed -> ERROR rc 1.
gate_history_scope() {
  echo "== GATE 46: HISTORY.md findings table — no scope-free universal whose evidence is the 31.6M dataset =="
  local F=documentation/HISTORY.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import sys, io, re
F=sys.argv[1]
HEAD="## What actually advanced understanding"
CORRUPT=["31.6M"]
UNIV=re.compile(r"\b(universally|universal|always|proven|proved)\b", re.I)
SCOPE=re.compile(r"\b[0-9]+(?:\.[0-9]+)?M\b|\bdataset\b", re.I)
MARK=re.compile(r"superseded|corrected|retract|withdrawn", re.I)
SPLIT=re.compile(r"(?<!\\)\|")
def cells(l): return [p.strip() for p in SPLIT.split(l.strip().strip("|"))]
try: lines=io.open(F,encoding="utf-8").read().splitlines()
except OSError as e: print("ERROR\t%s unreadable: %s"%(F,e)); sys.exit(0)
hs=[i for i,l in enumerate(lines) if l.strip()==HEAD]
if len(hs)!=1: print("ERROR\theading %r found %d times in %s (need exactly 1)"%(HEAD,len(hs),F)); sys.exit(0)
i=hs[0]+1
while i<len(lines) and not lines[i].lstrip().startswith("|") and not lines[i].startswith("#"): i+=1
if i>=len(lines) or not lines[i].lstrip().startswith("|"): print("ERROR\tno table directly under the heading"); sys.exit(0)
j=i
while j<len(lines) and lines[j].lstrip().startswith("|"): j+=1
block=lines[i:j]; hdr=[c.lower() for c in cells(block[0])]
ev=[k for k,c in enumerate(hdr) if "discovered" in c or "evidence" in c]; st=[k for k,c in enumerate(hdr) if "status" in c]
if not ev or not st: print("ERROR\ttable header lacks a How-discovered/Evidence or Status column: %s"%hdr); sys.exit(0)
ev=ev[0]; st=st[0]; rows=subj=exempt=scoped=0
for r,row in enumerate(block[2:],start=i+3):
    c=cells(row)
    if len(c)<=max(ev,st): continue
    rows+=1
    if not any(t in c[ev] for t in CORRUPT): continue
    subj+=1; S=c[st]
    if MARK.search(S): exempt+=1; continue
    if not UNIV.search(S): continue
    if SCOPE.search(S): scoped+=1; continue
    print("HIT\t%s\t%d\t%s\t%s"%(F,r,c[0][:70],S[:110]))
print("POP\t%d\t%d\t%d\t%d\t%s"%(rows,subj,exempt,scoped,",".join(CORRUPT)))
PY
) || { echo "  [FAIL] GATE 46 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 46 could not measure its subject: $err"; return 1; fi
  local pr ps pe pc tok
  IFS=$'\t' read -r pr ps pe pc tok < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5"\t"$6; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pr:-}"; then echo "  [FAIL] GATE 46 printed no population census — the scan did not complete."; return 1; fi
  if [ "$pr" -lt 10 ] || [ "$ps" -lt 1 ]; then
    echo "  [FAIL] GATE 46 parsed $pr row(s), $ps with Evidence naming {$tok}. The table holds >= 10 rows"
    echo "         and at least two 31.6M-evidenced rows; a smaller population is a parse failure, not a pass."
    return 1
  fi
  local rc=0 tag f ln name status
  while IFS=$'\t' read -r tag f ln name status; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f:$ln  row '$name' — Status '$status' is a scope-free universal, but its"
    echo "         Evidence cell names the 31.6M dataset, which this same table records as undersampled."
    echo "         Scope the verdict in the Status cell (\"... for the 31.6M dataset\"), or supersede it."
    rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] $pr findings rows parsed; $ps evidenced on {$tok}: $pe superseded/corrected (exempt), $pc self-scoped,"
  echo "       0 scope-free universals"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 47 — retracted phrasings in the NON-markdown corpus (`code-needles`).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md "A needle leg over solve.c/*.py/*.sh — 128 tracked text
# files are in NO needle scan. Needs an ALLOW mechanism first."
# THE GAP, MEASURED: GATE 3 scans `git ls-files '*.md'` plus reports/evidence/**. Every other
# tracked text file — solve.c, verify.c, every *.py and *.sh, the Lean sources, the TSV/JSON/TXT
# data — was in no needle scan at all. Two live emitters of registered-retracted claims were found
# on 2026-09-02 precisely because no registry row could reach them: solve.c:19 (a comment carrying
# the Q-353 wording fifteen lines below the block that withdrew it; retired ff804bb0) and
# solve.py:1649-1657 (the `--rules` banner printing the CX-02 "generative recipe" framing AT RUN TIME,
# four lines below the docstring that withdraws it; retired the same day, uncommitted).
#
# CORPUS: every tracked file that is not *.md, not under reports/evidence/ (GATE 3's half), and
# is text (`grep -I`, so .gz/.png/.mid are skipped BY CONTENT, not by a directory — .pdf was
# in this list until 2026-09-04, when the repository's only tracked PDF was removed), minus
# exactly THREE files named here and printed on every run, each of which holds withdrawn wording
# BY CONSTRUCTION: documentation/RETRACTED_PHRASES.tsv (the registry — every needle is in it),
# documentation/DOC_GATE_CODE_NEEDLE_ALLOW.tsv (this gate's allow table — same reason), and
# documentation/CORRECTIONS_INVENTORY.tsv (generated by scripts/corrections_inventory.sh from
# inline CORRECTED markers AND commit messages, so it quotes the wording every correction
# withdrew). MEASURED at build time: the wider population had 209 hits, 195 of them in that one
# file; a first cut tried a per-row construction rule keyed on the registry's allow column and
# it still fired on an inventory row that quotes a COMMIT MESSAGE (GIT-ae98df6), which no allow
# column describes. A named exclusion with a stated reason is the honest form; it is three files,
# each printed on the [ok] line, and widening it is a visible edit.
#
# MATCH RULE: identical to GATE 3 — fold_variants, then newline->space and runs collapsed, then a
# FIXED-STRING match of the folded, flattened needle. Comment markers are stripped per line before
# flattening (`*` already goes in fold_variants; a leading `#`, `//` or `--` does here), because a
# phrase hard-wrapped across two comment lines is the same phrase — solve.c's retired site was
# exactly that shape and a line-based grep could not see it.
#
# THE ALLOW MECHANISM, and why it cannot become a blanket exemption:
#   * an allowance is a ROW naming the FILE, the PHRASE (byte-identical to its registry row), a
#     MAXIMUM occurrence count, and an ANCHOR — one or more fixed strings, one of which must
#     precede EVERY allowed occurrence within 170 chars of the flattened file. The anchor is the
#     withdrawal CONSTRUCTION (`This read`, `once gave`, `WHAT WAS WRONG`, the gate's own
#     `fixed string` fixtures). A file-level allow would have hidden solve.c:19 (at ff804bb0^) behind the header
#     block that quotes the same phrase to withdraw it — and so would a COUNT: measured before
#     landing, the count-only first cut passed the pre-fix solve.c, because ff804bb0^ holds the
#     Q-353 phrase exactly once (the live :19 site) and the fixed file holds it exactly once too
#     (the quote that withdraws it). Six gates built the same day went green as no-ops on first
#     construction for the same reason; the anchor column is the fix, not the count;
#   * an occurrence NOT preceded by its row's anchor is a FAIL (a live use);
#   * MORE occurrences than `max` is a FAIL (a second use, even if anchored);
#   * ZERO occurrences is a FAIL too, printed by name: an unused allowance is a row that could
#     later hide a new use, so it is reported rather than tolerated;
#   * an allow row naming a phrase the registry does not hold is an ERROR (a typo'd phrase would
#     otherwise allow nothing and be silently "unused" — the ERROR makes the mismatch loud).
#
# POPULATION, printed and floored: >= 30 text files scanned and >= 1 registry phrase, else ERROR.
#
# MEASURED BEFORE LANDING (2026-09-02, local clone; the red trees are disposable git repos holding
# the historical files, never the shared worktree):
#   pre-fix solve.c (`git show ff804bb0^:solve.c`)  -> HIT: the Q-353 wording's one occurrence is not
#     preceded by `This read` (the :19 live site), rc 1 — with the count-only rule it was rc 0
#   HEAD solve.py (the :1581 banner still printing)  -> NO HIT: the banner's literal strings are not
#     registered needles (the registry's CX-02 row holds a different spelling of the recipe
#     claim) — the row's premise "registered-retracted framing" is true of the FRAMING and false
#     of the STRING, so this gate could not have caught solve.py:1581 with today's registry; the
#     two banner strings need registering (prose lane) for the leg to reach that class
#   live tree                                        -> rc 0, 14 allowances all used at their max
#   mutation: a needle planted in a live .py         -> HIT rc 1
#   mutation: allow row deleted                      -> HIT on that file rc 1 (the allowance was
#     load-bearing, so its removal must fire)
#   mutation: allow row max lowered by 1             -> HIT (count > max) rc 1
#   mutation: allow row anchor replaced by an absent string -> HIT (unanchored occurrence) rc 1
#   mutation: allow row for a phrase the file lacks  -> "unused allowance" FAIL rc 1
#   mutation: allow row phrase misspelled            -> ERROR (not in registry) rc 1
#   mutation: allow table removed                    -> ERROR rc 1
gate_code_needles() {
  echo "== GATE 47: retracted phrasings in the NON-markdown corpus (solve.c, *.py, *.sh, *.lean, data) =="
  local reg="documentation/RETRACTED_PHRASES.tsv" allow="documentation/DOC_GATE_CODE_NEEDLE_ALLOW.tsv"
  require_rows "$reg" "Zero rows silences every retraction check." || return 1
  require_tracked "$reg" "The retraction registry IS this gate; with it gone, zero phrases are checked."
  case $? in 1) return 0;; 2) return 1;; esac
  if [ ! -f "$allow" ]; then
    echo "  [FAIL] $allow is missing. Without it this gate fires on its own needle-holding sources, so it"
    echo "         cannot distinguish a live survivor from a correction doing its job — NOTHING was judged."
    return 1
  fi
  require_final_newline "$allow" || { echo "  [FAIL] $allow does not end with a newline — its last row is dropped by read"; return 1; }
  local files f flatdir n=0
  files=$(git ls-files) || { echo "  [FAIL] git ls-files failed — the corpus could not be enumerated."; return 1; }
  flatdir=$(mktemp -d "${TMPDIR:-/tmp}/docgates_codeneedle.XXXXXX") || { echo "  [FAIL] mktemp failed"; return 1; }
  local skipped_named=0
  for f in $files; do
    case "$f" in
      *.md|reports/evidence/*|scripts/doc_gates.d/*) continue;;  # GATE 3's corpus
      "$reg"|"$allow"|documentation/CORRECTIONS_INVENTORY.tsv) skipped_named=$((skipped_named+1)); continue;;   # withdrawn wording by construction, by NAME
    esac
    [ -f "$f" ] || continue                                    # tracked-but-deleted: preflight's finding
    grep -qI . "$f" 2>/dev/null || continue                    # binary by CONTENT (grep -I), not by directory
    mkdir -p "$flatdir/$(dirname "$f")"
    # strip leading comment markers, fold like GATE 3, flatten to one whitespace-collapsed line
    { if [ "$f" = scripts/doc_gates.sh ]; then bash scripts/doc_gates.d/logical_source.sh; else cat "$f"; fi; } | sed -E 's@^[[:space:]]*(#|//|--)+[[:space:]]?@@' | fold_variants | tr '\n' ' ' | tr -s ' ' > "$flatdir/$f"
    n=$((n+1))
  done
  if [ "$n" -lt 30 ]; then
    echo "  [FAIL] GATE 47 flattened only $n text file(s) (floor 30) — the corpus enumeration or the text"
    echo "         filter broke; a gate whose population silently emptied has cleared nothing."
    rm -rf "$flatdir"; return 1
  fi
  local out
  out=$(python3 - "$reg" "$allow" "$flatdir" <<'PY'
import sys, os, io, subprocess
reg, allow, flatdir = sys.argv[1:4]
WIN=170   # chars of preceding flattened text an allow-row anchor must fall in (stated in the table header)
def fold(s):
    p = subprocess.run(["bash","-c",'source /dev/stdin <<<"$(sed -n "/^fold_variants() {/,/^}/p" scripts/doc_gates.sh)"; fold_variants'],
                       input=s, capture_output=True, text=True)
    return " ".join(p.stdout.split())
rows=[]
for l in io.open(reg, encoding="utf-8"):
    # Q-761: reg_row_kind's rule — a needle starting '#7' is a row, not a comment.
    if not l.strip() or l.split("\t")[0].rstrip("\n") == "#" or l.startswith("# "): continue
    c=l.rstrip("\n").split("\t")
    if len(c)<2: continue
    rows.append((c[0], c[1], c[2] if len(c)>2 else ""))
if not rows: print("ERROR\tregistry parsed to zero rows"); sys.exit(0)
phrases={p for p,_,_ in rows}
allows={}
for ln,l in enumerate(io.open(allow, encoding="utf-8"),1):
    if not l.strip() or l.startswith("#"): continue
    c=l.rstrip("\n").split("\t")
    if len(c)<5 or not c[2].isdigit() or not c[3].strip(): print("ERROR\t%s:%d malformed allow row (need file<TAB>phrase<TAB>max<TAB>anchor<TAB>reason)"%(allow,ln)); sys.exit(0)
    if c[1] not in phrases: print("ERROR\t%s:%d allows a phrase the registry does not hold: %r"%(allow,ln,c[1])); sys.exit(0)
    anchors=c[3].split("|"); ("" in anchors) and (print("ERROR\t%s:%d empty anchor: a bare || or an edge | in the anchor column splits a field (Q-525)"%(allow,ln)), sys.exit(0))
    allows[(c[0],c[1])]=(int(c[2]),ln,[" ".join(fold(a).split()) for a in anchors])
# flatten every registry needle ONCE via the gate's own fold_variants (same bytes GATE 3 matches on)
needles={}
for p,_,_ in rows: needles[p]=fold(p)
files=[]
for d,_,fs in os.walk(flatdir):
    for fn in fs: files.append(os.path.relpath(os.path.join(d,fn), flatdir))
texts={f: io.open(os.path.join(flatdir,f), encoding="utf-8", errors="replace").read() for f in files}
used=set(); hits=0
import re as _re, hashlib as _hl
def _hflat(t):   # the gates' flatten: newline -> space, runs of spaces collapse
    return _re.sub(" +", " ", t.replace("\n", " "))
for p,allowcol,note in rows:
    # CX-230: a HASHED row (`sha256:<hex>/<n>`, doc_gates.sh hashed_row_parse) is matched by digest
    # of the n-character span at every dollar sign, in the flattened copy and in the raw file.
    hm=_re.fullmatch(r"sha256:([0-9a-f]{64})/([1-9][0-9]*)", p)
    if hm:
        hh,hn=hm.group(1),int(hm.group(2))
        for f in files:
            try: raw=_hflat(io.open(f, encoding="utf-8", errors="surrogateescape").read())
            except OSError: raw=""
            for t in (texts[f], raw):
                i=t.find("$"); hit=False
                while i>=0 and not hit:
                    hit=_hl.sha256(t[i:i+hn].encode("utf-8","surrogateescape")).hexdigest()==hh; i=t.find("$",i+1)
                if hit:
                    print("HIT\t%s\tRP-%s (hashed row; the phrase is not restated)\t1\tno allow row (%s)"%(f,hh[:8],note[:90])); hits+=1; break
        continue
    np_=needles[p]
    if not np_: continue
    for f in files:
        cnt=texts[f].count(np_)
        if cnt==0: continue
        key=(f,p)
        if key in allows:
            mx,ln,anchors=allows[key]; used.add(key)
            if cnt>mx: print("HIT\t%s\t%s\t%d\tallowed max %d (allow row %d) — a NEW use beyond the quoted-to-withdraw site(s)"%(f,p,cnt,mx,ln)); hits+=1; continue
            # every occurrence must sit inside the withdrawal CONSTRUCTION the row names: one of its
            # anchors within WIN chars BEFORE it. A count alone passed the pre-fix solve.c (see header).
            t=texts[f]; i=0; k=0
            while True:
                j=t.find(np_,i)
                if j<0: break
                k+=1; pre=t[max(0,j-WIN):j]
                if not any(a in pre for a in anchors):
                    print("HIT\t%s\t%s\t%d\toccurrence %d is NOT preceded (within %d chars) by the row's anchor %s — a live use, not a quote-to-withdraw (allow row %d)"%(f,p,cnt,k,WIN,"|".join(anchors),ln)); hits+=1
                i=j+1
            continue
        print("HIT\t%s\t%s\t%d\tno allow row (%s)"%(f,p,cnt,note[:90])); hits+=1
for key,(mx,ln,_a) in sorted(allows.items(), key=lambda kv: kv[1][1]):
    if key not in used:
        print("STALE\t%s\t%s\t%d\tallow row %d matched nothing — the quoted site is gone; delete the row so it cannot hide a future use"%(key[0],key[1],mx,ln)); hits+=1
print("POP\t%d\t%d\t%d\t%d"%(len(files),len(rows),len(allows),len(used)))
PY
) || { echo "  [FAIL] GATE 47 scanner failed — NOTHING was checked."; rm -rf "$flatdir"; return 1; }
  rm -rf "$flatdir"
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 47 could not judge its corpus: $err"; return 1; fi
  local pf pp pa pu
  IFS=$'\t' read -r pf pp pa pu < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pf:-}"; then echo "  [FAIL] GATE 47 printed no population census — the scan did not complete."; return 1; fi
  if [ "$pf" -lt 30 ] || [ "$pp" -lt 1 ]; then
    echo "  [FAIL] GATE 47 judged $pf file(s) against $pp phrase(s) (floors 30 / 1) — population collapsed."; return 1
  fi
  local rc=0 tag f p cnt detail
  while IFS=$'\t' read -r tag f p cnt detail; do
    case "$tag" in
      HIT)   echo "  [FAIL] $f: retracted phrasing present $cnt time(s): \"$p\""; echo "         $detail"; rc=1 ;;
      STALE) echo "  [FAIL] $f: UNUSED allowance for \"$p\" (max $cnt)"; echo "         $detail"; rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         A code file may carry a registered phrase ONLY inside a block that quotes it to withdraw it,"
    echo "         and only with an allow row naming the file, the phrase, the count and the withdrawal anchor: $allow"
    return 1
  fi
  echo "  [ok] $pf non-markdown text files scanned against $pp registered phrases; $pu of $pa allowances used"
  echo "       at or under their max (excluded by NAME, withdrawn wording by construction: $reg, $allow,"
  echo "       documentation/CORRECTIONS_INVENTORY.tsv; reports/evidence/** and *.md are GATE 3's corpus)"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 48 — a sha change predicted for a NAMED prune must be hedged or evidenced (`sha-prediction`).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md "two gate legs the adjudication specified", leg (a), from
# prose batch P42 (Codex V2-F12): a public sentence asserting a sha change for a named prune must
# cite a before/after artifact or use "can"/"may". Red-test = PARITY_ALTERNATION.md's pre-P42
# §Consequences item 3; CIRCULAR_KING_WEN.md §"Status decision" must pass.
# THE DESIGN NOTE THE ROW CARRIED, honoured: the CIRCULAR_KING_WEN / TR-7 sentence DOES contain an
# unhedged "would ... open a new sha lineage", so a modal-verb needle fails its own red-test. What
# separates the two is that the CIRCULAR sentence carries an EVIDENCED byte-identity clause
# ("as a pure leaf-emission filter it would be byte-identical ... zero 5-wrap records exist in any
# slice") beside its prune clause, and PARITY's did not. So the predicate is:
#   SUBJECT   = a sentence (flattened, bold stripped) naming a prune AND a sha AND a change verb
#               (would/will change, changes the/node/canonical, opens a new sha lineage, would differ)
#   PASSES if = the same sentence hedges (can/may/might change|move|differ|open, "wherever it
#               fires", "empirical question") OR evidences (byte-identical, or a hex sha token of
#               8-64 digits — a measured before/after)
# Sentence scope, not paragraph: at paragraph scope four live paragraphs fired on correct prose
# (numbered-list blocks flatten into one paragraph); at sentence scope the live tree yields the
# populations printed below.
# POPULATION, printed and floored: >= 2 subject sentences, else ERROR (PARITY + CIRCULAR exist
# today; a smaller count means the sentence splitter or the fold broke).
# MEASURED BEFORE LANDING (2026-09-02): pre-P42 tree (`git show 4ba41c12^`) -> HIT on
# PARITY_ALTERNATION.md item 3 ("would change", no hedge, no sha), CIRCULAR_KING_WEN passes;
# live tree -> PARITY passes ("can change" + two hex shas), CIRCULAR passes, and ONE live finding:
# reports/TR6_PARITY_SKELETON.md §Sections (c) still carries the pre-P42 wording ("canonical shas
# — would change") — the sibling P42 did not sweep; it escaped GATE 3 because its wording drops
# the word "therefore" that the registered needle carries. Owner: the prose lane.
# Mutation: live PARITY sentence with "can" -> "would" and the shas removed -> HIT rc 1.
gate_sha_prediction() {
  echo "== GATE 48: a sha change predicted for a named prune is hedged or evidenced =="
  local out
  out=$(python3 - <<'PY'
import re, io, subprocess, sys
files=subprocess.run(["git","ls-files","documentation/*.md","reports/*.md"],capture_output=True,text=True).stdout.split()
files=[f for f in files if not f.startswith("reports/evidence/")]
SUBJ=lambda s: re.search(r"\bprunes?\b",s) and re.search(r"\bshas?\b|sha lineage",s) and re.search(r"would change|will change|changes? (the|node|canonical)|opens? a new sha lineage|would differ",s)
HEDGE=re.compile(r"\b(can|may|might) (change|move|differ|open)|byte-identical|\b[0-9a-f]{8,64}\b|wherever it fires|empirical question")
n=0
for f in files:
    try: t=io.open(f,encoding="utf-8").read()
    except OSError as e: print("ERROR\t%s unreadable: %s"%(f,e)); sys.exit(0)
    flat=" ".join(t.replace("*","").split())
    for s in re.split(r"(?<=[.!?])\s+(?=[A-Z(\[⚠\"])",flat):
        if re.match(r"\| *v\d", s): continue  # revision rows quote superseded wording (a version, Q-763)
        if not SUBJ(s): continue
        n+=1
        if HEDGE.search(s): continue
        print("HIT\t%s\t%s"%(f,s[:220]))
print("POP\t%d\t%d"%(n,len(files)))
PY
) || { echo "  [FAIL] GATE 48 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 48 could not read its corpus: $err"; return 1; fi
  local pn pf
  IFS=$'\t' read -r pn pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 48 printed no population census."; return 1; fi
  if [ "$pn" -lt 2 ]; then
    echo "  [FAIL] GATE 48 found only $pn prune-sha-change sentence(s) across $pf files (floor 2): PARITY_ALTERNATION"
    echo "         and CIRCULAR_KING_WEN both carry one today, so a smaller count is a broken splitter, not a pass."
    return 1
  fi
  local rc=0 tag f s
  while IFS=$'\t' read -r tag f s; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f: a sha change is asserted for a named prune with neither a hedge nor evidence:"
    echo "         \"$s\""
    rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         Say \"can\"/\"may\" (whether a prune moves a sha is empirical per prune-set and budget), or cite"
    echo "         the measured before/after shas, as PARITY_ALTERNATION.md §Consequences item 3 does since P42."
    return 1
  fi
  echo "  [ok] $pn prune-sha-change sentence(s) across $pf files, every one hedged or evidenced"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 49 — every figure in PARITY_ALTERNATION.md is re-derived or names its reproducer (`parity-figures`).
#
# QUEUED AS: the same P42 row, leg (b): every distinct integer figure in PARITY_ALTERNATION.md
# must appear in `verify.py --check-parity-alternation` output OR within +-3 lines of its own named
# reproducer. Red-test = the pre-P42 `48` and `16/18` trip; both pass after P42.
# WHAT COUNTS AS A FIGURE: an integer of >= 2 digits or comma-grouped, or an a/b fraction; NOT a
# year (19xx/20xx), a date, a version token, a link target, or a revision row. A figure PASSES if
# (i) it is an integer printed by the checker (run here, ~0.1 s, and REQUIRED to print
# PARITY_ALTERNATION=PASS after CR-normalisation, else ERROR), or (ii) at least one of its
# occurrences sits within +-3 lines of a reproducer line (`verify.py --`, `solve.py --`,
# `python3 -c`, `tests.py`) — the +-3 rule is applied per file, not per occurrence, because P42
# put the two reproducers in one block at the top and the figures recur in the body, or (iii) it
# sits within +-3 lines of a CITATIONS.md link (a LITERATURE figure — Cook's 36 classes, Moore's
# 16/18 — whose reproducer IS the source), or (iv) it is one of the problem-definition constants
# printed on the [ok] line (6 bits, 31 boundaries, 32 pairs, 63 transitions, 64 hexagrams).
# MEASURED BEFORE LANDING (2026-09-02): the literal spec (i)+(ii) fires on the LIVE tree at `31`
# (":5 across its 31 pair boundaries") and `36` (":108 his 36-class ordering") — correct prose the
# adjudication never measured — which is why (iii) and (iv) exist; both are printed. Pre-P42 tree
# (`git show 4ba41c12^`) -> HIT on 48 and 16/18 (no reproducer anywhere in the file), rc 1; live
# tree -> rc 0; mutation (reproducer block deleted from the live file) -> HIT rc 1; checker output
# without its PASS token -> ERROR rc 1.
gate_parity_figures() {
  echo "== GATE 49: PARITY_ALTERNATION.md figures are re-derived by --check-parity-alternation or name a reproducer =="
  local F=documentation/PARITY_ALTERNATION.md cpa cparc
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  [ -f verify.py ] || { echo "  [FAIL] verify.py is missing — the reproducer this gate runs is absent."; return 1; }
  # Q-952: the checker's OWN exit status is read (PIPESTATUS[0]; `| tr` used to hide it), and PASS
  # needs rc 0 AND exactly one PARITY_ALTERNATION= line (require_pass_token, doc_gates.sh).
  cpa=$(python3 verify.py --check-parity-alternation 2>&1 | tr -d '\r'; exit "${PIPESTATUS[0]}"); cparc=$?
  if ! require_pass_token PARITY_ALTERNATION PASS "$cpa" "$cparc"; then
    echo "  [FAIL] verify.py --check-parity-alternation did not print PARITY_ALTERNATION=PASS — the output this gate"
    echo "         compares figures against is not trustworthy, so NOTHING was judged."
    return 1
  fi
  local out
  out=$(python3 - "$F" <<'PY' "$cpa"
import re, io, sys
F=sys.argv[1]; cpa=sys.argv[2]
out=set(re.findall(r"\d+", cpa))
CONST={"6","31","32","63","64"}
doc=io.open(F,encoding="utf-8").read().split("\n")
REPRO=re.compile(r"(verify|solve|tests)\.py\s+--|python3 -c |tests\.py")
LIT=re.compile(r"CITATIONS\.md#")
figs={}
for i,l in enumerate(doc):
    if re.match(r"^\|\s*v\d",l): continue
    l2=re.sub(r"\]\([^)]*\)","]()",l)
    l2=re.sub(r"\b(19|20)\d\d-\d\d-\d\d\b","",l2); l2=re.sub(r"\bv\d+(\.\d+)*\b","",l2); l2=re.sub(r"\b(19|20)\d\d\b","",l2)
    for m in re.finditer(r"(?<![\w.])(\d{1,3}(?:,\d{3})+|\d{2,})(?:/(\d+))?(?![\w.])",l2):
        figs.setdefault(m.group(0).replace(",",""),[]).append(i)
def near(i,rx):
    return any(rx.search(x) for x in doc[max(0,i-3):i+4])
bad=0
for tok,idx in sorted(figs.items()):
    parts=tok.split("/")
    if all(p in out for p in parts) or tok in CONST: continue
    if any(near(i,REPRO) for i in idx) or any(near(i,LIT) for i in idx): continue
    bad+=1; print("HIT\t%s\t%s\t%s"%(F,tok,",".join(str(i+1) for i in idx[:6])))
print("POP\t%d\t%d"%(len(figs),len(out)))
PY
) || { echo "  [FAIL] GATE 49 scanner failed — NOTHING was checked."; return 1; }
  local pn po
  IFS=$'\t' read -r pn po < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 49 printed no population census."; return 1; fi
  if [ "$pn" -lt 5 ] || [ "$po" -lt 5 ]; then
    echo "  [FAIL] GATE 49 judged $pn figure(s) against $po checker integers (floors 5 / 5) — the page or the"
    echo "         checker output shrank past recognition; a collapsed population is not a pass."
    return 1
  fi
  local rc=0 tag f tok lns
  while IFS=$'\t' read -r tag f tok lns; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f: figure '$tok' (line(s) $lns) is neither printed by --check-parity-alternation nor within"
    echo "         +-3 lines of a named reproducer or a CITATIONS.md source anywhere on the page."
    rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] $pn distinct figures on $F: each re-derived by the checker ($po integers printed), or"
  echo "       within +-3 lines of a reproducer / CITATIONS source, or a problem constant {6,31,32,63,64}"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 50 — a selection charge priced against the 91/95-observable ledger cites the file drawer (`file-drawer`).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, prose batch P31 / Codex V2-F11 #1, leg 1: "no document may
# price a selection charge against the 91-observable ledger without citing METHODS.md §The file
# drawer". Leg 2 of that row — a literal ban on `91-observable` — is NOT built and the reason is
# measured: 37 live hits, the majority being the NAME of the frozen ledger METHODS deliberately
# retains ("the 91-observable ledger ... as a disclosure"); a literal ban demands correct text be
# reworded. Leg 1 IS mechanical: the pricing is the binomial `C(91,k)` / `C(95,k)` literal, and
# the citation is the string "file drawer" in the same document (file scope, as the row states).
# POPULATION, printed and floored: >= 2 pricing documents, else ERROR (DESCRIPTION_LENGTH and
# TR-9 both price today; CORRECTIONS.md quotes the pricing and cites the drawer, and passes on
# the same rule with no exemption).
# MEASURED BEFORE LANDING (2026-09-02): pre-P31 tree (`git show 6ffab778^`) -> DESCRIPTION_LENGTH.md
# (2 pricings, 0 citations) and TR9_PRICING_THE_CONSTRAINTS.md (2, 0) HIT, rc 1; live tree ->
# rc 0 (3 pricing documents, each citing); mutation (the two "file drawer" citations removed from
# the live DESCRIPTION_LENGTH.md) -> HIT rc 1.
gate_file_drawer() {
  echo "== GATE 50: a document pricing a selection charge against the observable ledger cites §The file drawer =="
  local f n=0 rc=0 c d
  for f in $DOCS; do
    [ -f "$f" ] || continue
    c=$(grep -c -E 'C\(9[15],' "$f"); c=${c:-0}
    [ "$c" -gt 0 ] || continue
    n=$((n+1))
    d=$(grep -c -i 'file drawer' "$f"); d=${d:-0}
    if [ "$d" -eq 0 ]; then
      echo "  [FAIL] $f prices a selection charge against the observable ledger ($c C(91,k)/C(95,k) site(s)) and"
      echo "         never cites METHODS.md §\"The file drawer\" — the charge is stated without the gap that bounds it."
      rc=1
    fi
  done
  if [ "$n" -lt 2 ]; then
    echo "  [FAIL] GATE 50 found only $n document(s) pricing C(91,k)/C(95,k) (floor 2) — DESCRIPTION_LENGTH and TR-9"
    echo "         both price today; a smaller population means the pricing literal changed shape, not that it is gone."
    return 1
  fi
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] $n document(s) price a selection charge against the ledger; each cites §The file drawer"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 51 — a claim of independent draws cites artifacts whose seeds differ (`seed-provenance`).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, V2-F09 #2 gate half: any prose claiming independent draws
# or an independence check must cite two artifacts under reports/evidence/ whose `SEED OVERRIDE`
# lines differ; artifacts with no SEED OVERRIDE line ran on the fixed base seed and can never
# satisfy it. Red-test = TR-7's pre-P36 §5.
# THE GRAMMAR the prior lane said did not exist, measured into existence: a POSITIVE claim is a
# sentence in reports/*.md containing `independent draw(s)`, `independent seed(s)`,
# `independent-seed`, `independent replicate(s)` or `independence check`, whose 40 preceding
# characters do not carry a negation (not / never / neither / nor / rather than / instead of).
# The live corpus was censused before the rule was written: the negated forms (TR-7 §1 "is NOT an
# independent draw", METHODS "are not independent draws", TR-7 §5 "not an independence check")
# are exactly the corrected sentences and must not fire; the positive forms are TR-2's "four
# independent seeds" (r11 Phase-2) and METHODS' "12 independent-seed replicates".
# CITATION RESOLUTION: an `evidence/<path>` token in the same FILE resolves to that file, or to
# every tracked file under it when it names a directory — TR-2 cites `evidence/r11/` as a
# directory and the four seed files sit inside it; demanding two explicit filenames would have
# failed correct prose. The claim passes when the cited set holds >= 2 files whose SEED OVERRIDE
# `base=` values differ.
# POPULATION, printed and floored: the evidence tree must hold >= 2 SEED OVERRIDE files with
# distinct bases (6 today), else ERROR — the class cannot be judged without them.
# MEASURED BEFORE LANDING (2026-09-02): pre-P36 TR-7 (`git show 59027647^`) -> HIT on §5's
# registered two-draws claim citing evidence/r6/* (no SEED OVERRIDE line in any r6 file), rc 1; live tree
# -> TR-2 passes via r11/, TR-7's negated forms are not claims; ONE live finding printed by the
# run: METHODS.md:173 "Validated against 12 independent-seed replicates at 10⁷ probes" cites no
# evidence artifact at all. Owner: the prose lane (it is exactly the class the charge names).
gate_seed_provenance() {
  echo "== GATE 51: a claim of independent draws / seeds cites evidence whose SEED OVERRIDE lines differ =="
  local out
  out=$(python3 - <<'PY'
import re, io, os, subprocess, sys
ev=subprocess.run(["git","ls-files","reports/evidence/*"],capture_output=True,text=True).stdout.split()
seeds={}
for f in ev:
    if not os.path.isfile(f): continue
    try: t=io.open(f,encoding="utf-8",errors="replace").read()
    except OSError: continue
    m=re.search(r"SEED OVERRIDE ACTIVE: base=(0x[0-9a-fA-F]+|\d+)",t)
    if m: seeds[f]=m.group(1).lower()
if len(set(seeds.values()))<2: print("ERROR\tthe evidence tree holds %d SEED OVERRIDE file(s) with distinct bases (need >= 2) — the class cannot be judged"%len(set(seeds.values()))); sys.exit(0)
files=[f for f in subprocess.run(["git","ls-files","reports/*.md"],capture_output=True,text=True).stdout.split() if not f.startswith("reports/evidence/")]
CLAIM=re.compile(r"independent[- ](draws?|seeds?|replicates?)|independence check",re.I)
NEG=re.compile(r"\b(not|never|neither|nor|rather than|instead of)\b",re.I)
n=0
for f in files:
    t=io.open(f,encoding="utf-8").read()
    cites=set(re.findall(r"evidence/[A-Za-z0-9_./-]*[A-Za-z0-9_/]",t))
    resolved=set()
    for c in cites:
        p="reports/"+c if not c.startswith("reports/") else c
        p=p.rstrip("/")
        for e in seeds:
            if e==p or e.startswith(p+"/"): resolved.add(e)
    bases={seeds[e] for e in resolved}
    flat=" ".join(t.replace("*","").split())
    for s in re.split(r"(?<=[.!?])\s+(?=[A-Z(\[⚠\"])",flat):
        if re.match(r"\| *v\d", s): continue  # a version row only (Q-763)
        for m in CLAIM.finditer(s):
            if NEG.search(s[max(0,m.start()-40):m.start()]): continue
            n+=1
            if len(bases)>=2: break
            print("HIT\t%s\t%s\t%d\t%s"%(f,s[:200],len(resolved),",".join(sorted(cites))[:120] or "(no evidence path cited)"))
            break
print("POP\t%d\t%d\t%d"%(n,len(files),len(set(seeds.values()))))
PY
) || { echo "  [FAIL] GATE 51 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 51 could not judge its subject: $err"; return 1; fi
  local pn pf ps
  IFS=$'\t' read -r pn pf ps < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 51 printed no population census."; return 1; fi
  local rc=0 tag f s nres cites
  while IFS=$'\t' read -r tag f s nres cites; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f claims independent draws/seeds but its cited evidence resolves to $nres SEED OVERRIDE file(s):"
    echo "         \"$s\""
    echo "         cited: $cites"
    rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         Cite two reports/evidence/ artifacts whose SEED OVERRIDE bases differ (a directory such as"
    echo "         evidence/r11/ resolves to its files), or say the runs share the fixed base seed."
    return 1
  fi
  echo "  [ok] $pn positive independent-draw/seed claim(s) across $pf reports, each backed by cited evidence"
  echo "       with distinct SEED OVERRIDE bases ($ps distinct bases exist in the evidence tree)"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 52 — a citation the ledger records as unrepeatable is hedged wherever it is used (`unrepeatable-cite`).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md, V2-F09 #4 gate half (dangling evidence): fail when a report
# states the specific content of a source whose CITATIONS.md entry records that the content cannot
# be re-verified, unless the report carries the hedge. Red-test = TR-7's pre-P36 §"Prior work
# note". THE ROW'S OWN CAVEAT, honoured: the ledger does NOT say the content was never verified —
# it was read first-hand 2026-07-04 and can no longer be RE-verified — so this gate keys on the
# hedge's ABSENCE in the citing paragraph, never on the citation entry describing content.
# MECHANICS: an anchor in CITATIONS.md is UNREPEATABLE when its entry carries `404` and "zero
# captures" / "no snapshot" (the ledger's own vocabulary for the Meyer page). Every paragraph in
# reports/*.md or documentation/*.md (CITATIONS.md itself excluded) that links `#<anchor>` must
# carry a hedge: unrepeatable / 404 / zero captures / no snapshot / cannot|can no longer be
# re-verified / no reader can retrieve / not retrievable.
# POPULATION, printed and floored: >= 1 unrepeatable anchor, else ERROR with the instruction to
# retire this gate if the class is genuinely gone (1 today: meyer1998).
# MEASURED BEFORE LANDING (2026-09-02): pre-P36 TR-7 (`git show 59027647^`) -> HIT on the "Prior
# work note" paragraph (asserts Meyer's content, no hedge), rc 1; live tree -> rc 0 (the paragraph
# now says "This attribution rests on an unrepeatable read ... returned 404 ... zero captures");
# mutation (hedge sentence deleted from the live paragraph) -> HIT rc 1.
gate_unrepeatable_cite() {
  echo "== GATE 52: a citation CITATIONS.md records as unrepeatable is hedged wherever it is used =="
  local C=documentation/CITATIONS.md out
  require_tracked "$C" || { [ $? -eq 2 ] && return 1; echo "  [skip] $C absent and untracked"; return 0; }
  out=$(python3 - "$C" <<'PY'
import re, io, subprocess, sys
C=sys.argv[1]
t=io.open(C,encoding="utf-8").read()
blocks=re.split(r'(?=<a id="[^"]+"></a>)',t)
unrep=[]
for b in blocks:
    m=re.match(r'<a id="([^"]+)"></a>',b)
    if not m: continue
    body=b.split("\n<a id=")[0]
    if re.search(r"\b404\b",body) and re.search(r"zero captures|no snapshot|no captures?\b",body,re.I): unrep.append(m.group(1))
if not unrep: print("ERROR\tno CITATIONS.md entry carries both '404' and 'zero captures/no snapshot' — if the class is gone, retire this gate explicitly rather than let it pass on nothing"); sys.exit(0)
HEDGE=re.compile(r"unrepeatable|\b404\b|zero captures|no snapshot|cannot be re-?verified|can no longer be re-?verified|no longer be re-?verified|no reader can retrieve|not retrievable",re.I)
files=[f for f in subprocess.run(["git","ls-files","reports/*.md","documentation/*.md"],capture_output=True,text=True).stdout.split() if f!=C and not f.startswith("reports/evidence/")]
n=0
for f in files:
    try: d=io.open(f,encoding="utf-8").read()
    except OSError as e: print("ERROR\t%s unreadable: %s"%(f,e)); sys.exit(0)
    for p in re.split(r"\n\s*\n",d):
        for a in unrep:
            if "#"+a not in p: continue
            n+=1
            if HEDGE.search(p): continue
            print("HIT\t%s\t%s\t%s"%(f,a," ".join(p.split())[:200]))
print("POP\t%d\t%d\t%s"%(n,len(files),",".join(unrep)))
PY
) || { echo "  [FAIL] GATE 52 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 52 could not judge its subject: $err"; return 1; fi
  local pn pf anchors
  IFS=$'\t' read -r pn pf anchors < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 52 printed no population census."; return 1; fi
  local rc=0 tag f a p
  while IFS=$'\t' read -r tag f a p; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f cites #$a — a source CITATIONS.md records as no longer re-verifiable — with no hedge in the paragraph:"
    echo "         \"$p\""
    rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] unrepeatable anchor(s) {$anchors}: $pn citing paragraph(s) across $pf files, each carrying the hedge"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 53 — the published (pair, orient) branch split enumerates the 56 live branches (`branch-list`).
#
# QUEUED AS: Codex A12-designated leg `branch-list` (V2-F23 #5, LARGE_SCALE_CAMPAIGNS.md): the
# shipped split must have exactly 56 entries and exclude pair 0 and the six execution-confirmed
# dead tuples (4,0) (4,1) (6,0) (6,1) (21,0) (21,1). Red-test: the 62-entry split at 8efd6ee2.
# (A12 also asked for a tests.py behavioural token; tests.py is not this lane's file.)
# MECHANICS: every `→ N branches` line in documentation/LARGE_SCALE_CAMPAIGNS.md outside a
# CORRECTED-marker paragraph (the live file QUOTES the old 31+31 split inside its own correction,
# and a correction is doing its job) must sum to 56; and every `pairs a, b, c ...` list on those
# lines must avoid {0, 4, 6, 21}, be pairwise disjoint across VMs, and cover 28 pair indices.
# POPULATION, printed and floored: >= 2 split lines, else ERROR.
# MEASURED BEFORE LANDING (2026-09-02): 8efd6ee2 tree -> 31 + 31 = 62 HIT, rc 1; live tree ->
# 28 + 28 = 56, pair sets {1..16}\{4,6} and {17..31}\{21}, rc 0; mutation (live VM-B list given
# pair 21) -> HIT rc 1; mutation ("→ 28 branches" edited to 29) -> sum 57 HIT rc 1.
gate_branch_list() {
  echo "== GATE 53: LARGE_SCALE_CAMPAIGNS.md's branch split enumerates the 56 live (pair, orient) branches =="
  local F=documentation/LARGE_SCALE_CAMPAIGNS.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
DEAD={0,4,6,21}
t=io.open(F,encoding="utf-8").read()
lines=[]; sets=[]
for p in re.split(r"\n\s*\n",t):
    if "CORRECTED" in p: continue
    for l in p.split("\n"):
        l2=l.replace("*","")
        m=re.search(r"(?:→|->)\s*(\d+)\s+branches",l2)
        if not m: continue
        lines.append((int(m.group(1)),l2.strip()[:90]))
        pm=re.search(r"pairs?\s+((?:\d+\s*,\s*)+\d+)",l2)
        if pm: sets.append({int(x) for x in re.findall(r"\d+",pm.group(1))})
if len(lines)<2: print("ERROR\tonly %d '→ N branches' split line(s) found outside CORRECTED paragraphs (need >= 2)"%len(lines)); sys.exit(0)
tot=sum(n for n,_ in lines)
if tot!=56: print("HIT\tsum\tthe published split sums to %d branches, not 56: %s"%(tot," / ".join(l for _,l in lines)))
allp=set()
for s in sets:
    bad=s&DEAD
    if bad: print("HIT\tdead\ta VM list contains dead/fixed pair index(es) %s"%sorted(bad))
    if allp&s: print("HIT\toverlap\tpair index(es) %s appear on more than one VM"%sorted(allp&s))
    allp|=s
if sets and len(allp)!=28: print("HIT\tcover\tthe VM lists cover %d pair indices, not 28"%len(allp))
print("POP\t%d\t%d\t%d\t%d"%(len(lines),tot,len(sets),len(allp)))
PY
) || { echo "  [FAIL] GATE 53 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 53 could not find its subject: $err"; return 1; fi
  local pl pt ps pp
  IFS=$'\t' read -r pl pt ps pp < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pl:-}"; then echo "  [FAIL] GATE 53 printed no population census."; return 1; fi
  local rc=0 tag kind msg
  while IFS=$'\t' read -r tag kind msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F ($kind): $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         The 28 live pair indices are 1-31 minus {4, 6, 21}, each in both orientations = 56 branches;"
    echo "         a runner fed a dead tuple never finishes (LARGE_SCALE_CAMPAIGNS.md §Where the six go)."
    return 1
  fi
  echo "  [ok] $pl split line(s) sum to $pt branches; $ps VM pair list(s) covering $pp pair indices, none dead, none shared"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 54 — documentation/README.md indexes every tracked doc and states reading times honestly (`index-fidelity`).
#
# QUEUED AS: Codex A12-designated leg `index-fidelity` (V2-F47 #1/#3/#12): LEG 1 (coverage) every
# tracked documentation/*.md must appear as a link target in an index ROW of documentation/README.md
# — a list item or a table row; a mention inside a prose sentence does not count (the pre-P20
# LARGE_SCALE_CAMPAIGNS.md was reachable only from a deprecation sentence). LEG 2 (reading time)
# a stated minutes-to-read beside a named target must be >= wc -w(target) / 300 (the charge's floor;
# the index itself uses 250 wpm, which is stricter).
# NOT BUILT, with the measurement: A12's "figures check" (a percentage in an index line must appear
# verbatim in the target). It inverts on its own inputs: the pre-fix "<0.2%" PASSES because "0.2%"
# occurs in the target for a different quantity, and the live "33%" FAILS because the target prints
# "33.1%". A leg that is red on correct prose and green on the defect is the wrong leg.
# POPULATION, printed and floored: >= 20 tracked docs and >= 1 reading-time entry, else ERROR.
# MEASURED BEFORE LANDING (2026-09-02): pre-P20 tree (`git show fbd6f9e5^`) -> LEG 1: 12 docs
# unindexed (CIRCULAR_KING_WEN, CLAIMS_DECIDED, ..., VERIFY) HIT; LEG 2: "1–2 min" for the root
# README (4,101 words -> 13.7 min at 300 wpm) HIT; rc 1. Live tree -> 0 unindexed of 42, three
# reading-time entries all >= floor, rc 0. Mutation (one index row deleted) -> HIT rc 1.
# NOTE printed, not judged: the index's stated word counts (4,202 / 8,313 / 14,527, "measured
# 2026-09-01") already lag `wc -w` by 6-8 %; a count-drift leg is a candidate, not built here.
gate_index_fidelity() {
  echo "== GATE 54: documentation/README.md indexes every tracked doc; reading times are >= words/300 =="
  local F=documentation/README.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, os, subprocess, sys
F=sys.argv[1]
idx=io.open(F,encoding="utf-8").read().split("\n")
rows=[l for l in idx if re.match(r"^\s*([-*]|\d+\.|\|)\s",l)]
targets={}
for l in rows:
    for m in re.finditer(r"\]\(([^)#]+\.md)",l):
        targets[os.path.normpath(os.path.join(os.path.dirname(F),m.group(1)))]=l
docs=subprocess.run(["git","ls-files","documentation/*.md"],capture_output=True,text=True).stdout.split()
docs=[d for d in docs if d!=F]
if len(docs)<20: print("ERROR\tonly %d tracked documentation/*.md (need >= 20)"%len(docs)); sys.exit(0)
miss=[d for d in docs if d not in targets]
for d in miss: print("HIT\tunindexed\t%s\tno index list item or table row in %s links it"%(d,F))
nrt=0
for i,l in enumerate(idx,1):
    m=re.search(r"\((?:~(\d+)|(\d+)\s*[-–]\s*(\d+))\s*min",l)
    tg=re.findall(r"\]\(([^)#]+\.md)",l)
    if not m or not tg: continue
    nrt+=1
    mins=int(m.group(1) or m.group(3))
    t=os.path.normpath(os.path.join(os.path.dirname(F),tg[0]))
    try: w=len(io.open(t,encoding="utf-8").read().split())
    except OSError: print("HIT\treadtime\t%s:%d\ttarget %s unreadable"%(F,i,t)); continue
    floor=w/300.0
    if mins<floor: print("HIT\treadtime\t%s:%d\t%s: stated %d min, but %d words need >= %.1f min at 300 wpm"%(F,i,t,mins,w,floor))
print("POP\t%d\t%d\t%d\t%d"%(len(docs),len(targets),len(miss),nrt))
PY
) || { echo "  [FAIL] GATE 54 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 54 could not judge its subject: $err"; return 1; fi
  local pd pt pm pr
  IFS=$'\t' read -r pd pt pm pr < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pd:-}"; then echo "  [FAIL] GATE 54 printed no population census."; return 1; fi
  if [ "$pr" -lt 1 ]; then echo "  [FAIL] GATE 54 found no reading-time entry in $F (floor 1) — the section moved or its shape changed; LEG 2 judged nothing."; return 1; fi
  local rc=0 tag kind where msg
  while IFS=$'\t' read -r tag kind where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] ($kind) $where — $msg"; rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -eq 0 ] || return 1
  echo "  [ok] $pd tracked docs, $pt index-row link targets, $pm unindexed; $pr reading-time entries all >= words/300"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 55 — every enumeration of the sha-determining inputs is the registry's tuple (`sha-tuple`).
#
# QUEUED AS: Codex A12-designated leg `sha-tuple` (V2-F22 #5): every tracked-md enumeration of the
# sha-determining inputs must be the same set as CANONICAL_HASHES.md §"Reproducibility parameters".
# Red-test: the pre-P19 CAMPAIGN_METHODOLOGY.md:86@97f50cc6^ two-element "(source code, search budget)" red against
# the registry's four, with the same file's §8 green.
# MECHANICS: the enumeration grammar is the literal `a function of (...)` (fold strips bold); a
# sentence beginning "this read" or sitting in a CORRECTED paragraph is narration. The tuple must
# name all four inputs, each recognised by a stated token family: source code / (partition|search)
# depth|SOLVE_DEPTH / node limit|SOLVE_NODE_LIMIT / per-sub-branch|SOLVE_PER_SUB_BRANCH_LIMIT.
# The registry side is checked too: CANONICAL_HASHES.md §Reproducibility parameters must name the
# three env vars, else ERROR (the tuple this gate encodes would then be stale).
# POPULATION, printed and floored: >= 1 enumeration, else ERROR (one today, CAMPAIGN_METHODOLOGY:150).
# MEASURED BEFORE LANDING (2026-09-02): pre-P19 tree (`git show 97f50cc6^`) -> HIT "(source code,
# search budget)" names 1 of 4, rc 1; live tree -> the four-element tuple passes, its correction
# paragraph is narration, rc 0; mutation (live tuple with "partition depth," removed) -> HIT rc 1.
gate_sha_tuple() {
  echo "== GATE 55: every 'function of (...)' enumeration of the sha inputs matches the registry tuple =="
  local R=documentation/CANONICAL_HASHES.md out
  require_tracked "$R" || { [ $? -eq 2 ] && return 1; echo "  [skip] $R absent and untracked"; return 0; }
  out=$(python3 - "$R" <<'PY'
import re, io, subprocess, sys
R=sys.argv[1]
reg=io.open(R,encoding="utf-8").read()
m=re.search(r"^##+ .*Reproducibility parameters.*$",reg,re.M)
if not m: print("ERROR\t%s has no §Reproducibility parameters heading"%R); sys.exit(0)
sect=reg[m.end():m.end()+3000]
for v in ("SOLVE_DEPTH","SOLVE_NODE_LIMIT","SOLVE_PER_SUB_BRANCH_LIMIT"):
    if v not in sect: print("ERROR\t%s §Reproducibility parameters no longer names %s — the tuple this gate encodes is stale"%(R,v)); sys.exit(0)
FAM={"source code":r"source code|code version|binary",
     "depth":r"depth|SOLVE_DEPTH",
     "node limit":r"node limit|SOLVE_NODE_LIMIT|global budget",
     "per-sub-branch limit":r"per-sub-branch|SOLVE_PER_SUB_BRANCH_LIMIT|per-cell"}
files=subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split()
n=0
for f in files:
    t=io.open(f,encoding="utf-8").read()
    for p in re.split(r"\n\s*\n",t):
        if "CORRECTED" in p: continue
        flat=" ".join(p.replace("*","").split())
        # 🔴 THE PARAGRAPH MUST ACTUALLY BE ABOUT A SHA. Added 2026-09-04 after this gate blocked a
        # push by firing on documentation/PREREG_H1_H3_TEST_2026_07_26.md:108 — a sentence about a
        # STATISTICAL THRESHOLD being "a deterministic function of (a) the sampled reference
        # population with KW held out, or (b) a closed-form constant of C5's declared multiset".
        # That names 0 of 4 sha inputs because it is not about the sha; it merely shares the phrase.
        # The gate's population was "every `function of (...)` in every tracked .md", not "every
        # claim about what determines a sha", and the two are not the same set.
        # It mattered beyond noise: the file is an ESCROWED pre-registration whose sha IS its
        # identity, so it cannot be edited to satisfy a prose gate without destroying the thing the
        # escrow exists to prove. A gate that can only be satisfied by invalidating its subject is
        # not a gate. The legitimate population (e.g. CAMPAIGN_METHODOLOGY.md:158, "the canonical
        # sha **a function of (source code, partition depth, ...)") all name a sha in the same
        # paragraph, so requiring that is a narrowing, not a weakening.
        if not re.search(r"\bsha\b|\bsha256\b|\bhash(es|ed)?\b|canonical sha", p, re.I):
            continue
        for mm in re.finditer(r"function of \(([^)]*)\)",flat):
            pre=flat[max(0,mm.start()-60):mm.start()].lower()
            if "this read" in pre or "previously read" in pre: continue
            n+=1; tup=mm.group(1)
            missing=[k for k,rx in FAM.items() if not re.search(rx,tup,re.I)]
            if missing: print("HIT\t%s\t(%s)\tnames %d of 4 inputs; missing: %s"%(f,tup[:100],4-len(missing),", ".join(missing)))
print("POP\t%d\t%d"%(n,len(files)))
PY
) || { echo "  [FAIL] GATE 55 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 55 could not judge its subject: $err"; return 1; fi
  local pn pf
  IFS=$'\t' read -r pn pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 55 printed no population census."; return 1; fi
  if [ "$pn" -lt 1 ]; then echo "  [FAIL] GATE 55 found no 'function of (...)' enumeration across $pf docs (floor 1) — the grammar moved; nothing judged."; return 1; fi
  local rc=0 tag f tup msg
  while IFS=$'\t' read -r tag f tup msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f: the sha is stated as a function of $tup — $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         The registry tuple is (source code, partition depth, global node limit, per-sub-branch limit) —"
    echo "         $R §Reproducibility parameters; §8 of CAMPAIGN_METHODOLOGY says the same."
    return 1
  fi
  echo "  [ok] $pn sha-input enumeration(s) across $pf docs, each naming all four registry inputs"
  return 0
}

