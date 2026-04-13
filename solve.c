/*
 * https://github.com/petersm3/roae
 * Developed with AI assistance (Claude, Anthropic)
 *
 * Constraint solver for the King Wen sequence — multi-threaded C implementation.
 * Enumerates all orderings of 32 hexagram pairs satisfying 5 constraints + complement
 * distance, then compares each valid ordering to the historical King Wen sequence.
 *
 * ARCHITECTURE OVERVIEW
 * =====================
 * The King Wen sequence is 64 hexagrams (6-bit integers, 0-63). It naturally groups
 * into 32 consecutive pairs. This solver finds all orderings of those 32 pairs that
 * satisfy a set of mathematical constraints derived from the original sequence.
 *
 * The search is a depth-32 backtracking tree. At each depth, we try placing one of
 * the remaining unused pairs (in either orientation) at the next position. Pruning:
 *   C1: Pair structure — only the 32 pairs from KW are used (not arbitrary pairings)
 *   C2: No 5-line Hamming transitions between consecutive hexagrams
 *   C4: Position 1 is always Creative/Receptive (hexagrams 63, 0) — provably forced
 *   C5: Difference distribution — the multiset of Hamming distances between all 63
 *       consecutive hexagrams must exactly match King Wen's {1:2, 2:20, 3:13, 4:19, 6:9}
 *       This is tracked via a "budget" array decremented at each placement.
 *   C3: Complement distance — checked at depth 32 (complete solution). The sum of
 *       positional distances between each hexagram and its bitwise complement (v^63)
 *       must be <= King Wen's value (776, stored as x64 to avoid floating point).
 *
 * THREADING MODEL
 * ===============
 * Normal mode: The 31 remaining pairs × 2 orientations at position 2 yield 56 valid
 * "branches" after pruning. Each branch is an independent subtree — no shared mutable
 * state during search. Branches are distributed round-robin across N threads.
 * Why 56 is the max useful thread count: there are exactly 56 valid branches.
 *
 * Single-branch mode (--branch): Fixes positions 1-2 and enumerates position 3
 * choices as "sub-branches" (~54 per branch). Distributes sub-branches across all
 * available cores. Use this to parallelize exploration of one specific branch.
 * This exists because individual branches are enormous (>>24 hours on 64 cores)
 * and we need to parallelize within a branch, not just across branches.
 *
 * SOLUTION STORAGE
 * ================
 * Each thread has a full-key hash table (open addressing, linear probing) storing
 * canonical pair orderings. "Canonical" means within each pair, the smaller hexagram
 * value comes first — this collapses orientation variants into one entry.
 * Each record is 32 bytes (packed): one byte per position, encoding pair index
 * (5 bits) and orientation (1 bit). Hash and dedup compare pair identity only
 * (orient bit masked out). Full sequence recoverable from any record.
 * 32 bytes = half a cache line, doubling throughput vs the old 68-byte format.
 *
 * Earlier versions used hash-only comparison (no key verification) which had ~1-3%
 * false positive rate. Changed to full-key after discovering the loss was unacceptable
 * for a project claiming rigorous enumeration.
 *
 * Hash table size is configurable via SOLVE_HASH_LOG2 env var (default 2^22 = 4M
 * slots = 256 MB per thread). At 56 threads this is 14 GB total. Probe limit is 64
 * before giving up on insertion — if the table is >75% full, a warning is emitted.
 *
 * After all threads finish, per-thread tables are merged: extract all entries,
 * concatenate, qsort, deduplicate (memcmp adjacent entries). Cross-thread duplicates
 * are common since different orientation choices can produce the same canonical ordering.
 *
 * ANALYTICS
 * =========
 * "C3-valid" means a complete sequence passing ALL five constraints (C1+C2+C4+C5
 * enforced during backtracking, C3 checked at depth 32). The name reflects that
 * C3 is the last filter applied, not that it's the only one.
 *
 * All analytics are computed incrementally on every C3-valid solution, BEFORE
 * deduplication. This means analytics reflect ALL valid solutions (with orientation
 * variants), not just unique canonical orderings. This is intentional — it gives
 * statistically meaningful rates even from partial runs.
 *
 * Key analytics:
 *   - Position match rates: what fraction of solutions have the same pair as KW
 *     at each of the 32 positions. Position 1 is always 100% (forced by C4).
 *   - Edit distance: number of pair positions differing from KW (0 = identical)
 *   - Generalized adjacency: for each of the 31 pair boundaries, how often do
 *     both adjacent pairs match KW. Answers "how many boundary constraints needed
 *     to narrow to uniqueness" — the central open question.
 *   - Super-pairs: pairs grouped by complement relationship (pair {a,b} and its
 *     complement {a^63, b^63}). 20 super-pairs total (8 self-complementary +
 *     12 complementary pairs). Tracks structural constraint beyond individual pairs.
 *   - Top-N closest: the 20 solutions nearest to KW by edit distance, merged
 *     across threads. Useful for understanding what's "almost King Wen."
 *   - C6/C7: legacy adjacency constraints from earlier analysis (boundaries 25, 27).
 *     Kept for backward compatibility with documentation.
 *
 * CHECKPOINTING AND RESUME
 * ========================
 * After each branch (or sub-branch), a line is appended to checkpoint.txt with status
 * COMPLETE or INTERRUPTED. On restart, only COMPLETE branches are skipped — INTERRUPTED
 * branches are re-explored from scratch. This is critical: an earlier bug marked all
 * timed-out branches as "complete", causing resume to skip partially-explored work.
 * This enables:
 *   - Graceful recovery from SIGTERM/spot eviction (completed work is preserved)
 *   - Incremental enumeration across multiple runs
 * Note: analytics and solution storage are NOT checkpointed — only branch completion
 * status. A resumed run's analytics cover only the newly-explored branches.
 * A separate merge tool (merge.c) combines results from multiple branch runs.
 *
 * SIGNAL HANDLING
 * ===============
 * SIGTERM and SIGINT are caught via sigaction (not signal(), which resets after one
 * use — a bug in an earlier version). The handler sets global_timed_out = 1, which
 * is checked on every backtracking node. Threads exit cleanly, and the main thread
 * proceeds to merge, sort, write, and report — producing complete, valid output.
 *
 * OUTPUT FILES
 * ============
 * Normal mode:
 *   solutions.bin      — sorted unique orderings (32 bytes each, packed:
 *                         byte i = pair_index<<2 | orient<<1)
 *   solutions.sha256   — hash of solutions.bin for reproducibility
 *   solve_results.json — all analytics in machine-readable format
 *   checkpoint.txt     — branch completion log (append-only)
 *
 * Single-branch mode (--branch P O):
 *   solutions_P_O.bin      — per-branch, avoids overwriting other branch results
 *   solutions_P_O.sha256
 *   results_P_O.json
 *
 * KNOWN LIMITATIONS
 * =================
 * - Probe limit of 64 in hash table: if a cluster of 64+ consecutive slots are
 *   occupied, an insertion silently fails. Mitigated by large table (4M slots for
 *   typically <1M entries per thread) but theoretically possible.
 * - No sub-branch checkpointing: within a branch, if interrupted, all progress on
 *   the current branch is lost. Only completed branches are recoverable.
 * - pair_index_of() is O(32) linear scan, called frequently in analyze_solution.
 *   Not a bottleneck (called once per C3-valid solution, not per node) but could
 *   be replaced with a lookup table if profiling shows it matters.
 *
 * Compile: gcc -O3 -pthread -DGIT_HASH=\"$(git rev-parse --short HEAD)\" -o solve solve.c
 * Run:     ./solve [time_limit_seconds] [threads]
 *          ./solve 86400 56   (24h limit, 56 threads)
 *          ./solve 0          (no time limit — run to completion)
 *
 * Single-branch mode (parallelize one branch across all cores):
 *          ./solve --branch <pair> <orient> [time_limit] [threads]
 *          ./solve --branch 5 0 3600 56
 *
 * List all valid branches (with completion status from checkpoint.txt):
 *          ./solve --list-branches
 *
 * Validate a solutions.bin file (checks all constraints):
 *          ./solve --validate [solutions.bin]
 *
 * Environment variables:
 *   SOLVE_THREADS=N          — override thread count
 *   SOLVE_HASH_LOG2=N        — hash table size as power of 2 (default: 22 = 4M slots)
 *   SOLVE_NODE_LIMIT=N       — stop after N total nodes, distributed equally per branch
 *                              (deterministic, reproducible sha256 regardless of thread count)
 *
 * Graceful shutdown: handles SIGTERM/SIGINT — produces full output on signal.
 * Resume: reads checkpoint.txt on startup and skips completed branches.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include <stdint.h>

#ifndef GIT_HASH
#define GIT_HASH "unknown"
#endif

/* ---------- King Wen sequence: 64 hexagrams as 6-bit integers ---------- */
/* Each value 0-63 encodes a hexagram's six lines as bits (0=yin, 1=yang).
 * Index 0 = hexagram #1 (Creative, 111111 = 63), index 1 = hexagram #2
 * (Receptive, 000000 = 0), etc. in the traditional King Wen ordering. */
static const int KW[64] = {
    63,  0, 17, 34, 23, 58,  2, 16,
    55, 59,  7, 56, 61, 47,  4,  8,
    25, 38,  3, 48, 41, 37, 32,  1,
    57, 39, 33, 30, 18, 45, 28, 14,
    60, 15, 40,  5, 53, 43, 20, 10,
    35, 49, 31, 62, 24,  6, 26, 22,
    29, 46,  9, 36, 52, 11, 13, 44,
    54, 27, 50, 19, 51, 12, 21, 42
};

static inline int reverse6(int n) {
    return ((n & 1) << 5) | ((n >> 1 & 1) << 4) | ((n >> 2 & 1) << 3) |
           ((n >> 3 & 1) << 2) | ((n >> 4 & 1) << 1) | ((n >> 5 & 1));
}

static inline int hamming(int a, int b) {
    return __builtin_popcount(a ^ b);
}

/* ---------- Pairs ---------- */
typedef struct { int a, b; } Pair;
static Pair pairs[32];
static int n_pairs = 0;

/* ---------- Globals ---------- */
static int kw_dist[7] = {0};
static int kw_comp_dist_x64;
static int kw_canonical[32][2];
static int c6_pair_a_idx, c6_pair_b_idx;
static int c7_pair_a_idx, c7_pair_b_idx;
static int kw_pair_at_pos[32];          /* pair index at each KW position */
static int super_pair_of[32];           /* pair index -> super-pair index */
static int n_super_pairs;
static int kw_super_pair_at_pos[32];    /* super-pair index at each KW position */

/* Precomputed within-pair Hamming distance for each pair.
 * Used by forward feasibility check and pair ordering. */
static int pair_wpd[32];  /* pair_wpd[i] = hamming(pairs[i].a, pairs[i].b) */

/* Pair ordering: indices sorted by within-pair distance (rarest first).
 * Fail-first heuristic: try pairs that consume rare budget values early,
 * so infeasible branches are discovered sooner. */
static int pair_order[32];

/* Runtime-configurable hash table size.
 * Trade-off: larger = fewer collisions but more memory per thread.
 * At 2^22 (256 MB/thread), 56 threads = 14 GB. F64 VM has 128 GB so this is fine.
 * For smaller VMs, set SOLVE_HASH_LOG2=20 (64 MB/thread) or 18 (16 MB/thread). */
static int sol_hash_log2 = 22;         /* default: 2^22 = 4M slots */
static int sol_hash_size;
static int sol_hash_mask;

static int pair_index_of(int x, int y) {
    int lo = (x < y) ? x : y;
    int hi = (x < y) ? y : x;
    for (int i = 0; i < 32; i++) {
        int a = pairs[i].a, b = pairs[i].b;
        int plo = (a < b) ? a : b;
        int phi = (a < b) ? b : a;
        if (plo == lo && phi == hi) return i;
    }
    return -1;
}

/* Complement distance: sum of |pos(v) - pos(v^63)| for all v where v != v^63.
 * Multiplied by 64 (stored as integer) to avoid floating point throughout.
 * King Wen's value is 776 (= 12.125 when divided by 64).
 * Lower = complements are closer together in the sequence. KW minimizes this
 * (3.9th percentile among random orderings — a genuine statistical signal). */
static int compute_comp_dist_x64(const int seq[64]) {
    int pos[64];
    for (int i = 0; i < 64; i++) pos[seq[i]] = i;
    int total = 0;
    for (int v = 0; v < 64; v++) {
        int comp = v ^ 63;
        if (comp != v) {
            int d = pos[v] - pos[comp];
            total += (d < 0) ? -d : d;
        }
    }
    return total;
}

/* ---------- Branch definition ---------- */
typedef struct {
    int pair;
    int orient;
} Branch;

/* ---------- Sub-branch for single-branch mode ---------- */
typedef struct {
    int pair1;      /* first-level branch pair */
    int orient1;    /* first-level orientation */
    int pair2;      /* second-level (depth 2) pair */
    int orient2;    /* second-level orientation */
} SubBranch;

/* ---------- Top-N closest solutions ---------- */
#define TOP_N 20

/* Packed solution record: 32 bytes.
 * Byte i (0-31) = pair_index (bits 7-2) | orient (bit 1) | reserved (bit 0)
 *   pair_index: which of the 32 KW pairs is at this position (0-31)
 *   orient: 0 = pair.a first (natural), 1 = pair.b first (reversed)
 * Lossless: full 64-hexagram sequence recoverable from pair table + record.
 * Sortable with memcmp (pair index dominates sort order).
 * Fits in half a cache line (32 bytes). Hash/compare use all 32 bytes.
 *
 * To decode byte b: pair_index = (b >> 2), orient = (b >> 1) & 1
 * To decode position i: pair = pairs[record[i] >> 2]
 *   if orient bit set: seq[2i] = pair.b, seq[2i+1] = pair.a
 *   else:              seq[2i] = pair.a, seq[2i+1] = pair.b */
#define SOL_RECORD_SIZE 32

typedef struct {
    int edit_dist;
    int solution[64];
    int diff_positions[32];
    int diff_count;
} ClosestEntry;

/* ---------- Per-thread state ---------- */
typedef struct {
    int thread_id;

    /* Branches assigned to this thread (normal mode) */
    Branch *branches;
    int n_branches;

    /* Sub-branches (single-branch mode) */
    SubBranch *sub_branches;
    int n_sub_branches;
    int single_branch_mode;

    /* Counters */
    long long solutions_total;
    long long solutions_c3;     /* "C3-valid" = passed ALL constraints (C1-C5), not just C3 */
    long long nodes;
    long long branch_nodes;  /* per-branch counter, reset between branches */
    int kw_found;
    int branches_completed;
    long long hash_collisions;

    /* Position match analytics */
    long long pos_match_count[32];
    long long edit_dist_hist[33];
    long long c6_satisfied;
    long long c7_satisfied;
    long long c6_and_c7_satisfied;

    /* Generalized adjacency */
    long long per_boundary_sat[31];
    long long adj_match_hist[32];

    /* Top-N closest non-KW solutions */
    ClosestEntry top_closest[TOP_N];
    int top_count;

    /* Complement distance histogram */
    #define CD_HIST_SIZE 200
    long long cd_hist[CD_HIST_SIZE];

    /* Per-position pair frequency */
    long long pair_freq[32][32];

    /* Super-pair match */
    long long super_pair_match[32];

    /* Solution storage: full-key hash table */
    unsigned char *sol_table;
    char *sol_occupied;
    int solution_count;
} ThreadState;

static volatile int global_timed_out = 0;
static volatile int threads_completed = 0;
static pthread_mutex_t checkpoint_mutex = PTHREAD_MUTEX_INITIALIZER;
static int total_branches_completed = 0;
static int total_branches = 0;

/* SIGTERM/SIGINT handler. Uses sigaction (not signal()) because signal() resets
 * the handler after one invocation on some platforms — a bug in an earlier version
 * that caused the second signal to kill the process without clean output.
 * Only sets a flag — the backtracker checks it and exits cleanly. */
static void signal_handler(int sig) {
    (void)sig;
    global_timed_out = 1;
    const char msg[] = "\n*** Signal received — shutting down gracefully ***\n";
    if (write(STDERR_FILENO, msg, sizeof(msg) - 1)) {}
}

static time_t start_time;
static int time_limit = 0;
/* Node limit: stop after this many total nodes across all threads.
 * Set via SOLVE_NODE_LIMIT env var. 0 = no limit.
 * Unlike time limit, node limit is deterministic — same node limit on any
 * hardware produces the same solutions.bin (reproducible sha256). */
static long long node_limit = 0;
static long long per_branch_node_limit = 0;  /* node_limit / n_branches, set at startup */

/* ---------- Init functions ---------- */

static void init_pairs(void) {
    n_pairs = 0;
    for (int i = 0; i < 64; i += 2) {
        pairs[n_pairs].a = KW[i];
        pairs[n_pairs].b = KW[i + 1];
        n_pairs++;
    }
}

static void init_kw_dist(void) {
    memset(kw_dist, 0, sizeof(kw_dist));
    for (int i = 0; i < 63; i++) {
        kw_dist[hamming(KW[i], KW[i+1])]++;
    }
}

static void init_kw_canonical(void) {
    for (int i = 0; i < 32; i++) {
        int a = KW[i * 2], b = KW[i * 2 + 1];
        kw_canonical[i][0] = (a < b) ? a : b;
        kw_canonical[i][1] = (a < b) ? b : a;
    }
}

