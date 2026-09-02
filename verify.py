#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""Independent constraint verifier AND independent re-counter for the ROAE
King Wen results — a genuine second opinion answering TR-11 §10vi.

This file now independently verifies BOTH kinds of published result:

  (1) the RECORDS in solutions.bin — reads every record, reconstructs the
      64-hexagram sequence, and checks C1 (pair structure), C2 (no hamming-5
      transitions), C3 (complement distance <= 776), C4 (starts with
      hexagram 1 / hexagram 2), C5 (exact distance distribution), plus sorted
      order and duplicates.  [default mode / --enumerate-reference]

  (2) the exact COUNTS — `--recount` independently reproduces the small-n
      structural facts (the 32 pairs, within-pair multiset, XOR-product set,
      C3 = 776, the 48/24 symmetry group + King Wen's 24-record orbit) and the
      reduced-rung C1∩C2∩C4 union counts (U1/U2/U3 from TR-11's Verification
      Guide) by an independent COUNTING RECURRENCE — a plain (mask, last)
      layered subset DP with NO symmetry quotient, so a conceptual bug in
      solve.c's symmetry-quotient DP would NOT be shared. Since 2026-07-21 this
      also covers the **C5 ladder** (C1∩C2∩C4∩C5 — TR-11 §4b rungs n=9/13/16):
      each rung's target budget B0 is re-derived independently by §5's
      first-completion DFS (not taken from the published table) and the rung is
      then counted by a plain budgeted (mask,last,p) DP. The C5 layer — until
      now the only constraint with no independent re-count at all, and the one
      the full-31 integer rests on most heavily — therefore has one.

Different language, different implementation, standard-library only, NO import
of solve.c / solve.py / roae.py / sat.py — every quantity is rebuilt from the
published mathematical definitions (SPECIFICATION.md constraints C1–C5,
rev/comp/partner, the symmetry group; TR-11's reduced-rung tables).

Usage:
    python3 verify.py [solutions.bin]              # verify records
    python3 verify.py [solutions.bin] --jobs N     # parallel record verify
    python3 verify.py [solutions.bin] --expect-kw   # ... and REQUIRE King Wen to be present
    python3 verify.py --enumerate-reference N       # small-n brute-force (2<=N<=9)
    python3 verify.py --recount                     # independent count reproduction
    python3 verify.py --recount-rung N              # C5 ladder rung n=18/19 (worker-sized)
    python3 verify.py --recount-rung-layers N       # gate published per-layer masses (n=9/13)
    python3 verify.py --f1-dec-roundtrip            # gate the 192-bit decimal renderer, full range
    python3 verify.py --f1u192-binary-roundtrip     # gate the 24-byte on-disk limb layout
    python3 verify.py --recount-orbit-widths 31     # Burnside gate on the canonical_masks column
    python3 verify.py --recount-subtree             # TR-5 exact subtree anchors (443/62,256/9,422,793/16,504)
                                                    # + 3 away-from-KW C3 cross-anchors (solve.c-exact expectations)
    python3 verify.py --recount-finite              # TR-5/TR-6 finite record-mode + wrap/parity tallies
    python3 verify.py --recount-fiber               # TR-1 §7 orientation fiber (1,720,320 / 983,040)
    python3 verify.py --recount-gender-null         # TR-8 exact pair-null gender figure (47/445740)
    python3 verify.py [solutions.bin] --fiber-sweep # orientation-fiber factor: records -> sequences
    python3 verify.py --t3-stats DIR                # T3 pre-registered stats (a) uniformity, (c) C3
    python3 verify.py --t3-membership PATH          # T3 pre-registered stat (b) membership census
    python3 verify.py --g-structure C2ON C2OFF      # full-31 G-distribution structure from two logs

The last three read LARGE artifacts the caller supplies (a draw sample, two
enumerator logs). The artifacts are held privately; the ANALYSIS is public, and
each flag's --help names the command that GENERATES its input and the measured
cost of doing so — so the reproducibility promise is priced, not nominal.

--jobs N parallelizes via multiprocessing for large files. With N = 1
(default) behavior is identical to the single-threaded original.
N should typically be set to the number of physical cores. The output
must match --jobs 1 byte-for-byte (modulo the header line that prints
the chosen worker count).

Companion write-up (match table, method, corroboration chain, and the
reduced-C5-ladder definitional gap this instrument surfaced):
documentation/VERIFY.md.
"""
import sys, struct, argparse, multiprocessing, gzip, tempfile, atexit, os, shutil

KW = [
    63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
    25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
    60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
    29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42,
]
PAIRS = [(KW[2*i], KW[2*i+1]) for i in range(32)]
KW_DIST = [0] * 7
for i in range(63):
    KW_DIST[bin(KW[i] ^ KW[i+1]).count('1')] += 1
START_PAIR = 0  # hexagram 1 / hexagram 2

def hamming(a, b):
    return bin(a ^ b).count('1')

def compute_comp_dist(seq):
    """C3: sum of |pos[v] - pos[v^63]| over all v in 0..63.
    Bitwise complement; hexagram i's complement is i^63 (flip all 6 bits).
    Each complement pair contributes its absolute positional distance twice
    (once for each direction). KW's value is exactly 776 (= 12.125 × 64).
    The C3 constraint is total <= 776 (KW sets the ceiling)."""
    pos = [0] * 64
    for i, v in enumerate(seq):
        pos[v] = i
    total = 0
    for v in range(64):
        comp = v ^ 63
        total += abs(pos[v] - pos[comp])
    return total

# Derive the C3 ceiling from KW itself (same source of truth as solve.c)
KW_COMP_DIST = compute_comp_dist(KW)
if not (KW_COMP_DIST == 776):
    raise AssertionError(f"internal error: KW complement distance is {KW_COMP_DIST}, expected 776")

def decode(record):
    seq = []
    pairs_used = [0] * 32
    for i in range(32):
        pidx = (record[i] >> 2) & 0x3F
        orient = (record[i] >> 1) & 1
        if pidx >= 32:
            return None, None, None
        pairs_used[pidx] += 1
        a, b = PAIRS[pidx]
        if orient == 0:
            seq.extend([a, b])
        else:
            seq.extend([b, a])
    return seq, pairs_used, (record[0] >> 2) & 0x3F

def canonical(record):
    return bytes(b & 0xFC for b in record)

# ---------------------------------------------------------------------------
# INDEPENDENT repr(k) ORACLE  (--check-repr)
#
# WHY THIS EXISTS. solve.c's --kc-repr-normalize states outright that "there is
# NO separate repr oracle in this tree": its only built-in check is IDEMPOTENCE
# (re-run on the output, expect byte-identical), which is self-consistent and
# therefore cannot catch a normalization that is stable but WRONG. The
# SOLVE_REPR_FC A/B (forward-check on vs off) is also weaker than it looks --
# both arms share the same DFS, the same child ordering and the same code, so a
# defect in the shared traversal is invisible to it at any number of samples.
#
# This is the missing independent instrument, in the sanctioned home for one
# (CLAUDE.md INDEPENDENCE exception: verify.py / verify.c only, never a new file).
#
# INDEPENDENCE IS THE DELIVERABLE, NOT SPEED. This is written from the DEFINITION
# in lean/RecordConvention.lean --
#
#     repr(k) = the lexicographically least orientation completion of the
#               pair-order key k that satisfies the full constraint set
#               (slot 0 forced)
#
# -- not by transcribing solve.c's orb_recanon DFS. A fast reimplementation that
# borrowed solve.c's helpers, tables or search shape would not be a second
# opinion. Everything below is built on this file's own KW table, its own
# _partner()-derived PAIRS, and its own hamming().
#
# WHY GREEDY-0-FIRST IS EXACTLY LEX-LEAST. Record byte i is
# (pair_index << 2) | (orientation << 1). Given the key, pair_index is fixed at
# every slot, so at each slot the orient=0 byte is strictly less than the
# orient=1 byte, and record comparison is left-to-right. Hence the first
# complete valid assignment found by a DFS that tries 0 before 1 at every slot,
# in slot order, IS the lexicographic minimum. No search-order cleverness is
# involved and none is permitted -- that equivalence is the whole point.
# ---------------------------------------------------------------------------

def check_repr(path, count, offset=0):
    """Compare the artifact's stored orientations against this file's independent
    repr(k), record by record. Returns a process exit code.

    Verdicts are KEY=value so a harness can `grep -qx` them; a caller must never
    have to infer the result from output shape or from the exit code alone.

    SCOPE, STATED PLAINLY: this checks the records it reads and no others. It is
    a genuine second instrument -- it shares no code, table or search shape with
    solve.c -- but N records is N records. Do not report a sampled pass as
    whole-artifact agreement."""
    import gzip
    opener = gzip.open if path.endswith('.gz') or path.endswith('.bin') and _is_gzip(path) else open
    checked = agree = disagree = incomputable = 0
    try:
        with opener(path, 'rb') as fh:
            hdr = fh.read(SOL_HEADER_SIZE)
            if len(hdr) < SOL_HEADER_SIZE:
                print("CHECK_REPR=FAIL_short_header"); return 2
            fh.seek(SOL_HEADER_SIZE + offset * 32)
            while checked < count:
                rec = fh.read(32)
                if len(rec) < 32:
                    break
                pair_order = [(rec[i] >> 2) & 0x3F for i in range(32)]
                if any(p >= 32 for p in pair_order) or len(set(pair_order)) != 32:
                    print(f"CHECK_REPR=FAIL_malformed_key at record {offset + checked}")
                    return 2
                mine = repr_of_key(pair_order)
                checked += 1
                if mine is None:
                    incomputable += 1
                elif mine == rec:
                    agree += 1
                else:
                    disagree += 1
                    if disagree <= 3:      # show the first few, do not spam
                        print(f"  record {offset + checked - 1}: stored != independent repr")
    except OSError as e:
        print(f"CHECK_REPR=FAIL_io {e}"); return 2

    print(f"CHECKED={checked}")
    print(f"AGREE={agree}")
    print(f"DISAGREE={disagree}")
    print(f"INCOMPUTABLE={incomputable}")
    # Fail closed: an incomputable key is a finding too -- the artifact claims a
    # canonical record for a key this instrument says has no valid completion.
    if checked and disagree == 0 and incomputable == 0:
        print("CHECK_REPR=PASS")
        print("SCOPE=sampled_records_only_NOT_whole_artifact")
        return 0
    print("CHECK_REPR=FAIL")
    return 1


def check_artifact(path, count=-1, offset=0):
    """Validate what solutions.bin actually CLAIMS, record by record.

    WHY THIS AND NOT check_repr(). check_repr() asks whether the stored
    orientation is the global lex-least valid completion of the key. That IS the
    record convention -- forced by partition-invariance, and settled against the
    cell-scoped alternative -- but it is established by a POST-PASS, not by the
    merge: orb_normalize_rec_op -> orb_repr_global, exposed as
    `solve --kc-repr-normalize IN.bin OUT.bin`. Against a raw merge output that
    pass has not run, so check_repr() disagrees on exactly the records the
    post-pass would rewrite. Measured 2026-08-15 over 1,776,347,935 records: a
    regionally varying 1.06%-42.2%, INCOMPUTABLE=0 throughout. Expected, not a
    defect. check_repr() is the right acceptance test for the post-pass OUTPUT
    and the wrong instrument for its input.

    Do not mistake orb_recanon for the convention (a misreading made and
    retracted on 2026-08-15): it pins slots 0..3 from a member CELL's prefix and
    its only caller is orb_expand_record, for cell-faithful expansion shards.
    Cell-scoped visited-min was PROVEN INSUFFICIENT as a record representative --
    the merged cross-cell min moves with budget, breaking partition-invariance
    and record-level nesting.

    A second limitation survives normalization: check_repr() is structurally
    blind to a wrong pair sequence, since repr_of_key() is handed the key decoded
    from the very record it is compared against. This function is not.

    CHECKED HERE: (1) each record satisfies the constraint set -- the forced
    63->0 opening (C4), no HD-5 transition (C2), the C5 budget consumed EXACTLY,
    and the C3 complement-distance ceiling; (2) pair-order keys strictly
    increase, matching compare_solutions; (3) strictness in (2) IS the
    one-record-per-class dedup claim; (4) header conformance -- format version,
    the zero reserved field, and the declared count against the stream.

    (1) READ "each record's OWN ORIENTATIONS satisfy the constraint set" until
    2026-09-02. That was an overclaim in two directions at once: it promised the
    whole constraint set while C3 was absent, and the word "orientations" scoped
    the promise to a property C3 does not have. Both are now true as written --
    C3 landed with this revision -- but the wording was the thing that made the
    gap invisible, so it is corrected here rather than merely satisfied.

    SCOPE TOKEN, DELIBERATELY UNCHANGED. This mode still prints
    SCOPE=validity_sortedness_dedup_only_NOT_completeness. C3 and the header legs
    make the "validity" term MORE complete; they do not move the boundary the
    token actually draws, which is completeness -- that no valid solution is
    MISSING remains outside any single forward pass. Changing the string would
    break every `grep -qx` consumer to signal nothing.

    NOT CHECKED: completeness, as above; and the representative convention --
    whether a stored orientation is the class's global lex-least. That is
    --check-repr's job and it is deliberately NOT wired in here: solutions.bin is
    a PRE-normalization artifact and a raw merge output disagrees with the global
    representative on 1.06%-42.2% of records (measured 2026-08-15 over
    1,776,347,935). Folding that in would make this checker reject the project's
    own canonical artifacts.

    NOT CHECKED: completeness. That no valid solution is MISSING is the
    enumeration's claim, attested by the canonical sha -- a single forward pass
    over the file cannot establish it, and this must not be read as if it could.

    count < 0 means "to EOF". Verdicts are KEY=value for `grep -qx`."""
    import gzip
    opener = gzip.open if path.endswith('.gz') or (path.endswith('.bin') and _is_gzip(path)) else open
    budget0 = _c5_budget_from_kw()
    n = 0
    bad = dict(KEY=0, SPARE_BIT=0, OPENING=0, HD5=0, BUDGET=0, BUDGET_RESIDUE=0, ORDER=0,
               C3=0, HDR_VERSION=0, HDR_RESERVED=0, GEOMETRY=0)
    shown = 0
    prev = None
    try:
        with opener(path, 'rb') as fh:
            hdr = fh.read(SOL_HEADER_SIZE)
            if len(hdr) < SOL_HEADER_SIZE:
                print("ARTIFACT=FAIL_short_header"); return 2
            # Validate the magic. Without it a HEADERLESS file (a raw sub_*.bin
            # shard) has its first record silently eaten as "header" and this can
            # then report ARTIFACT=PASS on a file it never fully read -- the same
            # failure mode as applying solutions.bin's header convention to
            # headerless shards. Fail closed rather than auto-detect.
            if hdr[:4] != b'ROAE':
                print("ARTIFACT=FAIL_no_ROAE_header")
                print("  refusing: first 4 bytes are not 'ROAE'. A headerless shard would")
                print("  otherwise have its first record consumed as a header.")
                return 2
            # HEADER CONFORMANCE (added 2026-09-02; Codex V2-F48 #3 / V2-F58 #2).
            # Before this, the magic was the ONLY header field either checked --
            # the version and the declared count were never read and the reserved
            # field was never inspected, so a v2 header, a nonzero reserved byte
            # and a count that disagreed with the body all returned ARTIFACT=PASS.
            # SOLUTIONS_FORMAT.md makes version==1, a zero reserved field and an
            # accurate count normative; REBUILD_FROM_SPEC.md requires a conformant
            # reader to REJECT an unknown version. These are counters rather than
            # hard exits so that every record-level verdict below still prints:
            # a nonconformant header does not make the records unreadable, and an
            # operator is better served by both facts than by the first one alone.
            (hdr_version,) = struct.unpack("<I", hdr[4:8])
            if hdr_version != SOL_FORMAT_VERSION:
                bad['HDR_VERSION'] = 1
                print(f"  header: unsupported format version {hdr_version} "
                      f"(this reader knows version {SOL_FORMAT_VERSION})")
            if hdr[16:32] != b"\0" * 16:
                bad['HDR_RESERVED'] = 1
                print(f"  header: reserved bytes [16:32] are NONZERO ({hdr[16:32].hex()})")
            (hdr_declared,) = struct.unpack("<Q", hdr[8:16])
            fh.seek(SOL_HEADER_SIZE + offset * 32)
            while count < 0 or n < count:
                rec = fh.read(32)
                if len(rec) < 32:
                    # A TORN TRAILING RECORD IS A DEFECT, NOT AN END. This used to
                    # be a bare `break`, which silently discarded the partial tail
                    # and reported ARTIFACT=PASS over the records that happened to
                    # be whole -- while verify.c, on the same file, returned
                    # ARTIFACT=FAIL_partial_record rc=2. Two independent
                    # instruments that diverge on corrupt framing are not two
                    # instruments. verify.c fails closed here and is right to; this
                    # side now matches it, token for token.
                    if len(rec) > 0:
                        print("ARTIFACT=FAIL_partial_record"); return 2
                    break
                idx = offset + n
                n += 1
                pair_order = [(rec[i] >> 2) & 0x3F for i in range(32)]
                orient = [(rec[i] >> 1) & 1 for i in range(32)]
                bad['SPARE_BIT'] += sum(1 for i in range(32) if rec[i] & 1)
                if any(p >= 32 for p in pair_order) or len(set(pair_order)) != 32:
                    bad['KEY'] += 1
                    if shown < 5:
                        print(f"  record {idx}: key is not a permutation of 0..31"); shown += 1
                    continue

                # C3 (added 2026-09-02; Codex V2-F20 #1, corroborated V2-F58 #1).
                # SPECIFICATION.md's constraint set is C1-C5 and SOLUTIONS_FORMAT.md
                # states outright that "a re-implementation that omits C3 produces a
                # strict SUPERSET". This loop checked C4/C2/C5 and never computed C3,
                # so a record with cd = 1080 against the 776 ceiling was certified
                # ARTIFACT=PASS by BOTH implementations. The seven-negative controls
                # table could not catch it: a controls table exercises the counters
                # that exist and is blind, by construction, to a missing predicate.
                # Computed from the DECODED SEQUENCE, exactly as the records path
                # does -- not from the pair-order key via the 16+8*G identity, which
                # would import an algebraic result this instrument is meant to test
                # independently. (C3 is in fact orientation-invariant, so the two
                # agree; deriving it the long way keeps that a MEASUREMENT here
                # rather than an assumption.)
                seq = []
                for slot in range(32):
                    pa, pb = PAIRS[pair_order[slot]]
                    seq += [pb, pa] if orient[slot] else [pa, pb]
                if compute_comp_dist(seq) > KW_COMP_DIST:
                    bad['C3'] += 1
                    if shown < 5:
                        print(f"  record {idx}: complement distance "
                              f"{compute_comp_dist(seq)} > {KW_COMP_DIST} (C3)"); shown += 1

                ident = bytes(b & 0xFC for b in rec)
                if prev is not None and ident <= prev:
                    bad['ORDER'] += 1
                    if shown < 5:
                        why = "duplicate class" if ident == prev else "out of order"
                        print(f"  record {idx}: pair-order not strictly greater than predecessor ({why})")
                        shown += 1
                prev = ident

                budget = list(budget0)
                a0, b0 = PAIRS[pair_order[0]]
                f0, s0 = (b0, a0) if orient[0] else (a0, b0)
                if (f0, s0) != (63, 0):
                    bad['OPENING'] += 1
                    if shown < 5:
                        print(f"  record {idx}: opening is not the forced 63->0"); shown += 1
                    continue
                wd0 = hamming(63, 0)
                if budget[wd0] <= 0:
                    bad['BUDGET'] += 1
                    continue
                budget[wd0] -= 1
                last, fail = 0, False
                for slot in range(1, 32):
                    a, b = PAIRS[pair_order[slot]]
                    f, s = (b, a) if orient[slot] else (a, b)
                    bd = hamming(last, f)
                    if bd == 5:
                        bad['HD5'] += 1; fail = True
                        if shown < 5:
                            print(f"  record {idx}: HD-5 transition into slot {slot}"); shown += 1
                        break
                    if budget[bd] <= 0:
                        bad['BUDGET'] += 1; fail = True; break
                    budget[bd] -= 1
                    wd = hamming(f, s)
                    if budget[wd] <= 0:
                        bad['BUDGET'] += 1; fail = True; break
                    budget[wd] -= 1
                    last = s
                if fail:
                    continue
                # BUDGET_RESIDUE is a defensive guard that is STRUCTURALLY
                # UNREACHABLE, recorded as such rather than claimed as tested: the
                # budget totals 63 and a complete record consumes exactly
                # 1 + 31*2 = 63 units, so if every decrement above succeeded the
                # residue is necessarily zero. Kept to fail closed if a table change
                # ever breaks that identity. No negative control can exercise it.
                if any(v != 0 for v in budget):
                    bad['BUDGET_RESIDUE'] += 1
            # GEOMETRY: the declared record count must match the stream.
            # Only meaningful on a WHOLE-FILE read. Ignoring the count for loop
            # TERMINATION is a deliberate convention that makes the [N] [OFFSET]
            # sub-range form work -- but that explains not USING the count, never
            # not CHECKING it, so the default full pass compares them and a
            # sub-range invocation stays green. Measured on the logical (post-gunzip)
            # stream, so a .gz artifact is checked on its contents, not its
            # compressed size.
            if count < 0 and offset == 0 and n != hdr_declared:
                bad['GEOMETRY'] = 1
                print(f"  header declares {hdr_declared} records but the stream holds {n}")
    except OSError as e:
        print(f"ARTIFACT=FAIL_io {e}"); return 2

    print(f"RECORDS={n}")
    for k in ("KEY", "SPARE_BIT", "OPENING", "HD5", "BUDGET", "BUDGET_RESIDUE", "ORDER",
              "C3", "HDR_VERSION", "HDR_RESERVED", "GEOMETRY"):
        print(f"BAD_{k}={bad[k]}")
    if n and not any(bad.values()):
        print("ARTIFACT=PASS")
        print("SCOPE=validity_sortedness_dedup_only_NOT_completeness")
        return 0
    print("ARTIFACT=FAIL")
    return 1


# ---------------------------------------------------------------------------
# SHEN 1936 ORBIT CHECK  (--check-shen-orbits)  and  FLIP CENSUS (--check-flips)
#
# WHY THESE LIVE HERE. CITATIONS.md publishes two measured claims about Shen
# Youding's 1936 classification, and a published figure must not ship ahead of
# the means to reproduce it -- a private script does not make a public number
# reproducible. Both checks belong in verify.py rather than solve.py for the
# reason verify.py exists: the orbit claim is ABOUT orbit structure, and solve.c
# has orbit code, so a check that used it would not be independent. Nothing here
# imports from solve.c/solve.py/roae.py/sat.py; the trigram table below is the
# classical family doctrine, written out, and hexagram values are decomposed
# with this file's own bit conventions.
# ---------------------------------------------------------------------------

# Classical trigram doctrine. bit0 = bottom line (ROAE-native), so a trigram is
# three bits read bottom-up. rank = generational rank; gender = yang/yin.
_TRIGRAM = {
    0b111: ('乾', '老', 'yang'), 0b000: ('坤', '老', 'yin'),
    0b001: ('震', '长', 'yang'), 0b110: ('巽', '长', 'yin'),
    0b010: ('坎', '中', 'yang'), 0b101: ('离', '中', 'yin'),
    0b100: ('艮', '少', 'yang'), 0b011: ('兑', '少', 'yin'),
}
def _lower(h): return h & 0b111
def _upper(h): return (h >> 3) & 0b111
def _cuo(h):  return h ^ 0b111111                      # 错 complement
def _zong(h): return int(format(h, '06b')[::-1], 2)    # 综 reversal
def _hname(h): return _TRIGRAM[_upper(h)][0] + '/' + _TRIGRAM[_lower(h)][0]

def check_shen_orbits():
    """Verify the published claim that Shen Youding's (1936) six groups of
    principal hexagrams are EXACTLY the six K4 orbits of his sixteen.

    Shen's criterion (周易序卦骨构大意, 北京晨报 1936-05-06): a hexagram is 主卦
    (principal) iff its inner and outer trigrams share generational rank
    (老/长/中/少); the rest are 散卦. He states 主卦十有六 and 其余四十八卦皆散卦,
    grouped 总为六组.

    ATTRIBUTION -- THE ORBIT DECOMPOSITION IS WU CHENG'S, c.1300, AND IT IS
    COMPLETE. 吳澄 (1249-1333), 《易纂言外翼》卷一〈卦對第二〉, gives all 20 orbits of
    all 64 -- 「卦畫奇偶正對，二篇共二十對…正對不反易者四…正對兼反易者四…反易取正對者
    十二」 = 12 classes of four + 8 of two -- with his three classes matching the
    three stabiliser types exactly. 「反易取正對」 IS the composition of the two
    operations, and he defines 正對 at the LINE level (卦畫奇偶) while explicitly
    contrasting it with the TRIGRAM level (上下二體). Verified against this file's own
    bit operations: zero mismatches, all 64 covered once, class set identical to the
    true orbit set. See CITATIONS.md#wucheng and `--check-classical-groups`.

    The sixteen checked below are a SUBSET of that -- 6 of Wu Cheng's 20 orbits.

    THE SAME SIXTEEN AND THE SAME SIX GROUPS ARE ALSO CUI SHU'S, c.1800, reached
    independently -- creditably so, since 《易纂言外翼》 was lost after the Ming and
    only reconstructed from the 永樂大典 in 1781. Verified 2026-08-16 from the print
    (Kansai Univ. 内藤文庫 IIIF scan of 崔東壁先生遺書; ctext transcription agrees):
    崔述 (1740-1816), 〈易卦次圖說〉 in 《易卦圖說》, defines the two operations by
    LINE RULES -- 「何謂平對？陰陽之爻互易者也。何謂反對？上下之爻互易者也」, i.e.
    平對 = 錯 (invert all six lines) and 反對 = 綜 (turn the hexagram over) -- then
    forms the four-element sets and states their SIZES: 「兩體而四卦具焉」 against
    「兩卦仍為兩卦」. His diagram prints each hexagram's 反對 physically upside down.
    Shen knew: 「近讀崔東壁遺書易卦次圖說，乃與予說不謀而合」.

    WHY BOTH ARE NAMED, AND WHY THEIR STATUS DIFFERS. Shen's criterion is
    trigram-based (內外卦同序 / 類合 / 應合) and his text contains NO 錯/綜-type
    operation, so "these six groups are the six K4 orbits" is OUR observation about
    his classification. Cui states the operations himself, so for Cui the same
    sentence is much closer to his own claim. This function checks one arithmetic
    fact; the two attributions carry different weight, and conflating them would
    overstate Shen and understate Cui.

    NEITHER covers all 64: both stop at the sixteen, giving 6 of the 20 orbits.
    Cui never notices that 頤/大過, 中孚/小過, 隨/蠱 and 漸/歸妹 are size-2 orbits
    sitting inside his 散卦. See CITATIONS.md#cuishu and #shen1936.

    Verdicts are KEY=value for `grep -qx`."""
    zhu = [h for h in range(64)
           if _TRIGRAM[_lower(h)][1] == _TRIGRAM[_upper(h)][1]]
    leihe  = [h for h in zhu if _TRIGRAM[_lower(h)][2] == _TRIGRAM[_upper(h)][2]]
    yinghe = [h for h in zhu if _TRIGRAM[_lower(h)][2] != _TRIGRAM[_upper(h)][2]]
    print("ZHU=%d" % len(zhu))
    print("LEIHE=%d" % len(leihe))     # 类合 — the eight doubled trigrams
    print("YINGHE=%d" % len(yinghe))   # 应合 — the eight rank-partner pairs
    print("SAN=%d" % (64 - len(zhu)))  # 散卦

    Z = set(zhu)
    closed_cuo  = all(_cuo(h)  in Z for h in zhu)
    closed_zong = all(_zong(h) in Z for h in zhu)
    print("CLOSED_UNDER_CUO=%s"  % ("yes" if closed_cuo  else "no"))
    print("CLOSED_UNDER_ZONG=%s" % ("yes" if closed_zong else "no"))

    orbits = sorted({frozenset({h, _cuo(h), _zong(h), _cuo(_zong(h))}) for h in zhu},
                    key=lambda o: (len(o), min(o)))
    print("ORBITS=%d" % len(orbits))
    print("ORBIT_SIZES=%s" % ','.join(str(len(o)) for o in orbits))
    for o in orbits:
        print("  orbit(%d): %s" % (len(o), ' '.join(sorted(_hname(x) for x in o))))

    # Shen's six groups, as he names them.
    T = {n: b for b, (n, _, _) in _TRIGRAM.items()}
    def hx(lo, up): return T[lo] | (T[up] << 3)
    groups = {
        '乾坤':     {hx('乾','乾'), hx('坤','坤')},
        '泰否':     {hx('乾','坤'), hx('坤','乾')},
        '坎离':     {hx('坎','坎'), hx('离','离')},
        '既未济':   {hx('离','坎'), hx('坎','离')},
        '震艮巽兑': {hx('震','震'), hx('艮','艮'), hx('巽','巽'), hx('兑','兑')},
        '咸恒损益': {hx('艮','兑'), hx('巽','震'), hx('兑','艮'), hx('震','巽')},
    }
    oset = {frozenset(o) for o in orbits}
    every = all(frozenset(g) in oset for g in groups.values())
    union_ok = set().union(*groups.values()) == Z
    print("GROUPS=%d" % len(groups))
    print("EVERY_GROUP_IS_AN_ORBIT=%s" % ("yes" if every else "no"))
    print("GROUPS_UNION_EQUALS_ZHU=%s" % ("yes" if union_ok else "no"))

    ok = (len(zhu) == 16 and len(leihe) == 8 and len(yinghe) == 8
          and closed_cuo and closed_zong and len(orbits) == 6
          and sorted(len(o) for o in orbits) == [2, 2, 2, 2, 4, 4]
          and every and union_ok and len(groups) == len(orbits))
    print("SHEN_ORBITS=PASS" if ok else "SHEN_ORBITS=FAIL")
    print("SCOPE=Shen's_criterion_is_KW_INDEPENDENT;_this_verifies_a_classification,_not_an_ordering_claim")
    return 0 if ok else 1


def check_flips():
    """Census of the 31 single-orientation-bit flips of King Wen's own record,
    classified by how each fails --check-artifact.

    Reproduces the figure published in VERIFY.md. That figure first read "16
    validate", computed as 31-15 on the assumption that BAD_BUDGET was the only
    failure mode; the measuring harness grepped `^BAD_[A-Z_]+=[1-9]`, whose
    character class excludes DIGITS, so BAD_HD5 never matched. Shipping the
    census removes the need to trust any such grep."""
    budget0 = _c5_budget_from_kw()
    base = repr_of_key(list(range(32)))
    if base is None:
        print("FLIPS=FAIL_no_kw_record"); return 2

    def classify(rec):
        key    = [(rec[i] >> 2) & 0x3F for i in range(32)]
        orient = [(rec[i] >> 1) & 1 for i in range(32)]
        if any(b & 1 for b in rec):                   return 'BAD_SPARE_BIT'
        if len(set(key)) != 32 or any(p >= 32 for p in key): return 'BAD_KEY'
        budget = list(budget0)
        a0, b0 = PAIRS[key[0]]
        f0, s0 = (b0, a0) if orient[0] else (a0, b0)
        if (f0, s0) != (63, 0):                       return 'BAD_OPENING'
        budget[hamming(63, 0)] -= 1
        last = 0
        for slot in range(1, 32):
            a, b = PAIRS[key[slot]]
            f, s = (b, a) if orient[slot] else (a, b)
            bd = hamming(last, f)
            if bd == 5:                               return 'BAD_HD5'
            if budget[bd] <= 0:                       return 'BAD_BUDGET'
            budget[bd] -= 1
            wd = hamming(f, s)
            if budget[wd] <= 0:                       return 'BAD_BUDGET'
            budget[wd] -= 1
            last = s
        return 'PASS' if all(v == 0 for v in budget) else 'BAD_BUDGET_RESIDUE'

    from collections import Counter
    tally = Counter()
    for i in range(1, 32):          # slot 0's orientation is forced by C4
        t = bytearray(base); t[i] ^= 0x02
        tally[classify(bytes(t))] += 1
    print("FLIPS_TESTED=%d" % sum(tally.values()))
    for k in ('PASS', 'BAD_BUDGET', 'BAD_HD5', 'BAD_KEY', 'BAD_OPENING',
              'BAD_SPARE_BIT', 'BAD_BUDGET_RESIDUE'):
        print("%s=%d" % (k, tally.get(k, 0)))
    print("FLIPS=DONE")
    print("SCOPE=a_pair_order_key_admits_MANY_valid_orientation_completions;"
          "_which_one_a_record_carries_is_a_convention_choice")
    return 0


def check_parity_alternation():
    """Re-derive every published figure in PARITY_ALTERNATION.md from KW itself.

    WHY THIS EXISTS. That document is listed in CLAUDE.md as a stable, paper-citable
    finding, and it published its central figures -- the forced 15 alternations and the
    82,818,450 / 601,080,390 arrangement reduction -- with NO reproduction command.
    A reviewer had no way to re-derive them. GATE 25 LEG 2 flagged the file on
    2026-08-16 and this is the answer to that flag.

    Lemma 3 of that document: a pair's parity class is the popcount parity of either
    member, because reversal preserves popcount and complement maps p -> 6-p (same
    parity). So the class is well defined per pair, which this check confirms rather
    than assumes.

    The arrangement count is computed TWICE by different routes that share no code
    path: a dynamic program over (position, evens used, last class, changes so far),
    and the closed form 2*C(15,7)^2 that follows from 15 changes meaning 16 alternating
    runs, 8 per class, each class composed into 8 positive parts. They must agree.
    The DP is the instrument; the closed form is the check on the instrument.

    SCOPE: this attests the FIGURES in PARITY_ALTERNATION.md. The theorem itself
    ("every C1-C5-valid ordering has exactly 15 alternations") is a proof, not a
    measurement, and is not re-proven here -- what is checked is that King Wen
    exhibits it and that the arrangement arithmetic is right.

    Reads no files."""
    from math import comb
    from collections import Counter

    # -- the 63 transition distances of King Wen, and their parity ------------
    dists = [hamming(KW[i], KW[i + 1]) for i in range(63)]
    multiset = dict(sorted(Counter(dists).items()))
    PUBLISHED = {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}
    n_odd = sum(1 for d in dists if d % 2)
    print("KW_TRANSITIONS=%d" % len(dists))
    print("KW_DISTANCE_MULTISET=%s" % (multiset,))
    print("KW_DISTANCE_MULTISET_MATCHES_PUBLISHED=%s"
          % ("yes" if multiset == PUBLISHED else "NO"))
    print("KW_ODD_TRANSITIONS=%d" % n_odd)

    # -- pair classes: well defined, and 16/16 as C(32,16) presupposes --------
    pairs = [(KW[2 * i], KW[2 * i + 1]) for i in range(32)]
    well_defined = all(bin(a).count("1") % 2 == bin(b).count("1") % 2 for a, b in pairs)
    cls = [bin(a).count("1") % 2 for a, _ in pairs]
    print("PAIR_CLASS_WELL_DEFINED=%s" % ("yes" if well_defined else "NO"))
    print("PAIR_CLASS_SPLIT=even=%d,odd=%d" % (cls.count(0), cls.count(1)))
    print("PAIR_CLASS_SPLIT_IS_16_16=%s"
          % ("yes" if cls.count(0) == 16 and cls.count(1) == 16 else "NO"))

    kw_alts = sum(1 for i in range(31) if cls[i] != cls[i + 1])
    print("KW_CLASS_ALTERNATIONS=%d" % kw_alts)
    print("KW_HAS_THE_FORCED_15=%s" % ("yes" if kw_alts == 15 else "NO"))
    print("KW_ODD_TRANSITIONS_EQUALS_ALTERNATIONS=%s"
          % ("yes" if n_odd == kw_alts else "NO"))
    print("C4_PINS_FIRST_PAIR_TO_EVEN_CLASS=%s"
          % ("yes" if cls[0] == 0 and set(pairs[0]) == {63, 0} else "NO"))

    # -- arrangements with exactly 15 changes: DP, then the closed form -------
    # state: (evens placed, odds placed, last class, changes) -> count
    dp = {(1, 0, 0, 0): 1, (0, 1, 1, 0): 1}
    for _ in range(31):
        nxt = {}
        for (e, o, last, ch), v in dp.items():
            for c in (0, 1):
                ne, no = e + (c == 0), o + (c == 1)
                if ne > 16 or no > 16:
                    continue
                nch = ch + (c != last)
                if nch > 15:
                    continue
                k = (ne, no, c, nch)
                nxt[k] = nxt.get(k, 0) + v
        dp = nxt
    dp_count = sum(v for (e, o, _, ch), v in dp.items() if e == 16 and o == 16 and ch == 15)
    closed = 2 * comb(15, 7) ** 2
    total = comb(32, 16)
    print("ARRANGEMENTS_15_CHANGES_DP=%d" % dp_count)
    print("ARRANGEMENTS_15_CHANGES_CLOSED_FORM=%d" % closed)
    print("DP_AGREES_WITH_CLOSED_FORM=%s" % ("yes" if dp_count == closed else "NO"))
    print("TOTAL_ARRANGEMENTS_C32_16=%d" % total)
    print("REDUCTION_FACTOR=%.4f" % (total / dp_count))

    ok = (multiset == PUBLISHED and well_defined and cls.count(0) == 16
          and kw_alts == 15 and n_odd == 15 and cls[0] == 0
          and dp_count == closed == 82818450 and total == 601080390)
    print("PARITY_ALTERNATION=%s" % ("PASS" if ok else "FAIL"))
    print("SCOPE=re-derives_the_FIGURES_in_PARITY_ALTERNATION.md_from_KW;"
          "_the_theorem_is_a_proof_and_is_not_re-proven_here")
    return 0 if ok else 1


def check_zhu_yuansheng():
    """Verify 朱元昇's twelve quadruples against this file's own bit operations.

    WHY THIS EXISTS. On 2026-08-16 the complete <complement, reversal> orbit
    decomposition of all 64 was ceded to 朱元昇 (d. c.1273), 《三易備遺》卷八,
    complete by 1270 -- roughly forty years before 吳澄, to whom it had been ceded
    the same morning. A cession that deep must be checkable by a reader, not taken
    on the word of whoever read the text. CITATIONS.md#zhuyuansheng

    WHAT HE WROTE. He isolates the sixteen hexagrams whose 先天 (complement) and
    後天 (King Wen textual) pairings coincide, asks 「餘四十八卦之對不同，何也？」,
    and answers with twelve groups, each stated under BOTH operations at once:

        「先天屯對鼎、蒙對革；後天屯對蒙、鼎對革」  ... and so on, twelve times.

    then the degeneracy split:

        「至於乾坤頤大過中孚小過坎離八卦，不可得而反對；
          泰否隨蠱漸歸妹既濟未濟八卦，可得而反對，亦可得而變對；總十六卦。」

    WHAT THIS CHECKS. His text is transcribed below as KING WEN NUMBERS, exactly as
    he pairs them -- the 先天 pairs and the 後天 pairs kept SEPARATE, so each half of
    each line is tested on its own:
      * every 先天 pair he states is a true COMPLEMENT pair under _cuo
      * every 後天 pair he states is a true REVERSAL pair under _zong
      * his 48 quadruple members are disjoint from his 16 coincident hexagrams
      * 12x4 + 8x2 = 64, covering every hexagram exactly once
      * his eight 不可得而反對 are exactly the self-reverse hexagrams
      * his eight 可得而反對亦可得而變對 are exactly those where complement == reversal
      * his twelve quadruples ARE the size-4 orbits of <complement, reversal>

    A failure here means either the transcription is wrong or the cession is wrong.
    Both are worth knowing, which is the point of shipping it as a command.

    SCOPE: this attests a 13th-century READING. It changes no enumeration and no
    published count of this project's own.

    Reads no files. Uses only this file's KW array and bit conventions."""
    # 朱元昇《三易備遺》卷八 -- (label, 先天/complement pairs, 後天/reversal pairs)
    QUADS = [
        ("屯蒙鼎革",     [(3, 50), (4, 49)],  [(3, 4),   (50, 49)]),
        ("需訟晉明夷",   [(5, 35), (6, 36)],  [(5, 6),   (35, 36)]),
        ("師比同人大有", [(7, 13), (8, 14)],  [(7, 8),   (13, 14)]),
        ("小畜履豫謙",   [(9, 16), (10, 15)], [(9, 10),  (16, 15)]),
        ("臨觀遯大壯",   [(19, 33), (20, 34)],[(19, 20), (33, 34)]),
        ("噬嗑賁井困",   [(21, 48), (22, 47)],[(21, 22), (48, 47)]),
        ("剝復夬姤",     [(23, 43), (24, 44)],[(23, 24), (43, 44)]),
        ("无妄大畜升萃", [(25, 46), (26, 45)],[(25, 26), (46, 45)]),
        ("咸恒損益",     [(31, 41), (32, 42)],[(31, 32), (41, 42)]),
        ("家人睽解蹇",   [(37, 40), (38, 39)],[(37, 38), (40, 39)]),
        ("震艮巽兌",     [(51, 57), (52, 58)],[(51, 52), (57, 58)]),
        ("豐旅渙節",     [(55, 59), (56, 60)],[(55, 56), (59, 60)]),
    ]
    NO_REV   = [1, 2, 27, 28, 61, 62, 29, 30]      # 不可得而反對
    BOTH     = [11, 12, 17, 18, 53, 54, 63, 64]    # 可得而反對，亦可得而變對

    def hx(n):                      # King Wen number (1-based) -> binary value
        return KW[n - 1]

    bad_comp = [(lab, a, b) for lab, cp, _ in QUADS for (a, b) in cp
                if _cuo(hx(a)) != hx(b)]
    bad_rev  = [(lab, a, b) for lab, _, rp in QUADS for (a, b) in rp
                if _zong(hx(a)) != hx(b)]
    print("ZHU_XIANTIAN_PAIRS_ARE_COMPLEMENT=%d/24%s"
          % (24 - len(bad_comp), "" if not bad_comp else "  MISMATCH:%s" % (bad_comp,)))
    print("ZHU_HOUTIAN_PAIRS_ARE_REVERSAL=%d/24%s"
          % (24 - len(bad_rev), "" if not bad_rev else "  MISMATCH:%s" % (bad_rev,)))

    quad_members = set()
    for _, cp, rp in QUADS:
        for a, b in cp + rp:
            quad_members.add(a); quad_members.add(b)
    coincident = set(NO_REV) | set(BOTH)
    print("ZHU_QUAD_MEMBERS=%d" % len(quad_members))
    print("ZHU_COINCIDENT=%d" % len(coincident))
    print("ZHU_DISJOINT=%s" % ("yes" if not (quad_members & coincident) else "NO"))
    print("ZHU_COVERS_ALL_64=%s"
          % ("yes" if len(quad_members | coincident) == 64 else "NO"))
    print("ZHU_ARITHMETIC=12x4+8x2=%d" % (len(quad_members) + len(coincident)))

    nr_ok = all(_zong(hx(n)) == hx(n) for n in NO_REV)
    bo_ok = all(_cuo(hx(n)) == _zong(hx(n)) and _zong(hx(n)) != hx(n) for n in BOTH)
    print("ZHU_NO_REVERSAL_CLASS_IS_SELF_REVERSE=%s" % ("yes" if nr_ok else "NO"))
    print("ZHU_BOTH_CLASS_HAS_COMP_EQUALS_REV=%s"   % ("yes" if bo_ok else "NO"))

    # his twelve == the true size-4 orbits of <complement, reversal>
    seen, true4 = set(), []
    for h in KW:
        if h in seen:
            continue
        cl = {h}
        while True:
            nxt = cl | {f(x) for x in cl for f in (_cuo, _zong)}
            if nxt == cl:
                break
            cl = nxt
        seen |= cl
        if len(cl) == 4:
            true4.append(frozenset(cl))
    zhu4 = []
    for _, cp, rp in QUADS:
        s = set()
        for a, b in cp + rp:
            s.add(hx(a)); s.add(hx(b))
        zhu4.append(frozenset(s))
    print("ZHU_QUADS_ARE_THE_SIZE4_ORBITS=%s"
          % ("yes" if set(zhu4) == set(true4) else "NO"))

    ok = (not bad_comp and not bad_rev and nr_ok and bo_ok
          and set(zhu4) == set(true4)
          and not (quad_members & coincident)
          and len(quad_members | coincident) == 64)
    print("ZHU_YUANSHENG=%s" % ("PASS" if ok else "FAIL"))
    print("SCOPE=this_attests_a_13th_century_READING;"
          "_it_changes_no_enumeration_and_no_published_count_of_ours")
    return 0 if ok else 1


def check_classical_groups():
    """Report the group actions on the 64 hexagrams that the CLASSICAL Chinese
    literature actually attests, and how King Wen scores against each.

    WHY THIS EXISTS. The obvious deflation of a pairing constraint is "of course a
    symmetric arrangement satisfies some symmetry -- you went looking for a group
    and found one that fits." This answers that with a measurement, using rival
    groups WE DID NOT INVENT: every one below is taken from a classical source.

    THE SOURCES, none of them ours:
      * <comp, rev>  -- 吳澄 Wu Cheng (1249-1333), 《易纂言外翼》卷一〈卦對第二〉.
        The complete decomposition: 「卦畫奇偶正對，二篇共二十對」. CITATIONS.md#wucheng
      * <rev, swap>  -- 吳澄, THE SAME CHAPTER: 「卦體上下互易，二篇共十八對…純卦八…
        不與」, where swap exchanges the upper and lower trigrams.
      * <comp, swap> -- 焦循 Jiao Xun (1763-1820), 《易圖略》卷四 八卦相錯圖, an
        exhaustive partition of the 64 built from 說卦傳's 八卦相錯. CITATIONS.md#jiaoxun
      * the pairing rule itself is 孔穎達 (574-648), 非覆即變. CITATIONS.md#kongyingda

    THE RESULT THIS PRINTS. <comp,swap> has the SAME orbit profile as <comp,rev> --
    20 orbits, 8 of size 2 and 12 of size 4 -- yet King Wen seats partners adjacently
    64/64 under <comp,rev> and only 24/64 under <comp,swap>. Two structurally
    indistinguishable group actions, both classically attested, and the received
    sequence selects one decisively. That is a property of the sequence, not an
    artifact of looking for symmetry.

    It also re-derives 吳澄's OWN second count as a reading check: he says the
    <rev,swap> structure gives 「共十八對」 once the 八純卦 are set aside, and the
    computation returns 24 orbits minus the 6 meeting those eight = 18.

    SCOPE: this is a fact about King Wen's PAIRING. It changes no enumeration and no
    published count. It strengthens the constraint's motivation, not the result.

    Reads no files. Uses only this file's KW array and bit conventions."""
    def _swap(h):                      # 上下互易 -- exchange upper and lower trigrams
        return ((h >> 3) & 0b111) | ((h & 0b111) << 3)
    pos = {h: i for i, h in enumerate(KW)}

    def _orbits(gens):
        seen, out = set(), []
        for h in KW:
            if h in seen:
                continue
            cl = {h}
            while True:
                nxt = cl | {g(x) for x in cl for g in gens}
                if nxt == cl:
                    break
                cl = nxt
            seen |= cl
            out.append(frozenset(cl))
        return out

    GROUPS = [
        ("comp_rev",  "<comp,rev>  Wu Cheng c.1300",   [_cuo, _zong]),
        ("rev_swap",  "<rev,swap>  Wu Cheng, same ch", [_zong, _swap]),
        ("comp_swap", "<comp,swap> Jiao Xun c.1813",   [_cuo, _swap]),
    ]
    for key, label, gens in GROUPS:
        orbs = _orbits(gens)
        sizes = {}
        for c in orbs:
            sizes[len(c)] = sizes.get(len(c), 0) + 1
        # Does King Wen seat each hexagram beside a partner from its own orbit?
        adj = sum(1 for h in KW
                  if any(pos[g(h)] // 2 == pos[h] // 2 and g(h) != h for g in gens))
        print("%s_ORBITS=%d" % (key.upper(), len(orbs)))
        print("%s_SIZES=%s" % (key.upper(),
              ",".join("%dx%d" % (n, s) for s, n in sorted(sizes.items()))))
        print("%s_KW_ADJACENT=%d/64" % (key.upper(), adj))

    # ---- the sharper test: at the PAIRING-RULE level, not the group level -------
    # A group tells you which hexagrams are related; a PAIRING RULE tells you which
    # single partner each hexagram gets. C1 is the second kind, so this is the
    # comparison a referee actually wants.
    def _rule(primary, fallback=None):
        n = 0
        for h in KW:
            p = primary(h)
            if p == h and fallback is not None:
                p = fallback(h)
            if p != h and pos[p] // 2 == pos[h] // 2:
                n += 1
        return n
    RULES = [
        ("rev_then_comp", "rev, falling back to comp  [= C1, 非覆即變]", _zong, _cuo),
        ("comp_alone",    "comp alone",                                 _cuo,  None),
        ("rev_alone",     "rev alone",                                  _zong, None),
        ("swap_then_comp","swap, falling back to comp",                 _swap, _cuo),
        ("swap_alone",    "swap alone",                                 _swap, None),
        ("comp_of_rev",   "comp of rev, falling back to comp",
                          (lambda h: _cuo(_zong(h))), _cuo),
    ]
    for key, _label, prim, fb in RULES:
        print("RULE_%s=%d/64" % (key.upper(), _rule(prim, fb)))

    # HOW SPECIAL IS THAT? Not a sample -- the EXACT count, in closed form.
    #
    # An earlier version of this check sampled 20,000 random involutions and
    # reported the best score. That was a correct but very weak shadow of the real
    # answer, and it invited the reader to wonder about the unsampled remainder.
    # There is no remainder to wonder about: the count is exact.
    #
    # THE ARGUMENT. To score 64/64 an involution must send every NON-fixed hexagram
    # to its King Wen neighbour -- so off its fixed set it is FORCED to equal the
    # King Wen pairing. A fixed point contributes only if its COMPLEMENT is its King
    # Wen neighbour, and the fixed set must be a union of whole King Wen pairs (an
    # odd leftover cannot be matched). So the only freedom is WHICH eligible pairs
    # are called fixed.
    #
    # AND THE ELIGIBLE SET IS EXACTLY WU CHENG'S TWO DEGENERATE CLASSES (c. 1300):
    # the 8 self-reverse hexagrams (his 正對不反易者四) plus the 8 where complement
    # coincides with reversal (his 正對兼反易者四). His classification is not
    # decorative -- it precisely characterises where the ambiguity lives.
    from math import comb, factorial
    partner = {h: KW[pos[h] ^ 1] for h in KW}
    elig = [h for h in KW if partner[h] == _cuo(h)]
    elig_pairs = {frozenset((h, partner[h])) for h in elig}
    selfrev = {h for h in KW if _zong(h) == h}
    cuo_is_zong = {h for h in KW if _cuo(h) == _zong(h)}
    # size of the space we are choosing from: involutions on 64 with 8 fixed points
    dbl = 1
    for k in range(55, 0, -2):
        dbl *= k                                   # 55!! matchings on the other 56
    space = comb(64, 8) * dbl
    exact = comb(len(elig_pairs), 4)               # choose 4 of the eligible pairs
    print("SPACE_INVOLUTIONS_8_FIXED=%.4e" % space)
    print("ELIGIBLE_FIXED_HEXAGRAMS=%d" % len(elig))
    print("ELIGIBLE_IS_WUCHENG_DEGENERATE_CLASSES=%s"
          % ("yes" if set(elig) == selfrev | cuo_is_zong else "NO"))
    print("EXACT_INVOLUTIONS_SCORING_64=%d" % exact)
    print("EXACT_FRACTION=%.3e" % (exact / space))
    # every one of them is reversal off the degenerate part -- verify, do not assert
    core = [h for h in KW if h not in elig]
    print("ALL_AGREE_WITH_REV_ON_NONDEGENERATE=%s"
          % ("yes" if all(partner[h] == _zong(h) for h in core) else "NO"))
    print("SCOPE_UNIQUENESS=the_%d_are_ONE_rule_under_%d_labellings;"
          "_fixed_vs_swapped_is_VACUOUS_exactly_where_the_two_operations_coincide"
          % (exact, exact))

    # 吳澄's own second count, as a check that we are reading his chapter correctly.
    orbs = _orbits([_zong, _swap])
    pure = {0b111111, 0b000000, 0b010010, 0b101101,
            0b001001, 0b110110, 0b100100, 0b011011}   # the 八純卦 (doubled trigrams)
    meeting = sum(1 for c in orbs if c & pure)
    print("WUCHENG_SECOND_COUNT=%d" % (len(orbs) - meeting))
    print("WUCHENG_SECOND_COUNT_MATCHES_TEXT=%s"
          % ("yes" if len(orbs) - meeting == 18 else "NO"))
    # 焦循 Jiao Xun (1763-1820) 《易圖略》卷六〈原序第三〉:
    #   「反對旁通四卦交互，如九數之維乘」 -- reversal and complementation, four hexagrams
    # interlocking -- followed by five WORKED quadruples. CITATIONS.md#jiaoxun asserts all five
    # are exact <comp,rev> orbits; that assertion is checked here rather than asserted.
    # NOTE this does NOT make him a classifier: he gives instances, no line-rule, no census.
    JIAO_QUADS = [(3, 4, 50, 49), (55, 56, 60, 59), (22, 21, 47, 48),
                  (39, 40, 38, 37), (9, 10, 15, 16)]
    orb4 = {frozenset(c) for c in _orbits([_cuo, _zong])}
    jq = [frozenset(KW[n - 1] for n in q) for q in JIAO_QUADS]
    jq_ok = sum(1 for s in jq if s in orb4)
    print("JIAOXUN_WORKED_QUADRUPLES_ARE_EXACT_ORBITS=%d/5" % jq_ok)

    # The three-generator group <complement, reverse, trigram-swap>. Whalen (1998)'s
    # "families of derivation" appendix is a correct orbit decomposition under exactly this
    # group; CITATIONS.md records "14 orbits, machine-verified, zero errors" and this is the
    # command behind that number. Reception history for TR-8 -- NOT prior art for any result.
    orb3 = _orbits([_cuo, _zong, _swap])
    prof3 = sorted(len(c) for c in orb3)
    print("THREE_GENERATOR_ORBITS=%d" % len(orb3))
    print("THREE_GENERATOR_ORBITS_MATCHES_PUBLISHED_14=%s"
          % ("yes" if len(orb3) == 14 else "NO"))
    print("THREE_GENERATOR_SIZE_PROFILE=%s" % (prof3,))
    print("THREE_GENERATOR_COVERS_ALL_64=%s"
          % ("yes" if sum(prof3) == 64 else "NO"))

    print("CLASSICAL_GROUPS=DONE")
    print("SCOPE=a_rival_group_with_an_IDENTICAL_orbit_profile_does_NOT_fit_king_wen;"
          "_this_is_about_PAIRING,_not_about_any_published_count")
    return 0


def check_kw_pair_adjacency():
    """Check that King Wen seats every hexagram beside its own partner -- and
    draw the consequence, which is a NEGATIVE result about what excavated
    symbol data can ever show.

    ATTRIBUTION -- none of the structural facts below are ours.

      * The pairing rule itself (hexagrams run two-by-two, each with its
        reversal, or its complement where the hexagram is reversal-symmetric)
        is CLASSICAL: 非覆即变, stated explicitly by Kong Yingda 孔颖达
        (574-648) in the Zhouyi zhengyi, with earlier lineage through Yu Fan
        虞翻 (164-233). See CITATIONS.md#kongyingda and #yufan. The PASS this
        function prints is a re-verification of a 7th-century observation, NOT
        a discovery -- it exists so a reader can confirm the premise of the
        argument without taking anyone's word for it.

      * The claim being tested is Pu Maozuo's 濮茅左. In 附錄二 of 馬承源 ed.,
        《上海博物館藏戰國楚竹書（三）》 (Shanghai Guji, 2003), pp. 251-260, he
        argues the manuscript's head/tail symbols (首符/尾符) are invariant
        under 综, and gives the 24+4+4 pair partition of the 64. The
        observed-symbol data used below is his, from the per-slip 释文考释,
        pp. 136-215. See CITATIONS.md#pu2003.

      * The nearest related construction is Kondo Hiroyuki 近藤浩之 (2005),
        which quotients the 64 to 36 by 覆 (= 综) pairs alone and partitions
        those into nine 宮 of four. See CITATIONS.md#kondo2005.

      * What is ours is only the OBSERVATION that these two facts, combined,
        make the symbol evidence non-discriminating -- and the decision to
        report that rather than the 9/9 agreement alone.

    Tested on the symbols Pu reports as DIRECTLY OBSERVED -- excluding every
    entry his appendix reconstructs FROM that same invariance -- his claim
    holds: 9 testable pairs, 9 agreements, 0 disagreements.

    That result cannot support any inference about ordering, and this check says
    why in a form a reader can run. In King Wen EVERY adjacent pair (positions
    2k-1, 2k) is a partner pair: reversal where the hexagram is not
    reversal-symmetric, complement for the eight that are. So a symbol that
    agrees within each King Wen adjacent pair is EQUALLY well explained by
      H1  the symbol respects reversal, and
      H2  the symbol is merely constant on contiguous blocks of King Wen.
    H1 and H2 make identical predictions on every observation available, because
    the blocks and the orbits coincide by construction of the sequence itself.

    Discriminating would require the symbols mapped onto an ordering in which
    partners are NOT adjacent. The only candidate is the bamboo manuscript's own
    order -- and its editor states plainly (p. 135) that he arranged the slips
    by the received sequence because the manuscript is incomplete. So the
    discriminating experiment does not exist. This is an impossibility argument,
    not a failed search.

    Reads no files. Uses only this file's KW array and bit conventions."""
    n_zong = n_cuo = n_bad = 0
    for (a, b) in PAIRS:
        if _zong(a) == b and a != b:
            n_zong += 1
        elif _cuo(a) == b:
            n_cuo += 1
        else:
            n_bad += 1
    print("KW_PAIRS=%d" % len(PAIRS))
    print("PAIRS_BY_REVERSAL=%d" % n_zong)
    print("PAIRS_BY_COMPLEMENT=%d" % n_cuo)
    print("PAIRS_UNRELATED=%d" % n_bad)
    # Every hexagram's partner sits in the SAME King Wen adjacent pair.
    pos = {h: i for i, h in enumerate(KW)}
    not_adjacent = 0
    for h in KW:
        p = _zong(h) if _zong(h) != h else _cuo(h)
        if pos[h] // 2 != pos[p] // 2:
            not_adjacent += 1
    print("HEXAGRAMS_WHOSE_PARTNER_IS_NOT_ADJACENT=%d" % not_adjacent)
    adjacency = (n_bad == 0 and not_adjacent == 0)
    print("KW_PARTNER_ADJACENCY=%s" % ("PASS" if adjacency else "FAIL"))

    # The Shanghai Museum observed-symbol pairs, by King Wen number. Source: the
    # per-slip 释文考释 ONLY (Pu Maozuo 2003, pp. 136-215), which reports symbols
    # as physically present or explicitly lost and never supplies one by
    # argument. Appendix 2's reconstructed entries are deliberately excluded --
    # using them would test the invariance against itself.
    SHANGBO_OBSERVED_PAIRS = [(5, 6), (7, 8), (15, 16), (17, 18), (25, 26),
                              (31, 32), (39, 40), (47, 48), (55, 56)]
    discriminating = [(a, b) for (a, b) in SHANGBO_OBSERVED_PAIRS
                      if abs(a - b) != 1 or (a - 1) // 2 != (b - 1) // 2]
    print("SHANGBO_TESTABLE_PAIRS=%d" % len(SHANGBO_OBSERVED_PAIRS))
    print("SHANGBO_DISCRIMINATING_PAIRS=%d" % len(discriminating))
    print("KW_PAIR_ADJACENCY=DONE")
    print("SCOPE=this_shows_the_shangbo_symbol_data_CANNOT_distinguish_"
          "reversal_invariance_from_king_wen_block_constancy;"
          "_it_is_NOT_a_claim_that_the_editors_invariance_is_false")
    return 0 if adjacency else 2


def _is_gzip(path):
    try:
        with open(path, 'rb') as fh:
            return fh.read(2) == b'\x1f\x8b'
    except OSError:
        return False


def _c5_budget_from_kw():
    """The C5 transition budget, re-derived HERE from this file's KW table.

    63 transitions over 64 hexagrams; the multiset of their Hamming distances is
    the budget. Asserted against the published value so a corrupted KW table
    fails loudly rather than silently redefining the constraint."""
    budget = [0] * 7
    for i in range(63):
        budget[hamming(KW[i], KW[i + 1])] += 1
    if not (budget == [0, 2, 20, 13, 19, 0, 9]):
        raise AssertionError(f"KW budget mismatch: {budget}")
    return budget


def repr_of_key(pair_order):
    """Independent repr(k). `pair_order` is 32 pair indices, slot order.

    Returns the 32-byte lexicographically least valid record, or None if the key
    admits no valid completion.

    Constraints applied, from SPECIFICATION.md rather than from solve.c:
      * C4  -- slot 0 is the forced (63, 0) start, so its orientation is fixed.
      * C2  -- no adjacent transition may have Hamming distance 5.
      * C5  -- the combined 63-transition multiset (every within-pair and every
               between-pair transition) must match the KW-derived budget.
      * C3  -- the complement distance ceiling (added 2026-09-02; see below).
    Budget totals 63 and there are exactly 63 transitions, so the running cap
    check IS exact consumption; that identity is asserted, not assumed."""
    if len(pair_order) != 32:
        return None
    # C3 PRE-FILTER (added 2026-09-02). lean/RecordConvention.lean defines repr(k)
    # as the lex-least completion satisfying C2/C3/C5; this function implemented
    # C4/C2/C5 and omitted C3, so for a key whose C3 exceeds the ceiling it
    # RETURNED A RECORD where the definition says none exists. Because C3 cannot
    # change WHICH completion is lex-least (it is orientation-invariant -- swapping
    # a pair moves a hexagram and its complement together), the omission never
    # corrupted an AGREE/DISAGREE verdict. It corrupted the INCOMPUTABLE leg
    # instead: the one VERIFY.md advertises as fail-closed. Measured on a
    # C3 = 1080 key, both languages: CHECK_REPR=PASS, INCOMPUTABLE=0, rc 0.
    #
    # That same invariance is what makes this a legitimate PRE-DFS filter rather
    # than a leaf test: C3 is a function of the key alone, so it is decided once
    # here instead of at every completion, and it PRUNES rather than costing.
    # Verified by measurement, not assumed -- over random keys, C3 is constant
    # across every orientation assignment.
    seq0 = []
    for slot in range(32):
        a, b = PAIRS[pair_order[slot]]
        seq0 += [a, b]
    if compute_comp_dist(seq0) > KW_COMP_DIST:
        return None
    budget = _c5_budget_from_kw()
    if not (sum(budget) == 63):
        raise AssertionError("budget/transition-count identity broken")

    a0, b0 = PAIRS[pair_order[0]]
    # C4 forces the sequence to open (63, 0); only an orientation that produces
    # it can be slot 0, and if neither does, the key is not completable.
    if (a0, b0) == (63, 0):
        o0 = 0
    elif (b0, a0) == (63, 0):
        o0 = 1
    else:
        return None
    wd0 = hamming(63, 0)
    if budget[wd0] <= 0:
        return None
    budget[wd0] -= 1

    orient = [0] * 32
    orient[0] = o0

    def rec(slot, last):
        if slot == 32:
            return all(v == 0 for v in budget)      # exact consumption
        a, b = PAIRS[pair_order[slot]]
        for o in (0, 1):                            # 0 BEFORE 1 == lex-least
            f, s = (b, a) if o else (a, b)
            bd = hamming(last, f)
            if bd == 5 or budget[bd] <= 0:
                continue
            wd = hamming(f, s)
            budget[bd] -= 1
            if budget[wd] <= 0:
                budget[bd] += 1
                continue
            budget[wd] -= 1
            orient[slot] = o
            if rec(slot + 1, s):
                return True
            budget[wd] += 1
            budget[bd] += 1
        return False

    if not rec(1, 0):
        return None
    return bytes(((pair_order[i] << 2) | (orient[i] << 1)) for i in range(32))

SOL_HEADER_SIZE = 32
SOL_FORMAT_VERSION = 1

def parse_header(data):
    """Returns declared record_count, or raises ValueError on bad header."""
    if len(data) < SOL_HEADER_SIZE:
        raise ValueError(f"file too small ({len(data)} bytes) to contain 32-byte header")
    if data[0:4] != b"ROAE":
        raise ValueError(f"bad magic: got {data[0:4]!r}, expected b'ROAE'")
    (version,) = struct.unpack("<I", data[4:8])
    if version != SOL_FORMAT_VERSION:
        raise ValueError(f"unsupported format version {version} (this reader knows version {SOL_FORMAT_VERSION})")
    (record_count,) = struct.unpack("<Q", data[8:16])
    return record_count

def verify_chunk(args):
    """Verify records [start, end) of `path`. Returns dict of counts plus
    boundary state for inter-chunk stitching.

    All per-record checks (C1-C5, decode, kw_found) are local to the chunk.
    Sort and dup checks within the chunk are local; cross-chunk boundary
    sort/dup is stitched by the parent.
    """
    path, start, end = args
    n_chunk = end - start
    if n_chunk <= 0:
        return {
            'fail_c1': 0, 'fail_c2': 0, 'fail_c3': 0, 'fail_c4': 0, 'fail_c5': 0,
            'fail_decode': 0, 'fail_sort': 0, 'fail_dup': 0, 'fail_fmt': 0,
            'kw_found': False,
            'first_canonical': None, 'first_rec': None,
            'last_canonical': None, 'last_rec': None,
            'count': 0,
        }
    # Stream-read in 1M-record batches (32 MB each) to bound memory.
    # Previously loaded the full chunk (~6.87 GB at --jobs 16 on a 110 GB
    # solutions.bin) which forced N workers × chunk_size = file_size of
    # total memory regardless of N — caused swap-thrash on any VM with
    # RAM < file_size. Streamed batches: total memory ≈ N × 32 MB.
    BATCH_RECORDS = 1024 * 1024  # 1M records = 32 MB per batch
    fail_c1 = fail_c2 = fail_c3 = fail_c4 = fail_c5 = 0
    fail_decode = fail_sort = fail_dup = fail_fmt = 0
    kw_found = False
    prev_canonical = None
    prev_rec = None
    first_canonical = None
    first_rec = None

    f = open(path, 'rb')
    try:
        f.seek(SOL_HEADER_SIZE + start * 32)
        records_read = 0
        # Load the first batch as `chunk`; refill in-loop when exhausted.
        chunk = f.read(min(BATCH_RECORDS, n_chunk) * 32)
        chunk_records = len(chunk) // 32
        if chunk_records == 0 or len(chunk) % 32 != 0:
            raise IOError(f"verify_chunk: short or unaligned read at start={start}: got {len(chunk)} bytes")
    except Exception:
        f.close()
        raise

    for r_global in range(n_chunk):
        r_in_batch = r_global - records_read
        if r_in_batch >= chunk_records:
            # Refill the batch: free old chunk, read next batch.
            records_read += chunk_records
            remaining = n_chunk - records_read
            if remaining <= 0:
                break
            chunk = f.read(min(BATCH_RECORDS, remaining) * 32)
            chunk_records = len(chunk) // 32
            if chunk_records == 0 or len(chunk) % 32 != 0:
                f.close()
                raise IOError(f"verify_chunk: short or unaligned read mid-stream at offset {records_read}")
            r_in_batch = 0
        rec = chunk[r_in_batch*32:(r_in_batch+1)*32]

        # Format conformance: bit 0 of every record byte is reserved and MUST
        # be zero (SOLUTIONS_FORMAT.md: "bit 0: unused, always 0"). It is masked
        # out of the canonical sort key (& 0xFC) but DOES participate in the
        # full-byte dedup tie-break, so a set bit 0 silently breaks byte-exact
        # reproducibility between two otherwise-conformant implementations.
        if any(b & 1 for b in rec):
            fail_fmt += 1

        seq, pairs_used, first_pair = decode(rec)

        if seq is None:
            fail_decode += 1
            continue

        # C1: each pair used exactly once
        if any(c != 1 for c in pairs_used):
            fail_c1 += 1

        # C4: s0 = 63 (hexagram 1, all yang) AND s1 = 0 (hexagram 2, all yin) — both conjuncts.
        # This is the spec form (SPECIFICATION.md C4), not the pair-index proxy.
        # C4 is ORIENTED, and the 2026-07-26 retraction established that the
        # orientation is NOT forced by the other constraints: complementation
        # x -> x^63 is an exact symmetry of C1 n C2 n C3 n C5 (machine-checked,
        # lean/KingWen.lean). So a verifier testing only `first_pair == 0` would
        # accept comp(KW) — which opens (0, 63) — as fully C1-C5 valid. Testing
        # the pair index alone silently relies on the ENUMERATOR's hardcoded
        # seq[0]=63; seq[1]=0, which is exactly the invariant an independent
        # verifier is not entitled to assume. seq[0] == 63 subsumes the index
        # test (63 occurs only in pair 0, and the pairs are disjoint); both are
        # kept so the failure mode stays legible.
        if first_pair != START_PAIR or seq[0] != 63 or seq[1] != 0:
            fail_c4 += 1

        # C2: no hamming-5 transitions
        if any(hamming(seq[i], seq[i+1]) == 5 for i in range(63)):
            fail_c2 += 1

        # C5: distance distribution matches KW
        dist = [0] * 7
        for i in range(63):
            d = hamming(seq[i], seq[i+1])
            if d <= 6:
                dist[d] += 1
        if dist != KW_DIST:
            fail_c5 += 1

        # C3: complement distance <= KW's value (776)
        if compute_comp_dist(seq) > KW_COMP_DIST:
            fail_c3 += 1

        can = canonical(rec)
        if first_canonical is None:
            first_canonical = can
            first_rec = rec
        if prev_canonical is not None:
            if can < prev_canonical:
                fail_sort += 1
            elif can == prev_canonical and rec < prev_rec:
                fail_sort += 1
            if can == prev_canonical:
                fail_dup += 1
        prev_canonical = can
        prev_rec = rec

        if seq == KW:
            kw_found = True

    f.close()
    return {
        'fail_c1': fail_c1, 'fail_c2': fail_c2, 'fail_c3': fail_c3,
        'fail_c4': fail_c4, 'fail_c5': fail_c5,
        'fail_decode': fail_decode, 'fail_sort': fail_sort, 'fail_dup': fail_dup,
        'fail_fmt': fail_fmt,
        'kw_found': kw_found,
        'first_canonical': first_canonical, 'first_rec': first_rec,
        'last_canonical': prev_canonical, 'last_rec': prev_rec,
        'count': n_chunk,
    }

def stitch_boundary(prev_chunk, next_chunk):
    """Given two adjacent chunk results, return (sort_inc, dup_inc) for the
    boundary record pair: prev_chunk's last vs next_chunk's first.
    Mirrors the per-record sort+dup logic from verify_chunk."""
    p_can = prev_chunk['last_canonical']
    p_rec = prev_chunk['last_rec']
    n_can = next_chunk['first_canonical']
    n_rec = next_chunk['first_rec']
    if p_can is None or n_can is None:
        return 0, 0
    sort_inc = 0
    dup_inc = 0
    if n_can < p_can:
        sort_inc += 1
    elif n_can == p_can and n_rec < p_rec:
        sort_inc += 1
    if n_can == p_can:
        dup_inc += 1
    return sort_inc, dup_inc

def enumerate_reference(npairs):
    """Independent completeness reference on a REDUCED npairs-pair problem.

    Enumerates the complete set of valid arrangements of the first `npairs`
    KW-derived pairs under the structural constraints that reduce cleanly to a
    truncated sequence — C1 (each pair once), C2 (no hamming-5 transition
    between consecutive hexagrams), C4 (pair 0 = hexagram 1 / hexagram 2 placed
    first; either orientation). C3/C5 are GLOBAL (defined over the full
    64-hexagram sequence vs KW's distribution) and do NOT reduce, so they are
    intentionally excluded here.

    Runs the enumeration TWO independent ways and asserts identical result sets:
      A. generate-all-then-filter  (exhaustive ground truth — no pruning)
      B. prune-as-you-go DFS       (C2 checked at each placement — mirrors how
                                    solve.c prunes during its walk)
    If B != A, a pruning step dropped or added a valid sequence — exactly the
    "did an optimization silently drop a real solution" failure class. This is
    independent of solve.c (different language, separate enumerator) and of the
    verify.py per-record checker; it grounds the constraint/pruning SEMANTICS.

    SCOPE LIMIT (honest): this validates the structural-constraint enumeration
    logic on a reduced problem. It does NOT differential-test solve.c's full
    enumeration — that is infeasible (solve.c never exhausts any cell; global
    C3/C5 don't reduce; solve.c has no reduced-pair mode). solve.c prune
    completeness at canonical scale is covered empirically by the K-pilots
    (v1 ⊆ v1+prunes at every tested scale, tasks #80/#85/#86)."""
    import itertools
    if npairs < 2 or npairs > 9:
        print(f"ERROR: --enumerate-reference N requires 2 <= N <= 9 (got {npairs}); "
              f"N>9 is too slow for the exhaustive ground-truth pass")
        return 2
    pairs = PAIRS[:npairs]
    rest = list(range(1, npairs))  # non-start pair indices; pair 0 is fixed first (C4)

    def c2_ok_full(seq):
        return all(hamming(seq[i], seq[i+1]) != 5 for i in range(len(seq) - 1))

    def build(order, orients):
        seq = []
        for slot, pi in enumerate(order):
            a, b = pairs[pi]
            seq.extend((a, b) if orients[slot] == 0 else (b, a))
        return tuple(seq)

    # --- Method A: exhaustive generate-all, then filter by C2 (ground truth) ---
    setA = set()
    candidates_A = 0
    for perm in itertools.permutations(rest):
        order = (0,) + perm
        for ob in range(1 << npairs):
            orients = [(ob >> j) & 1 for j in range(npairs)]
            candidates_A += 1
            seq = build(order, orients)
            if c2_ok_full(seq):
                setA.add(seq)

    # --- Method B: prune-as-you-go DFS (C2 enforced incrementally) ---
    setB = set()
    used = [False] * npairs

    def dfs(seq, placed):
        if placed == npairs:
            setB.add(tuple(seq))
            return
        for pi in range(npairs):
            if used[pi]:
                continue
            a, b = pairs[pi]
            for (h0, h1) in ((a, b), (b, a)):
                # incremental C2: check the new internal + boundary transitions
                if seq and hamming(seq[-1], h0) == 5:
                    continue
                if hamming(h0, h1) == 5:
                    continue
                used[pi] = True
                seq.append(h0); seq.append(h1)
                dfs(seq, placed + 1)
                seq.pop(); seq.pop()
                used[pi] = False

    # C4: pair 0 first, both orientations
    a0, b0 = pairs[0]
    for (h0, h1) in ((a0, b0), (b0, a0)):
        if hamming(h0, h1) == 5:
            continue
        used[0] = True
        dfs([h0, h1], 1)
        used[0] = False

    print(f"=== verify.py --enumerate-reference {npairs} ===")
    print(f"Reduced problem: first {npairs} KW pairs, constraints C1+C2+C4 "
          f"(C3/C5 are global, excluded — see docstring)")
    print(f"Method A (exhaustive generate+filter): {candidates_A:,} candidates -> {len(setA):,} valid")
    print(f"Method B (prune-as-you-go DFS):        {len(setB):,} valid")
    if setA == setB:
        print(f"PASS: both methods produce the IDENTICAL {len(setA):,}-sequence set "
              f"(prune-as-you-go drops/adds nothing vs exhaustive)")
        return 0
    only_a = len(setA - setB)
    only_b = len(setB - setA)
    print(f"FAIL: sets differ — only in A (exhaustive): {only_a}, only in B (pruned): {only_b}")
    print("      A pruning step is unsound/incomplete. Investigate before trusting the predicate.")
    return 1


# ============================================================================
# INDEPENDENT RE-COUNTING  (--recount)  — answers TR-11 §10vi.
#
# Everything below is rebuilt clean-room from the published mathematical
# definitions. It shares NO code with solve.c/solve.py and imports nothing but
# the standard library. The counting method is deliberately DIFFERENT from
# solve.c's symmetry-quotient DP: a plain (mask, last) layered subset DP that
# stores every mask (no canonicalization), cross-checked at small n against the
# even-more-primitive exhaustive backtracking already in --enumerate-reference.
# All arithmetic is exact Python big integers. Memory is bounded by the number
# of live DP states (tens of MB), never by the astronomically large solution
# set.
# ============================================================================

def _rev6(n):
    """Bit reversal of a 6-bit integer (SPECIFICATION.md rev)."""
    r = 0
    for i in range(6):
        if (n >> i) & 1:
            r |= 1 << (5 - i)
    return r

def _comp6(n):
    """Complement: flip all 6 bits (SPECIFICATION.md comp = n ^ 63)."""
    return n ^ 63

def _partner(h):
    """partner(h) = rev(h) if rev(h) != h else comp(h) (SPECIFICATION.md C1)."""
    r = _rev6(h)
    return r if r != h else _comp6(h)

def _canonical_pairs():
    """The 32 canonical pairs, derived independently from _partner()."""
    seen = set(); out = []
    for h in range(64):
        if h in seen:
            continue
        p = _partner(h)
        seen.add(h); seen.add(p)
        out.append(tuple(sorted((h, p))))
    return out

def _verify_tables_against_rules():
    """Import-time gate: the KW table, and everything derived from it, must
    agree with the RULE-derived objects of SPECIFICATION.md — not merely with
    itself.

    Without this the record path is self-verifying: PAIRS, KW_DIST and
    KW_COMP_DIST are all computed from the KW literal at the top of this file,
    so a corrupted KW table would silently redefine C1 and C5 and then check
    every record against the corruption. (Concretely: swapping the last two
    pair-blocks moves both complement partners together, leaving cd = 776
    intact, while changing the C5 multiset — the file would then reject
    spec-compliant records and accept violating ones, against itself.)

    These are explicit raises rather than `assert` so they survive `python3 -O`.
    --recount reports the same facts as table rows; this gate makes them
    unconditional on the default `verify.py solutions.bin` path.
    """
    if sorted(KW) != list(range(64)):
        raise RuntimeError("table check: KW is not a permutation of {0..63}")
    if {frozenset(p) for p in PAIRS} != {frozenset(p) for p in _canonical_pairs()}:
        raise RuntimeError(
            "table check: published PAIRS != partner()-derived canonical pairing (C1)")
    for (a, b) in PAIRS:
        if _partner(a) != b or _partner(b) != a:
            raise RuntimeError(f"table check: pair ({a},{b}) is not a partner() pair (C1)")
    observed = {d: KW_DIST[d] for d in range(7) if KW_DIST[d]}
    if observed != {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}:
        raise RuntimeError(
            f"table check: KW difference-wave multiset {observed} != SPECIFICATION.md C5 literal")
    if KW_COMP_DIST != 776:
        raise RuntimeError(f"table check: KW complement distance {KW_COMP_DIST} != 776 (C3)")

_verify_tables_against_rules()

def _apply_bitperm(g, h):
    """Apply bit-position permutation g to hexagram h: bit i -> position g[i]."""
    r = 0
    for i in range(6):
        if (h >> i) & 1:
            r |= 1 << g[i]
    return r

def _commuting_bitperms():
    """The 48 position-permutations commuting with reversal (i <-> 5-i)."""
    import itertools
    out = []
    for g in itertools.permutations(range(6)):
        if all(g[5 - i] == 5 - g[i] for i in range(6)):
            out.append(g)
    return out

# Pair-orbit partition of the 31 free pairs (TR-11 §3 / F3 draft), published
# membership. Every reduced rung is a union of whole orbits (group-closed).
_ORBITS = {
    "3.0": [3, 7, 11],           "3.1": [4, 6, 21],
    "3.2": [13, 14, 30],         "4.0": [5, 8, 26, 31],
    "6.0": [1, 9, 17, 19, 22, 25], "6.1": [2, 12, 16, 18, 24, 28],
    "6.2": [10, 15, 20, 23, 27, 29],
}

def _derive_pair_orbits():
    """Derive the orbit partition of the 31 free pairs from THIS FILE's own group,
    rather than trusting the table above.

    Each of the 48 bit-position permutations commuting with reversal acts on
    hexagrams; because it commutes with rev and fixes 0 and 63, it maps canonical
    pairs to canonical pairs and so induces a permutation of the 32 pair indices.
    Orbits of the 31 free pairs (pair 0 is C4-pinned and fixed by every element)
    under that induced action are what `_ORBITS` records.

    A9 (2026-08-01): `_ORBITS` was transcribed from TR-11 §3, which made the
    reduced-rung machinery depend on a published table copied by hand — the same
    self-verifying-table weakness the record path had (see
    `_verify_tables_against_rules`). Deriving it closes the last such nick.
    """
    index_of = {frozenset(p): i for i, p in enumerate(PAIRS)}
    orbits, seen = [], set()
    for i in range(1, 32):
        if i in seen:
            continue
        orb, frontier = {i}, [i]
        while frontier:
            j = frontier.pop()
            a, b = PAIRS[j]
            for g in _commuting_bitperms():
                k = index_of.get(frozenset((_apply_bitperm(g, a), _apply_bitperm(g, b))))
                if k is None:
                    raise RuntimeError(
                        "orbit derivation: a group element moved a canonical pair off the pairing")
                if k not in orb:
                    orb.add(k); frontier.append(k)
        seen |= orb
        orbits.append(sorted(orb))
    return orbits

def _verify_orbits_against_group():
    """Gate: the published `_ORBITS` table must equal the derived orbit partition."""
    derived = {tuple(o) for o in _derive_pair_orbits()}
    published = {tuple(sorted(v)) for v in _ORBITS.values()}
    if derived != published:
        raise RuntimeError(
            f"orbit check: published _ORBITS != orbits derived from the 48 commuting "
            f"bit-perms.\n  derived  : {sorted(derived)}\n  published: {sorted(published)}")
    covered = sorted(i for o in derived for i in o)
    if covered != list(range(1, 32)):
        raise RuntimeError(
            f"orbit check: orbits do not partition the 31 free pairs (got {len(covered)} indices)")

_verify_orbits_against_group()

def _spec_to_pairs(spec):
    idxs = []
    for lab in spec.split(","):
        idxs.extend(_ORBITS[lab])
    idxs.sort()
    return [PAIRS[i] for i in idxs]

def _count_c1c2c4(pairs, start):
    """Independent COUNTING RECURRENCE for |C1∩C2∩C4| on a pair-union.

    Plain layered subset DP (NO symmetry quotient). State = (placed-mask,
    last-exit-hexagram) -> exact big-int count. Transition places any unused
    pair in either orientation iff the boundary distance != 5 (C2). Only two
    popcount layers are ever live; memory is bounded by the state count.
    """
    from collections import defaultdict
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs); full = (1 << n) - 1
    cur = {(0, start): 1}
    for _ in range(n):
        nxt = defaultdict(int)
        for (mask, last), cnt in cur.items():
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    if hamming(last, f) == 5:
                        continue
                    nxt[(mask | bit, s)] += cnt
        cur = nxt
    return sum(c for (m, _l), c in cur.items() if m == full)

def _backtrack_c1c2c4(pairs, start):
    """Even-more-primitive exhaustive backtracking count (no memoization),
    used only at small n to cross-check the DP recurrence."""
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs)
    total = 0
    def rec(depth, last, used):
        nonlocal total
        if depth == n:
            total += 1
            return
        for i in range(n):
            if used & (1 << i):
                continue
            for (f, s) in orients[i]:
                if hamming(last, f) == 5:
                    continue
                rec(depth + 1, s, used | (1 << i))
    rec(0, start, 0)
    return total


_CLS = (1, 2, 3, 4, 6)          # C5 boundary-distance classes; 5 is C2-forbidden
_CLS_IX = {d: i for i, d in enumerate(_CLS)}

def _spec_to_pairs_ordered(spec):
    """Pair list in SPEC ORDER — orbit rows concatenated in the order the spec
    names them, each row ascending internally (TR-11 §4b/§5).

    NOT the sorted index set: order is load-bearing for the C5 ladder, because
    B0 is defined by a first-completion DFS that scans pairs in subset-index
    order. Sorting the n=9 rung yields B0=(2,2,2,3,0) instead of (2,5,0,2,0).
    """
    idxs = []
    for lab in spec.split(","):
        idxs.extend(_ORBITS[lab])          # rows are already ascending
    return [PAIRS[i] for i in idxs]

def _b0_first_completion(pairs, start):
    """TR-11 §5 Step 1: B0 = boundary-class multiset of the FIRST complete
    C2-respecting walk, scanning unplaced pairs in ascending position within P
    and, for each, orientation o=0 (enter b, exit a) then o=1 (enter a, exit b).

    Returns a 5-tuple over classes (1,2,3,4,6), or None if no walk exists.
    """
    n = len(pairs)
    # o=0 first: (b,a) enters b and exits a, for a pair listed (a,b)
    orients = [((b, a), (a, b)) for (a, b) in pairs]

    def rec(depth, last, used, counts):
        if depth == n:
            return counts
        for i in range(n):
            if used & (1 << i):
                continue
            for (f, s) in orients[i]:
                d = hamming(last, f)
                if d == 5 or d == 0:
                    continue
                nc = list(counts); nc[_CLS_IX[d]] += 1
                got = rec(depth + 1, s, used | (1 << i), tuple(nc))
                if got is not None:
                    return got
        return None

    return rec(0, start, 0, (0,) * 5)

def _count_c1c2c4c5(pairs, start, b0):
    """Independent COUNTING RECURRENCE for |C1∩C2∩C4∩C5| on a reduced rung.

    TR-11 §5 Step 2: plain layered subset DP (NO symmetry quotient), state =
    (placed-mask, last-exit-hexagram, running class-usage vector p). A
    transition is allowed iff the boundary distance d != 5 (C2) AND
    p[class(d)] < B0[class(d)] (the budget cap). The answer is the mass on
    full-mask states; with the cap in place every full state carries p == B0
    exactly (sum invariant), so the equality filter is a no-op — but ONLY with
    the cap in place.

    This is the C5 analogue of _count_c1c2c4 and shares no code with solve.c.
    """
    from collections import defaultdict
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs); full = (1 << n) - 1
    cur = {(0, start, (0,) * 5): 1}
    for _ in range(n):
        nxt = defaultdict(int)
        for (mask, last, p), cnt in cur.items():
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    d = hamming(last, f)
                    if d == 5 or d == 0:
                        continue
                    ci = _CLS_IX[d]
                    if p[ci] >= b0[ci]:
                        continue
                    np_ = list(p); np_[ci] += 1
                    nxt[(mask | bit, s, tuple(np_))] += cnt
        cur = nxt
    return sum(c for (m, _l, p), c in cur.items() if m == full and p == tuple(b0))

# TR-11 §4b C5 ladder — (n, orbit spec, published B0, published exact count).
# Only the rungs that are cheap enough to recompute in-process are listed; the
# larger rungs in §4b need a worker, not this verifier.
_C5_RUNGS = [
    (9,  "3.0,3.1,3.2", (2, 5, 0, 2, 0), 26112),
    (13, "3.0,4.0,6.2", (1, 6, 0, 6, 0), 2063395607040),
    (16, "4.0,6.0,6.1", (1, 8, 1, 6, 0), 267765117419520),
]


# ---------------------------------------------------------------------------
# Verifier-gap closure (2026-07-31): worker-sized C5 rungs (A4), exact
# deterministic subtree anchors (A5), finite record-mode + wrap/parity
# tallies (A6).  Same discipline as the rest of this file: clean-room from
# the published definitions, stdlib only, no solve.c/solve.py import.
# ---------------------------------------------------------------------------

# TR-11 §4b worker-sized rungs.  n=18's integer was unpublished through TR-11
# v1.17 (the table printed "(in-RAM reference)"); v1.18 (2026-08-10) publishes it
# as 3,211,799,156,883,456, and it is GATED here as of the same day.
#
# The gate was deliberately NOT wired at publication time: gating asserts that THIS
# independent DP reproduces the integer, and doing that on faith would let the gate
# inherit its expected value from the engine it exists to check.  So the recount was
# run first, on a throwaway westus2 Spot VM (the orchestrator hosts the live Stage G
# supervisor and an OOM there would kill a 9-day campaign): 2026-08-10, n=16 packed-DP
# self-gate ok, B0 re-derived (0,7,1,10,0) MATCH, count 3,211,799,156,883,456 EXACT,
# 157 s wall / 953 MB peak RSS.  Only then was the value wired in.
# n=18's published B0 column was already gated before this.  n=24/25/27/28 are NOT reachable by this plain
# DP on any single-node RAM budget (peak live states ~4e9 at n=24, ~100 GB per
# layer) — they remain covered by the engine's in-RAM/out-of-core concordance
# and verify.c's IE engine.
_C5_RUNGS_LARGE = {
    18: ("6.0,6.1,6.2",     (0, 7, 1, 10, 0), 3211799156883456),
    19: ("3.0,4.0,6.0,6.1", (2, 11, 0, 6, 0), 63244766587981824),
}

def _count_c1c2c4c5_packed(pairs, start, b0):
    """Memory-lean variant of _count_c1c2c4c5 for the worker-sized rungs.

    Identical recurrence (TR-11 §5 Step 2); states are packed into a single
    int key (mask | last << n | pidx << (n + 6), pidx mixed-radix over B0+1)
    so each live state costs one small-int key + one int value.  Peak live
    states at n=19 are ~4e7 per layer (~8 GB, ~1e9 transitions in CPython —
    a worker, not a laptop).  Cross-checked against _count_c1c2c4c5 at
    n=9/13/16 (identical integers) before first use.
    """
    n = len(pairs); full = (1 << n) - 1
    radix = [c + 1 for c in b0]
    stride = [0] * 5
    acc = 1
    for c in range(5):
        stride[c] = acc; acc *= radix[c]
    shift_last = n; shift_p = n + 6
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    cur = {start << shift_last: 1}
    for _layer in range(n):
        nxt = {}
        get = nxt.get
        for key, cnt in cur.items():
            mask = key & full
            last = (key >> shift_last) & 63
            pidx = key >> shift_p
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    d = hamming(last, f)
                    if d == 5 or d == 0:
                        continue
                    ci = _CLS_IX[d]
                    if (pidx // stride[ci]) % radix[ci] >= b0[ci]:
                        continue
                    nkey = ((mask | bit) | (s << shift_last)
                            | ((pidx + stride[ci]) << shift_p))
                    nxt[nkey] = get(nkey, 0) + cnt
        cur = nxt
    b0idx = sum(b0[c] * stride[c] for c in range(5))
    total = 0
    for key, cnt in cur.items():
        if not (key & full == full and key >> shift_p == b0idx):
            raise AssertionError("sum invariant violated — cap logic bug")
        total += cnt
    return total

def recount_rung(n):
    """--recount-rung N: independently recompute a worker-sized TR-11 §4b C5
    rung (N in {18, 19}).  B0 is re-derived by §5's first-completion DFS and
    gated against the published B0 column; the count is gated against the
    published integer where one exists.  Returns 0 iff everything gated
    matched."""
    import time
    if n not in _C5_RUNGS_LARGE:
        if n in (9, 13, 16):
            print(f"n={n} is covered in-process by --recount; use that.")
        else:
            print(f"--recount-rung: n={n} not supported. Supported: 18, 19.")
            print("n=24/25/27/28 exceed any single-node RAM budget for the plain")
            print("DP (peak live states ~4e9 at n=24, ~100 GB/layer); they remain")
            print("covered by the engine's in-RAM/out-of-core concordance and")
            print("verify.c's IE engine (--ie-spec/--ie-expect).")
        return 2
    spec, b0_pub, pub = _C5_RUNGS_LARGE[n]
    pl = _spec_to_pairs_ordered(spec)
    if not (len(pl) == n):
        raise AssertionError('guard failed: len(pl) == n')
    t0 = time.time()
    # gate the packed DP against the plain DP on the largest cheap rung first
    xchk_pl = _spec_to_pairs_ordered("4.0,6.0,6.1")
    xchk_b0 = _b0_first_completion(xchk_pl, 0)
    a = _count_c1c2c4c5(xchk_pl, 0, xchk_b0)
    b = _count_c1c2c4c5_packed(xchk_pl, 0, xchk_b0)
    if a != b:
        print(f"*FAIL* packed-DP self-gate at n=16: plain={a:,} packed={b:,}")
        return 1
    print(f"packed-DP self-gate at n=16: {a:,} == {b:,}  [ok]")
    b0 = _b0_first_completion(pl, 0)
    ok_b0 = tuple(b0) == tuple(b0_pub)
    print(f"n={n} {{{spec}}}@0  B0 derived = {tuple(b0)}  published = {tuple(b0_pub)}"
          f"  [{'MATCH' if ok_b0 else '*** MISMATCH ***'}]")
    cnt = _count_c1c2c4c5_packed(pl, 0, tuple(b0))
    dt = time.time() - t0
    if pub is None:
        print(f"count = {cnt:,}   (report-only: this recount is not gated against a")
        print(f"        published integer, so compare it by hand to TR-11 §4b)  [{dt:.0f}s]")
        return 0 if ok_b0 else 1
    ok = (cnt == pub)
    print(f"count = {cnt:,}  published = {pub:,}  "
          f"[{'MATCH' if ok else '*** MISMATCH ***'}]  [{dt:.0f}s]")
    return 0 if (ok and ok_b0) else 1

# ---------------------------------------------------------------------------
# PER-LAYER RECOUNT (2026-08-27) — the gate behind reports/FULL31_EXACT_AGGREGATES.md
#
# WHY THIS EXISTS. The rung TOTALS have been independently recounted since
# 2026-07-21, but the INTERMEDIATE layers never had been by anything at all.
# Publishing a 31-row per-layer table therefore meant publishing 30 integers no
# instrument had ever checked, on the strength of the 31st matching. That is the
# silent-wrong-emitter shape: an emitter whose last row is right and whose middle
# is wrong looks exactly like a correct one.
#
# WHAT IT CHECKS, AND IN WHICH DIRECTION. It recomputes the layer masses with the
# SAME plain (mask, last, budget) recurrence _count_c1c2c4c5 uses for the total --
# no symmetry quotient, no shared code with solve.c -- and gates the PUBLISHED
# TABLE against them. The artifact is the thing under test; this file is the
# instrument. If the artifact is missing or its rows cannot be parsed, that is a
# FAILURE and not a pass: a verifier that goes quiet when its target is absent has
# no power to reject anything (the closure invariant).
#
# SHOWN ABLE TO FAIL. Weakening the cap from `p >= B0` to `p > B0` leaves k=1
# identical at 12 and diverges from k=2 (174 vs 96), total 3,731,760 vs 26,112.
# A first-layer-only check passes that engine; a total-only check catches it but
# cannot say the divergence starts at k=2.
_AGG_DOC = "reports/FULL31_EXACT_AGGREGATES.md"

def _layer_masses_c1c2c4c5(pairs, start, b0):
    """Per-layer prefix mass by the same recurrence as _count_c1c2c4c5.

    Deliberately a separate function rather than a flag on that one: the total is
    a gated published quantity and its code path should not grow a branch to serve
    a second caller."""
    from collections import defaultdict
    orients = [((a, b), (b, a)) for (a, b) in pairs]
    n = len(pairs)
    cur = {(0, start, (0,) * 5): 1}
    out = []
    for _ in range(n):
        nxt = defaultdict(int)
        for (mask, last, p), cnt in cur.items():
            for i in range(n):
                bit = 1 << i
                if mask & bit:
                    continue
                for (f, s) in orients[i]:
                    d = hamming(last, f)
                    if d == 5 or d == 0:
                        continue
                    ci = _CLS_IX[d]
                    if p[ci] >= b0[ci]:
                        continue
                    np_ = list(p); np_[ci] += 1
                    nxt[(mask | bit, s, tuple(np_))] += cnt
        cur = nxt
        out.append(sum(cur.values()))
    return out

def _published_rung_layers(n):
    """Parse the n=9 / n=13 layer-mass columns out of the published artifact.

    Returns a list of n integers, or raises. The two rungs share one markdown
    table (n=9 in cols 1-2, n=13 in cols 4-5), so a row is read by POSITION and a
    short row simply has no n=13 cell."""
    import os, re
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), _AGG_DOC)
    if not os.path.exists(path):
        raise RuntimeError(f"{_AGG_DOC} is absent -- nothing to gate. This is a "
                           f"failure, not a pass.")
    col = 0 if n == 9 else 3
    got = {}
    # SCOPE THE PARSE. The first cut matched any pipe row in the file and so read
    # the 31-row table of section 1, whose columns mean something else entirely --
    # it reported all nine n=9 layers as mismatched against numbers that were never
    # n=9 masses. A gate that fails for the wrong reason is only luckier than one
    # that passes for the wrong reason. The rung table is the one under "## 2" and
    # it is exactly five cells wide; section 1's is eight.
    in_s2 = False
    for line in open(path, encoding="utf-8"):
        if line.startswith("## "):
            in_s2 = line.startswith("## 2.")
            continue
        if not in_s2 or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 5:
            continue
        k, m = cells[col], cells[col + 1]
        if not re.fullmatch(r"\d+", k) or not re.fullmatch(r"[\d,]+", m):
            continue
        ki = int(k)
        if 1 <= ki <= n and ki not in got:
            got[ki] = int(m.replace(",", ""))
    missing = [k for k in range(1, n + 1) if k not in got]
    if missing:
        raise RuntimeError(f"{_AGG_DOC} has no n={n} mass for layer(s) {missing}")
    return [got[k] for k in range(1, n + 1)]

def recount_rung_layers(n):
    """--recount-rung-layers N: gate the published per-layer masses for the N=9
    or N=13 C5 rung against an independent recount. Returns 0 iff every layer
    matches AND the published table was found and fully parsed."""
    import time
    if n not in (9, 13):
        print(f"--recount-rung-layers: n={n} not supported. Supported: 9, 13.")
        print("Larger rungs exceed the plain DP's single-node budget; see")
        print("--recount-rung for the worker-sized totals.")
        return 2
    spec = {9: "3.0,3.1,3.2", 13: "3.0,4.0,6.2"}[n]
    try:
        pub = _published_rung_layers(n)
    except RuntimeError as e:
        print(f"*FAIL* {e}")
        return 1
    t0 = time.time()
    pl = _spec_to_pairs_ordered(spec)
    if not (len(pl) == n):
        raise AssertionError('guard failed: len(pl) == n')
    b0 = _b0_first_completion(pl, 0)
    got = _layer_masses_c1c2c4c5(pl, 0, tuple(b0))
    bad = 0
    print(f"n={n} {{{spec}}}@0  B0 re-derived = {tuple(b0)}")
    for k, (g, p) in enumerate(zip(got, pub), 1):
        ok = (g == p)
        if not ok:
            bad += 1
        print(f"  layer {k:2d}: recount {g:,}  published {p:,}  "
              f"[{'ok' if ok else '*** MISMATCH ***'}]")
    dt = time.time() - t0
    if bad:
        print(f"*FAIL* {bad} of {n} layer(s) disagree with {_AGG_DOC}  [{dt:.1f}s]")
        return 1
    print(f"all {n} layer masses MATCH {_AGG_DOC}  [{dt:.1f}s]")
    return 0

# ---------------------------------------------------------------------------
# F1U192 DECIMAL RENDERING — full-range gate (2026-08-27, Q-43 / Codex turn 4)
#
# THE GAP. f1_dec() renders every exact count this project publishes, including the
# 40-digit |C1&C2&C4&C5| = 1.097051e39 and all 31 layer masses in
# reports/FULL31_EXACT_AGGREGATES.md. Its only end-to-end exercise was the n=9 rung
# total, 26112 -- five digits, entirely inside limb 0. The multi-limb carry in
# f1_divmod_small() therefore had NO proof, at any width, ever. Codex found no bad
# formatter on the n=31 path, so this is a missing proof rather than a known defect,
# which is precisely the class this project refuses to score as passing.
#
# WHY THE Q-157 GATE DOES NOT COVER IT. --recount-rung-layers tops out at n=13,
# whose largest mass is 2,116,284,083,712 -- about 2.1e12, comfortably inside a
# single 64-bit limb. Every value it checks leaves the carry path untouched. A gate
# can be correct, independent, and still blind.
#
# THE INSTRUMENT. solve --f1-dec-selftest reads limb triples on stdin and prints
# what the REAL f1_dec() makes of them. It knows no expected values; the battery and
# the arithmetic live here, where the oracle is Python's arbitrary-precision int
# evaluating (l2<<128)|(l1<<64)|l0 -- a different derivation from C's repeated
# divide-by-ten, not a re-run of it.
def _f1_dec_battery():
    """Limb triples to render. Boundaries first, then the published integers."""
    U = (1 << 64) - 1
    def t(x):
        return ((x >> 128) & U, (x >> 64) & U, x & U)
    vals = [0, 1, 9, 10, 99, 100, 12345]
    for e in (64, 128, 192):
        base = 1 << e
        vals += [base - 2, base - 1, base, base + 1] if e < 192 else [base - 2, base - 1]
    # A limb that is zero BETWEEN two non-zero limbs is the classic carry trap: a
    # renderer that loses the remainder into limb 1 still gets these right at the top
    # and bottom and wrong in the middle.
    vals += [(1 << 128) | 1, (1 << 128) | (1 << 64), ((1 << 128) - 1) << 1 | 1]
    vals += [10 ** k for k in range(0, 58)]
    vals += [26112, 2063395607040, 267765117419520,
             1097051278789181790036112071176579186688]
    return [t(v) for v in vals if v < (1 << 192)]

def _f1_dec_published_masses():
    """Every layer mass in section 1 of the published aggregates artifact.

    Ties this gate to the artifact it protects: if f1_dec mis-renders a width, the
    number that would be WRONG in the repository is in the battery by construction
    rather than by my having thought to include it."""
    import os, re
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), _AGG_DOC)
    if not os.path.exists(path):
        raise RuntimeError(f"{_AGG_DOC} is absent -- the published masses this gate "
                           f"exists to protect cannot be read. Failure, not a pass.")
    out, in_s1 = [], False
    for line in open(path, encoding="utf-8"):
        if line.startswith("## "):
            in_s1 = line.startswith("## 1.")
            continue
        if not in_s1 or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 8 or not re.fullmatch(r"\d+", cells[0]):
            continue
        if not re.fullmatch(r"[\d,]+", cells[7]):
            continue
        out.append(int(cells[7].replace(",", "")))
    if len(out) != 31:
        raise RuntimeError(f"{_AGG_DOC} section 1 yielded {len(out)} masses, expected 31")
    return out

