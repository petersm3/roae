/* https://github.com/petersm3/roae
 * Developed with AI assistance (Claude, Anthropic)
 *
 * verify.c — independent per-layer mass verifier for the f1c5 run (TR-11 §10vi, gate (c)).
 *
 * WHAT THIS IS. A second opinion on the symmetry-quotient DP, computed a different way and
 * sharing NO code with solve.c. solve.c reports, for each layer k, a per-layer *plain*
 * (orbit-expanded) mass in its run.out:
 *
 *     [f1c5] layer k= 3/31: canonical_masks=378 ... mass=158364 ...
 *
 * That number is produced by the orbit-quotient DP and then expanded through orbit weights.
 * This program recomputes the same quantity with a PLAIN, NON-QUOTIENT layered DP — no
 * canonicalization, no orbit weights, no stabilizer bookkeeping — and compares. Agreement
 * therefore exercises exactly the machinery TR-11 §2 flags as delicate (the mask action is
 * NOT free, so prefix stabilizers exist and must be weighted correctly), and it does so on
 * the TRUE full-31 instance rather than a reduced rung.
 *
 * WHY THIS FORM. At the time this verifier was written (2026-07-21), solve.c's on-disk layer
 * format was not published in any public document, so verifying the binary layer FILES would
 * have required consulting solve.c — reintroducing precisely the shared-misreading failure
 * class that verify.py's F-3 finding proved is real. (Since then the formats HAVE been
 * published — documentation/F1C5_LAYER_FORMAT.md — so a spec-driven independent layer reader
 * is now possible; per the verifier discipline it belongs in this file.) The per-layer
 * masses in run.out, by contrast, are plain numbers whose MEANING is published (TR-11 §3's
 * gate identity), so they can be checked independently with no format dependency at all.
 *
 * SCOPE — what agreement does and does not establish.
 *   DOES: the quotient DP's orbit expansion and stabilizer weighting reproduce the plain
 *         mass exactly, at full-31, for every layer this program reaches.
 *   DOES NOT: verify layers beyond its memory reach (the plain state space grows ~16x per
 *         layer, so it exhausts long before k=31), and therefore does NOT constitute the
 *         independent full-scale recomputation §10(vi) asks for. That remains open.
 *
 * INDEPENDENCE. Everything is rebuilt from the published definitions — SPECIFICATION.md's
 * C1-C5, partner() = rev unless palindromic else comp, and TR-11 §5's first-completion DFS
 * for the budget B0. No solve.c header, no shared table, no magic constant copied. The KW
 * pair table and B0 are DERIVED here, then B0 is cross-checked against the value solve.c
 * records in its manifest (a disagreement is itself a finding).
 *
 * BUILD:  cc -O2 -o verify verify.c -lz -lpthread
 *         (zlib: the v2 layer codec is per-block zlib; pthreads: the --ie-* modes)
 * USAGE:  ./verify <run.out> [max_layer]      (default max_layer = 6)
 *         Increase max_layer while memory allows; the program reports what it reached and
 *         stops cleanly rather than being killed.
 *         ./verify --check-layers DIR [max_k] [run.out]   spec-driven layer-file reader
 *         (all layers, entry-streaming; with run.out also compares the independently
 *          re-derived orbit-weighted mass per layer); --check-layers-selftest.
 *         ./verify --scan-layers DIR [max_k] [run.out]   the SAME checks + masses via
 *          the multi-observable parallel scan driver (N O_DIRECT read lanes, riders:
 *          T7/BL-7 orbit census + T6-slot stub; env LC_SCAN_LANES/CHUNK_KB/ODIRECT/
 *          T6STUB). Identity contract: minus "[scan] " lines, stdout and rc are
 *          byte-identical to --check-layers; --scan-selftest proves it on fixtures.
 *         ./verify --check-g-ladder FDIR GDIR [max_k]   g-ladder verifier (structural +
 *          the f·g cut identity at every layer), against GT_LADDER_FORMAT.md.
 *         ./verify --check-t-ladder FDIR TDIR [max_k]   t-ladder verifier (f-geometry
 *          mirror + the f·t node identity at every layer); --check-gt-selftest.
 *         ./verify --ie-count [opts]   Route B: the INDEPENDENT inclusion–exclusion
 *          transfer-walk recount of |C1∩C2∩C4∩C5| (TR-11 §10vi) — see the ROUTE B
 *          section header below for the algorithm, options and validation ladder.
 *          --ie-no-budget = the C1∩C2∩C4 (F4) variant; --ie-pin/--ie-pin-c6c7 =
 *          the pinned-step (T3) variant for |C1∩C2∩C4∩C5∩C6∩C7|.
 *         ./verify --ie-probe NSAMP [--ie-threads N]   full-31 throughput probe.
 *         ./verify --dp-count [opts]   Route D: the SECOND instrument for the
 *          pinned (C6/C7) exact count — a direct layered exact-cover mask DP
 *          (NO inclusion–exclusion; different algorithm class from --ie-count).
 *          See the ROUTE D section header below.
 *         ./verify --knuth-anchors   clean-room Knuth prober validation gate:
 *          exact KW-prefix subtree anchors (443/4, 62,256/2,232,
 *          9,422,793/16,504, 8 with C6/C7) + a fixed-seed probe-vs-exact
 *          machinery check. Run before any probe run.
 *         ./verify --knuth-probe N [--knuth-seed S] [--knuth-threads T]
 *          [--knuth-no-c67] [--knuth-free F]   the #194 CLEAN-ROOM Knuth
 *          random-probe estimator of |C1..C7| (default; own C3 predicate and
 *          own C6/C7 pin logic) or |C1..C5| (--knuth-no-c67). See the
 *          CLEAN-ROOM KNUTH PROBER section header below.
 */

#define _GNU_SOURCE    /* O_DIRECT for the --scan-layers parallel read lanes */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <zlib.h>
#include <pthread.h>   /* --ie-count / --ie-probe worker threads (Route B); --scan-layers lanes */
#include <time.h>
#include <unistd.h>
#include <fcntl.h>     /* --scan-layers: open(O_DIRECT), pread */
#include <errno.h>
#include <math.h>      /* --knuth-probe: sqrtl/fabsl for the Wald CI */
#include <stdatomic.h> /* --knuth-probe: racy-free progress counters */

/* ---------- published constraint definitions, rebuilt from scratch ---------- */

static int popcount6(int n) { int c = 0; while (n) { c += n & 1; n >>= 1; } return c; }
static int hamming(int a, int b) { return popcount6(a ^ b); }

static int rev6(int n) {                       /* bit reversal of a 6-bit value */
    int r = 0;
    for (int i = 0; i < 6; i++) if ((n >> i) & 1) r |= 1 << (5 - i);
    return r;
}
static int comp6(int n) { return n ^ 63; }     /* complement */
static int partner(int h) { int r = rev6(h); return (r != h) ? r : comp6(h); }

/* The published King Wen sequence (the object of study; 6-bit hexagram values in KW order).
 * Needed because TR-11 §5 states plainly that "the pair ORDER is part of the instance
 * definition" — enumerating pairs by hexagram value instead builds a DIFFERENT instance and
 * yields the wrong B0. (Learned the hard way: value-order gave B0=(7,6,10,8,0) against the
 * published (2,8,13,7,1).)                                                                   */
static const int KW[64] = {
    63, 0,17,34,23,58, 2,16,55,59, 7,56,61,47, 4, 8,25,38, 3,48,41,37,32, 1,
    57,39,33,30,18,45,28,14,60,15,40, 5,53,43,20,10,35,49,31,62,24, 6,26,22,
    29,46, 9,36,52,11,13,44,54,27,50,19,51,12,21,42
};

/* The 32 canonical pairs IN KING WEN ORDER: pair i = (KW[2i], KW[2i+1]).
 * partner() is re-derived independently and used to CHECK each pair (a disagreement would
 * mean the published sequence violates C1 — itself a finding), not to build the ordering.  */
static int PA[32], PB[32], NPAIR = 0;
static int build_pairs(void) {
    if (NPAIR == 32) return 1;                 /* idempotent: both modes call it */
    for (int i = 0; i < 32; i++) {
        int a = KW[2 * i], b = KW[2 * i + 1];
        if (partner(a) != b || partner(b) != a) {
            fprintf(stderr, "*** C1 VIOLATION at KW pair %d: (%d,%d) partner=%d\n",
                    i, a, b, partner(a));
            return 0;
        }
        PA[i] = a; PB[i] = b; NPAIR++;
    }
    return 1;
}

/* C5 boundary classes; distance 5 is forbidden by C2, distance 0 cannot occur. */
static const int CLS[5] = {1, 2, 3, 4, 6};
static int cls_ix(int d) { for (int i = 0; i < 5; i++) if (CLS[i] == d) return i; return -1; }

/* ---------- independent repr(k) oracle (--check-repr) ----------------------
 *
 * WHY IT EXISTS. solve.c's --kc-repr-normalize says outright that "there is NO
 * separate repr oracle in this tree": its only built-in check is IDEMPOTENCE
 * (re-run on the output, expect byte-identical), which is self-consistent and
 * so cannot catch a normalization that is stable but WRONG. The SOLVE_REPR_FC
 * A/B is weaker than it looks for the same reason at one remove -- both arms
 * share solve.c's DFS, child order and code, so a defect in the shared
 * traversal is invisible to it at any sample size. This is the second
 * instrument, of a different algorithm class, per the TR-11 v1.11 pattern.
 *
 * INDEPENDENCE IS THE DELIVERABLE. Written from the DEFINITION in
 * lean/RecordConvention.lean --
 *
 *     repr(k) = the lexicographically least orientation completion of the
 *               pair-order key k satisfying the constraint set (slot 0 forced)
 *
 * -- on THIS file's own KW table, its own partner()-derived pairs and its own
 * hamming(). Not a transcription of orb_recanon_dfs. A faster reimplementation
 * that borrowed solve.c's helpers or search shape would not be a second opinion.
 * verify.py carries the same oracle; C exists because Python cannot cover 1.78e9
 * records.
 *
 * WHY GREEDY 0-BEFORE-1 IS EXACTLY LEX-LEAST. Record byte i is
 * (pair_index << 2) | (orientation << 1). The key fixes pair_index at every
 * slot, so at each slot the orient=0 byte is strictly below the orient=1 byte,
 * and records compare left to right. The first complete valid assignment found
 * by a DFS trying 0 before 1, in slot order, IS the minimum. No search-order
 * cleverness is involved, and none is permitted -- that equivalence is the
 * entire point. */

static int vc_budget0[7];

/* Re-derive the C5 budget HERE from this file's KW table. Asserted against the
 * published multiset so a corrupted table fails loudly instead of silently
 * redefining the constraint. */
static int vc_build_budget(void) {
    static const int WANT[7] = {0, 2, 20, 13, 19, 0, 9};
    for (int d = 0; d < 7; d++) vc_budget0[d] = 0;
    for (int i = 0; i < 63; i++) vc_budget0[hamming(KW[i], KW[i + 1])]++;
    for (int d = 0; d < 7; d++)
        if (vc_budget0[d] != WANT[d]) {
            fprintf(stderr, "*** KW budget mismatch at d=%d: %d != %d\n",
                    d, vc_budget0[d], WANT[d]);
            return 0;
        }
    return 1;
}

typedef struct { const int *key; int budget[7]; int orient[32]; } VcRepr;

static int vc_rec(VcRepr *st, int slot, int last) {
    if (slot == 32) {                    /* exact consumption, not merely "fits" */
        for (int d = 0; d < 7; d++) if (st->budget[d] != 0) return 0;
        return 1;
    }
    int P = st->key[slot], a = PA[P], b = PB[P];
    for (int o = 0; o < 2; o++) {        /* 0 BEFORE 1 == lex-least */
        int f = o ? b : a, s = o ? a : b;
        int bd = hamming(last, f);
        if (bd == 5 || st->budget[bd] <= 0) continue;
        int wd = hamming(f, s);
        st->budget[bd]--;
        if (st->budget[wd] <= 0) { st->budget[bd]++; continue; }
        st->budget[wd]--;
        st->orient[slot] = o;
        if (vc_rec(st, slot + 1, s)) return 1;
        st->budget[wd]++; st->budget[bd]++;
    }
    return 0;
}

/* out must hold 32 bytes. Returns 1 and fills out, or 0 if the key admits no
 * valid completion (which is itself a finding if the artifact stores one). */
static int vc_repr_of_key(const int *pair_order, unsigned char *out) {
    VcRepr st;
    st.key = pair_order;
    memcpy(st.budget, vc_budget0, sizeof(st.budget));
    int P0 = pair_order[0], a0 = PA[P0], b0 = PB[P0], o0;
    if (a0 == 63 && b0 == 0)      o0 = 0;   /* C4 forces the (63,0) opening */
    else if (b0 == 63 && a0 == 0) o0 = 1;
    else return 0;
    int wd0 = hamming(63, 0);
    if (st.budget[wd0] <= 0) return 0;
    st.budget[wd0]--;
    st.orient[0] = o0;
    if (!vc_rec(&st, 1, 0)) return 0;
    for (int i = 0; i < 32; i++)
        out[i] = (unsigned char)(((pair_order[i] & 0x3F) << 2) | ((st.orient[i] & 1) << 1));
    return 1;
}

/* ---------- --check-artifact: what solutions.bin ACTUALLY claims ----------
 *
 * WHY THIS EXISTS, AND WHEN --check-repr DOES NOT APPLY.
 *
 * --check-repr asks "is the stored orientation the global lex-least valid
 * completion of this key?". That IS the record convention -- forced by
 * partition-invariance, and settled against the cell-scoped alternative -- but it
 * is established by a POST-PASS, not by the merge. orb_normalize_rec_op ->
 * orb_repr_global, exposed as `solve --kc-repr-normalize IN.bin OUT.bin`, is what
 * applies it. Against a raw merge output that pass has not run, so --check-repr
 * disagrees on exactly the records the post-pass would rewrite: measured
 * 2026-08-15 over 1,776,347,935 records, a regionally varying 1.06%-42.2% with
 * INCOMPUTABLE=0 throughout. Expected, not a defect. --check-repr is the right
 * ACCEPTANCE TEST for the post-pass output and the wrong instrument for its input.
 *
 * Do not mistake orb_recanon for the convention (a misreading made and retracted
 * on 2026-08-15): it pins slots 0..3 from a member CELL's prefix and its only
 * caller is orb_expand_record, for cell-faithful expansion shards. Cell-scoped
 * visited-min was PROVEN INSUFFICIENT as a record representative -- the merged
 * cross-cell min moves with budget, breaking partition-invariance and
 * record-level nesting.
 *
 * A second limitation survives normalization: --check-repr is STRUCTURALLY BLIND
 * TO A WRONG PAIR SEQUENCE. vc_repr_of_key builds its output from the same key
 * array it just decoded out of the stored record, so the pair-order bits are
 * identical by construction and a disagreement can only ever be an orientation
 * bit. This check is not blind to it.
 *
 * WHAT THIS CHECKS INSTEAD -- the three properties the file does claim:
 *   (1) VALIDITY   every stored record's OWN orientations satisfy the constraint
 *                  set: forced (63,0) opening, no HD-5 transition, and the C5
 *                  budget consumed EXACTLY (not merely "fits").
 *   (2) SORTEDNESS pair-order keys strictly increase, matching compare_solutions.
 *   (3) DEDUP      strictness in (2) is exactly the one-record-per-class claim.
 *
 * This is a linear walk per record, not a backtracking search, so the whole
 * artifact streams in minutes rather than the ~47 h a repr sweep costs -- and
 * unlike the repr sweep it can actually fail on real corruption.
 *
 * SCOPE: this does NOT check that the artifact is COMPLETE (that no valid
 * solution is missing). Completeness is the enumeration's claim, attested by
 * the canonical sha, not something a single-pass reader can establish. */
static int vc_check_artifact_main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s --check-artifact FILE [N] [OFFSET]\n", argv[0]); return 2; }
    const char *path = argv[2];
    long long want = (argc >= 4) ? atoll(argv[3]) : -1;      /* -1 == to EOF */
    long long off  = (argc >= 5) ? atoll(argv[4]) : 0;
    if (!build_pairs() || !vc_build_budget()) { printf("ARTIFACT=FAIL_tables\n"); return 2; }

    gzFile fh = gzopen(path, "rb");
    if (!fh) { printf("ARTIFACT=FAIL_open\n"); return 2; }
    unsigned char hdr[32];
    if (gzread(fh, hdr, 32) != 32) { printf("ARTIFACT=FAIL_short_header\n"); gzclose(fh); return 2; }
    /* VALIDATE THE MAGIC. Without this a HEADERLESS file (a raw sub_*.bin shard)
     * has its FIRST RECORD silently eaten as "header", and the checker can then
     * report ARTIFACT=PASS on a file it never fully read. That is the same
     * failure mode as the recon off-by-one this repo already carries a fix for:
     * applying solutions.bin's header convention to headerless shards. Fail
     * closed rather than auto-detect -- this tool validates the merged artifact,
     * and a shard should be an explicit refusal, not a silent reinterpretation. */
    if (memcmp(hdr, "ROAE", 4) != 0) {
        printf("ARTIFACT=FAIL_no_ROAE_header\n");
        printf("  refusing: first 4 bytes are not 'ROAE'. A headerless shard would\n");
        printf("  otherwise have its first record consumed as a header.\n");
        gzclose(fh); return 2;
    }
    unsigned char rec[32], prev[32];
    for (long long i = 0; i < off; i++)
        if (gzread(fh, rec, 32) != 32) { printf("ARTIFACT=FAIL_offset_past_eof\n"); gzclose(fh); return 2; }

    long long n = 0, bad_key = 0, bad_spare = 0, bad_open = 0,
              bad_hd5 = 0, bad_budget = 0, bad_residue = 0, bad_order = 0, shown = 0;
    int have_prev = 0;

    while (want < 0 || n < want) {
        int got = gzread(fh, rec, 32);
        if (got == 0) break;
        if (got != 32) { printf("ARTIFACT=FAIL_partial_record\n"); gzclose(fh); return 2; }
        long long idx = off + n;
        n++;
        int key[32], orient[32]; uint32_t seen = 0; int bad = 0;
        /* Count spare bits over ALL 32 bytes BEFORE the key check. Previously this
         * sat inside the decode loop and stopped at the bad-key break, so on a
         * record with both a bad key and later spare bits the C and Python
         * implementations disagreed (Python counts all 32 first). Two independent
         * instruments that diverge on compound defects are not two instruments. */
        for (int i = 0; i < 32; i++) if (rec[i] & 1) bad_spare++;
        for (int i = 0; i < 32; i++) {
            key[i]    = (rec[i] >> 2) & 0x3F;
            orient[i] = (rec[i] >> 1) & 1;
            if (key[i] >= 32 || ((seen >> key[i]) & 1u)) { bad = 1; break; }
            seen |= 1u << key[i];
        }
        if (bad) { bad_key++; if (shown < 5) { printf("  record %lld: key is not a permutation of 0..31\n", idx); shown++; } continue; }

        /* (2)+(3): strictly increasing on the pair-identity bytes. */
        if (have_prev) {
            int c = 0;
            for (int i = 0; i < 32 && c == 0; i++) c = (prev[i] & 0xFC) - (rec[i] & 0xFC);
            if (c >= 0) { bad_order++; if (shown < 5) { printf("  record %lld: pair-order not strictly greater than predecessor (%s)\n", idx, c == 0 ? "duplicate class" : "out of order"); shown++; } }
        }
        memcpy(prev, rec, 32); have_prev = 1;

        /* (1): validate the STORED orientations, not some recomputed ideal. */
        int budget[7]; memcpy(budget, vc_budget0, sizeof(budget));
        int P0 = key[0], a0 = PA[P0], b0 = PB[P0];
        int f0 = orient[0] ? b0 : a0, s0 = orient[0] ? a0 : b0;
        if (!(f0 == 63 && s0 == 0)) { bad_open++; if (shown < 5) { printf("  record %lld: opening is not the forced 63->0\n", idx); shown++; } continue; }
        int wd0 = hamming(63, 0);
        if (budget[wd0] <= 0) { bad_budget++; continue; }
        budget[wd0]--;
        int last = 0, fail = 0;
        for (int slot = 1; slot < 32 && !fail; slot++) {
            int P = key[slot], a = PA[P], b = PB[P];
            int f = orient[slot] ? b : a, s = orient[slot] ? a : b;
            int bd = hamming(last, f);
            if (bd == 5) { bad_hd5++; fail = 1; if (shown < 5) { printf("  record %lld: HD-5 transition into slot %d\n", idx, slot); shown++; } break; }
            if (budget[bd] <= 0) { bad_budget++; fail = 1; break; }
            budget[bd]--;
            int wd = hamming(f, s);
            if (budget[wd] <= 0) { bad_budget++; fail = 1; break; }
            budget[wd]--;
            last = s;
        }
        if (fail) continue;
        /* BAD_BUDGET_RESIDUE is a defensive guard that is STRUCTURALLY UNREACHABLE,
         * and is recorded as such rather than claimed as tested: the budget totals
         * 63 (asserted by vc_build_budget) and a complete record consumes exactly
         * 1 + 31*2 = 63 units, so if every decrement above succeeded the residue is
         * necessarily zero. It stays only to fail closed if that identity is ever
         * broken by a table change. No negative control exercises it because none
         * can. */
        for (int d = 0; d < 7; d++) if (budget[d] != 0) { bad_residue++; break; }
    }
    gzclose(fh);

    long long bad_total = bad_key + bad_spare + bad_open + bad_hd5 + bad_budget + bad_residue + bad_order;
    printf("RECORDS=%lld\nBAD_KEY=%lld\nBAD_SPARE_BIT=%lld\nBAD_OPENING=%lld\n"
           "BAD_HD5=%lld\nBAD_BUDGET=%lld\nBAD_BUDGET_RESIDUE=%lld\nBAD_ORDER=%lld\n",
           n, bad_key, bad_spare, bad_open, bad_hd5, bad_budget, bad_residue, bad_order);
    if (n > 0 && bad_total == 0) {
        printf("ARTIFACT=PASS\nSCOPE=validity_sortedness_dedup_only_NOT_completeness\n");
        return 0;
    }
    printf("ARTIFACT=FAIL\n");
    return 1;
}

/* --check-repr FILE [N] [OFFSET] -- verdicts are KEY=value for `grep -qx`.
 *
 * NOTE: for solutions.bin as produced today this is EXPECTED to disagree; see
 * the --check-artifact header above. It becomes the right instrument only after
 * the repr(k) post-pass, applied to that post-pass's OUTPUT. */
static int vc_check_repr_main(int argc, char **argv) {
    if (argc < 3) { fprintf(stderr, "usage: %s --check-repr FILE [N] [OFFSET]\n", argv[0]); return 2; }
    const char *path = argv[2];
    long long want = (argc >= 4) ? atoll(argv[3]) : 1000;
    long long off  = (argc >= 5) ? atoll(argv[4]) : 0;
    if (!build_pairs() || !vc_build_budget()) { printf("CHECK_REPR=FAIL_tables\n"); return 2; }

    gzFile fh = gzopen(path, "rb");
    if (!fh) { printf("CHECK_REPR=FAIL_open\n"); return 2; }
    unsigned char hdr[32];
    if (gzread(fh, hdr, 32) != 32) { printf("CHECK_REPR=FAIL_short_header\n"); gzclose(fh); return 2; }
    /* Skip by READING, not by seeking: gzseek on a large member re-inflates
     * anyway, and a short read here must be distinguishable from EOF at the
     * target offset rather than silently landing somewhere else. */
    unsigned char rec[32];
    for (long long i = 0; i < off; i++)
        if (gzread(fh, rec, 32) != 32) { printf("CHECK_REPR=FAIL_offset_past_eof\n"); gzclose(fh); return 2; }

    long long checked = 0, agree = 0, disagree = 0, incomputable = 0;
    unsigned char mine[32];
    while (checked < want) {
        int got = gzread(fh, rec, 32);
        if (got == 0) break;
        if (got != 32) { printf("CHECK_REPR=FAIL_partial_record\n"); gzclose(fh); return 2; }
        int key[32]; uint32_t seen = 0; int bad = 0;
        for (int i = 0; i < 32; i++) {
            key[i] = (rec[i] >> 2) & 0x3F;
            if (key[i] >= 32 || (seen >> key[i]) & 1u) { bad = 1; break; }
            seen |= 1u << key[i];
        }
        if (bad) { printf("CHECK_REPR=FAIL_malformed_key at %lld\n", off + checked); gzclose(fh); return 2; }
        checked++;
        if (!vc_repr_of_key(key, mine)) incomputable++;
        else if (memcmp(mine, rec, 32) == 0) agree++;
        else {
            disagree++;
            if (disagree <= 3) printf("  record %lld: stored != independent repr\n", off + checked - 1);
        }
    }
    gzclose(fh);

    printf("CHECKED=%lld\nAGREE=%lld\nDISAGREE=%lld\nINCOMPUTABLE=%lld\n",
           checked, agree, disagree, incomputable);
    /* Fail closed: an incomputable key is a finding too -- the artifact claims a
     * canonical record for a key this instrument says cannot be completed. */
    if (checked > 0 && disagree == 0 && incomputable == 0) {
        printf("CHECK_REPR=PASS\nSCOPE=records_read_only_NOT_whole_artifact\n");
        return 0;
    }
    printf("CHECK_REPR=FAIL\n");
    return 1;
}

/* ---------- big enough integers: 128-bit with overflow detection ---------- */
typedef unsigned __int128 u128;
static int OVERFLOWED = 0;
static u128 add_ck(u128 a, u128 b) { u128 s = a + b; if (s < a) OVERFLOWED = 1; return s; }
static void print_u128(u128 v, char *out) {   /* out must hold >=40 bytes */
    char tmp[40]; int i = 0;
    if (v == 0) { strcpy(out, "0"); return; }
    while (v) { tmp[i++] = '0' + (int)(v % 10); v /= 10; }
    int j = 0; while (i) out[j++] = tmp[--i];
    out[j] = 0;
}

/* ---------- B0 via TR-11 §5 Step 1: deterministic first-completion DFS ----------
 * Scans unplaced pairs in ascending index and, for each, orientation o=0 (enter b, exit a)
 * then o=1 (enter a, exit b). B0 is the boundary-class multiset of the FIRST complete walk.
 * Derived here; cross-checked against solve.c's manifest by the caller.                     */
static int NFREE;                    /* pairs 1..31 are free; pair 0 is C4-pinned */
static int b0[5];
static int b0_dfs_res[5];
static int b0_found;
static int b0_cnt[5];

static void b0_dfs(int depth, int last, uint32_t used) {
    if (b0_found) return;
    if (depth == NFREE) { memcpy(b0_dfs_res, b0_cnt, sizeof b0_dfs_res); b0_found = 1; return; }
    for (int i = 0; i < NFREE && !b0_found; i++) {
        if (used & (1u << i)) continue;
        int a = PA[i + 1], b = PB[i + 1];          /* free pairs are 1..31 */
        for (int o = 0; o < 2 && !b0_found; o++) {
            int f = o == 0 ? b : a;                 /* o=0 enters b, exits a */
            int s = o == 0 ? a : b;
            int d = hamming(last, f);
            if (d == 5 || d == 0) continue;
            int ci = cls_ix(d);
            b0_cnt[ci]++;
            b0_dfs(depth + 1, s, used | (1u << i));
            if (!b0_found) b0_cnt[ci]--;
        }
    }
}

/* ---------- plain layered DP: state = (mask, last, budget vector) ---------- */

typedef struct { uint32_t mask; uint8_t last; uint8_t p[5]; u128 val; } Ent;

/* open-addressing hash table, grown by doubling */
typedef struct { Ent *e; size_t cap, n; } Tab;

static uint64_t mix(uint64_t x) {
    x ^= x >> 33; x *= 0xff51afd7ed558ccdULL;
    x ^= x >> 33; x *= 0xc4ceb9fe1a85ec53ULL;
    x ^= x >> 33; return x;
}
static uint64_t keyhash(uint32_t mask, int last, const uint8_t *p) {
    uint64_t k = ((uint64_t)mask << 8) | (uint64_t)last;
    for (int i = 0; i < 5; i++) k = k * 1099511628211ULL + p[i];
    return mix(k);
}
static int same(const Ent *e, uint32_t mask, int last, const uint8_t *p) {
    if (e->mask != mask || e->last != last) return 0;
    for (int i = 0; i < 5; i++) if (e->p[i] != p[i]) return 0;
    return 1;
}
static void tab_init(Tab *t, size_t cap) {
    /* on OOM sets cap=0; callers must check */
    t->cap = cap; t->n = 0;
    t->e = calloc(cap, sizeof(Ent));
    if (!t->e) { fprintf(stderr, "\n[memory exhausted allocating %zu entries — stopping cleanly]\n", cap); t->cap = 0; return; }
    for (size_t i = 0; i < cap; i++) t->e[i].last = 0xFF;   /* 0xFF marks empty */
}
static void tab_free(Tab *t) { free(t->e); t->e = NULL; t->cap = t->n = 0; }
static void tab_add(Tab *t, uint32_t mask, int last, const uint8_t *p, u128 v);

static void tab_grow(Tab *t) {
    Tab nt; tab_init(&nt, t->cap * 2);
    for (size_t i = 0; i < t->cap; i++)
        if (t->e[i].last != 0xFF) tab_add(&nt, t->e[i].mask, t->e[i].last, t->e[i].p, t->e[i].val);
    free(t->e); *t = nt;
}
static void tab_add(Tab *t, uint32_t mask, int last, const uint8_t *p, u128 v) {
    if ((t->n + 1) * 10 >= t->cap * 7) tab_grow(t);
    size_t i = keyhash(mask, last, p) & (t->cap - 1);
    for (;;) {
        Ent *e = &t->e[i];
        if (e->last == 0xFF) {
            e->mask = mask; e->last = (uint8_t)last; memcpy(e->p, p, 5); e->val = v;
            t->n++; return;
        }
        if (same(e, mask, last, p)) { e->val = add_ck(e->val, v); return; }
        i = (i + 1) & (t->cap - 1);
    }
}

/* ---------- run.out parsing (reads only the published per-layer mass line) ---------- */

static int parse_masses(const char *path, char masses[32][48]) {
    FILE *f = fopen(path, "r");
    if (!f) { fprintf(stderr, "cannot open %s\n", path); return -1; }
    char line[8192]; int found = 0;
    for (int i = 0; i < 32; i++) masses[i][0] = 0;
    while (fgets(line, sizeof line, f)) {
        int k; const char *q;
        if (sscanf(line, "[f1c5] layer k=%d/31:", &k) != 1) continue;
        if (k < 0 || k > 31) continue;
        q = strstr(line, "mass=");
        if (!q) continue;
        q += 5;
        int j = 0; while (*q >= '0' && *q <= '9' && j < 46) masses[k][j++] = *q++;
        masses[k][j] = 0;
        if (j) found++;
    }
    fclose(f);
    return found;
}

/* ==========================================================================
 * LAYER-FILE READER  (--check-layers DIR [max_k])   [task (A), TR-11 §10vi]
 *
 * Reads solve.c's on-disk layer files DIRECTLY and checks the invariants that
 * hold them together, written AGAINST documentation/F1C5_LAYER_FORMAT.md and
 * NOTHING from solve.c — the same two-step discipline that surfaced F-3: the
 * spec was published first, this reader was written against the spec second.
 *
 * The mass-DP mode above reaches only k≈4-6 (plain state blows up ~16×/layer).
 * This mode is entry-streaming and O(nm) in memory, so it reaches ALL layers
 * present on disk, including the final k=31 — where the summed value bytes must
 * equal the published 39-digit count. That is an end-to-end content check of
 * the headline integer, read from the real bytes, with no solve.c dependency.
 *
 * Checks per layer:
 *   header    magic/version/n/k/start_exit/pl_hash/b0 vs the manifest;
 *   pl_hash   recomputed from the spec's FNV-1a-64 WORD variant, == manifest;
 *   layout    masks strictly ascending; off[] monotone, off[0]=0, off[nm]=ne;
 *   per mask  popcount == k; no bits ≥ n; CANONICAL (numeric min of its orbit
 *             under the run's restricted pair-permutations);
 *   per entry last∈[0,63] (bits 22-31 zero); rid<R; keys ascending within span;
 *             value nonzero; and the SUM INVARIANT — the rid mixed-radix digits
 *             sum to k, each ≤ b0[c] (a strong per-entry content check, free);
 *   mass      the §Reading-recipe step-5/6 ORBIT-WEIGHTED MASS, Σ_i s_i ·
 *             (geff/|stab(mask_i)|), re-derived from the layer bytes under the
 *             independently-derived TR-11 §2 group (24 pair-perms from
 *             C_{S6}(rev), restricted to the run's pair list) and compared to
 *             solve.c's reported mass= for every layer when a run log is given
 *             — the full-scale counterpart of the small-k mass-DP check;
 *   layer 0   exactly {mask 0, key start_exit<<16, value 1};
 *   layer n   nm==1, mask==2^n-1, orbit 1, every rid==R-1, and for full-31
 *             Σvalues == PUBLISHED COUNT and ≡ 0 (mod 24).
 * A v2 block whose Adler-32 or decompressed size is wrong fails in zlib/inflate.
 *
 * Any mismatch is a FINDING (F1C5_LAYER_FORMAT.md: "report it, do not patch
 * around it"), never silently repaired.
 *
 * Memory: masks[nm] + off[nm+1] in RAM (peak full-31 ~156 MB); entries stream.
 * This is a CAMPAIGN-VM tool, not an orchestrator tool — run it where the layers
 * live. `--check-layers-selftest` builds tiny synthetic v1+v2 fixtures and needs
 * neither real data nor much memory.
 * ========================================================================== */

#define LC_PUBLISHED_COUNT "1097051278789181790036112071176579186688"  /* |C1∩C2∩C4∩C5| */
/* |C1∩C2∩C4| — published exact (TR-4 §"exact vs estimator" table / TR-11;
 * same integer as verify.py's _C1C2C4_EXACT and the solve.c §f1-exact comment). */
#define LC_PUBLISHED_COUNT_C1C2C4 "757058601340255440651419713405330315358208"
/* |C1∩C2∩C4∩C5∩C6∩C7| (= |C1–C7| with C3 dropped) — published exact
 * (METHODS.md estimate-vs-exact table; first computed 2026-07-25 by the T3
 * pinned-step IE recount). --dp-count's full-31 pinned default target. */
#define LC_PUBLISHED_COUNT_C1C7NOC3 "516880238445773965371923491676160"

typedef struct { uint64_t l[3]; } u192;                 /* value = l0 + 2^64 l1 + 2^128 l2 */
static int  u192_add(u192 *a, u192 b) {                 /* a+=b; returns 1 on 192-bit overflow */
    unsigned __int128 s = (unsigned __int128)a->l[0] + b.l[0]; a->l[0] = (uint64_t)s;
    s = (unsigned __int128)a->l[1] + b.l[1] + (s >> 64);  a->l[1] = (uint64_t)s;
    s = (unsigned __int128)a->l[2] + b.l[2] + (s >> 64);  a->l[2] = (uint64_t)s;
    return (s >> 64) != 0;
}
static int u192_zero(u192 a) { return (a.l[0] | a.l[1] | a.l[2]) == 0; }
static int u192_eq(u192 a, u192 b) { return a.l[0]==b.l[0] && a.l[1]==b.l[1] && a.l[2]==b.l[2]; }
static unsigned u192_mod(u192 a, unsigned m) {          /* a mod m, big-endian limb walk */
    unsigned __int128 r = 0;
    for (int i = 2; i >= 0; i--) { r = (r << 64) | a.l[i]; r %= m; }
    return (unsigned)r;
}
static u192 u192_dec(const char *s) {                   /* decimal string -> u192 */
    u192 v = {{0,0,0}};
    for (; *s; s++) { if (*s < '0' || *s > '9') continue;
        unsigned __int128 c = (unsigned)(*s - '0');
        for (int i = 0; i < 3; i++) { unsigned __int128 t = (unsigned __int128)v.l[i]*10 + c;
            v.l[i] = (uint64_t)t; c = t >> 64; } }
    return v;
}
static void u192_print(u192 v, char *out) {             /* out >= 60 bytes */
    if (u192_zero(v)) { strcpy(out, "0"); return; }
    char t[64]; int n = 0; u192 x = v;
    while (!u192_zero(x)) { unsigned __int128 r = 0;
        for (int i = 2; i >= 0; i--) { r = (r << 64) | x.l[i]; x.l[i] = (uint64_t)(r/10); r %= 10; }
        t[n++] = '0' + (int)r; }
    int j = 0; while (n) out[j++] = t[--n]; out[j] = 0;
}
static int u192_mul_small(u192 *a, uint32_t s) {        /* a*=s; 1 on 192-bit overflow */
    unsigned __int128 c = 0;
    for (int i = 0; i < 3; i++) {
        unsigned __int128 t = (unsigned __int128)a->l[i] * s + c;
        a->l[i] = (uint64_t)t; c = t >> 64;
    }
    return c != 0;
}
/* full 192x192 product; *ovf set to 1 if the true product exceeds 192 bits.
 * Valid-ladder products f(s)*g(s) / f(s)*t(s) never do (each is <= the total
 * node count < 2^192); the guard exists for the corrupt-file case. */
static u192 u192_mul(u192 a, u192 b, int *ovf) {
    uint64_t r[6] = {0, 0, 0, 0, 0, 0};
    for (int i = 0; i < 3; i++) {
        unsigned __int128 carry = 0;
        for (int j = 0; j < 3; j++) {
            unsigned __int128 t = (unsigned __int128)a.l[i] * b.l[j] + r[i + j] + carry;
            r[i + j] = (uint64_t)t; carry = t >> 64;
        }
        for (int q = i + 3; carry && q < 6; q++) {
            unsigned __int128 t = (unsigned __int128)r[q] + carry;
            r[q] = (uint64_t)t; carry = t >> 64;
        }
    }
    if (r[3] | r[4] | r[5]) *ovf = 1;
    u192 out; out.l[0] = r[0]; out.l[1] = r[1]; out.l[2] = r[2];
    return out;
}

/* pl_hash: FNV-1a-64 absorbing 64-bit WORDS (n, start_exit, pl[0..n-1]) — the
 * project-convention variant stated verbatim in F1C5_LAYER_FORMAT.md §Manifest. */
static uint64_t lc_pl_hash(uint32_t n, uint32_t start_exit, const uint32_t *pl) {
    uint64_t h = 0xcbf29ce484222325ULL;
    h ^= n;          h *= 0x100000001b3ULL;
    h ^= start_exit; h *= 0x100000001b3ULL;
    for (uint32_t i = 0; i < n; i++) { h ^= pl[i]; h *= 0x100000001b3ULL; }
    return h;
}

/* radices / place-values / R from b0, per §Entry encoding. */
static void lc_radix(const int b0v[5], uint32_t rad[5], uint32_t *R) {
    uint32_t pv = 1;
    for (int c = 0; c < 5; c++) { rad[c] = pv; pv *= (uint32_t)(b0v[c] + 1); }
    *R = pv;
}
/* decode rid -> per-class digits; return digit sum, or -1 if any digit > b0[c]. */
static int lc_rid_digits(uint32_t rid, const int b0v[5], const uint32_t rad[5]) {
    int sum = 0;
    for (int c = 4; c >= 0; c--) { uint32_t p = rid / rad[c]; rid %= rad[c];
        if ((int)p > b0v[c]) return -1;
        sum += (int)p; }
    return sum;
}

/* ---------------------------------------------------------------------------
 * The TR-11 §2 group, DERIVED here from the published definition — the same
 * derivation verify.py's --recount performs (_commuting_bitperms + induce +
 * dedup) and nothing from solve.c: enumerate the 720 bit-position permutations
 * of S6, keep the 48 commuting with reversal (g[5-i] == 5-g[i], TR-5's
 * C_{S6}(rev)), induce each on the 32 KW pairs (a pair maps to the pair whose
 * unordered hexagram set is its image), dedup (kernel {id, rev}) -> exactly 24
 * distinct pair-permutations (≅ S4), every one fixing pair 0.
 *
 * These 24 power the §Reading-recipe step-5 orbit weighting: mask bit i of a
 * run stands for pair pl[i], a pair-perm σ acts on a mask by relabeling its
 * set bits through pl, and orbit(mask) = |G_run| / |stab(mask)| where G_run is
 * the group of DISTINCT RESTRICTED permutations on the run's pair list (all 24
 * restrict when pl is group-closed, as every real run's is; fewer may remain
 * distinct after restriction). Group closure is re-verified numerically both
 * before and after restriction, so orbit-stabilizer genuinely applies.
 * ------------------------------------------------------------------------- */
static uint8_t PP[24][32]; static int NPP = 0;   /* the 24 induced pair-perms */
static uint8_t PPG[24][6];                        /* one witness bit-perm per pair-perm
                                                   * (recorded for --ie-count's elementwise
                                                   * startup re-verification; no other use) */
static int pp_n48;                                /* how many g commute with rev */
static int pp_fail;
static void pp_rec(int depth, int *g, int used) {
    if (pp_fail) return;
    if (depth == 6) {
        for (int i = 0; i < 6; i++) if (g[5-i] != 5-g[i]) return;   /* keep C_{S6}(rev) */
        pp_n48++;
        uint8_t m[32];
        for (int j = 0; j < 32; j++) {
            int ga = 0, gb = 0;                   /* bit i -> position g[i] */
            for (int t = 0; t < 6; t++) {
                if ((PA[j] >> t) & 1) ga |= 1 << g[t];
                if ((PB[j] >> t) & 1) gb |= 1 << g[t];
            }
            int found = -1;
            for (int q = 0; q < 32; q++)
                if ((PA[q]==ga && PB[q]==gb) || (PA[q]==gb && PB[q]==ga)) { found = q; break; }
            if (found < 0) { pp_fail = 1; return; }   /* g fails to permute the pairs — a finding */
            m[j] = (uint8_t)found;
        }
        for (int q = 0; q < NPP; q++) if (!memcmp(PP[q], m, 32)) return;
        if (NPP >= 24) { pp_fail = 2; return; }       /* >24 distinct — a finding */
        for (int t = 0; t < 6; t++) PPG[NPP][t] = (uint8_t)g[t];   /* witness bit-perm */
        memcpy(PP[NPP++], m, 32);
        return;
    }
    for (int v = 0; v < 6; v++)
        if (!(used & (1 << v))) { g[depth] = v; pp_rec(depth+1, g, used | (1 << v)); }
}
static int derive_pair_perms(void) {              /* 1 ok; prints its own failure */
    if (NPP == 24) return 1;                      /* idempotent */
    if (!build_pairs()) return 0;
    int g[6]; pp_n48 = 0; pp_fail = 0; NPP = 0;
    pp_rec(0, g, 0);
    if (pp_fail == 1) { printf("*** FAIL: a C_{S6}(rev) element does not permute the 32 pairs\n"); return 0; }
    if (pp_fail == 2 || NPP != 24) { printf("*** FAIL: induced pair-perms = %d, expected 24\n", NPP); return 0; }
    if (pp_n48 != 48) { printf("*** FAIL: |C_{S6}(rev)| = %d, expected 48\n", pp_n48); return 0; }
    for (int q = 0; q < NPP; q++) {
        uint32_t seen = 0;
        if (PP[q][0] != 0) { printf("*** FAIL: pair-perm %d moves the C4 anchor pair\n", q); return 0; }
        for (int j = 0; j < 32; j++) seen |= 1u << PP[q][j];
        if (seen != 0xffffffffu) { printf("*** FAIL: pair-perm %d is not a bijection\n", q); return 0; }
    }
    for (int a = 0; a < NPP; a++)                 /* closure: {24} must be a group */
        for (int b = 0; b < NPP; b++) {
            uint8_t c[32]; int found = 0;
            for (int j = 0; j < 32; j++) c[j] = PP[a][PP[b][j]];
            for (int t = 0; t < NPP; t++) if (!memcmp(PP[t], c, 32)) { found = 1; break; }
            if (!found) { printf("*** FAIL: pair-perms not closed under composition\n"); return 0; }
        }
    return 1;
}

/* Restrict the 24 pair-perms to the run's pair list pl[0..n-1] (mask bit i =
 * pair pl[i]). Keeps those preserving the pl SET, rewrites them on subset
 * indices, dedups, and re-verifies closure. Returns the group order geff
 * (1..24, divides 24), or -1 on failure. */
static int lc_restrict_perms(const uint32_t *pl, uint32_t n, uint8_t rp[24][32]) {
    int inv[32]; for (int i = 0; i < 32; i++) inv[i] = -1;
    if (n == 0 || n > 31) return -1;
    for (uint32_t i = 0; i < n; i++) {
        if (pl[i] < 1 || pl[i] > 31 || inv[pl[i]] >= 0) return -1;
        inv[pl[i]] = (int)i;
    }
    int geff = 0;
    for (int q = 0; q < NPP; q++) {
        uint8_t r[32]; int ok = 1;
        for (uint32_t i = 0; i < n && ok; i++) {
            int im = inv[PP[q][pl[i]]];
            if (im < 0) ok = 0; else r[i] = (uint8_t)im;
        }
        if (!ok) continue;                        /* does not preserve the pl set */
        int dup = 0;
        for (int t = 0; t < geff; t++) if (!memcmp(rp[t], r, n)) { dup = 1; break; }
        if (!dup) memcpy(rp[geff++], r, n);
    }
    if (geff < 1 || 24 % geff) return -1;         /* order must divide 24 (Lagrange) */
    for (int a = 0; a < geff; a++)                /* closure of the restricted set */
        for (int b = 0; b < geff; b++) {
            uint8_t c[32]; int found = 0;
            for (uint32_t i = 0; i < n; i++) c[i] = rp[a][rp[b][i]];
            for (int t = 0; t < geff; t++) if (!memcmp(rp[t], c, n)) { found = 1; break; }
            if (!found) return -1;
        }
    return geff;
}

static uint32_t lc_mask_img(uint32_t m, const uint8_t *sig) {
    uint32_t r = 0;
    while (m) { int b = __builtin_ctz(m); m &= m - 1; r |= 1u << sig[b]; }
    return r;
}
/* Orbit size of mask m under the geff restricted perms (orbit-stabilizer:
 * geff / |stab|); *canon set to 1 iff m is the numeric minimum of its orbit.
 * Returns 0 if geff % |stab| != 0 — impossible under a true group action,
 * guarded anyway so a closure bug can never mis-weight silently. */
static int lc_orbit_of(uint32_t m, uint8_t rp[24][32], int geff, int *canon) {
    int stab = 0; uint32_t mn = m;
    for (int q = 0; q < geff; q++) {
        uint32_t im = lc_mask_img(m, rp[q]);
        if (im == m) stab++;
        if (im < mn) mn = im;
    }
    *canon = (mn == m);
    if (stab == 0 || geff % stab) return 0;
    return geff / stab;
}

/* =========================================================================
 * --scan-layers: multi-observable parallel scan driver (config + rider state)
 *
 * One pass over the ladder, N registered integer accumulators, L parallel
 * O_DIRECT read lanes. The FULL implementation (stream reader, lane workers,
 * merge, self-test) lives after lc_selftest below; these declarations sit
 * here because the shared driver lc_check_layers_impl dispatches on them.
 *
 * INDEPENDENCE: everything in the scan path is derived from
 * documentation/F1C5_LAYER_FORMAT.md and this file's own spec-derived
 * helpers (lc_radix / lc_rid_digits / lc_orbit_of / u192). No solve.c
 * header, table, or constant — the same derivation discipline as
 * --check-layers, of which this is the parallel counterpart.
 *
 * IDENTITY CONTRACT (the gate, not a goal): on a valid ladder, the stdout of
 * --scan-layers minus lines prefixed "[scan] " is byte-identical to
 * --check-layers, for every lane count and chunk size, and the exit code is
 * always identical. All accumulation is exact integer (u192 / uint64_t):
 * per-lane partial sums are of non-negative integers bounded by the
 * sequential totals, merged in a fixed lane-ascending order, so lane count
 * cannot change any output (the LENS-1 integer-reduction discipline).
 * Span sums are stitched across lane boundaries and multiplied by the orbit
 * weight ONCE per span — the exact sum-then-multiply arithmetic of the
 * sequential path. On a file that FAILS validation both paths return the
 * same nonzero rc, but the diagnostic text may differ (the sequential path
 * stops at its first bad block; lanes each stop at their own).
 *
 * Riders (all exact-integer, all output on "[scan] "-prefixed lines,
 * none affect the exit code):
 *   census  (T7 / BL-7)  per-layer canonical-mask orbit-size census, from
 *           the mask table + orbits[] — masks and offsets only, no values.
 *   t6stub  (T6 / QL-6 slot) INTERFACE STUB ONLY: a per-layer entry-count +
 *           value-mass marginal by `last`, proving the driver carries
 *           per-entry accumulators with cross-layer persistence. It is NOT
 *           the QL-6 branching-factor statistic (that needs layer-(k+1)
 *           adjacency and its own review); enable via LC_SCAN_T6STUB=1.
 *
 * Config (env):  LC_SCAN_LANES   read/worker lanes        (default 8, 1..64)
 *                LC_SCAN_CHUNK_KB per-pread request size  (default 4096 KiB)
 *                LC_SCAN_ODIRECT 1=O_DIRECT reads         (default 1; falls
 *                                back per-fd to buffered reads on EINVAL —
 *                                e.g. tmpfs — with a note on stderr)
 *                LC_SCAN_T6STUB  1=enable the T6 slot stub (default 0)
 * ========================================================================= */
typedef struct {
    int lanes;            /* parallel lanes (threads, each its own fds) */
    size_t chunk;         /* bytes per pread request (4 KiB multiple) */
    int odirect;          /* 1 = open data streams O_DIRECT */
    int t6stub;           /* 1 = run the T6-slot stub accumulator */
} LcScanCfg;

typedef struct {          /* rider outputs across the whole run (integer only) */
    uint64_t census[32][25];   /* [k][s] = canonical masks of orbit size s */
    uint64_t census_raw[32];   /* [k] Σ_masks orbit size = orbit-expanded masks */
    int      census_got[32];   /* layer scanned (0 = absent or LC_RESUME replay) */
    uint64_t t6_n[32][64];     /* STUB: [k][last] entry count */
    u192     t6_v[32][64];     /* STUB: [k][last] Σ values */
    int      t6_got[32];
} LcsRiders;

static int lcs_scan_layer(const char *dir, int k, uint32_t exp_n, uint32_t exp_se,
                          uint64_t exp_plhash, const int exp_b0[5], int is_final,
                          uint8_t rp[24][32], int geff, u192 *grand_out, u192 *mass_out,
                          uint64_t *nm_out, uint64_t *ne_out, int *v2_out,
                          const LcScanCfg *cfg, LcsRiders *rd);

/* read exactly n bytes at absolute offset off; 1 ok, 0 short/err. */
static int lc_pread(FILE *f, long off, void *buf, size_t n) {
    if (fseek(f, off, SEEK_SET) != 0) return 0;
    return fread(buf, 1, n, f) == n;
}

/* Verify one layer file. Returns 0 ok, 1 fail. Accumulates grand into *grand
 * (only meaningful when the caller knows this is the final layer) and the
 * §Reading-recipe step-5/6 ORBIT-WEIGHTED MASS into *mass_out:
 *   mass(k) = Σ_i s_i · orbit(masks[i]),  s_i = Σ vals over mask i's span,
 * with orbit(m) = geff / |stab(m)| over the rp[] restricted pair-perms.
 * Overflow analysis: s_i ≤ Σvals (u192-guarded below) and orbit ≤ 24, and
 * mathematically mass(k) ≤ 31·30·…·(31−k+1)·2^k < 2^144 for any real layer
 * (an upper bound on C2/C5-feasible length-k prefixes), so u192 suffices with
 * ~48 bits of headroom; the checked multiply/add still guard the corrupt-file
 * case. Also checks per mask: popcount == k, no bits ≥ n, and CANONICITY
 * (numeric minimum of its orbit — a spec invariant the group makes checkable). */
static int lc_check_layer(const char *dir, int k, uint32_t exp_n, uint32_t exp_se,
                          uint64_t exp_plhash, const int exp_b0[5], int is_final,
                          uint8_t rp[24][32], int geff, u192 *grand_out, u192 *mass_out,
                          uint64_t *nm_out, uint64_t *ne_out, int *v2_out) {
    char path[1024]; snprintf(path, sizeof path, "%s/f1c5_layer_%02d.bin", dir, k);
    FILE *f = fopen(path, "rb");
    if (!f) { printf("  k=%2d  *** FAIL: cannot open %s\n", k, path); return 1; }

    unsigned char hd[72];
    if (!lc_pread(f, 0, hd, 72)) { printf("  k=%2d  *** FAIL: short header\n", k); fclose(f); return 1; }
    uint32_t version, hn, hk, hse, pad; uint64_t plhash, nm64, ne64; int hb0[5];
    memcpy(&version,hd+8,4); memcpy(&hn,hd+12,4); memcpy(&hk,hd+16,4); memcpy(&hse,hd+20,4);
    memcpy(&plhash,hd+24,8); memcpy(&nm64,hd+32,8); memcpy(&ne64,hd+40,8);
    for (int c=0;c<5;c++){ uint32_t t; memcpy(&t,hd+48+4*c,4); hb0[c]=(int)t; }
    memcpy(&pad,hd+68,4);
    int is_v2 = memcmp(hd,"F1C5LAY2",8)==0, is_v1 = memcmp(hd,"F1C5LAY1",8)==0;

    int fail = 0;
    #define LCF(cond,msg,...) do{ if(!(cond)){ printf("  k=%2d  *** FAIL: " msg "\n",k,##__VA_ARGS__); fail=1; } }while(0)
    LCF(is_v1||is_v2, "bad magic (not F1C5LAY1/2)");
    LCF((is_v1&&version==1)||(is_v2&&version==2), "version %u disagrees with magic", version);
    LCF(hn==exp_n, "header n=%u != manifest %u", hn, exp_n);
    LCF(hk==(uint32_t)k, "header k=%u != filename %d", hk, k);
    LCF(hse==exp_se, "header start_exit=%u != manifest %u", hse, exp_se);
    LCF(plhash==exp_plhash, "header pl_hash=%016llx != recomputed %016llx",
        (unsigned long long)plhash, (unsigned long long)exp_plhash);
    for (int c=0;c<5;c++) LCF(hb0[c]==exp_b0[c], "header b0[%d]=%d != KW %d", c, hb0[c], exp_b0[c]);
    if (fail) { fclose(f); return 1; }

    uint32_t rad[5], R; lc_radix(exp_b0, rad, &R);
    uint64_t nm = nm64, ne = ne64;
    uint32_t BLK = is_v2 ? pad : 0;
    if (is_v2) LCF(BLK>0, "v2 block size (pad field) is zero");

    /* masks[] + off[] */
    uint8_t *orbits = NULL;
    uint32_t *masks = malloc(nm*4 + 4);
    uint64_t *off   = malloc((nm+1)*8 + 8);
    if (!masks || !off) { printf("  k=%2d  *** FAIL: OOM (nm=%llu)\n", k,(unsigned long long)nm);
                          free(masks); free(off); fclose(f); return 1; }
    long masks_off = 72, off_off = 72 + 4*(long)nm;
    if (!lc_pread(f, masks_off, masks, nm*4) || !lc_pread(f, off_off, off, (nm+1)*8)) {
        printf("  k=%2d  *** FAIL: short masks/off table\n", k); fail=1; goto cleanup; }
    LCF(off[0]==0, "off[0]=%llu != 0", (unsigned long long)off[0]);
    LCF(off[nm]==ne, "off[nm]=%llu != ne=%llu", (unsigned long long)off[nm], (unsigned long long)ne);
    orbits = malloc(nm ? nm : 1);
    if (!orbits) { printf("  k=%2d  *** FAIL: OOM orbit table\n", k); fail=1; goto cleanup; }
    uint64_t bad_pc=0, bad_hibit=0, bad_canon=0, bad_orb=0;
    for (uint64_t i=0;i<nm;i++) {
        LCF(off[i]<=off[i+1], "off not monotone at %llu", (unsigned long long)i);
        if (i) LCF(masks[i]>masks[i-1], "masks not strictly ascending at %llu", (unsigned long long)i);
        if (fail) break;
        if (__builtin_popcount(masks[i]) != k) bad_pc++;
        if (exp_n < 32 && (masks[i] >> exp_n) != 0) bad_hibit++;
        int canon; int ob = lc_orbit_of(masks[i], rp, geff, &canon);
        if (ob == 0) bad_orb++;                    /* geff % stab != 0 — see lc_orbit_of */
        if (!canon) bad_canon++;
        orbits[i] = (uint8_t)ob;
    }
    LCF(bad_pc==0,    "%llu masks with popcount != k", (unsigned long long)bad_pc);
    LCF(bad_hibit==0, "%llu masks with bits >= n", (unsigned long long)bad_hibit);
    LCF(bad_canon==0, "%llu NON-CANONICAL masks (not the min of their orbit)", (unsigned long long)bad_canon);
    LCF(bad_orb==0,   "%llu masks where orbit-stabilizer failed (|stab| does not divide geff)", (unsigned long long)bad_orb);
    if (is_final && nm==1 && !fail)
        LCF(orbits[0]==1, "final full mask has orbit %d != 1", orbits[0]);
    if (fail) goto cleanup;

    /* layer-0 and final-layer shape */
    if (k==0) { LCF(nm==1 && masks[0]==0 && ne==1, "layer 0 must be {mask 0, 1 entry}"); }
    if (is_final) {
        LCF(nm==1, "final layer nm=%llu != 1", (unsigned long long)nm);
        LCF(masks[0]==((exp_n>=32)?0xffffffffu:((1u<<exp_n)-1)), "final mask != 2^n-1");
    }

    /* stream entries in global order, attributing each to its mask span via off[] */
    u192 grand = {{0,0,0}}, mass = {{0,0,0}}, span_sum = {{0,0,0}};
    uint64_t bad_last=0, bad_rid=0, bad_sum=0, bad_zero=0, bad_order=0, bad_finalrid=0, ovf=0, movf=0;
    uint64_t e = 0, mi = 0; uint32_t prev_key = 0; int have_prev = 0;
    long keys_base=0, vals_base=0, kidx_off=0, vidx_off=0, kblk_base=0, vblk_base=0;
    uint64_t nblk=0, *kidx=NULL, *vidx=NULL;
    if (is_v1) { keys_base = off_off + (long)(nm+1)*8; vals_base = keys_base + (long)ne*4; }
    else {
        nblk = ne ? (ne + BLK - 1)/BLK : 0;
        kidx = malloc((nblk+1)*8 + 8); vidx = malloc((nblk+1)*8 + 8);
        kidx_off = off_off + (long)(nm+1)*8; vidx_off = kidx_off + (long)(nblk+1)*8;
        if ((nblk && (!kidx||!vidx)) ||
            !lc_pread(f, kidx_off, kidx, (nblk+1)*8) || !lc_pread(f, vidx_off, vidx, (nblk+1)*8)) {
            printf("  k=%2d  *** FAIL: short kidx/vidx\n", k); free(kidx); free(vidx); goto cleanup; }
        LCF(kidx[0]==0 && vidx[0]==0, "kidx/vidx[0] != 0");
        kblk_base = 96 + 12*(long)nm + 16*(long)nblk;
        vblk_base = kblk_base + (long)kidx[nblk];
    }

    uint32_t *kbuf = malloc((BLK?BLK:65536)*4);
    unsigned char *vbuf = malloc((size_t)(BLK?BLK:65536)*24);
    unsigned char *zbuf = is_v2 ? malloc(compressBound(24u*BLK)+64) : NULL;
    if (!kbuf || !vbuf || (is_v2 && !zbuf)) { printf("  k=%2d  *** FAIL: OOM stream buffers\n", k);
        free(kbuf); free(vbuf); free(zbuf); free(kidx); free(vidx); goto cleanup; }

    uint64_t nblocks = is_v1 ? (ne ? (ne+65535)/65536 : 0) : nblk;
    for (uint64_t b = 0; b < nblocks && !fail; b++) {
        uint64_t bstart = b * (is_v1?65536:BLK);
        uint64_t bn = (is_v1?65536:BLK); if (bstart+bn > ne) bn = ne - bstart;
        if (is_v1) {
            if (!lc_pread(f, keys_base + (long)bstart*4, kbuf, bn*4) ||
                !lc_pread(f, vals_base + (long)bstart*24, vbuf, bn*24)) {
                printf("  k=%2d  *** FAIL: short v1 entry read\n", k); fail=1; break; }
        } else {
            uLongf kd = (uLongf)(bn*4), vd = (uLongf)(bn*24);
            uint64_t kc = kidx[b+1]-kidx[b], vc = vidx[b+1]-vidx[b];
            if (!lc_pread(f, kblk_base + (long)kidx[b], zbuf, kc) ||
                uncompress((Bytef*)kbuf, &kd, zbuf, (uLong)kc) != Z_OK || kd != bn*4) {
                printf("  k=%2d  *** FAIL: key block %llu inflate/size\n", k,(unsigned long long)b); fail=1; break; }
            if (!lc_pread(f, vblk_base + (long)vidx[b], zbuf, vc) ||
                uncompress((Bytef*)vbuf, &vd, zbuf, (uLong)vc) != Z_OK || vd != bn*24) {
                printf("  k=%2d  *** FAIL: val block %llu inflate/size\n", k,(unsigned long long)b); fail=1; break; }
        }
        for (uint64_t j = 0; j < bn; j++, e++) {
            while (mi < nm && e >= off[mi+1]) {           /* new mask span: close */
                u192 t = span_sum;                        /* out span mi weighted */
                if (u192_mul_small(&t, orbits[mi])) movf++;
                if (u192_add(&mass, t)) movf++;
                span_sum = (u192){{0,0,0}};
                mi++; have_prev = 0;
            }
            uint32_t key = kbuf[j];
            u192 val; memcpy(&val, vbuf + j*24, 24);
            uint32_t rid = key & 0xffff;
            if (key >> 22) bad_last++;   /* last = key>>16 must fit 0..63 */
            if (rid >= R) { bad_rid++; }
            else if (lc_rid_digits(rid, exp_b0, rad) != k) bad_sum++;
            if (have_prev && key <= prev_key) bad_order++;
            prev_key = key; have_prev = 1;
            if (u192_zero(val)) bad_zero++;
            if (is_final && rid != R-1) bad_finalrid++;
            if (u192_add(&grand, val)) ovf++;
            if (u192_add(&span_sum, val)) ovf++;
        }
    }
    while (mi < nm) {                                     /* close remaining spans */
        u192 t = span_sum;
        if (u192_mul_small(&t, orbits[mi])) movf++;
        if (u192_add(&mass, t)) movf++;
        span_sum = (u192){{0,0,0}};
        mi++;
    }
    free(kbuf); free(vbuf); free(zbuf); free(kidx); free(vidx);
    LCF(e==ne, "streamed %llu entries != ne=%llu", (unsigned long long)e,(unsigned long long)ne);
    LCF(bad_last==0,  "%llu entries with nonzero key bits 22-31", (unsigned long long)bad_last);
    LCF(bad_rid==0,   "%llu entries with rid >= R", (unsigned long long)bad_rid);
    LCF(bad_sum==0,   "%llu entries where rid digit-sum != k (SUM INVARIANT)", (unsigned long long)bad_sum);
    LCF(bad_order==0, "%llu non-ascending keys within a mask span", (unsigned long long)bad_order);
    LCF(bad_zero==0,  "%llu zero values", (unsigned long long)bad_zero);
    LCF(ovf==0,       "192-bit overflow summing values");
    LCF(movf==0,      "192-bit overflow in orbit-weighted mass");
    if (is_final) LCF(bad_finalrid==0, "%llu final-layer entries with rid != R-1", (unsigned long long)bad_finalrid);
    if (grand_out) *grand_out = grand;
    if (mass_out)  *mass_out  = mass;
    if (nm_out) *nm_out = nm;
    if (ne_out) *ne_out = ne;
    if (v2_out) *v2_out = is_v2;
    /* per-layer summary line printed by the caller (identical for a freshly
     * streamed layer and an LC_RESUME-replayed one — see the driver). */
cleanup:
    free(orbits); free(masks); free(off); fclose(f);
    #undef LCF
    return fail;
}

/* parse <pfx>_manifest.txt (spec §Manifest; first line must be
 * "<pfx>_manifest_v1" — GT_LADDER_FORMAT.md's per-kind tag). returns 0 ok. */
static int lc_manifest_pfx(const char *dir, const char *pfx,
                           uint32_t *n, uint32_t *se, uint64_t *plhash_hex,
                           uint32_t pl[64], int *npl, int b0[5], int *last_k) {
    char path[1024]; snprintf(path, sizeof path, "%s/%s_manifest.txt", dir, pfx);
    char tag[64];   snprintf(tag,  sizeof tag,  "%s_manifest_v1", pfx);
    FILE *f = fopen(path, "r"); if (!f) return 1;
    char line[8192]; int have_tag=0; *n=0; *se=0; *last_k=-1; *plhash_hex=0; *npl=0;
    for (int c=0;c<5;c++) b0[c]=0;
    while (fgets(line, sizeof line, f)) {
        if (!strncmp(line,tag,strlen(tag))) have_tag=1;
        else if (!strncmp(line,"n=",2)) *n=(uint32_t)atoi(line+2);
        else if (!strncmp(line,"start_exit=",11)) *se=(uint32_t)atoi(line+11);
        else if (!strncmp(line,"pl=",3)) { int i=0; char *t=strtok(line+3,",\n");
            while(t&&i<64){ pl[i++]=(uint32_t)atoi(t); t=strtok(NULL,",\n"); } *npl=i; }
        else if (!strncmp(line,"pl_hash=",8)) *plhash_hex=strtoull(line+8,NULL,16);
        else if (!strncmp(line,"b0=",3)) { int i=0; char *t=strtok(line+3,",\n");
            while(t&&i<5){ b0[i++]=atoi(t); t=strtok(NULL,",\n"); } }
        else if (!strncmp(line,"last_complete_k=",16)) *last_k=atoi(line+16);
    }
    fclose(f);
    return have_tag ? 0 : 1;
}
static int lc_manifest(const char *dir, uint32_t *n, uint32_t *se, uint64_t *plhash_hex,
                       uint32_t pl[64], int *npl, int b0[5], int *last_k) {
    return lc_manifest_pfx(dir, "f1c5", n, se, plhash_hex, pl, npl, b0, last_k);
}

/* parse the run log's "[f1c5] layer k=%2d/%d: ... mass=<dec> ..." lines for a
 * run of n pairs (lines exist for k=1..n only; layer 0 is trivially mass 1).
 * masses[k] receives the decimal string. Returns #lines parsed, -1 no file. */
static int lc_parse_masses(const char *path, uint32_t n, char masses[32][48]) {
    FILE *f = fopen(path, "r");
    if (!f) return -1;
    char line[8192]; int found = 0;
    while (fgets(line, sizeof line, f)) {
        int k, nn;
        if (sscanf(line, "[f1c5] layer k=%d/%d:", &k, &nn) != 2) continue;
        if (nn != (int)n || k < 0 || k > (int)n || k > 31) continue;
        const char *q = strstr(line, " mass=");
        if (!q) continue;
        q += 6;
        int j = 0; while (*q >= '0' && *q <= '9' && j < 46) masses[k][j++] = *q++;
        masses[k][j] = 0;
        if (j) found++;
    }
    fclose(f);
    return found;
}

/* Shared driver for --check-layers (cfg==NULL: the unchanged sequential
 * stdio path) and --scan-layers (cfg!=NULL: parallel lanes + riders). All
 * scan-only output is on "[scan] "-prefixed lines; everything else prints
 * byte-identically in both modes (see the IDENTITY CONTRACT above). */
static int lc_check_layers_impl(const char *dir, int maxk, const char *run_out,
                                const LcScanCfg *cfg) {
    uint32_t mn, mse, pl[64]; uint64_t m_plhash; int last_k, npl; int b0v[5];
    static LcsRiders riders;                  /* static: 68 KB, zeroed per call */
    memset(&riders, 0, sizeof riders);
    printf("======================================================================\n");
    printf("verify.c --check-layers : spec-driven independent layer-file reader\n");
    printf("written against documentation/F1C5_LAYER_FORMAT.md; shares no code with solve.c\n");
    printf("======================================================================\n");
    if (cfg)
        printf("[scan] multi-observable parallel scan: lanes=%d chunk=%zuKiB odirect=%d riders=census%s\n",
               cfg->lanes, cfg->chunk / 1024, cfg->odirect, cfg->t6stub ? ",t6stub" : "");
    if (lc_manifest(dir, &mn, &mse, &m_plhash, pl, &npl, b0v, &last_k)) {
        printf("*** FAIL: cannot read %s/f1c5_manifest.txt\n", dir); return 1; }
    if (mn < 1 || mn > 31 || npl != (int)mn) {
        printf("*** FAIL: manifest n=%u with %d pl entries (need 1<=n<=31, |pl|=n)\n", mn, npl);
        return 1; }

    uint64_t rec_plhash = lc_pl_hash(mn, mse, pl);
    int plhash_ok = (rec_plhash == m_plhash);
    printf("manifest: n=%u start_exit=%u last_complete_k=%d b0=(%d,%d,%d,%d,%d)\n",
           mn, mse, last_k, b0v[0],b0v[1],b0v[2],b0v[3],b0v[4]);
    printf("pl_hash : manifest %016llx  recomputed %016llx  %s\n",
           (unsigned long long)m_plhash, (unsigned long long)rec_plhash,
           plhash_ok ? "MATCH" : "*** MISMATCH ***");

    /* b0 authority is the manifest (used for every layer's rid decode + header check).
     * For full-31 it must additionally equal KW's boundary multiset — an independent
     * cross-check against the published sequence, not against solve.c. */
    int kw_ok = 1;
    if (mn == 31) { if (!build_pairs()) return 1;
        int kwb0[5] = {0,0,0,0,0};
        for (int i=0;i<31;i++){ int d=hamming(KW[2*i+1],KW[2*i+2]); int c=cls_ix(d);
            if(c<0){printf("*** FAIL: KW boundary %d outside classes\n",d);return 1;} kwb0[c]++; }
        for (int c=0;c<5;c++) if (kwb0[c]!=b0v[c]) kw_ok=0;
        printf("b0 (KW)  : (%d,%d,%d,%d,%d)  %s\n", kwb0[0],kwb0[1],kwb0[2],kwb0[3],kwb0[4],
               kw_ok ? "MATCH manifest" : "*** DIFFERS from manifest ***");
    }

    /* the group (§Reading recipe step 5): derive the 24 pair-perms from the
     * published definition, restrict to this run's pair list. */
    if (!derive_pair_perms()) return 1;
    static uint8_t rp[24][32];
    int geff = lc_restrict_perms(pl, mn, rp);
    if (geff < 0) { printf("*** FAIL: restricted pair-perms are not a group (pl line bad?)\n"); return 1; }
    int geff_ok = !(mn == 31 && geff != 24);
    printf("group   : |C_S6(rev)|=48 -> 24 induced pair-perms -> %d distinct on this run's %u pairs%s\n",
           geff, mn, geff_ok ? "" : "  *** expected 24 for full-31 ***");

    /* solve.c's reported per-layer masses (optional run.out) */
    char (*rm)[48] = NULL; int n_rm = 0;
    if (run_out) {
        rm = calloc(32, 48);
        if (!rm) { printf("*** FAIL: OOM mass table\n"); return 1; }
        n_rm = lc_parse_masses(run_out, mn, rm);
        if (n_rm < 0) { printf("*** FAIL: cannot open run log %s\n", run_out); free(rm); return 1; }
        printf("run log : parsed %d per-layer mass line(s) from %s\n", n_rm, run_out);
    }
    printf("----------------------------------------------------------------------\n");

    /* Per-layer eviction resume (env LC_RESUME=FILE, opt-in; Spot-host runs).
     * Each layer that streams CLEAN is appended to FILE (k, nm, ne, codec,
     * Σval, mass — exact decimal strings); on restart those layers are
     * replayed from the record instead of re-read, so the worst-case loss
     * from an eviction is one layer. A straight-through run and a resumed
     * run print byte-identical output (the g-build GA9 invariant). The
     * header pins n + pl_hash: a resume file from another run is REFUSED
     * (a finding, not silently ignored). Failing layers are never recorded. */
    const char *rf_path = getenv("LC_RESUME");
    FILE *rf = NULL;
    int rk_got[32]; uint64_t rk_nm[32], rk_ne[32];
    static char rk_codec[32][4], rk_grand[32][64], rk_mass[32][64];
    for (int k = 0; k < 32; k++) rk_got[k] = 0;
    if (rf_path) {
        FILE *in = fopen(rf_path, "r");
        if (in) {
            char line[512]; uint32_t hn = 0; unsigned long long hh = 0; int hdr_ok = 0;
            if (fgets(line, sizeof line, in) &&
                sscanf(line, "LC_RESUME_V1 n=%u pl_hash=%llx", &hn, &hh) == 2 &&
                hn == mn && hh == (unsigned long long)m_plhash) hdr_ok = 1;
            if (!hdr_ok) {
                printf("*** FAIL: LC_RESUME file %s does not match this run (n/pl_hash header)\n",
                       rf_path);
                fclose(in); return 1;
            }
            while (fgets(line, sizeof line, in)) {
                int k; unsigned long long lnm, lne; char cod[4], gd[64], md[64];
                if (sscanf(line, "k=%d nm=%llu ne=%llu codec=%3s grand=%63s mass=%63s",
                           &k, &lnm, &lne, cod, gd, md) == 6 && k >= 0 && k < 32) {
                    rk_got[k] = 1; rk_nm[k] = lnm; rk_ne[k] = lne;
                    snprintf(rk_codec[k], 4, "%s", cod);
                    snprintf(rk_grand[k], 64, "%s", gd);
                    snprintf(rk_mass[k], 64, "%s", md);
                }
            }
            fclose(in);
        }
        rf = fopen(rf_path, "a");
        if (!rf) { printf("*** FAIL: cannot open LC_RESUME file %s for append\n", rf_path); return 1; }
        if (ftell(rf) == 0) {
            fprintf(rf, "LC_RESUME_V1 n=%u pl_hash=%016llx\n", mn, (unsigned long long)m_plhash);
            fflush(rf); fsync(fileno(rf));
        }
    }

    int hi = last_k; if (maxk < hi) hi = maxk;
    int fails = !plhash_ok + !kw_ok + !geff_ok, checked = 0;
    u192 finalgrand = {{0,0,0}}; int saw_final = 0;
    u192 lmass[32]; int lgot[32];
    for (int k = 0; k < 32; k++) lgot[k] = 0;
    for (int k = 0; k <= hi && k < 32; k++) {
        char p[1024]; snprintf(p,sizeof p,"%s/f1c5_layer_%02d.bin",dir,k);
        FILE *t = fopen(p,"rb"); if (!t) continue; fclose(t);   /* rolling window may have pruned it */
        int is_final = (k == (int)mn);
        if (rk_got[k]) {                                  /* replay a recorded clean layer */
            printf("  k=%2d  nm=%-9llu ne=%-13llu %s  Σval=%s  mass=%s\n", k,
                   (unsigned long long)rk_nm[k], (unsigned long long)rk_ne[k],
                   rk_codec[k], rk_grand[k], rk_mass[k]);
            fflush(stdout);
            if (cfg)
                printf("[scan] k=%2d riders skipped (layer replayed from LC_RESUME record, not re-read)\n", k);
            lmass[k] = u192_dec(rk_mass[k]); lgot[k] = 1; checked++;
            if (is_final) { finalgrand = u192_dec(rk_grand[k]); saw_final = 1; }
            continue;
        }
        u192 g, ms; uint64_t onm = 0, one = 0; int ov2 = 0;
        int r = cfg
              ? lcs_scan_layer(dir, k, mn, mse, m_plhash, b0v, is_final,
                               rp, geff, &g, &ms, &onm, &one, &ov2, cfg, &riders)
              : lc_check_layer(dir, k, mn, mse, m_plhash, b0v, is_final,
                               rp, geff, &g, &ms, &onm, &one, &ov2);
        fails += r; checked++;
        if (!r) {
            char gd[64], md[64]; u192_print(g, gd); u192_print(ms, md);
            printf("  k=%2d  nm=%-9llu ne=%-13llu %s  Σval=%s  mass=%s\n", k,
                   (unsigned long long)onm, (unsigned long long)one, ov2?"v2":"v1", gd, md);
            fflush(stdout);
            if (cfg && riders.census_got[k]) {
                printf("[scan] k=%2d census nm=%llu raw=%llu |", k,
                       (unsigned long long)onm, (unsigned long long)riders.census_raw[k]);
                for (int s = 1; s <= 24; s++)
                    if (riders.census[k][s])
                        printf(" %d:%llu", s, (unsigned long long)riders.census[k][s]);
                printf("\n");
            }
            if (cfg && riders.t6_got[k]) {
                uint64_t tn = 0; u192 tv = {{0,0,0}}; int tovf = 0;
                for (int l = 0; l < 64; l++) {
                    tn += riders.t6_n[k][l];
                    if (u192_add(&tv, riders.t6_v[k][l])) tovf = 1;
                }
                char tvs[64]; u192_print(tv, tvs);
                printf("[scan] k=%2d t6stub(last-marginal; STUB, not QL-6) Σn=%llu Σv=%s"
                       " self-check(Σn==ne,Σv==Σval)=%s n[0..63]=", k,
                       (unsigned long long)tn, tvs,
                       (!tovf && tn == one && u192_eq(tv, g)) ? "ok" : "*MISMATCH*");
                for (int l = 0; l < 64; l++)
                    printf("%s%llu", l ? "," : "", (unsigned long long)riders.t6_n[k][l]);
                printf("\n");
            }
            if (cfg) fflush(stdout);
            lmass[k] = ms; lgot[k] = 1;
            if (rf) {
                fprintf(rf, "k=%d nm=%llu ne=%llu codec=%s grand=%s mass=%s\n",
                        k, (unsigned long long)onm, (unsigned long long)one,
                        ov2?"v2":"v1", gd, md);
                fflush(rf); fsync(fileno(rf));
            }
        }
        if (is_final && !r) { finalgrand = g; saw_final = 1; }
    }
    if (rf) fclose(rf);

    /* orbit-weighted mass vs the run log (§Reading recipe steps 5-6) — the
     * independent full-scale re-derivation of every layer's reported mass. */
    printf("----------------------------------------------------------------------\n");
    printf("  k | orbit-weighted mass (from layer bytes)     | solve.c reported (run.out)                 | match\n");
    printf("----+--------------------------------------------+--------------------------------------------+------\n");
    int mass_cmp = 0, mass_mism = 0;
    for (int k = 0; k < 32; k++) {
        if (!lgot[k]) continue;
        char got[64]; u192_print(lmass[k], got);
        const char *want = (rm && rm[k][0]) ? rm[k] : NULL;
        int ok = want && strcmp(got, want) == 0;
        if (want) { mass_cmp++; if (!ok) mass_mism++; }
        printf(" %2d | %-42s | %-42s | %s\n", k, got, want ? want : "(absent)",
               want ? (ok ? "  ok" : " *FAIL*") : " n/a");
    }
    if (mass_mism) fails += mass_mism;
    if (rm) free(rm);

    printf("======================================================================\n");
    if (saw_final) {
        char g[64]; u192_print(finalgrand, g);
        printf("FINAL LAYER Σvalues = %s\n", g);
        if (mn == 31) {          /* the published count + mod-24 gates are full-31 facts */
            u192 pub = u192_dec(LC_PUBLISHED_COUNT);
            int cnt_ok = u192_eq(finalgrand, pub), mod_ok = (u192_mod(finalgrand,24)==0);
            printf("  vs published |C1∩C2∩C4∩C5| = %s   %s\n", LC_PUBLISHED_COUNT,
                   cnt_ok ? "MATCH" : "*** MISMATCH ***");
            printf("  mod 24 = %u   %s (TR-5 free action)\n", u192_mod(finalgrand,24),
                   mod_ok ? "ok" : "*** FAIL ***");
            if (!cnt_ok || !mod_ok) fails++;
        }
    } else {
        printf("NOTE: final layer k=%u not present (run incomplete or window-pruned) —\n"
               "      the end-to-end published-count check did not fire.\n", mn);
    }
    if (fails==0)
        printf("RESULT: %d layer file(s) internally consistent; headers, pl_hash, layout,\n"
               "        per-entry keys/rids/values, sum invariant, and mask canonicity all\n"
               "        hold; orbit-weighted mass re-derived at every layer%s%s.\n",
               checked,
               mass_cmp ? " and it matches the run log at every compared layer" : "",
               (saw_final && mn==31) ? ", and the final layer sums to the published count" : "");
    else
        printf("RESULT: *** %d FAILURE(S) *** — a finding. Report it; do not patch around it.\n", fails);
    printf("======================================================================\n");
    if (cfg) {   /* rider summary — informational; never changes the exit code */
        int cgot = 0;
        for (int k = 0; k < 32; k++) cgot += riders.census_got[k];
        printf("[scan] census (T7/BL-7): %d layer(s) scanned, per-layer lines above; orbit-size\n", cgot);
        printf("[scan]   divisibility and layer-0/final shapes are enforced by the main checks.\n");
        printf("[scan] NOTE: rider outputs are measurements-in-passing, not attestations; the\n");
        printf("[scan]       attestation surface is exactly the unprefixed output, which is\n");
        printf("[scan]       byte-identical to --check-layers by the scan identity contract.\n");
    }
    return fails ? 1 : 0;
}

static int lc_check_layers(const char *dir, int maxk, const char *run_out) {
    return lc_check_layers_impl(dir, maxk, run_out, NULL);
}

/* ---- self-test: synthesize spec-valid v1 + v2 fixtures, then check them ---- */
static void lc_wr(FILE *f, const void *p, size_t n){ fwrite(p,1,n,f); }
static int lc_selftest(void) {
    printf("verify.c --check-layers-selftest : synthesize v1+v2 fixtures and read them back\n");
    const char *dir = "/tmp/lc_selftest_dir";
    char cmd[256]; snprintf(cmd,sizeof cmd,"rm -rf %s && mkdir -p %s",dir,dir); if(system(cmd)){}
    /* toy instance: n=2, start_exit=0, b0=(1,1,0,0,0) => rad=(1,2,4,4,4), R=4.
     * layer k=1 (rid digit-sum must == 1): two masks {mask1,mask2}, entries with rid∈{1,2}. */
    uint32_t n=2, se=0, pl[2]={1,2}; int b0v[5]={1,1,0,0,0};
    uint32_t rad[5],R; lc_radix(b0v,rad,&R);            /* rad=(1,2,4,4,4) R=4 */
    uint64_t plhash = lc_pl_hash(n,se,pl);
    /* two masks, entries: mask A -> [(last=5,rid=1)], mask B -> [(last=7,rid=1),(last=9,rid=2)] */
    uint32_t masks[2]={0x1,0x2}; uint64_t off[3]={0,1,3}, nm=2, ne=3;
    uint32_t keys[3]={ (5u<<16)|1u, (7u<<16)|1u, (9u<<16)|2u };
    u192 vals[3]={ {{7,0,0}}, {{11,0,0}}, {{13,0,0}} };   /* nonzero; digit-sums: rid1->1, rid2->1 (2/rad? see) */
    /* rid=1: digits over rad(1,2,4,4,4): c4..c0 => 1/4=0..; 1/1(c0)=1 => sum1 ✓. rid=2: 2/2(c1)=1 =>sum1 ✓ */
    unsigned char hd[72]; memset(hd,0,72);
    #define PUT(mag,ver,pADval) do{ memcpy(hd,mag,8); uint32_t v=ver; memcpy(hd+8,&v,4); \
        memcpy(hd+12,&n,4); uint32_t kk=1; memcpy(hd+16,&kk,4); memcpy(hd+20,&se,4); \
        memcpy(hd+24,&plhash,8); memcpy(hd+32,&nm,8); memcpy(hd+40,&ne,8); \
        for(int c=0;c<5;c++){uint32_t t=(uint32_t)b0v[c]; memcpy(hd+48+4*c,&t,4);} \
        uint32_t pd=pADval; memcpy(hd+68,&pd,4);}while(0)

    /* --- v1 file: f1c5_layer_01.bin (raw) --- */
    char path[512];
    PUT("F1C5LAY1",1,0);
    snprintf(path,sizeof path,"%s/f1c5_layer_01.bin",dir); FILE *f=fopen(path,"wb");
    lc_wr(f,hd,72); lc_wr(f,masks,nm*4); lc_wr(f,off,(nm+1)*8);
    lc_wr(f,keys,ne*4); for(uint64_t i=0;i<ne;i++) lc_wr(f,&vals[i],24); fclose(f);

    /* also a spec-valid layer-0 and a manifest so the driver runs end to end */
    { unsigned char h0[72]; memset(h0,0,72); memcpy(h0,"F1C5LAY1",8);
      uint32_t v=1; memcpy(h0+8,&v,4); memcpy(h0+12,&n,4); uint32_t z=0; memcpy(h0+16,&z,4);
      memcpy(h0+20,&se,4); memcpy(h0+24,&plhash,8); uint64_t one=1; memcpy(h0+32,&one,8); memcpy(h0+40,&one,8);
      for(int c=0;c<5;c++){uint32_t t=(uint32_t)b0v[c];memcpy(h0+48+4*c,&t,4);}
      uint32_t m0=0; uint64_t o0[2]={0,1}; uint32_t k0=(se<<16); u192 val1={{1,0,0}};
      snprintf(path,sizeof path,"%s/f1c5_layer_00.bin",dir); FILE *g=fopen(path,"wb");
      lc_wr(g,h0,72); lc_wr(g,&m0,4); lc_wr(g,o0,16); lc_wr(g,&k0,4); lc_wr(g,&val1,24); fclose(g); }
    snprintf(path,sizeof path,"%s/f1c5_manifest.txt",dir); FILE *mf=fopen(path,"w");
    fprintf(mf,"f1c5_manifest_v1\nn=%u\nstart_exit=%u\npl=1,2\npl_hash=%016llx\nb0=1,1,0,0,0\nlast_complete_k=1\n",
            n,se,(unsigned long long)plhash); fclose(mf);

    printf("\n[1] valid v1 fixture:\n");
    int r1 = lc_check_layers(dir, 31, NULL);

    /* --- overwrite layer 1 with a v2 file (same logical content) --- */
    uint32_t BLK=2; uint64_t nblk=(ne+BLK-1)/BLK;   /* =2 blocks: [0,2),[2,3) */
    PUT("F1C5LAY2",2,BLK);
    /* compress each block's keys(4*bn) and vals(24*bn) */
    unsigned char zk[2][256], zv[2][256]; uLongf zkl[2],zvl[2]; uint64_t kidx[3]={0}, vidx[3]={0};
    for(uint64_t b=0;b<nblk;b++){ uint64_t bs=b*BLK, bn=(bs+BLK<=ne)?BLK:ne-bs;
        uint32_t kk[2]; unsigned char vv[2*24]; for(uint64_t j=0;j<bn;j++){ kk[j]=keys[bs+j]; memcpy(vv+j*24,&vals[bs+j],24);}
        zkl[b]=sizeof zk[b]; compress2(zk[b],&zkl[b],(Bytef*)kk,bn*4,6);
        zvl[b]=sizeof zv[b]; compress2(zv[b],&zvl[b],(Bytef*)vv,bn*24,6);
        kidx[b+1]=kidx[b]+zkl[b]; vidx[b+1]=vidx[b]+zvl[b]; }
    snprintf(path,sizeof path,"%s/f1c5_layer_01.bin",dir); f=fopen(path,"wb");
    lc_wr(f,hd,72); lc_wr(f,masks,nm*4); lc_wr(f,off,(nm+1)*8);
    lc_wr(f,kidx,(nblk+1)*8); lc_wr(f,vidx,(nblk+1)*8);
    for(uint64_t b=0;b<nblk;b++) lc_wr(f,zk[b],zkl[b]);
    for(uint64_t b=0;b<nblk;b++) lc_wr(f,zv[b],zvl[b]);
    fclose(f);
    printf("\n[2] valid v2 fixture (same content, per-block zlib):\n");
    int r2 = lc_check_layers(dir, 31, NULL);

    /* --- corruption: zero a value in the v2 file's last value block; must FAIL --- */
    snprintf(path,sizeof path,"%s/f1c5_layer_01.bin",dir);
    /* rebuild v2 with vals[2] set to zero (sum-invariant/nonzero check must catch) */
    u192 badvals[3]; memcpy(badvals,vals,sizeof vals); badvals[2]=(u192){{0,0,0}};
    for(uint64_t b=0;b<nblk;b++){ uint64_t bs=b*BLK, bn=(bs+BLK<=ne)?BLK:ne-bs;
        unsigned char vv[2*24]; for(uint64_t j=0;j<bn;j++) memcpy(vv+j*24,&badvals[bs+j],24);
        zvl[b]=sizeof zv[b]; compress2(zv[b],&zvl[b],(Bytef*)vv,bn*24,6);
        vidx[b+1]=vidx[b]+zvl[b]; }
    f=fopen(path,"wb"); lc_wr(f,hd,72); lc_wr(f,masks,nm*4); lc_wr(f,off,(nm+1)*8);
    lc_wr(f,kidx,(nblk+1)*8); lc_wr(f,vidx,(nblk+1)*8);
    for(uint64_t b=0;b<nblk;b++) lc_wr(f,zk[b],zkl[b]);
    for(uint64_t b=0;b<nblk;b++) lc_wr(f,zv[b],zvl[b]);
    fclose(f);
    printf("\n[3] corrupted v2 fixture (a value zeroed) — MUST be rejected:\n");
    int r3 = lc_check_layers(dir, 31, NULL);

    #undef PUT

    /* =====================================================================
     * ORBIT-WEIGHTED MASS fixtures, on a pair set with a NON-TRIVIAL group:
     * pl = {3,7,11} = pair-orbit 3.0 (TR-11 §2). The 24 pair-perms restrict
     * to the full S3 on these three pairs (geff=6), so a single-bit mask has
     * |stab|=2 and orbit 6/2=3 < geff — exactly the stabilizer-weighting case
     * a trivial fixture would never exercise. Hand-derived expectations:
     *   layer 1: canonical mask 001, Σval=10, |stab|=2, orbit 3 -> mass 30
     *   layer 2: canonical mask 011, Σval=5,  |stab|=2, orbit 3 -> mass 15
     *   layer 3: full mask 111,      Σval=11, |stab|=6, orbit 1 -> mass 11
     * ===================================================================== */
    const char *dir2 = "/tmp/lc_selftest_dir2";
    snprintf(cmd,sizeof cmd,"rm -rf %s && mkdir -p %s",dir2,dir2); if(system(cmd)){}
    uint32_t n3=3, se3=0, pl3[3]={3,7,11}; int b3[5]={1,1,1,0,0};
    /* rad=(1,2,4,8,8), R=8; digit-sum-k rids: k1 in {1,2,4}, k2 in {3,5,6}, k3={7}=R-1 */
    uint64_t ph3 = lc_pl_hash(n3,se3,pl3);

    /* direct orbit-stabilizer assertions (the group math itself, no files) */
    int gs_ok = derive_pair_perms();
    static uint8_t rp3[24][32]; int geff3 = gs_ok ? lc_restrict_perms(pl3,n3,rp3) : -1;
    int cn = 0; int o_bit0 = geff3>0 ? lc_orbit_of(0x1,rp3,geff3,&cn) : 0; int c_bit0 = cn;
    int o_bit1 = geff3>0 ? lc_orbit_of(0x2,rp3,geff3,&cn) : 0; int c_bit1 = cn;
    int o_full = geff3>0 ? lc_orbit_of(0x7,rp3,geff3,&cn) : 0; int c_full = cn;
    int grp_ok = gs_ok && geff3==6 && o_bit0==3 && c_bit0==1     /* |stab|=2: NON-trivial */
                       && o_bit1==3 && c_bit1==0                 /* 010 not canonical */
                       && o_full==1 && c_full==1;                /* |stab|=geff */
    printf("\n[4] group math on pl={3,7,11} (orbit 3.0): geff=%d (want 6), "
           "orbit(001)=%d canon=%d (want 3,1: |stab|=2), orbit(010)=%d canon=%d (want 3,0), "
           "orbit(111)=%d canon=%d (want 1,1: |stab|=6)  =>  %s\n",
           geff3, o_bit0, c_bit0, o_bit1, c_bit1, o_full, c_full,
           grp_ok ? "ok" : "*** FAIL ***");

    /* v1 layer files 0..3 */
    unsigned char h3[72];
    #define PUT3(kk_,nm_,ne_) do{ memset(h3,0,72); memcpy(h3,"F1C5LAY1",8); \
        uint32_t v_=1; memcpy(h3+8,&v_,4); memcpy(h3+12,&n3,4); uint32_t k_=kk_; memcpy(h3+16,&k_,4); \
        memcpy(h3+20,&se3,4); memcpy(h3+24,&ph3,8); uint64_t nm64_=nm_, ne64_=ne_; \
        memcpy(h3+32,&nm64_,8); memcpy(h3+40,&ne64_,8); \
        for(int c=0;c<5;c++){uint32_t t_=(uint32_t)b3[c]; memcpy(h3+48+4*c,&t_,4);} }while(0)
    { PUT3(0,1,1); uint32_t m_=0; uint64_t o_[2]={0,1}; uint32_t k_=(se3<<16); u192 v_={{1,0,0}};
      snprintf(path,sizeof path,"%s/f1c5_layer_00.bin",dir2); FILE *g3=fopen(path,"wb");
      lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,&k_,4); lc_wr(g3,&v_,24); fclose(g3); }
    { PUT3(1,1,2); uint32_t m_=0x1; uint64_t o_[2]={0,2};
      uint32_t ks_[2]={(5u<<16)|1u,(6u<<16)|2u}; u192 vs_[2]={{{7,0,0}},{{3,0,0}}};
      snprintf(path,sizeof path,"%s/f1c5_layer_01.bin",dir2); FILE *g3=fopen(path,"wb");
      lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,ks_,8);
      for(int i=0;i<2;i++) { lc_wr(g3,&vs_[i],24); } fclose(g3); }
    { PUT3(2,1,1); uint32_t m_=0x3; uint64_t o_[2]={0,1};
      uint32_t k_=(1u<<16)|3u; u192 v_={{5,0,0}};
      snprintf(path,sizeof path,"%s/f1c5_layer_02.bin",dir2); FILE *g3=fopen(path,"wb");
      lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,&k_,4); lc_wr(g3,&v_,24); fclose(g3); }
    { PUT3(3,1,2); uint32_t m_=0x7; uint64_t o_[2]={0,2};
      uint32_t ks_[2]={(2u<<16)|7u,(9u<<16)|7u}; u192 vs_[2]={{{2,0,0}},{{9,0,0}}};
      snprintf(path,sizeof path,"%s/f1c5_layer_03.bin",dir2); FILE *g3=fopen(path,"wb");
      lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,ks_,8);
      for(int i=0;i<2;i++) { lc_wr(g3,&vs_[i],24); } fclose(g3); }
    snprintf(path,sizeof path,"%s/f1c5_manifest.txt",dir2); mf=fopen(path,"w");
    fprintf(mf,"f1c5_manifest_v1\nn=%u\nstart_exit=%u\npl=3,7,11\npl_hash=%016llx\nb0=1,1,1,0,0\nlast_complete_k=3\n",
            n3,se3,(unsigned long long)ph3); fclose(mf);
    snprintf(path,sizeof path,"%s/run.out",dir2); mf=fopen(path,"w");
    fprintf(mf,"[f1c5] layer k= 1/3: canonical_masks=1 (of C(3,1)=3) states=2 entries=2 mass=30 elapsed=0.0s\n"
               "[f1c5] layer k= 2/3: canonical_masks=1 (of C(3,2)=3) states=1 entries=1 mass=15 elapsed=0.0s\n"
               "[f1c5] layer k= 3/3: canonical_masks=1 (of C(3,3)=1) states=2 entries=2 mass=11 elapsed=0.0s\n");
    fclose(mf);
    char runout[512]; snprintf(runout,sizeof runout,"%s/run.out",dir2);
    printf("\n[5] orbit-weighted mass fixture (geff=6, |stab|=2 layers) vs its run log — must PASS:\n");
    int r5 = lc_check_layers(dir2, 31, runout);

    /* wrong reported mass (as if orbit weighting were off by the stabilizer) — must FAIL */
    snprintf(path,sizeof path,"%s/run.out",dir2); mf=fopen(path,"w");
    fprintf(mf,"[f1c5] layer k= 1/3: canonical_masks=1 (of C(3,1)=3) states=2 entries=2 mass=60 elapsed=0.0s\n"
               "[f1c5] layer k= 2/3: canonical_masks=1 (of C(3,2)=3) states=1 entries=1 mass=15 elapsed=0.0s\n"
               "[f1c5] layer k= 3/3: canonical_masks=1 (of C(3,3)=1) states=2 entries=2 mass=11 elapsed=0.0s\n");
    fclose(mf);
    printf("\n[6] same fixture vs a run log whose k=1 mass ignores the stabilizer (60 = Σval·geff\n"
           "    instead of Σval·orbit = 30) — the mass compare MUST reject it:\n");
    int r6 = lc_check_layers(dir2, 31, runout);

    /* non-canonical stored mask (010 instead of 001) — canonicity check must FAIL */
    { PUT3(1,1,2); uint32_t m_=0x2; uint64_t o_[2]={0,2};
      uint32_t ks_[2]={(5u<<16)|1u,(6u<<16)|2u}; u192 vs_[2]={{{7,0,0}},{{3,0,0}}};
      snprintf(path,sizeof path,"%s/f1c5_layer_01.bin",dir2); FILE *g3=fopen(path,"wb");
      lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,ks_,8);
      for(int i=0;i<2;i++) { lc_wr(g3,&vs_[i],24); } fclose(g3); }
    printf("\n[7] layer 1 rewritten with NON-CANONICAL mask 010 (min of orbit is 001) — must FAIL:\n");
    int r7 = lc_check_layers(dir2, 31, NULL);
    #undef PUT3

    printf("\n======================================================================\n");
    int ok = (r1==0 && r2==0 && r3!=0 && grp_ok && r5==0 && r6!=0 && r7!=0);
    printf("SELFTEST: v1 pass=%s  v2 pass=%s  corruption caught=%s  group-math=%s\n"
           "          nontrivial-stab mass pass=%s  wrong-mass caught=%s  non-canonical caught=%s\n"
           "          =>  %s\n",
           r1==0?"Y":"N", r2==0?"Y":"N", r3!=0?"Y":"N", grp_ok?"Y":"N",
           r5==0?"Y":"N", r6!=0?"Y":"N", r7!=0?"Y":"N", ok?"PASS":"*** FAIL ***");
    printf("======================================================================\n");
    return ok ? 0 : 1;
}

/* ==========================================================================
 * --scan-layers IMPLEMENTATION  (multi-observable parallel scan driver)
 *
 * See the design/identity-contract comment above the LcScanCfg typedef.
 * Layout facts used here are the published spec's (F1C5_LAYER_FORMAT.md):
 * header 72 B; masks nm*4; off (nm+1)*8; then
 *   v1: keys ne*4, vals ne*24 (raw);
 *   v2: kidx (nblk+1)*8, vidx (nblk+1)*8, key blocks, value blocks, with
 *       kblk_base = 96 + 12*nm + 16*nblk and vblk_base = kblk_base + kidx[nblk].
 * The same facts, from the same document, drive lc_check_layer above; the
 * only thing PHASE 3 changes is WHO reads WHICH bytes, never the arithmetic.
 *
 * Equivalence argument (why lane count cannot change any output):
 *  - every per-entry statistic (grand, the bad_* counters, the t6 stub) is a
 *    sum of per-entry integer terms -> lane partials merge by integer adds
 *    in fixed lane-ascending order;
 *  - the orbit-weighted mass is Sigma_span orbit(span) * (Sigma vals in span).
 *    Spans fully inside one lane are summed-then-multiplied there; spans cut
 *    by lane boundaries are stitched: their nonzero partial sums are merged
 *    ascending-by-span at join, multiplied ONCE by the orbit weight — the
 *    exact sequential sum-then-multiply arithmetic. Zero-sum span closes
 *    contribute 0 in both paths and are elided here;
 *  - the within-span key-ordering check pairs adjacent entries; pairs inside
 *    a lane are checked there, the one pair that straddles each lane
 *    boundary is checked at join (same span => compare), so every pair is
 *    checked exactly once;
 *  - partial sums of non-negative integers are bounded by the sequential
 *    totals, so an overflow counter that is zero sequentially is zero for
 *    every lane split (and any nonzero counter fails BOTH paths).
 * ========================================================================== */

static LcScanCfg lcs_cfg_from_env(void) {
    LcScanCfg c;
    const char *s;
    c.lanes = 8;
    if ((s = getenv("LC_SCAN_LANES"))) { c.lanes = atoi(s); }
    if (c.lanes < 1) c.lanes = 1;
    if (c.lanes > 64) c.lanes = 64;
    long ckb = 4096;
    if ((s = getenv("LC_SCAN_CHUNK_KB"))) { ckb = atol(s); }
    if (ckb < 64) ckb = 64;
    if (ckb > 65536) ckb = 65536;
    c.chunk = ((size_t)ckb * 1024) & ~4095UL;      /* 4 KiB multiple */
    c.odirect = 1;
    if ((s = getenv("LC_SCAN_ODIRECT"))) c.odirect = atoi(s) != 0;
    c.t6stub = 0;
    if ((s = getenv("LC_SCAN_T6STUB"))) c.t6stub = atoi(s) != 0;
    return c;
}

/* -------- per-lane sequential byte stream over [next,end) of one file ------
 * Chunk-sized aligned preads (O_DIRECT-capable) into an aligned bounce
 * buffer, consumed through a plain data buffer. Falls back to buffered
 * reads per-fd if O_DIRECT is refused (e.g. tmpfs); notes go to stderr so
 * stdout identity is never disturbed. */
typedef struct {
    int fd;
    size_t chunk;
    uint64_t next, end;         /* absolute file bytes not yet buffered */
    unsigned char *bounce;      /* aligned, chunk bytes */
    unsigned char *data;        /* plain, cap bytes */
    size_t cap, have, pos;
    int *od_fallback;           /* shared note flag (stderr once) */
} LcsStream;

static int lcs_open(const char *path, int odirect) {
    int fd = -1;
    if (odirect) fd = open(path, O_RDONLY | O_DIRECT);
    if (fd < 0) fd = open(path, O_RDONLY);
    return fd;
}

/* make >= need bytes available at data+pos; 1 ok, 0 short/error */
static int lcs_fill(LcsStream *S, size_t need) {
    if (S->have - S->pos >= need) return 1;
    memmove(S->data, S->data + S->pos, S->have - S->pos);
    S->have -= S->pos; S->pos = 0;
    while (S->have - S->pos < need) {
        if (S->next >= S->end) return 0;
        uint64_t a0   = S->next & ~4095ULL;
        size_t   want = S->chunk;
        ssize_t  got  = pread(S->fd, S->bounce, want, (off_t)a0);
        if (got < 0 && errno == EINVAL) {           /* O_DIRECT refused: fall back */
            int fl = fcntl(S->fd, F_GETFL);
            if (fl >= 0 && (fl & O_DIRECT) && fcntl(S->fd, F_SETFL, fl & ~O_DIRECT) == 0) {
                if (S->od_fallback && !*S->od_fallback) {
                    *S->od_fallback = 1;
                    fprintf(stderr, "[scan] note: O_DIRECT unsupported here; buffered reads\n");
                }
                got = pread(S->fd, S->bounce, want, (off_t)a0);
            }
        }
        if (got <= 0) return 0;
        uint64_t lead = S->next - a0;
        if ((uint64_t)got <= lead) return 0;
        uint64_t usable = (uint64_t)got - lead;
        uint64_t remain = S->end - S->next;
        if (usable > remain) usable = remain;
        if (S->have + usable > S->cap) usable = S->cap - S->have;   /* never true when cap >= need+chunk */
        memcpy(S->data + S->have, S->bounce + lead, usable);
        S->have += usable; S->next += usable;
        if (usable == 0) return 0;
    }
    return 1;
}

/* ------------------------------ mask phase ------------------------------ */
typedef struct {
    uint64_t lo, hi;            /* mask index range [lo,hi) */
    const uint32_t *masks; const uint64_t *off; uint8_t *orbits;
    uint8_t (*rp)[32]; int geff; int k; uint32_t exp_n;
    uint64_t bad_pc, bad_hibit, bad_canon, bad_orb;
    uint64_t mono_off_at, mono_mask_at;   /* UINT64_MAX = none */
    uint64_t census[25], census_raw;      /* T7/BL-7 partials */
    pthread_t tid;
} LcsMaskJob;

static void *lcs_mask_worker(void *arg) {
    LcsMaskJob *J = arg;
    J->mono_off_at = UINT64_MAX; J->mono_mask_at = UINT64_MAX;
    for (uint64_t i = J->lo; i < J->hi; i++) {
        if (J->off[i] > J->off[i+1] && i < J->mono_off_at) J->mono_off_at = i;
        if (i && !(J->masks[i] > J->masks[i-1]) && i < J->mono_mask_at) J->mono_mask_at = i;
        if (__builtin_popcount(J->masks[i]) != J->k) J->bad_pc++;
        if (J->exp_n < 32 && (J->masks[i] >> J->exp_n) != 0) J->bad_hibit++;
        int canon; int ob = lc_orbit_of(J->masks[i], J->rp, J->geff, &canon);
        if (ob == 0) J->bad_orb++;
        if (!canon) J->bad_canon++;
        J->orbits[i] = (uint8_t)ob;
        if (ob >= 1 && ob <= 24 && canon) { J->census[ob]++; J->census_raw += (uint64_t)ob; }
    }
    return NULL;
}

/* ------------------------------ entry phase ----------------------------- */
typedef struct {
    /* geometry (shared, read-only) */
    const char *path; int k, is_final, is_v2; uint32_t exp_n, BLK, R;
    const uint32_t *rad; const int *b0;
    uint64_t nm, ne, nblk;
    const uint64_t *off; const uint8_t *orbits;
    const uint64_t *kidx, *vidx;
    long keys_base, vals_base, kblk_base, vblk_base;
    const LcScanCfg *cfg;
    volatile int *abort_flag;
    int *od_fallback;
    /* lane assignment: block range [blo,bhi) */
    uint64_t blo, bhi;
    /* results */
    u192 grand, mass_closed;
    uint64_t part_mi[2]; u192 part_sum[2]; int nparts;
    uint64_t e_cnt;
    uint64_t bad_last, bad_rid, bad_sum, bad_zero, bad_order, bad_finalrid, ovf, movf;
    uint64_t first_mi, last_mi; uint32_t first_key, last_key; int nonempty;
    uint64_t t6_n[64]; u192 t6_v[64]; uint64_t t6_ovf;
    int fail; char msg[192];
    pthread_t tid;
} LcsLane;

static void lcs_flush_span(LcsLane *L, uint64_t mi, u192 s, uint64_t e0, uint64_t e1) {
    if (u192_zero(s)) return;                       /* zero closes contribute 0 in both paths */
    if (L->off[mi] >= e0 && L->off[mi+1] <= e1) {   /* span fully inside this lane */
        u192 t = s;
        if (u192_mul_small(&t, L->orbits[mi])) L->movf++;
        if (u192_add(&L->mass_closed, t)) L->movf++;
    } else if (L->nparts < 2) {                     /* straddles a lane boundary;
                                                     * only the first and last span
                                                     * of a lane can (proof above) */
        L->part_mi[L->nparts] = mi; L->part_sum[L->nparts] = s;
        L->nparts++;
    }
}

static void *lcs_lane_worker(void *arg) {
    LcsLane *L = arg;
    uint64_t BLKe = L->is_v2 ? L->BLK : 65536;
    uint64_t e0 = L->blo * BLKe, e1 = L->bhi * BLKe;
    if (e1 > L->ne) e1 = L->ne;
    if (e0 >= e1) { L->nonempty = 0; return NULL; }
    L->nonempty = 1;

    /* streams */
    LcsStream KS, VS; memset(&KS, 0, sizeof KS); memset(&VS, 0, sizeof VS);
    size_t kneed, vneed;                            /* max bytes pulled per block */
    if (L->is_v2) {
        uint64_t mk = 0, mv = 0;
        for (uint64_t b = L->blo; b < L->bhi; b++) {
            uint64_t kc = L->kidx[b+1] - L->kidx[b], vc = L->vidx[b+1] - L->vidx[b];
            if (kc > mk) mk = kc;
            if (vc > mv) mv = vc;
        }
        kneed = mk; vneed = mv;
        KS.next = (uint64_t)L->kblk_base + L->kidx[L->blo];
        KS.end  = (uint64_t)L->kblk_base + L->kidx[L->bhi];
        VS.next = (uint64_t)L->vblk_base + L->vidx[L->blo];
        VS.end  = (uint64_t)L->vblk_base + L->vidx[L->bhi];
    } else {
        kneed = (size_t)BLKe * 4; vneed = (size_t)BLKe * 24;
        KS.next = (uint64_t)L->keys_base + 4  * e0;
        KS.end  = (uint64_t)L->keys_base + 4  * e1;
        VS.next = (uint64_t)L->vals_base + 24 * e0;
        VS.end  = (uint64_t)L->vals_base + 24 * e1;
    }
    KS.chunk = VS.chunk = L->cfg->chunk;
    KS.od_fallback = VS.od_fallback = L->od_fallback;
    KS.cap = kneed + KS.chunk + 8192; VS.cap = vneed + VS.chunk + 8192;
    KS.fd = lcs_open(L->path, L->cfg->odirect); VS.fd = lcs_open(L->path, L->cfg->odirect);
    KS.bounce = aligned_alloc(4096, KS.chunk); VS.bounce = aligned_alloc(4096, VS.chunk);
    KS.data = malloc(KS.cap); VS.data = malloc(VS.cap);
    uint32_t *kbuf = malloc((size_t)BLKe * 4 + 8);
    unsigned char *vbuf = malloc((size_t)BLKe * 24 + 8);
    if (KS.fd < 0 || VS.fd < 0 || !KS.bounce || !VS.bounce || !KS.data || !VS.data || !kbuf || !vbuf) {
        snprintf(L->msg, sizeof L->msg, "  k=%2d  *** FAIL: OOM/open in scan lane\n", L->k);
        L->fail = 1; *L->abort_flag = 1; goto out;
    }

    /* initial span: smallest mi with off[mi+1] > e0 (sequential walk state at e0) */
    {
        uint64_t lo = 0, hi = L->nm;                /* find in off[1..nm] */
        while (lo < hi) {
            uint64_t mid = lo + (hi - lo) / 2;
            if (L->off[mid+1] > e0) hi = mid; else lo = mid + 1;
        }
        L->first_mi = lo;
    }
    uint64_t mi = L->first_mi;
    u192 span_sum = {{0,0,0}};
    uint32_t prev_key = 0; int have_prev = 0;
    int first_entry_seen = 0;

    for (uint64_t b = L->blo; b < L->bhi && !L->fail; b++) {
        if (*L->abort_flag) break;                   /* another lane failed */
        uint64_t bstart = b * BLKe;
        uint64_t bn = BLKe; if (bstart + bn > L->ne) bn = L->ne - bstart;
        if (L->is_v2) {
            uLongf kd = (uLongf)(bn * 4), vd = (uLongf)(bn * 24);
            uint64_t kc = L->kidx[b+1] - L->kidx[b], vc = L->vidx[b+1] - L->vidx[b];
            if (!lcs_fill(&KS, kc) ||
                uncompress((Bytef *)kbuf, &kd, KS.data + KS.pos, (uLong)kc) != Z_OK || kd != bn * 4) {
                snprintf(L->msg, sizeof L->msg, "  k=%2d  *** FAIL: key block %llu inflate/size\n",
                         L->k, (unsigned long long)b);
                L->fail = 1; *L->abort_flag = 1; break;
            }
            KS.pos += kc;
            if (!lcs_fill(&VS, vc) ||
                uncompress((Bytef *)vbuf, &vd, VS.data + VS.pos, (uLong)vc) != Z_OK || vd != bn * 24) {
                snprintf(L->msg, sizeof L->msg, "  k=%2d  *** FAIL: val block %llu inflate/size\n",
                         L->k, (unsigned long long)b);
                L->fail = 1; *L->abort_flag = 1; break;
            }
            VS.pos += vc;
        } else {
            if (!lcs_fill(&KS, (size_t)bn * 4) || !lcs_fill(&VS, (size_t)bn * 24)) {
                snprintf(L->msg, sizeof L->msg, "  k=%2d  *** FAIL: short v1 entry read\n", L->k);
                L->fail = 1; *L->abort_flag = 1; break;
            }
            memcpy(kbuf, KS.data + KS.pos, (size_t)bn * 4); KS.pos += (size_t)bn * 4;
            memcpy(vbuf, VS.data + VS.pos, (size_t)bn * 24); VS.pos += (size_t)bn * 24;
        }
        for (uint64_t j = 0; j < bn; j++) {
            uint64_t e = bstart + j;
            while (mi < L->nm && e >= L->off[mi+1]) {   /* close span (nonzero only) */
                lcs_flush_span(L, mi, span_sum, e0, e1);
                span_sum = (u192){{0,0,0}};
                mi++; have_prev = 0;
            }
            uint32_t key = kbuf[j];
            u192 val; memcpy(&val, vbuf + j * 24, 24);
            uint32_t rid = key & 0xffff;
            if (key >> 22) L->bad_last++;
            if (rid >= L->R) { L->bad_rid++; }
            else if (lc_rid_digits(rid, L->b0, L->rad) != L->k) L->bad_sum++;
            if (have_prev && key <= prev_key) L->bad_order++;
            prev_key = key; have_prev = 1;
            if (u192_zero(val)) L->bad_zero++;
            if (L->is_final && rid != L->R - 1) L->bad_finalrid++;
            if (u192_add(&L->grand, val)) L->ovf++;
            if (u192_add(&span_sum, val)) L->ovf++;
            if (!first_entry_seen) { first_entry_seen = 1; L->first_key = key; }
            L->last_key = key; L->last_mi = mi;
            L->e_cnt++;
            if (L->cfg->t6stub) {                    /* T6-slot STUB accumulator */
                int last = (int)((key >> 16) & 63);
                L->t6_n[last]++;
                if (u192_add(&L->t6_v[last], val)) L->t6_ovf++;
            }
        }
    }
    if (!L->fail && first_entry_seen)
        lcs_flush_span(L, mi, span_sum, e0, e1);     /* span containing e1-1 */
out:
    if (KS.fd >= 0) close(KS.fd);
    if (VS.fd >= 0) close(VS.fd);
    free(KS.bounce); free(VS.bounce); free(KS.data); free(VS.data);
    free(kbuf); free(vbuf);
    return NULL;
}

/* --------------------------- per-layer driver --------------------------- */
static int lcs_scan_layer(const char *dir, int k, uint32_t exp_n, uint32_t exp_se,
                          uint64_t exp_plhash, const int exp_b0[5], int is_final,
                          uint8_t rp[24][32], int geff, u192 *grand_out, u192 *mass_out,
                          uint64_t *nm_out, uint64_t *ne_out, int *v2_out,
                          const LcScanCfg *cfg, LcsRiders *rd) {
    char path[1024]; snprintf(path, sizeof path, "%s/f1c5_layer_%02d.bin", dir, k);
    FILE *f = fopen(path, "rb");
    if (!f) { printf("  k=%2d  *** FAIL: cannot open %s\n", k, path); return 1; }

    unsigned char hd[72];
    if (!lc_pread(f, 0, hd, 72)) { printf("  k=%2d  *** FAIL: short header\n", k); fclose(f); return 1; }
    uint32_t version, hn, hk, hse, pad; uint64_t plhash, nm64, ne64; int hb0[5];
    memcpy(&version,hd+8,4); memcpy(&hn,hd+12,4); memcpy(&hk,hd+16,4); memcpy(&hse,hd+20,4);
    memcpy(&plhash,hd+24,8); memcpy(&nm64,hd+32,8); memcpy(&ne64,hd+40,8);
    for (int c=0;c<5;c++){ uint32_t t; memcpy(&t,hd+48+4*c,4); hb0[c]=(int)t; }
    memcpy(&pad,hd+68,4);
    int is_v2 = memcmp(hd,"F1C5LAY2",8)==0, is_v1 = memcmp(hd,"F1C5LAY1",8)==0;

    int fail = 0;
    #define LCF(cond,msg,...) do{ if(!(cond)){ printf("  k=%2d  *** FAIL: " msg "\n",k,##__VA_ARGS__); fail=1; } }while(0)
    LCF(is_v1||is_v2, "bad magic (not F1C5LAY1/2)");
    LCF((is_v1&&version==1)||(is_v2&&version==2), "version %u disagrees with magic", version);
    LCF(hn==exp_n, "header n=%u != manifest %u", hn, exp_n);
    LCF(hk==(uint32_t)k, "header k=%u != filename %d", hk, k);
    LCF(hse==exp_se, "header start_exit=%u != manifest %u", hse, exp_se);
    LCF(plhash==exp_plhash, "header pl_hash=%016llx != recomputed %016llx",
        (unsigned long long)plhash, (unsigned long long)exp_plhash);
    for (int c=0;c<5;c++) LCF(hb0[c]==exp_b0[c], "header b0[%d]=%d != KW %d", c, hb0[c], exp_b0[c]);
    if (fail) { fclose(f); return 1; }

    uint32_t rad[5], R; lc_radix(exp_b0, rad, &R);
    uint64_t nm = nm64, ne = ne64;
    uint32_t BLK = is_v2 ? pad : 0;
    if (is_v2) LCF(BLK>0, "v2 block size (pad field) is zero");

    /* masks[] + off[] — the small tables; stdio like the sequential path */
    uint8_t *orbits = NULL;
    uint64_t *kidx = NULL, *vidx = NULL;
    uint32_t *masks = malloc(nm*4 + 4);
    uint64_t *off   = malloc((nm+1)*8 + 8);
    if (!masks || !off) { printf("  k=%2d  *** FAIL: OOM (nm=%llu)\n", k,(unsigned long long)nm);
                          free(masks); free(off); fclose(f); return 1; }
    long masks_off = 72, off_off = 72 + 4*(long)nm;
    if (!lc_pread(f, masks_off, masks, nm*4) || !lc_pread(f, off_off, off, (nm+1)*8)) {
        printf("  k=%2d  *** FAIL: short masks/off table\n", k); fail=1; goto cleanup; }
    LCF(off[0]==0, "off[0]=%llu != 0", (unsigned long long)off[0]);
    LCF(off[nm]==ne, "off[nm]=%llu != ne=%llu", (unsigned long long)off[nm], (unsigned long long)ne);
    orbits = malloc(nm ? nm : 1);
    if (!orbits) { printf("  k=%2d  *** FAIL: OOM orbit table\n", k); fail=1; goto cleanup; }

    /* mask phase: parallel validation + orbit table + census rider */
    {
        int T = cfg->lanes; if ((uint64_t)T > nm) T = nm ? (int)nm : 1;
        static LcsMaskJob mj[64];
        memset(mj, 0, sizeof mj);
        for (int t = 0; t < T; t++) {
            mj[t].lo = nm * (uint64_t)t / T; mj[t].hi = nm * (uint64_t)(t+1) / T;
            mj[t].masks = masks; mj[t].off = off; mj[t].orbits = orbits;
            mj[t].rp = rp; mj[t].geff = geff; mj[t].k = k; mj[t].exp_n = exp_n;
            if (T > 1) pthread_create(&mj[t].tid, NULL, lcs_mask_worker, &mj[t]);
            else lcs_mask_worker(&mj[t]);
        }
        if (T > 1) for (int t = 0; t < T; t++) pthread_join(mj[t].tid, NULL);
        uint64_t bad_pc=0, bad_hibit=0, bad_canon=0, bad_orb=0;
        uint64_t moff = UINT64_MAX, mmask = UINT64_MAX;
        for (int t = 0; t < T; t++) {
            bad_pc += mj[t].bad_pc; bad_hibit += mj[t].bad_hibit;
            bad_canon += mj[t].bad_canon; bad_orb += mj[t].bad_orb;
            if (mj[t].mono_off_at  < moff)  moff  = mj[t].mono_off_at;
            if (mj[t].mono_mask_at < mmask) mmask = mj[t].mono_mask_at;
        }
        LCF(moff==UINT64_MAX, "off not monotone at %llu", (unsigned long long)moff);
        LCF(mmask==UINT64_MAX, "masks not strictly ascending at %llu", (unsigned long long)mmask);
        LCF(bad_pc==0,    "%llu masks with popcount != k", (unsigned long long)bad_pc);
        LCF(bad_hibit==0, "%llu masks with bits >= n", (unsigned long long)bad_hibit);
        LCF(bad_canon==0, "%llu NON-CANONICAL masks (not the min of their orbit)", (unsigned long long)bad_canon);
        LCF(bad_orb==0,   "%llu masks where orbit-stabilizer failed (|stab| does not divide geff)", (unsigned long long)bad_orb);
        if (is_final && nm==1 && !fail)
            LCF(orbits[0]==1, "final full mask has orbit %d != 1", orbits[0]);
        if (fail) goto cleanup;
        if (rd) {                                    /* T7/BL-7 census rider */
            for (int t = 0; t < T; t++) {
                for (int s = 1; s <= 24; s++) rd->census[k][s] += mj[t].census[s];
                rd->census_raw[k] += mj[t].census_raw;
            }
            rd->census_got[k] = 1;
        }
    }

    /* layer-0 and final-layer shape */
    if (k==0) { LCF(nm==1 && masks[0]==0 && ne==1, "layer 0 must be {mask 0, 1 entry}"); }
    if (is_final) {
        LCF(nm==1, "final layer nm=%llu != 1", (unsigned long long)nm);
        LCF(masks[0]==((exp_n>=32)?0xffffffffu:((1u<<exp_n)-1)), "final mask != 2^n-1");
    }
    if (fail) goto cleanup;

    /* v2 block index */
    long keys_base=0, vals_base=0, kidx_off=0, vidx_off=0, kblk_base=0, vblk_base=0;
    uint64_t nblk=0;
    if (is_v1) { keys_base = off_off + (long)(nm+1)*8; vals_base = keys_base + (long)ne*4; }
    else {
        nblk = ne ? (ne + BLK - 1)/BLK : 0;
        kidx = malloc((nblk+1)*8 + 8); vidx = malloc((nblk+1)*8 + 8);
        kidx_off = off_off + (long)(nm+1)*8; vidx_off = kidx_off + (long)(nblk+1)*8;
        if ((nblk && (!kidx||!vidx)) ||
            !lc_pread(f, kidx_off, kidx, (nblk+1)*8) || !lc_pread(f, vidx_off, vidx, (nblk+1)*8)) {
            printf("  k=%2d  *** FAIL: short kidx/vidx\n", k); fail=1; goto cleanup; }
        LCF(kidx[0]==0 && vidx[0]==0, "kidx/vidx[0] != 0");
        kblk_base = 96 + 12*(long)nm + 16*(long)nblk;
        vblk_base = kblk_base + (long)kidx[nblk];
    }
    if (fail) goto cleanup;

    /* entry phase: partition blocks across lanes, balanced by bytes (v2)
     * or entries (v1), each lane a contiguous block range */
    uint64_t nblocks = is_v1 ? (ne ? (ne+65535)/65536 : 0) : nblk;
    uint64_t e_total = 0;
    u192 grand = {{0,0,0}}, mass = {{0,0,0}};
    uint64_t bad_last=0, bad_rid=0, bad_sum=0, bad_zero=0, bad_order=0, bad_finalrid=0, ovf=0, movf=0;
    {
        int Lc = cfg->lanes; if ((uint64_t)Lc > nblocks) Lc = nblocks ? (int)nblocks : 1;
        static LcsLane ln[64];
        memset(ln, 0, sizeof ln);
        volatile int abort_flag = 0; int od_fb = 0;
        /* cut points */
        uint64_t cuts[65]; cuts[0] = 0; cuts[Lc] = nblocks;
        if (is_v2 && nblocks) {
            uint64_t total = (kidx[nblk] - kidx[0]) + (vidx[nblk] - vidx[0]);
            uint64_t b = 0;
            for (int t = 1; t < Lc; t++) {
                uint64_t want = total / (uint64_t)Lc * (uint64_t)t;
                while (b < nblocks && (kidx[b] - kidx[0]) + (vidx[b] - vidx[0]) < want) b++;
                cuts[t] = b;
            }
        } else {
            for (int t = 1; t < Lc; t++) cuts[t] = nblocks * (uint64_t)t / (uint64_t)Lc;
        }
        for (int t = 0; t < Lc; t++) {
            LcsLane *L = &ln[t];
            L->path = path; L->k = k; L->is_final = is_final; L->is_v2 = is_v2;
            L->exp_n = exp_n; L->BLK = BLK; L->R = R; L->rad = rad; L->b0 = exp_b0;
            L->nm = nm; L->ne = ne; L->nblk = nblk;
            L->off = off; L->orbits = orbits; L->kidx = kidx; L->vidx = vidx;
            L->keys_base = keys_base; L->vals_base = vals_base;
            L->kblk_base = kblk_base; L->vblk_base = vblk_base;
            L->cfg = cfg; L->abort_flag = &abort_flag; L->od_fallback = &od_fb;
            L->blo = cuts[t]; L->bhi = cuts[t+1];
            if (Lc > 1) pthread_create(&L->tid, NULL, lcs_lane_worker, L);
            else lcs_lane_worker(L);
        }
        if (Lc > 1) for (int t = 0; t < Lc; t++) pthread_join(ln[t].tid, NULL);

        int lane_fail = 0;
        for (int t = 0; t < Lc; t++)
            if (ln[t].fail) { fputs(ln[t].msg, stdout); lane_fail = 1; }
        if (lane_fail) { fail = 1; goto cleanup; }

        /* merge — fixed lane-ascending order, integer only */
        for (int t = 0; t < Lc; t++) {
            LcsLane *L = &ln[t];
            e_total += L->e_cnt;
            bad_last += L->bad_last; bad_rid += L->bad_rid; bad_sum += L->bad_sum;
            bad_zero += L->bad_zero; bad_order += L->bad_order;
            bad_finalrid += L->bad_finalrid; ovf += L->ovf; movf += L->movf;
            if (u192_add(&grand, L->grand)) ovf++;
            if (u192_add(&mass, L->mass_closed)) movf++;
        }
        /* stitch boundary-straddling spans: partials arrive ascending by span */
        {
            uint64_t cur_mi = UINT64_MAX; u192 cur = {{0,0,0}};
            for (int t = 0; t < Lc; t++)
                for (int p = 0; p < ln[t].nparts; p++) {
                    uint64_t mi = ln[t].part_mi[p];
                    if (mi == cur_mi) { if (u192_add(&cur, ln[t].part_sum[p])) ovf++; }
                    else {
                        if (cur_mi != UINT64_MAX) {
                            u192 x = cur;
                            if (u192_mul_small(&x, orbits[cur_mi])) movf++;
                            if (u192_add(&mass, x)) movf++;
                        }
                        cur_mi = mi; cur = ln[t].part_sum[p];
                    }
                }
            if (cur_mi != UINT64_MAX) {
                u192 x = cur;
                if (u192_mul_small(&x, orbits[cur_mi])) movf++;
                if (u192_add(&mass, x)) movf++;
            }
        }
        /* the one key-order pair that straddles each lane boundary */
        {
            int prev = -1;
            for (int t = 0; t < Lc; t++) {
                if (!ln[t].nonempty || ln[t].e_cnt == 0) continue;
                if (prev >= 0 && ln[t].first_mi == ln[prev].last_mi &&
                    ln[t].first_key <= ln[prev].last_key) bad_order++;
                prev = t;
            }
        }
        /* t6 stub rider — lane-ascending merge; an overflow (impossible for
         * real layers, partials are bounded by grand) would surface as a
         * *MISMATCH* in the printed Σv==Σval self-check */
        if (rd && cfg->t6stub) {
            for (int t = 0; t < Lc; t++)
                for (int l = 0; l < 64; l++) {
                    rd->t6_n[k][l] += ln[t].t6_n[l];
                    u192_add(&rd->t6_v[k][l], ln[t].t6_v[l]);
                }
            rd->t6_got[k] = 1;
        }
    }
    LCF(e_total==ne, "streamed %llu entries != ne=%llu", (unsigned long long)e_total,(unsigned long long)ne);
    LCF(bad_last==0,  "%llu entries with nonzero key bits 22-31", (unsigned long long)bad_last);
    LCF(bad_rid==0,   "%llu entries with rid >= R", (unsigned long long)bad_rid);
    LCF(bad_sum==0,   "%llu entries where rid digit-sum != k (SUM INVARIANT)", (unsigned long long)bad_sum);
    LCF(bad_order==0, "%llu non-ascending keys within a mask span", (unsigned long long)bad_order);
    LCF(bad_zero==0,  "%llu zero values", (unsigned long long)bad_zero);
    LCF(ovf==0,       "192-bit overflow summing values");
    LCF(movf==0,      "192-bit overflow in orbit-weighted mass");
    if (is_final) LCF(bad_finalrid==0, "%llu final-layer entries with rid != R-1", (unsigned long long)bad_finalrid);
    if (grand_out) *grand_out = grand;
    if (mass_out)  *mass_out  = mass;
    if (nm_out) *nm_out = nm;
    if (ne_out) *ne_out = ne;
    if (v2_out) *v2_out = is_v2;
cleanup:
    free(orbits); free(masks); free(off); free(kidx); free(vidx); fclose(f);
    #undef LCF
    return fail;
}

/* ---- --scan-selftest: fixtures + old-vs-new byte-identity, in-process ----
 * Builds spec-valid fixtures (multi-span multi-block v1+v2 with a trivial
 * group; the nontrivial-stabilizer geff=6 mass fixture; a corrupted file),
 * then re-executes THIS binary in both modes and compares: for every lane
 * count, --scan-layers stdout minus "[scan] " lines must be byte-identical
 * to --check-layers stdout, scan output must be lane-count-invariant, and
 * exit codes must agree (including on the corrupt fixture). */
static char *lcs_slurp(const char *p, size_t *n) {
    FILE *f = fopen(p, "rb"); if (!f) return NULL;
    fseek(f, 0, SEEK_END); long sz = ftell(f); fseek(f, 0, SEEK_SET);
    char *b = malloc(sz + 1); if (b && fread(b, 1, sz, f) != (size_t)sz) { free(b); b = NULL; }
    fclose(f); if (b) { b[sz] = 0; if (n) *n = (size_t)sz; }
    return b;
}
/* drop lines by prefix: pfx="[scan] " -> the attestation surface;
 * pfx="[scan] multi-observable" -> drop only the config banner, the one
 * line that legitimately depends on the lane count */
static char *lcs_strip_pfx(const char *s, const char *pfx, size_t *n) {
    size_t len = strlen(s), pl = strlen(pfx);
    char *o = malloc(len + 1); size_t w = 0;
    const char *p = s;
    while (*p) {
        const char *e = strchr(p, '\n'); e = e ? e + 1 : p + strlen(p);
        if (strncmp(p, pfx, pl) != 0) { memcpy(o + w, p, e - p); w += e - p; }
        p = e;
    }
    o[w] = 0; if (n) *n = w;
    return o;
}
/* Build a shell command into cmd[], REFUSING to run a truncated one.
 *
 * WHY THIS IS NOT COSMETIC. The strings below are `system()` arguments. A silently
 * truncated command still runs — it just runs something else — and the most likely
 * "something else" is a redirect that lost its target, so the comparison downstream
 * reads a stale or empty file. That is a PASS reported for a test that never ran,
 * which is the one failure mode --scan-selftest exists to rule out. A verifier that
 * can lie about its own execution is worse than no verifier.
 *
 * cmd[] is sized above the provable worst case (exe up to 1023 + two 1199-byte paths
 * + a 1299-byte redirect target + literals is under 4.8 KB), so truncation should be
 * unreachable. The check is what makes a future edit that widens those bounds fail
 * LOUDLY instead of quietly — the buffer size is the fix, the check is the ratchet.
 *
 * FOUND BY THE PRE-PUSH COMPILE GATE, 2026-08-07: six -Wformat-truncation warnings
 * against verify.c's zero-warning baseline, on the merge that landed --scan-layers.
 * Neither doc_gates nor tests.py sees compiler output, so nothing earlier could have
 * caught it. */
#define LCS_CMD(...) do { \
        int lcs_n_ = snprintf(cmd, sizeof cmd, __VA_ARGS__); \
        if (lcs_n_ < 0 || (size_t)lcs_n_ >= sizeof cmd) { \
            fprintf(stderr, "verify.c --scan-selftest: refusing a truncated command " \
                            "(%d bytes needed, %zu available) — aborting rather than " \
                            "running something else\n", lcs_n_, sizeof cmd); \
            return 1; \
        } \
    } while (0)

static int lcs_selftest(const char *argv0) {
    printf("verify.c --scan-selftest : parallel scan vs sequential reader byte-identity\n");
    char exe[1024]; ssize_t el = readlink("/proc/self/exe", exe, sizeof exe - 1);
    if (el > 0) exe[el] = 0; else snprintf(exe, sizeof exe, "%s", argv0);
    unsetenv("LC_RESUME");
    const char *dir = "/tmp/lcs_scan_selftest";
    char cmd[8192], path[1200];
    LCS_CMD("rm -rf %s && mkdir -p %s/a1 %s/a2 %s/b %s/c", dir, dir, dir, dir, dir);
    if (system(cmd)) {}

    /* ---- fixture A: n=2, pl={1,2} (both single-bit masks canonical =>
     * multi-span layers), 22 entries over 2 spans; v1 in a1/, v2 (BLK=4,
     * 6 blocks) in a2/ — lane cuts land both mid-span and mid-block. ---- */
    uint32_t n = 2, se = 0, pl[2] = {1, 2}; int b0v[5] = {1, 1, 0, 0, 0};
    uint64_t plhash = lc_pl_hash(n, se, pl);
    enum { NE = 22 };
    uint32_t masks[2] = {0x1, 0x2}; uint64_t off[3] = {0, 12, NE}, nm = 2, ne = NE;
    uint32_t keys[NE]; u192 vals[NE];
    for (int i = 0; i < 12; i++) { keys[i]    = ((uint32_t)(i/2 + 1) << 16) | (uint32_t)(i%2 + 1); }
    for (int i = 0; i < 10; i++) { keys[12+i] = ((uint32_t)(i/2 + 1) << 16) | (uint32_t)(i%2 + 1); }
    for (int i = 0; i < NE; i++) vals[i] = (u192){{(uint64_t)(3*i + 7), 0, 0}};
    unsigned char hd[72];
    #define SPUT(mag,ver,kk,padv,nmv,nev) do{ memset(hd,0,72); memcpy(hd,mag,8); \
        uint32_t v_=ver; memcpy(hd+8,&v_,4); memcpy(hd+12,&n,4); uint32_t k_=kk; memcpy(hd+16,&k_,4); \
        memcpy(hd+20,&se,4); memcpy(hd+24,&plhash,8); uint64_t a_=nmv,b_=nev; \
        memcpy(hd+32,&a_,8); memcpy(hd+40,&b_,8); \
        for(int c=0;c<5;c++){uint32_t t_=(uint32_t)b0v[c]; memcpy(hd+48+4*c,&t_,4);} \
        uint32_t p_=padv; memcpy(hd+68,&p_,4);}while(0)
    for (int which = 0; which < 2; which++) {
        const char *sub = which ? "a2" : "a1";
        /* layer 0 (v1 in both dirs — mixed-format dirs don't occur in real
         * runs, but the reader treats each file by its own magic) */
        SPUT("F1C5LAY1", 1, 0, 0, 1, 1);
        snprintf(path, sizeof path, "%s/%s/f1c5_layer_00.bin", dir, sub);
        FILE *g = fopen(path, "wb");
        { uint32_t m0=0; uint64_t o0[2]={0,1}; uint32_t k0=(se<<16); u192 v1={{1,0,0}};
          lc_wr(g,hd,72); lc_wr(g,&m0,4); lc_wr(g,o0,16); lc_wr(g,&k0,4); lc_wr(g,&v1,24); }
        fclose(g);
        snprintf(path, sizeof path, "%s/%s/f1c5_layer_01.bin", dir, sub);
        g = fopen(path, "wb");
        if (!which) {                                 /* v1 raw */
            SPUT("F1C5LAY1", 1, 1, 0, nm, ne);
            lc_wr(g,hd,72); lc_wr(g,masks,nm*4); lc_wr(g,off,(nm+1)*8);
            lc_wr(g,keys,ne*4); for (uint64_t i=0;i<ne;i++) lc_wr(g,&vals[i],24);
        } else {                                      /* v2, BLK=4 => 6 blocks */
            uint32_t BLK = 4; uint64_t nblk = (ne + BLK - 1) / BLK;
            SPUT("F1C5LAY2", 2, 1, BLK, nm, ne);
            unsigned char zk[8][256], zv[8][512]; uLongf zkl[8], zvl[8];
            uint64_t kidx[9] = {0}, vidx[9] = {0};
            for (uint64_t b = 0; b < nblk; b++) {
                uint64_t bs = b*BLK, bn = (bs+BLK<=ne)?BLK:ne-bs;
                uint32_t kk[4]; unsigned char vv[4*24];
                for (uint64_t j = 0; j < bn; j++) { kk[j]=keys[bs+j]; memcpy(vv+j*24,&vals[bs+j],24); }
                zkl[b]=sizeof zk[b]; compress2(zk[b],&zkl[b],(Bytef*)kk,bn*4,6);
                zvl[b]=sizeof zv[b]; compress2(zv[b],&zvl[b],(Bytef*)vv,bn*24,6);
                kidx[b+1]=kidx[b]+zkl[b]; vidx[b+1]=vidx[b]+zvl[b];
            }
            lc_wr(g,hd,72); lc_wr(g,masks,nm*4); lc_wr(g,off,(nm+1)*8);
            lc_wr(g,kidx,(nblk+1)*8); lc_wr(g,vidx,(nblk+1)*8);
            for (uint64_t b=0;b<nblk;b++) lc_wr(g,zk[b],zkl[b]);
            for (uint64_t b=0;b<nblk;b++) lc_wr(g,zv[b],zvl[b]);
        }
        fclose(g);
        snprintf(path, sizeof path, "%s/%s/f1c5_manifest.txt", dir, sub);
        g = fopen(path, "w");
        fprintf(g, "f1c5_manifest_v1\nn=%u\nstart_exit=%u\npl=1,2\npl_hash=%016llx\nb0=1,1,0,0,0\nlast_complete_k=1\n",
                n, se, (unsigned long long)plhash);
        fclose(g);
    }

    /* ---- fixture B: the nontrivial-stabilizer mass fixture (n=3,
     * pl={3,7,11}, geff=6, masses 30/15/11) with its run.out ---- */
    {
        uint32_t n3=3, se3=0; int b3[5]={1,1,1,0,0};
        uint32_t pl3[3]={3,7,11}; uint64_t ph3 = lc_pl_hash(n3,se3,pl3);
        unsigned char h3[72];
        #define SPUT3(kk_,nm_,ne_) do{ memset(h3,0,72); memcpy(h3,"F1C5LAY1",8); \
            uint32_t v_=1; memcpy(h3+8,&v_,4); memcpy(h3+12,&n3,4); uint32_t k_=kk_; memcpy(h3+16,&k_,4); \
            memcpy(h3+20,&se3,4); memcpy(h3+24,&ph3,8); uint64_t a_=nm_,b_=ne_; \
            memcpy(h3+32,&a_,8); memcpy(h3+40,&b_,8); \
            for(int c=0;c<5;c++){uint32_t t_=(uint32_t)b3[c]; memcpy(h3+48+4*c,&t_,4);} }while(0)
        FILE *g3;
        { SPUT3(0,1,1); uint32_t m_=0; uint64_t o_[2]={0,1}; uint32_t k_=(se3<<16); u192 v_={{1,0,0}};
          snprintf(path,sizeof path,"%s/b/f1c5_layer_00.bin",dir); g3=fopen(path,"wb");
          lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,&k_,4); lc_wr(g3,&v_,24); fclose(g3); }
        { SPUT3(1,1,2); uint32_t m_=0x1; uint64_t o_[2]={0,2};
          uint32_t ks_[2]={(5u<<16)|1u,(6u<<16)|2u}; u192 vs_[2]={{{7,0,0}},{{3,0,0}}};
          snprintf(path,sizeof path,"%s/b/f1c5_layer_01.bin",dir); g3=fopen(path,"wb");
          lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,ks_,8);
          for(int i=0;i<2;i++) lc_wr(g3,&vs_[i],24);
          fclose(g3); }
        { SPUT3(2,1,1); uint32_t m_=0x3; uint64_t o_[2]={0,1};
          uint32_t k_=(1u<<16)|3u; u192 v_={{5,0,0}};
          snprintf(path,sizeof path,"%s/b/f1c5_layer_02.bin",dir); g3=fopen(path,"wb");
          lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,&k_,4); lc_wr(g3,&v_,24); fclose(g3); }
        { SPUT3(3,1,2); uint32_t m_=0x7; uint64_t o_[2]={0,2};
          uint32_t ks_[2]={(2u<<16)|7u,(9u<<16)|7u}; u192 vs_[2]={{{2,0,0}},{{9,0,0}}};
          snprintf(path,sizeof path,"%s/b/f1c5_layer_03.bin",dir); g3=fopen(path,"wb");
          lc_wr(g3,h3,72); lc_wr(g3,&m_,4); lc_wr(g3,o_,16); lc_wr(g3,ks_,8);
          for(int i=0;i<2;i++) lc_wr(g3,&vs_[i],24);
          fclose(g3); }
        snprintf(path,sizeof path,"%s/b/f1c5_manifest.txt",dir); g3=fopen(path,"w");
        fprintf(g3,"f1c5_manifest_v1\nn=%u\nstart_exit=%u\npl=3,7,11\npl_hash=%016llx\nb0=1,1,1,0,0\nlast_complete_k=3\n",
                n3,se3,(unsigned long long)ph3); fclose(g3);
        snprintf(path,sizeof path,"%s/b/run.out",dir); g3=fopen(path,"w");
        fprintf(g3,"[f1c5] layer k= 1/3: canonical_masks=1 (of C(3,1)=3) states=2 entries=2 mass=30 elapsed=0.0s\n"
                   "[f1c5] layer k= 2/3: canonical_masks=1 (of C(3,2)=3) states=1 entries=1 mass=15 elapsed=0.0s\n"
                   "[f1c5] layer k= 3/3: canonical_masks=1 (of C(3,3)=1) states=2 entries=2 mass=11 elapsed=0.0s\n");
        fclose(g3);
        #undef SPUT3
    }

    /* ---- fixture C: fixture A v1 with one value zeroed — must FAIL both ---- */
    {
        snprintf(cmd, sizeof cmd, "cp %s/a1/f1c5_layer_00.bin %s/a1/f1c5_manifest.txt %s/c/", dir, dir, dir);
        if (system(cmd)) {}
        SPUT("F1C5LAY1", 1, 1, 0, nm, ne);
        u192 bad[NE]; memcpy(bad, vals, sizeof vals); bad[17] = (u192){{0,0,0}};
        snprintf(path, sizeof path, "%s/c/f1c5_layer_01.bin", dir);
        FILE *g = fopen(path, "wb");
        lc_wr(g,hd,72); lc_wr(g,masks,nm*4); lc_wr(g,off,(nm+1)*8);
        lc_wr(g,keys,ne*4); for (uint64_t i=0;i<ne;i++) lc_wr(g,&bad[i],24);
        fclose(g);
    }
    #undef SPUT

    /* ---- run both modes, compare ---- */
    int ok = 1;
    setenv("LC_SCAN_CHUNK_KB", "64", 1);              /* small chunks: force many refills */
    setenv("LC_SCAN_T6STUB", "1", 1);
    const char *cases[3][2] = { {"a1", NULL}, {"a2", NULL}, {"b", "run.out"} };
    for (int c = 0; c < 3; c++) {
        char ref[1200], refout[1300];
        snprintf(ref, sizeof ref, "%s/%s", dir, cases[c][0]);
        snprintf(refout, sizeof refout, "%s/ref_%s.out", dir, cases[c][0]);
        if (cases[c][1])
            LCS_CMD("%s --check-layers %s 31 %s/%s > %s", exe, ref, ref, cases[c][1], refout);
        else
            LCS_CMD("%s --check-layers %s 31 > %s", exe, ref, refout);
        int rc_ref = system(cmd);
        char *refbuf = lcs_slurp(refout, NULL);
        char *scan1 = NULL;
        for (int lanes = 1; lanes <= 3; lanes++) {
            char lb[16], so[1300];
            snprintf(lb, sizeof lb, "%d", lanes); setenv("LC_SCAN_LANES", lb, 1);
            snprintf(so, sizeof so, "%s/scan_%s_%d.out", dir, cases[c][0], lanes);
            if (cases[c][1])
                LCS_CMD("%s --scan-layers %s 31 %s/%s > %s", exe, ref, ref, cases[c][1], so);
            else
                LCS_CMD("%s --scan-layers %s 31 > %s", exe, ref, so);
            int rc_scan = system(cmd);
            char *sbuf = lcs_slurp(so, NULL);
            if (!refbuf || !sbuf || rc_ref != rc_scan) { ok = 0; free(sbuf); continue; }
            char *filt = lcs_strip_pfx(sbuf, "[scan] ", NULL);
            char *nobanner = lcs_strip_pfx(sbuf, "[scan] multi-observable", NULL);
            int identical = (strcmp(filt, refbuf) == 0);
            int laneinv = 1;
            if (lanes == 1) { scan1 = nobanner; nobanner = NULL; }
            else laneinv = scan1 && nobanner && (strcmp(scan1, nobanner) == 0);
            printf("  [%s lanes=%d] rc=%d==%d  filtered==sequential: %s  lane-invariant: %s\n",
                   cases[c][0], lanes, rc_scan, rc_ref,
                   identical ? "YES" : "*** NO ***", laneinv ? "YES" : "*** NO ***");
            if (!identical || !laneinv) ok = 0;
            free(filt); free(nobanner); free(sbuf);
        }
        free(scan1); free(refbuf);
    }
    /* corrupt fixture: both must FAIL (rc!=0); text may differ by design */
    {
        char cdir[1200]; snprintf(cdir, sizeof cdir, "%s/c", dir);
        LCS_CMD("%s --check-layers %s 31 > %s/ref_c.out", exe, cdir, dir);
        int r1 = system(cmd);
        setenv("LC_SCAN_LANES", "3", 1);
        LCS_CMD("%s --scan-layers %s 31 > %s/scan_c.out", exe, cdir, dir);
        int r2 = system(cmd);
        printf("  [c corrupt] sequential rc!=0: %s  scan rc!=0: %s\n",
               r1 ? "YES" : "*** NO ***", r2 ? "YES" : "*** NO ***");
        if (!r1 || !r2) ok = 0;
    }
    printf("SCAN-SELFTEST: %s\n", ok ? "PASS" : "*** FAIL ***");
    return ok ? 0 : 1;
}
#undef LCS_CMD   /* scoped to lcs_selftest: it hardcodes the name `cmd` and returns 1 */

/* ==========================================================================
 * G-LADDER / T-LADDER CHECKERS
 *   --check-g-ladder FDIR GDIR [max_k]
 *   --check-t-ladder FDIR TDIR [max_k]
 *   --check-gt-selftest
 *
 * Written AGAINST documentation/GT_LADDER_FORMAT.md (published first, this
 * reader second — the same two-step discipline as --check-layers and the
 * one that surfaced F-3) and NOTHING from solve.c: the group, the pair
 * table, the budget radices, and both identities are re-derived here from
 * the published definitions, sharing only this file's already-independent
 * machinery (derive_pair_perms / lc_restrict_perms / lc_orbit_of / u192).
 *
 * What is verified, per the spec's §Invariants:
 *   g  structural: F1C5GLY1/2 magic+version, g_manifest_v1, header fields vs
 *      the manifest, v1/v2 file-size formulas, masks/off layout, canonicity,
 *      per-entry key packing / ascending order / rid < R / SUM INVARIANT /
 *      nonzero values, the stored-domain rule (last in the mask's
 *      pair-element set; start_exit at k=0), the exact seed layer n (2n
 *      sorted pair elements, rid = R-1, all values 1) and layer 0 (anchor
 *      singleton).
 *   g  identity: the f*g CUT IDENTITY at EVERY layer — sum over the layer of
 *      orbit(mask) * f(s)*g(s) (two-pointer key merge per mask; entries
 *      present in only one ladder pair with 0) == N, where N is re-derived
 *      from the f ladder's final-layer value bytes and, at full-31, must
 *      also equal the published count.
 *   t  structural: F1C5TLY1/2 magic+version, t_manifest_v1, GEOMETRY
 *      BYTE-IDENTICAL to the f layer (masks, off, keys) at every layer,
 *      every value >= 1, layer-n values exactly 1, layer-0 anchor singleton.
 *   t  identity: M_j (orbit-weighted f masses = # valid depth-j prefixes)
 *      re-derived from the f ladder's bytes, M_0 == 1, and at EVERY layer
 *      sum orbit(mask) * f(s)*t(s) == S_k = sum_{j>=k} M_j — the unfolded
 *      backward recurrence t(s) = 1 + sum_c t(s.c) checked layer-to-layer
 *      (S_k = S_{k+1} + M_k) — plus t(root) == S_0 printed and checked.
 *
 * Any mismatch is a FINDING (GT_LADDER_FORMAT.md: report it, do not patch
 * around it). Entry-streaming; per-mask spans are buffered (a span is at
 * most 64*R entries by the key packing, ~11 MB worst-case at full-31), so
 * memory is O(nm + 64*R) per open layer. Like --check-layers this is a
 * campaign-VM tool for real ladders; the selftest runs anywhere at ~zero
 * cost on synthetic fixtures.
 * ========================================================================== */

/* ---- sequential layer-entry cursor (v1 + v2), spec-driven ---- */
typedef struct {
    FILE *f; char lab; int k;
    int is_v2; uint32_t BLK;
    uint64_t nm, ne, nblk;
    uint32_t *masks; uint64_t *off, *kidx, *vidx;
    long keys_base, vals_base, kblk_base, vblk_base;
    uint32_t *kbuf; unsigned char *vbuf, *zbuf;
    uint64_t e, bstart, bn;
} GtCur;

static void gt_close(GtCur *c) {
    if (c->f) fclose(c->f);
    free(c->masks); free(c->off); free(c->kidx); free(c->vidx);
    free(c->kbuf); free(c->vbuf); free(c->zbuf);
    memset(c, 0, sizeof *c);
}

/* open + validate header/masks/off/index against the spec; 0 ok, 1 fail. */
static int gt_open(const char *dir, const char *pfx, const char *magic7, char lab,
                   int k, uint32_t exp_n, uint32_t exp_se, uint64_t exp_plhash,
                   const int exp_b0[5], GtCur *c) {
    memset(c, 0, sizeof *c);
    c->lab = lab; c->k = k;
    char path[1024]; snprintf(path, sizeof path, "%s/%s_layer_%02d.bin", dir, pfx, k);
    c->f = fopen(path, "rb");
    if (!c->f) { printf("  [%c] k=%2d  *** FAIL: cannot open %s\n", lab, k, path); return 1; }
    int fail = 0;
    #define GTF(cond,msg,...) do{ if(!(cond)){ printf("  [%c] k=%2d  *** FAIL: " msg "\n", lab, k, ##__VA_ARGS__); fail=1; } }while(0)
    unsigned char hd[72];
    if (!lc_pread(c->f, 0, hd, 72)) { GTF(0, "short header"); gt_close(c); return 1; }
    uint32_t version, hn, hk, hse, pad; uint64_t plhash, nm64, ne64;
    memcpy(&version,hd+8,4); memcpy(&hn,hd+12,4); memcpy(&hk,hd+16,4); memcpy(&hse,hd+20,4);
    memcpy(&plhash,hd+24,8); memcpy(&nm64,hd+32,8); memcpy(&ne64,hd+40,8);
    memcpy(&pad,hd+68,4);
    int is_v1 = memcmp(hd, magic7, 7)==0 && hd[7]=='1';
    int is_v2 = memcmp(hd, magic7, 7)==0 && hd[7]=='2';
    GTF(is_v1||is_v2, "bad magic (want %.7s1/2)", magic7);
    GTF((is_v1&&version==1)||(is_v2&&version==2), "version %u disagrees with magic", version);
    GTF(hn==exp_n, "header n=%u != expected %u", hn, exp_n);
    GTF(hk==(uint32_t)k, "header k=%u != filename %d", hk, k);
    GTF(hse==exp_se, "header start_exit=%u != expected %u", hse, exp_se);
    GTF(plhash==exp_plhash, "header pl_hash=%016llx != recomputed %016llx",
        (unsigned long long)plhash, (unsigned long long)exp_plhash);
    for (int d=0; d<5; d++) { uint32_t t; memcpy(&t,hd+48+4*d,4);
        GTF((int)t==exp_b0[d], "header b0[%d]=%u != expected %d", d, t, exp_b0[d]); }
    if (is_v1) GTF(pad==0, "v1 pad=%u != 0", pad);
    if (is_v2) GTF(pad>0, "v2 block size (pad field) is zero");
    if (fail) { gt_close(c); return 1; }
    c->is_v2 = is_v2; c->BLK = is_v2 ? pad : 65536;
    c->nm = nm64; c->ne = ne64;
    c->masks = malloc(c->nm*4 + 4);
    c->off   = malloc((c->nm+1)*8);
    if (!c->masks || !c->off) { GTF(0, "OOM masks/off (nm=%llu)", (unsigned long long)c->nm);
                                gt_close(c); return 1; }
    long off_off = 72 + 4*(long)c->nm;
    if (!lc_pread(c->f, 72, c->masks, c->nm*4) ||
        !lc_pread(c->f, off_off, c->off, (c->nm+1)*8)) {
        GTF(0, "short masks/off table"); gt_close(c); return 1; }
    GTF(c->off[0]==0, "off[0]=%llu != 0", (unsigned long long)c->off[0]);
    GTF(c->off[c->nm]==c->ne, "off[nm]=%llu != ne=%llu",
        (unsigned long long)c->off[c->nm], (unsigned long long)c->ne);
    for (uint64_t i=0; i<c->nm && !fail; i++) {
        if (c->off[i] > c->off[i+1]) GTF(0, "off not monotone at %llu", (unsigned long long)i);
        if (i && c->masks[i] <= c->masks[i-1]) GTF(0, "masks not strictly ascending at %llu", (unsigned long long)i);
    }
    if (fail) { gt_close(c); return 1; }
    fseek(c->f, 0, SEEK_END);
    long fsz = ftell(c->f);
    if (is_v1) {
        c->keys_base = off_off + (long)(c->nm+1)*8;
        c->vals_base = c->keys_base + (long)c->ne*4;
        GTF(fsz == (long)(80 + 12*c->nm + 28*c->ne), "v1 file size %ld != spec %llu",
            fsz, (unsigned long long)(80 + 12*c->nm + 28*c->ne));
    } else {
        c->nblk = c->ne ? (c->ne + c->BLK - 1)/c->BLK : 0;
        c->kidx = malloc((c->nblk+1)*8);
        c->vidx = malloc((c->nblk+1)*8);
        long kidx_off = off_off + (long)(c->nm+1)*8, vidx_off = kidx_off + (long)(c->nblk+1)*8;
        if (!c->kidx || !c->vidx ||
            !lc_pread(c->f, kidx_off, c->kidx, (c->nblk+1)*8) ||
            !lc_pread(c->f, vidx_off, c->vidx, (c->nblk+1)*8)) {
            GTF(0, "short kidx/vidx"); gt_close(c); return 1; }
        GTF(c->kidx[0]==0 && c->vidx[0]==0, "kidx/vidx[0] != 0");
        for (uint64_t b=0; b<c->nblk && !fail; b++)
            if (c->kidx[b+1]<c->kidx[b] || c->vidx[b+1]<c->vidx[b])
                GTF(0, "kidx/vidx not monotone at block %llu", (unsigned long long)b);
        c->kblk_base = 96 + 12*(long)c->nm + 16*(long)c->nblk;
        c->vblk_base = c->kblk_base + (long)c->kidx[c->nblk];
        GTF(fsz == c->vblk_base + (long)c->vidx[c->nblk], "v2 file size %ld != spec %ld",
            fsz, c->vblk_base + (long)c->vidx[c->nblk]);
    }
    if (fail) { gt_close(c); return 1; }
    c->kbuf = malloc((size_t)c->BLK*4);
    c->vbuf = malloc((size_t)c->BLK*24);
    c->zbuf = is_v2 ? malloc(compressBound(24u*c->BLK)+64) : NULL;
    if (!c->kbuf || !c->vbuf || (is_v2 && !c->zbuf)) {
        GTF(0, "OOM stream buffers"); gt_close(c); return 1; }
    #undef GTF
    return 0;
}

/* next entry in file order; 1 = produced, 0 = end, -1 = error (printed). */
static int gt_next(GtCur *c, uint32_t *key, u192 *val) {
    if (c->e >= c->ne) return 0;
    if (c->e >= c->bstart + c->bn) {
        uint64_t b = c->e / c->BLK;
        c->bstart = b * c->BLK;
        c->bn = c->BLK; if (c->bstart + c->bn > c->ne) c->bn = c->ne - c->bstart;
        if (!c->is_v2) {
            if (!lc_pread(c->f, c->keys_base + (long)c->bstart*4, c->kbuf, c->bn*4) ||
                !lc_pread(c->f, c->vals_base + (long)c->bstart*24, c->vbuf, c->bn*24)) {
                printf("  [%c] k=%2d  *** FAIL: short v1 entry read\n", c->lab, c->k); return -1; }
        } else {
            uLongf kd = (uLongf)(c->bn*4), vd = (uLongf)(c->bn*24);
            uint64_t kcz = c->kidx[b+1]-c->kidx[b], vcz = c->vidx[b+1]-c->vidx[b];
            if (!lc_pread(c->f, c->kblk_base + (long)c->kidx[b], c->zbuf, kcz) ||
                uncompress((Bytef*)c->kbuf, &kd, c->zbuf, (uLong)kcz) != Z_OK || kd != c->bn*4) {
                printf("  [%c] k=%2d  *** FAIL: key block %llu inflate/size\n",
                       c->lab, c->k, (unsigned long long)b); return -1; }
            if (!lc_pread(c->f, c->vblk_base + (long)c->vidx[b], c->zbuf, vcz) ||
                uncompress((Bytef*)c->vbuf, &vd, c->zbuf, (uLong)vcz) != Z_OK || vd != c->bn*24) {
                printf("  [%c] k=%2d  *** FAIL: val block %llu inflate/size\n",
                       c->lab, c->k, (unsigned long long)b); return -1; }
        }
    }
    uint64_t j = c->e - c->bstart;
    *key = c->kbuf[j];
    memcpy(val, c->vbuf + j*24, 24);
    c->e++;
    return 1;
}

/* buffer span i's entries (cursor must be positioned at off[i]); count, or
 * UINT64_MAX on error / span exceeding the 64*R key-space cap. */
static uint64_t gt_read_span(GtCur *c, uint64_t i, uint32_t *keys, u192 *vals, uint64_t cap) {
    uint64_t cnt = c->off[i+1] - c->off[i];
    if (cnt > cap) {
        printf("  [%c] k=%2d  *** FAIL: mask span %llu has %llu entries > 64*R = %llu\n",
               c->lab, c->k, (unsigned long long)i, (unsigned long long)cnt, (unsigned long long)cap);
        return UINT64_MAX;
    }
    for (uint64_t j = 0; j < cnt; j++)
        if (gt_next(c, &keys[j], &vals[j]) != 1) return UINT64_MAX;
    return cnt;
}

/* per-span structural checks (spec §Invariants). allow = bitmap of permitted
 * last values (0 = skip the domain check). Returns #problems (prints once per
 * kind). */
static uint64_t gt_span_checks(char lab, int k, uint64_t cnt, const uint32_t *keys,
                               const u192 *vals, const int b0v[5], const uint32_t rad[5],
                               uint32_t R, uint64_t allow) {
    uint64_t bad = 0;
    for (uint64_t j = 0; j < cnt; j++) {
        uint32_t key = keys[j], rid = key & 0xffff, last = key >> 16;
        if (j && key <= keys[j-1]) { printf("  [%c] k=%2d  *** FAIL: keys not strictly ascending in span\n", lab, k); bad++; }
        if (key >> 22)             { printf("  [%c] k=%2d  *** FAIL: key bits 22-31 nonzero\n", lab, k); bad++; }
        if (rid >= R)              { printf("  [%c] k=%2d  *** FAIL: rid %u >= R=%u\n", lab, k, rid, R); bad++; }
        else if (lc_rid_digits(rid, b0v, rad) != k)
                                   { printf("  [%c] k=%2d  *** FAIL: rid digit-sum != k (SUM INVARIANT)\n", lab, k); bad++; }
        if (u192_zero(vals[j]))    { printf("  [%c] k=%2d  *** FAIL: zero value stored\n", lab, k); bad++; }
        if (allow && last < 64 && !((allow >> last) & 1))
                                   { printf("  [%c] k=%2d  *** FAIL: last=%u outside the stored-domain pair-element set\n", lab, k, last); bad++; }
        if (bad > 8) return bad;                    /* stop flooding */
    }
    return bad;
}

/* mask sanity + canonicity for one open cursor; orbits[] receives per-mask
 * orbit sizes. Returns #problems. */
static uint64_t gt_mask_checks(GtCur *c, uint32_t n, uint8_t rp[24][32], int geff,
                               uint8_t *orbits) {
    uint64_t bad = 0;
    for (uint64_t i = 0; i < c->nm; i++) {
        int canon; int ob = lc_orbit_of(c->masks[i], rp, geff, &canon);
        orbits[i] = (uint8_t)ob;
        if (__builtin_popcount(c->masks[i]) != c->k) bad++;
        if (n < 32 && (c->masks[i] >> n) != 0) bad++;
        if (!canon || ob == 0) bad++;
    }
    if (bad) printf("  [%c] k=%2d  *** FAIL: %llu masks fail popcount/range/canonicity\n",
                    c->lab, c->k, (unsigned long long)bad);
    return bad;
}

/* Sum all values of one layer (used for N = f final-layer sum). 0 ok. */
static int lc_sum_layer(const char *dir, const char *pfx, const char *magic7, char lab,
                        int k, uint32_t n, uint32_t se, uint64_t plh, const int b0v[5],
                        u192 *out) {
    GtCur c;
    if (gt_open(dir, pfx, magic7, lab, k, n, se, plh, b0v, &c)) return 1;
    u192 s = {{0,0,0}}; int fail = 0, r;
    uint32_t key; u192 v;
    while ((r = gt_next(&c, &key, &v)) == 1)
        if (u192_add(&s, v)) { printf("  [%c] k=%2d  *** FAIL: overflow summing layer\n", lab, k); fail = 1; }
    if (r < 0) fail = 1;
    gt_close(&c);
    *out = s;
    return fail;
}

/* Orbit-weighted mass of f layer k (the M_j of the t identity), re-derived
 * from the layer bytes. 0 ok. */
static int lc_f_mass_layer(const char *fdir, int k, uint32_t n, uint32_t se, uint64_t plh,
                           const int b0v[5], uint8_t rp[24][32], int geff, u192 *mass_out) {
    GtCur c;
    if (gt_open(fdir, "f1c5", "F1C5LAY", 'f', k, n, se, plh, b0v, &c)) return 1;
    u192 mass = {{0,0,0}};
    int fail = 0, movf = 0;
    uint8_t *orbits = malloc(c.nm ? c.nm : 1);
    if (!orbits) { gt_close(&c); return 1; }
    if (gt_mask_checks(&c, n, rp, geff, orbits)) fail = 1;
    for (uint64_t i = 0; i < c.nm && !fail; i++) {
        u192 s = {{0,0,0}};
        uint64_t cnt = c.off[i+1] - c.off[i];
        for (uint64_t j = 0; j < cnt; j++) {
            uint32_t key; u192 v;
            if (gt_next(&c, &key, &v) != 1) { fail = 1; break; }
            if (u192_add(&s, v)) movf = 1;
        }
        if (u192_mul_small(&s, orbits[i])) movf = 1;
        if (u192_add(&mass, s)) movf = 1;
    }
    if (movf) { printf("  [f] k=%2d  *** FAIL: overflow in orbit-weighted mass\n", k); fail = 1; }
    free(orbits);
    gt_close(&c);
    *mass_out = mass;
    return fail;
}

/* read + cross-check the f manifest and a g/t manifest. 0 ok. */
static int lc_gt_manifests(const char *fdir, const char *ldir, const char *pfx,
                           uint32_t *n, uint32_t *se, uint64_t *plh, uint32_t pl[64],
                           int *npl, int b0v[5], int *l_lastk) {
    uint32_t fn, fse, fpl[64], ln, lse, lpl[64];
    uint64_t fph, lph; int fnpl, lnpl, fb0[5], lb0[5], flk;
    if (lc_manifest_pfx(fdir, "f1c5", &fn, &fse, &fph, fpl, &fnpl, fb0, &flk)) {
        printf("*** FAIL: cannot read %s/f1c5_manifest.txt\n", fdir); return 1; }
    if (lc_manifest_pfx(ldir, pfx, &ln, &lse, &lph, lpl, &lnpl, lb0, l_lastk)) {
        printf("*** FAIL: cannot read %s/%s_manifest.txt (or first line is not %s_manifest_v1)\n",
               ldir, pfx, pfx); return 1; }
    int ok = (fn==ln && fse==lse && fph==lph && fnpl==lnpl);
    for (int i=0;i<5;i++) if (fb0[i]!=lb0[i]) ok=0;
    for (int i=0;i<fnpl && i<64;i++) if (fpl[i]!=lpl[i]) ok=0;
    if (!ok) { printf("*** FAIL: %s manifest disagrees with the f manifest (n/start_exit/pl/pl_hash/b0)\n", pfx); return 1; }
    if (fn < 1 || fn > 31 || fnpl != (int)fn) {
        printf("*** FAIL: manifest n=%u with %d pl entries\n", fn, fnpl); return 1; }
    uint64_t rec = lc_pl_hash(fn, fse, fpl);
    if (rec != fph) { printf("*** FAIL: pl_hash %016llx != recomputed %016llx\n",
                             (unsigned long long)fph, (unsigned long long)rec); return 1; }
    if (*l_lastk < 0 || *l_lastk > (int)fn) {
        printf("*** FAIL: %s last_complete_k=%d out of range (backward ladder: 0=complete)\n",
               pfx, *l_lastk); return 1; }
    *n=fn; *se=fse; *plh=fph; *npl=fnpl;
    for (int i=0;i<fnpl;i++) pl[i]=fpl[i];
    for (int i=0;i<5;i++) b0v[i]=fb0[i];
    return 0;
}

/* ---- g mode: one layer (structural + the f*g cut identity) ---- */
static int lc_g_layer(const char *fdir, const char *gdir, int k, uint32_t n, uint32_t se,
                      uint64_t plh, const int b0v[5], const uint32_t rad[5], uint32_t R,
                      const uint32_t *pl, uint8_t rp[24][32], int geff,
                      const u192 *expect, int have_expect,
                      u192 *g0_out, int *g0_got) {
    GtCur gc, fc;
    int have_f = 0, fail = 0;
    if (gt_open(gdir, "g", "F1C5GLY", 'g', k, n, se, plh, b0v, &gc)) return 1;
    { char p[1024]; snprintf(p, sizeof p, "%s/f1c5_layer_%02d.bin", fdir, k);
      FILE *t = fopen(p, "rb");
      if (t) { fclose(t);
        if (gt_open(fdir, "f1c5", "F1C5LAY", 'f', k, n, se, plh, b0v, &fc) == 0) have_f = 1;
        else fail = 1; } }

    uint8_t *orbits = malloc(gc.nm ? gc.nm : 1);
    uint64_t cap = 64ull * R;
    uint32_t *gkeys = malloc(cap*4), *fkeys = malloc(cap*4);
    u192 *gvals = malloc(cap*sizeof(u192)), *fvals = malloc(cap*sizeof(u192));
    if (!orbits || !gkeys || !fkeys || !gvals || !fvals) {
        printf("  [g] k=%2d  *** FAIL: OOM span buffers\n", k);
        free(orbits); free(gkeys); free(fkeys); free(gvals); free(fvals);
        gt_close(&gc); if (have_f) gt_close(&fc); return 1; }

    if (gt_mask_checks(&gc, n, rp, geff, orbits)) fail = 1;
    /* spec: the f and g mask lists at a layer are identical (both = all
     * canonical popcount-k masks) */
    if (have_f && (gc.nm != fc.nm || memcmp(gc.masks, fc.masks, 4*gc.nm) != 0)) {
        printf("  [g] k=%2d  *** FAIL: g mask list differs from f mask list\n", k); fail = 1; }

    u192 acc = {{0,0,0}};
    int ovf = 0;
    uint64_t fi = 0, gi = 0, bad = 0, seed_bad = 0;
    while (!fail && (gi < gc.nm || (have_f && fi < fc.nm))) {
        int take_g = (gi < gc.nm) &&
                     (!have_f || fi >= fc.nm || gc.masks[gi] <= fc.masks[fi]);
        int take_f = have_f && (fi < fc.nm) &&
                     (gi >= gc.nm || fc.masks[fi] <= gc.masks[gi]);
        uint64_t gcnt = 0, fcnt = 0;
        uint32_t m = take_g ? gc.masks[gi] : fc.masks[fi];
        if (take_g) {
            gcnt = gt_read_span(&gc, gi, gkeys, gvals, cap);
            if (gcnt == UINT64_MAX) { fail = 1; break; }
            uint64_t allow = 0;                       /* stored-domain bitmap */
            if (k == 0) allow = 1ull << se;
            else for (uint32_t b = 0; b < n; b++)
                if ((m >> b) & 1) allow |= (1ull << PA[pl[b]]) | (1ull << PB[pl[b]]);
            bad += gt_span_checks('g', k, gcnt, gkeys, gvals, b0v, rad, R, allow);
            if (k == (int)n) {                        /* exact seed content */
                int elems[64]; uint32_t nel = 0;
                for (uint32_t b = 0; b < n; b++) { elems[nel++] = PA[pl[b]]; elems[nel++] = PB[pl[b]]; }
                for (uint32_t a2 = 1; a2 < nel; a2++) { int x = elems[a2]; uint32_t b2 = a2;
                    while (b2 > 0 && elems[b2-1] > x) { elems[b2] = elems[b2-1]; b2--; } elems[b2] = x; }
                if (gcnt != nel) seed_bad++;
                else for (uint32_t j = 0; j < nel; j++) {
                    u192 one = {{1,0,0}};
                    if (gkeys[j] != (((uint32_t)elems[j] << 16) | (R-1)) || !u192_eq(gvals[j], one))
                        seed_bad++;
                }
            }
            if (k == 0) {                             /* anchor singleton -> g(0) */
                if (gc.nm != 1 || gc.masks[0] != 0 || gcnt != 1 || gkeys[0] != (se << 16)) {
                    printf("  [g] k= 0  *** FAIL: layer 0 is not the anchor singleton\n"); fail = 1; }
                else { *g0_out = gvals[0]; *g0_got = 1; }
            }
        }
        if (take_f) {
            fcnt = gt_read_span(&fc, fi, fkeys, fvals, cap);
            if (fcnt == UINT64_MAX) { fail = 1; break; }
        }
        if (take_g && take_f) {                       /* matched mask: key merge */
            u192 msum = {{0,0,0}};
            uint64_t a2 = 0, b2 = 0;
            while (a2 < fcnt && b2 < gcnt) {
                if (fkeys[a2] < gkeys[b2]) a2++;
                else if (gkeys[b2] < fkeys[a2]) b2++;
                else {
                    u192 p = u192_mul(fvals[a2], gvals[b2], &ovf);
                    if (u192_add(&msum, p)) ovf = 1;
                    a2++; b2++;
                }
            }
            if (u192_mul_small(&msum, orbits[gi])) ovf = 1;
            if (u192_add(&acc, msum)) ovf = 1;
        }
        if (take_g) gi++;
        if (take_f) fi++;
    }
    if (bad) fail = 1;
    if (seed_bad) { printf("  [g] k=%2d  *** FAIL: seed layer content wrong (%llu deviations from "
                           "2n sorted pair elements, rid=R-1, value 1)\n",
                           k, (unsigned long long)seed_bad); fail = 1; }
    if (ovf)  { printf("  [g] k=%2d  *** FAIL: 192-bit overflow in f*g identity\n", k); fail = 1; }

    if (!fail && have_f && have_expect) {
        int ok = u192_eq(acc, *expect);
        char a[64], e[64]; u192_print(acc, a); u192_print(*expect, e);
        printf("  k=%2d  g nm=%-7llu ne=%-10llu %s  Σ orbit·f·g = %s (expect N = %s)  %s\n",
               k, (unsigned long long)gc.nm, (unsigned long long)gc.ne, gc.is_v2?"v2":"v1",
               a, e, ok ? "OK" : "*** MISMATCH ***");
        if (!ok) fail = 1;
    } else if (!fail) {
        printf("  k=%2d  g nm=%-7llu ne=%-10llu %s  structural OK (identity skipped: %s)\n",
               k, (unsigned long long)gc.nm, (unsigned long long)gc.ne, gc.is_v2?"v2":"v1",
               have_f ? "no expected N" : "f layer absent");
    }
    free(orbits); free(gkeys); free(fkeys); free(gvals); free(fvals);
    gt_close(&gc); if (have_f) gt_close(&fc);
    return fail;
}

static int lc_check_g(const char *fdir, const char *gdir, int maxk) {
    printf("======================================================================\n");
    printf("verify.c --check-g-ladder : spec-driven independent g-ladder verifier\n");
    printf("written against documentation/GT_LADDER_FORMAT.md; shares no code with solve.c\n");
    printf("======================================================================\n");
    uint32_t n, se, pl[64]; uint64_t plh; int npl, b0v[5], glk;
    if (lc_gt_manifests(fdir, gdir, "g", &n, &se, &plh, pl, &npl, b0v, &glk)) return 1;
    printf("manifests: n=%u start_exit=%u b0=(%d,%d,%d,%d,%d)  g last_complete_k=%d (0=complete; layers %d..%u present)\n",
           n, se, b0v[0], b0v[1], b0v[2], b0v[3], b0v[4], glk, glk, n);
    if (!derive_pair_perms()) return 1;
    static uint8_t rp[24][32];
    int geff = lc_restrict_perms(pl, n, rp);
    if (geff < 0) { printf("*** FAIL: restricted pair-perms are not a group\n"); return 1; }
    printf("group    : 48 -> 24 induced pair-perms -> %d distinct on this run's %u pairs\n", geff, n);
    uint32_t rad[5], R; lc_radix(b0v, rad, &R);

    /* N re-derived from the f ladder's final-layer bytes */
    u192 expect = {{0,0,0}}; int have_expect = 0, fails = 0;
    { char p[1024]; snprintf(p, sizeof p, "%s/f1c5_layer_%02u.bin", fdir, n);
      FILE *t = fopen(p, "rb");
      if (t) { fclose(t);
        if (lc_sum_layer(fdir, "f1c5", "F1C5LAY", 'f', (int)n, n, se, plh, b0v, &expect) == 0) {
            have_expect = 1;
            char d[64]; u192_print(expect, d);
            printf("expect N : Σ f(layer %u) = %s  (from the f ladder's value bytes)\n", n, d);
            if (n == 31) {
                u192 pub = u192_dec(LC_PUBLISHED_COUNT);
                int ok = u192_eq(expect, pub);
                printf("           vs published |C1∩C2∩C4∩C5| %s\n", ok ? "MATCH" : "*** MISMATCH ***");
                if (!ok) fails++;
            }
        } else fails++;
      } else printf("expect N : f layer %u absent — per-layer identity will be skipped\n", n);
    }
    printf("----------------------------------------------------------------------\n");
    u192 g0 = {{0,0,0}}; int g0_got = 0, checked = 0;
    int hi = (maxk < (int)n) ? maxk : (int)n;
    for (int k = 0; k <= hi; k++) {
        char p[1024]; snprintf(p, sizeof p, "%s/g_layer_%02d.bin", gdir, k);
        FILE *t = fopen(p, "rb");
        if (!t) {
            if (k >= glk) { printf("  k=%2d  *** FAIL: g layer missing but manifest promises layers %d..%u\n", k, glk, n); fails++; }
            continue;
        }
        fclose(t);
        fails += lc_g_layer(fdir, gdir, k, n, se, plh, b0v, rad, R, pl, rp, geff,
                            &expect, have_expect, &g0, &g0_got);
        checked++;
    }
    printf("----------------------------------------------------------------------\n");
    if (g0_got && have_expect) {
        int ok = u192_eq(g0, expect);
        char a[64]; u192_print(g0, a);
        printf("g(0) = %s  %s the f-ladder total (whole-space count from the suffix side)\n",
               a, ok ? "MATCHES" : "*** DOES NOT MATCH ***");
        if (!ok) fails++;
    }
    if (fails == 0)
        printf("RESULT: %d g layer(s) verified — headers, layout, canonicity, stored domain,\n"
               "        sum invariant, seed/anchor content, and the f·g cut identity at every\n"
               "        checked layer.\n", checked);
    else
        printf("RESULT: *** %d FAILURE(S) *** — a finding. Report it; do not patch around it.\n", fails);
    printf("======================================================================\n");
    return fails ? 1 : 0;
}

/* ---- t mode: one layer (geometry mirror + the f*t node identity) ---- */
static int lc_t_layer(const char *fdir, const char *tdir, int k, uint32_t n, uint32_t se,
                      uint64_t plh, const int b0v[5], const uint32_t rad[5], uint32_t R,
                      uint8_t rp[24][32], int geff,
                      const u192 *Sk, int have_S, u192 *troot_out, int *troot_got) {
    GtCur tc, fc;
    if (gt_open(tdir, "t", "F1C5TLY", 't', k, n, se, plh, b0v, &tc)) return 1;
    if (gt_open(fdir, "f1c5", "F1C5LAY", 'f', k, n, se, plh, b0v, &fc)) {
        printf("  [t] k=%2d  *** FAIL: the f layer is required (t inherits f geometry)\n", k);
        gt_close(&tc); return 1; }
    int fail = 0;
    if (tc.nm != fc.nm || memcmp(tc.masks, fc.masks, 4*tc.nm) != 0 ||
        memcmp(tc.off, fc.off, 8*(tc.nm+1)) != 0) {
        printf("  [t] k=%2d  *** FAIL: GEOMETRY (masks/off) differs from the f layer\n", k);
        gt_close(&tc); gt_close(&fc); return 1; }
    uint8_t *orbits = malloc(tc.nm ? tc.nm : 1);
    if (!orbits) { gt_close(&tc); gt_close(&fc); return 1; }
    if (gt_mask_checks(&tc, n, rp, geff, orbits)) fail = 1;

    u192 acc = {{0,0,0}};
    int ovf = 0;
    uint64_t bad_key = 0, bad_rid = 0, bad_zero = 0, bad_seed = 0;
    for (uint64_t i = 0; i < tc.nm && !fail; i++) {
        u192 msum = {{0,0,0}};
        uint64_t cnt = tc.off[i+1] - tc.off[i];
        for (uint64_t j = 0; j < cnt; j++) {
            uint32_t fk, tk; u192 fv, tv;
            if (gt_next(&fc, &fk, &fv) != 1 || gt_next(&tc, &tk, &tv) != 1) { fail = 1; break; }
            if (fk != tk || (tk >> 22)) bad_key++;
            uint32_t rid = tk & 0xffff;
            if (rid >= R || lc_rid_digits(rid, b0v, rad) != k) bad_rid++;
            if (u192_zero(tv)) bad_zero++;
            if (k == (int)n) { u192 one = {{1,0,0}}; if (!u192_eq(tv, one)) bad_seed++; }
            if (k == 0 && i == 0 && j == 0) { *troot_out = tv; *troot_got = 1; }
            u192 p = u192_mul(fv, tv, &ovf);
            if (u192_add(&msum, p)) ovf = 1;
        }
        if (u192_mul_small(&msum, orbits[i])) ovf = 1;
        if (u192_add(&acc, msum)) ovf = 1;
    }
    #define TCF(cnt,msg) do{ if (cnt) { printf("  [t] k=%2d  *** FAIL: %llu %s\n", k, (unsigned long long)(cnt), msg); fail=1; } }while(0)
    TCF(bad_key,  "entries whose key differs from the f layer (geometry mirror broken)");
    TCF(bad_rid,  "entries with rid >= R or digit-sum != k (SUM INVARIANT)");
    TCF(bad_zero, "zero t values (every node count is >= 1)");
    TCF(bad_seed, "seed-layer values != 1");
    #undef TCF
    if (ovf) { printf("  [t] k=%2d  *** FAIL: 192-bit overflow in f*t identity\n", k); fail = 1; }
    if (k == 0 && !fail && (tc.nm != 1 || tc.masks[0] != 0 || tc.ne != 1)) {
        printf("  [t] k= 0  *** FAIL: layer 0 is not the anchor singleton\n"); fail = 1; }

    if (!fail && have_S) {
        int ok = u192_eq(acc, *Sk);
        char a[64], e[64]; u192_print(acc, a); u192_print(*Sk, e);
        printf("  k=%2d  t nm=%-7llu ne=%-10llu %s  Σ orbit·f·t = %s (expect nodes at depth ≥%d = %s)  %s\n",
               k, (unsigned long long)tc.nm, (unsigned long long)tc.ne, tc.is_v2?"v2":"v1",
               a, k, e, ok ? "OK" : "*** MISMATCH ***");
        if (!ok) fail = 1;
    } else if (!fail) {
        printf("  k=%2d  t nm=%-7llu ne=%-10llu %s  structural+geometry OK (identity skipped: M_j incomplete)\n",
               k, (unsigned long long)tc.nm, (unsigned long long)tc.ne, tc.is_v2?"v2":"v1");
    }
    free(orbits);
    gt_close(&tc); gt_close(&fc);
    return fail;
}

static int lc_check_t(const char *fdir, const char *tdir, int maxk) {
    printf("======================================================================\n");
    printf("verify.c --check-t-ladder : spec-driven independent t-ladder verifier\n");
    printf("written against documentation/GT_LADDER_FORMAT.md; shares no code with solve.c\n");
    printf("======================================================================\n");
    uint32_t n, se, pl[64]; uint64_t plh; int npl, b0v[5], tlk;
    if (lc_gt_manifests(fdir, tdir, "t", &n, &se, &plh, pl, &npl, b0v, &tlk)) return 1;
    printf("manifests: n=%u start_exit=%u b0=(%d,%d,%d,%d,%d)  t last_complete_k=%d (0=complete; layers %d..%u present)\n",
           n, se, b0v[0], b0v[1], b0v[2], b0v[3], b0v[4], tlk, tlk, n);
    if (!derive_pair_perms()) return 1;
    static uint8_t rp[24][32];
    int geff = lc_restrict_perms(pl, n, rp);
    if (geff < 0) { printf("*** FAIL: restricted pair-perms are not a group\n"); return 1; }
    printf("group    : 48 -> 24 induced pair-perms -> %d distinct on this run's %u pairs\n", geff, n);
    uint32_t rad[5], R; lc_radix(b0v, rad, &R);

    /* M_j = orbit-weighted f masses (exact # valid prefixes at depth j),
     * re-derived from the f ladder's bytes; S_k = Σ_{j>=k} M_j. */
    int fails = 0, have_S = 1;
    u192 M[32], S[33];
    for (uint32_t j = 0; j <= n; j++) {
        char p[1024]; snprintf(p, sizeof p, "%s/f1c5_layer_%02u.bin", fdir, j);
        FILE *t = fopen(p, "rb");
        if (!t) { printf("M pass   : f layer %u absent — identities will be skipped\n", j); have_S = 0; break; }
        fclose(t);
        if (lc_f_mass_layer(fdir, (int)j, n, se, plh, b0v, rp, geff, &M[j])) { fails++; have_S = 0; break; }
    }
    if (have_S) {
        u192 one = {{1,0,0}};
        if (!u192_eq(M[0], one)) { printf("*** FAIL: M_0 != 1 (f layer 0 defect)\n"); fails++; }
        if (n == 31) {
            u192 pub = u192_dec(LC_PUBLISHED_COUNT);
            int ok = u192_eq(M[n], pub);
            printf("M pass   : M_31 vs published count %s\n", ok ? "MATCH" : "*** MISMATCH ***");
            if (!ok) fails++;
        }
        int sovf = 0;
        S[n+1] = (u192){{0,0,0}};
        for (int k = (int)n; k >= 0; k--) { S[k] = S[k+1]; if (u192_add(&S[k], M[k])) sovf = 1; }
        if (sovf) { printf("*** FAIL: overflow accumulating S_k\n"); fails++; have_S = 0; }
        else { char d[64]; u192_print(S[0], d);
               printf("M pass   : all %u f masses re-derived; total search-tree size S_0 = %s\n", n+1, d); }
    }
    printf("----------------------------------------------------------------------\n");
    u192 troot = {{0,0,0}}; int troot_got = 0, checked = 0;
    int hi = (maxk < (int)n) ? maxk : (int)n;
    for (int k = 0; k <= hi; k++) {
        char p[1024]; snprintf(p, sizeof p, "%s/t_layer_%02d.bin", tdir, k);
        FILE *t = fopen(p, "rb");
        if (!t) {
            if (k >= tlk) { printf("  k=%2d  *** FAIL: t layer missing but manifest promises layers %d..%u\n", k, tlk, n); fails++; }
            continue;
        }
        fclose(t);
        fails += lc_t_layer(fdir, tdir, k, n, se, plh, b0v, rad, R, rp, geff,
                            have_S ? &S[k] : NULL, have_S, &troot, &troot_got);
        checked++;
    }
    printf("----------------------------------------------------------------------\n");
    if (troot_got) {
        char a[64]; u192_print(troot, a);
        if (have_S) {
            int ok = u192_eq(troot, S[0]);
            printf("t(root) = %s  %s Σ M_j (the whole search-tree size, re-derived from f)\n",
                   a, ok ? "MATCHES" : "*** DOES NOT MATCH ***");
            if (!ok) fails++;
        } else printf("t(root) = %s  (no independent Σ M_j available)\n", a);
    }
    if (fails == 0)
        printf("RESULT: %d t layer(s) verified — headers, byte-exact f-geometry mirror,\n"
               "        values >= 1, seed/anchor content, and the f·t node identity\n"
               "        (recurrence unfolded, S_k = S_{k+1} + M_k) at every checked layer.\n", checked);
    else
        printf("RESULT: *** %d FAILURE(S) *** — a finding. Report it; do not patch around it.\n", fails);
    printf("======================================================================\n");
    return fails ? 1 : 0;
}

/* ==========================================================================
 * G/T SELF-TEST (--check-gt-selftest): builds a COMPLETE, CONSISTENT f+g+t
 * fixture by brute force from the published definitions, then round-trips it
 * through the spec-driven checkers, plus corruption legs that must FAIL.
 *
 * The fixture instance is deliberately NON-TRIVIAL: pl = {10,15,20,23,27,29}
 * is a single 6-pair orbit of the TR-11 §2 action (so the restricted group
 * is transitive: geff = 6, single-bit masks have orbit 6, two-bit masks
 * split into orbits with |stab| in {1,2}), the budget b0 = (0,0,1,2,3)
 * spans three boundary classes including d=6, and under it the instance has
 * 252 DEAD-END states (valid prefixes with g = 0) — exactly the f/t vs g
 * domain difference the t-ladder exists for. Anchors (cross-derived by an
 * independent Python implementation of the same definitions, 2026-07-24):
 * N = 96, t(root) = 1285, M = (1,12,72,288,528,288,96). The generator here
 * is a plain RAW-STATE DP (no quotient); the checkers then re-aggregate
 * through the canonical-mask + orbit-weight machinery — so a pass exercises
 * canonicalization, stabilizer weighting, domain rules, both identities,
 * and the v1/v2 codecs against known values.
 * ========================================================================== */
#define GTS_NP 6
static const uint32_t gts_pl[GTS_NP] = {10, 15, 20, 23, 27, 29};
static const int gts_b0[5] = {0, 0, 1, 2, 3};     /* Σ = 6 = n; R = 24 */
#define GTS_SE 0
#define GTS_N_EXPECT 96u
#define GTS_TROOT_EXPECT 1285u
#define GTS_DEAD_EXPECT 252u
static const uint64_t gts_M_expect[GTS_NP+1] = {1, 12, 72, 288, 528, 288, 96};

/* raw-state DP tables, index (mask, last, rid) */
#define GTS_IX(m,l,r,R) ((((uint64_t)(m)*64u + (uint32_t)(l)) * (R)) + (r))

static void gts_write_v1(const char *dir, const char *pfx, const char *magic8,
                         int k, uint64_t plh, const uint32_t *masks, uint64_t nm,
                         const uint64_t *off, const uint32_t *keys, const u192 *vals,
                         uint64_t ne) {
    unsigned char hd[72]; memset(hd, 0, 72);
    memcpy(hd, magic8, 8);
    uint32_t v = (uint32_t)(magic8[7] - '0'); memcpy(hd+8, &v, 4);
    uint32_t n = GTS_NP, se = GTS_SE, kk = (uint32_t)k;
    memcpy(hd+12, &n, 4); memcpy(hd+16, &kk, 4); memcpy(hd+20, &se, 4);
    memcpy(hd+24, &plh, 8); memcpy(hd+32, &nm, 8); memcpy(hd+40, &ne, 8);
    for (int c = 0; c < 5; c++) { uint32_t t = (uint32_t)gts_b0[c]; memcpy(hd+48+4*c, &t, 4); }
    char path[1024]; snprintf(path, sizeof path, "%s/%s_layer_%02d.bin", dir, pfx, k);
    FILE *f = fopen(path, "wb");
    lc_wr(f, hd, 72); lc_wr(f, masks, nm*4); lc_wr(f, off, (nm+1)*8);
    lc_wr(f, keys, ne*4);
    for (uint64_t i = 0; i < ne; i++) lc_wr(f, &vals[i], 24);
    fclose(f);
}

static void gts_write_v2(const char *dir, const char *pfx, const char *magic8,
                         int k, uint64_t plh, const uint32_t *masks, uint64_t nm,
                         const uint64_t *off, const uint32_t *keys, const u192 *vals,
                         uint64_t ne, uint32_t BLK) {
    unsigned char hd[72]; memset(hd, 0, 72);
    memcpy(hd, magic8, 8);
    uint32_t v = (uint32_t)(magic8[7] - '0'); memcpy(hd+8, &v, 4);
    uint32_t n = GTS_NP, se = GTS_SE, kk = (uint32_t)k;
    memcpy(hd+12, &n, 4); memcpy(hd+16, &kk, 4); memcpy(hd+20, &se, 4);
    memcpy(hd+24, &plh, 8); memcpy(hd+32, &nm, 8); memcpy(hd+40, &ne, 8);
    for (int c = 0; c < 5; c++) { uint32_t t = (uint32_t)gts_b0[c]; memcpy(hd+48+4*c, &t, 4); }
    memcpy(hd+68, &BLK, 4);
    uint64_t nblk = ne ? (ne + BLK - 1)/BLK : 0;
    uint64_t *kidx = calloc(nblk+1, 8), *vidx = calloc(nblk+1, 8);
    unsigned char *zk = malloc((nblk?nblk:1) * compressBound(4u*BLK));
    unsigned char *zv = malloc((nblk?nblk:1) * compressBound(24u*BLK));
    unsigned char *tmp = malloc(24u*BLK);
    uint64_t zkn = 0, zvn = 0;
    for (uint64_t b = 0; b < nblk; b++) {
        uint64_t bs = b*BLK, bn = (bs + BLK <= ne) ? BLK : ne - bs;
        uLongf zl = compressBound(4u*BLK);
        compress2(zk + zkn, &zl, (const Bytef*)(keys + bs), bn*4, 6);
        zkn += zl; kidx[b+1] = zkn;
        for (uint64_t j = 0; j < bn; j++) memcpy(tmp + j*24, &vals[bs+j], 24);
        zl = compressBound(24u*BLK);
        compress2(zv + zvn, &zl, tmp, bn*24, 6);
        zvn += zl; vidx[b+1] = zvn;
    }
    char path[1024]; snprintf(path, sizeof path, "%s/%s_layer_%02d.bin", dir, pfx, k);
    FILE *f = fopen(path, "wb");
    lc_wr(f, hd, 72); lc_wr(f, masks, nm*4); lc_wr(f, off, (nm+1)*8);
    lc_wr(f, kidx, (nblk+1)*8); lc_wr(f, vidx, (nblk+1)*8);
    lc_wr(f, zk, zkn); lc_wr(f, zv, zvn);
    fclose(f);
    free(kidx); free(vidx); free(zk); free(zv); free(tmp);
}

static void gts_write_manifest(const char *dir, const char *pfx, uint64_t plh, int lastk) {
    char path[1024]; snprintf(path, sizeof path, "%s/%s_manifest.txt", dir, pfx);
    FILE *f = fopen(path, "w");
    fprintf(f, "%s_manifest_v1\nn=%d\nstart_exit=%d\npl=", pfx, GTS_NP, GTS_SE);
    for (int i = 0; i < GTS_NP; i++) fprintf(f, "%s%u", i ? "," : "", gts_pl[i]);
    fprintf(f, "\npl_hash=%016llx\nb0=%d,%d,%d,%d,%d\nlast_complete_k=%d\n",
            (unsigned long long)plh, gts_b0[0], gts_b0[1], gts_b0[2], gts_b0[3], gts_b0[4], lastk);
    fclose(f);
}

/* assemble layer k of one ladder from a raw-value table and write it (v1).
 * kind: 0 = f (all last with tab>0), 1 = g (pair-element domain), 2 = t
 * (f geometry via tabf, values from tab). */
static void gts_emit_layer(const char *dir, const char *pfx, const char *magic8, int kind,
                           int k, uint64_t plh, uint32_t R, const uint64_t *tab,
                           const uint64_t *tabf, uint8_t rp[24][32], int geff,
                           uint32_t *masks_out, uint64_t *nm_out, uint64_t *off_out,
                           uint32_t *keys_out, u192 *vals_out, uint64_t *ne_out) {
    const int pa[GTS_NP] = {PA[gts_pl[0]], PA[gts_pl[1]], PA[gts_pl[2]],
                            PA[gts_pl[3]], PA[gts_pl[4]], PA[gts_pl[5]]};
    const int pb[GTS_NP] = {PB[gts_pl[0]], PB[gts_pl[1]], PB[gts_pl[2]],
                            PB[gts_pl[3]], PB[gts_pl[4]], PB[gts_pl[5]]};
    uint64_t nm = 0, ne = 0;
    for (uint32_t m = 0; m < (1u << GTS_NP); m++) {
        if (__builtin_popcount(m) != k) continue;
        int canon; lc_orbit_of(m, rp, geff, &canon);
        if (!canon) continue;
        masks_out[nm] = m;
        off_out[nm] = ne;
        if (kind == 1) {                       /* g: domain-restricted last */
            int dom[64]; uint32_t nd = 0;
            if (k == 0) dom[nd++] = GTS_SE;
            else for (int b = 0; b < GTS_NP; b++)
                if ((m >> b) & 1) { dom[nd++] = pa[b]; dom[nd++] = pb[b]; }
            for (uint32_t a = 1; a < nd; a++) { int x = dom[a]; uint32_t b2 = a;
                while (b2 > 0 && dom[b2-1] > x) { dom[b2] = dom[b2-1]; b2--; } dom[b2] = x; }
            for (uint32_t d = 0; d < nd; d++)
                for (uint32_t r = 0; r < R; r++) {
                    uint64_t v = tab[GTS_IX(m, dom[d], r, R)];
                    if (!v) continue;
                    keys_out[ne] = ((uint32_t)dom[d] << 16) | r;
                    vals_out[ne] = (u192){{v, 0, 0}};
                    ne++;
                }
        } else {                               /* f or t: f-domain geometry */
            for (int l = 0; l < 64; l++)
                for (uint32_t r = 0; r < R; r++) {
                    if (!tabf[GTS_IX(m, l, r, R)]) continue;
                    uint64_t v = tab[GTS_IX(m, l, r, R)];
                    keys_out[ne] = ((uint32_t)l << 16) | r;
                    vals_out[ne] = (u192){{v, 0, 0}};
                    ne++;
                }
        }
        nm++;
    }
    off_out[nm] = ne;
    *nm_out = nm; *ne_out = ne;
    gts_write_v1(dir, pfx, magic8, k, plh, masks_out, nm, off_out, keys_out, vals_out, ne);
}

static int lc_gt_selftest(void) {
    printf("verify.c --check-gt-selftest : brute-force f+g+t fixture, spec round-trip, corruption legs\n");
    if (!build_pairs() || !derive_pair_perms()) return 1;
    static uint8_t rp[24][32];
    uint32_t pl32[GTS_NP]; for (int i = 0; i < GTS_NP; i++) pl32[i] = gts_pl[i];
    int geff = lc_restrict_perms(pl32, GTS_NP, rp);
    uint32_t rad[5], R; lc_radix(gts_b0, rad, &R);
    uint64_t plh = lc_pl_hash(GTS_NP, GTS_SE, pl32);
    const int pa[GTS_NP] = {PA[gts_pl[0]], PA[gts_pl[1]], PA[gts_pl[2]],
                            PA[gts_pl[3]], PA[gts_pl[4]], PA[gts_pl[5]]};
    const int pb[GTS_NP] = {PB[gts_pl[0]], PB[gts_pl[1]], PB[gts_pl[2]],
                            PB[gts_pl[3]], PB[gts_pl[4]], PB[gts_pl[5]]};

    /* ---- brute-force raw-state DPs from the published definitions ---- */
    const uint64_t TSZ = GTS_IX((1u<<GTS_NP)-1, 63, R-1, R) + 1;
    uint64_t *tf = calloc(TSZ, 8), *tg = calloc(TSZ, 8), *tt = calloc(TSZ, 8);
    if (!tf || !tg || !tt) { printf("*** FAIL: OOM DP tables\n"); return 1; }
    tf[GTS_IX(0, GTS_SE, 0, R)] = 1;                      /* forward f */
    for (int k = 0; k < GTS_NP; k++)
        for (uint32_t m = 0; m < (1u << GTS_NP); m++) {
            if (__builtin_popcount(m) != k) continue;
            for (int l = 0; l < 64; l++)
                for (uint32_t r = 0; r < R; r++) {
                    uint64_t v = tf[GTS_IX(m, l, r, R)];
                    if (!v) continue;
                    for (int i = 0; i < GTS_NP; i++) {
                        if ((m >> i) & 1) continue;
                        for (int o = 0; o < 2; o++) {
                            int e = o ? pb[i] : pa[i], x = o ? pa[i] : pb[i];
                            int d = hamming(l, e), ci = cls_ix(d);
                            if (d == 5 || d == 0 || ci < 0) continue;
                            if ((r / rad[ci]) % (uint32_t)(gts_b0[ci]+1) >= (uint32_t)gts_b0[ci]) continue;
                            tf[GTS_IX(m | (1u<<i), x, r + rad[ci], R)] += v;
                        }
                    }
                }
        }
    for (int i = 0; i < GTS_NP; i++) {                    /* backward g: seed all 2n elements */
        tg[GTS_IX((1u<<GTS_NP)-1, pa[i], R-1, R)] = 1;
        tg[GTS_IX((1u<<GTS_NP)-1, pb[i], R-1, R)] = 1;
    }
    for (int k = GTS_NP - 1; k >= 0; k--)
        for (uint32_t m = 0; m < (1u << GTS_NP); m++) {
            if (__builtin_popcount(m) != k) continue;
            for (int l = 0; l < 64; l++)
                for (uint32_t r = 0; r < R; r++) {
                    if (lc_rid_digits(r, gts_b0, rad) != k) continue;
                    uint64_t acc = 0;
                    for (int i = 0; i < GTS_NP; i++) {
                        if ((m >> i) & 1) continue;
                        for (int o = 0; o < 2; o++) {
                            int e = o ? pb[i] : pa[i], x = o ? pa[i] : pb[i];
                            int d = hamming(l, e), ci = cls_ix(d);
                            if (d == 5 || d == 0 || ci < 0) continue;
                            if ((r / rad[ci]) % (uint32_t)(gts_b0[ci]+1) >= (uint32_t)gts_b0[ci]) continue;
                            acc += tg[GTS_IX(m | (1u<<i), x, r + rad[ci], R)];
                        }
                    }
                    tg[GTS_IX(m, l, r, R)] = acc;
                }
        }
    for (uint32_t m = 0; m < (1u << GTS_NP); m++)         /* t seed on f layer n */
        if (__builtin_popcount(m) == GTS_NP)
            for (int l = 0; l < 64; l++)
                for (uint32_t r = 0; r < R; r++)
                    if (tf[GTS_IX(m, l, r, R)]) tt[GTS_IX(m, l, r, R)] = 1;
    for (int k = GTS_NP - 1; k >= 0; k--)                 /* t backward on the f domain */
        for (uint32_t m = 0; m < (1u << GTS_NP); m++) {
            if (__builtin_popcount(m) != k) continue;
            for (int l = 0; l < 64; l++)
                for (uint32_t r = 0; r < R; r++) {
                    if (!tf[GTS_IX(m, l, r, R)]) continue;
                    uint64_t acc = 1;
                    for (int i = 0; i < GTS_NP; i++) {
                        if ((m >> i) & 1) continue;
                        for (int o = 0; o < 2; o++) {
                            int e = o ? pb[i] : pa[i], x = o ? pa[i] : pb[i];
                            int d = hamming(l, e), ci = cls_ix(d);
                            if (d == 5 || d == 0 || ci < 0) continue;
                            if ((r / rad[ci]) % (uint32_t)(gts_b0[ci]+1) >= (uint32_t)gts_b0[ci]) continue;
                            acc += tt[GTS_IX(m | (1u<<i), x, r + rad[ci], R)];
                        }
                    }
                    tt[GTS_IX(m, l, r, R)] = acc;
                }
        }

    /* ---- known-structure gates (anchors from the independent prototype) ---- */
    uint64_t N = tg[GTS_IX(0, GTS_SE, 0, R)];
    uint64_t troot = tt[GTS_IX(0, GTS_SE, 0, R)];
    uint64_t dead = 0, Mj[GTS_NP+1] = {0,0,0,0,0,0,0};
    for (uint32_t m = 0; m < (1u << GTS_NP); m++)
        for (int l = 0; l < 64; l++)
            for (uint32_t r = 0; r < R; r++) {
                uint64_t fv = tf[GTS_IX(m, l, r, R)];
                if (!fv) continue;
                Mj[__builtin_popcount(m)] += fv;
                if (!tg[GTS_IX(m, l, r, R)]) dead++;
            }
    int m_ok = 1;
    for (int j = 0; j <= GTS_NP; j++) if (Mj[j] != gts_M_expect[j]) m_ok = 0;
    int gen_ok = (geff == 6 && N == GTS_N_EXPECT && troot == GTS_TROOT_EXPECT &&
                  dead == GTS_DEAD_EXPECT && m_ok);
    printf("\n[1] generator vs independent anchors: geff=%d (want 6)  N=%llu (want %u)\n"
           "    t_root=%llu (want %u)  dead_states=%llu (want %u)  M match=%s  =>  %s\n",
           geff, (unsigned long long)N, GTS_N_EXPECT,
           (unsigned long long)troot, GTS_TROOT_EXPECT,
           (unsigned long long)dead, GTS_DEAD_EXPECT, m_ok ? "Y" : "N",
           gen_ok ? "ok" : "*** FAIL ***");

    /* ---- write the three ladders (v1) ---- */
    const char *fd = "/tmp/gt_selftest_f", *gd = "/tmp/gt_selftest_g", *td = "/tmp/gt_selftest_t";
    char cmd[512];
    snprintf(cmd, sizeof cmd, "rm -rf %s %s %s && mkdir -p %s %s %s", fd, gd, td, fd, gd, td);
    if (system(cmd)) {}
    uint32_t masks[64]; uint64_t off[65]; uint32_t keys[8192]; u192 vals[8192];
    uint64_t nm, ne;
    /* keep layer arrays for the corruption legs */
    static uint32_t Lmasks[3][GTS_NP+1][64]; static uint64_t Loff[3][GTS_NP+1][65];
    static uint32_t Lkeys[3][GTS_NP+1][8192]; static u192 Lvals[3][GTS_NP+1][8192];
    static uint64_t Lnm[3][GTS_NP+1], Lne[3][GTS_NP+1];
    for (int k = 0; k <= GTS_NP; k++) {
        gts_emit_layer(fd, "f1c5", "F1C5LAY1", 0, k, plh, R, tf, tf, rp, geff,
                       masks, &nm, off, keys, vals, &ne);
        memcpy(Lmasks[0][k], masks, sizeof masks); memcpy(Loff[0][k], off, sizeof off);
        memcpy(Lkeys[0][k], keys, sizeof keys);    memcpy(Lvals[0][k], vals, sizeof vals);
        Lnm[0][k] = nm; Lne[0][k] = ne;
        gts_emit_layer(gd, "g", "F1C5GLY1", 1, k, plh, R, tg, tf, rp, geff,
                       masks, &nm, off, keys, vals, &ne);
        memcpy(Lmasks[1][k], masks, sizeof masks); memcpy(Loff[1][k], off, sizeof off);
        memcpy(Lkeys[1][k], keys, sizeof keys);    memcpy(Lvals[1][k], vals, sizeof vals);
        Lnm[1][k] = nm; Lne[1][k] = ne;
        gts_emit_layer(td, "t", "F1C5TLY1", 2, k, plh, R, tt, tf, rp, geff,
                       masks, &nm, off, keys, vals, &ne);
        memcpy(Lmasks[2][k], masks, sizeof masks); memcpy(Loff[2][k], off, sizeof off);
        memcpy(Lkeys[2][k], keys, sizeof keys);    memcpy(Lvals[2][k], vals, sizeof vals);
        Lnm[2][k] = nm; Lne[2][k] = ne;
    }
    gts_write_manifest(fd, "f1c5", plh, GTS_NP);
    gts_write_manifest(gd, "g", plh, 0);
    gts_write_manifest(td, "t", plh, 0);
    free(tf); free(tg); free(tt);

    printf("\n[2] valid v1 g ladder vs f ladder (f*g identity at every layer) — must PASS:\n");
    int r2 = lc_check_g(fd, gd, 31);
    printf("\n[3] valid v1 t ladder vs f ladder (f*t node identity at every layer) — must PASS:\n");
    int r3 = lc_check_t(fd, td, 31);

    /* v2 leg: rewrite the whole g ladder per-block-zlib (BLK=8) */
    for (int k = 0; k <= GTS_NP; k++)
        gts_write_v2(gd, "g", "F1C5GLY2", k, plh, Lmasks[1][k], Lnm[1][k], Loff[1][k],
                     Lkeys[1][k], Lvals[1][k], Lne[1][k], 8);
    printf("\n[4] the same g ladder rewritten v2 (per-block zlib, BLK=8) — must PASS:\n");
    int r4 = lc_check_g(fd, gd, 31);

    /* corruption: one g value bumped at layer 2 — the f*g identity must catch
     * it. The bumped entry must be one that PAIRS with an f entry (the g
     * ladder legitimately stores suffix-only states with no f partner, whose
     * values never enter the identity), so search for a common (mask, key). */
    uint64_t gidx = UINT64_MAX;
    for (uint64_t mi = 0; mi < Lnm[1][2] && gidx == UINT64_MAX; mi++)
        for (uint64_t e = Loff[1][2][mi]; e < Loff[1][2][mi+1] && gidx == UINT64_MAX; e++)
            for (uint64_t a = Loff[0][2][mi]; a < Loff[0][2][mi+1]; a++)
                if (Lkeys[0][2][a] == Lkeys[1][2][e]) { gidx = e; break; }
    if (gidx == UINT64_MAX) { printf("*** FAIL: no f-paired g entry at layer 2 (fixture defect)\n"); return 1; }
    { u192 sv = Lvals[1][2][gidx];
      Lvals[1][2][gidx].l[0] += 1;
      gts_write_v1(gd, "g", "F1C5GLY1", 2, plh, Lmasks[1][2], Lnm[1][2], Loff[1][2],
                   Lkeys[1][2], Lvals[1][2], Lne[1][2]);
      printf("\n[5] g layer 2 with ONE f-paired value bumped by 1 — must FAIL (f*g identity):\n");
      int r5 = lc_check_g(fd, gd, 31);
      Lvals[1][2][gidx] = sv;
      gts_write_v1(gd, "g", "F1C5GLY1", 2, plh, Lmasks[1][2], Lnm[1][2], Loff[1][2],
                   Lkeys[1][2], Lvals[1][2], Lne[1][2]);
      /* corruption: one t value bumped at layer 3 */
      sv = Lvals[2][3][0];
      Lvals[2][3][0].l[0] += 1;
      gts_write_v1(td, "t", "F1C5TLY1", 3, plh, Lmasks[2][3], Lnm[2][3], Loff[2][3],
                   Lkeys[2][3], Lvals[2][3], Lne[2][3]);
      printf("\n[6] t layer 3 with ONE value bumped by 1 — must FAIL (f*t identity):\n");
      int r6 = lc_check_t(fd, td, 31);
      Lvals[2][3][0] = sv;
      gts_write_v1(td, "t", "F1C5TLY1", 3, plh, Lmasks[2][3], Lnm[2][3], Loff[2][3],
                   Lkeys[2][3], Lvals[2][3], Lne[2][3]);
      /* geometry tamper: a t key changed — mirror check must catch */
      uint32_t sk = Lkeys[2][1][0];
      Lkeys[2][1][0] ^= 1u;                                   /* different rid */
      gts_write_v1(td, "t", "F1C5TLY1", 1, plh, Lmasks[2][1], Lnm[2][1], Loff[2][1],
                   Lkeys[2][1], Lvals[2][1], Lne[2][1]);
      printf("\n[7] t layer 1 with ONE key changed — must FAIL (f-geometry mirror):\n");
      int r7 = lc_check_t(fd, td, 31);
      Lkeys[2][1][0] = sk;
      /* magic confusion: t layer written with the g magic — must be rejected */
      gts_write_v1(td, "t", "F1C5GLY1", 1, plh, Lmasks[2][1], Lnm[2][1], Loff[2][1],
                   Lkeys[2][1], Lvals[2][1], Lne[2][1]);
      printf("\n[8] t layer 1 carrying the g magic F1C5GLY1 — must FAIL (kind confusion):\n");
      int r8 = lc_check_t(fd, td, 31);
      gts_write_v1(td, "t", "F1C5TLY1", 1, plh, Lmasks[2][1], Lnm[2][1], Loff[2][1],
                   Lkeys[2][1], Lvals[2][1], Lne[2][1]);
      /* seed tamper: g layer n with a value 2 — exact-seed check must catch */
      sv = Lvals[1][GTS_NP][0];
      Lvals[1][GTS_NP][0] = (u192){{2, 0, 0}};
      gts_write_v1(gd, "g", "F1C5GLY1", GTS_NP, plh, Lmasks[1][GTS_NP], Lnm[1][GTS_NP],
                   Loff[1][GTS_NP], Lkeys[1][GTS_NP], Lvals[1][GTS_NP], Lne[1][GTS_NP]);
      printf("\n[9] g seed layer with a value != 1 — must FAIL (exact seed content):\n");
      int r9 = lc_check_g(fd, gd, 31);
      Lvals[1][GTS_NP][0] = sv;

      printf("\n======================================================================\n");
      int ok = gen_ok && r2 == 0 && r3 == 0 && r4 == 0 &&
               r5 != 0 && r6 != 0 && r7 != 0 && r8 != 0 && r9 != 0;
      printf("GT SELFTEST: anchors=%s  g-v1=%s  t-v1=%s  g-v2=%s  g-tamper=%s  t-tamper=%s\n"
             "             t-geom-tamper=%s  magic-confusion=%s  seed-tamper=%s  =>  %s\n",
             gen_ok?"Y":"N", r2==0?"Y":"N", r3==0?"Y":"N", r4==0?"Y":"N",
             r5!=0?"Y":"N", r6!=0?"Y":"N", r7!=0?"Y":"N", r8!=0?"Y":"N", r9!=0?"Y":"N",
             ok ? "PASS" : "*** FAIL ***");
      printf("======================================================================\n");
      return ok ? 0 : 1;
    }
}

/* ==========================================================================
 * ROUTE B — THE INDEPENDENT INCLUSION–EXCLUSION TRANSFER-WALK RECOUNT
 *   --ie-count [opts]          (the engine; full-31 or any reduced rung)
 *   --ie-probe NSAMP [opts]    (full-31 throughput probe for cost sizing)
 *
 * PURPOSE. TR-11 §10(vi): the landed |C1∩C2∩C4∩C5| =
 * 1,097,051,278,789,181,790,036,112,071,176,579,186,688 rests on a single
 * instrument (the out-of-core symmetry-quotient layered DP in solve.c).
 * This mode is the genuinely-independent second engine: a different
 * algorithm class that recomputes the same integer at full scale while
 * sharing NONE of the primary's machinery — no canonical-mask bookkeeping,
 * no gather/canonicalization/inverse-element mapping, no stabilizer
 * weighting, no layer files, no out-of-core streaming, no 192-bit hot-path
 * arithmetic. Shares only this file's already-independent helpers
 * (build_pairs / derive_pair_perms / lc_restrict_perms / lc_radix / u192).
 *
 * ALGORITHM (classical signed inclusion–exclusion — Karp-1982-style
 * Hamiltonian-walk counting; cf. Ryser, Björklund–Husfeldt; used, not
 * invented, here): with F = the instance's free pairs (31 at full scale),
 *
 *     N = Σ_{S ⊆ F} (−1)^{|F|−|S|} · W(S)
 *
 * where W(S) = the number of |F|-step walks with REPETITION ALLOWED whose
 * steps are (pair ∈ S, orientation), starting from the C4-pinned exit
 * hexagram, each step's boundary class d = popcount(last ⊕ enter) required
 * ∈ {1,2,3,4,6} (d = 0 and the C2-forbidden d = 5 excluded), with the
 * running class-usage vector capped componentwise at the instance budget
 * B0. Walk admissibility does not depend on S, so IE is sound; since
 * Σ_c B0_c = |F|, every capped |F|-step walk ends at exactly B0, and a walk
 * whose pair-set is all of F uses each pair exactly once — i.e. is exactly
 * a C1∩C2∩C4∩C5 sequence. DP state = (last hexagram, budget vector): at
 * full 31 that is 64 × ≤413 slots per layer (<1 MB per thread, no disk).
 *
 * THE 24-GROUP IS USED ONLY AS A SUBSET-ENUMERATION LEMMA. Each of TR-5's
 * 24 pair-permutations is induced by a bit-position permutation commuting
 * with reversal; such a g is a Hamming isometry fixing Kun(0) and Qian(63)
 * pointwise, so it maps admissible walks over S bijectively onto admissible
 * walks over gS: W(gS) = W(S), |gS| = |S|. The outer sum may therefore run
 * over canonical subsets (numeric min of orbit) weighted by orbit size.
 * Every premise is re-verified ELEMENTWISE at startup (ie_verify_group):
 * witness bit-perms are bijections on positions, fix 0 and 63 (hence the
 * start), are Hamming isometries on all 64×64 hexagram pairs, and map pair
 * j onto pair σ(j) as an unordered set. --ie-no-quotient disables the
 * lemma entirely (full 2^n outer loop); quotiented == unquotiented is part
 * of the validation ladder, and Σ orbit-weights == 2^n is checked on every
 * full-space quotiented pass.
 *
 * ARITHMETIC. Hot path is add-only uint64: values mod one 63-bit prime per
 * pass (three passes, CRT-combined offline — N < p0·p1·p2 ≈ 7.8e56), or
 * natural mod-2^64 wraparound ("wrap": exact whenever N < 2^64, i.e. on
 * the small-n rungs — an internal cross-check of the mod-p path). The
 * three primes are the largest primes below 2^63, found by downward scan
 * and proven prime at startup by deterministic Miller–Rabin (bases
 * 2..37 — deterministic far beyond 2^64); nothing is trusted from a doc.
 *
 * CHECKPOINTING (Spot-safe). The subset space is cut into fixed chunks;
 * each completed chunk's partial sums are appended to --ie-checkpoint and
 * fsync'd. Chunk results are deterministic (scheduling-independent), so a
 * resumed pass reproduces the uninterrupted pass exactly.
 *
 * USAGE:
 *   ./verify --ie-count [--ie-spec "3.0,3.1,3.2@0" | --ie-spec full31@0]
 *            [--ie-mod all|wrap|p0|p1|p2] [--ie-no-quotient] [--ie-no-budget]
 *            [--ie-threads N] [--ie-chunk-bits B] [--ie-checkpoint FILE]
 *            [--ie-range LO HI] [--ie-b0 a,b,c,d,e] [--ie-negctl]
 *            [--ie-expect DECIMAL] [--ie-pin SLOT:PAIR ...] [--ie-pin-c6c7]
 *            [--ie-brute]
 *   ./verify --ie-probe NSAMP [--ie-threads N]
 * Defaults: spec full31@0; mod all (= wrap+p0+p1+p2 when n≤19, else p0+p1+p2);
 * threads = online CPUs. Reduced-rung budgets are derived by TR-11 §5's
 * Step-1 first-completion DFS; the full-31 budget is DEFINED as KW's
 * boundary multiset (TR-11 v1.8). --ie-negctl swaps B0's d2/d4 budgets —
 * a negative control whose count MUST differ from the published value.
 *
 * --ie-no-budget (the F4 variant): drop the C5 budget lattice entirely and
 * count |C1 cap C2 cap C4| instead. Same signed IE over pair subsets, same
 * quotient lemma (its proof never used the budget); W(S) collapses to a
 * plain 64-state transfer walk (state = last hexagram). Soundness of the
 * shared d∉{0,5} step predicate: a support-full walk uses each pair once,
 * so consecutive hexagrams come from distinct pairs and d=0 cannot occur —
 * the predicate equals published C2 (d≠5) on exactly the walks that
 * survive the signed sum. Full-31 target = LC_PUBLISHED_COUNT_C1C2C4.
 * With --ie-negctl, admissibility is perturbed to forbid d=4 instead of
 * d=5 (budgets don't exist here) — the count MUST differ.
 *
 * --ie-pin SLOT:PAIR (repeatable) / --ie-pin-c6c7 (the T3 variant): FORCE
 * walk step SLOT (1-based; step k fills pair-slot k of the final ordering,
 * slot 0 being the C4-pinned pair 0) to place pair index PAIR (KW pair
 * order, 0..31; must be in the instance's pair list). Orientations stay
 * free. The IE identity extends untouched: define W(S) = capped walks
 * whose UNPINNED steps draw from S x {0,1} and whose pinned steps are
 * forced to their pinned pair (so W(S) = 0 unless S contains every pinned
 * pair — the outer sum collapses onto S = pins ∪ T, T ⊆ the unpinned
 * pairs). Then sum_{T} (-1)^{|F|-|pins|-|T|} W(pins ∪ T) counts exactly
 * the walks whose total pair support is all of F: with |F| steps that
 * forces each pair to be used exactly once (a permutation walk) with the
 * pinned slots holding their pinned pairs — i.e. the slot-pinned count.
 * Pinning the SAME pair at two slots is allowed and must yield 0 (no
 * permutation walk repeats a pair) — a built-in self-test.
 *
 * --ie-pin-c6c7 (requires full31@0) pins slots 24..27 to KW pairs
 * #24..27 — the SPECIFICATION.md C6+C7 adjacency constraints: C7 pins
 * {s48,s49}={29,46} & {s50,s51}={9,36} (slots 24,25); C6 pins
 * {s52,s53}={11,52} & {s54,s55}={13,44} (slots 26,27). The pinned pairs
 * are derived from the KW[] table and CROSS-CHECKED elementwise against
 * those SPEC hexagram constants at startup. Together with the full-31
 * budget this counts |C1∩C2∩C4∩C5∩C6∩C7| — the "C1–C7, C3 dropped" row,
 * published only as a Knuth ESTIMATE 5.18e32 (0.25%); there is no exact
 * target, so no default --ie-expect in pinned mode.
 *
 * HONEST GATE LOSS (pins): the pinned subset space is NOT closed under
 * the 24-group (the pointwise stabilizer of pairs {24,25,26,27} is
 * trivial), so (a) the quotient lemma is unavailable — pinned runs
 * REQUIRE --ie-no-quotient (enforced), and (b) the mod-24 free-action
 * divisibility gate does NOT apply (correct divisor = 1); N mod 24 is
 * printed as information only. Compensating validation: small-n pinned
 * counts vs the --ie-brute independent permutation DFS, the pin-sum
 * identity (sum over all pins of one slot == the unpinned count, whose
 * engine is externally validated), duplicate-pin == 0, CRT==wrap at
 * small n, and the estimator-envelope cross-check at full 31.
 *
 * --ie-brute (small n only, n <= 12): count by an explicit permutation
 * DFS over (pair, orientation) placements — a different algorithm class
 * from the signed IE sum (no subsets, no signs; direct enumeration with
 * used-pair bookkeeping). Reference instrument for the pinned small-n
 * ladder; honors pins, budget/no-budget, and negctl identically.
 * ========================================================================== */

/* ---- deterministic Miller–Rabin + the three 63-bit primes ---- */
static uint64_t ie_mulmod(uint64_t a, uint64_t b, uint64_t m) {
    return (uint64_t)((unsigned __int128)a * b % m);
}
static uint64_t ie_powmod(uint64_t a, uint64_t e, uint64_t m) {
    uint64_t r = 1 % m; a %= m;
    while (e) { if (e & 1) r = ie_mulmod(r, a, m); a = ie_mulmod(a, a, m); e >>= 1; }
    return r;
}
static int ie_is_prime_u64(uint64_t n) {
    static const uint64_t B[12] = {2,3,5,7,11,13,17,19,23,29,31,37};
    if (n < 2) return 0;
    for (int i = 0; i < 12; i++) { if (n == B[i]) return 1; if (n % B[i] == 0) return 0; }
    uint64_t d = n - 1; int s = 0;
    while (!(d & 1)) { d >>= 1; s++; }
    for (int i = 0; i < 12; i++) {   /* deterministic for all n < 3.317e24 > 2^64 */
        uint64_t x = ie_powmod(B[i], d, n);
        if (x == 1 || x == n - 1) continue;
        int ok = 0;
        for (int r = 1; r < s; r++) { x = ie_mulmod(x, x, n); if (x == n - 1) { ok = 1; break; } }
        if (!ok) return 0;
    }
    return 1;
}
static void ie_pick_primes(uint64_t p[3]) {      /* the 3 largest primes < 2^63 */
    int k = 0;
    for (uint64_t c = 0x7fffffffffffffffULL; k < 3; c -= 2)
        if (ie_is_prime_u64(c)) p[k++] = c;
}
static uint64_t ie_invmod(uint64_t a, uint64_t m) {   /* modular inverse, gcd(a,m)=1 */
    long long t = 0, nt = 1, r = (long long)m, nr = (long long)(a % m);
    while (nr) {
        long long q = r / nr, tmp;
        tmp = t - q * nt; t = nt; nt = tmp;
        tmp = r - q * nr; r = nr; nr = tmp;
    }
    if (t < 0) t += (long long)m;
    return (uint64_t)t;
}
/* CRT (Garner) for 3 pairwise-coprime 63-bit moduli; N < p0*p1*p2 assumed. */
static void ie_crt3(const uint64_t p[3], const uint64_t a[3], u192 *out) {
    uint64_t x1 = ie_mulmod((a[1] + p[1] - a[0] % p[1]) % p[1],
                            ie_invmod(p[0] % p[1], p[1]), p[1]);
    unsigned __int128 v01 = (unsigned __int128)p[0] * x1 + a[0];
    uint64_t v01m = (uint64_t)(v01 % p[2]);
    uint64_t p01m = ie_mulmod(p[0] % p[2], p[1] % p[2], p[2]);
    uint64_t x2 = ie_mulmod((a[2] + p[2] - v01m) % p[2], ie_invmod(p01m, p[2]), p[2]);
    unsigned __int128 p01 = (unsigned __int128)p[0] * p[1];
    u192 N   = {{ (uint64_t)v01, (uint64_t)(v01 >> 64), 0 }};
    u192 P01 = {{ (uint64_t)p01, (uint64_t)(p01 >> 64), 0 }};
    u192 X2  = {{ x2, 0, 0 }};
    int ovf = 0;
    u192 T = u192_mul(P01, X2, &ovf);
    (void)ovf;                        /* < 2^126 * 2^63 = 2^189: fits u192 */
    u192_add(&N, T);
    *out = N;
}

/* ---- elementwise startup re-verification of the subset-enumeration lemma ---- */
static int ie_verify_group(int start) {
    if (NPP != 24) return 0;
    for (int q = 0; q < NPP; q++) {
        const uint8_t *g = PPG[q];
        int seen = 0;
        for (int i = 0; i < 6; i++) { if (g[i] > 5) return 0; seen |= 1 << g[i]; }
        if (seen != 63) return 0;                       /* bijection on positions */
        int img[64];
        for (int x = 0; x < 64; x++) {
            int r = 0;
            for (int i = 0; i < 6; i++) if ((x >> i) & 1) r |= 1 << g[i];
            img[x] = r;
        }
        if (img[0] != 0 || img[63] != 63) return 0;     /* fixes Kun and Qian */
        if (img[start] != start) return 0;              /* fixes the walk start */
        for (int x = 0; x < 64; x++)                    /* Hamming isometry, all 64x64 */
            for (int y = 0; y < 64; y++)
                if (popcount6(img[x] ^ img[y]) != popcount6(x ^ y)) return 0;
        for (int j = 0; j < 32; j++) {                  /* maps pair j to pair PP[q][j] */
            int ja = img[PA[j]], jb = img[PB[j]], tj = PP[q][j];
            if (!((PA[tj] == ja && PB[tj] == jb) || (PA[tj] == jb && PB[tj] == ja)))
                return 0;
        }
    }
    return 1;
}

/* ---- pair-orbit table (derived, TR-11 §"pair-orbit partition" labeling) ---- */
static int ie_orb_row[8][6], ie_orb_sz[8], ie_orb_n;
static int ie_build_orbits(void) {
    int seen[32] = {0};
    ie_orb_n = 0;
    for (int i = 1; i < 32; i++) {            /* ascending min element by construction */
        if (seen[i]) continue;
        int mem[32], nm = 0;
        for (int q = 0; q < NPP; q++) {
            int im = PP[q][i], dup = 0;
            for (int t = 0; t < nm; t++) if (mem[t] == im) dup = 1;
            if (!dup) mem[nm++] = im;
        }
        for (int a = 0; a < nm; a++)
            for (int b = a + 1; b < nm; b++)
                if (mem[b] < mem[a]) { int t = mem[a]; mem[a] = mem[b]; mem[b] = t; }
        if (nm > 6 || ie_orb_n >= 8) return 0;
        for (int t = 0; t < nm; t++) { ie_orb_row[ie_orb_n][t] = mem[t]; seen[mem[t]] = 1; }
        ie_orb_sz[ie_orb_n++] = nm;
    }
    return 1;
}
/* "L.I,L.I,...@START" or "full31[@START]" -> ordered pair list (spec order). */
static int ie_parse_spec(const char *spec, int *pl, int *np, int *start) {
    char buf[256];
    strncpy(buf, spec, 255); buf[255] = 0;
    char *at = strchr(buf, '@');
    *start = 0;
    if (at) { *start = atoi(at + 1); *at = 0; }
    if (*start != 0 && *start != 63) return 0;
    int n = 0;
    if (!strcmp(buf, "full31")) { for (int i = 1; i < 32; i++) pl[n++] = i; *np = n; return 1; }
    for (char *tok = strtok(buf, ","); tok; tok = strtok(NULL, ",")) {
        int L, I;
        if (sscanf(tok, "%d.%d", &L, &I) != 2) return 0;
        int idx = -1, cnt = 0;
        for (int r = 0; r < ie_orb_n; r++) {
            if (ie_orb_sz[r] != L) continue;
            if (cnt == I) { idx = r; break; }
            cnt++;
        }
        if (idx < 0) return 0;
        for (int t = 0; t < L; t++) { if (n >= 31) return 0; pl[n++] = ie_orb_row[idx][t]; }
    }
    *np = n;
    return n > 0;
}

/* ---- TR-11 §5 Step 1: first-completion DFS budget for a reduced rung ---- */
static int ie_b0g_found;
static void ie_b0g_dfs(const int *pl, int n, int depth, int last, uint32_t used,
                       int cnt[5], int out[5]) {
    if (ie_b0g_found) return;
    if (depth == n) { memcpy(out, cnt, 5 * sizeof(int)); ie_b0g_found = 1; return; }
    for (int i = 0; i < n && !ie_b0g_found; i++) {
        if (used & (1u << i)) continue;
        int a = PA[pl[i]], b = PB[pl[i]];
        for (int o = 0; o < 2 && !ie_b0g_found; o++) {
            int f = o == 0 ? b : a;                 /* §5: o=0 enters b, exits a */
            int s = o == 0 ? a : b;
            int d = hamming(last, f);
            if (d == 5 || d == 0) continue;
            int ci = cls_ix(d);
            cnt[ci]++;
            ie_b0g_dfs(pl, n, depth + 1, s, used | (1u << i), cnt, out);
            if (!ie_b0g_found) cnt[ci]--;
        }
    }
}

/* ---- instance context ---- */
typedef struct {
    int n, start, quotient;
    int no_budget;             /* --ie-no-budget: count C1∩C2∩C4 (C5/budget layer
                                * dropped; DP state collapses to (last) alone) */
    int nb_negctl;             /* no-budget negative control: forbid d=4 instead of
                                * d=5 (perturbed C2 predicate) — count MUST differ */
    int npin;                  /* --ie-pin: number of pinned steps (0 = none) */
    int pin_at[32];            /* [step k]: pinned pl-position, or -1 (T3 variant) */
    uint32_t pinmask;          /* OR of 1<<position over pinned positions */
    int freepos[32], nfree;    /* unpinned pl-positions; outer sum = 2^nfree subsets
                                * (t-space); mask = pinmask | expand(t)  */
    char pinstr[160];          /* "24:24,25:25,..." — checkpoint-header pinning */
    int pl[32];
    int b0v[5];
    uint32_t rad[5], R;
    int16_t (*succ)[5];        /* [R][5]: slot in next layer, or -1 at cap */
    uint8_t  *layv;            /* [R]: layer = digit sum */
    uint16_t *slotv;           /* [R]: slot within its layer */
    int nv[33];                /* vectors per layer */
    uint16_t *vid[33];         /* per-layer rid lists */
    int maxnv;
    int8_t  cmap[64][64];      /* [2q+o][last]: class index or -1 */
    uint8_t exq[64];           /* [2q+o]: exit hexagram */
    int geff;
    uint8_t rp[24][32];        /* restricted pair-perms on subset indices */
    uint32_t (*tlo)[65536];    /* [geff]: mask-image tables, bits 0..15 */
    uint32_t (*thi)[32768];    /* [geff]: bits 16..30 */
} IeCtx;

static int ie_build(IeCtx *C) {
    if (C->n < 1 || C->n > 31) { printf("*** FAIL: n=%d out of range\n", C->n); return 0; }
    if (C->no_budget) {
        /* C1∩C2∩C4 mode: no budget lattice at all. Walk state = (last) alone,
         * one 64-slot row per layer (maxnv=1 sizes the worker buffers). The
         * IE identity is unchanged: a 31-step walk whose pair support is all
         * of F uses each pair exactly once regardless of any budget, and d=0
         * cannot occur on such walks (distinct pairs => distinct hexagrams),
         * so the per-step d∉{0,5} predicate equals the published C2 predicate
         * d≠5 on exactly the walks the signed sum keeps. */
        C->R = 0; C->maxnv = 1;
        memset(C->cmap, -1, sizeof C->cmap);
        int bad = C->nb_negctl ? 4 : 5;
        for (int q = 0; q < C->n; q++) {
            int a = PA[C->pl[q]], b = PB[C->pl[q]];
            for (int o = 0; o < 2; o++) {
                int enter = o ? b : a, exith = o ? a : b, qo = 2 * q + o;
                C->exq[qo] = (uint8_t)exith;
                for (int last = 0; last < 64; last++) {
                    int d = hamming(last, enter);
                    /* class index is unused without a budget: 0 = admissible */
                    C->cmap[qo][last] = (int8_t)((d == bad || d == 0) ? -1 : 0);
                }
            }
        }
        return 1;
    }
    int sum = 0;
    for (int c = 0; c < 5; c++) { if (C->b0v[c] < 0) return 0; sum += C->b0v[c]; }
    if (sum != C->n) {
        printf("*** FAIL: budget sum %d != n=%d (every %d-step capped walk must end at B0)\n",
               sum, C->n, C->n);
        return 0;
    }
    lc_radix(C->b0v, C->rad, &C->R);
    if (C->R < 1 || C->R > 20000) { printf("*** FAIL: lattice size R=%u out of range\n", C->R); return 0; }
    C->succ  = malloc(sizeof(int16_t[5]) * C->R);
    C->layv  = malloc(C->R);
    C->slotv = malloc(2 * (size_t)C->R);
    if (!C->succ || !C->layv || !C->slotv) return 0;
    memset(C->nv, 0, sizeof C->nv);
    for (uint32_t rid = 0; rid < C->R; rid++) {
        int s = lc_rid_digits(rid, C->b0v, C->rad);      /* digit sum (never -1 here) */
        C->layv[rid]  = (uint8_t)s;
        C->slotv[rid] = (uint16_t)C->nv[s]++;
    }
    C->maxnv = 0;
    for (int k = 0; k <= C->n; k++) {
        C->vid[k] = malloc(2 * (size_t)(C->nv[k] ? C->nv[k] : 1));
        if (!C->vid[k]) return 0;
        if (C->nv[k] > C->maxnv) C->maxnv = C->nv[k];
    }
    {   int fill[33] = {0};
        for (uint32_t rid = 0; rid < C->R; rid++)
            C->vid[C->layv[rid]][fill[C->layv[rid]]++] = (uint16_t)rid;
    }
    for (uint32_t rid = 0; rid < C->R; rid++)
        for (int c = 0; c < 5; c++) {
            uint32_t digit = (rid / C->rad[c]) % (uint32_t)(C->b0v[c] + 1);
            C->succ[rid][c] = (digit < (uint32_t)C->b0v[c])
                              ? (int16_t)C->slotv[rid + C->rad[c]] : (int16_t)-1;
        }
    if (C->nv[C->n] != 1 || C->vid[C->n][0] != C->R - 1) {
        printf("*** FAIL: layer n must hold exactly the all-cap vector\n");
        return 0;
    }
    memset(C->cmap, -1, sizeof C->cmap);
    for (int q = 0; q < C->n; q++) {
        int a = PA[C->pl[q]], b = PB[C->pl[q]];
        for (int o = 0; o < 2; o++) {
            int enter = o ? b : a, exith = o ? a : b, qo = 2 * q + o;
            C->exq[qo] = (uint8_t)exith;
            for (int last = 0; last < 64; last++) {
                int d = hamming(last, enter);
                C->cmap[qo][last] = (int8_t)((d == 5 || d == 0) ? -1 : cls_ix(d));
            }
        }
    }
    return 1;
}

static int ie_build_quot(IeCtx *C) {
    uint32_t pl32[32];
    for (int i = 0; i < C->n; i++) pl32[i] = (uint32_t)C->pl[i];
    C->geff = lc_restrict_perms(pl32, (uint32_t)C->n, C->rp);
    if (C->geff < 1) { printf("*** FAIL: restricted pair-perms are not a group\n"); return 0; }
    C->tlo = malloc(sizeof(uint32_t[65536]) * C->geff);
    C->thi = malloc(sizeof(uint32_t[32768]) * C->geff);
    if (!C->tlo || !C->thi) return 0;
    int lo_bits = C->n < 16 ? C->n : 16;
    int nhi = C->n > 16 ? C->n - 16 : 0;
    for (int q = 0; q < C->geff; q++) {
        for (uint32_t v = 0; v < 65536u; v++) {
            uint32_t im = 0, t = v & ((1u << lo_bits) - 1);
            while (t) { int b = __builtin_ctz(t); t &= t - 1; im |= 1u << C->rp[q][b]; }
            C->tlo[q][v] = im;
        }
        for (uint32_t v = 0; v < 32768u; v++) {
            uint32_t im = 0, t = nhi ? (v & ((1u << nhi) - 1)) : 0;
            while (t) { int b = __builtin_ctz(t); t &= t - 1; im |= 1u << C->rp[q][b + 16]; }
            C->thi[q][v] = im;
        }
    }
    return 1;
}
/* 1 = canonical (orbit size in *orbit), 0 = not canonical, -1 = group defect. */
static inline int ie_canon_orbit(const IeCtx *C, uint32_t m, int *orbit) {
    int stab = 0;
    for (int q = 0; q < C->geff; q++) {
        uint32_t im = C->tlo[q][m & 0xFFFFu] | C->thi[q][m >> 16];
        if (im < m) return 0;
        if (im == m) stab++;
    }
    if (stab == 0 || C->geff % stab) return -1;
    *orbit = C->geff / stab;
    return 1;
}

/* ---- the transfer-walk kernel: W(S) mod (mod ? mod : 2^64) ---- */
static uint64_t ie_walk(const IeCtx *C, uint32_t S, uint64_t mod,
                        uint64_t *cur, uint64_t *nxt, uint64_t *tcnt) {
    int n = C->n;
    uint64_t t = 0;
    memset(cur, 0, (size_t)C->nv[0] * 64 * 8);
    cur[C->start] = 1;                               /* layer 0: zero vector, slot 0 */
    for (int k = 0; k < n; k++) {
        memset(nxt, 0, (size_t)C->nv[k + 1] * 64 * 8);
        /* pinned step: alphabet is the single pinned pair (x2 orientations) */
        uint32_t Sk = (C->npin && C->pin_at[k] >= 0) ? (1u << C->pin_at[k]) : S;
        const uint16_t *vl = C->vid[k];
        for (int vi = 0; vi < C->nv[k]; vi++) {
            const int16_t *sc = C->succ[vl[vi]];
            const uint64_t *row = cur + (size_t)vi * 64;
            for (int last = 0; last < 64; last++) {
                uint64_t val = row[last];
                if (!val) continue;
                uint32_t tmp = Sk;
                while (tmp) {
                    int q = __builtin_ctz(tmp); tmp &= tmp - 1;
                    for (int o = 0; o < 2; o++) {
                        int qo = 2 * q + o;
                        int cl = C->cmap[qo][last];
                        if (cl < 0) continue;
                        int sl = sc[cl];
                        if (sl < 0) continue;
                        uint64_t *tp = nxt + (size_t)sl * 64 + C->exq[qo];
                        uint64_t nv2 = *tp + val;
                        if (mod && nv2 >= mod) nv2 -= mod;
                        *tp = nv2;
                        t++;
                    }
                }
            }
        }
        uint64_t *sw = cur; cur = nxt; nxt = sw;
    }
    uint64_t acc = 0;                                /* layer n: single vector (=B0) */
    for (int last = 0; last < 64; last++) {
        acc += cur[last];
        if (mod && acc >= mod) acc -= mod;
    }
    *tcnt += t;
    return acc;
}

/* ---- the no-budget kernel (--ie-no-budget): W(S) with state = (last) alone.
 * Same signed-IE outer sum, same d-admissibility via cmap, no lattice: the
 * C1∩C2∩C4 count needs no class-usage tracking. cur/nxt are 64 u64s each. */
static uint64_t ie_walk_nb(const IeCtx *C, uint32_t S, uint64_t mod,
                           uint64_t *cur, uint64_t *nxt, uint64_t *tcnt) {
    int n = C->n;
    uint64_t t = 0;
    memset(cur, 0, 64 * 8);
    cur[C->start] = 1;
    for (int k = 0; k < n; k++) {
        memset(nxt, 0, 64 * 8);
        uint32_t Sk = (C->npin && C->pin_at[k] >= 0) ? (1u << C->pin_at[k]) : S;
        for (int last = 0; last < 64; last++) {
            uint64_t val = cur[last];
            if (!val) continue;
            uint32_t tmp = Sk;
            while (tmp) {
                int q = __builtin_ctz(tmp); tmp &= tmp - 1;
                for (int o = 0; o < 2; o++) {
                    int qo = 2 * q + o;
                    if (C->cmap[qo][last] < 0) continue;
                    uint64_t *tp = nxt + C->exq[qo];
                    uint64_t nv2 = *tp + val;
                    if (mod && nv2 >= mod) nv2 -= mod;
                    *tp = nv2;
                    t++;
                }
            }
        }
        uint64_t *sw = cur; cur = nxt; nxt = sw;
    }
    uint64_t acc = 0;
    for (int last = 0; last < 64; last++) {
        acc += cur[last];
        if (mod && acc >= mod) acc -= mod;
    }
    *tcnt += t;
    return acc;
}

/* ---- --ie-brute: independent small-n reference — explicit permutation DFS.
 * A different algorithm class from the signed IE sum: enumerates actual
 * (pair, orientation) placements one by one with used-pair bookkeeping; no
 * subsets, no signs, no transfer matrix. Honors pins (a pinned step tries
 * only its pinned pair; if that pair is already used, the branch dies — so
 * duplicate pins correctly yield 0), the budget cap (capped walks end at B0
 * exactly since sum(B0) = n), no-budget mode, and negctl via the shared
 * cmap admissibility table. Counts fit u64 by the n <= 12 guard. ---- */
static void ie_brute_dfs(const IeCtx *C, int k, int last, uint32_t used,
                         int cnt[5], uint64_t *out) {
    if (k == C->n) { (*out)++; return; }
    int qlo = 0, qhi = C->n;
    if (C->npin && C->pin_at[k] >= 0) { qlo = C->pin_at[k]; qhi = qlo + 1; }
    for (int q = qlo; q < qhi; q++) {
        if (used & (1u << q)) continue;
        for (int o = 0; o < 2; o++) {
            int qo = 2 * q + o;
            int cl = C->cmap[qo][last];
            if (cl < 0) continue;
            if (C->no_budget) {
                ie_brute_dfs(C, k + 1, C->exq[qo], used | (1u << q), cnt, out);
            } else {
                if (cnt[cl] >= C->b0v[cl]) continue;
                cnt[cl]++;
                ie_brute_dfs(C, k + 1, C->exq[qo], used | (1u << q), cnt, out);
                cnt[cl]--;
            }
        }
    }
}

/* Q-286 / Codex R12b false accept #13: "IE and DP checkpoint rows are trusted without
 * integrity protection ... corruption inside a complete row is the false accept." A torn
 * FINAL row is safe because fscanf will not parse it; a row that is complete but wrong is
 * summed in silently, and the pass reports a clean residue for a total it never computed.
 *
 * That matters more here than anywhere else in this file: the whole purpose of the full-31
 * Route B recount is to be a SECOND, INDEPENDENT derivation of a published integer. An
 * eviction-resumed run that silently absorbs one corrupted row produces a wrong number wearing
 * the word "independent". The resume gate landed 2026-08-27 showed a corrupted row CHANGES the
 * residue; it did not show anything DETECTS it, because nothing did.
 *
 * FNV-1a over the five values plus the chunk index. This is an integrity check against silent
 * corruption -- a torn write, a bad sector, a half-flushed page -- and is not, and does not
 * claim to be, protection against deliberate tampering. */
static uint64_t ie_ck_hash(uint64_t ci, uint64_t a, uint64_t w, uint64_t s, uint64_t t) {
    uint64_t h = 1469598103934665603ULL;   /* FNV-1a offset basis */
    uint64_t v[5]; v[0]=ci; v[1]=a; v[2]=w; v[3]=s; v[4]=t;
    for (int i = 0; i < 5; i++)
        for (int b = 0; b < 8; b++) {
            h ^= (v[i] >> (b * 8)) & 0xff;
            h *= 1099511628211ULL;         /* FNV prime */
        }
    return h;
}

/* ---- threaded pass over a subset-mask range, chunked + checkpointed ---- */
typedef struct {
    IeCtx *C;
    uint64_t mod;
    uint64_t range_lo, range_hi;
    int chunk_bits;
    uint64_t nchunks;
    uint8_t *done;
    uint64_t next;                                   /* atomic chunk cursor */
    uint64_t acc, wsum, subs, trans;
    double cpu_ns;
    int fatal;
    pthread_mutex_t mu;
    FILE *ckpt;
} IeRun;

static void *ie_worker(void *arg) {
    IeRun *R = arg;
    IeCtx *C = R->C;
    uint64_t *cur = malloc((size_t)C->maxnv * 64 * 8);
    uint64_t *nxt = malloc((size_t)C->maxnv * 64 * 8);
    if (!cur || !nxt) { free(cur); free(nxt); return (void *)1; }
    uint64_t csz = 1ull << R->chunk_bits;
    for (;;) {
        uint64_t ci = __atomic_fetch_add(&R->next, 1, __ATOMIC_RELAXED);
        if (ci >= R->nchunks) break;
        if (R->done[ci]) continue;
        uint64_t lo = R->range_lo + ci * csz, hi = lo + csz;
        if (hi > R->range_hi) hi = R->range_hi;
        struct timespec t0, t1;
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t0);
        uint64_t acc = 0, wsum = 0, subs = 0, tcnt = 0;
        int bad = 0;
        for (uint64_t m = lo; m < hi; m++) {
            int orbit = 1;
            uint32_t act;                 /* actual pair-subset mask */
            if (C->npin) {
                /* pinned mode: m ranges over the 2^nfree t-space; the
                 * subset is pins ∪ expand(t). Quotient is forbidden here
                 * (enforced in the driver): the pinned space is not
                 * group-closed. */
                act = C->pinmask;
                uint32_t t2 = (uint32_t)m;
                while (t2) {
                    int b = __builtin_ctz(t2); t2 &= t2 - 1;
                    act |= 1u << C->freepos[b];
                }
            } else {
                act = (uint32_t)m;
                if (C->quotient) {
                    int r = ie_canon_orbit(C, act, &orbit);
                    if (r == 0) continue;
                    if (r < 0) { bad = 1; break; }
                }
            }
            uint64_t W = C->no_budget
                       ? ie_walk_nb(C, act, R->mod, cur, nxt, &tcnt)
                       : ie_walk(C, act, R->mod, cur, nxt, &tcnt);
            int neg = ((C->n - __builtin_popcount(act)) & 1);
            if (R->mod) {
                uint64_t term = (uint64_t)((unsigned __int128)W * (unsigned)orbit % R->mod);
                acc = neg ? (acc >= term ? acc - term : acc + R->mod - term)
                          : (acc + term >= R->mod ? acc + term - R->mod : acc + term);
            } else {
                uint64_t term = W * (uint64_t)orbit;   /* mod 2^64 by wraparound */
                acc = neg ? acc - term : acc + term;
            }
            wsum += (uint64_t)orbit;
            subs++;
        }
        clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t1);
        pthread_mutex_lock(&R->mu);
        if (bad) R->fatal = 1;
        else {
            if (R->mod) { R->acc += acc; if (R->acc >= R->mod) R->acc -= R->mod; }
            else R->acc += acc;
            R->wsum += wsum; R->subs += subs; R->trans += tcnt;
            R->cpu_ns += (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
            if (R->ckpt) {
                fprintf(R->ckpt, "C %llu %llu %llu %llu %llu %llu\n",
                        (unsigned long long)ci, (unsigned long long)acc,
                        (unsigned long long)wsum, (unsigned long long)subs,
                        (unsigned long long)tcnt,
                        (unsigned long long)ie_ck_hash(ci, acc, wsum, subs, tcnt));
                fflush(R->ckpt);
            }
            R->done[ci] = 1;
        }
        pthread_mutex_unlock(&R->mu);
    }
    free(cur); free(nxt);
    return NULL;
}

/* run one pass; returns 0 ok. Header line pins the instance so a stale or
 * mismatched checkpoint can never be silently mixed in. */
static int ie_run_pass(IeCtx *C, uint64_t mod, const char *modname, int threads,
                       int chunk_bits, const char *ckpt_path,
                       uint64_t lo, uint64_t hi, uint64_t *out_acc,
                       uint64_t *out_subs, uint64_t *out_trans, double *out_cpu_ns,
                       double *out_wall) {
    IeRun R;
    memset(&R, 0, sizeof R);
    R.C = C; R.mod = mod; R.range_lo = lo; R.range_hi = hi; R.chunk_bits = chunk_bits;
    uint64_t csz = 1ull << chunk_bits;
    R.nchunks = (hi - lo + csz - 1) / csz;
    R.done = calloc(R.nchunks ? R.nchunks : 1, 1);
    if (!R.done) return 1;
    pthread_mutex_init(&R.mu, NULL);
    char hdr[512];
    snprintf(hdr, sizeof hdr,
             "IEv1 n=%d start=%d b0=%d,%d,%d,%d,%d mod=%s quot=%d chunkbits=%d lo=%llu hi=%llu pl=",
             C->n, C->start, C->b0v[0], C->b0v[1], C->b0v[2], C->b0v[3], C->b0v[4],
             modname, C->quotient, chunk_bits,
             (unsigned long long)lo, (unsigned long long)hi);
    for (int i = 0; i < C->n; i++) {
        char t[8]; snprintf(t, sizeof t, "%s%d", i ? "," : "", C->pl[i]);
        strncat(hdr, t, sizeof hdr - strlen(hdr) - 1);
    }
    if (C->no_budget)              /* budget-mode headers stay byte-identical */
        strncat(hdr, C->nb_negctl ? " nb=negctl" : " nb=1",
                sizeof hdr - strlen(hdr) - 1);
    if (C->npin) {                 /* pinned headers carry the pin list (unpinned
                                    * headers stay byte-identical) */
        strncat(hdr, " pins=", sizeof hdr - strlen(hdr) - 1);
        strncat(hdr, C->pinstr, sizeof hdr - strlen(hdr) - 1);
    }
    if (ckpt_path) {
        FILE *f = fopen(ckpt_path, "r");
        if (f) {
            char line[600];
            if (!fgets(line, sizeof line, f)) { printf("*** FAIL: empty checkpoint %s\n", ckpt_path); fclose(f); free(R.done); return 1; }
            line[strcspn(line, "\n")] = 0;
            if (strcmp(line, hdr)) {
                printf("*** FAIL: checkpoint header mismatch in %s\n  have: %s\n  want: %s\n",
                       ckpt_path, line, hdr);
                fclose(f); free(R.done); return 1;
            }
            unsigned long long ci, a, w, s, t;
            int resumed = 0;
            unsigned long long ckh;
            int rows_bad = 0;
            while (fscanf(f, "C %llu %llu %llu %llu %llu %llu\n", &ci, &a, &w, &s, &t, &ckh) == 6) {
                if (ckh != ie_ck_hash(ci, a, w, s, t)) { rows_bad++; continue; }
                if (ci >= R.nchunks || R.done[ci]) continue;
                R.done[ci] = 1;
                if (mod) { R.acc += a; if (R.acc >= mod) R.acc -= mod; }
                else R.acc += a;
                R.wsum += w; R.subs += s; R.trans += t;
                resumed++;
            }
            fclose(f);
            if (rows_bad) {
                printf("*** FAIL: %d corrupted checkpoint row(s) in %s — refusing to resume.\n",
                       rows_bad, ckpt_path);
                printf("         A row that fails its own hash was silently summed in before Q-286.\n");
                printf("IE_CHECKPOINT=CORRUPT\n");
                free(R.done); return 1;
            }
            printf("[ie] resumed %d completed chunk(s) from %s\n", resumed, ckpt_path);
            R.ckpt = fopen(ckpt_path, "a");
        } else {
            R.ckpt = fopen(ckpt_path, "w");
            if (R.ckpt) { fprintf(R.ckpt, "%s\n", hdr); fflush(R.ckpt); }
        }
        if (!R.ckpt) { printf("*** FAIL: cannot open checkpoint %s\n", ckpt_path); free(R.done); return 1; }
    }
    struct timespec w0, w1;
    clock_gettime(CLOCK_MONOTONIC, &w0);
    pthread_t th[256];
    if (threads > 256) threads = 256;
    for (int i = 0; i < threads; i++) pthread_create(&th[i], NULL, ie_worker, &R);
    for (int i = 0; i < threads; i++) pthread_join(th[i], NULL);
    clock_gettime(CLOCK_MONOTONIC, &w1);
    double wall = (w1.tv_sec - w0.tv_sec) + (w1.tv_nsec - w0.tv_nsec) * 1e-9;
    if (R.ckpt) fclose(R.ckpt);
    free(R.done);
    if (R.fatal) { printf("*** FAIL: orbit-stabilizer defect during pass (group bug?)\n"); return 1; }
    /* full-space integrity: quotiented orbit weights must tile 2^n exactly;
     * pinned mode enumerates the 2^nfree t-space instead (quotient off). */
    {
        int bits = C->npin ? C->nfree : C->n;
        if (lo == 0 && hi == (1ull << bits)) {
            uint64_t want = 1ull << bits;
            if (C->quotient && R.wsum != want) {
                printf("*** FAIL: orbit-weight sum %llu != 2^n=%llu\n",
                       (unsigned long long)R.wsum, (unsigned long long)want);
                return 1;
            }
            if (!C->quotient && (R.wsum != want || R.subs != want)) {
                printf("*** FAIL: unquotiented pass visited %llu subsets, want %llu\n",
                       (unsigned long long)R.subs, (unsigned long long)want);
                return 1;
            }
        }
    }
    printf("[ie] pass mod=%-4s  subsets=%llu  weightsum=%llu  transitions=%llu\n"
           "     acc=%llu  wall=%.2fs  cpu=%.1f core-s  (%.1f ns/transition/core)\n",
           modname, (unsigned long long)R.subs, (unsigned long long)R.wsum,
           (unsigned long long)R.trans, (unsigned long long)R.acc, wall,
           R.cpu_ns / 1e9, R.trans ? R.cpu_ns / (double)R.trans : 0.0);
    *out_acc = R.acc; *out_subs = R.subs; *out_trans = R.trans;
    *out_cpu_ns = R.cpu_ns; *out_wall = wall;
    return 0;
}

/* ---- driver: --ie-count ---- */
static int ie_count_main(int argc, char **argv) {
    const char *spec = "full31@0", *ckpt = NULL, *expect = NULL, *modsel = "all";
    int threads = (int)sysconf(_SC_NPROCESSORS_ONLN);
    int chunk_bits = -1, no_quot = 0, negctl = 0, have_b0 = 0, no_budget = 0;
    int b0_cli[5] = {0,0,0,0,0};
    uint64_t rlo = 0, rhi = 0;
    int have_range = 0;
    int pin_slot[32], pin_pair[32], npin_cli = 0, pin_c6c7 = 0, brute = 0;
    for (int i = 2; i < argc; i++) {
        if (!strcmp(argv[i], "--ie-spec") && i + 1 < argc) spec = argv[++i];
        else if (!strcmp(argv[i], "--ie-mod") && i + 1 < argc) modsel = argv[++i];
        else if (!strcmp(argv[i], "--ie-threads") && i + 1 < argc) threads = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--ie-chunk-bits") && i + 1 < argc) chunk_bits = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--ie-checkpoint") && i + 1 < argc) ckpt = argv[++i];
        else if (!strcmp(argv[i], "--ie-expect") && i + 1 < argc) expect = argv[++i];
        else if (!strcmp(argv[i], "--ie-no-quotient")) no_quot = 1;
        else if (!strcmp(argv[i], "--ie-no-budget")) no_budget = 1;
        else if (!strcmp(argv[i], "--ie-negctl")) negctl = 1;
        else if (!strcmp(argv[i], "--ie-pin") && i + 1 < argc) {
            int s, p;
            if (sscanf(argv[++i], "%d:%d", &s, &p) != 2 || npin_cli >= 32) {
                fprintf(stderr, "bad --ie-pin (want SLOT:PAIR)\n"); return 2;
            }
            pin_slot[npin_cli] = s; pin_pair[npin_cli] = p; npin_cli++;
        }
        else if (!strcmp(argv[i], "--ie-pin-c6c7")) pin_c6c7 = 1;
        else if (!strcmp(argv[i], "--ie-brute")) brute = 1;
        else if (!strcmp(argv[i], "--ie-b0") && i + 1 < argc) {
            if (sscanf(argv[++i], "%d,%d,%d,%d,%d",
                       &b0_cli[0], &b0_cli[1], &b0_cli[2], &b0_cli[3], &b0_cli[4]) != 5) {
                fprintf(stderr, "bad --ie-b0\n"); return 2;
            }
            have_b0 = 1;
        }
        else if (!strcmp(argv[i], "--ie-range") && i + 2 < argc) {
            rlo = strtoull(argv[++i], NULL, 0);
            rhi = strtoull(argv[++i], NULL, 0);
            have_range = 1;
        }
        else { fprintf(stderr, "unknown --ie-count option %s\n", argv[i]); return 2; }
    }
    if (threads < 1) threads = 1;

    printf("======================================================================\n");
    if (no_budget) {
        printf("verify.c --ie-count --ie-no-budget : independent IE recount of\n");
        printf("|C1 cap C2 cap C4| (C5/budget layer dropped; DP state = (last)\n");
        printf(" alone, no mask, no lattice; shares no machinery with solve.c)\n");
    } else {
        printf("verify.c --ie-count : Route B — independent IE transfer-walk recount\n");
        printf("(signed inclusion-exclusion over free-pair subsets; DP state = (last,\n");
        printf(" budget) with NO mask; shares no code or machinery with solve.c)\n");
    }
    printf("======================================================================\n");
    if (no_budget && have_b0) {
        printf("*** FAIL: --ie-b0 contradicts --ie-no-budget\n");
        return 2;
    }
    if (!build_pairs()) return 1;
    if (!derive_pair_perms()) return 1;
    if (!ie_build_orbits()) { printf("*** FAIL: pair-orbit derivation\n"); return 1; }

    IeCtx C;
    memset(&C, 0, sizeof C);
    if (!ie_parse_spec(spec, C.pl, &C.n, &C.start)) {
        printf("*** FAIL: bad --ie-spec '%s'\n", spec);
        return 1;
    }
    C.quotient = !no_quot;
    C.no_budget = no_budget;
    C.nb_negctl = (no_budget && negctl);

    /* ---- pins (the T3 slot-pinned variant) ---- */
    for (int k = 0; k < 32; k++) C.pin_at[k] = -1;
    if (pin_c6c7) {
        if (C.n != 31 || C.start != 0) {
            printf("*** FAIL: --ie-pin-c6c7 requires --ie-spec full31@0\n");
            return 1;
        }
        /* SPECIFICATION.md C6/C7 hexagram constants — an independent cross-
         * check of the KW[]-derived pair table: C7 pins slots 24,25 to
         * {29,46},{9,36}; C6 pins slots 26,27 to {11,52},{13,44}. */
        static const int spec67[4][2] = {{29,46},{9,36},{11,52},{13,44}};
        for (int s = 24; s <= 27; s++) {
            int a = PA[s], b = PB[s];
            int sa = spec67[s - 24][0], sb = spec67[s - 24][1];
            if (!((a == sa && b == sb) || (a == sb && b == sa))) {
                printf("*** FAIL: KW pair #%d {%d,%d} != SPEC C6/C7 {%d,%d}\n",
                       s, a, b, sa, sb);
                return 1;
            }
            if (npin_cli >= 32) { printf("*** FAIL: too many pins\n"); return 1; }
            pin_slot[npin_cli] = s; pin_pair[npin_cli] = s; npin_cli++;
        }
    }
    if (npin_cli) {
        C.pinstr[0] = 0;
        for (int i = 0; i < npin_cli; i++) {
            int s = pin_slot[i], p = pin_pair[i];
            if (s < 1 || s > C.n) {
                printf("*** FAIL: pin slot %d outside 1..%d\n", s, C.n); return 1;
            }
            int q = -1;
            for (int j = 0; j < C.n; j++) if (C.pl[j] == p) { q = j; break; }
            if (q < 0) {
                printf("*** FAIL: pinned pair %d not in the instance pair list\n", p);
                return 1;
            }
            if (C.pin_at[s - 1] >= 0) {
                printf("*** FAIL: slot %d pinned twice\n", s); return 1;
            }
            C.pin_at[s - 1] = q;
            C.pinmask |= 1u << q;
            char t[16]; snprintf(t, sizeof t, "%s%d:%d", i ? "," : "", s, p);
            strncat(C.pinstr, t, sizeof C.pinstr - strlen(C.pinstr) - 1);
        }
        C.npin = npin_cli;
        C.nfree = 0;
        for (int j = 0; j < C.n; j++)
            if (!(C.pinmask & (1u << j))) C.freepos[C.nfree++] = j;
        if (C.quotient && !brute) {
            printf("*** FAIL: pins break the 24-group closure (the pinned pairs'\n"
                   "          stabilizer is trivial) — rerun with --ie-no-quotient\n");
            return 1;
        }
        printf("pins    : %d pinned step(s) [slot:pair] %s\n"
               "          outer sum = pins + 2^%d free-pair subsets, UNQUOTIENTED;\n"
               "          the mod-24 free-action gate does NOT apply under pins\n"
               "          (trivial stabilizer — divisor 1; N mod 24 informational)\n",
               C.npin, C.pinstr, C.nfree);
        for (int i = 0; i < npin_cli; i++) {
            int p = pin_pair[i];
            printf("          slot %2d := pair #%d {%d,%d} (orientation free)\n",
                   pin_slot[i], p, PA[p], PB[p]);
        }
    }

    /* startup re-verification of every premise of the subset-enumeration lemma */
    if (!ie_verify_group(C.start)) {
        printf("*** FAIL: elementwise group re-verification (bijection/fix-0-63/\n"
               "          Hamming-isometry/pair-mapping) — refusing to run\n");
        return 1;
    }
    printf("group   : 24 induced pair-perms; every witness bit-perm re-verified\n"
           "          elementwise (bijection, fixes 0/63/start, Hamming isometry on\n"
           "          all 64x64, maps pair j to pair sigma(j)) => W(gS)=W(S) holds\n");

    /* budget: full-31 is DEFINED as KW's boundary multiset (TR-11 v1.8);
     * reduced rungs use the Step-1 first-completion DFS. */
    if (no_budget) {
        printf("budget  : NONE (--ie-no-budget: counting |C1 cap C2 cap C4| — the\n"
               "          C5 boundary-multiset constraint is dropped entirely)\n");
        if (negctl)
            printf("budget  : *** NEGATIVE CONTROL: admissibility swapped to forbid d=4\n"
                   "          instead of d=5; the count MUST differ from published ***\n");
    }
    else if (have_b0) memcpy(C.b0v, b0_cli, sizeof C.b0v);
    else if (C.n == 31) {
        for (int i = 0; i < 31; i++) {
            int d = hamming(KW[2 * i + 1], KW[2 * i + 2]);
            int ci = cls_ix(d);
            if (ci < 0) { printf("*** FAIL: KW boundary outside classes\n"); return 1; }
            C.b0v[ci]++;
        }
        printf("budget  : full-31 B0 from KW boundary multiset = (%d,%d,%d,%d,%d)\n",
               C.b0v[0], C.b0v[1], C.b0v[2], C.b0v[3], C.b0v[4]);
    } else {
        int cnt[5] = {0,0,0,0,0};
        ie_b0g_found = 0;
        ie_b0g_dfs(C.pl, C.n, 0, C.start, 0, cnt, C.b0v);
        if (!ie_b0g_found) { printf("*** FAIL: no completing walk (B0 DFS)\n"); return 1; }
        printf("budget  : rung B0 via TR-11 SS5 Step-1 DFS = (%d,%d,%d,%d,%d)\n",
               C.b0v[0], C.b0v[1], C.b0v[2], C.b0v[3], C.b0v[4]);
    }
    if (negctl && !no_budget) {
        /* 🔴 Q-291: this swap is the IDENTITY whenever d2 == d4, so on those rungs the "negative
         * control" perturbs nothing and returns the published value it exists to differ from.
         * Measured 2026-08-27 on the PUBLISHED n=13 rung 3.0,4.0,6.2@0, B0 = (1,6,0,6,0):
         * baseline and --ie-negctl both return 2,063,395,607,040, and with no --ie-expect the
         * program prints "RESULT: pass complete; all in-run gates hold" and exits 0. The
         * comparison at the bottom of this function only runs when a target is supplied, so the
         * default path was silent. A control that CANNOT perturb has not passed; it has not run,
         * and a check that cannot run must ERROR. (Where d2 != d4 the control works: the same
         * rung family at (2,7,1,3,0) gives 13,662,676,224 vs 16,671,428,352.) */
        if (C.b0v[1] == C.b0v[3]) {
            printf("*** FAIL: --ie-negctl cannot perturb this rung — d2 == d4 == %d, so swapping\n"
                   "          them is the IDENTITY and the count CANNOT differ. This control has\n"
                   "          not passed; it has not run. Use --ie-b0 to supply a budget that\n"
                   "          actually differs, or perturb a different coordinate.\n", C.b0v[1]);
            printf("IE_NEGCTL=INAPPLICABLE\n");
            return 1;
        }
        int t = C.b0v[1]; C.b0v[1] = C.b0v[3]; C.b0v[3] = t;
        printf("budget  : *** NEGATIVE CONTROL: d2/d4 budgets swapped -> (%d,%d,%d,%d,%d);\n"
               "          the count MUST differ from the published value ***\n",
               C.b0v[0], C.b0v[1], C.b0v[2], C.b0v[3], C.b0v[4]);
    }

    if (!ie_build(&C)) return 1;

    if (brute) {                        /* small-n reference instrument */
        if (C.n > 12) {
            printf("*** FAIL: --ie-brute is a small-n reference (n <= 12)\n");
            return 1;
        }
        uint64_t bc = 0; int bcnt[5] = {0,0,0,0,0};
        ie_brute_dfs(&C, 0, C.start, 0, bcnt, &bc);
        printf("BRUTE   : N = %llu (explicit permutation DFS%s%s)\n",
               (unsigned long long)bc,
               C.no_budget ? ", no budget" : "",
               C.npin ? ", pins honored" : "");
        if (expect) {
            u192 E = u192_dec(expect), B = {{bc, 0, 0}};
            int eq = u192_eq(E, B);
            printf("          vs expected %s : %s\n", expect,
                   eq ? "MATCH" : "*** MISMATCH ***");
            return eq ? 0 : 1;
        }
        return 0;
    }

    if (!ie_build_quot(&C)) return 1;   /* geff needed for reporting even unquotiented */
    printf("instance: n=%d start=%d spec=%s  pairs=", C.n, C.start, spec);
    for (int i = 0; i < C.n; i++) printf("%s%d", i ? "," : "", C.pl[i]);
    if (no_budget) printf("\nlattice : none (no budget; walk state = last hexagram, 64 slots)\n");
    else printf("\nlattice : R=%u vectors, max coexisting per layer = %d\n", C.R, C.maxnv);
    printf("quotient: %s (geff=%d restricted pair-perms)\n",
           C.quotient ? "ON (canonical subsets x orbit size)" : "OFF (full 2^n)",
           C.geff);

    uint64_t primes[3];
    ie_pick_primes(primes);
    for (int i = 0; i < 3; i++)
        if (!ie_is_prime_u64(primes[i])) { printf("*** FAIL: prime selection\n"); return 1; }
    printf("primes  : p0=%llu p1=%llu p2=%llu (Miller-Rabin-proven at startup)\n",
           (unsigned long long)primes[0], (unsigned long long)primes[1],
           (unsigned long long)primes[2]);

    {   /* pinned mode enumerates the 2^nfree t-space, not 2^n */
        int ebits = C.npin ? C.nfree : C.n;
        if (!have_range) { rlo = 0; rhi = 1ull << ebits; }
        if (rhi > (1ull << ebits) || rlo >= rhi) { printf("*** FAIL: bad range\n"); return 1; }
        if (chunk_bits < 0) {
            chunk_bits = ebits - 11;
            if (chunk_bits < 8) chunk_bits = 8;
            if (chunk_bits > 20) chunk_bits = 20;
        }
    }

    /* which moduli to run */
    struct { const char *name; uint64_t mod; int run; } passes[4] = {
        { "wrap", 0, 0 }, { "p0", primes[0], 0 }, { "p1", primes[1], 0 }, { "p2", primes[2], 0 }
    };
    if (!strcmp(modsel, "all")) {
        /* wrap is exact only while N < 2^64. Budget mode: n<=19 (validated
         * band). No-budget counts are larger (no C5 filter): bound by
         * n!*2^n < 2^64 iff n<=16, so auto-wrap only there. */
        passes[0].run = (C.n <= (no_budget ? 16 : 19));
        passes[1].run = passes[2].run = passes[3].run = 1;
    }
    else if (!strcmp(modsel, "wrap")) passes[0].run = 1;
    else if (!strcmp(modsel, "p0")) passes[1].run = 1;
    else if (!strcmp(modsel, "p1")) passes[2].run = 1;
    else if (!strcmp(modsel, "p2")) passes[3].run = 1;
    else { printf("*** FAIL: bad --ie-mod '%s'\n", modsel); return 1; }

    uint64_t acc[4] = {0,0,0,0};
    int ran[4] = {0,0,0,0};
    for (int p = 0; p < 4; p++) {
        if (!passes[p].run) continue;
        char ckbuf[1024];
        const char *ck = NULL;
        if (ckpt) { snprintf(ckbuf, sizeof ckbuf, "%s.%s", ckpt, passes[p].name); ck = ckbuf; }
        uint64_t subs, trans;
        double cpu_ns, wall;
        printf("----------------------------------------------------------------------\n");
        if (ie_run_pass(&C, passes[p].mod, passes[p].name, threads, chunk_bits, ck,
                        rlo, rhi, &acc[p], &subs, &trans, &cpu_ns, &wall))
            return 1;
        ran[p] = 1;
    }
    printf("----------------------------------------------------------------------\n");

    int fails = 0;
    if (ran[1] && ran[2] && ran[3]) {
        uint64_t a3[3] = { acc[1], acc[2], acc[3] };
        u192 N;
        ie_crt3(primes, a3, &N);
        char dec[64];
        u192_print(N, dec);
        printf("CRT     : N = %s\n", dec);
        printf("          N mod 24 = %u%s\n", u192_mod(N, 24),
               C.npin ? "  (informational — free-action gate N/A under pins)"
                      : (C.n == 31 && !negctl)
                        ? (u192_mod(N, 24) == 0 ? "  (free-action gate: ok)"
                                                : "  *** FAIL: expected 0 ***") : "");
        if (C.n == 31 && !negctl && !C.npin && u192_mod(N, 24) != 0) fails++;
        if (ran[0]) {
            u192 W = {{ acc[0], 0, 0 }};
            int eq = u192_eq(N, W);
            printf("          wrap cross-check (N < 2^64): %llu  %s\n",
                   (unsigned long long)acc[0], eq ? "MATCH" : "*** MISMATCH ***");
            if (!eq) fails++;
        }
        const char *target = expect;
        if (!target && C.n == 31 && !have_range && !C.npin)
            /* pinned full-31 (|C1..C7|, C3 dropped) has NO published exact —
             * only the Knuth estimate 5.18e32 (0.25%) — so no default target */
            target = no_budget ? LC_PUBLISHED_COUNT_C1C2C4 : LC_PUBLISHED_COUNT;
        if (target) {
            u192 E = u192_dec(target);
            int eq = u192_eq(N, E);
            if (negctl) {
                printf("          vs published %s : %s (negative control %s)\n", target,
                       eq ? "EQUAL" : "DIFFERS", eq ? "*** FAILED ***" : "passed");
                if (eq) fails++;
            } else {
                printf("          vs expected %s : %s\n", target,
                       eq ? "MATCH" : "*** MISMATCH ***");
                if (!eq) fails++;
            }
        }
    } else if (ran[0]) {
        printf("wrap    : N mod 2^64 = %llu (exact iff N < 2^64)\n",
               (unsigned long long)acc[0]);
        if (expect && !negctl) {
            u192 E = u192_dec(expect);
            int eq = (E.l[1] == 0 && E.l[2] == 0 && E.l[0] == acc[0]);
            printf("          vs expected %s : %s\n", expect, eq ? "MATCH" : "*** MISMATCH ***");
            if (!eq) fails++;
        }
    } else {
        for (int p = 1; p < 4; p++)
            if (ran[p]) printf("residue : N mod %s(%llu) = %llu\n", passes[p].name,
                               (unsigned long long)passes[p].mod, (unsigned long long)acc[p]);
    }
    printf("======================================================================\n");
    printf("RESULT: %s\n", fails ? "*** FAILURE(S) — a finding; report, do not patch around ***"
                                 : "pass complete; all in-run gates hold");
    printf("======================================================================\n");
    return fails ? 1 : 0;
}

/* ---- driver: --ie-probe (full-31 throughput probe + cost extrapolation) ---- */
typedef struct {
    IeCtx *C;
    uint64_t next, chunk;               /* scan cursor over mask space */
    uint64_t cnt[32];                   /* canonical subsets per popcount */
    uint64_t hashmod[32];               /* sampling modulus per popcount */
    uint32_t *samp[32];
    int nsamp[32], maxsamp;
    pthread_mutex_t mu;
} IeScan;

static uint64_t ie_mix64(uint64_t x) {
    x ^= x >> 33; x *= 0xff51afd7ed558ccdULL;
    x ^= x >> 33; x *= 0xc4ceb9fe1a85ec53ULL;
    x ^= x >> 33; return x;
}
static void *ie_scan_worker(void *arg) {
    IeScan *S = arg;
    IeCtx *C = S->C;
    uint64_t total = 1ull << C->n;
    uint64_t lcnt[32] = {0};
    uint32_t *lsamp[32];
    int lns[32] = {0};
    for (int k = 0; k <= C->n; k++) lsamp[k] = malloc(4 * (size_t)S->maxsamp);
    for (;;) {
        uint64_t lo = __atomic_fetch_add(&S->next, S->chunk, __ATOMIC_RELAXED);
        if (lo >= total) break;
        uint64_t hi = lo + S->chunk;
        if (hi > total) hi = total;
        for (uint64_t m = lo; m < hi; m++) {
            int orbit;
            if (ie_canon_orbit(C, (uint32_t)m, &orbit) != 1) continue;
            int k = __builtin_popcountll(m);
            lcnt[k]++;
            if (S->hashmod[k] && lns[k] < S->maxsamp &&
                ie_mix64(m) % S->hashmod[k] == 0)
                lsamp[k][lns[k]++] = (uint32_t)m;
        }
    }
    pthread_mutex_lock(&S->mu);
    for (int k = 0; k <= C->n; k++) {
        S->cnt[k] += lcnt[k];
        int room = S->maxsamp - S->nsamp[k];
        int take = lns[k] < room ? lns[k] : room;
        if (take > 0) {
            memcpy(S->samp[k] + S->nsamp[k], lsamp[k], 4 * (size_t)take);
            S->nsamp[k] += take;
        }
    }
    pthread_mutex_unlock(&S->mu);
    for (int k = 0; k <= C->n; k++) free(lsamp[k]);
    return NULL;
}

typedef struct {
    IeCtx *C;
    uint64_t mod;
    const uint32_t *samp;
    int nsamp;
    uint64_t next;
    uint64_t trans;
    double cpu_ns;
    uint64_t sink;
    pthread_mutex_t mu;
} IeTime;

static void *ie_time_worker(void *arg) {
    IeTime *T = arg;
    IeCtx *C = T->C;
    uint64_t *cur = malloc((size_t)C->maxnv * 64 * 8);
    uint64_t *nxt = malloc((size_t)C->maxnv * 64 * 8);
    if (!cur || !nxt) { free(cur); free(nxt); return (void *)1; }
    uint64_t tcnt = 0, sink = 0;
    struct timespec t0, t1;
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t0);
    for (;;) {
        uint64_t i = __atomic_fetch_add(&T->next, 1, __ATOMIC_RELAXED);
        if (i >= (uint64_t)T->nsamp) break;
        sink ^= ie_walk(C, T->samp[i], T->mod, cur, nxt, &tcnt);
    }
    clock_gettime(CLOCK_THREAD_CPUTIME_ID, &t1);
    pthread_mutex_lock(&T->mu);
    T->trans += tcnt;
    T->cpu_ns += (t1.tv_sec - t0.tv_sec) * 1e9 + (t1.tv_nsec - t0.tv_nsec);
    T->sink ^= sink;
    pthread_mutex_unlock(&T->mu);
    free(cur); free(nxt);
    return NULL;
}

static int ie_probe_main(int argc, char **argv) {
    int nsamp = 1000, threads = (int)sysconf(_SC_NPROCESSORS_ONLN);
    if (argc >= 3 && argv[2][0] != '-') nsamp = atoi(argv[2]);
    for (int i = 2; i < argc; i++)
        if (!strcmp(argv[i], "--ie-threads") && i + 1 < argc) threads = atoi(argv[++i]);
    if (nsamp < 10) nsamp = 10;
    if (threads < 1) threads = 1;
    if (threads > 256) threads = 256;

    printf("======================================================================\n");
    printf("verify.c --ie-probe : full-31 Route B throughput probe (%d samples/class)\n", nsamp);
    printf("======================================================================\n");
    if (!build_pairs() || !derive_pair_perms() || !ie_build_orbits()) return 1;
    IeCtx C;
    memset(&C, 0, sizeof C);
    if (!ie_parse_spec("full31@0", C.pl, &C.n, &C.start)) return 1;
    C.quotient = 1;
    if (!ie_verify_group(C.start)) { printf("*** FAIL: group re-verification\n"); return 1; }
    for (int i = 0; i < 31; i++) {
        int ci = cls_ix(hamming(KW[2 * i + 1], KW[2 * i + 2]));
        if (ci < 0) return 1;
        C.b0v[ci]++;
    }
    if (!ie_build(&C) || !ie_build_quot(&C)) return 1;
    printf("lattice R=%u maxnv=%d geff=%d\n", C.R, C.maxnv, C.geff);
    uint64_t primes[3];
    ie_pick_primes(primes);

    /* pass A: exact canonical-count per popcount + hash-sampled timing masks.
     * Known expected density ~93.94M/2^31: seed per-class hashmod from the
     * binomial C(31,k)/24 heuristic, clamped >=1. */
    IeScan S;
    memset(&S, 0, sizeof S);
    S.C = &C; S.chunk = 1u << 20; S.maxsamp = nsamp;
    pthread_mutex_init(&S.mu, NULL);
    for (int k = 0; k <= 31; k++) {
        double est = 1.0;
        for (int i = 0; i < k; i++) est = est * (31 - i) / (i + 1);
        est /= 24.0;
        uint64_t hm = (uint64_t)(est / nsamp);
        S.hashmod[k] = hm < 1 ? 1 : hm;
        S.samp[k] = malloc(4 * (size_t)nsamp);
    }
    struct timespec a0, a1;
    clock_gettime(CLOCK_MONOTONIC, &a0);
    pthread_t th[256];
    for (int i = 0; i < threads; i++) pthread_create(&th[i], NULL, ie_scan_worker, &S);
    for (int i = 0; i < threads; i++) pthread_join(th[i], NULL);
    clock_gettime(CLOCK_MONOTONIC, &a1);
    double scan_wall = (a1.tv_sec - a0.tv_sec) + (a1.tv_nsec - a0.tv_nsec) * 1e-9;
    uint64_t total_canon = 0;
    for (int k = 0; k <= 31; k++) total_canon += S.cnt[k];
    printf("scan    : %.1fs wall on %d threads; canonical subsets = %llu (expect 93,939,712)\n",
           scan_wall, threads, (unsigned long long)total_canon);
    printf("          tail k23..k31 = ");
    for (int k = 23; k <= 31; k++) printf("%llu%s", (unsigned long long)S.cnt[k], k < 31 ? "," : "\n");
    printf("          peak k15=%llu k16=%llu\n",
           (unsigned long long)S.cnt[15], (unsigned long long)S.cnt[16]);
    if (total_canon != 93939712ull)
        printf("          *** WARNING: canonical total != 93,939,712 — investigate ***\n");

    /* pass B: per-popcount timing on the sampled canonical subsets (mod p0) */
    printf("----------------------------------------------------------------------\n");
    printf("  k |   canonical | samples |  mean us/subset | mean trans/subset | ns/trans\n");
    printf("----+-------------+---------+-----------------+-------------------+---------\n");
    double total_core_s = 0.0, total_trans = 0.0;
    for (int k = 0; k <= 31; k++) {
        if (S.cnt[k] == 0) continue;
        if (S.nsamp[k] == 0) { printf(" %2d | %11llu | 0 samples — skipped\n", k, (unsigned long long)S.cnt[k]); continue; }
        IeTime T;
        memset(&T, 0, sizeof T);
        T.C = &C; T.mod = primes[0]; T.samp = S.samp[k]; T.nsamp = S.nsamp[k];
        pthread_mutex_init(&T.mu, NULL);
        int nth = threads < T.nsamp ? threads : T.nsamp;
        for (int i = 0; i < nth; i++) pthread_create(&th[i], NULL, ie_time_worker, &T);
        for (int i = 0; i < nth; i++) pthread_join(th[i], NULL);
        double us = T.cpu_ns / 1e3 / T.nsamp;
        double tr = (double)T.trans / T.nsamp;
        printf(" %2d | %11llu | %7d | %15.1f | %17.0f | %7.2f\n",
               k, (unsigned long long)S.cnt[k], T.nsamp, us, tr,
               T.trans ? T.cpu_ns / (double)T.trans : 0.0);
        total_core_s += (double)S.cnt[k] * us / 1e6;
        total_trans += (double)S.cnt[k] * tr;
    }
    double scan_core_s = scan_wall * threads;
    printf("----------------------------------------------------------------------\n");
    printf("extrapolation, ONE prime pass (full 93.94M canonical subsets):\n");
    printf("  walk-DP core-seconds  = %.3e  (%.1f core-hours)\n", total_core_s, total_core_s / 3600);
    printf("  + canonicity scan     = %.3e core-seconds\n", scan_core_s);
    printf("  total transitions     = %.3e (eval sized 1.13e15)\n", total_trans);
    double pass_core_h = (total_core_s + scan_core_s) / 3600;
    printf("  per-pass:  %.1f core-h  =  %.2f h wall on 32 cores  =  %.2f h wall on 128 cores\n",
           pass_core_h, pass_core_h / 32, pass_core_h / 128);
    printf("  THREE passes on D128:  %.2f h wall\n", 3 * pass_core_h / 128);
    printf("  (dollar sizing left to the operator report: multiply by the Spot rate)\n");
    printf("======================================================================\n");
    return 0;
}

/* ==========================================================================
 * ROUTE D — THE SECOND INSTRUMENT FOR THE PINNED (C6/C7) EXACT COUNT
 *   --dp-count [opts]
 *
 * PURPOSE. The published exact |C1∩C2∩C4∩C5∩C6∩C7| (= |C1–C7|, C3 dropped) =
 * 516,880,238,445,773,965,371,923,491,676,160 was first computed (2026-07-25)
 * by ONE instrument: the pinned-step signed inclusion–exclusion transfer walk
 * (--ie-count --ie-pin-c6c7 --ie-no-quotient above). This mode is a genuinely
 * different SECOND instrument that recomputes the same integer at full scale,
 * mirroring the two-instrument pattern used for |C1∩C2∩C4∩C5| (solve.c mask
 * DP + Route B IE) — except here the direct mask DP is (re)built in this
 * file, adapted to the slot-pinned instance.
 *
 * ALGORITHM CLASS (classical Held–Karp-style exact-cover subset DP; used, not
 * invented, here — the same class as solve.c's f1c5 primary, independently
 * reimplemented). State = (M, last, tracked-budget) where M = the explicit
 * bitmask of used FREE pairs, layered by popcount; pinned slots are FORCED
 * steps (pair fixed, orientation free) that advance (last, budget) with M
 * unchanged. There is NO inclusion–exclusion anywhere: no subsets-of-pairs
 * outer sum, no signs, no W(S), no capped-walk identity, no group quotient.
 * C1-distinctness is enforced by the mask itself (each free pair placed at
 * most once; each walk of the final full-mask layer used every pair exactly
 * once), where the IE engine enforces it by signed cancellation.
 *
 * BUDGET (C5) — tracked caps + algebraic coefficient extraction. Tracking the
 * full 5-class budget vector alongside a 2^27 mask space needs ~1.6 TB; so
 * the three SMALL classes (d1,d4,d6: caps B0=(2,·,·,7,1) at full 31) are
 * tracked exactly (48 combos, cap-overflow states killed), and the (d2,d3)
 * split is recovered algebraically: each d2-step multiplies the walk weight
 * by a formal y, the derived total s = #d2+#d3 = t − (tracked sum) is killed
 * when it exceeds B0_d2+B0_d3 = D, and the final answer is the y^{B0_d2}
 * coefficient of the degree-≤D polynomial V(y), obtained by running the DP at
 * D+1 nodes y = 1..D+1 and Lagrange-interpolating mod p. One EXTRA node
 * (y = D+2) is always run and checked against the fitted polynomial — an
 * end-to-end overdetermination gate on the whole kernel. The interpolation
 * needs division, so this mode runs mod the three Miller–Rabin-proven 63-bit
 * primes only (no 2^64 wrap pass); CRT reconstructs every coefficient K_b
 * exactly (each K_b ≤ |C1∩C2∩C4| < p0·p1·p2 — a rigorous envelope). The K_b
 * for b ≠ B0_d2 are exact counts of perturbed-budget variants — free
 * diagnostics printed alongside.
 *
 * INDEPENDENCE from --ie-count (what IS shared, and why that is sound):
 *   shared: the PROBLEM SPEC ONLY — the KW[]/build_pairs pair table, the
 *     class map d = hamming ∈ {1,2,3,4,6} with d=5 (C2) excluded, the
 *     TR-11 §5 B0 derivation (ie_b0g_dfs) and rung-spec labels
 *     (ie_parse_spec; orbit labels NAME rungs, no group math is used here),
 *     the SPEC C6/C7 pin constants cross-check, and scalar arithmetic
 *     utilities (ie_mulmod/ie_powmod/ie_invmod, prime selection, ie_crt3,
 *     u192 printing) whose correctness is checked end-to-end by the small-n
 *     brute-force equalities.
 *   NOT shared: everything that computes — the walk kernel, the state
 *     space, the budget mechanism, the distinctness mechanism, and the
 *     outer structure are all different in kind from the IE engine's.
 *
 * MEMORY. Layers hold [rank(M)][last][comb] u64 residues; `last` is stored
 * SPARSELY: after a free step, last = the exit hexagram of the placed pair,
 * so a free layer of popcount k needs only 2k slots (the 32 pairs partition
 * the 64 hexagrams — slot = 2*(position of the pair in M) + side); after a
 * forced step only that pin's 2 exits are possible (2 slots). Full-31 pinned
 * peak = layers 13+14 ≈ 200+216 GB resident — a 512 GB VM fits. Per-unit
 * (prime × node) runs are independent, so checkpointing is at unit
 * granularity: an eviction loses at most one unit.
 *
 * USAGE:
 *   ./verify --dp-count [--dp-spec "3.0,3.1,3.2@0" | --dp-spec full31@0]
 *            [--dp-pin SLOT:PAIR ...] [--dp-pin-c6c7] [--dp-b0 a,b,c,d,e]
 *            [--dp-mod all|p0|p1|p2] [--dp-threads N] [--dp-checkpoint FILE]
 *            [--dp-expect DECIMAL] [--dp-negctl] [--dp-no-budget]
 *            [--dp-size-only]
 * Defaults: spec full31@0; mod all; threads = online CPUs. --dp-negctl swaps
 * B0's d2/d4 budgets (count MUST differ). --dp-no-budget drops C5 entirely
 * (plain (M,last) DP, one node — the F4-variant cross-check). --dp-size-only
 * prints the layer plan (masks, bytes, peak resident) and exits.
 * ========================================================================== */

static uint64_t dp_C[33][33];                     /* binomials (colex ranking) */
static void dp_binom_init(void) {
    for (int i = 0; i <= 32; i++) {
        for (int j = 0; j <= 32; j++) dp_C[i][j] = 0;
        dp_C[i][0] = 1;
        for (int j = 1; j <= i; j++)
            dp_C[i][j] = dp_C[i-1][j-1] + dp_C[i-1][j];
    }
}
/* rank r (numeric order) -> the r-th k-subset mask of [0,nf) */
static uint32_t dp_unrank(uint64_t r, int k, int nf) {
    uint32_t m = 0;
    for (int i = k; i >= 1; i--) {
        int p = i - 1;
        while (p + 1 < nf && dp_C[p+1][i] <= r) p++;
        m |= 1u << p;
        r -= dp_C[p][i];
    }
    return m;
}
static inline uint32_t dp_next_mask(uint32_t v) { /* Gosper: next same-popcount */
    uint32_t c = v & (0u - v);
    if (!c) return 0;
    uint32_t rr = v + c;
    return rr | (((v ^ rr) >> 2) / c);
}

#define DP_MAXCOMB 4096
typedef struct {
    int n, start;
    int pl[32];                /* instance pair list (KW pair indices) */
    int b0v[5];
    int no_budget, negctl;
    int npin;
    int pin_at[32];            /* [step t-1] = pl-position forced, or -1 */
    int pin_ord[32];           /* [step t-1] = pin order index, or -1 */
    int pqa[8], pqb[8];        /* pin order i -> its two hexagrams */
    char pinstr[160];
    int nfree;
    int fpa[32], fpb[32];      /* free index -> hexagrams (PA/PB of the pair) */
    int fpl[32];               /* free index -> KW pair index (reporting) */
    /* budget split */
    int tcap[3];               /* tracked caps: d1,d4,d6 = b0v[0],b0v[3],b0v[4] */
    int cstr[3];               /* comb-index stride of a +1 in each tracked class */
    int ncomb;
    int D;                     /* b0v[1]+b0v[2] — interpolation degree bound */
    int nnodes;                /* D+2 (fit D+1, check 1); 1 in no_budget mode */
    int comb_final;
    uint8_t tsum[DP_MAXCOMB];  /* comb -> tracked sum */
    uint8_t trk_ok[3][DP_MAXCOMB];
    int8_t cmap[64][64];       /* [enter][last] -> class index, or -1 */
} DpCtx;

typedef struct {
    int t;                     /* layer holds state after step t */
    int pc;                    /* mask popcount (free steps done) */
    int kindsrc;               /* -1 = free step (or t=0 base), else pin order */
    int nls;                   /* last slots: 1 (t=0), 2 (forced), 2*pc (free) */
    uint64_t nm;               /* number of masks = C(nfree, pc) */
    uint64_t *v;               /* [nm][nls][ncomb] residues */
} DpLayer;

/* comb-vector transfer for one (source-last, orientation) arc; returns #adds */
static inline uint64_t dp_apply(const DpCtx *X, int ci, const uint64_t *sv,
                                uint64_t *tv, uint64_t mod, uint64_t y,
                                const uint8_t *aliveU) {
    const int nc = X->ncomb;
    uint64_t tr = 0;
    if (ci == 1) {                       /* d2 (untracked, weight y) */
        for (int c = 0; c < nc; c++) {
            uint64_t v = sv[c];
            if (!v || !aliveU[c]) continue;
            v = (uint64_t)((unsigned __int128)v * y % mod);
            uint64_t s = tv[c] + v; if (s >= mod) s -= mod;
            tv[c] = s; tr++;
        }
    } else if (ci == 2) {                /* d3 (untracked, weight 1) */
        for (int c = 0; c < nc; c++) {
            uint64_t v = sv[c];
            if (!v || !aliveU[c]) continue;
            uint64_t s = tv[c] + v; if (s >= mod) s -= mod;
            tv[c] = s; tr++;
        }
    } else {                             /* tracked: d1/d4/d6 -> comb shift */
        int ti = (ci == 0) ? 0 : (ci == 3) ? 1 : 2;
        int str = X->cstr[ti];
        const uint8_t *ok = X->trk_ok[ti];
        for (int c = 0; c < nc; c++) {
            uint64_t v = sv[c];
            if (!v || !ok[c]) continue;
            uint64_t s = tv[c + str] + v; if (s >= mod) s -= mod;
            tv[c + str] = s; tr++;
        }
    }
    return tr;
}

typedef struct {
    const DpCtx *X;
    const DpLayer *S;
    DpLayer *T;
    uint64_t mod, y;
    int pin;                   /* pin order index for forced step, else -1 */
    uint64_t next;             /* atomic chunk cursor */
    uint64_t chunk;
    const uint8_t *aliveU;
    uint64_t trans;
    pthread_mutex_t mu;
} DpStep;

static void *dp_step_worker(void *arg) {
    DpStep *W = arg;
    const DpCtx *X = W->X;
    const DpLayer *S = W->S;
    DpLayer *T = W->T;
    const int nc = X->ncomb;
    const uint64_t mod = W->mod, y = W->y;
    const uint8_t *aliveU = W->aliveU;
    uint64_t tr = 0;
    int bl[32];
    uint64_t pre[33], suf[33];
    const size_t tstride = (size_t)T->nls * nc, sstride = (size_t)S->nls * nc;
    for (;;) {
        uint64_t c0 = __atomic_fetch_add(&W->next, 1, __ATOMIC_RELAXED);
        uint64_t lo = c0 * W->chunk;
        if (lo >= T->nm) break;
        uint64_t hi = lo + W->chunk; if (hi > T->nm) hi = T->nm;
        const int k1 = T->pc;
        uint32_t m = dp_unrank(lo, k1, X->nfree);
        for (uint64_t r = lo; r < hi; r++) {
            {   uint32_t mm = m;
                for (int i = 0; i < k1; i++) { bl[i] = __builtin_ctz(mm); mm &= mm - 1; }
            }
            uint64_t *trow = T->v + (size_t)r * tstride;
            memset(trow, 0, tstride * 8);
            if (W->pin >= 0) {
                /* FORCED step: same mask; pair = the pin; 2 target slots */
                const uint64_t *srow = S->v + (size_t)r * sstride;
                int pa = X->pqa[W->pin], pb = X->pqb[W->pin];
                for (int ls = 0; ls < S->nls; ls++) {
                    int h;
                    if (S->kindsrc >= 0)      h = (ls & 1) ? X->pqb[S->kindsrc] : X->pqa[S->kindsrc];
                    else if (S->t == 0)       h = X->start;
                    else { int p = ls >> 1;   h = (ls & 1) ? X->fpb[bl[p]] : X->fpa[bl[p]]; }
                    const uint64_t *sv = srow + (size_t)ls * nc;
                    for (int o = 0; o < 2; o++) {          /* o=0: enter b, exit a */
                        int enter = o ? pa : pb;
                        int ci = X->cmap[enter][h];
                        if (ci < 0) continue;
                        tr += dp_apply(X, ci, sv, trow + (size_t)o * nc, mod, y, aliveU);
                    }
                }
            } else {
                /* FREE step: gather from the k1 sub-masks M' \ {j} */
                pre[0] = 0;
                for (int i = 0; i < k1; i++) pre[i+1] = pre[i] + dp_C[bl[i]][i+1];
                suf[k1] = 0;
                for (int i = k1 - 1; i >= 0; i--) suf[i] = suf[i+1] + dp_C[bl[i]][i];
                for (int jj = 0; jj < k1; jj++) {
                    int j = bl[jj];
                    int pa = X->fpa[j], pb = X->fpb[j];
                    const uint64_t *srow = S->v + (size_t)(pre[jj] + suf[jj+1]) * sstride;
                    uint64_t *tv0 = trow + (size_t)(2*jj) * nc;
                    for (int ls = 0; ls < S->nls; ls++) {
                        int h;
                        if (S->kindsrc >= 0)      h = (ls & 1) ? X->pqb[S->kindsrc] : X->pqa[S->kindsrc];
                        else if (S->t == 0)       h = X->start;
                        else { int p = ls >> 1;   int js = bl[p < jj ? p : p + 1];
                               h = (ls & 1) ? X->fpb[js] : X->fpa[js]; }
                        const uint64_t *sv = srow + (size_t)ls * nc;
                        for (int o = 0; o < 2; o++) {      /* o=0: enter b, exit a */
                            int enter = o ? pa : pb;
                            int ci = X->cmap[enter][h];
                            if (ci < 0) continue;
                            tr += dp_apply(X, ci, sv, tv0 + (size_t)o * nc, mod, y, aliveU);
                        }
                    }
                }
            }
            if (r + 1 < hi) m = dp_next_mask(m);
        }
    }
    pthread_mutex_lock(&W->mu);
    W->trans += tr;
    pthread_mutex_unlock(&W->mu);
    return NULL;
}

/* one DP unit: full n-step pass at (mod, node y); returns 0 ok */
static int dp_run_unit(const DpCtx *X, uint64_t mod, uint64_t y, int threads,
                       uint64_t *out_val, uint64_t *out_trans, double *out_wall) {
    struct timespec w0, w1;
    clock_gettime(CLOCK_MONOTONIC, &w0);
    DpLayer S, T;
    memset(&S, 0, sizeof S);
    S.t = 0; S.pc = 0; S.kindsrc = -1; S.nls = 1; S.nm = 1;
    S.v = calloc((size_t)X->ncomb, 8);
    if (!S.v) return 1;
    S.v[0] = 1 % mod;
    uint64_t trans = 0;
    for (int t = 1; t <= X->n; t++) {
        int pin = X->pin_ord[t-1];
        memset(&T, 0, sizeof T);
        T.t = t;
        T.pc = S.pc + (pin < 0 ? 1 : 0);
        T.kindsrc = pin;
        T.nls = (pin >= 0) ? 2 : 2 * T.pc;
        T.nm = dp_C[X->nfree][T.pc];
        size_t bytes = (size_t)T.nm * T.nls * X->ncomb * 8;
        T.v = malloc(bytes);
        if (!T.v) {
            printf("*** FAIL: layer t=%d alloc of %.1f GB failed\n", t, bytes / 1e9);
            free(S.v); return 1;
        }
        uint8_t aliveU[DP_MAXCOMB];
        for (int c = 0; c < X->ncomb; c++)
            aliveU[c] = X->no_budget ? 1 : ((t - (int)X->tsum[c]) <= X->D);
        DpStep W;
        memset(&W, 0, sizeof W);
        W.X = X; W.S = &S; W.T = &T; W.mod = mod; W.y = y; W.pin = pin;
        W.aliveU = aliveU;
        W.chunk = T.nm / ((uint64_t)threads * 8) + 1;
        if (W.chunk > 32768) W.chunk = 32768;
        pthread_mutex_init(&W.mu, NULL);
        int nth = threads;
        if ((uint64_t)nth > T.nm) nth = (int)T.nm;
        if (nth > 256) nth = 256;
        pthread_t th[256];
        for (int i = 0; i < nth; i++) pthread_create(&th[i], NULL, dp_step_worker, &W);
        for (int i = 0; i < nth; i++) pthread_join(th[i], NULL);
        trans += W.trans;
        free(S.v);
        S = T;
    }
    /* final layer: nm=1 (full mask); sum the target-budget comb over all lasts */
    uint64_t acc = 0;
    for (int ls = 0; ls < S.nls; ls++) {
        uint64_t v = S.v[(size_t)ls * X->ncomb + X->comb_final];
        acc += v; if (acc >= mod) acc -= mod;
    }
    free(S.v);
    clock_gettime(CLOCK_MONOTONIC, &w1);
    *out_val = acc;
    *out_trans = trans;
    *out_wall = (w1.tv_sec - w0.tv_sec) + (w1.tv_nsec - w0.tv_nsec) * 1e-9;
    return 0;
}

/* Lagrange fit of the D+1 coefficients from nodes y=1..D+1 (mod p), then the
 * overdetermination check at y=D+2. Returns 1 ok, 0 on check failure. */
static int dp_fit_check(const DpCtx *X, uint64_t p, const uint64_t *V, uint64_t *K) {
    int D = X->D, nf = D + 1;
    uint64_t num[64], tmp[64];
    for (int b = 0; b <= D; b++) K[b] = 0;
    for (int j = 0; j < nf; j++) {
        num[0] = 1;
        int deg = 0;
        uint64_t den = 1;
        for (int m = 0; m < nf; m++) {
            if (m == j) continue;
            uint64_t ym = (uint64_t)(m + 1) % p;
            tmp[0] = 0;
            for (int i = 0; i <= deg; i++) tmp[i+1] = num[i];
            for (int i = 0; i <= deg; i++) {
                uint64_t sb = ie_mulmod(num[i], ym, p);
                tmp[i] = (tmp[i] >= sb) ? tmp[i] - sb : tmp[i] + p - sb;
            }
            deg++;
            for (int i = 0; i <= deg; i++) num[i] = tmp[i];
            uint64_t d = ((uint64_t)(j + 1) + p - ym) % p;
            den = ie_mulmod(den, d, p);
        }
        uint64_t w = ie_mulmod(V[j] % p, ie_invmod(den, p), p);
        for (int b = 0; b <= D; b++)
            K[b] = (K[b] + ie_mulmod(num[b], w, p)) % p;
    }
    uint64_t yc = (uint64_t)(D + 2) % p, pw = 1, pred = 0;
    for (int b = 0; b <= D; b++) {
        pred = (pred + ie_mulmod(K[b], pw, p)) % p;
        pw = ie_mulmod(pw, yc, p);
    }
    return pred == V[nf];
}

/* ---- driver: --dp-count ---- */
static int dp_count_main(int argc, char **argv) {
    const char *spec = "full31@0", *ckpt = NULL, *expect = NULL, *modsel = "all";
    int threads = (int)sysconf(_SC_NPROCESSORS_ONLN);
    int negctl = 0, no_budget = 0, have_b0 = 0, size_only = 0;
    int b0_cli[5] = {0,0,0,0,0};
    int pin_slot[32], pin_pair[32], npin_cli = 0, pin_c6c7 = 0;
    for (int i = 2; i < argc; i++) {
        if (!strcmp(argv[i], "--dp-spec") && i + 1 < argc) spec = argv[++i];
        else if (!strcmp(argv[i], "--dp-mod") && i + 1 < argc) modsel = argv[++i];
        else if (!strcmp(argv[i], "--dp-threads") && i + 1 < argc) threads = atoi(argv[++i]);
        else if (!strcmp(argv[i], "--dp-checkpoint") && i + 1 < argc) ckpt = argv[++i];
        else if (!strcmp(argv[i], "--dp-expect") && i + 1 < argc) expect = argv[++i];
        else if (!strcmp(argv[i], "--dp-negctl")) negctl = 1;
        else if (!strcmp(argv[i], "--dp-no-budget")) no_budget = 1;
        else if (!strcmp(argv[i], "--dp-size-only")) size_only = 1;
        else if (!strcmp(argv[i], "--dp-pin") && i + 1 < argc) {
            int s, p;
            if (sscanf(argv[++i], "%d:%d", &s, &p) != 2 || npin_cli >= 8) {
                fprintf(stderr, "bad --dp-pin (want SLOT:PAIR, max 8 pins)\n"); return 2;
            }
            pin_slot[npin_cli] = s; pin_pair[npin_cli] = p; npin_cli++;
        }
        else if (!strcmp(argv[i], "--dp-pin-c6c7")) pin_c6c7 = 1;
        else if (!strcmp(argv[i], "--dp-b0") && i + 1 < argc) {
            if (sscanf(argv[++i], "%d,%d,%d,%d,%d",
                       &b0_cli[0], &b0_cli[1], &b0_cli[2], &b0_cli[3], &b0_cli[4]) != 5) {
                fprintf(stderr, "bad --dp-b0\n"); return 2;
            }
            have_b0 = 1;
        }
        else { fprintf(stderr, "unknown --dp-count option %s\n", argv[i]); return 2; }
    }
    if (threads < 1) threads = 1;

    printf("======================================================================\n");
    printf("verify.c --dp-count : Route D — direct layered exact-cover mask DP\n");
    printf("(explicit used-pair bitmask, pins as forced steps; NO inclusion-\n");
    printf(" exclusion: no subset sum, no signs, no W(S), no quotient. Budget by\n");
    printf(" tracked (d1,d4,d6) caps + y^k coefficient extraction over (d2,d3),\n");
    printf(" Lagrange-interpolated mod 3 proven primes + CRT)\n");
    printf("======================================================================\n");
    if (!build_pairs()) return 1;
    if (!derive_pair_perms()) return 1;          /* only to LABEL rung specs */
    if (!ie_build_orbits()) { printf("*** FAIL: pair-orbit derivation\n"); return 1; }
    dp_binom_init();

    DpCtx X;
    memset(&X, 0, sizeof X);
    if (!ie_parse_spec(spec, X.pl, &X.n, &X.start)) {
        printf("*** FAIL: bad --dp-spec '%s'\n", spec);
        return 1;
    }
    X.no_budget = no_budget;
    X.negctl = negctl;

    /* ---- pins ---- */
    for (int k = 0; k < 32; k++) { X.pin_at[k] = -1; X.pin_ord[k] = -1; }
    if (pin_c6c7) {
        if (X.n != 31 || X.start != 0) {
            printf("*** FAIL: --dp-pin-c6c7 requires --dp-spec full31@0\n");
            return 1;
        }
        /* SPECIFICATION.md C6/C7 hexagram constants — independent cross-check
         * of the KW[]-derived pair table (same check as the IE variant). */
        static const int spec67[4][2] = {{29,46},{9,36},{11,52},{13,44}};
        for (int s = 24; s <= 27; s++) {
            int a = PA[s], b = PB[s];
            int sa = spec67[s - 24][0], sb = spec67[s - 24][1];
            if (!((a == sa && b == sb) || (a == sb && b == sa))) {
                printf("*** FAIL: KW pair #%d {%d,%d} != SPEC C6/C7 {%d,%d}\n",
                       s, a, b, sa, sb);
                return 1;
            }
            pin_slot[npin_cli] = s; pin_pair[npin_cli] = s; npin_cli++;
        }
    }
    int dup_pin = 0;
    if (npin_cli) {
        X.pinstr[0] = 0;
        for (int i = 0; i < npin_cli; i++) {
            int s = pin_slot[i], p = pin_pair[i];
            if (s < 1 || s > X.n) {
                printf("*** FAIL: pin slot %d outside 1..%d\n", s, X.n); return 1;
            }
            int q = -1;
            for (int j = 0; j < X.n; j++) if (X.pl[j] == p) { q = j; break; }
            if (q < 0) {
                printf("*** FAIL: pinned pair %d not in the instance pair list\n", p);
                return 1;
            }
            if (X.pin_at[s - 1] >= 0) {
                printf("*** FAIL: slot %d pinned twice\n", s); return 1;
            }
            for (int j = 0; j < i; j++) if (pin_pair[j] == p) dup_pin = 1;
            if (i >= 8) { printf("*** FAIL: more than 8 pins\n"); return 1; }
            X.pin_at[s - 1] = q;
            char tb[16]; snprintf(tb, sizeof tb, "%s%d:%d", i ? "," : "", s, p);
            strncat(X.pinstr, tb, sizeof X.pinstr - strlen(X.pinstr) - 1);
        }
        X.npin = npin_cli;
    }
    if (dup_pin) {
        /* one pair at two slots cannot be a C1 permutation: N = 0 by definition
         * (matches the IE engine's duplicate-pin self-test). */
        printf("pins    : DUPLICATE pinned pair -> N = 0 identically\n");
        printf("RESULT  : N = 0\n");
        if (expect) {
            int eq = !strcmp(expect, "0");
            printf("          vs expected %s : %s\n", expect, eq ? "MATCH" : "*** MISMATCH ***");
            return eq ? 0 : 1;
        }
        return 0;
    }
    /* pin order = slot order; free-pair list = instance minus pinned */
    {   int no = 0;
        for (int t = 0; t < X.n; t++)
            if (X.pin_at[t] >= 0) {
                X.pin_ord[t] = no;
                X.pqa[no] = PA[X.pl[X.pin_at[t]]];
                X.pqb[no] = PB[X.pl[X.pin_at[t]]];
                no++;
            }
        X.nfree = 0;
        for (int j = 0; j < X.n; j++) {
            int pinned = 0;
            for (int t = 0; t < X.n; t++) if (X.pin_at[t] == j) pinned = 1;
            if (!pinned) {
                X.fpl[X.nfree] = X.pl[j];
                X.fpa[X.nfree] = PA[X.pl[j]];
                X.fpb[X.nfree] = PB[X.pl[j]];
                X.nfree++;
            }
        }
        if (X.nfree + X.npin != X.n) { printf("*** FAIL: pin bookkeeping\n"); return 1; }
    }
    if (X.npin)
        printf("pins    : %d forced step(s) [slot:pair] %s (orientation free);\n"
               "          mask covers the %d free pairs; the mod-24 free-action\n"
               "          gate does NOT apply under pins (informational only)\n",
               X.npin, X.pinstr, X.nfree);

    /* ---- budget ---- */
    if (no_budget) {
        if (have_b0) { printf("*** FAIL: --dp-b0 contradicts --dp-no-budget\n"); return 1; }
        printf("budget  : NONE (--dp-no-budget: C5 dropped; plain (M,last) DP)\n");
        X.ncomb = 1; X.D = 0; X.nnodes = 1; X.comb_final = 0;
        X.tsum[0] = 0;
    } else {
        if (have_b0) memcpy(X.b0v, b0_cli, sizeof X.b0v);
        else if (X.n == 31) {
            for (int i = 0; i < 31; i++) {
                int d = hamming(KW[2 * i + 1], KW[2 * i + 2]);
                int ci = cls_ix(d);
                if (ci < 0) { printf("*** FAIL: KW boundary outside classes\n"); return 1; }
                X.b0v[ci]++;
            }
            printf("budget  : full-31 B0 from KW boundary multiset = (%d,%d,%d,%d,%d)\n",
                   X.b0v[0], X.b0v[1], X.b0v[2], X.b0v[3], X.b0v[4]);
        } else {
            int cnt[5] = {0,0,0,0,0};
            ie_b0g_found = 0;
            ie_b0g_dfs(X.pl, X.n, 0, X.start, 0, cnt, X.b0v);
            if (!ie_b0g_found) { printf("*** FAIL: no completing walk (B0 DFS)\n"); return 1; }
            printf("budget  : rung B0 via TR-11 SS5 Step-1 DFS = (%d,%d,%d,%d,%d)\n",
                   X.b0v[0], X.b0v[1], X.b0v[2], X.b0v[3], X.b0v[4]);
        }
        if (negctl) {
            int tt = X.b0v[1]; X.b0v[1] = X.b0v[3]; X.b0v[3] = tt;
            printf("budget  : *** NEGATIVE CONTROL: d2/d4 budgets swapped -> (%d,%d,%d,%d,%d);\n"
                   "          the count MUST differ from the published value ***\n",
                   X.b0v[0], X.b0v[1], X.b0v[2], X.b0v[3], X.b0v[4]);
        }
        int sum = 0;
        for (int c = 0; c < 5; c++) { if (X.b0v[c] < 0) { printf("*** FAIL: bad B0\n"); return 1; } sum += X.b0v[c]; }
        if (sum != X.n) {
            printf("*** FAIL: budget sum %d != n=%d\n", sum, X.n);
            return 1;
        }
        X.tcap[0] = X.b0v[0]; X.tcap[1] = X.b0v[3]; X.tcap[2] = X.b0v[4];
        X.cstr[2] = 1;
        X.cstr[1] = X.tcap[2] + 1;
        X.cstr[0] = (X.tcap[1] + 1) * (X.tcap[2] + 1);
        X.ncomb = (X.tcap[0] + 1) * X.cstr[0];
        if (X.ncomb > DP_MAXCOMB) { printf("*** FAIL: tracked-comb space too large\n"); return 1; }
        X.D = X.b0v[1] + X.b0v[2];
        X.nnodes = X.D + 2;
        X.comb_final = X.tcap[0] * X.cstr[0] + X.tcap[1] * X.cstr[1] + X.tcap[2];
        for (int c = 0; c < X.ncomb; c++) {
            int a = c / X.cstr[0], d4 = (c / X.cstr[1]) % (X.tcap[1] + 1), e = c % (X.tcap[2] + 1);
            X.tsum[c] = (uint8_t)(a + d4 + e);
            X.trk_ok[0][c] = a  < X.tcap[0];
            X.trk_ok[1][c] = d4 < X.tcap[1];
            X.trk_ok[2][c] = e  < X.tcap[2];
        }
        printf("split   : tracked (d1,d4,d6) caps (%d,%d,%d) -> %d combs; derived\n"
               "          s = #d2+#d3 killed above D=%d; y on d2-steps; N = the\n"
               "          y^%d coefficient, fit at y=1..%d, checked at y=%d\n",
               X.tcap[0], X.tcap[1], X.tcap[2], X.ncomb, X.D,
               X.b0v[1], X.D + 1, X.D + 2);
    }
    /* class map: d = hamming(last, enter); 0 and the C2-forbidden 5 excluded
     * (no-budget negative control would swap the forbidden class — the IE
     * engine covers that control; here negctl is the budget swap above). */
    for (int enter = 0; enter < 64; enter++)
        for (int h = 0; h < 64; h++) {
            int d = hamming(h, enter);
            int ci = (d == 0 || d == 5) ? -1 : cls_ix(d);
            X.cmap[enter][h] = (int8_t)(no_budget ? (ci < 0 ? -1 : 2) : ci);
        }

    printf("instance: n=%d start=%d spec=%s nfree=%d  pairs=", X.n, X.start, spec, X.nfree);
    for (int i = 0; i < X.n; i++) printf("%s%d", i ? "," : "", X.pl[i]);
    printf("\n");

    /* ---- layer plan (also the --dp-size-only output) ---- */
    {   double peak = 0, prev = 0;
        int pc = 0;
        for (int t = 1; t <= X.n; t++) {
            int pin = X.pin_ord[t-1];
            pc += (pin < 0) ? 1 : 0;
            int nls = (pin >= 0) ? 2 : 2 * pc;
            double gb = (double)dp_C[X.nfree][pc] * nls * X.ncomb * 8 / 1e9;
            if (gb + prev > peak) peak = gb + prev;
            if (size_only)
                printf("  layer t=%2d %s pc=%2d masks=%llu nls=%2d  %.2f GB\n",
                       t, pin >= 0 ? "PIN " : "free", pc,
                       (unsigned long long)dp_C[X.nfree][pc], nls, gb);
            prev = gb;
        }
        printf("memory  : peak resident (two adjacent layers) = %.1f GB; units = %d\n",
               peak, X.nnodes * 3);
        if (size_only) return 0;
    }

    uint64_t primes[3];
    ie_pick_primes(primes);
    for (int i = 0; i < 3; i++)
        if (!ie_is_prime_u64(primes[i])) { printf("*** FAIL: prime selection\n"); return 1; }
    printf("primes  : p0=%llu p1=%llu p2=%llu (Miller-Rabin-proven at startup)\n",
           (unsigned long long)primes[0], (unsigned long long)primes[1],
           (unsigned long long)primes[2]);

    int runp[3] = {0,0,0};
    if (!strcmp(modsel, "all")) runp[0] = runp[1] = runp[2] = 1;
    else if (!strcmp(modsel, "p0")) runp[0] = 1;
    else if (!strcmp(modsel, "p1")) runp[1] = 1;
    else if (!strcmp(modsel, "p2")) runp[2] = 1;
    else { printf("*** FAIL: bad --dp-mod '%s' (all|p0|p1|p2)\n", modsel); return 1; }

    /* ---- unit checkpoint (prime x node granularity) ---- */
    char hdr[512];
    snprintf(hdr, sizeof hdr,
             "DPv1 n=%d start=%d b0=%d,%d,%d,%d,%d nb=%d negctl=%d D=%d nodes=%d pins=%s pl=",
             X.n, X.start, X.b0v[0], X.b0v[1], X.b0v[2], X.b0v[3], X.b0v[4],
             X.no_budget, X.negctl, X.D, X.nnodes, X.npin ? X.pinstr : "-");
    for (int i = 0; i < X.n; i++) {
        char tb[8]; snprintf(tb, sizeof tb, "%s%d", i ? "," : "", X.pl[i]);
        strncat(hdr, tb, sizeof hdr - strlen(hdr) - 1);
    }
    uint64_t V[3][64];
    int have[3][64];
    memset(have, 0, sizeof have);
    FILE *ck = NULL;
    if (ckpt) {
        FILE *f = fopen(ckpt, "r");
        if (f) {
            char line[600];
            if (!fgets(line, sizeof line, f)) {
                printf("*** FAIL: empty checkpoint %s\n", ckpt); fclose(f); return 1;
            }
            line[strcspn(line, "\n")] = 0;
            if (strcmp(line, hdr)) {
                printf("*** FAIL: checkpoint header mismatch in %s\n  have: %s\n  want: %s\n",
                       ckpt, line, hdr);
                fclose(f); return 1;
            }
            int pi, nj; unsigned long long vv;
            int resumed = 0;
            while (fscanf(f, "U %d %d %llu\n", &pi, &nj, &vv) == 3) {
                if (pi < 0 || pi > 2 || nj < 0 || nj >= X.nnodes || have[pi][nj]) continue;
                V[pi][nj] = vv; have[pi][nj] = 1; resumed++;
            }
            fclose(f);
            printf("[dp] resumed %d completed unit(s) from %s\n", resumed, ckpt);
            ck = fopen(ckpt, "a");
        } else {
            ck = fopen(ckpt, "w");
            if (ck) { fprintf(ck, "%s\n", hdr); fflush(ck); }
        }
        if (!ck) { printf("*** FAIL: cannot open checkpoint %s\n", ckpt); return 1; }
    }

    /* ---- the units ---- */
    double tot_wall = 0;
    for (int pi = 0; pi < 3; pi++) {
        if (!runp[pi]) continue;
        for (int nj = 0; nj < X.nnodes; nj++) {
            if (have[pi][nj]) continue;
            uint64_t val, tr;
            double wall;
            if (dp_run_unit(&X, primes[pi], (uint64_t)(nj + 1), threads, &val, &tr, &wall))
                return 1;
            V[pi][nj] = val; have[pi][nj] = 1;
            tot_wall += wall;
            printf("[dp] unit p%d y=%-2d  V=%llu  trans=%llu  wall=%.1fs\n",
                   pi, nj + 1, (unsigned long long)val, (unsigned long long)tr, wall);
            fflush(stdout);
            if (ck) { fprintf(ck, "U %d %d %llu\n", pi, nj, (unsigned long long)val);
                      fflush(ck); fsync(fileno(ck)); }
        }
    }
    if (ck) fclose(ck);
    if (!(runp[0] && runp[1] && runp[2])) {
        printf("RESULT: partial (single-modulus) run complete — no CRT\n");
        return 0;
    }

    /* ---- fit + overdetermination check + CRT ---- */
    uint64_t K[3][64];
    int fails = 0;
    for (int pi = 0; pi < 3; pi++) {
        if (X.no_budget) { K[pi][0] = V[pi][0]; continue; }
        if (!dp_fit_check(&X, primes[pi], V[pi], K[pi])) {
            printf("*** FAIL: overdetermination check at p%d (node y=%d does not\n"
                   "          lie on the degree-%d fit) — kernel integrity gate\n",
                   pi, X.D + 2, X.D);
            fails++;
        } else
            printf("fit     : p%d degree-%d fit OK; check node y=%d MATCHES\n",
                   pi, X.D, X.D + 2);
    }
    if (fails) return 1;
    int nb_out = X.no_budget ? 1 : X.D + 1;
    u192 N = {{0, 0, 0}};
    char dec[64];
    printf("----------------------------------------------------------------------\n");
    for (int b = 0; b < nb_out; b++) {
        uint64_t a3[3] = { K[0][b], K[1][b], K[2][b] };
        u192 Kb;
        ie_crt3(primes, a3, &Kb);
        u192_print(Kb, dec);
        if (X.no_budget) {
            printf("CRT     : N = %s   (no-budget count)\n", dec);
            N = Kb;
        } else if (b == X.b0v[1]) {
            printf("CRT     : K[%2d] = %-45s  <== N (budget (%d,%d,%d,%d,%d))\n",
                   b, dec, X.b0v[0], X.b0v[1], X.b0v[2], X.b0v[3], X.b0v[4]);
            N = Kb;
        } else
            printf("          K[%2d] = %-45s  (perturbed budget (%d,%d,%d,%d,%d))\n",
                   b, dec, X.b0v[0], b, X.D - b, X.b0v[3], X.b0v[4]);
    }
    printf("----------------------------------------------------------------------\n");
    u192_print(N, dec);
    printf("RESULT  : N = %s\n", dec);
    printf("          N mod 24 = %u%s\n", u192_mod(N, 24),
           X.npin ? "  (informational — free-action gate N/A under pins)"
                  : (X.n == 31 && !negctl)
                    ? (u192_mod(N, 24) == 0 ? "  (free-action gate: ok)"
                                            : "  *** FAIL: expected 0 ***") : "");
    if (X.n == 31 && !negctl && !X.npin && u192_mod(N, 24) != 0) fails++;
    const char *target = expect;
    if (!target && X.n == 31 && !have_b0)
        target = X.no_budget
                 ? (X.npin ? NULL : LC_PUBLISHED_COUNT_C1C2C4)
                 : (pin_c6c7 ? LC_PUBLISHED_COUNT_C1C7NOC3
                             : (X.npin ? NULL : LC_PUBLISHED_COUNT));
    if (target) {
        u192 E = u192_dec(target);
        int eq = u192_eq(N, E);
        if (negctl) {
            printf("          vs published %s : %s (negative control %s)\n", target,
                   eq ? "EQUAL" : "DIFFERS", eq ? "*** FAILED ***" : "passed");
            if (eq) fails++;
        } else {
            printf("          vs expected %s : %s\n", target,
                   eq ? "MATCH" : "*** MISMATCH ***");
            if (!eq) fails++;
        }
    }
    printf("RESULT: pass complete (%d units, %.1fs total unit wall)%s\n",
           3 * X.nnodes, tot_wall, fails ? "  *** WITH FAILURES ***" : "");
    return fails ? 1 : 0;
}

/* ==========================================================================
 * CLEAN-ROOM KNUTH PROBER  (--knuth-anchors / --knuth-probe)   [task #194]
 *
 * WHAT THIS IS. A second, clean-room instrument on the published Knuth
 * random-probe estimate of |C1 n C2 n C3 n C4 n C5 n C6 n C7| ~= 5.21e31
 * (SEARCH_SPACE_SIZE.md "The C1-C7 space"; produced by solve.c's
 * --estimate-knuth under SOLVE_KNUTH_C67=1). Per the #163 audit that
 * estimate's ONE uncorroborated factor at full scale is the C3 conditional
 * ratio (~0.101): every existing full-scale cross-check is C3-free by scope
 * (the no-C3 denominator 5.16880...e32 is exact and two-instrument — Routes
 * B and D above — and the canonical shas prove consistency with the
 * HISTORICAL C3 predicate, not its correctness). This prober therefore
 * carries its OWN C3 predicate and its OWN C6/C7 pin logic, derived from
 * the published definitions, so a coherent day-one C3 defect in solve.c
 * would show here as a stable shift in the estimate, not be inherited.
 * Pre-registration (agreement gate frozen before any run):
 * roae-private/PREREG_KNUTH_CLEANROOM_2026_08_08.md.
 *
 * INDEPENDENCE (same discipline as the rest of this file). No solve.c
 * header, table, constant, or transliterated function. Sources:
 *   - SPECIFICATION.md: C1-C5 definitions, the C5 multiset literal
 *     {1:2,2:20,3:13,4:19,6:9}, C3's threshold cd(S) <= 12.125 (x64 form:
 *     Sum_h |pos(h)-pos(h^63)| <= 776), and C6/C7's concrete pinned pair
 *     sets {29,46},{9,36} (C7, slots 24-25) / {11,52},{13,44} (C6, slots
 *     26-27), orientation free.
 *   - lean/C3Decomposition.lean: the machine-checked slot decomposition
 *     C3 = 16 + 8*G (8 self-complement pairs contribute the constant 16;
 *     G = Sum over the 12 cross complement-couples of |slot(u)-slot(v)|).
 *     Both forms are computed here INDEPENDENTLY at every complete leaf and
 *     cross-asserted — a spec-vs-Lean identity check on every evaluation.
 *   - verify.py --recount-subtree (the sibling clean-room instrument, NOT
 *     solve.c) pins the published tree-node convention: the walk tracks the
 *     COMBINED 63-transition C5 multiset (within-pair distances consumed as
 *     pairs are placed, budget[within] checked AFTER consuming the
 *     boundary), and tree_nodes counts every reached state including the
 *     (prefix) root. Leaf counts are convention-independent; the node
 *     convention only matters for reproducing the published 443 / 62,256 /
 *     9,422,793 anchors exactly.
 *
 * THE ALGORITHM (Knuth 1975, "Estimating the efficiency of backtrack
 * programs"). One probe: W = 1 at the root (the C4-forced (63,0) state, or
 * a deeper KW-following prefix state); at a node build the FULL list of
 * live children — (pair, orientation) placements passing C2 (boundary
 * d != 5) and the combined C5 budget — pick uniformly among the d children,
 * W *= d, descend; stop at a dead end or a complete 32-slot leaf. The leaf
 * weight (captured at completion, before any further multiplication) is an
 * unbiased estimator of the leaf count; Sum of W over visited states
 * estimates tree nodes; testing C3 at the leaf gives the canonical count.
 * X and X^2 are accumulated per probe for a Wald CI. RNG: splitmix64
 * (Steele-Lea-Flood, public domain constants), fixed seed recorded in the
 * result line; child selection by modulo — bias < d/2^64 (d <= 62), i.e.
 * < 4e-18, negligible against the ~1e-2 statistical error.
 *
 * C6/C7 PIN LOGIC (--knuth-probe default; --knuth-no-c67 disables). At
 * slots 24-27 the only candidate is that slot's spec-pinned pair (both
 * orientations); at all other slots the four pinned pairs are excluded.
 * The exclusion removes only subtrees with zero pin-satisfying leaves (a
 * pinned pair placed elsewhere makes its slot's pin unsatisfiable), so the
 * leaf estimators remain unbiased for the pinned targets while probes die
 * earlier. NOTE this walks a DIFFERENT tree from solve.c's pinned walk —
 * identical leaf set, so the leaf estimands agree in expectation, but the
 * node estimate is not comparable to solve.c's published pinned-tree-nodes
 * figure, and per-probe variance differs. That divergence is deliberate:
 * independence extends to the pin mechanism itself.
 *
 * VALIDATION (--knuth-anchors; run it BEFORE trusting any probe):
 *   1. structural: KW pairing partner-exact; within-pair multiset
 *      {2:12,4:12,6:8} + KW boundary multiset == the C5 literal; 8
 *      self-complement pairs / 12 cross-couples (Lean's counts); the four
 *      spec pin sets match KW pairs 24-27; c3x64(KW) == 776 == 16 + 8*95.
 *   2. exact subtree anchors: exhaustive DFS below KW-following prefixes,
 *      gated on the published exact counts (SEARCH_SPACE_SIZE §Validation,
 *      TR-5 §3): 5-free 443 nodes / 4 canonical, 7-free 62,256 / 2,232,
 *      9-free 9,422,793 / 16,504, and exactly 8 of the 16,504 satisfying
 *      C6/C7 (SEARCH_SPACE_SIZE §C1-C7). The spec-vs-Lean C3 identity is
 *      asserted at every complete leaf reached (696K+ evaluations).
 *   3. machinery: a fixed-seed probe run on the 9-free prefix must agree
 *      with the exact counts within 4 sigma of its own Wald CI — this
 *      exercises the weighting/RNG path the exact DFS does not.
 *
 * USAGE:
 *   ./verify --knuth-anchors
 *   ./verify --knuth-probe N [--knuth-seed S] [--knuth-threads T]
 *            [--knuth-no-c67] [--knuth-free F]
 * N probes; S = RNG seed (0x... or decimal; default 20260808); T worker
 * threads (default 1); F = probe the KW (32-F)-slot prefix subtree instead
 * of the full tree (validation aid; default 31 = full). Threads use
 * disjoint 2^40-draw splitmix64 segments (a probe consumes <= 31 draws, so
 * segments cannot overlap below ~3.5e10 probes/thread).
 * ========================================================================== */

/* Spec constants, restated from the PUBLISHED documents (not from solve.c). */
static const int KN_C5FULL[7] = {0, 2, 20, 13, 19, 0, 9};  /* SPECIFICATION.md C5:
                                  * index d -> count; {1:2,2:20,3:13,4:19,6:9} */
#define KN_C3MAX 776              /* SPECIFICATION.md C3: 64 * 12.125 */
#define KN_PIN_LO 24              /* C6/C7 pin slots 24..27 (positions 48..55) */
static const int KN_PIN_SETS[4][2] = {  /* SPECIFICATION.md C7 then C6, in slot order:
                                         * {s48,s49}={011101b,101110b} {s50,s51}={001001b,100100b}
                                         * {s52,s53}={001011b,110100b} {s54,s55}={001101b,101100b} */
    {29, 46}, {9, 36}, {11, 52}, {13, 44}
};
#define KN_SEED_DEFAULT 20260808ULL

/* Derived-at-init tables (from the KW table + partner(), both spec-derived). */
static int KN_WD[32];             /* within-pair Hamming distance per pair    */
static int KN_CU[12], KN_CV[12];  /* the 12 cross complement-couples (i < j)  */
static int KN_NCOUPLE, KN_NSELF;

/* Derive the complement-couple structure and check every finite fact this
 * prober rests on. Returns 0 (with a printed reason) on any failure — a
 * failure here is a FINDING about the published definitions, not a state to
 * patch around. */
static int kn_init(void) {
    if (!build_pairs()) return 0;
    int wcnt[7] = {0}, bcnt[7] = {0};
    for (int i = 0; i < 32; i++) {
        KN_WD[i] = hamming(PA[i], PB[i]);
        wcnt[KN_WD[i]]++;
    }
    for (int i = 0; i < 31; i++) bcnt[hamming(KW[2 * i + 1], KW[2 * i + 2])]++;
    for (int d = 0; d < 7; d++)
        if (wcnt[d] + bcnt[d] != KN_C5FULL[d]) {
            printf("*** KN INIT FAIL: within+boundary multiset != C5 literal at d=%d "
                   "(%d+%d != %d)\n", d, wcnt[d], bcnt[d], KN_C5FULL[d]);
            return 0;
        }
    KN_NCOUPLE = KN_NSELF = 0;
    for (int i = 0; i < 32; i++) {
        int ca = comp6(PA[i]), j = -1;
        for (int k = 0; k < 32; k++)
            if (PA[k] == ca || PB[k] == ca) { j = k; break; }
        if (j < 0 || !((comp6(PA[i]) == PA[j] && comp6(PB[i]) == PB[j]) ||
                       (comp6(PA[i]) == PB[j] && comp6(PB[i]) == PA[j]))) {
            printf("*** KN INIT FAIL: pairing not closed under complement at pair %d\n", i);
            return 0;
        }
        if (j == i) KN_NSELF++;
        else if (j > i) { KN_CU[KN_NCOUPLE] = i; KN_CV[KN_NCOUPLE] = j; KN_NCOUPLE++; }
    }
    if (KN_NSELF != 8 || KN_NCOUPLE != 12) {   /* lean/C3Decomposition.lean counts */
        printf("*** KN INIT FAIL: %d self-complement pairs / %d couples (want 8 / 12)\n",
               KN_NSELF, KN_NCOUPLE);
        return 0;
    }
    for (int k = 0; k < 4; k++) {              /* spec C6/C7 sets == KW pairs 24..27 */
        int a = PA[KN_PIN_LO + k], b = PB[KN_PIN_LO + k];
        int u = KN_PIN_SETS[k][0], v = KN_PIN_SETS[k][1];
        if (!((a == u && b == v) || (a == v && b == u))) {
            printf("*** KN INIT FAIL: spec C6/C7 pin set %d {%d,%d} != KW pair %d "
                   "{%d,%d}\n", k, u, v, KN_PIN_LO + k, a, b);
            return 0;
        }
    }
    return 1;
}

/* C3, form 1 — the SPECIFICATION.md definition, computed directly:
 * Sum over all 64 hexagrams of |pos(h) - pos(h ^ 63)|. */
static int kn_c3_direct(const int *pos) {
    int s = 0;
    for (int h = 0; h < 64; h++) {
        int d = pos[h] - pos[h ^ 63];
        s += d < 0 ? -d : d;
    }
    return s;
}

/* C3, form 2 — the lean/C3Decomposition.lean slot decomposition 16 + 8*G. */
static int kn_c3_slots(const int *slot_of) {
    int g = 0;
    for (int c = 0; c < 12; c++) {
        int d = slot_of[KN_CU[c]] - slot_of[KN_CV[c]];
        g += d < 0 ? -d : d;
    }
    return 16 + 8 * g;
}

/* Shared walk/DFS state (small; per-thread instances are heap-allocated). */
typedef struct {
    int budget[7];                /* remaining combined C5 multiset            */
    int pos[64];                  /* position of each hexagram (valid entries:
                                   * the pairs placed on the current path)     */
    int slot_of[32];              /* slot index of each placed pair            */
    int step0, last0;             /* prefix: first free slot, prefix exit hex  */
    uint32_t used0;               /* prefix: pair usage mask                   */
} KnState;

/* Build the KW-following prefix occupying slots 0..(32-nfree-1) in KW's own
 * orientations, consuming the combined budget. Returns 0 if infeasible (it
 * never is for the published KW — a failure is a finding). */
static int kn_prefix(KnState *S, int nfree) {
    int nplaced = 32 - nfree;
    for (int d = 0; d < 7; d++) S->budget[d] = KN_C5FULL[d];
    S->budget[KN_WD[0]]--;                     /* pair 0's within transition */
    S->pos[PA[0]] = 0; S->pos[PB[0]] = 1;      /* C4: (63, 0) at slot 0      */
    S->slot_of[0] = 0;
    int last = PB[0];
    for (int t = 1; t < nplaced; t++) {
        int f = PA[t], s = PB[t];              /* KW orientation as published */
        int bd = hamming(last, f);
        if (bd == 5 || S->budget[bd] == 0) return 0;
        S->budget[bd]--;
        if (S->budget[KN_WD[t]] == 0) return 0;
        S->budget[KN_WD[t]]--;
        S->pos[f] = 2 * t; S->pos[s] = 2 * t + 1;
        S->slot_of[t] = t;
        last = s;
    }
    S->step0 = nplaced;
    S->last0 = last;
    S->used0 = (nplaced >= 32) ? 0xFFFFFFFFu : ((1u << nplaced) - 1u);
    return 1;
}

/* ---- exact exhaustive DFS below a prefix (the anchor instrument) ---- */
typedef struct {
    KnState st;
    uint64_t nodes, leaves, canon, canon67, identfail;
} KnExact;

static void kn_exact_rec(KnExact *E, int step, int last, uint32_t used) {
    E->nodes++;
    if (step == 32) {
        E->leaves++;
        int c3 = kn_c3_direct(E->st.pos);
        if (c3 != kn_c3_slots(E->st.slot_of)) E->identfail++;
        if (c3 <= KN_C3MAX) {
            E->canon++;
            int p67 = 1;
            for (int k = 0; k < 4; k++)
                if (E->st.slot_of[KN_PIN_LO + k] != KN_PIN_LO + k) p67 = 0;
            if (p67) E->canon67++;
        }
        return;
    }
    for (int p = 1; p < 32; p++) {
        if (used & (1u << p)) continue;
        int wd = KN_WD[p];
        for (int o = 0; o < 2; o++) {
            int f = o ? PB[p] : PA[p], s = o ? PA[p] : PB[p];
            int bd = hamming(last, f);
            if (bd == 5 || bd == 0 || E->st.budget[bd] == 0) continue;
            if (wd == bd ? E->st.budget[bd] < 2 : E->st.budget[wd] == 0) continue;
            E->st.budget[bd]--; E->st.budget[wd]--;
            E->st.pos[f] = 2 * step; E->st.pos[s] = 2 * step + 1;
            E->st.slot_of[p] = step;
            kn_exact_rec(E, step + 1, s, used | (1u << p));
            E->st.budget[bd]++; E->st.budget[wd]++;
        }
    }
}

/* ---- the random prober ---- */
static uint64_t kn_rng_next(uint64_t *s) {     /* splitmix64 */
    uint64_t z = (*s += 0x9E3779B97F4A7C15ULL);
    z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
    z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
    return z ^ (z >> 31);
}

typedef struct {
    /* in */
    const KnState *init;
    uint64_t seed, nprobes;
    int c67;
    /* out */
    long double sx, sx2;          /* canonical leaf weight (0 for non-hits)   */
    long double sy, sy2;          /* all-leaves weight                        */
    long double sn, sn2;          /* Sum W over visited states (tree nodes)   */
    uint64_t leaves, hits, identfail;
    _Atomic uint64_t done;        /* progress, updated per chunk (racy reads
                                   * by the poller are display-only)          */
    pthread_t tid;
} KnWorker;

static void *kn_worker(void *arg) {
    KnWorker *w = (KnWorker *)arg;
    KnState *S = malloc(sizeof *S);            /* keep large state off-stack */
    struct { uint8_t p, o; } *ch = malloc(62 * sizeof *ch);
    if (!S || !w->init || !ch) { free(S); free(ch); return NULL; }
    uint64_t rng = w->seed;
    uint64_t since = 0;
    for (uint64_t n = 0; n < w->nprobes; n++) {
        *S = *w->init;
        int last = S->last0;
        uint32_t used = S->used0;
        long double W = 1.0L, nodesum = 1.0L;
        int step = S->step0;
        for (; step < 32; step++) {
            int nch = 0;
            int plo = 1, phi = 32;
            int pinned = w->c67 && step >= KN_PIN_LO && step < KN_PIN_LO + 4;
            if (pinned) { plo = step; phi = step + 1; }
            for (int p = plo; p < phi; p++) {
                if (used & (1u << p)) continue;
                if (w->c67 && !pinned && p >= KN_PIN_LO && p < KN_PIN_LO + 4)
                    continue;                  /* reserved for its pinned slot */
                int wd = KN_WD[p];
                for (int o = 0; o < 2; o++) {
                    int f = o ? PB[p] : PA[p];
                    int bd = hamming(last, f);
                    if (bd == 5 || bd == 0 || S->budget[bd] == 0) continue;
                    if (wd == bd ? S->budget[bd] < 2 : S->budget[wd] == 0) continue;
                    ch[nch].p = (uint8_t)p; ch[nch].o = (uint8_t)o; nch++;
                }
            }
            if (nch == 0) break;               /* dead end */
            int pick = (int)(kn_rng_next(&rng) % (uint64_t)nch);
            int p = ch[pick].p, o = ch[pick].o;
            int f = o ? PB[p] : PA[p], s = o ? PA[p] : PB[p];
            int bd = hamming(last, f);
            S->budget[bd]--; S->budget[KN_WD[p]]--;
            S->pos[f] = 2 * step; S->pos[s] = 2 * step + 1;
            S->slot_of[p] = step;
            used |= 1u << p;
            last = s;
            W *= (long double)nch;
            nodesum += W;
        }
        w->sn += nodesum; w->sn2 += nodesum * nodesum;
        if (step == 32) {                      /* complete leaf; weight is W,
                                                * captured before any further
                                                * multiplication              */
            w->leaves++;
            w->sy += W; w->sy2 += W * W;
            int c3 = kn_c3_direct(S->pos);
            if (c3 != kn_c3_slots(S->slot_of)) w->identfail++;
            if (c3 <= KN_C3MAX) { w->hits++; w->sx += W; w->sx2 += W * W; }
        }
        if (++since == (1u << 20)) {
            atomic_fetch_add_explicit(&w->done, since, memory_order_relaxed);
            since = 0;
        }
    }
    atomic_fetch_add_explicit(&w->done, since, memory_order_relaxed);
    free(ch);
    free(S);
    return NULL;
}

/* mean / 95% CI / z-vs-target helper */
typedef struct { long double mean, se, lo, hi; } KnCI;
static KnCI kn_ci(long double s, long double s2, long double n) {
    KnCI c;
    c.mean = s / n;
    long double var = s2 / n - c.mean * c.mean;
    if (var < 0) var = 0;
    c.se = sqrtl(var / n);
    c.lo = c.mean - 1.96L * c.se;
    c.hi = c.mean + 1.96L * c.se;
    return c;
}
static long double kn_dec_ld(const char *s) {  /* decimal string -> long double */
    long double v = 0;
    for (; *s; s++) if (*s >= '0' && *s <= '9') v = v * 10 + (*s - '0');
    return v;
}

/* ---- --knuth-anchors ---- */
static int kn_anchors_main(void) {
    if (!kn_init()) return 1;
    printf("======================================================================\n");
    printf("verify.c --knuth-anchors — clean-room Knuth prober validation (#194)\n");
    printf("predicates + tree convention from SPECIFICATION.md / C3Decomposition\n");
    printf(".lean / the published subtree-anchor convention; nothing from solve.c\n");
    printf("======================================================================\n");
    int fails = 0;
    KnState kws;
    if (!kn_prefix(&kws, 0)) { printf("*** FAIL: KW itself infeasible\n"); return 1; }
    int c3kw = kn_c3_direct(kws.pos), c3kw2 = kn_c3_slots(kws.slot_of);
    printf("KW: c3x64 direct=%d, 16+8*G=%d (spec: 776; Lean: G=95)  %s\n",
           c3kw, c3kw2, (c3kw == 776 && c3kw2 == 776) ? "ok" : "*** FAIL ***");
    if (c3kw != 776 || c3kw2 != 776) fails++;

    /* published exact anchors: SEARCH_SPACE_SIZE §Validation + §C1-C7, TR-5 §3 */
    static const struct { int nfree; uint64_t nodes, canon; } A[3] = {
        {5, 443ULL, 4ULL}, {7, 62256ULL, 2232ULL}, {9, 9422793ULL, 16504ULL}
    };
    KnExact *E = malloc(sizeof *E);
    if (!E) { printf("*** FAIL: out of memory\n"); return 1; }
    for (int i = 0; i < 3; i++) {
        memset(E, 0, sizeof *E);
        if (!kn_prefix(&E->st, A[i].nfree)) {
            printf("*** FAIL: %d-free prefix infeasible\n", A[i].nfree);
            fails++; continue;
        }
        kn_exact_rec(E, E->st.step0, E->st.last0, E->st.used0);
        int ok = E->nodes == A[i].nodes && E->canon == A[i].canon
                 && E->identfail == 0 && (A[i].nfree != 9 || E->canon67 == 8);
        printf("%d-free: nodes=%llu (want %llu)  leaves=%llu  canonical=%llu "
               "(want %llu)  canon+C6/C7=%llu%s  C3 spec-vs-Lean mismatches=%llu"
               "  %s\n",
               A[i].nfree,
               (unsigned long long)E->nodes, (unsigned long long)A[i].nodes,
               (unsigned long long)E->leaves,
               (unsigned long long)E->canon, (unsigned long long)A[i].canon,
               (unsigned long long)E->canon67, A[i].nfree == 9 ? " (want 8)" : "",
               (unsigned long long)E->identfail, ok ? "ok" : "*** FAIL ***");
        if (!ok) fails++;
    }

    /* machinery: fixed-seed probe on the 9-free prefix vs the exact counts
     * (exercises the W-weighting + RNG path the exhaustive DFS never runs).
     * 4-sigma gate on the probe's own Wald CI; deterministic at this seed. */
    KnState ps;
    uint64_t exact_nodes = E->nodes, exact_leaves = E->leaves, exact_canon = E->canon;
    free(E);
    if (!kn_prefix(&ps, 9)) { printf("*** FAIL: probe prefix\n"); return 1; }
    KnWorker *w = calloc(1, sizeof *w);
    if (!w) { printf("*** FAIL: out of memory\n"); return 1; }
    w->init = &ps; w->seed = KN_SEED_DEFAULT; w->nprobes = 2000000; w->c67 = 0;
    kn_worker(w);
    long double n = (long double)w->nprobes;
    KnCI cn = kn_ci(w->sn, w->sn2, n), cl = kn_ci(w->sy, w->sy2, n),
         cc = kn_ci(w->sx, w->sx2, n);
    struct { const char *nm; KnCI *c; uint64_t want; } P[3] = {
        {"nodes", &cn, exact_nodes}, {"leaves", &cl, exact_leaves},
        {"canonical", &cc, exact_canon}
    };
    printf("probe machinery (9-free, %llu probes, seed %llu):\n",
           (unsigned long long)w->nprobes, (unsigned long long)w->seed);
    for (int i = 0; i < 3; i++) {
        long double z = P[i].c->se > 0
            ? fabsl(P[i].c->mean - (long double)P[i].want) / P[i].c->se : 999.0L;
        int ok = z <= 4.0L;
        printf("  %-9s est=%.1Lf  exact=%llu  z=%.2Lf  %s\n", P[i].nm,
               P[i].c->mean, (unsigned long long)P[i].want, z,
               ok ? "ok" : "*** FAIL (>4 sigma) ***");
        if (!ok) fails++;
    }
    if (w->identfail) { printf("  *** FAIL: %llu C3 identity mismatches in probe\n",
                               (unsigned long long)w->identfail); fails++; }
    free(w);
    printf("======================================================================\n");
    printf("RESULT: %s\n", fails ? "*** ANCHOR VALIDATION FAILED — do not run the "
                                   "prober; report, do not tune ***"
                                 : "all anchors + machinery checks PASS");
    printf("======================================================================\n");
    return fails ? 1 : 0;
}

/* ---- --knuth-probe ---- */
static int kn_probe_main(int argc, char **argv) {
    uint64_t nprobes = 0, seed = KN_SEED_DEFAULT;
    int nthreads = 1, c67 = 1, nfree = 31;
    if (argc < 3) {
        fprintf(stderr, "usage: %s --knuth-probe N [--knuth-seed S] [--knuth-threads T]"
                        " [--knuth-no-c67] [--knuth-free F]\n", argv[0]);
        return 2;
    }
    nprobes = strtoull(argv[2], NULL, 0);
    for (int i = 3; i < argc; i++) {
        if (strcmp(argv[i], "--knuth-seed") == 0 && i + 1 < argc)
            seed = strtoull(argv[++i], NULL, 0);
        else if (strcmp(argv[i], "--knuth-threads") == 0 && i + 1 < argc)
            nthreads = atoi(argv[++i]);
        else if (strcmp(argv[i], "--knuth-no-c67") == 0) c67 = 0;
        else if (strcmp(argv[i], "--knuth-free") == 0 && i + 1 < argc)
            nfree = atoi(argv[++i]);
        else { fprintf(stderr, "unknown option %s\n", argv[i]); return 2; }
    }
    if (nprobes == 0 || nthreads < 1 || nthreads > 256 || nfree < 1 || nfree > 31) {
        fprintf(stderr, "bad arguments (N>=1, 1<=T<=256, 1<=F<=31)\n");
        return 2;
    }
    if (!kn_init()) return 1;
    KnState init;
    if (!kn_prefix(&init, nfree)) { printf("*** FAIL: prefix infeasible\n"); return 1; }

    printf("[knuth] clean-room prober: probes=%llu seed=%llu (0x%llx) threads=%d "
           "c67=%d free=%d\n",
           (unsigned long long)nprobes, (unsigned long long)seed,
           (unsigned long long)seed, nthreads, c67, nfree);
    printf("[knuth] target: %s\n",
           c67 ? (nfree == 31 ? "|C1nC2nC3nC4nC5nC6nC7| (published estimate 5.21e31)"
                              : "pinned KW-prefix subtree (validation)")
               : (nfree == 31 ? "|C1..C5| (published estimate 1.3287e38)"
                              : "KW-prefix subtree (validation)"));

    KnWorker *w = calloc((size_t)nthreads, sizeof *w);
    if (!w) { printf("*** FAIL: out of memory\n"); return 1; }
    struct timespec t0, t1;
    clock_gettime(CLOCK_MONOTONIC, &t0);
    uint64_t per = nprobes / (uint64_t)nthreads;
    for (int t = 0; t < nthreads; t++) {
        w[t].init = &init;
        /* disjoint splitmix64 segments: thread t starts 2^40 draws into the
         * stream past thread t-1 (each probe draws <= 31 values)            */
        w[t].seed = seed + ((uint64_t)t << 40) * 0x9E3779B97F4A7C15ULL;
        w[t].nprobes = t == nthreads - 1 ? nprobes - per * (uint64_t)(nthreads - 1) : per;
        w[t].c67 = c67;
        if (pthread_create(&w[t].tid, NULL, kn_worker, &w[t]) != 0) {
            printf("*** FAIL: pthread_create\n"); free(w); return 1;
        }
    }
    /* progress poll (display-only; counters are relaxed atomics) */
    double last_print = 0;
    for (;;) {
        uint64_t done = 0;
        for (int t = 0; t < nthreads; t++)
            done += atomic_load_explicit(&w[t].done, memory_order_relaxed);
        if (done >= nprobes) break;
        struct timespec ts = {5, 0};
        nanosleep(&ts, NULL);
        clock_gettime(CLOCK_MONOTONIC, &t1);
        double el = (double)(t1.tv_sec - t0.tv_sec) + 1e-9 * (double)(t1.tv_nsec - t0.tv_nsec);
        if (el - last_print >= 30 && done > 0) {
            last_print = el;
            printf("[knuth] progress %llu/%llu probes (%.1f%%), %.0f/s, ETA %.0f s\n",
                   (unsigned long long)done, (unsigned long long)nprobes,
                   100.0 * (double)done / (double)nprobes, (double)done / el,
                   ((double)nprobes - (double)done) * el / (double)done);
            fflush(stdout);
        }
    }
    for (int t = 0; t < nthreads; t++) pthread_join(w[t].tid, NULL);
    clock_gettime(CLOCK_MONOTONIC, &t1);
    double wall = (double)(t1.tv_sec - t0.tv_sec) + 1e-9 * (double)(t1.tv_nsec - t0.tv_nsec);

    long double sx = 0, sx2 = 0, sy = 0, sy2 = 0, sn = 0, sn2 = 0;
    uint64_t leaves = 0, hits = 0, identfail = 0;
    for (int t = 0; t < nthreads; t++) {
        sx += w[t].sx; sx2 += w[t].sx2; sy += w[t].sy; sy2 += w[t].sy2;
        sn += w[t].sn; sn2 += w[t].sn2;
        leaves += w[t].leaves; hits += w[t].hits; identfail += w[t].identfail;
    }
    free(w);
    long double n = (long double)nprobes;
    KnCI cx = kn_ci(sx, sx2, n), cy = kn_ci(sy, sy2, n), cn = kn_ci(sn, sn2, n);

    printf("[knuth] probes=%llu wall=%.1fs rate=%.0f/s (%.0f/s/thread)\n",
           (unsigned long long)nprobes, wall, (double)nprobes / wall,
           (double)nprobes / wall / nthreads);
    printf("[knuth] complete leaves reached: %llu; canonical (C3-passing): %llu; "
           "C3 spec-vs-Lean mismatches: %llu%s\n",
           (unsigned long long)leaves, (unsigned long long)hits,
           (unsigned long long)identfail,
           identfail ? "  *** IDENTITY FAILURE — INVESTIGATE ***" : "");
    printf("[knuth] RESULT canonical%s: est=%.6Le  CI95=[%.6Le, %.6Le]  "
           "relerr=%.2Lf%%  (seed %llu)\n",
           c67 ? " (C1..C7)" : " (C1..C5)", cx.mean, cx.lo, cx.hi,
           cx.mean > 0 ? 100.0L * cx.se / cx.mean : -1.0L,
           (unsigned long long)seed);
    printf("[knuth] RESULT no-C3 leaves%s: est=%.6Le  CI95=[%.6Le, %.6Le]  "
           "relerr=%.2Lf%%\n",
           c67 ? " (C1,C2,C4,C5 + pins)" : " (C1,C2,C4,C5)", cy.mean, cy.lo, cy.hi,
           cy.mean > 0 ? 100.0L * cy.se / cy.mean : -1.0L);
    printf("[knuth] RESULT tree nodes: est=%.6Le  relerr=%.2Lf%%  (NOTE: %s)\n",
           cn.mean, cn.mean > 0 ? 100.0L * cn.se / cn.mean : -1.0L,
           c67 ? "pin-exclusion tree — NOT comparable to solve.c's pinned node count"
               : "comparable to the published 2.0875e40");
    if (nfree == 31) {
        /* free calibration: the no-C3 leaf estimand has an EXACT published
         * value (this file's own Routes B/D constants) in both modes        */
        const char *exact_s = c67 ? LC_PUBLISHED_COUNT_C1C7NOC3 : LC_PUBLISHED_COUNT;
        long double exact = kn_dec_ld(exact_s);
        long double zden = cy.se > 0 ? (cy.mean - exact) / cy.se : 999.0L;
        printf("[knuth] no-C3 vs exact %s:\n        ratio=%.6Lf  z=%.2Lf  "
               "(C3-free walk calibration)\n", exact_s, cy.mean / exact, zden);
        if (cy.mean > 0)
            printf("[knuth] C3 conditional ratio (canonical / no-C3): %.6Lf  "
                   "(published-derived reference 5.21e31 / 5.16880e32 = 0.1008)\n",
                   cx.mean / cy.mean);
    }
    return identfail ? 1 : 0;
}

int main(int argc, char **argv) {
    if (argc >= 2 && strcmp(argv[1], "--check-layers-selftest") == 0) return lc_selftest();
    if (argc >= 2 && strcmp(argv[1], "--check-gt-selftest") == 0) return lc_gt_selftest();
    if (argc >= 2 && strcmp(argv[1], "--check-repr") == 0) return vc_check_repr_main(argc, argv);
    if (argc >= 2 && strcmp(argv[1], "--check-artifact") == 0) return vc_check_artifact_main(argc, argv);
    if (argc >= 2 && strcmp(argv[1], "--ie-count") == 0) return ie_count_main(argc, argv);
    if (argc >= 2 && strcmp(argv[1], "--ie-probe") == 0) return ie_probe_main(argc, argv);
    if (argc >= 2 && strcmp(argv[1], "--dp-count") == 0) return dp_count_main(argc, argv);
    if (argc >= 2 && strcmp(argv[1], "--knuth-anchors") == 0) return kn_anchors_main();
    if (argc >= 2 && strcmp(argv[1], "--knuth-probe") == 0) return kn_probe_main(argc, argv);
    if (argc >= 2 && strcmp(argv[1], "--check-layers") == 0) {
        if (argc < 3) { fprintf(stderr, "usage: %s --check-layers DIR [max_k] [run.out]\n", argv[0]); return 2; }
        return lc_check_layers(argv[2], argc > 3 ? atoi(argv[3]) : 31,
                               argc > 4 ? argv[4] : NULL);
    }
    if (argc >= 2 && strcmp(argv[1], "--scan-layers") == 0) {
        if (argc < 3) { fprintf(stderr, "usage: %s --scan-layers DIR [max_k] [run.out]   "
                                        "(env: LC_SCAN_LANES/CHUNK_KB/ODIRECT/T6STUB, LC_RESUME)\n", argv[0]); return 2; }
        LcScanCfg cfg = lcs_cfg_from_env();
        return lc_check_layers_impl(argv[2], argc > 3 ? atoi(argv[3]) : 31,
                                    argc > 4 ? argv[4] : NULL, &cfg);
    }
    if (argc >= 2 && strcmp(argv[1], "--scan-selftest") == 0) return lcs_selftest(argv[0]);
    if (argc >= 2 && strcmp(argv[1], "--check-g-ladder") == 0) {
        if (argc < 4) { fprintf(stderr, "usage: %s --check-g-ladder FDIR GDIR [max_k]\n", argv[0]); return 2; }
        if (!build_pairs()) return 1;
        return lc_check_g(argv[2], argv[3], argc > 4 ? atoi(argv[4]) : 31);
    }
    if (argc >= 2 && strcmp(argv[1], "--check-t-ladder") == 0) {
        if (argc < 4) { fprintf(stderr, "usage: %s --check-t-ladder FDIR TDIR [max_k]\n", argv[0]); return 2; }
        if (!build_pairs()) return 1;
        return lc_check_t(argv[2], argv[3], argc > 4 ? atoi(argv[4]) : 31);
    }
    if (argc < 2) { fprintf(stderr, "usage: %s <run.out> [max_layer]\n"
                                    "       %s --check-layers DIR [max_k] [run.out]\n"
                                    "       %s --check-layers-selftest\n"
                                    "       %s --scan-layers DIR [max_k] [run.out]   (parallel multi-observable\n"
                                    "                                  scan; env LC_SCAN_LANES/CHUNK_KB/ODIRECT/T6STUB)\n"
                                    "       %s --scan-selftest\n"
                                    "       %s --check-g-ladder FDIR GDIR [max_k]\n"
                                    "       %s --check-t-ladder FDIR TDIR [max_k]\n"
                                    "       %s --check-gt-selftest\n"
                                    "       %s --ie-count [opts]      (Route B IE recount; see source header;\n"
                                    "                                  --ie-no-budget = the C1^C2^C4 F4 variant)\n"
                                    "       %s --ie-probe NSAMP [--ie-threads N]\n"
                                    "       %s --dp-count [opts]      (Route D direct mask-DP recount — the\n"
                                    "                                  non-IE second instrument; see source header)\n"
                                    "       %s --knuth-anchors        (clean-room Knuth prober: exact-anchor +\n"
                                    "                                  machinery validation gate; see source header)\n"
                                    "       %s --knuth-probe N [--knuth-seed S] [--knuth-threads T]\n"
                                    "                     [--knuth-no-c67] [--knuth-free F]\n"
                                    "                                  (#194 clean-room Knuth random-probe estimator)\n",
                                    argv[0], argv[0], argv[0], argv[0], argv[0], argv[0], argv[0], argv[0],
                                    argv[0], argv[0], argv[0], argv[0], argv[0]); return 2; }
    int maxk = argc > 2 ? atoi(argv[2]) : 6;
    if (maxk < 1) maxk = 1;
    if (maxk > 31) maxk = 31;

    if (!build_pairs()) return 1;
    NFREE = NPAIR - 1;                      /* pair 0 is the C4-pinned (Qian,Kun) */

    printf("======================================================================\n");
    printf("verify.c — independent plain-DP check of solve.c's per-layer mass\n");
    printf("plain (non-quotient) recomputation; shares no code with solve.c\n");
    printf("======================================================================\n");
    printf("derived: %d canonical pairs, %d free (pair 0 C4-pinned)\n", NPAIR, NFREE);
    if (NPAIR != 32) { printf("*** FAIL: expected 32 canonical pairs\n"); return 1; }

    /* B0 for the FULL-31 instance. TR-11 §5: "For the full 31 the two coincide, because B0
     * there IS KW's boundary multiset (2,8,13,7,1)." So derive it directly from the published
     * KW sequence — independent, and free of the first-completion DFS's tie-breaking, which is
     * only well-defined relative to solve.c's exact scan convention. */
    for (int i = 0; i < 5; i++) b0[i] = 0;
    for (int i = 0; i < 31; i++) {
        int d = hamming(KW[2 * i + 1], KW[2 * i + 2]);   /* the 31 between-pair boundaries */
        int ci = cls_ix(d);
        if (ci < 0) { printf("*** FAIL: KW boundary distance %d outside C5 classes\n", d); return 1; }
        b0[ci]++;
    }
    printf("B0 from KW boundary multiset (d1,d2,d3,d4,d6) = (%d,%d,%d,%d,%d)\n",
           b0[0], b0[1], b0[2], b0[3], b0[4]);

    /* Secondary, non-authoritative: the first-completion DFS. Its witness depends on the exact
     * scan/tie-break convention, so a disagreement here is reported as an OBSERVATION about the
     * published recipe's determinism, NOT treated as an error in either instrument. */
    b0_dfs(0, 0, 0);                        /* START = Kun exit = 0 */
    if (b0_found) {
        int same_b0 = 1;
        for (int i = 0; i < 5; i++) if (b0_dfs_res[i] != b0[i]) same_b0 = 0;
        printf("first-completion DFS witness      = (%d,%d,%d,%d,%d)  %s\n",
               b0_dfs_res[0], b0_dfs_res[1], b0_dfs_res[2], b0_dfs_res[3], b0_dfs_res[4],
               same_b0 ? "(agrees)"
                       : "*** DIFFERS — DOCUMENTED DEFECT ***\n"
                         "    TR-11 §5 states that at full 31 the first-completion DFS and KW's boundary\n"
                         "    multiset COINCIDE. They do not. Two independent implementations of the §5\n"
                         "    recipe (this one in C, and verify.py's in Python) both yield the witness\n"
                         "    above, while solve.c's manifest and KW's own multiset are (2,8,13,7,1).\n"
                         "    The §5 recipe reproduces B0 correctly on the REDUCED rungs (verify.py checks\n"
                         "    n=9/13/16), so the defect is specific to the full-31 claim.\n"
                         "    NO PUBLISHED NUMBER IS AFFECTED: solve.c uses KW's multiset, which is what\n"
                         "    the counts rest on; the defect is in the documented derivation, not the\n"
                         "    computation. This program therefore uses KW's multiset (derived above).");
    }

    char masses[32][48];
    int nm = parse_masses(argv[1], masses);
    if (nm <= 0) { printf("*** FAIL: no per-layer mass lines parsed from %s\n", argv[1]); return 1; }
    printf("parsed %d per-layer mass lines from %s\n\n", nm, argv[1]);

    Tab cur; tab_init(&cur, 1u << 12);
    uint8_t z[5] = {0,0,0,0,0};
    tab_add(&cur, 0u, 0, z, (u128)1);       /* virtual predecessor exits at Kun */

    int deepest = 0, mismatches = 0;
    printf("  k | independent plain mass          | solve.c reported                | match\n");
    printf("----+---------------------------------+---------------------------------+------\n");
    for (int k = 1; k <= maxk; k++) {
        Tab nxt; tab_init(&nxt, cur.cap * 4 > (1u<<12) ? cur.cap * 4 : (1u<<12));
        for (size_t i = 0; i < cur.cap; i++) {
            Ent *e = &cur.e[i];
            if (e->last == 0xFF) continue;
            for (int q = 0; q < NFREE; q++) {
                if (e->mask & (1u << q)) continue;
                int a = PA[q + 1], b = PB[q + 1];
                for (int o = 0; o < 2; o++) {
                    int f = o == 0 ? a : b, s = o == 0 ? b : a;
                    int d = hamming(e->last, f);
                    if (d == 5 || d == 0) continue;          /* C2 */
                    int ci = cls_ix(d);
                    if (e->p[ci] >= b0[ci]) continue;        /* C5 budget cap */
                    uint8_t np[5]; memcpy(np, e->p, 5); np[ci]++;
                    tab_add(&nxt, e->mask | (1u << q), s, np, e->val);
                }
            }
        }
        tab_free(&cur); cur = nxt;

        u128 mass = 0;
        for (size_t i = 0; i < cur.cap; i++)
            if (cur.e[i].last != 0xFF) mass = add_ck(mass, cur.e[i].val);
        if (OVERFLOWED) { printf("*** STOP: 128-bit overflow at k=%d — cannot verify deeper\n", k); break; }

        char got[48]; print_u128(mass, got);
        const char *want = masses[k][0] ? masses[k] : "(absent)";
        int ok = masses[k][0] && strcmp(got, want) == 0;
        if (masses[k][0] && !ok) mismatches++;
        printf(" %2d | %-31s | %-31s | %s\n", k, got, want,
               !masses[k][0] ? " n/a" : (ok ? "  ok" : " *FAIL*"));
        deepest = k;
    }
    tab_free(&cur);

    printf("\n======================================================================\n");
    if (mismatches == 0)
        printf("RESULT: independent plain DP agrees with solve.c's reported per-layer\n"
               "        mass for every layer checked (k=1..%d) on the full-31 instance.\n"
               "        This exercises the orbit expansion and prefix-stabilizer weighting.\n"
               "        It is NOT the full-scale recomputation TR-11 §10(vi) asks for:\n"
               "        layers beyond k=%d were not reached.\n", deepest, deepest);
    else
        printf("RESULT: *** %d MISMATCH(ES) *** — a bug in one instrument or the other.\n"
               "        Do NOT reconcile this away; report it.\n", mismatches);
    printf("======================================================================\n");
    return mismatches ? 1 : 0;
}