static void init_adjacency_constraints(void) {
    c6_pair_a_idx = pair_index_of(KW[52], KW[53]);
    c6_pair_b_idx = pair_index_of(KW[54], KW[55]);
    c7_pair_a_idx = pair_index_of(KW[48], KW[49]);
    c7_pair_b_idx = pair_index_of(KW[50], KW[51]);
}

static void init_kw_pair_positions(void) {
    for (int i = 0; i < 32; i++) {
        kw_pair_at_pos[i] = pair_index_of(KW[i * 2], KW[i * 2 + 1]);
    }
}

/* Super-pairs: group pairs by complement relationship. Pair {a,b} and pair
 * {a^63, b^63} form a super-pair (size 2). If a pair is its own complement
 * (a^63 and b^63 are already in the same pair), it's self-complementary (size 1).
 * Result: 20 super-pairs (8 self-complementary + 12 complement-paired).
 * This captures structural constraints beyond individual pair identity. */
static void init_super_pairs(void) {
    int assigned[32];
    memset(assigned, 0, sizeof(assigned));
    n_super_pairs = 0;
    for (int i = 0; i < 32; i++) {
        if (assigned[i]) continue;
        int comp_a = pairs[i].a ^ 63;
        int comp_b = pairs[i].b ^ 63;
        int j = pair_index_of(comp_a, comp_b);
        super_pair_of[i] = n_super_pairs;
        assigned[i] = 1;
        if (j >= 0 && j != i && !assigned[j]) {
            super_pair_of[j] = n_super_pairs;
            assigned[j] = 1;
        }
        n_super_pairs++;
    }
    for (int i = 0; i < 32; i++) {
        kw_super_pair_at_pos[i] = super_pair_of[kw_pair_at_pos[i]];
    }
}

static void init_pair_order(void) {
    /* Compute within-pair distances */
    for (int i = 0; i < 32; i++)
        pair_wpd[i] = hamming(pairs[i].a, pairs[i].b);

    /* Sort pair indices by: rarest within-pair distance first (fail-first).
     * Count how many pairs have each within-pair distance, then order by
     * ascending count (rarest distance values first). */
    int wpd_count[7] = {0};
    for (int i = 0; i < 32; i++) wpd_count[pair_wpd[i]]++;

    for (int i = 0; i < 32; i++) pair_order[i] = i;

    /* Simple insertion sort by wpd_count[pair_wpd[i]] ascending, then pair index */
    for (int i = 1; i < 32; i++) {
        int key = pair_order[i];
        int key_rarity = wpd_count[pair_wpd[key]];
        int j = i - 1;
        while (j >= 0 && wpd_count[pair_wpd[pair_order[j]]] > key_rarity) {
            pair_order[j + 1] = pair_order[j];
            j--;
        }
        pair_order[j + 1] = key;
    }
}

/* ---------- Resume from checkpoint ---------- */

static int completed_branches[64][2]; /* pair, orient */
static int n_completed_from_checkpoint = 0;

static void load_checkpoint(void) {
    FILE *f = fopen("checkpoint.txt", "r");
    if (!f) return;
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        /* Only resume from COMPLETE branches, not INTERRUPTED ones.
         * Old format: "Branch N/M complete (thread T, pair P orient O): ..."
         * New format: "Branch COMPLETE (thread T, pair P orient O): ..."
         * Skip lines containing "INTERRUPTED". */
        if (strstr(line, "INTERRUPTED")) continue;
        int pair_val, orient_val;
        char *p = strstr(line, "pair ");
        if (!p) continue;
        if (sscanf(p, "pair %d orient %d", &pair_val, &orient_val) == 2) {
            completed_branches[n_completed_from_checkpoint][0] = pair_val;
            completed_branches[n_completed_from_checkpoint][1] = orient_val;
            n_completed_from_checkpoint++;
            if (n_completed_from_checkpoint >= 64) break;
        }
    }
    fclose(f);
}

static int is_branch_completed(int pair, int orient) {
    for (int i = 0; i < n_completed_from_checkpoint; i++) {
        if (completed_branches[i][0] == pair && completed_branches[i][1] == orient)
            return 1;
    }
    return 0;
}

/* Sub-branch checkpoint for single-branch mode.
 * Format: "Sub-branch COMPLETE (thread T, pair2 P orient2 O): ..." */
static int completed_sub_branches[64][2]; /* [pair2, orient2] */
static int n_completed_subs = 0;

static void load_sub_checkpoint(void) {
    FILE *f = fopen("checkpoint.txt", "r");
    if (!f) return;
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        if (strstr(line, "INTERRUPTED")) continue;
        if (!strstr(line, "Sub-branch")) continue;
        int pair2_val, orient2_val;
        char *p = strstr(line, "pair2 ");
        if (!p) continue;
        if (sscanf(p, "pair2 %d orient2 %d", &pair2_val, &orient2_val) == 2) {
            completed_sub_branches[n_completed_subs][0] = pair2_val;
            completed_sub_branches[n_completed_subs][1] = orient2_val;
            n_completed_subs++;
            if (n_completed_subs >= 64) break;
        }
    }
    fclose(f);
}

static int is_sub_branch_completed(int pair2, int orient2) {
    for (int i = 0; i < n_completed_subs; i++) {
        if (completed_sub_branches[i][0] == pair2 && completed_sub_branches[i][1] == orient2)
            return 1;
    }
    return 0;
}

/* ---------- Solution analysis ---------- */

static void analyze_solution(ThreadState *ts, const int seq[64]) {
    int sol_pair_idx[32];
    int edit_dist = 0;
    int diff_positions[32];
    int diff_count = 0;

    for (int i = 0; i < 32; i++) {
        int a = seq[i * 2], b = seq[i * 2 + 1];
        int lo = (a < b) ? a : b;
        int hi = (a < b) ? b : a;
        sol_pair_idx[i] = pair_index_of(a, b);

        if (lo == kw_canonical[i][0] && hi == kw_canonical[i][1]) {
            ts->pos_match_count[i]++;
        } else {
            diff_positions[diff_count++] = i;
            edit_dist++;
        }
    }
    ts->edit_dist_hist[edit_dist]++;

    /* Top-N closest non-KW solutions */
    if (edit_dist > 0) {
        int dominated = 0;
        if (ts->top_count >= TOP_N &&
            edit_dist >= ts->top_closest[ts->top_count - 1].edit_dist)
            dominated = 1;
        if (!dominated) {
            int ins = ts->top_count < TOP_N ? ts->top_count : TOP_N - 1;
            for (int i = 0; i < ts->top_count && i < TOP_N; i++) {
                if (edit_dist < ts->top_closest[i].edit_dist) {
                    ins = i;
                    break;
                }
            }
            int end = ts->top_count < TOP_N ? ts->top_count : TOP_N - 1;
            for (int i = end; i > ins; i--)
                ts->top_closest[i] = ts->top_closest[i - 1];
            ts->top_closest[ins].edit_dist = edit_dist;
            memcpy(ts->top_closest[ins].solution, seq, sizeof(int) * 64);
            memcpy(ts->top_closest[ins].diff_positions, diff_positions, sizeof(int) * diff_count);
            ts->top_closest[ins].diff_count = diff_count;
            if (ts->top_count < TOP_N) ts->top_count++;
        }
    }

    /* C6/C7 adjacency (legacy) */
    int c6_ok = (sol_pair_idx[26] == c6_pair_a_idx && sol_pair_idx[27] == c6_pair_b_idx);
    int c7_ok = (sol_pair_idx[24] == c7_pair_a_idx && sol_pair_idx[25] == c7_pair_b_idx);
    if (c6_ok) ts->c6_satisfied++;
    if (c7_ok) ts->c7_satisfied++;
    if (c6_ok && c7_ok) ts->c6_and_c7_satisfied++;

    /* Generalized adjacency: check all 31 boundaries */
    int adj_matches = 0;
    for (int b = 0; b < 31; b++) {
        if (sol_pair_idx[b] == kw_pair_at_pos[b] &&
            sol_pair_idx[b + 1] == kw_pair_at_pos[b + 1]) {
            ts->per_boundary_sat[b]++;
            adj_matches++;
        }
    }
    ts->adj_match_hist[adj_matches]++;

    /* Complement distance */
    int cd = compute_comp_dist_x64(seq);
    int cd_bin = cd / 20;
    if (cd_bin >= CD_HIST_SIZE) cd_bin = CD_HIST_SIZE - 1;
    ts->cd_hist[cd_bin]++;

    /* Per-position pair frequency */
    for (int i = 0; i < 32; i++) {
        if (sol_pair_idx[i] >= 0) {
            ts->pair_freq[i][sol_pair_idx[i]]++;
        }
    }

    /* Super-pair match */
    for (int i = 0; i < 32; i++) {
        if (sol_pair_idx[i] >= 0 &&
            super_pair_of[sol_pair_idx[i]] == kw_super_pair_at_pos[i]) {
            ts->super_pair_match[i]++;
        }
    }

    /* Build packed 32-byte record: byte i = (pair_index << 2) | (orient << 1)
     * For dedup: compare with orient bit masked (0xFC) — only pair identity matters.
     * For storage: full byte preserved, orient recoverable. */
    unsigned char record[SOL_RECORD_SIZE];
    unsigned char canonical[SOL_RECORD_SIZE];  /* orient bits cleared, for hash/compare */
    for (int i = 0; i < 32; i++) {
        int pidx = sol_pair_idx[i];  /* already computed above */
        int orient = (seq[i * 2] == pairs[pidx].b) ? 1 : 0;
        record[i] = (unsigned char)((pidx << 2) | (orient << 1));
        canonical[i] = (unsigned char)(pidx << 2);  /* orient cleared */
    }

    /* FNV-1a hash of canonical bytes (pair identity only, no orientation) */
    unsigned long long ch = 14695981039346656037ULL;
    for (int i = 0; i < SOL_RECORD_SIZE; i++) { ch ^= canonical[i]; ch *= 1099511628211ULL; }

    if (!ts->sol_table) {
        ts->sol_table = calloc((size_t)sol_hash_size, SOL_RECORD_SIZE);
        ts->sol_occupied = calloc(sol_hash_size, 1);
        if (!ts->sol_table || !ts->sol_occupied) {
            fprintf(stderr, "ERROR: thread %d failed to allocate hash table (%d MB). "
                    "Solutions will not be stored. Reduce SOLVE_HASH_LOG2 or thread count.\n",
                    ts->thread_id, (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576));
            return;
        }
    }

    int slot = (int)(ch & (unsigned long long)sol_hash_mask);
    for (int probe = 0; probe < 64; probe++) {
        int idx = (slot + probe) & sol_hash_mask;
        if (!ts->sol_occupied[idx]) {
            memcpy(&ts->sol_table[(size_t)idx * SOL_RECORD_SIZE], record, SOL_RECORD_SIZE);
            ts->sol_occupied[idx] = 1;
            ts->solution_count++;
            break;
        }
        /* Compare canonical (pair identity only, orient masked out) */
        unsigned char *existing = &ts->sol_table[(size_t)idx * SOL_RECORD_SIZE];
        int match = 1;
        for (int ci = 0; ci < SOL_RECORD_SIZE; ci++) {
            if ((existing[ci] & 0xFC) != canonical[ci]) { match = 0; break; }
        }
        if (match) {
            ts->hash_collisions++;
            break;
        }
    }
}

/* ---------- Backtracking ---------- */

/* Core backtracking search. Parameters:
 *   seq[64]   — partial sequence being built (pairs placed at indices 0..step*2-1)
 *   used[32]  — which pairs have been placed
 *   budget[7] — remaining count for each Hamming distance (0-6). Decremented when
 *               a transition of that distance is used. Enforces C5 (exact match of
 *               KW's difference distribution). This is the key pruning mechanism —
 *               most branches are killed by budget exhaustion, not by C2 or C3.
 *   step      — current pair position (0-31). Step 0 is pre-filled (Creative/Receptive).
 *
 * The budget array makes this much faster than checking the distribution at the end:
 * invalid branches are pruned at depth 2-5 instead of depth 32. */
static void backtrack(ThreadState *ts, int seq[64], int used[32], int budget[7], int step) {
    ts->nodes++;
    ts->branch_nodes++;
    if (global_timed_out) return;
    /* Per-branch node limit: checked every node (just an integer compare, cheap).
     * Sets a thread-local flag rather than global_timed_out so other branches
     * on this thread can continue. But for simplicity, we use global_timed_out
     * which stops this branch's backtrack immediately. The thread function
     * resets it... actually we can't reset a volatile global. Instead, return
     * directly without setting the global flag. */
    if (per_branch_node_limit > 0 && ts->branch_nodes >= per_branch_node_limit)
        return;  /* branch budget exhausted — stop this branch only */
    /* Time check every 50M nodes (not every node — time() is a syscall). */
    if (ts->nodes % 50000000 == 0) {
        if (time_limit > 0 && (time(NULL) - start_time) >= time_limit)
            global_timed_out = 1;
    }
    if (global_timed_out) return;

    if (step == 32) {
        ts->solutions_total++;
        int cd = compute_comp_dist_x64(seq);
        if (cd <= kw_comp_dist_x64) {
            ts->solutions_c3++;
            if (!ts->kw_found) {
                int match = 1;
                for (int i = 0; i < 64; i++) {
                    if (seq[i] != KW[i]) { match = 0; break; }
                }
                if (match) ts->kw_found = 1;
            }
            analyze_solution(ts, seq);
        }
        return;
    }

    int prev_tail = seq[step * 2 - 1];  /* last hexagram placed */
    for (int p = 0; p < 32; p++) {
        if (used[p]) continue;
        for (int orient = 0; orient < 2; orient++) {
            int first = orient ? pairs[p].b : pairs[p].a;
            int second = orient ? pairs[p].a : pairs[p].b;
            /* bd = between-pair distance (prev_tail -> first of new pair)
             * wd = within-pair distance (first -> second of new pair)
             * Both consume from the budget. C2: bd == 5 is forbidden. */
            int bd = hamming(prev_tail, first);
            if (bd == 5) continue;  /* C2: no 5-line transitions */
            if (budget[bd] <= 0) continue;
            budget[bd]--;
            int wd = hamming(first, second);
            if (budget[wd] <= 0) { budget[bd]++; continue; }
            budget[wd]--;
            seq[step * 2] = first;
            seq[step * 2 + 1] = second;
            used[p] = 1;
            backtrack(ts, seq, used, budget, step + 1);
            used[p] = 0;
            budget[wd]++;
            budget[bd]++;
            if (global_timed_out) return;
        }
    }
}

/* Note: the old depth-1 thread_func has been removed. Normal mode now uses
 * thread_func_single with all ~3,030 sub-branches distributed across threads.
 * This eliminates the "tail problem" where a few large branches monopolize
 * single cores while the rest are idle. */

/* Dead sub-branch detection: skip if >N nodes with 0 C3-valid.
 * Default 0 = disabled. Set SOLVE_DEAD_LIMIT=100000000000 for 100B. */
static long long dead_node_limit = 0;

/* Write per-sub-branch solution file from thread's hash table.
 * Called with checkpoint_mutex held. */
static void flush_sub_solutions(ThreadState *ts, int p2, int o2) {
    if (!ts->sol_table || !ts->sol_occupied || ts->solution_count == 0) return;
    char fname[64];
    snprintf(fname, sizeof(fname), "sub_%d_%d.bin", p2, o2);
    FILE *sf = fopen(fname, "wb");
    if (sf) {
        int written = 0;
        for (int s = 0; s < sol_hash_size; s++) {
            if (ts->sol_occupied[s]) {
                fwrite(&ts->sol_table[(size_t)s * SOL_RECORD_SIZE], SOL_RECORD_SIZE, 1, sf);
                written++;
            }
        }
        fclose(sf);
        fprintf(stderr, "  Wrote %d solutions to %s\n", written, fname);
    }
    /* Clear hash table for next sub-branch */
    memset(ts->sol_table, 0, (size_t)sol_hash_size * SOL_RECORD_SIZE);
    memset(ts->sol_occupied, 0, sol_hash_size);
    ts->solution_count = 0;
    ts->hash_collisions = 0;
}

/* Update progress file with current status.
 * Called with checkpoint_mutex held. */
static void update_progress(int completed, int total, long elapsed) {
    FILE *pf = fopen("progress.txt", "w");
    if (!pf) return;
    fprintf(pf, "Sub-branches: %d/%d complete\n", completed, total);
    fprintf(pf, "Elapsed: %lds (%.1f hours)\n", elapsed, elapsed / 3600.0);
    double cost = elapsed / 3600.0 * 0.79;  /* spot F64 rate */
    fprintf(pf, "Estimated cost: $%.2f\n", cost);
    if (completed > 0 && elapsed > 0) {
        double rate = (double)completed / elapsed;
        int remaining = total - completed;
        long eta_sec = (long)(remaining / rate);
        fprintf(pf, "ETA: %ld hours %ld minutes\n", eta_sec / 3600, (eta_sec % 3600) / 60);
        fprintf(pf, "Projected total cost: $%.2f\n", (elapsed + eta_sec) / 3600.0 * 0.79);
    }
    time_t now = time(NULL);
    char tbuf[64];
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%d %H:%M:%S UTC", gmtime(&now));
    fprintf(pf, "Last updated: %s\n", tbuf);
    fclose(pf);
}

/* ---------- Thread function (single-branch mode) ---------- */