def f1_dec_roundtrip():
    """--f1-dec-roundtrip: gate solve's 192-bit decimal renderer across the whole
    range, including both limb boundaries and every published layer mass."""
    import os, subprocess
    here = os.path.dirname(os.path.abspath(__file__))
    binp = os.environ.get("SOLVE_BIN") or os.path.join(here, "solve")
    if not os.path.exists(binp):
        print(f"*FAIL* no solve binary at {binp} -- nothing to gate. Build it, or set")
        print("       SOLVE_BIN. A gate with no target must reject, not go quiet.")
        return 1
    U = (1 << 64) - 1
    try:
        masses = _f1_dec_published_masses()
    except RuntimeError as e:
        print(f"*FAIL* {e}")
        return 1
    trips = _f1_dec_battery() + [((m >> 128) & U, (m >> 64) & U, m & U) for m in masses]
    stdin = "".join(f"{a} {b} {c}\n" for (a, b, c) in trips)
    r = subprocess.run([binp, "--f1-dec-selftest"], input=stdin,
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(f"*FAIL* {binp} --f1-dec-selftest exited {r.returncode}")
        return 1
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    if len(lines) != len(trips):
        print(f"*FAIL* asked for {len(trips)} renderings, got {len(lines)}")
        return 1
    bad = 0
    widest = 0
    for line, (a, b, c) in zip(lines, trips):
        f = line.split()
        got = f[3]
        want = str((a << 128) | (b << 64) | c)
        if f[0] != str(a) or f[1] != str(b) or f[2] != str(c):
            print(f"*FAIL* echoed limbs {f[:3]} != submitted {(a, b, c)}")
            return 1
        if got != want:
            bad += 1
            if bad <= 8:
                print(f"  *** MISMATCH *** limbs=({a},{b},{c})")
                print(f"      solve says {got}")
                print(f"      exact is   {want}")
        else:
            widest = max(widest, len(want))
    if bad:
        print(f"*FAIL* {bad} of {len(trips)} renderings disagree with exact arithmetic")
        return 1
    print(f"all {len(trips)} renderings exact, widest {widest} digits "
          f"(battery + {len(masses)} published layer masses)")
    return 0

# ---------------------------------------------------------------------------
# F1U192 BINARY LAYOUT — independent read-back gate (2026-08-27, Q-267)
#
# THE OTHER HALF OF Q-43. Q-43 asked for a serialise/PARSE round-trip. solve.c has
# no decimal parser, so the parse side is the 24-byte binary limb layout written
# into f1c5_layer_NN.bin and read back by --resume-from-layers. That path had no
# independent check at all.
#
# WHY THE C ROUND-TRIP CANNOT SUPPLY ONE. Writer and reader are the same code, so a
# limb-order or endianness defect is written wrong, read wrong, and cancels exactly.
# The engine would resume and produce the right total from a file whose bytes are
# garbage to anyone else -- and the layer files are the published query substrate
# (SOLVE_F1_KEEP_LAYERS), so "anyone else" is the point of keeping them.
#
# THIS GATE reads the bytes from the documented layout in Python -- 72-byte header,
# then masks u32[nm], off u64[nm+1], keys u32[ne], vals 3x u64 little-endian [ne] --
# and checks the recovered final-layer mass against the rung total THIS FILE derives
# by its own DP. Nothing about the expectation comes from the engine.
_F1C5_HDR = "<8sIIIIQQQ5II"        # magic, version, n, k, start_exit, pl_hash,
                                    # n_masks, n_entries, b0[5], pad  -> 72 bytes

def _parse_f1c5_layer(path):
    """Read one f1c5_layer_NN.bin from the documented byte layout. Returns
    (hdr_dict, [values]). Raises on any structural inconsistency -- a short file, a
    bad magic, or a size that does not equal what the header says it should."""
    import struct
    raw = open(path, "rb").read()
    hs = struct.calcsize(_F1C5_HDR)
    if hs != 72:
        raise RuntimeError(f"header format computes to {hs} bytes, expected 72")
    if len(raw) < hs:
        raise RuntimeError(f"{path}: {len(raw)} bytes, shorter than the header")
    f = struct.unpack(_F1C5_HDR, raw[:hs])
    magic = f[0].rstrip(b"\x00").decode("ascii", "replace")
    if magic not in ("F1C5LAY1", "F1C3LAY1", "F1C5LAY2", "F1C3LAY2"):
        raise RuntimeError(f"{path}: magic {magic!r} is not a layer file")
    h = {"magic": magic, "version": f[1], "n": f[2], "k": f[3],
         "start_exit": f[4], "pl_hash": f[5], "n_masks": f[6], "n_entries": f[7]}
    nm, ne = h["n_masks"], h["n_entries"]
    h["blk"] = f[13]          # v1 leaves this zero; v2 records F1C5_OOC_BLK here
    if magic.endswith("2"):
        return h, _parse_v2_vals(path, raw, hs, nm, ne, h["blk"])
    want = hs + 4 * nm + 8 * (nm + 1) + 4 * ne + 24 * ne
    if len(raw) != want:
        raise RuntimeError(f"{path}: {len(raw)} bytes but header implies {want} "
                           f"(nm={nm}, ne={ne}) -- layout disagreement")
    off = hs + 4 * nm + 8 * (nm + 1) + 4 * ne
    vals = []
    for i in range(ne):
        l0, l1, l2 = struct.unpack_from("<QQQ", raw, off + 24 * i)
        vals.append(l0 | (l1 << 64) | (l2 << 128))
    return h, vals

def _parse_v2_vals(path, raw, hs, nm, ne, blk):
    """v2 (Q-268): hdr | masks | off | kidx[nblk+1] | vidx[nblk+1] | kblocks | vblocks,
    each block an RFC-1950 zlib stream of at most `blk` entries.

    This is the format the REAL runs write -- Stage F ran --f1-out-of-core, and its
    log says 'layer format: v2 (per-block gzip)'. The v1 reader gated in Q-267 was
    therefore reading bytes that no production artifact is made of."""
    import struct, zlib
    if blk <= 0:
        raise RuntimeError(f"{path}: v2 header records block size {blk}")
    nblk = (ne + blk - 1) // blk
    idx0 = hs + 4 * nm + 8 * (nm + 1)
    kidx = list(struct.unpack_from("<%dQ" % (nblk + 1), raw, idx0))
    vidx = list(struct.unpack_from("<%dQ" % (nblk + 1), raw, idx0 + 8 * (nblk + 1)))
    kbase = idx0 + 2 * 8 * (nblk + 1)
    vbase = kbase + (kidx[nblk] if nblk else 0)
    want = vbase + (vidx[nblk] if nblk else 0)
    if len(raw) != want:
        raise RuntimeError(f"{path}: {len(raw)} bytes but v2 index implies {want} "
                           f"(nm={nm}, ne={ne}, nblk={nblk}) -- layout disagreement")
    vals = []
    for b in range(nblk):
        e0, e1 = b * blk, min((b + 1) * blk, ne)
        blob = raw[vbase + vidx[b]: vbase + vidx[b + 1]]
        out = zlib.decompress(blob)
        if len(out) != 24 * (e1 - e0):
            raise RuntimeError(f"{path}: block {b} inflates to {len(out)} bytes, "
                               f"expected {24 * (e1 - e0)}")
        for i in range(e1 - e0):
            l0, l1, l2 = struct.unpack_from("<QQQ", out, 24 * i)
            vals.append(l0 | (l1 << 64) | (l2 << 128))
    return vals

def f1u192_binary_roundtrip():
    """--f1u192-binary-roundtrip: build the n=9 rung's layer files with solve, then
    read the FINAL layer back from raw bytes in Python and check its mass against
    this file's own independent count. Returns 0 iff they agree."""
    import os, subprocess, tempfile, shutil
    here = os.path.dirname(os.path.abspath(__file__))
    binp = os.environ.get("SOLVE_BIN") or os.path.join(here, "solve")
    if not os.path.exists(binp):
        print(f"*FAIL* no solve binary at {binp} -- nothing to gate. A gate with no")
        print("       target must reject, not go quiet.")
        return 1
    # The expectation is derived HERE, not read from the engine's output.
    pl = _spec_to_pairs_ordered("3.0,3.1,3.2")
    b0 = _b0_first_completion(pl, 0)
    want = _count_c1c2c4c5(pl, 0, tuple(b0))
    # BOTH on-disk formats. v1 is what --layers-dir writes; v2 (per-block zlib) is
    # what --f1-out-of-core writes and therefore what every real Stage F / 560T
    # artifact is actually made of. Gating only v1 would gate bytes nothing ships.
    arms = [("v1", ["--layers-dir"], {}),
            ("v2", ["--f1-out-of-core"], {"SOLVE_F1_OOC_FORMAT": "v2"})]
    rc, v2_ok = 0, False
    for name, flag, extra_env in arms:
        d = tempfile.mkdtemp(prefix=f"f1u192_{name}_")
        try:
            env = dict(os.environ); env.update(extra_env)
            r = subprocess.run([binp, "--f1-exact-c1c2c4c5", "--f1-pairs", "9"]
                               + flag + [d], capture_output=True, text=True, env=env)
            if r.returncode != 0:
                print(f"*FAIL* [{name}] solve exited {r.returncode} building the n=9 layers")
                rc = 1; continue
            fp = os.path.join(d, "f1c5_layer_09.bin")
            if not os.path.exists(fp):
                print(f"*FAIL* [{name}] no f1c5_layer_09.bin; got {sorted(os.listdir(d))}")
                rc = 1; continue
            try:
                h, vals = _parse_f1c5_layer(fp)
            except Exception as e:
                print(f"*FAIL* [{name}] {e}")
                rc = 1; continue
            # The full-mask layer is a single orbit of size 1, so its mass is the plain
            # sum of the stored values -- no group arithmetic needed, and therefore no
            # chance of importing the engine's symmetry assumptions into the check.
            got = sum(vals)
            print(f"[{name}] layer 9: magic={h['magic']} version={h['version']} "
                  f"n={h['n']} k={h['k']} n_masks={h['n_masks']} "
                  f"n_entries={h['n_entries']} ({len(vals)} read)")
            exp_magic = "F1C5LAY2" if name == "v2" else "F1C5LAY1"
            if h["magic"] != exp_magic or h["version"] != (2 if name == "v2" else 1):
                print(f"*FAIL* [{name}] expected {exp_magic}/v{2 if name=='v2' else 1}; "
                      f"this arm did not exercise the format it claims to")
                rc = 1; continue
            if not (h["n"] == 9 and h["k"] == 9 and h["n_masks"] == 1):
                print(f"*FAIL* [{name}] final layer header is not the full-mask layer of n=9")
                rc = 1; continue
            if got != want:
                print(f"  *** MISMATCH *** [{name}] bytes decode to {got:,}")
                print(f"                   independent count is {want:,}")
                print("  Writer and reader inside solve would agree with each other on")
                print("  these bytes; only an outside reader can see this.")
                rc = 1; continue
            print(f"[{name}] binary read-back {got:,} == independent count {want:,}  [ok]")
            if name == "v2":
                v2_ok = True
        finally:
            shutil.rmtree(d, ignore_errors=True)
    # MULTI-BLOCK. The two arms above prove nothing about v2's block seam: n=9's
    # final layer is 6 entries and NO rung at n<=13 reaches the 65536-entry block
    # size at all (measured: the widest n=13 layer is 11,102 entries). A gate that
    # never crosses a block boundary cannot see a block-boundary defect -- the same
    # coverage-is-about-VALUES lesson Q-43 taught one tick earlier. n=16 reaches
    # 89,388 entries, so it does cross, and it builds in about four seconds.
    if rc == 0:
        rc = _v2_multiblock_structural(binp)
    # Explicit verdict token: a harness must not have to infer pass from output shape.
    if v2_ok and rc == 0:
        print("F1U192_V2_LAYOUT=GATED")
    return rc

def _v2_multiblock_structural(binp):
    """Sweep every kept n=16 v2 layer and check the block seam structurally.

    Mass is NOT checked here: layers below the top have many canonical masks and
    weighting them needs the symmetry group, which would import the engine's own
    assumptions into the expectation. What IS checked is everything the group is not
    needed for -- index arithmetic, exact inflate sizes per block, and the entry
    total -- which is precisely where a block-boundary defect lives."""
    import os, subprocess, tempfile, shutil
    d = tempfile.mkdtemp(prefix="f1u192_mb_")
    try:
        env = dict(os.environ)
        env.update({"SOLVE_F1_OOC_FORMAT": "v2", "SOLVE_F1_KEEP_LAYERS": "1"})
        r = subprocess.run([binp, "--f1-exact-c1c2c4c5", "--f1-pairs", "16",
                            "--f1-out-of-core", d],
                           capture_output=True, text=True, env=env)
        if r.returncode != 0:
            print(f"*FAIL* [v2/multiblock] solve exited {r.returncode} at n=16")
            return 1
        files = sorted(x for x in os.listdir(d) if x.startswith("f1c5_layer_"))
        seen_multi, checked = 0, 0
        for fn in files:
            try:
                h, vals = _parse_f1c5_layer(os.path.join(d, fn))
            except Exception as e:
                print(f"*FAIL* [v2/multiblock] {e}")
                return 1
            ne, blk = h["n_entries"], h["blk"]
            if len(vals) != ne:
                print(f"*FAIL* [v2/multiblock] {fn}: decoded {len(vals)} entries, "
                      f"header says {ne}")
                return 1
            nblk = (ne + blk - 1) // blk if blk else 0
            if nblk > 1:
                seen_multi += 1
            checked += 1
        # ASSERT THE COVERAGE THIS ARM CLAIMS. Without this the arm would report a
        # clean sweep having crossed no block boundary at all, which is the silent
        # non-coverage failure, not a pass.
        if seen_multi == 0:
            print(f"*FAIL* [v2/multiblock] swept {checked} layer(s) but NONE had more "
                  f"than one block -- the block seam was never exercised")
            return 1
        print(f"[v2/multiblock] {checked} n=16 layer(s) structurally consistent; "
              f"{seen_multi} crossed the {65536}-entry block seam  [ok]")
        return 0
    finally:
        shutil.rmtree(d, ignore_errors=True)

# ---------------------------------------------------------------------------
# ORBIT WIDTHS — Burnside gate on the canonical_masks column (2026-08-27, Q-266)
#
# THE SEAM THIS CLOSES. reports/FULL31_EXACT_AGGREGATES.md ships seven columns and
# gated exactly one. `mass` is independently recounted; `states`, `entries`, `V_k`
# and layer bytes are marked engine-internal telemetry and explicitly not citable.
# `canonical_masks` sits between the two and was in neither camp: it is a property
# of the OBJECT -- the number of orbits of k-subsets of the 31 free pairs under the
# 24-element pair-permutation quotient -- yet it had no instrument, while a closed
# form has been available all along.
#
# THE METHOD. Burnside: #orbits = (1/|G|) * sum over g of #k-subsets fixed by g, and
# a permutation fixes a subset iff the subset is a union of its cycles, so the fixed
# counts are the coefficients of prod over cycles of (1 + x^len). Exact integer
# arithmetic, 24 polynomial multiplications, milliseconds.
#
# INDEPENDENCE. The 24 permutations are DERIVED here from _commuting_bitperms() --
# the same construction _derive_pair_orbits() already uses to refuse to trust a
# transcribed table -- not read from solve.c and not read from the artifact. The
# engine's agreement with this count is therefore a real coincidence of two
# derivations, not a restatement.
def _induced_pair_perms():
    """The pair-permutation quotient, derived. Returns a set of 31-tuples mapping
    free-pair index i (1..31) to its image, one entry per DISTINCT induced action.

    The 48 commuting bit-permutations act on hexagrams; each maps canonical pairs to
    canonical pairs, so each induces a permutation of the pair indices. The kernel of
    that induction collapses 48 down -- solve.c's own group self-check reports the
    quotient as 24 pair-perms, and this arrives at 24 without consulting it."""
    index_of = {frozenset(p): i for i, p in enumerate(PAIRS)}
    perms = set()
    for g in _commuting_bitperms():
        img = []
        for j in range(1, 32):
            a, b = PAIRS[j]
            k = index_of.get(frozenset((_apply_bitperm(g, a), _apply_bitperm(g, b))))
            if k is None:
                raise RuntimeError("induced perm moved a canonical pair off the pairing")
            img.append(k)
        perms.add(tuple(img))
    return perms

def _cycle_lengths(img):
    """Cycle-type of a permutation given as images of 1..31 (1-based values)."""
    n = len(img)
    seen = [False] * n
    out = []
    for i in range(n):
        if seen[i]:
            continue
        L, j = 0, i
        while not seen[j]:
            seen[j] = True
            j = img[j] - 1
            L += 1
        out.append(L)
    return out

def _orbit_widths():
    """Burnside count of orbits of k-subsets of the 31 free pairs, for k = 0..31."""
    perms = _induced_pair_perms()
    tot = [0] * 32
    for img in perms:
        poly = [1] + [0] * 31          # generating function of fixed subsets
        for L in _cycle_lengths(img):
            nxt = [0] * 32
            for d in range(32):
                if poly[d]:
                    nxt[d] += poly[d]                      # cycle absent
                    if d + L < 32:
                        nxt[d + L] += poly[d]              # cycle wholly present
            poly = nxt
        for d in range(32):
            tot[d] += poly[d]
    g = len(perms)
    out = []
    for k in range(32):
        q, r = divmod(tot[k], g)
        if r:
            raise RuntimeError(f"Burnside sum at k={k} is not divisible by |G|={g} "
                               f"-- the induced action is not a group action")
        out.append(q)
    return out, g

def _published_canonical_masks():
    """The canonical_masks column of section 1 of the published artifact."""
    import os, re
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), _AGG_DOC)
    if not os.path.exists(path):
        raise RuntimeError(f"{_AGG_DOC} is absent -- nothing to gate. Failure, not a pass.")
    got, in_s1 = {}, False
    for line in open(path, encoding="utf-8"):
        if line.startswith("## "):
            in_s1 = line.startswith("## 1.")
            continue
        if not in_s1 or not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 8 or not re.fullmatch(r"\d+", cells[0]):
            continue
        if not re.fullmatch(r"[\d,]+", cells[1]):
            continue
        got[int(cells[0])] = int(cells[1].replace(",", ""))
    missing = [k for k in range(1, 32) if k not in got]
    if missing:
        raise RuntimeError(f"{_AGG_DOC} has no canonical_masks for layer(s) {missing}")
    return got

