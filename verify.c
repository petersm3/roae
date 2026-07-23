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
 * BUILD:  cc -O2 -o verify verify.c -lz   (zlib: the v2 layer codec is per-block zlib)
 * USAGE:  ./verify <run.out> [max_layer]      (default max_layer = 6)
 *         Increase max_layer while memory allows; the program reports what it reached and
 *         stops cleanly rather than being killed.
 *         ./verify --check-layers DIR [max_k] [run.out]   spec-driven layer-file reader
 *         (all layers, entry-streaming; with run.out also compares the independently
 *          re-derived orbit-weighted mass per layer); --check-layers-selftest.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <zlib.h>

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
                          uint8_t rp[24][32], int geff, u192 *grand_out, u192 *mass_out) {
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

    if (!fail) { char g[64], md[64]; u192_print(grand, g); u192_print(mass, md);
        printf("  k=%2d  nm=%-9llu ne=%-13llu %s  Σval=%s  mass=%s\n", k,
               (unsigned long long)nm, (unsigned long long)ne, is_v2?"v2":"v1", g, md); }
cleanup:
    free(orbits); free(masks); free(off); fclose(f);
    #undef LCF
    return fail;
}

/* parse f1c5_manifest.txt (spec §Manifest). returns 0 ok. */
static int lc_manifest(const char *dir, uint32_t *n, uint32_t *se, uint64_t *plhash_hex,
                       uint32_t pl[64], int *npl, int b0[5], int *last_k) {
    char path[1024]; snprintf(path, sizeof path, "%s/f1c5_manifest.txt", dir);
    FILE *f = fopen(path, "r"); if (!f) return 1;
    char line[8192]; int have_tag=0; *n=0; *se=0; *last_k=-1; *plhash_hex=0; *npl=0;
    for (int c=0;c<5;c++) b0[c]=0;
    while (fgets(line, sizeof line, f)) {
        if (!strncmp(line,"f1c5_manifest_v1",16)) have_tag=1;
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

static int lc_check_layers(const char *dir, int maxk, const char *run_out) {
    uint32_t mn, mse, pl[64]; uint64_t m_plhash; int last_k, npl; int b0v[5];
    printf("======================================================================\n");
    printf("verify.c --check-layers : spec-driven independent layer-file reader\n");
    printf("written against documentation/F1C5_LAYER_FORMAT.md; shares no code with solve.c\n");
    printf("======================================================================\n");
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

    int hi = last_k; if (maxk < hi) hi = maxk;
    int fails = !plhash_ok + !kw_ok + !geff_ok, checked = 0;
    u192 finalgrand = {{0,0,0}}; int saw_final = 0;
    u192 lmass[32]; int lgot[32];
    for (int k = 0; k < 32; k++) lgot[k] = 0;
    for (int k = 0; k <= hi && k < 32; k++) {
        char p[1024]; snprintf(p,sizeof p,"%s/f1c5_layer_%02d.bin",dir,k);
        FILE *t = fopen(p,"rb"); if (!t) continue; fclose(t);   /* rolling window may have pruned it */
        int is_final = (k == (int)mn);
        u192 g, ms; int r = lc_check_layer(dir, k, mn, mse, m_plhash, b0v, is_final,
                                           rp, geff, &g, &ms);
        fails += r; checked++;
        if (!r) { lmass[k] = ms; lgot[k] = 1; }
        if (is_final && !r) { finalgrand = g; saw_final = 1; }
    }

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
    return fails ? 1 : 0;
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

int main(int argc, char **argv) {
    if (argc >= 2 && strcmp(argv[1], "--check-layers-selftest") == 0) return lc_selftest();
    if (argc >= 2 && strcmp(argv[1], "--check-layers") == 0) {
        if (argc < 3) { fprintf(stderr, "usage: %s --check-layers DIR [max_k] [run.out]\n", argv[0]); return 2; }
        return lc_check_layers(argv[2], argc > 3 ? atoi(argv[3]) : 31,
                               argc > 4 ? argv[4] : NULL);
    }
    if (argc < 2) { fprintf(stderr, "usage: %s <run.out> [max_layer]\n"
                                    "       %s --check-layers DIR [max_k] [run.out]\n"
                                    "       %s --check-layers-selftest\n",
                                    argv[0], argv[0], argv[0]); return 2; }
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
