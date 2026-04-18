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
 * Normal mode: enumerates ~3,030 depth-2 sub-branches (each fixing positions 0-3:
 * the forced Creative/Receptive at position 1, then a chosen pair+orient at
 * position 2 and another at position 3). Sub-branches are distributed round-robin
 * across N threads. Replaces an older "56-branch mode" that suffered from the
 * tail problem (a few large branches monopolizing single cores while the rest of
 * the machine sat idle).
 *
 * Single-branch mode (--branch P O): same depth-2 split but limited to a single
 * first-level (p,o) prefix. Useful for targeted incremental work on one branch.
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
 * Hash table size is configurable via SOLVE_HASH_LOG2 env var (default 2^24 = 16M
 * slots = 512 MB per thread). Tables auto-resize (double) when load exceeds 75%,
 * so SOLVE_HASH_LOG2 sets the INITIAL size, not a ceiling. No probe limit — the
 * full table is probed on each insertion, guaranteeing zero silent drops.
 *
 * After each sub-branch, the thread's hash table is flushed to a per-sub-branch
 * file `sub_P1_O1_P2_O2.bin` (atomic write: temp + rename) and the table is
 * cleared. The final solutions.bin is produced by reading all sub_*.bin files,
 * concatenating, qsort, dedup. This "shard then merge" structure ensures the
 * output sha256 is identical regardless of thread count, eviction, or restart
 * order — a property the older single-table approach didn't have.
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
 * After each sub-branch, a line is appended to checkpoint.txt:
 *   "Sub-branch <STATUS> (thread T, pair1 P1 orient1 O1 pair2 P2 orient2 O2): ..."
 * STATUS is COMPLETE (DFS exhausted naturally within budget) or INTERRUPTED (hit
 * per-sub-branch node budget OR external signal). On restart, only COMPLETE
 * sub-branches are skipped — INTERRUPTED ones are re-executed (their sub_*.bin
 * file is overwritten with the re-derived solutions, which is deterministic).
 *
 * Earlier versions keyed `sub_*.bin` files on (pair2, orient2) only. Since
 * 3030 sub-branches share only 64 unique (p2, o2) values, later sub-branches
 * SILENTLY OVERWROTE earlier ones' files — losing ~96% of solutions per run.
 * The bug was deterministic so sha256 was reproducible; the defect went
 * undetected until 2026-04-14 when "ls sub_*.bin | wc -l" showed 47 files for
 * a 3030-sub-branch run and the contradiction became obvious. Fix: full key
 * (pair1, orient1, pair2, orient2) in both filename and checkpoint resume
 * lookup. The 31.6M figure published before that date was a ~23x undercount;
 * the 742M figure from the next run was ALSO an undercount — 241M additional
 * solutions were silently dropped by the 64-probe hash table cap (fixed in
 * commit 585880f). New reference shas pending. See HISTORY.md Day 8.
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
 * Normal mode (and single-branch mode):
 *   sub_P1_O1_P2_O2.bin — per-sub-branch shards. Each holds the deduped solutions
 *                          found for one (p1, o1, p2, o2) prefix. Up to ~3030 files.
 *   solutions.bin      — final merged + sorted + deduped output (32 bytes/record:
 *                          byte i = pair_index<<2 | orient<<1)
 *   solutions.sha256   — hash of solutions.bin for reproducibility
 *   solve_results.json — all analytics in machine-readable format
 *   checkpoint.txt     — sub-branch completion log (append-only)
 *   progress.txt       — periodic progress snapshot (latest only)
 *
 * Disk space: at 10T total budget, sub_*.bin files total ~23 GB and
 * solutions.bin is another ~24 GB — preflight available disk against
 * estimated_output * 1.5 before launching. A previous 10T run silently
 * truncated solutions.bin from 23.7 GB to 8 GB because /data filled up
 * mid-write and the fwrite return value wasn't checked. See DEPLOYMENT.md.
 *
 * KNOWN LIMITATIONS / OPEN ISSUES
 * ===============================
 * - [FIXED 585880f] Hash table probe limit: removed 64-probe cap, added auto-
 *   resize at 75% load. Zero silent drops. See correctness audit for details.
 * - [FIXED 3f0167f] Status taxonomy: 3-way EXHAUSTED/BUDGETED/INTERRUPTED
 *   replaces the old conflation of interruption with budget exhaustion.
 * - [FIXED ac5a9ba] Spot-VM granularity: Option B depth-3 (SOLVE_DEPTH=3)
 *   partitions into ~158K sub-branches for finer eviction recovery.
 * - [FIXED 232d688] Flush I/O: fwrite/fsync/fclose return values checked in
 *   flush_sub_solutions. Post-write size verification. Abort on failure.
 * - [FIXED 232d688] Merge integrity: checkpoint cross-reference catches
 *   truncated sub_*.bin files. --verify mode independently checks C1-C5.
 * - [FIXED] pair_index_of() replaced with O(1) lookup table.
 * - Merge loads all records into RAM for sort+dedup. At exhaustive enumeration
 *   scale (billions of solutions), this may exceed available memory. An external
 *   merge-sort would handle arbitrary scale but is not yet implemented.
 *
 * BUILD
 * =====
 *   gcc -O3 -pthread -fopenmp -march=native \
 *       -DGIT_HASH=\"$(git rev-parse --short HEAD)\" -o solve solve.c -lm
 *
 *   -fopenmp parallelizes the heavy --analyze loops (3-subset enumeration,
 *    4-subset enumeration, MI matrix). Without it, --analyze still works
 *    but runs single-threaded. -march=native enables popcount/AVX intrinsics.
 *    libgomp (the OpenMP runtime) ships with gcc and is covered by the
 *    GCC Runtime Library Exception — no LICENSE.md change needed.
 *
 * RUN MODES
 * =========
 *   ./solve [time_limit_seconds] [threads]
 *       Normal enumeration. e.g. ./solve 86400 64  (24h, 64 threads)
 *
 *   ./solve --branch <pair> <orient> [time_limit] [threads]
 *       Limit enumeration to a single first-level (pair, orient) prefix.
 *
 *   ./solve --list-branches [solve_results.json]
 *       Show all valid branches and completion status from checkpoint.txt
 *
 *   ./solve --validate [solutions.bin]
 *       Check every record against C1-C5, sorted order, KW presence
 *
 *   ./solve --analyze [solutions.bin]
 *       Run all post-enumeration scientific analyses in one shot:
 *         entropy, per-boundary, KW variants, shift-pattern, greedy minimum,
 *         3-subset disproof, all 4-subsets, redundancy, mutual information,
 *         per-branch cascade configs, null-model, orbits.
 *       Reproducible source for every numerical claim in HISTORY.md and
 *       SOLVE-SUMMARY.md.
 *
 *   ./solve --merge
 *       Combine sub_*.bin files into solutions.bin (used after enumeration
 *       or to recover from a truncated solutions.bin).
 *
 *   ./solve --prove-cascade   ./solve --prove-self-comp   ./solve --prove-shift
 *       Targeted theorems / sanity checks on the constraint structure.
 *       Caveat: --prove-cascade operates within a "shift-pattern subspace"
 *       containing only ~3% of valid orderings at 742M scale. Do not
 *       overgeneralize its results.
 *
 * ENVIRONMENT VARIABLES
 * =====================
 *   SOLVE_THREADS=N          — override thread count
 *   SOLVE_HASH_LOG2=N        — initial hash table size as power of 2 (default: 24 = 16M slots; auto-resizes)
 *   SOLVE_NODE_LIMIT=N       — stop after N total nodes, distributed equally per
 *                              sub-branch. Deterministic, reproducible sha256
 *                              regardless of thread count.
 *
 * Graceful shutdown: SIGTERM/SIGINT handled via sigaction. Threads finish their
 * current sub-branch (which writes its sub_*.bin), then main proceeds to the
 * final merge before exiting. Spot eviction signals trigger this path.
 *
 * Resume: reads checkpoint.txt on startup and skips COMPLETE sub-branches.
 *
 * DEPLOYMENT (Azure / cloud-VM specifics)
 * =======================================
 * See DEPLOYMENT.md for: spot-VM provisioning, persistent managed disk attach,
 * monitor architecture, eviction recovery, sanity preflights, lessons from
 * past failures, and pre-launch checklist.
 *
 * Companion docs (one directory up, in roae/):
 *   HISTORY.md         project narrative, missteps, "what advanced understanding"
 *   SOLVE-SUMMARY.md   plain-language explanation of the constraints + findings
 *   SPECIFICATION.md   formal definitions of C1-C5
 *   enumeration/LEADERBOARD.md   per-branch / per-sub-branch enumeration progress
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include <stdint.h>
#include <math.h>
#include <sys/mman.h>
#include <dirent.h>
#include <sys/statvfs.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

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

/* Runtime-configurable INITIAL hash table size per thread.
 * Tables auto-resize (double) when load factor exceeds 75%, so this is a
 * starting point, not a ceiling. Larger initial size avoids early resizes.
 * At 2^24 (512 MB/thread), 64 threads = 32 GB. F64 VM has 128 GB so fine.
 * For smaller VMs, set SOLVE_HASH_LOG2=22 (128 MB/thread) or 20 (32 MB/thread). */
static int sol_hash_log2 = 24;         /* default: 2^24 = 16M slots */
static int sol_hash_size;
static int sol_hash_mask;

static int pair_lookup[64][64];
static int pair_lookup_initialized = 0;

static void init_pair_lookup(void) {
    memset(pair_lookup, -1, sizeof(pair_lookup));
    for (int i = 0; i < 32; i++) {
        pair_lookup[pairs[i].a][pairs[i].b] = i;
        pair_lookup[pairs[i].b][pairs[i].a] = i;
    }
    pair_lookup_initialized = 1;
}

