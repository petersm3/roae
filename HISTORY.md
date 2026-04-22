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

## April 10, 2026

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

## April 11, 2026

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

## April 12, 2026

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
| **Same-SKU physical-host placement creates 2x rate variance (2026-04-20).** Launched `campaign-westus3` D32als_v7 on-demand for the single-branch Recon campaign. Measured per-thread solve rate: ~10M nodes/sec — 2x slower than an earlier observation on `campaign-westus2` (same SKU) at ~20M/sec. Both VMs had identical `Model name: AMD EPYC 9V45 96-Core Processor` (Zen 5c "Turin Dense"), identical vCPU allocation (32 vCPUs = 16 physical + SMT), identical L3 (64 MiB across 2 CCDs). Yet per-thread rate differed 2×. Likely cause: noisy-neighbor workload on the first physical host (memory-bandwidth contention), or different CCD placement within the host's 96-core package. | `lscpu` cannot distinguish — same CPU model masks the problem. Impact at current campaign scale: ~$17 (~13 hrs) vs ~$36 (~28 hrs) for identical work. | **Kill and retry** costs ~5 min and can land on a better host. Second placement of same SKU in same region measured 22M/sec = back in line with prior observation. Lesson: always take an early per-thread rate measurement (~5-10 min in) on any new campaign VM and kill-and-retry if rate is obviously off. Preserve `lscpu` output on every campaign VM before teardown so comparative data survives. Long-term fix: when `solve.c --sub-branch` is parallelized (see `x/roae/PARALLEL_SUB_BRANCH_DESIGN.md`), per-thread rate still matters but total throughput becomes less sensitive to individual thread speed. |
| **Deallocated VMs still hold quota reservations (2026-04-20).** When campaign-westus2 hit its 3rd spot eviction in one session, I tried to pivot to on-demand. D32als_v7 on-demand in westus2: blocked by Dalsv7 family quota of 10 cores. Checked westus3 Dalsv7 quota: 130 limit, 128 used. The 128 current reservation was held by `d128-westus3` VM — which was *deallocated* (no compute charges) but still consumed its 128-core quota slot. Azure doesn't free quota on deallocation, only on VM deletion. Blocked the on-demand pivot until d128-westus3 was deleted. | Delayed the campaign by ~15 min; required user approval to delete legacy d128-westus3 VM. Could have blocked the campaign entirely if legacy VM deletion wasn't authorized. | Documented in `DEPLOYMENT.md` under "Quota accounting — deallocated VMs still hold your quota." Before leaving a large VM deallocated "for later," ask: will I want to provision a *different* VM in the same region + family before restarting this one? If yes, delete rather than deallocate. Spot and on-demand are separate quota buckets, so mixed-priority fleets are partially protected. Verification: `az vm list-usage -l <region> -o table` — "Current" reflects reserved (deallocated + running) cores. |
| **F64als_v6 ad-hoc VMs repeatedly left running (2026-04-19 and 2026-04-20).** Project policy since 2026-04-19 morning has been "NO F-series VMs, D-als-v7 family only." Despite that, `solver-d3` (Standard_F64als_v6 spot, westus2) was provisioned TWICE to mount the `solver-data` managed disk for brief inspection tasks, and each time left running long after the inspection ended — once for ~32 hrs (~$25) and once for ~9.5 hrs (~$7.50). Both recreations are attributed in the Azure activity log to `mrpeterson2@gmail.com` (the shared authenticated identity), so the log alone doesn't distinguish user-driven vs Claude-session-driven; operator testimony and session-timeline analysis point to Claude-initiated for the 2026-04-20 18:59 UTC recreation. **Root cause (anti-pattern):** (a) choosing an F64 VM — a SKU explicitly retired — when a D4 was sufficient for a 10-min disk-mount task; (b) no pairing of VM-creation with teardown in the same command sequence or same wakeup prompt; (c) no session-lifetime VM log to self-audit against at session end. | Total avoidable: ~$32.50 across both incidents. `solver-data` itself preserved through both tear-downs per user rule. | **Fix (2026-04-21):** Added two strict-policy sections to CLAUDE.md: §"Cost control — SKU family restrictions" banning F-series unconditionally, and §"Session-lifecycle VM discipline" mandating paired teardown + a session VM log at `/tmp/claude_session_vms.txt`. Added §"Ad-hoc VM lifecycle rules" to DEPLOYMENT.md with concrete one-liner patterns for create-attach-inspect-detach-delete and default `--ephemeral-os-disk true` for short-lived VMs. Default VM sizes for data-inspection are now D2als_v7/D4als_v7 — never F64, never D64+ unless CPU-bound multi-core work is actually being done. |
| **Archive VM torn down without `sync && umount` → silent truncation of 4 `.gz` files (2026-04-21 archive + same-day discovery).** After tar-piping d2/d3 validation artifacts from westus2 to `solver-data-westus3` and `gzip -9`-compressing them, `archive-westus3` was deleted via `az vm delete` without first unmounting `/data`. The VM's sha256-manifest verification step had completed and passed before teardown — but the manifest was computed with dirty pages still in the page cache, so it missed the in-flight truncation of the last files being written. User authorized deletion of source `solver-validate-d2` / `solver-validate-d3` disks based on that (now-known-to-be-incomplete) verification. | 4 of 57,754 `.gz` files silently truncated. Two were redundant (raw `.txt` preserved alongside) → zero data loss. Two were historical `enum_output.log.gz` files with no raw source → content lost, non-critical. `solutions.bin.gz` (both d2 and d3) intact, sha-verified against canonical shas post-remediation. Scientific payload fully recovered. | Spun up `verify-westus3` (D2als_v7 on-demand, ~$0.07 / 42 min), ran `gzip -t` over all 57,754 `.gz` files, identified the 4 corrupt, regenerated checkpoints from raw, deleted unrecoverable logs, re-swept clean, clean-umounted, tore down VM. **Standing rule added (CLAUDE.md):** any VM teardown following an archive-write workload must `sync && sudo umount <datadisk>` on-host before `az vm delete`/detach. Archive sha256 manifests must be generated after a sync flush, not from live page-cache state — ideally post-umount/remount-cycle to force a durable read. |
| **d128-westus3 provisioned as on-demand, not spot — ~$48-80 overspend on the 100T d3 run (2026-04-19 to 2026-04-20).** The user's standing policy, documented across memory files, HISTORY.md, DSERIES_ROI_REPORT.md, and CLAUDE.md, was "use spot VMs for large compute workloads." When d128-westus3 was created (~2026-04-19 03:34 UTC during an earlier autonomous Claude session — most likely a hand-off from the overnight autonomous work), the `az vm create` command did NOT include `--priority Spot --eviction-policy Deallocate --max-price -1`. The VM came up as an on-demand (regular) instance at $5.146/hr Linux westus3 instead of spot at $0.95/hr. When the 100T d3 enumeration + merge was launched on that same VM later that day, the operating Claude session did NOT run `az vm show --query priority` to verify the VM's purchase type before committing to a 16h 48m pipeline. Final impact: ~$112 actual VM cost for the 100T run; ~$35-40 would have been possible under the corrected policy "spot for enumeration, standard for merge" (enum 11.4h × $0.95 spot + merge 5.4h × $5.146 on-demand = $10.85 + $27.99 = $38.84). **Avoidable overspend: ~$73**. **Attribution:** both the creation-time miss and the launch-time verification miss were Claude's (not the user's) — the standing policy was clearly in the user's memory files and repo docs; execution failed to read and apply it. **Fix (applied 2026-04-20):** new auto-memory rule `feedback_spot_for_enum_standard_for_merge.md` mandating an explicit `az vm show --query priority` verification step before any >1-hour workload; added pre-launch gate language to POST_MERGEDONE_CHECKLIST.md; refined the policy itself to "spot for enumeration (eviction-resilient), on-demand for merge (eviction-fragile)." All docs that claimed "D128als_v7 spot" for the 2026-04-19/20 100T run should be updated to "on-demand (priority mis-provisioning)" for accuracy. |

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

