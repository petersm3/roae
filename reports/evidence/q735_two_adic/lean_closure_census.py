#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""lean_closure_census.py: classify what each root theorem of lean/SuperspaceDivisibility.lean uses,
by SOURCE POSITION and by DEFINITION. Reads the output of LeanClosureCensus.lean.in (same directory;
the command is in lean/README.md, section "SuperspaceDivisibility.lean").
usage: lean_closure_census.py SuperspaceDivisibility.lean census.out [report.txt]
Sections are read from the `/-! ## §N` headings (Part 1) and the `§N` header comments (Part 2).
By the Lean file's own header, Steps 2-5 live in
  Step 2: §7, §17   Step 3: §4, §5   Step 4: §1, §3, §6, §8-§12   Step 5: §18, §19
The verdict uses no list of lemma names:
  families root: 0 anchor definitions (the list is in LeanClosureCensus.lean.in and comes from its
                 output), 0 constants declared in §3, §9-§12 (the meaning of the transform;
                 the 512-entry table), and (added after an outside review found that the anchor
                 list did not name the pruned transform `PR`) every declaration of Part 1 in its
                 closure that is not a theorem is on the list ALLOW below. ALLOW is the list of
                 the Part 1 definitions the families proofs use; each was read, and none is a
                 character, a transform, a packed table or a statement about coefficients. A
                 definition that is not on it fails the root, whatever it is: the rule does not
                 depend on the anchor list being complete.
  control root:  at least 10 anchor definitions, at least 100 such constants, and at least 20
                 Part 1 non-theorem declarations that are not on ALLOW
  probe root:    a constant that reaches `PR` and no anchor and nothing in §3, §9-§12, so the two
                 older rules accept it; the ALLOW rule must reject it, and name `PR`. This is the
                 positive control for the ALLOW rule, run on real output of Lean.