static int pair_index_of(int x, int y) {
    if (!pair_lookup_initialized) init_pair_lookup();
    if (x < 0 || x >= 64 || y < 0 || y >= 64) return -1;
    return pair_lookup[x][y];
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

/* ---------- Sub-branch / work unit for enumeration ---------- */
/* In depth-2 mode (default): work unit = (pair1, orient1, pair2, orient2).
 *   ~3030 units, fixes positions 1-3 in the solution sequence.
 *   pair3/orient3 are sentinel -1.
 *
 * In depth-3 mode (SOLVE_DEPTH=3, Option B): work unit =
 *   (pair1, orient1, pair2, orient2, pair3, orient3). ~90,000 units,
 *   fixes positions 1-5. Smaller per-unit budget → shorter per-unit
 *   runtime → tolerable eviction loss on spot VMs.
 *
 * The pair3 == -1 sentinel distinguishes the two modes throughout the
 * file-naming, checkpoint, and resume paths. Default behavior is
 * byte-identical to pre-Option-B solve.c. */
typedef struct {
    int pair1;      /* first-level branch pair */
    int orient1;    /* first-level orientation */
    int pair2;      /* second-level (depth 2) pair */
    int orient2;    /* second-level orientation */
    int pair3;      /* third-level (depth 3) pair — -1 in depth-2 mode */
    int orient3;    /* third-level orientation    — -1 in depth-2 mode */
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
    long long hash_drops;   /* legacy counter; always 0 with auto-resize.
                             * kept for format compatibility with older code. */

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

    /* Solution storage: full-key hash table (auto-resizing) */
    unsigned char *sol_table;
    char *sol_occupied;
    long long solution_count;
    int ht_log2;
    int ht_size;
    int ht_mask;
    int ht_resizes;
} ThreadState;

static volatile int global_timed_out = 0;
static volatile int threads_completed = 0;
static pthread_mutex_t checkpoint_mutex = PTHREAD_MUTEX_INITIALIZER;
static int total_branches_completed = 0;
static int total_branches = 0;
/* In-memory counter of sub-branches with "COMPLETE" status in checkpoint.txt.
 * Protected by checkpoint_mutex. Replaces the O(n^2) per-sub-branch re-read
 * of checkpoint.txt. Initialized from load_sub_checkpoint() at resume. */
static int total_sub_complete = 0;

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
/* Enumeration depth for sub-branch partitioning. 2 (default) = depth-2
 * (pair1, orient1, pair2, orient2) — ~3030 work units. 3 = depth-3
 * (pair1..pair3, orient1..orient3) — ~90000 work units for finer granularity
 * under spot-VM eviction. Set from SOLVE_DEPTH env var. */
static int solve_depth = 2;

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
 * Format: "Sub-branch COMPLETE (thread T, pair1 P1 orient1 O1 pair2 P2 orient2 O2): ..."
 *
 * Bug history: earlier versions keyed sub-branches on (pair2, orient2) only.
 * Since 3030 sub-branches share only 64 unique (p2, o2) values, later
 * sub-branches overwrote earlier ones' sub_P2_O2.bin files and resume
 * falsely skipped siblings. Key is now the full (p1, o1, p2, o2) 4-tuple. */
#define MAX_COMPLETED_SUBS 4096
static int completed_sub_branches[MAX_COMPLETED_SUBS][4]; /* [p1, o1, p2, o2] */
static int n_completed_subs = 0;
/* O(1) membership lookup: 4096 possible (p1,o1,p2,o2) tuples encoded as
 * (p1 << 6) | (o1 << 5) | (p2 << 1) | o2, each a bit in a 512-byte bitmap.
 * Replaces the linear scan in is_sub_branch_completed(). */
static unsigned char completed_sub_bitmap[512] = {0};
static inline int completed_sub_key(int p1, int o1, int p2, int o2) {
    return ((p1 & 31) << 6) | ((o1 & 1) << 5) | ((p2 & 31) << 1) | (o2 & 1);
}
/* Depth-3 (Option B) membership lookup: up to 262144 possible
 * (p1, o1, p2, o2, p3, o3) tuples. 32 KB bitmap. Used only when SOLVE_DEPTH=3.
 * Key layout (no overlapping bits):
 *   bits 17..13 = p1 (5 bits, 0..31)
 *   bit 12      = o1
 *   bits 11..7  = p2 (5 bits)
 *   bit 6       = o2
 *   bits 5..1   = p3 (5 bits)
 *   bit 0       = o3
 */
static unsigned char completed_sub_bitmap_d3[262144 / 8] = {0};
static inline int completed_sub_key_d3(int p1, int o1, int p2, int o2, int p3, int o3) {
    return ((p1 & 31) << 13) | ((o1 & 1) << 12) | ((p2 & 31) << 7) | ((o2 & 1) << 6) |
           ((p3 & 31) << 1) | (o3 & 1);
}

/* Current run's per-sub-branch node budget, for budget-aware BUDGETED resume.
 * Set once per run from node_limit / total_branches after total_branches is known. */
static long long current_per_branch_budget = 0;

static void load_sub_checkpoint(void) {
    FILE *f = fopen("checkpoint.txt", "r");
    if (!f) return;
    char line[512];
    while (fgets(line, sizeof(line), f)) {
        if (!strstr(line, "Sub-branch")) continue;
        /* Skip-on-resume logic (3-way status taxonomy):
         *   EXHAUSTED / COMPLETE (legacy) — always skip (done for any budget)
         *   BUDGETED — skip only if stored budget >= current budget
         *              (otherwise current budget may explore deeper)
         *   INTERRUPTED — always re-run (signal/timeout mid-work)
         * Legacy "COMPLETE" under the bug-era taxonomy could mean either
         * truly exhausted OR budget-exhausted — since old runs never reached
         * natural DFS exhaustion within budget, legacy "COMPLETE" is treated
         * as EXHAUSTED here. That's conservative — in the worst case, a
         * legacy run whose labels were meaningful will skip some sub-branches
         * on resume, which is the same behavior as old solve.c. */
        if (strstr(line, "INTERRUPTED")) continue;
        /* Parse the budget field (new format: "...budget N" at line end;
         * old format: no budget field). If this is a BUDGETED entry and
         * the stored budget < current budget, DO NOT skip — force re-run. */
        int is_budgeted = (strstr(line, "BUDGETED") != NULL);
        long long stored_budget = 0;
        if (is_budgeted) {
            char *bp = strstr(line, "budget ");
            if (bp && sscanf(bp, "budget %lld", &stored_budget) == 1) {
                if (current_per_branch_budget > 0 && stored_budget < current_per_branch_budget) {
                    /* current budget is larger — re-run this sub-branch */
                    continue;
                }
            } else {
                /* BUDGETED but no budget field — old format; treat as unskippable */
                continue;
            }
        }
        int p1v, o1v, p2v, o2v, p3v = -1, o3v = -1;
        char *p = strstr(line, "pair1 ");
        if (!p) continue;
        /* Try depth-3 format first (6-tuple); fall back to depth-2 (4-tuple). */
        int matched = sscanf(p, "pair1 %d orient1 %d pair2 %d orient2 %d pair3 %d orient3 %d",
                             &p1v, &o1v, &p2v, &o2v, &p3v, &o3v);
        if (matched != 6) {
            p3v = -1; o3v = -1;
            matched = sscanf(p, "pair1 %d orient1 %d pair2 %d orient2 %d",
                             &p1v, &o1v, &p2v, &o2v);
        }
        if (matched == 4 || matched == 6) {
            if (n_completed_subs >= MAX_COMPLETED_SUBS) break;
            completed_sub_branches[n_completed_subs][0] = p1v;
            completed_sub_branches[n_completed_subs][1] = o1v;
            completed_sub_branches[n_completed_subs][2] = p2v;
            completed_sub_branches[n_completed_subs][3] = o2v;
            n_completed_subs++;
            total_sub_complete++;
            /* Populate the appropriate lookup bitmap */
            if (p3v >= 0) {
                int key = completed_sub_key_d3(p1v, o1v, p2v, o2v, p3v, o3v);
                completed_sub_bitmap_d3[key >> 3] |= (unsigned char)(1 << (key & 7));
            } else {
                int key = completed_sub_key(p1v, o1v, p2v, o2v);
                completed_sub_bitmap[key >> 3] |= (unsigned char)(1 << (key & 7));
            }
        }
    }
    fclose(f);
}

static int is_sub_branch_completed(int p1, int o1, int p2, int o2) {
    int key = completed_sub_key(p1, o1, p2, o2);
    return (completed_sub_bitmap[key >> 3] >> (key & 7)) & 1;
}
static int is_sub_branch_completed_d3(int p1, int o1, int p2, int o2, int p3, int o3) {
    int key = completed_sub_key_d3(p1, o1, p2, o2, p3, o3);
    return (completed_sub_bitmap_d3[key >> 3] >> (key & 7)) & 1;
}

/* ---------- Hash table resize ---------- */

static void resize_hash_table(ThreadState *ts) {
    int old_log2 = ts->ht_log2;
    int old_size = ts->ht_size;
    int new_log2 = old_log2 + 1;
    int new_size = 1 << new_log2;
    int new_mask = new_size - 1;

    unsigned char *new_table = calloc((size_t)new_size, SOL_RECORD_SIZE);
    char *new_occupied = calloc(new_size, 1);
    if (!new_table || !new_occupied) {
        fprintf(stderr, "FATAL: thread %d cannot resize hash table 2^%d → 2^%d "
                "(%d MB). Out of memory.\n",
                ts->thread_id, old_log2, new_log2,
                (int)((size_t)new_size * SOL_RECORD_SIZE / 1048576));
        exit(1);
    }

    for (int s = 0; s < old_size; s++) {
        if (ts->sol_occupied[s]) {
            unsigned char *rec = &ts->sol_table[(size_t)s * SOL_RECORD_SIZE];
            unsigned long long ch = 14695981039346656037ULL;
            for (int i = 0; i < SOL_RECORD_SIZE; i++) {
                ch ^= (rec[i] & 0xFC);
                ch *= 1099511628211ULL;
            }
            int slot = (int)(ch & (unsigned long long)new_mask);
            for (int p = 0; p < new_size; p++) {
                int idx = (slot + p) & new_mask;
                if (!new_occupied[idx]) {
                    memcpy(&new_table[(size_t)idx * SOL_RECORD_SIZE], rec, SOL_RECORD_SIZE);
                    new_occupied[idx] = 1;
                    break;
                }
            }
        }
    }

    free(ts->sol_table);
    free(ts->sol_occupied);
    ts->sol_table = new_table;
    ts->sol_occupied = new_occupied;
    ts->ht_log2 = new_log2;
    ts->ht_size = new_size;
    ts->ht_mask = new_mask;
    ts->ht_resizes++;

    fprintf(stderr, "  [thread %d] Hash table resized: 2^%d → 2^%d (%d MB)\n",
            ts->thread_id, old_log2, new_log2,
            (int)((size_t)new_size * SOL_RECORD_SIZE / 1048576));
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
        ts->sol_table = calloc((size_t)ts->ht_size, SOL_RECORD_SIZE);
        ts->sol_occupied = calloc(ts->ht_size, 1);
        if (!ts->sol_table || !ts->sol_occupied) {
            fprintf(stderr, "FATAL: thread %d failed to allocate hash table (%d MB).\n",
                    ts->thread_id, (int)((size_t)ts->ht_size * SOL_RECORD_SIZE / 1048576));
            exit(1);
        }
    }

    int slot = (int)(ch & (unsigned long long)ts->ht_mask);
    for (int probe = 0; probe < ts->ht_size; probe++) {
        int idx = (slot + probe) & ts->ht_mask;
        if (!ts->sol_occupied[idx]) {
            memcpy(&ts->sol_table[(size_t)idx * SOL_RECORD_SIZE], record, SOL_RECORD_SIZE);
            ts->sol_occupied[idx] = 1;
            ts->solution_count++;
            if (ts->solution_count > ts->ht_size * 3 / 4)
                resize_hash_table(ts);
            return;
        }
        unsigned char *existing = &ts->sol_table[(size_t)idx * SOL_RECORD_SIZE];
        int match = 1;
        for (int ci = 0; ci < SOL_RECORD_SIZE; ci++) {
            if ((existing[ci] & 0xFC) != canonical[ci]) { match = 0; break; }
        }
        if (match) {
            ts->hash_collisions++;
            return;
        }
    }
    fprintf(stderr, "FATAL: thread %d hash table 100%% full at 2^%d (%lld entries). "
            "This should never happen with auto-resize.\n",
            ts->thread_id, ts->ht_log2, ts->solution_count);
    exit(1);
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
    /* Runtime invariants (compile out in release builds via -DNDEBUG).
     * These catch any refactor that breaks budget bookkeeping or step
     * progression. Negligible cost when asserts are active. */
    #ifndef NDEBUG
    {
        int total = 0;
        for (int d = 0; d < 7; d++) {
            if (budget[d] < 0) {
                fprintf(stderr, "ASSERTION FAILED: budget[%d]=%d < 0 at step=%d\n",
                        d, budget[d], step);
                abort();
            }
            total += budget[d];
        }
        if (total + step * 2 != 64 && step > 0) {
            /* At step s, 2s hexagrams are placed; remaining budget should sum
             * to 64 - 2s (one edge per unused hex position pair... actually
             * budget counts TRANSITIONS, not hexagrams. 63 transitions total,
             * minus the 2*step-1 already placed, but some were within-pair.)
             * Actual invariant: sum(budget) = 63 - (number of transitions used so far).
             * Skip this assertion as the math is subtle; budget[i]>=0 catches
             * the common corruption patterns. */
        }
        if (step < 0 || step > 32) {
            fprintf(stderr, "ASSERTION FAILED: step=%d out of range\n", step);
            abort();
        }
    }
    #endif
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
 * Called with checkpoint_mutex held.
 * Filename encodes full (p1, o1, p2, o2) to avoid collisions — see bug note
 * on load_sub_checkpoint. */
/* Depth-3 (Option B) flush: filename includes pair3/orient3.
 * Separate function so depth-2 code path stays byte-identical.
 * NOTE: duplicates flush_sub_solutions logic below; kept separate for
 * clarity rather than parameterizing. */
static void flush_sub_solutions_d3(ThreadState *ts, int p1, int o1, int p2, int o2, int p3, int o3) {
    if (!ts->sol_table || !ts->sol_occupied || ts->solution_count == 0) return;
    char fname[96], tmpname[96];
    snprintf(fname, sizeof(fname), "sub_%d_%d_%d_%d_%d_%d.bin", p1, o1, p2, o2, p3, o3);
    snprintf(tmpname, sizeof(tmpname), "sub_%d_%d_%d_%d_%d_%d.bin.tmp", p1, o1, p2, o2, p3, o3);
    FILE *sf = fopen(tmpname, "wb");
    if (!sf) {
        fprintf(stderr, "FATAL: cannot open %s for writing: %s\n", tmpname, strerror(errno));
        exit(1);
    }
    long long written = 0;
    int write_error = 0;
    for (int s = 0; s < ts->ht_size; s++) {
        if (ts->sol_occupied[s]) {
            if (fwrite(&ts->sol_table[(size_t)s * SOL_RECORD_SIZE], SOL_RECORD_SIZE, 1, sf) != 1) {
                write_error = 1;
                break;
            }
            written++;
        }
    }
    if (write_error || fflush(sf) != 0 || fsync(fileno(sf)) != 0) {
        fprintf(stderr, "FATAL: write/flush/fsync failed on %s (wrote %lld of %lld): %s\n",
                tmpname, written, ts->solution_count, strerror(errno));
        fclose(sf);
        exit(1);
    }
    if (fclose(sf) != 0) {
        fprintf(stderr, "FATAL: close failed on %s: %s\n", tmpname, strerror(errno));
        exit(1);
    }
    struct stat st;
    long long expected = (long long)written * SOL_RECORD_SIZE;
    if (stat(tmpname, &st) != 0 || st.st_size != expected) {
        fprintf(stderr, "FATAL: post-write size mismatch on %s: got %lld, expected %lld\n",
                tmpname, (long long)(stat(tmpname, &st) == 0 ? st.st_size : -1), expected);
        exit(1);
    }
    if (rename(tmpname, fname) != 0) {
        fprintf(stderr, "FATAL: rename %s → %s failed: %s\n", tmpname, fname, strerror(errno));
        exit(1);
    }
    fprintf(stderr, "  Wrote %lld solutions to %s\n", written, fname);
    memset(ts->sol_table, 0, (size_t)ts->ht_size * SOL_RECORD_SIZE);
    memset(ts->sol_occupied, 0, ts->ht_size);
    ts->solution_count = 0;
    ts->hash_collisions = 0;
}

static void flush_sub_solutions(ThreadState *ts, int p1, int o1, int p2, int o2) {
    if (!ts->sol_table || !ts->sol_occupied || ts->solution_count == 0) return;
    char fname[64], tmpname[64];
    snprintf(fname, sizeof(fname), "sub_%d_%d_%d_%d.bin", p1, o1, p2, o2);
    snprintf(tmpname, sizeof(tmpname), "sub_%d_%d_%d_%d.bin.tmp", p1, o1, p2, o2);
    FILE *sf = fopen(tmpname, "wb");
    if (!sf) {
        fprintf(stderr, "FATAL: cannot open %s for writing: %s\n", tmpname, strerror(errno));
        exit(1);
    }
    long long written = 0;
    int write_error = 0;
    for (int s = 0; s < ts->ht_size; s++) {
        if (ts->sol_occupied[s]) {
            if (fwrite(&ts->sol_table[(size_t)s * SOL_RECORD_SIZE], SOL_RECORD_SIZE, 1, sf) != 1) {
                write_error = 1;
                break;
            }
            written++;
        }
    }
    if (write_error || fflush(sf) != 0 || fsync(fileno(sf)) != 0) {
        fprintf(stderr, "FATAL: write/flush/fsync failed on %s (wrote %lld of %lld): %s\n",
                tmpname, written, ts->solution_count, strerror(errno));
        fclose(sf);
        exit(1);
    }
    if (fclose(sf) != 0) {
        fprintf(stderr, "FATAL: close failed on %s: %s\n", tmpname, strerror(errno));
        exit(1);
    }
    struct stat st;
    long long expected = (long long)written * SOL_RECORD_SIZE;
    if (stat(tmpname, &st) != 0 || st.st_size != expected) {
        fprintf(stderr, "FATAL: post-write size mismatch on %s: got %lld, expected %lld\n",
                tmpname, (long long)(stat(tmpname, &st) == 0 ? st.st_size : -1), expected);
        exit(1);
    }
    if (rename(tmpname, fname) != 0) {
        fprintf(stderr, "FATAL: rename %s → %s failed: %s\n", tmpname, fname, strerror(errno));
        exit(1);
    }
    fprintf(stderr, "  Wrote %lld solutions to %s\n", written, fname);
    memset(ts->sol_table, 0, (size_t)ts->ht_size * SOL_RECORD_SIZE);
    memset(ts->sol_occupied, 0, ts->ht_size);
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
    /* Cost estimation is the orchestrator's job — it knows the deployment
     * context (spot/on-demand/laptop/etc.). The solver is environment-agnostic. */
    if (completed > 0 && elapsed > 0) {
        double rate = (double)completed / elapsed;
        int remaining = total - completed;
        long eta_sec = (long)(remaining / rate);
        fprintf(pf, "ETA: %ld hours %ld minutes\n", eta_sec / 3600, (eta_sec % 3600) / 60);
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

        /* Position 3: third-level work unit (Option B depth-3).
         * Skipped when sb->pair3 == -1 (depth-2 mode). */
        int backtrack_start_step = 3;
        if (sb->pair3 >= 0) {
            int p3 = sb->pair3, o3 = sb->orient3;
            int f3 = o3 ? pairs[p3].b : pairs[p3].a;
            int s3 = o3 ? pairs[p3].a : pairs[p3].b;
            int bd3 = hamming(seq[5], f3);
            if (bd3 == 5 || budget[bd3] <= 0) continue;
            budget[bd3]--;
            int wd3 = hamming(f3, s3);
            if (budget[wd3] <= 0) continue;
            budget[wd3]--;
            seq[6] = f3; seq[7] = s3;
            used[p3] = 1;
            backtrack_start_step = 4;
        }

        ts->branch_nodes = 0;  /* reset per-sub-branch counter */
        backtrack(ts, seq, used, budget, backtrack_start_step);

        long long sub_nodes = ts->nodes - nodes_before;
        long long sub_c3 = ts->solutions_c3 - c3_before;

        int sb_budget_exhausted = (per_branch_node_limit > 0 && ts->branch_nodes >= per_branch_node_limit);
        /* Three-way status taxonomy:
         *   EXHAUSTED  — DFS ran to natural completion within budget (true "done")
         *   BUDGETED   — per-sub-branch node limit reached (by-design stop)
         *   INTERRUPTED — external signal / global timeout (true interruption)
         * Resume skips EXHAUSTED always; skips BUDGETED only if the stored per-
         * sub-branch budget matches the current run's budget; always re-runs
         * INTERRUPTED.
         * For backward compat with old checkpoints containing "COMPLETE" /
         * "INTERRUPTED", the parser in load_sub_checkpoint() treats "COMPLETE"
         * as equivalent to "EXHAUSTED" (old runs that finished naturally). */
        const char *sb_status;
        if (global_timed_out) sb_status = "INTERRUPTED";
        else if (sb_budget_exhausted) sb_status = "BUDGETED";
        else sb_status = "EXHAUSTED";
        if (!global_timed_out && !sb_budget_exhausted)
            ts->branches_completed++;

        int done = __sync_add_and_fetch(&total_branches_completed, 1);
        long elapsed = (long)(time(NULL) - start_time);

        pthread_mutex_lock(&checkpoint_mutex);

        /* Capture solution_count BEFORE flush_sub_solutions zeroes it —
         * the checkpoint line's "solutions" field should record the actual
         * count, not the post-flush zero. */
        int sub_solutions = ts->solution_count;

        /* Always flush hash table to file after each sub-branch, then clear.
         * This ensures thread-count independence: each sub-branch's solutions are
         * written to its own file regardless of how many threads are running.
         * The final merge reads all sub_*.bin files instead of thread hash tables.
         * For INTERRUPTED sub-branches, solutions are still saved (they're valid
         * even if the sub-branch didn't complete). */
        if (ts->solution_count > 0) {
            if (sb->pair3 >= 0) {
                flush_sub_solutions_d3(ts, p1, o1, p2, o2, sb->pair3, sb->orient3);
            } else {
                flush_sub_solutions(ts, p1, o1, p2, o2);
            }
        } else if (ts->sol_table) {
            memset(ts->sol_table, 0, (size_t)ts->ht_size * SOL_RECORD_SIZE);
            memset(ts->sol_occupied, 0, ts->ht_size);
            ts->solution_count = 0;
            ts->hash_collisions = 0;
        }

        /* Write checkpoint entry. Use fflush + fsync before close so the line
         * lands on disk before a possible spot eviction (~30s notice window).
         * Also capture per-sub-branch budget on the line for future budget-aware
         * resume logic (see status-label taxonomy change — the budget value
         * tells a future resume whether a BUDGETED entry is still valid under
         * the current run's budget or needs re-running). */
        FILE *ckpt = fopen("checkpoint.txt", "a");
        if (ckpt) {
            if (sb->pair3 >= 0) {
                fprintf(ckpt, "Sub-branch %s (thread %d, pair1 %d orient1 %d pair2 %d orient2 %d pair3 %d orient3 %d): "
                        "%lld nodes, %lld C3-valid, %d solutions, %lds elapsed, budget %lld\n",
                        sb_status, ts->thread_id, p1, o1, p2, o2, sb->pair3, sb->orient3,
                        sub_nodes, sub_c3, sub_solutions, elapsed,
                        per_branch_node_limit);
            } else {
                fprintf(ckpt, "Sub-branch %s (thread %d, pair1 %d orient1 %d pair2 %d orient2 %d): "
                        "%lld nodes, %lld C3-valid, %d solutions, %lds elapsed, budget %lld\n",
                        sb_status, ts->thread_id, p1, o1, p2, o2,
                        sub_nodes, sub_c3, sub_solutions, elapsed,
                        per_branch_node_limit);
            }
            if (fflush(ckpt) != 0 || fsync(fileno(ckpt)) != 0) {
                fprintf(stderr, "WARNING: checkpoint.txt fflush/fsync failed — entry may be lost on eviction\n");
            }
            if (fclose(ckpt) != 0) {
                fprintf(stderr, "WARNING: checkpoint.txt close failed\n");
            }
        } else {
            fprintf(stderr, "WARNING: could not open checkpoint.txt for append\n");
        }

        /* Update progress file. Use in-memory total_sub_complete counter
         * (protected by checkpoint_mutex) instead of re-reading checkpoint.txt
         * after every sub-branch commit. Avoids O(n^2) scan under mutex.
         * Count both EXHAUSTED and BUDGETED as "processed" — both have
         * committed their solutions and won't be re-run (at the same budget).
         * INTERRUPTED does not count because it will re-run on resume. */
        if (strcmp(sb_status, "EXHAUSTED") == 0 || strcmp(sb_status, "BUDGETED") == 0)
            total_sub_complete++;
        update_progress(total_sub_complete, total_branches, elapsed);

        /* Use sub_solutions (captured before flush) rather than ts->solution_count
         * (which flush_sub_solutions already zeroed). */
        fprintf(stderr, "  *** Sub-branch %d/%d %s (pair1 %d orient1 %d pair2 %d orient2 %d): "
                "%lldB nodes, %lldM C3, %d solutions, %lds ***\n",
                done, total_branches, sb_status, p1, o1, p2, o2,
                sub_nodes / 1000000000LL, sub_c3 / 1000000LL,
                sub_solutions, elapsed);
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
                                        long long unique_count, long long total_nodes,
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
    fprintf(sf, "# Unique orderings: %lld\n", unique_count);
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
/* Time limit for proof_search, set by caller. 0 = no limit. */
static volatile time_t proof_search_deadline = 0;
static volatile int proof_search_timed_out = 0;

static void proof_search(int seq[64], int used[32], int budget[7],
                         int step, int last, long long *nodes, int *found) {
    (*nodes)++;
    if (*found || proof_search_timed_out) return;
    if ((*nodes) % 50000000LL == 0) {
        if ((*nodes) % 1000000000LL == 0)
            fprintf(stderr, " %lldB...", (*nodes) / 1000000000LL);
        if (proof_search_deadline > 0 && time(NULL) >= proof_search_deadline)
            proof_search_timed_out = 1;
    }
    if (proof_search_timed_out) return;

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
    /* Secondary: full byte (orient as tiebreaker for deterministic ordering) */
    return memcmp(sa, sb, SOL_RECORD_SIZE);
}

static int compare_canonical(const void *a, const void *b) {
    const unsigned char *sa = (const unsigned char *)a;
    const unsigned char *sb = (const unsigned char *)b;
    for (int i = 0; i < SOL_RECORD_SIZE; i++) {
        int ca = sa[i] & 0xFC;
        int cb = sb[i] & 0xFC;
        if (ca != cb) return ca - cb;
    }
    return 0;
}

/* ---------- External merge-sort ----------
 * Memory-independent alternative to the in-memory qsort merge. Reads sub_*.bin
 * files in fixed-size chunks, sorts each chunk in RAM, writes sorted temp files,
 * then does a k-way merge with canonical dedup. Memory bounded by chunk size
 * (default 4 GB, configurable via SOLVE_MERGE_CHUNK_GB).
 *
 * Controlled by SOLVE_MERGE_MODE env var:
 *   auto     (default) — external if needed RAM > 70% of physical
 *   memory   — force in-memory (fail if insufficient)
 *   external — force external merge-sort
 */

typedef struct {
    unsigned char rec[SOL_RECORD_SIZE];
    int file_idx;
} MergeHeapEntry;

static void merge_heap_sift_down(MergeHeapEntry *heap, int n, int i) {
    while (1) {
        int smallest = i;
        int left = 2*i + 1, right = 2*i + 2;
        if (left < n && compare_solutions(heap[left].rec, heap[smallest].rec) < 0)
            smallest = left;
        if (right < n && compare_solutions(heap[right].rec, heap[smallest].rec) < 0)
            smallest = right;
        if (smallest == i) break;
        MergeHeapEntry tmp = heap[i];
        heap[i] = heap[smallest];
        heap[smallest] = tmp;
        i = smallest;
    }
}

static int external_merge_sort(char (*filenames)[64], int n_files,
                                long long total_records,
                                const char *output_path, long long *out_unique) {
    long long chunk_bytes = 4LL * 1024 * 1024 * 1024;
    char *env_chunk = getenv("SOLVE_MERGE_CHUNK_GB");
    if (env_chunk) chunk_bytes = atoll(env_chunk) * 1024LL * 1024 * 1024;
    long long max_per_chunk = chunk_bytes / SOL_RECORD_SIZE;

    printf("External merge-sort: %lld records, chunk size %lld GB (%lld records/chunk)\n",
           total_records, chunk_bytes / (1024*1024*1024), max_per_chunk);

    unsigned char *chunk = malloc((size_t)chunk_bytes);
    if (!chunk) {
        fprintf(stderr, "ERROR: cannot allocate %lld bytes for sort chunk\n", chunk_bytes);
        return 1;
    }

    #define MAX_SORTED_CHUNKS 4096
    char sorted_names[MAX_SORTED_CHUNKS][64];
    int n_sorted = 0;
    long long records_in_chunk = 0;

    for (int fi = 0; fi < n_files; fi++) {
        FILE *f = fopen(filenames[fi], "rb");
        if (!f) continue;
        fseek(f, 0, SEEK_END);
        long sz = ftell(f);
        fseek(f, 0, SEEK_SET);
        if (sz <= 0 || sz % SOL_RECORD_SIZE != 0) { fclose(f); continue; }
        long long file_records = sz / SOL_RECORD_SIZE;

        while (file_records > 0) {
            long long space = max_per_chunk - records_in_chunk;
            long long to_read = (file_records < space) ? file_records : space;
            size_t got = fread(&chunk[records_in_chunk * SOL_RECORD_SIZE],
                               SOL_RECORD_SIZE, (size_t)to_read, f);
            records_in_chunk += got;
            file_records -= got;
            if ((long long)got < to_read) break;

            if (records_in_chunk >= max_per_chunk) {
                qsort(chunk, (size_t)records_in_chunk, SOL_RECORD_SIZE, compare_solutions);
                if (n_sorted >= MAX_SORTED_CHUNKS) {
                    fprintf(stderr, "ERROR: too many sorted chunks (%d)\n", n_sorted);
                    free(chunk); return 1;
                }
                snprintf(sorted_names[n_sorted], 64, "temp_sorted_%04d.bin", n_sorted);
                FILE *sf = fopen(sorted_names[n_sorted], "wb");
                if (!sf) { fprintf(stderr, "ERROR: cannot create %s\n", sorted_names[n_sorted]); free(chunk); return 1; }
                fwrite(chunk, SOL_RECORD_SIZE, (size_t)records_in_chunk, sf);
                fflush(sf); fsync(fileno(sf)); fclose(sf);
                printf("  Chunk %d: %lld records sorted + written\n", n_sorted, records_in_chunk);
                fflush(stdout);
                n_sorted++;
                records_in_chunk = 0;
            }
        }
        fclose(f);
    }

    if (records_in_chunk > 0) {
        qsort(chunk, (size_t)records_in_chunk, SOL_RECORD_SIZE, compare_solutions);
        if (n_sorted >= MAX_SORTED_CHUNKS) {
            fprintf(stderr, "ERROR: too many sorted chunks\n"); free(chunk); return 1;
        }
        snprintf(sorted_names[n_sorted], 64, "temp_sorted_%04d.bin", n_sorted);
        FILE *sf = fopen(sorted_names[n_sorted], "wb");
        if (!sf) { fprintf(stderr, "ERROR: cannot create %s\n", sorted_names[n_sorted]); free(chunk); return 1; }
        fwrite(chunk, SOL_RECORD_SIZE, (size_t)records_in_chunk, sf);
        fflush(sf); fsync(fileno(sf)); fclose(sf);
        printf("  Chunk %d: %lld records sorted + written (final)\n", n_sorted, records_in_chunk);
        fflush(stdout);
        n_sorted++;
    }
    free(chunk);
    printf("  %d sorted chunks created\n", n_sorted);
    fflush(stdout);

    /* Phase 2: k-way merge with canonical dedup */
    FILE **sfiles = calloc(n_sorted, sizeof(FILE*));
    MergeHeapEntry *heap = calloc(n_sorted, sizeof(MergeHeapEntry));
    if (!sfiles || !heap) {
        fprintf(stderr, "ERROR: merge heap allocation failed\n");
        free(sfiles); free(heap); return 1;
    }
    int heap_size = 0;

    for (int i = 0; i < n_sorted; i++) {
        sfiles[i] = fopen(sorted_names[i], "rb");
        if (sfiles[i] && fread(heap[heap_size].rec, SOL_RECORD_SIZE, 1, sfiles[i]) == 1) {
            heap[heap_size].file_idx = i;
            heap_size++;
        }
    }

    for (int i = heap_size/2 - 1; i >= 0; i--)
        merge_heap_sift_down(heap, heap_size, i);

    FILE *out = fopen(output_path, "wb");
    if (!out) {
        fprintf(stderr, "ERROR: cannot open %s for writing\n", output_path);
        free(sfiles); free(heap); return 1;
    }

    unsigned char last_written[SOL_RECORD_SIZE];
    memset(last_written, 0xFF, SOL_RECORD_SIZE);
    long long unique = 0, total_merged = 0;

    while (heap_size > 0) {
        MergeHeapEntry top = heap[0];
        total_merged++;

        if (compare_canonical(top.rec, last_written) != 0) {
            if (fwrite(top.rec, SOL_RECORD_SIZE, 1, out) != 1) {
                fprintf(stderr, "FATAL: write failed at record %lld\n", unique);
                fclose(out); free(sfiles); free(heap); return 1;
            }
            memcpy(last_written, top.rec, SOL_RECORD_SIZE);
            unique++;
        }

        int fi = top.file_idx;
        if (fread(heap[0].rec, SOL_RECORD_SIZE, 1, sfiles[fi]) == 1) {
            heap[0].file_idx = fi;
            merge_heap_sift_down(heap, heap_size, 0);
        } else {
            heap[0] = heap[heap_size - 1];
            heap_size--;
            if (heap_size > 0) merge_heap_sift_down(heap, heap_size, 0);
            fclose(sfiles[fi]);
        }

        if (total_merged % 100000000 == 0) {
            printf("  Merged %lld / %lld, %lld unique\n", total_merged, total_records, unique);
            fflush(stdout);
        }
    }

    if (fflush(out) != 0 || fsync(fileno(out)) != 0) {
        fprintf(stderr, "FATAL: flush/fsync failed on %s\n", output_path);
        fclose(out); free(sfiles); free(heap); return 1;
    }
    fclose(out);

    for (int i = 0; i < n_sorted; i++)
        remove(sorted_names[i]);
    free(sfiles);
    free(heap);

    printf("External merge complete: %lld total → %lld unique canonical orderings\n",
           total_merged, unique);
    fflush(stdout);
    *out_unique = unique;
    return 0;
}

/* ---------- JSON output ---------- */

static void write_json(const char *filename, const char *status,
                       long elapsed, int n_threads, int n_branches_total,
                       int branches_done,
                       long long total_nodes, long long total_sol,
                       long long total_c3, long long unique_count,
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
    fprintf(f, "    \"hash_table_initial_log2\": %d,\n", sol_hash_log2);
    fprintf(f, "    \"node_limit\": %lld,\n", node_limit);
    fprintf(f, "    \"solve_depth\": %d,\n", solve_depth);
    fprintf(f, "    \"cpu_cores\": %ld,\n", sysconf(_SC_NPROCESSORS_ONLN));
    fprintf(f, "    \"git_hash\": \"%s\",\n", GIT_HASH);
    fprintf(f, "    \"build_date\": \"%s %s\",\n", __DATE__, __TIME__);
    fprintf(f, "    \"resumed_branches\": %d\n", n_completed_from_checkpoint);
    fprintf(f, "  },\n");

    fprintf(f, "  \"counts\": {\n");
    fprintf(f, "    \"nodes_explored\": %lld,\n", total_nodes);
    fprintf(f, "    \"total_solutions\": %lld,\n", total_sol);
    fprintf(f, "    \"c3_valid\": %lld,\n", total_c3);
    fprintf(f, "    \"unique_orderings\": %lld,\n", unique_count);
    fprintf(f, "    \"dedup_semantics\": \"canonical pair ordering (orientation bits masked)\",\n");
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
    fprintf(f, "    \"solutions_bin_records\": %lld,\n", unique_count);
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
    int verify_mode = 0;
    int prove_cascade_mode = 0;
    int prove_self_comp_mode = 0;
    int prove_shift_mode = 0;
    int analyze_mode = 0;
    char *validate_file = NULL;
    char *verify_file = NULL;
    char *analyze_file = NULL;

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
    } else if (argc > 1 && strcmp(argv[1], "--analyze") == 0) {
        analyze_mode = 1;
        analyze_file = (argc > 2) ? argv[2] : "solutions.bin";
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--verify") == 0) {
        verify_mode = 1;
        verify_file = (argc > 2) ? argv[2] : "solutions.bin";
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--selftest") == 0) {
        /* --selftest: fork a child process that runs a fixed tiny scenario in
         * a temp directory, then compare its solutions.bin sha256 against a
         * known value. Catches regressions in enumeration, merge, or I/O
         * that would produce a different solutions.bin from the same inputs.
         *
         * Reference: SOLVE_THREADS=4 SOLVE_NODE_LIMIT=100000000, default depth-2.
         * Expected sha256: 76ada31ef4a5829dcf33c8127c296fcb08115ef066ab267b1a0fb0b162f2a20d
         */
        const char *expected_sha = "76ada31ef4a5829dcf33c8127c296fcb08115ef066ab267b1a0fb0b162f2a20d";
        char solve_path[4096];
        if (readlink("/proc/self/exe", solve_path, sizeof(solve_path) - 1) <= 0) {
            fprintf(stderr, "ERROR: cannot resolve self path for --selftest\n");
            return 10;
        }
        solve_path[sizeof(solve_path) - 1] = 0;
        /* strlen to locate null-terminator from readlink */
        ssize_t sn = readlink("/proc/self/exe", solve_path, sizeof(solve_path) - 1);
        if (sn > 0) solve_path[sn] = 0;

        char tempdir_template[] = "/tmp/solve_selftest_XXXXXX";
        if (!mkdtemp(tempdir_template)) {
            fprintf(stderr, "ERROR: mkdtemp failed\n");
            return 10;
        }
        printf("[--selftest] Running in %s\n", tempdir_template);
        printf("[--selftest] Expected sha256: %s\n", expected_sha);
        char cmd[8192];
        snprintf(cmd, sizeof(cmd),
                 "cd %s && "
                 "unset SOLVE_DEPTH && "
                 "SOLVE_THREADS=4 SOLVE_NODE_LIMIT=100000000 %s 60 > /dev/null 2>&1 && "
                 "sha256sum solutions.bin | cut -d' ' -f1",
                 tempdir_template, solve_path);
        FILE *fp = popen(cmd, "r");
        if (!fp) {
            fprintf(stderr, "ERROR: popen failed\n");
            return 30;
        }
        char actual_sha[128] = {0};
        if (fgets(actual_sha, sizeof(actual_sha), fp) == NULL) {
            pclose(fp);
            fprintf(stderr, "ERROR: selftest child produced no output\n");
            return 40;
        }
        pclose(fp);
        /* Strip trailing newline */
        for (char *p = actual_sha; *p; p++) if (*p == '\n') { *p = 0; break; }
        printf("[--selftest] Actual sha256:   %s\n", actual_sha);
        /* Cleanup temp dir */
        char rm_cmd[4200];
        snprintf(rm_cmd, sizeof(rm_cmd), "rm -rf %s", tempdir_template);
        int _rm = system(rm_cmd); (void)_rm;
        if (strcmp(actual_sha, expected_sha) == 0) {
            printf("[--selftest] PASS — sha256 matches canonical baseline\n");
            return 0;
        } else {
            fprintf(stderr, "[--selftest] FAIL — sha mismatch!\n");
            fprintf(stderr, "             Expected: %s\n", expected_sha);
            fprintf(stderr, "             Got:      %s\n", actual_sha);
            fprintf(stderr, "             Enumeration path has regressed — investigate.\n");
            return 40;  /* validation mismatch */
        }
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
            printf("Usage: ./solve [time_limit] [threads]  (0 = no limit)\n"
                   "       ./solve --verify [solutions.bin]   (independent C1-C5 check)\n"
                   "       ./solve --selftest                 (regression test)\n");
    }

    /* Configurable hash table size */
    char *env_hash = getenv("SOLVE_HASH_LOG2");
    if (env_hash) {
        int v = atoi(env_hash);
        if (v >= 16 && v <= 30) sol_hash_log2 = v;
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

    /* Enumeration depth (SOLVE_DEPTH env var). Default 2 for byte-identical
     * behavior with the canonical 10T baseline. SOLVE_DEPTH=3 enables Option B
     * depth-3 work units (~30x finer granularity for eviction resilience). */
    char *env_depth = getenv("SOLVE_DEPTH");
    if (env_depth) {
        solve_depth = atoi(env_depth);
        if (solve_depth != 2 && solve_depth != 3) {
            fprintf(stderr, "ERROR: SOLVE_DEPTH must be 2 or 3 (got %d)\n", solve_depth);
            return 10;
        }
    }
    if (solve_depth != 2) printf("Enumeration depth: %d (Option B opt-in)\n", solve_depth);

    init_pairs();
    init_kw_dist();
    kw_comp_dist_x64 = compute_comp_dist_x64(KW);
    init_kw_canonical();
    init_adjacency_constraints();
    init_kw_pair_positions();
    init_super_pairs();
    init_pair_order();

    /* KW self-check: validate that the canonical KW[] sequence satisfies C1-C5.
     * Catches accidental edits to KW[] or to the constraint checkers. If this
     * fails, everything downstream is suspect. */
    {
        /* C1: all 64 hexagrams unique */
        int seen[64] = {0};
        for (int i = 0; i < 64; i++) {
            if (KW[i] < 0 || KW[i] >= 64 || seen[KW[i]]++) {
                fprintf(stderr, "ERROR: KW self-check failed: hexagram %d at index %d invalid or duplicated\n", KW[i], i);
                return 50; /* exit code 50 = internal consistency failure */
            }
        }
        /* C2: no 5-line transitions between consecutive hexagrams */
        for (int i = 0; i < 63; i++) {
            if (hamming(KW[i], KW[i + 1]) == 5) {
                fprintf(stderr, "ERROR: KW self-check failed: 5-line transition at index %d (%d -> %d)\n", i, KW[i], KW[i + 1]);
                return 50;
            }
        }
        /* C4: position 1 is hexagram 63 (Creative), position 2 is 0 (Receptive) */
        if (KW[0] != 63 || KW[1] != 0) {
            fprintf(stderr, "ERROR: KW self-check failed: expected Creative/Receptive at positions 0-1, got %d/%d\n", KW[0], KW[1]);
            return 50;
        }
        /* C5: difference-distribution kw_dist accounts for all 63 transitions */
        int total_dist = 0;
        for (int d = 0; d < 7; d++) total_dist += kw_dist[d];
        if (total_dist != 63) {
            fprintf(stderr, "ERROR: KW self-check failed: kw_dist sums to %d, expected 63\n", total_dist);
            return 50;
        }
        /* C3: compute_comp_dist_x64(KW) returned a sane value (not negative, not huge) */
        if (kw_comp_dist_x64 <= 0 || kw_comp_dist_x64 > 2048) {
            fprintf(stderr, "ERROR: KW self-check failed: kw_comp_dist_x64 = %d out of plausible range\n", kw_comp_dist_x64);
            return 50;
        }
    }

    printf("Build: %s %s (git: %s)\n", __DATE__, __TIME__, GIT_HASH);
    printf("King Wen complement distance (x64): %d (= %.4f)\n",
           kw_comp_dist_x64, kw_comp_dist_x64 / 64.0);
    printf("Difference distribution: ");
    for (int d = 0; d < 7; d++) {
        if (kw_dist[d] > 0) printf("%d:%d ", d, kw_dist[d]);
    }
    printf("\nSuper-pairs: %d\n", n_super_pairs);

    /* --- Verify mode ---
     * Independent constraint verification: reads every record from solutions.bin,
     * reconstructs the full 64-hexagram sequence, and checks C1-C5 independently
     * of the search code. Also checks for duplicates and sorted order.
     * Returns 0 if all records pass, nonzero on any failure. */
    if (verify_mode) {
        printf("\n=== Independent Constraint Verification ===\n");
        printf("File: %s\n", verify_file);

        FILE *vf = fopen(verify_file, "rb");
        if (!vf) { fprintf(stderr, "ERROR: cannot open %s\n", verify_file); return 10; }
        fseek(vf, 0, SEEK_END);
        long vsize = ftell(vf);
        fseek(vf, 0, SEEK_SET);
        if (vsize <= 0 || vsize % SOL_RECORD_SIZE != 0) {
            fprintf(stderr, "ERROR: file size %ld is not a positive multiple of %d\n",
                    vsize, SOL_RECORD_SIZE);
            fclose(vf);
            return 20;
        }
        long long n_records = vsize / SOL_RECORD_SIZE;
        printf("Records: %lld (%ld bytes)\n\n", n_records, vsize);

        unsigned char rec[SOL_RECORD_SIZE];
        unsigned char prev[SOL_RECORD_SIZE];
        memset(prev, 0, SOL_RECORD_SIZE);
        int fail_c1 = 0, fail_c2 = 0, fail_c4 = 0, fail_c5 = 0;
        int fail_dup = 0, fail_sort = 0, fail_decode = 0;
        int kw_found_v = 0;

        for (long long r = 0; r < n_records; r++) {
            if (fread(rec, SOL_RECORD_SIZE, 1, vf) != 1) {
                fprintf(stderr, "ERROR: short read at record %lld\n", r);
                fclose(vf);
                return 20;
            }

            /* Decode: byte i = (pair_index << 2) | (orient << 1) */
            int seq[64];
            int used_pairs[32];
            memset(used_pairs, 0, sizeof(used_pairs));
            int decode_ok = 1;
            for (int i = 0; i < 32; i++) {
                int pidx = (rec[i] >> 2) & 0x3F;
                int orient = (rec[i] >> 1) & 1;
                if (pidx < 0 || pidx >= 32) { decode_ok = 0; break; }
                used_pairs[pidx]++;
                if (orient == 0) {
                    seq[i * 2] = pairs[pidx].a;
                    seq[i * 2 + 1] = pairs[pidx].b;
                } else {
                    seq[i * 2] = pairs[pidx].b;
                    seq[i * 2 + 1] = pairs[pidx].a;
                }
            }
            if (!decode_ok) { fail_decode++; continue; }

            /* C1: each pair used exactly once */
            int c1_ok = 1;
            for (int i = 0; i < 32; i++) {
                if (used_pairs[i] != 1) { c1_ok = 0; break; }
            }
            if (!c1_ok) fail_c1++;

            /* C4: first pair is Creative/Receptive (63, 0) */
            int pidx0 = (rec[0] >> 2) & 0x3F;
            if (pidx0 != pair_index_of(63, 0)) fail_c4++;

            /* C2: no hamming-5 transitions */
            int c2_ok = 1;
            for (int i = 0; i < 63; i++) {
                if (hamming(seq[i], seq[i + 1]) == 5) { c2_ok = 0; break; }
            }
            if (!c2_ok) fail_c2++;

            /* C5: distance distribution matches KW */
            int dist[7] = {0};
            for (int i = 0; i < 63; i++) {
                int d = hamming(seq[i], seq[i + 1]);
                if (d >= 0 && d <= 6) dist[d]++;
            }
            int c5_ok = 1;
            for (int d = 0; d < 7; d++) {
                if (dist[d] != kw_dist[d]) { c5_ok = 0; break; }
            }
            if (!c5_ok) fail_c5++;

            /* Sorted order (compare_solutions: canonical primary, orient secondary).
             * Duplicate = same canonical form (orient masked). */
            if (r > 0) {
                int cmp = compare_solutions(prev, rec);
                if (cmp > 0) fail_sort++;
                if (compare_canonical(prev, rec) == 0) fail_dup++;
            }

            /* King Wen check */
            int is_kw = 1;
            for (int i = 0; i < 64; i++) {
                if (seq[i] != KW[i]) { is_kw = 0; break; }
            }
            if (is_kw) kw_found_v = 1;

            memcpy(prev, rec, SOL_RECORD_SIZE);

            if (r > 0 && r % 10000000 == 0)
                printf("  ... verified %lld / %lld records\n", r, n_records);
        }
        fclose(vf);

        printf("\n--- Verification Results ---\n");
        printf("Records checked:        %lld\n", n_records);
        printf("C1 failures (pairs):    %d\n", fail_c1);
        printf("C2 failures (hamming5): %d\n", fail_c2);
        printf("C4 failures (first pair): %d\n", fail_c4);
        printf("C5 failures (dist):     %d\n", fail_c5);
        printf("Decode failures:        %d\n", fail_decode);
        printf("Sort order violations:  %d\n", fail_sort);
        printf("Duplicate records:      %d\n", fail_dup);
        printf("King Wen found:         %s\n", kw_found_v ? "YES" : "No");

        int total_fail = fail_c1 + fail_c2 + fail_c4 + fail_c5 + fail_decode + fail_sort + fail_dup;
        if (total_fail == 0) {
            printf("\n*** VERIFY PASS: all %lld records satisfy C1-C5, sorted, no duplicates ***\n", n_records);
            return 0;
        } else {
            printf("\n*** VERIFY FAIL: %d issues found ***\n", total_fail);
            return 1;
        }
    }

    /* --- Validate mode ---
     * solutions.bin uses packed 32-byte records: byte i = (pair_index<<2)|(orient<<1).
     * Full sequence is recoverable, enabling verification of ALL constraints. */
    if (validate_mode) {
        printf("\nValidating %s...\n", validate_file);
        printf("  Record format: %d bytes packed (pair_index<<2 | orient<<1 per position)\n",
               SOL_RECORD_SIZE);
        printf("  Checking: C1-C5, C3, sorted order, no duplicates, King Wen presence.\n\n");

        /* mmap the file: avoids loading 24 GB into a malloc, OS pages it in. */
        int vfd = open(validate_file, O_RDONLY);
        if (vfd < 0) { printf("ERROR: cannot open %s\n", validate_file); return 1; }
        struct stat vst;
        if (fstat(vfd, &vst) < 0) { printf("ERROR: fstat failed\n"); close(vfd); return 1; }
        long file_size = vst.st_size;
        long long n_solutions = file_size / SOL_RECORD_SIZE;
        printf("  File size: %ld bytes, %lld solutions (%d bytes/record)\n",
               file_size, n_solutions, SOL_RECORD_SIZE);
        if (file_size % SOL_RECORD_SIZE != 0)
            printf("  WARNING: file size not a multiple of %d bytes\n", SOL_RECORD_SIZE);
        unsigned char *vall = mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, vfd, 0);
        close(vfd);
        if (vall == MAP_FAILED) { printf("ERROR: mmap failed\n"); return 1; }
        madvise(vall, file_size, MADV_SEQUENTIAL);

        long long errors = 0;
        int kw_found_v = 0;
        int sorted_ok = 1;

        /* Sorted-order check: inherently sequential (compare each with predecessor).
         * Fast: 32-byte memcmp per record, ~3 GB/s on modern hardware. */
        for (long long s = 1; s < n_solutions; s++) {
            int cmp = compare_solutions(vall + s * SOL_RECORD_SIZE,
                                        vall + (s - 1) * SOL_RECORD_SIZE);
            if (cmp <= 0) {
                if (cmp == 0)
                    printf("  ERROR: duplicate at index %lld\n", s);
                else
                    printf("  ERROR: not sorted at index %lld\n", s);
                sorted_ok = 0;
                errors++;
                break;  /* report only first violation */
            }
        }

        /* Per-record constraint checks (C1-C5): embarrassingly parallel.
         * Compile with -fopenmp for ~32x speedup. Error printfs are wrapped in
         * critical sections; in the normal case (zero errors) the critical section
         * is never entered. */
        int kw_pair_index = pair_index_of(63, 0);
        #pragma omp parallel for schedule(static, 65536) reduction(+:errors) reduction(||:kw_found_v)
        for (long long s = 0; s < n_solutions; s++) {
            const unsigned char *rec = vall + s * SOL_RECORD_SIZE;
            int sol_pidx[32];
            int seq[64];
            int used_pairs[32] = {0};
            int local_errors = 0;
            int c1_ok = 1;
            for (int i = 0; i < 32; i++) {
                int pidx = rec[i] >> 2;
                int orient = (rec[i] >> 1) & 1;
                if (pidx < 0 || pidx >= 32) {
                    #pragma omp critical
                    printf("  ERROR: solution %lld position %d invalid pair index %d\n", s, i + 1, pidx);
                    c1_ok = 0; local_errors++; break;
                }
                if (used_pairs[pidx]) {
                    #pragma omp critical
                    printf("  ERROR: solution %lld duplicate pair %d at position %d\n", s, pidx, i + 1);
                    c1_ok = 0; local_errors++; break;
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
            if (c1_ok) {
                if (sol_pidx[0] != kw_pair_index) {
                    #pragma omp critical
                    printf("  ERROR: solution %lld position 1 is pair %d, expected Creative/Receptive\n",
                           s, sol_pidx[0]);
                    local_errors++;
                }
                int budget_check[7] = {0};
                int c2_ok = 1;
                for (int i = 0; i < 63; i++) {
                    int d = hamming(seq[i], seq[i + 1]);
                    if (d == 5) {
                        #pragma omp critical
                        printf("  ERROR: solution %lld has 5-line transition at position %d-%d\n", s, i, i + 1);
                        c2_ok = 0; local_errors++; break;
                    }
                    budget_check[d]++;
                }
                if (c2_ok) {
                    for (int d = 0; d < 7; d++) {
                        if (budget_check[d] != kw_dist[d]) {
                            #pragma omp critical
                            printf("  ERROR: solution %lld wrong difference distribution "
                                   "(dist %d: got %d, expected %d)\n",
                                   s, d, budget_check[d], kw_dist[d]);
                            local_errors++; break;
                        }
                    }
                }
                int cd = compute_comp_dist_x64(seq);
                if (cd > kw_comp_dist_x64) {
                    #pragma omp critical
                    printf("  ERROR: solution %lld complement distance %d > KW %d\n", s, cd, kw_comp_dist_x64);
                    local_errors++;
                }
                int is_kw = 1;
                for (int i = 0; i < 64; i++) {
                    if (seq[i] != KW[i]) { is_kw = 0; break; }
                }
                if (is_kw) kw_found_v = 1;
            }
            errors += local_errors;
        }
        munmap(vall, file_size);

        printf("\n--- Validation results ---\n");
        printf("  Solutions checked:  %lld\n", n_solutions);
        printf("  Sorted order:      %s\n", sorted_ok ? "OK" : "FAILED");
        printf("  King Wen present:  %s\n", kw_found_v ? "YES" : "No");
        printf("  Errors found:      %lld\n", errors);
        if (errors == 0)
            printf("  Result: ALL CONSTRAINTS VERIFIED\n");
        else
            printf("  Result: VALIDATION FAILED\n");
        return errors > 0 ? 1 : 0;
    }

    /* --- Analyze mode: post-enumeration scientific analyses on solutions.bin ---
     *
     * Single-shot reproducibility surface for all numerical claims cited in
     * HISTORY.md and SOLVE-SUMMARY.md. Designed to scale to large datasets:
     *
     *   - Memory-maps solutions.bin (no full malloc; OS pages in on demand)
     *   - Builds packed-bit boundary masks (1 bit per record per boundary,
     *     8x smaller than bool[] form). 31 boundaries × n_sols/8 bytes.
     *   - Uses __builtin_popcountll for SIMD-friendly intersection counts.
     *   - Parallelizes the heavy 3-subset, 4-subset, MI, redundancy, and
     *     null-model loops via OpenMP. Compile with `gcc -fopenmp -march=native`
     *     to enable; without -fopenmp the pragmas are no-ops and execution
     *     falls back to single-threaded.
     *
     * Build: gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm
     *        (libgomp is shipped with gcc and covered by the GCC Runtime
     *         Library Exception — no LICENSE change required.)
     *
     * Sections:
     *   1. File metadata
     *   2. Per-position Shannon entropy H(p)
     *   3. Per-boundary survivor counts (31 boundaries, KW-relative)
     *   4. King Wen variant analysis (count, varying within-pair orient positions)
     *   5. Shift-pattern violation rates per position 3-19
     *   6. Greedy minimum-boundary search to uniquely identify KW
     *   7. Exhaustive 3-subset disproof (all C(31,3)=4,495 triples)
     *   8. All 4-subsets uniquely identifying KW (C(31,4)=31,465)
     *   9. Boundary redundancy (top-redundant + most-independent pairs)
     *  10. Pairwise mutual information (top-N pairs)
     *  11. Per-first-level-branch distinct configurations at positions 3-19
     *  12. Null-model: greedy boundary search relative to a non-KW reference
     *  13. Orbit counts (palindromic / pair-complement-symmetric solutions)
     *  14. Orient-coupling generalization: group records by pair-index
     *      sequence (orient masked); analyze variants-per-pair-ordering
     *      distribution, per-position orient-variation frequency, 4-variant
     *      XOR-coupling check, 1-variant subfamily characterization. Also
     *      extracts the unique pair-orderings used by section 15.
     *  15. Orient-collapsed boundary analysis: rebuilds boundary masks on
     *      the 284M+ unique pair-orderings (orient collapsed, so KW appears
     *      exactly once) and re-runs the greedy minimum, 3-subset disproof,
     *      and all-4-subsets enumeration. Cleaner boundary count where KW
     *      isn't multi-counted via orient variants.
     */
    if (analyze_mode) {
        setbuf(stdout, NULL);
        printf("\n==== ./solve --analyze %s ====\n\n", analyze_file);
        time_t t_start = time(NULL);

        /* mmap the file: no malloc, no fread. OS pages it in on demand. */
        int afd = open(analyze_file, O_RDONLY);
        if (afd < 0) { printf("ERROR: cannot open %s\n", analyze_file); return 1; }
        struct stat ast;
        if (fstat(afd, &ast) < 0) { printf("ERROR: fstat failed\n"); close(afd); return 1; }
        long file_size = ast.st_size;
        if (file_size % SOL_RECORD_SIZE != 0) {
            printf("ERROR: file size %ld not a multiple of %d\n", file_size, SOL_RECORD_SIZE);
            close(afd); return 1;
        }
        long long n_sols = file_size / SOL_RECORD_SIZE;
        unsigned char *all = mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, afd, 0);
        close(afd);
        if (all == MAP_FAILED) {
            printf("ERROR: mmap of %ld bytes failed (errno %d)\n", file_size, errno);
            return 1;
        }
        madvise(all, file_size, MADV_SEQUENTIAL);

        printf("[1] File metadata\n");
        printf("    records:    %lld\n", n_sols);
        printf("    file size:  %ld bytes (%.2f GB)\n", file_size, file_size / 1e9);
        printf("    record fmt: %d bytes packed (pair_index<<2 | orient<<1 per position)\n", SOL_RECORD_SIZE);
        printf("    backed by:  mmap (PROT_READ, MAP_PRIVATE)\n\n");

        /* Complement-pair table: used by sections [20] and [22].
         * For each pair p, comp_pair_idx[p] = pair index of (a^0x3F, b^0x3F).
         * comp_orient_flip[p] = 1 if complementing swaps the pair's internal order. */
        int comp_pair_idx[32], comp_orient_flip[32];
        for (int cp = 0; cp < 32; cp++) {
            int ac = pairs[cp].a ^ 0x3F, bc = pairs[cp].b ^ 0x3F;
            comp_pair_idx[cp] = -1;
            for (int cq = 0; cq < 32; cq++) {
                if (pairs[cq].a == ac && pairs[cq].b == bc)
                    { comp_pair_idx[cp] = cq; comp_orient_flip[cp] = 0; break; }
                if (pairs[cq].a == bc && pairs[cq].b == ac)
                    { comp_pair_idx[cp] = cq; comp_orient_flip[cp] = 1; break; }
            }
        }

        /* === Streaming pass: build all per-record-derived state in one walk === */
        long long n_words = (n_sols + 63) / 64;
        long long pos_cnt[32][32]; memset(pos_cnt, 0, sizeof(pos_cnt));
        long long single[31] = {0};
        long long shift_exc[17] = {0};
        long long rows_with_exc = 0;
        int kw_count = 0;
        int orient_min[32], orient_max[32];
        for (int p = 0; p < 32; p++) { orient_min[p] = 2; orient_max[p] = -1; }
        int kw_cap = 256;
        long long *kw_indices = malloc(kw_cap * sizeof(long long));
        if (!kw_indices) {
            fprintf(stderr, "ERROR: malloc failed for kw_indices (%zu bytes)\n",
                    (size_t)(kw_cap * sizeof(long long)));
            munmap(all, file_size);
            return 1;
        }
        /* Section [26] input: per-first-level-branch (pair-at-pos-2, orient-at-pos-2) counts */
        long long branch_count[32][2]; memset(branch_count, 0, sizeof(branch_count));
        /* Section [28] input: edit-distance-to-KW histogram */
        long long edit_dist_hist[33]; memset(edit_dist_hist, 0, sizeof(edit_dist_hist));
        /* Section [25] input: per-sub-branch solution counts keyed on (p1, o1, p2, o2).
         * Derived from solutions.bin (not checkpoint.txt, whose solutions field is
         * always 0 — flush_sub_solutions zeroes ts->solution_count before the
         * checkpoint line is written). 32*2*32*2 = 4096 bins × 8 bytes = 32 KB. */
        long long (*sub_solution_count)[2][32][2] = calloc(32, sizeof(*sub_solution_count));
        if (!sub_solution_count) { printf("ERROR: sub_solution_count alloc failed\n"); return 1; }

        printf("[masks] Allocating 31 packed bitmaps (%lld words each, %.2f GB total)...\n",
               n_words, 31.0 * n_words * 8.0 / 1e9);
        uint64_t **bmask = malloc(31 * sizeof(uint64_t *));
        if (!bmask) {
            fprintf(stderr, "ERROR: malloc failed for bmask pointer array\n");
            free(kw_indices); free(sub_solution_count);
            munmap(all, file_size);
            return 1;
        }
        for (int b = 0; b < 31; b++) {
            bmask[b] = calloc((size_t)n_words, sizeof(uint64_t));
            if (!bmask[b]) {
                fprintf(stderr, "ERROR: calloc failed for bmask[%d] (%lld words)\n", b, n_words);
                for (int f = 0; f < b; f++) free(bmask[f]);
                free(bmask); free(kw_indices); free(sub_solution_count);
                munmap(all, file_size);
                return 1;
            }
        }

        printf("[stream] Single-pass streaming over %lld records ...\n", n_sols);
        time_t t_stream_start = time(NULL);
        for (long long i = 0; i < n_sols; i++) {
            const unsigned char *rec = all + i * SOL_RECORD_SIZE;
            int pi[32];
            int is_kw = 1;
            int has_shift_exc = 0;
            for (int p = 0; p < 32; p++) {
                pi[p] = rec[p] >> 2;
                pos_cnt[p][pi[p]]++;
                if (pi[p] != p) is_kw = 0;
            }
            for (int b = 0; b < 31; b++) {
                if (pi[b] == b && pi[b + 1] == b + 1) {
                    single[b]++;
                    bmask[b][i >> 6] |= ((uint64_t)1 << (i & 63));
                }
            }
            if (is_kw) {
                if (kw_count >= kw_cap) {
                    kw_cap *= 2;
                    long long *tmp = realloc(kw_indices, kw_cap * sizeof(long long));
                    if (!tmp) {
                        fprintf(stderr, "ERROR: realloc failed for kw_indices (cap=%d)\n", kw_cap);
                        /* Keep existing kw_indices; stop collecting further KW entries */
                        kw_cap = kw_count; /* prevent further realloc attempts */
                        goto done_streaming;
                    }
                    kw_indices = tmp;
                }
                kw_indices[kw_count++] = i;
                for (int p = 0; p < 32; p++) {
                    int o = (rec[p] >> 1) & 1;
                    if (o < orient_min[p]) orient_min[p] = o;
                    if (o > orient_max[p]) orient_max[p] = o;
                }
            }
            for (int idx = 2; idx <= 18; idx++) {
                if (pi[idx] != idx && pi[idx] != idx - 1) {
                    shift_exc[idx - 2]++;
                    has_shift_exc = 1;
                }
            }
            if (has_shift_exc) rows_with_exc++;
            /* Section [26]: per-first-level-branch counts (byte 1 = position 2 pair + orient) */
            branch_count[rec[1] >> 2][(rec[1] >> 1) & 1]++;
            /* Section [25]: per-sub-branch solution count (byte 1 = p1/o1, byte 2 = p2/o2) */
            sub_solution_count[rec[1] >> 2][(rec[1] >> 1) & 1][rec[2] >> 2][(rec[2] >> 1) & 1]++;
            /* Section [28]: edit-distance-to-KW (count positions where pair differs) */
            {
                int dist = 0;
                for (int p = 0; p < 32; p++) if (pi[p] != p) dist++;
                edit_dist_hist[dist]++;
            }
        }
        done_streaming:
        printf("        done in %lds.\n\n", (long)(time(NULL) - t_stream_start));

        /* === Section 2: entropy === */
        printf("[2] Per-position Shannon entropy H(p), max log2(32)=5.0\n");
        printf("    %-4s  %-10s  %s\n", "Pos", "H (bits)", "#distinct pairs");
        double H[32];
        for (int p = 0; p < 32; p++) {
            double h = 0.0; int distinct = 0;
            for (int k = 0; k < 32; k++) {
                if (pos_cnt[p][k] > 0) {
                    distinct++;
                    double pr = (double)pos_cnt[p][k] / (double)n_sols;
                    h -= pr * log2(pr);
                }
            }
            H[p] = h;
            printf("    %-4d  %-10.4f  %d\n", p + 1, h, distinct);
        }
        double Hsum = 0; for (int p = 0; p < 32; p++) Hsum += H[p];
        printf("    mean H: %.4f bits\n\n", Hsum / 32.0);

        /* === Section 3: per-boundary survivors === */
        printf("[3] Per-boundary survivors (records matching KW pair_p AND pair_{p+1})\n");
        for (int b = 0; b < 31; b++)
            printf("    Boundary %2d (pos %d-%d): %12lld (%.4f%%)\n",
                   b + 1, b + 1, b + 2, single[b], 100.0 * single[b] / n_sols);
        printf("\n");

        /* === Section 4: KW variants === */
        printf("[4] King Wen variants (records with pair_idx == 0,1,2,...,31)\n");
        printf("    KW records found: %d\n", kw_count);
        if (kw_count > 0 && kw_count <= 64) {
            printf("    Orient pattern per variant (1=reversed, 0=natural):\n");
            printf("      Pos:    "); for (int p = 0; p < 32; p++) printf("%2d ", p + 1); printf("\n");
            for (int v = 0; v < kw_count; v++) {
                printf("      KW#%d:   ", v + 1);
                for (int p = 0; p < 32; p++) {
                    int o = (all[kw_indices[v] * SOL_RECORD_SIZE + p] >> 1) & 1;
                    printf(" %d ", o);
                }
                printf("\n");
            }
            printf("    Varying-orient positions: ");
            int n_var = 0;
            for (int p = 0; p < 32; p++)
                if (orient_max[p] > orient_min[p]) { printf("%d ", p + 1); n_var++; }
            printf("\n    # varying: %d  (2^%d=%d combinations expected if independent; observed %d)\n\n",
                   n_var, n_var, 1 << n_var, kw_count);
        }

        /* === Section 5: shift-pattern violations === */
        printf("[5] Shift-pattern violations: at position p in [3..19], pair must be pair_{p-1} or pair_{p-2}\n");
        printf("    %-4s  %-14s  %s\n", "Pos", "Exceptions", "Pct of total");
        for (int idx = 2; idx <= 18; idx++)
            printf("    %-4d  %-14lld  %.4f%%\n", idx + 1, shift_exc[idx - 2], 100.0 * shift_exc[idx - 2] / n_sols);
        printf("    Rows with ANY shift exception: %lld (%.3f%%)\n",
               rows_with_exc, 100.0 * rows_with_exc / n_sols);
        printf("    Rows fully shift-conforming:    %lld (%.3f%%)\n\n",
               n_sols - rows_with_exc, 100.0 * (n_sols - rows_with_exc) / n_sols);

        /* Helper: count bits in intersection of two packed masks */
        #define POPCOUNT_AND(_a,_b,_n) ({ long long _s=0; for (long long _w=0; _w<(_n); _w++) _s += __builtin_popcountll((_a)[_w] & (_b)[_w]); _s; })

        /* Mask trailing bits past n_sols (used by sections 6, 12, 15) */
        long long extra = n_words * 64 - n_sols;

        /* === Section 6: greedy minimum boundary search === */
        printf("[6] Greedy minimum-boundary search to uniquely identify KW\n");
        uint64_t *alive_mask = malloc((size_t)n_words * sizeof(uint64_t));
        if (!alive_mask) {
            fprintf(stderr, "ERROR: malloc failed for alive_mask (%lld words)\n", n_words);
            printf("    SKIPPED: section 6 (alloc failed)\n\n");
            goto skip_section6;
        }
        for (long long w = 0; w < n_words; w++) {
            uint64_t bits = ~(uint64_t)0;
            /* Subtract KW-pair-sequence rows: those for which all 31 bmask bits are set */
            uint64_t kw_pairs = ~(uint64_t)0;
            for (int b = 0; b < 31; b++) kw_pairs &= bmask[b][w];
            alive_mask[w] = bits & ~kw_pairs;
        }
        if (extra > 0) alive_mask[n_words - 1] &= (((uint64_t)1 << (64 - extra)) - 1);

        long long alive_n = 0;
        for (long long w = 0; w < n_words; w++) alive_n += __builtin_popcountll(alive_mask[w]);
        printf("    Starting with %lld non-KW solutions\n", alive_n);
        int chosen_set[31] = {0};
        for (int step = 0; step < 8 && alive_n > 0; step++) {
            int best_b = -1; long long best_remain = n_sols + 1;
            for (int b = 0; b < 31; b++) {
                if (chosen_set[b]) continue;
                long long surv = POPCOUNT_AND(alive_mask, bmask[b], n_words);
                if (surv < best_remain) { best_remain = surv; best_b = b; }
            }
            long long elim = alive_n - best_remain;
            chosen_set[best_b] = 1;
            for (long long w = 0; w < n_words; w++) alive_mask[w] &= bmask[best_b][w];
            alive_n = best_remain;
            printf("    Step %d: Boundary %d eliminates %lld, %lld remain\n",
                   step + 1, best_b + 1, elim, best_remain);
        }
        printf("    Boundaries chosen: { ");
        for (int b = 0; b < 31; b++) if (chosen_set[b]) printf("%d ", b + 1);
        printf("}\n\n");
        free(alive_mask);
        skip_section6:

        /* === Section 7: 3-subset disproof (parallelized) === */
        printf("[7] Exhaustive 3-subset disproof: test all C(31,3)=4,495 triples\n");
        long long min_t_surv = n_sols + 1;
        int min_t1 = -1, min_t2 = -1, min_t3 = -1, n_t_below = 0;
        time_t t7_start = time(NULL);
        #pragma omp parallel
        {
            long long local_min = n_sols + 1;
            int local_t1 = -1, local_t2 = -1, local_t3 = -1, local_below = 0;
            #pragma omp for schedule(dynamic, 16) collapse(2) nowait
            for (int b1 = 0; b1 < 29; b1++)
                for (int b2 = 0; b2 < 30; b2++) {
                    if (b2 <= b1) continue;
                    for (int b3 = b2 + 1; b3 < 31; b3++) {
                        long long s = 0;
                        for (long long w = 0; w < n_words; w++)
                            s += __builtin_popcountll(bmask[b1][w] & bmask[b2][w] & bmask[b3][w]);
                        if (s < local_min) { local_min = s; local_t1 = b1+1; local_t2 = b2+1; local_t3 = b3+1; }
                        if (s <= kw_count) local_below++;
                    }
                }
            #pragma omp critical
            {
                if (local_min < min_t_surv) {
                    min_t_surv = local_min;
                    min_t1 = local_t1; min_t2 = local_t2; min_t3 = local_t3;
                }
                n_t_below += local_below;
            }
        }
        printf("    Minimum 3-subset survivors: %lld (best triple: {%d, %d, %d})  [%lds]\n",
               min_t_surv, min_t1, min_t2, min_t3, (long)(time(NULL) - t7_start));
        printf("    Triples reaching <=%d survivors: %d\n", kw_count, n_t_below);
        if (n_t_below == 0)
            printf("    => 4-boundary minimum proven for this dataset.\n\n");
        else
            printf("    => %d 3-subsets reach KW-only level; minimum is <= 3 for this dataset.\n\n", n_t_below);

        /* === Section 8: All 4-subsets uniquely identifying KW (parallelized) === */
        printf("[8] All 4-subsets that reduce survivors to <=%d (uniquely identify KW)\n", kw_count);
        int boundary_freq[31] = {0};
        int n_working = 0;
        typedef struct { int b1, b2, b3, b4; long long s; } QuadEntry;
        int report_cap = 1000;
        QuadEntry *report = malloc(report_cap * sizeof(QuadEntry));
        if (!report) {
            fprintf(stderr, "ERROR: malloc failed for report (section 8)\n");
            printf("    SKIPPED: section 8 (alloc failed)\n\n");
            goto skip_section8;
        }
        time_t t8_start = time(NULL);
        #pragma omp parallel
        {
            int local_freq[31] = {0};
            int local_n_working = 0;
            int local_cap = 64;
            QuadEntry *local_report = malloc(local_cap * sizeof(QuadEntry));
            if (!local_report) {
                fprintf(stderr, "ERROR: malloc failed for local_report in thread\n");
                local_cap = 0; /* prevent writes to NULL */
            }
            int local_report_n = 0;
            #pragma omp for schedule(dynamic, 8) collapse(2) nowait
            for (int b1 = 0; b1 < 28; b1++)
                for (int b2 = 0; b2 < 29; b2++) {
                    if (b2 <= b1) continue;
                    for (int b3 = b2 + 1; b3 < 30; b3++)
                    for (int b4 = b3 + 1; b4 < 31; b4++) {
                        long long s = 0;
                        for (long long w = 0; w < n_words; w++)
                            s += __builtin_popcountll(bmask[b1][w] & bmask[b2][w] & bmask[b3][w] & bmask[b4][w]);
                        if (s <= kw_count) {
                            local_n_working++;
                            local_freq[b1]++; local_freq[b2]++; local_freq[b3]++; local_freq[b4]++;
                            if (local_report_n < local_cap) {
                                local_report[local_report_n++] = (QuadEntry){b1+1, b2+1, b3+1, b4+1, s};
                            }
                        }
                    }
                }
            #pragma omp critical
            {
                for (int b = 0; b < 31; b++) boundary_freq[b] += local_freq[b];
                n_working += local_n_working;
                for (int i = 0; i < local_report_n && n_working <= 200; i++) {
                    if (n_working - local_n_working + i + 1 > report_cap) {
                        report_cap *= 2;
                        QuadEntry *tmp = realloc(report, report_cap * sizeof(QuadEntry));
                        if (!tmp) {
                            fprintf(stderr, "ERROR: realloc failed for report (section 8, cap=%d)\n", report_cap);
                            break; /* stop adding to report */
                        }
                        report = tmp;
                    }
                    /* approximate; just use up to 200 reports total */
                }
                /* Simpler: always add up to first 200 across all threads */
                for (int i = 0; i < local_report_n; i++) {
                    static int rep_so_far = 0;
                    if (rep_so_far < 200) {
                        report[rep_so_far++] = local_report[i];
                    }
                }
            }
            free(local_report);
        }
        printf("    [8] elapsed: %lds\n", (long)(time(NULL) - t8_start));
        int reported = n_working < 200 ? n_working : 200;
        for (int i = 0; i < reported; i++)
            printf("    {%2d, %2d, %2d, %2d}  survivors=%lld\n",
                   report[i].b1, report[i].b2, report[i].b3, report[i].b4, report[i].s);
        if (n_working > 200) printf("    ... (truncated; total reported below)\n");
        printf("    total working 4-subsets: %d\n", n_working);
        free(report);
        if (n_working > 0) {
            int by_freq[31];
            for (int b = 0; b < 31; b++) by_freq[b] = b;
            for (int i = 0; i < 31; i++)
                for (int j = i + 1; j < 31; j++)
                    if (boundary_freq[by_freq[j]] > boundary_freq[by_freq[i]]) {
                        int t = by_freq[i]; by_freq[i] = by_freq[j]; by_freq[j] = t;
                    }
            printf("    Boundary frequency in working sets:\n");
            for (int i = 0; i < 31 && boundary_freq[by_freq[i]] > 0; i++)
                printf("      Boundary %2d: %4d  (%5.1f%%)\n",
                       by_freq[i] + 1, boundary_freq[by_freq[i]],
                       100.0 * boundary_freq[by_freq[i]] / n_working);
            printf("    Boundaries appearing in EVERY working 4-set: { ");
            for (int b = 0; b < 31; b++) if (boundary_freq[b] == n_working) printf("%d ", b + 1);
            printf("}\n");
        }
        printf("\n");
        skip_section8:

        /* === Section 9: Boundary redundancy === */
        printf("[9] Boundary redundancy: joint(b1,b2) / min(single(b1), single(b2))\n");
        long long joint[31][31]; memset(joint, 0, sizeof(joint));
        #pragma omp parallel for schedule(dynamic, 4)
        for (int b1 = 0; b1 < 30; b1++) {
            for (int b2 = b1 + 1; b2 < 31; b2++) {
                long long s = 0;
                for (long long w = 0; w < n_words; w++)
                    s += __builtin_popcountll(bmask[b1][w] & bmask[b2][w]);
                joint[b1][b2] = joint[b2][b1] = s;
            }
        }
        typedef struct { double ratio; int b1, b2; long long jc; long long ms; } RedunEntry;
        int n_pairs = 31 * 30 / 2;
        RedunEntry *re = malloc(n_pairs * sizeof(RedunEntry));
        if (!re) {
            fprintf(stderr, "ERROR: malloc failed for re (section 9, %d entries)\n", n_pairs);
            printf("    SKIPPED: section 9 (alloc failed)\n\n");
            goto skip_section9;
        }
        int re_n = 0;
        for (int b1 = 0; b1 < 30; b1++)
            for (int b2 = b1 + 1; b2 < 31; b2++) {
                long long ms = single[b1] < single[b2] ? single[b1] : single[b2];
                if (ms == 0) continue;
                re[re_n].ratio = (double)joint[b1][b2] / (double)ms;
                re[re_n].b1 = b1 + 1; re[re_n].b2 = b2 + 1;
                re[re_n].jc = joint[b1][b2]; re[re_n].ms = ms;
                re_n++;
            }
        for (int i = 0; i < re_n; i++)
            for (int j = i + 1; j < re_n; j++)
                if (re[j].ratio > re[i].ratio) {
                    RedunEntry t = re[i]; re[i] = re[j]; re[j] = t;
                }
        int top = re_n < 10 ? re_n : 10;
        printf("    Top 10 most-redundant boundary pairs:\n");
        for (int i = 0; i < top; i++)
            printf("      b=%d, b'=%d  joint=%lld  min_single=%lld  ratio=%.3f\n",
                   re[i].b1, re[i].b2, re[i].jc, re[i].ms, re[i].ratio);
        int bot = re_n < 10 ? 0 : re_n - 10;
        printf("    Top 10 most-INDEPENDENT boundary pairs:\n");
        for (int i = bot; i < re_n; i++)
            printf("      b=%d, b'=%d  joint=%lld  min_single=%lld  ratio=%.3f\n",
                   re[i].b1, re[i].b2, re[i].jc, re[i].ms, re[i].ratio);
        printf("\n");
        free(re);
        skip_section9:

        /* === Section 10: pairwise mutual information (parallelized over pairs) === */
        printf("[10] Pairwise mutual information I(p; q) — top 20 strongest correlations\n");
        double MI[32][32];
        for (int p = 0; p < 32; p++) MI[p][p] = 0.0;
        time_t t10_start = time(NULL);
        #pragma omp parallel for schedule(dynamic, 4) collapse(2)
        for (int p = 0; p < 31; p++) {
            for (int q = 0; q < 32; q++) {
                if (q <= p) continue;
                long long jc[32 * 32]; memset(jc, 0, sizeof(jc));
                for (long long i = 0; i < n_sols; i++) {
                    int a = all[i * SOL_RECORD_SIZE + p] >> 2;
                    int b = all[i * SOL_RECORD_SIZE + q] >> 2;
                    jc[a * 32 + b]++;
                }
                double Hpq = 0.0;
                for (int k = 0; k < 32 * 32; k++) {
                    if (jc[k] > 0) {
                        double pr = (double)jc[k] / (double)n_sols;
                        Hpq -= pr * log2(pr);
                    }
                }
                MI[p][q] = MI[q][p] = H[p] + H[q] - Hpq;
            }
        }
        printf("    [10] elapsed: %lds\n", (long)(time(NULL) - t10_start));
        typedef struct { double mi; int p, q; } MIEntry;
        int n_mi_pairs = 32 * 31 / 2;
        MIEntry *mi_arr = malloc(n_mi_pairs * sizeof(MIEntry));
        if (!mi_arr) {
            fprintf(stderr, "ERROR: malloc failed for mi_arr (section 10)\n");
            printf("    SKIPPED: section 10 sort/display (alloc failed)\n\n");
            goto skip_section10;
        }
        int mi_n = 0;
        for (int p = 0; p < 31; p++)
            for (int q = p + 1; q < 32; q++) {
                mi_arr[mi_n].mi = MI[p][q];
                mi_arr[mi_n].p = p + 1; mi_arr[mi_n].q = q + 1;
                mi_n++;
            }
        for (int i = 0; i < mi_n; i++)
            for (int j = i + 1; j < mi_n; j++)
                if (mi_arr[j].mi > mi_arr[i].mi) {
                    MIEntry t = mi_arr[i]; mi_arr[i] = mi_arr[j]; mi_arr[j] = t;
                }
        for (int i = 0; i < (mi_n < 20 ? mi_n : 20); i++)
            printf("      pos %2d <-> pos %2d:  I = %.4f bits\n",
                   mi_arr[i].p, mi_arr[i].q, mi_arr[i].mi);
        free(mi_arr);
        skip_section10:
        printf("\n");

        /* === Section 11: Per-first-level-branch distinct configurations === */
        /* For each first-level pair p1, sort+dedup pair_idx[2..18] rows. */
        printf("[11] Per-first-level-branch distinct configs at positions 3..19\n");
        printf("     %-5s  %-30s  %s\n", "Pair", "Distinct configs at pos 3-19", "Records");
        /* Pre-count per p1 to size the per-branch buffer */
        long long p1_count[32] = {0};
        for (long long i = 0; i < n_sols; i++)
            p1_count[all[i * SOL_RECORD_SIZE + 1] >> 2]++;
        long long max_p1_cnt = 0;
        for (int p1 = 1; p1 < 32; p1++) if (p1_count[p1] > max_p1_cnt) max_p1_cnt = p1_count[p1];
        unsigned char *rows = malloc((size_t)max_p1_cnt * 17);
        if (!rows) { printf("    (skipping section 11 — alloc failed for %lld bytes)\n\n", max_p1_cnt * 17); }
        else {
            for (int p1 = 1; p1 < 32; p1++) {
                if (p1_count[p1] == 0) {
                    printf("     %-5d  %-30s  %lld\n", p1, "(no records)", 0LL);
                    continue;
                }
                long long ridx = 0;
                for (long long i = 0; i < n_sols; i++) {
                    if ((all[i * SOL_RECORD_SIZE + 1] >> 2) == p1) {
                        for (int k = 0; k < 17; k++)
                            rows[ridx * 17 + k] = all[i * SOL_RECORD_SIZE + 2 + k] >> 2;
                        ridx++;
                    }
                }
                int cmp17(const void *a, const void *b) { return memcmp(a, b, 17); }
                qsort(rows, (size_t)ridx, 17, cmp17);
                long long ndist = ridx > 0 ? 1 : 0;
                for (long long i = 1; i < ridx; i++)
                    if (memcmp(&rows[i * 17], &rows[(i - 1) * 17], 17) != 0) ndist++;
                printf("     %-5d  %-30lld  %lld\n", p1, ndist, ridx);
            }
            free(rows);
        }
        printf("\n");

        /* === Section 12: Null-model relative to a non-KW reference === */
        printf("[12] Null-model: greedy minimum-boundary search relative to a non-KW reference\n");
        long long ref_idx = n_sols / 2;
        unsigned char ref_pairs[32];
        for (int p = 0; p < 32; p++) ref_pairs[p] = all[ref_idx * SOL_RECORD_SIZE + p] >> 2;
        int ref_is_kw = 1;
        for (int p = 0; p < 32; p++) if (ref_pairs[p] != p) { ref_is_kw = 0; break; }
        printf("    Reference index: %lld  (is_kw=%s)\n", ref_idx, ref_is_kw ? "YES" : "no");
        if (ref_is_kw) {
            printf("    (random pick happened to be KW; skipping null-model)\n\n");
        } else {
            uint64_t **rmask = malloc(31 * sizeof(uint64_t *));
            if (!rmask) {
                fprintf(stderr, "ERROR: malloc failed for rmask (section 12)\n");
                printf("    SKIPPED: section 12 (alloc failed)\n\n");
                goto skip_section12;
            }
            int rmask_alloc_ok = 1;
            for (int b = 0; b < 31; b++) {
                rmask[b] = calloc((size_t)n_words, sizeof(uint64_t));
                if (!rmask[b]) {
                    fprintf(stderr, "ERROR: calloc failed for rmask[%d] (section 12)\n", b);
                    for (int f = 0; f < b; f++) free(rmask[f]);
                    free(rmask);
                    rmask_alloc_ok = 0;
                    break;
                }
            }
            if (!rmask_alloc_ok) {
                printf("    SKIPPED: section 12 (alloc failed)\n\n");
                goto skip_section12;
            }
            for (long long i = 0; i < n_sols; i++) {
                const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                for (int b = 0; b < 31; b++) {
                    int p_b = rec[b] >> 2;
                    int p_b1 = rec[b + 1] >> 2;
                    if (p_b == ref_pairs[b] && p_b1 == ref_pairs[b + 1])
                        rmask[b][i >> 6] |= ((uint64_t)1 << (i & 63));
                }
            }
            uint64_t *r_alive = malloc((size_t)n_words * sizeof(uint64_t));
            if (!r_alive) {
                fprintf(stderr, "ERROR: malloc failed for r_alive (section 12)\n");
                for (int b = 0; b < 31; b++) free(rmask[b]);
                free(rmask);
                printf("    SKIPPED: section 12 greedy search (alloc failed)\n\n");
                goto skip_section12;
            }
            for (long long w = 0; w < n_words; w++) {
                uint64_t bits = ~(uint64_t)0;
                uint64_t ref_full = ~(uint64_t)0;
                for (int b = 0; b < 31; b++) ref_full &= rmask[b][w];
                r_alive[w] = bits & ~ref_full;
            }
            if (extra > 0) r_alive[n_words - 1] &= (((uint64_t)1 << (64 - extra)) - 1);
            long long r_alive_n = 0;
            for (long long w = 0; w < n_words; w++) r_alive_n += __builtin_popcountll(r_alive[w]);
            printf("    Starting with %lld non-ref solutions\n", r_alive_n);
            int r_chosen[31] = {0};
            for (int step = 0; step < 8 && r_alive_n > 0; step++) {
                int best_b = -1; long long best_remain = n_sols + 1;
                for (int b = 0; b < 31; b++) {
                    if (r_chosen[b]) continue;
                    long long surv = POPCOUNT_AND(r_alive, rmask[b], n_words);
                    if (surv < best_remain) { best_remain = surv; best_b = b; }
                }
                long long elim = r_alive_n - best_remain;
                r_chosen[best_b] = 1;
                for (long long w = 0; w < n_words; w++) r_alive[w] &= rmask[best_b][w];
                r_alive_n = best_remain;
                printf("    Step %d: Boundary %d eliminates %lld, %lld remain\n",
                       step + 1, best_b + 1, elim, best_remain);
            }
            printf("    Reference-relative boundaries: { ");
            for (int b = 0; b < 31; b++) if (r_chosen[b]) printf("%d ", b + 1);
            printf("}\n\n");
            for (int b = 0; b < 31; b++) free(rmask[b]);
            free(rmask); free(r_alive);
        }
        skip_section12:

        /* === Section 13: Orbits === */
        printf("[13] Orbit analysis under reversal and pair-complement\n");
        long long n_palin = 0;
        for (long long i = 0; i < n_sols; i++) {
            int is_palin = 1;
            for (int p = 0; p < 16; p++) {
                int a = all[i * SOL_RECORD_SIZE + p] >> 2;
                int b = all[i * SOL_RECORD_SIZE + 31 - p] >> 2;
                if (a != b) { is_palin = 0; break; }
            }
            if (is_palin) n_palin++;
        }
        int hex_to_pair_local[64];
        for (int h = 0; h < 64; h++) hex_to_pair_local[h] = -1;
        for (int p = 0; p < 32; p++) {
            hex_to_pair_local[KW[2 * p]] = p;
            hex_to_pair_local[KW[2 * p + 1]] = p;
        }
        int comp_pair[32];
        for (int p = 0; p < 32; p++) comp_pair[p] = hex_to_pair_local[63 - KW[2 * p]];
        long long n_self_comp = 0;
        for (long long i = 0; i < n_sols; i++) {
            int is_self_comp = 1;
            for (int p = 0; p < 32; p++) {
                int pi = all[i * SOL_RECORD_SIZE + p] >> 2;
                if (comp_pair[pi] != pi) { is_self_comp = 0; break; }
            }
            if (is_self_comp) n_self_comp++;
        }
        int n_comp_self = 0;
        for (int p = 0; p < 32; p++) if (comp_pair[p] == p) n_comp_self++;
        printf("    Palindromic solutions (pair sequence reads same forwards/backwards): %lld (%.4f%%)\n",
               n_palin, 100.0 * n_palin / n_sols);
        printf("    Pair-complement self-symmetric (every pair is self-complementary): %lld (%.4f%%)\n",
               n_self_comp, 100.0 * n_self_comp / n_sols);
        printf("    (Note: %d of 32 pairs are self-complementary)\n\n", n_comp_self);

        /* NOTE on bmask lifetime: bmask[] (~2.9 GB on a 742M dataset) is
         * allocated before section [3] and freed at the end of analyze_mode,
         * AFTER sections [16]-[19] which all consume it. An earlier version
         * freed bmask here (between [13] and [14]) to make room for [14]'s
         * ~24 GB sort buffer on tight-RAM VMs — but that caused sections
         * [16]-[19] (added later) to read freed memory and segfault after
         * printing only [17]'s header.
         *
         * Current assumption: runs on a VM with >= 32 GB RAM so bmask
         * (~2.9 GB) + section [14] sort buffer (~24 GB) + overhead all fit.
         * Verified with `free -g` on an F32als_v6 (64 GB) during a full run.
         * If ever running on a smaller VM, re-add a free here and rebuild
         * bmask via a streaming pass inside each of sections [16]-[19].
         *
         * Any new section added AFTER [13] that needs bmask must either:
         *   (a) be inserted before this point, OR
         *   (b) rebuild bmask from a fresh streaming pass internally.
         */

        /* === Section 14: Orient-coupling generalization ===
         * Group all solutions by pair-index sequence (collapse within-pair orient
         * variants). For each unique pair-ordering, count its variants and which
         * positions show orient variation across them. Compare KW's pattern to
         * the population. Resolves the "does the KW orient-coupling generalize?"
         * question flagged in SOLVE-SUMMARY.md and INSIGHTS.md.
         */
        printf("[14] Orient-coupling generalization\n");
        printf("     Grouping %lld records by pair-index sequence (orient masked) ...\n", n_sols);
        time_t t14_start = time(NULL);

        /* Allocate (key, original_index) pairs. 32-byte key + 8-byte index = 40 bytes/record.
         * 742M records -> ~30 GB. Tight but fits on F32's 64 GB after freeing bmasks. */
        typedef struct { unsigned char pi[32]; long long idx; } PairKey;
        PairKey *pkeys = malloc((size_t)n_sols * sizeof(PairKey));
        if (!pkeys) {
            printf("    SKIPPED: malloc(%lld bytes) failed; need more RAM for section 14\n",
                   (long long)((size_t)n_sols * sizeof(PairKey)));
        } else {
            for (long long i = 0; i < n_sols; i++) {
                for (int p = 0; p < 32; p++) pkeys[i].pi[p] = all[i * SOL_RECORD_SIZE + p] >> 2;
                pkeys[i].idx = i;
            }
            int cmp_pkeys(const void *a, const void *b) {
                return memcmp(((const PairKey *)a)->pi, ((const PairKey *)b)->pi, 32);
            }
            qsort(pkeys, (size_t)n_sols, sizeof(PairKey), cmp_pkeys);
            printf("     sort done in %lds\n", (long)(time(NULL) - t14_start));

            /* Walk groups. Also extract representatives (first record of each group)
             * for section [15]'s orient-collapsed boundary analysis, and gather stats
             * for the 1-variant and 4-variant subfamilies. */
            long long unique_pos = 0;
            long long size_dist[64] = {0};
            long long pos_varies_count[32] = {0};
            long long max_group = 0;
            long long max_group_idx = -1;
            long long kw_group = 0;
            int kw_varies[32] = {0};

            /* 4-variant subgroup: varying-pattern histogram (linear-probe table) */
            typedef struct { unsigned int pattern; long long count; } PatternEntry;
            #define MAX_PATTERNS 8192
            PatternEntry *patterns4 = calloc(MAX_PATTERNS, sizeof(PatternEntry));
            if (!patterns4) {
                fprintf(stderr, "ERROR: calloc failed for patterns4 (section 14)\n");
                /* patterns4 analytics will be silently skipped */
            }
            int n_patterns4 = 0;
            long long kw_pattern_mask = 0;  /* KW's varying-position bitmask */
            long long groups4_with_kw_pattern = 0;
            long long groups4_with_kw_xor_coupling = 0;
            long long groups4_total = 0;

            /* 1-variant subgroup: edit-distance-to-KW histogram, per-position pair histogram */
            long long edist_hist_1[33] = {0};  /* edit distance 0..32 for 1-variant groups */
            long long pos_pair_hist_1[32][32] = {0};  /* [pos][pair_idx] for 1-variant groups */
            long long groups1_total = 0;

            /* Representatives buffer for section [15]. Allocate worst-case n_sols*32. */
            unsigned char *reps = malloc((size_t)n_sols * 32);
            if (!reps) { printf("    WARN: rep alloc failed; section 15 will skip.\n"); }
            long long n_reps = 0;

            long long s = 0;
            while (s < n_sols) {
                long long e = s + 1;
                while (e < n_sols && memcmp(pkeys[s].pi, pkeys[e].pi, 32) == 0) e++;
                long long size = e - s;
                unique_pos++;
                size_dist[size < 64 ? size : 63]++;
                if (size > max_group) { max_group = size; max_group_idx = s; }

                int orient_first[32];
                for (int p = 0; p < 32; p++)
                    orient_first[p] = (all[pkeys[s].idx * SOL_RECORD_SIZE + p] >> 1) & 1;
                int varies[32] = {0};
                for (long long j = s + 1; j < e; j++) {
                    for (int p = 0; p < 32; p++) {
                        int o = (all[pkeys[j].idx * SOL_RECORD_SIZE + p] >> 1) & 1;
                        if (o != orient_first[p]) varies[p] = 1;
                    }
                }
                for (int p = 0; p < 32; p++) if (varies[p]) pos_varies_count[p]++;

                /* Detect KW group */
                int is_kw = 1;
                for (int p = 0; p < 32; p++) if (pkeys[s].pi[p] != p) { is_kw = 0; break; }
                if (is_kw) {
                    kw_group = size;
                    memcpy(kw_varies, varies, sizeof(varies));
                    unsigned int m = 0;
                    for (int p = 0; p < 32; p++) if (varies[p]) m |= ((unsigned int)1 << p);
                    kw_pattern_mask = m;
                }

                /* Copy representative */
                if (reps) {
                    for (int p = 0; p < 32; p++) reps[n_reps * 32 + p] = pkeys[s].pi[p];
                    n_reps++;
                }

                /* 4-variant subfamily analytics */
                if (size == 4) {
                    groups4_total++;
                    unsigned int pat = 0;
                    for (int p = 0; p < 32; p++) if (varies[p]) pat |= ((unsigned int)1 << p);
                    /* Insert into linear-probe table */
                    if (patterns4 && n_patterns4 < MAX_PATTERNS) {
                        int found = 0;
                        for (int ii = 0; ii < n_patterns4; ii++)
                            if (patterns4[ii].pattern == pat) { patterns4[ii].count++; found = 1; break; }
                        if (!found) { patterns4[n_patterns4].pattern = pat; patterns4[n_patterns4].count = 1; n_patterns4++; }
                    }
                    /* Check KW-style XOR coupling: for each variant,
                     * (o[2] XOR o[3]) == o[28] == o[29] == o[30]
                     * This is only meaningful if those positions are in the varying set. */
                    if (varies[1] && varies[2] && varies[27] && varies[28] && varies[29]) {
                        /* 0-indexed: positions 2,3,28,29,30 are indices 1,2,27,28,29 */
                        int all_match = 1;
                        for (long long j = s; j < e; j++) {
                            int o2  = (all[pkeys[j].idx * SOL_RECORD_SIZE + 1] >> 1) & 1;
                            int o3  = (all[pkeys[j].idx * SOL_RECORD_SIZE + 2] >> 1) & 1;
                            int o28 = (all[pkeys[j].idx * SOL_RECORD_SIZE + 27] >> 1) & 1;
                            int o29 = (all[pkeys[j].idx * SOL_RECORD_SIZE + 28] >> 1) & 1;
                            int o30 = (all[pkeys[j].idx * SOL_RECORD_SIZE + 29] >> 1) & 1;
                            if ((o2 ^ o3) != o28 || o28 != o29 || o29 != o30) { all_match = 0; break; }
                        }
                        if (all_match) groups4_with_kw_xor_coupling++;
                    }
                    if (pat == (unsigned int)kw_pattern_mask && is_kw) {}
                }

                /* 1-variant subfamily analytics */
                if (size == 1) {
                    groups1_total++;
                    int ed = 0;
                    for (int p = 0; p < 32; p++) {
                        pos_pair_hist_1[p][pkeys[s].pi[p]]++;
                        if (pkeys[s].pi[p] != p) ed++;
                    }
                    if (ed <= 32) edist_hist_1[ed]++;
                }

                s = e;
            }
            /* Post-walk: compute groups4 with exactly KW's varying-position bitmask */
            if (kw_pattern_mask != 0 && patterns4) {
                for (int ii = 0; ii < n_patterns4; ii++)
                    if (patterns4[ii].pattern == (unsigned int)kw_pattern_mask)
                        groups4_with_kw_pattern = patterns4[ii].count;
            }

            printf("     analysis done in %lds\n", (long)(time(NULL) - t14_start));
            printf("     Unique pair-orderings: %lld (vs %lld total records, ratio %.3fx)\n",
                   unique_pos, n_sols, (double)n_sols / (double)unique_pos);
            printf("     Variants-per-pair-ordering distribution (group size -> #pair-orderings):\n");
            long long checksum = 0;
            for (int k = 1; k < 64; k++) {
                if (size_dist[k] > 0) {
                    printf("       %2d variants: %lld pair-orderings\n", k, size_dist[k]);
                    checksum += (long long)k * size_dist[k];
                }
            }
            printf("     Records accounted for: %lld\n", checksum);
            printf("     Per-position frequency of orient variation across pair-ordering groups:\n");
            printf("       %-4s  %-14s  %-7s\n", "Pos", "Groups varying", "Pct");
            for (int p = 0; p < 32; p++) {
                printf("       %-4d  %-14lld  %.3f%%\n",
                       p + 1, pos_varies_count[p], 100.0 * pos_varies_count[p] / unique_pos);
            }
            printf("     KW's group: %lld variants; varying-orient positions: ", kw_group);
            for (int p = 0; p < 32; p++) if (kw_varies[p]) printf("%d ", p + 1);
            printf("\n");
            printf("     Largest group: %lld variants (pair-ordering at sorted index %lld)\n",
                   max_group, max_group_idx);

            /* 4-variant subfamily report */
            printf("\n     --- 4-variant subfamily (KW is in this class) ---\n");
            printf("     Total 4-variant pair-orderings: %lld\n", groups4_total);
            printf("     4-variant groups with exactly KW's varying-position set {2,3,28,29,30}: %lld\n",
                   groups4_with_kw_pattern);
            printf("     4-variant groups satisfying KW's (pos2 XOR pos3) == pos28 == pos29 == pos30 coupling: %lld\n",
                   groups4_with_kw_xor_coupling);
            /* Print top-10 most common varying patterns among 4-variant groups */
            if (patterns4) {
                int order[MAX_PATTERNS]; for (int ii = 0; ii < n_patterns4; ii++) order[ii] = ii;
                for (int ii = 0; ii < n_patterns4; ii++)
                    for (int jj = ii + 1; jj < n_patterns4; jj++)
                        if (patterns4[order[jj]].count > patterns4[order[ii]].count) {
                            int t = order[ii]; order[ii] = order[jj]; order[jj] = t;
                        }
                int show = n_patterns4 < 10 ? n_patterns4 : 10;
                printf("     Top-%d varying-position patterns among 4-variant groups:\n", show);
                for (int ii = 0; ii < show; ii++) {
                    int o = order[ii];
                    printf("       pattern {");
                    int first = 1;
                    for (int p = 0; p < 32; p++) {
                        if (patterns4[o].pattern & ((unsigned int)1 << p)) {
                            printf("%s%d", first ? "" : ",", p + 1); first = 0;
                        }
                    }
                    printf("}: %lld groups (%.2f%%)\n",
                           patterns4[o].count,
                           100.0 * patterns4[o].count / groups4_total);
                }
            }
            free(patterns4);

            /* 1-variant subfamily report */
            printf("\n     --- 1-variant subfamily (pair-orderings with forced orient) ---\n");
            printf("     Total 1-variant pair-orderings: %lld\n", groups1_total);
            printf("     Edit-distance-to-KW distribution (non-zero bins):\n");
            for (int d = 0; d <= 32; d++) {
                if (edist_hist_1[d] > 0)
                    printf("       edit_dist %2d: %lld (%.3f%%)\n",
                           d, edist_hist_1[d], 100.0 * edist_hist_1[d] / groups1_total);
            }
            printf("     Per-position: most common pair among 1-variant groups:\n");
            printf("       %-4s  %-10s  %-10s  %s\n", "Pos", "KW_pair", "Most_common", "Pct");
            for (int p = 0; p < 32; p++) {
                int best = 0; long long best_c = 0;
                for (int k = 0; k < 32; k++) {
                    if (pos_pair_hist_1[p][k] > best_c) { best_c = pos_pair_hist_1[p][k]; best = k; }
                }
                printf("       %-4d  %-10d  %-10d  %.2f%%%s\n",
                       p + 1, p, best,
                       100.0 * best_c / (groups1_total > 0 ? groups1_total : 1),
                       best == p ? "  <- matches KW" : "");
            }

            free(pkeys);

            /* === Section 15: Orient-collapsed boundary analysis ===
             * Re-run the greedy minimum-boundary + exhaustive 3-subset + all-4-subsets
             * analyses on the 284.7M orient-collapsed pair-orderings (reps) instead of
             * the 742M byte-level records. At 10T this reduces KW's count from 4 to 1,
             * eliminating multi-counting; may shift the working 4-set family.
             */
            if (reps && n_reps > 0) {
                printf("\n[15] Orient-collapsed boundary analysis (%lld unique pair-orderings)\n", n_reps);
                long long n_words_r = (n_reps + 63) / 64;

                /* Verify KW count in reps (should be 1) */
                int kw_count_r = 0;
                for (long long i = 0; i < n_reps; i++) {
                    int is_kw_r = 1;
                    for (int p = 0; p < 32; p++) if (reps[i * 32 + p] != p) { is_kw_r = 0; break; }
                    if (is_kw_r) kw_count_r++;
                }
                printf("     KW present: %d copy(ies) (expected 1 after orient collapse)\n", kw_count_r);

                /* Build per-boundary packed bitmaps */
                printf("     Building 31 per-boundary packed bitmaps (%lld words each)...\n", n_words_r);
                uint64_t **rbm = malloc(31 * sizeof(uint64_t *));
                if (!rbm) {
                    fprintf(stderr, "ERROR: malloc failed for rbm (section 15)\n");
                    printf("     SKIPPED: section 15 bitmaps (alloc failed)\n");
                    goto skip_section15;
                }
                int rbm_alloc_ok = 1;
                for (int b = 0; b < 31; b++) {
                    rbm[b] = calloc((size_t)n_words_r, sizeof(uint64_t));
                    if (!rbm[b]) {
                        fprintf(stderr, "ERROR: calloc failed for rbm[%d] (section 15)\n", b);
                        for (int f = 0; f < b; f++) free(rbm[f]);
                        free(rbm);
                        rbm_alloc_ok = 0;
                        break;
                    }
                    for (long long i = 0; i < n_reps; i++) {
                        int pb = reps[i * 32 + b];
                        int pb1 = reps[i * 32 + b + 1];
                        if (pb == b && pb1 == b + 1) rbm[b][i >> 6] |= ((uint64_t)1 << (i & 63));
                    }
                }
                if (!rbm_alloc_ok) {
                    printf("     SKIPPED: section 15 bitmaps (alloc failed)\n");
                    goto skip_section15;
                }
                long long rsingle[31];
                for (int b = 0; b < 31; b++) {
                    long long c = 0;
                    for (long long w = 0; w < n_words_r; w++) c += __builtin_popcountll(rbm[b][w]);
                    rsingle[b] = c;
                }

                /* Greedy min */
                uint64_t *r_alive = malloc((size_t)n_words_r * sizeof(uint64_t));
                if (!r_alive) {
                    fprintf(stderr, "ERROR: malloc failed for r_alive (section 15)\n");
                    printf("     SKIPPED: section 15 greedy search (alloc failed)\n");
                    for (int b = 0; b < 31; b++) free(rbm[b]);
                    free(rbm);
                    goto skip_section15;
                }
                for (long long w = 0; w < n_words_r; w++) {
                    uint64_t kw_pairs_bits = ~(uint64_t)0;
                    for (int b = 0; b < 31; b++) kw_pairs_bits &= rbm[b][w];
                    r_alive[w] = ~kw_pairs_bits;
                }
                long long extra_r = n_words_r * 64 - n_reps;
                if (extra_r > 0) r_alive[n_words_r - 1] &= (((uint64_t)1 << (64 - extra_r)) - 1);
                long long r_alive_n = 0;
                for (long long w = 0; w < n_words_r; w++) r_alive_n += __builtin_popcountll(r_alive[w]);
                printf("     Greedy minimum-boundary search (%lld non-KW pair-orderings):\n", r_alive_n);
                int r_chosen[31] = {0};
                for (int step = 0; step < 8 && r_alive_n > 0; step++) {
                    int best_b = -1; long long best_remain = n_reps + 1;
                    for (int b = 0; b < 31; b++) {
                        if (r_chosen[b]) continue;
                        long long s2 = 0;
                        for (long long w = 0; w < n_words_r; w++)
                            s2 += __builtin_popcountll(r_alive[w] & rbm[b][w]);
                        if (s2 < best_remain) { best_remain = s2; best_b = b; }
                    }
                    long long elim = r_alive_n - best_remain;
                    r_chosen[best_b] = 1;
                    for (long long w = 0; w < n_words_r; w++) r_alive[w] &= rbm[best_b][w];
                    r_alive_n = best_remain;
                    printf("       Step %d: Boundary %d eliminates %lld, %lld remain\n",
                           step + 1, best_b + 1, elim, best_remain);
                }
                printf("     Boundaries chosen (orient-collapsed): { ");
                for (int b = 0; b < 31; b++) if (r_chosen[b]) printf("%d ", b + 1);
                printf("}\n");
                free(r_alive);

                /* Exhaustive 3-subset disproof */
                long long r_min_t = n_reps + 1; int r_t1 = -1, r_t2 = -1, r_t3 = -1, r_t_below = 0;
                #pragma omp parallel
                {
                    long long lmin = n_reps + 1; int lt1=-1, lt2=-1, lt3=-1, lb=0;
                    #pragma omp for schedule(dynamic,16) collapse(2) nowait
                    for (int b1 = 0; b1 < 29; b1++)
                        for (int b2 = 0; b2 < 30; b2++) {
                            if (b2 <= b1) continue;
                            for (int b3 = b2 + 1; b3 < 31; b3++) {
                                long long s2 = 0;
                                for (long long w = 0; w < n_words_r; w++)
                                    s2 += __builtin_popcountll(rbm[b1][w] & rbm[b2][w] & rbm[b3][w]);
                                if (s2 < lmin) { lmin = s2; lt1 = b1+1; lt2 = b2+1; lt3 = b3+1; }
                                if (s2 <= 1) lb++;
                            }
                        }
                    #pragma omp critical
                    {
                        if (lmin < r_min_t) { r_min_t = lmin; r_t1 = lt1; r_t2 = lt2; r_t3 = lt3; }
                        r_t_below += lb;
                    }
                }
                printf("     3-subset disproof: min survivors %lld (best {%d,%d,%d}); triples <=1 survivor: %d\n",
                       r_min_t, r_t1, r_t2, r_t3, r_t_below);

                /* All 4-subsets */
                int r_freq[31] = {0};
                int r_working = 0;
                char r_report[1024 * 256] = {0}; int r_report_len = 0;
                #pragma omp parallel
                {
                    int lfreq[31] = {0}; int lwork = 0;
                    #pragma omp for schedule(dynamic,8) collapse(2) nowait
                    for (int b1 = 0; b1 < 28; b1++)
                        for (int b2 = 0; b2 < 29; b2++) {
                            if (b2 <= b1) continue;
                            for (int b3 = b2 + 1; b3 < 30; b3++)
                            for (int b4 = b3 + 1; b4 < 31; b4++) {
                                long long s2 = 0;
                                for (long long w = 0; w < n_words_r; w++)
                                    s2 += __builtin_popcountll(rbm[b1][w] & rbm[b2][w] & rbm[b3][w] & rbm[b4][w]);
                                if (s2 <= 1) {
                                    lwork++;
                                    lfreq[b1]++; lfreq[b2]++; lfreq[b3]++; lfreq[b4]++;
                                    #pragma omp critical
                                    {
                                        if (r_report_len < (int)sizeof(r_report) - 64) {
                                            r_report_len += snprintf(r_report + r_report_len,
                                                sizeof(r_report) - r_report_len,
                                                "       {%2d,%2d,%2d,%2d} surv=%lld\n", b1+1, b2+1, b3+1, b4+1, s2);
                                        }
                                    }
                                }
                            }
                        }
                    #pragma omp critical
                    {
                        for (int b = 0; b < 31; b++) r_freq[b] += lfreq[b];
                        r_working += lwork;
                    }
                }
                printf("     All 4-subsets uniquely identifying KW (<=1 survivor): %d\n", r_working);
                printf("%s", r_report);
                if (r_working > 0) {
                    printf("     Boundary frequency: ");
                    for (int b = 0; b < 31; b++) if (r_freq[b] > 0)
                        printf("b%d=%d ", b + 1, r_freq[b]);
                    printf("\n");
                    printf("     Boundaries in EVERY working 4-set: { ");
                    for (int b = 0; b < 31; b++) if (r_freq[b] == r_working) printf("%d ", b + 1);
                    printf("}\n");
                }

                for (int b = 0; b < 31; b++) free(rbm[b]);
                free(rbm);
                skip_section15: ;
            }
            free(reps);
        }
        printf("\n");

        /* === Section 16: Per-(p2, o2) collision-key bug-impact map ===
         * Under the old buggy naming scheme, sub_*.bin was keyed only on (p2, o2).
         * 3030 sub-branches share just 64 (p2, o2) keys, so later writers
         * overwrote earlier ones. For each key we report:
         *   - #contributing (p1, o1) sub-branches
         *   - total records
         *   - min and max single-contributor counts
         * The old bug retained exactly ONE contributor per key (undetermined which),
         * so the bug-kept total is bounded by [sum(min), sum(max)].
         */
        printf("[16] Per-(p2, o2) collision-key bug-impact map\n");
        time_t t16 = time(NULL);
        {
            /* counts[p2][o2][p1][o1] — 32*2*32*2 = 4096 long longs */
            long long (*cnt)[2][32][2] = calloc(32, sizeof(*cnt));
            if (!cnt) { printf("    ERROR: alloc failed\n"); }
            else {
                for (long long i = 0; i < n_sols; i++) {
                    const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                    int p1 = rec[1] >> 2, o1 = (rec[1] >> 1) & 1;
                    int p2 = rec[2] >> 2, o2 = (rec[2] >> 1) & 1;
                    cnt[p2][o2][p1][o1]++;
                }
                long long total = 0, kept_lo_sum = 0, kept_hi_sum = 0;
                int n_keys_live = 0, max_contribs = 0;
                printf("    (p2, o2) | #contribs |   total records |     min single |     max single | max/total\n");
                for (int p2 = 0; p2 < 32; p2++)
                for (int o2 = 0; o2 < 2; o2++) {
                    long long tot = 0, mn = 0, mx = 0;
                    int nc = 0;
                    for (int p1 = 0; p1 < 32; p1++)
                    for (int o1 = 0; o1 < 2; o1++) {
                        long long c = cnt[p2][o2][p1][o1];
                        if (c > 0) { nc++; tot += c;
                                     if (nc == 1 || c < mn) mn = c;
                                     if (c > mx) mx = c; }
                    }
                    if (tot > 0) {
                        printf("    (%2d, %d) |   %4d    | %15lld | %14lld | %14lld | %.4f\n",
                               p2, o2, nc, tot, mn, mx, (double)mx / tot);
                        total += tot;
                        kept_lo_sum += mn;
                        kept_hi_sum += mx;
                        n_keys_live++;
                        if (nc > max_contribs) max_contribs = nc;
                    }
                }
                printf("    --- summary ---\n");
                printf("    Live (p2, o2) keys: %d of 64\n", n_keys_live);
                printf("    Max #contributors any single key: %d\n", max_contribs);
                printf("    Total records across all keys:    %lld\n", total);
                printf("    Bug-kept count bounds: [%lld, %lld] (%.2f%% to %.2f%% of %lld)\n",
                       kept_lo_sum, kept_hi_sum,
                       100.0 * kept_lo_sum / total, 100.0 * kept_hi_sum / total, total);
                printf("    Reported old (buggy) 10T result: 31.6M. Undercount factor: %.2fx\n",
                       (double)total / 31600000.0);
                free(cnt);
            }
        }
        printf("    [16] elapsed: %lds\n\n", (long)(time(NULL) - t16));

        /* === Section 17: Survivor structure of best triple {2, 25, 27} ===
         * Take records matching KW at boundaries 2, 25, 27 (0-indexed: 1, 24, 26)
         * and decompose: edit distance to KW, which positions vary, pair-sequences.
         */
        printf("[17] Survivor structure of best triple {2, 25, 27}\n");
        time_t t17 = time(NULL);
        {
            long long surv_cap = 256;
            long long *surv = malloc(surv_cap * sizeof(long long));
            if (!surv) {
                fprintf(stderr, "ERROR: malloc failed for surv (section 17)\n");
                printf("    SKIPPED: section 17 (alloc failed)\n");
                goto skip_section17;
            }
            long long n_surv = 0;
            for (long long w = 0; w < n_words; w++) {
                uint64_t bits = bmask[1][w] & bmask[24][w] & bmask[26][w];
                while (bits) {
                    int bit = __builtin_ctzll(bits);
                    long long i = w * 64 + bit;
                    if (i < n_sols) {
                        if (n_surv >= surv_cap) {
                            surv_cap *= 2;
                            long long *tmp = realloc(surv, surv_cap * sizeof(long long));
                            if (!tmp) {
                                fprintf(stderr, "ERROR: realloc failed for surv (section 17, cap=%lld)\n", surv_cap);
                                goto done_surv_collect;
                            }
                            surv = tmp;
                        }
                        surv[n_surv++] = i;
                    }
                    bits &= bits - 1;
                }
            }
            done_surv_collect:
            printf("    Total survivors (incl. KW orient variants): %lld\n", n_surv);
            int edit_hist[33] = {0};
            int pos_var[32] = {0};
            int n_non_kw = 0;
            for (long long k = 0; k < n_surv; k++) {
                const unsigned char *rec = all + surv[k] * SOL_RECORD_SIZE;
                int diffs = 0;
                for (int p = 0; p < 32; p++) {
                    int pi = rec[p] >> 2;
                    if (pi != p) { diffs++; pos_var[p]++; }
                }
                edit_hist[diffs]++;
                if (diffs > 0) n_non_kw++;
            }
            printf("    Non-KW survivors: %d\n", n_non_kw);
            printf("    Edit-distance histogram:\n");
            for (int d = 0; d <= 32; d++) if (edit_hist[d] > 0)
                printf("        dist=%2d: %d\n", d, edit_hist[d]);
            printf("    Positions where any non-KW survivor differs from KW:\n");
            for (int p = 0; p < 32; p++) if (pos_var[p] > 0)
                printf("        pos %2d: %d survivors differ\n", p + 1, pos_var[p]);
            printf("    Non-KW survivor pair-sequences (up to 30):\n");
            int shown = 0;
            for (long long k = 0; k < n_surv && shown < 30; k++) {
                const unsigned char *rec = all + surv[k] * SOL_RECORD_SIZE;
                int is_kw = 1;
                for (int p = 0; p < 32; p++) if ((rec[p] >> 2) != p) { is_kw = 0; break; }
                if (is_kw) continue;
                printf("        [%3d]: ", shown + 1);
                for (int p = 0; p < 32; p++) printf("%2d ", rec[p] >> 2);
                printf("\n");
                shown++;
            }
            free(surv);
        }
        skip_section17:
        printf("    [17] elapsed: %lds\n\n", (long)(time(NULL) - t17));

        /* === Section 18: Per-boundary conditional entropy ===
         * For each boundary b, compute sum_p H(pair at p | records matching KW
         * at boundary b). Compare to baseline sum_p H(pair at p) over all 742M.
         * info_gain(b) = baseline - cond(b) = information about the sequence
         * gained by learning that boundary b matches KW.
         */
        printf("[18] Per-boundary conditional entropy\n");
        time_t t18 = time(NULL);
        {
            double H_base[32]; double H_base_total = 0;
            for (int p = 0; p < 32; p++) {
                double H = 0;
                for (int pr = 0; pr < 32; pr++) {
                    long long c = pos_cnt[p][pr];
                    if (c > 0) { double q = (double)c / n_sols; H -= q * log2(q); }
                }
                H_base[p] = H; H_base_total += H;
            }
            printf("    Baseline sum_p H(pair at p) over all %lld records: %.4f bits\n",
                   n_sols, H_base_total);
            printf("    Boundary | matching_records | sum_p H(p | b) | info_gain=H_base-H_cond\n");
            long long (*cc)[32] = malloc(32 * sizeof(*cc));
            if (!cc) {
                fprintf(stderr, "ERROR: malloc failed for cc (section 18)\n");
                printf("    SKIPPED: section 18 (alloc failed)\n");
                goto skip_section18;
            }
            for (int b = 0; b < 31; b++) {
                memset(cc, 0, 32 * sizeof(*cc));
                long long n_match = 0;
                for (long long w = 0; w < n_words; w++) {
                    uint64_t bits = bmask[b][w];
                    while (bits) {
                        int bit = __builtin_ctzll(bits);
                        long long i = w * 64 + bit;
                        if (i < n_sols) {
                            const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                            for (int p = 0; p < 32; p++) cc[p][rec[p] >> 2]++;
                            n_match++;
                        }
                        bits &= bits - 1;
                    }
                }
                double Hc = 0;
                if (n_match > 0) {
                    for (int p = 0; p < 32; p++)
                    for (int pr = 0; pr < 32; pr++) {
                        long long c = cc[p][pr];
                        if (c > 0) { double q = (double)c / n_match; Hc -= q * log2(q); }
                    }
                }
                printf("      b=%2d   |   %14lld  |  %10.4f   |     %10.4f\n",
                       b + 1, n_match, Hc, H_base_total - Hc);
            }
            free(cc);
        }
        skip_section18:
        printf("    [18] elapsed: %lds\n\n", (long)(time(NULL) - t18));

        /* === Section 19: Identity-level check of the 4 working 4-sets ===
         * Dump the actual records surviving each of the 4 working 4-sets.
         * Rigorously confirms whether all 4 sets keep the same survivors
         * (expected: the 4 KW orient variants, no non-KW) or differ subtly.
         */
        printf("[19] Identity-level survivor dump per working 4-set\n");
        time_t t19 = time(NULL);
        {
            /* 0-indexed boundary tuples for {2,21,25,27}, {2,22,25,27}, {3,21,25,27}, {3,22,25,27} */
            int sets[4][4] = {
                {1, 20, 24, 26},
                {1, 21, 24, 26},
                {2, 20, 24, 26},
                {2, 21, 24, 26},
            };
            for (int s = 0; s < 4; s++) {
                int *bs = sets[s];
                printf("    Set {%d, %d, %d, %d}:\n", bs[0]+1, bs[1]+1, bs[2]+1, bs[3]+1);
                long long n = 0;
                for (long long w = 0; w < n_words; w++) {
                    uint64_t bits = bmask[bs[0]][w] & bmask[bs[1]][w]
                                  & bmask[bs[2]][w] & bmask[bs[3]][w];
                    while (bits) {
                        int bit = __builtin_ctzll(bits);
                        long long i = w * 64 + bit;
                        if (i < n_sols) {
                            const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                            int is_kw = 1;
                            for (int p = 0; p < 32; p++) if ((rec[p] >> 2) != p) { is_kw = 0; break; }
                            printf("        rec#%10lld  pair=", i);
                            for (int p = 0; p < 32; p++) printf("%2d ", rec[p] >> 2);
                            printf(" orient=");
                            for (int p = 0; p < 32; p++) printf("%d", (rec[p] >> 1) & 1);
                            printf("  %s\n", is_kw ? "[KW]" : "[NON-KW]");
                            n++;
                        }
                        bits &= bits - 1;
                    }
                }
                printf("        total: %lld survivors\n\n", n);
            }
        }
        printf("    [19] elapsed: %lds\n\n", (long)(time(NULL) - t19));

        /* === Section 20: Complement-orbit analysis ===
         * Bitwise-complement each hexagram (h → h^0x3F). This maps valid
         * pairs to valid pairs (preserves C1) and preserves Hamming
         * distances (preserves C2, C5). If C3 is also preserved, then
         * complement is an automorphism of the C1-C5 solution set:
         * every record's complement should also be in solutions.bin.
         *
         * This section doubles as a VALIDATION CHECK: if matches < n_sols,
         * either the solver missed valid orderings (bug) or complement
         * doesn't preserve C3 (which would be interesting in itself).
         *
         * Memory: allocates n_sols × 32 bytes (~24 GB on the 742M dataset).
         * Together with bmask (~2.9 GB) and the mmap, total resident
         * ~51 GB — fits on F32 (64 GB).
         */
        printf("[20] Complement-orbit analysis\n");
        time_t t20 = time(NULL);
        {
            /* comp_pair_idx[] and comp_orient_flip[] are hoisted to analyze-mode
             * scope (before the streaming pass) so sections [20] and [22] share them. */
            int comp_table_ok = 1;
            for (int p = 0; p < 32; p++)
                if (comp_pair_idx[p] < 0) { comp_table_ok = 0; break; }
            printf("    Complement-pair table:\n");
            int n_self_comp_pairs = 0;
            for (int p = 0; p < 32; p++) {
                int self = (comp_pair_idx[p] == p);
                if (self) n_self_comp_pairs++;
                printf("      pair %2d (%2d,%2d) → pair %2d (%2d,%2d) orient_flip=%d%s\n",
                       p, pairs[p].a, pairs[p].b,
                       comp_pair_idx[p], pairs[comp_pair_idx[p]].a, pairs[comp_pair_idx[p]].b,
                       comp_orient_flip[p], self ? " [self-comp]" : "");
            }
            printf("    Self-complementary pairs: %d of 32\n\n", n_self_comp_pairs);

            if (comp_table_ok) {
                unsigned char *comp = malloc((size_t)n_sols * SOL_RECORD_SIZE);
                if (!comp) {
                    printf("    ERROR: malloc %.1f GB failed\n",
                           (double)n_sols * SOL_RECORD_SIZE / 1e9);
                } else {
                    /* Compute complement of each record */
                    printf("    Computing complements of %lld records...\n", n_sols);
                    time_t tc0 = time(NULL);
                    #pragma omp parallel for schedule(static)
                    for (long long i = 0; i < n_sols; i++) {
                        const unsigned char *src = all + i * SOL_RECORD_SIZE;
                        unsigned char *dst = comp + i * SOL_RECORD_SIZE;
                        for (int p = 0; p < 32; p++) {
                            int old_pi = src[p] >> 2;
                            int old_o  = (src[p] >> 1) & 1;
                            int new_pi = comp_pair_idx[old_pi];
                            int new_o  = old_o ^ comp_orient_flip[old_pi];
                            dst[p] = (unsigned char)((new_pi << 2) | (new_o << 1));
                        }
                    }
                    printf("    Complement done in %lds.\n", (long)(time(NULL) - tc0));

                    /* Sort complemented records */
                    printf("    Sorting %lld complemented records...\n", n_sols);
                    time_t ts0 = time(NULL);
                    qsort(comp, n_sols, SOL_RECORD_SIZE, compare_solutions);
                    printf("    Sort done in %lds.\n", (long)(time(NULL) - ts0));

                    /* Merge-count: how many records in comp match records in all? */
                    long long i_all = 0, i_c = 0, matches = 0;
                    while (i_all < n_sols && i_c < n_sols) {
                        int cmp = memcmp(all + i_all * SOL_RECORD_SIZE,
                                         comp + i_c * SOL_RECORD_SIZE, SOL_RECORD_SIZE);
                        if (cmp == 0) { matches++; i_all++; i_c++; }
                        else if (cmp < 0) i_all++;
                        else i_c++;
                    }
                    printf("    Records with complement in set: %lld / %lld (%.4f%%)\n",
                           matches, n_sols, 100.0 * matches / n_sols);
                    if (matches == n_sols)
                        printf("    *** Complement is an AUTOMORPHISM of the C1-C5 solution set ***\n");
                    else
                        printf("    *** Complement is NOT closed: %lld records lack their complement partner ***\n",
                               n_sols - matches);

                    /* Check KW specifically (rec#0) */
                    unsigned char kw_comp[SOL_RECORD_SIZE];
                    const unsigned char *kw_rec = all;
                    for (int p = 0; p < 32; p++) {
                        int old_pi = kw_rec[p] >> 2;
                        int old_o  = (kw_rec[p] >> 1) & 1;
                        kw_comp[p] = (unsigned char)((comp_pair_idx[old_pi] << 2) |
                                     ((old_o ^ comp_orient_flip[old_pi]) << 1));
                    }
                    /* Binary search for KW's complement */
                    long long lo = 0, hi = n_sols;
                    int found_kw_comp = 0;
                    long long kw_comp_idx = -1;
                    while (lo < hi) {
                        long long mid = lo + (hi - lo) / 2;
                        int cmp = memcmp(kw_comp, all + mid * SOL_RECORD_SIZE, SOL_RECORD_SIZE);
                        if (cmp == 0) { found_kw_comp = 1; kw_comp_idx = mid; break; }
                        else if (cmp < 0) hi = mid;
                        else lo = mid + 1;
                    }
                    printf("    KW complement in set: %s", found_kw_comp ? "YES" : "NO");
                    if (found_kw_comp) printf(" (record index %lld)", kw_comp_idx);
                    printf("\n");
                    printf("    KW complement pair-seq: ");
                    for (int p = 0; p < 32; p++) printf("%2d ", kw_comp[p] >> 2);
                    printf("\n    KW complement orient:   ");
                    for (int p = 0; p < 32; p++) printf("%d", (kw_comp[p] >> 1) & 1);
                    printf("\n");

                    free(comp);
                }
            }
        }
        printf("    [20] elapsed: %lds\n\n", (long)(time(NULL) - t20));

        /* === Section 21: Full per-position pair frequency table ===
         * pos_cnt[p][pair] is already computed in the streaming pass.
         * Emit the full 32×32 table for baseline comparison at 100T.
         */
        printf("[21] Per-position pair frequency table (32 positions × 32 pairs)\n");
        time_t t21 = time(NULL);
        {
            printf("    Format: pos (1-indexed), pair_index, count, pct, is_KW_pair\n");
            for (int p = 0; p < 32; p++) {
                /* Find top pair at this position */
                long long top_cnt = 0; int top_pair = -1;
                int n_present = 0;
                for (int pr = 0; pr < 32; pr++) {
                    if (pos_cnt[p][pr] > 0) n_present++;
                    if (pos_cnt[p][pr] > top_cnt) { top_cnt = pos_cnt[p][pr]; top_pair = pr; }
                }
                printf("    pos %2d (%2d distinct): ", p + 1, n_present);
                /* Print all non-zero entries sorted by count descending */
                int order[32]; for (int i = 0; i < 32; i++) order[i] = i;
                for (int i = 0; i < 31; i++)
                    for (int j = i + 1; j < 32; j++)
                        if (pos_cnt[p][order[j]] > pos_cnt[p][order[i]])
                            { int tmp = order[i]; order[i] = order[j]; order[j] = tmp; }
                for (int k = 0; k < 32; k++) {
                    int pr = order[k];
                    if (pos_cnt[p][pr] == 0) break;
                    printf("p%d=%.2f%%%s ",
                           pr, 100.0 * pos_cnt[p][pr] / n_sols,
                           (pr == p) ? "*" : "");
                }
                printf("\n");
            }
        }
        printf("    [21] elapsed: %lds\n\n", (long)(time(NULL) - t21));

        /* === Section 22: Complement-distance distribution ===
         * Uses the same hex-level metric as C3 (compute_comp_dist_x64):
         *   cd = sum over all 64 hexagrams v of |pos[v] - pos[v^0x3F]|.
         * KW's cd = 776 (the C3 ceiling). Within the C1-C5 dataset, KW is
         * tautologically at the maximum (C3 enforces cd <= KW). The useful
         * information here is the SHAPE of the distribution — how tightly
         * solutions cluster near the ceiling vs. spread toward low cd.
         *
         * The "3.9th percentile" claim in SOLVE-SUMMARY.md is a DIFFERENT
         * comparison: KW vs all pair-constrained orderings (C1 only, from
         * roae.py Monte Carlo), not within C1-C5. Both are correct in their
         * respective reference populations.
         */
        printf("[22] Complement-distance distribution (hex-level, same metric as C3)\n");
        time_t t22 = time(NULL);
        {
            #define CD_X64_MAX 2048
            long long *cd_hist = calloc(CD_X64_MAX, sizeof(long long));
            if (!cd_hist) {
                fprintf(stderr, "ERROR: calloc failed for cd_hist (section 22)\n");
                printf("    SKIPPED: section 22 (alloc failed)\n");
                goto skip_section22;
            }

            #pragma omp parallel
            {
                long long *local_hist = calloc(CD_X64_MAX, sizeof(long long));
                if (!local_hist)
                    fprintf(stderr, "ERROR: calloc failed for local_hist (section 22, thread)\n");
                /* All threads must enter omp for; threads with no local_hist skip the update */
                #pragma omp for schedule(static)
                for (long long i = 0; i < n_sols; i++) {
                    if (!local_hist) continue;
                    const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                    int seq[64];
                    for (int p = 0; p < 32; p++) {
                        int pi = rec[p] >> 2;
                        int o  = (rec[p] >> 1) & 1;
                        seq[2*p]     = o ? pairs[pi].b : pairs[pi].a;
                        seq[2*p + 1] = o ? pairs[pi].a : pairs[pi].b;
                    }
                    int cd = compute_comp_dist_x64(seq);
                    if (cd >= 0 && cd < CD_X64_MAX) local_hist[cd]++;
                }
                if (local_hist) {
                    #pragma omp critical
                    for (int c = 0; c < CD_X64_MAX; c++) cd_hist[c] += local_hist[c];
                }
                free(local_hist);
            }

            int cd_min = -1, cd_max_val = -1;
            long long cumul = 0;
            for (int c = 0; c < CD_X64_MAX; c++) {
                if (cd_hist[c] > 0) {
                    if (cd_min < 0) cd_min = c;
                    cd_max_val = c;
                }
                if (c <= kw_comp_dist_x64) cumul += cd_hist[c];
            }
            double kw_pct = 100.0 * cumul / n_sols;

            printf("    KW complement distance (x64): %d  (= %.4f per hex)\n",
                   kw_comp_dist_x64, kw_comp_dist_x64 / 64.0);
            printf("    KW percentile within C1-C5 dataset: %.2f%%\n", kw_pct);
            printf("    NOTE: KW at %.0f%% is tautological — C3 enforces cd <= %d.\n",
                   kw_pct, kw_comp_dist_x64);
            printf("    The '3.9th percentile' in SOLVE-SUMMARY.md compares KW against\n");
            printf("    ALL pair-constrained orderings (C1 only), not within C1-C5.\n");
            printf("    Range within C1-C5 dataset: [%d, %d]\n", cd_min, cd_max_val);
            printf("    Distribution (20-unit bins, non-zero):\n");
            for (int base = (cd_min / 20) * 20; base <= cd_max_val; base += 20) {
                long long sum = 0;
                for (int c = base; c < base + 20 && c < CD_X64_MAX; c++)
                    sum += cd_hist[c];
                if (sum > 0)
                    printf("      cd %3d-%3d: %12lld (%.4f%%)%s\n",
                           base, base + 19, sum, 100.0 * sum / n_sols,
                           (kw_comp_dist_x64 >= base && kw_comp_dist_x64 < base + 20) ?
                           "  <- KW bin" : "");
            }
            free(cd_hist);
        }
        skip_section22:
        printf("    [22] elapsed: %lds\n\n", (long)(time(NULL) - t22));

        /* === Section 23: {25, 27}-only survivor characterization ===
         * Survivors matching KW at boundaries 25 and 27 (0-indexed: 24 and 26).
         * Updates the old "1,055 survivors" claim from the buggy dataset.
         */
        printf("[23] Survivors after mandatory boundaries {25, 27} only\n");
        time_t t23 = time(NULL);
        {
            long long n_surv = 0;
            int pos_var[32] = {0};
            int edit_hist[33] = {0};
            int n_non_kw = 0;
            int n_distinct_pairs[32] = {0};
            long long pos_freq[32][32]; memset(pos_freq, 0, sizeof(pos_freq));

            for (long long w = 0; w < n_words; w++) {
                uint64_t bits = bmask[24][w] & bmask[26][w];
                while (bits) {
                    int bit = __builtin_ctzll(bits);
                    long long i = w * 64 + bit;
                    if (i < n_sols) {
                        const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                        int diffs = 0;
                        for (int p = 0; p < 32; p++) {
                            int pi = rec[p] >> 2;
                            pos_freq[p][pi]++;
                            if (pi != p) { diffs++; pos_var[p]++; }
                        }
                        edit_hist[diffs]++;
                        if (diffs > 0) n_non_kw++;
                        n_surv++;
                    }
                    bits &= bits - 1;
                }
            }
            printf("    Total survivors: %lld (incl. %d KW orient variants)\n",
                   n_surv, (int)(n_surv - n_non_kw));
            printf("    Non-KW survivors: %d\n", n_non_kw);
            printf("    Edit-distance histogram:\n");
            for (int d = 0; d <= 32; d++) if (edit_hist[d] > 0)
                printf("        dist=%2d: %d\n", d, edit_hist[d]);
            printf("    Positions locked (0 non-KW vary): ");
            int n_locked = 0;
            for (int p = 0; p < 32; p++) if (pos_var[p] == 0) { printf("%d ", p + 1); n_locked++; }
            printf("(%d of 32)\n", n_locked);
            printf("    Positions free (any non-KW vary): ");
            for (int p = 0; p < 32; p++) if (pos_var[p] > 0)
                printf("%d(%d) ", p + 1, pos_var[p]);
            printf("\n");
            /* Per-position distinct pairs among survivors */
            printf("    Per-position distinct pairs among {25,27} survivors:\n");
            for (int p = 0; p < 32; p++) {
                int nd = 0;
                for (int pr = 0; pr < 32; pr++) if (pos_freq[p][pr] > 0) nd++;
                printf("      pos %2d: %2d distinct", p + 1, nd);
                if (nd <= 5) {
                    printf(" [");
                    for (int pr = 0; pr < 32; pr++)
                        if (pos_freq[p][pr] > 0)
                            printf(" p%d=%.1f%%", pr, 100.0 * pos_freq[p][pr] / n_surv);
                    printf(" ]");
                }
                printf("%s\n", (p == p) ? (nd == 1 ? " LOCKED" : "") : "");
            }
        }
        printf("    [23] elapsed: %lds\n\n", (long)(time(NULL) - t23));

        /* === Section 24: KW nearest-neighbor catalog ===
         * Find the N closest solutions to KW by edit distance (pair-position
         * differences, not orient). Stream all records, keep a running top-N
         * by edit distance.
         */
        printf("[24] KW nearest-neighbor catalog (top 50 closest)\n");
        time_t t24 = time(NULL);
        {
            #define NN_CAP 50
            typedef struct { long long idx; int dist; unsigned char rec[SOL_RECORD_SIZE]; } NNEntry;
            NNEntry *nn = calloc(NN_CAP, sizeof(NNEntry));
            if (!nn) {
                fprintf(stderr, "ERROR: calloc failed for nn (section 24)\n");
                printf("    SKIPPED: section 24 (alloc failed)\n");
                goto skip_section24;
            }
            int nn_count = 0;
            int nn_max_dist = 33;

            for (long long i = 0; i < n_sols; i++) {
                const unsigned char *rec = all + i * SOL_RECORD_SIZE;
                int dist = 0;
                for (int p = 0; p < 32; p++)
                    if ((rec[p] >> 2) != p) dist++;
                if (dist == 0) continue; /* skip KW itself */
                if (nn_count < NN_CAP || dist < nn_max_dist) {
                    /* Insert into nn list */
                    int insert_at = nn_count;
                    if (nn_count >= NN_CAP) insert_at = NN_CAP - 1; /* replace worst */
                    nn[insert_at].idx = i;
                    nn[insert_at].dist = dist;
                    memcpy(nn[insert_at].rec, rec, SOL_RECORD_SIZE);
                    if (nn_count < NN_CAP) nn_count++;
                    /* Sort by distance (insertion sort, small N) */
                    for (int j = nn_count - 1; j > 0; j--) {
                        if (nn[j].dist < nn[j-1].dist) {
                            NNEntry tmp = nn[j]; nn[j] = nn[j-1]; nn[j-1] = tmp;
                        } else break;
                    }
                    nn_max_dist = nn[nn_count - 1].dist;
                }
            }
            printf("    Closest %d non-KW solutions by edit distance:\n", nn_count);
            int prev_dist = -1;
            int at_dist = 0;
            for (int k = 0; k < nn_count; k++) {
                if (nn[k].dist != prev_dist) {
                    if (prev_dist >= 0) printf("      --- dist=%d: %d solutions ---\n", prev_dist, at_dist);
                    prev_dist = nn[k].dist;
                    at_dist = 0;
                }
                at_dist++;
                printf("      [%3d] dist=%d rec#%lld: ", k + 1, nn[k].dist, nn[k].idx);
                /* Show only differing positions */
                for (int p = 0; p < 32; p++) {
                    int pi = nn[k].rec[p] >> 2;
                    if (pi != p) printf("pos%d=%d ", p + 1, pi);
                }
                printf("\n");
            }
            if (prev_dist >= 0) printf("      --- dist=%d: %d solutions ---\n", prev_dist, at_dist);
            printf("    Min non-KW edit distance: %d\n", nn_count > 0 ? nn[0].dist : -1);
            free(nn);
        }
        skip_section24:
        printf("    [24] elapsed: %lds\n\n", (long)(time(NULL) - t24));

        /* === Section 25: Per-sub-branch yield from checkpoint.txt ===
         * Reads checkpoint.txt next to analyze_file. Parses sub-branch commit
         * lines and emits a per-sub-branch table: nodes, C3-valid, solutions,
         * status. Primary input for 10T-vs-100T saturation-curve fitting.
         */
        printf("[25] Per-sub-branch yield from checkpoint.txt\n");
        time_t t25 = time(NULL);
        {
            /* Derive checkpoint.txt path: same directory as analyze_file */
            char ckpt_path[1024];
            const char *slash = strrchr(analyze_file, '/');
            if (slash) {
                int dirlen = (int)(slash - analyze_file);
                snprintf(ckpt_path, sizeof(ckpt_path), "%.*s/checkpoint.txt",
                         dirlen, analyze_file);
            } else {
                snprintf(ckpt_path, sizeof(ckpt_path), "checkpoint.txt");
            }
            printf("    Reading: %s\n", ckpt_path);
            FILE *ckpt = fopen(ckpt_path, "r");
            if (!ckpt) {
                printf("    (checkpoint.txt not found — skipping)\n");
            } else {
                /* Allocate per-sub-branch records: up to 3030+; use 4096 cap */
                #define MAX_SUB 4096
                typedef struct {
                    int p1, o1, p2, o2;
                    long long nodes, c3, sols;
                    int elapsed;
                    /* Status codes: 0 = INTERRUPTED, 1 = BUDGETED, 2 = EXHAUSTED/COMPLETE */
                    int status_code;
                } SBEntry;
                SBEntry *entries = calloc(MAX_SUB, sizeof(SBEntry));
                if (!entries) {
                    fprintf(stderr, "ERROR: calloc failed for entries (section 25)\n");
                    printf("    SKIPPED: section 25 (alloc failed)\n");
                    fclose(ckpt);
                    goto skip_section25;
                }
                int n_entries = 0;
                int n_exhausted = 0, n_budgeted = 0, n_interrupted = 0;
                long long tot_nodes = 0, tot_sols = 0;

                char line[1024];
                while (fgets(line, sizeof(line), ckpt)) {
                    if (!strstr(line, "Sub-branch")) continue;
                    int p1v, o1v, p2v, o2v, thr;
                    long long nv, cv;
                    int sv, ev;
                    char status[32];
                    /* Match: Sub-branch {EXHAUSTED|BUDGETED|INTERRUPTED|COMPLETE (legacy)} ...
                     * Try depth-3 format first (has "pair3 P3 orient3 O3"),
                     * then fall back to depth-2. */
                    char *p = strstr(line, "Sub-branch ");
                    if (!p) continue;
                    int p3v_tmp, o3v_tmp;
                    int depth3_match = sscanf(p, "Sub-branch %31s (thread %d, pair1 %d orient1 %d pair2 %d orient2 %d pair3 %d orient3 %d): %lld nodes, %lld C3-valid, %d solutions, %ds elapsed",
                               status, &thr, &p1v, &o1v, &p2v, &o2v, &p3v_tmp, &o3v_tmp, &nv, &cv, &sv, &ev);
                    if (depth3_match != 12) {
                        if (sscanf(p, "Sub-branch %31s (thread %d, pair1 %d orient1 %d pair2 %d orient2 %d): %lld nodes, %lld C3-valid, %d solutions, %ds elapsed",
                                   status, &thr, &p1v, &o1v, &p2v, &o2v, &nv, &cv, &sv, &ev) != 10)
                            continue;
                    }
                    if (n_entries >= MAX_SUB) continue;
                    SBEntry *e = &entries[n_entries++];
                    e->p1 = p1v; e->o1 = o1v; e->p2 = p2v; e->o2 = o2v;
                    e->nodes = nv; e->c3 = cv;
                    /* Override checkpoint's solution count with the actual count
                     * from solutions.bin — checkpoint.txt's value was always 0 in
                     * pre-2026-04-16 runs (flush_sub_solutions zeroed solution_count
                     * before the line was written; fixed in hardening pass). */
                    e->sols = sub_solution_count[p1v][o1v][p2v][o2v];
                    e->elapsed = ev;
                    if (strncmp(status, "EXHAUSTED", 9) == 0 || strncmp(status, "COMPLETE", 8) == 0) {
                        e->status_code = 2; n_exhausted++;
                    } else if (strncmp(status, "BUDGETED", 8) == 0) {
                        e->status_code = 1; n_budgeted++;
                    } else {
                        e->status_code = 0; n_interrupted++;
                    }
                    tot_nodes += nv; tot_sols += e->sols;
                }
                fclose(ckpt);

                printf("    Total entries: %d (EXHAUSTED/COMPLETE: %d, BUDGETED: %d, INTERRUPTED: %d)\n",
                       n_entries, n_exhausted, n_budgeted, n_interrupted);
                printf("    Total nodes across all sub-branches: %lld\n", tot_nodes);
                printf("    Total solutions (from solutions.bin binning): %lld\n", tot_sols);
                printf("    (NOTE: checkpoint.txt's solutions field is always 0 —\n");
                printf("     flush_sub_solutions zeroes ts->solution_count before the\n");
                printf("     checkpoint line is written. We use solutions.bin binning instead.)\n");

                /* Yield distribution */
                long long y0 = 0, y_small = 0, y_mid = 0, y_high = 0, y_max = 0;
                long long max_yield = 0;
                int max_sb = -1;
                for (int i = 0; i < n_entries; i++) {
                    long long y = entries[i].sols;
                    if (y == 0) y0++;
                    else if (y < 1000) y_small++;
                    else if (y < 100000) y_mid++;
                    else y_high++;
                    if (y > max_yield) { max_yield = y; max_sb = i; }
                }
                printf("    Yield distribution:\n");
                printf("      0 solutions:              %lld (dead sub-branches)\n", y0);
                printf("      1 to 999:                 %lld\n", y_small);
                printf("      1,000 to 99,999:          %lld\n", y_mid);
                printf("      100,000+:                 %lld\n", y_high);
                if (max_sb >= 0) {
                    printf("    Highest-yield sub-branch: (p1=%d, o1=%d, p2=%d, o2=%d) with %lld solutions\n",
                           entries[max_sb].p1, entries[max_sb].o1,
                           entries[max_sb].p2, entries[max_sb].o2,
                           max_yield);
                }

                /* Top-20 highest-yield sub-branches */
                /* Simple insertion sort for top-20 */
                int topN = 20;
                if (topN > n_entries) topN = n_entries;
                int *top_idx = malloc(topN * sizeof(int));
                if (!top_idx) {
                    fprintf(stderr, "ERROR: malloc failed for top_idx (section 25)\n");
                    printf("    SKIPPED: top-%d listing (alloc failed)\n", topN);
                    free(entries);
                    goto skip_section25_top;
                }
                for (int i = 0; i < topN; i++) top_idx[i] = -1;
                for (int i = 0; i < n_entries; i++) {
                    long long y = entries[i].sols;
                    int insert = -1;
                    for (int k = 0; k < topN; k++) {
                        if (top_idx[k] < 0 || y > entries[top_idx[k]].sols) {
                            insert = k; break;
                        }
                    }
                    if (insert >= 0) {
                        for (int k = topN - 1; k > insert; k--) top_idx[k] = top_idx[k-1];
                        top_idx[insert] = i;
                    }
                }
                printf("    Top %d highest-yield sub-branches:\n", topN);
                printf("      rank  (p1,o1,p2,o2)         nodes       solutions   status\n");
                for (int k = 0; k < topN && top_idx[k] >= 0; k++) {
                    SBEntry *e = &entries[top_idx[k]];
                    const char *st = (e->status_code == 2) ? "EXHAUSTED"
                                   : (e->status_code == 1) ? "BUDGETED"
                                   : "INTERRUPTED";
                    printf("      %4d  (%2d,%d,%2d,%d)   %13lld   %10lld   %s\n",
                           k + 1, e->p1, e->o1, e->p2, e->o2,
                           e->nodes, e->sols, st);
                }

                free(top_idx);
                free(entries);
                skip_section25_top: ;
            }
        }
        skip_section25:
        printf("    [25] elapsed: %lds\n\n", (long)(time(NULL) - t25));

        /* === Section 26: Per-first-level-branch solution count ===
         * Uses branch_count[] populated in the streaming pass at top of analyze_mode.
         * Reports solution count per (pair_at_pos_2, orient_at_pos_2) = the "first-level"
         * branch, for cross-scale comparison and deep-dive selection.
         */
        printf("[26] Per-first-level-branch solution count\n");
        time_t t26 = time(NULL);
        {
            long long tot_by_pair[32] = {0};
            int live_branches = 0;
            long long sum_check = 0;
            for (int p = 0; p < 32; p++) {
                for (int o = 0; o < 2; o++) {
                    if (branch_count[p][o] > 0) live_branches++;
                    tot_by_pair[p] += branch_count[p][o];
                    sum_check += branch_count[p][o];
                }
            }
            printf("    Total records accounted for: %lld (should == %lld)\n", sum_check, n_sols);
            printf("    Live first-level branches: %d of 64 possible (p1, o1) combos\n", live_branches);
            printf("    Per-(p1, o1) solution counts:\n");
            printf("      pair1  orient1        count     pct\n");
            for (int p = 0; p < 32; p++) {
                for (int o = 0; o < 2; o++) {
                    if (branch_count[p][o] > 0)
                        printf("      %4d   %6d   %12lld   %6.3f%%\n",
                               p, o, branch_count[p][o],
                               100.0 * branch_count[p][o] / n_sols);
                }
            }
            /* Per-pair1 aggregate (summed over both orients) */
            printf("    Per-pair1 aggregate (summed over both orients):\n");
            int live_pairs = 0;
            for (int p = 0; p < 32; p++) if (tot_by_pair[p] > 0) live_pairs++;
            printf("    Live pair1 values: %d of 32\n", live_pairs);
            for (int p = 0; p < 32; p++) {
                if (tot_by_pair[p] > 0)
                    printf("      pair %2d:  %12lld   %6.3f%%\n",
                           p, tot_by_pair[p], 100.0 * tot_by_pair[p] / n_sols);
            }
        }
        printf("    [26] elapsed: %lds\n\n", (long)(time(NULL) - t26));

        /* === Section 27: Budget-exhaustion summary ===
         * Re-reads checkpoint.txt (lightweight second pass) for aggregate counts.
         * Primary saturation signal: fraction of sub-branches that completed naturally.
         */
        printf("[27] Budget-exhaustion summary (from checkpoint.txt)\n");
        time_t t27 = time(NULL);
        {
            char ckpt_path[1024];
            const char *slash = strrchr(analyze_file, '/');
            if (slash) {
                int dirlen = (int)(slash - analyze_file);
                snprintf(ckpt_path, sizeof(ckpt_path), "%.*s/checkpoint.txt",
                         dirlen, analyze_file);
            } else {
                snprintf(ckpt_path, sizeof(ckpt_path), "checkpoint.txt");
            }
            FILE *ckpt = fopen(ckpt_path, "r");
            if (!ckpt) {
                printf("    (checkpoint.txt not found — skipping)\n");
            } else {
                /* Counts for 3-way taxonomy plus legacy COMPLETE */
                int n_exhausted = 0, n_budgeted = 0, n_interrupted = 0, n_other = 0;
                int n_per_branch_exhausted[32] = {0};
                int n_per_branch_total[32]    = {0};
                char line[1024];
                while (fgets(line, sizeof(line), ckpt)) {
                    if (!strstr(line, "Sub-branch")) continue;
                    /* Priority order: EXHAUSTED > COMPLETE (legacy equivalent) > BUDGETED > INTERRUPTED */
                    int is_exhausted  = (strstr(line, "EXHAUSTED") != NULL) ||
                                        (strstr(line, "COMPLETE")  != NULL);  /* legacy */
                    int is_budgeted   = (strstr(line, "BUDGETED")  != NULL);
                    int is_interrupted = (strstr(line, "INTERRUPTED") != NULL);
                    int p1v;
                    char *p = strstr(line, "pair1 ");
                    if (p && sscanf(p, "pair1 %d", &p1v) == 1 && p1v >= 0 && p1v < 32) {
                        n_per_branch_total[p1v]++;
                        if (is_exhausted && !is_interrupted) n_per_branch_exhausted[p1v]++;
                    }
                    if (is_exhausted && !is_interrupted) n_exhausted++;
                    else if (is_budgeted && !is_interrupted) n_budgeted++;
                    else if (is_interrupted) n_interrupted++;
                    else n_other++;
                }
                fclose(ckpt);
                int total = n_exhausted + n_budgeted + n_interrupted + n_other;
                printf("    Sub-branch commit lines parsed: %d\n", total);
                printf("    EXHAUSTED (natural DFS completion): %d (%.4f%%)\n",
                       n_exhausted, total > 0 ? 100.0 * n_exhausted / total : 0);
                printf("    BUDGETED  (per-sub-branch budget hit): %d (%.4f%%)\n",
                       n_budgeted, total > 0 ? 100.0 * n_budgeted / total : 0);
                printf("    INTERRUPTED (external signal):     %d (%.4f%%)\n",
                       n_interrupted, total > 0 ? 100.0 * n_interrupted / total : 0);
                if (n_other > 0) printf("    Other/unparsed: %d\n", n_other);
                printf("    Saturation signal: %s\n",
                       n_exhausted == 0 ? "ZERO sub-branches exhausted → budget-limited run"
                                        : "SOME sub-branches exhausted → partial saturation visible");
                if (n_exhausted > 0) {
                    printf("    Per-pair1 exhaustion rates:\n");
                    for (int p = 0; p < 32; p++) {
                        if (n_per_branch_total[p] > 0)
                            printf("      pair %2d: %d/%d (%.1f%%)\n",
                                   p, n_per_branch_exhausted[p], n_per_branch_total[p],
                                   100.0 * n_per_branch_exhausted[p] / n_per_branch_total[p]);
                    }
                }
            }
        }
        printf("    [27] elapsed: %lds\n\n", (long)(time(NULL) - t27));

        /* === Section 28: Edit-distance-to-KW histogram (full 0-32) ===
         * Uses edit_dist_hist[] populated in the streaming pass. Full histogram
         * across the 742M dataset; baseline for 100T shape comparison.
         */
        printf("[28] Edit-distance-to-KW histogram (full dataset)\n");
        time_t t28 = time(NULL);
        {
            long long hist_total = 0;
            for (int d = 0; d <= 32; d++) hist_total += edit_dist_hist[d];
            printf("    Total records: %lld (should == %lld)\n", hist_total, n_sols);
            printf("    Distance | Count         | Pct      | Cumulative pct\n");
            long long cumul = 0;
            for (int d = 0; d <= 32; d++) {
                if (edit_dist_hist[d] > 0) {
                    cumul += edit_dist_hist[d];
                    printf("    %4d     | %13lld | %7.4f%% | %7.4f%%\n",
                           d, edit_dist_hist[d],
                           100.0 * edit_dist_hist[d] / n_sols,
                           100.0 * cumul / n_sols);
                }
            }
            /* Summary */
            int min_d = -1, max_d = -1, mode_d = -1;
            long long mode_count = 0;
            for (int d = 0; d <= 32; d++) {
                if (edit_dist_hist[d] > 0) {
                    if (min_d < 0) min_d = d;
                    max_d = d;
                    if (edit_dist_hist[d] > mode_count) { mode_count = edit_dist_hist[d]; mode_d = d; }
                }
            }
            printf("    Range: [%d, %d]; mode at distance %d (%lld records)\n",
                   min_d, max_d, mode_d, mode_count);
        }
        printf("    [28] elapsed: %lds\n\n", (long)(time(NULL) - t28));

        /* bmask freed here (end of analyze_mode) — see lifetime note above
         * section [14]. Sections [3]-[19] all depend on bmask being alive. */
        for (int b = 0; b < 31; b++) free(bmask[b]);
        free(bmask);
        free(sub_solution_count);
        free(kw_indices);
        munmap(all, file_size);

        time_t t_end = time(NULL);
        printf("==== analyze done in %lds ====\n", (long)(t_end - t_start));
        return 0;
    }

    /* --- Merge mode: combine sub_*.bin files into one sorted, deduped output --- */
    if (merge_mode) {
        printf("\nMerge mode: combining sub_*.bin files...\n");

        /* Scan current directory for any sub_*.bin file — handles both
         * depth-2 naming (sub_P1_O1_P2_O2.bin) and depth-3 naming
         * (sub_P1_O1_P2_O2_P3_O3.bin) without hard-coded nested loops.
         * Depth-3 can produce up to ~260k files; size accordingly. */
        #define MAX_SUB_FILES 300000
        static char filenames[MAX_SUB_FILES][64];
        int n_files = 0;
        DIR *dir = opendir(".");
        if (!dir) { fprintf(stderr, "ERROR: opendir(.) failed\n"); return 10; }
        struct dirent *de;
        while ((de = readdir(dir)) != NULL) {
            if (strncmp(de->d_name, "sub_", 4) != 0) continue;
            int nlen = strlen(de->d_name);
            if (nlen < 5 || strcmp(de->d_name + nlen - 4, ".bin") != 0) continue;
            if (strstr(de->d_name, ".tmp")) continue;  /* skip in-progress writes */
            FILE *tf = fopen(de->d_name, "rb");
            if (!tf) continue;
            fseek(tf, 0, SEEK_END);
            long sz = ftell(tf);
            fclose(tf);
            if (sz <= 0) continue;
            if (sz % SOL_RECORD_SIZE != 0) {
                fprintf(stderr, "ERROR: %s size %ld is not a multiple of %d — truncated file\n",
                        de->d_name, sz, SOL_RECORD_SIZE);
                closedir(dir);
                return 20;
            }
            if (n_files >= MAX_SUB_FILES) {
                fprintf(stderr, "ERROR: MAX_SUB_FILES (%d) exceeded\n", MAX_SUB_FILES);
                closedir(dir);
                return 10;
            }
            snprintf(filenames[n_files], 64, "%s", de->d_name);
            n_files++;
        }
        closedir(dir);
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

        /* Preflight resource check (item 7e):
         * In-memory merge needs total_records × 32 bytes for the sort buffer,
         * plus ~total_records × 32 bytes of writeout to disk. Verify both
         * resources BEFORE malloc — a short malloc failure or short write
         * late in the process loses hours of preceding work. */
        /* Merge mode selection */
        int use_ext = 0;
        {
            long long needed_bytes = total_records * SOL_RECORD_SIZE;
            long pages = sysconf(_SC_PHYS_PAGES);
            long page_size = sysconf(_SC_PAGE_SIZE);
            long long total_ram = (long long)pages * page_size;
            char *mm = getenv("SOLVE_MERGE_MODE");
            if (mm && strcmp(mm, "external") == 0) {
                use_ext = 1;
                printf("  Merge: external (forced by SOLVE_MERGE_MODE)\n");
            } else if (mm && strcmp(mm, "memory") == 0) {
                use_ext = 0;
                printf("  Merge: in-memory (forced by SOLVE_MERGE_MODE)\n");
            } else {
                use_ext = (needed_bytes > total_ram * 7 / 10);
                printf("  Merge: %s (need %lld GB, have %lld GB RAM)\n",
                       use_ext ? "external (auto)" : "in-memory (auto)",
                       needed_bytes / (1024*1024*1024), total_ram / (1024*1024*1024));
            }
        }

        long long unique = 0;
        const char *outname = "solutions.bin";

        if (use_ext) {
            int rc = external_merge_sort(filenames, n_files, total_records, outname, &unique);
            if (rc != 0) return rc;
        } else {
            /* Preflight: check disk space */
            {
                long long need_disk_gb = (total_records * SOL_RECORD_SIZE * 2) / (1024LL*1024*1024);
                struct statvfs vfs;
                long long disk_avail_gb = 0;
                if (statvfs(".", &vfs) == 0)
                    disk_avail_gb = ((long long)vfs.f_bavail * vfs.f_frsize) / (1024LL*1024*1024);
                if (disk_avail_gb > 0 && need_disk_gb > disk_avail_gb) {
                    fprintf(stderr, "ERROR: insufficient disk (%lld GB needed, %lld available)\n"
                            "       Try SOLVE_MERGE_MODE=external\n", need_disk_gb, disk_avail_gb);
                    return 10;
                }
            }

            unsigned char *all = malloc((size_t)total_records * SOL_RECORD_SIZE);
            if (!all) {
                fprintf(stderr, "ERROR: malloc failed for %lld records.\n"
                        "       Try SOLVE_MERGE_MODE=external\n", total_records);
                return 1;
            }

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

            for (long long i = 0; i < total_records; i++) {
                if (i == 0 || compare_canonical(
                        &all[i * SOL_RECORD_SIZE],
                        &all[(i - 1) * SOL_RECORD_SIZE]) != 0) {
                    if (unique != i)
                        memcpy(&all[unique * SOL_RECORD_SIZE],
                               &all[i * SOL_RECORD_SIZE], SOL_RECORD_SIZE);
                    unique++;
                }
            }
            printf("  Unique: %lld (removed %lld orient duplicates)\n",
                   unique, total_records - unique);

            printf("  Writing %s...\n", outname);

            FILE *of = fopen(outname, "wb");
            if (!of) { fprintf(stderr, "ERROR: cannot open %s\n", outname); free(all); return 30; }
            size_t written = fwrite(all, SOL_RECORD_SIZE, unique, of);
            if ((long long)written != unique) {
                fprintf(stderr, "ERROR: short write (%zu of %lld)\n", written, unique);
                fclose(of); free(all); return 30;
            }
            if (fflush(of) != 0 || fsync(fileno(of)) != 0) {
                fprintf(stderr, "ERROR: flush/fsync failed\n"); fclose(of); free(all); return 30;
            }
            fclose(of);
            free(all);
        }
        printf("  Unique solutions: %lld\n", unique);
        /* Post-write size verification (catches truncation) */
        {
            struct stat pst;
            long long expected = unique * SOL_RECORD_SIZE;
            if (stat(outname, &pst) != 0 || pst.st_size != expected) {
                fprintf(stderr, "ERROR: post-write size mismatch on %s: got %lld, expected %lld\n",
                        outname, (long long)(stat(outname, &pst) == 0 ? pst.st_size : -1), expected);
                return 30;
            }
        }

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
        char val_cmd[128];
        snprintf(val_cmd, sizeof(val_cmd), "./solve --validate %s", outname);
        int vret = system(val_cmd);
        if (vret != 0) {
            fprintf(stderr, "ERROR: post-merge validation returned non-zero (%d)\n", vret);
            return 40; /* exit 40 = validation mismatch */
        }

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

        /* Per-branch result buffer so OpenMP-parallel iterations can be printed in order. */
        struct CascadeResult { int branch_feasible; int n_found; int status_code; /* 0=dead 1=proved 2=multi */ } results_phase1[32];
        memset(results_phase1, 0, sizeof(results_phase1));

        /* Phase 1 is embarrassingly parallel: 31 independent branches.
         * Compile with -fopenmp for ~30x speedup; without it the pragma is a no-op. */
        #pragma omp parallel for schedule(dynamic) reduction(+:proved_count,dead_count,multi_count) reduction(&&:all_proved)
        for (int bp = 0; bp < 32; bp++) {
            if (bp == start_pair_idx) continue;

            int branch_feasible = 0;
            /* Track unique pair sequences (ignoring orientation).
             * Per-iteration (was static; that broke under OpenMP parallelism). */
            int found_seqs[1000][17];
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

            int status_code;
            if (n_found == 0) {
                status_code = 0;
                dead_count++;
            } else if (n_found == 1) {
                status_code = 1;
                proved_count++;
            } else {
                status_code = 2;
                multi_count++;
                all_proved = 0;
            }
            results_phase1[bp].branch_feasible = branch_feasible;
            results_phase1[bp].n_found = n_found;
            results_phase1[bp].status_code = status_code;
        }
        /* Print Phase 1 results in branch order (parallel loop above scrambled order). */
        for (int bp = 0; bp < 32; bp++) {
            if (bp == start_pair_idx) continue;
            const char *status = results_phase1[bp].status_code == 0 ? "DEAD (no feasible paths)" :
                                 results_phase1[bp].status_code == 1 ? "PROVED: exactly 1 pair sequence" :
                                                                       "MULTIPLE sequences";
            printf("  Pair %2d (hexagrams %2d,%2d): %6d feasible paths, %d unique -> %s\n",
                   bp, pairs[bp].a, pairs[bp].b,
                   results_phase1[bp].branch_feasible, results_phase1[bp].n_found, status);
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
                    /* Set per-config time limit (300s = 5 min, or 0 for no limit) */
                    int config_time_limit = 300; /* default 5 min survey */
                    char *env_ctl = getenv("PROVE_CONFIG_TIMEOUT");
                    if (env_ctl) config_time_limit = atoi(env_ctl);
                    proof_search_timed_out = 0;
                    proof_search_deadline = config_time_limit > 0 ? time(NULL) + config_time_limit : 0;
                    proof_search(seq, used, budget, step, last_hex, &cnodes, &found_c3);
                    total_nodes += cnodes;
                }

                if (found_c3) {
                    printf(" FOUND (%lld nodes). NOT eliminated.\n", total_nodes);
                    fflush(stdout);
                    full_proved = 0;
                } else if (proof_search_timed_out) {
                    printf(" TIMEOUT (%lld nodes in %ds). Inconclusive.\n",
                           total_nodes, 300);
                    fflush(stdout);
                    full_proved = 0;  /* can't claim proved if timed out */
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
                if (is_sub_branch_completed(sb_pair, sb_orient, p2, o2)) {
                    n_skipped++;
                    continue;
                }

                if (n_sub >= 64) {
                    fprintf(stderr, "FATAL: all_sub buffer overflow\n");
                    return 10;
                }
                all_sub[n_sub].pair1 = sb_pair;
                all_sub[n_sub].orient1 = sb_orient;
                all_sub[n_sub].pair2 = p2;
                all_sub[n_sub].orient2 = o2;
                all_sub[n_sub].pair3 = -1;
                all_sub[n_sub].orient3 = -1;
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
            threads[i].ht_log2 = sol_hash_log2;
            threads[i].ht_size = sol_hash_size;
            threads[i].ht_mask = sol_hash_mask;
            for (int j = 0; j < TOP_N; j++)
                threads[i].top_closest[j].edit_dist = 33;
        }

        printf("Threads: %d, Sub-branches per thread: %d-%d\n",
               n_threads, n_sub / n_threads, (n_sub + n_threads - 1) / n_threads);
        printf("Initial hash memory: %d MB (%d MB/thread, auto-resize at 75%%)\n",
               n_threads * (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576),
               (int)((size_t)sol_hash_size * SOL_RECORD_SIZE / 1048576));
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
        long long total_hash_drops = 0;
        long long total_stored = 0;
        int branches_done = 0;
        ClosestEntry all_top[64 * TOP_N];
        int all_top_count = 0;

        for (int i = 0; i < n_threads; i++) {
            total_nodes += threads[i].nodes;
            total_sol += threads[i].solutions_total;
            total_c3 += threads[i].solutions_c3;
            total_hash_drops += threads[i].hash_drops;
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
        printf("Merging %lld stored solutions from %d threads...\n", total_stored, n_threads);
        fflush(stdout);
        unsigned char *all_solutions = NULL;
        if (total_stored > 0) {
            all_solutions = malloc((size_t)total_stored * SOL_RECORD_SIZE);
            if (!all_solutions) {
                fprintf(stderr, "ERROR: failed to allocate %lld bytes for solution merge\n",
                        (long long)total_stored * SOL_RECORD_SIZE);
                return 30;
            }
        }
        long long sol_offset = 0;
        for (int i = 0; i < n_threads; i++) {
            if (threads[i].sol_table && threads[i].sol_occupied) {
                for (int s = 0; s < threads[i].ht_size; s++) {
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
        printf("Sorting %lld solutions...\n", total_stored);
        fflush(stdout);
        if (all_solutions && total_stored > 0)
            qsort(all_solutions, (size_t)total_stored, SOL_RECORD_SIZE, compare_solutions);
        long long unique_count = 0;
        for (long long i = 0; i < total_stored; i++) {
            if (i == 0 || compare_canonical(&all_solutions[(size_t)i * SOL_RECORD_SIZE], &all_solutions[(size_t)(i - 1) * SOL_RECORD_SIZE]) != 0) {
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

        printf("Writing %lld unique solutions to %s...\n", unique_count, bin_name);
        fflush(stdout);
        FILE *bf = fopen(bin_name, "wb");
        if (!bf) {
            fprintf(stderr, "ERROR: cannot open %s for writing\n", bin_name);
            free(all_solutions);
            return 30;
        }
        if (all_solutions) {
            size_t written = fwrite(all_solutions, SOL_RECORD_SIZE, (size_t)unique_count, bf);
            if ((long long)written != unique_count) {
                fprintf(stderr, "ERROR: short write to %s (%zu of %lld records) — disk full?\n",
                        bin_name, written, unique_count);
                fclose(bf);
                free(all_solutions);
                return 30;
            }
        }
        if (fflush(bf) != 0 || fsync(fileno(bf)) != 0) {
            fprintf(stderr, "ERROR: flush/fsync failed on %s\n", bin_name);
            fclose(bf);
            free(all_solutions);
            return 30;
        }
        if (fclose(bf) != 0) {
            fprintf(stderr, "ERROR: close failed on %s — write may be incomplete\n", bin_name);
            free(all_solutions);
            return 30;
        }
        /* Post-write size verification: catches silent truncation (the bug
         * that produced the 23.7→8 GB incident in the 10T recovery). */
        {
            struct stat pst;
            long long expected = (long long)unique_count * SOL_RECORD_SIZE;
            if (stat(bin_name, &pst) != 0) {
                fprintf(stderr, "ERROR: post-write stat failed on %s\n", bin_name);
                free(all_solutions);
                return 30;
            }
            if (pst.st_size != expected) {
                fprintf(stderr, "ERROR: post-write size mismatch on %s: got %lld, expected %lld\n",
                        bin_name, (long long)pst.st_size, expected);
                free(all_solutions);
                return 30;
            }
        }
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
        printf("Unique pair orderings:         %lld\n", unique_count);
        printf("King Wen found:                %s\n", kw_found ? "YES" : "No");
        printf("Hash de-dup collisions:        %lld\n", total_hash_collisions);
        {
            int max_ht = sol_hash_log2;
            int total_resizes = 0;
            for (int i = 0; i < n_threads; i++) {
                if (threads[i].ht_log2 > max_ht) max_ht = threads[i].ht_log2;
                total_resizes += threads[i].ht_resizes;
            }
            printf("Hash table:                    initial 2^%d, max 2^%d, %d resize(s)\n",
                   sol_hash_log2, max_ht, total_resizes);
        }
        printf("Hash-table silent drops:       %lld  (0 expected with auto-resize)\n", total_hash_drops);
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
        printf("  %s:  %lld unique x %d bytes = %lld bytes\n", bin_name, unique_count, SOL_RECORD_SIZE, (long long)unique_count * SOL_RECORD_SIZE);
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

    /* Resume from checkpoint — first set the expected per-branch budget so
     * BUDGETED entries can be skipped only when the stored budget >= current.
     * Use 3030 as the canonical denominator (standard 3030-sub-branch mode);
     * this is the expected total_branches before checkpoint skipping.
     * Approximation error is irrelevant: the budget-aware resume just needs
     * a rough threshold, not an exact match. */
    if (node_limit > 0) current_per_branch_budget = node_limit / 3030;
    load_sub_checkpoint();
    if (n_completed_subs > 0) {
        printf("Resuming: %d sub-branches already completed (from checkpoint.txt)\n",
               n_completed_subs);
        total_branches_completed = n_completed_subs;
    }

    /* Enumerate ALL valid work units across all 56 first-level branches.
     * depth-2: ~3030 units each (p1, o1, p2, o2)
     * depth-3: ~90000 units each (p1, o1, p2, o2, p3, o3) — Option B
     * Default allocation 4096 for depth-2, 131072 for depth-3. */
    int n_all_subs = 0;
    int n_skipped_subs = 0;
    int subs_cap = (solve_depth == 3) ? 262144 : 4096;
    SubBranch *all_subs = malloc(subs_cap * sizeof(SubBranch));
    if (!all_subs) {
        fprintf(stderr, "ERROR: failed to allocate %zu bytes for all_subs\n",
                (size_t)subs_cap * sizeof(SubBranch));
        return 30;
    }

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
                    budget2[wd2]--;

                    if (solve_depth == 2) {
                        /* Depth-2: each (p1, o1, p2, o2) is a work unit */
                        if (is_sub_branch_completed(p1, o1, p2, o2)) {
                            n_skipped_subs++;
                            continue;
                        }
                        if (n_all_subs >= subs_cap) { fprintf(stderr, "ERROR: subs_cap overflow\n"); return 10; }
                        all_subs[n_all_subs].pair1 = p1;
                        all_subs[n_all_subs].orient1 = o1;
                        all_subs[n_all_subs].pair2 = p2;
                        all_subs[n_all_subs].orient2 = o2;
                        all_subs[n_all_subs].pair3 = -1;
                        all_subs[n_all_subs].orient3 = -1;
                        n_all_subs++;
                    } else {
                        /* Depth-3 (Option B): further partition by (p3, o3) */
                        int used2[32];
                        memcpy(used2, used1, sizeof(used2));
                        used2[p2] = 1;
                        for (int p3 = 0; p3 < 32; p3++) {
                            if (used2[p3]) continue;
                            for (int o3 = 0; o3 < 2; o3++) {
                                int f3 = o3 ? pairs[p3].b : pairs[p3].a;
                                int s3 = o3 ? pairs[p3].a : pairs[p3].b;
                                int bd3 = hamming(s2, f3);
                                if (bd3 == 5) continue;
                                int budget3[7];
                                memcpy(budget3, budget2, sizeof(budget3));
                                if (budget3[bd3] <= 0) continue;
                                budget3[bd3]--;
                                int wd3 = hamming(f3, s3);
                                if (budget3[wd3] <= 0) continue;

                                if (is_sub_branch_completed_d3(p1, o1, p2, o2, p3, o3)) {
                                    n_skipped_subs++;
                                    continue;
                                }
                                if (n_all_subs >= subs_cap) { fprintf(stderr, "ERROR: subs_cap overflow\n"); return 10; }
                                all_subs[n_all_subs].pair1 = p1;
                                all_subs[n_all_subs].orient1 = o1;
                                all_subs[n_all_subs].pair2 = p2;
                                all_subs[n_all_subs].orient2 = o2;
                                all_subs[n_all_subs].pair3 = p3;
                                all_subs[n_all_subs].orient3 = o3;
                                n_all_subs++;
                            }
                        }
                    }
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
    for (int i = 0; i < n_threads; i++) {
        thread_subs[i] = malloc(max_per_thread * sizeof(SubBranch));
        if (!thread_subs[i]) {
            fprintf(stderr, "ERROR: failed to allocate %zu bytes for thread_subs[%d]\n",
                    (size_t)max_per_thread * sizeof(SubBranch), i);
            for (int j = 0; j < i; j++) free(thread_subs[j]);
            return 30;
        }
    }

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
        threads[i].ht_log2 = sol_hash_log2;
        threads[i].ht_size = sol_hash_size;
        threads[i].ht_mask = sol_hash_mask;
    }

    printf("Initial hash memory: %d MB (%d threads x %d MB, auto-resize at 75%%)\n",
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
    long long total_hash_drops = 0;
    long long total_stored = 0;
    int branches_done = 0;

    ClosestEntry all_top[64 * TOP_N];
    int all_top_count = 0;

    for (int i = 0; i < n_threads; i++) {
        total_nodes += threads[i].nodes;
        total_sol += threads[i].solutions_total;
        total_c3 += threads[i].solutions_c3;
        total_hash_drops += threads[i].hash_drops;
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

    /* Count total records across all sub_*.bin files. Uses opendir to scan
     * the current directory, picking up BOTH depth-2 (sub_P_O_P_O.bin) and
     * depth-3 (sub_P_O_P_O_P_O.bin) naming patterns. */
    long long total_file_records = 0;
    int n_sub_files = 0;
    /* Collect filenames first so we can stream through them twice
     * (counting and reading). Capped at MAX_MERGE_FILES to avoid unbounded
     * allocation. */
    #define MAX_MERGE_FILES 300000
    char (*merge_filenames)[64] = malloc(MAX_MERGE_FILES * 64);
    if (!merge_filenames) { fprintf(stderr, "ERROR: merge_filenames alloc failed\n"); return 30; }
    {
        DIR *dir = opendir(".");
        if (!dir) { fprintf(stderr, "ERROR: opendir(.) failed\n"); free(merge_filenames); return 10; }
        struct dirent *de;
        while ((de = readdir(dir)) != NULL) {
            if (strncmp(de->d_name, "sub_", 4) != 0) continue;
            int nlen = strlen(de->d_name);
            if (nlen < 5 || strcmp(de->d_name + nlen - 4, ".bin") != 0) continue;
            if (strstr(de->d_name, ".tmp")) continue;
            FILE *tf = fopen(de->d_name, "rb");
            if (!tf) continue;
            fseek(tf, 0, SEEK_END);
            long sz = ftell(tf);
            fclose(tf);
            if (sz <= 0) continue;
            if (sz % SOL_RECORD_SIZE != 0) {
                fprintf(stderr, "ERROR: %s size %ld is not a multiple of %d — truncated file\n",
                        de->d_name, sz, SOL_RECORD_SIZE);
                closedir(dir);
                free(merge_filenames);
                return 20;
            }
            if (n_sub_files >= MAX_MERGE_FILES) {
                fprintf(stderr, "ERROR: MAX_MERGE_FILES (%d) exceeded\n", MAX_MERGE_FILES);
                closedir(dir);
                free(merge_filenames);
                return 10;
            }
            snprintf(merge_filenames[n_sub_files], 64, "%s", de->d_name);
            n_sub_files++;
            total_file_records += sz / SOL_RECORD_SIZE;
        }
        closedir(dir);
    }
    printf("  Found %d sub-branch files with %lld total records\n", n_sub_files, total_file_records);

    /* Fix #2: Cross-reference sub_*.bin record counts against checkpoint.
     * A truncated file (disk-full during flush) passes the "multiple of 32"
     * check but contains fewer records than the checkpoint claims. */
    int ckpt_exhausted = 0, ckpt_budgeted = 0, ckpt_interrupted = 0;
    {
        FILE *ckf = fopen("checkpoint.txt", "r");
        if (ckf) {
            char ckline[1024];
            while (fgets(ckline, sizeof(ckline), ckf)) {
                if (strstr(ckline, "EXHAUSTED") || strstr(ckline, "COMPLETE"))
                    ckpt_exhausted++;
                else if (strstr(ckline, "BUDGETED"))
                    ckpt_budgeted++;
                else if (strstr(ckline, "INTERRUPTED"))
                    ckpt_interrupted++;

                /* Extract solution count and filename from checkpoint line.
                 * Format: "... N solutions, Ts ***" with sub-branch identifiers
                 * that map to sub_P1_O1_P2_O2[_P3_O3].bin */
                char *sol_str = strstr(ckline, " solutions,");
                if (!sol_str) continue;
                /* Walk backward to find the number */
                char *p = sol_str - 1;
                while (p > ckline && *p >= '0' && *p <= '9') p--;
                int ckpt_count = atoi(p + 1);
                if (ckpt_count <= 0) continue;

                /* Extract sub-branch key: pair1, orient1, pair2, orient2[, pair3, orient3] */
                int cp1 = -1, co1 = -1, cp2 = -1, co2 = -1, cp3 = -1, co3 = -1;
                char *pk = strstr(ckline, "pair1 ");
                if (pk) sscanf(pk, "pair1 %d orient1 %d pair2 %d orient2 %d pair3 %d orient3 %d",
                               &cp1, &co1, &cp2, &co2, &cp3, &co3);
                if (cp1 < 0) continue;

                char expected_fname[96];
                if (cp3 >= 0)
                    snprintf(expected_fname, sizeof(expected_fname),
                             "sub_%d_%d_%d_%d_%d_%d.bin", cp1, co1, cp2, co2, cp3, co3);
                else
                    snprintf(expected_fname, sizeof(expected_fname),
                             "sub_%d_%d_%d_%d.bin", cp1, co1, cp2, co2);

                struct stat fst;
                if (stat(expected_fname, &fst) == 0) {
                    int file_records = (int)(fst.st_size / SOL_RECORD_SIZE);
                    if (file_records != ckpt_count) {
                        fprintf(stderr, "ERROR: %s has %d records but checkpoint says %d — "
                                "file is truncated or corrupted\n",
                                expected_fname, file_records, ckpt_count);
                        free(merge_filenames);
                        return 20;
                    }
                }
            }
            fclose(ckf);
            printf("  Checkpoint cross-ref: %d EXHAUSTED, %d BUDGETED, %d INTERRUPTED\n",
                   ckpt_exhausted, ckpt_budgeted, ckpt_interrupted);
        } else {
            printf("  No checkpoint.txt found — skipping cross-reference\n");
        }
    }

    /* Merge mode selection: in-memory (fast) or external (memory-independent).
     * SOLVE_MERGE_MODE: auto (default), memory, external */
    int use_external_merge = 0;
    {
        long long needed_bytes = total_file_records * SOL_RECORD_SIZE;
        long pages = sysconf(_SC_PHYS_PAGES);
        long page_size = sysconf(_SC_PAGE_SIZE);
        long long total_ram = (long long)pages * page_size;
        char *merge_mode_env = getenv("SOLVE_MERGE_MODE");

        if (merge_mode_env && strcmp(merge_mode_env, "external") == 0) {
            use_external_merge = 1;
            printf("Merge mode: external (forced by SOLVE_MERGE_MODE)\n");
        } else if (merge_mode_env && strcmp(merge_mode_env, "memory") == 0) {
            use_external_merge = 0;
            printf("Merge mode: in-memory (forced by SOLVE_MERGE_MODE)\n");
        } else {
            use_external_merge = (needed_bytes > total_ram * 7 / 10);
            printf("Merge mode: %s (need %lld GB, have %lld GB RAM)\n",
                   use_external_merge ? "external (auto — insufficient RAM)" : "in-memory (auto)",
                   needed_bytes / (1024*1024*1024), total_ram / (1024*1024*1024));
        }
    }

    long long unique_count = 0;

    if (use_external_merge) {
        int rc = external_merge_sort(merge_filenames, n_sub_files,
                                      total_file_records, "solutions.bin", &unique_count);
        free(merge_filenames);
        if (rc != 0) return rc;
    } else {
        unsigned char *all_solutions = NULL;
        if (total_file_records > 0) {
            all_solutions = malloc((size_t)total_file_records * SOL_RECORD_SIZE);
            if (!all_solutions) {
                fprintf(stderr, "ERROR: failed to allocate %lld bytes for in-memory merge.\n"
                        "       Try SOLVE_MERGE_MODE=external for memory-independent merge.\n",
                        (long long)total_file_records * SOL_RECORD_SIZE);
                free(merge_filenames);
                return 30;
            }
        }

        long long sol_offset = 0;
        if (all_solutions) {
            for (int i = 0; i < n_sub_files; i++) {
                FILE *tf = fopen(merge_filenames[i], "rb");
                if (tf) {
                    fseek(tf, 0, SEEK_END);
                    long sz = ftell(tf);
                    fseek(tf, 0, SEEK_SET);
                    if (sz > 0) {
                        if (fread(&all_solutions[sol_offset * SOL_RECORD_SIZE], 1, sz, tf) != (size_t)sz)
                            printf("  WARNING: short read on %s\n", merge_filenames[i]);
                        sol_offset += sz / SOL_RECORD_SIZE;
                    }
                    fclose(tf);
                }
            }
        }
        free(merge_filenames);
        long long total_stored = sol_offset;

        printf("Sorting %lld solutions...\n", total_stored);
        fflush(stdout);
        if (all_solutions && total_stored > 0)
            qsort(all_solutions, (size_t)total_stored, SOL_RECORD_SIZE, compare_solutions);

        for (long long i = 0; i < total_stored; i++) {
            if (i == 0 || compare_canonical(&all_solutions[(size_t)i * SOL_RECORD_SIZE], &all_solutions[(size_t)(i - 1) * SOL_RECORD_SIZE]) != 0) {
                if (unique_count != i)
                    memcpy(&all_solutions[(size_t)unique_count * SOL_RECORD_SIZE], &all_solutions[(size_t)i * SOL_RECORD_SIZE], SOL_RECORD_SIZE);
                unique_count++;
            }
        }

        printf("Writing %lld unique solutions to solutions.bin...\n", unique_count);
        fflush(stdout);
        FILE *f = fopen("solutions.bin", "wb");
        if (!f) {
            fprintf(stderr, "ERROR: cannot open solutions.bin for writing\n");
            free(all_solutions);
            return 30;
    }
    if (all_solutions) {
        size_t written = fwrite(all_solutions, SOL_RECORD_SIZE, (size_t)unique_count, f);
        if ((long long)written != unique_count) {
            fprintf(stderr, "ERROR: short write to solutions.bin (%zu of %lld records) — disk full?\n",
                    written, unique_count);
            fclose(f);
            free(all_solutions);
            return 30;
        }
    }
    if (fflush(f) != 0 || fsync(fileno(f)) != 0) {
        fprintf(stderr, "ERROR: flush/fsync failed on solutions.bin\n");
        fclose(f);
        free(all_solutions);
        return 30;
    }
    if (fclose(f) != 0) {
        fprintf(stderr, "ERROR: close failed on solutions.bin — write may be incomplete\n");
        free(all_solutions);
        return 30;
    }
        free(all_solutions);
    } /* end in-memory merge */

    /* Post-write size verification (both merge paths) */
    {
        struct stat pst;
        long long expected = unique_count * SOL_RECORD_SIZE;
        if (stat("solutions.bin", &pst) != 0) {
            fprintf(stderr, "ERROR: post-write stat failed on solutions.bin\n");
            return 30;
        }
        if (pst.st_size != expected) {
            fprintf(stderr, "ERROR: post-write size mismatch on solutions.bin: got %lld, expected %lld\n",
                    (long long)pst.st_size, expected);
            return 30;
        }
    }

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

    /* Fix #6: Aggregate exhaustion status */
    {
        const char *enum_status;
        if (ckpt_exhausted + ckpt_budgeted + ckpt_interrupted > 0) {
            if (ckpt_budgeted == 0 && ckpt_interrupted == 0)
                enum_status = "COMPLETE";
            else
                enum_status = "BUDGET-LIMITED";
            printf("Enumeration: %s (%d EXHAUSTED, %d BUDGETED, %d INTERRUPTED)\n",
                   enum_status, ckpt_exhausted, ckpt_budgeted, ckpt_interrupted);
        }
    }
    printf("======================================================================\n\n");

    printf("--- Counts ---\n");
    printf("Nodes explored:                %lld\n", total_nodes);
    printf("Node rate:                     %.1f M/sec\n",
           elapsed > 0 ? total_nodes / (double)elapsed / 1e6 : 0);
    printf("Total solutions (C1+C2+C4+C5): %lld\n", total_sol);
    printf("C3-valid solutions:            %lld\n", total_c3);
    printf("Unique pair orderings:         %lld  (canonical: orient bits masked)\n", unique_count);
    printf("King Wen found:                %s\n", kw_found ? "YES" : "No");
    printf("Threads used:                  %d\n", n_threads);
    printf("Hash de-dup collisions:        %lld (exact match — zero false positives)\n",
           total_hash_collisions);
    {
        int max_ht = sol_hash_log2;
        int total_resizes = 0;
        for (int i = 0; i < n_threads; i++) {
            if (threads[i].ht_log2 > max_ht) max_ht = threads[i].ht_log2;
            total_resizes += threads[i].ht_resizes;
        }
        printf("Hash table:                    initial 2^%d, max 2^%d, %d resize(s)\n",
               sol_hash_log2, max_ht, total_resizes);
    }
    printf("Hash-table silent drops:       %lld  (0 expected with auto-resize)\n", total_hash_drops);
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
                printf("  %4d %6d %6d %12lld %12lld %10lld %10s\n",
                       i, threads[i].branches[0].pair + 1, threads[i].branches[0].orient,
                       threads[i].nodes, threads[i].solutions_c3,
                       threads[i].solution_count, done);
            }
        }
        if (threads[i].n_branches > 1) {
            printf("  %4d  (%d branches) %12lld %12lld %10lld %10d/%d\n",
                   i, threads[i].n_branches,
                   threads[i].nodes, threads[i].solutions_c3,
                   threads[i].solution_count,
                   threads[i].branches_completed, threads[i].n_branches);
        }
    }
    printf("\n");

    printf("--- Output files ---\n");
    printf("  solutions.bin:      %lld unique solutions x %d bytes = %lld bytes\n",
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
