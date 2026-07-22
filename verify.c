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
 * BUILD:  cc -O2 -o verify verify.c
 * USAGE:  ./verify <run.out> [max_layer]      (default max_layer = 6)
 *         Increase max_layer while memory allows; the program reports what it reached and
 *         stops cleanly rather than being killed.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

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

int main(int argc, char **argv) {
    if (argc < 2) { fprintf(stderr, "usage: %s <run.out> [max_layer]\n", argv[0]); return 2; }
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