def recount_orbit_widths(n):
    """--recount-orbit-widths N: gate the published canonical_masks column against a
    Burnside count over the independently derived pair-permutation quotient."""
    if n != 31:
        print(f"--recount-orbit-widths: n={n} not supported; the published table is n=31.")
        return 2
    try:
        pub = _published_canonical_masks()
    except RuntimeError as e:
        print(f"*FAIL* {e}")
        return 1
    widths, g = _orbit_widths()
    print(f"quotient derived from the 48 commuting bit-perms: |G| = {g} pair-perms")
    # C(31,k) must equal the orbit-size-weighted total; a cheap structural check that
    # the Burnside numbers describe the right ambient set before comparing anything.
    if widths[0] != 1:
        print(f"*FAIL* Burnside says {widths[0]} orbits of the empty set")
        return 1
    bad = 0
    for k in range(1, 32):
        ok = (widths[k] == pub[k])
        if not ok:
            bad += 1
            print(f"  layer {k:2d}: Burnside {widths[k]:,}  published {pub[k]:,}  "
                  f"[*** MISMATCH ***]")
    if bad:
        print(f"*FAIL* {bad} of 31 canonical_masks disagree with {_AGG_DOC}")
        return 1
    print(f"all 31 canonical_masks MATCH {_AGG_DOC} "
          f"(widest {max(widths[1:]):,} at k={widths.index(max(widths[1:]))})")
    print("ORBIT_WIDTHS=GATED")
    return 0