The declaration a constant belongs to is read from the source at the line Lean reports (the
first `theorem`/`def`/... keyword at or after that line; for a field of a structure, the
structure's head before it); its name must be a prefix of the constant's name, or the run fails.
Fails closed: every root must have its summary line and as many constant lines as the summary
says; every Part 1 constant must be matched to a declaration of the source; every name on ALLOW
must be used by some families root (no dead entries); every constant must have a line (unplaced = 0), must be in the environment, and must sit
in the part its namespace says (SuperspaceDivisibility.* in §0-§34, all others in §35-§45);
29 anchors, each a definition of Part 1 with a line (the Lean side has checked that each is a
definition); the Lean side must have reached its last line.
Short lines (POS, POSV, POSA, POS_ALLOW, POS_VERDICT) go to stdout; the full list of Part 1 constants under the
families roots that sit in Step 2-5 sections goes to report.txt if given.
The last line is the verdict, POS_VERDICT=PASS or POS_VERDICT=FAIL; the exit status is 0 for PASS
and 1 for FAIL. Written and read by Fable lanes of this project (Claude Fable 5.2); not
independent examination."""
import re, sys, collections
src = open(sys.argv[1], encoding='utf-8').read().split('\n')
heads = []
for i, l in enumerate(src, 1):
    m = re.match(r'^/-! ## §(\d+)\s', l) or re.match(r'^  §(\d+)  \S', l)
    if m and (not heads or int(m.group(1)) > heads[-1][1]) and not (i < 160):
        heads.append((i, int(m.group(1))))
assert [h[1] for h in heads] == list(range(0, 46)), [h[1] for h in heads]
def sec(line):
    s = -1
    for i, n in heads:
        if i <= line: s = n
    return s
def user(n): return re.sub(r'^_private\.[^0-9]*\.\d+\.', '', n)
STEP = {7: 2, 17: 2, 4: 3, 5: 3, 1: 4, 3: 4, 6: 4, 8: 4, 9: 4, 10: 4, 11: 4, 12: 4, 18: 5, 19: 5}
TABLE_SECS = {3, 9, 10, 11, 12}          # meaning of the transform; the 512-entry table
# The Part 1 declarations, other than theorems, that a families root may use. Hexagram-level
# definitions (§0-§2), plain sums over assignments (§4, §17, §21), a 3-bit popcount (§7 `pc3`), `st` (§8), the coordinate model
# of a fibre with its 0/1 weight and count (§14), slot book-keeping (§18, §19), indicators and sums
# of fibres (§23), sequences and pairs (§21-§23), the coordinate permutations (§24).
ALLOW = set("""pc6 rev6 partner ham KW transitions c1ok c4ok c5ok
 rev3 hexof supp samePair
 seqs isSuper bclass bseq skel cellV2 superCount
 Asg upd sum8 sumOver Indep
 pc3 st
 entry clsAt distinctOK W fibreC budgetOK
 sumN catK
 slots Ksl Ks kk Q4 cq
 sg KA
 lsum c1L pairs listFrom
 bl wl bk LL
 Bind Gs
 ptab pm pos rsel""".split())
DECL = re.compile(r'^\s*(?:@\[[^\]]*\]\s*)*(?:(?:private|protected|noncomputable|partial|unsafe)\s+)*'
                  r'(theorem|def|abbrev|structure|inductive|instance|class|opaque|axiom)\s+([^\s:({\[]+)')
_decl = {}
def decl(line):
    """(keyword, name) of the declaration that starts at `line` (its doc comment or its keyword)."""
    if line not in _decl:
        r = None
        for j in range(line, min(line + 40, len(src) + 1)):
            m = DECL.match(src[j - 1])
            if m: r = (m.group(1), m.group(2)); break
        _decl[line] = r
    return _decl[line]
def offlist(L):
    """Part 1 non-theorem declarations in a closure: (all names, names not on ALLOW, unmatched constants)."""
    names = set(); unmatched = 0
    for ln, kind, n in L:
        if not ln or sec(ln) > 34: continue
        u = user(n)
        own = lambda d: d is not None and (u == 'SuperspaceDivisibility.' + d[1] or u.startswith('SuperspaceDivisibility.' + d[1] + '.'))
        d = decl(ln)
        if not own(d):
            # a field of a structure is declared on a line inside the structure: look back for its head
            d = None
            for j in range(ln - 1, max(ln - 40, 0), -1):
                m = DECL.match(src[j - 1])
                if m:
                    if m.group(1) in ('structure', 'inductive', 'class'): d = (m.group(1), m.group(2))
                    break
            if not own(d): unmatched += 1; continue
        if d[0] != 'theorem': names.add(d[1])
    return names, sorted(names - ALLOW), unmatched
roots = collections.OrderedDict(); summ = {}; complete = None; anch = []; errors = 0
for l in open(sys.argv[2], encoding='utf-8'):
    l = l.rstrip()
    if 'V2POS_ERROR' in l or ': error' in l: errors += 1
    m = re.search(r'V2POS (\S+) (\d+) (\S+) (\S+)$', l)
    if m: roots.setdefault(m.group(1), []).append((int(m.group(2)), m.group(3), m.group(4))); continue
    m = re.search(r'V2POSANCH (\d+) (\S+)$', l)
    if m: anch.append((int(m.group(1)), m.group(2))); continue
    m = re.search(r'V2POSSUM (\S+) (.*)$', l)
    if m: summ[m.group(1)] = m.group(2); continue
    m = re.search(r'V2POS_COMPLETE (.*)$', l)
    if m: complete = m.group(1)
def num(s, key):
    m = re.search(r'(?:^| )' + re.escape(key) + r'=(\d+)', s or '')
    return int(m.group(1)) if m else -1
FAM = ['Q1150.gplus_fibre', 'Q1150.gplus_fibre_13', 'Q1150.gplus_family', 'Q1150.cellV2_dvd_families',
       'Q1150.superCount_dvd_families', 'Q1150.censusC_dvd_families', 'Q1150.kw_gplus', 'Q1150.kw_family',
       'Q1150.ident_bound', 'Q1150.inv_fibre', 'Q1150.ident_exact', 'Q1150.moves_exact', 'Q1150.family_exact',
       'Q1150.piece_dvd']
CTL = ['Q1150.censusC_dvd', 'SuperspaceDivisibility.cellV2_dvd', 'SuperspaceDivisibility.superCount_dvd',
       'SuperspaceDivisibility.fibreC_dvd', 'SuperspaceDivisibility.fibreC_dvd_general', 'SuperspaceDivisibility.cellV1_dvd']
# probe roots: `pm_same` (§16) is a theorem about a value of the pruned transform; `PR` is the transform itself
PROBE = ['SuperspaceDivisibility.pm_same', 'SuperspaceDivisibility.PR']
# the anchors come from LeanClosureCensus.lean.in (`posAnchors`), whose run stops with V2POS_ERROR unless
# each is a constant of the module and a definition
anch_ok = (len(anch) == 29 and len(set(a[1] for a in anch)) == 29
           and all(a[0] > 0 and 1 <= sec(a[0]) <= 34 and a[1].startswith('SuperspaceDivisibility.') for a in anch))
ANCH = set(a[1] for a in anch)
print("POS_ANCHORS n=%d distinct=%d each_a_placed_definition_of_part1=%s in_step2to5_sections=%d elsewhere=[%s]" % (
    len(anch), len(ANCH), anch_ok, sum(1 for a in anch if sec(a[0]) in STEP),
    ' '.join('%s:§%d' % (a[1].split('.', 1)[1], sec(a[0])) for a in anch if sec(a[0]) not in STEP)))
union = {}; bad = 0; out = []; allow_used = set(); post = []
for r, L in roots.items():
    h = collections.Counter(sec(x[0]) if x[0] else 'UNPLACED' for x in L)
    insteps = [x for x in L if x[0] and sec(x[0]) in STEP]
    kinds = collections.Counter(x[1] for x in insteps)
    fam = r in FAM
    unplaced = sum(1 for x in L if x[0] == 0)
    # NEW: a constant sits in the part of the file that its namespace says
    wrong_part = sum(1 for x in L if x[0] and (user(x[2]).startswith('SuperspaceDivisibility.') != (sec(x[0]) <= 34)))
    # NEW: the summary line agrees with the constant lines
    s = summ.get(r)
    whole = num(s, 'in_module') == len(L) > 0 and num(s, 'unplaced') == unplaced and num(s, 'not_in_env') == 0
    a = sorted(n for n in set(user(x[2]) for x in L) if n in ANCH)
    ts = sum(1 for x in L if x[0] and sec(x[0]) in TABLE_SECS)
    names, off, unmatched = offlist(L)
    if r in PROBE:
        # the older rules accept it (that is the precondition of the control); the ALLOW rule must not
        old_accepts = (not a and ts == 0)
        okp = (old_accepts and 'PR' in off and unmatched == 0 and unplaced == 0 and wrong_part == 0 and whole)
        bad += not okp
        post.append("POSV PROBE    %s anchor_defs_in_closure=%d table_section_constants=%d older_rules_accept=%s "
                    "part1_nontheorem_declarations=%d not_on_allow_list=%d [%s] unmatched=%d summary_agrees=%s %s" % (
                        r, len(a), ts, old_accepts, len(names), len(off), ' '.join(off), unmatched, whole,
                        'REJECTED_AS_REQUIRED' if okp else 'UNEXPECTED'))
        continue
    if fam: allow_used |= names & ALLOW
    oka = (not off) if fam else (len(off) >= 20)
    oka = oka and unmatched == 0
    post.append("POSA %s %s part1_nontheorem_declarations=%d not_on_allow_list=%d%s unmatched=%d %s" % (
        'FAMILIES' if fam else 'CONTROL ', r, len(names), len(off),
        (' [%s]' % ' '.join(off)) if fam and off else '', unmatched, 'AS_EXPECTED' if oka else 'UNEXPECTED'))
    ok = (not a and ts == 0) if fam else (len(a) >= 10 and ts >= 100)
    ok = ok and unplaced == 0 and wrong_part == 0 and whole and (fam or r in CTL)
    bad += not (ok and oka)                # the POSV line below is as before; the ALLOW rule has its own line (POSA)
    print("POS %s %s :: in_module=%d in_step2to5_sections=%d (%s) :: by_section %s" % (
        'FAMILIES' if fam else 'CONTROL ', r, len(L), len(insteps), ' '.join('%s=%d' % kv for kv in sorted(kinds.items())),
        ' '.join('§%s=%d' % kv for kv in sorted(h.items(), key=lambda kv: (isinstance(kv[0], str), kv[0])))))
    print("POSV %s %s anchor_defs_in_closure=%d table_section_constants=%d unplaced=%d wrong_part=%d summary_agrees=%s %s" % (
        'FAMILIES' if fam else 'CONTROL ', r, len(a), ts, unplaced, wrong_part, whole, 'AS_EXPECTED' if ok else 'UNEXPECTED'))
    if fam:
        for x in insteps: union[x[2]] = (x[0], x[1])
nf = sum(1 for r in roots if r in FAM); nc = sum(1 for r in roots if r in CTL); npr = sum(1 for r in roots if r in PROBE)
for l in post: print(l)
dead = sorted(ALLOW - allow_used)
allow_ok = (not dead and not (ALLOW & set(x.split('.', 1)[1] for x in ANCH)))
print("POS_ALLOW n=%d used_by_a_families_root=%d unused=[%s] anchors_on_it=%d" % (
    len(ALLOW), len(allow_used), ' '.join(dead), len(ALLOW & set(x.split('.', 1)[1] for x in ANCH))))
print("POS_SUMMARIES=%d COMPLETE=[%s] ERROR_LINES=%d" % (len(summ), complete, errors))
print("FAMILIES_UNION_IN_STEP2TO5_SECTIONS n=%d thm=%d def=%d by_section %s" % (
    len(union), sum(1 for v in union.values() if v[1] == 'thm'), sum(1 for v in union.values() if v[1] == 'def'),
    ' '.join('§%d=%d' % kv for kv in sorted(collections.Counter(sec(v[0]) for v in union.values()).items()))))
if len(sys.argv) > 3:
    with open(sys.argv[3], 'w', encoding='utf-8') as f:
        f.write("Part 1 constants in Step 2-5 sections under the 14 families roots (n=%d)\n" % len(union))
        for n, (ln, k) in sorted(union.items(), key=lambda kv: (kv[1][0], kv[0])):
            f.write("  §%-2d step%d line %5d %-4s %s\n" % (sec(ln), STEP[sec(ln)], ln, k, n))
        f.write("anchor definitions (n=%d)\n" % len(anch))
        for ln, n in sorted(anch): f.write("  §%-2d line %5d %s\n" % (sec(ln), ln, n))
good = (bad == 0 and nf == 14 and nc == 6 and npr == 2 and len(roots) == 22 and len(summ) == 22 and anch_ok
        and allow_ok and errors == 0
        and complete is not None and num(complete, 'roots') == 22 and num(complete, 'anchors') == 29)
print("POS_VERDICT=%s roots=%d families=%d controls=%d probes=%d unexpected=%d anchors_ok=%s allow_ok=%s errors=%d complete=%s" % (
    'PASS' if good else 'FAIL', len(roots), nf, nc, npr, bad, anch_ok, allow_ok, errors, complete is not None))
sys.exit(0 if good else 1)