## April 13, 2026

**100T deployment on spot, then aborted.** Deployed a 100T run on a spot F64 with the (then-still-buggy) solver. The run was evicted after ~3 hours (intra-day Pacific business-hour load). After redeploy, monitoring revealed only ~1.5% of sub-branches committed in 9 hours of wall clock — eviction was killing all 64 in-flight sub-branches each time, and the per-sub-branch node budget (33B) was so large that recovery cost exceeded forward progress. Projected completion under that approach: ~30 days. The 47 committed sub-branches were archived locally (49.7M solutions, sha256 verified against the partial output) and the run was killed. The lesson — sub-branch-granularity recovery is too coarse for spot at large per-sub-branch budgets — drove the design of "Option B" (depth-3 work units) for any future 100T attempt.

## April 14, 2026

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

## April 15, 2026

**Consolidation in C.** Rewrote all post-enumeration analyses as a single `./solve --analyze [solutions.bin]` mode in solve.c. mmap'd file access (no full malloc), packed `uint64_t` boundary masks (8× memory savings), `__builtin_popcountll` for SIMD-friendly intersections, OpenMP parallelism on the heavy 3-subset, 4-subset, MI, and redundancy loops. Validated against the Python results on 742M: every numerical claim matches. Total `--analyze` runtime: 7 minutes (vs ~2 hours for the equivalent Python). Exhaustive 3-subset test went from 36 minutes (Python) to 4 seconds (C). The 4-subset enumeration went from 100 minutes to 37 seconds.

**OpenMP also added to `--validate` and `--prove-cascade`.** Predicted ~10s `--validate` on 742M (was ~2 min). `--prove-cascade` Phase 1 outer loop now parallelized across 31 branches with per-branch result buffer for ordered output (output is identical to the pre-parallel version; only the wall time changes).

**Documentation rewrite.** `solve.c` top-of-file comment updated to reflect the 3030-sub-branch architecture (the older "56-branch" description was stale), bug-history section, all current run modes including `--analyze`, build flags including `-fopenmp -march=native`, OpenMP licensing note. New `DEPLOYMENT.md` captures architecture + lessons + Azure spot-VM provisioning instructions in an appendix. `HISTORY.md`, `SOLVE-SUMMARY.md`, and `LEADERBOARD.md` all updated with the corrected 742M numbers and the {25, 27} truly-mandatory finding. Methodological rule established: any "proven" claim must be either universal or explicitly scoped (e.g., "proven for the 742M dataset"); applied throughout.

**Pushed to GitHub.** 4 commits: solve.c (bug fix + --analyze + parallelization + doc), DEPLOYMENT.md, doc updates, run artifacts.

## April 16, 2026

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

## April 16-17, 2026

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

**Canonical dedup fix (402b835).** The merge was keeping orientation variants across sub-branches while the per-sub-branch hash table collapsed them — an inconsistency. Fixed: merge now uses canonical comparison (orient masked). At 100M: 336,288 → 135,780 unique pair orderings. Selftest updated to `76ada31e...`. Added `verify.py` (standalone Python constraint verifier) and `SOLUTIONS_FORMAT.md` (binary format spec for long-term archival).

**All prior 10T shas are invalidated.** The sha `aa1415...` had 241M silent drops AND orientation duplicates. New reference shas being established with the fixed solver.

**10T depth-3 enumeration completed, merge pending.** All 158,364 sub-branches completed (all BUDGETED at 10T). 56,404 sub_*.bin files on the managed disk (the remainder had 0 solutions). 2.77 billion pre-dedup records. The solver's own merge was killed by the progress-stall watchdog mid-merge (the watchdog didn't know the merge phase legitimately takes 15+ min without progress updates). Watchdog fixed to check solve_output.txt for merge-phase indicators. Subsequent merge attempt on an on-demand F64 was also lost to a spot eviction (the VM was provisioned as spot by mistake). Merge to be re-run on a properly on-demand VM using the current solve.c (with canonical dedup in the --merge path). Sub_*.bin files are intact on the 300 GB managed disk.

**Standalone --merge code path had stale dedup.** The `--merge` flag used `compare_solutions` (full-byte dedup, keeping orient variants) while the solver's normal-mode merge used `compare_canonical` (orient masked). Running `--merge` on the same sub_*.bin files would produce a different sha. Fixed: both paths now use `compare_canonical`.

**External merge-sort implemented.** `SOLVE_MERGE_MODE=external` enables disk-based merge for datasets that exceed RAM. Produces identical output to in-memory merge (verified at 100M scale: same sha, same --verify PASS). Enables merge on small VMs (8 GB) at any scale.

**Hardening pass (2026-04-18, commits ac0bce6 → d4c6355).** Comprehensive code-quality and robustness pass on solve.c:
- **External-sort chunk I/O** — every `fwrite` / `fflush` / `fsync` / `fclose` checked; post-write `stat()` verifies size. Same discipline as `flush_sub_solutions`.
- **Merge-input reads** — `fopen`/`fseek`/`ftell`/`fread` checked in all three merge paths; short reads are now hard errors (exit 20), not warnings. Size-not-multiple-of-32 triggers abort.
- **Signal safety** — `global_timed_out` is now `volatile sig_atomic_t` (was `volatile int`), the only C-standard type guaranteed safe for signal-handler writes.
- **pthread_create** — both launch sites check return code; on failure, already-started threads are joined and the program exits 10 with a clear errno.
- **sha256 preflight** — walks `$PATH` at startup for `sha256sum` (coreutils) or `shasum -a 256` (BSD/macOS); fails fast with install hints if neither is present. Previously the tool's absence was discovered at the very end of a run (silent empty `.sha256`). Modes that don't write digests (`--verify`, `--validate`, `--analyze`, `--prove-*`, `--list-branches`) skip the preflight and stay dependency-free.
- **Integer-overflow guards** — defensive bounds checks before every capacity-doubler and merge-size aggregation. Never-fires in practice, prevents UB on corrupted shard metadata.
- **Thread-safe time** — all 8 `gmtime()` calls replaced with `gmtime_r()` so concurrent metadata writes can't corrupt each other.
- **`--Wall -Wextra` clean** — six `--analyze` warnings fixed, including a real `(p == p)` copy-paste bug that made a LOCKED annotation always fire.
- **Self-path resolution** — `--merge` post-validation uses `/proc/self/exe` to re-invoke the actual running binary rather than `./solve` (broke if the binary was run from elsewhere or installed to PATH).

Selftest PASS at commit d4c6355 (sha `76ada31e...`). No enumeration semantics changed — the hardening is strictly in error paths and infrastructure.

**Second hardening pass + solutions.bin format v1 (2026-04-18, commits 6a1f0bc → 446b42e).** Triggered by an independent scientific/mathematical review of the whole corpus.
- **Exact KW self-check.** The KW[] validator at startup now verifies the pair-partner relationship for all 32 pairs (catches a KW[] typo that swaps a hexagram for a non-partner), checks the distance distribution element-by-element against `{1:2, 2:20, 3:13, 4:19, 6:9}` exactly (was: sums-to-63), and asserts `kw_comp_dist_x64 == 776` exactly (was: "in range [1, 2048]"). The prior check passed for many wrong sequences; the exact form passes only for canonical King Wen. Exit 50 on any failure — downstream claims become unsafe.
- **Record-encoding static asserts.** `_Static_assert` blocks lock `SOL_RECORD_SIZE == 32`, `SOL_HEADER_SIZE == 32`, and the relationship between the bit-packing expression and the canonical-form mask `0xFC`. Any drift in the byte layout refuses to compile.
- **Canonical-dedup correctness proof.** Added a comment block proving that the hash-insert + qsort + merge-dedup pipeline produces one record per canonical equivalence class regardless of path. The reasoning used to be scattered; now it's documented in one place next to the two comparators.
- **solutions.bin format v1.** Files now start with a 32-byte header (magic `ROAE`, uint32-LE format version, uint64-LE record count, 16 reserved zero bytes) before the record stream. Header contains only deterministic-from-input fields, so `sha256(solutions.bin)` remains a pure function of the enumeration inputs. A sidecar `solutions.meta.json` records provenance (timestamp, git hash) outside the canonical file so the sha stays reproducible. See `SOLUTIONS_FORMAT.md` for the full spec and a language-agnostic read-sketch.
  - **Format transition.** All prior `solutions.bin` files are format v0 (raw record stream). Future files are v1. Old files can be verified by running the old `verify.py`; new tools refuse v0 with a clear error. Selftest baseline regenerated: `76ada31e...` (v0) → `403f7202a33a9337...` (v1, same 135,780 records with 32-byte prefix).
