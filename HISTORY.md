# Project History

An honest narrative of how the enumeration analysis evolved — including missteps, corrections, and the iterative process of discovery. Written for anyone curious about how computational research actually works, as opposed to the clean narrative of published results.

For the mathematical rules, see [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md). For formal definitions, see [SPECIFICATION.md](SPECIFICATION.md). For the full technical analysis, see [SOLVE.md](SOLVE.md). For enumeration progress, see [enumeration/LEADERBOARD.md](enumeration/LEADERBOARD.md).

## Prelude — Before April 10, 2026

The project began as a mathematical analysis of the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence), built iteratively with [Claude Code](https://claude.ai/code) (Anthropic). What started as exploring a known structural property grew into a comprehensive computational investigation.

**[roae.py](roae.py) — the analysis engine.** A single-file Python program (no external dependencies) was built to approach the King Wen sequence from every mathematical angle available. It grew to include 28 statistical analyses: pair structure, difference wave, trigrams, complements, entropy, autocorrelation, Markov chains, FFT spectral analysis, Gray code comparison, Monte Carlo constraint testing, and more. Each analysis includes appropriate null models and statistical caveats.

**Key discoveries during this phase:**
- **Trigram name swap bug:** Gen/Xun/Dui were cyclically swapped in the original code. Fixed by correcting the trigram_names dict.
- **Complement distance direction:** Originally claimed King Wen "maximizes" complement distance. Discovered this was a circular filtering artifact — KW actually *minimizes* (3.9th percentile). Corrected across all documentation.
- **XOR regularity is a theorem, not a finding:** The 7 unique XOR products in KW's pairs are a mathematical consequence of ANY reverse/inverse pairing of 6-bit values, not a property of King Wen specifically. Proved and documented.
- **Null model test:** Applying the same constraint-extraction methodology to random pair-constrained sequences produces apparent uniqueness in 9 out of 10 cases. This means the constraint framework makes almost any sequence appear uniquely determined — a critical methodological caveat.
- **"97%/3%" framing was misleading.** Replaced with more honest descriptions of what the data actually showed.

**[solve.py](solve.py) — the first constraint solver.** A Python backtracking solver was built to test whether the mathematical constraints could reconstruct King Wen from scratch. It found 438 valid orderings from a partial search (limited by Python's speed). Based on this small sample, several claims were made that would later be invalidated by larger-scale enumeration.

**Six rounds of scientific review.** The documentation was iteratively attacked from mathematical and scientific perspectives — testing every claim for rigor, checking null models, correcting statistical framing, and adding appropriate caveats. This adversarial review process caught the complement distance error, the XOR theorem, and the null model caveat.

**Documentation suite.** [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) (plain-language), [SOLVE.md](SOLVE.md) (technical), [SPECIFICATION.md](SPECIFICATION.md) (formal), [CRITIQUE.md](CRITIQUE.md) (known limitations), [MCKENNA.md](MCKENNA.md) (relationship to [Timewave Zero theory](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero)), and [GUIDE.md](GUIDE.md) (newcomer introduction) were all written during this phase.

## Day 1 — April 10, 2026

**Starting point:** The ROAE project had a Python analysis engine ([roae.py](roae.py)) with 28 statistical analyses of the King Wen sequence, and a Python constraint solver ([solve.py](solve.py)) that had found 438 valid orderings from a partial search. Based on those 438 solutions, the documentation claimed:

- "23 of 32 pair positions are locked" (identical across all solutions)
- "2 adjacency constraints uniquely determine King Wen"
- A "complete generative recipe" existed

These claims would all turn out to be wrong.

**The C solver:** To explore the solution space more thoroughly, a multi-threaded C solver ([solve.c](solve.c)) was built. The initial version was single-threaded, then rewritten with pthreads to use multiple cores. Early versions had several bugs:

- **Segfault at 40M solutions:** `realloc` overflow when the solution buffer doubled past 1GB. Fixed by switching to a fixed-size hash table.
- **Hash-only comparison:** The first hash table used FNV-1a hash comparison only (no key verification), giving ~1-3% false positive rate. Later replaced with full 64-byte key comparison for zero false positives.
- **SSH process killed on disconnect:** The solver died when the SSH session closed. Fixed by launching from a quick SSH command with `nohup`.
- **`signal()` handler reset bug:** SIGTERM handler only fired once because `signal()` resets after invocation on Linux. Replaced with `sigaction()`.

**First Azure deployment:** An F64als_v6 VM (64 cores, 128 GB RAM) was deployed in westus2 to run the solver. Initial cost estimate was $1.97/hr — this would later turn out to be wrong (actual on-demand price: $3.87/hr).

## Day 2 — April 11, 2026

**The 4-hour run that crashed:** A 4-hour run on the F64 explored 18.7 trillion nodes across 56 threads. All 56 branches hit the time limit — none completed. But the process crashed during the merge phase with no output. The cause: **integer overflow** in `sol_offset * 64` — at 78.5M entries, the multiplication exceeded 32-bit int range, causing a buffer overwrite and segfault.

The crash destroyed all in-memory analytics and solutions. However, checkpoint.txt survived with per-branch data, revealing:

- The search tree was far larger than estimated
- Some branches had zero C3-valid solutions (potential "dead" branches)
- One branch (pair 30) had overflowed its hash table (4M entries)

**Critical bug in checkpointing:** All 56 branches were marked "complete" in the checkpoint — but they were actually interrupted by the time limit. The checkpoint code didn't distinguish between "finished naturally" and "stopped by timeout." On resume, all branches would have been skipped. Fixed by adding COMPLETE vs INTERRUPTED status labels.

**The 1-hour run:** After fixing the integer overflow, a 1-hour run on 56 threads found 20,110,129 unique pair orderings. This was the first successful large-scale result. Key revelations:

- **Only 1 position is locked, not 23.** Position 1 (Creative/Receptive) is the only universally locked position. The "23 locked" claim was an artifact of the 438-solution sample, which came from a single search branch.
- **Millions of solutions exist, not thousands.** Three orders of magnitude more than previously documented.
- 24 of 56 branches appeared dead (zero C3-valid solutions).

All documentation was rewritten to reflect these revised findings. The narrative changed from "6 rules + 2 adjacencies = unique King Wen" to "5 constraints narrow 10^89 to at least 20 million; uniqueness is an open question."

**Visualization:** A visualization script was written to generate PCA scatter plots of the solution space. The initial version had Python loops that would have taken hours on 20M+ solutions. Rewritten with numpy vectorization and subsampling for plots. (Not yet committed to the repository.)

## Day 3 — April 12, 2026

**The 10T reproducible run:** The solver was enhanced with a deterministic node limit (`SOLVE_NODE_LIMIT`) for reproducible results. See [solve.c](solve.c) architecture comments for full design documentation. Unlike time limits, node limits produce identical output on any hardware.

Initial implementation checked the node limit globally (total across all threads), but this made the sha256 depend on thread count. Redesigned to use **per-branch node budgets** (`node_limit / n_branches`), checked per-branch in the backtracker. Each branch explores exactly the same nodes regardless of how many threads are running.

Verified: 1-thread and 2-thread runs produce identical sha256.

**The cost discovery:** Azure pricing API revealed the F64 on-demand cost was $3.87/hr, not the $1.97 originally estimated. Spot pricing was $0.79/hr. Requested and received spot quota increase to 64 cores.

**10T run results (56-branch mode):** 9.99 trillion nodes explored, 31,630,621 unique orderings found. King Wen confirmed present. sha256: `c43f251fb9b66de0237c35ad78b5236011cb9886644ce73437138b50d2f2104d`. **(Later superseded — this was a ~23× undercount due to the sub-branch filename collision bug. The subsequent 742M figure was also an undercount due to 241M hash-table silent drops — see Day 8.)**

**The tail problem:** The last 4 branches (all "dead" — zero solutions) ran on single cores for 90+ minutes while 60 cores sat idle. The 10T run took 3h 48m instead of ~2h because of this load imbalance.

**Solutions.bin lost:** When the F64 VM was deallocated, the 1-hour run's solutions.bin was lost — it was on the VM's disk and the monitor hadn't copied it. The 10T run's solutions.bin was properly preserved. Lesson: always copy ALL output files before deallocating.

**Minimum constraint analysis:** Using the 31.6M solution dataset:

- **4 boundary constraints uniquely determine King Wen** (not 2 as previously claimed). Boundaries 25 and 27 (the original C6/C7) eliminate 99.6% but leave 1,055 survivors. Boundaries 1 and 21 eliminate the rest.
- **4 is the proven minimum for the 31.6M dataset** (computational finite-case check, not a universal theorem). Exhaustive testing of all 31 singles (31), pairs (465), triples (4,495), and quadruples (31,465) against the 31.6M solutions confirmed this. Only 4 of 31,465 quadruples work for that dataset. (Later re-verified for the corrected 742M dataset in the 2026-04-14 bugfix run — minimum is still 4 there, though the specific working 4-sets changed.)
- **3 boundaries are mandatory** (21, 25, 27). The 4th can be any of boundaries 1-4. The constraint structure is almost fully determined.
- **No scalar property uniquely identifies King Wen.** No complement distance, position constraint, or edit distance pattern distinguishes KW. The uniqueness is irreducibly combinatorial.

**Dead branch correction:** 4 branches classified as "dead" in the 1-hour run (pairs 13, 16, 21, 26) were found to be live in the 10T run — they had deep, hard-to-find solutions. "Estimated dead" is the correct label.

**Self-complementary proof:** Constructive proof that all self-complementary pairs at position 2 produce valid orderings. 7 concrete examples extracted and verified. The budget analysis shows why: self-complementary pairs consume from the loosest budget category (distance-6).

**Super-pair anomaly:** Position 20 has the largest gap between pair match (27.5%) and super-pair match (51.2%). Complement pairs are interchangeable at this position — the constraint operates at the super-pair level.

**Neighbor analysis:** 14 solutions differ from King Wen by exactly 2 positions (edit distance 2). All are mutual pair swaps in positions 21-32. 3 of 14 swap structurally identical pairs.

**The 3,030 sub-branch rewrite:** The normal mode was rewritten to enumerate all ~3,030 depth-2 sub-branches instead of 56 depth-1 branches. This eliminates the tail problem: all cores stay busy until near the end.

Each sub-branch writes solutions to a per-sub-branch file (`sub_P2_O2.bin`), the hash table is cleared, and the final merge reads all files. This ensures thread-count-independent output — the sha256 is the same regardless of how many cores run the solver.

**The 10T run with 3,030 mode:** Completed in 2h 6m (vs 3h 48m for the old mode). But King Wen was NOT found — the per-sub-branch budget (3.3B nodes) was too shallow. The old 56-branch mode gave 178B per branch, deep enough to find KW. The 3,030 mode spreads the budget 54x thinner.

This meant the 4-boundary analysis was invalid on this dataset. The old 31.6M dataset remained the reference for analysis.

**100T run deployed — then lost to spot eviction.** A 100T run was started on a spot F64 ($0.79/hr). It reached ~35% (1,022/3,030 sub-branches) in ~6.5 hours before the VM was evicted by Azure. **All progress was lost.** The monitor had been syncing files from the prior 10T run's data in `spot_work/`, not the new 100T run's data. The bug: the 100T deployment cleared files on the VM, but the monitor never synced the new checkpoint before eviction — it still had stale files from the previous run and didn't detect the discrepancy.

**Mitigations for next deployment:**
- Persistent managed disk ($1/month) that survives VM deallocation — data lives on the disk, not the ephemeral OS disk
- Atomic file writes in solve.c (write to .tmp, fsync, rename) — prevents corrupt files from mid-write eviction
- Rotating checkpoints (3 copies) on the local VM
- Run ID verification — monitor confirms it's syncing the right run's data
- Immediate sync after deployment — confirms connection before waiting 5 minutes
- Exponential backoff on retry (1h → 2h → 4h cap)

**The shift pattern (later invalidated by 742M dataset):** In the original 31.6M dataset (which we now know was undercounted by ~23× due to the file-collision bug), positions 3-19 appeared to have EXACTLY 2 possible pairs: King Wen's pair or the pair shifted by one position. The "zero exceptions" observation was an artifact of the bug — the surviving sub-branch files happened to be heavily skewed toward shift-pattern solutions. **At full 742M coverage (2026-04-14), 97.07% of solutions VIOLATE the shift pattern at some position 3-19.** Per-position violation rate ranges from 95.4% at position 3 down to 22.1% at position 19. Only ~21.7M of the 742M (2.93%) conform to the shift pattern fully. The earlier `--prove-shift` finding that "C3 drives the filtering to exactly 2" applied only within the small shift-conforming subset.

**Position 2 and the cascade — substantially weakened by 742M analysis.** The empirical observation that position 2 determines positions 3-19 (1 configuration per branch, zero exceptions in 31.6M solutions) was largely an artifact of the file-collision bug. The 742M dataset directly counts 2-29 distinct pair sequences at positions 3-19 per first-level branch — none have exactly 1. The earlier `--prove-cascade` results remain *correct within their narrower scope*:

- **`--prove-cascade` (still correct, but narrowed):** Proves something only within the **shift-pattern subspace** (each position is constrained to either pair_p or pair_{p-1}, only 2 candidates per position out of 32). Within that 3%-of-reality subspace, 16 branches have a unique budget-feasible path. This is no longer a useful claim about the full solution space.
- **The original "16 of 31 branches deterministic" framing was overreaching.** It implicitly assumed shift-pattern universality — which has now been disproven (97% of 742M solutions are non-shift-pattern). A re-statement of the cascade behavior on the corrected dataset is pending.

A survey of all 204 non-KW configurations (5 minutes max each) revealed a spectrum:

- **Branch 24 (Revolution/Cauldron):** All 17 non-KW configs have valid alternatives — maximum freedom at positions 3-19
- **Branches 22, 23:** 12/17 valid — mostly open
- **Branch 20:** 4/17 valid — partially open
- **Branch 19:** 1/17 valid — nearly deterministic
- **Branch 25:** 0/17 found in 5 minutes — either deterministic or trees too large
- **Remaining branches:** survey in progress

**Key correction:** The earlier claim "all freedom is in positions 20-32 — only 13 positions are free" was first weakened to "wrong for half the branches" via `--prove-cascade`, and is now further invalidated by the 742M dataset. Per-position Shannon entropy on 742M shows positions 4-20 still carry only 0.28-1.72 bits each (heavily constrained relative to log₂(32)=5 bits) — so the "cascade region" still has structure — but that structure permits many distinct configurations per branch, not just one. The phrase "13 free positions" no longer captures the picture; the freedom is distributed across the cascade region rather than concentrated in 13.

**Self-complementary proof (`--prove-self-comp`):** Proved in seconds. All 7 eligible self-complementary branches produce valid orderings. Reproducible via `./solve --prove-self-comp`.

**Shift pattern proof attempt (`--prove-shift`):** The budget allows 13-30 candidates per position, not 2. The 2-option pattern was claimed enforced by C3 — but on the 742M dataset only 2.93% of solutions actually conform to the shift pattern. C3 narrows but does not enforce 2 options; the constraint geometry is much more permissive than originally believed.

## Missteps and corrections (summary)

| What went wrong | Impact | Fix |
|----------------|--------|-----|
| "23 of 32 locked" claim | Published in all docs | Corrected to "only 1 locked" after 20M+ enumeration |
| "2 adjacency constraints suffice" | Core claim invalidated | Corrected to 4 constraints (proven minimum for the 31.6M dataset; later re-verified for the 742M dataset) |
| Integer overflow in merge | Lost 4-hour run's output | Cast to `size_t` for array indexing |
| `signal()` resets after one use | SIGTERM didn't produce output | Replaced with `sigaction()` |
| Checkpoint marked interrupted as complete | Resume would skip unfinished work | Added COMPLETE/INTERRUPTED status |
| Hash-only comparison (no key verify) | ~1-3% false positive rate | Full 64-byte key comparison |
| solutions.bin not copied before VM deallocation | Lost data, had to re-run | Monitor always copies bin files now |
| Cost estimate wrong ($1.97 vs $3.87) | Underestimated spending | Verified via Azure pricing API |
| 3,030 mode too shallow at 10T | KW not found, analysis invalid | Deployed 100T run with deeper per-sub-branch budget |
| Forward feasibility check too slow | 34% overhead per node | Removed; pair ordering also removed (no net benefit) |
| Pair ordering heuristic | Front-loaded solutions but same total work | Reverted; no speedup for fixed-budget runs |
| GIT_HASH fallback in wrong scope | Compile failure without -DGIT_HASH | Moved #ifndef to top of file |
| 100T run lost to spot eviction | ~6.5 hours of compute lost (~$5) | Added persistent disk, atomic writes, run ID verification, rotating checkpoints |
| Monitor synced stale data | Didn't detect new run started | Added run ID check, immediate sync after deploy |
| Orchestrator died silently before monitoring started | 100T run continued unmonitored; scp of not-yet-existing checkpoint tripped `set -euo pipefail` with stderr hidden | Split launcher and monitor into separate processes; `set -uo pipefail` (no -e) in monitor; guard remote reads with `test -f` before scp; verify monitor with `pgrep` after launch |
| 2nd 100T attempt — sub-branch-granularity recovery insufficient | After ~9h wall time and multiple spot evictions, only 47/3030 sub-branches (1.5%) committed. Each eviction lost all 64 in-flight sub-branches (33B nodes each) because `INTERRUPTED` branches restart from zero on resume. 12.5T nodes wasted across interrupts. Projected completion: ~30 days. | Aborted run; 47 committed sub-branches archived (49.7M solutions, sha256 verified). Follow-up: add intra-sub-branch checkpointing before retrying on spot |
| "Position 2 determines 3-19" claimed as universal | Overclaimed; disproven for 12 branches | Corrected: proved for 16, alternatives exist for 12 |
| Shift pattern attributed to budget | Budget allows 13-30 candidates, not 2 | Corrected: C3 drives the filtering |
| **Sub-branch filename collision — silent data loss in all prior runs.** `flush_sub_solutions` keyed `sub_P2_O2.bin` on (pair2, orient2) only. 3030 sub-branches share only 64 unique (p2, o2) values, so later sub-branches **overwrote** earlier ones' solutions.bin files. The sha256 was still reproducible (bug was deterministic) so the defect went undetected. | Prior "31.6M unique orderings from 10T" was a **~23× undercount**. Correct result at 10T is **742,043,303 unique orderings**. All 4-boundary / cascade / shift-pattern claims built atop the 31.6M dataset need re-verification. | Broadened file key to (pair1, orient1, pair2, orient2): `sub_P1_O1_P2_O2.bin`. Checkpoint format includes full key. Dynamic `completed_sub_branches` array (MAX_COMPLETED_SUBS=4096) replaced the hard-coded 64-cap. |
| Monitor completion regex mismatch | Post-run monitor grep for "SEARCH COMPLETE\|TIMED OUT" didn't match the actual `SEARCH_COMPLETE` (underscore) status in solver output. Monitor concluded run failed, tore down VM mid-archive. | Data preserved on managed disk (safe). Monitor should match stable machine-readable markers (e.g. `solve_results.json` status field) not stderr text. Queued in post-10T hardening. |
| `fwrite` return value never checked — silent truncation on disk-full | 10T run's `solutions.bin` wrote only 8GB of intended 23.7GB (disk was 32GB; sub_*.bin files consumed 23GB, leaving only ~8GB for output). Solver reported "742M unique solutions" (from in-memory dedup) but the file was short. sha256 file matched the truncated output so audit-by-sha missed it. Caught by byte-size vs record-count sanity check. | Recovered by resizing disk 32→64GB, re-running `./solve --merge` against preserved sub_*.bin files, producing the correct 23.7GB output. Fix: audit all fwrite/fopen/fclose return values; add end-to-end sha verification (compute-from-memory vs reread-from-file); preflight `free_disk ≥ estimated_output × 1.5`. |

## What actually advanced understanding

| Finding | How discovered | Status |
|---------|---------------|--------|
| **≥742,043,303 valid orderings** exist (10T) | 10T enumeration, 2026-04-14 | Lower bound and itself an undercount — 241M solutions silently dropped by hash-table probe cap (Day 8). sha `aa1415...` invalidated. New reference pending. |
| 4 boundary constraints needed (proven minimum for the 742M dataset) | Greedy search against 742M unique orderings, 2026-04-14; then exhaustive disproof of all 4,495 three-subsets | **Proven minimum for the 742M dataset** (computational finite-case proof, not a universal theorem): no 3-subset suffices (best leaves 24 survivors vs 4 KW variants). Chosen 4-set shifted from {1, 21, 25, 27} (31.6M) to **{2, 21, 25, 27}** (742M). A deeper enumeration could in principle change the minimum. |
| 3 mandatory boundaries (21, 25, 27) | Greedy search; appear in both 31.6M and 742M solutions | Partially superseded — see next row. |
| 2 truly mandatory boundaries (25, 27) for the 742M dataset | Exhaustive enumeration of all C(31,4)=31,465 four-subsets (2026-04-15) | Only 4 four-subsets uniquely identify KW: {2,21,25,27}, {2,22,25,27}, {3,21,25,27}, {3,22,25,27}. Boundaries 25 and 27 appear in **every** working 4-set (truly mandatory for the 742M dataset). Boundaries {2 ↔ 3} and {21 ↔ 22} are pairwise interchangeable — knowing one from each pair plus the mandatory {25, 27} uniquely identifies KW. The earlier "21 mandatory" claim was a greedy-search artifact: greedy picks 21 (or sometimes 2), but exhaustive search shows 21 can be swapped for 22 (or 2 for 3) without losing uniqueness. Stronger result, scoped to the 742M dataset. |
| Per-position Shannon entropy reveals a crisp constraint gradient | Computed over 742M (2026-04-14) | Position 1: 0.0 bits (forced). Position 3: 4.12 bits (highest freedom, 31 pairs observed). Positions 4-20: 0.28-1.72 bits (cascade region). Positions 22-31: 3.45-3.65 bits. Max possible = log₂(32) = 5.0 bits. |
| Pairwise mutual information — boundaries 25, 27 are not information bottlenecks | I(p; q) matrix computed over 742M (2026-04-14) | Strongest correlations are adjacent-position within the cascade region (pos 19↔20 = 1.15 bits). Boundaries 25 & 27 show weak MI to every other position (max 0.19 bits) despite being mandatory. Their role is likely structural (specific pair adjacencies KW realizes and few alternatives do) rather than information-geometric. |
| Cascade determinism claim resolved: `--prove-cascade` is correct only within the shift-pattern subspace, which is just 3% of the full solution space | Counted distinct pos-3..19 pair sequences per first-level branch (2026-04-14) and verified shift-pattern violation rate (2026-04-15) | `--prove-cascade` enumerates only 2 candidates per position (KW's pair_p or the shifted pair_{p-1}). It correctly proves 16 branches have a unique budget-feasible path *within that subspace*. But on the corrected 742M dataset, only 2.93% of solutions stay within that subspace — 97.07% violate it. So the "16 deterministic" claim, while not technically wrong, was applied to a tiny minority of the actual solution geometry. The full-space cascade is much less constrained: every reachable branch admits 2-29 distinct pos-3-19 configurations. |
| Shift pattern at positions 3-19 collapses at full coverage | Direct count of shift-pattern violations across 742M (2026-04-15) | Only 2.93% of 742M valid orderings conform to "every position 3-19 uses pair_p or pair_{p-1}". The earlier "zero exceptions in 31.6M" was an artifact of the file-collision bug undersampling non-shift-pattern solutions. Per-position violation rates: pos 3 = 95.4%, pos 4 = 95.2%, decreasing to pos 19 = 22.1%. The full cascade region (3-19) is much more permissive than the earlier observation suggested. |
| Hidden orient-coupling in King Wen's 4 stored variants | Direct inspection of the 4 KW records in solutions.bin (2026-04-15) | KW appears 4 times in solutions.bin (cross-sub-branch dedup is byte-level; within-sub-branch is canonical). The 4 variants differ in within-pair orient at exactly 5 positions: {2, 3, 28, 29, 30}. But not all 32 combinations are valid — only 4 are. The constraint: orient bits at positions 28, 29, 30 are locked together; their value equals (orient at pos 2) XOR (orient at pos 3). So effectively 2 independent toggle bits = 4 variants. This is a structural orient-symmetry of King Wen's specific arrangement (not yet checked whether it generalizes to other valid orderings). |
| Boundary redundancy structure in 742M | Pairwise joint-survivor counts across all 465 boundary-pairs (2026-04-15) | Boundaries 15-19 are fully redundant: `joint(b1, b2) / min(survivors)` = 1.000 for every pair within the cascade-region {15,16,17,18,19}. Knowing one of these implies all the others. By contrast, boundaries 26 and 27 are highly *independent* of the cascade region (ratios ~0.007-0.010 with boundaries 3-8). This explains why the minimum 4-set picks {2, 21, 25, 27}: 2 catches position-2's high-entropy choice, 21 catches the cascade-end transition, 25 and 27 contribute *independent* information not implied by the others. |
| Position 2 determines positions 3-19 (16 branches) | Proved by budget via [`--prove-cascade`](solve.c) | Proved for pairs 1-18; disproven for others |
| Cascade NOT deterministic for 12 branches | `--prove-cascade` full C3 proof found valid alternatives | Branch 24: all 17 configs valid; varies by branch |
| Shift pattern (2 options at positions 3-19) | Analysis of 31.6M solutions | Observed universally; driven by C3 not budget |
| Self-complementary branches always live | Constructive proof (7 examples verified against [C1-C5](SPECIFICATION.md#constraints)) | Proved |
| XOR=100001 branches always dead | 10T enumeration observation | Empirical (not formally proved) |
| Super-pair constraint at position 20 | Per-position analysis | Observed |
| Best-triple survivors: 24 total (20 non-KW + 4 KW orient variants) from best triple {2, 25, 27} — see [SOLVE.md](SOLVE.md#structure-of-the-best-triple-survivors-for-742m) | Characterization of residual after best 3 boundaries; replaces the earlier "18 triple-survivors" finding from the 31.6M bug-era dataset | Observed (742M) |
| No scalar property uniquely identifies KW | Exhaustive feature search | Proven for 31.6M dataset |
| 3,030 sub-branch mode eliminates tail problem | Comparative benchmarks | Engineering result |
| Thread-independent reproducibility | Per-branch node budgets | Verified (1-thread = 2-thread sha256) |

## Day 4 — April 13, 2026

**100T deployment on spot, then aborted.** Deployed a 100T run on a spot F64 with the (then-still-buggy) solver. The run was evicted after ~3 hours (intra-day Pacific business-hour load). After redeploy, monitoring revealed only ~1.5% of sub-branches committed in 9 hours of wall clock — eviction was killing all 64 in-flight sub-branches each time, and the per-sub-branch node budget (33B) was so large that recovery cost exceeded forward progress. Projected completion under that approach: ~30 days. The 47 committed sub-branches were archived locally (49.7M solutions, sha256 verified against the partial output) and the run was killed. The lesson — sub-branch-granularity recovery is too coarse for spot at large per-sub-branch budgets — drove the design of "Option B" (depth-3 work units) for any future 100T attempt.

## Day 5 — April 14, 2026

**The bug discovered.** While preparing a 10T re-run before attempting 100T again, an audit of the solver's `flush_sub_solutions` keyed `sub_*.bin` filenames on `(pair2, orient2)` only — but 3030 sub-branches share only 64 distinct `(p2, o2)` values, so later writes silently overwrote earlier ones. Every prior result, including the published 31.6M figure, was a deterministic undercount: the sha256 reproduced because the bug reproduced. Fix: broaden the filename and checkpoint key to `(pair1, orient1, pair2, orient2)`. Same change in `is_sub_branch_completed`, `load_sub_checkpoint`, the merge step, and the per-sub-branch flush. Tested locally: 100M-node smoke test produced 1097 unique `sub_*.bin` files (cap was previously 64), 336k solutions, deterministic across thread counts.

**The 10T bugfix run.** Deployed on F64 spot (sha256 `aa1415174c914f8ee06821e51f599b196321c69a8c736f26936694d81a56719b`, 742,043,303 unique orderings — a 23.5× increase over the buggy 31.6M). All 6 audits passed: KW present, sort order OK, all 3030 sub-branches enumerated (1344 produce ≥1 C3-valid solution; 1686 are dead), 23.5× more than the buggy baseline, every record passes C1-C5, sum of per-sub-branch nodes exactly equals the global total (10,000,002,096,398 nodes).

**Two more bugs surfaced during recovery.** The solver's final write of `solutions.bin` was *silently truncated* from 23.7 GB to 8 GB because the persistent disk filled up mid-write and `fwrite`'s return value wasn't checked. The `solutions.sha256` matched the truncated file (sha computed post-truncation), so audit-by-sha didn't catch it — only a byte-size-vs-record-count comparison did. Recovered by resizing the data disk 32→64 GB and re-running `./solve --merge` against the preserved sub_*.bin shards. Separately, the run-monitor's completion-detection regex grepped for `"SEARCH COMPLETE"` while the solver writes `"SEARCH_COMPLETE"` (underscore) in its JSON output — the monitor concluded the run had failed and tore down the VM. Data was safe on the preserved managed disk.

**Scientific analyses on 742M.** Ran 11 distinct analyses spanning ~3 hours of spot VM time:
- Per-position Shannon entropy: position 1 = 0.00 bits (forced), position 3 = 4.12 bits (highest freedom), positions 4-20 = 0.28-1.72 bits (cascade region), positions 22-31 = 3.45-3.65 bits.
- Pairwise mutual information: strongest correlations between adjacent positions in the cascade region (pos 19↔20 = 1.15 bits). Boundaries 25 and 27 — both mandatory — show *weak* MI to everything (max 0.19 bits).
- Per-boundary survivors and exhaustive 3-subset disproof: best 3-subset leaves 24 survivors → 4-boundary minimum proven for the 742M dataset.
- All 4-subsets enumeration: only 4 working sets exist — `{2,21,25,27}`, `{2,22,25,27}`, `{3,21,25,27}`, `{3,22,25,27}`. **Boundaries 25 and 27 are truly mandatory** (in every working set). Boundaries {2 ↔ 3} and {21 ↔ 22} are pairwise interchangeable.
- Boundary redundancy: boundaries 15-19 are fully redundant (knowing one implies all others); boundaries 26 and 27 are highly independent of the cascade region (ratios ~0.01).
- KW within-pair orient variants: 4 KW records (not 1) because cross-sub-branch dedup is byte-level. Orient varies at exactly 5 positions {2, 3, 28, 29, 30}, but constrained by `(pos2 XOR pos3) == pos28 == pos29 == pos30`. So 2 free toggles, not 5.
- Shift-pattern verification: only 2.93% of 742M solutions conform to "every position 3-19 uses pair_p or pair_{p-1}". The earlier "shift pattern observed universally in 31.6M" was an artifact of the file-collision bug undersampling non-shift solutions. This also resolves the apparent contradiction with `--prove-cascade`: that proof is correct only within the shift-pattern subspace.
- Cascade direct count: every reachable first-level branch admits 2-29 distinct configurations at positions 3-19, none have exactly 1.
- Null-model boundary (relative to a random non-KW reference): different boundary set chosen, indicating the {25, 27} mandatory pair is KW-specific, not a feature of the constraint geometry alone.
- Orbit analysis: 0 palindromic solutions, 0 fully self-pair-complement-symmetric solutions.

## Day 6 — April 15, 2026

**Consolidation in C.** Rewrote all post-enumeration analyses as a single `./solve --analyze [solutions.bin]` mode in solve.c. mmap'd file access (no full malloc), packed `uint64_t` boundary masks (8× memory savings), `__builtin_popcountll` for SIMD-friendly intersections, OpenMP parallelism on the heavy 3-subset, 4-subset, MI, and redundancy loops. Validated against the Python results on 742M: every numerical claim matches. Total `--analyze` runtime: 7 minutes (vs ~2 hours for the equivalent Python). Exhaustive 3-subset test went from 36 minutes (Python) to 4 seconds (C). The 4-subset enumeration went from 100 minutes to 37 seconds.

**OpenMP also added to `--validate` and `--prove-cascade`.** Predicted ~10s `--validate` on 742M (was ~2 min). `--prove-cascade` Phase 1 outer loop now parallelized across 31 branches with per-branch result buffer for ordered output (output is identical to the pre-parallel version; only the wall time changes).

**Documentation rewrite.** `solve.c` top-of-file comment updated to reflect the 3030-sub-branch architecture (the older "56-branch" description was stale), bug-history section, all current run modes including `--analyze`, build flags including `-fopenmp -march=native`, OpenMP licensing note. New `DEPLOYMENT.md` captures architecture + lessons + Azure spot-VM provisioning instructions in an appendix. `HISTORY.md`, `SOLVE-SUMMARY.md`, and `LEADERBOARD.md` all updated with the corrected 742M numbers and the {25, 27} truly-mandatory finding. Methodological rule established: any "proven" claim must be either universal or explicitly scoped (e.g., "proven for the 742M dataset"); applied throughout.

**Pushed to GitHub.** 4 commits: solve.c (bug fix + --analyze + parallelization + doc), DEPLOYMENT.md, doc updates, run artifacts.

## Day 7 — April 16, 2026

**`--analyze` extended to 24 sections.** Four rounds of spot-VM runs added sections [16]-[24] to the consolidated analysis mode, each targeting a specific gap:

- **[16] Per-(p2, o2) collision-key bug-impact map.** 62 of 64 keys are live; up to 47 sub-branches collided on a single key. Bug-retained count bounded by `[0.16%, 17.52%]` of 742M; the old 31.6M (4.26%) is mid-range, consistent with random thread-scheduling winners. Undercount factor: 23.48×.
- **[17] Structural decomposition of best-triple survivors.** Best triple `{2, 25, 27}` leaves 24 total survivors (4 KW orient variants + 20 non-KW). The 20 non-KW collapse to 6 distinct pair-orderings, all permutations of pairs `{20, 21, 22, 23}` at positions 21-24. Replaces the bug-era "18 triple-survivors" finding.
- **[18] Per-boundary conditional entropy.** Baseline 65.8 bits. Top boundaries: 2 and 3 at 35.3 bits each. Mandatory `{25, 27}` sit mid-pack at 11.4 and 10.8 bits. Reframes mandatory status: **structural independence, not informational weight**.
- **[19] Identity-level equivalence of 4 working 4-sets.** All four leave exactly the same 4 records (KW orient variants, zero non-KW). Rigorous confirmation of what was previously only probabilistically inferred.
- **[20] Complement-orbit analysis.** Bitwise complement (h → h^0x3F) maps pairs to pairs, preserving C1/C2/C5. Tested whether complement is an automorphism of the C1-C5 solution set. Result: **0 of 742M records have their complement in the dataset.** Complement is NOT closed — C3 (complement distance) breaks under the map. KW's complement has pair-sequence `[0 24 17 6 7 5 3 4 8 16 23 21 22 13 14 20 9 2 19 18 15 11 12 10 1 28 26 29 25 27 30 31]`, not in the dataset. The solution space is fundamentally asymmetric under bitwise complement.
- **[21] Full per-position pair frequency table.** 32×32 baseline for 100T comparison. Confirms cascade structure: positions 4-20 have exactly 3 distinct pairs each; positions 22-31 have 14 each.
- **[22] Complement-distance distribution (hex-level, same metric as C3).** KW at 100th percentile within C1-C5 is tautological (C3 enforces cd ≤ KW). The 3.9th percentile claim in SOLVE-SUMMARY.md is correct — it measures KW against ALL pair-constrained orderings (C1 only). Distribution is strongly right-skewed: 32.5% of C1-C5 solutions are in the top bin (760-779 out of range [448, 776]).
- **[23] {25, 27}-only survivor characterization.** 37,356 total survivors (37,352 non-KW), replacing the old buggy "1,055." Positions 1, 25-28 are locked (5 of 32). Positions 4-20 still have exactly 3 distinct pairs each in this subspace.
- **[24] KW nearest-neighbor catalog.** 44 solutions at edit distance 2 (the minimum); 6 at distance 3. All dist-2 neighbors are single pair-swaps in the free region (positions 21-32), except 2 records that swap pairs 1↔2 at positions 2-3. Consistent with the earlier pair-swap analysis.

**A use-after-free bug caught and fixed.** First run of sections [16]-[19] crashed silently because `bmask[]` had been freed between sections [13] and [14]. Fix: moved the free to end of analyze_mode; verified via `free -g` that combined working set (~27 GB) fits on F32als_v6 (64 GB). Added code-level lifetime notes and a DEVELOPMENT.md gotcha entry.

**Two-phase deployment pattern documented.** DEPLOYMENT.md now describes separating enumeration (core-dense F-series) from merge (RAM-dense E/M-series) to cut costs. Saves ~50% at 100T, becomes architecturally necessary at 1000T.

**Documentation updates.** SOLVE.md boundary section rewritten with corrected 742M numbers, {25, 27} mandatory finding, shift-pattern rescoping, and new structured-family characterization. SOLVE-SUMMARY.md: added conditional-entropy reframing, orient-collapsed robustness, rigorous 4-set equivalence, structured-family description. CRITIQUE.md and MCKENNA.md: hyperlinked Latin square references. GUIDE.md: added ䷄ Waiting #5 to Hamming distance example.

## Day 8 — April 16-17, 2026

**Correctness audit and hardening pass.** Systematic review of every component in solve.c for the standard: every valid solution found, none lost, no duplicates, deterministic regardless of hardware.

**Critical bug found and fixed: hash-table silent drops (585880f).** The 64-probe linear-probe cap in the per-thread hash table silently dropped records when the table exceeded ~75% capacity. At 10T depth-2, **241 million solutions were silently lost** — the prior 742M figure is an undercount. The sha `aa1415...` is reproducible but represents an incomplete dataset.

Root cause: an optimization assumption ("4M slots for <1M entries per sub-branch") that was never tested at production scale. Some sub-branches at 10T have 4.17M unique solutions — 99.6% of the table. The code had no detection mechanism until the drop counter was added days earlier; even then, the counter showed the problem only after the fact.

Fix: removed the probe cap entirely, added per-thread auto-resizing hash tables that double at 75% load, hard abort on OOM. Default initial size raised from 2^22 (4M) to 2^24 (16M). Zero silent drops guaranteed at any budget.

**Five additional correctness fixes (232d688):**
- flush_sub_solutions: fwrite/fsync/fclose return values now checked; post-write size verification; abort on any I/O failure (was silently truncating sub_*.bin on disk-full)
- Merge checkpoint cross-reference: each sub_*.bin record count validated against checkpoint.txt (catches truncated files that pass "multiple of 32" validation)
- `--verify` mode: independent constraint verification reads solutions.bin and checks every record against C1 (all pairs), C2 (no hamming-5), C4 (first pair), C5 (distance distribution), sorted order, no duplicates
- Aggregate enumeration status: final output now prints "COMPLETE (N EXHAUSTED)" or "BUDGET-LIMITED (N EXHAUSTED, M BUDGETED)"
- Dedup semantics documented in output and solve_results.json: "canonical pair ordering (orientation bits masked)"

**All KNOWN LIMITATIONS resolved (6197b2b).** pair_index_of replaced with O(1) lookup table. Only remaining documented limitation: merge loads all records into RAM (needs external merge-sort for billion+ record scale, not yet implemented).

**Infrastructure: private-IP-only topology, dynamic disk expansion, SSH launch fix.** Solver VMs now use claude-vnet private IPs (no public IP, no external attack surface). Monitor's solver-launch SSH hardened with setsid + timeout 15 (fixes a hang where backgrounded nohup didn't release the SSH channel). Dynamic disk expansion watchdog added to monitor for 100T+ runs.

**Thread-count independence verified.** 1, 2, 4, 8 threads all produce identical sha at 100M budget. Selftest PASS at commit 6197b2b.

**All prior 10T shas are invalidated.** The sha `aa1415...` represented 742M solutions minus 241M silent drops. New reference shas must be established with the fixed solver. 10T depth-2 and depth-3 re-runs pending.

## Current state

The prior **742,043,303-solution dataset at 10T** (sha `aa1415...`) is now known to be an **undercount** due to 241M hash-table silent drops (see Day 8). New reference shas must be established with the fixed solver (commit 6197b2b+). The selftest baseline at 100M (sha `00851fa5...`) is unchanged because no sub-branch at that scale exceeds hash table capacity.

The 4-boundary minimum-uniqueness result holds at the new scale, but the specific chosen set shifted: greedy search on 742M picks **{2, 21, 25, 27}** rather than the old **{1, 21, 25, 27}**. Exhaustive enumeration of all 31,465 four-subsets found only 4 working sets: {2,21,25,27}, {2,22,25,27}, {3,21,25,27}, {3,22,25,27}. Only **{25, 27} are truly mandatory** (present in every working 4-set); {2 <-> 3} and {21 <-> 22} are pairwise interchangeable. Cascade and shift-pattern claims built atop the old 31.6M dataset have been re-verified against 742M: the shift pattern holds for only 2.93% of solutions, and every reachable branch admits 2-29 distinct configurations at positions 3-19.

A 100T run remains pending: the 2026-04-13 attempt on spot F64 was aborted after multiple evictions revealed that sub-branch-granularity recovery is too coarse for spot under current eviction rates (only 1.5% committed in 9h). Next retry requires intra-sub-branch checkpointing in [solve.c](solve.c) plus the hardening pass from the 10T recovery (see [DEPLOYMENT.md](DEPLOYMENT.md)).

## Infrastructure

- **This VM** (claude, D2as_v6): orchestration, analysis, git. $0.09/hr, ~$66/month if always on.
  - Deallocated when no work is running to save costs. Only active during solver runs and analysis sessions.
- **F64 spot** (solver-f64-spot, F64als_v6): solver runs. $0.79/hr, created/destroyed per run.
- **Spot quota**: 64 cores in westus2. Approved April 12.
- **All run outputs archived** in `solve_c/runs/` with sha256 verification.
- **Auto-retrying monitor** handles spot evictions: syncs files, waits 1 hour, restarts.
- **Persistent managed disk** (solver-data, 64GB, ~$1/month): survives VM deallocation. Data stored here, not on ephemeral OS disk. (Originally 32GB; resized to 64GB on 2026-04-14 after solutions.bin truncation.)
- **Atomic file writes** in solve.c: write to .tmp, fsync, rename. Prevents mid-eviction corruption.
- **Rotating checkpoints**: 3 copies maintained locally (checkpoint.txt, .1, .2).