# TR-5 Verification Guide's sigma-related 23-pair prefix (pair, orient).
_SIGMA_PREFIX = [(22, 1), (28, 0), (3, 1), (21, 1), (26, 0), (6, 1), (11, 0),
                 (5, 0), (19, 0), (27, 0), (7, 1), (16, 1), (30, 1), (14, 0),
                 (20, 0), (18, 1), (25, 0), (24, 1), (1, 1), (15, 0), (4, 0),
                 (9, 0)]

def _exact_subtree(prefix):
    """Exact deterministic count of the C1-C5 backtracking tree below a fixed
    (pair, orient) prefix — returns (tree_nodes, leaves, canonical_leaves,
    canonical_and_C6C7).

    The tree object is the enumerator's: states are pair-sequences from the
    forced (63, 0) start; a placement must pass boundary distance != 5 (C2)
    and keep the running COMBINED 63-transition multiset (within + boundary,
    including pair 0's within d=6) dominated by C5's {1:2,2:20,3:13,4:19,6:9};
    tree_nodes counts every reached state including the prefix root; canonical
    leaves additionally pass C3 (sum |pos(v)-pos(v^63)| <= 776).  The
    internal-node convention is the published instrument's (SEARCH_SPACE_SIZE
    §Method: live-child states of the pruned walk); the implementation here is
    clean-room."""
    budget = [0] * 7
    for i in range(63):
        budget[hamming(KW[i], KW[i + 1])] += 1
    if not (budget == [0, 2, 20, 13, 19, 0, 9]):
        raise AssertionError('guard failed: budget == [0, 2, 20, 13, 19, 0, 9]')
    budget[6] -= 1                              # pair 0's within transition
    seq = [63, 0] + [0] * 62
    slotp = [0] * 32                            # pair index placed at each slot
    used = 1
    last = 0
    step = 1
    for (p, o) in prefix:
        slotp[step] = p
        a, b = PAIRS[p]
        f, s = (b, a) if o else (a, b)
        bd = hamming(last, f)
        if not (bd != 5 and budget[bd] > 0):
            raise AssertionError("prefix infeasible (boundary)")
        budget[bd] -= 1
        wd = hamming(f, s)
        if not (budget[wd] > 0):
            raise AssertionError("prefix infeasible (within)")
        budget[wd] -= 1
        seq[2 * step], seq[2 * step + 1] = f, s
        used |= 1 << p
        last = s
        step += 1
    stats = [0, 0, 0, 0]                # nodes, leaves, canonical, canon+C6/C7

    def rec(st, lst, usedm):
        stats[0] += 1
        if st == 32:
            stats[1] += 1
            pos = [0] * 64
            for i, v in enumerate(seq):
                pos[v] = i
            if sum(abs(pos[v] - pos[v ^ 63]) for v in range(64)) <= 776:
                stats[2] += 1
                # C6/C7 (SPECIFICATION.md): pairs 24,25 at slots 24,25 (C7)
                # and pairs 26,27 at slots 26,27 (C6), orientation free
                if slotp[24:28] == [24, 25, 26, 27]:
                    stats[3] += 1
            return
        for p in range(1, 32):
            if (usedm >> p) & 1:
                continue
            a, b = PAIRS[p]
            for (f, s) in ((a, b), (b, a)):
                bd = hamming(lst, f)
                if bd == 5 or budget[bd] == 0:
                    continue
                budget[bd] -= 1
                wd = hamming(f, s)
                if budget[wd] == 0:
                    budget[bd] += 1
                    continue
                budget[wd] -= 1
                seq[2 * st], seq[2 * st + 1] = f, s
                slotp[st] = p
                rec(st + 1, s, usedm | (1 << p))
                budget[wd] += 1
                budget[bd] += 1

    rec(step, last, used)
    return tuple(stats)

# Cross-instrument subtree anchors AWAY from King Wen's neighbourhood
# (2026-08-06).  The KW-following anchors in recount_subtree() all sit in
# KW's own corner of the tree, and their leaf C3 values cluster at the 776
# threshold (measured with this file's own walk: 5-free 776..808, 7-free
# 752..816, 9-free 752..928) — so a C3 defect that manifests only far from
# that neighbourhood, in either direction (falsely REJECTING sequences that
# comfortably pass, or falsely ACCEPTING sequences that clearly fail), would
# escape every one of them.  The three prefixes below were drawn at random
# from the C1-C5 tree by `solve --knuth-dump-prefix 24 <seed>` (seeds 43, 9,
# 112; depth 24 = 7 free positions, chosen to keep each anchor sub-second in
# CPython) and land far from KW's prefix.  Each expectation 4-tuple
# (tree_nodes, leaves_C1C2C4C5, canonical_leaves, canonical_and_C6C7) was
# computed by the OTHER instrument, solve.c's exact deterministic mode:
#     ulimit -s 9216      # --estimate-knuth segfaults at the default 8 MB
#                         # stack (main-frame + 1.05 MB KnuthArg arg[256])
#     ./solve --estimate-knuth 0 <p1> <o1> ... <p24> <o24>
# (run 2026-08-06 against the sha-anchored solve.c; <0.5 s each), so these
# gates are a two-instrument cross-check of the C3 predicate in BOTH
# directions, not verify.py grading its own homework.  The instruments'
# prefix conventions were confirmed identical on all three published KW
# anchors AND on the mixed-orientation sigma-related prefix first.  One
# caveat: solve.c's exact mode does not print the C6/C7 tally, so the 0 in
# the fourth slot is definition-forced rather than cross-computed (C7
# requires pair 24 AT slot 24; these prefixes place pairs 10, 31, 20 there)
# — the substantive C6/C7 anchor remains the KW 9-free "exactly 8" (TR-4
# §4).  Measured leaf-C3 ranges (this file's walk, 2026-08-06):
#   PASS-LOW  (seed 43):  C3 528..624  — every leaf canonical, margin >= 152
#   FAIL-HIGH (seed 9):   C3 1024..1104 — zero canonical, margin >= 248
#   STRADDLE  (seed 112): C3 736..840 — 11,984 of 26,672 leaves canonical
# With the KW anchors, the C3 range exercised by this gate is 528..1104.
_CROSS_PREFIXES = (
    ("away-KW PASS-LOW (seed 43)",
     [(26, 0), (11, 0), (27, 0), (2, 1), (3, 0), (5, 0), (21, 1), (14, 1),
      (29, 0), (22, 1), (7, 0), (6, 1), (8, 0), (30, 1), (17, 0), (20, 0),
      (4, 1), (24, 1), (13, 0), (12, 1), (28, 1), (15, 0), (25, 1), (10, 1)],
     (35293, 1600, 1600, 0)),
    ("away-KW FAIL-HIGH (seed 9)",
     [(24, 0), (29, 0), (15, 1), (13, 1), (8, 0), (30, 1), (23, 1), (4, 0),
      (9, 1), (21, 0), (28, 1), (25, 0), (19, 1), (10, 1), (26, 0), (16, 1),
      (1, 0), (20, 1), (3, 1), (5, 0), (27, 1), (2, 0), (6, 0), (31, 1)],
     (22228, 1296, 0, 0)),
    ("away-KW STRADDLE (seed 112)",
     [(18, 0), (16, 1), (25, 1), (22, 0), (11, 1), (12, 1), (29, 0), (8, 1),
      (21, 0), (27, 1), (17, 0), (19, 1), (24, 1), (1, 0), (7, 1), (23, 0),
      (14, 0), (5, 0), (30, 1), (4, 0), (2, 0), (9, 0), (15, 0), (20, 1)],
     (95031, 26672, 11984, 0)),
)

# ===========================================================================
# THE ORIENTATION FIBER — STATE-SPACE ARITHMETIC FIRST  (2026-08-02)
# ===========================================================================
# This arithmetic is written and evaluated BEFORE the DP below, because the
# attempt that skipped it hard-rebooted an 8 GB orchestrator.
#
# (0) THE FORMULATION THAT MUST NEVER BE WRITTEN AGAIN
#     key = (slot i, accumulated orientation prefix o_1..o_i)
#       |keys| = Σ_{i=0..31} 2^i = 2^32 − 1 = 4,294,967,295
#       final layer alone = 2^31 = 2,147,483,648 dict entries
#                        ≈ 215 GB at CPython's ~100 B per small dict entry
#     → OOM, then reboot. The orientation vector is the ANSWER being counted;
#       the moment it enters the key the DP stops being a DP and becomes the
#       2^31 search it was supposed to replace.
#
# (1) THE FORMULATION USED HERE
#     key = (exit hexagram of slot i, budget consumed so far)
#       exit hexagram                    : 64
#       budget n = (n₁,n₂,n₃,n₄,n₆), 0 ≤ n_c ≤ B0_c
#       B0 = C5's 63-multiset − the within-pair multiset
#          = {1:2, 2:20, 3:13, 4:19, 6:9} − {2:12, 4:12, 6:8}
#          = {1:2, 2:8, 3:13, 4:7, 6:1}          Σ = 31   (SPECIFICATION.md §137)
#       |budgets| = Π (B0_c + 1) = 3·9·14·8·2 = 6,048
#       |states|  ≤ 64 × 6,048   = 387,072
#     — and that 387,072 bounds the WHOLE RUN, not one slot: Σ_c n_c = i
#       identically, so the slot index is a FUNCTION of the key rather than an
#       extra dimension. Transitions ≤ 2 per state → ≤ 774,144 edge relaxations.
#       Ratio to (0): 4,294,967,295 / 387,072 ≈ 1.11 × 10⁴ fewer states.
#
# (2) WHY IT IS A C2+C5 OBJECT ONLY
#     Within-pair distances are orientation-invariant (d(a,b) = d(b,a)) and the
#     within-pair multiset {2:12, 4:12, 6:8} is the same for every C1 ordering
#     under every orientation vector, so C5 reduces to the fixed budget B0 on
#     the 31 BETWEEN-pair distances, and C2 is implied by it (B0 has no 5).
#
# (3) C3 WITHOUT CARRYING THE PATH — the deliverable that removes the only
#     reason anyone wanted orientation bits in the key.
#     C3 = 16 + 8·G,  G = Σ over the 12 complement-couples of |slot(P) − slot(P′)|
#     (lean/C3Decomposition.lean; TR-11 §10(ii)). The 8 self-complementary pairs
#     sit at adjacent positions and contribute 1 each way whichever member leads
#     (the 16); inside a couple at slots i<j the two members' cross-distances sum
#     to 4(j−i) with both orientation bits cancelling. So G reads the SLOT MAP
#     alone: C3 is CONSTANT on a fiber, evaluated ONCE before the DP starts as a
#     single admissibility flag on the whole fiber — never as DP state. That is
#     `c3_of_ordering` below, 12 subtractions, no path, no prefix.
#
#     HONEST COUNTERFACTUAL (the question was asked, so it is answered rather
#     than dodged): C3 really is a GRAPH over pairs, not a chain over slots —
#     pair P constrains the pair holding its complement, which may sit at any
#     later slot. Had the orientation bits NOT cancelled, an exact DP would have
#     to carry the orientation bit of every couple left OPEN across the slot cut.
#     24 of the 32 pairs lie in 12 cross-couples, so the cut carries ≤ 12 bits:
#       |states| ≤ 64 × 6,048 × 2¹² = 1,585,446,912 ≈ 1.6 × 10⁹
#     ≈ 160 GB as a CPython dict → an exact DP would be INFEASIBLE in Python and
#     infeasible on this orchestrator in any language. The alternatives would
#     then be (a) a packed-array DP in C on a memory-sized VM (~13 GB at 8 B/cell)
#     under a min-cutwidth slot order, or (b) abandon exactness and report the
#     per-ordering bound as a range. Neither is needed: the identity makes the
#     coupling vanish. The dissolution is the result.
#
# (4) THE ANCHOR, DERIVED BY HAND — checkable without executing anything.
#     TR-1 §7 gives the C4-oriented fiber as 3·5·7·2¹⁴. In units of 2¹⁴:
#         C4-oriented  (opening 63,0) = 105 · 2¹⁴ = 1,720,320
#         flipped      (opening 0,63) =  60 · 2¹⁴ =   983,040   (= 15·2¹⁶)
#         pair-only C4 (both openings)= 165 · 2¹⁴ = 2,703,360
#     so EXACTLY   flipped / oriented =  60/105 =  4/7
#                  both    / oriented = 165/105 = 11/7
#     An 11/7 excess is therefore the arithmetic SIGNATURE of exactly one
#     unpinned bit — C4's opening orientation — and of nothing else. It is NOT
#     evidence of a loose C2/C3/C5: adding C3 multiplies a fiber count by exactly
#     1 or exactly 0 (it is constant on the fiber, (3)), never by 7/11. So a
#     routine returning 2,703,360 is under-CONSTRAINED in one specific place and
#     is fixed by pinning the opening, not by tightening anything else.
#     `_fiber_diagnose` turns that into a machine verdict.
#
#     The two openings are NOT equal (983,040 ≠ 1,720,320) even though
#     complementation is an exact symmetry of C1∩C2∩C3∩C5 (SPECIFICATION.md
#     §Complement Z₂). Complementation moves the PAIR ORDERING as well as the
#     orientations — comp{a,b} = {63−a, 63−b} is a different pair unless the pair
#     is self-complementary — so it does not act inside one ordering's fiber.
#     Reasoning "the symmetry doubles it" yields 3,440,640, a third distinct
#     wrong answer, classified separately below so the two are never conflated.
# ===========================================================================

_FIBER_CLS = (1, 2, 3, 4, 6)      # C2 forbids 5; 0 cannot occur between distinct hexagrams


def _fiber_diagnose(measured, oriented=1_720_320, flipped=983_040):
    """WHY a fiber count missed its anchor — not merely THAT it did.

    Pure integer arithmetic over the three published fiber sizes: no DP, no
    tables, no King Wen. That is deliberate. It lets tests.py drive this
    classifier through the exact historical defect it exists to catch (a
    routine that returned 2,703,360) WITHOUT running the routine it guards,
    which is what "prove the gate fires against its own motivating example"
    requires.

    Returns (verdict, evidence). The evidence always names the observed ratio,
    so a failure report says what the count was off BY and which constraint to
    look at — never just "MISMATCH".
    """
    from math import gcd
    both = oriented + flipped
    if measured == oriented:
        return ("OK", f"{measured:,} == TR-1 §7's C4-oriented fiber")
    if measured == both:
        return ("C4-OPENING-NOT-PINNED",
                f"{measured:,} = {oriented:,} + {flipped:,}: BOTH opening orientations "
                f"were summed, so this is the pair-only-C4 fiber. Ratio to the anchor is "
                f"exactly 11/7 (165·2¹⁴ / 105·2¹⁴) — the signature of one unpinned bit, "
                f"C4's opening. FIX: pin the opening hexagram to 63. Do NOT tighten "
                f"C2/C3/C5: C3 is constant on a fiber, so it cannot contribute a 7/11.")
    if measured == flipped:
        return ("OPENING-PINNED-TO-THE-WRONG-SIDE",
                f"{measured:,} is the opening-(0,63) fiber; ratio to the anchor is exactly "
                f"4/7. The opening WAS pinned — to 0 instead of 63.")
    if measured == 2 * oriented:
        return ("SYMMETRY-DOUBLED",
                f"{measured:,} = 2 × {oriented:,}: the complement-Z₂ trap. Complementation "
                f"permutes the PAIR ORDERING too, so it does not act inside one ordering's "
                f"fiber; the true both-openings total is {both:,}, not {2 * oriented:,}.")
    if measured == 0:
        return ("EMPTY-FIBER",
                "no orientation vector survived. B0, the distance-class set or the opening "
                "is wrong — a real ordering's own stored orientation is a member of its "
                "fiber by construction, so 0 is impossible for a correct routine.")
    g = gcd(abs(measured), oriented) or 1
    return ("UNCLASSIFIED",
            f"{measured:,} vs anchor {oriented:,}; ratio = {measured // g}/{oriented // g}. "
            f"Not 11/7 (unpinned opening), not 4/7 (wrong side), not 2 (symmetry-doubled), "
            f"not 0 — so this is NOT an opening-orientation defect. Check B0 (must be "
            f"(2,8,13,7,1), Σ=31) and the distance-class set (1,2,3,4,6).")


_FIBER_ANCHOR = None


def _fiber_anchor():
    """THE FIRST ASSERTION — King Wen's own fiber, before anything else answers.

    TR-1 §7's C4-oriented fiber is 1,720,320. Every public fiber entry point
    calls this before it returns a number, so a wrong budget table can never
    reach a caller. Memoized: one 31-step DP per process, not one per record.

    Raises RuntimeError carrying `_fiber_diagnose`'s verdict AND its reason.
    """
    global _FIBER_ANCHOR
    if _FIBER_ANCHOR is not None:
        return _FIBER_ANCHOR
    ident = list(range(32))
    oriented = _fiber_count_raw(ident, 63)
    flipped = _fiber_count_raw(ident, 0)
    checks = (
        ("C4-oriented fiber (TR-1 §7)",     oriented,                  1_720_320),
        ("flipped-opening fiber",           flipped,                     983_040),
        ("pair-only-C4 fiber",              oriented + flipped,        2_703_360),
        ("TR-1's 3·5·7·2¹⁴ factorization",  oriented,        3 * 5 * 7 * 2 ** 14),
        ("the exact 4/7 identity",          7 * flipped,          4 * oriented),
        ("the exact 11/7 identity",         7 * (oriented + flipped), 11 * oriented),
    )
    bad = [(n, got, want) for (n, got, want) in checks if got != want]
    if bad:
        verdict, why = _fiber_diagnose(oriented)
        detail = "; ".join(f"{n}: got {got:,}, want {want:,}" for n, got, want in bad)
        raise RuntimeError(f"FIBER ANCHOR FAILED [{verdict}] — {why}  ({detail})")
    _FIBER_ANCHOR = (oriented, flipped)
    return _FIBER_ANCHOR


_C3_COUPLES = None


def _c3_couples():
    """The complement-couple GRAPH on pair indices, plus its known-answer anchor.

    C3 couples each pair to the pair holding its complement, so it is a graph
    over pairs, not a chain along slots — which is exactly why a path-carrying
    DP looked necessary. It is not; see (3) in the header. Building the graph
    once lets `c3_of_ordering` evaluate C3 from the slot map alone.

    Returns (cross, selfc): the 12 two-element couples {p, q} with p < q, and
    the 8 self-complementary pairs (which contribute the constant 16).
    """
    global _C3_COUPLES
    if _C3_COUPLES is not None:
        return _C3_COUPLES
    idx = {frozenset(pr): p for p, pr in enumerate(PAIRS)}
    cross, selfc = [], []
    for p, (a, b) in enumerate(PAIRS):
        key = frozenset((a ^ 63, b ^ 63))
        if key not in idx:
            raise RuntimeError(f"c3: the complement of pair {p} is not a C1 pair — the "
                               f"pair set is not closed under complementation")
        q = idx[key]
        if q == p:
            selfc.append(p)
        elif p < q:
            cross.append((p, q))
    if len(cross) != 12 or len(selfc) != 8 or 2 * len(cross) + len(selfc) != 32:
        raise RuntimeError(f"c3: couple graph is malformed — {len(cross)} cross-couples and "
                           f"{len(selfc)} self-complementary pairs (want 12 and 8, 2·12+8=32)")
    # KNOWN-ANSWER ANCHOR, written before the routine is trusted: the identity
    # permutation IS King Wen's own slot map (PAIRS[i] is KW's pair at slot i),
    # and KW's C3 is 776 (SPECIFICATION.md §C3: 12.125 × 64).
    g = sum(abs(p - q) for p, q in cross)
    if 16 + 8 * g != 776:
        raise RuntimeError(f"c3: KNOWN-ANSWER ANCHOR FAILED — 16 + 8·G = {16 + 8 * g} on "
                           f"King Wen's own ordering, but KW's C3 is 776. G came out "
                           f"{g}, want {(776 - 16) // 8}.")
    _C3_COUPLES = (tuple(cross), tuple(selfc))
    return _C3_COUPLES