- **Reproducibility footgun removed from selftest.** The selftest harness previously passed `60` as a wall-clock safety net. Under load or on slower VMs, that limit fired mid-enumeration, interrupting whatever sub-branches happened to be running — producing non-deterministic sha mismatches in an otherwise correct solver. Now uses node-limit only. Related: the solver prints a startup WARNING if both `SOLVE_NODE_LIMIT` and a wall-clock time_limit are set simultaneously, and a new `REPRODUCIBILITY RULE OF THUMB` block at the top of solve.c documents why canonical runs must use node-limit exclusively.
- **Documentation corrections.**
  - **SPECIFICATION.md §Complement distance** had `|C| = 60` — a documentation error. The correct divisor is 64: `comp(h) = h` requires `63 = 0` and is never true, so all 64 hexagrams contribute to the sum, giving `776 / 64 = 12.125` as the mean complement-pair distance.
  - **Null-model caveat elevated** from a single paragraph in `CRITIQUE.md:136` to lead notes in `README.md` and `SOLVE-SUMMARY.md`. The honest framing: C1+C2+C3 are robust findings; the "4 boundaries uniquely determine KW" result is a property of the constraint-extraction methodology (which produces apparent uniqueness for 9/10 random pair-constrained sequences), not evidence of KW specialness beyond the robust findings.
  - **"{25, 27} mandatory"** reformulated: the minimum structure is `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}` — two mandatory + two interchangeable slots, yielding exactly 2 × 2 = 4 working quadruples. Old phrasing was true but elided the interchangeability.

Selftest PASS at commit 446b42e (sha `403f7202a33a9337...`, v1 format). Zero `-Wall -Wextra` warnings.

**Canonical v1 reference shas established (2026-04-18).** First `solutions.bin` artifacts in v1 format, cross-validated via independent paths.

**D3 10T canonical sha** (confirmed via Phase B re-merge AND Phase C fresh re-enumeration producing byte-identical output):
- **sha256: `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e`**
- Unique canonical pair orderings: **706,422,987**
- Pre-dedup records: 2,772,506,921 (2.77B)
- Partition: `SOLVE_DEPTH=3`, 158,364 sub-branches, 63.1M per-sub-branch node budget
- Verified: `--verify` PASS on all 706M records; C1-C5, sorted, no duplicates, King Wen present
- Archives: `solve_c/runs/20260418_10T_d3_v1/` (Phase B) and `solve_c/runs/20260418_10T_d3_fresh/` (Phase C fresh re-enumeration)
- Cross-validation: Phase B's re-merge of the 2026-04-17 shards produced this sha; Phase C's fresh re-enumeration on a new VM with new disks, same solver, produced byte-identical output. That validates enumeration determinism (backtracking + hash table + flush all reproduce byte-identically across VM / time / fresh run), shard determinism, and merge determinism simultaneously. This byte-identical match is an empirical instance of the Partition Invariance theorem — see [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) for the formal statement and proof.

**D2 10T reference sha** (independent from d3; different partition → different 10T-partial sampling, not expected to match d3):
- **sha256: `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2`**
- Unique canonical pair orderings: **286,357,503**
- Partition: `SOLVE_DEPTH=2`, 3,030 sub-branches, 3.3B per-sub-branch node budget
- Verified: `--verify` PASS on all 286M records
- Archive: `solve_c/runs/20260418_10T_d2_fresh/`
- Note on the count difference: d2 has 52× fewer sub-branches each with 52× more node budget than d3. At the same 10T total, different partitions sample the solution space differently. d3 reaches more unique orderings at 10T because finer partitioning spreads coverage more broadly; d2 invests more budget per sub-branch (some likely reach EXHAUSTED). Neither is "more correct"; both are valid partial enumerations at 10T budget. Under exhaustive enumeration (no budget limit), both partitions would converge on the same canonical count — but we have not yet run to exhaustion at any depth.

**Old invalidated shas, for historical reference only:**
- `c43f251f...d2f2104d` — original 31.6M count, caused by sub-branch filename collision bug (April 2026 Day 5 in the missteps table)
- `aa1415174c...a56719b` — 742M count, caused by combination of 241M hash-drops + orient-variant duplication inflating the raw count (April 2026 Day 8)

Both are reproducibly WRONG and must not be cited as canonical. The 706M d3 and 286M d2 shas above supersede them.

**Operational footnote — in-memory merge auto-mode has an unsafe default at 10T on F64.** Discovered during Phase C: auto-mode's `needed_bytes > total_ram * 7/10` threshold doesn't account for glibc qsort's auxiliary memory on large sorts. At 82 GB buffer on 125 GB VM, peak RSS hit 129 GB → OOM. Phase B avoided this by explicitly setting `SOLVE_MERGE_MODE=external`; Phase C reproduced the OOM on first attempt and recovered by forcing external; Phase D was launched with `SOLVE_MERGE_MODE=external` from the start. **Recommendation: for any merge at or near 10T scale on F64-sized VMs, force `SOLVE_MERGE_MODE=external` rather than trusting auto-mode.** A code-level fix (tighter threshold or in-place sort) is pending operator review.

**SIGTERM graceful-shutdown validated end-to-end.** As a side effect of the Phase D kill/restart, solve received SIGTERM 60 seconds into enumeration. The graceful-shutdown path (signal handler sets `global_timed_out` → worker threads flush current sub-branches → main runs merge → writes valid v1 output) completed cleanly and produced a valid partial `solutions.bin` with 5M canonical records. Not a canonical artifact, but a clean proof that interrupt-driven shutdowns produce usable output.

**SOLVE_TEMP_DIR env var (2026-04-18, commit 5fc1e72).** Lets the operator direct external-merge temp chunks to a dedicated disk while keeping shards and final output on archival storage. Pattern: attach a Premium SSD to the merge VM just for the merge, run with `SOLVE_TEMP_DIR=/mnt/merge-scratch`, then detach and delete the SSD. CWD stays on `solver-data` (Standard HDD) so the final `solutions.bin` archives cheaply. Concrete az CLI workflow in `DEPLOYMENT.md §Premium-SSD-attach-for-merge`. Smoke-tested at 100M scale: byte-identical output to default-temp-dir run, temp chunks correctly landing in the specified directory. Motivated by the d3 re-merge performance findings below.

**Scale limits documented (2026-04-18).** `solve.c` now has an explicit comment block at the `MAX_SORTED_CHUNKS` definition describing the external-merge ceiling: **16 TB pre-dedup at default chunk size = ~2,000T node enumerations**. Error message on hit points at the mitigation (`SOLVE_MERGE_CHUNK_GB=16` or higher). `DEPLOYMENT.md §Known scale limits of external merge` captures the operator-facing version; `DEVELOPMENT.md` Known Gotchas has the developer-facing summary. The `ulimit -n = 1024` default hits first in practice (~500T) and is a one-line shell fix.

**D3 re-merge performance lessons (2026-04-18).** First production-scale test of the external merge-sort path (landed in commit 2752ce6). Lessons from the 2.77B-record, 83 GB external merge on `solver-data` (Standard_LRS 300 GB HDD-tier):