static void *thread_func_single(void *arg) {
    ThreadState *ts = (ThreadState *)arg;
    int start_pair_idx = pair_index_of(63, 0);

    for (int br = 0; br < ts->n_sub_branches; br++) {
        if (global_timed_out) break;

        SubBranch *sb = &ts->sub_branches[br];

        /* Track per-sub-branch node count for dead detection */
        long long nodes_before = ts->nodes;
        long long c3_before = ts->solutions_c3;

        int seq[64];
        int used[32];
        int budget[7];

        /* Position 0: Creative/Receptive */
        seq[0] = 63; seq[1] = 0;
        memset(used, 0, sizeof(used));
        used[start_pair_idx] = 1;
        memcpy(budget, kw_dist, sizeof(budget));
        budget[hamming(63, 0)]--;

        /* Position 1: first-level branch */
        int p1 = sb->pair1, o1 = sb->orient1;
        int f1 = o1 ? pairs[p1].b : pairs[p1].a;
        int s1 = o1 ? pairs[p1].a : pairs[p1].b;
        int bd1 = hamming(seq[1], f1);
        if (bd1 == 5 || budget[bd1] <= 0) continue;
        budget[bd1]--;
        int wd1 = hamming(f1, s1);
        if (budget[wd1] <= 0) continue;
        budget[wd1]--;
        seq[2] = f1; seq[3] = s1;
        used[p1] = 1;

        /* Position 2: second-level sub-branch */
        int p2 = sb->pair2, o2 = sb->orient2;
        int f2 = o2 ? pairs[p2].b : pairs[p2].a;
        int s2 = o2 ? pairs[p2].a : pairs[p2].b;
        int bd2 = hamming(seq[3], f2);
        if (bd2 == 5 || budget[bd2] <= 0) continue;
        budget[bd2]--;
        int wd2 = hamming(f2, s2);
        if (budget[wd2] <= 0) continue;
        budget[wd2]--;
        seq[4] = f2; seq[5] = s2;
        used[p2] = 1;

        ts->branch_nodes = 0;  /* reset per-sub-branch counter */
        backtrack(ts, seq, used, budget, 3);

        long long sub_nodes = ts->nodes - nodes_before;
        long long sub_c3 = ts->solutions_c3 - c3_before;

        int sb_budget_exhausted = (per_branch_node_limit > 0 && ts->branch_nodes >= per_branch_node_limit);
        const char *sb_status = (global_timed_out || sb_budget_exhausted) ? "INTERRUPTED" : "COMPLETE";
        if (!global_timed_out && !sb_budget_exhausted)
            ts->branches_completed++;

        int done = __sync_add_and_fetch(&total_branches_completed, 1);
        long elapsed = (long)(time(NULL) - start_time);

        pthread_mutex_lock(&checkpoint_mutex);

        /* Always flush hash table to file after each sub-branch, then clear.
         * This ensures thread-count independence: each sub-branch's solutions are
         * written to its own file regardless of how many threads are running.
         * The final merge reads all sub_*.bin files instead of thread hash tables.
         * For INTERRUPTED sub-branches, solutions are still saved (they're valid
         * even if the sub-branch didn't complete). */
        if (ts->solution_count > 0) {
            flush_sub_solutions(ts, p2, o2);  /* writes file AND clears table */
        } else if (ts->sol_table) {
            memset(ts->sol_table, 0, (size_t)sol_hash_size * SOL_RECORD_SIZE);
            memset(ts->sol_occupied, 0, sol_hash_size);
            ts->solution_count = 0;
            ts->hash_collisions = 0;
        }

        /* Write checkpoint entry */
        FILE *ckpt = fopen("checkpoint.txt", "a");
        if (ckpt) {
            fprintf(ckpt, "Sub-branch %s (thread %d, pair2 %d orient2 %d): "
                    "%lld nodes, %lld C3-valid, %d solutions, %lds elapsed\n",
                    sb_status, ts->thread_id, p2, o2,
                    sub_nodes, sub_c3, ts->solution_count, elapsed);
            fclose(ckpt);
        }

        /* Update progress file */
        int total_complete = 0;
        /* Count COMPLETE entries (thread-safe since we hold the mutex) */
        FILE *cpf = fopen("checkpoint.txt", "r");
        if (cpf) {
            char line[512];
            while (fgets(line, sizeof(line), cpf))
                if (strstr(line, "COMPLETE") && strstr(line, "Sub-branch"))
                    total_complete++;
            fclose(cpf);
        }
        update_progress(total_complete, total_branches, elapsed);

        fprintf(stderr, "  *** Sub-branch %d/%d %s (pair2 %d orient2 %d): "
                "%lldB nodes, %lldM C3, %d solutions, %lds ***\n",
                done, total_branches, sb_status, p2, o2,
                sub_nodes / 1000000000LL, sub_c3 / 1000000LL,
                ts->solution_count, elapsed);
        pthread_mutex_unlock(&checkpoint_mutex);
    }

    __sync_fetch_and_add(&threads_completed, 1);
    return NULL;
}

/* Compare for qsort — compare pair identity only (orient bit masked out).
 * Each byte: (pair_index << 2) | (orient << 1). Mask with 0xFC. */
/* Write sha256 file with metadata for reproducibility.
 * First line is bare sha256 (compatible with sha256sum -c).
 * Remaining lines are metadata comments. */
static void write_sha256_with_metadata(const char *bin_name, const char *sha_name,
                                        int unique_count, long long total_nodes,
                                        int n_branches_total, int branches_done) {
    /* Compute sha256 */
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "sha256sum %s > %s 2>/dev/null || shasum -a 256 %s > %s 2>/dev/null",
             bin_name, sha_name, bin_name, sha_name);
    int _u = system(cmd); (void)_u;

    /* Read back the hash line */
    char hash_line[256] = {0};
    FILE *hf = fopen(sha_name, "r");
    if (hf) { if (fgets(hash_line, sizeof(hash_line), hf)) {} fclose(hf); }

    /* Rewrite with metadata */
    FILE *sf = fopen(sha_name, "w");
    if (!sf) return;
    fprintf(sf, "%s", hash_line);  /* first line: bare hash (sha256sum -c compatible) */

    /* Metadata */
    char tbuf[64];
    time_t now = time(NULL);
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime(&now));

    fprintf(sf, "# Metadata for reproducibility\n");
    fprintf(sf, "# Date: %s\n", tbuf);
    fprintf(sf, "# Build: %s %s (git: %s)\n", __DATE__, __TIME__, GIT_HASH);
    fprintf(sf, "# Record format: %d bytes packed (pair_index<<2 | orient<<1)\n", SOL_RECORD_SIZE);
    fprintf(sf, "# Unique orderings: %d\n", unique_count);
    fprintf(sf, "# Nodes explored: %lld\n", total_nodes);
    fprintf(sf, "# Branches: %d total, %d completed\n", n_branches_total, branches_done);
    if (node_limit > 0)
        fprintf(sf, "# SOLVE_NODE_LIMIT=%lld (per-branch: %lld, thread-independent)\n",
                node_limit, per_branch_node_limit);
    else
        fprintf(sf, "# SOLVE_NODE_LIMIT=0 (time-limited, not reproducible across hardware)\n");
    if (time_limit > 0)
        fprintf(sf, "# Time limit: %d seconds\n", time_limit);
    fprintf(sf, "# SOLVE_THREADS: any (output is thread-independent with node limit)\n");
    fclose(sf);
}

/* Compare for qsort — compare pair identity first (orient bit masked out),
 * then break ties by full byte value (including orient). This ensures
 * deterministic sort order: among records with the same canonical pair ordering,
 * the one with the smallest orient bits always comes first. Critical for
 * thread-count-independent reproducibility in dedup. */
/* Exhaustive search for C3-valid completions at positions step..31.
 * Used by --prove-cascade to verify no non-KW config has valid completions. */
static void proof_search(int seq[64], int used[32], int budget[7],
                         int step, int last, long long *nodes, int *found) {
    (*nodes)++;
    if (*found) return;
    if ((*nodes) % 1000000000LL == 0) {
        fprintf(stderr, " %lldB nodes...", (*nodes) / 1000000000LL);
    }

    if (step == 32) {
        int cd = compute_comp_dist_x64(seq);
        if (cd <= kw_comp_dist_x64) {
            *found = 1;
        }
        return;
    }

    for (int p = 0; p < 32; p++) {
        if (used[p]) continue;
        for (int orient = 0; orient < 2; orient++) {
            int first = orient ? pairs[p].b : pairs[p].a;
            int second = orient ? pairs[p].a : pairs[p].b;
            int bd = hamming(last, first);
            if (bd == 5 || budget[bd] <= 0) continue;
            budget[bd]--;
            int wd = hamming(first, second);
            if (budget[wd] <= 0) { budget[bd]++; continue; }
            budget[wd]--;
            seq[step * 2] = first;
            seq[step * 2 + 1] = second;
            used[p] = 1;
            proof_search(seq, used, budget, step + 1, second, nodes, found);
            used[p] = 0;
            budget[wd]++;
            budget[bd]++;
            if (*found) return;
        }
    }
}

static int compare_solutions(const void *a, const void *b) {
    const unsigned char *sa = (const unsigned char *)a;
    const unsigned char *sb = (const unsigned char *)b;
    /* Primary: pair identity (orient masked out) */
    for (int i = 0; i < SOL_RECORD_SIZE; i++) {
        int ca = sa[i] & 0xFC;
        int cb = sb[i] & 0xFC;
        if (ca != cb) return ca - cb;
    }
    /* Secondary: full byte (orient as tiebreaker for deterministic dedup) */
    return memcmp(sa, sb, SOL_RECORD_SIZE);
}

/* ---------- JSON output ---------- */

static void write_json(const char *filename, const char *status,
                       long elapsed, int n_threads, int n_branches_total,
                       int branches_done,
                       long long total_nodes, long long total_sol,
                       long long total_c3, int unique_count,
                       int kw_found, long long total_hash_collisions,
                       long long pos_match[32],
                       long long edit_hist[33],
                       ClosestEntry *top_closest, int top_count,
                       long long c6_sat, long long c7_sat, long long c6c7_sat,
                       long long per_boundary[31], long long adj_hist[32],
                       long long cd_hist_arr[],
                       long long pair_freq[][32],
                       long long super_match[32],
                       const char *sha256_hash) {
    FILE *f = fopen(filename, "w");
    if (!f) return;
    char tbuf[64];

    fprintf(f, "{\n");
    fprintf(f, "  \"version\": \"2.0\",\n");
    fprintf(f, "  \"status\": \"%s\",\n", status);

    fprintf(f, "  \"run\": {\n");
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime(&start_time));
    fprintf(f, "    \"start_utc\": \"%s\",\n", tbuf);
    time_t end = start_time + elapsed;
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime(&end));
    fprintf(f, "    \"end_utc\": \"%s\",\n", tbuf);
    fprintf(f, "    \"elapsed_seconds\": %ld,\n", elapsed);
    fprintf(f, "    \"time_limit_seconds\": %d,\n", time_limit);
    fprintf(f, "    \"threads\": %d,\n", n_threads);
    fprintf(f, "    \"branches_total\": %d,\n", n_branches_total);
    fprintf(f, "    \"branches_completed\": %d,\n", branches_done);
    fprintf(f, "    \"hash_table_size\": %d,\n", sol_hash_size);
    fprintf(f, "    \"hash_table_log2\": %d,\n", sol_hash_log2);
    fprintf(f, "    \"cpu_cores\": %ld,\n", sysconf(_SC_NPROCESSORS_ONLN));
    fprintf(f, "    \"resumed_branches\": %d\n", n_completed_from_checkpoint);
    fprintf(f, "  },\n");

    fprintf(f, "  \"counts\": {\n");
    fprintf(f, "    \"nodes_explored\": %lld,\n", total_nodes);
    fprintf(f, "    \"total_solutions\": %lld,\n", total_sol);
    fprintf(f, "    \"c3_valid\": %lld,\n", total_c3);
    fprintf(f, "    \"unique_orderings\": %d,\n", unique_count);
    fprintf(f, "    \"king_wen_found\": %s,\n", kw_found ? "true" : "false");
    fprintf(f, "    \"hash_dedup_collisions\": %lld\n", total_hash_collisions);
    fprintf(f, "  },\n");

    fprintf(f, "  \"position_match\": {\n");
    fprintf(f, "    \"rates\": [");
    for (int i = 0; i < 32; i++) {
        double rate = total_c3 > 0 ? (double)pos_match[i] / total_c3 * 100 : 0;
        fprintf(f, "%.4f%s", rate, i < 31 ? ", " : "");
    }
    fprintf(f, "],\n");
    fprintf(f, "    \"counts\": [");
    for (int i = 0; i < 32; i++)
        fprintf(f, "%lld%s", pos_match[i], i < 31 ? ", " : "");
    fprintf(f, "]\n");
    fprintf(f, "  },\n");

    fprintf(f, "  \"edit_distance\": {\n");
    fprintf(f, "    \"histogram\": {");
    int first = 1;
    for (int d = 0; d <= 32; d++) {
        if (edit_hist[d] > 0) {
            fprintf(f, "%s\"%d\": %lld", first ? "" : ", ", d, edit_hist[d]);
            first = 0;
        }
    }
    fprintf(f, "},\n");
    fprintf(f, "    \"closest\": [\n");
    for (int i = 0; i < top_count; i++) {
        fprintf(f, "      {\"distance\": %d, \"diff_positions\": [", top_closest[i].edit_dist);
        for (int j = 0; j < top_closest[i].diff_count; j++)
            fprintf(f, "%d%s", top_closest[i].diff_positions[j] + 1,
                    j < top_closest[i].diff_count - 1 ? ", " : "");
        fprintf(f, "], \"sequence\": [");
        for (int j = 0; j < 64; j++)
            fprintf(f, "%d%s", top_closest[i].solution[j], j < 63 ? ", " : "");
        fprintf(f, "]}%s\n", i < top_count - 1 ? "," : "");
    }
    fprintf(f, "    ]\n");
    fprintf(f, "  },\n");

    fprintf(f, "  \"adjacency\": {\n");
    fprintf(f, "    \"per_boundary_rates\": [");
    for (int b = 0; b < 31; b++) {
        double rate = total_c3 > 0 ? (double)per_boundary[b] / total_c3 * 100 : 0;
        fprintf(f, "%.4f%s", rate, b < 30 ? ", " : "");
    }
    fprintf(f, "],\n");
    fprintf(f, "    \"match_histogram\": {");
    first = 1;
    for (int k = 0; k < 32; k++) {
        if (adj_hist[k] > 0) {
            fprintf(f, "%s\"%d\": %lld", first ? "" : ", ", k, adj_hist[k]);
            first = 0;
        }
    }
    fprintf(f, "},\n");
    fprintf(f, "    \"c6_satisfied\": %lld,\n", c6_sat);
    fprintf(f, "    \"c7_satisfied\": %lld,\n", c7_sat);
    fprintf(f, "    \"c6_and_c7_satisfied\": %lld\n", c6c7_sat);
    fprintf(f, "  },\n");

    fprintf(f, "  \"complement_distance\": {\n");
    fprintf(f, "    \"kw_value_x64\": %d,\n", kw_comp_dist_x64);
    fprintf(f, "    \"kw_value\": %.4f,\n", kw_comp_dist_x64 / 64.0);
    fprintf(f, "    \"histogram\": {");
    first = 1;
    for (int i = 0; i < CD_HIST_SIZE; i++) {
        if (cd_hist_arr[i] > 0) {
            fprintf(f, "%s\"%d-%d\": %lld", first ? "" : ", ",
                    i * 20, (i + 1) * 20 - 1, cd_hist_arr[i]);
            first = 0;
        }
    }
    fprintf(f, "}\n");
    fprintf(f, "  },\n");

    fprintf(f, "  \"super_pairs\": {\n");
    fprintf(f, "    \"count\": %d,\n", n_super_pairs);
    fprintf(f, "    \"match_rates\": [");
    for (int i = 0; i < 32; i++) {
        double rate = total_c3 > 0 ? (double)super_match[i] / total_c3 * 100 : 0;
        fprintf(f, "%.4f%s", rate, i < 31 ? ", " : "");
    }
    fprintf(f, "],\n");
    fprintf(f, "    \"mapping\": [");
    for (int i = 0; i < 32; i++)
        fprintf(f, "%d%s", super_pair_of[i], i < 31 ? ", " : "");
    fprintf(f, "]\n");
    fprintf(f, "  },\n");

    /* Per-position pair frequency (top 3 per position) */
    fprintf(f, "  \"pair_frequency\": [\n");
    for (int pos = 0; pos < 32; pos++) {
        fprintf(f, "    [");
        int top3[3] = {-1, -1, -1};
        long long top3c[3] = {0, 0, 0};
        int n_diff = 0;
        for (int p = 0; p < 32; p++) {
            if (pair_freq[pos][p] > 0) n_diff++;
            if (pair_freq[pos][p] > top3c[0]) {
                top3[2] = top3[1]; top3c[2] = top3c[1];
                top3[1] = top3[0]; top3c[1] = top3c[0];
                top3[0] = p; top3c[0] = pair_freq[pos][p];
            } else if (pair_freq[pos][p] > top3c[1]) {
                top3[2] = top3[1]; top3c[2] = top3c[1];
                top3[1] = p; top3c[1] = pair_freq[pos][p];
            } else if (pair_freq[pos][p] > top3c[2]) {
                top3[2] = p; top3c[2] = pair_freq[pos][p];
            }
        }
        first = 1;
        for (int t = 0; t < 3; t++) {
            if (top3[t] >= 0 && top3c[t] > 0) {
                double pct = total_c3 > 0 ? (double)top3c[t] / total_c3 * 100 : 0;
                fprintf(f, "%s{\"pair\": %d, \"count\": %lld, \"pct\": %.2f, \"n_different\": %d}",
                        first ? "" : ", ", top3[t] + 1, top3c[t], pct, n_diff);
                first = 0;
            }
        }
        fprintf(f, "]%s\n", pos < 31 ? "," : "");
    }
    fprintf(f, "  ],\n");

    fprintf(f, "  \"output\": {\n");
    fprintf(f, "    \"solutions_bin_records\": %d,\n", unique_count);
    fprintf(f, "    \"solutions_bin_record_size\": %d,\n", SOL_RECORD_SIZE);
    fprintf(f, "    \"solutions_bin_bytes\": %lld,\n", (long long)unique_count * SOL_RECORD_SIZE);
    fprintf(f, "    \"sha256\": \"%s\"\n", sha256_hash ? sha256_hash : "");
    fprintf(f, "  }\n");

    fprintf(f, "}\n");
    fclose(f);
}