def c3_of_ordering(perm):
    """C3 EVALUATED WITHOUT CARRYING THE PATH.

    C3 = 16 + 8·G,  G = Σ over the 12 complement-couples of |slot(P) − slot(P′)|.
    G reads the SLOT MAP only, so:
      * C3 is independent of the orientation vector → CONSTANT on a fiber, and
        enters as one admissibility flag on the whole fiber, computed before the
        DP starts rather than inside it;
      * C3 is independent of the walk order → no prefix, no path, no DP state.
    Cost is 12 subtractions for any ordering. `perm[s]` is the pair index at
    slot s. Returns the integer C3 (King Wen's is 776; C3-valid means ≤ 776).
    """
    cross, _selfc = _c3_couples()
    if sorted(perm) != list(range(32)):
        raise ValueError("c3_of_ordering: perm is not a permutation of the 32 pairs")
    slot = [0] * 32
    for s, p in enumerate(perm):
        slot[p] = s
    return 16 + 8 * sum(abs(slot[p] - slot[q]) for p, q in cross)


def check_t5_c3(sol_bin, chunks_dir):
    """--check-t5-c3: independent recomputation of c3_total for the T5 mega-sample.

    WHY THIS GATE EXISTS. The T5 battery's load-bearing number is
    P(C3 <= 776) = 12.1288% over the exact-uniform C1&C2&C4&C5 sample, and it is what
    refutes the withdrawn "3.9th percentile" figure. That number came out of ONE pipeline:
    solve.py --encode-solutions -> solve.py --compute-stats -> parquet. A single pipeline
    agreeing with itself is not a check.

    So recompute c3_total from the ENCODED RECORDS using this file's own c3_of_ordering,
    which reaches C3 by a completely different route: the machine-checked identity
    C3 = 16 + 8*G over the 12 complement-couples' slot gaps (lean/C3Decomposition.lean),
    reading the SLOT MAP only -- no transition walk, no path, no orientation. solve.py's
    compute-stats walks the ordering. Same quantity, disjoint derivations.

    EVERY record is checked, not a subsample -- this project does not subsample, and at 12
    subtractions per ordering the full 1e6 is seconds.

    SCOPE, stated so this is not over-claimed: verify.py is an INDEPENDENT IMPLEMENTATION
    (it imports nothing from solve.py) but it is still PYTHON. This discharges the
    implementation-independence half of T5's cross-check gate, NOT the two-LANGUAGE half.
    A C-side per-record observable export does not exist and would be new solve.c surface.

    Emits T5_C3_AGREE=PASS/FAIL.
    """
    import glob, struct
    import numpy as np
    import pyarrow.parquet as pq

    with open(sol_bin, 'rb') as f:
        hdr = f.read(32)
        if hdr[:4] != b'ROAE':
            print('T5_C3_AGREE=FAIL bad magic in %s' % sol_bin); return 1
        ver, = struct.unpack('<I', hdr[4:8])
        count, = struct.unpack('<Q', hdr[8:16])
        print('[t5-c3] %s: version=%d records=%d' % (sol_bin, ver, count))

        files = sorted(glob.glob('%s/chunk_*.parquet' % chunks_dir))
        if not files:
            print('T5_C3_AGREE=FAIL no chunk_*.parquet in %s' % chunks_dir); return 1
        seen = mism = 0
        first = []
        for fp in files:
            want = pq.read_table(fp).column('c3_total').to_numpy()
            blob = f.read(32 * len(want))
            if len(blob) != 32 * len(want):
                print('T5_C3_AGREE=FAIL short read: records exhausted before parquet rows'); return 1
            for j in range(len(want)):
                rec = blob[32 * j:32 * j + 32]
                got = c3_of_ordering([b >> 2 for b in rec])
                if got != int(want[j]):
                    mism += 1
                    if len(first) < 5:
                        first.append((seen, int(want[j]), got))
                seen += 1
        # the record stream and the parquet rows must be the SAME length, or the comparison
        # silently checked a prefix and called it agreement
        leftover = f.read(32)
    if seen != count or leftover:
        print('T5_C3_AGREE=FAIL length mismatch: parquet rows=%d header count=%d trailing=%d'
              % (seen, count, len(leftover)))
        return 1
    for idx, w, g in first:
        print('  MISMATCH rec %d: parquet=%d verify.py=%d' % (idx, w, g))
    print('[t5-c3] compared %d records, mismatches %d' % (seen, mism))
    if mism == 0:
        print('T5_C3_AGREE=PASS')
        return 0
    print('T5_C3_AGREE=FAIL')
    return 1


def _fiber_dp():
    """Forward/backward transfer DP over King Wen's OWN pair sequence, varying only
    the 32 within-pair orientations.

    Two facts make the orientation fiber a small exact computation rather than a
    2^31 search, and both are re-derived here rather than assumed:
      * within-pair distances do not depend on orientation (a pair's two members are
        fixed; orientation only swaps their order), so constraining C5's full 63-value
        multiset is equivalent to constraining the 31 BETWEEN-pair values;
      * C3 = 16 + 8*G and the orientation bits cancel in G, so C3 is CONSTANT across
        the fiber and imposes nothing on it.
    So the fiber is exactly {orientation vectors : no boundary distance = 5 (C2), and
    the boundary multiset equals King Wen's own}. The budget B0 is recomputed from KW
    here, not copied from any report.

    Returns (B0, F, B) where F[i] maps (entry-hexagram-of-slot-i, budget-consumed) to
    the number of ways to reach it, and B[i] maps the same state to the number of
    completions from slot i through slot 31 landing exactly on B0.
    """
    from collections import Counter, defaultdict
    kwb = Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31))
    if set(kwb) - set(_FIBER_CLS):
        raise RuntimeError(f"fiber: KW boundary multiset has an out-of-class value: {dict(kwb)}")
    B0 = tuple(kwb.get(c, 0) for c in _FIBER_CLS)

    # backward: completions[i][(last, budget)] = ways to finish slots i..31 on exactly B0
    B = [defaultdict(int) for _ in range(33)]
    # seed at slot 32 (past the end): only the exactly-consumed budget completes
    B[32][None] = 1

    succ = lambda i, last, bud: _fiber_succ(i, last, bud, B0)

    # enumerate reachable states forward first, so the backward pass has a domain
    F = [defaultdict(int) for _ in range(33)]
    a, b = PAIRS[0]
    zero = (0,) * len(_FIBER_CLS)
    for o, (f, s) in enumerate(((a, b), (b, a))):
        F[1][(s, zero, f)] += 1
    for i in range(1, 32):
        for (last, bud, _open), cnt in F[i].items():
            for o, s, nb in succ(i, last, bud):
                F[i + 1][(s, nb, _open)] += cnt

    # backward counts, keyed the same way minus the opening marker
    Bk = [defaultdict(int) for _ in range(33)]
    for (last, bud, _open) in F[32]:
        Bk[32][(last, bud)] = 1 if bud == B0 else 0
    for i in range(31, 0, -1):
        seen = {(l, bd) for (l, bd, _o) in F[i]}
        for (last, bud) in seen:
            t = 0
            for o, s, nb in succ(i, last, bud):
                t += Bk[i + 1].get((s, nb), 0)
            Bk[i][(last, bud)] = t
    return B0, F, Bk

def recount_fiber():
    """A7: independently recount TR-1 §7's orientation fiber — the frozen dispositive
    null for the eleven-functional battery — and the forced/free structure of its bits."""
    B0, F, Bk = _fiber_dp()
    tot = {63: 0, 0: 0}
    for (last, bud, opening), cnt in F[1].items():
        tot[opening] = tot.get(opening, 0) + cnt * Bk[1].get((last, bud), 0)
    oriented = tot.get(63, 0)          # opening (63, 0) — C4 as defined
    flipped = tot.get(0, 0)            # opening (0, 63) — pair-only reading of C4
    both = oriented + flipped

    # which slots are genuinely free (both orientations occur somewhere in the fiber)?
    forced = []
    for i in range(1, 32):
        per = [0, 0]
        for (last, bud, opening), cnt in F[i].items():
            if opening != 63:
                continue               # forced-bit claim is stated on the C4-oriented fiber
            for o, s, nb in _fiber_succ(i, last, bud, B0):
                per[o] += cnt * Bk[i + 1].get((s, nb), 0)
        if per[0] == 0 or per[1] == 0:
            forced.append(i)

    print("=" * 74)
    print("verify.py --recount-fiber : TR-1 §7 orientation fiber, independent recount")
    print("transfer DP over KW's own pair order; B0 recomputed from KW, not copied")
    print("=" * 74)
    print(f"  boundary budget B0 (d=1,2,3,4,6)            : {B0}  (sum {sum(B0)})")
    rows = [
        ("C4-oriented fiber  (opening 63,0)", 1_720_320, oriented),
        ("pair-only C4 fiber (both openings)", 2_703_360, both),
        ("  of which opening (0,63)", 983_040, flipped),
    ]
    ok = True
    for name, pub, mine in rows:
        m = "MATCH" if pub == mine else "*** MISMATCH ***"
        ok &= (pub == mine)
        print(f"  {name:<42} published {pub:>10,}  ours {mine:>10,}  {m}")
    # TR-1 states the fiber size factors as 3*5*7*2^14
    fact = 3 * 5 * 7 * 2 ** 14
    print(f"  factorization 3·5·7·2¹⁴ = {fact:,}"
          f"                     {'MATCH' if fact == oriented else '*** MISMATCH ***'}")
    ok &= (fact == oriented)
    print(f"  forced bits among slots 1..31              : {forced if forced else 'none'}")
    print(f"    -> {31 - len(forced)} of 31 vary somewhere in the fiber"
          f"  (TR-1 says 30, forced slot 30) "
          f"{'MATCH' if forced == [30] else '*** CHECK ***'}")
    ok &= (forced == [30])
    print("=" * 74)
    if ok:
        print("RESULT: ALL MATCH — TR-1 §7's fiber is now two-instrument")
        return 0
    # Say WHY, not just THAT. `_fiber_diagnose` is pure arithmetic on the three
    # published sizes and is unit-tested against the historical 2,703,360 defect,
    # so this verdict is itself gated rather than advisory.
    verdict, why = _fiber_diagnose(oriented)
    print(f"RESULT: *** MISMATCH — verdict [{verdict}]")
    print(f"        {why}")
    return 1

def _fiber_succ(i, last, bud, B0):
    a, b = PAIRS[i]
    for o, (f, s) in enumerate(((a, b), (b, a))):
        if last is None:
            yield o, s, bud
            continue
        d = hamming(last, f)
        if d not in _FIBER_CLS:
            continue
        j = _FIBER_CLS.index(d)
        nb = list(bud); nb[j] += 1
        if nb[j] > B0[j]:
            continue
        yield o, s, tuple(nb)

# ---------------------------------------------------------------------------
# A1 (2026-08-01): the orientation fiber of an ARBITRARY C1 pair ordering.
#
# `_fiber_dp` / `recount_fiber` above answer TR-1 §7's question — the fiber of
# King Wen's OWN ordering, with the forced/free bit structure. The block below
# answers the *counting-convention* question instead. A record in solutions.bin
# is a PAIR ORDERING with orientation collapsed (SOLUTIONS_FORMAT.md §"The
# output counts unique pair orderings, not unique oriented sequences"), while
# the C1–C5 space estimate counts orientation-explicit SEQUENCES. The exact
# conversion between the two levels is the fiber size, ordering by ordering:
#
#     N = Σ over valid pair orderings P of |fiber(P)|      (sequences)
#     R = # of P with |fiber(P)| ≥ 1                       (records)
#     mean fiber = N / R = the orientation-dedup factor
#
# Which constraints see orientation at all:
#   C1 (pair structure)  orientation-BLIND — C1 fixes the SET of 32 pairs, and
#                        a pair is the same pair either way round.
#   C4 (opening)         pins pair {63,0} at slot 0 and, as defined, its
#                        orientation (63 then 0), so exactly 31 bits are free.
#   C2 (no distance 5)   orientation-SENSITIVE, but only across pair boundaries:
#                        d(a,b) = d(b,a), so the 32 within-pair distances are
#                        orientation-invariant — and none of them is 5.
#   C5 (distance multiset) orientation-SENSITIVE in the same place and for the
#                        same reason. The within-pair multiset is {2:12, 4:12,
#                        6:8} for EVERY C1 ordering under EVERY orientation
#                        vector, so C5 reduces to a fixed budget B0 on the 31
#                        BETWEEN-pair distances, identical for every ordering.
#   C3 (complement dist) orientation-BLIND: C3 = 16 + 8·G, G = Σ over the 12
#                        complement-couples of |slot(P) − slot(P′)|
#                        (lean/C3Decomposition.lean; TR-11 §10(ii)). The 8
#                        self-complementary pairs sit at adjacent positions and
#                        contribute 1 each way whichever member leads (the 16);
#                        inside a couple at slots i<j the two members' distances
#                        sum to 4(j−i) with both orientations cancelling. So C3
#                        is CONSTANT on a fiber — it decides WHICH orderings
#                        have a fiber, never which orientations are in it.
#
# The fiber is therefore exactly the set of orientation vectors whose 31
# between-pair distances avoid 5 and realise B0 — a transfer DP over
# (exit hexagram, budget consumed) in 31 steps. Exact, not a sample.
# ---------------------------------------------------------------------------

_FIBER_CODE_BITS = 13     # budget codes occupy 6,048 < 2^13 values
_FIBER_TABLES = None

def _fiber_tables():
    """Build (once) the residual between-pair budget B0 and the mixed-radix
    budget-increment tables the arbitrary-ordering DP runs on.

    B0 is DERIVED, not copied: C5's full 63-value multiset minus the
    orientation- and ordering-invariant within-pair multiset. It is then
    cross-checked against King Wen's own 31 between-pair distances, which must
    agree — two derivations of the same universal budget."""
    global _FIBER_TABLES
    if _FIBER_TABLES is not None:
        return _FIBER_TABLES
    from collections import Counter
    full = Counter(hamming(KW[i], KW[i + 1]) for i in range(63))
    within = Counter(hamming(a, b) for a, b in PAIRS)
    if 5 in within:
        raise RuntimeError("fiber: a within-pair distance is 5 — C1 and C2 would be "
                           "unsatisfiable together; tables are wrong")
    resid = full - within
    if sum(resid.values()) != 31 or (set(resid) - set(_FIBER_CLS)):
        raise RuntimeError(f"fiber: residual between-pair budget is malformed: {dict(resid)}")
    betw = Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31))
    if resid != betw:
        raise RuntimeError(f"fiber: C5-minus-within budget {dict(resid)} disagrees with "
                           f"KW's own between-pair multiset {dict(betw)}")
    B0 = tuple(resid.get(c, 0) for c in _FIBER_CLS)

    ham = [[bin(x ^ y).count('1') for y in range(64)] for x in range(64)]
    clsidx = [-1] * 7
    for j, c in enumerate(_FIBER_CLS):
        clsidx[c] = j
    pv, r = [], 1
    for c in B0:
        pv.append(r)
        r *= (c + 1)
    ncode = r
    if ncode > (1 << _FIBER_CODE_BITS):
        raise RuntimeError(f"fiber: budget code space {ncode} exceeds the packing width")
    full_code = sum(B0[j] * pv[j] for j in range(len(B0)))
    add = []
    for j in range(len(B0)):
        col = [-1] * ncode
        for code in range(ncode):
            if (code // pv[j]) % (B0[j] + 1) < B0[j]:
                col[code] = code + pv[j]
        add.append(col)
    _FIBER_TABLES = (B0, ham, clsidx, add, full_code)
    return _FIBER_TABLES

def _fiber_count_raw(perm, opening=63, fixed=None):
    """The DP itself, UNANCHORED — call `fiber_count` instead.

    Split out so `_fiber_anchor` can compute King Wen's fiber without calling
    the anchored wrapper and recursing. Nothing else should call this.

    EXACT size of the orientation fiber over the pair ordering `perm`.

    `perm` is a list of 32 pair indices (the record's pair identities, slot by
    slot); `opening` is the hexagram leading slot 0 — 63 for C4 as defined
    (the C4-oriented fiber), 0 for the flipped opening of the pair-only reading.
    `fixed`, if given, maps slot -> orientation bit (0 = PAIRS[p] as stored,
    1 = reversed, matching the record encoding) and counts only the sub-fiber
    agreeing with it — the hook the brute-force cross-check in tests.py drives.

    Returns the number of orientation vectors for the remaining 31 slots that
    satisfy C2 and C5 — which, C3 being constant on the fiber and C1 being
    orientation-blind, is the number of C1–C5 sequences collapsing to this one
    record, provided the record satisfies C3 at all (every record in a
    solutions.bin does, by construction).

    This is a DP over 31 steps, not a search over 2^31 vectors, and not a
    sample. Cost is ~0.2 ms per ordering in CPython."""
    B0, ham, clsidx, add, full_code = _fiber_tables()
    if sorted(perm) != list(range(32)):
        raise ValueError("fiber_count: perm is not a permutation of the 32 pairs")
    a0, b0 = PAIRS[perm[0]]
    if {a0, b0} != {63, 0}:
        raise ValueError("fiber_count: C4 requires pair {63, 0} at slot 0")
    if opening == a0:
        exit0 = b0
    elif opening == b0:
        exit0 = a0
    else:
        raise ValueError("fiber_count: opening must be 63 or 0")
    cur = {(exit0 << _FIBER_CODE_BITS): 1}
    mask = (1 << _FIBER_CODE_BITS) - 1
    for i in range(1, 32):
        a, b = PAIRS[perm[i]]
        opts = ((a, b), (b, a))
        if fixed is not None and i in fixed:
            opts = (opts[fixed[i]],)
        nxt = {}
        get = nxt.get
        for key, cnt in cur.items():
            row = ham[key >> _FIBER_CODE_BITS]
            code = key & mask
            for f, s in opts:
                # C2 (no 5) and "must be a class C5 budgets" are the same test
                # here: B0 has no 5, so C5 already implies C2 — see
                # test_the_two_redundancies_in_the_fiber_dp_are_real.
                j = clsidx[row[f]]              # distance 5 (and 0) -> -1
                if j < 0:
                    continue
                nc = add[j][code]               # C5: class j budget exhausted -> -1
                if nc < 0:
                    continue
                k = (s << _FIBER_CODE_BITS) | nc
                nxt[k] = get(k, 0) + cnt
        cur = nxt
        if not cur:
            return 0
    # 31 boundaries placed and every class capped at B0 => any survivor is exactly on
    # budget; the filter is kept so the exactness is asserted rather than argued.
    return sum(c for k, c in cur.items() if (k & mask) == full_code)


def fiber_count(perm, opening=63, fixed=None):
    """EXACT orientation-fiber size over `perm`, King-Wen-anchored.

    The public entry point. `_fiber_anchor()` runs FIRST — before this call can
    return any number — so King Wen's 1,720,320 is asserted ahead of the answer
    rather than checked after it. The anchor is memoized, so the guarantee costs
    one 31-step DP per process even when sweeping millions of records.

    See `_fiber_count_raw` for the DP and its arguments.
    """
    _fiber_anchor()
    return _fiber_count_raw(perm, opening, fixed)

def _fiber_records(path, limit=None):
    """Yield (index, perm, orient) for each record of a solutions.bin, gzipped or
    raw. Small-file path: the whole file is read into memory, so this is for the
    repo's sample artifact, not for a multi-hundred-GB canonical."""
    with open(path, 'rb') as fh:
        head = fh.read(2)
    blob = gzip.open(path, 'rb').read() if head == b'\x1f\x8b' else open(path, 'rb').read()
    if blob[:4] != b'ROAE':
        raise RuntimeError(f"{path}: not a ROAE solutions.bin (magic {blob[:4]!r})")
    n = struct.unpack('<Q', blob[8:16])[0]
    if 32 + 32 * n != len(blob):
        raise RuntimeError(f"{path}: header says {n} records but the body is "
                           f"{len(blob) - 32} bytes")
    if limit is not None:
        n = min(n, limit)
    for i in range(n):
        rec = blob[32 + 32 * i: 64 + 32 * i]
        yield i, [(x >> 2) & 0x3F for x in rec], [(x >> 1) & 1 for x in rec]

def fiber_sweep(path=None):
    """A1: measure the ORIENTATION-FIBER FACTOR — the exact conversion between
    the two counting levels the suite publishes side by side.

    Gates first (KW's own fiber, three published values, plus agreement with the
    independent `_fiber_dp` instrument), then, if a solutions.bin is present,
    reports the exact fiber-size distribution over its records."""
    import math
    B0, _ham, _ci, _add, _fc = _fiber_tables()
    ident = list(range(32))
    print("=" * 78)
    print("verify.py --fiber-sweep : the orientation-fiber factor, measured")
    print("=" * 78)
    print(f"  residual between-pair budget B0 (d=1,2,3,4,6) : {B0}  (sum {sum(B0)})")
    print("  derived as C5's 63-value multiset minus the within-pair multiset,")
    print("  cross-checked against KW's own 31 between-pair distances.")
    print()
    print("  GATE — King Wen's own pair ordering (TR-1 §7), asserted FIRST:")
    ok = True
    try:
        oriented, flipped = _fiber_anchor()
    except RuntimeError as e:
        print(f"    *** {e}")
        print("\n*** GATE FAILED — the fiber routine is wrong; every number below is void.")
        return 1
    for name, pub, mine in (("C4-oriented fiber  (opening 63,0)", 1_720_320, oriented),
                            ("pair-only C4 fiber (both openings)", 2_703_360, oriented + flipped),
                            ("  of which opening (0,63)", 983_040, flipped),
                            ("factorization 3·5·7·2¹⁴", 3 * 5 * 7 * 2 ** 14, oriented)):
        good = (pub == mine)
        ok &= good
        print(f"    {name:<38} published {pub:>10,}  ours {mine:>10,}  "
              f"{'MATCH' if good else '*** MISMATCH ***'}")
    # cross-instrument: the KW-only transfer DP above must agree slot for slot
    _B0x, Fx, Bkx = _fiber_dp()
    tot = {63: 0, 0: 0}
    for (last, bud, op), cnt in Fx[1].items():
        tot[op] = tot.get(op, 0) + cnt * Bkx[1].get((last, bud), 0)
    agree = (tot.get(63, 0) == oriented and tot.get(0, 0) == flipped)
    ok &= agree
    print(f"    {'vs the independent _fiber_dp instrument':<38} "
          f"{'MATCH' if agree else '*** MISMATCH ***'}")
    if not ok:
        print("\n*** GATE FAILED — the fiber routine is wrong; every number below is void.")
        return 1

    print()
    print("  PROVEN floor on the dedup factor (no compute, no sampling):")
    print("    a record is a permutation of the 31 non-opening pairs, so the number")
    print("    of records R is at most 31! = 8.222839e33. With the EXACT")
    print("    |C1∩C2∩C4∩C5| = 1.097051e39 (TR-11 §9), mean fiber = N/R ≥ N/31! =")
    print("    1.3342e5. The published '~4×' orientation-dedup factor is therefore")
    print("    low by at least four and a half orders of magnitude.")

    if path is None:
        path = 'solutions.bin'
    if not os.path.exists(path):
        print(f"\n  (no {path} present — sample sweep skipped; the gate above is the result)")
        return 0

    print()
    print(f"  SAMPLE SWEEP — exact fiber of every record in {path}:")
    sizes, zero, kw_seen = [], 0, False
    for i, perm, orient in _fiber_records(path):
        if perm == ident:
            kw_seen = True
        f = fiber_count(perm, 63)
        if f == 0:
            zero += 1
        sizes.append(f)
    if zero:
        print(f"    *** {zero} record(s) have an EMPTY fiber — impossible, since the "
              f"record's own stored orientation is in it. The routine is wrong.")
        return 1
    sizes.sort()
    n = len(sizes)
    am = sum(sizes) / n
    gm = math.exp(sum(math.log(s) for s in sizes) / n)
    print(f"    records swept                : {n:,}"
          f"{'  (King Wen included)' if kw_seen else ''}")
    print(f"    empty fibers                 : 0  (every record admits its own orientation)")
    print(f"    min / median / max           : {sizes[0]:,} / {sizes[n // 2]:,} / {sizes[-1]:,}")
    print(f"    ARITHMETIC MEAN (dedup factor over this population) : {am:,.1f}")
    print(f"    geometric mean               : {gm:,.1f}")
    print(f"    King Wen's own fiber         : {oriented:,}"
          f"   (percentile {100.0 * sum(1 for s in sizes if s < oriented) / n:.2f})")
    print()
    print("    SCOPE — this is the mean over ONE budget-truncated sample, not over the")
    print("    C1–C5 space. It is an unbiased estimate of N/R only for the population")
    print("    this file enumerates. See A1_ORIENTATION_FIBER_MEASUREMENT.md for the")
    print("    run that would settle the whole-space value.")
    print("=" * 78)
    return 0

def _gender6(h):
    """Schulz 1990 / Cook 2006 minority-line gender of a 6-bit hexagram
    (published definition: SOLVE_C_CLI.md §--rc4b-verify): popcount < 3 male
    ('M'), popcount > 3 female ('F'); popcounts {0, 3, 6} exempt ('N').
    Inversion (rev) preserves popcount, so gender is inversion-class-invariant."""
    pc = bin(h).count('1')
    return 'N' if pc in (0, 3, 6) else ('M' if pc < 3 else 'F')

def _rc4_violations_indep(seq):
    """Independent implementation of the Schulz-1990 gender/position-parity
    violation count, rebuilt from the PUBLISHED definition (SOLVE_C_CLI.md
    §--rc4b-verify; LITERATURE_RULES_POPULATION_TESTS.md §Schulz gender rule):
    over the 36 inversion-class positions in FIRST-OCCURRENCE order, a male
    class (popcount < 3) belongs at an odd class position and a female class
    (popcount > 3) at an even one; exempt classes ({0,3,6}) never violate.
    Returns (violation_count, sorted list of violating class positions,
    1-based).  KW's published anchors: exactly 2, at class positions 25/26."""
    order, seen = [], set()
    for h in seq:
        cls = min(h, _rev6(h))            # inversion-class representative
        if cls not in seen:
            seen.add(cls)
            order.append(cls)
    viol = []
    for i, cls in enumerate(order):
        p = i + 1                          # 1-based class position
        g = _gender6(cls)
        if (g == 'M' and p % 2 == 0) or (g == 'F' and p % 2 == 1):
            viol.append(p)
    return len(viol), viol

def _gender_null_distribution():
    """Exact distribution of rc4 violations under TR-8's pair-only (C1) null —
    KW's 32 canonical pairs in uniformly random order, each independently in
    either orientation (32!·2^32 members) — computed two structurally different
    exact ways and cross-asserted, returned as {violations: Fraction}.

    Structure (derived here from the C1 primitives, not copied): 28 of the
    pairs are inversion pairs (both members one class); 4 are
    palindrome-complement pairs (two singleton classes each), 28 + 8 = 36
    classes.  A palindrome pair consumes TWO class positions, so it never
    changes the running parity of the class counter; hence the class-position
    parity of the i-th inversion pair (by rank among inversion pairs alone) is
    just the parity of i, and the inversion-pair violations are a
    multivariate-hypergeometric functional of a uniform arrangement of the
    male/female/exempt inversion classes over 14 odd + 14 even alternating
    slots.  Each male+female palindrome pair spans one odd and one even class
    position, so by its own independent orientation bit it contributes 0 or 2
    violations with probability 1/2 each, independently of everything else
    (the exempt+exempt palindrome pair contributes 0).  Method 1 evaluates
    that closed form; method 2 is a slot-by-slot DP over pair types that never
    uses the decomposition.  Both are exact (Fractions throughout; no
    sampling); they must agree term-by-term."""
    from fractions import Fraction
    from math import comb, factorial
    from collections import defaultdict

    # --- classify the 32 canonical pairs from the C1 primitives ---
    inv_genders, pal_pairs = [], []
    for a, b in PAIRS:
        if _rev6(a) == b:                  # inversion pair: one class
            if _gender6(a) != _gender6(b):
                raise RuntimeError("gender not inversion-class-invariant")
            inv_genders.append(_gender6(a))
        else:                              # palindrome-complement pair: two classes
            if not (_rev6(a) == a and _rev6(b) == b and b == _comp6(a)):
                raise RuntimeError(f"pair ({a},{b}) is neither inversion nor "
                                   "palindrome-complement")
            pal_pairs.append(frozenset((_gender6(a), _gender6(b))))
    if len(inv_genders) != 28 or len(pal_pairs) != 4:
        raise RuntimeError("expected 28 inversion + 4 palindrome-complement pairs")
    m = inv_genders.count('M')
    f = inv_genders.count('F')
    e = inv_genders.count('N')
    n_mf = pal_pairs.count(frozenset(('M', 'F')))
    n_ee = pal_pairs.count(frozenset(('N',)))
    if n_mf + n_ee != 4:
        raise RuntimeError("unexpected palindrome-pair gender composition")

    # --- method 1: closed form (hypergeometric arrangement x binomial) ---
    n_odd = (28 + 1) // 2                  # inversion-class slots at odd positions
    n_even = 28 - n_odd
    total = factorial(28) // (factorial(m) * factorial(f) * factorial(e))
    inv_counts = defaultdict(int)          # violations from inversion classes
    for j in range(m + 1):                 # males at even class positions
        for k in range(f + 1):             # females at odd class positions
            if f - k > n_even - j or k > n_odd - (m - j):
                continue
            n = (comb(n_even, j) * comb(n_even - j, f - k)
                 * comb(n_odd, m - j) * comb(n_odd - (m - j), k))
            if n:
                inv_counts[j + k] += n
    if sum(inv_counts.values()) != total:
        raise RuntimeError("hypergeometric arrangement count does not close")
    dist_cf = defaultdict(Fraction)
    for b in range(n_mf + 1):              # MF palindrome pairs each add 0 or 2, p=1/2
        pb = Fraction(comb(n_mf, b), 2 ** n_mf)
        for v, n in inv_counts.items():
            dist_cf[v + 2 * b] += pb * Fraction(n, total)

    # --- method 2: slot-by-slot DP over pair types (no decomposition) ---
    # state: (males, females, exempt-inv, MF-palindrome, EE-palindrome used;
    # violations so far) -> probability.  The next class position is forced by
    # the counts (palindrome pairs consume two class positions).
    states = {(0, 0, 0, 0, 0, 0): Fraction(1)}
    for step in range(32):
        nxt = defaultdict(Fraction)
        rem_total = 32 - step
        for (mu, fu, eu, mfu, eeu, v), p in states.items():
            cpos = mu + fu + eu + 2 * (mfu + eeu) + 1
            odd = (cpos % 2 == 1)
            for t, r in (('M', m - mu), ('F', f - fu), ('N', e - eu),
                         ('MF', n_mf - mfu), ('EE', n_ee - eeu)):
                if not r:
                    continue
                w = p * Fraction(r, rem_total)
                if t == 'M':
                    nxt[(mu + 1, fu, eu, mfu, eeu, v + (0 if odd else 1))] += w
                elif t == 'F':
                    nxt[(mu, fu + 1, eu, mfu, eeu, v + (1 if odd else 0))] += w
                elif t == 'N':
                    nxt[(mu, fu, eu + 1, mfu, eeu, v)] += w
                elif t == 'EE':
                    nxt[(mu, fu, eu, mfu, eeu + 1, v)] += w
                else:                      # MF: one odd + one even class position;
                    half = w / 2           # orientation picks 0 or 2 violations
                    nxt[(mu, fu, eu, mfu + 1, eeu, v)] += half
                    nxt[(mu, fu, eu, mfu + 1, eeu, v + 2)] += half
        states = nxt
    dist_dp = defaultdict(Fraction)
    for (mu, fu, eu, mfu, eeu, v), p in states.items():
        dist_dp[v] += p

    strip = lambda d: {v: p for v, p in d.items() if p}
    if strip(dist_cf) != strip(dist_dp):
        raise RuntimeError("closed form and slot DP disagree — investigate")
    if sum(dist_cf.values()) != 1:
        raise RuntimeError("distribution does not sum to 1")
    return strip(dist_cf)

def recount_gender_null():
    """--recount-gender-null: independently recompute TR-8 §Commands' exact
    pair-null Schulz-gender figure P(rc4_violations <= 2) = 47/445740
    (~1.054426e-04) — the probability that a uniformly random C1-preserving
    ordering (32 canonical pairs permuted uniformly, each pair independently in
    either orientation) matches King Wen's gender-rule compliance level (KW
    sits at exactly 2 violations, class positions 25/26).  The functional is
    rebuilt from the published definition (SOLVE_C_CLI.md §--rc4b-verify;
    Schulz 1990 motif 2, elaborated by Cook 2006), the null distribution is
    computed exactly two ways (closed form + slot DP, cross-asserted — see
    _gender_null_distribution), and KW's published anchors gate the reading of
    the definition.  Instant.  Does NOT read solutions.bin."""
    from fractions import Fraction
    ok = True

    nv, locus = _rc4_violations_indep(KW)
    dist = _gender_null_distribution()
    le2 = sum(p for v, p in dist.items() if v <= 2)

    print("=" * 74)
    print("verify.py --recount-gender-null : TR-8 exact pair-null gender figure")
    print("functional rebuilt from the published definition; 32!*2^32 null solved")
    print("exactly two ways (closed form + slot DP, cross-asserted); no sampling")
    print("=" * 74)
    rows = [
        ("KW rc4 violations (SOLVE_C_CLI anchor)", "2", str(nv)),
        ("KW violation locus (class positions)", "[25, 26]", str(locus)),
        ("P(rc4_violations <= 2), pair-only null", "47/445740", str(le2)),
        ("  same, decimal (TR-8 quotes 1.054426e-04)", "1.054426e-04",
         f"{float(le2):.6e}"),
    ]
    for name, pub, mine in rows:
        match = (pub == mine)
        ok &= match
        print(f"  {name:<44} published {pub:>13}  ours {mine:>13}  "
              f"{'MATCH' if match else '*** MISMATCH ***'}")
    print(f"  full distribution support                    : "
          f"{min(dist)}..{max(dist)} (mass sums to 1 exactly)")
    print(f"  P(= 0) {sum(p for v, p in dist.items() if v == 0)}   "
          f"P(= 1) {sum(p for v, p in dist.items() if v == 1)}   "
          f"P(= 2) {sum(p for v, p in dist.items() if v == 2)}")
    print("=" * 74)
    print("RESULT:", "ALL MATCH — TR-8's pair-null gender figure is now two-instrument"
          if ok else "*** MISMATCH — investigate ***")
    return 0 if ok else 1

def recount_subtree():
    """--recount-subtree: independently recompute the exact deterministic
    subtree anchors of TR-5 §3 / TR-4 §"validated" / SEARCH_SPACE_SIZE.md
    (KW-following prefixes at 5/7/9 free positions) and the sigma-related
    prefix tree-isomorphism check, plus TR-4 §4's uniqueness-refutation
    anchor (exactly 8 of the 16,504 canonical completions satisfy C6/C7),
    plus the three away-from-KW cross-instrument anchors of _CROSS_PREFIXES
    (expectations from solve.c --estimate-knuth exact mode; leaf C3 ranges
    528..624 / 1024..1104 / 736..840, so C3 is exercised well clear of the
    776 threshold in both directions, not only at KW's own neighbourhood).
    ~1-2 min in CPython (the two 9-free runs visit ~9.4M nodes each; the
    cross anchors add < 1 s).  Returns 0 iff every anchor matched.
    The FAST subset of these anchors (everything but the two 9-free trees)
    also runs on every `python3 tests.py` (TestSubtreeCrossAnchors); the full
    driver is wired into reports/certificates/verify_all.sh §2."""
    import time
    t0 = time.time()
    rc = [0]

    def gate(name, got, want, src="published"):
        ok = (want is None) or (got == want)
        if not ok:
            rc[0] = 1
        tag = "  --  " if want is None else (" MATCH" if ok else "*FAIL*")
        pub = "(no public target)" if want is None else f"{want:,}"
        print(f"[{tag}] {name}: recomputed {got:,}  {src} {pub}")

    for free, want_nodes, want_canon in ((5, 443, 4), (7, 62256, 2232),
                                         (9, 9422793, 16504)):
        d = 31 - free                    # KW-following prefix pairs 1..d
        nodes, leaves, canon, c67 = _exact_subtree(
            [(i, 0) for i in range(1, d + 1)])
        gate(f"KW prefix {free}-free tree_nodes", nodes, want_nodes)
        gate(f"KW prefix {free}-free leaves_C1C2C4C5", leaves, None)
        gate(f"KW prefix {free}-free canonical leaves", canon, want_canon)
        if free == 9:
            gate("KW prefix 9-free canonical AND C6/C7 (TR-4 'exactly 8')",
                 c67, 8)
    nodes, leaves, canon, _c67 = _exact_subtree(_SIGMA_PREFIX)
    gate("sigma-related prefix tree_nodes (isomorphism)", nodes, 9422793)
    gate("sigma-related prefix canonical leaves (isomorphism)", canon, 16504)
    for name, pfx, (wn, wl, wc, wx) in _CROSS_PREFIXES:
        nodes, leaves, canon, c67 = _exact_subtree(pfx)
        gate(f"{name} tree_nodes", nodes, wn, src="solve.c-exact")
        gate(f"{name} leaves_C1C2C4C5", leaves, wl, src="solve.c-exact")
        gate(f"{name} canonical leaves (C3)", canon, wc, src="solve.c-exact")
        gate(f"{name} C6/C7 (slot-24 pair != 24 forces 0)", c67, wx,
             src="definition-forced")
    print(f"recount-subtree: {'ALL MATCH' if rc[0] == 0 else '*** MISMATCH ***'}"
          f"  ({time.time() - t0:.0f}s)")
    return rc[0]

def recount_finite():
    """--recount-finite: independently recompute the finite record-mode and
    wrap/parity tallies (TR-5 §3; TR-6; SPECIFICATION wrap-parity theorem;
    CIRCULAR_KING_WEN).  Validity of each sigma(KW) is checked from the
    constraint definitions directly — NOT via group membership — so this is a
    second instrument for the 48-of-720 classification itself, not only for
    the group order.  Seconds.  Returns 0 iff everything matched."""
    import itertools
    from collections import Counter
    from math import comb
    from functools import lru_cache
    rc = [0]

    def gate(name, got, want):
        ok = (got == want)
        if not ok:
            rc[0] = 1
        print(f"[{' MATCH' if ok else '*FAIL*'}] {name}: recomputed {got!r}"
              f"  published {want!r}")

    kw_ms = sorted(hamming(KW[i], KW[i + 1]) for i in range(63))

    def classify(s):
        if any(s[2*i+1] != _partner(s[2*i]) for i in range(32)):
            return "C1"
        if any(hamming(s[i], s[i+1]) == 5 for i in range(63)):
            return "C2"
        if compute_comp_dist(s) > 776:
            return "C3"
        if not (s[0] == 63 and s[1] == 0):
            return "C4"
        if sorted(hamming(s[i], s[i+1]) for i in range(63)) != kw_ms:
            return "C5"
        return None

    valid, first_fail, recs, c3s = [], Counter(), set(), []
    for g in itertools.permutations(range(6)):
        s = [_apply_bitperm(g, h) for h in KW]
        why = classify(s)
        if why is None:
            valid.append(g)
            recs.add(tuple(frozenset((s[2*i], s[2*i+1])) for i in range(32)))
            c3s.append(compute_comp_dist(s))
        else:
            first_fail[why] += 1
    gate("48-of-720 sigma(KW) C1-C5-valid", len(valid), 48)
    gate("all 672 invalid images fail C1 first", first_fail.get("C1", 0), 672)
    gate("distinct canonical records (KW + twins)", len(recs), 24)
    kw_rec = tuple(frozenset((KW[2*i], KW[2*i+1])) for i in range(32))
    gate("KW's own record in the orbit", kw_rec in recs, True)
    gate("record-twin count", len(recs) - 1, 23)
    gate("every valid image's C3 sum", set(c3s), {776})
    cent = {g for g in itertools.permutations(range(6))
            if all(g[5 - i] == 5 - g[i] for i in range(6))}
    gate("valid set == centralizer of rev in S6", set(valid) == cent, True)

    cls = [bin(KW[2*i]).count('1') & 1 for i in range(32)]
    gate("pairs parity-homogeneous", all(
        (bin(KW[2*i]).count('1') & 1) == (bin(KW[2*i+1]).count('1') & 1)
        for i in range(32)), True)
    gate("pair-class split (E, O)", (cls.count(0), cls.count(1)), (16, 16))
    gate("first pair even class (C4 pin)", cls[0], 0)
    gate("linear parity-class alternations",
         sum(cls[i] != cls[i+1] for i in range(31)), 15)
    gate("circular parity-class alternations",
         sum(cls[i] != cls[(i+1) % 32] for i in range(32)), 16)
    lin = [hamming(KW[i], KW[i+1]) for i in range(63)]
    wrap = hamming(KW[63], KW[0])
    gate("linear C5 multiset", dict(Counter(lin)),
         {1: 2, 2: 20, 3: 13, 4: 19, 6: 9})
    gate("linear odd-distance count", sum(d & 1 for d in lin), 15)
    gate("wrap distance d(s63, s0)", wrap, 3)
    gate("wrap parity odd", wrap & 1, 1)
    gate("circular multiset (wrap added)", dict(Counter(lin + [wrap])),
         {1: 2, 2: 20, 3: 14, 4: 19, 6: 9})
    gate("circular odd-of-64 (McKenna 3:1)",
         sum(d & 1 for d in lin + [wrap]), 16)
    tp = [d & 1 for d in lin]
    gate("transition-parity switches", sum(tp[i] != tp[i+1] for i in range(62)), 30)

    @lru_cache(maxsize=None)
    def arr(pos, ones, last, alt):
        if alt > 15 or ones > 16 or pos - ones > 16:
            return 0
        if pos == 32:
            return 1 if (ones == 16 and alt == 15) else 0
        return sum(arr(pos + 1, ones + b, b,
                       alt + (0 if pos == 0 else int(b != last)))
                   for b in (0, 1))
    gate("15-alternation 16/16 arrangement count (DP)", arr(0, 0, 0, 0), 82818450)
    gate("same, closed form 2*C(15,7)^2", 2 * comb(15, 7) ** 2, 82818450)
    print("recount-finite:",
          "ALL MATCH" if rc[0] == 0 else "*** MISMATCH — investigate ***")
    return rc[0]


def recount():
    """Independently reproduce the published ROAE exact counts (TR-11 §10vi).

    Prints a match table. Returns 0 iff every quantity with a published target
    reproduced exactly; a mismatch is a SERIOUS finding and is reported loudly.
    """
    import itertools, time
    from collections import Counter
    _t0 = time.time()
    rows = []        # (name, published, independent, matched|None, method)
    all_match = [True]

    def check(name, pub, ind, method):
        matched = None if pub is None else (pub == ind)
        if matched is False:
            all_match[0] = False
        rows.append((name, pub, ind, matched, method))

    print("=" * 74)
    print("verify.py --recount : independent reproduction of the ROAE exact counts")
    print("clean-room from published definitions; different method than the")
    print("symmetry-quotient DP; stdlib only; no solve.c/solve.py import.")
    print("=" * 74)

    # ---------------- TARGET 1 : small-n structural facts ----------------
    mine = {frozenset(p) for p in _canonical_pairs()}
    pub_pairs = {frozenset(p) for p in PAIRS}
    check("Canonical partner-pairing == published 32 KW pairs (as sets)",
          True, (mine == pub_pairs), "derive partner() orbits, compare")

    check("KW is a permutation of {0..63}", True, sorted(KW) == list(range(64)),
          "flatten published pair table")

    check("C1: every KW pair is {h, partner(h)}", True,
          all(_partner(a) == b and _partner(b) == a for (a, b) in PAIRS),
          "recompute partner() on each pair")

    within = dict(Counter(hamming(a, b) for (a, b) in _canonical_pairs()))
    check("Within-pair distance multiset (32 pairs)", {2: 12, 4: 12, 6: 8},
          within, "popcount within each canonical pair")

    xorset = sorted({a ^ b for (a, b) in _canonical_pairs()})
    check("XOR-product set {h ^ partner(h)}",
          [12, 18, 30, 33, 45, 51, 63], xorset, "XOR within each pair, dedup")

    fullms = dict(Counter(hamming(KW[i], KW[i + 1]) for i in range(63)))
    check("KW difference-wave multiset D(S) (all 63 transitions, C5)",
          {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}, fullms, "popcount along KW")

    between = dict(Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31)))
    check("KW between-pair boundary multiset (31 boundaries) [reduced-C5 B0]",
          {1: 2, 2: 8, 3: 13, 4: 7, 6: 1}, between, "popcount at 31 boundaries")

    pos = {h: i for i, h in enumerate(KW)}
    cd_sum = sum(abs(pos[h] - pos[h ^ 63]) for h in range(64))
    check("KW C3 complement-distance sum (x64 integer form)", 776, cd_sum,
          "sum |pos(h)-pos(comp(h))| over all 64 hexagrams")

    check("C2: no distance-5 adjacency in KW", True,
          all(hamming(KW[i], KW[i + 1]) != 5 for i in range(63)), "popcount")
    check("C4: KW starts (63, 0)", True, (KW[0] == 63 and KW[1] == 0), "read s0,s1")

    G = _commuting_bitperms()
    check("|symmetry group C_S6(rev)| (bit-position perms)", 48, len(G),
          "enumerate 720 perms, keep those commuting with reversal")

    check("group elements fix {0,63} and preserve Hamming distance",
          True,
          all(_apply_bitperm(g, 0) == 0 and _apply_bitperm(g, 63) == 63 for g in G)
          and all(hamming(_apply_bitperm(g, a), _apply_bitperm(g, b)) == hamming(a, b)
                  for g in G[:4] for a in range(64) for b in range(a, 64)),
          "verify fix of all-0/all-1 + isometry (subset)")

    cps = _canonical_pairs()
    pidx = {frozenset(p): i for i, p in enumerate(cps)}
    induced = {tuple(pidx[frozenset((_apply_bitperm(g, a), _apply_bitperm(g, b)))]
                     for (a, b) in cps) for g in G}
    check("distinct induced pair-permutations (record group, S4)", 24, len(induced),
          "induce each g on the 32 pairs, dedup")

    def rec_canon(seq):
        return tuple(frozenset((seq[2 * i], seq[2 * i + 1])) for i in range(32))
    orbit = {rec_canon([_apply_bitperm(g, h) for h in KW]) for g in G}
    check("King Wen orbit size at record level (KW + twins)", 24, len(orbit),
          "apply 48 bit-perms to KW, canonicalize, dedup")
    check("King Wen record-level twin count (orbit - KW)", 23, len(orbit) - 1,
          "orbit size - 1")

    # ------- cross-method independence check (DP == raw backtracking) -------
    print("\nCross-method check  plain DP  ==  raw backtracking  (small prefixes):")
    base = _spec_to_pairs("3.0,3.1,3.2")
    cross_ok = True
    for k in (3, 4, 5, 6, 7):
        a = _count_c1c2c4(base[:k], 0)
        b = _backtrack_c1c2c4(base[:k], 0)
        if a != b:
            cross_ok = False; all_match[0] = False
        print(f"   k={k}: DP={a:,}  backtrack={b:,}  "
              f"{'AGREE' if a == b else '*** DISAGREE ***'}")
    check("plain-DP recurrence == exhaustive backtracking (k=3..7)",
          True, cross_ok, "two independent methods agree")

    # ---------------- TARGET 2 : reduced-rung C1∩C2∩C4 unions ----------------
    check("U1  = |C1∩C2∩C4|, 9 pairs {3.0,3.1,3.2}@0",
          63366144, _count_c1c2c4(_spec_to_pairs("3.0,3.1,3.2"), 0),
          "plain (mask,last) counting recurrence")
    # U1 also reproduced by fully-independent raw backtracking (63M leaves) —
    # cheap enough to include as a second method.
    check("U1  (same) via raw exhaustive backtracking (independent of any DP)",
          63366144, _backtrack_c1c2c4(_spec_to_pairs("3.0,3.1,3.2"), 0),
          "exhaustive backtracking, no memoization")
    check("U2  = |C1∩C2∩C4|, 12 pairs {6.0,6.1}@0",
          1961990553600, _count_c1c2c4(_spec_to_pairs("6.0,6.1"), 0),
          "plain (mask,last) counting recurrence")
    import math as _math
    check("U2  closed form 12! * 2^12 (no d=5 boundary occurs in this union)",
          1961990553600, _math.factorial(12) * (2 ** 12), "closed form")
    check("U3  = |C1∩C2∩C4|, 13 pairs {3.0,4.0,6.2}@63",
          39239811072000, _count_c1c2c4(_spec_to_pairs("3.0,4.0,6.2"), 63),
          "plain (mask,last) counting recurrence")

    # -------------- TARGET 3 : reduced-rung C1∩C2∩C4∩C5 (C5 ladder) --------------
    # GAP NOW CLOSED (2026-07-21). Earlier revisions of this file recorded these
    # rungs as NOT independently re-countable: the published Verification Guide
    # then said "retain states whose boundary multiset is a SUB-multiset of KW's
    # {1:2,2:8,3:13,4:7,6:1}", which at the 13-pair rung yields
    # 38,492,859,594,240 rather than the published 2,063,395,607,040 — because
    # the true rule is an EXACT match against that rung's own target B0, and the
    # per-rung B0 was not in any public document. That defect (surfaced by this
    # instrument) was fixed in TR-11 v1.2 / adversarial-review item F-3, which
    # published both the spec-ORDER pair lists and the per-rung B0 targets.
    #
    # So the ladder is now reproducible from public definitions alone, and this
    # block does so — deriving B0 INDEPENDENTLY via TR-11 §5's first-completion
    # DFS rather than trusting the published B0, then counting with a plain
    # budgeted (mask,last,p) DP that shares no code with solve.c. Two things are
    # therefore checked per rung: the derived B0 and the resulting count.
    #
    # Rungs n>=19 exceed this host's pure-Python memory/time budget and are
    # honestly recorded as not re-counted here (they need a worker, not a laptop).
    for n, spec, b0_pub, pub in _C5_RUNGS:
        pl = _spec_to_pairs_ordered(spec)
        b0_ind = _b0_first_completion(pl, 0)
        check(f"C5 ladder n={n} {{{spec}}}@0 — B0 derived independently",
              tuple(b0_pub), tuple(b0_ind) if b0_ind else None,
              "TR-11 §5 first-completion DFS (spec order, o=0 then o=1)")
        check(f"C5 ladder n={n} {{{spec}}}@0 — |C1∩C2∩C4∩C5|",
              pub, _count_c1c2c4c5(pl, 0, b0_pub),
              "plain budgeted (mask,last,p) counting recurrence")

    rows.append(("C5 ladder n=18 {6.0,6.1,6.2}@0", 3211799156883456,
                 "re-countable via --recount-rung 18 (~953 MB peak RSS; wall unmeasured here)",
                 None, "plain budgeted packed-state DP — recount_rung()"))
    rows.append(("C5 ladder n=19 {3.0,4.0,6.0,6.1}@0", 63244766587981824,
                 "re-countable via --recount-rung 19 (worker-sized: ~8 GB)",
                 None, "plain budgeted packed-state DP — recount_rung()"))
    for n, spec, pub in [
        (24, "3.0,3.1,6.0,6.1,6.2", 7477248378538061907099648),
        (25, "3.0,4.0,6.0,6.1,6.2", 83855263774549546015506432),
        (27, "3.0,3.1,3.2,6.0,6.1,6.2", 61666352085618532666071318528),
        (28, "3.0,3.1,4.0,6.0,6.1,6.2", 2155118806480613893163229118464),
    ]:
        rows.append((f"C5 ladder n={n} {{{spec}}}@0", pub,
                     "not re-counted here (exceeds this host; needs a worker)",
                     None, "recipe now public — TR-11 §4b/§5"))

    # ------------------------------ match table ------------------------------
    print("\n" + "=" * 74)
    print("MATCH TABLE  (quantity | published | independent | match)")
    print("=" * 74)
    def _fmt(v):
        if v is None:
            return "(no public target)"
        return format(v, ",") if isinstance(v, int) else str(v)
    for name, pub, ind, matched, method in rows:
        mark = "  --  " if matched is None and pub is None else \
               " n/a  " if matched is None else \
               " MATCH" if matched else "*FAIL*"
        print(f"[{mark}] {name}")
        print(f"          published:   {_fmt(pub)}")
        print(f"          independent: {_fmt(ind)}")
        print(f"          method:      {method}")
    print("=" * 74)
    n_ok = sum(1 for r in rows if r[3] is True)
    n_fail = sum(1 for r in rows if r[3] is False)
    n_na = sum(1 for r in rows if r[3] is None)
    print(f"summary: {n_ok} reproduced, {n_fail} MISMATCH, {n_na} not re-counted "
          f"(total wall time {time.time() - _t0:.1f}s)")
    # V2-F58 #8 (2026-08-30): the old absolute sentence ("every quantity with a
    # published target reproduced") also covered the n/a rows, which carry
    # published targets that were explicitly NOT re-counted. The verdict now
    # states the census, and an empty census is a failure.
    if all_match[0] and n_ok > 0:
        print(f"RESULT: every quantity RE-COUNTED HERE reproduced its published target")
        print(f"        EXACTLY ({n_ok} of {n_ok + n_fail + n_na} rows; {n_na} published "
              f"rows NOT re-counted —")
        print("        they exceed this host, are marked n/a above, and remain")
        print("        corroborated by the project's own two engines (in-RAM +")
        print("        out-of-core agree digit-for-digit) + estimator, NOT by this run.)")
    elif all_match[0]:
        print("RESULT: *** ZERO quantities re-counted — nothing was verified. ***")
    else:
        print("RESULT: *** MISMATCH DETECTED *** — a bug in one instrument or the")
        print("        other. See the *FAIL* row(s) above. Do NOT paper over this.")
    print(f"RECOUNT_REPRODUCED={n_ok}")
    print(f"RECOUNT_MISMATCH={n_fail}")
    print(f"RECOUNT_NA={n_na}")
    print(f"RECOUNT_RESULT={'PASS' if (all_match[0] and n_ok > 0) else 'FAIL'}")
    print("=" * 74)
    return 0 if (all_match[0] and n_ok > 0) else 1