- **Disk tier dominates merge time.** Standard_LRS is capped at ~60 MB/s and 500 IOPS — correct choice for long-term archival of shards (~$3/month for 300 GB) but wrong for active merge-phase compute. Observed ~6-7 min per 4 GB sorted chunk, ~20 chunks total for 10T input → ~2-3 hours phase 1 + ~30-45 min phase 2 = ~3-4 hours wall. At F64 on-demand ($3.87/hr), that's $12-15 for the merge alone — roughly 6× the in-memory cost on the same VM, 3-4× the external-on-Premium-SSD cost.
- **In-memory is fastest when it fits.** F64als_v6 has 128 GB RAM; the 10T pre-dedup buffer is ~89 GB, which fits comfortably. Auto-mode would have selected in-memory for this merge (~30 min, ~$2). `SOLVE_MERGE_MODE=external` was forced for this run deliberately — the external path had been smoke-tested at 100M scale but never at production scale, and the $10 overrun on this run was worth the validation data point.
- **Premium SSD is the sweet spot for external mode.** Recommended pattern when external is required (either by RAM constraints or deliberate test): attach a Premium-tier data disk (P20 512 GB or P30 1 TB) for the duration of the merge, do the merge on SSD, copy the final `solutions.bin` back to `solver-data` for archival, then detach/delete the SSD. Prorated Premium cost is pennies for a few-hour merge; throughput improves ~3-4× over HDD.
- **100T is not feasible in-memory on practical VMs.** 100T ≈ 27.7B pre-dedup records ≈ 830 GB. In-memory would need M-series (2-4 TB RAM, $15-30/hr — 10× the cost for marginal benefit). Practical 100T path: **F64 + Premium SSD (P40 2 TB) + external merge** at ~3 hours, ~$13-15.
- **Takeaway for `DEPLOYMENT.md`.** The disk-tier choice at merge time matters as much as VM SKU choice. `solver-data` stays Standard because shards are cold data; attach Premium temporarily when actively merging at 100T scale. Full tables and recommendations are in [DEPLOYMENT.md §Two-phase deployment](../solve_c/DEPLOYMENT.md).

**Pivot to D128als_v7 in westus3 (2026-04-19).** For the first ~10 days of serious enumeration work, everything ran on F64als_v6 in westus2 — 64-core AMD EPYC 9004 (Genoa, Zen 4), $0.79/hr spot. At project start, F64 was the obvious pick: "compute-optimized" branding, newest AMD generation then available, quota approved quickly. The next-generation `Dalsv7` (Zen 5 Turin) didn't enter Microsoft Learn's SKU tree until `ms.date: 2026-03-10`, so any pre-March quota request defaulted to v6.

**The trigger event.** On 2026-04-18, a D128als_v7 quota request was filed in westus2 to enable wider parallel 100T enumeration (128 cores vs 64, 256 GB RAM vs 128 GB). Microsoft denied it the same day citing "high demand for virtual machines in this region." A fallback D64als_v7 request was also denied. Operator asked about alternative regions, which prompted pulling authoritative specs from Microsoft Learn and Vantage pricing pages.

**The counterintuitive finding.** Comparing the two SKU families head-to-head:

| SKU | Architecture | Boost clock | Spot $/hr | $/core·hr |
|---|---|---|---|---|
| F64als_v6 | Zen 4 Genoa | 3.7 GHz | $0.826 | $0.0129 |
| D64als_v7 | Zen 5 Turin | 4.5 GHz | $0.501 | $0.0078 |

**D64als_v7 is both cheaper AND faster per-core than F64als_v6.** The "compute-optimized premium" Azure charges on F-series only pays off *within* the same generation. Across a generation boundary (v6 → v7, Genoa → Turin, Zen 4 → Zen 5), the newer general-purpose SKU wins on every axis — clock speed, IPC, price. Per unit of solve.c work, **D-series v7 delivers ~2.2× more compute per dollar than F-series v6** on spot. This wasn't a cost-optimization failure at project start; it was a temporal artifact. The SKU economics flipped when Dalsv7 went GA in March 2026, and the project hadn't reexamined its SKU choice until the quota denial forced it.

**Region hunt succeeded.** A 128-vCPU Dalsv7 quota was granted in **westus3** on 2026-04-19. westus3 is a newer datacenter in the same US region pair as westus2, so cross-region egress is cheap (~$0.02/GB) and latency is low. Managed disks are region-locked — `solver-data` and the two validation disks stay in westus2 as the canonical archive — but that's fine: partition invariance ([PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)) guarantees the same `solutions.bin` regardless of which region or SKU produced the shards. A fresh 10T enumeration on D128/westus3 reproducing canonical sha `f7b8c4fb…` would be an additional reproducibility proof, not a data migration problem.

**Standing policy going forward:**

- **Large-scale enumerations (≥10T)**: D128als_v7 spot in westus3. Full 128-thread parallel on first-level branches, ~2.3 hrs for 10T, ~23 hrs for 100T.
- **Merges**: D-series in westus3 sized to the RAM profile, not core count (merge is single-threaded heapsort). d2 10T fits in D16als_v7 (32 GB RAM), d3 10T needs D64als_v7 (128 GB RAM) minimum for in-memory, D96als_v7 (192 GB RAM) safer. External-merge mode with Premium SSD temp storage when RAM-constrained or >30T.
- **Archival**: westus2 `solver-data` remains authoritative. westus3 runs produce their own disks per run; kept or destroyed case-by-case.
- **F64als_v6**: retained for short runs, analysis, or when westus3 spot is evicted — but no longer the default for new large runs. The 10T d2/d3 canonical shas established on F64 in westus2 remain authoritative.

**Cross-region sha validation — COMPLETED 2026-04-19 ~07:35 UTC.** The D128/westus3 validation ran in sequence:

- **1T smoke test** (D128als_v7 spot): 57m 44s wall, $1.63. Produced a valid v1 `solutions.bin` with 134M canonical records. Pipeline validated end-to-end on Zen 5 Turin hardware.
- **10T canonical run** (same VM): 82m 57s enumeration + 51m 47s in-memory heap-sort merge = 2h 14m 44s total, $3.81. Produced sha256 `f7b8c4fb…` — **byte-identical to F64 westus2 canonical**.
- **External-merge validation** (same shards, P20 Premium SSD attached via `SOLVE_TEMP_DIR`): 42m 59s, $1.26. Same sha256 `f7b8c4fb…`.

**4-corners validation grid now complete**: {Zen 4 F64 westus2, Zen 5 D128 westus3} × {external merge, in-memory heap-sort} — all four combinations produce byte-identical canonical output. Cross-region + cross-SKU + cross-generation + cross-merge-mode reproducibility confirmed. This is the strongest empirical validation of `PARTITION_INVARIANCE.md` achievable short of exhaustive enumeration.

**Measured scaling (D128als_v7 vs F64als_v6 on 10T d3):** enumeration ~3.6× faster on D128 (82:57 vs ~300 min); merge ~1.3× faster per-core (Zen 5 IPC + DDR5-6000 advantage on single-threaded heap-sort); total pipeline ~3× faster and ~2.4× cheaper at spot pricing. This exceeds the pre-run 2.6× projection. Full analysis + SKU sizing recommendations in `DSERIES_ROI_REPORT.md` (kept outside the repo as an operator-review doc).

**Archive**: run artifacts (shas, meta, compressed logs, README) in [solve_c/runs/20260419_10T_d3_d128westus3/](solve_c/runs/20260419_10T_d3_d128westus3/). The canonical `solutions.bin` lives on the new `solver-data-westus3` managed disk (300 GB Standard_LRS, bi-region archival).

**Supporting documentation.** Full SKU comparison (with authoritative Microsoft Learn sources) and ROI analysis are maintained as operator review docs at top-of-working-tree, outside the git repo.

## April 19, 2026 afternoon — null-model framework

With the 100T d3 enumeration running on D128 westus3 (Zen 5), attention shifted to null-model testing — systematically measuring how structured permutation families compare to King Wen on the C1/C2/C3 constraints. This had been a long-standing gap in CRITIQUE.md §Missing analyses (acknowledged during the Day 8 scientific reviews).

**solve.c gained eight new subroutines** for structured-null testing (all present alongside the existing enumeration machinery, not replacing it):

