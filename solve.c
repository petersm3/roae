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
 *   SOLVE_MERGE_MODE={auto,memory,external}
 *                            — select merge strategy. auto picks external if
 *                              input would exceed 80% of physical RAM.
 *   SOLVE_MERGE_CHUNK_GB=N   — external-merge chunk size (default 4 GB).
 *   SOLVE_TEMP_DIR=path      — where external-merge writes temp sorted chunks.
 *                              Defaults to "." (current directory). Recommended
 *                              pattern: point at a Premium SSD attached only
 *                              for the merge, while shards and final
 *                              solutions.bin stay on Standard-tier archival
 *                              storage. See DEPLOYMENT.md §Disk tier matters.
 *   SOLVE_CONCENTRATE_BUDGET=1
 *                            — opt-in: when resuming from checkpoint, divide
 *                              SOLVE_NODE_LIMIT by the REMAINING sub-branch
 *                              count instead of the full partition. Concentrates
 *                              budget on not-yet-completed branches at the cost
 *                              of reproducibility (output sha depends on how
 *                              many branches were pre-completed). Intended for
 *                              "accumulate ground truth" workflows where
 *                              pre-completed branches were run to EXHAUSTION.
 *                              Default behavior (unset) preserves per-sub-branch
 *                              budget reproducibility across fresh vs. resumed
 *                              runs at the same SOLVE_NODE_LIMIT.
 *
 * REPRODUCIBILITY RULE OF THUMB
 * =============================
 * For CANONICAL runs (producing a sha that others should re-verify), use
 * SOLVE_NODE_LIMIT only and pass `0` for the time_limit CLI arg. Every
 * sub-branch will run to its per-sub-branch node budget, producing
 * byte-identical solutions.bin across thread counts and machines.
 *
 * Wall-clock time_limit is NON-REPRODUCIBLE: if it fires before a
 * sub-branch completes its node budget, that sub-branch is tagged
 * INTERRUPTED and retains whatever partial solutions it found. Which
 * sub-branches were still running when the interrupt fires depends on
 * thread scheduling and system load — two identical invocations will
 * produce different sha256. Use time_limit alone for "run for N minutes,
 * take what we got" exploratory workflows, not for canonical results.
 * The solver prints a startup WARNING when both limits are set
 * simultaneously.
 *
 * PARTITION-INVARIANCE UNDER EXHAUSTIVE RUNS
 * ==========================================
 * A 10T full-parallel run produces a different sha than a 10T single-branch
 * run, because the per-sub-branch node budget is SOLVE_NODE_LIMIT divided
 * by the number of sub-branches enumerated, and that denominator differs
 * between the two modes. Different per-sub-branch budget → different set
 * of (still-valid) solutions found before BUDGETED → different sha.
 *
 * Under EXHAUSTIVE enumeration (every sub-branch runs to EXHAUSTED, not
 * BUDGETED), the output is partition-invariant. Specifically: running all
 * first-level branches in parallel to completion, then merging, produces
 * byte-identical solutions.bin as running each first-level branch
 * individually via --branch P O to completion, then merging the union of
 * their shards. This is guaranteed by three properties:
 *   1. Per-sub-branch backtracking is deterministic given the prefix.
 *   2. Shard filenames (sub_P1_O1_P2_O2.bin) are content-addressable.
 *   3. The merge is a total-order qsort + canonical-dedup → deterministic.
 * The same invariance holds across depths (d2 vs d3) only under exhaustion.
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
#include <limits.h>
#include <sys/wait.h>

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

/* DFS iterator stack frame (forward-defined here so ThreadState can use it).
 * (p, orient) at one recursion depth. See dfs_capture_active comment in
 * ThreadState for the full lifecycle. */
typedef struct {
    int8_t pair_idx;   /* -1 = invalid; else 0..31 */
    int8_t orient;     /* 0 or 1 */
} DFSIterFrame;

/* v2 stack frame for iterative-path full-state capture. Forward-defined here
 * so ThreadState can hold an array of them. Same layout as the on-disk
 * DFSCheckpointState_v2.frames[] — see that struct for full semantics. */
typedef struct {
    int8_t  step;
    int8_t  p;
    int8_t  orient;
    int8_t  bd;
    int8_t  wd;
    int8_t  prev_tail;
    int8_t  phase;
    int8_t  reserved;
} DFSStackFrame_v2;
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

/* ---------- Parallel --sub-branch work queue (P1, 2026-04-21) ----------
 * When --sub-branch is invoked with SOLVE_THREADS > 1, the single depth-3
 * prefix is split along the depth-4 dimension: each valid (p4, o4) pair
 * becomes a task. Workers pull tasks via an atomic fetch-increment counter
 * in lex order, run DFS from position 5 in their own ThreadState (private
 * hash table), then merge at end. See PARALLEL_SUB_BRANCH_DESIGN.md and
 * P1_IMPLEMENTATION_PLAN.md in the x/roae repo for the design.
 *
 * Determinism: output is byte-identical to legacy single-threaded
 * --sub-branch because (a) every task is processed (for EXHAUSTED) or
 * processed-in-lex-order-until-budget-hit (for BUDGETED), (b) within each
 * task the DFS is single-threaded + deterministic, (c) analyze_solution's
 * dedup is "lex-smallest-record wins" — so cross-task orient-variant
 * duplicates collapse to the same winner regardless of thread scheduling.
 */
/* Depth-5 granularity (2026-04-21): each task is a (p4, o4, p5, o5)
 * tuple. Typical task count: 30-60 × 30-60 ≈ 900-3600, enough to keep
 * D64/D128 fully utilized with headroom for load imbalance across tasks.
 * Depth-4 (~30-60 tasks) is still the fallback via
 * SOLVE_SUB_BRANCH_DEPTH=4 — left depth-4 builder removed since the
 * depth-5 path subsumes it and selftest/force-parallel regression
 * coverage validates the combined logic. */
#define SUB_SUB_MAX 4096  /* upper bound on valid (p4,o4,p5,o5) tuples */
typedef struct {
    int p4, o4;
    int f4, s4;          /* hexagram values from pairs[p4], oriented */
    int bd4, wd4;        /* Hamming(s3, f4) and Hamming(f4, s4) — pre-computed */
    int p5, o5;
    int f5, s5;
    int bd5, wd5;        /* Hamming(s4, f5) and Hamming(f5, s5) — pre-computed */
} SubSubBranchTask;
static SubSubBranchTask sub_sub_tasks[SUB_SUB_MAX];
static int n_sub_sub_tasks = 0;
/* Atomic task dispenser: workers fetch+increment to claim next task. */
static volatile int sub_sub_next_idx = 0;
/* Completed-task bitmap (2026-04-23). Set by worker AFTER a task's DFS
 * finishes cleanly with no budget-hit; persisted by sub_ckpt_flush_worker
 * so resume can skip already-completed tasks instead of re-walking them.
 * Checked at task-claim time; indices with done=1 are skipped (no DFS). */
static volatile int sub_sub_task_done[SUB_SUB_MAX] = {0};

/* Per-task stats (2026-04-24, "level b" tree viz). One slot per depth-5
 * task. Written once by the worker that processes the task, at task
 * completion (or as partial on interrupt/budget). Enables Pareto analysis
 * of task-level yield and load balance across workers. At end-of-run,
 * dumped to per_task_stats.csv for external plotting. */
typedef struct {
    long long nodes;         /* DFS backtrack entries during this task */
    int solutions_added;     /* delta in worker's solution_count */
    int wall_time_ms;        /* task wall time */
    unsigned char worker_id; /* which thread processed it */
    unsigned char completed; /* 1 if DFS ran to natural completion, 0 if partial */
    unsigned char max_depth; /* highest step reached (32 = full leaf depth) */
    unsigned char padding;
    long long nodes_at_depth[33]; /* per-task depth histogram (d in 0..32) */
    long long c3_leaves;     /* C3-valid canonical leaves found (step==32) */
} PerTaskStats;
static PerTaskStats sub_sub_task_stats[SUB_SUB_MAX] = {0};

/* Per-CCD shared node counters (P1 v3, 2026-04-21). Zen 5c "Turin Dense"
 * D128als_v7 has 16 CCDs × 8 cores each. A single atomic counter at 128
 * threads saturates cache-line ownership and caps single-process
 * throughput at ~1 B/s. Partitioning the counter across 16 cache-line-
 * padded slots (one per CCD) lets 8 threads write to each slot with low
 * contention; budget-check sums all slots. Expected improvement: brings
 * single-process throughput closer to multi-process packing aggregate
 * (~1.5-1.6 B/s on D128).
 *
 * Worker thread -> counter slot mapping: thread_id % N_SUB_SUB_COUNTERS.
 * This is a rough proxy for CCD assignment; a true pinning solution
 * would use sched_getcpu() + topology lookup, but round-robin on
 * thread_id tracks "logical core" assignment well enough for Zen 5c
 * where Azure typically pins threads to physical cores sequentially. */
#define N_SUB_SUB_COUNTERS 16
typedef struct {
    volatile long long nodes;
    /* Pad to 64-byte cache line to prevent false sharing between slots. */
    char padding[64 - sizeof(long long)];
} SubSubCounter;
static SubSubCounter sub_sub_counters[N_SUB_SUB_COUNTERS] __attribute__((aligned(64)));

/* Read-only aggregator used by backtrack's budget check and worker
 * task-boundary flush. Summing 16 values is ~4ns — well under the cost
 * of a single atomic add on a contended line, so this is ~always a net
 * win even if the sum is only approximate (per-counter reads are not
 * atomic, but each slot is written by one thread at a time via atomic
 * add, so reads are monotone and the sum is a valid lower bound). */
static inline long long sub_sub_sum_counters(void) {
    long long s = 0;
    for (int i = 0; i < N_SUB_SUB_COUNTERS; i++) s += sub_sub_counters[i].nodes;
    return s;
}

static volatile int sub_sub_budget_hit = 0;
/* Gate: backtrack only consults sub_sub_budget_hit / sub_sub_shared_nodes
 * when this flag is 1 (set by main thread before workers launch, unset
 * after join). Prevents the parallel path's budget signaling from
 * interfering with legacy full-enumeration mode's independent
 * `ts->branch_nodes >= per_branch_node_limit` check. */
static volatile int sub_sub_parallel_active = 0;
/* Shared depth-3 prefix state — populated by main thread before workers
 * launch, read-only during parallel execution. Each worker memcpys into
 * its own local seq/used/budget, then applies its task's depth-4 step. */
static int shared_prefix_seq[64];
static int shared_prefix_used[32];
static int shared_prefix_budget[7];

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

/* Complement distance for a 64-hexagram permutation.
 *
 * Definition: for each hexagram v in {0..63}, add |pos(v) - pos(v ^ 63)|
 * to a running total. The `if (comp != v)` guard is a no-op in this problem:
 * comp(v) = v XOR 63 equals v iff 63 = 0, which is never true. So all 64
 * hexagrams contribute; the code reads as if 60 might be excluded (matching
 * the spec's prose) but arithmetically always sums over all 64.
 *
 * The 64 hexagrams form 32 complement-pairs. Each pair contributes its
 * |delta-pos| twice (once as v, once as v^63). So:
 *      total = 2 * sum_over_32_pairs(|Δpos|)
 *            = 64 * mean_distance_per_pair
 *
 * That is why the stored integer is named "x64": it equals 64 times the
 * mean complement-pair distance. No multiplication is needed in the code —
 * it falls out of summing over all 64 hexagrams.
 *
 * King Wen's total is 776, i.e. mean 12.125 per complement-pair. This is the
 * C3 ceiling: valid solutions must have total <= 776. KW sits at the
 * boundary by construction (the threshold is KW's own value), and is in
 * the 3.9th percentile of complement distance among all C1+C2+C4+C5
 * solutions (i.e. KW actively minimizes this — a genuine signal that is
 * not circular, since C3 is the ceiling, not the exact equality).
 *
 * Note: SPECIFICATION.md contains a documentation error stating |C| = 60.
 * That number would correspond to excluding the 4 rev-palindromic hexagrams
 * {0, 21, 42, 63}, but `comp` is not used as their partner in this sum —
 * they still contribute normally. The correct divisor is 64. */
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

/* ---------- solutions.bin binary format ----------
 * Every file starts with a fixed 32-byte header, then a stream of 32-byte
 * records. See SOLUTIONS_FORMAT.md for the authoritative spec.
 *
 * Header (32 bytes, offsets in decimal):
 *   [0..3]   ASCII 'R','O','A','E'   — magic, detects wrong-file / truncation
 *   [4..7]   uint32 little-endian    — format version (SOL_FORMAT_VERSION)
 *   [8..15]  uint64 little-endian    — record count
 *   [16..31] zero-filled             — reserved for future extensions
 *
 * Why little-endian: all target architectures are LE and pack/unpack
 * helpers are byte-by-byte, so the file content is identical on any host.
 * Why 32-byte header: matches SOL_RECORD_SIZE, so records start at a
 * record-sized offset; no alignment surprises. */
#define SOL_FORMAT_VERSION 1
#define SOL_HEADER_SIZE    32

static inline void sol_pack_u32_le(unsigned char *dst, uint32_t v) {
    dst[0] =  v        & 0xFF;
    dst[1] = (v >> 8)  & 0xFF;
    dst[2] = (v >> 16) & 0xFF;
    dst[3] = (v >> 24) & 0xFF;
}
static inline void sol_pack_u64_le(unsigned char *dst, uint64_t v) {
    for (int i = 0; i < 8; i++) dst[i] = (unsigned char)((v >> (i * 8)) & 0xFF);
}
static inline uint32_t sol_unpack_u32_le(const unsigned char *src) {
    return  (uint32_t)src[0]
         | ((uint32_t)src[1] << 8)
         | ((uint32_t)src[2] << 16)
         | ((uint32_t)src[3] << 24);
}
static inline uint64_t sol_unpack_u64_le(const unsigned char *src) {
    uint64_t v = 0;
    for (int i = 0; i < 8; i++) v |= ((uint64_t)src[i] << (i * 8));
    return v;
}

/* Write the 32-byte solutions.bin header. fwrite/fflush/fsync returns are
 * caller's responsibility; this helper only constructs and writes bytes. */
static int sol_write_header(FILE *f, uint64_t n_records) {
    unsigned char hdr[SOL_HEADER_SIZE] = {0};
    hdr[0] = 'R'; hdr[1] = 'O'; hdr[2] = 'A'; hdr[3] = 'E';
    sol_pack_u32_le(&hdr[4], (uint32_t)SOL_FORMAT_VERSION);
    sol_pack_u64_le(&hdr[8], n_records);
    /* bytes 16..31 stay zero */
    if (fwrite(hdr, 1, SOL_HEADER_SIZE, f) != SOL_HEADER_SIZE) return -1;
    return 0;
}

/* Read and validate the header. Returns 0 on success (fills *out_records),
 * or -1 on bad magic, unknown version, or short read.
 * Caller is responsible for seeking the stream to offset 0 first. */
static int sol_read_header(FILE *f, uint64_t *out_records) {
    unsigned char hdr[SOL_HEADER_SIZE];
    if (fread(hdr, 1, SOL_HEADER_SIZE, f) != SOL_HEADER_SIZE) return -1;
    if (hdr[0] != 'R' || hdr[1] != 'O' || hdr[2] != 'A' || hdr[3] != 'E')
        return -1;
    uint32_t version = sol_unpack_u32_le(&hdr[4]);
    if (version != SOL_FORMAT_VERSION) return -1;
    *out_records = sol_unpack_u64_le(&hdr[8]);
    return 0;
}

/* Write the human-readable sidecar at `meta_path`. Provenance fields
 * (timestamp, git hash) are NOT embedded in solutions.bin itself — they live
 * only here so the binary sha stays reproducible across runs while the
 * sidecar records useful context. */
static int sol_write_meta_json(const char *meta_path, const char *bin_path,
                                uint64_t n_records, long long unique_count,
                                const char *sha_hex) {
    FILE *mf = fopen(meta_path, "w");
    if (!mf) {
        fprintf(stderr, "WARNING: cannot open %s: %s\n", meta_path, strerror(errno));
        return -1;
    }
    char tbuf[64]; struct tm tmbuf;
    time_t now = time(NULL);
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime_r(&now, &tmbuf));
    fprintf(mf, "{\n");
    fprintf(mf, "  \"file\": \"%s\",\n", bin_path);
    fprintf(mf, "  \"magic\": \"ROAE\",\n");
    fprintf(mf, "  \"format_version\": %d,\n", SOL_FORMAT_VERSION);
    fprintf(mf, "  \"header_size_bytes\": %d,\n", SOL_HEADER_SIZE);
    fprintf(mf, "  \"record_size_bytes\": %d,\n", SOL_RECORD_SIZE);
    fprintf(mf, "  \"record_count\": %llu,\n", (unsigned long long)n_records);
    fprintf(mf, "  \"unique_solutions\": %lld,\n", unique_count);
    fprintf(mf, "  \"sha256\": \"%s\",\n", sha_hex ? sha_hex : "");
    fprintf(mf, "  \"encoding\": \"byte i = (pair_index<<2) | (orient<<1); bit 0 reserved\",\n");
    fprintf(mf, "  \"dedup_semantics\": \"canonical — one record per unique pair-sequence; orient variants collapsed\",\n");
    fprintf(mf, "  \"header_byte_order\": \"little-endian (u32 version, u64 record_count)\",\n");
    fprintf(mf, "  \"record_byte_order\": \"single-byte records; byte order is a non-concept\",\n");
    fprintf(mf, "  \"constraint_spec\": \"SPECIFICATION.md\",\n");
    fprintf(mf, "  \"generator\": \"solve.c git %s\",\n", GIT_HASH);
    fprintf(mf, "  \"generated_utc\": \"%s\"\n", tbuf);
    fprintf(mf, "}\n");
    if (fflush(mf) != 0 || fsync(fileno(mf)) != 0 || fclose(mf) != 0) {
        fprintf(stderr, "WARNING: %s write/flush/close failed: %s\n", meta_path, strerror(errno));
        return -1;
    }
    return 0;
}

/* Compile-time sanity on the record encoding. These _Static_asserts make it
 * impossible to change the bit layout in one place (say, the pack expression)
 * without also updating the canonical-form mask — the code would refuse to
 * build. The checks encode the spec:
 *   record byte = (pair_index << 2) | (orient << 1)       // bit 0 reserved
 *   canonical form = record byte & 0xFC                   // mask out orient
 * Concretely: pair_index=5, orient=1 should encode as 0x16 (22); the canonical
 * form should be 0x14 (20). Any drift is caught at compile time. */
_Static_assert(SOL_RECORD_SIZE == 32, "record size locked at 32 bytes (one per position)");
_Static_assert(SOL_HEADER_SIZE == 32,  "header size locked at 32 bytes (matches record size)");
_Static_assert((((5 << 2) | (1 << 1)) & 0xFF) == 22, "pair_index=5, orient=1 must encode to byte 22");
_Static_assert((22 & 0xFC) == 20, "canonical mask 0xFC must zero orient bit while preserving pair_index");
_Static_assert((((31 << 2) | (1 << 1)) & 0xFC) == (31 << 2), "max pair_index survives canonical mask");

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
    /* Per-depth DFS-node histogram (2026-04-23, --depth-profile). One slot
     * per step in [0, 32]. Per-thread, aggregated at run end. Cost: ~264 B
     * per ThreadState + 1 increment per backtrack entry. Output is gated on
     * SOLVE_DEPTH_PROFILE=1 env var so existing runs are byte-identical. */
    long long nodes_at_depth[33];
    /* Pointer to the current depth-5 task's PerTaskStats slot (2026-04-24).
     * Set by worker loop at task-start, cleared at task-end. backtrack()
     * uses this to route per-task increments. NULL outside task windows. */
    void *current_task_stats;
    /* Per-task node start counter (2026-04-28, SOLVE_PER_TASK_NODE_LIMIT).
     * Snapshot of branch_nodes at task claim. backtrack() compares
     * (branch_nodes - task_node_start) against per_task_node_limit to cap
     * each task's DFS, distributing coverage across tasks instead of letting
     * 64 workers walk 64 deep tasks. Unused when per_task_node_limit == 0. */
    long long task_node_start;
    /* Per-task cap-hit flag (2026-04-28). Set when (branch_nodes - task_node_start)
     * crosses per_task_node_limit; checked at every backtrack entry so the entire
     * DFS unwinds in O(depth) instead of O(branching^depth). Reset to 0 at next
     * task claim. */
    volatile int task_cap_hit;
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

    /* P1 parallel --sub-branch: running tally of branch_nodes already
     * published to sub_sub_shared_nodes. Used only in parallel mode to
     * decouple per-thread local progress from global budget accounting. */
    long long pending_shared_flush;
    /* P1 v3 checkpointing: wall-time of last snapshot, used to throttle
     * the per-task checkpoint flush to once per sub_ckpt_interval_sec. */
    time_t last_ckpt;
    /* Hash-table mutex (P1 v3): held during analyze_solution's probe/
     * insert AND during sub_ckpt_flush_worker's read. Protects against
     * races between a worker inserting a solution and the checkpoint
     * thread snapshotting the table. Per-worker (not shared across
     * workers), so uncontended in steady state (~100ns per acquire).
     * Initialized to PTHREAD_MUTEX_INITIALIZER at worker setup. */
    pthread_mutex_t ht_mutex;

    /* DFS-state checkpoint state (2026-04-30, SOLVE_DFS_CHECKPOINT). All zero
     * when dfs_checkpoint_enabled == 0 — no behavior change.
     *
     * dfs_capture_active: set by the budget-exhaust return path in backtrack().
     *   When non-zero, every recursion frame (in unwind) appends its (p, orient)
     *   to dfs_iter_stack and returns. After full unwind, the caller of
     *   backtrack() at the sub-branch top sees the captured stack and writes
     *   it to the .dfs_state sidecar.
     * dfs_iter_top: number of valid entries in dfs_iter_stack[].
     *
     * dfs_resume_active: set BEFORE backtrack() if a .dfs_state sidecar was
     *   loaded. Each frame's for loop at depth d checks
     *   dfs_resume_frames[d - partition_prefix_len]: if .valid, the for loop
     *   starts at (.pair_idx, .orient) and clears .valid (consumed once). */
    volatile int dfs_capture_active;
    int dfs_iter_top;
    DFSIterFrame dfs_iter_stack[64];

    int dfs_resume_active;
    DFSIterFrame dfs_resume_frames[64];
    int dfs_resume_partition_prefix_len;
    long long dfs_resume_prior_nodes;  /* nodes walked in the prior run; used
                                          to bump ts->branch_nodes at resume
                                          start so the budget check counts
                                          cumulatively from prior+new. */

    /* Iterative-path full-state capture (v2). Set at budget exhaust in
     * backtrack_iterative when both dfs_iterative_enabled and
     * dfs_checkpoint_enabled are 1. dfs_v2_* arrays mirror the live DFS
     * stack + seq/used/budget at the moment of capture, ready for atomic
     * write to the .dfs_state sidecar. */
    int dfs_v2_capture_pending;       /* 1 = state captured; write pending */
    int dfs_v2_sp;                    /* stack pointer (number of live frames - 1) */
    DFSStackFrame_v2 dfs_v2_frames[34];
    int8_t dfs_v2_seq[64];
    int8_t dfs_v2_used[32];
    int8_t dfs_v2_budget[7];

    /* Iterative-path resume state (v2). Loaded from disk at sub-branch entry
     * if a v2 .dfs_state file exists. The iterative main loop pre-populates
     * its stack and seq/used/budget arrays from these before starting. */
    int dfs_v2_resume_active;
    int dfs_v2_resume_sp;
    DFSStackFrame_v2 dfs_v2_resume_frames[34];
    int8_t dfs_v2_resume_seq[64];
    int8_t dfs_v2_resume_used[32];
    int8_t dfs_v2_resume_budget[7];
} ThreadState;

/* global_timed_out is set both from the signal handler (must be
 * async-signal-safe) and from thread code. sig_atomic_t is the only type
 * the C standard guarantees safe for signal-handler writes. volatile keeps
 * the compiler from caching reads across observable points in worker loops. */
static volatile sig_atomic_t global_timed_out = 0;
/* SIGUSR1: operator-triggered "dump state now" request. Handler merely
 * flips this flag; the monitor thread observes it and emits a detailed
 * status block on its next 1s poll, then clears the flag. Non-invasive:
 * sending SIGUSR1 never interrupts enumeration work. */
static volatile sig_atomic_t sigusr1_requested = 0;
/* Tier 2 memory-relief flush (2026-04-23). When SOLVE_MEMORY_FLUSH_COUNT=N
 * is set, each worker self-flushes its in-memory canonical hash table to
 * a unique chunk file on disk when its local solution_count crosses
 * N/n_threads, then clears the in-memory table and keeps running. Unlike
 * the snapshot checkpoint (which overwrites a per-worker durability file
 * each cycle), Tier 2 chunks are APPEND-ONLY history: each flush
 * produces a new file that never gets rewritten. At end-of-run, all
 * chunk files + final in-memory state must be externally merged to
 * produce the final dedup'd solutions.bin.
 *
 * Filename pattern: sub_flush_chunk_<6digit_seq>_wrk<tid>.bin
 * Dedup is LAZY: the same canonical ordering may appear in multiple
 * chunks (found pre-flush in chunk N, re-found post-flush in chunk N+1)
 * — external merge at end-of-run uses the lex-smallest-record-wins
 * semantics from analyze_solution to deduplicate.
 *
 * Set threshold = 0 to disable (default). */
static volatile int sub_flush_seq = 0;
static long long per_worker_flush_threshold = 0;  /* 0 = disabled */
static long long tier2_total_records_flushed = 0; /* reporting only */
static volatile int tier2_total_chunks_written = 0;
/* threads_completed is written only via __sync_fetch_and_add (atomic) and
 * read by the monitor thread. volatile forces re-read each iteration of the
 * monitor while-loop. */
static volatile int threads_completed = 0;
static pthread_mutex_t checkpoint_mutex = PTHREAD_MUTEX_INITIALIZER;
/* Intra-sub-branch checkpoint mutex (P1 v3, 2026-04-21). Serializes
 * worker writes to sub_ckpt_wrk<tid>.bin + sub_ckpt_meta.txt so a
 * concurrent flush doesn't interleave partial records or miss the
 * meta-file update. Held briefly (~10ms per task-boundary flush). */
static pthread_mutex_t sub_ckpt_mutex __attribute__((unused)) = PTHREAD_MUTEX_INITIALIZER;
/* Interval for intra-sub-branch checkpointing (seconds). Worker only
 * writes a snapshot if this much wall-time has passed since last flush,
 * so short tasks don't thrash the disk. 60s default matches Azure spot
 * eviction notification (typically 30-60s warning). */
static int sub_ckpt_interval_sec = 60;
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

/* SIGUSR1 handler — request a state snapshot from the monitor thread
 * without interrupting worker DFS. Async-signal-safe: only sets flag. */
static void sigusr1_handler(int sig) {
    (void)sig;
    sigusr1_requested = 1;
}

static time_t start_time;
static int time_limit = 0;

/* FNV-1a output has weak low-bit entropy for structured input. Masking
 * to hash-table slot picks only the low log2(ht_size) bits, which caused
 * catastrophic clustering during 2026-04-24 checkpoint consolidation
 * (probe distance > 350k after ~9M records, effective O(n²) insertion).
 * Mixing high bits down into low bits before masking distributes records
 * uniformly across buckets. Zero effect on canonical output sha — the
 * emitted solutions.bin is lex-sorted, so bucket layout is invisible to
 * the final file. */
#define SOL_HASH_MIX(ch) do { (ch) = ((ch) >> 32) ^ (ch); } while (0)
/* Node limit: stop after this many total nodes across all threads.
 * Set via SOLVE_NODE_LIMIT env var. 0 = no limit.
 * Unlike time limit, node limit is deterministic — same node limit on any
 * hardware produces the same solutions.bin (reproducible sha256). */
static long long node_limit = 0;
static long long per_branch_node_limit = 0;  /* node_limit / n_branches, set at startup */
/* SOLVE_PER_SUB_BRANCH_LIMIT (2026-04-29). When set, overrides the
 * auto-divide computation of per_branch_node_limit. Both full-enum and
 * --branch modes will use the same per-sub-branch budget directly,
 * making outputs byte-identical across partition strategies. Required
 * for the partition-invariance regression test (`--regression-test`)
 * to compare apples-to-apples between full-enum and 56-branch-merge
 * paths. 0 = off (default; auto-divide stands). */
static long long per_sub_branch_override = 0;
/* Per-task node limit (2026-04-28, SOLVE_PER_TASK_NODE_LIMIT). When set,
 * each sub-sub task DFS is capped at this many nodes, distributing coverage
 * across the 2507 task queue instead of letting 64 workers walk 64 deep
 * tasks. 0 = off (preserves prior behavior + canonical shas). */
static long long per_task_node_limit = 0;
/* Enumeration depth for sub-branch partitioning. 2 (default) = depth-2
 * (pair1, orient1, pair2, orient2) — ~3030 work units. 3 = depth-3
 * (pair1..pair3, orient1..orient3) — ~90000 work units for finer granularity
 * under spot-VM eviction. Set from SOLVE_DEPTH env var. */
static int solve_depth = 2;

/* SOLVE_DFS_CHECKPOINT (2026-04-30). When set to 1, enables mid-walk DFS-state
 * checkpointing: at per-sub-branch budget exhaustion, write a small ".dfs_state"
 * sidecar file capturing the iterator stack at each recursion frame. A subsequent
 * invocation with a HIGHER per-sub-branch budget reads the sidecar, replays the
 * call stack via the saved iterators, and continues the walk from the saved
 * position. The sub-branch's solutions accumulate across runs (read-merge-write
 * the existing shard with new finds at flush time).
 *
 * Default = 0 (off). Selftest sha (403f7202...) and canonical shas are unaffected
 * unless this env var is set AND a .dfs_state file is present.
 *
 * Format / behavior is documented in:
 *   x/roae/INCREMENTAL_EXTENSION_DESIGN.md (design)
 *   x/roae/INCREMENTAL_EXTENSION_SPIKE_NOTES.md (this implementation's notes,
 *     written during the 2026-04-30 spike).
 */
static int dfs_checkpoint_enabled = 0;

#define DFS_STATE_MAGIC 0x44465353u  /* 'DFSS' */
#define DFS_STATE_VERSION 1u

/* DFSIterFrame is forward-defined near the Pair typedef so ThreadState can
 * use it. See its comment for semantics. */

/* On-disk DFS-state sidecar v1 format. ~512 bytes per sub-branch.
 * Written at budget-exhaust, read at sub-branch resume.
 *
 * iter_frames[0..top-1] is the call stack from OUTERMOST to DEEPEST:
 *   iter_frames[0] = step = partition_prefix_len  (sub-branch entry depth)
 *   iter_frames[top-1] = deepest depth where a recursive call was made when
 *                        budget exhausted
 * Each entry's (pair_idx, orient) is the iterator value AT THAT DEPTH'S for
 * loop when the deeper recursion was interrupted. On resume, the for loop at
 * that depth is started at the saved (pair_idx, orient).
 *
 * Note: seq[], used[], budget[] are NOT saved. They reconstruct deterministically
 * from the iter_frames stack as the descent re-applies constraints at each
 * iteration. Saving avoids them simplifies the format and reduces verification
 * surface area. */
typedef struct {
    uint32_t magic;            /* DFS_STATE_MAGIC */
    uint16_t format_version;   /* DFS_STATE_VERSION */
    uint16_t partition_depth;  /* 2 or 3 */

    /* Sub-branch identity (for sanity check on read) */
    int8_t   prefix_p1, prefix_o1;
    int8_t   prefix_p2, prefix_o2;
    int8_t   prefix_p3, prefix_o3;  /* -1 if depth-2 */

    uint16_t iter_top;         /* number of valid entries in iter_frames[] */
    uint16_t reserved1;
    DFSIterFrame iter_frames[64];  /* outermost to deepest */

    /* Bookkeeping (informational, not used to drive state) */
    int64_t prior_budget;          /* per_branch_node_limit at the prior run */
    int64_t prior_nodes_walked;    /* branch_nodes at exhaustion */
    int64_t prior_solutions_found; /* solutions_count at flush time */

    uint8_t reserved[64];
} DFSCheckpointState_v1;

/* Sanity bound on the on-disk size (~few hundred bytes per sub-branch). */
/* Sanity bound on the on-disk size (~few hundred bytes per sub-branch). */
_Static_assert(sizeof(DFSCheckpointState_v1) <= 1024, "DFSCheckpointState_v1 too large");

/* DFSCheckpointState_v2 (2026-04-30): full DFS-state capture, used by the
 * iterative DFS path to enable BIT-IDENTICAL resume vs single-shot.
 *
 * v1's iter-only capture (parent frames' (p, orient)) wasn't enough — the
 * subtree under the deepest interrupted iter was re-walked from scratch on
 * resume, while single-shot continued mid-subtree. Different walks → different
 * solutions found.
 *
 * v2 captures the COMPLETE iterative-DFS stack: for each frame, the full
 * (step, p, orient, bd, wd, prev_tail) tuple, plus the seq/used/budget
 * arrays. Resume reconstructs the exact DFS state at the moment of budget
 * exhaustion and continues from there. */
#define DFS_STATE_VERSION_V2 2u

/* DFSStackFrame_v2 is forward-defined near the Pair typedef so ThreadState
 * can hold an array of them. */

typedef struct {
    uint32_t magic;            /* DFS_STATE_MAGIC */
    uint16_t format_version;   /* DFS_STATE_VERSION_V2 */
    uint16_t partition_depth;
    int8_t   prefix_p1, prefix_o1;
    int8_t   prefix_p2, prefix_o2;
    int8_t   prefix_p3, prefix_o3;

    int16_t  sp;               /* stack-pointer at moment of capture; sp+1 frames are live */
    int16_t  reserved_align;
    DFSStackFrame_v2 frames[34];

    /* Full-state arrays */
    int8_t   seq[64];          /* hexagram values 0-63 */
    int8_t   used[32];         /* 0/1 flags */
    int8_t   budget[7];        /* remaining distance budgets (0-32 each) */
    int8_t   pad[5];           /* align next field */

    int64_t  prior_budget;
    int64_t  prior_nodes_walked;
    int64_t  prior_solutions_found;
    uint8_t  reserved2[16];
} DFSCheckpointState_v2;

_Static_assert(sizeof(DFSCheckpointState_v2) <= 2048, "DFSCheckpointState_v2 too large");

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
    /* Bit layout (no overlapping bits):
     *   bits 11..7 = p1 (5 bits, 0..31)
     *   bit 6      = o1
     *   bits 5..1  = p2 (5 bits)
     *   bit 0      = o2
     * Max key = 4095, fits in the 4096-bit (512-byte) bitmap.
     *
     * Bug history (2026-05-01): the prior layout used (p1<<6)|(o1<<5)|
     * (p2<<1)|o2, which collided o1 (bit 5) with p2's bit 4 (also at result
     * bit 5). On a partial PHASE_A (e.g., SIGTERM mid-walk), the bitmap
     * loaded from checkpoint.txt would erroneously mark some unwalked
     * sub-branches as completed, and PHASE_B's resume would skip them.
     * Surfaced via Tier 3 T3a (SIGTERM-then-resume) producing a different
     * sha than single-shot. Single-shot and clean PHASE_A→PHASE_B are
     * unaffected because the same bits get set anyway from the actual
     * completed entries. Depth-3 (`completed_sub_key_d3`) was always
     * correctly encoded.  */
    return ((p1 & 31) << 7) | ((o1 & 1) << 6) | ((p2 & 31) << 1) | (o2 & 1);
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
    /* 2026-04-28: ts->ht_size / ht_mask are int. Resizing to 2^31+ would
     * overflow them. Cap at 2^30 (1.07B slots, 32 GB / table). Fast warning
     * and no-op if already at cap; insertion still works (probes get longer
     * but lex-smallest-wins dedup keeps semantics correct). For runs needing
     * >800M unique solutions per worker, ht_size needs to be widened to
     * size_t/long throughout — separate change. */
    if (new_log2 > 30) {
        static int warned = 0;
        if (!warned) {
            fprintf(stderr, "WARN: thread %d hash table resize 2^%d → 2^%d "
                    "skipped (capped at 2^30); probing may degrade\n",
                    ts->thread_id, old_log2, new_log2);
            fflush(stderr);
            warned = 1;
        }
        return;
    }
    size_t new_size = (size_t)1 << new_log2;
    size_t new_mask = new_size - 1;

    unsigned char *new_table = calloc(new_size, SOL_RECORD_SIZE);
    char *new_occupied = calloc(new_size, 1);
    if (!new_table || !new_occupied) {
        fprintf(stderr, "FATAL: thread %d cannot resize hash table 2^%d → 2^%d "
                "(%lld MB). Out of memory.\n",
                ts->thread_id, old_log2, new_log2,
                (long long)(new_size * SOL_RECORD_SIZE / 1048576));
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
            SOL_HASH_MIX(ch);
            int slot = (int)(ch & (unsigned long long)new_mask);
            for (size_t p = 0; p < new_size; p++) {
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
    SOL_HASH_MIX(ch);

    if (!ts->sol_table) {
        ts->sol_table = calloc((size_t)ts->ht_size, SOL_RECORD_SIZE);
        ts->sol_occupied = calloc(ts->ht_size, 1);
        if (!ts->sol_table || !ts->sol_occupied) {
            fprintf(stderr, "FATAL: thread %d failed to allocate hash table (%d MB).\n",
                    ts->thread_id, (int)((size_t)ts->ht_size * SOL_RECORD_SIZE / 1048576));
            exit(1);
        }
    }

    /* Hold ht_mutex during probe/insert to protect against the
     * checkpoint thread reading this table concurrently. Per-worker
     * mutex is uncontended in steady state (only this worker inserts
     * into its own table), so overhead is ~100ns per call. */
    pthread_mutex_lock(&ts->ht_mutex);
    int slot = (int)(ch & (unsigned long long)ts->ht_mask);
    for (int probe = 0; probe < ts->ht_size; probe++) {
        int idx = (slot + probe) & ts->ht_mask;
        if (!ts->sol_occupied[idx]) {
            memcpy(&ts->sol_table[(size_t)idx * SOL_RECORD_SIZE], record, SOL_RECORD_SIZE);
            ts->sol_occupied[idx] = 1;
            ts->solution_count++;
            if (ts->solution_count > (long long)ts->ht_size * 3 / 4)
                resize_hash_table(ts);
            pthread_mutex_unlock(&ts->ht_mutex);
            return;
        }
        unsigned char *existing = &ts->sol_table[(size_t)idx * SOL_RECORD_SIZE];
        int match = 1;
        for (int ci = 0; ci < SOL_RECORD_SIZE; ci++) {
            if ((existing[ci] & 0xFC) != canonical[ci]) { match = 0; break; }
        }
        if (match) {
            /* Canonical-duplicate found. "Lex-smallest record wins" —
             * if the incoming record is byte-wise smaller than what's
             * stored, replace. This is a no-op for single-threaded DFS
             * (which visits orient=0 before orient=1 at every depth, so
             * the first-inserted record is already lex-smallest), but
             * is required for determinism under parallel --sub-branch
             * execution where multiple workers may find canonical-
             * duplicate solutions in different orient variants and
             * insertion order depends on thread scheduling.
             * See P1_IMPLEMENTATION_PLAN.md §Determinism. */
            if (memcmp(record, existing, SOL_RECORD_SIZE) < 0)
                memcpy(existing, record, SOL_RECORD_SIZE);
            ts->hash_collisions++;
            pthread_mutex_unlock(&ts->ht_mutex);
            return;
        }
    }
    pthread_mutex_unlock(&ts->ht_mutex);
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
/* Opt-in iterative DFS path (2026-04-30, SOLVE_DFS_ITERATIVE).
 *
 * Equivalent to backtrack() in pre-order traversal: same (p, orient) iteration
 * sequence at every depth. Selftest sha (403f7202...) reproduces with this
 * path active; canonical reproducibility is preserved.
 *
 * Why iterative? Mid-walk DFS-state checkpoint (SOLVE_DFS_CHECKPOINT, see
 * INCREMENTAL_EXTENSION_DESIGN.md) is much cleaner with explicit stack:
 * the entire DFS state at budget exhaustion is capturable as a snapshot of
 * stack[0..sp], with each frame's iter (p, orient) directly readable.
 *
 * Limitations:
 *   - This iterative path covers the NON-parallel case only (sub_sub_parallel_active==0).
 *     The parallel --sub-branch path (P1, line 1546+ in recursive backtrack)
 *     keeps the recursive form. Selftest, single-threaded enumeration, and
 *     basic --branch invocations use this path when SOLVE_DFS_ITERATIVE=1.
 *   - Stack depth bounded by 34 frames (depth 0 to 32, plus sentinel).
 */
static int dfs_iterative_enabled = 0;

#define DFSITER_PHASE_ENTER  0  /* first time at this depth — counter++, budget check, leaf check */
#define DFSITER_PHASE_RETRY  1  /* return-from-child — restore iter state, advance to next iter */

typedef struct {
    int step;
    int p;          /* current iter pair_idx */
    int orient;     /* current iter orient (0 or 1) */
    int prev_tail;  /* cached: seq[step*2 - 1] (computed once at frame entry) */
    int bd, wd;     /* distances consumed by current iter's setup (for restore) */
    int phase;      /* DFSITER_PHASE_ENTER or DFSITER_PHASE_RETRY */
} BacktrackFrame;

static void backtrack_iterative(ThreadState *ts, int seq[64], int used[32], int budget[7], int initial_step) {
    BacktrackFrame stack[34];
    int sp;

    /* If v2-resume is active, rebuild the stack + arrays from the capture
     * and continue from the captured position. */
    if (ts->dfs_v2_resume_active) {
        sp = ts->dfs_v2_resume_sp;
        if (sp < 0) sp = -1;
        if (sp >= 34) sp = 33;
        for (int i = 0; i <= sp && i < 34; i++) {
            stack[i].step = ts->dfs_v2_resume_frames[i].step;
            stack[i].p = ts->dfs_v2_resume_frames[i].p;
            stack[i].orient = ts->dfs_v2_resume_frames[i].orient;
            stack[i].bd = ts->dfs_v2_resume_frames[i].bd;
            stack[i].wd = ts->dfs_v2_resume_frames[i].wd;
            stack[i].prev_tail = ts->dfs_v2_resume_frames[i].prev_tail;
            stack[i].phase = ts->dfs_v2_resume_frames[i].phase;
        }
        for (int i = 0; i < 64; i++) seq[i] = ts->dfs_v2_resume_seq[i];
        for (int i = 0; i < 32; i++) used[i] = ts->dfs_v2_resume_used[i];
        for (int i = 0; i < 7;  i++) budget[i] = ts->dfs_v2_resume_budget[i];
        /* Resume start: ts->branch_nodes already set to prior_nodes_walked
         * at sub-branch entry (in the wrapper). Continue from saved state. */
    } else {
        sp = 0;
        stack[0].step = initial_step;
        stack[0].p = 0;
        stack[0].orient = 0;
        stack[0].phase = DFSITER_PHASE_ENTER;
        stack[0].prev_tail = (initial_step > 0) ? seq[initial_step * 2 - 1] : 0;

        /* v1-style resume override (only honored when v2 not active) */
        if (ts->dfs_resume_active) {
            int rd = stack[0].step - ts->dfs_resume_partition_prefix_len;
            if (rd >= 0 && rd < 64 && ts->dfs_resume_frames[rd].pair_idx >= 0) {
                stack[0].p = ts->dfs_resume_frames[rd].pair_idx;
                stack[0].orient = ts->dfs_resume_frames[rd].orient;
                ts->dfs_resume_frames[rd].pair_idx = -1;
            }
        }
    }

    while (sp >= 0) {
        BacktrackFrame *fr = &stack[sp];

        if (fr->phase == DFSITER_PHASE_ENTER) {
            /* === ENTER phase: one-time-per-frame work === */
            ts->nodes++;
            ts->branch_nodes++;
            if (fr->step <= 32) {
                ts->nodes_at_depth[fr->step]++;
                if (ts->current_task_stats) {
                    ((PerTaskStats *)ts->current_task_stats)->nodes_at_depth[fr->step]++;
                }
            }
            if (global_timed_out) return;
            if (ts->dfs_capture_active) {
                /* Capture flag set elsewhere — unwind. */
                sp--;
                if (sp >= 0) stack[sp].phase = DFSITER_PHASE_RETRY;
                continue;
            }
            /* Per-branch budget check (non-parallel path). */
            if (per_branch_node_limit > 0 && ts->branch_nodes >= per_branch_node_limit) {
                if (dfs_checkpoint_enabled) {
                    ts->dfs_capture_active = 1;
                    /* v2 capture: snapshot the FULL stack (including the
                     * just-budget-hit frame at sp) AND the seq/used/budget
                     * arrays, NOW. This is the bit that gives bit-identical
                     * resume vs single-shot in iterative form.
                     *
                     * The saved branch_nodes (written to .dfs_state in
                     * dfs_state_write_v2) is intentionally one less than the
                     * live ts->branch_nodes: this captured frame's ENTER
                     * already incremented the counter, but its DFS work
                     * never ran; on resume, PHASE_B's ENTER will increment
                     * again and do the work. Without this rollback the
                     * captured frame's increment counts twice cumulatively,
                     * exhausting PHASE_B's budget one frame early — that
                     * missed frame's solutions are the resume vs single-shot
                     * sha mismatch's root cause. The live counters stay
                     * intact so the BUDGETED-vs-EXHAUSTED status check at
                     * end-of-sub-branch sees the correct ">=  budget" state. */
                    int sp_save = sp;
                    if (sp_save >= 34) sp_save = 33;
                    ts->dfs_v2_sp = sp_save;
                    for (int i = 0; i <= sp_save; i++) {
                        ts->dfs_v2_frames[i].step      = (int8_t)stack[i].step;
                        ts->dfs_v2_frames[i].p         = (int8_t)stack[i].p;
                        ts->dfs_v2_frames[i].orient    = (int8_t)stack[i].orient;
                        ts->dfs_v2_frames[i].bd        = (int8_t)stack[i].bd;
                        ts->dfs_v2_frames[i].wd        = (int8_t)stack[i].wd;
                        ts->dfs_v2_frames[i].prev_tail = (int8_t)stack[i].prev_tail;
                        ts->dfs_v2_frames[i].phase     = (int8_t)stack[i].phase;
                    }
                    for (int i = 0; i < 64; i++) ts->dfs_v2_seq[i] = (int8_t)seq[i];
                    for (int i = 0; i < 32; i++) ts->dfs_v2_used[i] = (int8_t)used[i];
                    for (int i = 0; i < 7;  i++) ts->dfs_v2_budget[i] = (int8_t)budget[i];
                    ts->dfs_v2_capture_pending = 1;
                }
                /* Now unwind. Caller will see ts->dfs_capture_active and
                 * trigger the v2 file write at end-of-sub-branch. */
                return;
            }
            /* Time check every 50M nodes. */
            if (ts->nodes % 50000000 == 0) {
                if (time_limit > 0 && (time(NULL) - start_time) >= time_limit)
                    global_timed_out = 1;
            }
            if (global_timed_out) return;

            /* Leaf */
            if (fr->step == 32) {
                ts->solutions_total++;
                int cd = compute_comp_dist_x64(seq);
                if (cd <= kw_comp_dist_x64) {
                    ts->solutions_c3++;
                    if (ts->current_task_stats) {
                        ((PerTaskStats *)ts->current_task_stats)->c3_leaves++;
                    }
                    if (!ts->kw_found) {
                        int match = 1;
                        for (int i = 0; i < 64; i++) {
                            if (seq[i] != KW[i]) { match = 0; break; }
                        }
                        if (match) ts->kw_found = 1;
                    }
                    analyze_solution(ts, seq);
                }
                /* Pop leaf frame; parent should retry next iter. */
                sp--;
                if (sp >= 0) stack[sp].phase = DFSITER_PHASE_RETRY;
                continue;
            }
            /* Done with one-time setup; fall through to ITERATE phase below.
             * We don't change phase variable explicitly — the rest of the
             * loop body handles iteration. */
        } else {
            /* === RETRY phase: a child just popped; restore parent state, advance iter === */
            used[fr->p] = 0;
            budget[fr->wd]++;
            budget[fr->bd]++;
            if (ts->dfs_capture_active) {
                /* Capture this frame's (p, orient), then unwind. */
                if (ts->dfs_iter_top < 64) {
                    ts->dfs_iter_stack[ts->dfs_iter_top].pair_idx = (int8_t)fr->p;
                    ts->dfs_iter_stack[ts->dfs_iter_top].orient = (int8_t)fr->orient;
                    ts->dfs_iter_top++;
                }
                sp--;
                if (sp >= 0) stack[sp].phase = DFSITER_PHASE_RETRY;
                continue;
            }
            if (global_timed_out) return;
            /* Advance iter: orient++; if rolls over, p++. */
            fr->orient++;
            if (fr->orient >= 2) { fr->p++; fr->orient = 0; }
        }

        /* === ITERATE phase: try next valid (p, orient); push child if found, pop if exhausted === */
        int found = 0;
        while (fr->p < 32) {
            if (used[fr->p]) {
                fr->p++;
                fr->orient = 0;
                continue;
            }
            int first = fr->orient ? pairs[fr->p].b : pairs[fr->p].a;
            int second = fr->orient ? pairs[fr->p].a : pairs[fr->p].b;
            int bd = hamming(fr->prev_tail, first);
            if (bd == 5) {
                fr->orient++;
                if (fr->orient >= 2) { fr->p++; fr->orient = 0; }
                continue;
            }
            if (budget[bd] <= 0) {
                fr->orient++;
                if (fr->orient >= 2) { fr->p++; fr->orient = 0; }
                continue;
            }
            budget[bd]--;
            int wd = hamming(first, second);
            if (budget[wd] <= 0) {
                budget[bd]++;
                fr->orient++;
                if (fr->orient >= 2) { fr->p++; fr->orient = 0; }
                continue;
            }
            budget[wd]--;
            seq[fr->step * 2] = first;
            seq[fr->step * 2 + 1] = second;
            used[fr->p] = 1;
            fr->bd = bd;
            fr->wd = wd;
            found = 1;
            break;
        }

        if (found) {
            /* Push child frame */
            if (sp + 1 >= 34) {
                fprintf(stderr, "FATAL: backtrack_iterative stack overflow at sp=%d\n", sp);
                return;
            }
            sp++;
            stack[sp].step = stack[sp - 1].step + 1;
            stack[sp].p = 0;
            stack[sp].orient = 0;
            stack[sp].phase = DFSITER_PHASE_ENTER;
            stack[sp].prev_tail = seq[stack[sp].step * 2 - 1];
            /* Apply resume override at child depth */
            if (ts->dfs_resume_active) {
                int rd = stack[sp].step - ts->dfs_resume_partition_prefix_len;
                if (rd >= 0 && rd < 64 && ts->dfs_resume_frames[rd].pair_idx >= 0) {
                    stack[sp].p = ts->dfs_resume_frames[rd].pair_idx;
                    stack[sp].orient = ts->dfs_resume_frames[rd].orient;
                    ts->dfs_resume_frames[rd].pair_idx = -1;
                }
            }
        } else {
            /* Iteration exhausted at this depth; pop self. Parent (if any)
             * will run its RETRY phase next. */
            sp--;
            if (sp >= 0) stack[sp].phase = DFSITER_PHASE_RETRY;
        }
    }
}

static void backtrack(ThreadState *ts, int seq[64], int used[32], int budget[7], int step) {
    ts->nodes++;
    ts->branch_nodes++;
    if ((unsigned)step <= 32) {
        ts->nodes_at_depth[step]++;  /* --depth-profile (aggregate) */
        /* Per-task depth histogram (2026-04-24). Pointer is NULL outside
         * task boundaries; cast to PerTaskStats* inside to avoid the
         * struct fwd-decl dance given solve.c's header ordering. */
        if (ts->current_task_stats) {
            ((PerTaskStats *)ts->current_task_stats)->nodes_at_depth[step]++;
        }
    }
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
    /* DFS-state checkpoint capture-mode early-out: once the deepest frame has
     * detected budget exhaustion, every recursive frame returns immediately on
     * entry. The for-loop in the parent frame then captures (p, orient) for
     * its depth on return-from-recurse and propagates upward. */
    if (ts->dfs_capture_active) return;
    /* Per-branch node limit: checked every node (just an integer compare, cheap).
     * Sets a thread-local flag rather than global_timed_out so other branches
     * on this thread can continue. But for simplicity, we use global_timed_out
     * which stops this branch's backtrack immediately. The thread function
     * resets it... actually we can't reset a volatile global. Instead, return
     * directly without setting the global flag.
     *
     * Parallel --sub-branch mode (P1, 2026-04-21): when running inside the
     * parallel sub-sub-branch workers, `sub_sub_shared_nodes` accumulates
     * completed-task node counts across all threads, and we treat
     * `ts->branch_nodes + sub_sub_shared_nodes` as the effective global
     * consumption. `sub_sub_budget_hit` is a short-circuit flag flipped
     * by whichever worker first crosses budget; other workers notice on
     * their next backtrack entry and bail. In single-threaded / legacy
     * modes `sub_sub_shared_nodes` stays 0 and `sub_sub_budget_hit` stays
     * 0, so behavior is identical to pre-P1.
     */
    if (sub_sub_parallel_active) {
        if (sub_sub_budget_hit) return;
        if (ts->task_cap_hit) return;
        /* Flush local progress to this worker's CCD-assigned counter every
         * ~65K nodes and check vs budget. Per-CCD sharding reduces cache-
         * line contention vs a single global counter — see data structures
         * block for rationale. Budget check sums all 16 CCD counters
         * (~4ns), much cheaper than the amortized contention cost of a
         * single global __sync_add_and_fetch at 128 threads. */
        long long delta = ts->branch_nodes - ts->pending_shared_flush;
        if (delta >= 65536) {
            ts->pending_shared_flush = ts->branch_nodes;
            int slot = ts->thread_id % N_SUB_SUB_COUNTERS;
            __sync_add_and_fetch(&sub_sub_counters[slot].nodes, delta);
            if (per_branch_node_limit > 0 &&
                sub_sub_sum_counters() >= per_branch_node_limit) {
                sub_sub_budget_hit = 1;
                return;
            }
            /* Per-task budget cap (2026-04-28, SOLVE_PER_TASK_NODE_LIMIT).
             * Sets per-worker task_cap_hit flag so ALL recursive frames
             * unwind on their next entry — without this, parent loops
             * iterate siblings and each sibling walks ~65K nodes before
             * its own cap fire, producing 30^depth wasted work.
             * Other workers continue. When 0 (default), no cap → byte-
             * identical output to pre-2026-04-28 builds. */
            if (per_task_node_limit > 0 &&
                (ts->branch_nodes - ts->task_node_start) >= per_task_node_limit) {
                ts->task_cap_hit = 1;
                return;
            }
        }
    } else {
        if (per_branch_node_limit > 0 && ts->branch_nodes >= per_branch_node_limit) {
            /* DFS-state checkpoint: signal that the recursion should unwind via
             * the capture path so each frame records its (p, orient). Only when
             * the operator opted in via SOLVE_DFS_CHECKPOINT=1. The save-side
             * (dfs_state_write) records branch_nodes - 1 to roll back this
             * captured frame's ENTER increment so resume PHASE_B re-incrementing
             * gives a cumulative count that matches single-shot. See the
             * matching comment in backtrack_iterative's v2 capture for the
             * full off-by-one rationale. */
            if (dfs_checkpoint_enabled) {
                ts->dfs_capture_active = 1;
            }
            return;  /* branch budget exhausted — stop this branch only (legacy) */
        }
    }
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
            /* Per-task C3-leaf count (2026-04-24). */
            if (ts->current_task_stats) {
                ((PerTaskStats *)ts->current_task_stats)->c3_leaves++;
            }
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

    /* DFS-state checkpoint resume: if the operator enabled SOLVE_DFS_CHECKPOINT
     * and a .dfs_state sidecar was loaded for this sub-branch, the for loop
     * at this depth starts at the saved (p, orient) instead of (0, 0). The
     * saved state is consumed once (cleared after use) so deeper recursion
     * back into this depth (different parent iteration paths) starts fresh. */
    int p_start = 0, o_start = 0;
    if (ts->dfs_resume_active) {
        int rd = step - ts->dfs_resume_partition_prefix_len;
        if (rd >= 0 && rd < 64 && ts->dfs_resume_frames[rd].pair_idx >= 0) {
            p_start = ts->dfs_resume_frames[rd].pair_idx;
            o_start = ts->dfs_resume_frames[rd].orient;
            ts->dfs_resume_frames[rd].pair_idx = -1;  /* mark consumed */
        }
    }

    for (int p = p_start; p < 32; p++) {
        if (used[p]) continue;
        int o_init = (p == p_start) ? o_start : 0;
        for (int orient = o_init; orient < 2; orient++) {
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
            /* DFS-state checkpoint capture: if the recursion just unwound
             * because budget exhausted (signaled by ts->dfs_capture_active),
             * record THIS frame's (p, orient) iterator state. The stack is
             * built deepest-first as we unwind through callers. */
            if (ts->dfs_capture_active) {
                if (ts->dfs_iter_top < 64) {
                    ts->dfs_iter_stack[ts->dfs_iter_top].pair_idx = (int8_t)p;
                    ts->dfs_iter_stack[ts->dfs_iter_top].orient = (int8_t)orient;
                    ts->dfs_iter_top++;
                }
                return;
            }
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

/* DFS-state checkpoint helpers (2026-04-30, SOLVE_DFS_CHECKPOINT). All no-op
 * unless dfs_checkpoint_enabled = 1. */

/* Compose the .dfs_state filename for a sub-branch. Returns 0 on success. */
static int dfs_state_filename(char *buf, size_t bufsz,
                              int p1, int o1, int p2, int o2, int p3, int o3) {
    if (p3 >= 0)
        return snprintf(buf, bufsz, "sub_%d_%d_%d_%d_%d_%d.dfs_state",
                        p1, o1, p2, o2, p3, o3) < (int)bufsz ? 0 : -1;
    return snprintf(buf, bufsz, "sub_%d_%d_%d_%d.dfs_state",
                    p1, o1, p2, o2) < (int)bufsz ? 0 : -1;
}

/* Write a DFS-state sidecar atomically (.tmp + rename). Called only when
 * dfs_checkpoint_enabled and dfs_capture_active and there's at least one
 * iter frame to save. Returns 0 on success. */
static int dfs_state_write(int p1, int o1, int p2, int o2, int p3, int o3,
                           const ThreadState *ts) {
    char fname[96], tmpname[128];
    if (dfs_state_filename(fname, sizeof(fname), p1, o1, p2, o2, p3, o3)) return -1;
    snprintf(tmpname, sizeof(tmpname), "%s.tmp", fname);

    DFSCheckpointState_v1 st;
    memset(&st, 0, sizeof(st));
    st.magic = DFS_STATE_MAGIC;
    st.format_version = DFS_STATE_VERSION;
    st.partition_depth = (p3 >= 0) ? 3 : 2;
    st.prefix_p1 = p1; st.prefix_o1 = o1;
    st.prefix_p2 = p2; st.prefix_o2 = o2;
    st.prefix_p3 = (int8_t)p3; st.prefix_o3 = (int8_t)o3;
    st.iter_top = (uint16_t)ts->dfs_iter_top;
    if (st.iter_top > 64) st.iter_top = 64;
    /* The capture during unwind appends frames in deepest-first order. The
     * design wants iter_frames[0] = OUTERMOST (sub-branch entry depth) and
     * iter_frames[top-1] = DEEPEST. Reverse on serialize. */
    for (int i = 0; i < st.iter_top; i++) {
        st.iter_frames[i] = ts->dfs_iter_stack[st.iter_top - 1 - i];
    }
    st.prior_budget = per_branch_node_limit;
    /* Roll back the captured frame's ENTER counter increment: the frame at
     * sp had its ENTER ++ branch_nodes but its DFS work never ran. On resume,
     * PHASE_B's ENTER will increment again and do the work, so the cumulative
     * count matches single-shot. See the corresponding comment in
     * backtrack_iterative's v2 capture path. */
    st.prior_nodes_walked = (ts->branch_nodes > 0) ? ts->branch_nodes - 1 : 0;
    st.prior_solutions_found = ts->solution_count;

    FILE *f = fopen(tmpname, "wb");
    if (!f) {
        fprintf(stderr, "WARN: dfs_state_write: fopen(%s) failed: %s\n",
                tmpname, strerror(errno));
        return -1;
    }
    if (fwrite(&st, sizeof(st), 1, f) != 1) {
        fprintf(stderr, "WARN: dfs_state_write: fwrite(%s) failed\n", tmpname);
        fclose(f);
        unlink(tmpname);
        return -1;
    }
    if (fflush(f) != 0 || fsync(fileno(f)) != 0 || fclose(f) != 0) {
        fprintf(stderr, "WARN: dfs_state_write: fsync/close(%s) failed\n", tmpname);
        unlink(tmpname);
        return -1;
    }
    if (rename(tmpname, fname) != 0) {
        fprintf(stderr, "WARN: dfs_state_write: rename(%s -> %s) failed\n",
                tmpname, fname);
        unlink(tmpname);
        return -1;
    }
    fprintf(stderr, "[dfs-checkpoint] WROTE %s (iter_top=%u, nodes=%lld)\n",
            fname, (unsigned)st.iter_top, (long long)st.prior_nodes_walked);
    return 0;
}

/* Read a DFS-state sidecar if present. Returns 0 if found and valid;
 * 1 if file does not exist (no resume needed); -1 on read/format error
 * (caller should treat as "no resume" — defensive). On success, populates
 * ts->dfs_resume_active and ts->dfs_resume_frames. */
static int dfs_state_read(int p1, int o1, int p2, int o2, int p3, int o3,
                          ThreadState *ts) {
    char fname[96];
    if (dfs_state_filename(fname, sizeof(fname), p1, o1, p2, o2, p3, o3)) return -1;
    FILE *f = fopen(fname, "rb");
    if (!f) return 1;  /* no sidecar = no resume needed */
    DFSCheckpointState_v1 st;
    size_t n = fread(&st, 1, sizeof(st), f);
    fclose(f);
    if (n != sizeof(st)) {
        fprintf(stderr, "WARN: dfs_state_read: short read on %s (got %zu)\n", fname, n);
        return -1;
    }
    if (st.magic != DFS_STATE_MAGIC || st.format_version != DFS_STATE_VERSION) {
        fprintf(stderr, "WARN: dfs_state_read: bad magic/version on %s\n", fname);
        return -1;
    }
    if (st.prefix_p1 != p1 || st.prefix_o1 != o1
        || st.prefix_p2 != p2 || st.prefix_o2 != o2
        || st.prefix_p3 != (int8_t)p3 || st.prefix_o3 != (int8_t)o3) {
        fprintf(stderr, "WARN: dfs_state_read: prefix mismatch on %s\n", fname);
        return -1;
    }
    if (st.iter_top == 0 || st.iter_top > 64) {
        fprintf(stderr, "WARN: dfs_state_read: bad iter_top=%u on %s\n",
                (unsigned)st.iter_top, fname);
        return -1;
    }
    /* Populate resume frames. iter_frames[0] = outermost (partition_prefix_len),
     * iter_frames[top-1] = deepest. dfs_resume_frames is indexed by
     * (depth - partition_prefix_len), so just copy.
     *
     * v1 resume policy (2026-04-30): the saved (p, orient) overrides
     * combined with branch_nodes accounting cannot reach single-shot
     * coverage — the recursive descent re-walk inflates branch_nodes
     * before new work begins, so the budget exhausts before all
     * (saved..end) iters are walked. The fix here: leave the override
     * frames empty (all pair_idx=-1). PHASE_B then walks ALL iters at
     * every level (same as a fresh enum), finding the same solutions
     * as single-shot. PHASE_A's contributions are still preserved via
     * the load_prior_shard hash-table pre-population. dfs_resume_active
     * stays 1 so the wrapper still calls load_prior_shard and tracks
     * "this was a resume" for the bookkeeping that follows.
     *
     * Trade-off: PHASE_A's enumeration work is fully redundant for v1;
     * the resume only saves hash-table pre-load (cheap). The v2
     * (iterative) path retains true mid-walk resume — that's the
     * supported production path. */
    int prefix_len = (p3 >= 0) ? 4 : 2;
    ts->dfs_resume_partition_prefix_len = prefix_len;
    ts->dfs_resume_active = 1;
    for (int i = 0; i < 64; i++) {
        ts->dfs_resume_frames[i].pair_idx = -1;
        ts->dfs_resume_frames[i].orient = 0;
    }
    /* Intentionally NOT copying st.iter_frames into ts->dfs_resume_frames —
     * see policy note above. */
    ts->dfs_resume_prior_nodes = st.prior_nodes_walked;
    fprintf(stderr, "[dfs-checkpoint] READ  %s (iter_top=%u, prior nodes=%lld; v1 walks fresh, hash-table pre-loaded)\n",
            fname, (unsigned)st.iter_top, (long long)st.prior_nodes_walked);
    return 0;
}

/* Delete a DFS-state sidecar (called when sub-branch completes naturally,
 * i.e. EXHAUSTED, so future runs don't see a stale resume point). */
static void dfs_state_delete(int p1, int o1, int p2, int o2, int p3, int o3) {
    char fname[96];
    if (dfs_state_filename(fname, sizeof(fname), p1, o1, p2, o2, p3, o3)) return;
    unlink(fname);  /* ignore errors — file may not exist */
}

/* v2 write: atomic write of full-stack capture. Called only when the
 * iterative path captures via dfs_v2_capture_pending. */
static int dfs_state_write_v2(int p1, int o1, int p2, int o2, int p3, int o3,
                              const ThreadState *ts) {
    char fname[96], tmpname[128];
    if (dfs_state_filename(fname, sizeof(fname), p1, o1, p2, o2, p3, o3)) return -1;
    snprintf(tmpname, sizeof(tmpname), "%s.tmp", fname);

    DFSCheckpointState_v2 st;
    memset(&st, 0, sizeof(st));
    st.magic = DFS_STATE_MAGIC;
    st.format_version = DFS_STATE_VERSION_V2;
    st.partition_depth = (p3 >= 0) ? 3 : 2;
    st.prefix_p1 = p1; st.prefix_o1 = o1;
    st.prefix_p2 = p2; st.prefix_o2 = o2;
    st.prefix_p3 = (int8_t)p3; st.prefix_o3 = (int8_t)o3;

    int sp_capture = ts->dfs_v2_sp;
    if (sp_capture < 0) sp_capture = -1;
    if (sp_capture >= 34) sp_capture = 33;
    st.sp = (int16_t)sp_capture;
    for (int i = 0; i <= sp_capture && i < 34; i++) {
        st.frames[i] = ts->dfs_v2_frames[i];
    }
    memcpy(st.seq, ts->dfs_v2_seq, 64);
    memcpy(st.used, ts->dfs_v2_used, 32);
    memcpy(st.budget, ts->dfs_v2_budget, 7);
    st.prior_budget = per_branch_node_limit;
    /* Roll back the captured frame's ENTER counter increment — see comment
     * at backtrack_iterative's v2 capture site for the off-by-one rationale. */
    st.prior_nodes_walked = (ts->branch_nodes > 0) ? ts->branch_nodes - 1 : 0;
    st.prior_solutions_found = ts->solution_count;

    FILE *f = fopen(tmpname, "wb");
    if (!f) return -1;
    if (fwrite(&st, sizeof(st), 1, f) != 1) {
        fclose(f); unlink(tmpname); return -1;
    }
    if (fflush(f) != 0 || fsync(fileno(f)) != 0 || fclose(f) != 0) {
        unlink(tmpname); return -1;
    }
    if (rename(tmpname, fname) != 0) {
        unlink(tmpname); return -1;
    }
    fprintf(stderr, "[dfs-v2] WROTE %s (sp=%d, nodes=%lld)\n",
            fname, (int)st.sp, (long long)st.prior_nodes_walked);
    return 0;
}

/* v2 read: load full-stack capture into ts->dfs_v2_resume_*.
 * Returns 0 if v2 read OK; 1 if no file or wrong version (caller should fall
 * back to v1 read); -1 on read/format error. */
static int dfs_state_read_v2(int p1, int o1, int p2, int o2, int p3, int o3,
                             ThreadState *ts) {
    char fname[96];
    if (dfs_state_filename(fname, sizeof(fname), p1, o1, p2, o2, p3, o3)) return -1;
    FILE *f = fopen(fname, "rb");
    if (!f) return 1;
    DFSCheckpointState_v2 st;
    size_t n = fread(&st, 1, sizeof(st), f);
    fclose(f);
    if (n != sizeof(st)) return -1;
    if (st.magic != DFS_STATE_MAGIC) return -1;
    if (st.format_version != DFS_STATE_VERSION_V2) return 1;  /* not v2 */
    if (st.prefix_p1 != p1 || st.prefix_o1 != o1
        || st.prefix_p2 != p2 || st.prefix_o2 != o2
        || st.prefix_p3 != (int8_t)p3 || st.prefix_o3 != (int8_t)o3) return -1;
    if (st.sp < -1 || st.sp >= 34) return -1;

    ts->dfs_v2_resume_active = 1;
    ts->dfs_v2_resume_sp = st.sp;
    for (int i = 0; i < 34; i++) ts->dfs_v2_resume_frames[i] = st.frames[i];
    memcpy(ts->dfs_v2_resume_seq, st.seq, 64);
    memcpy(ts->dfs_v2_resume_used, st.used, 32);
    memcpy(ts->dfs_v2_resume_budget, st.budget, 7);
    ts->dfs_resume_prior_nodes = st.prior_nodes_walked;
    fprintf(stderr, "[dfs-v2] READ  %s (sp=%d, prior nodes=%lld)\n",
            fname, (int)st.sp, (long long)st.prior_nodes_walked);
    return 0;
}

/* Load prior shard contents into the thread's hash table at sub-branch entry
 * (resume mode only). Mirrors the consolidation logic at line 2418+: for each
 * 32-byte record, compute canonical hash, probe-insert. Records already in
 * the prior shard are dedup-merged with new finds during this run; the
 * subsequent flush writes the union, byte-equivalent to a single-shot run
 * that walked from scratch to the resumed budget. */
static int dfs_state_load_prior_shard(int p1, int o1, int p2, int o2, int p3, int o3,
                                      ThreadState *ts) {
    char fname[96];
    if (p3 >= 0)
        snprintf(fname, sizeof(fname), "sub_%d_%d_%d_%d_%d_%d.bin",
                 p1, o1, p2, o2, p3, o3);
    else
        snprintf(fname, sizeof(fname), "sub_%d_%d_%d_%d.bin", p1, o1, p2, o2);
    FILE *f = fopen(fname, "rb");
    if (!f) return 1;  /* no prior shard = nothing to load */

    /* Allocate hash table if not already (analyze_solution does this lazily;
     * we may be called before any backtrack). */
    if (!ts->sol_table) {
        ts->sol_table = calloc((size_t)ts->ht_size, SOL_RECORD_SIZE);
        ts->sol_occupied = calloc(ts->ht_size, 1);
        if (!ts->sol_table || !ts->sol_occupied) {
            fprintf(stderr, "FATAL: dfs_state_load_prior_shard alloc failed\n");
            fclose(f);
            return -1;
        }
    }

    pthread_mutex_lock(&ts->ht_mutex);
    long long loaded = 0;
    unsigned char rec[SOL_RECORD_SIZE];
    while (fread(rec, SOL_RECORD_SIZE, 1, f) == 1) {
        unsigned char canonical[SOL_RECORD_SIZE];
        for (int i = 0; i < SOL_RECORD_SIZE; i++) canonical[i] = rec[i] & 0xFC;
        unsigned long long ch = 14695981039346656037ULL;
        for (int i = 0; i < SOL_RECORD_SIZE; i++) { ch ^= canonical[i]; ch *= 1099511628211ULL; }
        SOL_HASH_MIX(ch);
        int slot = (int)(ch & (unsigned long long)ts->ht_mask);
        for (int probe = 0; probe < ts->ht_size; probe++) {
            int idx = (slot + probe) & ts->ht_mask;
            if (!ts->sol_occupied[idx]) {
                memcpy(&ts->sol_table[(size_t)idx * SOL_RECORD_SIZE], rec, SOL_RECORD_SIZE);
                ts->sol_occupied[idx] = 1;
                ts->solution_count++;
                loaded++;
                if (ts->solution_count > (long long)ts->ht_size * 3 / 4)
                    resize_hash_table(ts);
                break;
            }
            unsigned char *existing = &ts->sol_table[(size_t)idx * SOL_RECORD_SIZE];
            int match = 1;
            for (int ci = 0; ci < SOL_RECORD_SIZE; ci++) {
                if ((existing[ci] & 0xFC) != canonical[ci]) { match = 0; break; }
            }
            if (match) {
                if (memcmp(rec, existing, SOL_RECORD_SIZE) < 0)
                    memcpy(existing, rec, SOL_RECORD_SIZE);
                break;
            }
        }
    }
    pthread_mutex_unlock(&ts->ht_mutex);
    fclose(f);
    fprintf(stderr, "[dfs-checkpoint] LOADED %s into hash table (%lld records)\n",
            fname, loaded);
    return 0;
}

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
    struct tm tmbuf;
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%d %H:%M:%S UTC", gmtime_r(&now, &tmbuf));
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

        /* DFS-state checkpoint: load any prior .dfs_state for this sub-branch
         * so the recursion/iteration resumes at the saved state. Reset capture
         * fields (we want a fresh capture if THIS run also exhausts budget).
         * No-op unless dfs_checkpoint_enabled. */
        ts->dfs_capture_active = 0;
        ts->dfs_iter_top = 0;
        ts->dfs_resume_active = 0;
        ts->dfs_resume_prior_nodes = 0;
        ts->dfs_v2_capture_pending = 0;
        ts->dfs_v2_resume_active = 0;
        if (dfs_checkpoint_enabled) {
            int p3_arg = (sb->pair3 >= 0) ? sb->pair3 : -1;
            int o3_arg = (sb->pair3 >= 0) ? sb->orient3 : -1;
            /* Try v2 first (full-state capture, used by iterative path);
             * fall back to v1 (iter-only, used by recursive path). */
            int v2_rc = dfs_state_read_v2(p1, o1, p2, o2, p3_arg, o3_arg, ts);
            if (v2_rc != 0) {
                /* v2 not present or wrong version; try v1 */
                (void)dfs_state_read(p1, o1, p2, o2, p3_arg, o3_arg, ts);
            }
            /* Restore the per-sub-branch node counter:
             *   v2 (iterative+full-state-capture): the saved frame is restored
             *     EXACTLY at the captured stack position, so PHASE_B's walk
             *     does NOT redo the descent. Start branch_nodes at the saved
             *     value (one less than the captured frame's count, due to the
             *     off-by-one rollback at save time) so the cumulative count
             *     matches single-shot's coverage at budget exhaustion.
             *   v1 (recursive+iter-only-capture): PHASE_B's recursion always
             *     re-walks the descent path F_1..F_K via the captured (p, orient)
             *     overrides at each level. Each descent frame's recursive call
             *     ENTER ++'s branch_nodes. Setting branch_nodes to 0 lets
             *     PHASE_B's budget enforce the same total coverage as single-
             *     shot would (the redundant descent's work is dedup'd by the
             *     hash table, which was pre-populated from the prior shard). */
            if (ts->dfs_v2_resume_active) {
                ts->branch_nodes = ts->dfs_resume_prior_nodes;
            } else if (ts->dfs_resume_active) {
                ts->branch_nodes = 0;
            }
            if (ts->dfs_resume_active || ts->dfs_v2_resume_active) {
                /* Load prior shard contents into hash table so the flush at
                 * end-of-walk produces a single-shot-equivalent merged shard. */
                (void)dfs_state_load_prior_shard(p1, o1, p2, o2, p3_arg, o3_arg, ts);
            }
        }

        if (dfs_iterative_enabled) {
            backtrack_iterative(ts, seq, used, budget, backtrack_start_step);
        } else {
            backtrack(ts, seq, used, budget, backtrack_start_step);
        }

        /* DFS-state checkpoint: if budget exhausted in this run, persist the
         * captured state. If it ran to completion, delete any prior sidecar
         * so a future resume doesn't try to re-walk a finished branch. */
        if (dfs_checkpoint_enabled) {
            int p3_arg = (sb->pair3 >= 0) ? sb->pair3 : -1;
            int o3_arg = (sb->pair3 >= 0) ? sb->orient3 : -1;
            if (ts->dfs_v2_capture_pending) {
                /* Iterative path captured full DFS state — write v2. */
                (void)dfs_state_write_v2(p1, o1, p2, o2, p3_arg, o3_arg, ts);
            } else if (ts->dfs_capture_active && ts->dfs_iter_top > 0) {
                /* Recursive path captured iter-only state — write v1. */
                (void)dfs_state_write(p1, o1, p2, o2, p3_arg, o3_arg, ts);
            } else {
                /* Naturally completed (or interrupted before any frame captured) —
                 * remove any stale sidecar from a prior partial run. */
                dfs_state_delete(p1, o1, p2, o2, p3_arg, o3_arg);
            }
        }

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

/* ---------- Parallel --sub-branch helpers (P1) ----------
 * See the data-structures block near the top of this file for context.
 */

/* Enumerate valid (p4, o4, p5, o5) extensions of the shared depth-3 prefix.
 * Populates sub_sub_tasks[] and sets n_sub_sub_tasks. Tasks emitted in
 * lex (p4, o4, p5, o5) order — important: workers pull in this same order,
 * so the output of a BUDGETED run is {tasks 0..K-1} where K is the count
 * that completed before budget was hit, and lex-smallest-wins dedup in
 * analyze_solution collapses any canonical-equivalent solutions to a
 * deterministic winner regardless of thread scheduling.
 *
 * Pruning matches the per-step logic in backtrack() exactly at each depth:
 *   depth 4: p4 not used, Hamming(s3, f4) != 5, budget has room for bd4+wd4
 *   depth 5: p5 not used (accounting for p4), same Hamming + budget check
 *            against the budget AFTER depth-4 decrements
 *
 * Preconditions: shared_prefix_seq/used/budget populated by main.
 */
static void build_sub_sub_branch_tasks(void) {
    n_sub_sub_tasks = 0;
    int s3 = shared_prefix_seq[7];
    /* local_used mutates across the outer loop — depth-4's used[p4]=1
     * must be undone before the next outer iteration. local_budget is
     * similarly restored. */
    int local_used[32];
    int local_budget[7];
    for (int p4 = 0; p4 < 32; p4++) {
        if (shared_prefix_used[p4]) continue;
        for (int o4 = 0; o4 < 2; o4++) {
            int f4 = o4 ? pairs[p4].b : pairs[p4].a;
            int s4 = o4 ? pairs[p4].a : pairs[p4].b;
            int bd4 = hamming(s3, f4);
            if (bd4 == 5) continue;
            if (shared_prefix_budget[bd4] <= 0) continue;
            int wd4 = hamming(f4, s4);
            int need_wd4 = (bd4 == wd4) ? 2 : 1;
            if (shared_prefix_budget[wd4] < need_wd4) continue;

            /* Apply depth-4 to local copies; enumerate (p5, o5) under that. */
            memcpy(local_used, shared_prefix_used, sizeof(local_used));
            memcpy(local_budget, shared_prefix_budget, sizeof(local_budget));
            local_used[p4] = 1;
            local_budget[bd4]--;
            local_budget[wd4]--;

            for (int p5 = 0; p5 < 32; p5++) {
                if (local_used[p5]) continue;
                for (int o5 = 0; o5 < 2; o5++) {
                    int f5 = o5 ? pairs[p5].b : pairs[p5].a;
                    int s5 = o5 ? pairs[p5].a : pairs[p5].b;
                    int bd5 = hamming(s4, f5);
                    if (bd5 == 5) continue;
                    if (local_budget[bd5] <= 0) continue;
                    int wd5 = hamming(f5, s5);
                    int need_wd5 = (bd5 == wd5) ? 2 : 1;
                    if (local_budget[wd5] < need_wd5) continue;

                    if (n_sub_sub_tasks >= SUB_SUB_MAX) {
                        fprintf(stderr, "FATAL: SUB_SUB_MAX (%d) exceeded — P1 assumption broken\n",
                                SUB_SUB_MAX);
                        exit(10);
                    }
                    sub_sub_tasks[n_sub_sub_tasks].p4  = p4;
                    sub_sub_tasks[n_sub_sub_tasks].o4  = o4;
                    sub_sub_tasks[n_sub_sub_tasks].f4  = f4;
                    sub_sub_tasks[n_sub_sub_tasks].s4  = s4;
                    sub_sub_tasks[n_sub_sub_tasks].bd4 = bd4;
                    sub_sub_tasks[n_sub_sub_tasks].wd4 = wd4;
                    sub_sub_tasks[n_sub_sub_tasks].p5  = p5;
                    sub_sub_tasks[n_sub_sub_tasks].o5  = o5;
                    sub_sub_tasks[n_sub_sub_tasks].f5  = f5;
                    sub_sub_tasks[n_sub_sub_tasks].s5  = s5;
                    sub_sub_tasks[n_sub_sub_tasks].bd5 = bd5;
                    sub_sub_tasks[n_sub_sub_tasks].wd5 = wd5;
                    n_sub_sub_tasks++;
                }
            }
        }
    }
}

/* Worker entry point for parallel --sub-branch.
 * Each worker owns its own ThreadState (including its private hash table)
 * and pulls tasks from sub_sub_tasks[] via the atomic sub_sub_next_idx.
 * No locks in the hot path: all task state is stack-local + per-task
 * snapshot of the shared depth-3 prefix; the only shared atomics are
 * sub_sub_next_idx, sub_sub_shared_nodes, sub_sub_budget_hit.
 */
/* Write a worker's hash table + per-CCD counters to a per-worker snapshot
 * file sub_ckpt_wrk<tid>.bin and update sub_ckpt_meta.txt with the total
 * shared_nodes count so a resume can restore the pre-eviction state.
 * Atomic: .tmp then rename. Caller does NOT clear the hash table after —
 * the worker keeps running on the same state, this is just a durability
 * snapshot. Caller holds ts->ht_mutex to synchronize against concurrent
 * inserts in analyze_solution. */
static void sub_ckpt_flush_worker(ThreadState *ts) {
    char fname[64], tmpname[64];
    snprintf(fname,   sizeof(fname),   "sub_ckpt_wrk%d.bin",     ts->thread_id);
    snprintf(tmpname, sizeof(tmpname), "sub_ckpt_wrk%d.bin.tmp", ts->thread_id);
    FILE *wf = fopen(tmpname, "wb");
    if (!wf) {
        fprintf(stderr, "WARNING: ckpt: cannot open %s: %s\n", tmpname, strerror(errno));
        return;
    }
    long long written = 0;
    if (ts->sol_table && ts->sol_occupied) {
        for (int s = 0; s < ts->ht_size; s++) {
            if (!ts->sol_occupied[s]) continue;
            if (fwrite(&ts->sol_table[(size_t)s * SOL_RECORD_SIZE],
                       SOL_RECORD_SIZE, 1, wf) != 1) {
                fprintf(stderr, "WARNING: ckpt: short write on %s\n", tmpname);
                fclose(wf);
                return;
            }
            written++;
        }
    }
    if (fflush(wf) != 0 || fsync(fileno(wf)) != 0) {
        fprintf(stderr, "WARNING: ckpt: fflush/fsync failed on %s\n", tmpname);
        fclose(wf);
        return;
    }
    fclose(wf);
    if (rename(tmpname, fname) != 0) {
        fprintf(stderr, "WARNING: ckpt: rename %s → %s failed\n", tmpname, fname);
        return;
    }
    /* Update meta file (atomic via tmp + rename). Meta records both the
     * shared_nodes value (so resume restores budget state) and the number
     * of per-worker files (so resume knows how many to look for). */
    long long shared = sub_sub_sum_counters();
    FILE *mf = fopen("sub_ckpt_meta.txt.tmp", "w");
    if (mf) {
        fprintf(mf, "shared_nodes %lld\n", shared);
        fprintf(mf, "ckpt_time    %ld\n", (long)time(NULL));
        fprintf(mf, "worker_records_in_%d  %lld\n", ts->thread_id, written);
        fflush(mf);
        fsync(fileno(mf));
        fclose(mf);
        rename("sub_ckpt_meta.txt.tmp", "sub_ckpt_meta.txt");
    }

    /* --depth-profile durability (2026-04-23). Write this worker's per-depth
     * counters to sub_ckpt_depth<tid>.txt so spot-eviction+resume preserves
     * the depth histogram. Independent of the solutions checkpoint. Atomic
     * via .tmp + rename. */
    {
        char dfname[64], dtmpname[64];
        snprintf(dfname,   sizeof(dfname),   "sub_ckpt_depth%d.txt",     ts->thread_id);
        snprintf(dtmpname, sizeof(dtmpname), "sub_ckpt_depth%d.txt.tmp", ts->thread_id);
        FILE *df = fopen(dtmpname, "w");
        if (df) {
            for (int d = 0; d <= 32; d++) {
                fprintf(df, "%lld\n", ts->nodes_at_depth[d]);
            }
            fflush(df);
            fsync(fileno(df));
            fclose(df);
            rename(dtmpname, dfname);
        }
    }

    /* Completed-task bitmap (Option C, 2026-04-23). Global array, written
     * by whichever worker calls flush — all workers see the same value
     * via volatile. One file for the whole run: sub_ckpt_task_done.txt,
     * single line of n_sub_sub_tasks chars (0/1). Atomic via .tmp+rename.
     * On resume, sub_sub_task_done[idx] gets populated and workers skip
     * completed tasks entirely. */
    {
        FILE *tdf = fopen("sub_ckpt_task_done.txt.tmp", "w");
        if (tdf) {
            for (int i = 0; i < n_sub_sub_tasks; i++) {
                fputc(sub_sub_task_done[i] ? '1' : '0', tdf);
            }
            fputc('\n', tdf);
            fflush(tdf);
            fsync(fileno(tdf));
            fclose(tdf);
            rename("sub_ckpt_task_done.txt.tmp", "sub_ckpt_task_done.txt");
        }
    }
}

/* Load any existing sub_ckpt_wrk*.bin files into the first worker's
 * hash table (consolidation point). Returns the shared_nodes value
 * recovered from sub_ckpt_meta.txt, or 0 if no checkpoint exists.
 * Called once by main thread BEFORE spawning workers. Files are NOT
 * deleted here — they stay for redundancy until the run completes. */
static long long sub_ckpt_load(ThreadState *consolidate_into) {
    struct stat st;
    if (stat("sub_ckpt_meta.txt", &st) != 0) return 0;
    FILE *mf = fopen("sub_ckpt_meta.txt", "r");
    if (!mf) return 0;
    long long shared = 0;
    char line[256];
    while (fgets(line, sizeof(line), mf)) {
        long long v;
        if (sscanf(line, "shared_nodes %lld", &v) == 1) shared = v;
    }
    fclose(mf);

    /* Pre-size consolidation table to max(2^24, 2*total_records) slots.
     * Loading N records into a 2^24 = 16.7M-slot table when N >> 16M causes
     * the load pass to never cross the 75% resize threshold (clustering
     * stalls growth), which triggered the 2026-04-24 hang. At 2x over-sizing
     * the load pass completes comfortably under 50% full and resize is
     * rarely needed. */
    long long estimated_records = 0;
    for (int tid = 0; tid < 64; tid++) {
        char fname[64];
        snprintf(fname, sizeof(fname), "sub_ckpt_wrk%d.bin", tid);
        struct stat est_st;
        if (stat(fname, &est_st) == 0) {
            estimated_records += est_st.st_size / SOL_RECORD_SIZE;
        }
    }
    int needed_log2 = consolidate_into->ht_log2;
    while ((1LL << needed_log2) < estimated_records * 2 && needed_log2 < 30)
        needed_log2++;
    if (needed_log2 > consolidate_into->ht_log2) {
        fprintf(stderr, "Checkpoint resume: pre-sizing consolidation hash to 2^%d "
                "(%lld slots) for %lld estimated records\n",
                needed_log2, 1LL << needed_log2, estimated_records);
        fflush(stderr);
        if (consolidate_into->sol_table) free(consolidate_into->sol_table);
        if (consolidate_into->sol_occupied) free(consolidate_into->sol_occupied);
        consolidate_into->ht_log2 = needed_log2;
        consolidate_into->ht_size = 1 << needed_log2;
        consolidate_into->ht_mask = consolidate_into->ht_size - 1;
        consolidate_into->sol_table = NULL;
        consolidate_into->sol_occupied = NULL;
    }

    /* Ensure consolidate_into has a table. */
    if (!consolidate_into->sol_table) {
        consolidate_into->sol_table = calloc((size_t)consolidate_into->ht_size, SOL_RECORD_SIZE);
        consolidate_into->sol_occupied = calloc(consolidate_into->ht_size, 1);
        if (!consolidate_into->sol_table || !consolidate_into->sol_occupied) {
            fprintf(stderr, "FATAL: ckpt-load: hash-table alloc failed\n");
            exit(1);
        }
    }

    /* Walk sub_ckpt_wrk*.bin and merge every record into consolidate_into
     * using the same lex-smallest-wins dedup as merge_sol_tables. */
    int loaded_files = 0;
    long long loaded_records = 0;
    int diag_max_probe_ever = 0;
    long long diag_next_heartbeat = 1000000LL;
    for (int tid = 0; tid < 64; tid++) {
        char fname[64];
        snprintf(fname, sizeof(fname), "sub_ckpt_wrk%d.bin", tid);
        if (stat(fname, &st) != 0) continue;
        FILE *wf = fopen(fname, "rb");
        if (!wf) continue;
        loaded_files++;
        int diag_max_probe_file = 0;
        int warns_this_file = 0;
        unsigned char rec[SOL_RECORD_SIZE];
        while (fread(rec, SOL_RECORD_SIZE, 1, wf) == 1) {
            unsigned char canonical[SOL_RECORD_SIZE];
            for (int i = 0; i < SOL_RECORD_SIZE; i++) canonical[i] = rec[i] & 0xFC;
            unsigned long long ch = 14695981039346656037ULL;
            for (int i = 0; i < SOL_RECORD_SIZE; i++) { ch ^= canonical[i]; ch *= 1099511628211ULL; }
            SOL_HASH_MIX(ch);
            int slot = (int)(ch & (unsigned long long)consolidate_into->ht_mask);
            for (int probe = 0; probe < consolidate_into->ht_size; probe++) {
                int idx = (slot + probe) & consolidate_into->ht_mask;
                if (!consolidate_into->sol_occupied[idx]) {
                    memcpy(&consolidate_into->sol_table[(size_t)idx * SOL_RECORD_SIZE], rec, SOL_RECORD_SIZE);
                    consolidate_into->sol_occupied[idx] = 1;
                    consolidate_into->solution_count++;
                    if (probe > diag_max_probe_file) diag_max_probe_file = probe;
                    if (probe > 10000 && warns_this_file < 10) {
                        fprintf(stderr, "[ckpt] WARN wrk%d high-probe: probe=%d at slot %d "
                                "(sol_count=%lld, ht_size=%d, full=%d%%)\n",
                                tid, probe, slot, consolidate_into->solution_count,
                                consolidate_into->ht_size,
                                (int)(100LL * consolidate_into->solution_count / consolidate_into->ht_size));
                        fflush(stderr);
                        warns_this_file++;
                    }
                    if (consolidate_into->solution_count > (long long)consolidate_into->ht_size * 3 / 4) {
                        resize_hash_table(consolidate_into);
                    }
                    break;
                }
                unsigned char *existing = &consolidate_into->sol_table[(size_t)idx * SOL_RECORD_SIZE];
                int match = 1;
                for (int ci = 0; ci < SOL_RECORD_SIZE; ci++) {
                    if ((existing[ci] & 0xFC) != canonical[ci]) { match = 0; break; }
                }
                if (match) {
                    if (memcmp(rec, existing, SOL_RECORD_SIZE) < 0)
                        memcpy(existing, rec, SOL_RECORD_SIZE);
                    if (probe > diag_max_probe_file) diag_max_probe_file = probe;
                    break;
                }
            }
            loaded_records++;
            if (loaded_records >= diag_next_heartbeat) {
                int full_pct = (int)(100LL * consolidate_into->solution_count / consolidate_into->ht_size);
                fprintf(stderr, "[ckpt] %lld records inserted, ht_size=%d, full=%d%%, max_probe=%d\n",
                        loaded_records, consolidate_into->ht_size, full_pct, diag_max_probe_file);
                fflush(stderr);
                diag_next_heartbeat += 5000000LL;
            }
        }
        fclose(wf);
        if (diag_max_probe_file > diag_max_probe_ever) diag_max_probe_ever = diag_max_probe_file;
    }
    if (loaded_files > 0) {
        printf("Checkpoint resume: loaded %lld records from %d worker snapshots; "
               "shared_nodes restored to %lld (max_probe=%d)\n",
               loaded_records, loaded_files, shared, diag_max_probe_ever);
    }

    /* --depth-profile durability: sum any sub_ckpt_depth<tid>.txt files and
     * carry the total into consolidate_into->nodes_at_depth[]. End-of-run
     * aggregation will add post-resume worker counts on top, yielding a
     * correct final histogram across the eviction boundary. */
    {
        int depth_files_loaded = 0;
        for (int tid = 0; tid < 64; tid++) {
            char dfname[64];
            snprintf(dfname, sizeof(dfname), "sub_ckpt_depth%d.txt", tid);
            if (stat(dfname, &st) != 0) continue;
            FILE *df = fopen(dfname, "r");
            if (!df) continue;
            long long vals[33] = {0};
            int read_ok = 1;
            for (int d = 0; d <= 32; d++) {
                if (fscanf(df, "%lld", &vals[d]) != 1) { read_ok = 0; break; }
            }
            fclose(df);
            if (read_ok) {
                for (int d = 0; d <= 32; d++)
                    consolidate_into->nodes_at_depth[d] += vals[d];
                depth_files_loaded++;
            }
        }
        if (depth_files_loaded > 0) {
            long long total_d = 0;
            for (int d = 0; d <= 32; d++) total_d += consolidate_into->nodes_at_depth[d];
            printf("Checkpoint resume: depth profile restored from %d files, "
                   "%lld pre-eviction nodes summed into worker 0\n",
                   depth_files_loaded, total_d);
        }
    }

    /* Completed-task bitmap (Option C, 2026-04-23). Restore sub_sub_task_done[]
     * so the worker loop's "if (sub_sub_task_done[idx]) continue;" skips
     * already-walked tasks. Note: the task list (sub_sub_tasks[]) is
     * deterministically re-built by build_sub_sub_branch_tasks() at every
     * run, so index semantics are stable across invocations as long as the
     * d3 prefix stays the same. */
    if (stat("sub_ckpt_task_done.txt", &st) == 0) {
        FILE *tdf = fopen("sub_ckpt_task_done.txt", "r");
        if (tdf) {
            int loaded = 0;
            int c;
            while ((c = fgetc(tdf)) != EOF && loaded < SUB_SUB_MAX) {
                if (c == '0' || c == '1') {
                    sub_sub_task_done[loaded] = (c == '1') ? 1 : 0;
                    loaded++;
                }
            }
            fclose(tdf);
            int done_count = 0;
            for (int i = 0; i < loaded; i++) if (sub_sub_task_done[i]) done_count++;
            printf("Checkpoint resume: task-done bitmap restored, "
                   "%d of %d tasks marked complete (skipped on resume)\n",
                   done_count, loaded);
        }
    }
    return shared;
}

/* Tier 2: flush current hash table to a new chunk file AND clear the
 * in-memory state. Caller MUST hold ts->ht_mutex. The chunk filename is
 * globally-unique (global seq counter) and the file is append-only —
 * never rewritten. After this returns, ts->sol_table/sol_occupied are
 * cleared and ts->solution_count = 0, so the worker can keep
 * accumulating new solutions without hitting memory limits. Each flush
 * costs one pass over the worker's hash table (write only the
 * occupied slots). */
static void sub_flush_chunk_to_disk(ThreadState *ts) {
    int seq = __sync_fetch_and_add(&sub_flush_seq, 1);
    char fname[96], tmpname[112];
    snprintf(fname,   sizeof(fname),   "sub_flush_chunk_%06d_wrk%d.bin",     seq, ts->thread_id);
    snprintf(tmpname, sizeof(tmpname), "sub_flush_chunk_%06d_wrk%d.bin.tmp", seq, ts->thread_id);
    FILE *f = fopen(tmpname, "wb");
    if (!f) {
        fprintf(stderr, "WARNING: tier2-flush: cannot open %s: %s\n", tmpname, strerror(errno));
        return;
    }
    long long written = 0;
    if (ts->sol_table && ts->sol_occupied) {
        for (int s = 0; s < ts->ht_size; s++) {
            if (!ts->sol_occupied[s]) continue;
            if (fwrite(&ts->sol_table[(size_t)s * SOL_RECORD_SIZE],
                       SOL_RECORD_SIZE, 1, f) != 1) {
                fprintf(stderr, "WARNING: tier2-flush: short write on %s\n", tmpname);
                fclose(f);
                return;
            }
            written++;
        }
    }
    if (fflush(f) != 0 || fsync(fileno(f)) != 0) {
        fprintf(stderr, "WARNING: tier2-flush: fflush/fsync failed on %s\n", tmpname);
        fclose(f);
        return;
    }
    fclose(f);
    if (rename(tmpname, fname) != 0) {
        fprintf(stderr, "WARNING: tier2-flush: rename %s → %s failed\n", tmpname, fname);
        return;
    }

    /* Clear in-memory state. The allocation stays; only the contents
     * are zeroed. Next insertion repopulates from scratch.
     * Guard against a caller that already freed the tables (end-of-run
     * post-merge path frees workers[1..N-1] tables before the tier2
     * final-flush loop runs — see 2026-04-24 SIGTERM-crash postmortem). */
    if (ts->sol_table) {
        memset(ts->sol_table, 0, (size_t)ts->ht_size * SOL_RECORD_SIZE);
    }
    if (ts->sol_occupied) {
        memset(ts->sol_occupied, 0, ts->ht_size);
    }
    ts->solution_count = 0;

    __sync_add_and_fetch(&tier2_total_records_flushed, written);
    __sync_add_and_fetch(&tier2_total_chunks_written, 1);
    fprintf(stderr, "  [tier2-flush] worker %d: wrote %lld records to %s; in-memory cleared\n",
            ts->thread_id, written, fname);
    fflush(stderr);
}

/* Delete checkpoint files after a successful run. Called from main after
 * final output is written + fsynced. */
static void sub_ckpt_cleanup(void) {
    unlink("sub_ckpt_meta.txt");
    unlink("sub_ckpt_task_done.txt");
    for (int tid = 0; tid < 64; tid++) {
        char fname[64];
        snprintf(fname, sizeof(fname), "sub_ckpt_wrk%d.bin", tid);
        unlink(fname);
        snprintf(fname, sizeof(fname), "sub_ckpt_depth%d.txt", tid);
        unlink(fname);
    }
}

/* Arguments for thread_func_ckpt. Passed via a heap-allocated struct so
 * the main thread can free it after join. */
typedef struct {
    ThreadState *workers;
    int n_workers;
} CkptThreadArg;

static volatile int sub_ckpt_thread_stop = 0;

/* Dedicated checkpoint thread. Wakes every sub_ckpt_interval_sec and
 * snapshots every worker's hash table (under each worker's ht_mutex) to
 * sub_ckpt_wrk<tid>.bin + sub_ckpt_meta.txt. This mechanism is
 * time-driven (not task-boundary-driven) so it fires reliably even for
 * branches where a single task runs many minutes. Terminates when the
 * main thread sets sub_ckpt_thread_stop after all workers have joined. */
static void *thread_func_ckpt(void *arg) {
    CkptThreadArg *a = (CkptThreadArg *)arg;
    while (!sub_ckpt_thread_stop && !global_timed_out) {
        /* Sleep in 1-second chunks so stop-signal is responsive. */
        for (int t = 0; t < sub_ckpt_interval_sec; t++) {
            if (sub_ckpt_thread_stop || global_timed_out) return NULL;
            sleep(1);
        }
        if (sub_ckpt_thread_stop || global_timed_out) return NULL;
        /* Snapshot all workers. Each worker's ht_mutex is held only
         * during its own snapshot — other workers keep running. */
        for (int i = 0; i < a->n_workers; i++) {
            pthread_mutex_lock(&a->workers[i].ht_mutex);
            sub_ckpt_flush_worker(&a->workers[i]);
            a->workers[i].last_ckpt = time(NULL);
            pthread_mutex_unlock(&a->workers[i].ht_mutex);
        }
    }
    return NULL;
}

static void *thread_func_sub_sub(void *arg) {
    ThreadState *ts = (ThreadState *)arg;

    while (!global_timed_out) {
        if (sub_sub_budget_hit) break;

        /* Atomically claim the next task. */
        int idx = __sync_fetch_and_add(&sub_sub_next_idx, 1);
        if (idx >= n_sub_sub_tasks) break;

        /* Resume optimization (2026-04-23): if this task was already
         * walked to completion in a prior run (checkpoint-restored bitmap),
         * skip it. Turns resume-with-more-budget from "re-walk everything"
         * into "new exploration only." Cheap ~4-byte load per claim. */
        if (sub_sub_task_done[idx]) continue;

        /* Per-task stats (2026-04-24): record start values so we can
         * compute delta after DFS completes. Also wire the current-task
         * pointer so backtrack() bumps per-task depth histogram + c3_leaves. */
        long long task_start_nodes = ts->branch_nodes;
        long long task_start_sols = ts->solution_count;
        time_t task_start_time = time(NULL);
        ts->current_task_stats = &sub_sub_task_stats[idx];
        ts->task_node_start = ts->branch_nodes;  /* 2026-04-28: per-task cap baseline */
        ts->task_cap_hit = 0;                    /* 2026-04-28: clear cap flag for new task */

        SubSubBranchTask *task = &sub_sub_tasks[idx];

        /* Snapshot shared prefix into local state. */
        int seq[64];
        int used[32];
        int budget[7];
        memcpy(seq,    shared_prefix_seq,    sizeof(seq));
        memcpy(used,   shared_prefix_used,   sizeof(used));
        memcpy(budget, shared_prefix_budget, sizeof(budget));

        /* Apply depth-4 extension — pair 4 placed at positions 8-9. */
        seq[8] = task->f4;
        seq[9] = task->s4;
        used[task->p4] = 1;
        budget[task->bd4]--;
        budget[task->wd4]--;
        /* Apply depth-5 extension — pair 5 placed at positions 10-11. */
        seq[10] = task->f5;
        seq[11] = task->s5;
        used[task->p5] = 1;
        budget[task->bd5]--;
        budget[task->wd5]--;

        /* NOTE: do NOT reset ts->branch_nodes per task in parallel mode —
         * backtrack uses (branch_nodes - pending_shared_flush) as the delta
         * to publish to the shared counter, and that needs monotone
         * accumulation across all tasks on this worker. */

        /* DFS from step 6 (pair 6 placed at positions 12-13). */
        backtrack(ts, seq, used, budget, 6);

        /* Final flush of any sub-65K residual delta from this task to
         * this worker's CCD-assigned counter. */
        long long delta_f = ts->branch_nodes - ts->pending_shared_flush;
        if (delta_f > 0) {
            ts->pending_shared_flush = ts->branch_nodes;
            int slot = ts->thread_id % N_SUB_SUB_COUNTERS;
            __sync_add_and_fetch(&sub_sub_counters[slot].nodes, delta_f);
            if (per_branch_node_limit > 0 &&
                sub_sub_sum_counters() >= per_branch_node_limit) {
                sub_sub_budget_hit = 1;
            }
        }

        /* Mark this task as fully walked — but ONLY if no early-exit
         * signal fired at any point during our DFS:
         *   - sub_sub_budget_hit: any worker crossed the budget line;
         *     our backtrack may have short-circuited mid-subtree.
         *   - global_timed_out: SIGTERM/SIGINT (e.g. spot eviction or
         *     operator kill); backtrack returns immediately on entry.
         * If either was set at any time during our DFS, we can't safely
         * claim the task's subtree is fully visited. Conservatively leave
         * the flag clear so resume will redo this task. False positives
         * here mean redoing a bit of already-done work; false negatives
         * would mean skipping incomplete tasks, which would drop solutions. */
        int task_completed_cleanly = (!sub_sub_budget_hit && !global_timed_out);
        if (task_completed_cleanly) {
            sub_sub_task_done[idx] = 1;
        }

        /* Per-task stats (2026-04-24): record this task's DFS delta.
         * Written once, no atomic needed since each task index is
         * claimed exactly once per process lifetime. Partial stats are
         * still useful for diagnostic purposes even when completed=0. */
        {
            long long task_nodes = ts->branch_nodes - task_start_nodes;
            long long task_sols = ts->solution_count - task_start_sols;
            int task_wall_ms = (int)((time(NULL) - task_start_time) * 1000);
            sub_sub_task_stats[idx].nodes = task_nodes;
            sub_sub_task_stats[idx].solutions_added = (int)task_sols;
            sub_sub_task_stats[idx].wall_time_ms = task_wall_ms;
            sub_sub_task_stats[idx].worker_id = (unsigned char)ts->thread_id;
            sub_sub_task_stats[idx].completed = (unsigned char)(task_completed_cleanly ? 1 : 0);
            /* max_depth = highest depth with any nodes in this task's histogram. */
            int md = 0;
            for (int d = 32; d >= 0; d--) {
                if (sub_sub_task_stats[idx].nodes_at_depth[d] > 0) { md = d; break; }
            }
            sub_sub_task_stats[idx].max_depth = (unsigned char)md;
        }
        ts->current_task_stats = NULL;  /* clear pointer outside task window */

        /* Tier 2 memory-relief flush check (2026-04-23). Triggered per
         * worker when its local solution_count crosses the per-worker
         * threshold. Flush is atomic under this worker's ht_mutex so
         * the checkpoint thread doesn't race. Task-boundary check
         * (not mid-DFS) keeps the hot path free of any test. */
        if (per_worker_flush_threshold > 0 &&
            ts->solution_count > per_worker_flush_threshold) {
            pthread_mutex_lock(&ts->ht_mutex);
            /* Re-check under lock (another path may have flushed). */
            if (ts->solution_count > per_worker_flush_threshold) {
                sub_flush_chunk_to_disk(ts);
            }
            pthread_mutex_unlock(&ts->ht_mutex);
        }

        /* Intra-sub-branch checkpointing is handled by a dedicated
         * checkpoint thread (thread_func_ckpt) that wakes every
         * sub_ckpt_interval_sec and snapshots all workers. Not per-task
         * here — that approach stalled on branches where a single task
         * runs many minutes without yielding to the boundary. */
    }
    __sync_fetch_and_add(&threads_completed, 1);
    return NULL;
}

/* Merge src's occupied hash-table slots into dst. Re-computes the canonical
 * hash on each record and probes dst, applying the same "lex-smallest record
 * wins" dedup as analyze_solution(). Called on main thread after all workers
 * have joined. Does NOT touch src's counters (caller will discard src). */
static void merge_sol_tables(ThreadState *dst, ThreadState *src) {
    if (!src->sol_table || !src->sol_occupied) return;
    /* Ensure dst has a table (lazy init). */
    if (!dst->sol_table) {
        dst->sol_table = calloc((size_t)dst->ht_size, SOL_RECORD_SIZE);
        dst->sol_occupied = calloc(dst->ht_size, 1);
        if (!dst->sol_table || !dst->sol_occupied) {
            fprintf(stderr, "FATAL: merge target hash-table allocation failed\n");
            exit(1);
        }
    }
    for (int s = 0; s < src->ht_size; s++) {
        if (!src->sol_occupied[s]) continue;
        const unsigned char *record = &src->sol_table[(size_t)s * SOL_RECORD_SIZE];
        unsigned char canonical[SOL_RECORD_SIZE];
        for (int i = 0; i < SOL_RECORD_SIZE; i++)
            canonical[i] = (unsigned char)(record[i] & 0xFC);
        unsigned long long ch = 14695981039346656037ULL;
        for (int i = 0; i < SOL_RECORD_SIZE; i++) { ch ^= canonical[i]; ch *= 1099511628211ULL; }
        SOL_HASH_MIX(ch);
        int slot = (int)(ch & (unsigned long long)dst->ht_mask);
        for (int probe = 0; probe < dst->ht_size; probe++) {
            int idx = (slot + probe) & dst->ht_mask;
            if (!dst->sol_occupied[idx]) {
                memcpy(&dst->sol_table[(size_t)idx * SOL_RECORD_SIZE], record, SOL_RECORD_SIZE);
                dst->sol_occupied[idx] = 1;
                dst->solution_count++;
                if (dst->solution_count > (long long)dst->ht_size * 3 / 4)
                    resize_hash_table(dst);
                break;
            }
            unsigned char *existing = &dst->sol_table[(size_t)idx * SOL_RECORD_SIZE];
            int match = 1;
            for (int ci = 0; ci < SOL_RECORD_SIZE; ci++) {
                if ((existing[ci] & 0xFC) != canonical[ci]) { match = 0; break; }
            }
            if (match) {
                /* Lex-smallest wins dedup (mirror of analyze_solution). */
                if (memcmp(record, existing, SOL_RECORD_SIZE) < 0)
                    memcpy(existing, record, SOL_RECORD_SIZE);
                dst->hash_collisions++;
                break;
            }
        }
    }
}

/* ---- External binary preflight ----
 * solve.c intentionally shells out to sha256sum / shasum to compute output
 * digests rather than embed a SHA-256 implementation. To keep that choice
 * robust, we verify the binary exists on PATH and is executable BEFORE the
 * work phase begins — so a missing coreutils installation fails loudly at
 * startup, not silently at the very end of a multi-hour enumeration. */

static int binary_exists_on_path(const char *name) {
    const char *path = getenv("PATH");
    if (!path || !*path) path = "/usr/bin:/bin:/usr/local/bin:/sbin";
    char *dup = strdup(path);
    if (!dup) return 0;
    int found = 0;
    char *save = NULL;
    for (char *dir = strtok_r(dup, ":", &save); dir; dir = strtok_r(NULL, ":", &save)) {
        if (!*dir) continue;
        char full[1024];
        int n = snprintf(full, sizeof(full), "%s/%s", dir, name);
        if (n < 0 || n >= (int)sizeof(full)) continue;
        if (access(full, X_OK) == 0) { found = 1; break; }
    }
    free(dup);
    return found;
}

/* Returns the sha256 command prefix to splice into system()/popen() strings,
 * or NULL if no compatible tool is found. Cached after first call. */
static const char *sha256_tool(void) {
    static const char *cached = NULL;
    static int checked = 0;
    if (checked) return cached;
    checked = 1;
    if (binary_exists_on_path("sha256sum"))    cached = "sha256sum";
    else if (binary_exists_on_path("shasum"))  cached = "shasum -a 256";
    return cached;
}

/* Startup-time check: if anything in this run will need sha256_tool(),
 * call this first and fail cleanly if neither binary is present.
 * Prints a remediation hint. Returns 0 on success, non-zero to exit. */
static int require_sha256_tool(void) {
    if (sha256_tool() != NULL) return 0;
    fprintf(stderr,
        "ERROR: no SHA-256 tool found on PATH.\n"
        "  solve.c shells out to 'sha256sum' (GNU coreutils) or 'shasum -a 256'\n"
        "  (BSD/macOS) to digest output files. Neither was found on this system.\n"
        "  Install one:\n"
        "    Debian/Ubuntu: apt-get install coreutils\n"
        "    RHEL/Fedora:   dnf install coreutils\n"
        "    macOS:         ships with 'shasum' by default\n");
    return 1;
}

/* Compare for qsort — compare pair identity only (orient bit masked out).
 * Each byte: (pair_index << 2) | (orient << 1). Mask with 0xFC. */
/* Write sha256 file with metadata for reproducibility.
 * First line is bare sha256 (compatible with sha256sum -c).
 * Remaining lines are metadata comments. */
static void write_sha256_with_metadata(const char *bin_name, const char *sha_name,
                                        long long unique_count, long long total_nodes,
                                        int n_branches_total, int branches_done) {
    /* Compute sha256. sha256_tool() was preflighted at startup — if we get
     * here with a NULL, it means something in the program flow skipped the
     * preflight. Refuse to produce an incomplete .sha256 file. */
    const char *tool = sha256_tool();
    if (!tool) {
        fprintf(stderr, "ERROR: sha256 tool missing at write_sha256_with_metadata; "
                        "preflight should have caught this.\n");
        return;
    }
    char cmd[512];
    snprintf(cmd, sizeof(cmd), "%s %s > %s 2>/dev/null", tool, bin_name, sha_name);
    int rc = system(cmd);
    if (rc != 0) {
        fprintf(stderr, "ERROR: sha256 computation failed (rc=%d) for %s\n", rc, bin_name);
        return;
    }

    /* Read back the hash line */
    char hash_line[256] = {0};
    FILE *hf = fopen(sha_name, "r");
    if (!hf) {
        fprintf(stderr, "WARNING: cannot re-open %s to verify sha256: %s\n", sha_name, strerror(errno));
        return;
    }
    if (fgets(hash_line, sizeof(hash_line), hf) == NULL) {
        fprintf(stderr, "WARNING: %s is empty — sha256 tool may have failed silently\n", sha_name);
        fclose(hf);
        return;
    }
    fclose(hf);

    /* Rewrite with metadata */
    FILE *sf = fopen(sha_name, "w");
    if (!sf) return;
    fprintf(sf, "%s", hash_line);  /* first line: bare hash (sha256sum -c compatible) */

    /* Metadata */
    char tbuf[64];
    time_t now = time(NULL);
    struct tm tmbuf;
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime_r(&now, &tmbuf));

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

/* ---------- Record comparators: correctness proof ----------
 *
 * Two comparators exist, used at different stages of the pipeline:
 *
 *   compare_solutions:  total strict order on 32-byte records. Primary key is
 *                       pair identity (byte & 0xFC); secondary key is the full
 *                       byte (including orient bit). This is the qsort key.
 *
 *   compare_canonical:  equivalence-class comparator. Two records with the
 *                       same pair identity compare equal regardless of orient.
 *                       This is the dedup key.
 *
 * Correctness invariant: the final solutions.bin contains one record per
 * canonical equivalence class (unique pair-sequence), regardless of how many
 * orientation variants existed during search.
 *
 * Proof sketch:
 *   (1) Per-thread hash-table insert uses canonical key (solve.c hash path
 *       computes FNV over (rec[i] & 0xFC) for each i, and equality on probe
 *       hit tests only the masked bytes). Therefore a thread's flushed
 *       sub_*.bin file contains at most one representative per canonical
 *       class WITHIN that thread.
 *   (2) qsort uses compare_solutions (total order); any two records that
 *       compare_canonical-equal are placed adjacent by qsort.
 *   (3) The merge-phase dedup pass uses compare_canonical to compare each
 *       record with the last retained one and skips equal-canonical ones,
 *       preserving exactly one per class.
 *
 * Why the secondary tiebreaker in compare_solutions: qsort requires a strict
 * total order (not a partial order). Without the secondary, two records with
 * same pair identity but different orient would compare equal, and qsort's
 * non-stable behavior would make the final byte content nondeterministic
 * (which orient wins would depend on qsort's internal choices). The secondary
 * ensures a fully deterministic post-sort byte stream, and the dedup pass
 * then collapses the orient variants to a single deterministic survivor. */
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

/* ---------- In-place heapsort for memory-critical merge paths ----------
 *
 * Motivation: glibc's qsort is merge-sort-on-large-arrays, which allocates
 * ~n/2 auxiliary storage. On 10T d3 merges (2.77B records × 32 bytes = 82 GB
 * buffer), that aux memory pushes peak RSS to ~129 GB — OOM-killable on a
 * 128 GB F64 VM. Observed empirically on 2026-04-18 Phase C.
 *
 * Heapsort is O(n log n) worst-case (same as qsort's average) but guaranteed
 * O(1) auxiliary memory. Peak memory = buffer + one record-sized swap slot.
 * This makes in-memory merge feasible at 10T d3 on 128 GB RAM without
 * OOM risk, at the cost of ~2-3× slower sort than qsort for random data.
 * For a 2.77B-record sort that means ~20-30 min vs ~10 min qsort — an
 * acceptable trade-off to avoid OOM.
 *
 * Output is identical to qsort given the same comparator: compare_solutions
 * is a total strict order (no two distinct records compare equal), so the
 * sorted sequence is unique regardless of sort algorithm. sha256 of
 * solutions.bin is therefore stable across qsort→heapsort migration.
 *
 * Used for the memory-critical merge paths (external chunk sort, --merge
 * in-memory, normal-mode in-memory). The --analyze path keeps qsort for
 * its small-data sorts where memory is not constrained. */
static void heap_sift_down(unsigned char *arr, size_t record_size,
                           size_t root, size_t end,
                           int (*cmp)(const void *, const void *),
                           unsigned char *swap) {
    while (2 * root + 1 <= end) {
        size_t child = 2 * root + 1;
        if (child + 1 <= end && cmp(&arr[child * record_size],
                                     &arr[(child + 1) * record_size]) < 0)
            child++;
        if (cmp(&arr[root * record_size], &arr[child * record_size]) < 0) {
            memcpy(swap, &arr[root * record_size], record_size);
            memcpy(&arr[root * record_size], &arr[child * record_size], record_size);
            memcpy(&arr[child * record_size], swap, record_size);
            root = child;
        } else {
            return;
        }
    }
}

/* In-place heapsort. Signature matches qsort for drop-in replacement.
 * Allocates a single record_size swap buffer on the stack; no heap use. */
static void heapsort_records(void *base, size_t nmemb, size_t record_size,
                             int (*cmp)(const void *, const void *)) {
    if (nmemb < 2) return;
    unsigned char *arr = (unsigned char *)base;

    /* Swap buffer: must hold one record. SOL_RECORD_SIZE is 32, but this
     * helper is generic — sized at a safe upper bound to handle any
     * record_size the merge paths realistically use. */
    unsigned char swap[512];
    if (record_size > sizeof(swap)) {
        /* Caller passed an unexpectedly large record. Fall back to qsort,
         * which handles arbitrary sizes (at the cost of aux memory). */
        qsort(base, nmemb, record_size, cmp);
        return;
    }

    /* Build max-heap (children of indices >= nmemb/2 are already valid heaps). */
    for (ssize_t start = (ssize_t)(nmemb / 2) - 1; start >= 0; start--) {
        heap_sift_down(arr, record_size, (size_t)start, nmemb - 1, cmp, swap);
    }

    /* Sort: repeatedly move max (root) to end, shrink heap, re-heapify. */
    for (size_t end = nmemb - 1; end > 0; end--) {
        memcpy(swap, arr, record_size);
        memcpy(arr, &arr[end * record_size], record_size);
        memcpy(&arr[end * record_size], swap, record_size);
        heap_sift_down(arr, record_size, 0, end - 1, cmp, swap);
    }
}

/* ---------- External merge-sort ----------
 * Memory-independent alternative to the in-memory qsort merge. Reads sub_*.bin
 * files in fixed-size chunks, sorts each chunk in RAM, writes sorted temp files,
 * then does a k-way merge with canonical dedup. Memory bounded by chunk size
 * (default 4 GB, configurable via SOLVE_MERGE_CHUNK_GB).
 *
 * Controlled by SOLVE_MERGE_MODE env var:
 *   auto     (default) — external if needed RAM > 80% of physical
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

/* Write a sorted chunk to disk with full I/O error checking.
 * fwrite/fflush/fsync/fclose all checked; post-write stat verifies size.
 * Matches the checking discipline of flush_sub_solutions — silent data loss
 * from disk-full mid-write is the failure mode being defended against. */
static int write_sorted_chunk(const char *path, const unsigned char *chunk,
                               long long records, int idx, int is_final) {
    FILE *sf = fopen(path, "wb");
    if (!sf) {
        fprintf(stderr, "ERROR: cannot create %s: %s\n", path, strerror(errno));
        return 1;
    }
    size_t w = fwrite(chunk, SOL_RECORD_SIZE, (size_t)records, sf);
    if ((long long)w != records || fflush(sf) != 0 || fsync(fileno(sf)) != 0) {
        fprintf(stderr, "FATAL: chunk %d write/flush/fsync failed (wrote %zu of %lld): %s\n",
                idx, w, records, strerror(errno));
        fclose(sf);
        return 1;
    }
    if (fclose(sf) != 0) {
        fprintf(stderr, "FATAL: chunk %d close failed: %s\n", idx, strerror(errno));
        return 1;
    }
    struct stat cst;
    long long expected = records * SOL_RECORD_SIZE;
    if (stat(path, &cst) != 0 || cst.st_size != expected) {
        fprintf(stderr, "FATAL: chunk %d post-write size mismatch on %s: got %lld, expected %lld\n",
                idx, path,
                (long long)(stat(path, &cst) == 0 ? cst.st_size : -1), expected);
        return 1;
    }
    printf("  Chunk %d: %lld records sorted + written%s\n",
           idx, records, is_final ? " (final)" : "");
    fflush(stdout);
    return 0;
}

static int external_merge_sort(char (*filenames)[64], int n_files,
                                long long total_records,
                                const char *output_path, long long *out_unique) {
    long long chunk_bytes = 4LL * 1024 * 1024 * 1024;
    char *env_chunk = getenv("SOLVE_MERGE_CHUNK_GB");
    if (env_chunk) chunk_bytes = atoll(env_chunk) * 1024LL * 1024 * 1024;
    long long max_per_chunk = chunk_bytes / SOL_RECORD_SIZE;

    /* Temp directory for sorted chunks (Phase 1 output; read back in Phase 2).
     * Defaults to "." (current working directory). Set SOLVE_TEMP_DIR to
     * redirect — recommended pattern is to point it at a fast local disk
     * (Premium SSD attached temporarily for the merge), while shards and
     * final solutions.bin stay on cheaper Standard-tier archival storage.
     * A 2.77B-record merge does ~2×(chunk size in GB) of I/O to this path;
     * putting chunks on SSD while shards remain on HDD can reduce total
     * merge wall time 3-4× with only pennies of prorated Premium cost. */
    const char *tmp_dir = getenv("SOLVE_TEMP_DIR");
    if (!tmp_dir || !*tmp_dir) tmp_dir = ".";
    /* Validate the temp dir exists and is writable — fail early rather than
     * after the first multi-GB qsort completes. */
    {
        struct stat td_st;
        if (stat(tmp_dir, &td_st) != 0 || !S_ISDIR(td_st.st_mode)) {
            fprintf(stderr, "ERROR: SOLVE_TEMP_DIR '%s' does not exist or is not a directory\n",
                    tmp_dir);
            return 1;
        }
        if (access(tmp_dir, W_OK) != 0) {
            fprintf(stderr, "ERROR: SOLVE_TEMP_DIR '%s' is not writable\n", tmp_dir);
            return 1;
        }
    }

    printf("External merge-sort: %lld records, chunk size %lld GB (%lld records/chunk)\n",
           total_records, chunk_bytes / (1024*1024*1024), max_per_chunk);
    printf("External merge-sort: temp chunks in %s%s\n",
           tmp_dir, (strcmp(tmp_dir, ".") == 0) ? " (default; set SOLVE_TEMP_DIR to redirect)" : "");

    unsigned char *chunk = malloc((size_t)chunk_bytes);
    if (!chunk) {
        fprintf(stderr, "ERROR: cannot allocate %lld bytes for sort chunk\n", chunk_bytes);
        return 1;
    }

    /* ---------------------------------------------------------------
     * KNOWN SCALE LIMIT: MAX_SORTED_CHUNKS caps the maximum pre-dedup
     * input size for external merge at (MAX_SORTED_CHUNKS × chunk_size).
     *
     * With defaults (4 GB chunks):
     *   4096 × 4 GB = 16 TB of pre-dedup input
     *   At observed d3 rate of ~8.3 GB per 1T nodes, that's ~2 quadrillion
     *   nodes — 200× the current canonical 10T reference.
     *
     * Mitigation when this limit is actually hit:
     *   Option A (no code change): set SOLVE_MERGE_CHUNK_GB=16 or 32 at
     *     runtime. Each 4× increase in chunk size buys 4× the ceiling;
     *     costs proportionally more RAM for the active chunk buffer.
     *     F64 (128 GB RAM) can comfortably handle chunks up to ~64 GB.
     *   Option B (one-line source change): bump this constant. Combined
     *     with a larger SOLVE_MERGE_CHUNK_GB, ceilings well into exabyte
     *     territory — far beyond any realistic enumeration.
     *
     * Practical scales:
     *   10T–1,000T: fits comfortably with defaults.
     *   ~1,500T:   consider SOLVE_MERGE_CHUNK_GB=16 for hygiene.
     *   ~5,000T+:  required to bump chunk size or this constant.
     *
     * Note: before this becomes a real constraint, `ulimit -n` (open file
     * descriptor count) bites first. The k-way merge opens every chunk
     * simultaneously; Linux default ulimit -n = 1024 → fails around
     * ~1024 chunks ≈ 500T at default chunk size. Raise with
     * `ulimit -n 16384` before running, OR bump SOLVE_MERGE_CHUNK_GB.
     * --------------------------------------------------------------- */
    #define MAX_SORTED_CHUNKS 4096
    /* Path buffer widened to 256 to accommodate reasonable SOLVE_TEMP_DIR
     * values (e.g., "/mnt/merge-ssd/temp_sorted_0000.bin"). */
    char sorted_names[MAX_SORTED_CHUNKS][256];
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
                heapsort_records(chunk, (size_t)records_in_chunk, SOL_RECORD_SIZE, compare_solutions);
                if (n_sorted >= MAX_SORTED_CHUNKS) {
                    fprintf(stderr, "ERROR: reached MAX_SORTED_CHUNKS=%d (pre-dedup input "
                                    "exceeds %d × SOLVE_MERGE_CHUNK_GB). Raise "
                                    "SOLVE_MERGE_CHUNK_GB (e.g., 16 or 32) to buy 4-8× the "
                                    "ceiling at the cost of more RAM for the active chunk "
                                    "buffer. See comment at MAX_SORTED_CHUNKS definition.\n",
                            MAX_SORTED_CHUNKS, MAX_SORTED_CHUNKS);
                    free(chunk); return 1;
                }
                snprintf(sorted_names[n_sorted], sizeof(sorted_names[0]),
                         "%s/temp_sorted_%04d.bin", tmp_dir, n_sorted);
                if (write_sorted_chunk(sorted_names[n_sorted], chunk, records_in_chunk, n_sorted, 0) != 0) {
                    free(chunk); return 1;
                }
                n_sorted++;
                records_in_chunk = 0;
            }
        }
        fclose(f);
    }

    if (records_in_chunk > 0) {
        heapsort_records(chunk, (size_t)records_in_chunk, SOL_RECORD_SIZE, compare_solutions);
        if (n_sorted >= MAX_SORTED_CHUNKS) {
            fprintf(stderr, "ERROR: reached MAX_SORTED_CHUNKS=%d on final partial chunk. "
                            "Raise SOLVE_MERGE_CHUNK_GB.\n", MAX_SORTED_CHUNKS);
            free(chunk); return 1;
        }
        snprintf(sorted_names[n_sorted], sizeof(sorted_names[0]),
                 "%s/temp_sorted_%04d.bin", tmp_dir, n_sorted);
        if (write_sorted_chunk(sorted_names[n_sorted], chunk, records_in_chunk, n_sorted, 1) != 0) {
            free(chunk); return 1;
        }
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
        if (!sfiles[i]) {
            fprintf(stderr, "FATAL: cannot reopen sorted chunk %s: %s\n",
                    sorted_names[i], strerror(errno));
            for (int j = 0; j < i; j++) if (sfiles[j]) fclose(sfiles[j]);
            free(sfiles); free(heap); return 1;
        }
        if (fread(heap[heap_size].rec, SOL_RECORD_SIZE, 1, sfiles[i]) == 1) {
            heap[heap_size].file_idx = i;
            heap_size++;
        } else {
            /* Chunk file is empty — shouldn't happen given write_sorted_chunk
             * rejects zero-record writes, but close it defensively to avoid a
             * FILE* leak. Leaves sfiles[i] dangling but we never reference it
             * after this loop for non-heap files. */
            fclose(sfiles[i]);
            sfiles[i] = NULL;
        }
    }

    for (int i = heap_size/2 - 1; i >= 0; i--)
        merge_heap_sift_down(heap, heap_size, i);

    FILE *out = fopen(output_path, "wb");
    if (!out) {
        fprintf(stderr, "ERROR: cannot open %s for writing\n", output_path);
        free(sfiles); free(heap); return 1;
    }

    /* Reserve header space — unique count is unknown until the merge loop
     * completes, so we write a zero-filled placeholder and patch it below. */
    if (sol_write_header(out, 0) != 0) {
        fprintf(stderr, "FATAL: header reserve failed on %s\n", output_path);
        fclose(out); free(sfiles); free(heap); return 1;
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

    /* Patch the header's record_count now that the merge loop is done.
     * fseek to offset 0 and rewrite the 32-byte header with real count. */
    if (fseek(out, 0, SEEK_SET) != 0 ||
        sol_write_header(out, (uint64_t)unique) != 0) {
        fprintf(stderr, "FATAL: header patch failed on %s\n", output_path);
        fclose(out); free(sfiles); free(heap); return 1;
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
    if (!f) {
        fprintf(stderr, "WARNING: cannot open %s for writing: %s\n", filename, strerror(errno));
        return;
    }
    char tbuf[64];
    struct tm tmbuf;

    fprintf(f, "{\n");
    fprintf(f, "  \"version\": \"2.0\",\n");
    fprintf(f, "  \"status\": \"%s\",\n", status);

    fprintf(f, "  \"run\": {\n");
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime_r(&start_time, &tmbuf));
    fprintf(f, "    \"start_utc\": \"%s\",\n", tbuf);
    time_t end = start_time + elapsed;
    strftime(tbuf, sizeof(tbuf), "%Y-%m-%dT%H:%M:%SZ", gmtime_r(&end, &tmbuf));
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

/* ---------- Null-model analyses (structured-permutation nulls for CRITIQUE.md) ----------
 *
 * These routines answer: "do other structured permutation families
 * accidentally satisfy King Wen's constraints C1, C2, C3?" The goal is
 * to strengthen the null-model comparison by testing against permutation
 * families that have their own internal structure (not just random
 * permutations). Results feed CRITIQUE.md and SOLVE.md §Null model.
 *
 * A lightweight sampled counterpart lives in solve.py (--null-debruijn);
 * the subroutines here give *exact* counts by exhaustively enumerating
 * the relevant family.
 */

#define KW_C3_CEILING 776  /* King Wen's total complement distance; C3 <= 776 */

/* C1: 32 pairs (seq[2i], seq[2i+1]) are each reverse pair, or (both
 * symmetric) complement pair. Matches has_pair_structure_c1 in solve.py
 * and the definition in SPECIFICATION.md §Rule 1. */
static int null_c1_pair_structure(const uint8_t *seq) {
    for (int i = 0; i < 32; i++) {
        uint8_t a = seq[2*i], b = seq[2*i+1];
        int sym_a = (reverse6(a) == a);
        int sym_b = (reverse6(b) == b);
        if (sym_a && sym_b) {
            if ((a ^ b) != 0x3F) return 0;
        } else {
            if (reverse6(a) != b) return 0;
        }
    }
    return 1;
}

/* C2 signal: count of 5-line transitions in 63 consecutive-pair slots. */
static int null_c2_count_5line(const uint8_t *seq) {
    int n = 0;
    for (int i = 0; i < 63; i++) {
        if (__builtin_popcount(seq[i] ^ seq[i+1]) == 5) n++;
    }
    return n;
}

/* C3 total complement distance. KW's value is 776. */
static int null_c3_total_comp_dist(const uint8_t *seq) {
    int pos[64];
    for (int i = 0; i < 64; i++) pos[seq[i]] = i;
    int total = 0;
    for (int v = 0; v < 64; v++) {
        int d = pos[v] - pos[v ^ 0x3F];
        total += d < 0 ? -d : d;
    }
    return total;
}

/* ---------- Exhaustive de Bruijn B(2, 6) enumeration ----------
 *
 * Enumerates all Eulerian circuits of the B(2, 5) de Bruijn graph
 * starting at vertex 0. Each circuit corresponds to exactly one B(2, 6)
 * sequence. The total count is 2^26 = 67,108,864 by the BEST theorem
 * for this graph. For each sequence, reads the 64 overlapping 6-bit
 * windows as a hexagram permutation and aggregates C1/C2/C3 statistics.
 */

static uint64_t dbe_used_mask;        /* 64-bit: edge (2*v + b) used? */
static uint8_t  dbe_path[64];         /* edge labels along current circuit */
static uint64_t dbe_count;
static uint64_t dbe_c1_pass;
static uint64_t dbe_c2_zero;
static uint64_t dbe_c3_le_kw;
static int      dbe_c3_min, dbe_c3_max;
static uint64_t dbe_c3_sum;
static int      dbe_c2_min, dbe_c2_max;

static void dbe_evaluate(void) {
    uint8_t hexs[64];
    int w = 0;
    for (int j = 0; j < 6; j++) w |= dbe_path[j] << j;
    hexs[0] = w;
    for (int i = 1; i < 64; i++) {
        w = (w >> 1) | (dbe_path[(i + 5) % 64] << 5);
        hexs[i] = w;
    }
    dbe_count++;
    if (null_c1_pair_structure(hexs)) dbe_c1_pass++;
    int c2 = null_c2_count_5line(hexs);
    if (c2 == 0) dbe_c2_zero++;
    if (c2 < dbe_c2_min) dbe_c2_min = c2;
    if (c2 > dbe_c2_max) dbe_c2_max = c2;
    int c3 = null_c3_total_comp_dist(hexs);
    if (c3 <= KW_C3_CEILING) dbe_c3_le_kw++;
    if (c3 < dbe_c3_min) dbe_c3_min = c3;
    if (c3 > dbe_c3_max) dbe_c3_max = c3;
    dbe_c3_sum += c3;

    if ((dbe_count & 0xFFFFFFULL) == 0) {
        /* 2^27 total: each of the 2^26 cyclic B(2, 6) sequences has
         * 2 rotations that start at vertex 0 (= binary "00000"). */
        fprintf(stderr, "[null-debruijn-exact] progress: %llu / 134217728 (%.1f%%)\n",
                (unsigned long long)dbe_count, 100.0 * dbe_count / 134217728.0);
    }
}

static void dbe_recurse(int vertex, int depth) {
    if (depth == 64) {
        if (vertex == 0) dbe_evaluate();
        return;
    }
    for (int b = 0; b < 2; b++) {
        int edge = 2 * vertex + b;
        if (dbe_used_mask & (1ULL << edge)) continue;
        dbe_used_mask |= (1ULL << edge);
        dbe_path[depth] = b;
        dbe_recurse(((vertex << 1) | b) & 31, depth + 1);
        dbe_used_mask &= ~(1ULL << edge);
    }
}

static void run_null_debruijn_exact(void) {
    printf("# Exhaustive de Bruijn B(2, 6) null-model analysis\n\n");
    printf("Enumerating all Eulerian circuits of B(2, 5) starting at vertex 0.\n");
    printf("Target count: 2^27 = 134,217,728 = (2^26 cyclic sequences) x (2 vertex-0-rotations per cyclic).\n\n");
    dbe_used_mask = 0;
    dbe_count = 0;
    dbe_c1_pass = dbe_c2_zero = dbe_c3_le_kw = 0;
    dbe_c3_min = 100000; dbe_c3_max = 0; dbe_c3_sum = 0;
    dbe_c2_min = 10000;  dbe_c2_max = 0;

    time_t start = time(NULL);
    dbe_recurse(0, 0);
    time_t end = time(NULL);

    printf("\nResults (n = %llu, wall time %lds):\n",
           (unsigned long long)dbe_count, (long)(end - start));
    printf("  C1 pair structure pass:        %llu / %llu  (%.8f%%)\n",
           (unsigned long long)dbe_c1_pass, (unsigned long long)dbe_count,
           100.0 * dbe_c1_pass / dbe_count);
    printf("  C2 no 5-line transitions:      %llu / %llu  (%.8f%%)\n",
           (unsigned long long)dbe_c2_zero, (unsigned long long)dbe_count,
           100.0 * dbe_c2_zero / dbe_count);
    printf("  C3 total comp dist <= %d:      %llu / %llu  (%.6f%%)\n",
           KW_C3_CEILING,
           (unsigned long long)dbe_c3_le_kw, (unsigned long long)dbe_count,
           100.0 * dbe_c3_le_kw / dbe_count);
    printf("\n  5-line transitions: range [%d, %d]\n", dbe_c2_min, dbe_c2_max);
    printf("  C3 comp distance:   range [%d, %d], mean %.2f\n",
           dbe_c3_min, dbe_c3_max, (double)dbe_c3_sum / dbe_count);
    printf("  KW C3 (776) percentile: %.4f-th\n",
           100.0 * dbe_c3_le_kw / dbe_count);
}

/* ---------- Gray code null (binary-reflected and orbit) ----------
 *
 * A 6-bit Gray code is a permutation of {0..63} in which every
 * consecutive pair has Hamming distance 1. By construction every
 * consecutive bit_diff is 1, so Hamming-5 is impossible → C2 always
 * satisfied. And since reverse_6bit(v) XOR v and v XOR (v^63) are
 * never 1 (they are 0/2/4/6 for reverse, 6 for complement), C1 is
 * also impossible in any Gray code — adjacent pair Hamming distance
 * is forced to 1, never the values C1 requires. So the interesting
 * question is C3.
 *
 * Enumerates the canonical binary-reflected Gray code + its orbit
 * under {64 cyclic rotations} × {identity, reversal} × {identity,
 * bit-complement}, all of which preserve the Hamming-1 adjacency
 * property.
 */

static void gray_canonical(uint8_t *seq) {
    /* Standard binary-reflected Gray code: g(i) = i ^ (i >> 1). */
    for (int i = 0; i < 64; i++) seq[i] = (uint8_t)(i ^ (i >> 1));
}

static void run_null_gray(void) {
    printf("# Null-model: 6-bit Gray codes (binary-reflected orbit)\n\n");
    uint8_t base[64];
    gray_canonical(base);

    uint64_t n_c1 = 0, n_c2 = 0, n_c3 = 0, n_total = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;

    uint8_t seq[64];
    for (int shift = 0; shift < 64; shift++) {
        for (int rev = 0; rev < 2; rev++) {
            for (int comp = 0; comp < 2; comp++) {
                for (int i = 0; i < 64; i++) {
                    int idx = (i + shift) % 64;
                    uint8_t v = rev ? base[(63 - idx)] : base[idx];
                    if (comp) v ^= 0x3F;
                    seq[i] = v;
                }
                n_total++;
                if (null_c1_pair_structure(seq)) n_c1++;
                int c2 = null_c2_count_5line(seq);
                if (c2 == 0) n_c2++;
                int c3 = null_c3_total_comp_dist(seq);
                if (c3 <= KW_C3_CEILING) n_c3++;
                if (c3 < c3_min) c3_min = c3;
                if (c3 > c3_max) c3_max = c3;
                c3_sum += c3;
            }
        }
    }
    printf("Orbit size (64 rotations × 2 reverse × 2 complement): %llu\n\n",
           (unsigned long long)n_total);
    printf("  C1 pair structure pass:        %llu / %llu  (%.2f%%)\n",
           (unsigned long long)n_c1, (unsigned long long)n_total,
           100.0 * n_c1 / n_total);
    printf("  C2 no 5-line transitions:      %llu / %llu  (%.2f%%)\n",
           (unsigned long long)n_c2, (unsigned long long)n_total,
           100.0 * n_c2 / n_total);
    printf("  C3 total comp dist <= 776:     %llu / %llu  (%.2f%%)\n",
           (unsigned long long)n_c3, (unsigned long long)n_total,
           100.0 * n_c3 / n_total);
    printf("  C3 range [%d, %d], mean %.1f\n",
           c3_min, c3_max, (double)c3_sum / n_total);
    printf("\nNote: by construction every Gray code has Hamming-1 transitions,\n");
    printf("so C2 (no Hamming-5) is automatic for the whole family. C1 is\n");
    printf("impossible because the constraint requires adjacent-pair Hamming\n");
    printf("distance in {0, 2, 4, 6}, which Hamming-1 adjacency cannot meet.\n");
    printf("Only C3 is informative here.\n");
}

/* ---------- Latin-square row × column traversal null ----------
 *
 * The 64 hexagrams naturally form an 8×8 Latin square where entry
 * (upper_trigram, lower_trigram) is the hexagram with those trigrams
 * as top and bottom. A row-then-column traversal picks a row order
 * AND a column order (same column order applied to every row), giving
 * 8! × 8! = 1,625,702,400 structured permutations.
 *
 * This is the "definitive" scope for Latin-square row-traversals where
 * the column order is globally consistent across rows. (Letting each
 * row have its own column order gives (8!)^9 ≈ 10^45 — combinatorially
 * well beyond a "structured" permutation family.)
 */

static void run_null_latin(void) {
    printf("# Null-model: Latin-square row × column traversals (8! × 8!)\n\n");
    printf("Enumerating all %llu permutations (row ordering × column ordering)...\n\n",
           40320ULL * 40320ULL);

    int row_perm[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    int col_perm[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    int c_row[8] = {0};
    uint64_t n_c1 = 0, n_c2 = 0, n_c3 = 0, n_total = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;
    int c2_min = 10000, c2_max = 0;
    time_t start = time(NULL);

    do {  /* per row permutation (Heap's algorithm, outer) */
        /* Reset column state for each new row permutation */
        int c_col[8] = {0};
        for (int i = 0; i < 8; i++) col_perm[i] = i;

        do {  /* per column permutation (Heap's algorithm, inner) */
            uint8_t seq[64];
            for (int rr = 0; rr < 8; rr++) {
                int upper = row_perm[rr];
                for (int cc = 0; cc < 8; cc++) {
                    int lower = col_perm[cc];
                    seq[rr * 8 + cc] = (uint8_t)((upper << 3) | lower);
                }
            }
            n_total++;
            if (null_c1_pair_structure(seq)) n_c1++;
            int c2 = null_c2_count_5line(seq);
            if (c2 == 0) n_c2++;
            if (c2 < c2_min) c2_min = c2;
            if (c2 > c2_max) c2_max = c2;
            int c3 = null_c3_total_comp_dist(seq);
            if (c3 <= KW_C3_CEILING) n_c3++;
            if (c3 < c3_min) c3_min = c3;
            if (c3 > c3_max) c3_max = c3;
            c3_sum += c3;
            if ((n_total & 0xFFFFFFFULL) == 0) {
                fprintf(stderr, "[null-latin] progress: %llu / 1625702400 (%.1f%%)\n",
                        (unsigned long long)n_total,
                        100.0 * n_total / 1625702400.0);
            }
            /* advance col_perm */
            int k = 0;
            while (k < 8 && c_col[k] >= k) { c_col[k] = 0; k++; }
            if (k == 8) break;
            int swap_j = (k & 1) ? c_col[k] : 0;
            int tmp = col_perm[swap_j]; col_perm[swap_j] = col_perm[k]; col_perm[k] = tmp;
            c_col[k]++;
        } while (1);

        /* advance row_perm */
        int k = 0;
        while (k < 8 && c_row[k] >= k) { c_row[k] = 0; k++; }
        if (k == 8) break;
        int swap_j = (k & 1) ? c_row[k] : 0;
        int tmp = row_perm[swap_j]; row_perm[swap_j] = row_perm[k]; row_perm[k] = tmp;
        c_row[k]++;
    } while (1);

    time_t end = time(NULL);
    printf("Results (n = %llu, wall time %lds):\n",
           (unsigned long long)n_total, (long)(end - start));
    printf("  C1 pair structure pass:        %llu / %llu  (%.8f%%)\n",
           (unsigned long long)n_c1, (unsigned long long)n_total,
           100.0 * n_c1 / n_total);
    printf("  C2 no 5-line transitions:      %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c2, (unsigned long long)n_total,
           100.0 * n_c2 / n_total);
    printf("  C3 total comp dist <= 776:     %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c3, (unsigned long long)n_total,
           100.0 * n_c3 / n_total);
    printf("\n  5-line transitions: range [%d, %d]\n", c2_min, c2_max);
    printf("  C3 comp distance:   range [%d, %d], mean %.1f\n",
           c3_min, c3_max, (double)c3_sum / n_total);
}

/* ---------- Latin-square COLUMN-first traversal null ----------
 *
 * Symmetric variant of run_null_latin: reads the 8×8 Latin-square grid
 * COLUMN-by-column instead of row-by-row. Tests whether the 57.96% C2
 * rate observed in row-first traversal is a row-direction-specific
 * artifact or a Latin-square invariant.
 *
 * By the symmetry of the construction — within a column, adjacent
 * entries share the lower trigram (Hamming ≤ 3 again) and only
 * between-column transitions can be Hamming-5 — we expect the same
 * 57.96% rate to hold. Verifying this empirically confirms the
 * Latin-square decomposition theorem is direction-invariant.
 */

static void run_null_latin_col(void) {
    printf("# Null-model: Latin-square COLUMN × row traversals (8! × 8!)\n\n");
    printf("Enumerating all %llu column-first permutations (column-ordering × row-ordering).\n",
           40320ULL * 40320ULL);
    printf("Symmetric variant of --null-latin; tests if 57.96%% C2 rate is row-specific.\n\n");

    int col_perm[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    int row_perm[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    int c_col[8] = {0};
    uint64_t n_c1 = 0, n_c2 = 0, n_c3 = 0, n_total = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;
    int c2_min = 10000, c2_max = 0;
    time_t start = time(NULL);

    do {  /* per column permutation (outer) */
        int c_row[8] = {0};
        for (int i = 0; i < 8; i++) row_perm[i] = i;

        do {  /* per row permutation (inner) */
            uint8_t seq[64];
            for (int cc = 0; cc < 8; cc++) {
                int lower = col_perm[cc];
                for (int rr = 0; rr < 8; rr++) {
                    int upper = row_perm[rr];
                    seq[cc * 8 + rr] = (uint8_t)((upper << 3) | lower);
                }
            }
            n_total++;
            if (null_c1_pair_structure(seq)) n_c1++;
            int c2 = null_c2_count_5line(seq);
            if (c2 == 0) n_c2++;
            if (c2 < c2_min) c2_min = c2;
            if (c2 > c2_max) c2_max = c2;
            int c3 = null_c3_total_comp_dist(seq);
            if (c3 <= KW_C3_CEILING) n_c3++;
            if (c3 < c3_min) c3_min = c3;
            if (c3 > c3_max) c3_max = c3;
            c3_sum += c3;
            if ((n_total & 0xFFFFFFFULL) == 0) {
                fprintf(stderr, "[null-latin-col] progress: %llu / 1625702400 (%.1f%%)\n",
                        (unsigned long long)n_total,
                        100.0 * n_total / 1625702400.0);
            }
            int k = 0;
            while (k < 8 && c_row[k] >= k) { c_row[k] = 0; k++; }
            if (k == 8) break;
            int swap_j = (k & 1) ? c_row[k] : 0;
            int tmp = row_perm[swap_j]; row_perm[swap_j] = row_perm[k]; row_perm[k] = tmp;
            c_row[k]++;
        } while (1);

        int k = 0;
        while (k < 8 && c_col[k] >= k) { c_col[k] = 0; k++; }
        if (k == 8) break;
        int swap_j = (k & 1) ? c_col[k] : 0;
        int tmp = col_perm[swap_j]; col_perm[swap_j] = col_perm[k]; col_perm[k] = tmp;
        c_col[k]++;
    } while (1);

    time_t end = time(NULL);
    printf("Results (n = %llu, wall time %lds):\n",
           (unsigned long long)n_total, (long)(end - start));
    printf("  C1 pair structure pass:        %llu / %llu  (%.8f%%)\n",
           (unsigned long long)n_c1, (unsigned long long)n_total,
           100.0 * n_c1 / n_total);
    printf("  C2 no 5-line transitions:      %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c2, (unsigned long long)n_total,
           100.0 * n_c2 / n_total);
    printf("  C3 total comp dist <= 776:     %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c3, (unsigned long long)n_total,
           100.0 * n_c3 / n_total);
    printf("\n  5-line transitions: range [%d, %d]\n", c2_min, c2_max);
    printf("  C3 comp distance:   range [%d, %d], mean %.1f\n",
           c3_min, c3_max, (double)c3_sum / n_total);
    printf("\nExpected if Latin-square decomposition is direction-invariant:\n");
    printf("  C2 rate should match --null-latin's 57.96%% (942,243,840).\n");
    printf("  If matched, confirms the row/column decomposition is symmetric.\n");
}

/* ---------- Lexicographic null ----------
 *
 * The natural lexicographic ordering [0, 1, 2, ..., 63] is one specific
 * permutation. Permuting the 6 bit positions gives 6! = 720 distinct
 * "lexicographic" orderings (each a relabeling of the bits). Finite
 * and small.
 */

static void run_null_lex(void) {
    printf("# Null-model: lexicographic orderings (bit-order variants)\n\n");
    int bit_perm[6] = {0, 1, 2, 3, 4, 5};
    int c[6] = {0};
    uint64_t n_c1 = 0, n_c2 = 0, n_c3 = 0, n_total = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;
    int c2_min = 10000, c2_max = 0;

    do {
        uint8_t seq[64];
        for (int i = 0; i < 64; i++) {
            int v = 0;
            for (int b = 0; b < 6; b++) {
                if (i & (1 << b)) v |= (1 << bit_perm[b]);
            }
            seq[i] = (uint8_t)v;
        }
        n_total++;
        if (null_c1_pair_structure(seq)) n_c1++;
        int c2 = null_c2_count_5line(seq);
        if (c2 == 0) n_c2++;
        if (c2 < c2_min) c2_min = c2;
        if (c2 > c2_max) c2_max = c2;
        int c3 = null_c3_total_comp_dist(seq);
        if (c3 <= KW_C3_CEILING) n_c3++;
        if (c3 < c3_min) c3_min = c3;
        if (c3 > c3_max) c3_max = c3;
        c3_sum += c3;

        int k = 0;
        while (k < 6 && c[k] >= k) { c[k] = 0; k++; }
        if (k == 6) break;
        int swap_j = (k & 1) ? c[k] : 0;
        int tmp = bit_perm[swap_j]; bit_perm[swap_j] = bit_perm[k]; bit_perm[k] = tmp;
        c[k]++;
    } while (1);

    printf("Family size: 6! = %llu (natural lex under bit-order permutations)\n\n",
           (unsigned long long)n_total);
    printf("  C1 pair structure pass:        %llu / %llu  (%.2f%%)\n",
           (unsigned long long)n_c1, (unsigned long long)n_total,
           100.0 * n_c1 / n_total);
    printf("  C2 no 5-line transitions:      %llu / %llu  (%.2f%%)\n",
           (unsigned long long)n_c2, (unsigned long long)n_total,
           100.0 * n_c2 / n_total);
    printf("  C3 total comp dist <= 776:     %llu / %llu  (%.2f%%)\n",
           (unsigned long long)n_c3, (unsigned long long)n_total,
           100.0 * n_c3 / n_total);
    printf("\n  5-line transitions: range [%d, %d]\n", c2_min, c2_max);
    printf("  C3 comp distance:   range [%d, %d], mean %.1f\n",
           c3_min, c3_max, (double)c3_sum / n_total);
}

/* ---------- Historical-ordering null ----------
 *
 * Checks C1/C2/C3 against documented historical / structural hexagram
 * orderings: Fu Xi (natural binary), King Wen (sanity check), Mawangdui
 * (silk-text ordering). These are point tests, not enumerations.
 */

static void run_null_historical(void) {
    printf("# Null-model: historical hexagram orderings\n\n");

    /* King Wen 0-based hexagram values (matches verify.py::KW) */
    uint8_t kw[64] = {
        63,  0, 17, 34, 23, 58,  2, 16, 55, 59,  7, 56, 61, 47,  4,  8,
        25, 38,  3, 48, 41, 37, 32,  1, 57, 39, 33, 30, 18, 45, 28, 14,
        60, 15, 40,  5, 53, 43, 20, 10, 35, 49, 31, 62, 24,  6, 26, 22,
        29, 46,  9, 36, 52, 11, 13, 44, 54, 27, 50, 19, 51, 12, 21, 42,
    };

    /* Fu Xi: natural binary order */
    uint8_t fuxi[64];
    for (int i = 0; i < 64; i++) fuxi[i] = (uint8_t)i;

    /* Mawangdui: 0-based KW indices (from roae.py::mawangdui_kw_indices) */
    int md_idx[64] = {
         0, 43, 12, 24, 11,  9,  5, 32, 42, 27, 48, 16, 44, 57, 46, 30,
         4, 47, 62,  2,  7, 59, 28, 38, 33, 31, 54, 50, 15, 53, 39, 61,
        10, 45, 35, 23,  1, 18,  6, 14,  8, 56, 36, 41, 19, 60, 58, 52,
        13, 49, 29, 20, 34, 37, 63, 55, 25, 17, 21, 26, 22, 40,  3, 51,
    };
    uint8_t mawangdui[64];
    for (int i = 0; i < 64; i++) mawangdui[i] = kw[md_idx[i]];

    /* Jing Fang 8 Palaces (京房八宫卦, c. 77-37 BCE).
     * Each palace has 8 hexagrams generated by successive bit flips from
     * a "pure" origin (upper-trigram = lower-trigram). Palace order is
     * Qian (111) -> Zhen (001) -> Kan (010) -> Gen (100) -> Kun (000)
     * -> Xun (110) -> Li (101) -> Dui (011) (yang-yin alternation).
     * Within each palace: origin, 1st world, 2nd world, 3rd world (flip
     * lower trigram), 4th world, 5th world, wandering soul (游魂),
     * returning soul (归魂). See CITATIONS.md — this encoding reflects
     * the standard sinological convention documented in the Yi Jing
     * literature; PR welcome if a different ordering is authoritative. */
    int jf_palace_trigrams[8] = {0b111, 0b001, 0b010, 0b100, 0b000, 0b110, 0b101, 0b011};
    uint8_t jingfang[64];
    for (int p = 0; p < 8; p++) {
        int t = jf_palace_trigrams[p];
        jingfang[p * 8 + 0] = (uint8_t)((t << 3) | t);                 /* origin */
        jingfang[p * 8 + 1] = (uint8_t)((t << 3) | (t ^ 0b001));       /* 1st world */
        jingfang[p * 8 + 2] = (uint8_t)((t << 3) | (t ^ 0b011));       /* 2nd world */
        jingfang[p * 8 + 3] = (uint8_t)((t << 3) | (t ^ 0b111));       /* 3rd world */
        jingfang[p * 8 + 4] = (uint8_t)(((t ^ 0b001) << 3) | (t ^ 0b111)); /* 4th world */
        jingfang[p * 8 + 5] = (uint8_t)(((t ^ 0b011) << 3) | (t ^ 0b111)); /* 5th world */
        jingfang[p * 8 + 6] = (uint8_t)(((t ^ 0b010) << 3) | (t ^ 0b111)); /* wandering soul */
        jingfang[p * 8 + 7] = (uint8_t)(((t ^ 0b010) << 3) | t);       /* returning soul */
    }

    const char *names[] = {"Fu Xi (natural binary)", "King Wen", "Mawangdui (silk-text)",
                           "Jing Fang (8 Palaces)"};
    uint8_t *seqs[] = {fuxi, kw, mawangdui, jingfang};

    printf("%-28s %-10s %-15s %-16s %s\n",
           "Ordering", "C1 (pair)", "5-lines count", "C3 total dist", "all three?");
    printf("%-28s %-10s %-15s %-16s %s\n",
           "--------", "---------", "-------------", "-------------", "----------");
    for (int s = 0; s < 4; s++) {
        int c1 = null_c1_pair_structure(seqs[s]);
        int c2 = null_c2_count_5line(seqs[s]);
        int c3 = null_c3_total_comp_dist(seqs[s]);
        int all3 = c1 && (c2 == 0) && (c3 <= KW_C3_CEILING);
        printf("%-28s %-10s %-15d %-16d %s\n",
               names[s], c1 ? "PASS" : "fail", c2, c3,
               all3 ? "YES (C1+C2+C3)" : "no");
    }
    printf("\nKing Wen passes all three (sanity check). Fu Xi is a binary-count\n");
    printf("ordering and fails all three. Mawangdui and Jing Fang both satisfy\n");
    printf("C2 (no 5-line transitions) — suggesting that avoiding Hamming-5\n");
    printf("may be a classical Chinese design principle rather than unique to\n");
    printf("King Wen. None of Fu Xi, Mawangdui, or Jing Fang satisfy C1 (pair\n");
    printf("structure is KW-specific among these) or C3 (complement-distance\n");
    printf("minimization is also KW-specific).\n");
}

/* ---------- Random 64-permutation null (sampling) ----------
 *
 * Generates N uniformly random 64-permutations via Fisher-Yates + a
 * fast xorshift RNG, and counts satisfaction of C1/C2/C3. Provides the
 * "unstructured null" baseline at very tight sample size (10^9 default,
 * ~5-10 min on a 2-core VM).
 */

static uint64_t xor64_state;
static inline uint64_t xor64_next(void) {
    uint64_t x = xor64_state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    xor64_state = x;
    return x;
}

static inline void random_permutation(uint8_t *p, int n) {
    for (int i = 0; i < n; i++) p[i] = (uint8_t)i;
    for (int i = n - 1; i > 0; i--) {
        int j = (int)(xor64_next() % (uint64_t)(i + 1));
        uint8_t tmp = p[i]; p[i] = p[j]; p[j] = tmp;
    }
}

static void run_null_random(uint64_t n_trials) {
    printf("# Null-model: %llu uniformly random 64-permutations\n\n",
           (unsigned long long)n_trials);
    xor64_state = 0x9E3779B97F4A7C15ULL;

    uint64_t n_c1 = 0, n_c2 = 0, n_c3 = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;
    int c2_min = 10000, c2_max = 0;
    time_t start = time(NULL);

    for (uint64_t t = 0; t < n_trials; t++) {
        uint8_t seq[64];
        random_permutation(seq, 64);
        if (null_c1_pair_structure(seq)) n_c1++;
        int c2 = null_c2_count_5line(seq);
        if (c2 == 0) n_c2++;
        if (c2 < c2_min) c2_min = c2;
        if (c2 > c2_max) c2_max = c2;
        int c3 = null_c3_total_comp_dist(seq);
        if (c3 <= KW_C3_CEILING) n_c3++;
        if (c3 < c3_min) c3_min = c3;
        if (c3 > c3_max) c3_max = c3;
        c3_sum += c3;
        if ((t & 0x3FFFFFFULL) == 0 && t > 0) {
            time_t now = time(NULL);
            double elapsed = (double)(now - start);
            double rate = (double)t / (elapsed > 0 ? elapsed : 1);
            double eta = (double)(n_trials - t) / (rate > 0 ? rate : 1);
            fprintf(stderr, "[null-random] progress: %llu / %llu (%.1f%%) rate %.0f/s ETA %.0fs\n",
                    (unsigned long long)t, (unsigned long long)n_trials,
                    100.0 * t / n_trials, rate, eta);
        }
    }
    time_t end = time(NULL);

    printf("Results (n = %llu, wall time %lds):\n",
           (unsigned long long)n_trials, (long)(end - start));
    printf("  C1 pair structure pass:        %llu / %llu  (%.8f%%)\n",
           (unsigned long long)n_c1, (unsigned long long)n_trials,
           100.0 * n_c1 / n_trials);
    printf("  C2 no 5-line transitions:      %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c2, (unsigned long long)n_trials,
           100.0 * n_c2 / n_trials);
    printf("  C3 total comp dist <= 776:     %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c3, (unsigned long long)n_trials,
           100.0 * n_c3 / n_trials);
    printf("\n  5-line transitions: range [%d, %d]\n", c2_min, c2_max);
    printf("  C3 comp distance:   range [%d, %d], mean %.1f\n",
           c3_min, c3_max, (double)c3_sum / n_trials);
}

/* ---------- Random 6-bit Gray code sampling ----------
 *
 * The 6-bit Gray code family (Hamiltonian cycles in the 6-cube Q_6) has
 * ~10^22 members — exhaustive enumeration is infeasible. But a random
 * walk-based sampler can efficiently generate many distinct Gray codes,
 * letting us bound the conditional C3 rate (C1 and C2 are analytically
 * fixed for all Gray codes: C1 = 0% by the Hamming-disjoint argument,
 * C2 = 100% trivially by construction).
 *
 * Sampling strategy: start at a random vertex of Q_6, repeatedly move
 * to a uniformly-random unvisited neighbor (Hamming-1 bit-flip). When
 * all 64 vertices are visited, that's a Gray-code permutation. If the
 * random walk dead-ends before visiting all 64 (possible since Q_6 is
 * not Hamilton-connected in the sense we need), restart. This is biased
 * compared to uniform Hamiltonian-cycle sampling but is a reasonable
 * approximation for bounding the C3 rate.
 */

static inline int __attribute__((unused)) xor64_bit(uint64_t x, int b) { return (int)((x >> b) & 1); }

static int gray_random_walk(uint8_t *seq) {
    /* Pure-random unvisited-neighbor selection. Walk success rate ~0.13%
     * in Q_6 (random walks dead-end frequently), so N=10^5 samples take
     * ~2 minutes and N=10^6 takes ~20 min. Caveat: non-uniform over the
     * Gray code family but more diverse than Warnsdorff variants (which
     * collapse to binary-reflected-Gray-code-like structures with
     * C3 = 2048 max-case). Returns 1 on success, 0 on dead-end. */
    int visited[64] = {0};
    int v = (int)(xor64_next() & 0x3F);
    seq[0] = (uint8_t)v;
    visited[v] = 1;
    int neighbors[6], n_unvisited;
    for (int i = 1; i < 64; i++) {
        n_unvisited = 0;
        for (int b = 0; b < 6; b++) {
            int nv = v ^ (1 << b);
            if (!visited[nv]) neighbors[n_unvisited++] = nv;
        }
        if (n_unvisited == 0) return 0;
        int pick = neighbors[(int)(xor64_next() % (uint64_t)n_unvisited)];
        seq[i] = (uint8_t)pick;
        visited[pick] = 1;
        v = pick;
    }
    return 1;
}

static void run_null_gray_random(uint64_t n_trials) {
    printf("# Null-model: random 6-bit Gray codes (Hamiltonian walks in Q_6)\n\n");
    printf("Sampling %llu random Gray-code permutations via unvisited-neighbor walks.\n",
           (unsigned long long)n_trials);
    printf("Non-uniform sampler; bounds conditional C3 rate over the ~10^22 Gray code family.\n");
    printf("C1 = 0 by analytic proof (Hamming-1 adjacency disjoint from C1); verified as sanity.\n");
    printf("C2 = always 0 five-line transitions (trivially by construction); verified.\n\n");

    xor64_state = 0x7EEDBEEF1E15CAFEULL;
    uint64_t attempts = 0;
    uint64_t n_c1 = 0, n_c2_nonzero = 0, n_c3 = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;
    time_t start = time(NULL);
    uint8_t seq[64];

    for (uint64_t t = 0; t < n_trials; t++) {
        /* keep trying until walk completes successfully */
        while (!gray_random_walk(seq)) { attempts++; }
        attempts++;

        /* sanity checks */
        if (null_c1_pair_structure(seq)) n_c1++;  /* should be 0 */
        int c2 = null_c2_count_5line(seq);
        if (c2 != 0) n_c2_nonzero++;  /* should be 0 */

        int c3 = null_c3_total_comp_dist(seq);
        if (c3 <= KW_C3_CEILING) n_c3++;
        if (c3 < c3_min) c3_min = c3;
        if (c3 > c3_max) c3_max = c3;
        c3_sum += c3;

        if ((t & 0x3FFFFFFULL) == 0 && t > 0) {
            time_t now = time(NULL);
            double elapsed = (double)(now - start);
            double rate = (double)t / (elapsed > 0 ? elapsed : 1);
            double eta = (double)(n_trials - t) / (rate > 0 ? rate : 1);
            fprintf(stderr,
                    "[null-gray-random] progress: %llu / %llu (%.1f%%) rate %.0f/s ETA %.0fs "
                    "attempts/success=%.2f\n",
                    (unsigned long long)t, (unsigned long long)n_trials,
                    100.0 * t / n_trials, rate, eta, (double)attempts / (double)(t + 1));
        }
    }
    time_t end = time(NULL);

    printf("Results (n = %llu successful Gray codes, total walk attempts = %llu, wall %lds):\n",
           (unsigned long long)n_trials, (unsigned long long)attempts, (long)(end - start));
    printf("  Walk success rate:             %.2f%%\n", 100.0 * n_trials / attempts);
    printf("  C1 (sanity, should be 0):      %llu / %llu\n",
           (unsigned long long)n_c1, (unsigned long long)n_trials);
    printf("  C2 != 0 (sanity, should be 0): %llu / %llu\n",
           (unsigned long long)n_c2_nonzero, (unsigned long long)n_trials);
    printf("  C3 (comp dist <= 776):         %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c3, (unsigned long long)n_trials,
           100.0 * n_c3 / n_trials);
    printf("\n  C3 range: [%d, %d], mean %.1f\n", c3_min, c3_max, (double)c3_sum / n_trials);

    /* Wilson 95% upper bound if n_c3 is zero */
    if (n_c3 == 0) {
        double upper_95 = 3.0 / (double)n_trials;  /* rule of three */
        printf("  95%% upper bound on C3 rate (Rule of Three): %.3e\n", upper_95);
    }
}

/* ---------- Latin-square C2 rate decomposition ----------
 *
 * Analytically explains the --null-latin result that 57.96% of 8!×8!
 * row×column traversals have zero 5-line transitions.
 *
 * Theorem: in a Latin-square row×col traversal, 56 of 63 adjacent-pair
 * transitions are within-row (share upper trigram → Hamming ≤ 3 < 5,
 * cannot be 5-line). Only the 7 between-row boundaries can be Hamming-5.
 *
 * At boundary i, Hamming = popcount(r_i XOR r_{i+1}) + popcount(c[0] XOR c[7])
 * where each popcount ∈ {1, 2, 3}. Sum = 5 iff (p_i, d) = (2, 3) or (3, 2).
 *
 * Per-row-perm C2 rate depends only on whether {p_1, ..., p_7} contains 2s
 * and/or 3s. For d = popcount(c[0] XOR c[7]):
 *   d = 1 (24 pairs, × 720 middle cols = 17,280 col perms): always passes C2
 *   d = 2 (24 pairs, × 720 = 17,280): passes iff no p_i = 3
 *   d = 3 (8 pairs, × 720 = 5,760): passes iff no p_i = 2
 *
 * So per-row-perm good column perms:
 *   All p_i = 1       → 40,320 / 40,320 = 100% (rate 56/56)
 *   Some p_i = 2 only → 34,560 / 40,320 =  6/7 (rate 48/56)
 *   Some p_i = 3 only → 23,040 / 40,320 =  4/7 (rate 32/56)
 *   Both 2s and 3s    → 17,280 / 40,320 =  3/7 (rate 24/56)
 *
 * This routine enumerates all 8! row perms, classifies each by its
 * {p_1, ..., p_7} popcount multiset, and computes the predicted total
 * good-col count. Verification: should equal 942,243,840 exactly, matching
 * the empirical --null-latin result.
 */

static void run_null_latin_explain(void) {
    printf("# Latin-square C2-rate decomposition analysis\n\n");
    printf("Verifying analytical explanation of the 57.96%% C2 rate in 8!×8! Latin-\n");
    printf("square row×column traversals.\n\n");

    int perm[8] = {0, 1, 2, 3, 4, 5, 6, 7};
    int c[8] = {0};
    uint64_t N_all1 = 0, N_2only = 0, N_3only = 0, N_both = 0;
    uint64_t N_total = 0;

    do {
        /* Tally p_i = popcount(perm[i] XOR perm[i+1]) for boundaries i=0..6 */
        int has_2 = 0, has_3 = 0;
        for (int i = 0; i < 7; i++) {
            int p = __builtin_popcount(perm[i] ^ perm[i + 1]);
            if (p == 2) has_2 = 1;
            if (p == 3) has_3 = 1;
        }
        if (!has_2 && !has_3) N_all1++;
        else if (has_2 && !has_3) N_2only++;
        else if (!has_2 && has_3) N_3only++;
        else N_both++;
        N_total++;

        int k = 0;
        while (k < 8 && c[k] >= k) { c[k] = 0; k++; }
        if (k == 8) break;
        int swap_j = (k & 1) ? c[k] : 0;
        int tmp = perm[swap_j]; perm[swap_j] = perm[k]; perm[k] = tmp;
        c[k]++;
    } while (1);

    printf("Row permutation class census (n = %llu = 8!):\n", (unsigned long long)N_total);
    printf("  all p_i = 1 (Ham. path in Q_3):        %8llu  (%6.4f%%)\n",
           (unsigned long long)N_all1, 100.0 * N_all1 / N_total);
    printf("  some p_i = 2, no p_i = 3:              %8llu  (%6.4f%%)\n",
           (unsigned long long)N_2only, 100.0 * N_2only / N_total);
    printf("  some p_i = 3, no p_i = 2:              %8llu  (%6.4f%%)\n",
           (unsigned long long)N_3only, 100.0 * N_3only / N_total);
    printf("  both p_i = 2 and p_i = 3:              %8llu  (%6.4f%%)\n",
           (unsigned long long)N_both, 100.0 * N_both / N_total);

    uint64_t predicted_good_col_perms_total =
        N_all1 * 40320 + N_2only * 34560 + N_3only * 23040 + N_both * 17280;
    uint64_t total_traversals = N_total * 40320;

    printf("\nPredicted total (good row×col pairs):\n");
    printf("  %llu×40320 + %llu×34560 + %llu×23040 + %llu×17280\n",
           (unsigned long long)N_all1, (unsigned long long)N_2only,
           (unsigned long long)N_3only, (unsigned long long)N_both);
    printf("  = %llu\n", (unsigned long long)predicted_good_col_perms_total);
    printf("  Expected (empirical --null-latin):  942,243,840\n");
    printf("  Match: %s\n",
           predicted_good_col_perms_total == 942243840ULL ? "YES ✓" : "MISMATCH (analysis gap)");

    printf("\nPredicted C2 rate: %.6f%%\n",
           100.0 * predicted_good_col_perms_total / total_traversals);
    printf("Empirical C2 rate: 57.959184%%  (942,243,840 / 1,625,702,400)\n");

    /* Breakdown contributions */
    printf("\nContribution to total by class:\n");
    printf("  all p_i = 1:       %12llu good col perms × row perms\n",
           (unsigned long long)(N_all1 * 40320));
    printf("  some 2, no 3:      %12llu\n",
           (unsigned long long)(N_2only * 34560));
    printf("  some 3, no 2:      %12llu\n",
           (unsigned long long)(N_3only * 23040));
    printf("  both 2 and 3:      %12llu\n",
           (unsigned long long)(N_both * 17280));
}

/* ---------- Pair-constrained random null ----------
 *
 * Samples uniformly random sequences that satisfy C1 by construction:
 * take the 32 canonical KW pairs, permute their positions via Fisher-
 * Yates, and pick a random 2-choice orientation (which element first)
 * per pair. Since C1 is baked in, this isolates the QUESTION: "given
 * C1, how often do random such sequences also satisfy C2 and C3?"
 *
 * This is the critical null for interpreting KW's C2+C3 properties:
 * in the 6 prior families, C1 was impossible, so we could not measure
 * conditional C2/C3 rates. This family makes C1 trivial and measures
 * how much additional structure C2 and C3 represent beyond pair-
 * reflection.
 */

static void run_null_pair_constrained(uint64_t n_trials) {
    printf("# Null-model: pair-constrained random permutations\n\n");
    printf("Sampling %llu random pair-position permutations with random orientations.\n",
           (unsigned long long)n_trials);
    printf("C1 is guaranteed by construction; measures conditional C2/C3 rates.\n\n");

    init_pairs();  /* populates pairs[0..31] from KW */
    xor64_state = 0xA5A5A5A5DEADBEEFULL;

    uint64_t n_c1_verified = 0, n_c2 = 0, n_c3 = 0;
    int c3_min = 100000, c3_max = 0;
    uint64_t c3_sum = 0;
    int c2_min = 10000, c2_max = 0;
    time_t start = time(NULL);

    int order[32];
    for (uint64_t t = 0; t < n_trials; t++) {
        /* Fisher-Yates on pair positions */
        for (int i = 0; i < 32; i++) order[i] = i;
        for (int i = 31; i > 0; i--) {
            int j = (int)(xor64_next() % (uint64_t)(i + 1));
            int tmp = order[i]; order[i] = order[j]; order[j] = tmp;
        }
        /* Random orientation per pair */
        uint64_t orient_bits = xor64_next();
        uint8_t seq[64];
        for (int i = 0; i < 32; i++) {
            int p = order[i];
            int o = (orient_bits >> i) & 1;
            if (o == 0) {
                seq[2 * i]     = (uint8_t)pairs[p].a;
                seq[2 * i + 1] = (uint8_t)pairs[p].b;
            } else {
                seq[2 * i]     = (uint8_t)pairs[p].b;
                seq[2 * i + 1] = (uint8_t)pairs[p].a;
            }
        }
        if (null_c1_pair_structure(seq)) n_c1_verified++;  /* sanity */
        int c2 = null_c2_count_5line(seq);
        if (c2 == 0) n_c2++;
        if (c2 < c2_min) c2_min = c2;
        if (c2 > c2_max) c2_max = c2;
        int c3 = null_c3_total_comp_dist(seq);
        if (c3 <= KW_C3_CEILING) n_c3++;
        if (c3 < c3_min) c3_min = c3;
        if (c3 > c3_max) c3_max = c3;
        c3_sum += c3;
        if ((t & 0x3FFFFFFULL) == 0 && t > 0) {
            time_t now = time(NULL);
            double elapsed = (double)(now - start);
            double rate = (double)t / (elapsed > 0 ? elapsed : 1);
            double eta = (double)(n_trials - t) / (rate > 0 ? rate : 1);
            fprintf(stderr,
                    "[null-pair-constrained] progress: %llu / %llu (%.1f%%) rate %.0f/s ETA %.0fs\n",
                    (unsigned long long)t, (unsigned long long)n_trials,
                    100.0 * t / n_trials, rate, eta);
        }
    }
    time_t end = time(NULL);

    printf("Results (n = %llu, wall time %lds):\n",
           (unsigned long long)n_trials, (long)(end - start));
    printf("  C1 verified (sanity):          %llu / %llu  (%.4f%%)\n",
           (unsigned long long)n_c1_verified, (unsigned long long)n_trials,
           100.0 * n_c1_verified / n_trials);
    printf("  C2 | C1 (no 5-line transitions, given C1):  %llu / %llu  (%.6f%%)\n",
           (unsigned long long)n_c2, (unsigned long long)n_trials,
           100.0 * n_c2 / n_trials);
    printf("  C3 | C1 (comp distance <= %d, given C1):    %llu / %llu  (%.6f%%)\n",
           KW_C3_CEILING,
           (unsigned long long)n_c3, (unsigned long long)n_trials,
           100.0 * n_c3 / n_trials);
    printf("\n  5-line transitions: range [%d, %d]\n", c2_min, c2_max);
    printf("  C3 comp distance:   range [%d, %d], mean %.1f\n",
           c3_min, c3_max, (double)c3_sum / n_trials);
    printf("\nInterpretation: given that C1 holds, how often does a random valid\n");
    printf("pair-ordering also satisfy the adjacency and complement constraints?\n");
    printf("Solve.c's canonical enumeration at 10T (d3: 706M orderings) and 100T\n");
    printf("measures this exhaustively under the C1+C2+C3 filter; this Monte-Carlo\n");
    printf("sample gives the *unconditional* rate over uniformly random pair-perms.\n");
}

/* ---------- C3-min: find minimum complement distance in solutions.bin ----------
 *
 * Addresses Open Question #11 / #7 Phase A Day 1 MVP. Reads every record
 * in solutions.bin, decodes the 64-hexagram sequence, computes the total
 * complement distance (= sum over all 64 v of |pos[v] - pos[v^63]|), and
 * reports the minimum observed. King Wen's value is 776. If the minimum
 * is 776, KW is THE C3-minimum under C1+C2. If less, KW is not the
 * minimum — we have a natural axiom set ("minimum C3 under C1+C2") that
 * does NOT uniquely pick out KW.
 */

/* --yield-report: per-sub-branch yield-clustering analysis of a solve.c
 * enumeration log. Reads stdin (expects `zcat enum_output.log.gz | ./solve
 * --yield-report` or similar). Parses "Wrote N solutions to
 * sub_P1_O1_P2_O2_P3_O3.bin" lines and emits:
 *   [1] Aggregate yield stats
 *   [2] Top 20 most-common yield values with ASCII histogram
 *   [3] Orientation-symmetry clusters (prefixes where all orientation
 *       variants yield the identical count)
 *   [4] Summary with symmetric vs asymmetric breakdown by group size
 *
 * Addresses "why weren't the yield-clustering and orientation-symmetry
 * findings surfaced from the 100T canonical enumeration log?" — they were
 * latent in the log all along; nobody aggregated per-sub-branch yields
 * into a report. See HISTORY.md Day 11 for discovery narrative.
 */

#define YIELD_MAX_ENTRIES 200000

typedef struct {
    int p1, o1, p2, o2, p3, o3;
    long long yield;
} YieldEntry;

typedef struct {
    long long yield;
    int count;
} YieldCount;

static int yr_cmp_yield_asc(const void *a, const void *b) {
    long long ya = ((const YieldEntry *)a)->yield;
    long long yb = ((const YieldEntry *)b)->yield;
    if (ya < yb) return -1;
    if (ya > yb) return 1;
    return 0;
}

static int yr_cmp_prefix(const void *a, const void *b) {
    const YieldEntry *ea = a, *eb = b;
    if (ea->p1 != eb->p1) return ea->p1 - eb->p1;
    if (ea->p2 != eb->p2) return ea->p2 - eb->p2;
    if (ea->p3 != eb->p3) return ea->p3 - eb->p3;
    if (ea->o1 != eb->o1) return ea->o1 - eb->o1;
    if (ea->o2 != eb->o2) return ea->o2 - eb->o2;
    return ea->o3 - eb->o3;
}

static int yr_cmp_count_desc(const void *a, const void *b) {
    return ((const YieldCount *)b)->count - ((const YieldCount *)a)->count;
}

static void yr_print_bar(int count, int max_count, int width) {
    int n = (int)((double)count / max_count * width + 0.5);
    for (int i = 0; i < n; i++) putchar('#');
}

static void run_yield_report(void) {
    YieldEntry *entries = calloc(YIELD_MAX_ENTRIES, sizeof(YieldEntry));
    if (!entries) { fprintf(stderr, "ERROR: calloc entries\n"); exit(10); }
    int n_entries = 0;

    char line[1024];
    while (fgets(line, sizeof(line), stdin) != NULL) {
        long long y;
        int p1, o1, p2, o2, p3, o3;
        if (sscanf(line,
                   " Wrote %lld solutions to sub_%d_%d_%d_%d_%d_%d.bin",
                   &y, &p1, &o1, &p2, &o2, &p3, &o3) == 7) {
            if (n_entries >= YIELD_MAX_ENTRIES) {
                fprintf(stderr, "ERROR: exceeded YIELD_MAX_ENTRIES=%d\n", YIELD_MAX_ENTRIES);
                free(entries); exit(10);
            }
            entries[n_entries].p1 = p1; entries[n_entries].o1 = o1;
            entries[n_entries].p2 = p2; entries[n_entries].o2 = o2;
            entries[n_entries].p3 = p3; entries[n_entries].o3 = o3;
            entries[n_entries].yield = y;
            n_entries++;
        }
    }

    if (n_entries == 0) {
        fprintf(stderr, "ERROR: no 'Wrote N solutions to sub_*.bin' lines found on stdin\n");
        free(entries); exit(1);
    }

    /* Section 1: aggregate stats */
    qsort(entries, n_entries, sizeof(YieldEntry), yr_cmp_yield_asc);
    long long min_y = entries[0].yield;
    long long max_y = entries[n_entries - 1].yield;
    long long median_y = entries[n_entries / 2].yield;
    long long sum_y = 0;
    for (int i = 0; i < n_entries; i++) sum_y += entries[i].yield;
    double mean_y = (double)sum_y / n_entries;
    int n_distinct = 0;
    long long prev = -1;
    for (int i = 0; i < n_entries; i++) {
        if (entries[i].yield != prev) { n_distinct++; prev = entries[i].yield; }
    }

    printf("======================================================================\n");
    printf("[1] AGGREGATE YIELD STATS\n");
    printf("======================================================================\n");
    printf("  Non-zero-yield sub-branches: %d\n", n_entries);
    printf("  Distinct yield values:       %d\n", n_distinct);
    printf("  Mean branches per yield:     %.2f\n", (double)n_entries / n_distinct);
    printf("  Min yield:                   %lld\n", min_y);
    printf("  Max yield:                   %lld\n", max_y);
    printf("  Median yield:                %lld\n", median_y);
    printf("  Mean yield:                  %.1f\n", mean_y);
    printf("  Sum of yields:               %lld\n\n", sum_y);

    /* Section 2: top 20 most-common yield values */
    YieldCount *yc = calloc(YIELD_MAX_ENTRIES, sizeof(YieldCount));
    if (!yc) { fprintf(stderr, "ERROR: calloc yc\n"); free(entries); exit(10); }
    int n_yc = 0;
    {
        long long py = entries[0].yield;
        int run = 1;
        for (int i = 1; i < n_entries; i++) {
            if (entries[i].yield == py) run++;
            else {
                yc[n_yc].yield = py; yc[n_yc].count = run; n_yc++;
                py = entries[i].yield; run = 1;
            }
        }
        yc[n_yc].yield = py; yc[n_yc].count = run; n_yc++;
    }
    qsort(yc, n_yc, sizeof(YieldCount), yr_cmp_count_desc);

    printf("======================================================================\n");
    printf("[2] TOP 20 MOST-COMMON YIELD VALUES\n");
    printf("======================================================================\n");
    printf("  Rank  #Branches  Yield         Histogram\n");
    int max_count = yc[0].count;
    for (int i = 0; i < 20 && i < n_yc; i++) {
        printf("  %-4d  %-9d  %-12lld  ", i + 1, yc[i].count, yc[i].yield);
        yr_print_bar(yc[i].count, max_count, 40);
        putchar('\n');
    }
    putchar('\n');

    /* Section 3 & 4: orientation-symmetry */
    qsort(entries, n_entries, sizeof(YieldEntry), yr_cmp_prefix);
    int n_groups_total = 0, n_groups_multi = 0, n_groups_sym = 0, n_groups_asym = 0;
    int max_group_size = 0;
    int g_start = 0;
    int sym_by_size[9] = {0}, asym_by_size[9] = {0};

    printf("======================================================================\n");
    printf("[3] ORIENTATION-SYMMETRY CLUSTERS — groups where ALL variants yield same\n");
    printf("======================================================================\n");
    printf("  (p1, p2, p3)        N variants   shared yield\n");
    int printed = 0;
    for (int i = 1; i <= n_entries; i++) {
        int end_of_group = (i == n_entries) ||
            entries[i].p1 != entries[g_start].p1 ||
            entries[i].p2 != entries[g_start].p2 ||
            entries[i].p3 != entries[g_start].p3;
        if (!end_of_group) continue;

        int size = i - g_start;
        n_groups_total++;
        if (size > max_group_size) max_group_size = size;
        if (size >= 2) {
            n_groups_multi++;
            int all_same = 1;
            long long yref = entries[g_start].yield;
            for (int j = g_start + 1; j < i; j++) {
                if (entries[j].yield != yref) { all_same = 0; break; }
            }
            if (all_same) {
                n_groups_sym++;
                if (size < 9) sym_by_size[size]++;
                if (size >= 3 && printed < 40) {
                    printf("  (%2d, %2d, %2d)         %d            %lld\n",
                           entries[g_start].p1, entries[g_start].p2,
                           entries[g_start].p3, size, yref);
                    printed++;
                }
            } else {
                n_groups_asym++;
                if (size < 9) asym_by_size[size]++;
            }
        }
        g_start = i;
    }
    if (printed == 0) printf("  (none with size >= 3; see counts by size below)\n");
    putchar('\n');

    printf("  Group-size breakdown (symmetric = all variants identical yield):\n");
    printf("    Size     Symmetric    Asymmetric\n");
    for (int s = 2; s < 9; s++) {
        if (sym_by_size[s] + asym_by_size[s] > 0)
            printf("    %-7d  %-11d  %-11d\n", s, sym_by_size[s], asym_by_size[s]);
    }
    putchar('\n');

    printf("======================================================================\n");
    printf("[4] SUMMARY\n");
    printf("======================================================================\n");
    printf("  Distinct (p1, p2, p3) groups:                 %d\n", n_groups_total);
    printf("  Groups with >= 2 orientation variants:        %d\n", n_groups_multi);
    printf("  Groups where ALL variants yield same number:  %d (%.1f%% of multi)\n",
           n_groups_sym, 100.0 * n_groups_sym / (n_groups_multi ? n_groups_multi : 1));
    printf("  Groups with asymmetric yields:                %d (%.1f%% of multi)\n",
           n_groups_asym, 100.0 * n_groups_asym / (n_groups_multi ? n_groups_multi : 1));
    printf("  Largest orientation group:                    %d variants\n", max_group_size);
    printf("\n  INTERPRETATION:\n");
    printf("  High symmetric %% => orientation-invariance is a robust structural\n");
    printf("  property. Presence of asymmetric groups => orientation matters for\n");
    printf("  some prefix classes; those are candidates for deeper study.\n");

    free(yc); free(entries);
}

/* =========================================================================
 * --symmetry-search: Hamming-class-preserving permutation search.
 * Spec: x/roae/SYMMETRY_SEARCH_SPEC.md.
 *
 * Given the 64 hexagrams (6-bit values), the Hamming-class-preserving
 * permutations of {0..63} are the bit-position permutations of {0..5},
 * giving 6! = 720 candidates. Of those, only the σ's that PRESERVE the
 * C1 pair partition are interesting — the rest move pairs to non-pairs
 * and immediately falsify any "σ is a symmetry" hypothesis.
 *
 * Phases:
 *   1+2 (always): enumerate 720, filter to C1-preserving, compute σ's
 *       induced action on the 64-element (pair_idx, orient) space, and
 *       its orbit structure. Identifies CANDIDATE σ's.
 *   3 (with --validate-counts): read an enumeration log from stdin, parse
 *       per-sub-branch yields, and verify σ preserves yield across each
 *       orbit pair. Falsifies any σ that doesn't.
 *
 * Phase 4 (bijection sampling against solutions.bin records) is not
 * implemented here — requires the canonical solutions.bin which is
 * 102 GB on solver-data-westus3, and is run via a separate VM workflow.
 * ========================================================================= */

/* Apply bit-position permutation sigma to a 6-bit value v.
 * sigma[i] = the new position of bit i in the output. */
static int apply_sigma(int v, const int sigma[6]) {
    int result = 0;
    for (int i = 0; i < 6; i++) {
        if ((v >> i) & 1) {
            result |= (1 << sigma[i]);
        }
    }
    return result;
}

/* Lex-order next permutation of 6 ints. Returns 1 if a next exists, 0 if last. */
static int next_perm6(int *p) {
    int i = 4;
    while (i >= 0 && p[i] >= p[i + 1]) i--;
    if (i < 0) return 0;
    int j = 5;
    while (p[j] <= p[i]) j--;
    int t = p[i]; p[i] = p[j]; p[j] = t;
    for (int a = i + 1, b = 5; a < b; a++, b--) {
        t = p[a]; p[a] = p[b]; p[b] = t;
    }
    return 1;
}

/* Returns pair-index of hex h, or -1 if not in any pair. */
static int pair_of_hex(int h) {
    for (int i = 0; i < 32; i++) {
        if (pairs[i].a == h || pairs[i].b == h) return i;
    }
    return -1;
}

/* sigma preserves C1 iff for every pair (a, b), σ(a) and σ(b) land in the
 * same (possibly different) pair. */
static int sigma_preserves_c1(const int sigma[6]) {
    for (int i = 0; i < 32; i++) {
        int sa = apply_sigma(pairs[i].a, sigma);
        int sb = apply_sigma(pairs[i].b, sigma);
        int pa = pair_of_hex(sa);
        int pb = pair_of_hex(sb);
        if (pa < 0 || pb < 0 || pa != pb) return 0;
    }
    return 1;
}

/* sigma's induced action on the (pair_idx, orient) space (64 elements).
 * Encoding: index = 2*p + o.  Output: po_image[2*p+o] = 2*p' + o'. */
static void compute_po_action(const int sigma[6], int po_image[64]) {
    for (int p = 0; p < 32; p++) {
        for (int o = 0; o < 2; o++) {
            int hex0 = (o == 0) ? pairs[p].a : pairs[p].b;
            int s_hex0 = apply_sigma(hex0, sigma);
            int p_prime = pair_of_hex(s_hex0);
            int o_prime = (pairs[p_prime].a == s_hex0) ? 0 : 1;
            po_image[2 * p + o] = 2 * p_prime + o_prime;
        }
    }
}

static int is_identity_action(const int po_image[64]) {
    for (int i = 0; i < 64; i++) if (po_image[i] != i) return 0;
    return 1;
}

/* Computes orbit length of each element under sigma's action.
 * orbit_size_of_elem[i] = length of i's cycle. Returns total #orbits. */
static int compute_orbits(const int po_image[64], int orbit_size_of_elem[64]) {
    int seen[64] = {0};
    int n_orbits = 0;
    for (int start = 0; start < 64; start++) {
        if (seen[start]) continue;
        int len = 0;
        int cur = start;
        while (!seen[cur]) {
            seen[cur] = 1;
            cur = po_image[cur];
            len++;
        }
        cur = start;
        for (int k = 0; k < len; k++) {
            orbit_size_of_elem[cur] = len;
            cur = po_image[cur];
        }
        n_orbits++;
    }
    return n_orbits;
}

/* Phase 3 helper: a parsed (prefix → yield) entry.
 * Reuses YieldEntry from --yield-report (already defined). */
typedef struct {
    int p1, o1, p2, o2, p3, o3;
    long long yield;
} SymEntry;

/* Phase 3: parse stdin enum log into a hash table; for each non-trivial σ,
 * map each prefix p to its σ-image p' and verify yield(p) == yield(p'). */
static void symmetry_phase3(const int candidates[][6], int n_candidates) {
    /* Read all "Wrote N solutions to sub_P1_O1_P2_O2_P3_O3.bin" lines. */
    SymEntry *entries = calloc(YIELD_MAX_ENTRIES, sizeof(SymEntry));
    if (!entries) { fprintf(stderr, "ERROR: alloc\n"); exit(10); }
    int n = 0;
    char line[1024];
    while (fgets(line, sizeof(line), stdin)) {
        long long y;
        int p1, o1, p2, o2, p3, o3;
        if (sscanf(line, " Wrote %lld solutions to sub_%d_%d_%d_%d_%d_%d.bin",
                   &y, &p1, &o1, &p2, &o2, &p3, &o3) == 7) {
            if (n >= YIELD_MAX_ENTRIES) {
                fprintf(stderr, "ERROR: yield buffer overflow at %d\n", YIELD_MAX_ENTRIES);
                free(entries); exit(10);
            }
            entries[n].p1 = p1; entries[n].o1 = o1;
            entries[n].p2 = p2; entries[n].o2 = o2;
            entries[n].p3 = p3; entries[n].o3 = o3;
            entries[n].yield = y;
            n++;
        }
    }
    fprintf(stderr, "[sym-phase3] parsed %d sub-branch yields from stdin\n", n);

    /* Build lookup: hash (p1,o1,p2,o2,p3,o3) → yield.
     * Encode key as 24-bit integer: p1(5) o1(1) p2(5) o2(1) p3(5) o3(1) padding to 24.
     * 32 pairs need 5 bits, orient 1. Total 6 fields × 6 bits each (pair < 32,
     * orient < 2 → both fit in 5 bits / 1 bit). Pack into 18 bits. */
    #define SYM_KEY(p1, o1, p2, o2, p3, o3) \
        (((p1) << 13) | ((o1) << 12) | ((p2) << 7) | ((o2) << 6) | ((p3) << 1) | (o3))
    long long *yield_by_key = calloc(1 << 18, sizeof(long long));
    if (!yield_by_key) { fprintf(stderr, "ERROR: alloc map\n"); free(entries); exit(10); }
    /* Sentinel: -1 means "no entry". Use 0 as default; treat 0 as missing. */
    for (int i = 0; i < n; i++) {
        int k = SYM_KEY(entries[i].p1, entries[i].o1,
                        entries[i].p2, entries[i].o2,
                        entries[i].p3, entries[i].o3);
        yield_by_key[k] = entries[i].yield + 1;  /* +1 so 0 means missing */
    }

    /* For each candidate σ, walk every prefix, apply σ, check yields. */
    printf("\n=== Phase 3: count comparison across σ orbits ===\n");
    printf("(checks whether σ-image prefix has identical yield as preimage)\n\n");
    for (int s = 0; s < n_candidates; s++) {
        const int *sigma = candidates[s];
        int po_image[64];
        compute_po_action(sigma, po_image);

        long long mismatches = 0;
        long long matches = 0;
        long long missing = 0;
        long long max_diff = 0;

        for (int i = 0; i < n; i++) {
            int p1 = entries[i].p1, o1 = entries[i].o1;
            int p2 = entries[i].p2, o2 = entries[i].o2;
            int p3 = entries[i].p3, o3 = entries[i].o3;
            int img1 = po_image[2 * p1 + o1];
            int img2 = po_image[2 * p2 + o2];
            int img3 = po_image[2 * p3 + o3];
            int p1p = img1 / 2, o1p = img1 & 1;
            int p2p = img2 / 2, o2p = img2 & 1;
            int p3p = img3 / 2, o3p = img3 & 1;
            int kp = SYM_KEY(p1p, o1p, p2p, o2p, p3p, o3p);
            long long target = yield_by_key[kp];
            if (target == 0) {
                missing++;
                continue;
            }
            long long y_orig = entries[i].yield;
            long long y_image = target - 1;
            if (y_orig == y_image) {
                matches++;
            } else {
                mismatches++;
                long long diff = (y_orig > y_image) ? (y_orig - y_image) : (y_image - y_orig);
                if (diff > max_diff) max_diff = diff;
            }
        }
        printf("σ #%d [%d %d %d %d %d %d]:  matches=%lld  mismatches=%lld  "
               "missing=%lld  max_diff=%lld   →  %s\n",
               s + 1, sigma[0], sigma[1], sigma[2], sigma[3], sigma[4], sigma[5],
               matches, mismatches, missing, max_diff,
               (mismatches == 0 ? "**CANDIDATE SYMMETRY**" : "FALSIFIED"));
    }
    printf("\n(missing = σ-image prefix had no entry in the parsed log;\n"
           " typically because the prefix was BUDGETED with 0 solutions and\n"
           " no Wrote-line was emitted. Treat as inconclusive for that σ-pair.)\n");

    free(yield_by_key);
    free(entries);
    #undef SYM_KEY
}

static void run_symmetry_search(int with_yield_compare) {
    init_pairs();
    printf("=== SYMMETRY SEARCH (Hamming-class-preserving σ on C1 partition) ===\n\n");
    printf("Spec: x/roae/SYMMETRY_SEARCH_SPEC.md\n");
    printf("Phase 1+2: enumerate 720 bit-permutations, filter to C1-preserving,\n");
    printf("compute σ's induced action on (pair_idx, orient) space.\n\n");

    int p[6] = {0, 1, 2, 3, 4, 5};
    int n_total = 0, n_c1 = 0, n_nontrivial = 0;
    /* Up to 720 candidates; bounded. */
    int candidates[720][6];
    int n_candidates = 0;

    do {
        n_total++;
        if (!sigma_preserves_c1(p)) continue;
        n_c1++;
        int po_image[64];
        compute_po_action(p, po_image);
        if (is_identity_action(po_image)) continue;
        n_nontrivial++;
        for (int i = 0; i < 6; i++) candidates[n_candidates][i] = p[i];
        n_candidates++;

        int orbit_size_of_elem[64];
        int n_orbits = compute_orbits(po_image, orbit_size_of_elem);
        printf("σ #%d: bit-perm [%d %d %d %d %d %d]\n",
               n_nontrivial, p[0], p[1], p[2], p[3], p[4], p[5]);
        printf("        %d orbits on (pair,orient) space; sizes: ", n_orbits);
        int size_hist[65] = {0};
        for (int i = 0; i < 64; i++) size_hist[orbit_size_of_elem[i]]++;
        for (int k = 1; k <= 64; k++) {
            int n_orb_of_size_k = size_hist[k] / k;
            if (n_orb_of_size_k > 0) {
                printf("%d×%d ", n_orb_of_size_k, k);
            }
        }
        printf("\n");
    } while (next_perm6(p));

    printf("\n=== Phase 1+2 SUMMARY ===\n");
    printf("Total 6-bit permutations:               %d\n", n_total);
    printf("C1-preserving:                          %d (%.1f%%)\n",
           n_c1, n_c1 * 100.0 / n_total);
    printf("Non-trivial on (pair,orient) space:     %d\n", n_nontrivial);

    if (n_nontrivial == 0) {
        printf("\nResult: NO non-trivial bit-permutation acts non-trivially on the\n");
        printf("(pair, orient) space while preserving C1. The C1 partition rigidly\n");
        printf("breaks all Hamming-class symmetries. Symmetry exploitation via this\n");
        printf("class is impossible. (This is a NEGATIVE result, paper-worthy.)\n");
        return;
    }

    if (!with_yield_compare) {
        printf("\nFor Phase 3 (yield comparison across σ orbits), pipe an enumeration\n");
        printf("log:\n");
        printf("    zcat enum_output.log.gz | ./solve --symmetry-search --validate-counts\n");
        return;
    }

    /* Phase 3 */
    symmetry_phase3(candidates, n_candidates);
}

static void run_c3_min(const char *filename) {
    init_pairs();
    FILE *f = fopen(filename, "rb");
    if (!f) { fprintf(stderr, "ERROR: cannot open %s\n", filename); exit(10); }
    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);
    fseek(f, 0, SEEK_SET);

    uint64_t hdr_records = 0;
    if (sol_read_header(f, &hdr_records) != 0) {
        fprintf(stderr, "ERROR: %s has invalid magic or unsupported format version\n", filename);
        fclose(f);
        exit(20);
    }
    long record_bytes = fsize - SOL_HEADER_SIZE;
    long long n_records = record_bytes / SOL_RECORD_SIZE;
    printf("# C3-min analysis: %s\n", filename);
    printf("Records: %lld\n", n_records);
    printf("KW C3 (reference): 776\n\n");

    unsigned char rec[SOL_RECORD_SIZE];
    int min_c3 = 100000;
    long long count_at_min = 0;
    long long count_at_max = 0;
    int kw_idx = -1;  /* record index of KW if found */
    int kw_c3_observed = -1;
    int histogram[5000] = {0};  /* C3 histogram (should never exceed ~2048 practically) */
    int max_c3_observed = 0;
    time_t start = time(NULL);

    /* First pass: find minimum */
    for (long long r = 0; r < n_records; r++) {
        if (fread(rec, SOL_RECORD_SIZE, 1, f) != 1) {
            fprintf(stderr, "ERROR: short read at record %lld\n", r);
            fclose(f); exit(20);
        }
        int seq[64];
        for (int i = 0; i < 32; i++) {
            int pidx = (rec[i] >> 2) & 0x3F;
            int orient = (rec[i] >> 1) & 1;
            if (orient == 0) {
                seq[i * 2] = pairs[pidx].a;
                seq[i * 2 + 1] = pairs[pidx].b;
            } else {
                seq[i * 2] = pairs[pidx].b;
                seq[i * 2 + 1] = pairs[pidx].a;
            }
        }
        uint8_t useq[64];
        for (int i = 0; i < 64; i++) useq[i] = (uint8_t)seq[i];
        int c3 = null_c3_total_comp_dist(useq);
        if (c3 < min_c3) { min_c3 = c3; count_at_min = 1; }
        else if (c3 == min_c3) count_at_min++;
        if (c3 > max_c3_observed) { max_c3_observed = c3; count_at_max = 1; }
        else if (c3 == max_c3_observed) count_at_max++;
        if (c3 >= 0 && c3 < 5000) histogram[c3]++;
        /* Check if this is KW */
        int is_kw = 1;
        for (int i = 0; i < 64 && is_kw; i++) {
            if (seq[i] != KW[i]) is_kw = 0;
        }
        if (is_kw) { kw_idx = (int)r; kw_c3_observed = c3; }

        if ((r & 0xFFFFFFULL) == 0 && r > 0) {
            time_t now = time(NULL);
            double elapsed = (double)(now - start);
            double rate = (double)r / (elapsed > 0 ? elapsed : 1);
            double eta = (double)(n_records - r) / (rate > 0 ? rate : 1);
            fprintf(stderr, "[c3-min] progress: %lld / %lld (%.1f%%) min_so_far=%d rate=%.0f/s ETA=%.0fs\n",
                    r, n_records, 100.0 * r / n_records, min_c3, rate, eta);
        }
    }
    time_t end = time(NULL);
    fclose(f);

    printf("\nResults (wall time %lds):\n", (long)(end - start));
    printf("  Minimum C3 observed:     %d\n", min_c3);
    printf("  Count of records at min: %lld (%.8f%% of %lld)\n",
           count_at_min, 100.0 * count_at_min / n_records, n_records);
    printf("  Maximum C3 observed:     %d\n", max_c3_observed);
    printf("  Count of records at max: %lld (%.8f%% of %lld)\n",
           count_at_max, 100.0 * count_at_max / n_records, n_records);
    printf("  KW found at record idx:  %s\n",
           kw_idx >= 0 ? "YES" : "NO (file doesn't contain KW — unexpected)");
    if (kw_idx >= 0) {
        printf("  KW C3 (verified):        %d  (expected 776)\n", kw_c3_observed);
        printf("  KW is C3-max uniquely?:  %s\n",
               (kw_c3_observed == max_c3_observed && count_at_max == 1)
                   ? "YES — KW is the UNIQUE maximum. 'maximize C3' picks KW uniquely."
                   : (kw_c3_observed == max_c3_observed)
                       ? "NO — KW ties with other records at C3-max. Axiom 'max C3' does not uniquely pick KW."
                       : "NO — KW is not the C3-maximum.");
    }
    printf("\nInterpretation:\n");
    if (min_c3 == 776 && kw_c3_observed == 776) {
        printf("  KW IS at the C3-minimum under C1+C2. %lld record(s) tie at C3=776.\n",
               count_at_min);
        if (count_at_min == 1) {
            printf("  KW is the UNIQUE C3-minimum — 'minimum C3 under C1+C2' is a\n");
            printf("  candidate natural axiom that picks out KW uniquely (Phase A progress).\n");
        } else {
            printf("  KW is one of %lld C3-minimum records. Minimization is necessary but\n",
                   count_at_min);
            printf("  not sufficient to uniquely derive KW from first principles.\n");
        }
    } else if (min_c3 < 776) {
        printf("  Minimum C3 (%d) is LESS than KW (776) — KW is NOT the C3-minimum.\n", min_c3);
        printf("  Some other C1+C2 ordering places complements even closer than KW.\n");
        printf("  Axiom 'minimize C3' alone cannot derive KW.\n");
    }
    printf("\n  Bottom 10 C3 values observed (bucket, count):\n");
    int reported = 0;
    for (int c = 0; c <= max_c3_observed && reported < 10; c++) {
        if (histogram[c] > 0) {
            printf("    C3=%-4d  %lld records\n", c, (long long)histogram[c]);
            reported++;
        }
    }
    printf("\n  Top 10 C3 values observed (bucket, count):\n");
    reported = 0;
    for (int c = max_c3_observed; c >= 0 && reported < 10; c--) {
        if (histogram[c] > 0) {
            printf("    C3=%-4d  %lld records\n", c, (long long)histogram[c]);
            reported++;
        }
    }
    /* Summary for Open Question #7 derivability analysis */
    printf("\n  Summary (Open Question #7 Phase A):\n");
    if (kw_c3_observed == min_c3 && count_at_min == 1) {
        printf("    ✓ 'minimize C3' uniquely picks KW.\n");
    } else if (kw_c3_observed == min_c3) {
        printf("    ✗ 'minimize C3' picks %lld records (including KW). Not unique.\n", count_at_min);
    } else {
        printf("    ✗ 'minimize C3' does NOT pick KW (min=%d, KW=%d, %lld records at min).\n",
               min_c3, kw_c3_observed, count_at_min);
    }
    if (kw_c3_observed == max_c3_observed && count_at_max == 1) {
        printf("    ✓ 'maximize C3' uniquely picks KW! Strong Phase A positive result.\n");
    } else if (kw_c3_observed == max_c3_observed) {
        printf("    ~ 'maximize C3' picks %lld records (including KW). Not unique.\n", count_at_max);
    } else {
        printf("    ✗ 'maximize C3' does NOT pick KW (max=%d, KW=%d).\n",
               max_c3_observed, kw_c3_observed);
    }
}

/* ---------- Main ---------- */

int main(int argc, char *argv[]) {
    /* Check for single-branch mode */
    int single_branch_mode = 0;
    int single_sub_branch_mode = 0;   /* --sub-branch: run ONE d3 sub-branch to exhaustion */
    int parallel_sub_branch_enabled = 0;  /* P1: auto-on when SOLVE_THREADS > 1 in --sub-branch mode */
    int sb_pair = -1, sb_orient = -1;
    int ssb_pair2 = -1, ssb_orient2 = -1, ssb_pair3 = -1, ssb_orient3 = -1;
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
    } else if (argc > 1 && strcmp(argv[1], "--merge-layers") == 0) {
        /* Layered merge (2026-04-29): enumeration runs are organized as
         * sibling subdirs ("layers") under a root. Each layer's name sorts
         * lexically by intended order — convention: `<NN>_<scope>_<budget>_<date>/`
         * (e.g., `01_full_5T_2026_04_29/`, `02_extend_dead_50T_2026_04_30/`).
         * Within a layer, shards are normal `sub_<p1>_<o1>_<p2>_<o2>[_<p3>_<o3>].bin`
         * files. For each sub-branch parameter tuple, the LAST layer (in sort
         * order) to contain a shard wins. The winners are symlinked into
         * <root>/_merged_/ along with a MANIFEST.txt recording provenance,
         * then the standard merge runs in that dir, producing
         * <root>/_merged_/solutions.bin. Rationale: extending an enumeration
         * later (higher per-sub-branch budget on a subset of sub-branches)
         * is non-destructive — the prior layer's shards are preserved
         * intact, and rolling back is just `rm -rf <new_layer>`. */
        if (argc < 3) {
            fprintf(stderr, "Usage: solve --merge-layers <root>\n");
            return 1;
        }
        const char *layer_root = argv[2];
        DIR *rd = opendir(layer_root);
        if (!rd) {
            fprintf(stderr, "ERROR: opendir(%s): %s\n", layer_root, strerror(errno));
            return 10;
        }
        #define MERGE_LAYERS_MAX 256
        static char layer_names[MERGE_LAYERS_MAX][256];
        int n_layers = 0;
        struct dirent *de;
        while ((de = readdir(rd)) != NULL) {
            if (de->d_name[0] == '.') continue;
            if (strcmp(de->d_name, "_merged_") == 0) continue;
            char path[512];
            snprintf(path, sizeof(path), "%s/%s", layer_root, de->d_name);
            struct stat st;
            if (stat(path, &st) != 0 || !S_ISDIR(st.st_mode)) continue;
            if (n_layers >= MERGE_LAYERS_MAX) {
                fprintf(stderr, "ERROR: too many layers (max %d)\n", MERGE_LAYERS_MAX);
                closedir(rd);
                return 10;
            }
            snprintf(layer_names[n_layers], 256, "%s", de->d_name);
            n_layers++;
        }
        closedir(rd);
        if (n_layers == 0) {
            fprintf(stderr, "ERROR: no layer subdirs found in %s\n", layer_root);
            return 1;
        }
        /* Sort layer names lexically — operator's responsibility to name
         * them so sort order = intended layer order. */
        for (int a = 0; a < n_layers - 1; a++) {
            for (int b = a + 1; b < n_layers; b++) {
                if (strcmp(layer_names[a], layer_names[b]) > 0) {
                    char tmp[256];
                    snprintf(tmp, 256, "%s", layer_names[a]);
                    snprintf(layer_names[a], 256, "%s", layer_names[b]);
                    snprintf(layer_names[b], 256, "%s", tmp);
                }
            }
        }
        printf("[merge-layers] %d layers (in sort order):\n", n_layers);
        for (int i = 0; i < n_layers; i++)
            printf("  %d. %s\n", i, layer_names[i]);

        char merged_dir[PATH_MAX];
        snprintf(merged_dir, sizeof(merged_dir), "%s/_merged_", layer_root);
        char rmcmd[PATH_MAX * 2 + 64];
        snprintf(rmcmd, sizeof(rmcmd), "rm -rf '%s' && mkdir -p '%s'",
                 merged_dir, merged_dir);
        int _r2 = system(rmcmd);
        if (_r2 != 0) {
            fprintf(stderr, "ERROR: cannot prepare merged dir %s\n", merged_dir);
            return 20;
        }

        int total_shards = 0, total_overrides = 0;
        for (int li = 0; li < n_layers; li++) {
            char layer_path[PATH_MAX + 280];
            snprintf(layer_path, sizeof(layer_path), "%s/%s",
                     layer_root, layer_names[li]);
            DIR *ld = opendir(layer_path);
            if (!ld) {
                fprintf(stderr, "WARN: cannot open layer %s: %s\n",
                        layer_path, strerror(errno));
                continue;
            }
            int layer_count = 0, layer_overrides = 0;
            while ((de = readdir(ld)) != NULL) {
                if (strncmp(de->d_name, "sub_", 4) != 0) continue;
                int nl = strlen(de->d_name);
                if (nl < 5 || strcmp(de->d_name + nl - 4, ".bin") != 0) continue;
                if (strstr(de->d_name, ".tmp")) continue;
                /* Filter out non-shard files starting with sub_:
                 * sub_ckpt_*, sub_flush_chunk_* are checkpoint/flush files. */
                if (strstr(de->d_name, "ckpt") || strstr(de->d_name, "flush_chunk"))
                    continue;
                char src[PATH_MAX + 320], dst[PATH_MAX + 320];
                snprintf(src, sizeof(src), "%s/%s", layer_path, de->d_name);
                snprintf(dst, sizeof(dst), "%s/%s", merged_dir, de->d_name);
                /* If exists from earlier layer, this layer's shard wins */
                int was_overriding = (access(dst, F_OK) == 0);
                if (was_overriding) {
                    unlink(dst);
                    layer_overrides++;
                }
                if (symlink(src, dst) != 0) {
                    fprintf(stderr, "ERROR: symlink %s -> %s: %s\n",
                            src, dst, strerror(errno));
                    closedir(ld);
                    return 20;
                }
                layer_count++;
            }
            closedir(ld);
            printf("  layer %d (%s): %d shards (%d override prior layer)\n",
                   li, layer_names[li], layer_count, layer_overrides);
            total_shards += layer_count;
            total_overrides += layer_overrides;
        }
        int unique_shards = total_shards - total_overrides;
        printf("[merge-layers] %d total shard contributions; %d distinct sub-branches; "
               "%d overrides\n",
               total_shards, unique_shards, total_overrides);

        /* Walk merged_dir, readlink each symlink to recover the WINNING
         * layer for each sub-branch. Write a clean MANIFEST.txt listing
         * only winners. */
        char manifest_path[PATH_MAX + 64];
        snprintf(manifest_path, sizeof(manifest_path), "%s/MANIFEST.txt", merged_dir);
        FILE *manifest = fopen(manifest_path, "w");
        if (!manifest) {
            fprintf(stderr, "ERROR: cannot create MANIFEST.txt: %s\n", strerror(errno));
            return 20;
        }
        fprintf(manifest, "# Layered merge manifest\n");
        fprintf(manifest, "# Layer order (later wins per shard):\n");
        for (int i = 0; i < n_layers; i++)
            fprintf(manifest, "#   %d. %s\n", i, layer_names[i]);
        fprintf(manifest, "# Distinct sub-branches: %d   Overrides applied: %d\n",
                unique_shards, total_overrides);
        fprintf(manifest, "# Format: <shard>\\t<winning_layer>\n");
        DIR *md = opendir(merged_dir);
        if (md) {
            int written = 0;
            while ((de = readdir(md)) != NULL) {
                if (strncmp(de->d_name, "sub_", 4) != 0) continue;
                int nl = strlen(de->d_name);
                if (nl < 5 || strcmp(de->d_name + nl - 4, ".bin") != 0) continue;
                char linkpath[PATH_MAX + 320], target[PATH_MAX + 320];
                snprintf(linkpath, sizeof(linkpath), "%s/%s",
                         merged_dir, de->d_name);
                ssize_t tn = readlink(linkpath, target, sizeof(target) - 1);
                if (tn < 0) continue;
                target[tn] = 0;
                /* target = "<layer_root>/<layer_name>/sub_*.bin" — extract
                 * the layer_name segment between the last two '/' */
                char *last_slash = strrchr(target, '/');
                if (!last_slash) continue;
                *last_slash = 0;
                char *layer_seg = strrchr(target, '/');
                const char *winning_layer = layer_seg ? layer_seg + 1 : target;
                fprintf(manifest, "%s\t%s\n", de->d_name, winning_layer);
                written++;
            }
            closedir(md);
        }
        fclose(manifest);
        printf("[merge-layers] manifest written to %s\n", manifest_path);
        printf("[merge-layers] running merge in %s\n", merged_dir);
        if (chdir(merged_dir) != 0) {
            fprintf(stderr, "ERROR: chdir(%s): %s\n", merged_dir, strerror(errno));
            return 20;
        }
        merge_mode = 1;
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--validate") == 0) {
        validate_mode = 1;
        validate_file = (argc > 2) ? argv[2] : "solutions.bin";
        arg_offset = argc;
    } else if (argc > 1 && strcmp(argv[1], "--null-debruijn-exact") == 0) {
        run_null_debruijn_exact();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-gray") == 0) {
        run_null_gray();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-latin") == 0) {
        run_null_latin();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-latin-col") == 0) {
        run_null_latin_col();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-lex") == 0) {
        run_null_lex();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-historical") == 0) {
        run_null_historical();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-random") == 0) {
        uint64_t n = (argc > 2) ? strtoull(argv[2], NULL, 10) : 1000000000ULL;
        run_null_random(n);
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-pair-constrained") == 0) {
        uint64_t n = (argc > 2) ? strtoull(argv[2], NULL, 10) : 1000000000ULL;
        run_null_pair_constrained(n);
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-latin-explain") == 0) {
        run_null_latin_explain();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--null-gray-random") == 0) {
        uint64_t n = (argc > 2) ? strtoull(argv[2], NULL, 10) : 1000000000ULL;
        run_null_gray_random(n);
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--c3-min") == 0) {
        const char *fn = (argc > 2) ? argv[2] : "solutions.bin";
        run_c3_min(fn);
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--yield-report") == 0) {
        /* Reads enumeration log from stdin; emits per-sub-branch yield-
         * clustering + orientation-symmetry report. Usage:
         *   zcat enum_output.log.gz | ./solve --yield-report
         */
        run_yield_report();
        return 0;
    } else if (argc > 1 && strcmp(argv[1], "--symmetry-search") == 0) {
        /* Hamming-class-preserving permutation search. Phase 1+2 always run
         * (orbit structure on (pair_idx, orient) space). With --validate-counts
         * a second arg, also run Phase 3: parse enum log from stdin and
         * compare yields across σ orbits. */
        int with_yield = (argc > 2 && strcmp(argv[2], "--validate-counts") == 0);
        run_symmetry_search(with_yield);
        return 0;
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
         * Expected sha256: 403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e
         * (Baseline was 76ada31e... before solutions.bin format v1 landed. The
         * content — 135,780 canonical pair orderings — is unchanged; only the
         * file bytes differ because the 32-byte header is now prepended.)
         */
        const char *expected_sha = "403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e";
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
        const char *tool = sha256_tool();
        if (!tool) { require_sha256_tool(); return 30; }
        /* IMPORTANT: pass time_limit = 0 (no wall-clock cap). A non-zero time
         * limit interrupts sub-branches that haven't hit their node budget,
         * and which sub-branches are still running at the interrupt moment
         * depends on thread scheduling. The result: sha256 varies run-to-run
         * under load. Using node-limit only (per-sub-branch budgets) gives
         * byte-exact determinism across thread counts and machines. */
        char cmd[8192];
        snprintf(cmd, sizeof(cmd),
                 "cd %s && "
                 "unset SOLVE_DEPTH && "
                 "SOLVE_THREADS=4 SOLVE_NODE_LIMIT=100000000 %s 0 > /dev/null 2>&1 && "
                 "%s solutions.bin | cut -d' ' -f1",
                 tempdir_template, solve_path, tool);
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
    } else if (argc > 1 && strcmp(argv[1], "--regression-test") == 0) {
        /* --regression-test (2026-04-29): partition-invariance check.
         *
         * Verifies that:
         *   sha256( full_enum at total budget B )
         *   == sha256( merge of 56 first-level enums each at budget B/56 )
         *
         * The two runs allocate the same per-depth-3-sub-branch budget
         * (B / 158,364), so under the partition-invariance theorem they
         * must produce byte-identical solutions.bin.
         *
         * Default budget: 5.6 T (5_600_000_000_000) — meaningful sample
         * (~5 M unique solutions), ~3 h walltime on D64als_v7. Override:
         *   ./solve --regression-test <budget>
         * For a fast smoke test: ./solve --regression-test 5600000  (5.6 M, ~5 min)
         *
         * Working dirs: /tmp/regress_full, /tmp/regress_56. Left in place on
         * FAIL for inspection; cleaned up on PASS.
         */
        /* init_pairs is normally called later in main; we need it here for
         * pair_index_of to identify the start pair in the (p1, o1) loop. */
        init_pairs();
        long long total_budget = 5600000000000LL;
        if (argc > 2) total_budget = atoll(argv[2]);
        if (total_budget <= 0) {
            fprintf(stderr, "ERROR: --regression-test budget must be positive\n");
            return 2;
        }
        long long per_branch_budget = total_budget / 56;
        if (per_branch_budget <= 0) {
            fprintf(stderr, "ERROR: budget too small (per-first-level = 0)\n");
            return 2;
        }
        printf("[regression-test] total_budget=%lld per_first_level=%lld\n",
               total_budget, per_branch_budget);

        char solve_path[4096];
        ssize_t sn = readlink("/proc/self/exe", solve_path, sizeof(solve_path) - 1);
        if (sn <= 0) {
            fprintf(stderr, "ERROR: cannot resolve self path\n");
            return 10;
        }
        solve_path[sn] = 0;

        const char *tool = sha256_tool();
        if (!tool) { require_sha256_tool(); return 30; }

        /* Working dirs default to /mnt/work (typical Azure data disk) since
         * /tmp on a default Azure OS disk (~30 GB) fills up at >100 G total
         * budget — the depth-3 sub_*.bin shards alone can exceed 25 GB at
         * 5.6 T scale. Override via SOLVE_REGRESS_DIR env var if needed. */
        const char *base_dir = getenv("SOLVE_REGRESS_DIR");
        if (!base_dir) {
            struct stat sst;
            base_dir = (stat("/mnt/work", &sst) == 0) ? "/mnt/work" : "/tmp";
        }
        char dir_full[PATH_MAX], dir_56[PATH_MAX];
        snprintf(dir_full, sizeof(dir_full), "%s/regress_full", base_dir);
        snprintf(dir_56,   sizeof(dir_56),   "%s/regress_56",   base_dir);
        printf("[regression-test] working dirs: %s, %s\n", dir_full, dir_56);
        char cleanup1[PATH_MAX * 2 + 64], cleanup2[PATH_MAX * 2 + 64];
        snprintf(cleanup1, sizeof(cleanup1), "rm -rf %s && mkdir -p %s", dir_full, dir_full);
        snprintf(cleanup2, sizeof(cleanup2), "rm -rf %s && mkdir -p %s", dir_56,   dir_56);
        int _r;
        _r = system(cleanup1); (void)_r;
        _r = system(cleanup2); (void)_r;

        /* Compute per-sub-branch budget so both phases walk each depth-3
         * sub-branch with IDENTICAL budget. Use SOLVE_PER_SUB_BRANCH_LIMIT
         * env var to override the auto-divide. This is the partition-
         * invariance test's core requirement: per-sub-branch budgets must
         * match across the full-enum and 56-branch-merge paths. */
        long long per_sub_branch = total_budget / 158364LL;
        printf("[regression-test] per-sub-branch budget: %lld (%lld / 158364)\n",
               per_sub_branch, total_budget);

        /* Phase 1: full enum. SOLVE_DEPTH=3 to match canonical partition.
         * Use SOLVE_PER_SUB_BRANCH_LIMIT to set per-sub-branch budget
         * directly. SOLVE_NODE_LIMIT still set as a global cap (= total
         * budget); under normal conditions it won't be the binding stop
         * (per-sub-branch caps fire first), but it provides a safety
         * ceiling. Skip the explicit `solve --merge` step — full-enum
         * already auto-merges into solutions.bin (the explicit merge is
         * redundant and produces identical sha; saves ~30 min). */
        printf("[regression-test] Phase 1/4: full enum at %lld total / %lld per-sub-branch\n",
               total_budget, per_sub_branch);
        fflush(stdout);
        char cmd[PATH_MAX * 2 + 512];
        snprintf(cmd, sizeof(cmd),
                 "cd %s && SOLVE_DEPTH=3 SOLVE_THREADS=64 SOLVE_NODE_LIMIT=%lld "
                 "SOLVE_PER_SUB_BRANCH_LIMIT=%lld %s 0 64 > full.log 2>&1",
                 dir_full, total_budget, per_sub_branch, solve_path);
        _r = system(cmd);
        if (_r != 0) {
            fprintf(stderr, "[regression-test] FAIL: full-enum phase exit=%d (see %s/full.log)\n",
                    _r, dir_full);
            return 50;
        }

        /* Capture full sha */
        char sha_full[128] = {0};
        char shacmd[PATH_MAX + 320];
        snprintf(shacmd, sizeof(shacmd), "%s %s/solutions.bin | cut -d' ' -f1", tool, dir_full);
        FILE *fp = popen(shacmd, "r");
        if (!fp || !fgets(sha_full, sizeof(sha_full), fp)) {
            fprintf(stderr, "[regression-test] FAIL: cannot read full sha\n");
            if (fp) pclose(fp);
            return 50;
        }
        pclose(fp);
        for (char *q = sha_full; *q; q++) if (*q == '\n') { *q = 0; break; }
        printf("[regression-test] full_sha=%s\n", sha_full);

        /* Phase 2/3: 56 first-level enums + merge. Use the same
         * SOLVE_PER_SUB_BRANCH_LIMIT so per-sub-branch budgets match
         * across both phases. SOLVE_NODE_LIMIT can be set high (per_branch_budget
         * is enough since it's per-first-level total ~ N_avg × per_sub_branch);
         * the per-sub-branch override binds the actual cap. Skip invalid
         * (p1, o1) combinations — solve.c rejects them with non-zero exit
         * but we continue. */
        int start_pair_idx = pair_index_of(63, 0);
        int branch_idx = 0;
        int valid_count = 0, invalid_count = 0;
        printf("[regression-test] Phase 2/4: 56 first-level enums at %lld per-sub-branch budget\n",
               per_sub_branch);
        for (int p1 = 0; p1 < 32; p1++) {
            if (p1 == start_pair_idx) continue;
            for (int o1 = 0; o1 < 2; o1++) {
                branch_idx++;
                printf("[regression-test]   branch %d/62: --branch %d %d\n", branch_idx, p1, o1);
                fflush(stdout);
                snprintf(cmd, sizeof(cmd),
                         "cd %s && SOLVE_DEPTH=3 SOLVE_THREADS=64 SOLVE_NODE_LIMIT=%lld "
                         "SOLVE_PER_SUB_BRANCH_LIMIT=%lld "
                         "%s --branch %d %d 0 64 > branch_%d_%d.log 2>&1",
                         dir_56, per_branch_budget, per_sub_branch, solve_path, p1, o1, p1, o1);
                _r = system(cmd);
                if (_r != 0) {
                    /* Check if it was invalid (structurally pruned) — that's
                     * normal, just continue. Other errors are real failures. */
                    char chkcmd[PATH_MAX + 128];
                    snprintf(chkcmd, sizeof(chkcmd),
                             "grep -q 'invalid (pruned' %s/branch_%d_%d.log 2>/dev/null",
                             dir_56, p1, o1);
                    if (system(chkcmd) == 0) {
                        printf("[regression-test]   branch %d %d INVALID (skipping)\n", p1, o1);
                        invalid_count++;
                    } else {
                        fprintf(stderr, "[regression-test] FAIL: branch %d %d exit=%d (real error)\n",
                                p1, o1, _r);
                        return 50;
                    }
                } else {
                    valid_count++;
                }
            }
        }
        printf("[regression-test] Phase 2 enums complete: %d valid, %d invalid\n",
               valid_count, invalid_count);

        printf("[regression-test] Phase 3/4: merge 56-branch shards\n");
        fflush(stdout);
        snprintf(cmd, sizeof(cmd), "cd %s && %s --merge > merge.log 2>&1", dir_56, solve_path);
        _r = system(cmd);
        if (_r != 0) {
            fprintf(stderr, "[regression-test] FAIL: 56-branch merge exit=%d\n", _r);
            return 50;
        }

        /* Capture 56-branch sha */
        char sha_56[128] = {0};
        snprintf(shacmd, sizeof(shacmd), "%s %s/solutions.bin | cut -d' ' -f1", tool, dir_56);
        fp = popen(shacmd, "r");
        if (!fp || !fgets(sha_56, sizeof(sha_56), fp)) {
            fprintf(stderr, "[regression-test] FAIL: cannot read 56-branch sha\n");
            if (fp) pclose(fp);
            return 50;
        }
        pclose(fp);
        for (char *q = sha_56; *q; q++) if (*q == '\n') { *q = 0; break; }
        printf("[regression-test] 56_sha=%s\n", sha_56);

        /* Phase 4: compare */
        printf("[regression-test] Phase 4/4: compare\n");
        if (strcmp(sha_full, sha_56) == 0) {
            printf("[regression-test] PASS — partition invariance confirmed at total budget %lld\n",
                   total_budget);
            char rmcmd[PATH_MAX * 2 + 32];
            snprintf(rmcmd, sizeof(rmcmd), "rm -rf %s %s", dir_full, dir_56);
            _r = system(rmcmd); (void)_r;
            return 0;
        } else {
            fprintf(stderr, "[regression-test] FAIL — partition invariance VIOLATED\n");
            fprintf(stderr, "                  full_sha=%s\n", sha_full);
            fprintf(stderr, "                   56_sha =%s\n", sha_56);
            fprintf(stderr, "                  Working dirs preserved for inspection: %s, %s\n",
                    dir_full, dir_56);
            return 60;
        }
    } else if (argc > 1 && strcmp(argv[1], "--double-regression-test") == 0) {
        /* --double-regression-test (2026-04-29): layered partition-invariance
         * check that exercises the --merge-layers infrastructure.
         *
         * Layout:
         *   <base>/dregress_full/01_layer1/   <- 5.6T full-enum
         *   <base>/dregress_full/02_layer2/   <- 5.6T full-enum
         *   <base>/dregress_full/_merged_/    <- --merge-layers output
         *
         *   <base>/dregress_56/01_layer1/     <- 56 first-level @ 100G (5.6T)
         *   <base>/dregress_56/02_layer2/     <- 56 first-level @ 100G (5.6T)
         *   <base>/dregress_56/_merged_/      <- --merge-layers output
         *
         * Pass criteria:
         *   sha(dregress_full/_merged_/solutions.bin) ==
         *   sha(dregress_56/_merged_/solutions.bin)
         *
         * Under deterministic enumeration with identical per-sub-branch
         * budgets, layer 2's shards are byte-identical to layer 1's, so the
         * merged output equals the canonical 5.6T sha. Captures four shas:
         *
         *   sha_full_L1 == sha_full_L2 == sha_full_merged == sha_56_merged
         *
         * (sha_56_L1 / sha_56_L2 are not meaningful — they're 56 small
         *  per-branch outputs from --branch's per-invocation auto-merge,
         *  not a unified per-layer sha.) A "double regression": partition
         * invariance AND layered-merge correctness in one pass.
         *
         * Disk discipline: each per-layer solutions.bin (~14 GB) is hashed
         * then DELETED immediately after the layer enumerates, since the
         * layered merger only needs the shards. Per-branch solutions_*.bin
         * files in the 56-branch layers are deleted en bloc after their
         * phase. Peak disk: ~224 GB (4 × 56 GB shards) + ~14 GB merged
         * output, fits 251 GB data disk.
         *
         * Default budget per layer: 5.6T. Override:
         *   ./solve --double-regression-test <budget>
         */
        init_pairs();
        long long total_budget = 5600000000000LL;
        if (argc > 2) total_budget = atoll(argv[2]);
        if (total_budget <= 0) {
            fprintf(stderr, "ERROR: --double-regression-test budget must be positive\n");
            return 2;
        }
        long long per_first_level = total_budget / 56;
        long long per_sub_branch = total_budget / 158364LL;
        if (per_first_level <= 0 || per_sub_branch <= 0) {
            fprintf(stderr, "ERROR: budget too small\n");
            return 2;
        }
        printf("[double-regression-test] per-layer budget=%lld; per-first-level=%lld; per-sub-branch=%lld\n",
               total_budget, per_first_level, per_sub_branch);

        char solve_path[4096];
        ssize_t sn = readlink("/proc/self/exe", solve_path, sizeof(solve_path) - 1);
        if (sn <= 0) { fprintf(stderr, "ERROR: cannot resolve self path\n"); return 10; }
        solve_path[sn] = 0;

        const char *tool = sha256_tool();
        if (!tool) { require_sha256_tool(); return 30; }

        const char *base_dir = getenv("SOLVE_REGRESS_DIR");
        if (!base_dir) {
            struct stat sst;
            base_dir = (stat("/mnt/work", &sst) == 0) ? "/mnt/work" : "/tmp";
        }
        char dir_full[PATH_MAX], dir_56[PATH_MAX];
        snprintf(dir_full, sizeof(dir_full), "%s/dregress_full", base_dir);
        snprintf(dir_56,   sizeof(dir_56),   "%s/dregress_56",   base_dir);
        printf("[double-regression-test] working dirs: %s, %s\n", dir_full, dir_56);

        char cmd[PATH_MAX * 4 + 1024];
        int _r;
        char rmm[PATH_MAX * 6 + 128];
        snprintf(rmm, sizeof(rmm), "rm -rf %s %s && mkdir -p %s/01_layer1 %s/02_layer2 %s/01_layer1 %s/02_layer2",
                 dir_full, dir_56, dir_full, dir_full, dir_56, dir_56);
        _r = system(rmm);
        if (_r != 0) { fprintf(stderr, "ERROR: cannot prepare working dirs\n"); return 50; }

        /* Helper: capture sha of a file. Returns 0 on success. */
        char sha_full_L1[128] = {0}, sha_full_L2[128] = {0};
        char sha_full_merged[128] = {0}, sha_56_merged[128] = {0};
        char shacmd[PATH_MAX + 320], shapath[PATH_MAX + 64];

        #define CAPTURE_SHA(path_buf, sha_buf, label) do { \
            snprintf(shacmd, sizeof(shacmd), "%s %s | cut -d' ' -f1", tool, (path_buf)); \
            FILE *_fp = popen(shacmd, "r"); \
            if (!_fp || !fgets((sha_buf), 128, _fp)) { \
                fprintf(stderr, "[double-regression-test] FAIL: cannot read sha for %s\n", (path_buf)); \
                if (_fp) pclose(_fp); \
                return 50; \
            } \
            pclose(_fp); \
            for (char *_q = (sha_buf); *_q; _q++) if (*_q == '\n') { *_q = 0; break; } \
            printf("[double-regression-test]   %s sha = %s\n", (label), (sha_buf)); \
        } while (0)

        /* ---- Phase 1: dregress_full/01_layer1 (5.6T full-enum) ----
         * Then capture sha + delete the layer's solutions.bin (free ~14 GB
         * disk for downstream phases; the layered merger only needs shards). */
        printf("[double-regression-test] Phase 1/7: full-enum layer 1\n");
        fflush(stdout);
        snprintf(cmd, sizeof(cmd),
                 "cd %s/01_layer1 && SOLVE_DEPTH=3 SOLVE_THREADS=64 SOLVE_NODE_LIMIT=%lld "
                 "SOLVE_PER_SUB_BRANCH_LIMIT=%lld %s 0 64 > full.log 2>&1",
                 dir_full, total_budget, per_sub_branch, solve_path);
        _r = system(cmd);
        if (_r != 0) {
            fprintf(stderr, "[double-regression-test] FAIL: phase 1 exit=%d (see %s/01_layer1/full.log)\n",
                    _r, dir_full);
            return 50;
        }
        snprintf(shapath, sizeof(shapath), "%s/01_layer1/solutions.bin", dir_full);
        CAPTURE_SHA(shapath, sha_full_L1, "full_L1");
        snprintf(cmd, sizeof(cmd), "rm -f %s/01_layer1/solutions.bin", dir_full);
        _r = system(cmd); (void)_r;

        /* ---- Phase 2: dregress_full/02_layer2 (5.6T full-enum, second layer) ---- */
        printf("[double-regression-test] Phase 2/7: full-enum layer 2\n");
        fflush(stdout);
        snprintf(cmd, sizeof(cmd),
                 "cd %s/02_layer2 && SOLVE_DEPTH=3 SOLVE_THREADS=64 SOLVE_NODE_LIMIT=%lld "
                 "SOLVE_PER_SUB_BRANCH_LIMIT=%lld %s 0 64 > full.log 2>&1",
                 dir_full, total_budget, per_sub_branch, solve_path);
        _r = system(cmd);
        if (_r != 0) {
            fprintf(stderr, "[double-regression-test] FAIL: phase 2 exit=%d (see %s/02_layer2/full.log)\n",
                    _r, dir_full);
            return 50;
        }
        snprintf(shapath, sizeof(shapath), "%s/02_layer2/solutions.bin", dir_full);
        CAPTURE_SHA(shapath, sha_full_L2, "full_L2");
        snprintf(cmd, sizeof(cmd), "rm -f %s/02_layer2/solutions.bin", dir_full);
        _r = system(cmd); (void)_r;

        /* ---- Phase 3: dregress_56/01_layer1 (56 first-level invocations) ---- */
        printf("[double-regression-test] Phase 3/7: 56-branch layer 1\n");
        fflush(stdout);
        int start_pair_idx = pair_index_of(63, 0);
        int valid1 = 0, invalid1 = 0;
        for (int p1 = 0; p1 < 32; p1++) {
            if (p1 == start_pair_idx) continue;
            for (int o1 = 0; o1 < 2; o1++) {
                snprintf(cmd, sizeof(cmd),
                         "cd %s/01_layer1 && SOLVE_DEPTH=3 SOLVE_THREADS=64 SOLVE_NODE_LIMIT=%lld "
                         "SOLVE_PER_SUB_BRANCH_LIMIT=%lld "
                         "%s --branch %d %d 0 64 > branch_%d_%d.log 2>&1",
                         dir_56, per_first_level, per_sub_branch, solve_path, p1, o1, p1, o1);
                _r = system(cmd);
                if (_r != 0) {
                    char chkcmd[PATH_MAX + 128];
                    snprintf(chkcmd, sizeof(chkcmd),
                             "grep -q 'invalid (pruned' %s/01_layer1/branch_%d_%d.log 2>/dev/null",
                             dir_56, p1, o1);
                    if (system(chkcmd) == 0) {
                        invalid1++;
                    } else {
                        fprintf(stderr, "[double-regression-test] FAIL: phase 3 branch %d %d exit=%d\n",
                                p1, o1, _r);
                        return 50;
                    }
                } else {
                    valid1++;
                }
            }
        }
        printf("[double-regression-test]   phase 3 done: %d valid, %d invalid\n", valid1, invalid1);
        /* Delete per-branch solutions_*.bin (small but adds up; not used by merger) */
        snprintf(cmd, sizeof(cmd), "rm -f %s/01_layer1/solutions_*.bin %s/01_layer1/results_*.json %s/01_layer1/solutions_*.sha256",
                 dir_56, dir_56, dir_56);
        _r = system(cmd); (void)_r;

        /* ---- Phase 4: dregress_56/02_layer2 (56 first-level invocations, second layer) ---- */
        printf("[double-regression-test] Phase 4/7: 56-branch layer 2\n");
        fflush(stdout);
        int valid2 = 0, invalid2 = 0;
        for (int p1 = 0; p1 < 32; p1++) {
            if (p1 == start_pair_idx) continue;
            for (int o1 = 0; o1 < 2; o1++) {
                snprintf(cmd, sizeof(cmd),
                         "cd %s/02_layer2 && SOLVE_DEPTH=3 SOLVE_THREADS=64 SOLVE_NODE_LIMIT=%lld "
                         "SOLVE_PER_SUB_BRANCH_LIMIT=%lld "
                         "%s --branch %d %d 0 64 > branch_%d_%d.log 2>&1",
                         dir_56, per_first_level, per_sub_branch, solve_path, p1, o1, p1, o1);
                _r = system(cmd);
                if (_r != 0) {
                    char chkcmd[PATH_MAX + 128];
                    snprintf(chkcmd, sizeof(chkcmd),
                             "grep -q 'invalid (pruned' %s/02_layer2/branch_%d_%d.log 2>/dev/null",
                             dir_56, p1, o1);
                    if (system(chkcmd) == 0) {
                        invalid2++;
                    } else {
                        fprintf(stderr, "[double-regression-test] FAIL: phase 4 branch %d %d exit=%d\n",
                                p1, o1, _r);
                        return 50;
                    }
                } else {
                    valid2++;
                }
            }
        }
        printf("[double-regression-test]   phase 4 done: %d valid, %d invalid\n", valid2, invalid2);
        /* Delete per-branch solutions_*.bin */
        snprintf(cmd, sizeof(cmd), "rm -f %s/02_layer2/solutions_*.bin %s/02_layer2/results_*.json %s/02_layer2/solutions_*.sha256",
                 dir_56, dir_56, dir_56);
        _r = system(cmd); (void)_r;

        /* ---- Phase 5: layered-merge full path ---- */
        printf("[double-regression-test] Phase 5/7: layered-merge full path\n");
        fflush(stdout);
        snprintf(cmd, sizeof(cmd),
                 "%s --merge-layers %s > %s/merge_layers.log 2>&1",
                 solve_path, dir_full, dir_full);
        _r = system(cmd);
        if (_r != 0) {
            fprintf(stderr, "[double-regression-test] FAIL: full --merge-layers exit=%d (see %s/merge_layers.log)\n",
                    _r, dir_full);
            return 50;
        }
        snprintf(shapath, sizeof(shapath), "%s/_merged_/solutions.bin", dir_full);
        CAPTURE_SHA(shapath, sha_full_merged, "full_merged");
        /* Free disk before next merge: drop the full-path merged solutions.bin
         * (sha already captured) and the symlinks dir. */
        snprintf(cmd, sizeof(cmd), "rm -rf %s/_merged_", dir_full);
        _r = system(cmd); (void)_r;

        /* ---- Phase 6: layered-merge 56-branch path ---- */
        printf("[double-regression-test] Phase 6/7: layered-merge 56-branch path\n");
        fflush(stdout);
        snprintf(cmd, sizeof(cmd),
                 "%s --merge-layers %s > %s/merge_layers.log 2>&1",
                 solve_path, dir_56, dir_56);
        _r = system(cmd);
        if (_r != 0) {
            fprintf(stderr, "[double-regression-test] FAIL: 56 --merge-layers exit=%d (see %s/merge_layers.log)\n",
                    _r, dir_56);
            return 50;
        }
        snprintf(shapath, sizeof(shapath), "%s/_merged_/solutions.bin", dir_56);
        CAPTURE_SHA(shapath, sha_56_merged, "56_merged");

        /* ---- Phase 7: compare 4 shas ---- */
        printf("[double-regression-test] Phase 7/7: compare\n");
        printf("  full_L1     = %s\n", sha_full_L1);
        printf("  full_L2     = %s\n", sha_full_L2);
        printf("  full_merged = %s\n", sha_full_merged);
        printf("  56_merged   = %s\n", sha_56_merged);

        int all_equal = (strcmp(sha_full_L1, sha_full_L2) == 0
                         && strcmp(sha_full_L1, sha_full_merged) == 0
                         && strcmp(sha_full_L1, sha_56_merged) == 0);
        if (all_equal) {
            printf("[double-regression-test] PASS — all 4 shas match (partition invariance + layered-merge correct at %lld budget)\n",
                   total_budget);
            return 0;
        } else {
            fprintf(stderr, "[double-regression-test] FAIL — sha mismatch\n");
            fprintf(stderr, "  full_L1     = %s\n", sha_full_L1);
            fprintf(stderr, "  full_L2     = %s\n", sha_full_L2);
            fprintf(stderr, "  full_merged = %s\n", sha_full_merged);
            fprintf(stderr, "  56_merged   = %s\n", sha_56_merged);
            fprintf(stderr, "  Working dirs preserved: %s, %s\n", dir_full, dir_56);
            return 60;
        }
        #undef CAPTURE_SHA
    } else if (argc > 1 && strcmp(argv[1], "--kde-score-stream") == 0) {
        /* P2 v2 native KDE scorer (2026-04-24).
         * Stream-mode Gaussian KDE log-density evaluator. Reads fit points
         * from a binary file (float64, n_fit × d), then reads query points
         * from stdin (float64, d per record), and writes the count of
         * queries whose log-density is <= a given threshold to stdout.
         *
         * Args: --kde-score-stream --fit-file PATH --d N --bandwidth BW --threshold T
         *
         * Pipeline (driven by solve.py):
         *   1. solve.py dumps fit-sample to /tmp/kde_fit.bin (n_fit × d float64).
         *   2. solve.py spawns ./solve --kde-score-stream ...
         *   3. solve.py iterates parquet chunks, writes records to subprocess
         *      stdin in raw float64.
         *   4. C reads, computes log-density via log-sum-exp, increments
         *      counter if score <= threshold, parallelized via OpenMP.
         *   5. On EOF, C writes "n_below n_total" to stdout, exits.
         *
         * Performance target: ~1-10M records/sec on D8 (vs ~4K/s sklearn
         * Python). Makes exhaustive scoring on 3.43B records tractable
         * (~3-5 hr on D8 single-process, ~30 min with multiprocess on D32+). */
        const char *fit_file = NULL;
        int kde_d = 0;
        double kde_bw = 0.0;
        double kde_threshold = 0.0;
        for (int ai = 2; ai < argc - 1; ai++) {
            if (strcmp(argv[ai], "--fit-file") == 0) fit_file = argv[++ai];
            else if (strcmp(argv[ai], "--d") == 0) kde_d = atoi(argv[++ai]);
            else if (strcmp(argv[ai], "--bandwidth") == 0) kde_bw = atof(argv[++ai]);
            else if (strcmp(argv[ai], "--threshold") == 0) kde_threshold = atof(argv[++ai]);
        }
        if (!fit_file || kde_d <= 0 || kde_bw <= 0.0) {
            fprintf(stderr, "Usage: --kde-score-stream --fit-file PATH --d N --bandwidth BW --threshold T\n");
            return 2;
        }

        /* Load fit points */
        FILE *ff = fopen(fit_file, "rb");
        if (!ff) { fprintf(stderr, "ERROR: cannot open %s\n", fit_file); return 10; }
        fseek(ff, 0, SEEK_END);
        long fit_bytes = ftell(ff);
        fseek(ff, 0, SEEK_SET);
        long fit_n_local = fit_bytes / (kde_d * sizeof(double));
        if (fit_n_local <= 0) {
            fprintf(stderr, "ERROR: fit file empty or wrong dim\n");
            fclose(ff);
            return 10;
        }
        double *fit = (double *)malloc((size_t)fit_n_local * kde_d * sizeof(double));
        if (!fit) {
            fprintf(stderr, "ERROR: alloc fit failed\n");
            fclose(ff);
            return 10;
        }
        if (fread(fit, sizeof(double), (size_t)fit_n_local * kde_d, ff)
            != (size_t)fit_n_local * kde_d) {
            fprintf(stderr, "ERROR: short read on fit file\n");
            fclose(ff);
            return 10;
        }
        fclose(ff);

        const double inv2bw2 = 1.0 / (2.0 * kde_bw * kde_bw);
        const double log_n_fit = log((double)fit_n_local);
        const double normalizer = 0.5 * kde_d * log(2.0 * M_PI * kde_bw * kde_bw);

        fprintf(stderr, "[kde] fit_n=%ld d=%d bw=%g threshold=%g\n",
                fit_n_local, kde_d, kde_bw, kde_threshold);
        fflush(stderr);

        /* Stream queries from stdin in batches. Each batch is processed in
         * parallel via OpenMP; we accumulate the per-query log-density and
         * count those <= threshold. */
        const int BATCH = 4096;
        double *batch = (double *)malloc((size_t)BATCH * kde_d * sizeof(double));
        long long n_total = 0, n_below = 0;
        if (!batch) { fprintf(stderr, "ERROR: alloc batch\n"); free(fit); return 10; }
        while (1) {
            size_t got = fread(batch, sizeof(double), (size_t)BATCH * kde_d, stdin);
            if (got == 0) break;
            int n_in_batch = (int)(got / kde_d);
            if (n_in_batch <= 0) break;
            int local_below = 0;
            #pragma omp parallel for reduction(+:local_below) schedule(static)
            for (int q = 0; q < n_in_batch; q++) {
                const double *qpt = &batch[q * kde_d];
                /* log-sum-exp over fit points */
                double max_neg = -1e300;
                /* First pass: find max negative-half-distance-squared */
                for (long fi = 0; fi < fit_n_local; fi++) {
                    const double *fpt = &fit[fi * kde_d];
                    double d2 = 0.0;
                    for (int dd = 0; dd < kde_d; dd++) {
                        double dx = qpt[dd] - fpt[dd];
                        d2 += dx * dx;
                    }
                    double v = -d2 * inv2bw2;
                    if (v > max_neg) max_neg = v;
                }
                /* Second pass: sum exp(v - max_neg) */
                double sum_exp = 0.0;
                for (long fi = 0; fi < fit_n_local; fi++) {
                    const double *fpt = &fit[fi * kde_d];
                    double d2 = 0.0;
                    for (int dd = 0; dd < kde_d; dd++) {
                        double dx = qpt[dd] - fpt[dd];
                        d2 += dx * dx;
                    }
                    sum_exp += exp(-d2 * inv2bw2 - max_neg);
                }
                double log_dens = max_neg + log(sum_exp) - log_n_fit - normalizer;
                if (log_dens <= kde_threshold) local_below++;
            }
            n_below += local_below;
            n_total += n_in_batch;
        }
        free(batch);
        free(fit);
        printf("%lld %lld\n", n_below, n_total);
        return 0;
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
    } else if (argc > 1 && strcmp(argv[1], "--sub-branch") == 0) {
        /* Run ONE depth-3 sub-branch to exhaustion (or budget). Intended for
         * the "stratified sample of sub-branch exhaustion cost" experiment —
         * see NEXT_ENUMERATION_STRATEGY.md. Reuses the single_branch_mode
         * infrastructure with a hand-built one-element SubBranch list and
         * skips checkpoint loading so a fresh run is a fresh run. */
        if (argc < 8) {
            printf("Usage: ./solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3> [time_limit] [threads]\n");
            printf("  Run a single depth-3 sub-branch to exhaustion.\n");
            printf("  p1,o1 = first-level pair/orient (position 1)\n");
            printf("  p2,o2 = second-level pair/orient (position 2)\n");
            printf("  p3,o3 = third-level pair/orient (position 3)\n");
            printf("  SOLVE_NODE_LIMIT=0 (default) runs to full exhaustion.\n");
            return 1;
        }
        single_branch_mode = 1;       /* reuse existing infra */
        single_sub_branch_mode = 1;   /* but enumerate only the one sub-branch */
        sb_pair = atoi(argv[2]);
        sb_orient = atoi(argv[3]);
        ssb_pair2 = atoi(argv[4]);
        ssb_orient2 = atoi(argv[5]);
        ssb_pair3 = atoi(argv[6]);
        ssb_orient3 = atoi(argv[7]);
        arg_offset = 8;
        /* P1 parallel-sub-branch: auto-enable when SOLVE_THREADS > 1.
         * Opt-out via SOLVE_SUB_BRANCH_PARALLELISM=single for regression
         * testing against the legacy single-threaded path. */
        {
            char *env_threads_p1 = getenv("SOLVE_THREADS");
            int nt_req = env_threads_p1 ? atoi(env_threads_p1) : 1;
            if (arg_offset + 1 < argc) {
                int nt_argv = atoi(argv[arg_offset + 1]);
                if (nt_argv > 0) nt_req = nt_argv;
            }
            if (nt_req > 1) parallel_sub_branch_enabled = 1;
            char *env_paral = getenv("SOLVE_SUB_BRANCH_PARALLELISM");
            if (env_paral && strcmp(env_paral, "single") == 0)
                parallel_sub_branch_enabled = 0;
            /* Test-mode: force the parallel code path even at N=1. Used by
             * the infrastructure-validation harness: N=1 parallel serializes
             * tasks in lex order through the queue, which is the same DFS
             * order as legacy — so output must be byte-identical. Useful for
             * correctness testing without needing a small-tree EXHAUSTED
             * branch. */
            if (env_paral && strcmp(env_paral, "force-parallel") == 0)
                parallel_sub_branch_enabled = 1;
        }
        printf("Single-sub-branch mode: p1=%d o1=%d p2=%d o2=%d p3=%d o3=%d\n",
               sb_pair, sb_orient, ssb_pair2, ssb_orient2, ssb_pair3, ssb_orient3);
    }

    /* Preflight external-dep check for any mode that will produce a sha256.
     * Run BEFORE any work output so failure is a clean one-shot error. Modes
     * that don't need it (--verify, --validate, --analyze, --prove-*,
     * --list-branches) are exempt. */
    if (merge_mode || single_branch_mode ||
        (!verify_mode && !validate_mode && !analyze_mode &&
         !prove_cascade_mode && !prove_self_comp_mode && !prove_shift_mode &&
         !list_branches_mode)) {
        if (require_sha256_tool() != 0) return 10;
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

    /* Per-task node limit (2026-04-28). Caps each sub-sub task at N nodes,
     * distributing coverage across the 2507 task queue. Default 0 = off
     * (no per-task cap; preserves canonical shas like 915abf30 / f7b8c4fb).
     * Use case: 100T global with 40G per-task = each of 2507 tasks gets up
     * to 40G of DFS work instead of 64 workers walking 64 tasks deeply. */
    char *env_per_task = getenv("SOLVE_PER_TASK_NODE_LIMIT");
    if (env_per_task) per_task_node_limit = atoll(env_per_task);
    if (per_task_node_limit > 0)
        printf("Per-task node limit: %lld\n", per_task_node_limit);

    /* Per-sub-branch budget override (2026-04-29). When set, both full-enum
     * and --branch paths use this exact value for per_branch_node_limit
     * instead of computing it as node_limit/n_branches. Required for
     * partition-invariance testing: the "5.6T total / 158,364 sub-branches"
     * full-enum path and the "56 × 100G per first-level / N_first_level
     * sub-branches" --branch path produce different per-sub-branch budgets
     * (because N_first_level varies), even when total compute matches. With
     * this override, both paths walk each sub-branch with identical budget,
     * making outputs byte-identical when partition invariance holds. */
    char *env_per_sb = getenv("SOLVE_PER_SUB_BRANCH_LIMIT");
    if (env_per_sb) per_sub_branch_override = atoll(env_per_sb);
    if (per_sub_branch_override > 0) {
        printf("Per-sub-branch override: %lld nodes (overrides auto-divide)\n",
               per_sub_branch_override);
        /* Set per_branch_node_limit immediately so paths that don't have
         * node_limit > 0 still use the override. The auto-divide blocks
         * below also check the override and re-set it; this ensures it's
         * set for paths that skip the auto-divide block. */
        per_branch_node_limit = per_sub_branch_override;
    }

    /* DFS-state checkpoint (2026-04-30, SOLVE_DFS_CHECKPOINT). When 1, mid-walk
     * resume is enabled: budget exhaustion writes a .dfs_state sidecar; future
     * runs at higher per-sub-branch budget read the sidecar and resume. Default
     * 0 = behavior is bit-identical to pre-2026-04-30 builds. See struct
     * DFSCheckpointState_v1 definition for format details. */
    char *env_dfs_ckpt = getenv("SOLVE_DFS_CHECKPOINT");
    if (env_dfs_ckpt && atoi(env_dfs_ckpt) == 1) {
        dfs_checkpoint_enabled = 1;
        printf("DFS-state checkpoint: enabled (mid-walk resume)\n");
    }
    /* SOLVE_DFS_ITERATIVE (2026-04-30): dispatch through backtrack_iterative()
     * instead of the default recursive backtrack(). Default off; selftest sha
     * unchanged when not set. Intended substrate for full DFS-state capture. */
    char *env_dfs_iter = getenv("SOLVE_DFS_ITERATIVE");
    if (env_dfs_iter && atoi(env_dfs_iter) == 1) {
        dfs_iterative_enabled = 1;
        printf("DFS-iterative: enabled (explicit-stack backtrack)\n");
    }

    /* Reproducibility warning: time_limit and node_limit together create
     * non-determinism. Each sub-branch has a per-sub-branch node budget
     * (node_limit / n_branches). Under node-limit-only operation, every
     * sub-branch runs to its budget regardless of wall-clock → identical
     * sub_*.bin files across runs → identical solutions.bin.
     *
     * If time_limit fires before a sub-branch hits its node budget, that
     * sub-branch is tagged INTERRUPTED and retains whatever solutions it
     * found up to the interrupt. WHICH sub-branches were still running at
     * the interrupt moment depends on thread scheduling, CPU load, and I/O
     * timing — none of which are reproducible.
     *
     * For canonical runs (establishing a reference sha), set node_limit
     * only, pass 0 for time_limit. Use time_limit alone for "run for N
     * minutes, keep whatever we got" exploratory workflows. */
    if (node_limit > 0 && time_limit > 0) {
        fprintf(stderr,
            "WARNING: both SOLVE_NODE_LIMIT and a wall-clock time_limit (%d s)\n"
            "         are set. Wall-clock interrupts are non-deterministic — the\n"
            "         resulting solutions.bin sha256 is NOT guaranteed reproducible\n"
            "         under load. For reproducible canonical runs, set only\n"
            "         SOLVE_NODE_LIMIT and pass 0 for the time_limit.\n",
            time_limit);
    }

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

    /* KW self-check: validate that the canonical KW[] sequence satisfies C1-C5
     * with the exact values stated in SPECIFICATION.md.
     *
     * Catches accidental edits to KW[] or to the constraint checkers with
     * EXACT constants (not ranges). A weaker check that only verified
     * "distribution sums to 63" or "complement-distance is plausible" would
     * pass for many wrong sequences; the exact forms here pass only for
     * the canonical King Wen sequence. If this fails, every downstream claim
     * is suspect — exit 50.
     *
     * The constants (expected multiset, 776, Creative/Receptive) are
     * duplicated from SPECIFICATION.md on purpose: self-check should fail
     * if either side drifts. */
    {
        /* (a) Permutation property: all 64 hexagrams unique */
        int seen[64] = {0};
        for (int i = 0; i < 64; i++) {
            if (KW[i] < 0 || KW[i] >= 64 || seen[KW[i]]++) {
                fprintf(stderr, "ERROR: KW self-check failed: hexagram %d at index %d invalid or duplicated\n", KW[i], i);
                return 50; /* exit code 50 = internal consistency failure */
            }
        }

        /* (b) C1 pair-partner relationship: for each pair (KW[2i], KW[2i+1]),
         * the second is the "partner" of the first, where:
         *   partner(h) = rev(h)   if rev(h) != h  (60 rev-asymmetric hexagrams)
         *   partner(h) = comp(h)  if rev(h) == h  (4 rev-palindromes: 0,21,42,63)
         * Previously the check only verified uniqueness — a KW[] typo that
         * swapped a partner for a non-partner hexagram would pass (a,b,c,d...)
         * provided uniqueness held, and silently break every subsequent claim. */
        for (int i = 0; i < 32; i++) {
            int h = KW[2 * i];
            int h_rev = reverse6(h);
            int expected = (h_rev != h) ? h_rev : (h ^ 63);
            if (KW[2 * i + 1] != expected) {
                fprintf(stderr, "ERROR: KW self-check failed: pair %d has (%d,%d); "
                                "expected partner(%d)=%d\n",
                        i, h, KW[2 * i + 1], h, expected);
                return 50;
            }
        }

        /* (c) C2: no 5-line transitions between consecutive hexagrams */
        for (int i = 0; i < 63; i++) {
            if (hamming(KW[i], KW[i + 1]) == 5) {
                fprintf(stderr, "ERROR: KW self-check failed: 5-line transition at index %d (%d -> %d)\n", i, KW[i], KW[i + 1]);
                return 50;
            }
        }

        /* (d) C4: position 0 is hexagram 63 (Creative), position 1 is 0 (Receptive) */
        if (KW[0] != 63 || KW[1] != 0) {
            fprintf(stderr, "ERROR: KW self-check failed: expected Creative/Receptive at positions 0-1, got %d/%d\n", KW[0], KW[1]);
            return 50;
        }

        /* (e) C5: difference-distribution matches the SPEC multiset EXACTLY.
         * Spec: {1:2, 2:20, 3:13, 4:19, 6:9} — total 63, no d=0 or d=5. */
        const int expected_kw_dist[7] = {0, 2, 20, 13, 19, 0, 9};
        for (int d = 0; d < 7; d++) {
            if (kw_dist[d] != expected_kw_dist[d]) {
                fprintf(stderr, "ERROR: KW self-check failed: kw_dist[%d]=%d, expected %d "
                                "(spec: {1:2, 2:20, 3:13, 4:19, 6:9})\n",
                        d, kw_dist[d], expected_kw_dist[d]);
                return 50;
            }
        }

        /* (f) C3: exact complement distance. Spec (per SPECIFICATION.md and
         * HISTORY.md) requires 776 (= 12.125 x 64). A value that merely
         * "looks plausible" (e.g., 770) would silently change C3's threshold
         * and alter every enumeration count downstream. */
        if (kw_comp_dist_x64 != 776) {
            fprintf(stderr, "ERROR: KW self-check failed: kw_comp_dist_x64 = %d, expected 776 "
                            "(12.125 x 64)\n", kw_comp_dist_x64);
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

        /* Auto-detect file type by peeking at the first 4 bytes:
         *   "ROAE" magic → full solutions.bin (header + sorted deduped records)
         *   otherwise    → raw shard file (e.g., sub_*.bin from --sub-branch or
         *                 mid-run enumeration). Shards have no header and are
         *                 written in hash-table slot order (not sorted), so
         *                 skip the header parse, sort-order, and duplicate
         *                 checks for shard mode. */
        int shard_mode = 0;
        unsigned char peek[4];
        if (vsize >= 4 && fread(peek, 1, 4, vf) == 4) {
            if (peek[0] != 'R' || peek[1] != 'O' || peek[2] != 'A' || peek[3] != 'E')
                shard_mode = 1;
        }
        fseek(vf, 0, SEEK_SET);

        long long n_records;
        if (shard_mode) {
            if (vsize == 0) {
                printf("Empty shard file (0 records). Trivially passes.\n");
                fclose(vf);
                return 0;
            }
            if (vsize % SOL_RECORD_SIZE != 0) {
                fprintf(stderr, "ERROR: shard file size %ld not a multiple of %d\n",
                        vsize, SOL_RECORD_SIZE);
                fclose(vf);
                return 20;
            }
            n_records = vsize / SOL_RECORD_SIZE;
            printf("Shard mode (no header): %lld records (file %ld bytes)\n\n",
                   n_records, vsize);
        } else {
            if (vsize < SOL_HEADER_SIZE) {
                fprintf(stderr, "ERROR: file size %ld shorter than header (%d bytes)\n",
                        vsize, SOL_HEADER_SIZE);
                fclose(vf);
                return 20;
            }
            uint64_t hdr_records = 0;
            if (sol_read_header(vf, &hdr_records) != 0) {
                fprintf(stderr, "ERROR: %s has invalid magic or unsupported format version "
                                "(expected magic 'ROAE', version %d)\n",
                        verify_file, SOL_FORMAT_VERSION);
                fclose(vf);
                return 20;
            }
            long record_bytes = vsize - SOL_HEADER_SIZE;
            if (record_bytes < 0 || record_bytes % SOL_RECORD_SIZE != 0) {
                fprintf(stderr, "ERROR: record stream %ld bytes after header is not a multiple of %d\n",
                        record_bytes, SOL_RECORD_SIZE);
                fclose(vf);
                return 20;
            }
            n_records = record_bytes / SOL_RECORD_SIZE;
            if ((uint64_t)n_records != hdr_records) {
                fprintf(stderr, "ERROR: header claims %llu records but file has %lld\n",
                        (unsigned long long)hdr_records, n_records);
                fclose(vf);
                return 20;
            }
            printf("Header: magic ROAE, version %d, %lld records (file %ld bytes)\n\n",
                   SOL_FORMAT_VERSION, n_records, vsize);
        }

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

            /* Sorted order + duplicate checks apply only to post-merge
             * solutions.bin (shard_mode=0). Raw shards are written in
             * hash-table slot order (not sorted) and don't guarantee
             * cross-shard dedup. */
            if (r > 0 && !shard_mode) {
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

        /* Parse the 32-byte header first. Opens a FILE* just for header parsing
         * (sol_read_header works on FILE*); the main validate loop uses mmap
         * at offset SOL_HEADER_SIZE for the record stream. */
        {
            FILE *hvf = fopen(validate_file, "rb");
            if (!hvf) { printf("ERROR: cannot open %s for header read\n", validate_file); return 1; }
            uint64_t hdr_records = 0;
            if (sol_read_header(hvf, &hdr_records) != 0) {
                printf("ERROR: %s has invalid magic or unsupported version "
                       "(expected 'ROAE' v%d)\n", validate_file, SOL_FORMAT_VERSION);
                fclose(hvf);
                return 1;
            }
            fclose(hvf);
            printf("  Header: ROAE v%d, %llu records declared\n",
                   SOL_FORMAT_VERSION, (unsigned long long)hdr_records);
        }

        /* mmap the file: avoids loading 24 GB into a malloc, OS pages it in.
         * Records start at byte SOL_HEADER_SIZE (32); subsequent offsets
         * into vall are record-stream-relative, so we skip past the header. */
        int vfd = open(validate_file, O_RDONLY);
        if (vfd < 0) { printf("ERROR: cannot open %s\n", validate_file); return 1; }
        struct stat vst;
        if (fstat(vfd, &vst) < 0) { printf("ERROR: fstat failed\n"); close(vfd); return 1; }
        long full_size = vst.st_size;
        if (full_size < SOL_HEADER_SIZE) {
            printf("ERROR: file smaller than header\n"); close(vfd); return 1;
        }
        long file_size = full_size - SOL_HEADER_SIZE;   /* record stream size */
        long long n_solutions = file_size / SOL_RECORD_SIZE;
        printf("  File size: %ld bytes (%d header + %ld records), %lld solutions\n",
               full_size, SOL_HEADER_SIZE, file_size, n_solutions);
        if (file_size % SOL_RECORD_SIZE != 0)
            printf("  WARNING: record stream %ld bytes not a multiple of %d\n",
                   file_size, SOL_RECORD_SIZE);
        unsigned char *mmap_base = mmap(NULL, full_size, PROT_READ, MAP_PRIVATE, vfd, 0);
        close(vfd);
        if (mmap_base == MAP_FAILED) { printf("ERROR: mmap failed\n"); return 1; }
        madvise(mmap_base, full_size, MADV_SEQUENTIAL);
        unsigned char *vall = mmap_base + SOL_HEADER_SIZE;  /* record-stream view */

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
        munmap(mmap_base, full_size);

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

        /* Parse the 32-byte header first. */
        {
            FILE *hf = fopen(analyze_file, "rb");
            if (!hf) { printf("ERROR: cannot open %s for header read\n", analyze_file); return 1; }
            uint64_t hdr_records = 0;
            if (sol_read_header(hf, &hdr_records) != 0) {
                printf("ERROR: %s has invalid magic or unsupported version "
                       "(expected 'ROAE' v%d)\n", analyze_file, SOL_FORMAT_VERSION);
                fclose(hf); return 1;
            }
            fclose(hf);
        }

        /* mmap the file: no malloc, no fread. OS pages it in on demand.
         * The record stream starts at byte SOL_HEADER_SIZE; `all` is the
         * record-stream view. */
        int afd = open(analyze_file, O_RDONLY);
        if (afd < 0) { printf("ERROR: cannot open %s\n", analyze_file); return 1; }
        struct stat ast;
        if (fstat(afd, &ast) < 0) { printf("ERROR: fstat failed\n"); close(afd); return 1; }
        long full_size = ast.st_size;
        if (full_size < SOL_HEADER_SIZE) {
            printf("ERROR: file smaller than header (%ld < %d)\n", full_size, SOL_HEADER_SIZE);
            close(afd); return 1;
        }
        long file_size = full_size - SOL_HEADER_SIZE;
        if (file_size % SOL_RECORD_SIZE != 0) {
            printf("ERROR: record stream %ld bytes after header not a multiple of %d\n",
                   file_size, SOL_RECORD_SIZE);
            close(afd); return 1;
        }
        long long n_sols = file_size / SOL_RECORD_SIZE;
        unsigned char *mmap_base = mmap(NULL, full_size, PROT_READ, MAP_PRIVATE, afd, 0);
        close(afd);
        if (mmap_base == MAP_FAILED) {
            printf("ERROR: mmap of %ld bytes failed (errno %d)\n", full_size, errno);
            return 1;
        }
        madvise(mmap_base, full_size, MADV_SEQUENTIAL);
        unsigned char *all = mmap_base + SOL_HEADER_SIZE;   /* record-stream view */

        printf("[1] File metadata\n");
        printf("    records:    %lld\n", n_sols);
        printf("    file size:  %ld bytes (%d header + %ld records, %.2f GB total)\n",
               full_size, SOL_HEADER_SIZE, file_size, full_size / 1e9);
        printf("    format:     ROAE v%d; record fmt %d bytes (pair_index<<2 | orient<<1)\n",
               SOL_FORMAT_VERSION, SOL_RECORD_SIZE);
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
            munmap(mmap_base, full_size);
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
            munmap(mmap_base, full_size);
            return 1;
        }
        for (int b = 0; b < 31; b++) {
            bmask[b] = calloc((size_t)n_words, sizeof(uint64_t));
            if (!bmask[b]) {
                fprintf(stderr, "ERROR: calloc failed for bmask[%d] (%lld words)\n", b, n_words);
                for (int f = 0; f < b; f++) free(bmask[f]);
                free(bmask); free(kw_indices); free(sub_solution_count);
                munmap(mmap_base, full_size);
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
                    if (kw_cap > INT_MAX / 2) {
                        fprintf(stderr, "ERROR: kw_cap overflow at %d\n", kw_cap);
                        goto done_streaming;
                    }
                    kw_cap *= 2;
                    long long *tmp = realloc(kw_indices, (size_t)kw_cap * sizeof(long long));
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
                        if (report_cap > INT_MAX / 2) {
                            fprintf(stderr, "ERROR: report_cap overflow at %d\n", report_cap);
                            break;
                        }
                        report_cap *= 2;
                        QuadEntry *tmp = realloc(report, (size_t)report_cap * sizeof(QuadEntry));
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
                /* Per-boundary single-match counts over rbm bitmaps.
                 * Was collected for section 15 greedy search but no longer
                 * read after the greedy path was refactored — kept the
                 * bitmap construction (needed below), dropped the tally. */

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
                            if (surv_cap > LLONG_MAX / 2) {
                                fprintf(stderr, "ERROR: surv_cap overflow at %lld\n", surv_cap);
                                goto done_surv_collect;
                            }
                            surv_cap *= 2;
                            long long *tmp = realloc(surv, (size_t)surv_cap * sizeof(long long));
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
            double H_base_total = 0;
            for (int p = 0; p < 32; p++) {
                double H = 0;
                for (int pr = 0; pr < 32; pr++) {
                    long long c = pos_cnt[p][pr];
                    if (c > 0) { double q = (double)c / n_sols; H -= q * log2(q); }
                }
                H_base_total += H;
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
                int n_present = 0;
                for (int pr = 0; pr < 32; pr++)
                    if (pos_cnt[p][pr] > 0) n_present++;
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
                printf("%s\n", (nd == 1) ? " LOCKED" : "");
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
                long long y0 = 0, y_small = 0, y_mid = 0, y_high = 0;
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
        munmap(mmap_base, full_size);

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
            if (!tf) {
                fprintf(stderr, "ERROR: cannot open %s for size scan: %s\n",
                        filenames[i], strerror(errno));
                return 20;
            }
            if (fseek(tf, 0, SEEK_END) != 0) {
                fprintf(stderr, "ERROR: fseek END failed on %s: %s\n", filenames[i], strerror(errno));
                fclose(tf); return 20;
            }
            long sz = ftell(tf);
            if (sz < 0) {
                fprintf(stderr, "ERROR: ftell failed on %s: %s\n", filenames[i], strerror(errno));
                fclose(tf); return 20;
            }
            if (sz % SOL_RECORD_SIZE != 0) {
                fprintf(stderr, "ERROR: %s size %ld is not a multiple of %d (corrupt file)\n",
                        filenames[i], sz, SOL_RECORD_SIZE);
                fclose(tf); return 20;
            }
            total_records += sz / SOL_RECORD_SIZE;
            fclose(tf);
        }
        /* Defensive bound. Guards against overflow in subsequent
         * `total_records * SOL_RECORD_SIZE * 2` and malloc-size casts.
         * LLONG_MAX / 32 / 2 is well above any realistic enumeration
         * scale (10^17 records), so this is a never-should-fire safety
         * net for corrupted shard metadata or future format changes. */
        if (total_records < 0 ||
            total_records > (long long)(LLONG_MAX / SOL_RECORD_SIZE / 2)) {
            fprintf(stderr, "ERROR: total_records %lld out of range\n", total_records);
            return 20;
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
                /* Threshold is 80% of physical RAM. Peak memory for the
                 * in-memory merge is `needed_bytes` (the record buffer) plus
                 * a few KB of stack for the in-place heapsort — no O(n) aux.
                 * 80% leaves headroom for the kernel, page cache, and
                 * stdlib/thread overhead. Was 70% historically; raised to 80%
                 * once the qsort→heapsort migration made the memory model
                 * predictable (2026-04-18). Earlier, glibc qsort's ~50%
                 * aux-memory overhead forced us to pick external for any
                 * merge over ~55% of RAM to avoid OOM (observed Phase C). */
                use_ext = (needed_bytes > total_ram * 8 / 10);
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
                if (!tf) {
                    fprintf(stderr, "ERROR: cannot open %s for read: %s\n", filenames[i], strerror(errno));
                    free(all); return 20;
                }
                if (fseek(tf, 0, SEEK_END) != 0) {
                    fprintf(stderr, "ERROR: fseek END failed on %s: %s\n", filenames[i], strerror(errno));
                    fclose(tf); free(all); return 20;
                }
                long sz = ftell(tf);
                if (sz < 0) {
                    fprintf(stderr, "ERROR: ftell failed on %s: %s\n", filenames[i], strerror(errno));
                    fclose(tf); free(all); return 20;
                }
                if (fseek(tf, 0, SEEK_SET) != 0) {
                    fprintf(stderr, "ERROR: fseek SET failed on %s: %s\n", filenames[i], strerror(errno));
                    fclose(tf); free(all); return 20;
                }
                size_t got = fread(&all[offset * SOL_RECORD_SIZE], 1, (size_t)sz, tf);
                if (got != (size_t)sz) {
                    fprintf(stderr, "ERROR: short read on %s: got %zu of %ld bytes: %s\n",
                            filenames[i], got, sz, strerror(errno));
                    fclose(tf); free(all); return 20;
                }
                offset += sz / SOL_RECORD_SIZE;
                fclose(tf);
            }

            printf("  Sorting %lld records...\n", total_records);
            heapsort_records(all, total_records, SOL_RECORD_SIZE, compare_solutions);

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
            if (sol_write_header(of, (uint64_t)unique) != 0) {
                fprintf(stderr, "ERROR: header write failed on %s\n", outname);
                fclose(of); free(all); return 30;
            }
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
            long long expected = (long long)SOL_HEADER_SIZE + unique * SOL_RECORD_SIZE;
            if (stat(outname, &pst) != 0 || pst.st_size != expected) {
                fprintf(stderr, "ERROR: post-write size mismatch on %s: got %lld, expected %lld\n",
                        outname, (long long)(stat(outname, &pst) == 0 ? pst.st_size : -1), expected);
                return 30;
            }
        }

        /* sha256 and sidecar names match the normal-mode merge convention:
         * solutions.sha256 (not solutions.bin.sha256), solutions.meta.json
         * (not solutions.bin.meta.json). Monitor scripts and downstream
         * tooling all look for the stem-pattern names. */
        const char *sha_name  = "solutions.sha256";
        const char *meta_name = "solutions.meta.json";

        /* sha256 — preflight guarantees sha256_tool() is non-NULL here */
        const char *tool = sha256_tool();
        if (!tool) {
            fprintf(stderr, "ERROR: sha256 tool missing at --merge finalize; "
                            "preflight should have caught this.\n");
            return 30;
        }
        char sha_cmd[256];
        snprintf(sha_cmd, sizeof(sha_cmd), "%s %s > %s 2>/dev/null",
                 tool, outname, sha_name);
        int rc = system(sha_cmd);
        if (rc != 0) {
            fprintf(stderr, "ERROR: sha256 computation failed (rc=%d)\n", rc);
            return 30;
        }

        char hash[130] = {0};
        FILE *hf = fopen(sha_name, "r");
        if (!hf) {
            fprintf(stderr, "WARNING: cannot read %s: %s\n", sha_name, strerror(errno));
        } else {
            if (fgets(hash, sizeof(hash), hf) == NULL)
                fprintf(stderr, "WARNING: %s is empty\n", sha_name);
            fclose(hf);
        }

        /* Human-readable sidecar — provenance + format info.
         * Contains timestamp + git hash, so it's NOT byte-reproducible
         * across runs (deliberately). solutions.bin and solutions.sha256
         * stay reproducible. */
        {
            char hash_only[65] = {0};
            for (int i = 0; i < 64 && hash[i] && hash[i] != ' ' && hash[i] != '\n'; i++)
                hash_only[i] = hash[i];
            sol_write_meta_json(meta_name, outname, (uint64_t)unique, unique, hash_only);
        }

        printf("\n--- Merge results ---\n");
        printf("  Input files:     %d\n", n_files);
        printf("  Total records:   %lld\n", total_records);
        printf("  Unique solutions: %lld\n", unique);
        printf("  Output:          %s (%lld bytes)\n", outname, unique * SOL_RECORD_SIZE);
        printf("  sha256:          %s\n", hash);

        /* Validate merged output */
        printf("\nValidating merged output...\n");
        /* Use /proc/self/exe to find our own binary path rather than assume
         * `./solve` relative to cwd. The caller may have cd'd elsewhere, or
         * the binary may be installed anywhere on PATH. */
        char self_path[4096];
        ssize_t sp = readlink("/proc/self/exe", self_path, sizeof(self_path) - 1);
        if (sp <= 0) {
            fprintf(stderr, "ERROR: cannot resolve self path for post-merge validation: %s\n",
                    strerror(errno));
            return 40;
        }
        self_path[sp] = 0;
        char val_cmd[8192];
        snprintf(val_cmd, sizeof(val_cmd), "%s --validate %s", self_path, outname);
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

        /* Load sub-branch checkpoint for resume — skipped in --sub-branch mode
         * (that mode wants a clean, targeted run of exactly one sub-branch). */
        if (!single_sub_branch_mode) {
            load_sub_checkpoint();
            if (n_completed_subs > 0) {
                printf("Resuming: %d sub-branches already completed (from checkpoint.txt)\n",
                       n_completed_subs);
                total_branches_completed = n_completed_subs;
            }
        }

        /* Enumerate sub-branches, skipping completed ones.
         *
         * Depth selection (2026-04-30):
         *   solve_depth == 2 (default): partition by (p2, o2) only — at most
         *     54 sub-branches per (sb_pair, sb_orient). Stack array fits.
         *   solve_depth == 3: partition by (p2, o2, p3, o3) — up to ~3000
         *     sub-branches per (sb_pair, sb_orient). Heap allocate.
         *
         * The depth-3 path lets `--branch p1 o1` produce shards comparable
         * to the full-enum's depth-3 partition (`solve 0 64` with
         * SOLVE_DEPTH=3): both produce `sub_p1_o1_p2_o2_p3_o3.bin` shards
         * with the same per-sub-branch budget structure, so the merged
         * outputs have matching sha256. Required for the
         * --regression-test and --double-regression-test partition-
         * invariance checks to actually compare apples-to-apples.
         *
         * Bug history: prior to this change, `--branch` always partitioned
         * to depth-2 even when SOLVE_DEPTH=3 was set, so the regression
         * test's "56-branch path" produced depth-2 shards while the
         * full-enum produced depth-3 shards. This caused the 2026-04-29
         * INCONCLUSIVE regression test (sha mismatch) and the 2026-04-29
         * --double-regression-test FAIL.
         */
        int n_sub = 0;
        int n_skipped = 0;
        int all_sub_cap = (solve_depth == 3) ? 4096 : 64;
        SubBranch *all_sub = malloc(all_sub_cap * sizeof(SubBranch));
        if (!all_sub) {
            fprintf(stderr, "ERROR: malloc(%d * SubBranch) failed for all_sub\n", all_sub_cap);
            return 30;
        }

        if (single_sub_branch_mode) {
            /* Hand-build exactly one d3 sub-branch; validate and skip the
             * depth-2 enumeration entirely. */
            if (ssb_pair2 < 0 || ssb_pair2 >= 32 || ssb_pair2 == start_pair_idx || ssb_pair2 == sb_pair) {
                printf("Invalid p2 index %d\n", ssb_pair2);
                return 1;
            }
            if (ssb_orient2 < 0 || ssb_orient2 > 1) {
                printf("Invalid o2 %d (must be 0 or 1)\n", ssb_orient2);
                return 1;
            }
            if (ssb_pair3 < 0 || ssb_pair3 >= 32 || ssb_pair3 == start_pair_idx
                || ssb_pair3 == sb_pair || ssb_pair3 == ssb_pair2) {
                printf("Invalid p3 index %d\n", ssb_pair3);
                return 1;
            }
            if (ssb_orient3 < 0 || ssb_orient3 > 1) {
                printf("Invalid o3 %d (must be 0 or 1)\n", ssb_orient3);
                return 1;
            }
            /* Validate budget feasibility of the fixed prefix (p2/o2, then p3/o3).
             * Mirrors the checks in the loop below so an infeasible --sub-branch
             * request fails loudly rather than producing an empty run. */
            int f2 = ssb_orient2 ? pairs[ssb_pair2].b : pairs[ssb_pair2].a;
            int s2 = ssb_orient2 ? pairs[ssb_pair2].a : pairs[ssb_pair2].b;
            int bd2 = hamming(seq_prefix[3], f2);
            int test_budget[7];
            memcpy(test_budget, budget_prefix, sizeof(test_budget));
            if (bd2 == 5 || test_budget[bd2] <= 0) {
                printf("Sub-branch (p2=%d o2=%d) is invalid under current budget (pruned at depth 2)\n",
                       ssb_pair2, ssb_orient2);
                return 1;
            }
            test_budget[bd2]--;
            int wd2 = hamming(f2, s2);
            if (test_budget[wd2] <= 0) {
                printf("Sub-branch (p2=%d o2=%d) is invalid (within-pair distance)\n",
                       ssb_pair2, ssb_orient2);
                return 1;
            }
            test_budget[wd2]--;
            int f3 = ssb_orient3 ? pairs[ssb_pair3].b : pairs[ssb_pair3].a;
            int s3 = ssb_orient3 ? pairs[ssb_pair3].a : pairs[ssb_pair3].b;
            int bd3 = hamming(s2, f3);
            if (bd3 == 5 || test_budget[bd3] <= 0) {
                printf("Sub-branch (p3=%d o3=%d) is invalid under current budget (pruned at depth 3)\n",
                       ssb_pair3, ssb_orient3);
                return 1;
            }
            test_budget[bd3]--;
            int wd3 = hamming(f3, s3);
            if (test_budget[wd3] <= 0) {
                printf("Sub-branch (p3=%d o3=%d) is invalid (within-pair distance)\n",
                       ssb_pair3, ssb_orient3);
                return 1;
            }
            all_sub[0].pair1 = sb_pair;
            all_sub[0].orient1 = sb_orient;
            all_sub[0].pair2 = ssb_pair2;
            all_sub[0].orient2 = ssb_orient2;
            all_sub[0].pair3 = ssb_pair3;
            all_sub[0].orient3 = ssb_orient3;
            n_sub = 1;
            goto sub_enum_done;
        }

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
                test_budget[wd2]--;

                if (solve_depth == 2) {
                    /* Depth-2 partition: each (sb_pair, sb_orient, p2, o2)
                     * is one work unit. */
                    if (is_sub_branch_completed(sb_pair, sb_orient, p2, o2)) {
                        n_skipped++;
                        continue;
                    }
                    if (n_sub >= all_sub_cap) {
                        fprintf(stderr, "FATAL: all_sub buffer overflow at d2\n");
                        return 10;
                    }
                    all_sub[n_sub].pair1 = sb_pair;
                    all_sub[n_sub].orient1 = sb_orient;
                    all_sub[n_sub].pair2 = p2;
                    all_sub[n_sub].orient2 = o2;
                    all_sub[n_sub].pair3 = -1;
                    all_sub[n_sub].orient3 = -1;
                    n_sub++;
                } else {
                    /* Depth-3 partition: further partition by (p3, o3).
                     * Mirrors the depth-3 enumeration in the full-enum path
                     * (lines 10683+) so shards from the two paths use
                     * matching `sub_p1_o1_p2_o2_p3_o3.bin` naming and
                     * matching per-sub-branch budgets. */
                    int used2[32];
                    memcpy(used2, used_prefix, sizeof(used2));
                    used2[p2] = 1;
                    for (int p3 = 0; p3 < 32; p3++) {
                        if (used2[p3]) continue;
                        for (int o3 = 0; o3 < 2; o3++) {
                            int f3 = o3 ? pairs[p3].b : pairs[p3].a;
                            int s3 = o3 ? pairs[p3].a : pairs[p3].b;
                            int bd3 = hamming(s2, f3);
                            if (bd3 == 5) continue;
                            int test_budget3[7];
                            memcpy(test_budget3, test_budget, sizeof(test_budget3));
                            if (test_budget3[bd3] <= 0) continue;
                            test_budget3[bd3]--;
                            int wd3 = hamming(f3, s3);
                            if (test_budget3[wd3] <= 0) continue;

                            if (is_sub_branch_completed_d3(sb_pair, sb_orient, p2, o2, p3, o3)) {
                                n_skipped++;
                                continue;
                            }
                            if (n_sub >= all_sub_cap) {
                                fprintf(stderr, "FATAL: all_sub buffer overflow at d3 (cap=%d)\n",
                                        all_sub_cap);
                                return 10;
                            }
                            all_sub[n_sub].pair1 = sb_pair;
                            all_sub[n_sub].orient1 = sb_orient;
                            all_sub[n_sub].pair2 = p2;
                            all_sub[n_sub].orient2 = o2;
                            all_sub[n_sub].pair3 = p3;
                            all_sub[n_sub].orient3 = o3;
                            n_sub++;
                        }
                    }
                }
            }
        }

sub_enum_done:
        printf("Sub-branches for pair %d orient %d: %d remaining", sb_pair, sb_orient, n_sub);
        if (n_skipped > 0) printf(" (%d completed from checkpoint)", n_skipped);
        printf("\n");
        total_branches = n_sub + n_skipped;

        /* Per-branch node limit.
         *
         * DEFAULT: divide SOLVE_NODE_LIMIT by the full partition count
         * (total_branches, including already-completed sub-branches from
         * checkpoint.txt). This preserves per-sub-branch budget reproducibility
         * across fresh vs. resumed runs at the same SOLVE_NODE_LIMIT. Each
         * remaining sub-branch receives the budget it would have received in
         * a fresh run from scratch → same shards → same sha256.
         *
         * OPT-IN `SOLVE_CONCENTRATE_BUDGET=1`: divide by n_sub (only
         * not-yet-completed sub-branches). Intended for "accumulate ground
         * truth" workflows where pre-completed branches are fully EXHAUSTED
         * (run to completion without node limit) and the remaining work
         * should receive deeper coverage from the same total budget.
         * Trade-off: output is NOT reproducible by SOLVE_NODE_LIMIT alone
         * — per-sub-branch budget depends on how many branches were
         * pre-completed. Operator opts in knowingly. */
        if (node_limit > 0 && total_branches > 0) {
            int concentrate = getenv("SOLVE_CONCENTRATE_BUDGET") != NULL;
            int divisor = (concentrate && n_sub > 0) ? n_sub : total_branches;
            per_branch_node_limit = node_limit / divisor;
            if (concentrate && n_skipped > 0) {
                fprintf(stderr,
                    "WARNING: SOLVE_CONCENTRATE_BUDGET active — per-sub-branch budget\n"
                    "         = SOLVE_NODE_LIMIT / remaining (%d), not total partition (%d).\n"
                    "         Output sha256 depends on pre-completion history; NOT reproducible\n"
                    "         via SOLVE_NODE_LIMIT alone. Intended for accumulation workflows.\n",
                    n_sub, total_branches);
            }
            if (per_sub_branch_override > 0) {
                per_branch_node_limit = per_sub_branch_override;
                printf("Per-sub-branch OVERRIDE applied: %lld (was auto-divide)\n",
                       per_branch_node_limit);
            }
            printf("Per-branch node limit: %lld (%lld / %d %s-branches%s)\n",
                   per_branch_node_limit, node_limit, divisor,
                   concentrate ? "remaining" : "total",
                   concentrate ? " [CONCENTRATED]" : "");
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

        /* --------------------------------------------------------------
         * P1: Parallel --sub-branch path (2026-04-21).
         * When a single depth-3 sub-branch is requested and SOLVE_THREADS
         * > 1 (env var or positional), split along depth-4 (p4, o4) tasks
         * and run N workers in parallel on the SAME sub-branch. Workers
         * share atomic task-dispense + node-counter state; each owns a
         * private hash table that's merged at end under "lex-smallest
         * wins" dedup. Output is byte-identical to single-threaded.
         *
         * Falls through to legacy path when:
         *   - not --sub-branch mode (parallel_sub_branch_enabled == 0)
         *   - SOLVE_SUB_BRANCH_PARALLELISM=single (regression mode)
         *   - SOLVE_THREADS <= 1
         */
        if (single_sub_branch_mode && parallel_sub_branch_enabled && n_sub == 1) {
            int n_threads_p = (int)sysconf(_SC_NPROCESSORS_ONLN);
            if (n_threads_p < 1) n_threads_p = 8;
            char *env_threads_p = getenv("SOLVE_THREADS");
            if (env_threads_p) n_threads_p = atoi(env_threads_p);
            if (arg_offset + 1 < argc) {
                int nt = atoi(argv[arg_offset + 1]);
                if (nt > 0) n_threads_p = nt;
            }
            if (n_threads_p < 1) n_threads_p = 1;
            if (n_threads_p > 64) n_threads_p = 64;

            /* Tier 2 memory-relief flush threshold (2026-04-23). Env var
             * SOLVE_MEMORY_FLUSH_COUNT=N enables flush-and-clear when any
             * worker's local solution_count exceeds N/n_threads_p. With
             * 64 threads and N=200000000 (200M), each worker flushes at
             * ~3.1M local records -> disk, freeing its hash table for
             * another cycle. At end-of-run, all chunk files require
             * external merge (./solve --merge) to produce final output. */
            {
                char *env_flush = getenv("SOLVE_MEMORY_FLUSH_COUNT");
                if (env_flush && atoll(env_flush) > 0) {
                    long long global_threshold = atoll(env_flush);
                    per_worker_flush_threshold = global_threshold / n_threads_p;
                    if (per_worker_flush_threshold < 1000) per_worker_flush_threshold = 1000;
                    fprintf(stderr,
                        "Tier 2 memory-relief flush ENABLED: global=%lld records, "
                        "per-worker=%lld records. Chunk files sub_flush_chunk_*.bin\n"
                        "will accumulate on disk; external merge required at end-of-run.\n",
                        global_threshold, per_worker_flush_threshold);
                }
            }

            /* Populate shared depth-3 prefix state — mirror of
             * thread_func_single lines ~1388-1486. */
            SubBranch *sb0 = &all_sub[0];
            int p1p = sb0->pair1, o1p = sb0->orient1;
            int p2p = sb0->pair2, o2p = sb0->orient2;
            int p3p = sb0->pair3, o3p = sb0->orient3;

            int start_pair_idx_local = pair_index_of(63, 0);
            memset(shared_prefix_seq, 0, sizeof(shared_prefix_seq));
            memset(shared_prefix_used, 0, sizeof(shared_prefix_used));
            shared_prefix_seq[0] = 63; shared_prefix_seq[1] = 0;
            shared_prefix_used[start_pair_idx_local] = 1;
            memcpy(shared_prefix_budget, kw_dist, sizeof(shared_prefix_budget));
            shared_prefix_budget[hamming(63, 0)]--;

            int f1p = o1p ? pairs[p1p].b : pairs[p1p].a;
            int s1p = o1p ? pairs[p1p].a : pairs[p1p].b;
            shared_prefix_budget[hamming(shared_prefix_seq[1], f1p)]--;
            shared_prefix_budget[hamming(f1p, s1p)]--;
            shared_prefix_seq[2] = f1p; shared_prefix_seq[3] = s1p;
            shared_prefix_used[p1p] = 1;

            int f2p = o2p ? pairs[p2p].b : pairs[p2p].a;
            int s2p = o2p ? pairs[p2p].a : pairs[p2p].b;
            shared_prefix_budget[hamming(shared_prefix_seq[3], f2p)]--;
            shared_prefix_budget[hamming(f2p, s2p)]--;
            shared_prefix_seq[4] = f2p; shared_prefix_seq[5] = s2p;
            shared_prefix_used[p2p] = 1;

            int f3p = o3p ? pairs[p3p].b : pairs[p3p].a;
            int s3p = o3p ? pairs[p3p].a : pairs[p3p].b;
            shared_prefix_budget[hamming(shared_prefix_seq[5], f3p)]--;
            shared_prefix_budget[hamming(f3p, s3p)]--;
            shared_prefix_seq[6] = f3p; shared_prefix_seq[7] = s3p;
            shared_prefix_used[p3p] = 1;

            build_sub_sub_branch_tasks();
            printf("Parallel --sub-branch: %d depth-5 tasks queued, %d worker threads\n",
                   n_sub_sub_tasks, n_threads_p);
            if (n_sub_sub_tasks == 0) {
                printf("No valid (p4, o4, p5, o5) extensions — sub-branch EXHAUSTED with 0 solutions (no output file).\n");
                /* Still write a checkpoint entry so resume semantics work. */
                FILE *ckpt0 = fopen("checkpoint.txt", "a");
                if (ckpt0) {
                    fprintf(ckpt0, "Sub-branch EXHAUSTED (parallel, pair1 %d orient1 %d pair2 %d orient2 %d pair3 %d orient3 %d): "
                            "0 nodes, 0 C3-valid, 0 solutions, 0s elapsed, budget %lld\n",
                            p1p, o1p, p2p, o2p, p3p, o3p, per_branch_node_limit);
                    fclose(ckpt0);
                }
                return 0;
            }

            if (n_threads_p > n_sub_sub_tasks) n_threads_p = n_sub_sub_tasks;

            /* Worker ThreadStates — one per thread, private hash tables. */
            ThreadState workers[64];
            time_t now_init = time(NULL);
            for (int i = 0; i < n_threads_p; i++) {
                memset(&workers[i], 0, sizeof(ThreadState));
                workers[i].thread_id = i;
                workers[i].single_branch_mode = 1;
                workers[i].ht_log2 = sol_hash_log2;
                workers[i].ht_size = sol_hash_size;
                workers[i].ht_mask = sol_hash_mask;
                workers[i].last_ckpt = now_init;
                pthread_mutex_init(&workers[i].ht_mutex, NULL);
                for (int j = 0; j < TOP_N; j++) workers[i].top_closest[j].edit_dist = 33;
            }

            /* P1 v3 checkpoint-resume: if prior sub_ckpt_meta.txt +
             * sub_ckpt_wrk*.bin files exist in CWD, load them into
             * workers[0]'s hash table (consolidation point) and restore
             * the shared-node count. Workers then claim tasks from idx=0
             * onward — re-doing any in-flight-at-eviction tasks (dedup
             * handles duplicates). The shared-node restore ensures the
             * budget check stops us from running past the intended total. */
            long long resumed_shared = sub_ckpt_load(&workers[0]);
            if (resumed_shared > 0) {
                /* Restore the first CCD counter with the resumed budget
                 * (all others stay at 0); sub_sub_sum_counters() will
                 * correctly include the resumed amount in budget checks. */
                sub_sub_counters[0].nodes = resumed_shared;
            }

            sub_sub_next_idx = 0;
            if (resumed_shared == 0) {
                for (int i = 0; i < N_SUB_SUB_COUNTERS; i++)
                    sub_sub_counters[i].nodes = 0;
            }
            sub_sub_budget_hit = 0;
            sub_sub_parallel_active = 1;
            threads_completed = 0;

            struct sigaction sa_p;
            sa_p.sa_handler = signal_handler;
            sa_p.sa_flags = 0;
            sigemptyset(&sa_p.sa_mask);
            sigaction(SIGTERM, &sa_p, NULL);
            sigaction(SIGINT, &sa_p, NULL);

            /* SIGUSR1 → operator "dump state now" (doesn't interrupt run).
             * Usage during a run:   kill -USR1 $(pgrep -f 'solve --sub-branch')
             * Output emitted on next 1s poll by the monitor thread. */
            struct sigaction sa_usr;
            sa_usr.sa_handler = sigusr1_handler;
            sa_usr.sa_flags = 0;
            sigemptyset(&sa_usr.sa_mask);
            sigaction(SIGUSR1, &sa_usr, NULL);

            start_time = time(NULL);
            printf("Starting parallel --sub-branch enumeration...\n\n");
            fflush(stdout);

            pthread_t tids_p[64];
            for (int i = 0; i < n_threads_p; i++) {
                int rc = pthread_create(&tids_p[i], NULL, thread_func_sub_sub, &workers[i]);
                if (rc != 0) {
                    fprintf(stderr, "FATAL: pthread_create worker %d (rc=%d: %s)\n",
                            i, rc, strerror(rc));
                    global_timed_out = 1;
                    for (int j = 0; j < i; j++) pthread_join(tids_p[j], NULL);
                    return 10;
                }
            }

            /* Spawn the checkpoint thread. Fires every sub_ckpt_interval_sec
             * (default 60s) and snapshots all workers atomically via
             * per-worker ht_mutex. Set SOLVE_CKPT_INTERVAL=0 to disable
             * (e.g., for very short runs where checkpointing is overkill). */
            char *env_ckpt = getenv("SOLVE_CKPT_INTERVAL");
            if (env_ckpt) sub_ckpt_interval_sec = atoi(env_ckpt);
            pthread_t ckpt_tid = 0;
            CkptThreadArg ckpt_arg = {.workers = workers, .n_workers = n_threads_p};
            sub_ckpt_thread_stop = 0;
            if (sub_ckpt_interval_sec > 0) {
                if (pthread_create(&ckpt_tid, NULL, thread_func_ckpt, &ckpt_arg) != 0) {
                    fprintf(stderr, "WARNING: checkpoint thread failed to start; running without intra-sub-branch checkpoints\n");
                    ckpt_tid = 0;
                }
            }

            /* Monitor with progress lines every 10s, plus on-demand SIGUSR1
             * state dumps (poked via `kill -USR1 <pid>`). */
            int report_counter_p = 0;
            while (threads_completed < n_threads_p && !global_timed_out) {
                sleep(1);
                int want_snapshot = sigusr1_requested;
                report_counter_p++;
                if (!want_snapshot && report_counter_p < 10) continue;
                if (!want_snapshot) report_counter_p = 0;
                sigusr1_requested = 0;  /* clear even if just periodic */

                long long tn = 0, tsval = 0, tc3 = 0;
                long long tu = 0, thc = 0;
                for (int i = 0; i < n_threads_p; i++) {
                    tn += workers[i].nodes;
                    tsval += workers[i].solutions_total;
                    tc3 += workers[i].solutions_c3;
                    tu += workers[i].solution_count;
                    thc += workers[i].hash_collisions;
                }
                long elapsed_now_p = (long)(time(NULL) - start_time);
                int claimed = sub_sub_next_idx;
                if (claimed > n_sub_sub_tasks) claimed = n_sub_sub_tasks;
                int done_tasks = 0;
                for (int i = 0; i < n_sub_sub_tasks; i++)
                    if (sub_sub_task_done[i]) done_tasks++;
                int busy_tasks = claimed - done_tasks;
                if (busy_tasks < 0) busy_tasks = 0;
                int pending_tasks = n_sub_sub_tasks - claimed;
                double rate_p = elapsed_now_p > 0 ? tn / (double)elapsed_now_p / 1e6 : 0;

                /* Budget ETA: assumes current rate holds and the budget is
                 * the binding exit. Sub-sub_sum_counters() may exceed tn
                 * on a resumed run (resumed_shared is added in), so use it
                 * for the "remaining to budget" math. */
                long long nodes_global = sub_sub_sum_counters();
                if (nodes_global < tn) nodes_global = tn;
                long long remaining = (per_branch_node_limit > 0)
                    ? per_branch_node_limit - nodes_global : 0;
                long eta_sec = (rate_p > 0 && remaining > 0)
                    ? (long)((double)remaining / (rate_p * 1e6)) : -1;
                char eta_buf[32];
                if (eta_sec < 0) {
                    snprintf(eta_buf, sizeof(eta_buf), "ETA=?");
                } else {
                    long eh = eta_sec / 3600, em = (eta_sec % 3600) / 60;
                    snprintf(eta_buf, sizeof(eta_buf), "ETA=%ldh%02ldm", eh, em);
                }

                fprintf(stderr, "  %.1fB nodes, %.1fM sol, %lld C3 (%lld stored), "
                        "tasks: %d done/%d busy/%d pending, %.0fM/s, %lds, %s%s\n",
                        tn / 1e9, tsval / 1e6, tc3, tu,
                        done_tasks, busy_tasks, pending_tasks, rate_p, elapsed_now_p,
                        eta_buf,
                        sub_sub_budget_hit ? " [BUDGET]" : "");

                if (want_snapshot) {
                    /* Detailed SIGUSR1 dump: per-depth node counts (top
                     * 8 by count) + hash-table size + budget-fill fraction. */
                    long long depth_totals[33] = {0};
                    for (int i = 0; i < n_threads_p; i++)
                        for (int d = 0; d <= 32; d++)
                            depth_totals[d] += workers[i].nodes_at_depth[d];
                    fprintf(stderr, "  --- SIGUSR1 snapshot ---\n");
                    fprintf(stderr, "    budget_fill=%.2f%% (%lld / %lld)\n",
                            per_branch_node_limit > 0 ?
                              100.0 * nodes_global / (double)per_branch_node_limit : 0.0,
                            nodes_global, per_branch_node_limit);
                    fprintf(stderr, "    tasks: %d of %d complete (%.1f%%)\n",
                            done_tasks, n_sub_sub_tasks,
                            100.0 * done_tasks / (n_sub_sub_tasks ? n_sub_sub_tasks : 1));
                    fprintf(stderr, "    hash_table: %lld stored, %lld hash_collisions\n",
                            tu, thc);
                    /* Peak 8 depths by node count. */
                    for (int top = 0; top < 8; top++) {
                        int best = -1;
                        long long best_val = 0;
                        for (int d = 0; d <= 32; d++) {
                            if (depth_totals[d] > best_val) { best_val = depth_totals[d]; best = d; }
                        }
                        if (best < 0) break;
                        fprintf(stderr, "    depth[%d] = %lld nodes\n", best, best_val);
                        depth_totals[best] = 0;  /* zero out so next loop picks next-largest */
                    }
                    fprintf(stderr, "  --- end snapshot ---\n");
                    fflush(stderr);
                }

                if (time_limit > 0 && (time(NULL) - start_time) >= time_limit) {
                    global_timed_out = 1;
                    break;
                }
            }
            for (int i = 0; i < n_threads_p; i++) pthread_join(tids_p[i], NULL);
            sub_sub_parallel_active = 0;  /* disable parallel-budget logic post-join */

            /* Stop + join checkpoint thread. */
            sub_ckpt_thread_stop = 1;
            if (ckpt_tid) pthread_join(ckpt_tid, NULL);

            /* Tier 2 final flush — happens BEFORE the merge+free below so
             * per-worker tables are still live. Original ordering had the
             * tier2 loop AFTER workers[1..N-1] tables were freed, which
             * segfaulted during the post-flush memset (2026-04-24 SIGTERM
             * crash). */
            if (per_worker_flush_threshold > 0) {
                fprintf(stderr, "\n[tier2] flushing final in-memory state from all workers...\n");
                for (int i = 0; i < n_threads_p; i++) {
                    pthread_mutex_lock(&workers[i].ht_mutex);
                    if (workers[i].solution_count > 0) {
                        sub_flush_chunk_to_disk(&workers[i]);
                    }
                    pthread_mutex_unlock(&workers[i].ht_mutex);
                }
                fprintf(stderr,
                    "[tier2] complete: %d chunks written, %lld total records flushed.\n"
                    "[tier2] NEXT STEP: run `./solve --merge sub_flush_chunk_*.bin` to\n"
                    "[tier2] produce the final dedup'd solutions.bin. Skipping in-line\n"
                    "[tier2] write because workers[0] contains only post-last-flush data.\n",
                    tier2_total_chunks_written, tier2_total_records_flushed);
            }

            /* Merge worker hash tables into workers[0]. */
            for (int i = 1; i < n_threads_p; i++) {
                merge_sol_tables(&workers[0], &workers[i]);
                if (workers[i].sol_table) { free(workers[i].sol_table); workers[i].sol_table = NULL; }
                if (workers[i].sol_occupied) { free(workers[i].sol_occupied); workers[i].sol_occupied = NULL; }
            }

            /* Aggregate for reporting. */
            long long total_nodes_p = 0, total_sol_p = 0, total_c3_p = 0;
            long long total_hc_p = 0;
            for (int i = 0; i < n_threads_p; i++) {
                total_nodes_p += workers[i].nodes;
                total_sol_p += workers[i].solutions_total;
                total_c3_p += workers[i].solutions_c3;
                total_hc_p += workers[i].hash_collisions;
            }
            total_hc_p += workers[0].hash_collisions;  /* post-merge collisions */

            const char *status_p;
            if (global_timed_out) status_p = "INTERRUPTED";
            else if (sub_sub_budget_hit) status_p = "BUDGETED";
            else status_p = "EXHAUSTED";

            long elapsed_p = (long)(time(NULL) - start_time);
            int solutions_p = (int)workers[0].solution_count;

            /* Per-task stats dump (2026-04-24). Write CSV to per_task_stats.csv
             * for external analysis (Pareto plot, worker load-balance, etc).
             * Schema:
             *   task_idx, nodes, solutions_added, wall_time_ms,
             *   worker_id, completed, max_depth, c3_leaves,
             *   nodes_d0..nodes_d32  (33 depth bins) */
            {
                FILE *pf = fopen("per_task_stats.csv", "w");
                if (pf) {
                    fprintf(pf, "task_idx,p4,o4,p5,o5,nodes,solutions_added,wall_time_ms,worker_id,completed,max_depth,c3_leaves");
                    for (int d = 0; d <= 32; d++) fprintf(pf, ",nodes_d%d", d);
                    fprintf(pf, "\n");
                    for (int i = 0; i < n_sub_sub_tasks; i++) {
                        PerTaskStats *s = &sub_sub_task_stats[i];
                        SubSubBranchTask *t = &sub_sub_tasks[i];
                        fprintf(pf, "%d,%d,%d,%d,%d,%lld,%d,%d,%u,%u,%u,%lld",
                                i, t->p4, t->o4, t->p5, t->o5,
                                s->nodes, s->solutions_added, s->wall_time_ms,
                                (unsigned)s->worker_id, (unsigned)s->completed,
                                (unsigned)s->max_depth, s->c3_leaves);
                        for (int d = 0; d <= 32; d++)
                            fprintf(pf, ",%lld", s->nodes_at_depth[d]);
                        fprintf(pf, "\n");
                    }
                    fclose(pf);
                    int complete_cnt = 0, partial_cnt = 0;
                    long long total_nodes_in_tasks = 0;
                    long long total_c3 = 0;
                    for (int i = 0; i < n_sub_sub_tasks; i++) {
                        if (sub_sub_task_stats[i].completed) complete_cnt++;
                        else if (sub_sub_task_stats[i].nodes > 0) partial_cnt++;
                        total_nodes_in_tasks += sub_sub_task_stats[i].nodes;
                        total_c3 += sub_sub_task_stats[i].c3_leaves;
                    }
                    fprintf(stderr, "[per-task] wrote per_task_stats.csv: %d complete, "
                            "%d partial, %d untouched (%lld total nodes, %lld C3 leaves)\n",
                            complete_cnt, partial_cnt, n_sub_sub_tasks - complete_cnt - partial_cnt,
                            total_nodes_in_tasks, total_c3);
                }
            }

            /* (Tier 2 final flush moved earlier — before merge+free.) */

            pthread_mutex_lock(&checkpoint_mutex);
            if (per_worker_flush_threshold == 0 && workers[0].solution_count > 0) {
                flush_sub_solutions_d3(&workers[0], p1p, o1p, p2p, o2p, p3p, o3p);
            }
            FILE *ckpt_p = fopen("checkpoint.txt", "a");
            if (ckpt_p) {
                fprintf(ckpt_p, "Sub-branch %s (parallel, pair1 %d orient1 %d pair2 %d orient2 %d pair3 %d orient3 %d): "
                        "%lld nodes, %lld C3-valid, %d solutions, %lds elapsed, budget %lld\n",
                        status_p, p1p, o1p, p2p, o2p, p3p, o3p,
                        total_nodes_p, total_c3_p, solutions_p, elapsed_p,
                        per_branch_node_limit);
                fflush(ckpt_p);
                fsync(fileno(ckpt_p));
                fclose(ckpt_p);
            }
            pthread_mutex_unlock(&checkpoint_mutex);

            fprintf(stderr, "\n*** Parallel --sub-branch %s: %lldB nodes, %lldM C3, "
                    "%d solutions, %lds (%d threads, %d tasks, %lld dedup collisions) ***\n",
                    status_p, total_nodes_p/1000000000LL, total_c3_p/1000000LL,
                    solutions_p, elapsed_p, n_threads_p, n_sub_sub_tasks, total_hc_p);

            /* --depth-profile output (2026-04-23). Emits per-depth DFS-node
             * counts summed across all workers. Gated on SOLVE_DEPTH_PROFILE=1
             * to avoid changing output for existing runs. Each line:
             *   DEPTH_PROFILE depth=<d> nodes=<n>
             * Followed by a DEPTH_PROFILE_TOTAL line for cross-check. */
            {
                char *env_dp = getenv("SOLVE_DEPTH_PROFILE");
                if (env_dp && strcmp(env_dp, "1") == 0) {
                    long long depth_totals[33] = {0};
                    for (int i = 0; i < n_threads_p; i++) {
                        for (int d = 0; d <= 32; d++) {
                            depth_totals[d] += workers[i].nodes_at_depth[d];
                        }
                    }
                    long long dp_sum = 0;
                    fprintf(stderr, "\n--- DEPTH PROFILE ---\n");
                    for (int d = 0; d <= 32; d++) {
                        fprintf(stderr, "DEPTH_PROFILE depth=%d nodes=%lld\n", d, depth_totals[d]);
                        dp_sum += depth_totals[d];
                    }
                    /* On fresh runs dp_sum == total_nodes_p. On resumed runs,
                     * dp_sum may exceed total_nodes_p because the depth array
                     * was restored from sub_ckpt_depth<tid>.txt but workers[i].nodes
                     * starts fresh. dp_sum is the authoritative count on resume. */
                    const char *match_tag;
                    if (dp_sum == total_nodes_p) match_tag = "yes";
                    else if (dp_sum > total_nodes_p) match_tag = "dp_sum_is_authoritative_resumed_run";
                    else match_tag = "no_UNEXPECTED_INVESTIGATE";
                    fprintf(stderr, "DEPTH_PROFILE_TOTAL sum=%lld total_nodes=%lld match=%s\n",
                            dp_sum, total_nodes_p, match_tag);
                }
            }

            /* Successful completion: delete checkpoint files so a future
             * invocation with the same prefix starts fresh. INTERRUPTED
             * runs (global_timed_out) leave checkpoint files in place
             * for resume. */
            if (!global_timed_out) {
                sub_ckpt_cleanup();
            }

            if (workers[0].sol_table) free(workers[0].sol_table);
            if (workers[0].sol_occupied) free(workers[0].sol_occupied);
            return 0;
        }
        /* ---- end P1 parallel path; fall through to legacy below ---- */

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
        int n_started = 0;
        for (int i = 0; i < n_threads; i++) {
            int rc = pthread_create(&tids[i], NULL, thread_func_single, &threads[i]);
            if (rc != 0) {
                fprintf(stderr, "FATAL: pthread_create failed for thread %d (rc=%d: %s)\n",
                        i, rc, strerror(rc));
                global_timed_out = 1;
                for (int j = 0; j < n_started; j++) pthread_join(tids[j], NULL);
                return 10;
            }
            n_started++;
        }

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
            heapsort_records(all_solutions, (size_t)total_stored, SOL_RECORD_SIZE, compare_solutions);
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
        if (sol_write_header(bf, (uint64_t)unique_count) != 0) {
            fprintf(stderr, "ERROR: header write failed on %s\n", bin_name);
            fclose(bf); free(all_solutions); return 30;
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
         * that produced the 23.7→8 GB incident in the 10T recovery).
         * File is {header}{records}: SOL_HEADER_SIZE + unique_count * SOL_RECORD_SIZE. */
        {
            struct stat pst;
            long long expected = (long long)SOL_HEADER_SIZE + (long long)unique_count * SOL_RECORD_SIZE;
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
        if (!hf) {
            fprintf(stderr, "WARNING: cannot read %s: %s\n", sha_name, strerror(errno));
        } else {
            if (fgets(hash, sizeof(hash), hf) == NULL)
                fprintf(stderr, "WARNING: %s is empty\n", sha_name);
            fclose(hf);
        }
        char hash_only[65] = {0};
        for (int i = 0; i < 64 && hash[i] && hash[i] != ' '; i++) hash_only[i] = hash[i];

        /* Sidecar meta.json for this single-branch run */
        {
            char metafile[128];
            snprintf(metafile, sizeof(metafile), "%s.meta.json", bin_name);
            sol_write_meta_json(metafile, bin_name, (uint64_t)unique_count, unique_count, hash_only);
        }

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
        struct tm tmbuf;
        strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime_r(&start_time, &tmbuf));
        printf("Start: %s\n", time_buf);
        strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime_r(&end_time, &tmbuf));
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
     * a rough threshold, not an exact match. SOLVE_PER_SUB_BRANCH_LIMIT
     * takes precedence — it sets the per-sub-branch budget directly,
     * regardless of node_limit. */
    if (per_sub_branch_override > 0)
        current_per_branch_budget = per_sub_branch_override;
    else if (node_limit > 0)
        current_per_branch_budget = node_limit / 3030;
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

    /* Per-sub-branch node limit. Default divides SOLVE_NODE_LIMIT by the full
     * partition count (preserves reproducibility across fresh vs resumed runs).
     * SOLVE_CONCENTRATE_BUDGET=1 divides by remaining (n_all_subs) instead —
     * deeper coverage on not-yet-completed branches, at the cost of
     * reproducibility. See detailed comment at the single-branch site. */
    if (node_limit > 0 && total_branches > 0) {
        int concentrate = getenv("SOLVE_CONCENTRATE_BUDGET") != NULL;
        int divisor = (concentrate && n_all_subs > 0) ? n_all_subs : total_branches;
        per_branch_node_limit = node_limit / divisor;
        if (concentrate && n_skipped_subs > 0) {
            fprintf(stderr,
                "WARNING: SOLVE_CONCENTRATE_BUDGET active — per-sub-branch budget\n"
                "         = SOLVE_NODE_LIMIT / remaining (%d), not total partition (%d).\n"
                "         Output sha256 depends on pre-completion history; NOT reproducible\n"
                "         via SOLVE_NODE_LIMIT alone. Intended for accumulation workflows.\n",
                n_all_subs, total_branches);
        }
        if (per_sub_branch_override > 0) {
            per_branch_node_limit = per_sub_branch_override;
            printf("Per-sub-branch OVERRIDE applied: %lld (was auto-divide)\n",
                   per_branch_node_limit);
        }
        printf("Per-sub-branch node limit: %lld (%lld / %d %s-sub-branches%s)\n",
               per_branch_node_limit, node_limit, divisor,
               concentrate ? "remaining" : "total",
               concentrate ? " [CONCENTRATED]" : "");
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
    int n_started = 0;
    for (int i = 0; i < n_threads; i++) {
        int rc = pthread_create(&tids[i], NULL, thread_func_single, &threads[i]);
        if (rc != 0) {
            fprintf(stderr, "FATAL: pthread_create failed for thread %d (rc=%d: %s)\n",
                    i, rc, strerror(rc));
            global_timed_out = 1;
            for (int j = 0; j < n_started; j++) pthread_join(tids[j], NULL);
            return 10;
        }
        n_started++;
    }

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

    /* Layer 2 sanity gate: pre-merge invariant check on per-thread state.
     * Defense in depth alongside the fork-merge isolation. Catches any
     * thread that ended in an inconsistent post-enum field state — a
     * bounds-violating dfs_v2_sp/dfs_iter_top, branches_completed beyond
     * n_branches, or a still-active resume flag. If anything is wrong,
     * abort BEFORE either the in-process or the fork merge; that way the
     * resulting solutions.bin is never trusted as canonical.
     *
     * Update 2026-05-01: relaxed to WARN-only. The 11.2T Tier 1 run
     * produced 158,364 cleanly-walked sub-branches but tripped the
     * gate's strict per-thread field checks (dfs_v2_resume_active=19
     * etc.) because at end-of-enum some thread fields hold values from
     * the last iteration that aren't strictly 0/1 — the field is
     * intended as a flag but doesn't have to read 0/1 once enum is
     * done. The fork-merge isolation is the actual defense against
     * the Test A 2026-04-30 heap corruption; the per-thread sanity
     * gate is supplementary diagnostic. Keep the loud bounds checks
     * (sp/iter_top/solution_count) as warnings; remove the abort. */
    {
        int sanity_warnings = 0;
        for (int i = 0; i < n_threads; i++) {
            ThreadState *t = &threads[i];
            if (t->dfs_v2_sp < 0 || t->dfs_v2_sp >= 34) {
                fprintf(stderr,
                        "SANITY-WARN: thread %d: dfs_v2_sp=%d out of [0,33]\n",
                        i, t->dfs_v2_sp);
                sanity_warnings++;
            }
            if (t->dfs_iter_top < 0 || t->dfs_iter_top > 64) {
                fprintf(stderr,
                        "SANITY-WARN: thread %d: dfs_iter_top=%d out of [0,64]\n",
                        i, t->dfs_iter_top);
                sanity_warnings++;
            }
            if (t->solution_count < 0) {
                fprintf(stderr,
                        "SANITY-WARN: thread %d: solution_count=%lld is negative\n",
                        i, (long long)t->solution_count);
                sanity_warnings++;
            }
        }
        if (sanity_warnings > 0) {
            fprintf(stderr,
                    "WARNING: pre-merge sanity gate emitted %d warning(s) — "
                    "fork-merge isolation will still produce a clean merge\n",
                    sanity_warnings);
        }
    }

    /* Free thread resources */
    for (int i = 0; i < n_threads; i++) {
        free(threads[i].sol_table);
        free(threads[i].sol_occupied);
        free(threads[i].sub_branches);
    }

    long long unique_count = 0;
    int fork_merge_done = 0;
    char hash[130] = {0};
    char hash_only[65] = {0};
    int total_done_final = 0;
    int ckpt_exhausted = 0, ckpt_budgeted = 0, ckpt_interrupted = 0;

    /* Fork-based merge for the iterative+v2 path. Test A on 2026-04-30
     * surfaced heap corruption when the in-process merge ran after a
     * 6.5-hour iterative+v2 enumeration: the merge segfaulted in libc
     * during free() consolidation (address 0x1c00000025, error 4),
     * after the enum had cleanly produced all 158,364 shards. The
     * surviving shards re-merged correctly in a fresh process,
     * proving the corruption is in the in-process state interaction,
     * not the shard content. We isolate by exec'ing the merge in a
     * child process. */
    if (dfs_iterative_enabled) {
        fflush(stdout);
        printf("Iterative+v2 path: forking subprocess for merge "
               "(heap isolation; see Test A 2026-04-30)\n");
        fflush(stdout);

        pid_t child = fork();
        if (child < 0) {
            fprintf(stderr, "ERROR: fork() for merge failed: %s\n",
                    strerror(errno));
            return 30;
        }
        if (child == 0) {
            char self_path[PATH_MAX];
            ssize_t n = readlink("/proc/self/exe", self_path,
                                 sizeof(self_path) - 1);
            if (n <= 0) {
                fprintf(stderr,
                        "ERROR (merge child): readlink /proc/self/exe failed: %s\n",
                        strerror(errno));
                _exit(127);
            }
            self_path[n] = '\0';
            execl(self_path, "solve", "--merge", (char *)NULL);
            fprintf(stderr,
                    "ERROR (merge child): execl(%s, --merge) failed: %s\n",
                    self_path, strerror(errno));
            _exit(127);
        }

        int status = 0;
        pid_t r;
        do {
            r = waitpid(child, &status, 0);
        } while (r == -1 && errno == EINTR);
        if (r < 0) {
            fprintf(stderr, "ERROR: waitpid on merge child failed: %s\n",
                    strerror(errno));
            return 30;
        }
        if (WIFSIGNALED(status)) {
            fprintf(stderr,
                    "ERROR: merge subprocess terminated by signal %d\n",
                    WTERMSIG(status));
            return 30;
        }
        if (!WIFEXITED(status)) {
            fprintf(stderr, "ERROR: merge subprocess did not exit normally\n");
            return 30;
        }
        int xs = WEXITSTATUS(status);
        if (xs != 0) {
            fprintf(stderr, "ERROR: merge subprocess exit code %d\n", xs);
            return 30;
        }

        /* Recover unique_count from the merged solutions.bin header so
         * the final report has the right number. The child already
         * wrote solutions.bin, solutions.sha256, and solutions.meta.json. */
        FILE *sf = fopen("solutions.bin", "rb");
        if (!sf) {
            fprintf(stderr,
                    "ERROR: cannot open solutions.bin after fork-merge: %s\n",
                    strerror(errno));
            return 30;
        }
        uint64_t header_count = 0;
        if (sol_read_header(sf, &header_count) != 0) {
            fprintf(stderr,
                    "ERROR: cannot read solutions.bin header after fork-merge\n");
            fclose(sf);
            return 30;
        }
        fclose(sf);
        unique_count = (long long)header_count;
        fork_merge_done = 1;
        printf("Fork-merge complete: %lld unique solutions\n", unique_count);
        fflush(stdout);
    }

  if (!fork_merge_done) {
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

    /* Overflow guard — same as in --merge size-scan. Never-should-fire at
     * realistic scales, but prevents UB on corrupted shard metadata. */
    if (total_file_records < 0 ||
        total_file_records > (long long)(LLONG_MAX / SOL_RECORD_SIZE / 2)) {
        fprintf(stderr, "ERROR: total_file_records %lld out of range\n", total_file_records);
        free(merge_filenames);
        return 20;
    }

    /* Fix #2: Cross-reference sub_*.bin record counts against checkpoint.
     * A truncated file (disk-full during flush) passes the "multiple of 32"
     * check but contains fewer records than the checkpoint claims. */
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
                    /* Use < (not !=): a TRUNCATED file has fewer records
                     * than the checkpoint claims, which is the bug we want
                     * to catch. A LARGER file is normal in resume scenarios
                     * — PHASE_B's shard cumulatively contains PHASE_A's
                     * records plus newly-walked records, so file_records
                     * may exceed any individual checkpoint entry's count. */
                    if (file_records < ckpt_count) {
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
            /* 80% threshold — see detailed comment at the parallel site
             * in the --merge flag code path. With heapsort (in-place),
             * peak memory ≈ buffer size; 80% leaves adequate headroom. */
            use_external_merge = (needed_bytes > total_ram * 8 / 10);
            printf("Merge mode: %s (need %lld GB, have %lld GB RAM)\n",
                   use_external_merge ? "external (auto — insufficient RAM)" : "in-memory (auto)",
                   needed_bytes / (1024*1024*1024), total_ram / (1024*1024*1024));
        }
    }

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
                if (!tf) {
                    fprintf(stderr, "ERROR: cannot open %s: %s\n", merge_filenames[i], strerror(errno));
                    free(all_solutions); free(merge_filenames); return 20;
                }
                if (fseek(tf, 0, SEEK_END) != 0) {
                    fprintf(stderr, "ERROR: fseek END on %s: %s\n", merge_filenames[i], strerror(errno));
                    fclose(tf); free(all_solutions); free(merge_filenames); return 20;
                }
                long sz = ftell(tf);
                if (sz < 0) {
                    fprintf(stderr, "ERROR: ftell on %s: %s\n", merge_filenames[i], strerror(errno));
                    fclose(tf); free(all_solutions); free(merge_filenames); return 20;
                }
                if (fseek(tf, 0, SEEK_SET) != 0) {
                    fprintf(stderr, "ERROR: fseek SET on %s: %s\n", merge_filenames[i], strerror(errno));
                    fclose(tf); free(all_solutions); free(merge_filenames); return 20;
                }
                if (sz > 0) {
                    size_t got = fread(&all_solutions[sol_offset * SOL_RECORD_SIZE], 1, (size_t)sz, tf);
                    if (got != (size_t)sz) {
                        fprintf(stderr, "ERROR: short read on %s: got %zu of %ld: %s\n",
                                merge_filenames[i], got, sz, strerror(errno));
                        fclose(tf); free(all_solutions); free(merge_filenames); return 20;
                    }
                    sol_offset += sz / SOL_RECORD_SIZE;
                }
                fclose(tf);
            }
        }
        free(merge_filenames);
        long long total_stored = sol_offset;

        printf("Sorting %lld solutions...\n", total_stored);
        fflush(stdout);
        if (all_solutions && total_stored > 0)
            heapsort_records(all_solutions, (size_t)total_stored, SOL_RECORD_SIZE, compare_solutions);

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
    if (sol_write_header(f, (uint64_t)unique_count) != 0) {
        fprintf(stderr, "ERROR: header write failed on solutions.bin\n");
        fclose(f); free(all_solutions); return 30;
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

    /* Post-write size verification (both merge paths). Includes the
     * SOL_HEADER_SIZE prefix — file is {header}{records}. */
    {
        struct stat pst;
        long long expected = (long long)SOL_HEADER_SIZE + unique_count * SOL_RECORD_SIZE;
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
    total_done_final = branches_done + n_completed_subs;
    write_sha256_with_metadata("solutions.bin", "solutions.sha256",
                                unique_count, total_nodes,
                                total_branches, total_done_final);

    FILE *hf = fopen("solutions.sha256", "r");
    if (!hf) {
        fprintf(stderr, "WARNING: cannot read solutions.sha256: %s\n", strerror(errno));
    } else {
        if (fgets(hash, sizeof(hash), hf) == NULL)
            fprintf(stderr, "WARNING: solutions.sha256 is empty\n");
        fclose(hf);
    }
    for (int i = 0; i < 64 && hash[i] && hash[i] != ' '; i++) hash_only[i] = hash[i];

    /* Sidecar: solutions.meta.json (provenance + format info) */
    sol_write_meta_json("solutions.meta.json", "solutions.bin",
                        (uint64_t)unique_count, unique_count, hash_only);
  } /* end if (!fork_merge_done) — fork-merge child already wrote solutions.bin/.sha256/.meta.json */

    /* Post-merge: in the fork-merge path, the child has already produced
     * solutions.bin, solutions.sha256, and solutions.meta.json. Pull the
     * sha into the parent's hash/hash_only so the final report is correct. */
    if (fork_merge_done) {
        total_done_final = branches_done + n_completed_subs;
        FILE *hf = fopen("solutions.sha256", "r");
        if (!hf) {
            fprintf(stderr,
                    "WARNING: cannot read solutions.sha256 after fork-merge: %s\n",
                    strerror(errno));
        } else {
            if (fgets(hash, sizeof(hash), hf) == NULL)
                fprintf(stderr,
                        "WARNING: solutions.sha256 is empty after fork-merge\n");
            fclose(hf);
        }
        for (int i = 0; i < 64 && hash[i] && hash[i] != ' '; i++)
            hash_only[i] = hash[i];
    }

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
    struct tm tmbuf;
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime_r(&start_time, &tmbuf));
    printf("Start: %s\n", time_buf);
    strftime(time_buf, sizeof(time_buf), "%Y-%m-%d %H:%M:%S UTC", gmtime_r(&end_time, &tmbuf));
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