_PUBLISHED_F1C5 = 1097051278789181790036112071176579186688   # TR-11 §9, |C1∩C2∩C4∩C5|

def _parse_layer_certificate(run_out):
    """Extract the per-layer certificate rows a completed f1c5 run leaves in run.out.

    Returns [(k, canonical_masks, C(31,k), states, entries, V_k, mass)]. These are the
    engine's own published per-layer figures — this function only READS them; every
    identity checked against them lives in check_certificate() below."""
    import re
    pat = (r"\[f1c5\] layer k=\s*(\d+)/31: canonical_masks=(\d+) \(of C\(31,(\d+)\)=(\d+)\) "
           r"states=(\d+) entries=(\d+) V_k=(\d+).*?mass=(\d+)")
    out = []
    with open(run_out, encoding='utf-8', errors='replace') as fh:
        txt = fh.read()
    for m in re.finditer(pat, txt):
        k, cm, _kk, cbin, st, en, vk, mass = (int(x) for x in m.groups())
        out.append((k, cm, cbin, st, en, vk, mass))
    return out

def check_certificate(dirpath):
    """Validate a completed f1c5 run's ARTIFACTS without re-running the DP (TR-11 §10iii).

    This is the "check the artifact, don't trust the code" half of the verification
    story: the engine's per-layer figures + manifest + preserved digests are checked
    against structural identities and against quantities this file derives on its own
    (King Wen's boundary multiset; the mod-24 gate; the published integer).

    IMPORTANT — what this does and does NOT establish. It does NOT recompute the DP, so
    it cannot certify that the per-layer masses are *correct*; it certifies that the
    published artifact is internally consistent, structurally admissible, digest-intact,
    and terminates at the published integer. Row-level recomputation is the companion
    step and is deliberately not done here.

    Identities were validated against the landed 2026-07-16 run (31/31 layers) before
    being encoded; two plausible-looking candidates were REJECTED as false and are
    recorded here so they are not re-added: `states == masks*2k` (fails at small k —
    C2 forbids some exits, so only <= holds) and `mass strictly increasing across
    layers` (simply untrue of the DP masses).
    """
    import os
    rows = []
    run_out = os.path.join(dirpath, 'run.out')
    man = os.path.join(dirpath, 'f1c5_manifest.txt')
    shas = os.path.join(dirpath, 'PRESERVE_SHA256.txt')
    ok = [True]

    def chk(name, cond, detail=""):
        rows.append((name, bool(cond), detail))
        if not cond:
            ok[0] = False

    print("=" * 74)
    print("verify.py --check-certificate : artifact check for a completed f1c5 run")
    print("reads the run's own artifacts; recomputes nothing. See docstring for scope.")
    print("=" * 74)

    if not os.path.isfile(run_out):
        print(f"FATAL: no run.out under {dirpath}")
        return 1
    lay = _parse_layer_certificate(run_out)
    chk("run.out carries all 31 layer certificate rows", len(lay) == 31, f"got {len(lay)}")
    # V2-F58 #3 (2026-08-30): len(lay)==31 alone accepted a run.out whose terminal
    # row was duplicated 31 times — count COVERAGE, not just cardinality.
    ks = sorted(k for k, *_r in lay)
    chk("layer certificate rows cover k=1..31 exactly once (no duplicates, no gaps)",
        ks == list(range(1, 32)),
        "coverage exact" if ks == list(range(1, 32)) else f"k values = {ks}")

    if lay:
        chk("every layer: canonical_masks <= C(31,k)",
            all(cm <= cb for _k, cm, cb, _s, _e, _v, _m in lay), "combinatorial bound")
        chk("every layer: states <= canonical_masks * 2k",
            all(st <= cm * 2 * k for k, cm, _cb, st, _e, _v, _m in lay),
            "each placed pair offers <=2 exits; C2 removes some (equality FAILS at small k)")
        chk("every layer: states <= entries <= states * V_k",
            all(st <= en <= st * vk for _k, _cm, _cb, st, en, vk, _m in lay),
            "budget-vector fan-out bound")
        chk("every layer: mass > 0", all(m > 0 for *_r, m in lay))
        term = lay[-1]
        chk("terminal layer k=31 is a single canonical mask",
            term[0] == 31 and term[1] == 1, f"k={term[0]} masks={term[1]}")
        chk("terminal mass == published |C1∩C2∩C4∩C5| (TR-11 §9)",
            term[6] == _PUBLISHED_F1C5, f"{term[6]}")
        chk("terminal mass ≡ 0 (mod 24)  [free-action theorem gate]",
            term[6] % 24 == 0, f"mod24={term[6] % 24}")

    # manifest b0 vs King Wen's boundary multiset, derived HERE (not read from solve.c)
    if os.path.isfile(man):
        mtxt = open(man, encoding='utf-8').read()
        got = None
        for line in mtxt.splitlines():
            if line.startswith('b0='):
                got = tuple(int(x) for x in line[3:].split(','))
        from collections import Counter
        between = Counter(hamming(KW[2 * i + 1], KW[2 * i + 2]) for i in range(31))
        mine = tuple(between.get(d, 0) for d in (1, 2, 3, 4, 6))
        chk("manifest b0 == KW between-pair boundary multiset (derived independently)",
            got == mine, f"manifest={got} derived={mine}")
        chk("manifest reports last_complete_k=31", 'last_complete_k=31' in mtxt)
    else:
        # V2-F58 #3/#4 class (2026-08-30): an absent manifest used to be an "n/a"
        # row that left ok[0] untouched — absent expected evidence must go RED.
        chk("f1c5_manifest.txt present (required artifact)", False,
            "ABSENT — b0/last_complete_k anchors NOT EVALUATED")

    # preserved digests — a CENSUS, not a survivor count: "digest-intact" may only
    # be claimed for digests actually recomputed (V2-F58 #3: zero digests used to
    # print as intact).
    ndig = 0
    if os.path.isfile(shas):
        import hashlib
        bad = []
        for line in open(shas, encoding='utf-8'):
            parts = line.split()
            if len(parts) != 2:
                continue
            want, fn = parts
            p = os.path.join(dirpath, fn)
            if not os.path.isfile(p):
                bad.append(f"{fn}:missing"); continue
            h = hashlib.sha256()
            with open(p, 'rb') as fh:
                for blk in iter(lambda: fh.read(1 << 20), b''):
                    h.update(blk)
            ndig += 1
            if h.hexdigest() != want:
                bad.append(f"{fn}:MISMATCH")
        chk("preserved artifact digests match PRESERVE_SHA256.txt", not bad,
            ",".join(bad) or f"all {ndig} recomputed digest(s) match")
        chk("digest census: at least one preserved digest recomputed", ndig > 0,
            f"DIGESTS_VERIFIED={ndig}")
    else:
        chk("PRESERVE_SHA256.txt present (required artifact)", False,
            "ABSENT — ZERO digests verified; 'digest-intact' cannot be claimed")

    print()
    for name, res, detail in rows:
        tag = "[ MATCH]" if res is True else ("[ n/a  ]" if res is None else "[*FAIL*]")
        print(f"{tag} {name}")
        if detail:
            print(f"          {detail}")
    print("=" * 74)
    if ok[0]:
        print(f"RESULT: artifact is internally consistent, digest-intact ({ndig} digest(s)")
        print("        recomputed and matched), and terminates at the published integer.")
        print("        This is NOT a recomputation — the per-layer masses are taken as")
        print("        given; row-level recomputation is the companion check and was")
        print("        not performed here.")
    else:
        print("RESULT: *** ARTIFACT CHECK FAILED *** — see FAIL row(s). Do not explain away.")
    print(f"CERT_LAYER_ROWS={len(lay)}")
    print(f"CERT_DIGESTS_VERIFIED={ndig}")
    print(f"CERT_RESULT={'PASS' if ok[0] else 'FAIL'}")
    print("=" * 74)
    return 0 if ok[0] else 1


# ---------------------------------------------------------------------------
# LAYER-SIDECAR IDENTITIES  (--check-layer-sidecars)
#
# The f1c5 per-layer sidecars (f1c5_layer_stats_KK.json, written for resume) are
# already most of a checkable certificate. This validates the identities they must
# satisfy, reading ONLY the small JSON files — no layer-file I/O, so it costs
# nothing and runs anywhere, including long after the campaign VM is gone.
#
# The two load-bearing checks:
#   * marginal_last_mass and marginal_rid_mass are two INDEPENDENT decompositions
#     of the same mass_total (by terminal pair, and by boundary-residue id). Both
#     must sum to mass_total. A transfer/stabilizer bug generically breaks one.
#   * input_sha256_decompressed[k] == own_sha256_decompressed[k-1] chains the
#     layers into a single lineage — proving the retained set is one uninterrupted
#     run, not a mix of runs stitched across Spot evictions.
#
# NOTE (identity that looks right and is WRONG): entries_per_mask's min/max/mean
# and histogram are over NON-EMPTY masks, so they total n_masks - n_empty_masks,
# NOT n_masks. Layers with n_empty_masks == 0 pass the naive form by luck; k=1,2,3
# of the 2026-07-22 full-31 run have n_empty_masks == 1 and do not. Do not "fix" a
# failure here by relaxing to n_masks.
# ---------------------------------------------------------------------------

def check_layer_sidecars(dirpath):
    import json, glob, re
    files = sorted(glob.glob(os.path.join(dirpath, "f1c5_layer_stats_*.json")),
                   key=lambda p: int(re.search(r"_(\d+)\.json$", p).group(1)))
    if not files:
        print(f"no f1c5_layer_stats_*.json in {dirpath}")
        return 1

    man = {}
    mpath = os.path.join(dirpath, "f1c5_manifest.txt")
    if os.path.exists(mpath):
        for line in open(mpath):
            if "=" in line:
                k_, v_ = line.strip().split("=", 1)
                man[k_] = v_

    layers = {}
    for f in files:
        d = json.load(open(f))
        layers[d["k"]] = d

    fails, n, skipped = [], [0], []
    chain_links = [0]
    def ck(cond, label):
        n[0] += 1
        if not cond:
            fails.append(label)

    print("=" * 74)
    print("verify.py --check-layer-sidecars : f1c5 per-layer sidecar identities")
    print(f"  dir      : {dirpath}")
    print(f"  layers   : k={min(layers)}..{max(layers)} ({len(layers)} sidecars)")
    if man:
        print(f"  manifest : n={man.get('n')} b0={man.get('b0')} pl_hash={man.get('pl_hash')}")
    print("=" * 74)

    for k in sorted(layers):
        d = layers[k]
        mt = int(d["mass_total"])
        nonempty = d["n_masks"] - d["n_empty_masks"]

        s_last = sum(int(v) for _, v in d["marginal_last_mass"])
        s_rid = sum(int(v) for _, v in d["marginal_rid_mass"])
        ck(s_last == mt, f"k={k}: sum(marginal_last_mass) != mass_total")
        ck(s_rid == mt, f"k={k}: sum(marginal_rid_mass) != mass_total")

        ck(sum(c for _, c in d["value_hist_log2"]) == d["n_entries"],
           f"k={k}: value_hist_log2 counts != n_entries")
        ck(sum(c for _, c in d["entries_per_mask"]["hist_log2"]) == nonempty,
           f"k={k}: entries_per_mask hist != n_masks - n_empty_masks")
        ck(sum(c for _, c in d["branching"]["hist"]) == d["n_entries"],
           f"k={k}: branching hist != n_entries")

        lo = sum(c * 2 ** b for b, c in d["value_hist_log2"])
        hi = sum(c * 2 ** (b + 1) for b, c in d["value_hist_log2"])
        ck(lo <= mt <= hi, f"k={k}: mass_total outside its own value_hist bounds")

        epm = d["entries_per_mask"]
        ck(epm["min"] * nonempty <= d["n_entries"] <= epm["max"] * nonempty,
           f"k={k}: n_entries outside entries_per_mask min/max envelope")
        ck(abs(epm["mean"] * nonempty - d["n_entries"]) / d["n_entries"] < 1e-6,
           f"k={k}: entries_per_mask mean inconsistent with n_entries/nonempty")

        if man:
            ck(d["n"] == int(man["n"]), f"k={k}: n != manifest n")
            ck(d["pl_hash"] == man["pl_hash"], f"k={k}: pl_hash != manifest pl_hash")
            ck(",".join(str(x) for x in d["b0"]) == man["b0"], f"k={k}: b0 != manifest b0")
        else:
            # V2-F58 #4 (2026-08-30): an absent manifest used to silently REMOVE
            # these three anchor checks from the census — the "8/8 passed" on a
            # single fabricated sidecar. Skips are counted and reported.
            skipped.append(f"k={k}: manifest anchors (n/pl_hash/b0) NOT EVALUATED — "
                           "f1c5_manifest.txt absent")

        if k - 1 in layers:
            chain_links[0] += 1
            ck(d.get("input_layer_k") == k - 1, f"k={k}: input_layer_k != k-1")
            ck(d.get("input_sha256_decompressed") == layers[k - 1]["own_sha256_decompressed"],
               f"k={k}: BROKEN HASH CHAIN — input sha != k-1's own sha")
        elif k != min(layers):
            # A gap inside the retained set: the chain link cannot be evaluated,
            # which used to be a silent skip — the set is then NOT one proven
            # lineage, so the absence itself is the failure.
            ck(False, f"k={k}: chain link k-1->k UNVERIFIABLE — sidecar k-1 ABSENT "
                      "(gap in the retained set)")

        print(f"  k={k:2d}  masks={d['n_masks']:>11,}  entries={d['n_entries']:>15,}  "
              f"mass={mt:>27,}  {'OK' if s_last == mt and s_rid == mt else 'FAIL'}")

    # census verdict (V2-F58 #4, 2026-08-30): what was EVALUATED is stated
    # separately from what was ITERATED, and the lineage claim requires the
    # chain to have actually been walked — zero links, a gap, or an absent
    # manifest is a failure, never a quiet shrink of the denominator.
    census_fails = []
    if not man:
        census_fails.append(f"f1c5_manifest.txt ABSENT — {3 * len(layers)} external-anchor "
                            "check(s) NOT EVALUATED; sidecars were checked only against themselves")
    if chain_links[0] == 0:
        census_fails.append("ZERO chain links evaluated — an 'unbroken hash chain' cannot be "
                            "attested from fewer than 2 consecutive sidecars")
    print("=" * 74)
    print(f"{n[0] - len(fails)}/{n[0]} checks passed; {len(skipped)} SKIPPED; "
          f"{chain_links[0]} chain link(s) evaluated")
    if skipped:
        print("SKIPPED (not evaluated, counted against the verdict):")
        for s in skipped:
            print("  " + s)
    print(f"SIDECAR_CHAIN_LINKS_CHECKED={chain_links[0]}")
    print(f"SIDECAR_CHECKS_SKIPPED={len(skipped)}")
    fails = fails + census_fails
    if fails:
        print("FAILURES:")
        for f in fails:
            print("  " + f)
        print("RESULT: *** SIDECAR IDENTITY CHECK FAILED *** — do not explain away.")
        print("SIDECARS_RESULT=FAIL")
        return 1
    print(f"RESULT: all sidecar identities hold, and the layer hash chain is unbroken")
    print(f"        across the retained set ({chain_links[0]} link(s) walked). This is NOT")
    print("        a recomputation of the masses — it checks self-consistency and")
    print("        lineage, not the DP's arithmetic.")
    print("SIDECARS_RESULT=PASS")
    print("=" * 74)
    return 0


# ---------------------------------------------------------------------------
# NULL G-DISTRIBUTION  (--check-null-g)
#
# G is the C3 slot-gap statistic: C3 = 16 + 8*G (Lean `c3_slot_decomposition`), so
# C3 <= 776 <=> G <= 95, and King Wen sits exactly at G = 95.
#
# This computes the EXACT distribution of G under the C1-and-C4 null -- 12 cross-couples
# and 7 self-pairs placed into slots 1..31, uniformly. It is a reference distribution:
# it tells you what G looks like with no C2 and no C5 conditioning at all, which is the
# baseline any "KW's G is unusual" claim has to beat.
#
# INDEPENDENCE (the reason this lives in verify.py and not solve.c): solve.c's G channel
# accumulates g -= s when a couple opens at slot s and g += s when it closes. This does
# not touch slot indices in the accumulator AT ALL. It uses
#
#     G = sum_i (close_i - open_i) = sum_{s=1..30} o_s
#
# where o_s is the number of couples still open after slot s -- because a couple opened
# at a and closed at b is open across exactly the b-a boundaries s in [a, b-1]. Same
# model, different arithmetic. Agreement is therefore evidence, not tautology.
#
# Two checks need no DP at all and are applied as gates below:
#   * total must be 31! exactly
#   * E[G] must be 128 exactly, by linearity: each couple's slot-pair is marginally a
#     uniform 2-subset of {1..31}, and E|i-j| = (n+1)/3 for a uniform 2-subset of
#     {1..n}, so E[G] = 12*(32/3) = 128.
#
# --unpinned VARIANT (C3|C1, start unpinned): the SAME DP with the C4 slot-0 pin
# removed -- 12 cross-couples and all 8 self-pairs placed into slots 1..32,
# uniformly. This is the exact analogue of solve.c --null-pair-constrained's
# sampled C3|C1 figure (6.42% at 10^9 trials): that sampler Fisher-Yates-permutes
# all 32 pairs with random orientations, and orientation bits cancel in G (Lean
# `c3_slot_decomposition`: C3 = 16 + 8*G over all C1-valid orderings), so
# P(C3 <= 776 | C1) = P(G <= 95) over uniform orderings of the 32 pair-slots.
# The same two DP-free gates apply with one more slot: total must be 32! exactly,
# and E[G] = 12*(33/3) = 132 exactly.
# ---------------------------------------------------------------------------