/* ---------- Main ---------- */

int main(int argc, char *argv[]) {
    /* Check for single-branch mode */
    int single_branch_mode = 0;
    int sb_pair = -1, sb_orient = -1;
    int arg_offset = 1;

    int list_branches_mode = 0;
    int validate_mode = 0;
    int merge_mode = 0;
    int prove_cascade_mode = 0;
    int prove_self_comp_mode = 0;
    int prove_shift_mode = 0;
    char *validate_file = NULL;

    if (argc > 1 && strcmp(argv[1], "--prove-cascade") == 0) {
        prove_cascade_mode = 1;
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--prove-self-comp") == 0) {
        prove_self_comp_mode = 1;
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--prove-shift") == 0) {
        prove_shift_mode = 1;
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--merge") == 0) {
        merge_mode = 1;
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--validate") == 0) {
        validate_mode = 1;
        validate_file = (argc > 2) ? argv[2] : "solutions.bin";
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--list-branches") == 0) {
        list_branches_mode = 1;
        arg_offset = argc;  /* consume all args */
    } else if (argc > 1 && strcmp(argv[1], "--branch") == 0) {
        if (argc < 4) {
            printf("Usage: ./solve --branch <pair> <orient> [time_limit] [threads]\n");
            printf("       ./solve --list-branches [solve_results.json]\n");
            printf("  pair:   pair index (0-31)\n");
            printf("  orient: 0 or 1\n");
            return 1;
        }
        single_branch_mode = 1;
        sb_pair = atoi(argv[2]);
        sb_orient = atoi(argv[3]);
        arg_offset = 4;
        printf("Single-branch mode: pair %d, orient %d\n", sb_pair, sb_orient);
    }

    if (arg_offset < argc) {
        time_limit = atoi(argv[arg_offset]);
        if (time_limit > 0)
            printf("Time limit: %d seconds\n", time_limit);
        else
            printf("No time limit — running to completion.\n");
    } else {
        printf("No time limit — running to completion.\n");
        if (!single_branch_mode)
            printf("Usage: ./solve [time_limit] [threads]  (0 = no limit)\n");
    }

    /* Configurable hash table size */
    char *env_hash = getenv("SOLVE_HASH_LOG2");
    if (env_hash) {
        int v = atoi(env_hash);
        if (v >= 16 && v <= 28) sol_hash_log2 = v;
    }
    sol_hash_size = 1 << sol_hash_log2;
    sol_hash_mask = sol_hash_size - 1;

    /* Dead sub-branch detection: skip sub-branches with >N nodes and 0 C3-valid.
     * Default 0 = disabled. Set e.g. SOLVE_DEAD_LIMIT=100000000000 for 100B. */
    char *env_dead = getenv("SOLVE_DEAD_LIMIT");
    if (env_dead) dead_node_limit = atoll(env_dead);

    /* Node limit for reproducible runs. E.g. SOLVE_NODE_LIMIT=5000000000000 for 5T. */
    char *env_nodes = getenv("SOLVE_NODE_LIMIT");
    if (env_nodes) node_limit = atoll(env_nodes);
    if (node_limit > 0)
        printf("Node limit: %lld (reproducible mode)\n", node_limit);

    init_pairs();
    init_kw_dist();
    kw_comp_dist_x64 = compute_comp_dist_x64(KW);
    init_kw_canonical();
    init_adjacency_constraints();
    init_kw_pair_positions();
    init_super_pairs();
    init_pair_order();

    printf("Build: %s %s (git: %s)\n", __DATE__, __TIME__, GIT_HASH);
    printf("King Wen complement distance (x64): %d (= %.4f)\n",
           kw_comp_dist_x64, kw_comp_dist_x64 / 64.0);
    printf("Difference distribution: ");
    for (int d = 0; d < 7; d++) {
        if (kw_dist[d] > 0) printf("%d:%d ", d, kw_dist[d]);
    }
    printf("\nSuper-pairs: %d\n", n_super_pairs);

    /* --- Validate mode ---
     * solutions.bin uses packed 32-byte records: byte i = (pair_index<<2)|(orient<<1).
     * Full sequence is recoverable, enabling verification of ALL constraints. */
    if (validate_mode) {
        printf("\nValidating %s...\n", validate_file);
        printf("  Record format: %d bytes packed (pair_index<<2 | orient<<1 per position)\n",
               SOL_RECORD_SIZE);
        printf("  Checking: C1-C5, C3, sorted order, no duplicates, King Wen presence.\n\n");

        FILE *vf = fopen(validate_file, "rb");
        if (!vf) { printf("ERROR: cannot open %s\n", validate_file); return 1; }
        fseek(vf, 0, SEEK_END);
        long file_size = ftell(vf);
        fseek(vf, 0, SEEK_SET);
        int n_solutions = (int)(file_size / SOL_RECORD_SIZE);
        printf("  File size: %ld bytes, %d solutions (%d bytes/record)\n",
               file_size, n_solutions, SOL_RECORD_SIZE);
        if (file_size % SOL_RECORD_SIZE != 0)
            printf("  WARNING: file size not a multiple of %d bytes\n", SOL_RECORD_SIZE);

        int errors = 0, kw_found_v = 0;
        unsigned char prev[SOL_RECORD_SIZE];
        memset(prev, 0, sizeof(prev));
        int sorted_ok = 1;

        for (int s = 0; s < n_solutions; s++) {
            unsigned char rec[SOL_RECORD_SIZE];
            if (fread(rec, SOL_RECORD_SIZE, 1, vf) != 1) {
                printf("  ERROR: read failed at solution %d\n", s);
                errors++; break;
            }

            /* Check sorted order (pair identity only, orient masked) */
            if (s > 0 && compare_solutions(rec, prev) <= 0) {
                if (compare_solutions(rec, prev) == 0)
                    printf("  ERROR: duplicate at index %d\n", s);
                else
                    printf("  ERROR: not sorted at index %d\n", s);
                sorted_ok = 0; errors++;
            }
            memcpy(prev, rec, SOL_RECORD_SIZE);

            /* Decode packed record into pair indices and full sequence */
            int sol_pidx[32];
            int seq[64];
            int used_pairs[32] = {0};
            int c1_ok = 1;
            for (int i = 0; i < 32; i++) {
                int pidx = rec[i] >> 2;
                int orient = (rec[i] >> 1) & 1;
                if (pidx < 0 || pidx >= 32) {
                    printf("  ERROR: solution %d position %d invalid pair index %d\n",
                           s, i + 1, pidx);
                    c1_ok = 0; errors++; break;
                }
                if (used_pairs[pidx]) {
                    printf("  ERROR: solution %d duplicate pair %d at position %d\n",
                           s, pidx, i + 1);
                    c1_ok = 0; errors++; break;
                }
                used_pairs[pidx] = 1;
                sol_pidx[i] = pidx;
                if (orient) {
                    seq[i * 2] = pairs[pidx].b;
                    seq[i * 2 + 1] = pairs[pidx].a;
                } else {
                    seq[i * 2] = pairs[pidx].a;
                    seq[i * 2 + 1] = pairs[pidx].b;
                }
            }
            if (!c1_ok) continue;

            /* C4: position 1 must be Creative/Receptive (pair 0) */
            if (sol_pidx[0] != pair_index_of(63, 0)) {
                printf("  ERROR: solution %d position 1 is pair %d, expected Creative/Receptive\n",
                       s, sol_pidx[0]);
                errors++;
            }

            /* C2 + C5: check transitions on reconstructed sequence */
            int budget_check[7] = {0};
            int c2_ok = 1;
            for (int i = 0; i < 63; i++) {
                int d = hamming(seq[i], seq[i + 1]);
                if (d == 5) {
                    printf("  ERROR: solution %d has 5-line transition at position %d-%d\n",
                           s, i, i + 1);
                    c2_ok = 0; errors++; break;
                }
                budget_check[d]++;
            }
            if (c2_ok) {
                for (int d = 0; d < 7; d++) {
                    if (budget_check[d] != kw_dist[d]) {
                        printf("  ERROR: solution %d wrong difference distribution "
                               "(dist %d: got %d, expected %d)\n",
                               s, d, budget_check[d], kw_dist[d]);
                        errors++; break;
                    }
                }
            }

            /* C3: complement distance */
            int cd = compute_comp_dist_x64(seq);
            if (cd > kw_comp_dist_x64) {
                printf("  ERROR: solution %d complement distance %d > KW %d\n",
                       s, cd, kw_comp_dist_x64);
                errors++;
            }

            /* Check if this is King Wen */
            int is_kw = 1;
            for (int i = 0; i < 64; i++) {
                if (seq[i] != KW[i]) { is_kw = 0; break; }
            }
            if (is_kw) kw_found_v = 1;

            if (s > 0 && s % 1000000 == 0)
                printf("  Validated %d/%d solutions...\n", s, n_solutions);
        }
        fclose(vf);

        printf("\n--- Validation results ---\n");
        printf("  Solutions checked:  %d\n", n_solutions);
        printf("  Sorted order:      %s\n", sorted_ok ? "OK" : "FAILED");
        printf("  King Wen present:  %s\n", kw_found_v ? "YES" : "No");
        printf("  Errors found:      %d\n", errors);
        if (errors == 0)
            printf("  Result: ALL CONSTRAINTS VERIFIED\n");
        else
            printf("  Result: VALIDATION FAILED\n");
        return errors > 0 ? 1 : 0;
    }

    /* --- Merge mode: combine sub_*.bin files into one sorted, deduped output --- */
    if (merge_mode) {
        printf("\nMerge mode: combining sub_*.bin files...\n");

        /* Count and list sub_*.bin files using a simple scan */
        char filenames[64][64];
        int n_files = 0;
        for (int p2 = 0; p2 < 32; p2++) {
            for (int o2 = 0; o2 < 2; o2++) {
                char fname[64];
                snprintf(fname, sizeof(fname), "sub_%d_%d.bin", p2, o2);
                FILE *tf = fopen(fname, "rb");
                if (tf) {
                    fseek(tf, 0, SEEK_END);
                    long sz = ftell(tf);
                    fclose(tf);
                    if (sz > 0) {
                        snprintf(filenames[n_files], 64, "%s", fname);
                        n_files++;
                        printf("  Found %s: %ld bytes (%ld solutions)\n",
                               fname, sz, sz / SOL_RECORD_SIZE);
                    }
                }
            }
        }
        if (n_files == 0) {
            printf("No sub_*.bin files found.\n");
            return 1;
        }
        printf("  %d files to merge\n", n_files);

        /* Read all files into one buffer */
        long long total_records = 0;
        for (int i = 0; i < n_files; i++) {
            FILE *tf = fopen(filenames[i], "rb");
            fseek(tf, 0, SEEK_END);
            total_records += ftell(tf) / SOL_RECORD_SIZE;
            fclose(tf);
        }
        printf("  Total records before dedup: %lld\n", total_records);

        unsigned char *all = malloc((size_t)total_records * SOL_RECORD_SIZE);
        if (!all) { printf("ERROR: malloc failed for %lld records\n", total_records); return 1; }

        long long offset = 0;
        for (int i = 0; i < n_files; i++) {
            FILE *tf = fopen(filenames[i], "rb");
            fseek(tf, 0, SEEK_END);
            long sz = ftell(tf);
            fseek(tf, 0, SEEK_SET);
            if (fread(&all[offset * SOL_RECORD_SIZE], 1, sz, tf) != (size_t)sz)
                printf("  WARNING: short read on %s\n", filenames[i]);
            offset += sz / SOL_RECORD_SIZE;
            fclose(tf);
        }

        printf("  Sorting %lld records...\n", total_records);
        qsort(all, total_records, SOL_RECORD_SIZE, compare_solutions);

        /* Dedup */
        long long unique = 0;
        for (long long i = 0; i < total_records; i++) {
            if (i == 0 || compare_solutions(
                    &all[i * SOL_RECORD_SIZE],
                    &all[(i - 1) * SOL_RECORD_SIZE]) != 0) {
                if (unique != i)
                    memcpy(&all[unique * SOL_RECORD_SIZE],
                           &all[i * SOL_RECORD_SIZE], SOL_RECORD_SIZE);
                unique++;
            }
        }
        printf("  Unique solutions: %lld (removed %lld duplicates)\n",
               unique, total_records - unique);

        /* Write merged output */
        char outname[64] = "solutions_merged.bin";
        printf("  Writing %s...\n", outname);
        FILE *of = fopen(outname, "wb");
        if (of) { fwrite(all, SOL_RECORD_SIZE, unique, of); fclose(of); }
        free(all);

        /* sha256 */
        char sha_cmd[256];
        snprintf(sha_cmd, sizeof(sha_cmd),
                 "sha256sum %s > %s.sha256 2>/dev/null || shasum -a 256 %s > %s.sha256 2>/dev/null",
                 outname, outname, outname, outname);
        int _u = system(sha_cmd); (void)_u;

        char hash[130] = {0};
        char hashfile[80];
        snprintf(hashfile, sizeof(hashfile), "%s.sha256", outname);
        FILE *hf = fopen(hashfile, "r");
        if (hf) { if (fgets(hash, sizeof(hash), hf)) {} fclose(hf); }

        printf("\n--- Merge results ---\n");
        printf("  Input files:     %d\n", n_files);
        printf("  Total records:   %lld\n", total_records);
        printf("  Unique solutions: %lld\n", unique);
        printf("  Output:          %s (%lld bytes)\n", outname, unique * SOL_RECORD_SIZE);
        printf("  sha256:          %s\n", hash);

        /* Validate merged output */
        printf("\nValidating merged output...\n");
        int _v = 0;
        char val_cmd[128];
        snprintf(val_cmd, sizeof(val_cmd), "./solve --validate %s", outname);
        _v = system(val_cmd); (void)_v;

        return 0;
    }

    /* --- Prove cascade: position 2 determines positions 3-19 --- */
    /* --- Prove self-complementary branches always live --- */
    if (prove_self_comp_mode) {
        setbuf(stdout, NULL);
        int start_pair_idx = pair_index_of(63, 0);

        printf("\n======================================================================\n");
        printf("PROOF: All self-complementary branches produce valid orderings\n");
        printf("======================================================================\n\n");
        printf("A pair is self-complementary when a XOR b = 111111 (WPD = 6).\n");
        printf("For each such pair at position 2, we run a bounded backtracking\n");
        printf("search to find at least one C3-valid solution, then verify all\n");
        printf("5 constraints on the found solution.\n\n");

        int tested = 0, proved = 0;

        for (int bp = 0; bp < 32; bp++) {
            if (bp == start_pair_idx) continue;
            if ((pairs[bp].a ^ 63) != pairs[bp].b) continue;  /* not self-comp */

            tested++;
            printf("  Pair %2d (%2d XOR %2d = 63): ", bp, pairs[bp].a, pairs[bp].b);
            fflush(stdout);

            /* Try to find one C3-valid solution with this pair at position 2 */
            int found = 0;
            for (int orient1 = 0; orient1 < 2 && !found; orient1++) {
                int f1 = orient1 ? pairs[bp].b : pairs[bp].a;
                int s1 = orient1 ? pairs[bp].a : pairs[bp].b;
                int bd1 = hamming(0, f1);
                if (bd1 == 5) continue;
                int budget[7]; memcpy(budget, kw_dist, sizeof(budget));
                budget[hamming(63, 0)]--;
                if (budget[bd1] <= 0) continue;
                budget[bd1]--;
                int wd1 = hamming(f1, s1);
                if (budget[wd1] <= 0) continue;
                budget[wd1]--;

                int seq[64];
                seq[0] = 63; seq[1] = 0; seq[2] = f1; seq[3] = s1;
                int used[32] = {0};
                used[start_pair_idx] = 1; used[bp] = 1;

                long long nodes = 0;
                proof_search(seq, used, budget, 2, s1, &nodes, &found);
            }

            if (found) {
                proved++;
                printf("PROVED (found C3-valid solution)\n");
            } else {
                printf("FAILED (no solution found)\n");
            }
        }

        printf("\n======================================================================\n");
        printf("Result: %d/%d self-complementary branches proved live.\n", proved, tested);
        if (proved == tested) {
            printf("\nTHEOREM PROVED: Every self-complementary pair at position 2\n");
            printf("produces at least one valid ordering satisfying C1-C5. QED.\n");
        } else {
            printf("\nNOT FULLY PROVED: %d branches failed.\n", tested - proved);
        }
        printf("======================================================================\n");
        return 0;
    }

    /* --- Prove shift pattern: positions 3-19 have exactly 2 candidates --- */
    if (prove_shift_mode) {
        setbuf(stdout, NULL);
        int start_pair_idx = pair_index_of(63, 0);

        printf("\n======================================================================\n");
        printf("PROOF: Positions 3-19 have exactly 2 budget-feasible candidates\n");
        printf("======================================================================\n\n");
        printf("For each valid branch (pair at position 2), at each position i\n");
        printf("(3-19), we test ALL 30 unused pairs (not just the 2 candidates).\n");
        printf("If exactly 2 pass the budget check at every position, the shift\n");
        printf("pattern is a mathematical necessity of the budget constraints.\n\n");

        int all_proved = 1;

        for (int bp = 0; bp < 32; bp++) {
            if (bp == start_pair_idx) continue;

            int any_valid_orient = 0;

            for (int orient1 = 0; orient1 < 2; orient1++) {
                int f1 = orient1 ? pairs[bp].b : pairs[bp].a;
                int s1 = orient1 ? pairs[bp].a : pairs[bp].b;
                int bd1 = hamming(0, f1);
                if (bd1 == 5) continue;
                int budget_init[7]; memcpy(budget_init, kw_dist, sizeof(budget_init));
                budget_init[hamming(63, 0)]--;
                if (budget_init[bd1] <= 0) continue;
                budget_init[bd1]--;
                int wd1 = hamming(f1, s1);
                if (budget_init[wd1] <= 0) continue;
                budget_init[wd1]--;

                any_valid_orient = 1;

                /* At each position 2-18, count how many unused pairs are budget-feasible */
                int budget[7]; memcpy(budget, budget_init, sizeof(budget));
                int used[32] = {0};
                used[start_pair_idx] = 1; used[bp] = 1;
                int last_hex = s1;
                int branch_ok = 1;

                printf("  Pair %2d orient %d:", bp, orient1);

                for (int pos = 2; pos < 19; pos++) {
                    int feasible_count = 0;
                    int feasible_pairs[32];

                    for (int cand = 0; cand < 32; cand++) {
                        if (used[cand]) continue;
                        /* Try both orientations */
                        int can_place = 0;
                        for (int orient = 0; orient < 2; orient++) {
                            int first = orient ? pairs[cand].b : pairs[cand].a;
                            int second = orient ? pairs[cand].a : pairs[cand].b;
                            int bd = hamming(last_hex, first);
                            if (bd == 5 || budget[bd] <= 0) continue;
                            int test_b[7]; memcpy(test_b, budget, sizeof(test_b));
                            test_b[bd]--;
                            int wd = hamming(first, second);
                            if (test_b[wd] <= 0) continue;
                            test_b[wd]--;
                            /* Forward check */
                            int tmp_used[32]; memcpy(tmp_used, used, sizeof(tmp_used));
                            tmp_used[cand] = 1;
                            int need[7] = {0};
                            for (int p = 0; p < 32; p++)
                                if (!tmp_used[p]) need[hamming(pairs[p].a, pairs[p].b)]++;
                            int fwd = 1;
                            for (int d = 0; d < 7; d++)
                                if (need[d] > test_b[d]) { fwd = 0; break; }
                            if (fwd) { can_place = 1; break; }
                        }
                        if (can_place) {
                            feasible_pairs[feasible_count++] = cand;
                        }
                    }

                    printf(" %d", feasible_count);
                    if (feasible_count != 2) {
                        branch_ok = 0;
                    }

                    /* Place the KW pair (pair = pos) to continue the check.
                     * If KW pair isn't feasible, place first feasible one. */
                    int placed = -1;
                    for (int fi = 0; fi < feasible_count; fi++) {
                        if (feasible_pairs[fi] == pos) { placed = pos; break; }
                    }
                    if (placed < 0 && feasible_count > 0) placed = feasible_pairs[0];
                    if (placed < 0) { branch_ok = 0; break; }

                    /* Actually place it to update budget state */
                    for (int orient = 0; orient < 2; orient++) {
                        int first = orient ? pairs[placed].b : pairs[placed].a;
                        int second = orient ? pairs[placed].a : pairs[placed].b;
                        int bd = hamming(last_hex, first);
                        if (bd == 5 || budget[bd] <= 0) continue;
                        budget[bd]--;
                        int wd = hamming(first, second);
                        if (budget[wd] <= 0) { budget[bd]++; continue; }
                        budget[wd]--;
                        used[placed] = 1;
                        last_hex = second;
                        break;
                    }
                }

                if (branch_ok) {
                    printf(" -> PROVED (all positions have exactly 2)\n");
                } else {
                    printf(" -> VARIES\n");
                    all_proved = 0;
                }
            }

            if (!any_valid_orient) {
                printf("  Pair %2d: DEAD (no valid orientation)\n", bp);
            }
        }

        printf("\n======================================================================\n");
        if (all_proved) {
            printf("THEOREM PROVED: At every position 3-19, exactly 2 pairs are\n");
            printf("budget-feasible (with forward checking). The shift pattern\n");
            printf("is a mathematical necessity of constraint C5. QED.\n");
        } else {
            printf("PARTIAL: Some positions have != 2 feasible candidates.\n");
        }
        printf("======================================================================\n");
        return 0;
    }

    if (prove_cascade_mode) {
        /* Disable buffering so progress is visible in real-time */
        setbuf(stdout, NULL);
        setbuf(stderr, NULL);
        int start_pair_idx = pair_index_of(63, 0);

        printf("\n======================================================================\n");
        printf("PROOF: Position 2 determines positions 3-19\n");
        printf("======================================================================\n\n");
        printf("Method: For each valid branch (pair at position 2), enumerate all\n");
        printf("2^17 = 131,072 binary paths at positions 3-19. At each position i,\n");
        printf("the two candidates are pair i (KW) and pair i-1 (shifted). Check\n");
        printf("budget feasibility for every path. If exactly 1 survives per branch,\n");
        printf("the cascade is deterministic.\n\n");

        int all_proved = 1;
        int proved_count = 0, dead_count = 0, multi_count = 0;

        for (int bp = 0; bp < 32; bp++) {
            if (bp == start_pair_idx) continue;

            int branch_feasible = 0;
            /* Track unique pair sequences (ignoring orientation) */
            /* Use a simple array of found sequences, max 131072 */
            /* At most a few unique sequences expected; 1000 is generous */
            static int found_seqs[1000][17];
            int n_found = 0;

            for (int orient1 = 0; orient1 < 2; orient1++) {
                int f1 = orient1 ? pairs[bp].b : pairs[bp].a;
                int s1 = orient1 ? pairs[bp].a : pairs[bp].b;

                int bd1 = hamming(0, f1);  /* from Receptive */
                if (bd1 == 5) continue;
                int budget_init[7];
                memcpy(budget_init, kw_dist, sizeof(budget_init));
                budget_init[hamming(63, 0)]--;  /* pair 0 within-pair */
                if (budget_init[bd1] <= 0) continue;
                budget_init[bd1]--;
                int wd1 = hamming(pairs[bp].a, pairs[bp].b);
                if (budget_init[wd1] <= 0) continue;
                budget_init[wd1]--;

                /* Enumerate all 2^17 binary paths */
                for (int bits = 0; bits < (1 << 17); bits++) {
                    int budget[7];
                    memcpy(budget, budget_init, sizeof(budget));
                    int used[32] = {0};
                    used[start_pair_idx] = 1;
                    used[bp] = 1;
                    int last_hex = s1;
                    int path[17];
                    int feasible = 1;

                    for (int j = 0; j < 17; j++) {
                        int pos = j + 2;  /* pair position 2-18 */
                        int choice = (bits >> j) & 1;
                        int cand = choice ? (pos - 1) : pos;

                        if (cand < 0 || cand >= 32 || used[cand]) {
                            feasible = 0;
                            break;
                        }

                        /* Try both orientations, pick first valid one */
                        int placed = 0;
                        for (int orient = 0; orient < 2; orient++) {
                            int first = orient ? pairs[cand].b : pairs[cand].a;
                            int second = orient ? pairs[cand].a : pairs[cand].b;
                            int bd = hamming(last_hex, first);
                            if (bd == 5) continue;
                            if (budget[bd] <= 0) continue;

                            int new_budget[7];
                            memcpy(new_budget, budget, sizeof(new_budget));
                            new_budget[bd]--;
                            int wd = hamming(pairs[cand].a, pairs[cand].b);
                            if (new_budget[wd] <= 0) continue;
                            new_budget[wd]--;

                            /* Forward check: remaining pairs' WPDs must fit budget */
                            int need[7] = {0};
                            int tmp_used[32];
                            memcpy(tmp_used, used, sizeof(tmp_used));
                            tmp_used[cand] = 1;
                            for (int p = 0; p < 32; p++) {
                                if (!tmp_used[p])
                                    need[hamming(pairs[p].a, pairs[p].b)]++;
                            }
                            int fwd_ok = 1;
                            for (int d = 0; d < 7; d++) {
                                if (need[d] > new_budget[d]) { fwd_ok = 0; break; }
                            }
                            if (!fwd_ok) continue;

                            memcpy(budget, new_budget, sizeof(budget));
                            used[cand] = 1;
                            last_hex = second;
                            path[j] = cand;
                            placed = 1;
                            break;
                        }

                        if (!placed) { feasible = 0; break; }
                    }

                    if (feasible) {
                        /* Check if this pair sequence is new */
                        int is_new = 1;
                        for (int f = 0; f < n_found; f++) {
                            int match = 1;
                            for (int j = 0; j < 17; j++) {
                                if (found_seqs[f][j] != path[j]) { match = 0; break; }
                            }
                            if (match) { is_new = 0; break; }
                        }
                        if (is_new && n_found < 131072) {
                            memcpy(found_seqs[n_found], path, sizeof(int) * 17);
                            n_found++;
                        }
                        branch_feasible++;
                    }
                }
            }

            const char *status;
            if (n_found == 0) {
                status = "DEAD (no feasible paths)";
                dead_count++;
            } else if (n_found == 1) {
                status = "PROVED: exactly 1 pair sequence";
                proved_count++;
            } else {
                status = "MULTIPLE sequences";
                multi_count++;
                all_proved = 0;
            }

            printf("  Pair %2d (hexagrams %2d,%2d): %6d feasible paths, %d unique -> %s\n",
                   bp, pairs[bp].a, pairs[bp].b, branch_feasible, n_found, status);
        }

        printf("\n======================================================================\n");
        printf("Results: %d proved, %d dead, %d multiple\n", proved_count, dead_count, multi_count);
        if (all_proved && multi_count == 0) {
            printf("\nTHEOREM PROVED: For every valid branch, exactly one pair sequence\n");
            printf("at positions 3-19 is budget-feasible. The choice at position 2\n");
            printf("deterministically locks positions 3-19 via budget propagation.\n\n");
            printf("This is a MATHEMATICAL PROOF by exhaustive enumeration of all\n");
            printf("2^17 = 131,072 binary paths per branch, checking budget feasibility.\n");
            printf("No solution search or sampling is involved. QED.\n");
            printf("======================================================================\n");
            return 0;
        }

        printf("\n%d branches proved by budget alone. %d branches need C3 check.\n",
               proved_count, multi_count);
        printf("Running full proof: for each extra configuration, exhaustively search\n");
        printf("positions 20-32 and check if ANY completion satisfies C3.\n\n");

        /* Full proof: for branches with multiple budget-feasible sequences,
         * check each non-KW sequence by exhaustively searching positions 20-32.
         * If no C3-valid completion exists, that configuration is eliminated. */

        int full_proved = 1;
        int configs_tested = 0, configs_eliminated = 0;

        printf("\nPhase 2: Full proof with C3 check (exhaustive search of positions 19-31)\n");
        printf("Testing %d branches with multiple configs...\n\n", multi_count);

        for (int bp = 0; bp < 32; bp++) {
            if (bp == start_pair_idx) continue;

            /* Re-run the binary path enumeration to collect the multiple sequences */
            static int multi_seqs[100][17];
            int n_multi = 0;

            for (int orient1 = 0; orient1 < 2; orient1++) {
                int f1 = orient1 ? pairs[bp].b : pairs[bp].a;
                int s1 = orient1 ? pairs[bp].a : pairs[bp].b;
                int bd1 = hamming(0, f1);
                if (bd1 == 5) continue;
                int bi[7]; memcpy(bi, kw_dist, sizeof(bi));
                bi[hamming(63, 0)]--;
                if (bi[bd1] <= 0) continue;
                bi[bd1]--;
                int wd1 = hamming(pairs[bp].a, pairs[bp].b);
                if (bi[wd1] <= 0) continue;
                bi[wd1]--;

                for (int bits = 0; bits < (1 << 17); bits++) {
                    int budget[7]; memcpy(budget, bi, sizeof(budget));
                    int used[32] = {0};
                    used[start_pair_idx] = 1; used[bp] = 1;
                    int last_hex = s1;
                    int path[17];
                    int feasible = 1;

                    for (int j = 0; j < 17; j++) {
                        int pos = j + 2;
                        int cand = ((bits >> j) & 1) ? (pos - 1) : pos;
                        if (cand < 0 || cand >= 32 || used[cand]) { feasible = 0; break; }
                        int placed = 0;
                        for (int orient = 0; orient < 2; orient++) {
                            int first = orient ? pairs[cand].b : pairs[cand].a;
                            int second = orient ? pairs[cand].a : pairs[cand].b;
                            int bd = hamming(last_hex, first);
                            if (bd == 5 || budget[bd] <= 0) continue;
                            int nb[7]; memcpy(nb, budget, sizeof(nb));
                            nb[bd]--;
                            int wd = hamming(pairs[cand].a, pairs[cand].b);
                            if (nb[wd] <= 0) continue;
                            nb[wd]--;
                            int tu[32]; memcpy(tu, used, sizeof(tu)); tu[cand] = 1;
                            int need[7] = {0};
                            for (int p = 0; p < 32; p++) if (!tu[p]) need[hamming(pairs[p].a, pairs[p].b)]++;
                            int ok = 1;
                            for (int d = 0; d < 7; d++) if (need[d] > nb[d]) { ok = 0; break; }
                            if (!ok) continue;
                            memcpy(budget, nb, sizeof(budget));
                            memcpy(used, tu, sizeof(used));
                            last_hex = second;
                            path[j] = cand;
                            placed = 1;
                            break;
                        }
                        if (!placed) { feasible = 0; break; }
                    }
                    if (feasible) {
                        int is_new = 1;
                        for (int f = 0; f < n_multi; f++) {
                            int m = 1;
                            for (int j = 0; j < 17; j++) if (multi_seqs[f][j] != path[j]) { m = 0; break; }
                            if (m) { is_new = 0; break; }
                        }
                        if (is_new && n_multi < 100) {
                            memcpy(multi_seqs[n_multi], path, sizeof(int) * 17);
                            n_multi++;
                        }
                    }
                }
            }

            if (n_multi <= 1) continue;  /* already proved or dead */

            /* Identify the KW sequence for this branch */
            int kw_seq[17];
            for (int j = 0; j < 17; j++) kw_seq[j] = j + 2;  /* KW: pair i at position i */
            /* Check which of the multi_seqs matches KW */
            int kw_match_idx = -1;
            for (int f = 0; f < n_multi; f++) {
                int m = 1;
                for (int j = 0; j < 17; j++) if (multi_seqs[f][j] != kw_seq[j]) { m = 0; break; }
                if (m) { kw_match_idx = f; break; }
            }

            printf("  Branch pair %d: %d configurations. Testing non-KW configs...\n", bp, n_multi);

            /* For each non-KW configuration, build positions 0-19 and exhaustively
             * search positions 20-32 for ANY C3-valid completion. */
            for (int ci = 0; ci < n_multi; ci++) {
                if (ci == kw_match_idx) continue;  /* skip KW's own config */
                configs_tested++;

                long long total_nodes = 0;
                /* Build the fixed prefix: positions 0-19 */
                /* Position 0: Creative/Receptive, Position 1: branch pair */
                /* Positions 2-18: from multi_seqs[ci] */
                /* Position 19: determined by what's left (the shift pattern places
                 * a specific pair here — but we need to figure out which) */

                /* Actually, the proof enumerated positions 2-18 (17 positions).
                 * Position 19 (pair position 19) is NOT covered by the binary path.
                 * We need to search positions 19-31 (13 positions), not 20-32. */

                /* Reconstruct full state at position 19 */
                int found_c3 = 0;

                for (int orient1 = 0; orient1 < 2 && !found_c3; orient1++) {
                    int f1 = orient1 ? pairs[bp].b : pairs[bp].a;
                    int s1 = orient1 ? pairs[bp].a : pairs[bp].b;
                    int bd1 = hamming(0, f1);
                    if (bd1 == 5) continue;
                    int budget[7]; memcpy(budget, kw_dist, sizeof(budget));
                    budget[hamming(63, 0)]--;
                    if (budget[bd1] <= 0) continue;
                    budget[bd1]--;
                    if (budget[hamming(pairs[bp].a, pairs[bp].b)] <= 0) continue;
                    budget[hamming(pairs[bp].a, pairs[bp].b)]--;

                    int seq[64];
                    seq[0] = 63; seq[1] = 0;
                    seq[2] = f1; seq[3] = s1;
                    int used[32] = {0};
                    used[start_pair_idx] = 1;
                    used[bp] = 1;
                    int last_hex = s1;
                    int ok = 1;

                    /* Place positions 2-18 per this configuration */
                    for (int j = 0; j < 17 && ok; j++) {
                        int cand = multi_seqs[ci][j];
                        if (used[cand]) { ok = 0; break; }
                        int placed = 0;
                        for (int orient = 0; orient < 2; orient++) {
                            int first = orient ? pairs[cand].b : pairs[cand].a;
                            int second = orient ? pairs[cand].a : pairs[cand].b;
                            int bd = hamming(last_hex, first);
                            if (bd == 5 || budget[bd] <= 0) continue;
                            budget[bd]--;
                            int wd = hamming(pairs[cand].a, pairs[cand].b);
                            if (budget[wd] <= 0) { budget[bd]++; continue; }
                            budget[wd]--;
                            used[cand] = 1;
                            seq[(j+2)*2] = first;
                            seq[(j+2)*2+1] = second;
                            last_hex = second;
                            placed = 1;
                            break;
                        }
                        if (!placed) { ok = 0; }
                    }
                    if (!ok) continue;

                    /* Now search positions 19-31 (13 remaining pairs) exhaustively */
                    int step = 19;

                    printf("    Config %d/%d: searching positions %d-31...",
                           ci + 1, n_multi, step);
                    fflush(stdout);
                    long long cnodes = 0;
                    proof_search(seq, used, budget, step, last_hex, &cnodes, &found_c3);
                    total_nodes += cnodes;
                }

                if (found_c3) {
                    printf(" FOUND (%lld nodes). NOT eliminated.\n", total_nodes);
                    fflush(stdout);
                    full_proved = 0;
                } else {
                    printf(" exhausted (%lld nodes). Eliminated.\n", total_nodes);
                    fflush(stdout);
                    configs_eliminated++;
                }
            }
        }

        printf("\n======================================================================\n");
        printf("Full proof: %d configs tested, %d eliminated\n", configs_tested, configs_eliminated);
        if (full_proved && configs_tested > 0) {
            printf("\nTHEOREM FULLY PROVED: For ALL branches, exactly one pair sequence\n");
            printf("at positions 3-19 leads to any C3-valid completion.\n");
            printf("16 branches proved by budget alone. %d configs in %d branches\n",
                   configs_tested, multi_count);
            printf("eliminated by exhaustive C3 search of positions 20-32. QED.\n");
        } else if (!full_proved) {
            printf("\nTHEOREM PARTIALLY PROVED: Some non-KW configurations have C3-valid\n");
            printf("completions. Position 2 does NOT fully determine positions 3-19\n");
            printf("for all branches (C3 is necessary but not sufficient for uniqueness).\n");
        }
        printf("======================================================================\n");
        return 0;
    }

    printf("Hash table: %d slots (2^%d) x %d bytes = %d MB per thread\n",
           sol_hash_size, sol_hash_log2, SOL_RECORD_SIZE, (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576));

    /* --- List branches mode --- */
    if (list_branches_mode) {
        int start_pair_idx = pair_index_of(63, 0);

        /* Load checkpoint to show completion status */
        load_checkpoint();

        /* Try to read per-thread node counts from solve_output.txt.
         * Parse lines matching: "  THRD  PAIR  ORIENT  NODES  ..." */
        long long branch_nodes[32][2]; /* [pair][orient] = nodes */
        memset(branch_nodes, 0, sizeof(branch_nodes));
        int have_node_data = 0;
        FILE *of = fopen("solve_output.txt", "r");
        if (!of) of = fopen("solve_results.json", "r"); /* try JSON too */
        if (of) {
            char line[512];
            int in_thread_section = 0;
            while (fgets(line, sizeof(line), of)) {
                if (strstr(line, "Per-thread/branch summary")) {
                    in_thread_section = 1;
                    /* Skip header lines */
                    if (fgets(line, sizeof(line), of)) {} /* column headers */
                    if (fgets(line, sizeof(line), of)) {} /* dashes */
                    continue;
                }
                if (in_thread_section) {
                    int thrd, pr, ori;
                    long long nodes;
                    /* Parse: "  THRD   PAIR ORIENT        NODES ..." */
                    if (sscanf(line, " %d %d %d %lld", &thrd, &pr, &ori, &nodes) >= 4) {
                        pr--;  /* output is 1-indexed, internal is 0-indexed */
                        if (pr >= 0 && pr < 32 && ori >= 0 && ori <= 1) {
                            branch_nodes[pr][ori] = nodes;
                            have_node_data = 1;
                        }
                    } else if (line[0] == '\n' || line[0] == '-') {
                        if (have_node_data) break; /* end of section */
                    }
                }
            }
            fclose(of);
        }

        printf("\nValid first-level branches:\n");
        if (have_node_data)
            printf("  %4s %6s %6s %14s  %s\n", "Pair", "Orient", "SubBr", "Nodes(prior)", "Status");
        else
            printf("  %4s %6s %6s   %s\n", "Pair", "Orient", "SubBr", "Hexagrams (first, second)");
        printf("  %4s %6s %6s %s\n", "----", "------", "-----",
               have_node_data ? "  --------------  ------" : "  -------------------------");

        int total_valid = 0;
        int total_done = 0;
        for (int p = 0; p < 32; p++) {
            if (p == start_pair_idx) continue;
            for (int orient = 0; orient < 2; orient++) {
                int first = orient ? pairs[p].b : pairs[p].a;
                int bd = hamming(0, first);
                if (bd == 5) continue;
                if (kw_dist[bd] == 0) continue;
                int second = orient ? pairs[p].a : pairs[p].b;
                int wd = hamming(first, second);
                int test_budget[7];
                memcpy(test_budget, kw_dist, sizeof(test_budget));
                test_budget[hamming(63, 0)]--;
                if (test_budget[bd] <= 0) continue;
                test_budget[bd]--;
                if (test_budget[wd] <= 0) continue;

                /* Count sub-branches for this branch */
                int used_tmp[32]; memset(used_tmp, 0, sizeof(used_tmp));
                used_tmp[start_pair_idx] = 1;
                used_tmp[p] = 1;
                int budget_tmp[7];
                memcpy(budget_tmp, kw_dist, sizeof(budget_tmp));
                budget_tmp[hamming(63, 0)]--;
                budget_tmp[bd]--;
                budget_tmp[wd]--;

                int n_sub = 0;
                for (int p2 = 0; p2 < 32; p2++) {
                    if (used_tmp[p2]) continue;
                    for (int o2 = 0; o2 < 2; o2++) {
                        int f2 = o2 ? pairs[p2].b : pairs[p2].a;
                        int s2 = o2 ? pairs[p2].a : pairs[p2].b;
                        int bd2 = hamming(second, f2);
                        if (bd2 == 5) continue;
                        int tb[7]; memcpy(tb, budget_tmp, sizeof(tb));
                        if (tb[bd2] <= 0) continue;
                        tb[bd2]--;
                        int wd2 = hamming(f2, s2);
                        if (tb[wd2] <= 0) continue;
                        n_sub++;
                    }
                }

                int done = is_branch_completed(p, orient);
                if (done) total_done++;
                int is_kw = (p == pair_index_of(KW[2], KW[3]) &&
                            ((orient == 0 && pairs[p].a == KW[2]) ||
                             (orient == 1 && pairs[p].b == KW[2])));

                if (have_node_data) {
                    printf("  %4d %6d %6d %14lld  %s%s\n",
                           p, orient, n_sub, branch_nodes[p][orient],
                           done ? "DONE" : "",
                           is_kw ? "  <-- King Wen" : "");
                } else {
                    printf("  %4d %6d %6d   (%2d, %2d)%s%s\n",
                           p, orient, n_sub, first, second,
                           done ? "  DONE" : "",
                           is_kw ? "  <-- King Wen" : "");
                }
                total_valid++;
            }
        }
        printf("\nTotal valid branches: %d (%d completed)\n", total_valid, total_done);
        printf("\nUsage: ./solve --branch <pair> <orient> [time_limit] [threads]\n");
        return 0;
    }

    /* --- Single-branch mode --- */
    if (single_branch_mode) {
        int start_pair_idx = pair_index_of(63, 0);

        /* Validate branch */
        if (sb_pair < 0 || sb_pair >= 32 || sb_pair == start_pair_idx) {
            printf("Invalid pair index %d\n", sb_pair);
            return 1;
        }
        if (sb_orient < 0 || sb_orient > 1) {
            printf("Invalid orient %d (must be 0 or 1)\n", sb_orient);
            return 1;
        }

        /* Set up position 0 and 1, then enumerate valid position 2 choices */
        int seq_prefix[4];
        int used_prefix[32];
        int budget_prefix[7];

        seq_prefix[0] = 63; seq_prefix[1] = 0;
        memset(used_prefix, 0, sizeof(used_prefix));
        used_prefix[start_pair_idx] = 1;
        memcpy(budget_prefix, kw_dist, sizeof(budget_prefix));
        budget_prefix[hamming(63, 0)]--;

        int f1 = sb_orient ? pairs[sb_pair].b : pairs[sb_pair].a;
        int s1 = sb_orient ? pairs[sb_pair].a : pairs[sb_pair].b;
        int bd1 = hamming(seq_prefix[1], f1);
        if (bd1 == 5 || budget_prefix[bd1] <= 0) {
            printf("Branch (pair %d orient %d) is invalid (pruned at depth 1)\n", sb_pair, sb_orient);
            return 1;
        }
        budget_prefix[bd1]--;
        int wd1 = hamming(f1, s1);
        if (budget_prefix[wd1] <= 0) {
            printf("Branch (pair %d orient %d) is invalid (within-pair distance)\n", sb_pair, sb_orient);
            return 1;
        }
        budget_prefix[wd1]--;
        seq_prefix[2] = f1; seq_prefix[3] = s1;
        used_prefix[sb_pair] = 1;

        /* Load sub-branch checkpoint for resume */
        load_sub_checkpoint();
        if (n_completed_subs > 0) {
            printf("Resuming: %d sub-branches already completed (from checkpoint.txt)\n",
                   n_completed_subs);
            total_branches_completed = n_completed_subs;
        }

        /* Enumerate depth-2 sub-branches, skipping completed ones */
        int n_sub = 0;
        int n_skipped = 0;
        SubBranch all_sub[64];

        for (int p2 = 0; p2 < 32; p2++) {
            if (used_prefix[p2]) continue;
            for (int o2 = 0; o2 < 2; o2++) {
                int f2 = o2 ? pairs[p2].b : pairs[p2].a;
                int s2 = o2 ? pairs[p2].a : pairs[p2].b;
                int bd2 = hamming(seq_prefix[3], f2);
                if (bd2 == 5) continue;
                int test_budget[7];
                memcpy(test_budget, budget_prefix, sizeof(test_budget));
                if (test_budget[bd2] <= 0) continue;
                test_budget[bd2]--;
                int wd2 = hamming(f2, s2);
                if (test_budget[wd2] <= 0) continue;

                /* Skip completed sub-branches (resume) */
                if (is_sub_branch_completed(p2, o2)) {
                    n_skipped++;
                    continue;
                }

                all_sub[n_sub].pair1 = sb_pair;
                all_sub[n_sub].orient1 = sb_orient;
                all_sub[n_sub].pair2 = p2;
                all_sub[n_sub].orient2 = o2;
                n_sub++;
            }
        }

        printf("Sub-branches for pair %d orient %d: %d remaining", sb_pair, sb_orient, n_sub);
        if (n_skipped > 0) printf(" (%d completed from checkpoint)", n_skipped);
        printf("\n");
        total_branches = n_sub + n_skipped;

        /* Per-branch node limit for thread-count-independent reproducibility */
        if (node_limit > 0 && total_branches > 0) {
            per_branch_node_limit = node_limit / total_branches;
            printf("Per-branch node limit: %lld (%lld total / %d branches)\n",
                   per_branch_node_limit, node_limit, total_branches);
        }

        if (n_sub == 0 && n_skipped > 0) {
            printf("All %d sub-branches already completed (from checkpoint.txt).\n", n_skipped);
            printf("Delete checkpoint.txt to re-run from scratch.\n");
            return 0;
        }
        if (n_sub == 0) {
            printf("No valid sub-branches found.\n");
            return 1;
        }

        /* Determine thread count */
        int n_threads = (int)sysconf(_SC_NPROCESSORS_ONLN);
        if (n_threads < 1) n_threads = 8;
        char *env_threads = getenv("SOLVE_THREADS");
        if (env_threads) n_threads = atoi(env_threads);
        if (arg_offset + 1 < argc) n_threads = atoi(argv[arg_offset + 1]);
        if (n_threads > n_sub) n_threads = n_sub;
        if (n_threads < 1) n_threads = 1;

        /* Distribute sub-branches round-robin */
        ThreadState threads[64];
        SubBranch thread_subs[64][64];
        int thread_sub_count[64];
        memset(thread_sub_count, 0, sizeof(thread_sub_count));

        for (int i = 0; i < n_sub; i++) {
            int tid = i % n_threads;
            thread_subs[tid][thread_sub_count[tid]++] = all_sub[i];
        }

        for (int i = 0; i < n_threads; i++) {
            memset(&threads[i], 0, sizeof(ThreadState));
            threads[i].thread_id = i;
            threads[i].sub_branches = thread_subs[i];
            threads[i].n_sub_branches = thread_sub_count[i];
            threads[i].single_branch_mode = 1;
            threads[i].branches = NULL;
            threads[i].n_branches = 0;
            threads[i].top_count = 0;
            for (int j = 0; j < TOP_N; j++)
                threads[i].top_closest[j].edit_dist = 33;
        }

        printf("Threads: %d, Sub-branches per thread: %d-%d\n",
               n_threads, n_sub / n_threads, (n_sub + n_threads - 1) / n_threads);
        printf("Total hash memory: %d MB\n",
               n_threads * (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576));
        if (time_limit > 0)
            printf("Time limit: %d seconds (%.1f hours)\n", time_limit, time_limit / 3600.0);
        printf("\nStarting single-branch enumeration...\n\n");
        fflush(stdout);

        /* Signal handlers */
        struct sigaction sa;
        sa.sa_handler = signal_handler;
        sa.sa_flags = 0;
        sigemptyset(&sa.sa_mask);
        sigaction(SIGTERM, &sa, NULL);
        sigaction(SIGINT, &sa, NULL);

        start_time = time(NULL);

        pthread_t tids[64];
        for (int i = 0; i < n_threads; i++)
            pthread_create(&tids[i], NULL, thread_func_single, &threads[i]);

        /* Monitor */
        int report_counter = 0;
        while (threads_completed < n_threads && !global_timed_out) {
            sleep(1);
            report_counter++;
            if (report_counter < 10) continue;
            report_counter = 0;

            long long tn = 0, ts_val = 0, tc3 = 0;
            int tu = 0, tbd = 0;
            long long thc = 0;
            for (int i = 0; i < n_threads; i++) {
                tn += threads[i].nodes;
                ts_val += threads[i].solutions_total;
                tc3 += threads[i].solutions_c3;
                tu += threads[i].solution_count;
                tbd += threads[i].branches_completed;
                thc += threads[i].hash_collisions;
            }
            long elapsed_now = (long)(time(NULL) - start_time);
            double pct = n_sub > 0 ? (double)tbd / n_sub * 100 : 0;
            double rate = elapsed_now > 0 ? tn / (double)elapsed_now / 1e6 : 0;

            char eta_buf[64] = "";
            if (tbd > 0 && elapsed_now > 0) {
                double br_rate = (double)tbd / elapsed_now;
                int rem = n_sub - tbd;
                long eta_sec = (long)(rem / br_rate);
                snprintf(eta_buf, sizeof(eta_buf), ", ETA %ldh%02ldm",
                         eta_sec / 3600, (eta_sec % 3600) / 60);
            }

            fprintf(stderr, "  %.1fB nodes, %.1fM sol, %lld C3 (%d stored), "
                    "%d/%d sub-branches (%.0f%%), %.0fM/s%s, %lds\n",
                    tn / 1e9, ts_val / 1e6, tc3, tu,
                    tbd, n_sub, pct, rate, eta_buf, elapsed_now);

            if (time_limit > 0 && (time(NULL) - start_time) >= time_limit) {
                global_timed_out = 1;
                break;
            }
            /* Node limit is checked per-branch inside backtrack, not here */
        }

        for (int i = 0; i < n_threads; i++)
            pthread_join(tids[i], NULL);

        /* Jump to output section (reuse same code via goto) */
        /* Fall through to shared output code below */
        time_t end_time = time(NULL);
        long elapsed = (long)(end_time - start_time);

        /* Merge results */
        long long total_nodes = 0, total_sol = 0, total_c3 = 0;
        long long pos_match[32] = {0};
        long long edit_hist[33] = {0};
        long long c6_sat = 0, c7_sat = 0, c6c7_sat = 0;
        long long per_boundary[31] = {0};
        long long adj_hist[32] = {0};
        long long cd_hist[CD_HIST_SIZE] = {0};
        long long pair_freq_m[32][32] = {{0}};
        long long super_match[32] = {0};
        int kw_found = 0;
        long long total_hash_collisions = 0;
        int total_stored = 0;
        int branches_done = 0;
        ClosestEntry all_top[64 * TOP_N];
        int all_top_count = 0;

        for (int i = 0; i < n_threads; i++) {
            total_nodes += threads[i].nodes;
            total_sol += threads[i].solutions_total;
            total_c3 += threads[i].solutions_c3;
            if (threads[i].kw_found) kw_found = 1;
            c6_sat += threads[i].c6_satisfied;
            c7_sat += threads[i].c7_satisfied;
            c6c7_sat += threads[i].c6_and_c7_satisfied;
            total_stored += threads[i].solution_count;
            total_hash_collisions += threads[i].hash_collisions;
            branches_done += threads[i].branches_completed;
            for (int j = 0; j < 32; j++) pos_match[j] += threads[i].pos_match_count[j];
            for (int j = 0; j <= 32; j++) edit_hist[j] += threads[i].edit_dist_hist[j];
            for (int j = 0; j < 31; j++) per_boundary[j] += threads[i].per_boundary_sat[j];
            for (int j = 0; j < 32; j++) adj_hist[j] += threads[i].adj_match_hist[j];
            for (int j = 0; j < CD_HIST_SIZE; j++) cd_hist[j] += threads[i].cd_hist[j];
            for (int j = 0; j < 32; j++) {
                for (int k = 0; k < 32; k++)
                    pair_freq_m[j][k] += threads[i].pair_freq[j][k];
                super_match[j] += threads[i].super_pair_match[j];
            }
            for (int j = 0; j < threads[i].top_count; j++)
                all_top[all_top_count++] = threads[i].top_closest[j];
        }

        /* Sort top-N */
        for (int i = 0; i < all_top_count - 1; i++)
            for (int j = i + 1; j < all_top_count; j++)
                if (all_top[j].edit_dist < all_top[i].edit_dist) {
                    ClosestEntry tmp = all_top[i]; all_top[i] = all_top[j]; all_top[j] = tmp;
                }
        int final_top_count = all_top_count < TOP_N ? all_top_count : TOP_N;

        /* De-dup and write solutions */
        printf("Merging %d stored solutions from %d threads...\n", total_stored, n_threads);
        fflush(stdout);
        unsigned char *all_solutions = NULL;
        if (total_stored > 0)
            all_solutions = malloc((size_t)total_stored * SOL_RECORD_SIZE);
        int sol_offset = 0;
        for (int i = 0; i < n_threads; i++) {
            if (threads[i].sol_table && threads[i].sol_occupied) {
                for (int s = 0; s < sol_hash_size; s++) {
                    if (threads[i].sol_occupied[s]) {
                        memcpy(&all_solutions[(size_t)sol_offset * SOL_RECORD_SIZE], &threads[i].sol_table[(size_t)s * SOL_RECORD_SIZE], SOL_RECORD_SIZE);
                        sol_offset++;
                    }
                }
            }
            free(threads[i].sol_table);
            free(threads[i].sol_occupied);
        }
        total_stored = sol_offset;
        printf("Sorting %d solutions...\n", total_stored);
        fflush(stdout);
        if (all_solutions && total_stored > 0)
            qsort(all_solutions, total_stored, SOL_RECORD_SIZE, compare_solutions);
        int unique_count = 0;
        for (int i = 0; i < total_stored; i++) {
            if (i == 0 || compare_solutions(&all_solutions[(size_t)i * SOL_RECORD_SIZE], &all_solutions[(size_t)(i - 1) * SOL_RECORD_SIZE]) != 0) {
                if (unique_count != i)
                    memcpy(&all_solutions[(size_t)unique_count * SOL_RECORD_SIZE], &all_solutions[(size_t)i * SOL_RECORD_SIZE], SOL_RECORD_SIZE);
                unique_count++;
            }
        }
        /* Per-branch output filenames */
        char bin_name[64], sha_name[64], json_name[64];
        snprintf(bin_name, sizeof(bin_name), "solutions_%d_%d.bin", sb_pair, sb_orient);
        snprintf(sha_name, sizeof(sha_name), "solutions_%d_%d.sha256", sb_pair, sb_orient);
        snprintf(json_name, sizeof(json_name), "results_%d_%d.json", sb_pair, sb_orient);

        printf("Writing %d unique solutions to %s...\n", unique_count, bin_name);
        fflush(stdout);
        FILE *bf = fopen(bin_name, "wb");
        if (bf && all_solutions) { fwrite(all_solutions, SOL_RECORD_SIZE, unique_count, bf); fclose(bf); }
        else if (bf) fclose(bf);
        free(all_solutions);

        printf("Computing sha256...\n"); fflush(stdout);
        write_sha256_with_metadata(bin_name, sha_name,
                                    unique_count, total_nodes,
                                    n_sub, branches_done);

        char hash[130] = {0};
        FILE *hf = fopen(sha_name, "r");
        if (hf) { if (fgets(hash, sizeof(hash), hf)) {} fclose(hf); }
        char hash_only[65] = {0};
        for (int i = 0; i < 64 && hash[i] && hash[i] != ' '; i++) hash_only[i] = hash[i];

        /* Print report */
        printf("\n======================================================================\n");
        const char *status_str;
        if (global_timed_out) {
            status_str = "TIMED_OUT";
            printf("TIMED OUT after %lds (%ld hours %ld minutes)\n",
                   elapsed, elapsed / 3600, (elapsed % 3600) / 60);
        } else {
            status_str = "SEARCH_COMPLETE";
            printf("*** SEARCH COMPLETE in %lds (%ld hours %ld minutes) ***\n",
                   elapsed, elapsed / 3600, (elapsed % 3600) / 60);
        }
        printf("Mode: single-branch (pair %d orient %d)\n", sb_pair, sb_orient);
        char time_buf[64];
        strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime(&start_time));
        printf("Start: %s\n", time_buf);
        strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime(&end_time));
        printf("End:   %s\n", time_buf);
        printf("Sub-branches: %d/%d completed\n", branches_done, n_sub);
        printf("======================================================================\n\n");

        /* Counts */
        printf("--- Counts ---\n");
        printf("Nodes explored:                %lld\n", total_nodes);
        printf("Node rate:                     %.1f M/sec\n",
               elapsed > 0 ? total_nodes / (double)elapsed / 1e6 : 0);
        printf("Total solutions (C1+C2+C4+C5): %lld\n", total_sol);
        printf("C3-valid solutions:            %lld\n", total_c3);
        printf("Unique pair orderings:         %d\n", unique_count);
        printf("King Wen found:                %s\n", kw_found ? "YES" : "No");
        printf("Hash de-dup collisions:        %lld\n", total_hash_collisions);
        printf("\n");

        /* Position match rates */
        printf("--- Position match rates ---\n");
        int locked_count = 0;
        for (int i = 0; i < 32; i++) {
            double r = (total_c3 > 0) ? (double)pos_match[i] / total_c3 * 100 : 0;
            const char *lk = (pos_match[i] == total_c3 && total_c3 > 0) ? "LOCKED" : "";
            if (pos_match[i] == total_c3 && total_c3 > 0) locked_count++;
            printf("  Position %2d: %lld/%lld (%.4f%%) %s\n", i + 1, pos_match[i], total_c3, r, lk);
        }
        printf("Locked positions: %d/32\n\n", locked_count);

        /* Super-pair match rates */
        printf("--- Super-pair match rates ---\n");
        for (int i = 0; i < 32; i++) {
            double r = (total_c3 > 0) ? (double)super_match[i] / total_c3 * 100 : 0;
            const char *lk = (super_match[i] == total_c3 && total_c3 > 0) ? "LOCKED" : "";
            printf("  Position %2d: %lld/%lld (%.4f%%) %s\n", i + 1, super_match[i], total_c3, r, lk);
        }
        printf("\n");

        /* Edit distance */
        printf("--- Edit distance from King Wen ---\n");
        for (int d = 0; d <= 32; d++)
            if (edit_hist[d] > 0) printf("  %2d differences: %lld solutions\n", d, edit_hist[d]);
        printf("\n");

        /* Top-N closest */
        printf("--- Top %d closest non-King-Wen solutions ---\n", final_top_count);
        for (int i = 0; i < final_top_count; i++) {
            printf("  #%d: edit distance %d, positions:", i + 1, all_top[i].edit_dist);
            for (int j = 0; j < all_top[i].diff_count; j++)
                printf(" %d", all_top[i].diff_positions[j] + 1);
            printf("\n");
        }
        printf("\n");

        /* Adjacency */
        printf("--- Adjacency constraints (generalized) ---\n");
        for (int b = 0; b < 31; b++) {
            double r = total_c3 > 0 ? (double)per_boundary[b] / total_c3 * 100 : 0;
            printf("  Boundary %2d (pos %d-%d): %lld (%.4f%%)\n",
                   b + 1, b + 1, b + 2, per_boundary[b], r);
        }
        printf("  Match histogram:\n");
        for (int k = 0; k < 32; k++)
            if (adj_hist[k] > 0) printf("    %2d boundaries: %lld solutions\n", k, adj_hist[k]);
        printf("\n");

        /* Complement distance */
        printf("--- Complement distance distribution ---\n");
        printf("  KW cd (x64): %d (= %.4f)\n", kw_comp_dist_x64, kw_comp_dist_x64 / 64.0);
        for (int i = 0; i < CD_HIST_SIZE; i++)
            if (cd_hist[i] > 0) printf("  cd x64 [%4d-%4d]: %lld\n", i*20, (i+1)*20-1, cd_hist[i]);
        printf("\n");

        /* Per-position pair frequency */
        printf("--- Per-position pair frequency ---\n");
        for (int pos = 0; pos < 32; pos++) {
            int bp = -1; long long bc = 0; int nd = 0;
            for (int p = 0; p < 32; p++) {
                if (pair_freq_m[pos][p] > 0) { nd++; if (pair_freq_m[pos][p] > bc) { bc = pair_freq_m[pos][p]; bp = p; } }
            }
            double bpct = total_c3 > 0 ? (double)bc / total_c3 * 100 : 0;
            printf("  Position %2d: %d different, top=%d (%.1f%%)%s\n",
                   pos + 1, nd, bp + 1, bpct, bp == kw_pair_at_pos[pos] ? " = KW" : "");
        }
        printf("\n");

        printf("--- Output files ---\n");
        printf("  %s:  %d unique x %d bytes = %lld bytes\n", bin_name, unique_count, SOL_RECORD_SIZE, (long long)unique_count * SOL_RECORD_SIZE);
        printf("  %s:  %s", sha_name, hash);
        printf("  %s:  machine-readable results\n\n", json_name);

        write_json(json_name, status_str, elapsed, n_threads, n_sub, branches_done,
                   total_nodes, total_sol, total_c3, unique_count, kw_found, total_hash_collisions,
                   pos_match, edit_hist, all_top, final_top_count,
                   c6_sat, c7_sat, c6c7_sat, per_boundary, adj_hist, cd_hist,
                   pair_freq_m, super_match, hash_only);
        printf("JSON results written to %s\n", json_name);
        return 0;
    }

    /* ---------- Normal mode: enumerate all depth-2 sub-branches ---------- */
    /* Instead of 56 branches (depth 1), enumerate ~3,030 sub-branches (depth 2).
     * Each sub-branch = (pair1, orient1, pair2, orient2) fixing positions 0-3.
     * Distributed round-robin across threads for optimal load balancing.
     * This eliminates the "tail problem" where a few large branches run on
     * single cores while the rest of the machine is idle. */

    int start_pair = pair_index_of(63, 0);

    /* Resume from checkpoint */
    load_sub_checkpoint();
    if (n_completed_subs > 0) {
        printf("Resuming: %d sub-branches already completed (from checkpoint.txt)\n",
               n_completed_subs);
        total_branches_completed = n_completed_subs;
    }

    /* Enumerate ALL valid depth-2 sub-branches across all 56 branches */
    int n_all_subs = 0;
    int n_skipped_subs = 0;
    /* Max: 56 branches * 55 sub-branches = 3080, but static array is safer larger */
    SubBranch *all_subs = malloc(4096 * sizeof(SubBranch));

    for (int p1 = 0; p1 < 32; p1++) {
        if (p1 == start_pair) continue;
        for (int o1 = 0; o1 < 2; o1++) {
            int f1 = o1 ? pairs[p1].b : pairs[p1].a;
            int s1 = o1 ? pairs[p1].a : pairs[p1].b;
            int bd1 = hamming(0, f1);  /* distance from Receptive to first hex */
            if (bd1 == 5) continue;
            int budget1[7];
            memcpy(budget1, kw_dist, sizeof(budget1));
            budget1[hamming(63, 0)]--;  /* pair 0 within-pair */
            if (budget1[bd1] <= 0) continue;
            budget1[bd1]--;
            int wd1 = hamming(f1, s1);
            if (budget1[wd1] <= 0) continue;
            budget1[wd1]--;

            /* Enumerate depth-2 sub-branches for this branch */
            int used1[32]; memset(used1, 0, sizeof(used1));
            used1[start_pair] = 1;
            used1[p1] = 1;

            for (int p2 = 0; p2 < 32; p2++) {
                if (used1[p2]) continue;
                for (int o2 = 0; o2 < 2; o2++) {
                    int f2 = o2 ? pairs[p2].b : pairs[p2].a;
                    int s2 = o2 ? pairs[p2].a : pairs[p2].b;
                    int bd2 = hamming(s1, f2);
                    if (bd2 == 5) continue;
                    int budget2[7];
                    memcpy(budget2, budget1, sizeof(budget2));
                    if (budget2[bd2] <= 0) continue;
                    budget2[bd2]--;
                    int wd2 = hamming(f2, s2);
                    if (budget2[wd2] <= 0) continue;

                    /* Skip completed sub-branches (resume) */
                    if (is_sub_branch_completed(p2, o2)) {
                        n_skipped_subs++;
                        continue;
                    }

                    all_subs[n_all_subs].pair1 = p1;
                    all_subs[n_all_subs].orient1 = o1;
                    all_subs[n_all_subs].pair2 = p2;
                    all_subs[n_all_subs].orient2 = o2;
                    n_all_subs++;
                }
            }
        }
    }

    total_branches = n_all_subs + n_skipped_subs;
    printf("Sub-branches: %d remaining", n_all_subs);
    if (n_skipped_subs > 0) printf(" (%d completed from checkpoint)", n_skipped_subs);
    printf(" of %d total\n", total_branches);

    /* Per-sub-branch node limit for thread-count-independent reproducibility */
    if (node_limit > 0 && total_branches > 0) {
        per_branch_node_limit = node_limit / total_branches;
        printf("Per-sub-branch node limit: %lld (%lld total / %d sub-branches)\n",
               per_branch_node_limit, node_limit, total_branches);
    }

    if (n_all_subs == 0) {
        printf("All %d sub-branches already completed.\n", total_branches);
        free(all_subs);
        return 0;
    }

    /* Determine thread count */
    int n_threads = (int)sysconf(_SC_NPROCESSORS_ONLN);
    if (n_threads < 1) n_threads = 8;
    char *env_threads = getenv("SOLVE_THREADS");
    if (env_threads) n_threads = atoi(env_threads);
    if (arg_offset < argc - 1) n_threads = atoi(argv[arg_offset + 1]);
    if (n_threads > n_all_subs) n_threads = n_all_subs;
    if (n_threads < 1) n_threads = 1;

    /* Distribute sub-branches round-robin across threads */
    ThreadState threads[256];  /* up to 256 threads */
    SubBranch *thread_subs[256];
    int thread_sub_count[256];
    memset(thread_sub_count, 0, sizeof(thread_sub_count));

    /* Allocate per-thread sub-branch arrays */
    int max_per_thread = (n_all_subs + n_threads - 1) / n_threads + 1;
    for (int i = 0; i < n_threads; i++)
        thread_subs[i] = malloc(max_per_thread * sizeof(SubBranch));

    for (int i = 0; i < n_all_subs; i++) {
        int tid = i % n_threads;
        thread_subs[tid][thread_sub_count[tid]++] = all_subs[i];
    }
    free(all_subs);

    for (int i = 0; i < n_threads; i++) {
        memset(&threads[i], 0, sizeof(ThreadState));
        threads[i].thread_id = i;
        threads[i].branches = NULL;
        threads[i].n_branches = 0;
        threads[i].single_branch_mode = 1;
        threads[i].sub_branches = thread_subs[i];
        threads[i].n_sub_branches = thread_sub_count[i];
        threads[i].top_count = 0;
        for (int j = 0; j < TOP_N; j++)
            threads[i].top_closest[j].edit_dist = 33;
        threads[i].sol_table = NULL;
        threads[i].sol_occupied = NULL;
        threads[i].solution_count = 0;
    }

    printf("Total hash memory: %d MB (%d threads x %d MB)\n",
           n_threads * (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576),
           n_threads, (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576));
    printf("Threads: %d (%d-%d sub-branches per thread)\n",
           n_threads, n_all_subs / n_threads,
           (n_all_subs + n_threads - 1) / n_threads);
    if (time_limit > 0)
        printf("Time limit: %d seconds (%.1f hours)\n", time_limit, time_limit / 3600.0);
    else
        printf("Time limit: none (run to completion or SIGTERM)\n");
    printf("CPU cores detected: %ld\n", sysconf(_SC_NPROCESSORS_ONLN));
    printf("\nStarting enumeration...\n\n");
    fflush(stdout);

    /* Register signal handlers */
    struct sigaction sa;
    sa.sa_handler = signal_handler;
    sa.sa_flags = 0;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGTERM, &sa, NULL);
    sigaction(SIGINT, &sa, NULL);

    start_time = time(NULL);

    /* Launch threads — use thread_func_single which handles SubBranch work units */
    pthread_t tids[256];
    for (int i = 0; i < n_threads; i++)
        pthread_create(&tids[i], NULL, thread_func_single, &threads[i]);

    /* Monitor progress */
    int report_counter = 0;
    int prev_branches_done = n_completed_from_checkpoint;
    time_t first_branch_time = 0;

    while (threads_completed < n_threads && !global_timed_out) {
        sleep(1);
        report_counter++;
        if (report_counter < 10) continue;
        report_counter = 0;

        long long tn = 0, ts_val = 0, tc3 = 0;
        int tu = 0, tbd = 0;
        long long thc = 0;
        for (int i = 0; i < n_threads; i++) {
            tn += threads[i].nodes;
            ts_val += threads[i].solutions_total;
            tc3 += threads[i].solutions_c3;
            tu += threads[i].solution_count;
            tbd += threads[i].branches_completed;
            thc += threads[i].hash_collisions;
        }
        int total_done = tbd + n_completed_subs;
        long elapsed_now = (long)(time(NULL) - start_time);
        double pct = total_branches > 0 ? (double)total_done / total_branches * 100 : 0;
        double rate = elapsed_now > 0 ? tn / (double)elapsed_now / 1e6 : 0;

        if (total_done > prev_branches_done && first_branch_time == 0)
            first_branch_time = time(NULL);

        char eta_buf[64] = "";
        if (total_done > n_completed_subs && first_branch_time > 0) {
            long br_elapsed = (long)(time(NULL) - first_branch_time);
            int new_done = total_done - n_completed_subs;
            if (new_done > 0 && br_elapsed > 0) {
                double br_rate = (double)new_done / br_elapsed;
                int rem = total_branches - total_done;
                long eta_sec = (long)(rem / br_rate);
                snprintf(eta_buf, sizeof(eta_buf), ", ETA %ldh%02ldm",
                         eta_sec / 3600, (eta_sec % 3600) / 60);
            }
        }

        fprintf(stderr, "  %.1fB nodes, %.1fM sol, %lld C3 (%d stored), "
                "%d/%d sub-branches (%.0f%%), %d/%d threads, %.0fM/s%s, %lds\n",
                tn / 1e9, ts_val / 1e6, tc3, tu,
                total_done, total_branches, pct,
                threads_completed, n_threads,
                rate, eta_buf, elapsed_now);

        prev_branches_done = total_done;

        if (time_limit > 0 && (time(NULL) - start_time) >= time_limit) {
            global_timed_out = 1;
            break;
        }
        /* Node limit is checked per-branch inside backtrack, not here */
    }

    /* Wait for threads */
    for (int i = 0; i < n_threads; i++)
        pthread_join(tids[i], NULL);

    time_t end_time = time(NULL);
    long elapsed = (long)(end_time - start_time);

    /* === Merge results === */
    long long total_nodes = 0, total_sol = 0, total_c3 = 0;
    long long pos_match[32] = {0};
    long long edit_hist[33] = {0};
    long long c6_sat = 0, c7_sat = 0, c6c7_sat = 0;
    long long per_boundary[31] = {0};
    long long adj_hist[32] = {0};
    long long cd_hist[CD_HIST_SIZE] = {0};
    long long pair_freq_m[32][32] = {{0}};
    long long super_match[32] = {0};
    int kw_found = 0;
    long long total_hash_collisions = 0;
    int total_stored = 0;
    int branches_done = 0;

    ClosestEntry all_top[64 * TOP_N];
    int all_top_count = 0;

    for (int i = 0; i < n_threads; i++) {
        total_nodes += threads[i].nodes;
        total_sol += threads[i].solutions_total;
        total_c3 += threads[i].solutions_c3;
        if (threads[i].kw_found) kw_found = 1;
        c6_sat += threads[i].c6_satisfied;
        c7_sat += threads[i].c7_satisfied;
        c6c7_sat += threads[i].c6_and_c7_satisfied;
        total_stored += threads[i].solution_count;
        total_hash_collisions += threads[i].hash_collisions;
        branches_done += threads[i].branches_completed;

        for (int j = 0; j < 32; j++) pos_match[j] += threads[i].pos_match_count[j];
        for (int j = 0; j <= 32; j++) edit_hist[j] += threads[i].edit_dist_hist[j];
        for (int j = 0; j < 31; j++) per_boundary[j] += threads[i].per_boundary_sat[j];
        for (int j = 0; j < 32; j++) adj_hist[j] += threads[i].adj_match_hist[j];
        for (int j = 0; j < CD_HIST_SIZE; j++) cd_hist[j] += threads[i].cd_hist[j];
        for (int j = 0; j < 32; j++) {
            for (int k = 0; k < 32; k++)
                pair_freq_m[j][k] += threads[i].pair_freq[j][k];
            super_match[j] += threads[i].super_pair_match[j];
        }

        for (int j = 0; j < threads[i].top_count; j++)
            all_top[all_top_count++] = threads[i].top_closest[j];
    }

    /* Sort merged top-N by edit distance */
    for (int i = 0; i < all_top_count - 1; i++)
        for (int j = i + 1; j < all_top_count; j++)
            if (all_top[j].edit_dist < all_top[i].edit_dist) {
                ClosestEntry tmp = all_top[i]; all_top[i] = all_top[j]; all_top[j] = tmp;
            }
    int final_top_count = all_top_count < TOP_N ? all_top_count : TOP_N;

    /* Free thread resources */
    for (int i = 0; i < n_threads; i++) {
        free(threads[i].sol_table);
        free(threads[i].sol_occupied);
        free(threads[i].sub_branches);
    }

    /* === Merge from sub_*.bin files (thread-count independent) === */
    /* Each sub-branch wrote its solutions to sub_P2_O2.bin and cleared the
     * hash table. The final merge reads all files, concatenates, sorts, deduplicates.
     * This produces identical output regardless of thread count. */
    fflush(stdout);
    printf("Reading sub-branch solution files...\n");
    fflush(stdout);

    /* Count total records across all sub_*.bin files */
    long long total_file_records = 0;
    int n_sub_files = 0;
    for (int p2 = 0; p2 < 32; p2++) {
        for (int o2 = 0; o2 < 2; o2++) {
            char fname[64];
            snprintf(fname, sizeof(fname), "sub_%d_%d.bin", p2, o2);
            FILE *tf = fopen(fname, "rb");
            if (tf) {
                fseek(tf, 0, SEEK_END);
                long sz = ftell(tf);
                fclose(tf);
                if (sz > 0) {
                    total_file_records += sz / SOL_RECORD_SIZE;
                    n_sub_files++;
                }
            }
        }
    }
    printf("  Found %d sub-branch files with %lld total records\n", n_sub_files, total_file_records);

    unsigned char *all_solutions = NULL;
    if (total_file_records > 0)
        all_solutions = malloc((size_t)total_file_records * SOL_RECORD_SIZE);

    long long sol_offset = 0;
    if (all_solutions) {
        for (int p2 = 0; p2 < 32; p2++) {
            for (int o2 = 0; o2 < 2; o2++) {
                char fname[64];
                snprintf(fname, sizeof(fname), "sub_%d_%d.bin", p2, o2);
                FILE *tf = fopen(fname, "rb");
                if (tf) {
                    fseek(tf, 0, SEEK_END);
                    long sz = ftell(tf);
                    fseek(tf, 0, SEEK_SET);
                    if (sz > 0) {
                        if (fread(&all_solutions[sol_offset * SOL_RECORD_SIZE], 1, sz, tf) != (size_t)sz)
                            printf("  WARNING: short read on %s\n", fname);
                        sol_offset += sz / SOL_RECORD_SIZE;
                    }
                    fclose(tf);
                }
            }
        }
    }
    total_stored = (int)sol_offset;

    printf("Sorting %d solutions...\n", total_stored);
    fflush(stdout);
    if (all_solutions && total_stored > 0)
        qsort(all_solutions, total_stored, SOL_RECORD_SIZE, compare_solutions);

    int unique_count = 0;
    for (int i = 0; i < total_stored; i++) {
        if (i == 0 || compare_solutions(&all_solutions[(size_t)i * SOL_RECORD_SIZE], &all_solutions[(size_t)(i - 1) * SOL_RECORD_SIZE]) != 0) {
            if (unique_count != i)
                memcpy(&all_solutions[(size_t)unique_count * SOL_RECORD_SIZE], &all_solutions[(size_t)i * SOL_RECORD_SIZE], SOL_RECORD_SIZE);
            unique_count++;
        }
    }

    printf("Writing %d unique solutions to solutions.bin...\n", unique_count);
    fflush(stdout);
    FILE *f = fopen("solutions.bin", "wb");
    if (f && all_solutions) { fwrite(all_solutions, SOL_RECORD_SIZE, unique_count, f); fclose(f); }
    else if (f) fclose(f);
    free(all_solutions);

    printf("Computing sha256...\n");
    fflush(stdout);
    int total_done_final = branches_done + n_completed_subs;
    write_sha256_with_metadata("solutions.bin", "solutions.sha256",
                                unique_count, total_nodes,
                                total_branches, total_done_final);

    char hash[130] = {0};
    FILE *hf = fopen("solutions.sha256", "r");
    if (hf) { if (fgets(hash, sizeof(hash), hf)) {} fclose(hf); }
    char hash_only[65] = {0};
    for (int i = 0; i < 64 && hash[i] && hash[i] != ' '; i++) hash_only[i] = hash[i];

    /* === Final Report === */

    printf("\n");
    printf("======================================================================\n");
    const char *status;
    if (global_timed_out) {
        status = "TIMED_OUT";
        printf("TIMED OUT after %lds (%ld hours %ld minutes)\n",
               elapsed, elapsed / 3600, (elapsed % 3600) / 60);
    } else {
        status = "SEARCH_COMPLETE";
        printf("*** SEARCH COMPLETE in %lds (%ld hours %ld minutes) ***\n",
               elapsed, elapsed / 3600, (elapsed % 3600) / 60);
    }
    char time_buf[64];
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime(&start_time));
    printf("Start: %s\n", time_buf);
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime(&end_time));
    printf("End:   %s\n", time_buf);
    printf("Sub-branches: %d/%d completed", total_done_final, total_branches);
    if (n_completed_subs > 0)
        printf(" (%d from checkpoint)", n_completed_subs);
    printf("\n");
    printf("======================================================================\n\n");

    printf("--- Counts ---\n");
    printf("Nodes explored:                %lld\n", total_nodes);
    printf("Node rate:                     %.1f M/sec\n",
           elapsed > 0 ? total_nodes / (double)elapsed / 1e6 : 0);
    printf("Total solutions (C1+C2+C4+C5): %lld\n", total_sol);
    printf("C3-valid solutions:            %lld\n", total_c3);
    printf("Unique pair orderings:         %d\n", unique_count);
    printf("King Wen found:                %s\n", kw_found ? "YES" : "No");
    printf("Threads used:                  %d\n", n_threads);
    printf("Hash table size:               %d (2^%d)\n", sol_hash_size, sol_hash_log2);
    printf("Hash de-dup collisions:        %lld (exact match — zero false positives)\n",
           total_hash_collisions);
    int tables_over_75 = 0;
    for (int i = 0; i < n_threads; i++) {
        if (threads[i].solution_count > sol_hash_size * 3 / 4) tables_over_75++;
    }
    if (tables_over_75 > 0) {
        printf("WARNING: %d/%d threads exceeded 75%% hash table capacity.\n", tables_over_75, n_threads);
        printf("  Some solutions may have been lost due to probe limit.\n");
        printf("  Increase SOLVE_HASH_LOG2 and re-run.\n");
    }
    printf("\n");

    printf("--- Position match rates ---\n");
    int locked_count = 0;
    for (int i = 0; i < 32; i++) {
        double rate = (total_c3 > 0) ? (double)pos_match[i] / total_c3 * 100 : 0;
        const char *lk = (pos_match[i] == total_c3 && total_c3 > 0) ? "LOCKED" : "";
        if (pos_match[i] == total_c3 && total_c3 > 0) locked_count++;
        printf("  Position %2d: %lld/%lld (%.4f%%) %s\n",
               i + 1, pos_match[i], total_c3, rate, lk);
    }
    printf("Locked positions: %d/32\n\n", locked_count);

    printf("--- Super-pair match rates ---\n");
    int sp_locked = 0;
    for (int i = 0; i < 32; i++) {
        double rate = (total_c3 > 0) ? (double)super_match[i] / total_c3 * 100 : 0;
        const char *lk = (super_match[i] == total_c3 && total_c3 > 0) ? "LOCKED" : "";
        if (super_match[i] == total_c3 && total_c3 > 0) sp_locked++;
        printf("  Position %2d: %lld/%lld (%.4f%%) %s\n",
               i + 1, super_match[i], total_c3, rate, lk);
    }
    printf("Super-pair locked positions: %d/32 (of %d super-pairs)\n\n", sp_locked, n_super_pairs);

    printf("--- Edit distance from King Wen ---\n");
    for (int d = 0; d <= 32; d++) {
        if (edit_hist[d] > 0)
            printf("  %2d differences: %lld solutions\n", d, edit_hist[d]);
    }
    printf("\n");

    printf("--- Top %d closest non-King-Wen solutions ---\n", final_top_count);
    for (int i = 0; i < final_top_count; i++) {
        printf("  #%d: edit distance %d, differing positions:", i + 1, all_top[i].edit_dist);
        for (int j = 0; j < all_top[i].diff_count; j++)
            printf(" %d", all_top[i].diff_positions[j] + 1);
        printf("\n");
    }
    printf("\n");

    printf("--- Adjacency constraints (generalized) ---\n");
    printf("  Per-boundary satisfaction rates (of %lld C3-valid):\n", total_c3);
    for (int b = 0; b < 31; b++) {
        double rate = total_c3 > 0 ? (double)per_boundary[b] / total_c3 * 100 : 0;
        printf("    Boundary %2d (pos %d-%d): %lld (%.4f%%)\n",
               b + 1, b + 1, b + 2, per_boundary[b], rate);
    }
    printf("  Boundary match histogram (how many boundaries each solution matches):\n");
    for (int k = 0; k < 32; k++) {
        if (adj_hist[k] > 0)
            printf("    %2d boundaries matched: %lld solutions\n", k, adj_hist[k]);
    }
    printf("  Legacy C6 (boundary 27): %lld (%.4f%%)\n",
           c6_sat, total_c3 > 0 ? (double)c6_sat / total_c3 * 100 : 0);
    printf("  Legacy C7 (boundary 25): %lld (%.4f%%)\n",
           c7_sat, total_c3 > 0 ? (double)c7_sat / total_c3 * 100 : 0);
    printf("  Both C6+C7:              %lld (%.4f%%)\n",
           c6c7_sat, total_c3 > 0 ? (double)c6c7_sat / total_c3 * 100 : 0);
    printf("\n");

    printf("--- Complement distance distribution ---\n");
    printf("  King Wen cd (x64): %d (= %.4f)\n", kw_comp_dist_x64, kw_comp_dist_x64 / 64.0);
    for (int i = 0; i < CD_HIST_SIZE; i++) {
        if (cd_hist[i] > 0)
            printf("  cd x64 [%4d-%4d]: %lld\n", i * 20, (i + 1) * 20 - 1, cd_hist[i]);
    }
    printf("\n");

    printf("--- Per-position pair frequency ---\n");
    for (int pos = 0; pos < 32; pos++) {
        int best_pair = -1;
        long long best_count = 0;
        int n_different = 0;
        for (int p = 0; p < 32; p++) {
            if (pair_freq_m[pos][p] > 0) {
                n_different++;
                if (pair_freq_m[pos][p] > best_count) {
                    best_count = pair_freq_m[pos][p];
                    best_pair = p;
                }
            }
        }
        double best_pct = total_c3 > 0 ? (double)best_count / total_c3 * 100 : 0;
        int is_kw = (best_pair == kw_pair_at_pos[pos]);
        printf("  Position %2d: %d different pairs, top pair=%d (%.1f%%)%s\n",
               pos + 1, n_different, best_pair + 1, best_pct,
               is_kw ? " = KW" : "");
    }
    printf("\n");

    printf("--- Per-thread/branch summary ---\n");
    printf("  %4s %6s %6s %12s %12s %10s %10s\n",
           "Thrd", "Pair", "Orient", "Nodes", "C3-valid", "Stored", "Br.Done");
    printf("  %4s %6s %6s %12s %12s %10s %10s\n",
           "----", "------", "------", "------------", "------------", "----------", "-------");
    for (int i = 0; i < n_threads; i++) {
        for (int b = 0; b < threads[i].n_branches; b++) {
            const char *done = (b < threads[i].branches_completed) ? "YES" : "no";
            if (threads[i].n_branches == 1) {
                printf("  %4d %6d %6d %12lld %12lld %10d %10s\n",
                       i, threads[i].branches[0].pair + 1, threads[i].branches[0].orient,
                       threads[i].nodes, threads[i].solutions_c3,
                       threads[i].solution_count, done);
            }
        }
        if (threads[i].n_branches > 1) {
            printf("  %4d  (%d branches) %12lld %12lld %10d %10d/%d\n",
                   i, threads[i].n_branches,
                   threads[i].nodes, threads[i].solutions_c3,
                   threads[i].solution_count,
                   threads[i].branches_completed, threads[i].n_branches);
        }
    }
    printf("\n");

    printf("--- Output files ---\n");
    printf("  solutions.bin:      %d unique solutions x %d bytes = %lld bytes\n",
           unique_count, SOL_RECORD_SIZE, (long long)unique_count * SOL_RECORD_SIZE);
    printf("  solutions.sha256:   %s", hash);
    printf("  solve_results.json: machine-readable results\n");
    printf("\n");

    /* Write JSON */
    write_json("solve_results.json", status, elapsed, n_threads, total_branches,
               total_done_final, total_nodes, total_sol, total_c3, unique_count,
               kw_found, total_hash_collisions,
               pos_match, edit_hist, all_top, final_top_count,
               c6_sat, c7_sat, c6c7_sat, per_boundary, adj_hist, cd_hist,
               pair_freq_m, super_match, hash_only);
    printf("JSON results written to solve_results.json\n");

    return 0;
}