- `--null-debruijn-exact`: exhaustive enumeration of all 2^27 = 134,217,728 B(2, 6) Eulerian circuits starting at vertex 0 via randomized Hierholzer. In C, ~80 seconds total. Result: 0 satisfy C1 (proven analytically too — any B(2, 6) satisfying C1 is forced to period-4 structure, contradicting the 64-distinct-window requirement), 0 satisfy C2, 247,048 (0.1841%) satisfy C3.
- `--null-gray`: 256-member orbit of the binary-reflected 6-bit Gray code under rotations × reversal × bit-complement. 0 C1 (analytic: Hamming-1 adjacency is disjoint from C1's required {0, 2, 4, 6}), 256 C2 (trivial), 0 C3 (null range [1792, 2048]).
- `--null-latin`: exhaustive 8! × 8! = 1,625,702,400 Latin-square row × column traversals (each of the 64 hexagrams indexed by upper × lower trigram). 0 C1, **57.96% C2** (strikingly high), 6.67% C3.
- `--null-latin-explain`: analytic decomposition of the 57.96% figure. Row-permutation class census (144 all-Hamming-1 paths in Q_3, 13,680 "some-2-no-3", 1,008 "some-3-no-2", 25,488 "both") weighted by column-perm good counts reproduces the 942,243,840 empirical count exactly.
- `--null-lex`: exhaustive 6! = 720 lexicographic bit-order variants. 0 on all three constraints.
- `--null-historical`: point-tests Fu Xi (natural binary), King Wen, Mawangdui silk-text, Jing Fang 8 Palaces. **Novel finding: three of four ancient Chinese hexagram orderings — KW, Mawangdui, Jing Fang — satisfy C2 exactly**, suggesting C2 may be a shared classical design principle rather than unique to KW. Only Fu Xi (binary, not traditionally divinatory) has Hamming-5 transitions.
- `--null-random`: 10^9 uniformly random 64-permutations via Fisher-Yates + xorshift64. 0/10^9 satisfy C1 (consistent with the theoretical rate of ~10^-44), 0.1828% satisfy C2, 0.002836% satisfy C3.
- `--null-pair-constrained`: 10^9 pair-permutations with random 2-choice orientations (C1 baked in). Measures conditional rates: C2 | C1 = 4.29% (23.5× the unconditional rate) and C3 | C1 = 6.42% (2,264× unconditional). Shows that C1 alone does most of the structural work KW relies on.
- `--null-gray-random`: biased sampler for 6-bit Gray codes via random Hamiltonian walks in Q_6; bounds the C3 rate over the ~10^22 Gray code family tighter than the 256-orbit alone.

**CITATIONS.md** was created to distinguish prior-literature findings from ROAE-original contributions. Key credits:

- C1 (pair structure): classical (Yi Zhuan commentary), formalized in **Cook 2006** *Classical Chinese Combinatorics* (STEDT Monograph 5, 656 pages).
- C2 (no-5-line-transitions): **Terence & Dennis McKenna, *The Invisible Landscape*** (Seabury Press, 1975). Earliest documented public reference per web search; the 1971 Amazonian experience described there is pre-publication but no pre-1975 lectures are indexed.
- C3 (complement-distance ceiling of 776): no prior citation found; believed ROAE-original, with the standing disclaimer that PR-based updates to CITATIONS.md are welcome.

**Doc audit for citation integrity.** At the user's direction, SOLVE.md, SOLVE-SUMMARY.md, CRITIQUE.md, README.md, and CLAUDE.md were updated to soften "we discovered" language where prior literature exists, and to cross-reference CITATIONS.md. Softened 2026-04-19 in commit `5de0676`.

**New analytical results consolidated in CRITIQUE.md.** (a) C1 impossibility proofs for de Bruijn B(2, 6) (period-4 contradiction) and all 6-bit Gray codes (Hamming-disjoint). (b) Latin-square C2-rate decomposition with exact reproduction of the empirical 57.96%. (c) King Wen's own adjacency decomposition: 32 within-pair transitions (Hamming 2/4/6 by C1 construction) + 31 between-pair transitions, with the 14:2 odd-transition concentration and zero Hamming-5 matching the prior-documented 3:1 even:odd ratio (McKenna 1975 / Cook 2006). (d) Open Questions section with 11 falsifiable follow-ups.

**Aggregate across this batch:** 1.86 billion permutations tested across seven structured and unstructured families. Zero satisfy C1 in any. The conjunction C1 ∧ C2 ∧ C3 is uniquely satisfied by King Wen across every tested family. McKenna's "no-5-line-transitions" observation reframed as a likely shared classical design principle across multiple ancient Chinese orderings — not a KW-unique accident.

## April 20, 2026 early morning — 100T d3 canonical lands

100T d3 enumeration + external merge pipeline completed at 00:45 UTC (17:45 PDT Sunday / 2026-04-19). Total wall time: enum 11h 22m (40,927s) + external merge 5h 26m (19,538s) = 16h 48m.

**Canonical result:**
- sha256: `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`
- Records (canonical unique orderings): **3,432,399,297** (~4.86× the 10T count)
- Solutions.bin: 102.3 GB
- Pre-dedup input: 13.8B records, 60,533 merge chunks

**Validation:** `--verify` PASS — all 3.43B records satisfy C1-C5, sorted, no duplicates, KW present. Independent code-path confirms the canonical sha is trustworthy.

**Novel scientific findings from the analyze pass (4156s wall, 69 min):**

1. **The boundary-minimum jumps from 4 to 5 at 100T.** Section [8] exhaustive test of all C(31,4) = 31,465 quadruples: total working 4-subsets = 0. Greedy-optimal 5-set: **{1, 4, 21, 25, 27}**. The earlier "4-boundary minimum" finding (at d2 10T and d3 10T) is SUPERSEDED at deeper enumeration. **Boundaries {25, 27} remain mandatory across all three partitions** — most stable structural finding to date. The true boundary-minimum is partition-depth-dependent; may continue to grow at 1000T+.

2. **KW's C3 = 776 is the CEILING of the constraint, not the floor.** Via `--c3-min`: minimum C3 = 424 (221 records); **9.91% of the canonical set (340,179,649 records) tie with KW at C3 = 776**. KW is NOT the C3-minimum; it's at the maximum of the constraint. Axiom "minimize C3" picks 221 records, not KW. Axiom "maximize C3" picks 340M records including KW. Both simple C3-extremal axioms fail to uniquely derive KW. Phase A Day 1 MVP for Open Question #7 gives a decisive NEGATIVE result for derivability via C3 extremality. Rule 3 ("opposites kept unusually close") is refined: true vs random and vs C1-only, but within C1+C2+C3 canonical, KW is at the ceiling.

3. **Edit-distance distribution heavily right-skewed.** Mode at edit distance 30 (867M records = 25.3%); only 10.87% of records within edit distance 25 of KW. KW sits in a sparsely-populated neighborhood of the solution manifold — most canonical orderings are far from KW, not close.

4. **Shift-pattern conformance: 0.077%** (2,635,756 of 3.43B). Trajectory: 2.69% (d2 10T) → 0.062% (d3 10T) → 0.077% (d3 100T). Not monotonically decreasing; suggests some shift-conforming orderings surface at deeper budget.

**Spot-vs-on-demand misprovisioning (retrospective):** d128-westus3 was inadvertently provisioned as on-demand at $5.146/hr instead of spot at $0.95/hr. Total avoidable overspend: ~$73 on the enumeration portion. See §Missteps (row added 2026-04-20) for the full attribution (Claude's fault, not the user's) and the corrective policy (spot for enum, right-sized on-demand for merge; mandatory pre-launch `az vm show --query priority` gate codified in CLAUDE.md + DEPLOYMENT.md + auto-memory feedback rule).

**Pending work post-MERGEDONE:** viz run on 102.3 GB solutions.bin, Step 8b safety gate, d128-westus3 teardown, P40 scratch SSD deletion. Docs in `petersm3/x/roae` (CURRENT_PLAN, AUTONOMOUS_STATUS, POST_MERGEDONE_CHECKLIST) refreshed.

## April 20-21, 2026 — 1T single-branch Recon + P2 kickoff + solver-d3 lesson

**Recon campaign (32 sub-branches × 1T budget).** Picked the 32 lowest-yield-at-100T sub-branches, ran each at 1T (1,580× the 100T per-sub-branch budget), serial-by-default solve.c. Full results at `solve_c/runs/20260420_singlebranch1T_d32westus3/` and `x/roae/RECON_1T_RESULTS.md`.

Key findings:
- **0 of 32 EXHAUSTED.** All BUDGETED. 1T wasn't enough to exhaust any low-yield branch.
- **8 distinct yield values across 32 branches, strong clustering** — every prefix class lands on exactly one of 959, 1599, 33372, 34981, 663369, 1110543, 2679422, or 3212005. Orientation-symmetry dominates in this low-yield subset.
- **Yield-at-100T was a poor proxy for tree size.** Branches with identical 100T yield = 24 grew anywhere 67× to 133,833× at 1T.
- **Cross-prefix yield equivalence**: 6 branches with DIFFERENT (p1, p2, p3) all yield 1,110,543 — worth investigating (pair-relabeling symmetry candidate).
- The `./solve --yield-report` subcommand (new subcommand added to solve.c for per-sub-branch yield-clustering analysis) confirms 16.3% of multi-variant prefix groups in 100T are perfectly orientation-symmetric. 380 groups have all 2³=8 orientation variants with identical counts.

**Spot eviction rate in westus2 (empirical, 2026-04-20):** 3 evictions in ~7 hours of running time on D32als_v7 spot (~0.43 evictions/hour). 1T campaigns on spot NOT reliably completable; ≤ 500B budgets might be. All recoveries via `az vm start` succeeded within 1 hour. Documented in `x/roae/SPOT_EVICTION_LOG.md`. See §Missteps for the pivot to on-demand that followed.

**westus3 spot quota blocker (discovered 2026-04-20):** Azure denied a quota-increase request for westus3 low-priority vCPUs (stays at 3 cores). Any D-series spot in westus3 is impossible; meaningful spot compute is westus2-only. `d128-westus3` VM deleted to free on-demand quota for the `campaign-westus3` pivot that ran the 32×1T to completion.

**P2 distributional analysis kickoff (acceleration-proposals review).** External proposal covered five directions (SAT #counting, ZDD, GPU enumerator, ML heuristic, scientific reframing to distributional analysis). My review (`x/roae/ACCELERATION_PROPOSALS_REVIEW.md`) recommended: prioritize CPU intra-sub-branch parallelism (P1) + distributional reframing (P2); run SAT-counting as a weekend experiment; skip GPU and ML. P2 implementation started tonight: 10-dim observable-statistics schema defined (`x/roae/P2_OBSERVABLES_SCHEMA.md`), Python compute script written with per-chunk parquet output, running against the 3.43B canonical on `stats-westus3` D16als_v7 at ~0.67M records/sec. First attempt with a single streaming ParquetWriter hung at 99.6%; rewrote to write per-chunk files, re-launched.

**solver-d3 F64als_v6 recreation (second occurrence).** See §Missteps row added this date. Provisioned at 2026-04-20 18:59 UTC to mount `solver-data` for inspection; left running for ~9.5 hrs until operator noticed at 04:30 UTC Tue. Compute cost: ~$7.50 avoidable. Root cause: same anti-pattern as 2026-04-19 — Claude provisions a VM to inspect a disk and never tears it down. Corrective rules codified in CLAUDE.md §"Session-lifecycle VM discipline" and DEPLOYMENT.md §"Ad-hoc VM lifecycle rules."

## April 21, 2026 — P2 distributional analysis + invariance theorem

**Scientific reframing executed.** The "is King Wen unique?" question — long a sticking point for honest scoping in SOLVE.md / CRITIQUE.md — reframed as a quantified distributional claim. Details in [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

**Computational pipeline executed on 3,432,399,297-record 100T d3 canonical** using Python scripts in `scripts/` (compute_stats, p2_marginals, p2_bivariate, p2_joint_density): per-record 10-dim observable-statistics vector (edit_dist_kw, c3_total, c6_c7_count, position_2_pair, mean/max transition hamming, fft_dominant_freq, fft_peak_amplitude, shift_conformant_count, first_position_deviation); per-chunk parquet directory output (3,433 files); streaming-histogram marginals + hexbin bivariate heatmaps + sklearn KDE on 7 informative dimensions with bootstrap 1000× CI. Ran in 66 min on D16als_v7.

**Headline result: KW sits at 0.000% in the joint observable-density distribution, bootstrap 95% CI [0.000%, 0.000%].** KW's log-density under the sample-fit KDE is −128,260 while the entire 100K sample spans log-density [−10.11, −2.98]. The extremity is driven by simultaneous 95th+ percentile values across four independent structural dimensions (c3_total, c6_c7_count, shift_conformant_count, first_position_deviation), not any single dimension — a typical canonical ordering does not concentrate extremes that way.

**Theorem of invariant transition-Hamming distribution (new):** every C1-C5 valid ordering has the identical multiset of 63 consecutive-hexagram Hamming distances `{1:2, 2:20, 3:13, 4:19, 6:9}`, proven directly from C5's budget-constraint formulation. Corollary: any real-valued statistic of that multiset (mean, median, max, variance, etc.) is constant across all 3.43B valid orderings. This retroactively identifies two of the originally-proposed observable dimensions (`mean_transition_hamming` = 3.3492 always, `max_transition_hamming` = 6 always) as structurally invariant — zero discriminative information.

**`fft_dominant_freq` correction:** the marginal analysis initially reported KW's k=16 as "29th percentile" following standard half-bin percentile convention, implying rarity. On closer inspection, k=16 is the **mode** (12.6% of records — 433 million — share this value), not a tail value. KW is typical, not distinguished, on this dimension. The joint-distribution extremity remains despite this correction because it's driven by the four structural extremes, not by FFT features.

**Schema lessons:**
- Observable-statistics schemas should be validated for discriminative power *before* being used as analysis dimensions. Two of ten original P2 dimensions were pure noise due to C5-driven invariance.
- Percentile conventions (half-bin vs strict-less-than) matter when drawing "is KW at the extreme?" narratives — a mode can report as a low-ish percentile under half-bin convention.

## April 21, 2026 evening — Archive integrity incident and remediation

*(All dates in this project use Pacific Time; UTC timestamps from the session log crossed midnight into April 22 UTC during this work, but the Pacific-time dateline is April 21.)*

**Incident.** The 2026-04-21 consolidation — tar-piping d2 10T and d3 10T validation artifacts from `solver-validate-d2` / `solver-validate-d3` (westus2) into `/data/archive/westus2/{d2,d3}` on `solver-data-westus3`, then `gzip -9`-compressing the `.bin` outputs — passed a sha256-manifest verification before the source disks were deleted on user authorization. But the `archive-westus3` VM was torn down with `az vm delete` *without* a preceding `sync && umount /data`. On remounting `solver-data-westus3` on a fresh `verify-westus3` D2als_v7 (2026-04-21), ext4 reported "needs journal recovery" — a signal that writes were in flight when the VM was killed. Journal replay restored filesystem metadata consistency, but cannot recover file *content* truncated between the last application `fsync` and the forced shutdown. This is exactly the corruption class that an earlier sha256-manifest verification can miss if the manifest itself was written while dirty pages still lived in the page cache.

**Verification.** `gzip -t` scan across all 57,754 `.gz` files:

- 57,750 (99.993%) passed
- 4 failed with "unexpected end of file":
  - `d{2,3}/checkpoint.txt.gz` — raw `checkpoint.txt` preserved alongside → redundant `.gz` broken, zero science loss
  - `d{2,3}/enum_output.log.gz` — historical solver stdout logs, no raw source preserved → content lost, non-critical

**Scientific payload check.** `solutions.bin.gz` for both datasets decompressed and re-hashed to the canonical shas documented in CLAUDE.md:

- d2 10T → `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` ✅
- d3 10T → `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` ✅

All 57,748 `sub_*.bin.gz` shards passed. Scientific payload fully intact.

**Remediation.**
1. Regenerated `d{2,3}/checkpoint.txt.gz` from the preserved raw `checkpoint.txt` files.
2. Deleted the two corrupt `enum_output.log.gz` files (unrecoverable, non-critical).
3. Re-ran `gzip -t` sweep over all 57,752 remaining `.gz` files — 0 failures.
4. `sync && sudo umount /data` (clean).
5. Detached `solver-data-westus3`; deleted `verify-westus3` VM + NIC + OS disk + public IP.

**Cost of verification + remediation:** ~$0.07 (42 min on D2als_v7 on-demand).

**Standing rule added.** Any VM-teardown sequence that follows an archive-write workload MUST run `sync && sudo umount <datadisk>` on-host *before* the `az vm` delete/detach commands. Additionally, sha256 manifests for archive verification must be generated *after* a `sync` flush (or ideally post-umount/remount cycle), not from live dirty-page-cache state. Both go into CLAUDE.md §Session-lifecycle VM discipline as explicit gates for any VM attached to `solver-data*` or archive-destination disks.

## April 21, 2026 late evening — P1 parallel `--sub-branch` + depth-5 + scaling measurements

**P1 (parallel `--sub-branch`) landed.** `solve.c` commits `8a31025` (initial depth-4 impl) and `201d706` (depth-5 upgrade) retool the single-sub-branch mode so a single depth-3 prefix (e.g. `./solve --sub-branch 22 0 30 1 20 0`) uses all N available threads to enumerate in parallel, instead of the prior behavior where 1 thread did work and N-1 sat idle. Implementation: ~580 lines added; see `PARALLEL_SUB_BRANCH_DESIGN.md` (staging) for architecture.

**Granularity: depth-5 (p4, o4, p5, o5) tasks.** For the test branch `22_0_30_1_20_0` the task enumerator produces 2,507 valid (p4, o4, p5, o5) tuples — enough to saturate D64 and D128 without idle-core tails. Tasks dispensed in lex order via atomic fetch-and-add; workers snapshot shared depth-3 prefix state then run DFS from step 6. Per-thread hash tables merged at end under "lex-smallest record wins" canonical dedup, which is a no-op for single-threaded DFS (first-inserted is already lex-smallest) and the determinism fix for parallel (collisions resolve to the same winner regardless of scheduling).

**Correctness validated.** On D32als_v7 spot, legacy N=1 vs force-parallel N=1 produces byte-identical output at 100M, 1B, and 10B budgets (three matching sha256s). All 388,785 records in a BUDGETED N=32 output pass C1+C2+C5 via `./solve --verify` (extended to handle raw shard files — peeks at first 4 bytes; if not "ROAE" magic, treats as headerless `sub_*.bin`).

**Measured speedup (D32als_v7 spot, 5B budget):** N=1 baseline 198s → N=32 14s = **14× wall-time reduction**, 44% parallel efficiency. Remaining 56% efficiency loss is ~equal parts (a) task-count ceiling at depth-4 (pre-depth-5 measurement — depth-5 has 48× more tasks and removes this ceiling), (b) shared-atomic contention on the 65K-node-flush budget counter, (c) memory bandwidth on Zen 5c CCDs. Post-depth-5 scaling (measured on D64/D128): 34.9× at N=64 on D128, 36.5× at N=128 — memory bandwidth saturates at N=64.

**Packing experiment (2026-04-21 night).** Running K concurrent `--sub-branch` processes on one VM (each with N threads, K×N ≤ cores) breaks through the single-process atomic-contention ceiling. D128 aggregate throughput rises from 980 M/s (K=1 N=128) to 1.60 B/s (K=16 N=8) — 63% improvement — because each process has its own atomic counter and cache-resident hash table. Measured cost per branch at 50B budget:

| VM | Best packing | $/branch | Notes |
|---|---|---|---|
| D128als_v7 spot | K=16 N=8 | $0.0083 | packing wins 39% vs K=1 |
| **D64als_v7 spot** | **K=8 N=8** | **$0.0080** | ← global cheapest measured |
| D32als_v7 spot | K=8 N=4 | $0.0086 | packing wins only 24% (bandwidth-limited) |

**D64 K=8 N=8 is the measured cost optimum** for single-branch work. D128 K=1 N=128 wins on wall-time (51s vs 491s for an 8-branch batch) at 69% higher cost.

**Detail on the atomic-contention finding:** `sub_sub_shared_nodes` is updated every 65K nodes via `__sync_add_and_fetch`. With 128 threads on a single process, all threads hit the same cache line — serialized. Multiple processes with separate atomic counters (and separate hash tables) eliminate the serialization. A per-CCD atomic counter refactor (16 counters on D128 Zen 5c "Turin Dense", one per CCD) could deliver the packing throughput without needing to run multiple processes; deferred since packing achieves the same effect with simpler user-space config.

**Doc outputs:** `DEPLOYMENT.md` gained a "Single-branch parallel — SKU sizing" section with the measured-optimum table. Raw data + noisy-neighbor analysis + mechanism breakdown archived to `x/roae/P1_SCALING_MEASUREMENTS.md` (staging repo).

**Measurement cost:** $0.45 total across all P1 test VMs (D32 + D64 scaling + D128 scaling + D64 packing + D128 packing + D32 packing).

## April 21, 2026 late-night — P1 v3: per-CCD counters + intra-sub-branch checkpointing

Two post-measurement enhancements to `solve.c` (commit `cca1a40`) closing the P1 work:

**Per-CCD atomic counters.** The packing experiment revealed that single-process throughput caps at ~1 B/s on Zen 5c Turin Dense because all N threads contend on one `sub_sub_shared_nodes` atomic. Sharded the counter into 16 cache-line-aligned slots (one per CCD); each worker writes to slot `thread_id % 16`; budget check sums all slots (~4ns). Expected to bring single-process throughput closer to the measured packed-aggregate ~1.6 B/s on D128. Mechanism is correct by construction; not re-measured on D128.

**Intra-sub-branch checkpointing.** Added a dedicated checkpoint thread that wakes every `SOLVE_CKPT_INTERVAL` seconds (default 60) and snapshots every worker's hash table to `sub_ckpt_wrk<tid>.bin` + the shared-counter state to `sub_ckpt_meta.txt`. Worker synchronization via per-`ThreadState` `ht_mutex` held during `analyze_solution`'s probe/insert (uncontended, ~100ns cost). On restart with the same prefix, `sub_ckpt_load()` consolidates all worker snapshots into worker 0's hash table and restores the shared counter; workers claim tasks from idx=0 (any in-flight-at-eviction tasks re-run, dedup collapses duplicates). On successful completion, `sub_ckpt_cleanup()` deletes the files.

**Spot-viability implication.** At 10T+ per-branch single-branch runs with 60s checkpoint cadence, a spot eviction loses at most 60s × worker_count of work (~tens of seconds of compute). Enables 10T+ single-branch on spot without constant restart-from-scratch on eviction.

**Validation:** selftest passes (sha `403f7202…`), legacy-N=1 vs force-parallel-N=1 byte-identical at 100M+1B budgets, checkpoint thread confirmed firing on schedule via debug instrumentation. Full kill+resume round-trip not measured end-to-end (validation complicated by stale-process leftovers; mechanism code-reviewed correct, uses wall-time-driven dedicated thread so fires regardless of task duration).

**P1 status: ✅ COMPLETE** as of 2026-04-21 late evening. Unblocks single-branch campaigns A–D ([`x/roae/SINGLE_BRANCH_NEXT_STEPS.md`](https://example.invalid); in staging repo).

## Current state (2026-04-21)

**Code.** solve.c carries the core enumeration + `--merge` + `--verify` + `--analyze` + `--sub-branch` + `--null-*` subcommands, plus newer additions: `--c3-min` (complement-distance minimum analysis), `--yield-report` (per-sub-branch yield-clustering and orientation-symmetry report reading an enumeration log on stdin). Per standing rule: all C code lives in solve.c; no separate .c files. Zero compile warnings.

All Python lives in `solve.py` as of 2026-04-21 (single-Python-file rule, modeled on the single-C-file rule): the P2 subcommands `solve.py --compute-stats`, `solve.py --marginals`, `solve.py --bivariate`, `solve.py --joint-density` read the 100T canonical `solutions.bin` / per-chunk parquet outputs and produce the distributional-analysis artifacts. The only Python file outside `solve.py` is `viz/visualize.py` (PCA plots); the `scripts/` subdirectory that briefly held `compute_stats.py`/`p2_marginals.py`/`p2_bivariate.py`/`p2_joint_density.py` during P2 development was retired on 2026-04-21 as those scripts were consolidated into `solve.py`.

**Data.** Canonical v1 reference shas established and 4-corners-validated:
- **d3 100T**: `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` — **3,432,399,297 canonical orderings** (the current primary reference).
- **d3 10T**: `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` — 706,422,987 canonical orderings.
- **d2 10T**: `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2` — 286,357,503 canonical orderings.

All partition-invariance validated. 100T solutions.bin (102 GB) lives on `solver-data-westus3` managed disk (westus3, 1.5 TB Standard_LRS, preserved across VM tear-down).

**Selftest baseline.** `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` (135,780 canonical orderings at 100M, format v1). Verified deterministic across 1/2/4/8 threads with `SOLVE_NODE_LIMIT` only.

**Scientific framing.** C1+C2+C3 are the robust findings (rare or extremal in random permutations). C4-C7 are extracted from KW. The **5-boundary minimum at 100T d3** supersedes the earlier "4-boundary minimum" — boundaries `{25, 27}` remain mandatory across d2 / d3-10T / d3-100T; partition-dependent boundaries shift at deeper budget. Greedy-optimal 5-set at 100T: `{1, 4, 21, 25, 27}`. **KW is at the C3 ceiling (776)**, not the floor — 9.91% of records tie with KW at 776; minimum C3 = 424 (221 records). **Distributional analysis (April 21):** KW sits at 0.000%-ile of joint observable density (bootstrap 95% CI [0.000%, 0.000%]) — joint extremity driven by simultaneous 95th+ percentile values across c3_total, c6_c7_count, shift_conformant_count, first_position_deviation. See `DISTRIBUTIONAL_ANALYSIS.md`.

**Next steps (as of 2026-04-21):**
1. **P1 — parallel `--sub-branch` implementation** (currently single-threaded, ~22M nodes/sec on D32): design doc at `x/roae/PARALLEL_SUB_BRANCH_DESIGN.md`, implementation plan at `x/roae/P1_IMPLEMENTATION_PLAN.md`. Gating dependency for any further single-branch campaign at meaningful budgets. Without P1, Pass 1 (10T per branch) takes 5 days serial; with P1 it's ~3 hrs.
2. **P3 — SAT #counting weekend experiment** (ganak / d4 / sharpSAT-TD). Encode C1-C5 as CNF, hand to modern model-counter, see whether a closed-form exact count for the full C1-C5 ordering count is attainable. Low cost (~$5), high variance on outcome. Parallel to P1.
3. **Distributional-analysis follow-ups**: schema v2 drops the two C5-invariant dimensions (mean/max transition hamming); denser KDE on 1M+ anchor points; stratified analysis conditional on position_2_pair; formal joint-hypothesis testing with Bonferroni / permutation.
4. **Single-branch campaign follow-ups** (blocked on P1): A = yield-16 laggard budget ladder (try for first EXHAUSTED); B = orientation-symmetry structural test on `(20,*,21,*,26,*)` cluster; C = cross-prefix-equivalence investigation on the 6 branches at yield 1,110,543; D = mid-yield calibration (10 branches at 100T yield=1,116).
5. **Disk decommissioning** (pending user approval): `solver-validate-d2`, `solver-validate-d3` (both 300 GB Unattached, westus2, superseded by 100T canonical), `solver-data` (westus2, 300 GB Unattached, superseded). Rule: never auto-delete; user approval required. `solver-data-westus3` stays (holds the 100T canonical).
6. **Scientific-review follow-ups** from `x/roae/` staging: formal proof of forced-orientation theorem (Lean/Rocq, Level 2), technical report (#14), bootstrap confidence intervals already added for the P2 joint-density claim.

## Infrastructure (2026-04-21)

- **Orchestrator VM** (`claude`, D2as_v6, westus2 zone 2): orchestration, analysis, git. $0.09/hr on-demand. Can't be stopped without ending the session.
- **Enumeration VMs (standing rule — updated 2026-04-20 & 2026-04-21)**:
  - **Spot for enumeration, on-demand right-sized for merge** (see CLAUDE.md §"Cost control — VM purchase type"). Mandatory pre-launch `az vm show --query priority` verification.
  - **westus2 has 128-core spot quota (approved);** westus3 spot quota remains at 3 cores (quota increase denied 2026-04-20). New spot enumeration compute pivots to **westus2**.
  - D128als_v7 spot: $0.95/hr westus2. Zen 5 Turin, 128 cores, 256 GB RAM. Saturates at ~2.5B nodes/sec across 128 threads in full-enumeration mode; single-threaded `--sub-branch` = ~22M nodes/sec (P1 would change this).
  - Single-branch campaigns at scales <10T: D16-D32als_v7 spot in westus2 is cost-efficient (~$0.13-0.24/hr).
- **Merge VMs**: **on-demand, right-sized** (merge is single-threaded heapsort; 1-2 cores used, rest idle). d3 10T merge → D16als_v7 on-demand (~$0.50/hr × 1h). d3 100T merge → D32als_v7 on-demand (~$1.30/hr × 5h). Never D128 or F-series for merge — wastes cores.
- **F-series VMs BANNED** (2026-04-21, after two `solver-d3` F64als_v6 spot incidents cost ~$32.50 avoidable). All D-als-v7 family going forward. See CLAUDE.md §"Cost control — SKU family restrictions" and DEPLOYMENT.md §"Ad-hoc VM lifecycle rules."
- **Session-lifecycle VM discipline** (2026-04-21): every `az vm create` in a Claude-driven session must pair with teardown in the same command sequence or wakeup prompt. Session VM log at `/tmp/claude_session_vms.txt`. Reconcile at session end.
- **Managed disks (current, as of 2026-04-21):**
  - `solver-data-westus3` (westus3, 1500 GB Standard_LRS, **Unattached**): holds 100T canonical `solutions.bin` (sha `915abf30…`, 102 GB) at the root; also holds the archived d2 10T and d3 10T validation artifacts at `/data/archive/westus2/{d2,d3}/` (~540 GB compressed, 57,752 gzip-verified `.gz` shards + supporting metadata, integrity-re-verified 2026-04-21). **Primary scientific reference — never delete.**
  - `solver-data` (westus2, 300 GB Standard_LRS, **Unattached**): stale partial shards from pre-100T runs; held pending decommission decision per user's "investigate later" directive.
  - ~~`solver-validate-d2`~~, ~~`solver-validate-d3`~~ (westus2, formerly 300 GB each): **deleted 2026-04-21** after user authorization — contents migrated to `solver-data-westus3` archive path, sha-manifest-verified pre-delete, gzip-integrity-re-verified post-delete (see §"April 21, 2026 evening — Archive integrity incident and remediation").
  - Premium SSD temp disks for external merges: ephemeral, provisioned/destroyed per merge.
- **Atomic file writes** in solve.c (write to .tmp, fsync, rename). Prevents mid-eviction corruption.
- **Rotating checkpoints**: 3 copies maintained locally.
- **All run outputs archived** in `solve_c/runs/<YYYYMMDD>_<description>/` with README.md + sha256 verification. Most recent: `20260420_singlebranch1T_d32westus3/` (32×1T Recon).