_NULL_G_EXPECT = {
    'total_is_31_factorial': True,
    'support': (12, 228),
    'mean': 128,
    'p_le_95_num': 641983711307479,
    'p_le_95_den': 7919632354008375,
}

# Exact C3|C1 (start unpinned): first computed 2026-07-25 by this DP; cross-checked
# against brute-force enumeration at reduced scopes (NC,NS) in {(1,1),(2,1),(2,2),
# (3,1),(2,3)} and against the 10^9-sample MC (solve.c --null-pair-constrained,
# 6.42%; exact = 6.421137%, inside the MC's ~0.0008pp 1-sigma band).
_NULL_G_UNPINNED_EXPECT = {
    'total_is_32_factorial': True,
    'support': (12, 240),
    'mean': 132,
    'p_le_95_num': 1977618313669549,
    'p_le_95_den': 30798570265588125,
}


def check_null_g(verbose=True, unpinned=False):
    import math
    from fractions import Fraction
    from collections import defaultdict

    if unpinned:
        NC, NS, NSLOT = 12, 8, 32   # no C4 pin: all 8 self-pairs free, 32 slots
        expect = _NULL_G_UNPINNED_EXPECT
    else:
        NC, NS, NSLOT = 12, 7, 31   # C4 pin: pair 0 fixed at slot 0; 31 free slots
        expect = _NULL_G_EXPECT
    cur = {(0, 0, 0): 1}
    for s in range(1, NSLOT + 1):
        nxt = defaultdict(int)
        for (o, c, g), w in cur.items():
            rem_self = NS - ((s - 1) - o - 2 * c)
            if rem_self > 0:
                nxt[(o, c, g + o)] += w * rem_self
            un = NC - o - c
            if un > 0:
                nxt[(o + 1, c, g + o + 1)] += w * 2 * un
            if o > 0:
                nxt[(o - 1, c + 1, g + o - 1)] += w * o
        cur = dict(nxt)

    hist = defaultdict(int)
    for (o, c, g), w in cur.items():
        if o != 0 or c != NC:
            print(f"FAIL: terminal state (o={o}, c={c}) has unclosed couples")
            return 1
        hist[g] += w

    total = sum(hist.values())
    gs = sorted(hist)
    mean = Fraction(sum(g * w for g, w in hist.items()), total)
    ex2 = Fraction(sum(g * g * w for g, w in hist.items()), total)
    var = ex2 - mean * mean
    le95 = sum(w for g, w in hist.items() if g <= 95)
    frac = Fraction(le95, total)

    ok = [True]
    def gate(cond, label, got, want):
        status = "PASS" if cond else "*** FAIL ***"
        if not cond:
            ok[0] = False
        if verbose:
            print(f"  [{status}] {label}")
            if not cond:
                print(f"            got  {got}\n            want {want}")

    if verbose:
        print("=" * 74)
        if unpinned:
            print("verify.py --check-null-g --unpinned : exact G-distribution, bare C1 null")
        else:
            print("verify.py --check-null-g : exact G-distribution under the C1&C4 null")
        print("  method: G = sum_s (couples open after slot s)  -- deliberately NOT")
        print("          solve.c's -/+ slot-index accumulator, so agreement is evidence")
        print("=" * 74)

    gate(total == math.factorial(NSLOT), f"total == {NSLOT}!", total, math.factorial(NSLOT))
    gate((gs[0], gs[-1]) == expect['support'],
         f"support == [{expect['support'][0]}, {expect['support'][1]}]",
         (gs[0], gs[-1]), expect['support'])
    gate(mean == expect['mean'],
         f"E[G] == {expect['mean']} exactly (DP-free: 12*({NSLOT + 1}/3))",
         mean, expect['mean'])
    gate(frac == Fraction(expect['p_le_95_num'], expect['p_le_95_den']),
         f"P(G <= 95) == {expect['p_le_95_num']}/{expect['p_le_95_den']}", frac,
         Fraction(expect['p_le_95_num'], expect['p_le_95_den']))

    if verbose:
        print("-" * 74)
        print(f"  support        [{gs[0]}, {gs[-1]}]   bins {len(gs)}")
        print(f"  E[G]           {mean}")
        print(f"  sd             {math.sqrt(float(var)):.6f}")
        print(f"  P(G <= 95)     {frac}  = {100*float(frac):.6f}%")
        print(f"  P(G == 95)     {100*float(Fraction(hist.get(95,0), total)):.6f}%")
        print(f"  P(G == 95 | G <= 95) = {100*float(Fraction(hist.get(95,0), le95)):.4f}%")
        print("=" * 74)
        if not ok[0]:
            print("RESULT: *** NULL G-DISTRIBUTION CHECK FAILED *** — do not explain away.")
        elif unpinned:
            print("RESULT: unpinned null G-distribution reproduced exactly.")
            print("        SCOPE: this is the bare C1 null with the start UNPINNED — no C4,")
            print("        no C2, no C5, no budget truncation: uniform orderings of all 32")
            print("        pair-slots (orientations cancel in G). P(G <= 95) here is the")
            print("        EXACT value of the C3|C1 rate that solve.c --null-pair-constrained")
            print("        samples (6.42% at 10^9 trials). Same non-comparability caveats as")
            print("        the pinned null apply to C2/C5-conditioned populations.")
        else:
            print("RESULT: null G-distribution reproduced exactly.")
            print("        SCOPE: this is the C1&C4 null ONLY — no C2, no C5, no budget")
            print("        truncation. It is NOT comparable like-for-like to ceiling-tie")
            print("        shares measured over C2/C5-conditioned enumerated populations,")
            print("        and it does not on its own refute or confirm any such figure.")
        print("=" * 74)
    return 0 if ok[0] else 1


# Exact C2-acceptance target: |C1&C2&C4| / |C1&C4| = |C1&C2&C4| / (31! * 2^31).
# |C1&C2&C4| is an EXACT integer (S4-orbit DP, 2026-07-04; DESCRIPTION_LENGTH.md).
_C1C2C4_EXACT = 757058601340255440651419713405330315358208


def check_c2_shift(n_samples=200_000, seed=20260724, verbose=True):
    """DECISION-SUPPORT (Monte-Carlo — NOT a canonical count): measure how conditioning
    on C2 shifts the G-distribution at the C1&C2&C4 scope, i.e. P(G<=95 | C1&C2&C4), by
    importance-weighting the exact C1&C4 null with w(sigma) = the exact number of C2-valid
    orientation assignments of pair-order sigma (a 2x2 transfer product over exit faces).
    Ratio estimator R = E[w 1_{G<=95}] / E[w] with a delta-method CI.

    HARD-GATED on the exact acceptance identity E[w]/2^31 == |C1&C2&C4|/|C1&C4| (within
    Monte-Carlo error): a broken sampler cannot pass it. Reads no files; uses only PAIRS +
    hamming, nothing from solve.c (independence).

    SCOPE / GRADE: this is a MEASURED estimate with a CI, at MC grade. It is decision
    support, NOT a canonical published number. The load-bearing EXACT legs of the C3
    rule-out are --check-null-g (the C1&C4 null) and the exact rung histograms; this
    instrument only pins the small C2 shift between the two, with an error bar."""
    import math, random

    fs = [frozenset(p) for p in PAIRS]
    idx = {f: i for i, f in enumerate(fs)}
    ctab = []  # per pair: complement-couple partner index, or None for a self-complement pair
    for i, (a, b) in enumerate(PAIRS):
        comp = frozenset((a ^ 63, b ^ 63))
        ctab.append(None if comp == fs[i] else idx[comp])
    if sum(1 for c in ctab if c is None) != 8:
        print("FAIL: expected exactly 8 self-complement pairs")
        return 1

    free = list(range(1, 32))          # pinned pair 0 = {63,0} fixed (C4); free pairs 1..31
    rng = random.Random(seed)
    N = int(n_samples)

    sum_w = 0        # Sum w
    sum_wA = 0       # Sum w * 1_{G<=95}
    sum_w_tie = 0    # Sum w * 1_{G==95}
    sum_w2 = 0.0     # Sum w^2      (for w-fluctuation + acceptance SE)
    sum_w2A = 0.0    # Sum w^2 * 1_{G<=95}   (for the ratio delta-method SE)
    gsum_w = 0       # Sum w * G    (for E[G | C2])
    n_wzero = 0
    for _ in range(N):
        rng.shuffle(free)
        # exact G = sum over cross-couples of |slot difference| (self-couples excluded: they are the +16)
        slot = {}
        g = 0
        for s, pi in enumerate(free, start=1):
            pj = ctab[pi]
            if pj is not None:
                if pj in slot:
                    g += s - slot[pj]
                else:
                    slot[pi] = s
        # exact w = number of C2-valid orientation assignments (transfer product over exit faces)
        prev = {0: 1}                  # start exit face = 0 (Kun exit, C4)
        for pi in free:
            a, b = PAIRS[pi]
            nxt = {}
            for exitf, c in prev.items():
                if hamming(exitf, a) != 5:   # enter a, exit b (no 5-line boundary transition)
                    nxt[b] = nxt.get(b, 0) + c
                if hamming(exitf, b) != 5:   # enter b, exit a
                    nxt[a] = nxt.get(a, 0) + c
            prev = nxt
            if not prev:
                break
        w = sum(prev.values())
        wf = float(w)
        if w == 0:
            n_wzero += 1
        sum_w += w
        sum_w2 += wf * wf
        gsum_w += g * w
        if g <= 95:
            sum_wA += w
            sum_w2A += wf * wf
            if g == 95:
                sum_w_tie += w

    if sum_w == 0:
        print("FAIL: all sampled pair-orders had w==0 (impossible unless the sampler is broken)")
        return 2

    Ew = sum_w / N
    E_w2 = sum_w2 / N
    E_w2A = sum_w2A / N
    R = sum_wA / sum_w                                   # P(G<=95 | C1&C2&C4)
    tie = sum_w_tie / sum_w
    relsd = math.sqrt(max(0.0, E_w2 - Ew * Ew)) / Ew     # sd(w)/E[w]
    # delta-method SE of the ratio R: Var(R) ~ E[w^2 (1_A - R)^2] / (N * E[w]^2)
    resid2 = (1.0 - 2.0 * R) * E_w2A + R * R * E_w2
    se_R = math.sqrt(max(0.0, resid2) / (N * Ew * Ew))
    # acceptance estimate + its SE
    acc_hat = Ew / (2 ** 31)
    exact_acc = _C1C2C4_EXACT / (math.factorial(31) * (2 ** 31))
    se_acc = (math.sqrt(max(0.0, E_w2 - Ew * Ew)) / (2 ** 31)) / math.sqrt(N)

    # HARD GATE: the estimated acceptance must agree with the exact identity within 5 sigma.
    gate_ok = abs(acc_hat - exact_acc) <= 5.0 * se_acc

    if verbose:
        print("=" * 74)
        print("verify.py --check-c2-shift : P(G<=95 | C1&C2&C4) by importance-weighted MC")
        print("  DECISION-SUPPORT (Monte-Carlo, CI-labeled) -- NOT a canonical count.")
        print(f"  N = {N:,}   seed = {seed}")
        print("=" * 74)
        status = "PASS" if gate_ok else "*** FAIL ***"
        print(f"  [{status}] acceptance identity  E[w]/2^31 == |C1&C2&C4|/|C1&C4|")
        print(f"            estimate {acc_hat:.6f}  +/- {se_acc:.6f} (1 sigma)")
        print(f"            exact    {exact_acc:.6f}  (= 4.2872%; |C1&C2&C4| S4-orbit DP)")
        print(f"            |diff|   {abs(acc_hat-exact_acc):.6f}  ({abs(acc_hat-exact_acc)/se_acc:.2f} sigma; gate = 5 sigma)")
        print("-" * 74)
        print(f"  P(G<=95 | C1&C2&C4)  = {100*R:.4f}%   95% CI [{100*(R-1.96*se_R):.3f}%, {100*(R+1.96*se_R):.3f}%]")
        print(f"  P(G==95 | C1&C2&C4)  = {100*tie:.4f}%")
        print(f"  E[G   | C1&C2&C4]    = {gsum_w/sum_w:.4f}")
        print(f"  w==0 fraction        = {n_wzero/N:.6f}   sd(w)/E[w] = {relsd:.3f}")
        print("-" * 74)
        print(f"  compare EXACT C1&C4 null P(G<=95)   = 8.106231%   (--check-null-g)")
        print(f"  compare prior MC estimates          ~ 8.9% (c2quant 8.98%; 2026-07-24 review 8.89%)")
        print("  READING: the C2 shift is small and *upward* (tail slightly inflated),")
        print("           so KW's G=95 stays null-generic at the C1&C2&C4 scope. This")
        print("           MEASURES that shift with a CI; it does not (and cannot cheaply)")
        print("           make it exact -- the exact legs are --check-null-g + the rungs.")
        print("=" * 74)
        if gate_ok:
            print("RESULT: acceptance identity reproduced; C2-shift measured (MC grade).")
        else:
            print("RESULT: *** ACCEPTANCE GATE FAILED *** — sampler is broken; estimate not trustworthy.")
        print("=" * 74)

    return 0 if gate_ok else 2


# ============================================================================
# ANALYSES OVER LARGE, PRIVATELY-HELD ARTIFACTS  (task #213 C, 2026-08-11)
#
# WHY THESE LIVE HERE. Three analyses previously existed only as scripts in the
# private staging repo, so the numbers they produce were not publicly
# reproducible: a reader could see the figure and had no way to regenerate it.
# A script that only the operator can run does not make a public number
# reproducible — that is the whole of the #213 debt. The INPUT ARTIFACTS are
# large and stay private (a ~107 MB draw sample; two campaign logs); the
# ANALYSIS is public, takes the artifact PATH from the caller, and states in
# its help text the command that GENERATES that artifact and what that cost.
# The promise is therefore "reproducible at a stated price", not a nominal
# claim of reproducibility. Anyone with the stated budget can rebuild the
# input and re-derive every number these modes print.
#
# INDEPENDENCE IS PRESERVED — do not "fix" this by importing engine helpers.
# These modes import nothing from solve.c / solve.py / roae.py / sat.py, in
# keeping with this file's standing discipline. The MEMBERSHIP evaluator in
# particular exists ONLY because it shares no code with the sampler whose
# output it judges: every predicate below is transcribed from
# documentation/SPECIFICATION.md §C1/C2/C4/C5, and `partner` is re-derived from
# the stated rule (reverse; complement for the self-reverse hexagrams) rather
# than copied from any table. It reuses this file's own rule-derived helpers
# (`_partner`, `hamming`, `compute_comp_dist`), all of which are gated at
# import by `_verify_tables_against_rules()` against the SPECIFICATION.md
# literals — that is the same clean-room derivation, not a shortcut through the
# engine. Importing a solve.c/solve.py helper here would destroy the only
# property that makes the check worth running.
# ============================================================================

# --- FROZEN BARS ------------------------------------------------------------
# Quoted from the pre-registration `PREREG_F_CATALOG_T1_T4_2026_08_06.md` §3
# (private staging repo), committed 2026-08-06 — BEFORE the first recorded T3
# draw. No bar here was chosen after seeing data and none may be adjusted to
# make a result land: on a breach the prereg's own instruction is that the
# sample is QUARANTINED, never silently redrawn.
T3_N = 1097051278789181790036112071176579186688  # |C1∩C2∩C4∩C5| (TR-11 §9)
T3_BUCKETS = 16          # equal rank buckets, bucket = floor(16*r/N)
T3_CHI2_BAR = 37.70      # 15 dof; the engine's own kc-midn critical value
T3_CD_MAX = 387          # the C3 threshold, in the sampler's `cd=` units
T3_P0 = 0.12107          # 1/8.26, the doc figure named in the prereg
T3_SIGMA_K = 4.0         # flag beyond 4 sigma, either direction


def _t3_c5_target():
    """The C5 transition multiset, taken from this file's import-time-gated
    tables rather than re-typed: `_verify_tables_against_rules()` already
    raises unless KW_DIST equals the SPECIFICATION.md §C5 literal
    {1:2, 2:20, 3:13, 4:19, 6:9}, so deriving it from KW_DIST cannot silently
    drift from the spec."""
    return {d: KW_DIST[d] for d in range(7) if KW_DIST[d]}


def _t3_cd(seq):
    """The sampler's recorded `cd=` value for a full 64-hexagram sequence.

    DERIVED, not copied from the engine. `compute_comp_dist()` above is the
    SPECIFICATION.md C3 functional: it sums |pos[v] − pos[v^63]| over ALL 64
    v, so every complement pair is counted TWICE. The engine's `cd` counts each
    pair once and excludes the C4-pinned (63, 0) pair, which sits at positions
    0 and 1 and contributes |0−1| = 1. Hence

        cd(seq) = compute_comp_dist(seq) // 2 − 1

    which is gated on King Wen in `_t3_sanity()`: compute_comp_dist(KW) == 776
    (already asserted at import) and cd(KW) == 387 == the prereg's threshold.
    """
    return compute_comp_dist(seq) // 2 - 1


def _t3_c1(S):
    """C1: for every even i, s_{i+1} = partner(s_i)."""
    return all(S[i + 1] == _partner(S[i]) for i in range(0, len(S), 2))


def _t3_c2(S):
    """C2: no transition has Hamming distance 5."""
    return all(hamming(S[i], S[i + 1]) != 5 for i in range(len(S) - 1))


def _t3_c4(S):
    """C4 (oriented): s0 = 63, s1 = 0."""
    return S[0] == 63 and S[1] == 0


def _t3_c5(S):
    """C5: the multiset of the 63 transition distances is exactly the target."""
    got = {}
    for i in range(len(S) - 1):
        d = hamming(S[i], S[i + 1])
        got[d] = got.get(d, 0) + 1
    return got == _t3_c5_target()


_T3_PREDS = [("C1", _t3_c1), ("C2", _t3_c2), ("C4", _t3_c4), ("C5", _t3_c5)]


def _t3_member(S):
    return all(f(S) for _, f in _T3_PREDS)


def _t3_which_fail(S):
    return [n for n, f in _T3_PREDS if not f(S)]


def _t3_reconstruct(walk):
    """A stream line carries 62 entries — the C4 opening pair is pinned and not
    repeated in the walk. Prepend it to get the 64-element sequence, i.e. the
    63 transitions C5's multiset (2+20+13+19+9 = 63) requires."""
    return [63, 0] + list(walk)


def _t3_sanity():
    """The evaluator checking ITSELF: properties of the transcription that must
    hold before any verdict it produces means anything. Returns [(desc, ok)]."""
    out = []
    out.append(("partner is an involution on all 64 hexagrams",
                all(_partner(_partner(x)) == x for x in range(64))))
    out.append(("exactly 8 self-reverse hexagrams",
                len([x for x in range(64) if _rev6(x) == x]) == 8))
    out.append(("partner(x) != x for all x",
                all(_partner(x) != x for x in range(64))))
    out.append(("partner(63) == 0 (the C4 pair)", _partner(63) == 0))
    out.append(("within-pair distances are even",
                all(hamming(x, _partner(x)) % 2 == 0 for x in range(64))))
    out.append(("C5 target sums to 63 transitions",
                sum(_t3_c5_target().values()) == 63))
    out.append(("compute_comp_dist(KW) == 776 (C3 anchor)",
                compute_comp_dist(KW) == 776))
    out.append(("cd(KW) == 387 == the prereg C3 threshold",
                _t3_cd(KW) == T3_CD_MAX))
    out.append(("King Wen itself is accepted (checker is not always-reject)",
                _t3_member(KW)))
    return out


def _t3_open(path):
    """Streams are stored gzipped; accept either form."""
    return (gzip.open(path, "rt", errors="replace") if path.endswith(".gz")
            else open(path, "rt", errors="replace"))


def _t3_stream_paths(path):
    """Resolve a --t3-* argument to a sorted list of stream files. Accepts a
    DIRECTORY holding t3_stream_*.out[.gz], or a single stream file."""
    import glob as _glob
    if os.path.isdir(path):
        return sorted(_glob.glob(os.path.join(path, "t3_stream_*.out.gz"))
                      + _glob.glob(os.path.join(path, "t3_stream_*.out")))
    return [path] if os.path.exists(path) else []


def _t3_iter_draws(paths, want_walk=False):
    """Yield (path, rank, cd[, walk]) for every DRAW line.

    INPUT FORMAT, measured from the artifact rather than assumed. Two lines per
    draw:
        <rank>\\tcd=<n>\\t<62-element walk>    <- the draw
        record\\tm=<mass>\\t<62-element walk>  <- its orientation-lex-min rep
    Only the draw line carries a rank and a cd. Streams also carry provenance
    headers that happen to have three tab fields, so requiring field 1 to start
    with 'cd=' is what separates a draw from a record line or a header.

    The WALK line is the one checked, deliberately. Both lines carry the same
    62 pair elements in the same order and differ only in within-pair
    orientation; the `record` line is the orientation-lex-min representative,
    so checking it would answer "does this class admit a valid orientation" —
    strictly weaker than, and easy to confuse with, "is the emitted walk a
    member", which is the pre-registered question.
    """
    for path in paths:
        with _t3_open(path) as fh:
            for line in fh:
                f = line.rstrip("\n").split("\t")
                if len(f) < 3 or f[0] == "record" or not f[1].startswith("cd="):
                    continue
                if want_walk:
                    yield path, int(f[0]), int(f[1][3:]), [int(x) for x in f[2].split(",")]
                else:
                    yield path, int(f[0]), int(f[1][3:])


_T3_GEN = (
    "  GENERATING THE INPUT (the artifact is private; the recipe is not):\n"
    "    16 independent streams x 62,500 draws, one invocation per stream, with the\n"
    "    enumerator's KC sampler subcommand and these arguments:\n"
    "      --kc-sample <f-dir> 62500 <seed> --kc-record --kc-ooc --kc-cache-mb 384\n"
    "      (with SOLVE_F1_OOC_READ_MB=1)\n"
    "    WHICH BUILD: the --kc-* subcommands are NOT on main. They live in solve.c on\n"
    "    the published branch `v4-query-program`, which BRANCH_REGISTRY.tsv classes as\n"
    "    a snapshot (a frozen working branch, not the authoritative corpus, and it may\n"
    "    carry claims since corrected on main -- read main for the corpus). So the\n"
    "    honest price of regenerating this sample includes checking out that branch\n"
    "    and building its solve.c; the command is written here WITHOUT a `solve`\n"
    "    prefix precisely because it is not runnable against this ref's binary, and\n"
    "    a doc must not imply otherwise.\n"
    "    MEASURED COST: ~12.6 h wall on one D16als_v7 against a 3.1 TB f-ladder\n"
    "    (16 lanes, Premium P50 f-disk). Seed-deterministic: the same seeds against\n"
    "    the same f-ladder and binary regenerate the same draws.\n")


