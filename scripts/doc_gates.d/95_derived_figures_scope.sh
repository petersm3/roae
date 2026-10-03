#@ scripts/doc_gates.d/95_derived_figures_scope.sh -- sourced by scripts/doc_gates.sh (Q-797 split, 2026-09-25); not runnable on its own.
#@ GATES 56-77 and 80: derived figures, arithmetic, vocabulary, scope and inventory gates.
#@ Lines 18147-20311 of the logical source (`bash scripts/doc_gates.d/logical_source.sh`); `#@` lines are
#@ split commentary and are not part of it. Run gates through the entry: bash scripts/doc_gates.sh <gate>
# GATE 56 — figures a document attributes to an analyze-log section are the log's own figures
# (`log-derived-figures`).
#
# QUEUED AS: Codex A12-designated leg `log-derived-figures` (BATCH A01 rows 33/39, A02 row 29,
# A05 rows 9/29): boundary survivor counts, greedy sets and redundancy pairs stated in prose must be
# regenerated from the shipped, tracked `analyze_output.log.gz` §[3]/§[6]/§[9] blocks and compared
# by string equality, never transcribed.
# PREMISE CORRECTED BEFORE BUILDING (measured 2026-09-02): A12's prescribed red-test — "the
# reviewer's unsourceable 21,794,755 / 152,468,987 must fail and §[3]'s 93,439,670 / 872,797,288
# must pass" — is WRONG. `runs/20260418_10T_d3_fresh/analyze_output.log.gz` IS tracked and its
# §[3] prints boundary 15 = 21794755 and boundary 19 = 152468987; the 93,439,670 / 872,797,288
# pair is the 100T log's. The live PROJECT_OVERVIEW.md:102 attributes the first pair to "d3 10T
# (§[3])", which is exactly right. A gate built to the prescribed red-test would fail a correct
# figure. So the leg keys every figure on the DATASET the sentence names, mapped to the tracked
# log for that dataset; the red-test is a real historical tree instead (below).
# MECHANICS. Logs (dataset -> tracked file, each parsed for §[3] survivors, §[6] chosen set and
# step counts, §[9] pair/joint/min_single/ratio; a log that yields none of these is ERROR):
#   d3 10T -> runs/20260418_10T_d3_fresh, d2 10T -> runs/20260418_10T_d2_fresh,
#   100T -> runs/20260419_100T_d3_d128westus3, 742M -> enumeration/analyze_c_742M.txt.
#   560T and 11.2T name datasets whose analyze log is NOT in the tree: UNCHECKABLE, printed.
# LEG T (tables): a table whose header cell cites §[6] or reads "Greedy set" — for each row naming
#   a logged dataset, the `{...}` set in that cell must be exactly the log's `Boundaries chosen`
#   set. LEG P (prose): a paragraph citing §[3], §[6] or §[9] and naming a logged dataset — every
#   comma-grouped or >=5-digit integer must be a figure of the cited section(s) of a named log
#   (elsewhere in that log = [note], a mis-cited section; nowhere = FAIL), and under §[9] every
#   `0.ddd` ratio must be one the log prints. A paragraph that ALSO names an un-logged dataset
#   cannot have a figure pinned on it (the figure may be that dataset's): a miss there is printed
#   as unattributable, not failed. Correction narration is excluded: CORRECTIONS.md and HISTORY.md
#   whole, `⚠ [CORRECTED` paragraphs, and `*(Corrected ...)*` spans.
# POPULATION, printed and floored: >= 1 checkable table row AND >= 1 checkable paragraph, else
#   ERROR — an absent population is not a clean one.
# MEASURED BEFORE LANDING (2026-09-02): see the [ok] line and PROSE_LANE_FOLLOWUPS for the
#   red-test (`git show 84590abe:documentation/BOUNDARY_MINIMUM.md` — the pre-P39 table whose
#   "Greedy set" column held the §[8] union-shorthand families on the two 10T rows, rows 42-43;
#   the d3 shorthand is registry row 186, so it is not quoted here) and the mutation cases.
gate_log_derived_figures() {
  echo "== GATE 56: figures attributed to an analyze-log section (§[3]/§[6]/§[9]) are that log's own figures =="
  local out
  out=$(python3 - <<'PY'
import gzip, io, re, subprocess, sys
LOGS = {'d3 10T': 'runs/20260418_10T_d3_fresh/analyze_output.log.gz',
        'd2 10T': 'runs/20260418_10T_d2_fresh/analyze_output.log.gz',
        '100T':   'runs/20260419_100T_d3_d128westus3/analyze_output.log.gz',
        '742M':   'enumeration/analyze_c_742M.txt'}
NOLOG = ['560T', '11.2T']
DS_RX = {'d3 10T': r'\bd3[ _-]10T\b|\b10T[ _-]d3\b|\b10T \(d3\)', 'd2 10T': r'\bd2[ _-]10T\b|\b10T[ _-]d2\b|\b10T \(d2\)',
         '100T': r'\b100T\b', '742M': r'\b742M\b', '560T': r'\b560T\b', '11.2T': r'\b11\.2T\b'}
tracked = set(subprocess.run(['git','ls-files'], capture_output=True, text=True).stdout.split('\n'))
def parse(path):
    if path not in tracked: print('ERROR\t%s is not tracked — the dataset map is stale' % path); sys.exit(0)
    try:
        t = gzip.open(path, 'rt', encoding='utf-8', errors='replace').read() if path.endswith('.gz') \
            else io.open(path, encoding='utf-8', errors='replace').read()
    except OSError as e: print('ERROR\tcannot read %s: %s' % (path, e)); sys.exit(0)
    secs, cur = {}, None
    for l in t.split('\n'):
        m = re.match(r'^\[(\d+)\]', l)
        if m: cur = int(m.group(1)); secs[cur] = []; continue
        if cur is not None: secs[cur].append(l)
    surv, chosen, n6, pairs, ratios, n9 = {}, None, set(), {}, set(), set()
    for l in secs.get(3, []):
        m = re.match(r'^\s*Boundary\s+(\d+)\s+\(pos [\d-]+\):\s+(\d+)', l)
        if m: surv[int(m.group(1))] = int(m.group(2))
    for l in secs.get(6, []):
        m = re.search(r'Boundaries chosen: \{([\d ]+)\}', l)
        if m and chosen is None: chosen = frozenset(int(x) for x in m.group(1).split())
        n6.update(int(x) for x in re.findall(r'\b(\d{5,})\b', l))
    for l in secs.get(9, []):
        m = re.match(r"^\s*b=(\d+), b'=(\d+)\s+joint=(\d+)\s+min_single=(\d+)\s+ratio=([\d.]+)", l)
        if m:
            pairs[(int(m.group(1)), int(m.group(2)))] = m.group(5)
            ratios.add(m.group(5)); n9.add(int(m.group(3))); n9.add(int(m.group(4)))
    if len(surv) < 31 or chosen is None or not pairs:
        print('ERROR\t%s: §[3]/§[6]/§[9] did not parse (surv=%d chosen=%s pairs=%d) — the log format moved' % (path, len(surv), chosen, len(pairs))); sys.exit(0)
    allnums = set(int(x) for x in re.findall(r'\b(\d{5,})\b', t))
    return dict(surv=surv, n3=set(surv.values()), chosen=chosen, n6=n6, pairs=pairs, ratios=ratios, n9=n9, all=allnums)
L = {k: parse(v) for k, v in LOGS.items()}
def named(s): return [d for d, rx in DS_RX.items() if re.search(rx, s)]
files = [f for f in subprocess.run(['git','ls-files','*.md'], capture_output=True, text=True).stdout.split('\n')
         if f and f not in ('documentation/CORRECTIONS.md', 'documentation/HISTORY.md')]
NUM = r'(?<![\d.,])\d{1,3}(?:,\d{3})+(?![\d,])|(?<![\d.,])\d{5,}(?![\d,])'
pt = pp = un = 0
for f in files:
    text = io.open(f, encoding='utf-8', errors='replace').read()
    text = re.sub(r'\*\(Corrected.*?\)\*', '', text, flags=re.S)
    lines = text.split('\n')
    # LEG T
    for i, l in enumerate(lines):
        if not l.startswith('|') or i+1 >= len(lines) or not re.match(r'^\|[\s:|-]+\|?\s*$', lines[i+1]): continue
        hdr = [c.strip() for c in re.split(r'(?<!\\)\|', l.strip().strip('|'))]  # Q-525: a GFM \| is not a cell break
        cols = [k for k, c in enumerate(hdr) if re.search(r'§\s*\[6\]|Greedy set', c)]
        if not cols: continue
        j = i + 2
        while j < len(lines) and lines[j].startswith('|'):
            cells = [c.strip() for c in re.split(r'(?<!\\)\|', lines[j].strip().strip('|'))]
            ds = named(cells[0] if cells else '')
            for k in cols:
                if k >= len(cells): continue
                sets = [frozenset(int(x) for x in re.findall(r'\d+', s)) for s in re.findall(r'\{[\d,\s]+\}', cells[k])]
                if not sets: continue
                ok_ds = [d for d in ds if d in L]
                if not ok_ds:
                    if ds: un += 1; print('UNCHECKABLE\t%s:%d\ttable row for %s — no tracked analyze log' % (f, j+1, '/'.join(ds)))
                    continue
                pt += 1
                if not any(len(sets) == 1 and sets[0] == L[d]['chosen'] for d in ok_ds):
                    print('HIT\t%s:%d\t§[6] column holds %s but the %s log says Boundaries chosen = {%s}' % (
                        f, j+1, ' '.join('{%s}' % ','.join(map(str, sorted(s))) for s in sets), '/'.join(ok_ds),
                        ', '.join(' '.join(map(str, sorted(L[d]['chosen']))) for d in ok_ds)))
            j += 1
    # LEG P — the window is the citing line ±1 within its paragraph (a sentence may be hard-wrapped),
    # overlapping windows merged; the figures judged are those in log-figure grammar (a number
    # after "boundary N['s]", "survivors", "joint", "min_single", "eliminates", "remain", "non-KW",
    # or before "survivors"/"remain"). Measured 2026-09-02 on the whole-paragraph, every-number
    # version: PROJECT_OVERVIEW.md:102's 130,674,232 — a correct DIFFERENCE of two §[3] figures —
    # was a FAIL, and 60 unattributable notes came from paragraphs that merely mention 560T.
    KEY = r"(?:[Bb]oundary \d+(?:'s|’s)?|survivors?|joint|min[- _]?single|eliminates?|remain(?:ing)?|non-KW)"
    def figures(flat):
        got = set()
        for m in re.finditer(KEY + r"\W+(?:[\w'’×-]+\W+){0,3}?(" + NUM + r")", flat): got.add(int(m.group(1).replace(',', '')))
        for m in re.finditer(r"(" + NUM + r")\W+(?:[\w'’-]+\W+){0,2}?(?:survivors?|remain|non-KW)", flat): got.add(int(m.group(1).replace(',', '')))
        return got
    blank = [not l.strip() for l in lines]
    wins = []
    for i, l in enumerate(lines):
        if not re.search(r'§\s*\[(3|6|9)\]', l) or l.lstrip().startswith('|'): continue
        lo = i if i == 0 or blank[i-1] else i-1
        hi = i if i+1 >= len(lines) or blank[i+1] else i+1
        if wins and lo <= wins[-1][1] + 1: wins[-1][1] = max(wins[-1][1], hi)
        else: wins.append([lo, hi])
    for lo, hi in wins:
        para = '\n'.join(lines[lo:hi+1]); ln = lo + 1
        if para.lstrip().startswith('⚠') or '[CORRECTED' in para: continue
        cited = set(int(x) for x in re.findall(r'§\s*\[(3|6|9)\]', para))
        flat = ' '.join(para.split())
        ds = named(flat); ok_ds = [d for d in ds if d in L]
        if not ok_ds:
            if ds: un += 1; print('UNCHECKABLE\t%s:%d\tcites §%s for %s — no tracked analyze log' % (f, ln, sorted(cited), '/'.join(ds)))
            continue
        pp += 1
        # Each SENTENCE is keyed on the dataset and section it names itself, falling back to the
        # window's. Measured 2026-09-02: with window-level keys, swapping :102's "d3 10T (§[3])" to
        # "100T (§[3])" did NOT fire, because the next line's "d3 10T §[9]" sat in the same window.
        for sent in re.split(r'(?<=[.!?;])\s+(?=[A-Z`*(\[])', flat):
            sds = named(sent) or ds; sok = [d for d in sds if d in L]
            if not sok: continue
            scited = set(int(x) for x in re.findall(r'§\s*\[(3|6|9)\]', sent)) or cited
            partial = any(d in NOLOG for d in sds)
            want = set().union(*[L[d]['n%d' % s] for d in sok for s in scited])
            anywhere = set().union(*[L[d]['all'] for d in sok])
            for n in sorted(figures(sent)):
                if n in want: continue
                if n in anywhere: print('NOTE\t%s:%d\t%s is in the %s log but not in the cited §%s' % (f, ln, format(n, ','), '/'.join(sok), sorted(scited))); continue
                if partial: print('UNATTRIB\t%s:%d\t%s is in no tracked log named here (%s); %s has no tracked log' % (f, ln, format(n, ','), '/'.join(sok), '/'.join(d for d in sds if d in NOLOG))); continue
                print('HIT\t%s:%d\t%s is attributed to §%s of the %s log, and that log does not contain it' % (f, ln, format(n, ','), sorted(scited), '/'.join(sok)))
            if 9 in scited:
                rset = set().union(*[L[d]['ratios'] for d in sok])
                for r in sorted(set(re.findall(r'\b0\.\d{3}\b', sent))):
                    if r in rset: continue
                    if partial: print('UNATTRIB\t%s:%d\tratio %s is printed by no tracked log named here' % (f, ln, r)); continue
                    print('HIT\t%s:%d\tratio %s is attributed to §[9] of the %s log, whose ratio column never prints it' % (f, ln, r, '/'.join(sok)))
print('POP\t%d\t%d\t%d\t%d' % (pt, pp, un, len(files)))
PY
) || { echo "  [FAIL] GATE 56 scanner failed — NOTHING was checked."; return 1; }
  out="$(printf '%s\n' "$out" | tr -d '\r')"
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 56 could not judge its subject: $err"; return 1; fi
  local pt pp un pf
  IFS=$'\t' read -r pt pp un pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pt:-}" || ! grep -qxE '[0-9]+' <<<"${pp:-}"; then
    echo "  [FAIL] GATE 56 printed no population census."; return 1; fi
  if [ "$pt" -lt 1 ] || [ "$pp" -lt 1 ]; then
    echo "  [FAIL] GATE 56 population below floor: $pt checkable §[6] table row(s), $pp checkable §-citing paragraph(s) across $pf docs (floor 1 each) — the citation grammar or the dataset names moved; nothing judged."; return 1; fi
  local rc=0 tag site msg
  while IFS=$'\t' read -r tag site msg; do
    case "$tag" in
      HIT)         echo "  [FAIL] $site: $msg"; rc=1 ;;
      NOTE)        echo "  [note] $site: $msg" ;;
      UNATTRIB)    echo "  [note] $site: $msg (unattributable, not failed)" ;;
      UNCHECKABLE) echo "  [note] $site: $msg" ;;
    esac
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         A figure cited to a log section is the log's figure or it is a transcription error;"
    echo "         regenerate it from the tracked log named above (gzip -dc ... | sed -n '/^\[N\]/,/^\[/p')."
    return 1
  fi
  echo "  [ok] GATE 56: $pt §[6] table row(s) match their log's chosen set; $pp §[3]/§[6]/§[9] paragraph(s) carry only their log's figures; $un site(s) name a dataset with no tracked log (listed above, unjudged); $pf docs scanned"
  return 0
}


# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 57 — a display equation in a documentation/reports block has two DIFFERENT sides
# (`nontrivial-display`).
#
# QUEUED AS: Codex A-batch designated leg `nontrivial-display` (BATCH A03 row 29,
# PARTITION_INVARIANCE.md:25): the displayed theorem read `sha256( M( ⋃ E(B) ) ) = sha256( M( ⋃ E(B) ) )`
# — character-identical sides, i.e. `x = x`, with the two meanings assigned only in the prose after it.
# MECHANICS: population = every indented (>= 4 spaces) or fenced line in tracked documentation/*.md +
# reports/**/*.md that splits on a spaced ` = ` into exactly two sides, each >= 6 chars after stripping
# whitespace, bold markers and trailing punctuation. HIT when the two normalised sides are byte-equal.
# No theorem-block heuristic: an `x = x` display is vacuous wherever it sits, and the same predicate
# over the whole corpus found ZERO live hits (so no "theorem section" carve-out was needed to go green).
# POPULATION printed and floored at 20 (93 candidate lines across 73 docs measured 2026-09-02).
# MEASURED BEFORE LANDING (2026-09-02): pre-fix tree (`git show 89e7a9a1:documentation/PARTITION_INVARIANCE.md`)
# -> HIT :25, rc 1; live -> `E_full` vs `E_branch` sides differ, rc 0; mutation (live :31 with the right
# side copied from the left) -> HIT rc 1; population floor raised above the live count -> ERROR rc 1.
gate_nontrivial_display() {
  echo "== GATE 57: a display equation (indented/fenced ' = ' line) does not have identical sides =="
  local out
  out=$(python3 - <<'PY'
import re, io, subprocess, sys
files=[f for f in subprocess.run(["git","ls-files","documentation/*.md","reports/*.md","reports/**/*.md"],capture_output=True,text=True).stdout.split() if f.endswith(".md")]
files=sorted(set(files))
n=0
for f in files:
    fence=False
    for i,line in enumerate(io.open(f,encoding="utf-8").read().split("\n"),1):
        if line.strip().startswith("```"): fence=not fence; continue
        if not (fence or re.match(r"^ {4,}\S",line)): continue
        s=line.strip()
        if s[:1] in "#$>|-*": continue
        parts=s.split(" = ")
        if len(parts)!=2: continue
        def norm(x):
            x=x.replace("**","").strip()
            return re.sub(r"[\s.,;:]+$","",re.sub(r"\s+","",x))
        a,b=norm(parts[0]),norm(parts[1])
        if len(a)<6 or len(b)<6: continue
        n+=1
        if a==b: print("HIT\t%s:%d\t%s"%(f,i,s[:110]))
print("POP\t%d\t%d"%(n,len(files)))
PY
) || { echo "  [FAIL] GATE 57 scanner failed — NOTHING was checked."; return 1; }
  local pn pf
  IFS=$'\t' read -r pn pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 57 printed no population census."; return 1; fi
  if [ "$pn" -lt 20 ]; then echo "  [FAIL] GATE 57 found only $pn two-sided display line(s) across $pf docs (floor 20) — the corpus or the grammar moved; nothing judged."; return 1; fi
  local rc=0 tag loc s
  while IFS=$'\t' read -r tag loc s; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $loc: display equation has IDENTICAL sides (it states x = x): $s"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         Parameterise the sides (e.g. E_full vs E_branch) — a formula whose sides are the same string is true of any E, M."
    return 1
  fi
  echo "  [ok] GATE 57: $pn two-sided display line(s) across $pf docs, none with identical sides"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 58 — a stated "N independent paths/witnesses" equals the rows of the table it introduces,
# and every 11.2T restatement matches (`witness-count`).
#
# QUEUED AS: Codex A-batch designated leg `witness-count` (BATCH A03 row 33): CANONICAL_HASHES.md
# headed its 11.2T witness table "8 independent paths" over 7 data rows, while PARTITION_INVARIANCE.md
# restated "7 independent witnesses total" — three counts for one campaign.
# MECHANICS: LEG 1 — every tracked-md line of the form `... (N independent paths|witnesses):` that is
# followed by a markdown table: N must equal that table's data-row count (rows beginning `| 2026`, the
# table's own date column; a row in the same table with no date is still a row, so any `|`-row after
# the separator counts). LEG 2 — outside CORRECTIONS.md/HISTORY.md (chronicles), any sentence or table
# row naming `11.2 T` together with `<cardinal> independent (witnesses|paths)` must state the registry
# count (LEG 1's CANONICAL_HASHES.md table). Number words one..twelve are folded to digits.
# POPULATION printed: LEG 1 headings (floor 1), LEG 2 restatements (printed, no floor).
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`89e7a9a1`: CANONICAL_HASHES.md heading 8 over 7
# rows; PARTITION_INVARIANCE.md:296 "(7 independent witnesses total)") -> 2 HITs, rc 1; live -> 8 over
# 8 rows, "eight independent paths" restatement = 8, rc 0; mutation (live heading 8 -> 9) -> HIT rc 1.
gate_witness_count() {
  echo "== GATE 58: 'N independent paths/witnesses' equals the rows of its table; 11.2T restatements agree =="
  local R=documentation/CANONICAL_HASHES.md out
  require_tracked "$R" || { [ $? -eq 2 ] && return 1; echo "  [skip] $R absent and untracked"; return 0; }
  out=$(python3 - "$R" <<'PY'
import re, io, subprocess, sys
R=sys.argv[1]
W={"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10,"eleven":11,"twelve":12}
files=subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split()
heads=0; reg=None
for f in files:
    lines=io.open(f,encoding="utf-8").read().split("\n")
    for i,l in enumerate(lines):
        m=re.search(r"\((\d+) independent (?:paths|witnesses)[^)]*\):?\**\s*$",l)
        if not m: continue
        j=i+1
        while j<len(lines) and lines[j].strip()=="": j+=1
        if j>=len(lines) or not lines[j].lstrip().startswith("|"): continue
        heads+=1
        rows=0; k=j
        while k<len(lines) and lines[k].lstrip().startswith("|"):
            c=lines[k].strip()
            if not re.match(r"^\|\s*:?-",c) and k>j: rows+=1
            k+=1
        n=int(m.group(1))
        if f==R: reg=n if reg is None else reg
        if n!=rows: print("HIT\t%s:%d\tsays %d independent paths/witnesses; the table it introduces has %d data row(s)"%(f,i+1,n,rows))
        elif f==R: reg=n
if reg is None: print("ERROR\t%s has no '(N independent paths):' heading followed by a table — the registry count cannot be read"%R); sys.exit(0)
rest=0
for f in files:
    if f.endswith("CORRECTIONS.md") or f.endswith("HISTORY.md"): continue
    t=io.open(f,encoding="utf-8").read()
    for p in re.split(r"\n\s*\n",t):
        units=[l for l in p.split("\n") if l.lstrip().startswith("|")] or [" ".join(p.split())]
        for u in units:
            u=u.replace("*","")
            u=re.sub(r"\[CORRECTED\b.*?\]"," ",u,flags=re.S)
            for s in re.split(r"(?<=[.!?])\s+",u):
                if not re.search(r"11\.2\s?T\b",s): continue
                mm=re.search(r"\b(\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\b independent (?:witnesses|paths)",s,re.I)
                if not mm: continue
                rest+=1
                v=mm.group(1).lower(); v=int(v) if v.isdigit() else W[v]
                if v!=reg: print("HIT\t%s\tstates '%s independent %s' for 11.2T; the registry table has %d"%(f,mm.group(1),mm.group(0).split()[-1],reg))
print("POP\t%d\t%d\t%d"%(heads,rest,reg))
PY
) || { echo "  [FAIL] GATE 58 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 58 could not judge its subject: $err"; return 1; fi
  local ph pr reg
  IFS=$'\t' read -r ph pr reg < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${ph:-}"; then echo "  [FAIL] GATE 58 printed no population census."; return 1; fi
  if [ "$ph" -lt 1 ]; then echo "  [FAIL] GATE 58 found no '(N independent paths):' heading followed by a table (floor 1) — the grammar moved; nothing judged."; return 1; fi
  local rc=0 tag loc msg
  while IFS=$'\t' read -r tag loc msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $loc: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         One manifest, one count: add the row or fix the number — never quote evidence weight from memory ($R §d3 11.2T)."
    return 1
  fi
  echo "  [ok] GATE 58: $ph witness heading(s) match their tables; $pr 11.2T restatement(s) agree with the registry count $reg"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 59 — "K of the N ... (in)eligible, so the baseline is 1/M" must satisfy M = N-K (or M = K)
# (`baseline-arithmetic`).
#
# QUEUED AS: Codex A-batch designated leg `baseline-arithmetic` (BATCH A03 row 15,
# LITERATURE_RULES_POPULATION_TESTS.md:56): "16 of the 31 non-initial pairs ineligible ... so the
# baseline is 1/16" — its own arithmetic gives 1/15. The published 1/16 was RIGHT (15 ineligible); only
# the rationale was wrong, which is exactly why a reader never catches it.
# MECHANICS: per flattened sentence of tracked md (correction narration stripped: `*(Corrected …)*`,
# `[CORRECTED …]`), the first `K of (the) N … eligible|ineligible` fixes (K, N, polarity); a later
# `baseline (is|of) 1/M` in the same sentence must have M = N-K when ineligible, M = K when eligible.
# POPULATION printed and floored at 1.
# ADJUDICATED-OPEN SITES (the GATE 18 / GATE 47 pattern): documentation/DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv
# names file + the (K, N, M) triple + the reason; a matching hit prints [OPEN] and does NOT set rc; an
# allowance that matches nothing FAILS, so a row cannot outlive the fix it waits for. ZERO rows today:
# the table is header-only. It briefly held reports/TR1_EIGHT_CENTURIES_MEASURED.md:132-134 -- the
# un-swept sibling of the LRPT correction, found by this gate's FIRST live run on 2026-09-02 -- and the
# prose lane FIXED that site the same day (TR-1 v1.32, TR-7 v2.5, CORRECTIONS entry appended), so the
# row was removed rather than left standing. That is the intended lifecycle and it is worth stating:
# the backlog row for this defect said explicitly "deliberately NOT whitelisted ... rather than being
# allow-rowed into silence", so an [OPEN] row here is a SHORT-LIVED holding position for a defect
# already scheduled to be fixed, never a resting place for one that is not.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:documentation/LITERATURE_RULES_POPULATION_TESTS.md`)
# -> HIT "16 of the 31 … ineligible … 1/16 (expected 1/15)", rc 1; live "15 of the 31 … ineligible … 1/16"
# -> rc 0 with TR-1 printed [OPEN] (the `*(Corrected …)*` narration quoting the old 16 is stripped, not
# counted); mutation (live LRPT 15 -> 14) -> HIT rc 1; OPEN row deleted -> TR-1 FAILs rc 1; OPEN row
# pointed at a file with no such sentence -> "allowance matched nothing" FAIL rc 1.
gate_baseline_arithmetic() {
  echo "== GATE 59: 'K of the N ... ineligible, so the baseline is 1/M' satisfies M = N-K =="
  local A=documentation/DOC_GATE_BASELINE_ARITHMETIC_OPEN.tsv out
  require_tracked "$A" || { [ $? -eq 2 ] && return 1; echo "  [skip] $A absent and untracked"; return 0; }
  out=$(python3 - "$A" <<'PY'
import re, io, subprocess, sys
A=sys.argv[1]
allow={}
for line in io.open(A,encoding="utf-8").read().split("\n"):
    if not line.strip() or line.startswith("#"): continue
    c=line.split("\t")
    if len(c)<5: print("ERROR\t%s row has %d columns, need 5 (file, K, N, M, reason): %r"%(A,len(c),line[:60])); sys.exit(0)
    allow[(c[0],int(c[1]),int(c[2]),int(c[3]))]=[c[4],0]
files=subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split()
n=0
for f in files:
    t=io.open(f,encoding="utf-8").read()
    for p in re.split(r"\n\s*\n",t):
        p=re.sub(r"\*\(Corrected\b.*?\)\*"," ",p,flags=re.S)
        p=re.sub(r"\[CORRECTED\b.*?\]"," ",p,flags=re.S)
        flat=" ".join(p.replace("*","").split())
        for s in re.split(r"(?<=[.!?])\s+",flat):
            mb=re.search(r"baseline (?:is|of) 1/(\d+)",s)
            if not mb: continue
            mk=re.search(r"\b(\d+) of (?:the )?(\d+)\b[^.;]*?\b(ineligible|eligible)\b",s[:mb.start()])
            if not mk: continue
            n+=1
            K,N,pol=int(mk.group(1)),int(mk.group(2)),mk.group(3)
            M=int(mb.group(1)); exp=N-K if pol=="ineligible" else K
            if M!=exp:
                key=(f,K,N,M)
                if key in allow:
                    allow[key][1]+=1; print("OPEN\t%s\t%d of %d %s -> 1/%d (arithmetic gives 1/%d) — adjudicated open: %s"%(f,K,N,pol,M,exp,allow[key][0]))
                else: print("HIT\t%s\t%d of %d %s -> baseline 1/%d, but N-K arithmetic gives 1/%d"%(f,K,N,pol,M,exp))
for key,(why,used) in allow.items():
    if used==0: print("HIT\t%s\tallowance (%d of %d -> 1/%d) matched NOTHING — the site was fixed or moved; delete the row from %s"%(key[0],key[1],key[2],key[3],A))
print("POP\t%d\t%d"%(n,len(files)))
PY
) || { echo "  [FAIL] GATE 59 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 59 could not read its allowance table: $err"; return 1; fi
  local pn pf
  IFS=$'\t' read -r pn pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 59 printed no population census."; return 1; fi
  if [ "$pn" -lt 1 ]; then echo "  [FAIL] GATE 59 found no 'K of the N … (in)eligible … baseline is 1/M' sentence across $pf docs (floor 1) — the grammar moved; nothing judged."; return 1; fi
  local rc=0 tag f msg no=0
  while IFS=$'\t' read -r tag f msg; do
    case "$tag" in
      HIT) echo "  [FAIL] $f: $msg"; rc=1 ;;
      OPEN) echo "  [OPEN] $f: $msg"; no=$((no+1)) ;;
    esac
  done < <(printf '%s\n' "$out")
  [ "$rc" -ne 0 ] && return 1
  echo "  [ok] GATE 59: $pn eligibility-baseline sentence(s) across $pf docs; $((pn-no)) arithmetically self-consistent, $no adjudicated-open (listed above, NOT covered by this verdict)"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 60 — the zero-cell percentage and the .bin-per-cell coefficient equal the campaign actuals
# in the same file (`derived-coefficient`).
#
# QUEUED AS: Codex A-batch designated leg `derived-coefficient` (BATCH A02 row 11,
# CAMPAIGN_METHODOLOGY.md:634-635): "63.6 % of fully-scanned cells produced zero solutions … roughly
# 0.37×" against the same file's finals (93,083 zero cells of 158,364 = 58.78 %; 65,281/158,364 = 0.4122).
# MECHANICS: actuals from the campaign table — `| Cells with zero solutions | Z (P %)` and the cell total
# from `= 560 T / T cells`. Claims, outside `[CORRECTED …]` spans: every `X % of fully-scanned cells
# produced zero` and every `roughly C× the scanned-cells count`. X must equal 100·Z/T and C must equal
# (T-Z)/T, each at the claim's own printed precision; the table's own P must equal 100·Z/T too.
# POPULATION printed and floored at 1 percentage claim + 1 coefficient claim.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show d70d8dde:documentation/CAMPAIGN_METHODOLOGY.md`)
# -> 2 HITs (63.6 vs 58.8; 0.37 vs 0.41), rc 1; live -> 58.8 / 0.41 pass, the CORRECTED span quoting
# 63.6/0.37 is stripped, rc 0; mutation (live 0.41 -> 0.37) -> HIT rc 1; actuals row deleted -> ERROR.
gate_derived_coefficient() {
  echo "== GATE 60: CAMPAIGN_METHODOLOGY.md's zero-cell % and .bin-per-cell coefficient equal its own campaign actuals =="
  local F=documentation/CAMPAIGN_METHODOLOGY.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
t=io.open(F,encoding="utf-8").read()
mz=re.search(r"^\|\s*Cells with zero solutions\s*\|\s*([\d,]+)\s*\(([\d.]+)\s*%\)",t,re.M)
mt=re.search(r"=\s*560\s*T\s*/\s*([\d,]+)\s*cells",t)
if not mz: print("ERROR\t%s has no '| Cells with zero solutions | Z (P %%)' actuals row"%F); sys.exit(0)
if not mt: print("ERROR\t%s no longer states the cell total as '= 560 T / N cells'"%F); sys.exit(0)
Z=int(mz.group(1).replace(",","")); T=int(mt.group(1).replace(",",""))
pct=100.0*Z/T; coef=(T-Z)/T
def dec(s): return len(s.split(".")[1]) if "." in s else 0
def eq(claim,actual): return round(actual,dec(claim))==float(claim)
if not eq(mz.group(2),pct): print("HIT\tactuals row\tzero-cell row prints %s %% but %s/%s = %.2f %%"%(mz.group(2),mz.group(1),mt.group(1),pct))
body=re.sub(r"\[CORRECTED\b.*?\]"," ",t,flags=re.S).replace("*","")
flat=" ".join(body.split())
np_=nc=0
for m in re.finditer(r"([\d.]+)\s*% of fully-scanned cells produced zero",flat):
    np_+=1
    if not eq(m.group(1),pct): print("HIT\tprose\t'%s %% of fully-scanned cells produced zero' but the actuals give %.2f %% (%d of %d)"%(m.group(1),pct,Z,T))
for m in re.finditer(r"roughly ([\d.]+)×? ?the scanned-cells count",flat):
    nc+=1
    if not eq(m.group(1),coef): print("HIT\tprose\t'roughly %s× the scanned-cells count' but (T-Z)/T = %.4f"%(m.group(1),coef))
print("POP\t%d\t%d\t%d\t%d"%(np_,nc,Z,T))
PY
) || { echo "  [FAIL] GATE 60 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 60 could not judge its subject: $err"; return 1; fi
  local pp pc z tt
  IFS=$'\t' read -r pp pc z tt < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pp:-}"; then echo "  [FAIL] GATE 60 printed no population census."; return 1; fi
  if [ "$pp" -lt 1 ] || [ "$pc" -lt 1 ]; then echo "  [FAIL] GATE 60 found $pp percentage claim(s) and $pc coefficient claim(s) in $F (floor 1 each) — the sentence grammar moved; nothing judged."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F ($where): $msg"; rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -ne 0 ] && return 1
  echo "  [ok] GATE 60: $pp zero-cell % claim(s) and $pc coefficient claim(s) agree with the actuals ($z zero cells of $tt)"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 61 — a CPU vendor is never paired with another vendor's microarchitecture (`cpu-vendor`).
#
# QUEUED AS: Codex A-batch designated leg `cpu-vendor` (BATCH A02 row 34, BRANCHES_EXPLAINED.md:399):
# "Intel Zen 5 vs ARM Cobalt 100" — Zen is AMD's. The prescribed shared SKU->CPU table is NOT built
# here (no such registry exists in-tree; inventing one would be a hand-kept table nothing derives), so
# this is the vendor<->family half only: a registered mapping of vendor word to architecture family.
# MECHANICS: over tracked md (CORRECTIONS.md excluded as the ledger of quoted defects; `*Revision …`
# paragraphs and `[CORRECTED …]` spans stripped as narration), every `<Vendor> <Family>` adjacency with
# Vendor in {Intel, AMD, ARM, Ampere} and Family in {Zen, EPYC, Ryzen, Xeon, Core i, Cobalt, Neoverse,
# Altra, Graviton} must be a registered pair. POPULATION printed and floored at 3 adjacencies.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show d70d8dde:documentation/BRANCHES_EXPLAINED.md`)
# -> HIT "Intel Zen", rc 1; live -> 0 mismatches over the measured adjacency population, rc 0
# (BRANCHES_EXPLAINED.md:808's revision narration quoting "Intel Zen 5" is stripped, not counted);
# mutation (live "AMD EPYC" -> "Intel EPYC" at one site) -> HIT rc 1.
gate_cpu_vendor() {
  echo "== GATE 61: a CPU vendor is paired only with its own microarchitecture family =="
  local out
  out=$(python3 - <<'PY'
import re, io, subprocess, sys
OK={"intel":{"xeon","core"},"amd":{"zen","epyc","ryzen"},"arm":{"cobalt","neoverse","altra","graviton"},"ampere":{"altra","neoverse"}}
files=[f for f in subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split() if not f.endswith("CORRECTIONS.md")]
n=0
for f in files:
    t=io.open(f,encoding="utf-8").read()
    for p in re.split(r"\n\s*\n",t):
        if p.lstrip().startswith("*Revision") or p.lstrip().startswith("*(Revision"): continue
        p=re.sub(r"\[CORRECTED\b.*?\]"," ",p,flags=re.S)
        flat=" ".join(p.replace("*","").split())
        for m in re.finditer(r"\b(Intel|AMD|ARM|Ampere)\s+(Zen|EPYC|Ryzen|Xeon|Core|Cobalt|Neoverse|Altra|Graviton)\b",flat):
            n+=1
            if m.group(2).lower() not in OK[m.group(1).lower()]:
                print("HIT\t%s\t'%s' — %s does not make %s parts"%(f,m.group(0),m.group(1),m.group(2)))
print("POP\t%d\t%d"%(n,len(files)))
PY
) || { echo "  [FAIL] GATE 61 scanner failed — NOTHING was checked."; return 1; }
  local pn pf
  IFS=$'\t' read -r pn pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 61 printed no population census."; return 1; fi
  if [ "$pn" -lt 3 ]; then echo "  [FAIL] GATE 61 found only $pn vendor+family adjacency(ies) across $pf docs (floor 3) — the corpus moved; nothing judged."; return 1; fi
  local rc=0 tag f msg
  while IFS=$'\t' read -r tag f msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -ne 0 ] && return 1
  echo "  [ok] GATE 61: $pn vendor+family adjacency(ies) across $pf docs, every pairing registered"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 62 — every Azure resource name DEPLOYMENT.md shows/deletes/attaches was created in the same
# section, or is a documented pre-existing resource (`az-name-closure`).
#
# QUEUED AS: Codex A-batch designated leg `az-name-closure` (batch 10 row 13, DEPLOYMENT.md:640 appendix):
# the example created `solver-nic` and then queried `spot-nic`, queried a `spot-pip` it never created,
# and tore down `spot-nic`/`spot-pip`/`spot-nsg`/`spot-vnet` — rename residue from a partial sweep.
# MECHANICS: DEPLOYMENT.md is split at H2 headings. Backslash-continued lines are joined. In each
# section, CREATED = names after `-n|--name` on `az … create`, plus the resource segment of an
# `az rest --method PUT --url …/<type>/<name>?`; REFERENCED = names after `-n|--name|--vm-name` on
# `az … show|delete|update|get-instance-view|start|stop|deallocate|wait|attach|detach`. A referenced
# name that is a shell variable (`$X`, `"$X"`), a placeholder (`<x>`), or on the pre-existing allowlist
# (`solver-data` — the persistent data disk; `claude-vnet` / `claude` — the orchestrator's) is skipped;
# any other referenced name absent from the section's CREATED set is a HIT. Same-section, not
# strictly-prior: the ad-hoc lifecycle section shows its cleanup pattern before its create pattern.
# POPULATION printed and floored at 3 references.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:documentation/DEPLOYMENT.md`) ->
# HITs spot-nic ×2, spot-pip ×2, spot-nsg, spot-vnet, plus the exact-name `az disk delete -n temp-vm_OsDisk_*`
# glob the live doc itself later fixed, rc 1; live -> all 16 references close, rc 0;
# mutation (live `az network nic show … -n solver-nic` -> `spot-nic`) -> HIT rc 1.
gate_az_name_closure() {
  echo "== GATE 62: every az resource name DEPLOYMENT.md references was created in its section (or is pre-existing) =="
  local F=documentation/DEPLOYMENT.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
ALLOW={"solver-data","claude-vnet","claude"}
t=io.open(F,encoding="utf-8").read()
t=re.sub(r"\\\n\s*"," ",t)
secs=re.split(r"(?m)^## ",t)
nref=0
for si,sec in enumerate(secs):
    title=sec.split("\n",1)[0][:50]
    created=set()
    for m in re.finditer(r"\baz\s+(?:[a-z-]+\s+)+create\b[^\n]*?(?:\s-n|\s--name)\s+([^\s\"'\\]+)",sec): created.add(m.group(1))
    for m in re.finditer(r"az rest --method PUT[^\n]*?/(?:virtualMachines|disks|networkInterfaces|publicIPAddresses|virtualNetworks|networkSecurityGroups)/([A-Za-z0-9_.-]+)\??",sec): created.add(m.group(1))
    for ln,line in enumerate(sec.split("\n"),1):
        for m in re.finditer(r"\baz\s+(?:[a-z-]+\s+)+(?:show|delete|update|get-instance-view|start|stop|deallocate|wait|attach|detach)\b(.*)$",line):
            tail=m.group(1)
            for nm in re.findall(r"(?:\s-n|\s--name|\s--vm-name)\s+([^\s\"'\\]+)",tail):
                if nm.startswith("$") or nm.startswith("<") or nm.startswith("{") or "$" in nm: continue
                nref+=1
                if nm in ALLOW or nm in created: continue
                print("HIT\t%s\t%s\t%s"%(title,nm,line.strip()[:100]))
print("POP\t%d\t%d"%(nref,len(secs)))
PY
) || { echo "  [FAIL] GATE 62 scanner failed — NOTHING was checked."; return 1; }
  local pn ps
  IFS=$'\t' read -r pn ps < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 62 printed no population census."; return 1; fi
  if [ "$pn" -lt 3 ]; then echo "  [FAIL] GATE 62 found only $pn literal az resource reference(s) in $F (floor 3) — the appendix moved or its commands changed shape; nothing judged."; return 1; fi
  local rc=0 tag sec nm line
  while IFS=$'\t' read -r tag sec nm line; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F §\"$sec\": '$nm' is referenced but never created in this section (and is not a documented pre-existing resource): $line"; rc=1
  done < <(printf '%s\n' "$out")
  [ "$rc" -ne 0 ] && return 1
  echo "  [ok] GATE 62: $pn literal az resource reference(s) across $ps sections of $F, every one created in its section or pre-existing"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 63 — every definition of a registered term carries the term's discriminating token
# (`glossary-consistency`).
#
# QUEUED AS: Codex A-batch designated leg `glossary-consistency` (BATCH A02 row 30,
# BRANCHES_EXPLAINED.md:277-279/:629): the body defined a node as "every step from a parent to a
# child" and the glossary as "one parent-to-child decision", while :314-319 said the frame the walk
# starts from is counted — a one-node difference against a sha-determining 3,536,157,207 budget.
# The general "any term defined twice must agree" is UNGATEABLE (paraphrase); this is the registered-
# term core the row prescribed, with exactly one term registered: node -> `frame`.
# MECHANICS: in documentation/BRANCHES_EXPLAINED.md, definition sites of `node` are (a) the glossary
# row `| **Node** | … |` and (b) every flattened sentence matching `(is|counts as) (a|one)? "node"`
# (any quote style, or none). Each must contain `frame`. `[CORRECTED …]` spans and `*Revision` paragraphs
# are stripped. POPULATION printed and floored at 2 (glossary row + >= 1 body definition).
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show d70d8dde:documentation/BRANCHES_EXPLAINED.md`)
# -> 2 HITs at d70d8dde (:277 body, :629 glossary), rc 1; live -> "every frame entry is a node" + glossary "one frame
# entry", rc 0; mutation (live glossary row with BOTH `frame` mentions replaced by "parent-to-child")
# -> HIT rc 1 (a first mutation that left the cell's second `frame` in place did not fire — correctly).
gate_glossary_consistency() {
  echo "== GATE 63: every definition of 'node' in BRANCHES_EXPLAINED.md names the frame (registered term list: node) =="
  local F=documentation/BRANCHES_EXPLAINED.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
TERMS={"node":"frame"}
t=io.open(F,encoding="utf-8").read()
n=0
for term,disc in TERMS.items():
    for p in re.split(r"\n\s*\n",t):
        if p.lstrip().startswith("*Revision"): continue
        p=re.sub(r"\[CORRECTED\b.*?\]"," ",p,flags=re.S)
        for line in p.split("\n"):
            m=re.match(r"^\|\s*\*\*%s\*\*\s*\|(.*)$"%term.capitalize(),line.strip())
            if m:
                n+=1
                if disc not in m.group(1).lower(): print("HIT\tglossary row\t%s"%line.strip()[:120])
        flat=" ".join(p.replace("*","").split())
        if flat.startswith("|") or flat.startswith("#"): continue
        for s in re.split(r"(?<=[.!?])\s+",flat):
            if re.search(r"\b(?:is|counts as) (?:a |one )?[\"“'‘]?%s[\"”'’]?(?=[\s,.;:—)])"%term,s):
                n+=1
                if disc not in s.lower(): print("HIT\tbody definition\t%s"%s[:120])
print("POP\t%d"%n)
PY
) || { echo "  [FAIL] GATE 63 scanner failed — NOTHING was checked."; return 1; }
  local pn
  pn=$(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 63 printed no population census."; return 1; fi
  if [ "$pn" -lt 2 ]; then echo "  [FAIL] GATE 63 found only $pn definition site(s) of 'node' in $F (floor 2: glossary row + body) — the definitions moved; nothing judged."; return 1; fi
  local rc=0 tag where s
  while IFS=$'\t' read -r tag where s; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F ($where) defines a node without naming the frame: $s"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         The frame the walk starts from is counted (§'Exactly what counts as a node'); a parent-to-child definition is one node short per walk."; return 1; fi
  echo "  [ok] GATE 63: $pn definition site(s) of 'node' in $F, each naming the frame"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 64 — every "C1–C5 plus N" / "C1–C7 plus N" identifying-set count agrees with BOUNDARY_MINIMUM.md's
# result table (`identifying-set-arity`).
#
# QUEUED AS: Codex A-batch designated leg `identifying-set-arity` (BATCH A03 row 21, SPECIFICATION.md:3):
# "C1–C7 plus four … five" double-counted C6 and C7, which are boundaries 27 and 25 and sit INSIDE the
# four/five-boundary greedy sets per BOUNDARY_MINIMUM.md's "{25, 27} in greedy set?" column.
# MECHANICS: registry = BOUNDARY_MINIMUM.md rows `| <dataset> | **size** | … | ✓ |` -> the set S of
# greedy-minimum sizes and, for rows whose last cell is ✓, S-2. Claims over tracked md (CORRECTIONS.md/
# HISTORY.md excluded; `[CORRECTED …]` spans and `*Revision` paragraphs stripped): `C1–C5 plus (the) N`
# needs N ∈ S; `C1–C7 plus (the) N` needs N ∈ {s-2}. N is a digit or a number word; a non-numeric
# continuation ("plus the dedup semantics", "plus C6 and C7") is not a count and is skipped.
# POPULATION printed and floored at 1 claim.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:documentation/SPECIFICATION.md`) ->
# HIT "C1–C7 plus four" (4 ∉ {2,3}), rc 1; live -> "C1–C5 plus four", "C1–C7 plus two", "C1–C7 plus
# three", "C1–C5 plus the five" all consistent, rc 0; mutation (live "plus two" -> "plus four") -> HIT rc 1;
# registry ✓ column blanked -> the C7 set empties and every "C1–C7 plus N" claim HITs (rc 1).
gate_identifying_set_arity() {
  echo "== GATE 64: every 'C1–C5/C1–C7 plus N' identifying-set count matches BOUNDARY_MINIMUM.md's result table =="
  local R=documentation/BOUNDARY_MINIMUM.md out
  require_tracked "$R" || { [ $? -eq 2 ] && return 1; echo "  [skip] $R absent and untracked"; return 0; }
  out=$(python3 - "$R" <<'PY'
import re, io, subprocess, sys
R=sys.argv[1]
W={"one":1,"two":2,"three":3,"four":4,"five":5,"six":6,"seven":7,"eight":8,"nine":9,"ten":10}
reg=io.open(R,encoding="utf-8").read()
S=set(); S7=set()
for line in reg.split("\n"):
    m=re.match(r"^\|\s*\**(d[23] \S+[^|]*?)\**\s*\|\s*\**(\d+)\**\s*\|(.*)\|\s*$",line.strip())
    if not m: continue
    size=int(m.group(2)); S.add(size)
    last=m.group(3).split("|")[-1]
    if "✓" in last: S7.add(size-2)
if not S: print("ERROR\t%s has no '| d? … | **size** | … |' result rows — the registry cannot be read"%R); sys.exit(0)
files=[f for f in subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split() if not (f.endswith("CORRECTIONS.md") or f.endswith("HISTORY.md"))]
n=0
for f in files:
    t=io.open(f,encoding="utf-8").read()
    for p in re.split(r"\n\s*\n",t):
        if p.lstrip().startswith("*Revision"): continue
        p=re.sub(r"\[CORRECTED\b.*?\]"," ",p,flags=re.S)
        flat=" ".join(p.replace("*","").split())
        for m in re.finditer(r"C1[–-]C([57]) plus (?:the )?(\d+|one|two|three|four|five|six|seven|eight|nine|ten)\b",flat):
            v=m.group(2).lower(); N=int(v) if v.isdigit() else W[v]; base=m.group(1)
            n+=1
            allowed=S if base=="5" else S7
            if N not in allowed: print("HIT\t%s\t'%s' — allowed counts are %s (BOUNDARY_MINIMUM.md sizes %s%s)"%(f,m.group(0),sorted(allowed),sorted(S),"" if base=="5" else ", minus the two that are C6/C7"))
print("POP\t%d\t%d\t%s\t%s"%(n,len(files),",".join(map(str,sorted(S))),",".join(map(str,sorted(S7)))))
PY
) || { echo "  [FAIL] GATE 64 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 64 could not judge its subject: $err"; return 1; fi
  local pn pf s s7
  IFS=$'\t' read -r pn pf s s7 < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4"\t"$5; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 64 printed no population census."; return 1; fi
  if [ "$pn" -lt 1 ]; then echo "  [FAIL] GATE 64 found no 'C1–C5/C1–C7 plus N' claim across $pf docs (floor 1) — the grammar moved; nothing judged."; return 1; fi
  local rc=0 tag f msg
  while IFS=$'\t' read -r tag f msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         C6 and C7 ARE boundaries 27 and 25, inside every greedy set ($R) — 'C1–C7 plus' must not count them twice."; return 1; fi
  echo "  [ok] GATE 64: $pn identifying-set claim(s) across $pf docs agree with $R (greedy sizes {$s}; beyond C1–C7: {$s7})"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 65 — a "stdlib only" claim naming a file that imports third-party modules must be scoped
# (`stdlib-claims`).
#
# QUEUED AS: Codex A-batch designated leg `stdlib-claims` (batch 11 row 6, DEVELOPMENT.md:47 +
# METHODS.md:93): "Stdlib only; no third-party modules are required" for tests.py/solve.py/roae.py/
# verify.py, while solve.py's P2 modes and verify.py --check-t5-c3 import numpy/pyarrow — V2-L13 hit
# ModuleNotFoundError following the doc.
# MECHANICS: per flattened paragraph (or table row) of tracked md, CORRECTIONS.md/HISTORY.md excluded,
# a stdlib claim is `stdlib-only|stdlib only|standard library … no third-party|no third-party
# (modules|dependencies)`. The files it names are the tracked `*.py` paths in the same paragraph. For
# each named file, THIRD-PARTY = any `import|from` of numpy|pyarrow|pandas|scipy|sklearn|matplotlib at
# any indentation (lazy imports count — they are the ones that fail). "Named" = a .py path in the
# clause (split at `.`/`;`) that carries the claim, or — when that clause names none — in the clause
# just before it ("for tests.py, solve.py, …. Stdlib only;" is the pre-fix shape). MEASURED: a whole-
# paragraph scope fired on reports/evidence/r11/README.md ("r11_calibration.py … stdlib-only; reuses the
# M_G builder in solve.py"), a correct sentence, so the clause rule is what separates the two.
# A claim naming such a file must carry a scope word in the same paragraph: core|except|default|
# optional|lazily|lazy|P2|itself|Scoped|--check-t5-c3. POPULATION printed and floored at 3 claims.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:` DEVELOPMENT.md:47@89e7a9a1 + METHODS.md:93@89e7a9a1)
# -> 2 HITs (solve.py 39 third-party import lines, verify.py 2; no scope word), rc 1; live -> every
# claim naming solve.py/verify.py carries core/default/except/lazily, rc 0 (12 claims, 7 naming such a
# file); mutation (live DEVELOPMENT.md:47-55 bullet replaced by the unscoped pre-fix sentence) -> HIT rc 1
# — a mutation touching only :47 did NOT fire because the same bullet carries `P2` at :51/:55, i.e. the
# paragraph-scope qualifier is deliberately lenient: the bullet as a whole IS scoped.
gate_stdlib_claims() {
  echo "== GATE 65: a 'stdlib only' claim naming a file that imports third-party modules carries a scope word =="
  local out
  out=$(python3 - <<'PY'
import re, io, subprocess, sys
files=[f for f in subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split() if not (f.endswith("CORRECTIONS.md") or f.endswith("HISTORY.md"))]
tracked=set(subprocess.run(["git","ls-files"],capture_output=True,text=True).stdout.split())
imp={}
def third(path):
    if path not in imp:
        try: src=io.open(path,encoding="utf-8").read()
        except Exception: src=""
        imp[path]=len(re.findall(r"(?m)^\s*(?:import|from)\s+(?:numpy|pyarrow|pandas|scipy|sklearn|matplotlib)\b",src))
    return imp[path]
CLAIM=re.compile(r"stdlib[ -]only|standard library[^.]{0,40}no third-party|no third-party (?:modules|dependencies)",re.I)
SCOPE=re.compile(r"\b(core|except|default|optional|lazily|lazy|P2|itself|Scoped)\b|--check-t5-c3")
n=0; named=0
for f in files:
    t=io.open(f,encoding="utf-8").read()
    for p in re.split(r"\n\s*\n",t):
        units=[l for l in p.split("\n") if l.lstrip().startswith("|")] or [" ".join(p.split())]
        for u in units:
            u=" ".join(u.replace("*","").split())
            if not CLAIM.search(u): continue
            n+=1
            clauses=re.split(r"(?<=[.;])\s+",u)
            named_files=set()
            for ci,cl in enumerate(clauses):
                if not CLAIM.search(cl): continue
                fs=set(re.findall(r"`?([A-Za-z0-9_./-]+\.py)`?",cl))
                if not fs and ci>0: fs=set(re.findall(r"`?([A-Za-z0-9_./-]+\.py)`?",clauses[ci-1]))
                named_files|=fs
            for py in named_files:
                cands=[py] if py in tracked else [x for x in tracked if x.endswith("/"+py)]
                for c in cands:
                    k=third(c)
                    if k==0: continue
                    named+=1
                    if not SCOPE.search(u): print("HIT\t%s\t%s has %d third-party import line(s) but the claim carries no scope word: %s"%(f,c,k,u[:110]))
print("POP\t%d\t%d\t%d"%(n,named,len(files)))
PY
) || { echo "  [FAIL] GATE 65 scanner failed — NOTHING was checked."; return 1; }
  local pn pm pf
  IFS=$'\t' read -r pn pm pf < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 65 printed no population census."; return 1; fi
  if [ "$pn" -lt 3 ]; then echo "  [FAIL] GATE 65 found only $pn stdlib claim(s) across $pf docs (floor 3) — the grammar moved; nothing judged."; return 1; fi
  local rc=0 tag f msg
  while IFS=$'\t' read -r tag f msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $f: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         Scope it: 'stdlib only for the core paths; the P2 modes / --check-t5-c3 need numpy/pyarrow' (DEVELOPMENT.md:47-53 form)."; return 1; fi
  echo "  [ok] GATE 65: $pn stdlib claim(s) across $pf docs; $pm name a file with third-party imports and each of those is scoped"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 66 — TRIGRAM_STRUCTURE.md's "verbatim" ledger block IS the header of lean/TrigramTheorems.lean
# (`lean-header-verbatim`).
#
# QUEUED AS: Codex A-batch designated leg `lean-header-verbatim` (BATCH A04 row 16,
# TRIGRAM_STRUCTURE.md:242): the block said "reproduced verbatim" and differed in 12 lines / 3 hunks —
# one word change ("kernel-checked" -> "machine-checked", a trust-base weakening) and two inserted
# parentheticals.
# MECHANICS: the fenced block after the paragraph that says the ledger is reproduced (the first fence
# following the line containing "binding ledger") is compared line-by-line, after rstrip, against the
# Lean file from the first line equal to the block's first line (comment indent of two spaces stripped).
# Trailing truncation of the block is allowed; any interior difference, insertion, or a block longer
# than the header is a HIT. If the doc states its own range "lines A–B of that file", A must be where
# the block was found and B its end, else HIT (the doc's own claim about itself is checked too).
# POPULATION printed and floored at 20 block lines.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:` both files) -> first divergence at
# the TG-1 "machine-checked" line, rc 1; live -> 72 lines identical to lean lines 44–115, rc 0; mutation
# (live block with one interior line changed) -> HIT rc 1; block deleted -> ERROR rc 1.
gate_lean_header_verbatim() {
  echo "== GATE 66: TRIGRAM_STRUCTURE.md's fenced attribution ledger is verbatim lean/TrigramTheorems.lean's header =="
  local F=documentation/TRIGRAM_STRUCTURE.md L=lean/TrigramTheorems.lean out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  require_tracked "$L" || { [ $? -eq 2 ] && return 1; echo "  [skip] $L absent and untracked"; return 0; }
  out=$(python3 - "$F" "$L" <<'PY'
import re, io, sys
F,L=sys.argv[1],sys.argv[2]
doc=io.open(F,encoding="utf-8").read().split("\n")
lean=[l.rstrip() for l in io.open(L,encoding="utf-8").read().split("\n")]
start=None
for i,l in enumerate(doc):
    if "binding ledger" in l: start=i; break
if start is None: print("ERROR\t%s no longer says which block is the binding ledger"%F); sys.exit(0)
i=start
while i<len(doc) and not doc[i].strip().startswith("```"): i+=1
if i>=len(doc): print("ERROR\t%s has no fenced block after 'binding ledger'"%F); sys.exit(0)
blk=[]; j=i+1
while j<len(doc) and not doc[j].strip().startswith("```"): blk.append(doc[j].rstrip()); j+=1
while blk and blk[-1]=="": blk.pop()
if not blk: print("ERROR\t%s: the ledger fence is empty"%F); sys.exit(0)
stripped=[re.sub(r"^  ","",l) for l in lean]
try: a=stripped.index(blk[0])
except ValueError: print("HIT\tblock line 1\t%r is not a line of %s"%(blk[0][:80],L)); print("POP\t%d"%len(blk)); sys.exit(0)
hits=0
for k,bl in enumerate(blk):
    if a+k>=len(stripped): print("HIT\tblock line %d\tblock runs past the end of %s"%(k+1,L)); hits+=1; break
    if bl!=stripped[a+k]:
        print("HIT\tblock line %d (doc :%d vs %s:%d)\tdoc: %r | lean: %r"%(k+1,i+2+k,L,a+k+1,bl[:70],stripped[a+k][:70])); hits+=1
        if hits>=3: break
m=re.search(r"lines (\d+)[–-](\d+) of that file"," ".join(doc[start:i]))
if m:
    A,B=int(m.group(1)),int(m.group(2))
    if A!=a+1 or B!=a+len(blk): print("HIT\tdoc's own range claim\tsays lines %d–%d, but the block matches %s:%d–%d"%(A,B,L,a+1,a+len(blk)))
print("POP\t%d\t%d"%(len(blk),a+1))
PY
) || { echo "  [FAIL] GATE 66 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 66 could not judge its subject: $err"; return 1; fi
  local pn pa
  IFS=$'\t' read -r pn pa < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 66 printed no population census."; return 1; fi
  if [ "$pn" -lt 20 ]; then echo "  [FAIL] GATE 66: the ledger block has only $pn line(s) (floor 20) — it was truncated to nothing; nothing judged."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F ($where): $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         The block claims to be verbatim: move annotations outside the fence, or land them in the Lean header."; return 1; fi
  echo "  [ok] GATE 66: $pn-line ledger block is byte-identical (indent-stripped) to $L from line $pa"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 67 — every Evidence-type cell of PARTITION_INVARIANCE.md's evidence table is drawn from the
# closed vocabulary, and a heading claiming every scale needs every row DIRECT
# (`evidence-type-vocabulary`).
#
# QUEUED AS: Codex A-batch designated leg `evidence-type-vocabulary` (BATCH A03 row 26,
# PARTITION_INVARIANCE.md:286/:296): the 560T row was labelled "Direct second same-scale witness" for a
# same-partition determinism re-run, under a heading "verified at every canonical scale to date".
# MECHANICS: the table whose header names `Evidence type`; each data row's last cell, bold stripped,
# must BEGIN with one of: Partition-path | Execution-mode | Host/ISA | Re-run determinism | Inherited
# (case-insensitive). LEG 2: the nearest preceding heading, if it says "every … scale", requires every
# row's type ∈ {Partition-path, Execution-mode} (the two DIRECT partition witnesses).
# POPULATION printed and floored at 3 rows.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:documentation/PARTITION_INVARIANCE.md`)
# -> 4 vocabulary HITs ("Direct sha-equality across …") + the "every canonical scale" heading over a
# non-direct row, rc 1; live -> 4 rows in vocabulary, heading scoped "directly at 5.6 T and 100 T;
# inherited at 560 T", rc 0; mutation (live 560T cell "Re-run determinism" -> "Direct second witness")
# -> HIT rc 1; heading mutated to "every canonical scale" -> LEG 2 HIT rc 1.
gate_evidence_type_vocabulary() {
  echo "== GATE 67: PARTITION_INVARIANCE.md evidence-type cells use the closed vocabulary; 'every scale' needs every row direct =="
  local F=documentation/PARTITION_INVARIANCE.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
VOCAB=["partition-path","execution-mode","host/isa","re-run determinism","inherited"]
DIRECT={"partition-path","execution-mode"}
lines=io.open(F,encoding="utf-8").read().split("\n")
hi=None
for i,l in enumerate(lines):
    if l.lstrip().startswith("|") and "evidence type" in l.lower(): hi=i; break
if hi is None: print("ERROR\t%s has no table with an 'Evidence type' column"%F); sys.exit(0)
head=""
for k in range(hi,-1,-1):
    if lines[k].startswith("#"): head=lines[k]; break
rows=0; k=hi+1; types=[]
while k<len(lines) and lines[k].lstrip().startswith("|"):
    c=lines[k].strip()
    if not re.match(r"^\|\s*:?-",c):
        cells=[x.strip() for x in re.split(r"(?<!\\)\|", c.strip("|"))]  # Q-525: escape-aware
        cell=cells[-1].replace("**","").strip()
        rows+=1
        t=next((v for v in VOCAB if cell.lower().startswith(v)),None)
        types.append(t)
        if t is None: print("HIT\t:%d\tEvidence-type cell is not in the closed vocabulary %s: %r"%(k+1,VOCAB,cell[:80]))
    k+=1
if re.search(r"\bevery\b.*\bscale",head,re.I):
    nd=[i for i,t in enumerate(types) if t not in DIRECT]
    if nd: print("HIT\theading\t%r claims every scale, but %d row(s) carry a non-direct evidence type"%(head.strip()[:90],len(nd)))
print("POP\t%d"%rows)
PY
) || { echo "  [FAIL] GATE 67 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 67 could not judge its subject: $err"; return 1; fi
  local pn
  pn=$(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 67 printed no population census."; return 1; fi
  if [ "$pn" -lt 3 ]; then echo "  [FAIL] GATE 67 found only $pn evidence row(s) in $F (floor 3) — the table shrank; nothing judged."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F ($where): $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         A witness that is real but witnesses a different proposition needs its own type; 'every scale' is earned only by direct rows."; return 1; fi
  echo "  [ok] GATE 67: $pn evidence row(s) in $F, every type in the closed vocabulary; the heading claims no more than the rows carry"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 68 — SPECIFICATION.md's enumeration of observed wrap distances names d=5 or scopes itself
# (`theorem-vs-slice`).
#
# QUEUED AS: Codex A-batch designated leg `theorem-vs-slice` (BATCH A03 row 22, SPECIFICATION.md:173):
# the theorem admits every odd wrap; the sentence "(d=1 vs d=3)" read as exhaustive while
# CIRCULAR_KING_WEN.md publishes a C1–C5-valid witness with wrap d=5 (absent from the 560T slice).
# MECHANICS: every flattened SPECIFICATION.md sentence (`[CORRECTED …]` spans stripped) containing
# `d=1 vs d=3` must contain `d=5` or a scope marker: `within the canonical` | `as measured` | `slice` |
# `in the enumerated`. Kept to SPECIFICATION.md as the row prescribed: SOLVE_C_CLI.md:922 uses the same
# phrase to describe what `--verify-wrap-parity` prints, where neither d=5 nor a scope word belongs.
# POPULATION printed and floored at 1.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:documentation/SPECIFICATION.md`) ->
# HIT :173, rc 1; live -> "**Within the canonical**, which odd value …" passes, rc 0; mutation (live
# with "Within the canonical, " removed) -> HIT rc 1.
gate_theorem_vs_slice() {
  echo "== GATE 68: SPECIFICATION.md's '(d=1 vs d=3)' wrap enumeration names d=5 or scopes itself to the slice =="
  local F=documentation/SPECIFICATION.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
t=io.open(F,encoding="utf-8").read()
n=0
for p in re.split(r"\n\s*\n",t):
    p=re.sub(r"\[CORRECTED\b.*?\]"," ",p,flags=re.S)
    flat=" ".join(p.replace("*","").split())
    for s in re.split(r"(?<=[.!?])\s+",flat):
        if not re.search(r"d ?= ?1 vs\.? d ?= ?3",s): continue
        n+=1
        if not re.search(r"d ?= ?5|within the canonical|as measured|\bslice\b|in the enumerated",s,re.I):
            print("HIT\t%s"%s[:140])
print("POP\t%d"%n)
PY
) || { echo "  [FAIL] GATE 68 scanner failed — NOTHING was checked."; return 1; }
  local pn
  pn=$(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 68 printed no population census."; return 1; fi
  if [ "$pn" -lt 1 ]; then echo "  [FAIL] GATE 68 found no '(d=1 vs d=3)' sentence in $F (floor 1) — the sentence moved; nothing judged."; return 1; fi
  local rc=0 tag s
  while IFS=$'\t' read -r tag s; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F: wrap distances enumerated as exhaustive without d=5 or a scope word: $s"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         The theorem permits d=5 (CIRCULAR_KING_WEN.md witness); say 'within the canonical' or name d=5."; return 1; fi
  echo "  [ok] GATE 68: $pn wrap-distance enumeration(s) in $F, each scoped or naming d=5"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 69 — a CITATIONS.md access-exclusion clause may not rest on a year inside the author's own
# life-range (`chronology-access`).
#
# QUEUED AS: Codex A-batch designated leg `chronology-access` (BATCH A07 row 13, CITATIONS.md:683-684):
# "reconstructed … in 1781, so he almost certainly could not have read it" — of Cui Shu (1740–1816):
# 1781 precedes his death by 35 years, so the date argues the other way.
# MECHANICS: CITATIONS.md is split into `- **Name** (YYYY–YYYY)` entries (the life-range in the entry's
# first line); within an entry, `[CORRECTED …]` spans stripped, every flattened sentence carrying an
# exclusion clause (`could not have read|almost certainly could not|no access to|had no access|could
# not have seen`) and a 4-digit year Y is a HIT when lo <= Y <= hi. POPULATION printed and floored at
# 3 entries with a life-range on the entry's first line (MEASURED 3 today: Jiao Xun, Wu Cheng, Cui Shu;
# the other life-ranges in the file are inline mentions, not entry heads); the number of exclusion
# clauses judged is printed (0 today: the live clause sits inside its CORRECTED span).
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:documentation/CITATIONS.md`) ->
# HIT Cui Shu / 1781 in 1740–1816, rc 1; live -> 0 clauses outside CORRECTED spans, rc 0; mutation
# (the pre-fix clause ", so he almost certainly could not have read it" re-planted after the live
# "1781.") -> HIT rc 1. NEEDLE NOTE: "in 1781" is hard-wrapped across two lines in the live file, so a
# single-line sed on it matched nothing the first time — verified against the flattened text.
gate_chronology_access() {
  echo "== GATE 69: a CITATIONS.md 'could not have read' clause does not rest on a year inside the author's life-range =="
  local F=documentation/CITATIONS.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, sys
F=sys.argv[1]
t=io.open(F,encoding="utf-8").read()
entries=re.split(r"(?m)^(?=- \*\*)",t)
ne=nc=0
for e in entries:
    head=e.split("\n",1)[0]
    m=re.search(r"\((\d{4})[–-](\d{4})\)",head)
    if not m: continue
    ne+=1; lo,hi=int(m.group(1)),int(m.group(2))
    name=re.sub(r"\*","",head)[2:40]
    body=re.sub(r"\[CORRECTED\b.*?\]"," ",e,flags=re.S)
    flat=" ".join(body.replace("*","").split())
    for s in re.split(r"(?<=[.!?])\s+",flat):
        if not re.search(r"could not have read|almost certainly could not|no access to|had no access|could not have seen",s,re.I): continue
        nc+=1
        for y in re.findall(r"\b(1[0-9]{3}|20[0-9]{2})\b",s):
            y=int(y)
            if lo<=y<=hi: print("HIT\t%s\tyear %d lies inside the life-range %d–%d, so it cannot exclude access: %s"%(name.strip(),y,lo,hi,s[:110]))
print("POP\t%d\t%d"%(ne,nc))
PY
) || { echo "  [FAIL] GATE 69 scanner failed — NOTHING was checked."; return 1; }
  local pe pc
  IFS=$'\t' read -r pe pc < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pe:-}"; then echo "  [FAIL] GATE 69 printed no population census."; return 1; fi
  if [ "$pe" -lt 3 ]; then echo "  [FAIL] GATE 69 found only $pe entries with a (YYYY–YYYY) life-range in $F (floor 3) — the entry shape moved; nothing judged."; return 1; fi
  local rc=0 tag who msg
  while IFS=$'\t' read -r tag who msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F [$who]: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         State the honest clause: 'access cannot be excluded on chronology; independence rests on the absence of any citation'."; return 1; fi
  echo "  [ok] GATE 69: $pe life-ranged entries in $F; $pc access-exclusion clause(s) judged, none resting on an in-range year"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 70 — TR-11's per-layer footprint table equals FULL31_EXACT_AGGREGATES.md's `layer GB` column
# at TR-11's own printed precision (`layer-profile`).
#
# QUEUED AS: Codex A-batch designated leg `layer-profile` (batch 4 row 2, TR11:218-232): the table
# carried ">2.45 TB" for k=15 (an in-RAM mid-layer allocation, not entries×28 B), "≈656 GB" derived for
# k=12 and "1.6 TB" for k=14, against completed telemetry of 2155.82 / 655.23 / 1698.15 GB.
# MECHANICS: TR-11's `| Layer k | Footprint | Provenance |` table rows `| k | X GB|TB … |`; FULL31's
# `| k | canonical_masks | C(31,k) | states | entries | V_k | layer GB | …` rows. X (bold, ≈, >, ~
# stripped; TB → GB ×1000) must equal FULL31's layer GB rounded to X's printed decimals; a parenthesised
# entry count in the TR-11 cell must equal FULL31's entries. POPULATION printed and floored at 5 rows.
# MEASURED BEFORE LANDING (2026-09-02): pre-fix (`git show 89e7a9a1:reports/TR11_…md`) -> HITs k=12
# (≈656 vs 655.23), k=14 (1.6 vs 1.698 TB), k=15 (>2.45 vs 2.156 TB), rc 1; live -> 10 rows agree,
# rc 0; mutation (live k=16 "2.341 TB" -> "2.451 TB") -> HIT rc 1.
gate_layer_profile() {
  echo "== GATE 70: TR-11's per-layer footprint table equals FULL31_EXACT_AGGREGATES.md's layer GB column =="
  local T=reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md A=reports/FULL31_EXACT_AGGREGATES.md out
  require_tracked "$T" || { [ $? -eq 2 ] && return 1; echo "  [skip] $T absent and untracked"; return 0; }
  require_tracked "$A" || { [ $? -eq 2 ] && return 1; echo "  [skip] $A absent and untracked"; return 0; }
  out=$(python3 - "$T" "$A" <<'PY'
import re, io, sys
T,A=sys.argv[1],sys.argv[2]
# SCOPE THE PARSE TO SECTION 1 (Q-265, 2026-09-04). The first cut matched ANY >=7-cell
# pipe row anywhere in A. That was safe only while section 2's rung table was five cells
# wide; the moment the n=16 column landed it became EIGHT cells, its k column collided
# with section 1's, and because section 2 comes later it OVERWROTE the real footprints --
# k=9 was read as "9.00 GB / 24,294,300,960 entries", i.e. the n=13 layer-9 MASS parsed
# as an entry count. Two [FAIL]s produced by a correct edit to a different table. The
# identical defect and the identical remedy are already recorded in verify.py's
# _published_rung_layers(), which scopes ITS parse to "## 2." for the mirror-image reason.
# A parser keyed on row SHAPE and not on SECTION is a latent false verdict in both
# directions; this one now fails loud when section 1 is absent rather than judging
# whatever else in the file happens to be eight cells wide.
agg={}; in_s1=False; saw_s1=False
for line in io.open(A,encoding="utf-8").read().split("\n"):
    if line.startswith("## "):
        in_s1=line.startswith("## 1."); saw_s1=saw_s1 or in_s1; continue
    if not in_s1: continue
    c=[x.strip() for x in line.strip().strip("|").split("|")]
    if len(c)>=7 and re.fullmatch(r"\d+",c[0]):
        try: agg[int(c[0])]=(float(c[6].replace(",","")),int(c[4].replace(",","")))
        except ValueError: pass
if not saw_s1: print("ERROR\t%s has no '## 1.' section -- the layer table could not be located, so NOTHING was judged"%A); sys.exit(0)
if len(agg)<20: print("ERROR\t%s section 1 has %d parseable '| k | … | entries | V_k | layer GB |' rows (need 20+)"%(A,len(agg))); sys.exit(0)
lines=io.open(T,encoding="utf-8").read().split("\n")
hi=None
for i,l in enumerate(lines):
    if re.match(r"^\s*\|\s*Layer k\s*\|\s*Footprint\s*\|",l): hi=i; break
if hi is None: print("ERROR\t%s has no '| Layer k | Footprint | … |' table"%T); sys.exit(0)
n=0; k=hi+1
while k<len(lines) and lines[k].strip().startswith("|"):
    c=[x.strip() for x in lines[k].strip().strip("|").split("|")]
    k+=1
    if len(c)<2 or not re.fullmatch(r"\d+",c[0]): continue
    layer=int(c[0]); cell=c[1].replace("**","")
    m=re.search(r"[≈>~]?\s*([\d.]+)\s*(GB|TB)\b",cell)
    if not m: continue
    n+=1
    if layer not in agg: print("HIT\tk=%d\tno such layer in %s"%(layer,A)); continue
    gb,ent=agg[layer]
    val=float(m.group(1)); unit=m.group(2); dec=len(m.group(1).split(".")[1]) if "." in m.group(1) else 0
    actual=gb/1000.0 if unit=="TB" else gb
    if round(actual,dec)!=val: print("HIT\tk=%d\tTR-11 says %s %s; %s layer GB = %.6f (%.*f %s)"%(layer,m.group(1),unit,A,gb,dec,actual,unit))
    me=re.search(r"\(([\d,]+) entries\)",cell)
    if me and int(me.group(1).replace(",",""))!=ent: print("HIT\tk=%d\tTR-11 says %s entries; %s says %d"%(layer,me.group(1),A,ent))
print("POP\t%d\t%d"%(n,len(agg)))
PY
) || { echo "  [FAIL] GATE 70 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 70 could not judge its subject: $err"; return 1; fi
  local pn pa
  IFS=$'\t' read -r pn pa < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pn:-}"; then echo "  [FAIL] GATE 70 printed no population census."; return 1; fi
  if [ "$pn" -lt 5 ]; then echo "  [FAIL] GATE 70 found only $pn footprint row(s) in $T (floor 5) — the table shrank; nothing judged."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $T ($where): $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         The table's unit is entries × 28 B + masks × 12 B; quote $A, never an in-RAM allocation or a derived value."; return 1; fi
  echo "  [ok] GATE 70: $pn footprint row(s) in $T agree with $A ($pa layers) at their printed precision"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 71 — a prose enumeration of the (Z/2)⁶ arrivals is the CITATIONS.md chain (`arrivals-sync`).
#
# QUEUED AS: prose batch P33 / Codex V2-F53 #5. Two sites in documentation/SYMMETRY_SEARCH.md
# enumerated the (Z/2)⁶ hexagram-algebra arrivals and BOTH had drifted from CITATIONS.md
# §"The (Z/2)⁶ hexagram algebra and hexagram-level group actions — priority ceded": Yuan Zuoxing
# (1991) and Cao Hongjun et al. (1995) joined the ledger's chain in the 2026-08-29 correction and
# reached neither prose site until P33 fixed them on 2026-09-02. A priority cession that a reader
# meets in the wrong place is a smaller cession than the one the ledger actually made.
# MECHANICS: the LEDGER set is read from CITATIONS.md, never from the checked text — the single
# paragraph of the priority-ceded section carrying "independent arrival" and "→ ROAE"; its `](#a)`
# anchors are folded to one key per person (trailing year stripped, so #ouyang1990 and #ouyang1992
# are one arrival), and each key's SURNAME comes from that anchor's own bibliography entry head.
# The judged population is every blank-line paragraph of every other tracked *.md that links >= 3
# distinct ledger keys as `CITATIONS.md#anchor` — i.e. that is already enumerating the chain. Such
# a paragraph must name EVERY ledger key, as a link OR as the bibliography surname in plain prose
# (accent-folded). The plain-prose arm is not a softening: SYMMETRY_SEARCH.md:485 names Goldenberg
# in running text and links the other six, and a link-only predicate would have failed correct
# published content — MEASURED, 1 false positive of 2 paragraphs.
# 🔴 VERIFIER-CLOSURE / NEEDLE-REACHABILITY GUARD: the >= 3 trigger is read off the checked
# paragraph, so deleting arrival links would make a drifted paragraph LEAVE the population instead
# of failing. That is why POP is printed and FLOORED AT 2 paragraphs (exactly 2 today) and the
# ledger at 5 arrivals — a site dropping out of the census fails the gate rather than passing it.
# MEASURED BEFORE LANDING (2026-09-03): pre-P33 tree (`git show c67737d2^` of CITATIONS.md +
# SYMMETRY_SEARCH.md, staged in a scratch repo so `git ls-files` sees them) -> 2 HITs,
# SYMMETRY_SEARCH.md:28 and :309, each "enumerates 5 of the ledger's 7 arrivals but never names
# Cao (#caohongjun1995); Yuan (#yuanzuoxing1991)", rc 1. Live tree -> LEDGER 7
# (caohongjun/goldenberg/ouyang/radisic/schoter/suenaga/yuanzuoxing), POP 2, rc 0.
gate_arrivals_sync() {
  echo "== GATE 71: a prose enumeration of the (Z/2)⁶ arrivals names every arrival CITATIONS.md's chain names =="
  local C=documentation/CITATIONS.md out
  require_tracked "$C" || { [ $? -eq 2 ] && return 1; echo "  [skip] $C absent and untracked"; return 0; }
  out=$(python3 - "$C" <<'PY'
import re, io, sys, subprocess, unicodedata
C=sys.argv[1]
def deacc(s): return "".join(c for c in unicodedata.normalize("NFKD",s) if not unicodedata.combining(c))
try: t=io.open(C,encoding="utf-8").read()
except Exception as e: print("ERROR\tcannot read %s: %s"%(C,e)); sys.exit(0)
L=t.split("\n")
hs=[i for i,l in enumerate(L) if l.startswith("## ") and "hexagram algebra" in l and "priority ceded" in l]
if len(hs)!=1: print("ERROR\t%s has %d '## ... hexagram algebra ... priority ceded' heading(s), expected 1"%(C,len(hs))); sys.exit(0)
s=hs[0]; e=next((i for i in range(s+1,len(L)) if L[i].startswith("## ")), len(L))
paras=re.split(r"\n\s*\n","\n".join(L[s:e]))
chain=[p for p in paras if "independent arrival" in p and "→ ROAE" in p]
if len(chain)!=1: print("ERROR\tthe priority-ceded section holds %d chain paragraph(s) ('independent arrival' + an arrow to ROAE), expected 1"%len(chain)); sys.exit(0)
anchors=sorted(set(re.findall(r"\]\(#([a-z0-9]+)\)",chain[0])))
keys={}
for a in anchors: keys.setdefault(re.sub(r"\d{4}$","",a),set()).add(a)
if len(keys)<5: print("ERROR\tthe chain paragraph names only %d distinct cited arrival(s) (floor 5)"%len(keys)); sys.exit(0)
sur={}
for k in keys:
    got=None
    for a in sorted(keys[k]):
        m=re.search(r'<a id="%s"></a>\n(.*?)(?:\n|$)'%re.escape(a),t)
        if not m: continue
        head=re.sub(r"^(?:##\s+|-\s+)","",m.group(1)).replace("*","").strip()
        w=re.match(r"([A-Za-zÀ-ɏ]+)",head)
        if w: got=w.group(1); break
    if not got: print("ERROR\tno bibliography entry head yields a surname for chain member '%s' (%s)"%(k,",".join(sorted(keys[k])))); sys.exit(0)
    sur[k]=got
print("LEDGER\t%s"%(" ".join("%s=%s"%(k,sur[k]) for k in sorted(sur))))
files=subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True).stdout.split()
npara=0
for f in files:
    if f==C: continue
    try: d=io.open(f,encoding="utf-8",errors="replace").read()
    except Exception: continue
    if "CITATIONS.md#" not in d: continue
    off=0
    for p in re.split(r"(\n\s*\n)",d):
        if re.fullmatch(r"\n\s*\n",p): off+=p.count("\n"); continue
        linked={re.sub(r"\d{4}$","",a) for a in re.findall(r"CITATIONS\.md#([a-z0-9]+)\)",p)} & set(sur)
        if len(linked)>=3:
            npara+=1; ln=off+1
            flat=deacc(" ".join(p.split()))
            miss=[]
            for k in sorted(sur):
                if k in linked: continue
                if re.search(r"(?<![A-Za-z])%s(?![a-z])"%re.escape(deacc(sur[k])),flat): continue
                miss.append("%s (#%s)"%(sur[k],sorted(keys[k])[0]))
            if miss: print("HIT\t%s:%d\tenumerates %d of the ledger's %d arrivals but never names %s"%(f,ln,len(sur)-len(miss),len(sur),"; ".join(miss)))
        off+=p.count("\n")
print("POP\t%d\t%d"%(npara,len(sur)))
PY
) || { echo "  [FAIL] GATE 71 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 71 could not judge its subject: $err"; return 1; fi
  local pp pl
  IFS=$'\t' read -r pp pl < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pp:-}"; then echo "  [FAIL] GATE 71 printed no population census."; return 1; fi
  if [ "$pp" -lt 2 ]; then echo "  [FAIL] GATE 71 found only $pp paragraph(s) enumerating the arrivals chain (floor 2) — a site left the census instead of failing; nothing judged."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $where: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         $C §'The (Z/2)⁶ hexagram algebra ... — priority ceded' is the list of record; re-sync the prose to its chain."; return 1; fi
  echo "  [ok] GATE 71: $pp paragraph(s) enumerating the arrivals chain name all $pl of $C's arrivals"
  printf '  '; printf '%s\n' "$out" | awk -F'\t' '$1=="LEDGER"{print "ledger chain: "$2}'
  return 0
}


# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 72 — every CLAIMS_DECIDED row's linked report names a reproduction command
# (`scorecard-repro`).
#
# QUEUED AS: P12's sheet, "GATE-25 extension: every CLAIMS_DECIDED row's linked report resolves to
# a command whose inputs are classified in-tree / archived-external (declared) / ABSENT — ABSENT
# fails." SHIPPED IS THE FIRST HALF ONLY, and the second half is declined here with its
# measurement rather than left implied:
#   * "inputs classified" HAS NO DECLARATION CONVENTION TO READ. `archived-external` and
#     `archived external` have ZERO occurrences anywhere in the corpus or in scripts/, so the
#     middle class of the prescribed trichotomy is unrepresentable today.
#   * MEASURED, the naive form is 7/19 FALSE: taking every path-shaped token after a tool command
#     in a row's linked report and requiring it to exist flags 7 of the 19 rows, and every hit is
#     an OUTPUT PLACEHOLDER, not an input — `f.cnf`/`f.drat` (`python3 sat.py --emit-cnf <name>
#     f.cnf && kissat f.cnf`: the file is created by the left half and consumed by the right),
#     `NEW.bin`/`OLD.bin`, `analyze_output.log`, `shard_manifest_phaseA.txt`.
#   * THE PROPERTY IS ALREADY INSTRUMENTED, corpus-wide and at 29x this coverage:
#     `scripts/exec_lane.sh` classifies missing inputs as `SKIP-MISSING-INPUT` over all 544 RUN
#     commands (85 such on the 2026-09-02 full-lane run), not over 19 rows.
# WHAT THIS LEG DOES ENFORCE is the page's own stated promise, which nothing checked: CLAIMS_DECIDED
# opens "Every row carries a link in its last column, and the reproduction command for that row
# lives in the linked report — not here." GATE 25 LEG 2's standing observation is that this page
# publishes figures and names no command of its own; that is only acceptable while the delegation
# holds. A row whose linked report names NO command has silently withdrawn the promise, and GATE 1
# (anchors resolve) and GATE 4 (links resolve) both stay green through it.
# 🔴 VERIFIER-CLOSURE GUARD: a row with no link at all must FAIL, never vanish — the row census is
# taken from the table's own rows, the link census from the last cell, and both are printed and
# floored (15 rows; every row must yield >= 1 resolvable .md target). Deleting a link makes the row
# fail on "names no linked report", it does not remove it from the population.
# MEASURED BEFORE LANDING (2026-09-03): live -> 19 rows, 26 distinct link targets, all resolve,
# 19/19 carry >= 1 tool command in a linked report; rc 0. Red-tested on a scratch tree by planting
# a row linking only to a command-free doc (HIT), by emptying a row's Proof cell (HIT), and by
# deleting the table (POP floor HIT).
gate_scorecard_repro() {
  echo "== GATE 72: every CLAIMS_DECIDED row's linked report names a reproduction command =="
  local F=documentation/CLAIMS_DECIDED.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, os, sys
F=sys.argv[1]
D=os.path.dirname(F)
CMD=re.compile(r"(?:python3?\s+)?(?:\./)?(?:verify\.py|solve\.py|sat\.py|roae\.py|solve|verify)\s+--[a-z0-9][a-z0-9-]*")
try: t=io.open(F,encoding="utf-8").read()
except Exception as e: print("ERROR\tcannot read %s: %s"%(F,e)); sys.exit(0)
rows=[l for l in t.split("\n")
      if l.startswith("|") and not re.match(r"^\|[-\s|:]+\|$",l) and not l.startswith("| Claim ")]
nrow=len(rows); ntgt=set(); cache={}
for r in rows:
    cells=[c.strip() for c in re.split(r"(?<!\\)\|", r.strip("|"))]  # Q-525: a \| in the Claim cell is not a cell break
    claim=re.sub(r"\s+"," ",re.sub(r"[*`]","",cells[0]))[:62]
    if len(cells)<2:
        print("HIT\t%s\tmalformed row: %d cell(s), expected the 5-column scorecard shape"%(claim,len(cells))); continue
    proof=cells[-1]
    links=re.findall(r"\]\(([^)#]+\.md)",proof)
    if not links:
        print("HIT\t%s\tthe Proof cell names no linked report, but this page delegates every reproduction command to one"%claim); continue
    ok=False; gone=[]
    for l in links:
        p=os.path.normpath(os.path.join(D,l)); ntgt.add(p)
        if not os.path.exists(p): gone.append(l); continue
        if p not in cache:
            try: cache[p]=len(CMD.findall(io.open(p,encoding="utf-8",errors="replace").read()))
            except Exception: cache[p]=0
        if cache[p]: ok=True
    if gone: print("HIT\t%s\tProof link(s) do not resolve: %s"%(claim,", ".join(gone))); continue
    if not ok:
        print("HIT\t%s\tnone of its linked report(s) (%s) names a solve/verify/sat/roae command, so the row's reproduction path ends nowhere"%(claim,", ".join(links)))
print("POP\t%d\t%d"%(nrow,len(ntgt)))
PY
) || { echo "  [FAIL] GATE 72 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 72 could not judge its subject: $err"; return 1; fi
  local pr pt
  IFS=$'\t' read -r pr pt < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pr:-}"; then echo "  [FAIL] GATE 72 printed no population census."; return 1; fi
  if [ "$pr" -lt 15 ]; then echo "  [FAIL] GATE 72 found only $pr scorecard row(s) in $F (floor 15) — the table shape moved; nothing judged."; return 1; fi
  local rc=0 tag who msg
  while IFS=$'\t' read -r tag who msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F [$who]: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         $F states 'the reproduction command for that row lives in the linked report'; either point the row at the report that carries the command, or add the command there."; return 1; fi
  echo "  [ok] GATE 72: $pr scorecard row(s), $pt linked report target(s), every row reaching at least one that names a command"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 73 — a CLAIMS_DECIDED Source cell may not attribute more than its own linked report
# (`scorecard-attribution`).
#
# QUEUED AS: P12's sheet, "source-column-attribution cross-doc leg (a scorecard attribution may not
# exceed the linked report's attribution sentence)". The scorecard adjudicates and delegates its
# evidence; an attribution that appears only on the scorecard is a credit no report backs, and the
# reader who follows the link to check it finds nothing to check.
# TWO LEGS, both pure CONTAINMENT (scorecard ⊆ report), so neither can be satisfied by the
# scorecard's own text — the witness always comes from the linked file:
#   LEG 1 — every `CITATIONS.md#anchor` cited in a row's Source cell must be cited by at least one
#     of that row's linked reports (as `CITATIONS.md#anchor` or, inside CITATIONS.md itself, `(#a)`).
#   LEG 2 — every page number a Source cell cites (`p.257 n2`, `pp. 113–114`) must appear inside a
#     page reference in a linked report. Comma-separated groups are expanded on BOTH sides: the
#     first cut compared `p.257` against TR-10's `pp. 251–255, 257 n2` and reported a FALSE HIT
#     because it stopped the group at the first range — measured and fixed before landing.
# NOT BUILT, with the measurement: a NAME+YEAR leg ("Davis 2012" in the Source must be co-located
# in the report). It returns 2 hits of 12 and BOTH are false. (i) "Li Shangxin 2007" — the Source
# cell and TR-4 both delegate to the SAME `CITATIONS.md#uniqueness-conjecture` attribution note,
# which TR-4 links four times; the report is not under-attributing, it is pointing at the shared
# record. (ii) "publication 2026" is not a name at all — the regex ate "earlier ROAE publication
# (2026-06-11)". The semantic half of the charge ("may not exceed the attribution SENTENCE") is
# left to review: 11 of the 19 rows carry a plain-prose Source ("Davis 2012, p.114", "earlier ROAE
# publication") with nothing an exceeds-relation can be computed against.
# POPULATION printed and floored: >= 6 anchor citations and >= 6 page numbers judged, else the
# gate FAILS rather than passing on an empty census — a Source cell stripped of its anchors must
# not be able to leave the population (needle-reachability mechanism 7).
# MEASURED BEFORE LANDING (2026-09-03): live -> 8 anchor citations across 8 anchored Source cells,
# 8 page numbers, 0 hits, rc 0. Red-tested by planting an unbacked anchor, an unbacked page, and by
# stripping the anchors to trip the floor.
gate_scorecard_attribution() {
  echo "== GATE 73: a CLAIMS_DECIDED Source cell attributes no more than its linked report does =="
  local F=documentation/CLAIMS_DECIDED.md out
  require_tracked "$F" || { [ $? -eq 2 ] && return 1; echo "  [skip] $F absent and untracked"; return 0; }
  out=$(python3 - "$F" <<'PY'
import re, io, os, sys
F=sys.argv[1]; D=os.path.dirname(F)
GRP=re.compile(r"pp?\.\s?((?:[0-9]{1,4}(?:\s?[–-]\s?[0-9]{1,4})?)(?:\s?,\s?(?:n?[0-9]{1,4}(?:\s?[–-]\s?[0-9]{1,4})?))*)")
def pages(s):
    out=set()
    for m in GRP.finditer(s):
        for part in m.group(1).split(","):
            mm=re.match(r"([0-9]{1,4})(?:\s?[–-]\s?([0-9]{1,4}))?$",part.strip().lstrip("n"))
            if not mm: continue
            a=int(mm.group(1)); b=int(mm.group(2)) if mm.group(2) else a
            if a<=b<=a+200: out|=set(range(a,b+1))
    return out
try: t=io.open(F,encoding="utf-8").read()
except Exception as e: print("ERROR\tcannot read %s: %s"%(F,e)); sys.exit(0)
rows=[l for l in t.split("\n")
      if l.startswith("|") and not re.match(r"^\|[-\s|:]+\|$",l) and not l.startswith("| Claim ")]
if not rows: print("ERROR\tno scorecard table rows found in %s"%F); sys.exit(0)
na=npg=0; cache={}
for r in rows:
    c=[x.strip() for x in re.split(r"(?<!\\)\|", r.strip("|"))]  # Q-525: escape-aware, as GATE 72
    if len(c)<3: continue
    claim=re.sub(r"\s+"," ",re.sub(r"[*`]","",c[0]))[:56]
    src=c[1]; body=""; tgt=[]
    for l in re.findall(r"\]\(([^)#]+\.md)",c[-1]):
        p=os.path.normpath(os.path.join(D,l))
        if not os.path.exists(p): continue
        if p not in cache:
            try: cache[p]=io.open(p,encoding="utf-8",errors="replace").read()
            except Exception: cache[p]=""
        body+=cache[p]; tgt.append(l)
    if not tgt: continue
    seen=set(re.findall(r"CITATIONS\.md#([a-z0-9-]+)",body))|set(re.findall(r"\]\(#([a-z0-9-]+)\)",body))
    for a in sorted(set(re.findall(r"CITATIONS\.md#([a-z0-9-]+)",src))):
        na+=1
        if a not in seen:
            print("HIT\t%s\tSource credits CITATIONS.md#%s, which none of its linked report(s) (%s) cites"%(claim,a,", ".join(tgt)))
    rp=pages(body)
    for x in sorted(pages(src)):
        npg+=1
        if x not in rp:
            print("HIT\t%s\tSource cites p.%d, which none of its linked report(s) (%s) references"%(claim,x,", ".join(tgt)))
print("POP\t%d\t%d\t%d"%(len(rows),na,npg))
PY
) || { echo "  [FAIL] GATE 73 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 73 could not judge its subject: $err"; return 1; fi
  local pr pa pg
  IFS=$'\t' read -r pr pa pg < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pa:-}"; then echo "  [FAIL] GATE 73 printed no population census."; return 1; fi
  if [ "$pa" -lt 6 ]; then echo "  [FAIL] GATE 73 judged only $pa anchored Source citation(s) in $F (floor 6) — the Source column stopped citing the ledger; nothing to contain."; return 1; fi
  if [ "$pg" -lt 6 ]; then echo "  [FAIL] GATE 73 judged only $pg page citation(s) in $F (floor 6) — the page-reference idiom moved; LEG 2 checked nothing."; return 1; fi
  local rc=0 tag who msg
  while IFS=$'\t' read -r tag who msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $F [$who]: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         The scorecard adjudicates and the report carries the evidence; move the credit into the report, or drop it from the Source cell."; return 1; fi
  echo "  [ok] GATE 73: $pr row(s); $pa anchored Source citation(s) and $pg page citation(s), all backed by a linked report"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 74 — a report whose body scopes a result "not decided above" repeats that scope in its
# executive summary (`summary-scope`).
#
# QUEUED AS: the GATE 12-class summary/scope coupling leg (Codex V2-F07 #1, prose batch P38).
# TR-5's body stated the scope correctly at three sites — "the solution-set automorphism group is
# bounded below by G and not decided above" — and the EXECUTIVE SUMMARY dropped it at two, opening
# with an unqualified completeness claim over "such [relabeling] symmetries (a group of 48)",
# solution-set-automorphism reading, which is exactly what §1 leaves open. A reader who reads only
# the summary — which is what an executive summary is for — got the stronger claim.
# 🔴 THE PREDICATE HAS TO BE PER-SENTENCE, AND THAT WAS MEASURED, NOT ASSUMED. A document-level
# "does the summary contain 'relabeling'" test does NOT fire on the defect: the pre-fix summary
# already used the word in its opening clause ("relabeling every hexagram by the same
# line-permutation"), three lines above the unqualified completeness claim. The qualifier has to
# sit in the CLAIM's own sentence.
# MECHANICS: population = every `reports/TR*.md` whose text OUTSIDE the `## Executive summary`
# section carries "not decided above". Inside that section, a flattened sentence is judged when it
# is (a) a COMPLETENESS claim — `complete*` together with `symmetr*` / `automorphism` / "group of
# 48" — or (b) a TWIN-INDISTINGUISHABILITY claim — `twin` together with `indistinguishable` /
# "cannot tell" / "cannot distinguish" / "no … distinguish". Such a sentence must contain
# `relabel`. Both censuses are printed and floored at 1, so a report that stops stating the scope
# in its body, or a summary that stops making the claim, FAILS instead of leaving the population.
# MEASURED BEFORE LANDING (2026-09-03): live -> 1 report in population (TR-5; it is the only
# `reports/TR*.md` carrying the phrase), 3 claim sentences judged, 0 hits, rc 0. Pre-fix
# (`git show 53760aa2^:reports/TR5_SYMMETRY.md`) -> HIT on that report's opening summary sentence,
# rc 1. (The pre-fix wording is NOT quoted here: it is a registered retracted phrase, and GATE 47
# reads this file. It is on the record at documentation/RETRACTED_PHRASES.tsv:201.) Mutations: the `## Executive summary` heading
# renamed -> the SPECIFIC hit ("no '## Executive summary' section to repeat it in"), which is why
# a summary-less report is counted INTO the population rather than dropped — otherwise the
# population floor fires first and masks the finding; every `relabel` stripped from the summary
# -> both legs hit (twin-indistinguishability and completeness); the body's scope phrase reworded
# -> population floor hit. Also verified as a correct NON-firing: deleting only the first of the
# summary's two qualifiers leaves the claim sentence still carrying one, and the gate stays green
# because the sentence is still scoped — the per-sentence rule, working as specified.
gate_summary_scope() {
  echo "== GATE 74: a body scoped 'not decided above' is repeated in the report's executive summary =="
  local out
  out=$(python3 - <<'PY'
import re, io, glob
SCOPE=re.compile(r"not decided above",re.I)
COMPLETE=re.compile(r"\bcomplete\w*\b",re.I)
GROUP=re.compile(r"\bsymmetr\w+|\bautomorphism\b|group of 48",re.I)
TWIN=re.compile(r"\btwins?\b",re.I)
INDIST=re.compile(r"indistinguishable|cannot tell|can(?:not|'t) distinguish|no[^.]{0,60}distinguish",re.I)
QUAL=re.compile(r"relabel",re.I)
docs=sorted(glob.glob("reports/TR*.md"))
if not docs: print("ERROR\tzero reports/TR*.md found — vacuous, treated as failure."); raise SystemExit
npop=nsumm=nclaim=0
for f in docs:
    try: t=io.open(f,encoding="utf-8",errors="replace").read()
    except Exception: continue
    L=t.split("\n")
    hs=[i for i,l in enumerate(L) if re.match(r"^##\s+Executive summary",l,re.I)]
    if not hs:
        # In population, and a HIT: the scope has nowhere to be repeated. Counted into npop so the
        # population floor does not fire FIRST and mask the more specific finding.
        if SCOPE.search(t):
            npop+=1
            print("HIT\t%s\tits body states a 'not decided above' scope but the report has no '## Executive summary' section to repeat it in"%f)
        continue
    s=hs[0]; e=next((i for i in range(s+1,len(L)) if L[i].startswith("## ")),len(L))
    summ="\n".join(L[s+1:e]); body="\n".join(L[:s]+L[e:])
    if not SCOPE.search(body): continue
    npop+=1; nsumm+=1
    flat=" ".join(re.sub(r"[*`]","",summ).split())
    for sent in re.split(r"(?<=[.!?])\s+",flat):
        comp = bool(COMPLETE.search(sent) and GROUP.search(sent))
        twin = bool(TWIN.search(sent) and INDIST.search(sent))
        if not (comp or twin): continue
        nclaim+=1
        if not QUAL.search(sent):
            print("HIT\t%s\tthe executive summary's %s claim carries no 'relabeling' qualifier, but the body scopes it 'not decided above': %s"
                  %(f,"completeness" if comp else "twin-indistinguishability",sent[:160]))
print("POP\t%d\t%d\t%d"%(npop,nsumm,nclaim))
PY
) || { echo "  [FAIL] GATE 74 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 74 could not judge its subject: $err"; return 1; fi
  local pp ps pc
  IFS=$'\t' read -r pp ps pc < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pp:-}"; then echo "  [FAIL] GATE 74 printed no population census."; return 1; fi
  if [ "$pp" -lt 1 ]; then echo "  [FAIL] GATE 74 found no reports/TR*.md whose body states a 'not decided above' scope (floor 1) — the scope note left the corpus; nothing judged."; return 1; fi
  if [ "$ps" -ge 1 ] && [ "$pc" -lt 1 ]; then echo "  [FAIL] GATE 74 judged 0 summary claim sentence(s) across $ps summarised report(s) (floor 1) — the executive summary stopped making the claim this leg scopes; nothing judged."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $where: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         The completeness result is per-predicate over hexagram RELABELINGS; say so in the sentence that makes the claim, not three lines above it."; return 1; fi
  echo "  [ok] GATE 74: $pp report(s) scoped 'not decided above' in body ($ps with an executive summary); $pc summary claim sentence(s), all carrying the relabeling qualifier"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 75 — a mandatoriness claim over boundary SETS must be scoped to the subset size that was
# actually exhausted (`boundary-scope`).
#
# QUEUED AS: Codex A01 row 32 (PROJECT_OVERVIEW.md:96/:105) and A05 row 7
# (PARTITION_STABILITY_BOUNDARIES.md:62). Both rows accepted the same charge, at different
# sites, six weeks apart — A05:7's own adjudication opens by noting `PRIOR_ART=HIT n=42` on
# `C(31,5)` and that "this project has already ruled on the identical defect once, at different
# sites, and not fixed it". A05:7 then prescribed exactly this gate: *"`scripts/doc_gates.sh`
# fails when 'mandatory' or 'no combination' appears within N lines of a boundary-set claim whose
# document does not also state the exhausted subset size."*
#
# ITEM 2474 CLASSIFIED THIS ROW AS "only running C(31,5)=169,911 decides it", AND THAT IS THE
# RESIDUAL, NOT THE GATE. A05:7's remediation column reads "**Zero compute**" and records the
# 169,911-subset enumeration as "**the reviewer's text, not a proposal**". What the run would
# decide is the SCIENCE — whether some 5-set lacking 25 or 27 identifies KW. What this gate
# decides is whether the PROSE claims more than the search performed. Those are different
# questions and only the second one needed a gate; the row was buildable all along.
#
# THE SUBSTANCE. §[7] and §[8] exhaust all C(31,3) = 4,495 triples and all C(31,4) = 31,465
# quadruples, and at 100T/560T §[8] = 0, so the minimum is 5 and §[6] returns ONE deterministic
# tie-broken greedy 5-set. The C(31,5) = 169,911 five-subsets were never enumerated. So the
# evidence supports "{25,27} are in the greedy representative" and not "mandatory, full stop".
#
# DEPTH IS NOT A SCOPE FOR THIS CLAIM, and getting that wrong cost this leg its first two
# drafts. A scope vocabulary that accepted "at both d2 and d3", "across all four partitions
# tested" or "partition depths" scored the real pre-fix tree 13 population / 13 scoped / 0 fires
# — because every defective site was depth-qualified and that is precisely the conflation the
# charge is about. Exhausting C(31,4) at four depths says nothing whatever about the five-subsets.
# The accepted scope tokens are therefore about the SEARCH: greedy / C(31,3) / C(31,4) /
# "working 4" / 4-boundary / 4-set / "at their respective subset sizes" / an explicit C(31,5)
# disclaimer. Nothing about depth.
#
# NOT SELF-WITNESSING (needle-reachability mechanism 7). The needle is the CLAIM and the witness
# is a SCOPE TOKEN elsewhere in the window — two different strings. Perturbing the scope token
# does not make the claim vanish, it makes the claim unscoped, which is the failure. Perturbing
# the claim removes it from the population, and the FLOOR below is what refuses that: if the
# population drops under 10 the gate ERRORS rather than reporting a clean corpus.
#
# WINDOW = THE MARKDOWN UNIT the claim sits in (its list item, table row, heading or paragraph,
# following hard wraps to the end of that unit). Not the whole document, and that is a measured
# choice: PARTITION_STABILITY_BOUNDARIES.md:5 is literally a paragraph headed "Scope of that
# claim, stated once for this document", so a document-wide rule would clear every site in that
# file on one sentence. Not the single line either — hard wraps split these sentences routinely.
# AND NOT +/- N RAW LINES, which is what the first cut used and what MUT A caught: stripping
# "greedy" from documentation/README.md:50 did NOT fire, because :51 is a DIFFERENT document's
# index entry (BOUNDARY_MINIMUM.md's) and it carries "greedy minimum 4 -> 5". One index entry was
# scoping its neighbour. That is a false NEGATIVE, so it is invisible on a green run — the only
# reason it surfaced is that the mutation was run and its result read rather than assumed.
#
# MEASURED. Live: 14 claim sites, 14 scoped, 0 fires, rc 0. REAL PRE-FIX TREE
# `793210b7^` (the commit before "Prose sweep 2026-09-01: 23 batches, 37 files") with
# PROJECT_OVERVIEW.md / PARTITION_STABILITY_BOUNDARIES.md / BOUNDARY_MINIMUM.md restored:
# 12 sites, 11 scoped, **1 FIRE at documentation/PROJECT_OVERVIEW.md:96** — the exact A01 row 32
# site, "eliminate non-KW solutions that no combination of other boundaries can reach", rc 1.
# NOTE `git log -S` DOES NOT FIND THAT COMMIT: the fix moved the phrase from :96 into the
# revision narration at :211, so the occurrence COUNT never changed and the pickaxe reports only
# a 2026-07-03 commit. `-G` finds it. Recorded because the wrong tool here reads as "no fix ever
# landed" rather than "the count did not move".
#
# WHAT IS AND IS NOT RED-TESTED, stated rather than blurred: LEG 1 (`no combination`) has a
# demonstrated true positive on a real pre-fix tree. LEG 2 (quantified mandatoriness) does NOT —
# its pre-fix sites at PARTITION_STABILITY_BOUNDARIES.md and BOUNDARY_MINIMUM.md already carried
# "greedy" as far back as `bbf5348e` (2026-06-11), so no reachable tree fires it. It is proven by
# MUTATION only (strip the scope token from a live claim -> fires), which is strictly weaker.
gate_boundary_scope() {
  echo "== GATE 75: a mandatoriness claim over boundary sets is scoped to the subset size exhausted =="
  local out err pop nsc
  out=$(python3 - <<'PY'
import subprocess, sys
mds = subprocess.run(['git','ls-files','*.md'], capture_output=True, text=True).stdout.split()
if not mds:
    print('ERR\tgit ls-files returned no markdown at all'); sys.exit(0)
# Correction narration DOCUMENTS the defect and must not be judged as committing it — the GATE 47
# counting trap, and the reason CORRECTIONS.md and HISTORY.md are whole-file exclusions here.
SKIP = ('documentation/CORRECTIONS.md', 'documentation/HISTORY.md')
SCOPE = ('greedy', 'c(31,3)', 'c(31,4)', 'working 4', '4-boundary', '4 boundary', '4-set',
         'four-set', 'at their respective subset sizes', 'c(31,5)', 'five-subsets were never')
def starts_unit(l):
    # A line that OPENS a new markdown unit: list item, heading, table row, blockquote, or blank.
    t = l.lstrip()
    if not t: return True
    if t[0] in '#|>': return True
    if t[:2] in ('- ', '* ', '+ '): return True
    k = 0
    while k < len(t) and t[k].isdigit(): k += 1
    if k and k < len(t) and t[k] in '.)' and t[k+1:k+2] == ' ': return True
    return False
def unit(lines, idx):
    # THE WINDOW IS THE MARKDOWN UNIT, NOT +/- N RAW LINES, and this was forced by a measurement.
    # The first cut used lines[i-3:i+2]; MUT A (strip 'greedy' from documentation/README.md:50)
    # did NOT fire, because :50 is a DIFFERENT document's index entry — the BOUNDARY_MINIMUM.md
    # summary — and it happens to contain 'greedy minimum 4 -> 5'. One index entry was scoping
    # its neighbour. A raw-line window in any list, index or table leaks the neighbour's text,
    # which is a false NEGATIVE and so is invisible on a green run.
    a = idx
    while a > 0 and not starts_unit(lines[a]): a -= 1
    b = idx
    while b + 1 < len(lines) and not starts_unit(lines[b+1]): b += 1
    return ' '.join(lines[a:b+1])
QUANT = ('in every', 'in all', 'in any', 'every working', 'every minimum', 'all working',
         'every greedy', 'no matter how')
pop = 0; nsc = 0
for m in mds:
    if m in SKIP: continue
    try:
        lines = open(m, encoding='utf-8').read().split('\n')
    except OSError as e:
        print('ERR\t%s could not be read: %s' % (m, e)); sys.exit(0)
    for i, l in enumerate(lines, 1):
        low = l.lower()
        if 'no combination of other boundaries' in low:
            kind = 'no-combination'
        elif 'mandator' in low and any(q in low for q in QUANT):
            kind = 'quantified-mandatory'
        else:
            continue
        pop += 1
        para = unit(lines, i-1).lower()
        if any(t in para for t in SCOPE):
            nsc += 1
        else:
            print('HIT\t%s:%d\t%s\t%s' % (m, i, kind, l.strip()[:150]))
print('POP\t%d\t%d' % (pop, nsc))
PY
) || { echo "  [FAIL] GATE 75 scanner failed — NOTHING was checked."; return 1; }
  err=$(printf '%s\n' "$out" | sed -n 's/^ERR\t//p')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 75 could not judge its subject: $err"; return 1; fi
  pop=$(printf '%s\n' "$out" | sed -n 's/^POP\t\([0-9]*\)\t.*/\1/p')
  nsc=$(printf '%s\n' "$out" | sed -n 's/^POP\t[0-9]*\t\([0-9]*\)/\1/p')
  # A gate that scanned nothing must say so LOUDLY, never report a clean corpus (the fail-open
  # class). Both the census line and the floor are checked before any verdict is printed.
  if ! grep -qxE '[0-9]+' <<<"${pop:-}"; then
    echo "  [FAIL] GATE 75 printed no population census, so 'no findings' would be a lie."; return 1
  fi
  if [ "$pop" -lt 10 ]; then
    echo "  [FAIL] GATE 75 judged only $pop boundary-mandatoriness claim(s) (floor 10, measured 14)."
    echo "         Either the claim left the corpus — in which case this gate has nothing to say and"
    echo "         must not say it is clean — or the population grammar stopped matching text that is"
    echo "         still there. Re-measure before lowering this floor."
    return 1
  fi
  local rc=0 line
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    case "$line" in HIT*) ;; *) continue ;; esac
    echo "  [FAIL] $(printf '%s' "$line" | cut -f2) — a boundary-set mandatoriness claim with no subset-size scope"
    echo "         KIND: $(printf '%s' "$line" | cut -f3)"
    echo "         LINE: $(printf '%s' "$line" | cut -f4)"
    rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then
    echo "         §[7]/§[8] exhaust all C(31,3) = 4,495 triples and all C(31,4) = 31,465 quadruples."
    echo "         The C(31,5) = 169,911 five-subsets were NEVER enumerated, so a claim quantified over"
    echo "         boundary SETS must name the search: 'in every greedy-ordered minimum', 'in every"
    echo "         working 4-set', or an explicit C(31,5) disclaimer. Depth is not a scope for this"
    echo "         claim — exhausting C(31,4) at four depths says nothing about the five-subsets."
    return 1
  fi
  echo "  [ok] GATE 75: $pop boundary-set mandatoriness claim(s), all $nsc scoped to the subset size searched"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 76 — prose may not DENY a merge capability the binary's env surface provides
# (`merge-semantics`).
#
# QUEUED AS: Codex A01 row 20, whose adjudication ends by naming this gap in its own words:
# *"a NEW wrong paraphrase of merge semantics is not a registrable string; reaching that needs a
# GATE 2 (cli) env-surface leg (`SOLVE_MERGE_MODE`/`SOLVE_MERGE_CHUNK_GB` documented in
# SOLVE_C_CLI.md ⇒ prose may not deny external sort), which does not exist yet and is the honest
# gap here."* `grep -c` over doc_gates.sh for `SOLVE_MERGE_MODE`: 0. It did not exist.
#
# WHY GATE 3 IS NOT ENOUGH, which is the whole reason this row was flagged as needing machinery
# beyond a regex. GATE 3 registers the three refuted SPELLINGS in RETRACTED_PHRASES.tsv, so those
# exact sentences cannot come back. It cannot refuse a sentence nobody has written yet. The
# durable fact is not a string: it is that `solve.c` HAS the capability, and the evidence for
# that is its ENV SURFACE. So this leg derives the capability from the binary's source and then
# refuses prose that contradicts it — the needle is the DENIAL and the witness is `solve.c`.
#
# FALSE WHEN THE TARGET IS ABSENT, deliberately and in the loud direction. If SOLVE_MERGE_MODE or
# SOLVE_MERGE_CHUNK_GB leaves solve.c, this gate ERRORS. It does NOT pass. Two things could be
# true at that point and the gate can distinguish neither: the capability was removed (in which
# case the "denials" become TRUE and this leg must be retired, not satisfied), or the scan broke.
# Either way a clean verdict would be a lie, which is the fail-open shape this suite exists to
# refuse. The documented half is a FAIL rather than an ERROR: the code still has the capability,
# only SOLVE_C_CLI.md stopped saying so.
#
# THE DENIAL GRAMMAR IS CLAUSE-SCOPED, ON FLATTENED PARAGRAPHS, AND CHECKS EVERY OCCURRENCE.
# Three separate measurements forced each of those:
#   (1) LINE-scoped scored the real pre-fix tree 0 — `793210b7^`'s defect at
#       LARGE_SCALE_CAMPAIGNS.md:590@fbd6f9e5 is HARD-WRAPPED as "does not currently implement true
#       external" / "sort + dedup", so the noun does not exist on any single line. Same lesson as
#       GATE 18's whitespace-normalisation leg, met again on a different gate.
#   (2) PARAGRAPH-scoped without a clause bound fired on affirmations: `DEPLOYMENT.md:166`
#       ("external merge streams in chunks, doesn't…") and `LARGE_SCALE_CAMPAIGNS.md:1026`
#       ("There is no S at which you need code that does not exist. External merge is not
#       RAM-bounded") both carry a negation and an external-merge noun and both are CORRECT. The
#       negation must govern the noun within one clause, cut at `. ` / `; ` / ` — `.
#   (3) FIRST-occurrence-only let a paragraph that affirms and then denies pass on its opening
#       clause — measured on the live narration paragraph at LARGE_SCALE_CAMPAIGNS.md:873, which opens "**`solve --merge`
#       already does external sort + dedup.**" and quotes the retracted denial two sentences
#       later. Every occurrence is now checked.
#
# NARRATION IS EXCLUDED, not counted — the GATE 47 trap. LARGE_SCALE_CAMPAIGNS.md:841-847 is the
# paragraph that DOCUMENTS this very correction and quotes the refuted wording inside `*"…"*`.
# A gate that fires there punishes the fix. Whole-file exclusions: CORRECTIONS.md, HISTORY.md.
# THE REFUTED WORDING IS NOT QUOTED IN THIS COMMENT — see RETRACTED_PHRASES.tsv for the
# registered spellings; the sentence above is A01 row 20's own description of the GAP, not the
# retracted claim.
#
# MEASURED. Live: 56 markdown units mention external sort/merge, 0 denials, 1 correctly excluded
# as narration, rc 0. REAL PRE-FIX TREE `793210b7^` with LARGE_SCALE_CAMPAIGNS.md restored:
# 49 units, **1 DENIAL at documentation/LARGE_SCALE_CAMPAIGNS.md:587** (the unit holding :590),
# 0 narration exclusions, rc 1 — the exact A01 row 20 site.
gate_merge_semantics() {
  echo "== GATE 76: prose may not deny a merge capability the binary's env surface provides =="
  local out err npara nden
  out=$(python3 - <<'PY'
import subprocess, sys, os
ENV = ('SOLVE_MERGE_MODE', 'SOLVE_MERGE_CHUNK_GB')
CLI = 'documentation/SOLVE_C_CLI.md'
if not os.path.exists('solve.c'):
    print('ERR\tsolve.c is absent, so the env surface this leg derives from could not be read')
    sys.exit(0)
src = open('solve.c', encoding='utf-8', errors='replace').read()
missing = [e for e in ENV if e not in src]
if missing:
    print('ERR\tsolve.c no longer mentions %s — the capability this leg asserts cannot be '
          'confirmed from the source. If the capability was REMOVED the prose denials become '
          'true and this gate must be retired, not satisfied; if the scan broke, fix the scan. '
          'A clean verdict is not available here.' % ', '.join(missing))
    sys.exit(0)
try:
    cli = open(CLI, encoding='utf-8').read()
except OSError as e:
    print('ERR\t%s could not be read: %s' % (CLI, e)); sys.exit(0)
undoc = [e for e in ENV if e not in cli]
for e in undoc:
    print('UNDOC\t%s' % e)
mds = subprocess.run(['git','ls-files','*.md'], capture_output=True, text=True).stdout.split()
if not mds:
    print('ERR\tgit ls-files returned no markdown at all'); sys.exit(0)
SKIP = ('documentation/CORRECTIONS.md', 'documentation/HISTORY.md')
NOUN = ('external sort', 'external chunked-sort', 'external merge')
NEG  = ('does not currently implement', 'does not implement', 'not implement',
        'is not implemented', 'no true', 'not in `solve.c`', 'not in solve.c',
        'cannot do', 'does not do', 'no external', 'does not currently')
NARR = ('the old text', 'previously read', 'used to read', 'now reads', '[corrected',
        '*(corrected', 'the old wording', 'superseded', 'old text opened')
def starts_unit(l):
    t = l.lstrip()
    if not t: return True
    if t[0] in '#|>': return True
    if t[:2] in ('- ', '* ', '+ '): return True
    k = 0
    while k < len(t) and t[k].isdigit(): k += 1
    if k and k < len(t) and t[k] in '.)' and t[k+1:k+2] == ' ': return True
    return False
npara = nden = nnarr = 0
for m in mds:
    if m in SKIP: continue
    try:
        L = open(m, encoding='utf-8').read().split('\n')
    except OSError as e:
        print('ERR\t%s could not be read: %s' % (m, e)); sys.exit(0)
    i = 0
    while i < len(L):
        a = i; b = i
        while b + 1 < len(L) and not starts_unit(L[b+1]): b += 1
        i = b + 1
        flat = ' '.join(' '.join(L[a:b+1]).split()).lower()
        if not any(n in flat for n in NOUN): continue
        npara += 1
        poss = []
        for n in NOUN:
            k = flat.find(n)
            while k >= 0:
                poss.append(k); k = flat.find(n, k + 1)
        for pos in sorted(set(poss)):
            seg = flat[:pos]
            cut = max(seg.rfind('. '), seg.rfind('; '), seg.rfind(' — '))
            clause = seg[cut+1:] if cut >= 0 else seg
            if not any(g in clause for g in NEG): continue
            if any(x in flat for x in NARR):
                nnarr += 1
            else:
                nden += 1
                print('HIT\t%s:%d\t%s' % (m, a + 1, flat[max(0, pos-100):pos+45]))
            break
print('POP\t%d\t%d\t%d' % (npara, nden, nnarr))
PY
) || { echo "  [FAIL] GATE 76 scanner failed — NOTHING was checked."; return 1; }
  err=$(printf '%s\n' "$out" | sed -n 's/^ERR\t//p')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 76 could not judge its subject: $err"; return 1; fi
  local rc=0 line
  while IFS= read -r line; do
    case "$line" in
      UNDOC*) echo "  [FAIL] $(printf '%s' "$line" | cut -f2) is in solve.c but not documented in documentation/SOLVE_C_CLI.md."
              echo "         This leg's whole premise is that the documented env surface is the public"
              echo "         evidence for the capability. Undocumented, the capability is real and the"
              echo "         reader cannot check it — document the variable."
              rc=1 ;;
      HIT*)   echo "  [FAIL] $(printf '%s' "$line" | cut -f2) — prose denies a merge capability solve.c has"
              echo "         CLAUSE: …$(printf '%s' "$line" | cut -f3)"
              rc=1 ;;
    esac
  done < <(printf '%s\n' "$out")
  npara=$(printf '%s\n' "$out" | sed -n 's/^POP\t\([0-9]*\)\t.*/\1/p')
  nden=$(printf '%s\n' "$out" | sed -n 's/^POP\t[0-9]*\t\([0-9]*\)\t.*/\1/p')
  if ! grep -qxE '[0-9]+' <<<"${npara:-}"; then
    echo "  [FAIL] GATE 76 printed no population census, so 'no findings' would be a lie."; return 1
  fi
  if [ "$npara" -lt 20 ]; then
    echo "  [FAIL] GATE 76 judged only $npara markdown unit(s) mentioning external sort/merge (floor 20,"
    echo "         measured 56). The subject left the corpus or the unit splitter broke; either way this"
    echo "         gate has nothing to say and must not say the corpus is clean."
    return 1
  fi
  if [ "$rc" -ne 0 ]; then
    echo "         solve.c carries SOLVE_MERGE_MODE and SOLVE_MERGE_CHUNK_GB: \`--merge\` runs in"
    echo "         memory when the set fits and falls back to external sort otherwise. The 560T merge"
    echo "         WAS an external chunked-sort. Rewrite the sentence, or — if the capability really"
    echo "         was removed — retire this gate in the same commit rather than wording around it."
    return 1
  fi
  echo "  [ok] GATE 76: $npara markdown unit(s) mention external sort/merge; 0 deny what SOLVE_MERGE_MODE/SOLVE_MERGE_CHUNK_GB provide; both documented in $(basename documentation/SOLVE_C_CLI.md)"
  return 0
}

# ─────────────────────────────────────────────────────────────────────────────────────────────
# GATE 80 — a `rec#` literal qualified across datasets must be attached to the dataset it indexes
# (`rec-scope`).
#
# QUEUED AS: PROSE_LANE_FOLLOWUPS.md "GATE (proposed, not built) — cross-scale rec# identifiers"
# (prose batch P39, Codex V2-F31). A `rec#` is a position in ONE dataset's sort order and does not
# survive a change of dataset: the same ordering — KW with the position-2/3 pair blocks swapped —
# is rec#330177707 at d3 560T, rec#104178045 at d3 100T and rec#21262918 at d3 10T (MEASURED by
# P39: rec#330177707 has zero occurrences in runs/20260419_100T_d3_d128westus3/analyze_output.log.gz).
# P39 registered the two literal defect sentences as RP-c79db9ce / RP-926ac304; those needles catch
# those two strings and nothing else, and the class needs a PREDICATE.
#
# THE PREDICATE, per SENTENCE (hard-wrapped paragraphs are flattened first, so a line-based grep is
# not what runs here). A sentence is JUDGED when it carries a multi-dataset qualifier — "at both
# canonical scales", "at every tested depth", "at every scale", "across scales", "in all four
# datasets" and the like (QUAL below) — AND at least one `rec#<digits>` literal. In a judged
# sentence EVERY literal must be ATTACHED to a scale token (560T, 100T, 10T, 11.2T, 5.6T, 742M …):
#   (a) directly after it: `rec#N at 560T`, `rec#N in the 560T canonical's own sort order`,
#       `rec#N at d3 100T` — a preposition and at most one article/depth word between; or
#   (b) directly before it: `the 560T record rec#N`, `at 560T: rec#N` — a scale token within 30
#       chars of the literal with no `,` `;` `(` `)` in between. That last clause is what keeps
#       "(100T and 560T), the survivor is rec#N" — the defect itself — from passing on proximity
#       alone, and it was the first thing a 48-char proximity window got wrong.
# A literal that is unattached is a HIT: it is being read across datasets.
#
# QUOTED QUALIFIERS ARE MENTIONS, NOT USES. Correction narration — CORRECTIONS.md's BEFORE
# paragraphs, BOUNDARY_MINIMUM.md's own revision note — writes `was qualified as holding "at every
# tested depth"`. Double-quoted spans ("…", “…”) are removed from the sentence BEFORE the qualifier
# search, so a narrated qualifier does not put its sentence in the population. That is an exemption
# by CONSTRUCTION (the quotation marks), not by file or directory, and removing the quotation marks
# is one of the mutants below: the sentence then becomes a use, and fires.
#
# POPULATION, printed and floored: >= 10 `rec#` literals corpus-wide and >= 2 judged sentences,
# else FAIL. A rewrite that deletes every cross-scale sentence, or every rec# literal, must not
# produce a quiet green.
#
# MEASURED BEFORE LANDING (2026-09-04, disposable shared clone, never the shared worktree):
#   live main 2a929ea3  -> 1 HIT: documentation/SOLVE.md:329 — "identical greedy order at both
#     canonical scales (… boundary 1 kills the last impostor, rec#330177707)" — a third live site
#     of the P39 class that the two registered needles could not reach; rc 1
#   live main with SOLVE.md:329 attached ("rec#330177707 at 560T")  -> 0 hits, rc 0
#   pre-P39 tree (`42620c77^`)  -> HITs on BOUNDARY_MINIMUM.md's headline ("at every tested depth")
#     and §What this implies ("at both canonical scales") plus SOLVE.md:329, rc 1
#   mutation: BOUNDARY_MINIMUM.md:58 "at 560T" deleted after the literal  -> HIT rc 1
#   mutation: BOUNDARY_MINIMUM.md:108 quotation marks removed from the narrated qualifier -> HIT rc 1
#   mutation: CLAIMS_DECIDED.md:42 sixty chars of filler between the literal and "560T" -> HIT rc 1
#   mutation: "(100T and 560T), the survivor is rec#330177707" planted -> HIT rc 1 (proximity alone
#     would have passed it)
#   mutation: qualifier reworded "across the three scales" -> still judged, HIT rc 1
#   mutation: every rec# literal removed from the corpus -> population FAIL rc 1, not green
#   correct NON-firing: a sentence with a literal and no qualifier stays green
gate_rec_scope() {
  echo "== GATE 80: a rec# literal qualified across datasets is attached to the dataset it indexes =="
  local out
  out=$(python3 - <<'PY'
import re, io, sys, subprocess
QUAL=re.compile(r"\b(?:at|in|across)\s+(?:both|every|each|all)(?:\s+(?:of|the|four|three|two|tested|canonical|published|partition))*\s+(?:scales?|depths?|canonicals?|datasets?|budgets?)\b"
                r"|\bacross\s+(?:(?:the|all|four|three|two|tested|canonical|published)\s+)*(?:scales|depths|datasets|canonicals|budgets)\b"
                r"|\bat\s+every\s+(?:tested\s+)?(?:depth|scale|budget)\b"
                r"|\bscale-invariant\b|\bdataset-invariant\b", re.I)
REC=re.compile(r"rec#\d+")
SCALE=r"(?:\d+(?:\.\d+)?\s?T|742M|31\.6M)"
AFTER=re.compile(r"rec#\d+\)?,?\s+(?:at|in|of|from|for)\s+(?:the\s+)?(?:d[23]\s+)?"+SCALE+r"\b", re.I)
BEFORE=re.compile(SCALE+r"(?:'s)?[^,;()]{0,30}rec#\d+", re.I)
QUOTED=re.compile(r'"[^"\n]{1,160}"|“[^”\n]{1,160}”')
try:
    files=subprocess.run(["git","ls-files","*.md"],capture_output=True,text=True,check=True).stdout.split("\n")
except Exception as e:
    print("ERROR\tgit ls-files failed — the corpus could not be enumerated: %s"%e); raise SystemExit
files=[f for f in files if f.strip()]
if not files: print("ERROR\tzero tracked *.md — vacuous, treated as failure."); raise SystemExit
nfiles=nlit=njudged=0
for f in files:
    try: t=io.open(f,encoding="utf-8",errors="replace").read()
    except OSError: continue
    nfiles+=1
    nlit+=len(REC.findall(t))
    pos=0
    for para in re.split(r"\n[ \t]*\n", t):
        start=t.count("\n",0,pos)+1; pos+=len(para)+2
        if "rec#" not in para: continue
        flat=" ".join(re.sub(r"[*`]","",para).split())
        for sent in re.split(r"(?<=[.!?])\s+(?=[A-Z(\[\"“*])", flat):
            lits=REC.findall(sent)
            if not lits: continue
            unquoted=QUOTED.sub(" ",sent)
            q=QUAL.search(unquoted)
            if not q: continue
            njudged+=1
            attached=set()
            for m in AFTER.finditer(unquoted): attached.add(REC.search(m.group()).group())
            for m in BEFORE.finditer(unquoted): attached.add(REC.findall(m.group())[-1])
            for lit in dict.fromkeys(REC.findall(unquoted)):
                if lit not in attached:
                    k=para.find(lit); line=start+(para[:k].count("\n") if k>=0 else 0)
                    print("HIT\t%s:%d\t%s is qualified %r but attached to no dataset — a rec# is a position in ONE dataset's sort order: %s"
                          %(f,line,lit,q.group(),sent[:150]))
print("POP\t%d\t%d\t%d"%(nfiles,nlit,njudged))
PY
) || { echo "  [FAIL] GATE 80 scanner failed — NOTHING was checked."; return 1; }
  local err; err=$(printf '%s\n' "$out" | awk -F'\t' '$1=="ERROR"{print $2}')
  if [ -n "$err" ]; then echo "  [FAIL] GATE 80 could not judge its corpus: $err"; return 1; fi
  local pf pl pj
  IFS=$'\t' read -r pf pl pj < <(printf '%s\n' "$out" | awk -F'\t' '$1=="POP"{print $2"\t"$3"\t"$4; exit}')
  if ! grep -qxE '[0-9]+' <<<"${pl:-}"; then echo "  [FAIL] GATE 80 printed no population census — the scan did not complete."; return 1; fi
  if [ "$pl" -lt 10 ]; then echo "  [FAIL] GATE 80 found only $pl rec# literal(s) across $pf files (floor 10) — the identifier idiom left the corpus; nothing judged."; return 1; fi
  if [ "$pj" -lt 2 ]; then echo "  [FAIL] GATE 80 judged only $pj cross-scale sentence(s) carrying a rec# literal (floor 2) — the population collapsed; a quiet green is not evidence."; return 1; fi
  local rc=0 tag where msg
  while IFS=$'\t' read -r tag where msg; do
    [ "$tag" = HIT ] || continue
    echo "  [FAIL] $where: $msg"; rc=1
  done < <(printf '%s\n' "$out")
  if [ "$rc" -ne 0 ]; then echo "         Name the dataset the index belongs to (\"rec#N at 560T\") or drop the literal; the ORDERING is what holds across scales, the rec# is not."; return 1; fi
  echo "  [ok] GATE 80: $pl rec# literal(s) in $pf files; $pj cross-scale sentence(s) judged, every literal attached to its dataset"
  return 0
}

# ---------------------------------------------------------------------------
# GATE 77 — the certificate directory's STATED inventory equals the corpus on disk
# (`cert-inventory`).
#
# 🔴 WHY. reports/certificates/README.md carried a "Full inventory" count of 22 from 2026-09-02
# until 2026-09-19 while the directory held 24: the two cardinality-only alternation subsets
# (alt_le_14_noY_unsat, alt_ge_16_noY_unsat), archived 2026-09-03 by fcd9feab, were REPLAYED BY
# verify_all.sh and described by that page nowhere. The count had already been caught once, on
# 2026-09-10, at verify_all.sh's own section header and CERT_FLOOR (its note there reads "COUNT
# CORRECTED 2026-09-10"); the README was not swept with it, which is the fix-the-instance failure
# this repo has filed repeatedly.
#
# THE DEFECT IS THE MISSING DIRECTION, NOT THE WRONG NUMBER. GATE 39 LEG 1 (`cert-claims-shipped`)
# runs MARKDOWN -> DISK: every certificate named in prose must exist and be mapped. Nothing ran
# DISK -> MARKDOWN, so a certificate that no document mentions is invisible to it BY CONSTRUCTION.
# Demonstrated rather than argued: a full `doc_gates.sh all` passed on 2026-09-19 against a tree
# carrying this exact mismatch. This gate is that reverse direction, and it is why a README row
# alone would not have closed the row it came from -- the drift mechanism would have survived.
#
# FOUR LEGS, each failing loudly when its own input is absent:
#   LEG 1  the archived corpus is enumerable and non-trivial; the git index and the directory agree
#   LEG 2  README.md carries EXACTLY ONE live "Full inventory: N certificates" sentence, N == corpus
#   LEG 3  verify_all.sh carries EXACTLY ONE CERT_FLOOR=<int>, and it equals the corpus too
#   LEG 4  README.md carries EXACTLY ONE live "N distinct proofs" sentence, and N equals the number
#          of DISTINCT proof objects — every archived proof decompressed and sha256'd (Q-640,
#          2026-09-21). Files and proofs are different counts: grand_ccn4_unsat and
#          five_loo_ccn8_unsat are byte-identical DRAT under two target names, so the corpus is 24
#          files and 23 proofs, and a file-level census (legs 1-3, or any sha of the .gz blobs,
#          which differ by compression) cannot see it. "24/24 verified" read as 24 independent
#          results is the overstatement this leg exists to refuse. Cost: ~0.3 s for the whole
#          corpus, measured.
#
# ON "EXACTLY ONE", which is a measured hazard here and not a nicety: a count captured by a pattern
# that can match twice is not a value. This page quotes its own retired counts inside dated
# correction notes (the house convention), so the FIRST draft of the 2026-09-19 repair made this
# pattern match twice -- the live sentence and its own correction note. That FAILS here, naming the
# remedy, rather than silently comparing whichever line grep reached first.
#
# VERDICT TOKEN: a whole line, CERT_INVENTORY=PASS or CERT_INVENTORY=FAIL, emitted on EVERY path
# including those where an input is missing (`grep -qx 'CERT_INVENTORY=PASS'`). A gate that prints
# nothing when its subject is absent is indistinguishable from a gate nobody ran.
# COST: two greps, one git ls-files, one find over a 27-entry directory. Milliseconds; it is in `all`.
# ---------------------------------------------------------------------------
gate_cert_inventory() {
  echo "== GATE 77: certificates/README.md's stated inventory equals the archived corpus =="
  local readme="reports/certificates/README.md" vs="reports/certificates/verify_all.sh"
  local dir="reports/certificates" t
  # BOTH require_tracked outcomes are failures for THIS gate, including rc 1 ("absent and never
  # tracked"), which is a legitimate skip elsewhere. Here the file IS the subject: if it is not
  # there, nothing was compared, and a check that cannot run must ERROR rather than report clean.
  require_tracked "$readme" "The inventory sentence is this gate's subject; with it absent, nothing was compared."
  t=$?
  if [ "$t" -ne 0 ]; then echo "  [FAIL] GATE 77 has no README to read — it checked NOTHING."; echo "CERT_INVENTORY=FAIL"; return 1; fi
  require_tracked "$vs" "CERT_FLOOR is this gate's third leg; with verify_all.sh absent, nothing was compared."
  t=$?
  if [ "$t" -ne 0 ]; then echo "  [FAIL] GATE 77 has no verify_all.sh to read — it checked NOTHING."; echo "CERT_INVENTORY=FAIL"; return 1; fi
  if [ ! -d "$dir" ]; then
    echo "  [FAIL] $dir is not a directory — the archived corpus could not be enumerated."
    echo "         An unreadable corpus is the strongest possible mismatch, not a reason to pass."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi

  # ---------- LEG 1: the corpus itself ----------
  # A FAILED listing is not an EMPTY one: both rc's are printed beside their counts so a tool
  # error can never reach the comparison disguised as a number.
  local glist grc dlist drc n_idx n_disk
  glist=$(git ls-files -- "$dir/*.drat" "$dir/*.drat.gz"); grc=$?
  if [ "$grc" -ne 0 ]; then
    echo "  [FAIL] git ls-files failed (rc=$grc) — the tracked corpus could not be enumerated; nothing judged."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  dlist=$(find "$dir" -maxdepth 1 -type f \( -name '*.drat' -o -name '*.drat.gz' \) -print); drc=$?
  if [ "$drc" -ne 0 ]; then
    echo "  [FAIL] find failed (rc=$drc) over $dir — the on-disk corpus could not be enumerated; nothing judged."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  if [ -z "$glist" ]; then n_idx=0; else n_idx=$(printf '%s\n' "$glist" | wc -l); fi
  if [ -z "$dlist" ]; then n_disk=0; else n_disk=$(printf '%s\n' "$dlist" | wc -l); fi
  echo "  [info] corpus census: tracked=$n_idx on_disk=$n_disk (git rc=$grc, find rc=$drc)"
  if [ "$n_idx" -lt 20 ]; then
    echo "  [FAIL] only $n_idx tracked certificate(s) under $dir (floor 20) — the corpus collapsed or"
    echo "         the glob stopped matching. A count this gate cannot trust is not a count it may compare."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  if [ "$n_idx" -ne "$n_disk" ]; then
    echo "  [FAIL] the git index holds $n_idx certificate(s) and the directory holds $n_disk — they disagree,"
    echo "         so 'the corpus' has no single size and neither number may be published as one."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi

  # ---------- LEG 2: the README's stated inventory ----------
  local claims crc nclaims n
  claims=$(grep -oE 'Full inventory: [0-9]+ certificates' "$readme"); crc=$?
  if [ "$crc" -gt 1 ]; then          # 0 = matched, 1 = no match, >1 = a grep ERROR
    echo "  [FAIL] grep failed (rc=$crc) reading $readme — the claim was never read; nothing judged."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  if [ -z "$claims" ]; then nclaims=0; else nclaims=$(printf '%s\n' "$claims" | wc -l); fi
  echo "  [info] README sentences in the live inventory form: $nclaims (grep rc=$crc)"
  if [ "$nclaims" -ne 1 ]; then
    echo "  [FAIL] $readme carries $nclaims sentence(s) of the form 'Full inventory: N certificates'; exactly 1 is required."
    if [ "$nclaims" -eq 0 ]; then
      echo "         ZERO means the sentence was reworded, moved or deleted. This gate then has nothing to"
      echo "         compare against the directory, and an unanchored gate must fail rather than go quiet."
    else
      echo "         MORE THAN ONE means the capture is ambiguous. A retired count quoted in a dated"
      echo "         correction note must not be written in the LIVE form — quote it as a bare number."
    fi
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  n=${claims#Full inventory: }; n=${n% certificates}
  if ! grep -qxE '[0-9]+' <<<"$n"; then
    echo "  [FAIL] the captured inventory count is not a single integer: '$n'"
    echo "CERT_INVENTORY=FAIL"; return 1
  fi

  # ---------- LEG 3: verify_all.sh's CERT_FLOOR ----------
  local floors frc nfloors f
  floors=$(grep -oE '^CERT_FLOOR=[0-9]+' "$vs"); frc=$?
  if [ "$frc" -gt 1 ]; then
    echo "  [FAIL] grep failed (rc=$frc) reading $vs — CERT_FLOOR was never read; nothing judged."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  if [ -z "$floors" ]; then nfloors=0; else nfloors=$(printf '%s\n' "$floors" | wc -l); fi
  echo "  [info] verify_all.sh CERT_FLOOR assignments: $nfloors (grep rc=$frc)"
  if [ "$nfloors" -ne 1 ]; then
    echo "  [FAIL] $vs carries $nfloors CERT_FLOOR assignment(s); exactly 1 is required. Zero means the"
    echo "         population floor was renamed or removed; more than one means the effective floor"
    echo "         depends on which assignment runs last, which no reader can see."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  f=${floors#CERT_FLOOR=}
  if ! grep -qxE '[0-9]+' <<<"$f"; then
    echo "  [FAIL] the captured CERT_FLOOR is not a single integer: '$f'"
    echo "CERT_INVENTORY=FAIL"; return 1
  fi

  # ---------- LEG 4: distinct proof OBJECTS, not files (Q-640) ----------
  # Every archived proof is decompressed and hashed; the .gz blobs themselves are NOT compared,
  # because two gzips of one DRAT differ by compression and a blob census is exactly the
  # instrument that missed this. A proof that cannot be decompressed is a census that did not
  # happen, so it FAILS here rather than counting as one more distinct object.
  local shalist="" h n_distinct
  for h in $glist; do
    local f_sha
    case "$h" in
      *.gz) f_sha=$(gzip -dc -- "$h" | sha256sum) ;;
      *)    f_sha=$(sha256sum -- "$h") ;;
    esac
    if [ $? -ne 0 ] || [ -z "$f_sha" ]; then
      echo "  [FAIL] could not decompress+hash $h — the proof census is incomplete; nothing judged."
      echo "CERT_INVENTORY=FAIL"; return 1
    fi
    shalist="$shalist${f_sha%% *} $h"$'\n'
  done
  n_distinct=$(printf '%s' "$shalist" | cut -d' ' -f1 | sort -u | grep -c .)
  if ! grep -qxE '[1-9][0-9]*' <<<"$n_distinct" || [ "$n_distinct" -gt "$n_idx" ]; then
    echo "  [FAIL] distinct-proof census returned '$n_distinct' over $n_idx files — not a count this gate may compare."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  echo "  [info] proof census: $n_idx file(s), $n_distinct distinct proof object(s)"
  # name every duplicate group, so a reader sees WHICH files share a proof, not just that some do
  printf '%s' "$shalist" | cut -d' ' -f1 | sort | uniq -d | while read -r dup; do
    echo "  [info] shared proof ${dup:0:16}…: $(printf '%s' "$shalist" | grep "^$dup " | cut -d' ' -f2- | xargs -n1 basename | tr '\n' ' ')"
  done
  local dclaims dcrc ndclaims nd
  dclaims=$(grep -oE '[0-9]+ distinct proofs' "$readme"); dcrc=$?
  if [ "$dcrc" -gt 1 ]; then
    echo "  [FAIL] grep failed (rc=$dcrc) reading $readme — the distinct-proof claim was never read; nothing judged."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  if [ -z "$dclaims" ]; then ndclaims=0; else ndclaims=$(printf '%s\n' "$dclaims" | wc -l); fi
  echo "  [info] README sentences in the live distinct-proof form: $ndclaims (grep rc=$dcrc)"
  if [ "$ndclaims" -ne 1 ]; then
    echo "  [FAIL] $readme carries $ndclaims sentence(s) of the form 'N distinct proofs'; exactly 1 is required."
    echo "         ZERO means the files-vs-proofs disclosure was reworded or deleted; MORE THAN ONE means the"
    echo "         capture is ambiguous — quote a retired count as a bare number, never in the live form."
    echo "CERT_INVENTORY=FAIL"; return 1
  fi
  nd=${dclaims% distinct proofs}
  if ! grep -qxE '[0-9]+' <<<"$nd"; then
    echo "  [FAIL] the captured distinct-proof count is not a single integer: '$nd'"
    echo "CERT_INVENTORY=FAIL"; return 1
  fi

  # ---------- judge, as a step of its own ----------
  echo "  [info] measured: corpus=$n_idx readme_claim=$n cert_floor=$f distinct=$n_distinct readme_distinct_claim=$nd"
  local bad=0
  if [ "$n" -ne "$n_idx" ]; then
    echo "  [FAIL] $readme states 'Full inventory: $n certificates' but $n_idx are archived under $dir."
    echo "         Name every certificate that exists, or the page describes a corpus the repository does not ship."
    bad=1
  fi
  if [ "$f" -ne "$n_idx" ]; then
    echo "  [FAIL] $vs sets CERT_FLOOR=$f but $n_idx certificates are archived — the shrink-guard is off by $((n_idx - f))."
    echo "         A floor below the corpus lets certificates disappear silently, which is the condition it exists to refuse."
    bad=1
  fi
  if [ "$nd" -ne "$n_distinct" ]; then
    echo "  [FAIL] $readme states '$nd distinct proofs' but the decompressed corpus holds $n_distinct distinct proof object(s)."
    echo "         Files and proofs are different counts; the page must state the one the census measures."
    bad=1
  fi
  if [ "$bad" -ne 0 ]; then echo "CERT_INVENTORY=FAIL"; return 1; fi
  echo "  [ok] GATE 77: $n_idx archived certificate(s); README states $n; verify_all.sh CERT_FLOOR=$f; $n_distinct distinct proofs, README states $nd — all agree"
  echo "CERT_INVENTORY=PASS"
  return 0
}