def t3_stats(path):
    """#177 statistics (a) and (c) over a T3 draw sample. See _T3_GEN for how
    the sample is produced and at what cost."""
    import math
    paths = _t3_stream_paths(path)
    if not paths:
        print(f"no T3 stream files found at {path} "
              f"(expected a directory of t3_stream_*.out[.gz], or one such file)")
        return 1

    print("=" * 74)
    print("verify.py --t3-stats : pre-registered T3 validity statistics (a) and (c)")
    print("  Bars are FROZEN in PREREG_F_CATALOG_T1_T4_2026_08_06.md §3, committed")
    print("  BEFORE the first recorded draw. A breach is a FINDING: quarantine the")
    print("  sample, do not redraw, do not adjust a bar.")
    print("=" * 74)
    print(_T3_GEN, end="")

    counts = [0] * T3_BUCKETS
    per_stream = {}
    n_le = M = out_of_range = 0
    r_min = r_max = None
    for p, r, cd in _t3_iter_draws(paths):
        M += 1
        per_stream[p] = per_stream.get(p, 0) + 1
        if 0 <= r < T3_N:
            counts[(T3_BUCKETS * r) // T3_N] += 1
        else:
            out_of_range += 1
        r_min = r if r_min is None or r < r_min else r_min
        r_max = r if r_max is None or r > r_max else r_max
        if cd <= T3_CD_MAX:
            n_le += 1

    if M == 0:
        print("\nno draw lines parsed — nothing was measured. Treated as a failure.")
        return 1

    print("\n=== INPUT ===")
    print(f"  streams        : {len(per_stream)}")
    print(f"  draws total M  : {M:,}")
    sizes = sorted(set(per_stream.values()))
    print(f"  draws/stream   : {sizes[0] if len(sizes) == 1 else 'UNEVEN %s' % sizes}")
    print(f"  rank range     : [{r_min}, {r_max}]")
    print(f"  N              : {T3_N}")
    print(f"  ranks outside [0,N) : {out_of_range}"
          + ("" if out_of_range == 0 else "   *** INVALID ***"))
    if out_of_range:
        print("  A rank outside [0,N) is a first-order defect in the unrank path.")
        return 1

    exp = M / T3_BUCKETS
    chi2 = sum((c - exp) ** 2 / exp for c in counts)
    print(f"\n=== (a) UNIFORMITY — chi^2, {T3_BUCKETS} buckets, {T3_BUCKETS - 1} dof ===")
    print(f"  expected/bucket: {exp:.1f}")
    for i, c in enumerate(counts):
        print(f"    bucket {i:2d}: {c:9,}   ({100.0 * (c - exp) / exp:+.2f}%)")
    print(f"  chi^2 = {chi2:.4f}   bar = {T3_CHI2_BAR:.2f}")
    uni_pass = chi2 < T3_CHI2_BAR
    print("  VERDICT: " + ("PASS — rank stream is uniform on [0, N)" if uni_pass else
                           "*** FINDING — chi^2 >= bar. QUARANTINE the sample. "
                           "Investigate the RNG/unrank path. DO NOT REDRAW. ***"))

    obs = n_le / M
    sigma = math.sqrt(T3_P0 * (1 - T3_P0) / M)
    dev = obs - T3_P0
    print(f"\n=== (c) C3 FRACTION — cd <= {T3_CD_MAX} ===")
    print(f"  observed  : {n_le:,} / {M:,} = {obs:.6f}")
    print(f"  p0        : {T3_P0:.6f}  (1/8.26, the doc figure named in the prereg)")
    print(f"  sigma     : {sigma:.6f}   (sqrt(p0(1-p0)/M))")
    print(f"  deviation : {dev:+.6f}  = {dev / sigma:+.2f} sigma   bar = {T3_SIGMA_K:.1f} sigma")
    c3_ok = abs(dev) <= T3_SIGMA_K * sigma
    print("  VERDICT: " + ("within bar — unremarkable" if c3_ok else
                           f"*** FINDING — beyond {T3_SIGMA_K:.0f} sigma. Flag per prereg. ***"))
    print("  NOTE: p0 is the DOC figure 1/8.26, not an exact rational. The prereg allows")
    print("        an exact p0 from the A2 coverage line to be substituted later as a")
    print("        dated annotation; the 4-sigma rule is unchanged by that substitution.")

    print("\n=== (b) MEMBERSHIP — NOT COMPUTED HERE ===")
    print("  Statistic (b) is a separate full-population pass with its own cost, and")
    print("  this mode does not restate a number it did not measure. Run:")
    print("      python3 verify.py --t3-membership <same path>")

    print("\n=== SCOPE — what this does NOT establish ===")
    print("  Uniformity of the RANK STREAM is not uniformity over the solution space in")
    print("  any richer sense: it tests the unrank path, which is exactly the embedded")
    print("  validity hypothesis the prereg framed. A PASS licenses the sample as a")
    print("  uniform null; it says nothing about whether any particular downstream")
    print("  observable is well-behaved.")
    print("\n=== SUMMARY ===")
    print("  (a) uniformity  : %s" % ("PASS" if uni_pass else "FINDING"))
    print("  (b) membership  : not run here (--t3-membership)")
    print("  (c) C3 fraction : %s" % ("within bar" if c3_ok else "FINDING"))
    print("=" * 74)
    return 0 if (uni_pass and c3_ok) else 1


def t3_membership(path, limit=0):
    """#177 statistic (b): independent membership re-validation of a T3 sample.

    The pre-registered bar is 100% — a single failure is a first-order finding.
    Adds two checks the prereg did not require: an independent recompute of the
    engine's `cd=` value, and duplicate detection."""
    import time
    paths = _t3_stream_paths(path)
    if not paths:
        print(f"no T3 stream files found at {path} "
              f"(expected a directory of t3_stream_*.out[.gz], or one such file)")
        return 1

    print("=" * 74)
    print("verify.py --t3-membership : independent membership census of a T3 sample")
    print("  SECOND-LANGUAGE CHECK. Every predicate is transcribed from")
    print("  SPECIFICATION.md §C1/C2/C4/C5 and shares no code with the sampler that")
    print("  produced these draws. Bar: 100% members. A single failure is a")
    print("  first-order finding — quarantine, do not redraw, do not adjust the bar.")
    print("=" * 74)
    print(_T3_GEN, end="")

    print("\n=== transcription sanity (the evaluator checking ITSELF) ===")
    ok_all = True
    for desc, ok in _t3_sanity():
        print("  [%s] %s" % ("ok" if ok else "FAIL", desc))
        ok_all = ok_all and ok
    if not ok_all:
        print("*** transcription is broken — stopping; results would be meaningless ***")
        return 2

    # POSITIVE CONTROLS. A checker that always says MEMBER passes everything, so
    # each predicate must be shown to FIRE on a deliberate violation of itself.
    # Controls are built from a real draw, so they also prove the file parsed.
    first = None
    for _, _, _, w in _t3_iter_draws(paths[:1], want_walk=True):
        first = w
        break
    if first is None:
        print("\nno draw lines parsed — nothing was measured. Treated as a failure.")
        return 1
    base = _t3_reconstruct(first)
    print("\n=== structural check on the first draw ===")
    print(f"  length 62                      : {len(first) == 62}")
    print(f"  a permutation of {{1..62}}       : {sorted(first) == list(range(1, 63))}")
    if not _t3_member(base):
        print("  *** the first draw is not a member; cannot build controls from it ***")
        print(f"      failing: {_t3_which_fail(base)}")
        return 3

    print("\n=== POSITIVE CONTROL — each predicate must REJECT its own violation ===")
    print("  Each control breaks the NAMED constraint; the run fails unless that")
    print("  constraint's predicate is among the ones that fire. (Collateral failures")
    print("  are expected and reported: one edit can break more than one constraint.)")
    controls = []
    # C1: swap two hexagrams across pair blocks — destroys the pairing.
    b = list(base); b[4], b[6] = b[6], b[4]; controls.append(("C1", b))
    # C4: flip the pinned opening orientation.
    b = list(base); b[0], b[1] = b[1], b[0]; controls.append(("C4", b))
    # C2 and C5: transposing two WHOLE pair blocks preserves C1 and C4 exactly, so
    # it isolates the transition-distance constraints. Search that family for one
    # swap that creates a distance-5 edge (C2), and one that perturbs the distance
    # multiset WITHOUT creating a distance-5 edge (C5 on its own).
    c2_ctrl = c5_ctrl = None
    for i in range(2, 62, 2):
        for j in range(i + 2, 62, 2):
            b = list(base)
            b[i], b[i + 1], b[j], b[j + 1] = b[j], b[j + 1], b[i], b[i + 1]
            ok_c2 = _t3_c2(b)
            if c2_ctrl is None and not ok_c2:
                c2_ctrl = b
            if c5_ctrl is None and ok_c2 and not _t3_c5(b):
                c5_ctrl = b
            if c2_ctrl is not None and c5_ctrl is not None:
                break
        if c2_ctrl is not None and c5_ctrl is not None:
            break
    for nm, ct in (("C2", c2_ctrl), ("C5", c5_ctrl)):
        if ct is None:
            print(f"  *** no pair-block swap of this draw violates {nm}; control NOT built,")
            print(f"      so {nm} is UNPROVEN on this run ***")
            return 2
        controls.append((nm, ct))
    blind = 0
    for name, cb in controls:
        fails = _t3_which_fail(cb)
        hit = name in fails
        if not hit:
            blind += 1
        print("  break %-3s -> %s  failing predicates=%s"
              % (name, "rejected by its own predicate" if hit
                 else "*** NOT REJECTED BY %s — CHECKER IS BLIND ***" % name,
                 fails or "NONE"))
    if blind:
        print("  *** a control was not caught by the constraint it violates; the checker")
        print("      cannot see that violation and its verdicts are worthless ***")
        return 2

    # THE MEASUREMENT — every draw in `paths`, or the first `limit` if capped.
    t0 = time.time()
    tot = bad_struct = cd_mismatch = dups = n_nonmember = 0
    bad = []
    per_pred = {}
    seen = set()
    for p, _r, cd_rec, w in _t3_iter_draws(paths, want_walk=True):
        S = _t3_reconstruct(w)
        if len(w) != 62 or sorted(w) != list(range(1, 63)):
            bad_struct += 1
        f = _t3_which_fail(S)
        if f:
            n_nonmember += 1
            if len(bad) < 10:
                bad.append((os.path.basename(p), tot, f))
            for n_ in f:
                per_pred[n_] = per_pred.get(n_, 0) + 1
        if _t3_cd(S) != cd_rec:
            cd_mismatch += 1
        k = bytes(w)
        if k in seen:
            dups += 1
        else:
            seen.add(k)
        tot += 1
        if limit and tot >= limit:
            break
    elapsed = time.time() - t0

    # per_pred counts PREDICATE failures, which can exceed the number of failing
    # walks (one walk may break two constraints); the walk count is reported
    # separately rather than conflated.
    print(f"\n=== MEMBERSHIP CENSUS over {tot:,} draw(s) "
          f"({len(paths)} stream file(s){', capped by --t3-membership-limit' if limit else ''}) ===")
    print(f"  members                                    : {tot - n_nonmember:,} / {tot:,}")
    print(f"  NON-MEMBER walks                           : {n_nonmember}")
    print(f"  structural failures (length / permutation) : {bad_struct}")
    print(f"  predicate failures by constraint           : "
          f"{per_pred if per_pred else '{} (none)'}")
    print(f"  cd mismatches (independent recompute vs engine `cd=`) : {cd_mismatch}")
    print(f"  duplicate walks                            : {dups}")
    print(f"  elapsed                                    : {elapsed:.1f}s")
    if bad:
        print("  FIRST NON-MEMBERS (file, index, failing predicates):")
        for row in bad:
            print(f"    {row}")
    failed = bool(per_pred) or bad_struct or cd_mismatch
    if failed:
        print("\n  *** FINDING — the bar is 100%. Quarantine the sample. Do NOT redraw.")
        print("      Do NOT adjust the bar. ***")
    else:
        print("\n  VERDICT: 100% MEMBER — statistic (b) meets its pre-registered bar.")
        print("           cd cross-check and duplicate check are EXTRA, beyond the prereg.")
    print("=" * 74)
    return 1 if failed else 0


def _g_load_hist(path):
    """Parse G_HIST bins (+ optional G_HIST_TOTAL / G_HIST_WSUM) from a full-31
    run log. Emitted by the enumerator; the format is read here, never imported."""
    import re as _re
    pat = _re.compile(r'^G_HIST\s+g=(-?\d+)\s+count=(\d+)')
    bins, total, wsum = {}, None, None
    with open(path, errors="replace") as fh:
        for line in fh:
            m = pat.match(line)
            if m:
                bins[int(m.group(1))] = int(m.group(2))
                continue
            if line.startswith("G_HIST_TOTAL"):
                total = int(line.split("=")[1].split()[0])
            elif line.startswith("G_HIST_WSUM"):
                wsum = int(line.split("=")[1].split()[0])
    return bins, total, wsum


def _g_factor(n, lim=100000):
    """Trial division to `lim`. Any residue left above lim^2 may be COMPOSITE —
    the caller says so rather than implying a complete factorization."""
    f, d = {}, 2
    while d * d <= n and d < lim:
        while n % d == 0:
            f[d] = f.get(d, 0) + 1
            n //= d
        d += 1
    if n > 1:
        f[n] = f.get(n, 0) + 1
    return f


def _g_moments(bins):
    from fractions import Fraction as F
    n = sum(bins.values())
    mu = F(sum(g * c for g, c in bins.items()), n)
    cm = lambda r: F(sum(c * (F(g) - mu) ** r for g, c in bins.items()), n)
    return n, mu, cm(2), cm(3), cm(4)


def _g_series_pow(q, alpha, terms):
    """Coefficients of q(z)^alpha as a power series (requires q[0] != 0).
    J.C.P. Miller's recurrence — a standard identity, implemented here."""
    p = [0.0] * terms
    p[0] = q[0] ** alpha
    for k in range(1, terms):
        acc = 0.0
        for j in range(1, k + 1):
            if j < len(q):
                acc += ((alpha + 1) * j - k) * q[j] * p[k - j]
        p[k] = acc / (k * q[0])
    return p


def g_structure(c2on_path, c2off_path):
    """#205: structure of the full-31 G distribution, C2-on and C2-off.

    Regenerates every number in the private G_DISTRIBUTION_STRUCTURE note, which
    was first produced as inline one-off heredocs — numbers in prose with no
    runnable provenance. A derivation checked against a number nobody can
    regenerate is not a check."""
    from fractions import Fraction as F
    for p in (c2on_path, c2off_path):
        if not os.path.exists(p):
            print(f"missing G_HIST log: {p}")
            return 1

    print("=" * 74)
    print("verify.py --g-structure : full-31 G-distribution structure (C2-on vs C2-off)")
    print("=" * 74)
    print("  GENERATING THE INPUTS (the logs are private; the recipe is not):")
    print("    both are full-31 enumerator runs that emit G_HIST bin lines —")
    print("      solve --f1-c3-hist --f1-pairs 31 --f1-out-of-core DIR          (C2-ON)")
    print("      solve --f1-c3-hist --f1-pairs 31 --f1-out-of-core DIR --no-c2  (C2-OFF)")
    print("    These are on main; see SOLVE_C_CLI.md.")
    print("    MEASURED: 23,054 s (C2-on) and 39,003 s (C2-off) on 128 threads. Each is")
    print("    the FINAL ATTEMPT's wall — both runs checkpoint/resumed across Spot")
    print("    evictions (the C2-off log begins at 'RESUME from last complete layer")
    print("    k=16'), so these are LOWER BOUNDS on from-scratch cost, not the total.")
    print("    The logs were already captured and sha-verified; this analysis reads")
    print("    them only — no compute, no VM.")
    print("\n=== INPUTS ===")
    print(f"  C2-ON  {c2on_path}")
    print(f"  C2-OFF {c2off_path}")

    rc = 0
    for tag, path in (("C2-ON (C1&C2&C4)", c2on_path), ("C2-OFF (C1&C4)", c2off_path)):
        bins, total, wsum = _g_load_hist(path)
        if not bins:
            print(f"\n{path}: no G_HIST bin lines — nothing measured. Treated as a failure.")
            return 1
        n, mu, m2, m3, m4 = _g_moments(bins)
        print(f"\n=== {tag} ===")
        print(f"  bins={len(bins)} gmin={min(bins)} gmax={max(bins)}")
        # V2-F58 #5 (2026-08-30): absent TOTAL/WSUM lines used to silently drop
        # these checks from the census — a full-31 producer log ALWAYS carries
        # both, so absence is a failure, not a skip.
        if total is not None:
            print(f"  sum(bins) == G_HIST_TOTAL : {n == total}")
            rc |= 0 if n == total else 1
        else:
            print("  G_HIST_TOTAL line ABSENT — sum check NOT EVALUATED: failure")
            rc |= 1
        if wsum is not None:
            agree = sum(g * c for g, c in bins.items()) == wsum
            print(f"  sum(g*c)  == G_HIST_WSUM  : {agree}")
            rc |= 0 if agree else 1
        else:
            print("  G_HIST_WSUM line ABSENT — weighted-sum check NOT EVALUATED: failure")
            rc |= 1
        print(f"  E[G]  = {mu}  = {float(mu):.9f}")
        print(f"  Var   = {m2}  = {float(m2):.6f}")
        print(f"  mu3   = {m3}  = {float(m3):.6f}")
        print(f"  skew  = {float(m3) / float(m2) ** 1.5:.8f}")
        print(f"  exkurt= {float(m4) / float(m2) ** 2 - 3:.8f}")
        # V2-F58 #5 (2026-08-30): this invariant was printed but never wired to
        # the exit status — a False here now goes red like every other line.
        div48 = all(c % 48 == 0 for c in bins.values())
        print(f"  all bins divisible by 48 : {div48}")
        rc |= 0 if div48 else 1
        print(f"  N factors (trial division to 100000; a residue above 10^10 may be"
              f" composite): {_g_factor(n)}")

        if "C2-OFF" in tag:
            print("\n  --- the SHARP pre-registered test ---")
            if total is not None and wsum is not None:
                exact = (wsum == 128 * total)
                print(f"  WSUM == 128 * TOTAL exactly : {exact}  (remainder {wsum - 128 * total})")
                rc |= 0 if exact else 1
            cum = sum(c for g, c in bins.items() if g <= 95)
            p = F(cum, n)
            null = F(641983711307479, 7919632354008375)
            print(f"  P(G<=95)          = {p}")
            print(f"  closed-form null  = {null}")
            print(f"  EQUAL as rationals: {p == null}")
            rc |= 0 if p == null else 1
            print(f"  null denominator factors: {_g_factor(7919632354008375)}")

            print("\n  --- CONVOLUTION TEST: is G a sum of independent parts? ---")
            print(f"  (support span {max(bins) - min(bins)}; the 216 = 12x18 '12 couples'")
            print("   hypothesis predicts q^(1/12) truncates at degree 18. It does not.)")
            gmin = min(bins)
            q = [bins.get(gmin + j, 0) / n for j in range(max(bins) - gmin + 1)]
            print("  %-6s %s" % ("m", "max|coef[30..34]| of q^(1/m)  (~0 would mean m-fold iid)"))
            for m in (2, 3, 4, 6, 7, 8, 12, 16, 18, 19, 24, 31, 36, 48):
                pw = _g_series_pow(q, 1.0 / m, 35)
                tail = max(abs(pw[j] / pw[0]) for j in range(30, 35))
                print("  m=%-4d %.3e" % (m, tail))
            print("  VERDICT: no m truncates -> G is NOT an independent-sum statistic.")
            print("  The moment denominators (5, then 105 = 3*5*7) and the smooth-to-31")
            print("  factorisations above identify it as a PERMUTATION statistic")
            print("  (sampling WITHOUT replacement), which is why no convolution fits.")

    print("\n=== SCOPE ===")
    print("  None of the above touches prefix-G g48-invariance. A quotiented run cannot")
    print("  test the assumption its own quotient makes; do not cite a green run here as")
    print("  narrowing that gap.")
    print(f"GSTRUCTURE_RESULT={'PASS' if rc == 0 else 'FAIL'}")
    print("=" * 74)
    return rc


def main():
    parser = argparse.ArgumentParser(description="Independent two-language constraint verifier for solutions.bin")
    parser.add_argument('path', nargs='?', default='solutions.bin', help='solutions.bin path')
    parser.add_argument('--expect-kw', action='store_true',
                        help='require the King Wen sequence to be present in the '
                             'records (default: presence is reported but not '
                             'required, since an individual shard need not '
                             'contain it). Use on a complete canonical.')
    parser.add_argument('--jobs', type=int, default=1,
                        help='Parallel workers (default 1 = single-thread, identical to legacy behavior). '
                             'Recommended: number of physical cores.')
    parser.add_argument('--enumerate-reference', type=int, metavar='NPAIRS', default=None,
                        help='Independent completeness reference: brute-force the reduced NPAIRS-pair '
                             'problem (C1+C2+C4) two ways (exhaustive vs prune-as-you-go) and assert '
                             'identical sets. Does NOT read solutions.bin. 2<=NPAIRS<=9.')
    parser.add_argument('--recount', action='store_true',
                        help='Independently reproduce the published exact COUNTS (small-n structural '
                             'facts + reduced-rung C1∩C2∩C4 union counts) by a counting recurrence — '
                             'a different method than solve.c\'s symmetry-quotient DP. Prints a match '
                             'table. Does NOT read solutions.bin. Answers TR-11 §10vi.')
    parser.add_argument('--recount-orbit-widths', type=int, metavar='N', default=None,
                        help='Gate the canonical_masks column of '
                             'reports/FULL31_EXACT_AGGREGATES.md (N=31) against a Burnside count '
                             'over the 24-element pair-permutation quotient DERIVED here from the '
                             '48 commuting bit-perms. canonical_masks is a property of the object, '
                             'not of the implementation, and had no instrument. Milliseconds.')
    parser.add_argument('--f1u192-binary-roundtrip', action='store_true',
                        help='Build the n=9 layer files with solve, then read the final layer '
                             'back from RAW BYTES in Python (72-byte header, masks, off, keys, '
                             '24-byte little-endian limb triples) and check its mass against '
                             'this file\'s own independent count. solve\'s own write/resume '
                             'round-trip cannot do this: writer and reader share any limb-order '
                             'defect and cancel it exactly. Absence of a binary FAILS.')
    parser.add_argument('--f1-dec-roundtrip', action='store_true',
                        help='Gate solve.c\'s 192-bit decimal renderer f1_dec() against exact '
                             'Python integer arithmetic across the full range -- both limb '
                             'boundaries, 10^0..10^57, and every layer mass published in '
                             'reports/FULL31_EXACT_AGGREGATES.md. Until this mode the renderer '
                             'was exercised only at 26112, which is one limb wide. Needs a solve '
                             'binary (SOLVE_BIN or ./solve); absence FAILS.')
    parser.add_argument('--recount-rung-layers', type=int, metavar='N', default=None,
                        help='Gate the PER-LAYER masses published in '
                             'reports/FULL31_EXACT_AGGREGATES.md for the N=9 or N=13 C5 rung '
                             'against an independent recount by the plain budgeted DP (no '
                             'symmetry quotient, B0 re-derived). The rung TOTALS were already '
                             'gated; the intermediate layers were not gated by anything until '
                             'this mode. A missing or unparsable table FAILS. Under a second.')
    parser.add_argument('--recount-rung', type=int, metavar='N', default=None,
                        help='Independently recompute a worker-sized TR-11 §4b C5 rung (N in {18, 19}) '
                             'by the plain budgeted packed-state DP, with B0 re-derived by §5 Step 1 '
                             'and the packed DP self-gated against the plain DP at n=16 first. n=19 '
                             'gates against the published integer; n=18 likewise since 2026-08-10 '
                             '(TR-11 v1.18 publishes its integer and this recount reproduced it '
                             'exactly — 157 s, 953 MB). Worker-sized: n=19 needs ~8 GB '
                             'and tens of minutes in CPython. Does NOT read solutions.bin.')
    parser.add_argument('--recount-fiber', action='store_true',
                        help='Independently recount TR-1 §7\'s orientation fiber — the frozen '
                             'dispositive null for the eleven-functional battery: 1,720,320 '
                             '(C4-oriented) / 2,703,360 (pair-only C4) / 983,040 (opening 0,63), '
                             'its 3·5·7·2¹⁴ factorization, and which orientation bits are forced. '
                             'Transfer DP over KW\'s own pair order with B0 recomputed from KW. '
                             'Instant. Does NOT read solutions.bin.')
    parser.add_argument('--fiber-sweep', action='store_true',
                        help='Measure the ORIENTATION-FIBER FACTOR: the exact conversion '
                             'between the two counting levels the suite publishes side by '
                             'side — deduped RECORDS (pair orderings) vs orientation-explicit '
                             'SEQUENCES. Gates on King Wen\'s own fiber (1,720,320 / 983,040 / '
                             '2,703,360, TR-1 §7) and on agreement with --recount-fiber\'s '
                             'independent DP, then reports the exact fiber-size distribution '
                             'over the records of the solutions.bin at `path` (gzip ok) if one '
                             'is present. ~0.2 ms per record; seconds on the repo sample.')
    parser.add_argument('--recount-subtree', action='store_true',
                        help='Independently recompute the exact deterministic subtree anchors of '
                             'TR-5 §3 / SEARCH_SPACE_SIZE.md (KW-following prefixes at 5/7/9 free '
                             'positions: tree_nodes 443 / 62,256 / 9,422,793 and canonical leaves '
                             '4 / 2,232 / 16,504) plus the sigma-related-prefix tree-isomorphism '
                             'check, plus three away-from-KW anchors whose expectations come from '
                             'solve.c --estimate-knuth exact mode (leaf C3 528..1104 — the C3 '
                             'predicate exercised in both directions away from the 776 threshold; '
                             'see _CROSS_PREFIXES). ~1-2 min. Does NOT read solutions.bin.')
    parser.add_argument('--recount-finite', action='store_true',
                        help='Independently recompute the finite record-mode + wrap/parity tallies: '
                             'TR-5\'s 48-of-720 validity classification / 24 records / 23 twins '
                             '(validity checked from the constraint definitions, not group '
                             'membership), TR-6\'s 15 alternations / 30 switches / wrap-parity / '
                             'circular 16-of-64, and the 82,818,450 arrangement count. Seconds. '
                             'Does NOT read solutions.bin.')
    parser.add_argument('--recount-gender-null', action='store_true',
                        help='Independently recompute TR-8 §Commands\' exact pair-null gender figure '
                             'P(rc4_violations <= 2) = 47/445740 (~1.054426e-04) — the functional '
                             'rebuilt from the published Schulz-1990 definition and the 32!·2^32 '
                             'pair-only null solved exactly two ways (closed form + slot DP, '
                             'cross-asserted; Fractions, no sampling), gated on KW\'s published '
                             'anchors (2 violations at class positions 25/26). Instant. Does NOT '
                             'read solutions.bin.')
    parser.add_argument('--check-certificate', metavar='DIR', default=None,
                        help='Artifact check for a completed f1c5 run directory (TR-11 §10iii): '
                             'validates the per-layer certificate rows, manifest, and preserved '
                             'digests against structural identities and independently-derived '
                             'quantities. Recomputes NOTHING — see check_certificate() for scope.')
    parser.add_argument('--check-layer-sidecars', metavar='DIR', default=None,
                        help='Check the f1c5 per-layer sidecar identities in DIR (two independent '
                             'marginal decompositions each summing to mass_total, histogram totals, '
                             'manifest agreement, and the layer-to-layer sha256 lineage chain). '
                             'Reads ONLY the small JSON sidecars — no layer-file I/O, so it is free '
                             'and works long after the campaign VM is gone. Recomputes no masses.')
    parser.add_argument('--check-repr', type=int, nargs='?', const=1000, metavar='N',
                        default=None,
                        help='independently recompute repr(k) for N records and compare '
                             'against what the artifact stores (default 1000). This is the '
                             'only repr oracle outside solve.c; solve.c itself has none.')
    parser.add_argument('--check-repr-offset', type=int, default=0, metavar='R',
                        help='start --check-repr at record R (default 0). Use several '
                             'offsets to spread coverage instead of resampling one window.')
    parser.add_argument('--check-artifact', type=int, nargs='?', const=-1, metavar='N',
                        default=None,
                        help='validate what solutions.bin actually claims: each record\'s OWN '
                             'orientations satisfy the constraint set (forced 63->0 opening, no '
                             'HD-5 transition, C5 budget consumed exactly), and pair-order keys '
                             'strictly increase (sortedness AND the one-per-class dedup claim). '
                             'N records, default -1 = to EOF. Linear per record, so the whole '
                             'artifact streams in minutes. Prefer this over --check-repr on the '
                             'merge output: --check-repr tests lex-leastness, which this file has '
                             'never claimed, and is structurally blind to a wrong pair sequence. '
                             'Does NOT check completeness.')
    parser.add_argument('--check-shen-orbits', action='store_true',
                        help='(added 2026-08-15) verify the published claim that Shen Youding\'s '
                             '1936 six groups of principal hexagrams are EXACTLY the six K4 orbits '
                             'of his sixteen (sizes 2,2,2,2,4,4). Shen\'s criterion — inner and '
                             'outer trigrams of equal generational rank — is KW-INDEPENDENT, and '
                             'this checks a CLASSIFICATION, not an ordering claim. Independent of '
                             'solve.c\'s orbit code by construction: the orbit claim is about orbit '
                             'structure, so a check using that code would not be independent. '
                             'Reads no files.')
    parser.add_argument('--check-flips', action='store_true',
                        help='(added 2026-08-15) census of the 31 single-orientation-bit flips of '
                             'King Wen\'s own record, classified by failure mode. Reproduces the '
                             'VERIFY.md figure (9 PASS / 15 BAD_BUDGET / 7 BAD_HD5) and removes the '
                             'need to trust a grep — the figure first read "16" because the '
                             'measuring harness used a character class that excluded digits, so '
                             'BAD_HD5 never matched. Reads no files.')
    parser.add_argument('--check-parity-alternation', action='store_true',
                        help='re-derive every published figure in PARITY_ALTERNATION.md '
                             'from KW itself (GATE 25 LEG 2, 2026-08-16)')
    parser.add_argument('--check-zhu-yuansheng', action='store_true',
                        help="verify 朱元昇's (d.c.1273) twelve quadruples against this "
                             "file's own bit operations; see CITATIONS.md#zhuyuansheng")
    parser.add_argument('--check-classical-groups', action='store_true',
                        help='(added 2026-08-16) report the group actions on the 64 hexagrams that '
                             'the CLASSICAL literature attests, and how King Wen scores against '
                             'each. Sources, none of them ours: <comp,rev> and <rev,swap> from '
                             '吳澄 Wu Cheng (1249-1333) 《易纂言外翼》卷一〈卦對第二〉; <comp,swap> '
                             'from 焦循 Jiao Xun (1763-1820) 《易圖略》八卦相錯圖. The point: '
                             '<comp,swap> has the SAME orbit profile as <comp,rev> (20 orbits, '
                             '8x2 + 12x4) yet King Wen seats partners adjacently 64/64 under '
                             '<comp,rev> and only 24/64 under <comp,swap> — a structurally '
                             'indistinguishable rival group, classically attested, that does NOT '
                             'fit. Also re-derives 吳澄\'s own 「共十八對」 as a reading check. '
                             'Changes no enumeration. Reads no files.')
    parser.add_argument('--check-kw-pair-adjacency', action='store_true',
                        help='(added 2026-08-16) re-verify the CLASSICAL fact that King Wen seats '
                             'every hexagram beside its own partner — reversal, or complement for '
                             'the eight reversal-symmetric ones. The rule is Kong Yingda 孔颖达 '
                             '(574-648), 非覆即变; this only lets a reader confirm it. Then draws '
                             'the consequence: the head/tail symbol data of the Shanghai Museum Chu '
                             'bamboo Zhouyi (Pu Maozuo 濮茅左 in 馬承源 ed. 2003) CANNOT distinguish '
                             '"the symbol respects reversal" — Pu\'s claim, which holds 9/9 on his '
                             'directly-observed symbols — from "the symbol is merely constant on '
                             'contiguous King Wen blocks", because blocks and orbits coincide by '
                             'construction of the sequence. An impossibility argument, not a '
                             'criticism of his reading, and not a failed search. Reads no files.')
    parser.add_argument('--check-artifact-offset', type=int, default=0, metavar='R',
                        help='start --check-artifact at record R (default 0). NOTE: the '
                             'sortedness check compares against the predecessor WITHIN the range '
                             'read, so a sharded run cannot see a violation across a shard seam; '
                             'overlap shards by one record, or run offset 0 to EOF.')
    parser.add_argument('--check-t5-c3', nargs=2, metavar=('SOLUTIONS_BIN', 'CHUNKS_DIR'),
                        help='Independently recompute c3_total for every record of the T5 '
                             'mega-sample via C3 = 16 + 8*G (slot map only) and compare against '
                             'the parquet the solve.py pipeline produced. Implementation-'
                             'independent, NOT language-independent. Emits T5_C3_AGREE=PASS/FAIL.')
    parser.add_argument('--check-null-g', action='store_true',
                        help='Compute the exact G-distribution under the C1&C4 null (12 couples + 7 '
                             'self-pairs into 31 slots) and gate it against total == 31!, support '
                             '[12,228], E[G] == 128, and P(G<=95) == 641983711307479/7919632354008375. '
                             'Uses a different accumulator than solve.c (open-couple counts, not '
                             '+/- slot indices), so agreement is evidence. Reads no files.')
    parser.add_argument('--unpinned', action='store_true',
                        help='With --check-null-g: drop the C4 slot-0 pin — 12 couples + all 8 '
                             'self-pairs into 32 slots (the bare C1 null). Computes the EXACT '
                             'C3|C1 rate P(G<=95) = 1977618313669549/30798570265588125 = 6.421137%%, '
                             'the exact analogue of solve.c --null-pair-constrained\'s sampled '
                             '6.42%%. Gates: total == 32!, support [12,240], E[G] == 132.')
    parser.add_argument('--check-c2-shift', type=int, nargs='?', const=200_000, default=None,
                        metavar='N',
                        help='DECISION-SUPPORT (Monte-Carlo, NOT canonical): estimate '
                             'P(G<=95 | C1&C2&C4) via importance-weighted MC (default N=200000), '
                             'hard-gated on the exact acceptance identity E[w]/2^31 == '
                             '|C1&C2&C4|/|C1&C4|. Reports the small upward C2 shift off the exact '
                             'C1&C4 null with a delta-method CI. Reads no files; imports nothing '
                             'from solve.c. This MEASURES the shift; it is not an exact count.')
    parser.add_argument('--t3-stats', metavar='DIR', default=None,
                        help='Pre-registered T3 validity statistics (a) uniformity and (c) C3 '
                             'fraction over a T3 draw sample at DIR (a directory of '
                             't3_stream_*.out[.gz], or one such file). Bars are FROZEN in the '
                             'pre-registration: chi^2 over 16 rank buckets, 15 dof, PASS below '
                             '37.70; C3 fraction at cd<=387 vs p0=1/8.26=0.12107, flagged beyond '
                             '4 sigma. GENERATING THE INPUT: 16 streams x 62,500 draws, one '
                             'KC-sampler invocation per stream — `--kc-sample <f-dir> 62500 '
                             '<seed> --kc-record --kc-ooc --kc-cache-mb 384`. Those subcommands '
                             'are NOT on main: they live in solve.c on the published snapshot '
                             'branch `v4-query-program`, so regenerating the sample means building '
                             'that branch. MEASURED ~12.6 h on one D16als_v7 against a 3.1 TB '
                             'f-ladder. The analysis itself is cheap: MEASURED 4.3-4.6 s wall '
                             'and ~22.9 MB peak RSS for the full 10^6 draws (3 runs, '
                             '/usr/bin/time -v, 2-vCPU D2as_v6). Wall is a band, not a figure '
                             '— see VERIFY.md "Analyses over large artifacts".')
    parser.add_argument('--t3-membership', metavar='PATH', default=None,
                        help='Pre-registered T3 statistic (b): independent membership census of a '
                             'T3 draw sample at PATH (a directory of streams, or one stream file). '
                             'Second-language check — predicates transcribed from SPECIFICATION.md '
                             'C1/C2/C4/C5, sharing no code with the sampler; self-tested and '
                             'positive-controlled before it reports. Adds two checks beyond the '
                             'prereg: an independent recompute of the engine-recorded cd= value, and '
                             'duplicate detection. Bar: 100%% members. Same input and generating '
                             'cost as --t3-stats (~12.6 h on a D16als_v7, plus a build of the '
                             '`v4-query-program` branch, which is where the --kc-* sampler lives). '
                             'The analysis itself is cheap: MEASURED ~149 MB peak RSS for the '
                             'full 10^6 draws — the one figure that reproduced across every '
                             'measurement condition. Wall ranged 60-98 s depending on what else '
                             'the box was doing and is NOT a reproducible figure; see VERIFY.md '
                             '"Analyses over large artifacts", which records two successive '
                             'wrong answers about it.')
    parser.add_argument('--t3-membership-limit', type=int, metavar='N', default=0,
                        help='With --t3-membership: stop after N draws (0 = all). The '
                             'pre-registered spot-check was the first 1,000 walks of one stream, '
                             'so `--t3-membership <stream> --t3-membership-limit 1000` reproduces '
                             'exactly the pre-registered leg for a few seconds of CPU.')
    parser.add_argument('--g-structure', nargs=2, metavar=('C2ON_LOG', 'C2OFF_LOG'), default=None,
                        help='Structure of the full-31 G distribution from two enumerator logs '
                             'carrying G_HIST lines: C2-ON (C1&C2&C4) and C2-OFF (C1&C4). '
                             'Reports moments as exact rationals, the 48-divisibility of every '
                             'bin, the sharp WSUM == 128*TOTAL identity, P(G<=95) against the '
                             'closed-form null 641983711307479/7919632354008375, and a '
                             'convolution test showing G is not an independent-sum statistic. '
                             'GENERATING THE INPUTS: two full-31 `solve --f1-c3-hist --f1-pairs 31 '
                             '--f1-out-of-core DIR` runs, the C2-OFF one adding --no-c2 (both on '
                             'main). MEASURED 23,054 s and 39,003 s on 128 threads, each the FINAL '
                             'attempt wall after checkpoint/resume across Spot evictions — lower '
                             'bounds on from-scratch cost. Analysis itself is instant and reads '
                             'only the logs.')
    args = parser.parse_args()

    if args.t3_stats is not None:
        sys.exit(t3_stats(args.t3_stats))

    if args.t3_membership is not None:
        sys.exit(t3_membership(args.t3_membership, args.t3_membership_limit))

    if args.t3_membership_limit and args.t3_membership is None:
        parser.error("--t3-membership-limit only makes sense with --t3-membership")

    if args.g_structure is not None:
        sys.exit(g_structure(args.g_structure[0], args.g_structure[1]))

    if args.check_t5_c3:
        sys.exit(check_t5_c3(args.check_t5_c3[0], args.check_t5_c3[1]))
    if args.check_null_g:
        sys.exit(check_null_g(unpinned=args.unpinned))
    if args.unpinned:
        parser.error("--unpinned only makes sense with --check-null-g")

    if args.check_c2_shift is not None:
        sys.exit(check_c2_shift(args.check_c2_shift))

    if args.check_layer_sidecars is not None:
        sys.exit(check_layer_sidecars(args.check_layer_sidecars))

    if args.check_certificate is not None:
        sys.exit(check_certificate(args.check_certificate))

    if args.recount:
        sys.exit(recount())

    if args.recount_orbit_widths is not None:
        sys.exit(recount_orbit_widths(args.recount_orbit_widths))
    if args.f1u192_binary_roundtrip:
        sys.exit(f1u192_binary_roundtrip())
    if args.f1_dec_roundtrip:
        sys.exit(f1_dec_roundtrip())
    if args.recount_rung_layers is not None:
        sys.exit(recount_rung_layers(args.recount_rung_layers))
    if args.recount_rung is not None:
        sys.exit(recount_rung(args.recount_rung))

    if args.recount_subtree:
        sys.exit(recount_subtree())

    if args.recount_finite:
        sys.exit(recount_finite())

    if args.recount_fiber:
        sys.exit(recount_fiber())

    if args.fiber_sweep:
        sys.exit(fiber_sweep(args.path))

    if args.recount_gender_null:
        sys.exit(recount_gender_null())


    if args.enumerate_reference is not None:
        sys.exit(enumerate_reference(args.enumerate_reference))

    if args.check_repr is not None:
        sys.exit(check_repr(args.path, args.check_repr, args.check_repr_offset))
    if args.check_artifact is not None:
        sys.exit(check_artifact(args.path, args.check_artifact, args.check_artifact_offset))
    if args.check_shen_orbits:
        sys.exit(check_shen_orbits())
    if args.check_flips:
        sys.exit(check_flips())
    if args.check_kw_pair_adjacency:
        sys.exit(check_kw_pair_adjacency())
    if args.check_parity_alternation:
        sys.exit(check_parity_alternation())
    if args.check_zhu_yuansheng:
        sys.exit(check_zhu_yuansheng())
    if args.check_classical_groups:
        sys.exit(check_classical_groups())

    path = args.path
    n_jobs = max(1, args.jobs)

    # #169: solutions.bin may be gzip-compressed (SOLVE_COMPRESS default on). verify.py uses
    # byte-offset parallel chunking which gzip cannot seek, so transparently decompress a gz file
    # to a temp raw file and verify that — the logical (decompressed) content is byte-identical to
    # a raw solutions.bin, so all constraint/sort/dup checks are unchanged. Temp removed at exit.
    with open(path, 'rb') as _fh:
        _is_gz = _fh.read(2) == b'\x1f\x8b'
    if _is_gz:
        _fd, _tmp = tempfile.mkstemp(prefix='verify_solbin_', suffix='.bin')
        os.close(_fd)
        atexit.register(lambda p=_tmp: os.path.exists(p) and os.remove(p))
        print(f"Detected gzip-compressed solutions.bin; decompressing to {_tmp} for verification...")
        with gzip.open(path, 'rb') as _fin, open(_tmp, 'wb') as _fout:
            shutil.copyfileobj(_fin, _fout, length=1 << 24)
        path = _tmp
        print(f"  decompressed: {os.path.getsize(path):,} bytes (logical content)")

    # Read header from main process to validate format and get record count.
    with open(path, 'rb') as f:
        head = f.read(SOL_HEADER_SIZE)
    try:
        declared_records = parse_header(head)
    except ValueError as e:
        print(f"ERROR: invalid solutions.bin header: {e}")
        sys.exit(2)

    file_size = os.path.getsize(path)
    record_bytes = file_size - SOL_HEADER_SIZE
    if record_bytes % 32 != 0:
        print(f"ERROR: record stream size {record_bytes} not a multiple of 32")
        sys.exit(2)
    n = record_bytes // 32
    if n != declared_records:
        print(f"ERROR: header declares {declared_records} records but file has {n}")
        sys.exit(2)
    # The 16 reserved header bytes MUST be zero (SOLUTIONS_FORMAT.md). Counted
    # as a format error rather than a hard exit: the file is still readable and
    # every record-level verdict below stays meaningful, so a nonzero reserved
    # field belongs alongside those results, not instead of them.
    header_reserved_bad = 1 if head[16:32] != b"\0" * 16 else 0

    print(f"Header: ROAE v{SOL_FORMAT_VERSION}, {n:,} records")
    print(f"Verifying {n:,} records from {path} ({file_size:,} bytes total, "
          f"{SOL_HEADER_SIZE} header + {record_bytes:,} records)")
    if n_jobs > 1:
        print(f"Parallel: {n_jobs} workers")

    # Split records into n_jobs approximately-equal chunks.
    if n_jobs == 1 or n < n_jobs:
        chunks = [(path, 0, n)]
    else:
        chunk_size = n // n_jobs
        bounds = [(path, i * chunk_size, (i + 1) * chunk_size) for i in range(n_jobs)]
        # Last chunk absorbs the remainder.
        last_path, last_start, _ = bounds[-1]
        bounds[-1] = (last_path, last_start, n)
        chunks = bounds

    # Verify chunks in parallel.
    if n_jobs == 1:
        results = [verify_chunk(chunks[0])]
    else:
        ctx = multiprocessing.get_context('fork')
        with ctx.Pool(processes=n_jobs) as pool:
            # imap preserves order, which we need for boundary stitching.
            results = list(pool.imap(verify_chunk, chunks))

    # Aggregate per-chunk counters.
    fail_c1 = sum(r['fail_c1'] for r in results)
    fail_c2 = sum(r['fail_c2'] for r in results)
    fail_c3 = sum(r['fail_c3'] for r in results)
    fail_c4 = sum(r['fail_c4'] for r in results)
    fail_c5 = sum(r['fail_c5'] for r in results)
    fail_decode = sum(r['fail_decode'] for r in results)
    fail_sort = sum(r['fail_sort'] for r in results)
    fail_dup = sum(r['fail_dup'] for r in results)
    fail_fmt = sum(r['fail_fmt'] for r in results)
    kw_found = any(r['kw_found'] for r in results)
    total_count = sum(r['count'] for r in results)

    # Stitch inter-chunk boundaries: chunk i's LAST vs chunk i+1's FIRST.
    for i in range(len(results) - 1):
        s_inc, d_inc = stitch_boundary(results[i], results[i + 1])
        fail_sort += s_inc
        fail_dup += d_inc

    # Sanity: ensure every record was visited exactly once.
    if total_count != n:
        print(f"INTERNAL ERROR: chunks covered {total_count:,} records, expected {n:,}")
        sys.exit(3)

    print(f"\n--- Results ---")
    print(f"Records:        {n:,}")
    print(f"C1 failures:    {fail_c1}")
    print(f"C2 failures:    {fail_c2}")
    print(f"C3 failures:    {fail_c3}  (ceiling: {KW_COMP_DIST} = KW's complement distance)")
    print(f"C4 failures:    {fail_c4}  (oriented: s0 = 63 AND s1 = 0)")
    print(f"C5 failures:    {fail_c5}")
    print(f"Decode errors:  {fail_decode}")
    print(f"Sort errors:    {fail_sort}")
    print(f"Duplicates:     {fail_dup}")
    print(f"Format errors:  {fail_fmt}  (records with reserved bit 0 set)"
          + ("  + header reserved bytes NONZERO" if header_reserved_bad else ""))
    print(f"King Wen:       {'YES' if kw_found else 'No'}"
          + ("  [--expect-kw: REQUIRED]" if args.expect_kw else ""))

    # KW presence is informational by default — a shard legitimately need not
    # contain King Wen. --expect-kw promotes it to a hard requirement for runs
    # over a complete canonical, where its absence would be a real defect that
    # was previously visible only to an operator reading the line above.
    fail_kw = 1 if (args.expect_kw and not kw_found) else 0

    total_fail = (fail_c1 + fail_c2 + fail_c3 + fail_c4 + fail_c5
                  + fail_decode + fail_sort + fail_dup + fail_fmt
                  + header_reserved_bad + fail_kw)
    if total_fail == 0:
        print(f"\nVERIFY PASS: all {n:,} records satisfy C1-C5, sorted, no duplicates")
        sys.exit(0)
    else:
        print(f"\nVERIFY FAIL: {total_fail} issues")
        sys.exit(1)

if __name__ == "__main__":
    main()
