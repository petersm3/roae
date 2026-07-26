# Development notes

Notes for anyone picking up this project — human or AI — who wants to reproduce
the results, extend the analysis, or continue the engineering work.

This is a *conventions* document, not a *reference*. Concrete technical details
live in:

- [solve.c](../solve.c) top-of-file comment — architecture, all run modes, bug
  history, build flags, environment variables.
- [HISTORY.md](HISTORY.md) — day-by-day project narrative, including missteps
  and the forensic trail that led to each correction.
- [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) — plain-language findings.
- [SPECIFICATION.md](SPECIFICATION.md) — formal constraint definitions.
- [CRITIQUE.md](CRITIQUE.md) — limitations, statistical caveats.
- [DEPLOYMENT.md](DEPLOYMENT.md) — cloud-VM deployment architecture + lessons.
- [enumeration/LEADERBOARD.md](../enumeration/LEADERBOARD.md) — current state of
  the enumeration.
- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — full `solve.c` command-line reference
  (subcommands, env vars, exit codes).
- [ROAE_PY_CLI.md](ROAE_PY_CLI.md) — full `roae.py` analysis-CLI reference.

---

## Project conventions

### "Proven" language must be universal or explicitly scoped

Any claim calling something "proven" must be a universal/formal proof. If the
proof is scoped (e.g., a computational finite-case check over a specific
dataset), the scope must be stated explicitly in the same sentence.

- Universal: "proven"
- Scoped: "proven for the 742M dataset", "proven at 10T node budget",
  "exhaustively verified for all 4,495 three-subsets against the current
  dataset"
- Acceptable weaker alternatives: "exhaustively verified", "empirically
  confirmed", "no counterexamples found among N tested"

Same rule applies to synonyms: "theorem", "guaranteed", "verified formally".
These imply universality.

This convention emerged from the 2026-04-14 bug discovery: an earlier
"31.6 million unique orderings" figure was a ~23× undercount, but the bug was
deterministic so the sha256 reproduced. Claims couched as "proven" retrospectively
became "proven only under a specific bug." Explicit scoping prevents this.

### A reproducible sha256 is not a proof of correctness

Deterministic code that produces the same output on every run only proves that
the bug (if any) is reproducible. Output *shape* must also be cross-checked
against what the architecture predicts — record counts, file counts, expected
ratios. The sub-branch filename collision bug was invisible to sha-based audits
because the bug was deterministic. It was caught by `ls sub_*.bin | wc -l` (saw
47 files where the architecture predicted ~3030).

Always include at least one "does the output shape match the architecture"
check in any new analysis.

### Dataset-scope any quantitative claim

"742M unique orderings" is a lower bound for the 10T enumeration, not the true
count. Every per-sub-branch enumeration hit the per-sub-branch node budget
rather than completing naturally, so more solutions likely exist beyond the
enumerated space. When citing quantitative results, note the enumeration depth
(10T, 100T, etc.) and whether the budget was saturated.

### Asset preservation

- **Managed data disks are never deleted.** The persistent `solver-data` volume
  holds committed solver work (sub_*.bin files, solutions.bin). Between runs,
  VMs come and go; the data disk stays. On cleanup, delete the VM and its
  orphan OS disk, preserve the data disk.
- **sha256 files are committed but solutions.bin is excluded.** The 23.7 GB
  solutions.bin lives on the managed disk, not in the git repo. `enumeration/
  solutions.sha256` lets anyone verify their own reproduction.
- **Analysis outputs (text, small) are committed.** `enumeration/
  analyze_c_742M.txt`, `analyze_section14_742M.txt`, etc. serve as
  reproducibility references.

### Performance changes — empirical record required

Any commit modifying solve.c hot paths (DFS, prune predicates, hash-table
operations, merge inner loops, SIMD-vectorized arithmetic) or build flags
affecting per-thread rate must append an entry to
[PERFORMANCE_HISTORY.md](PERFORMANCE_HISTORY.md). The entry follows the schema
at the top of that file.

Standardized paired-bench harness lives at `scripts/perf_bench.sh`. It runs
control vs treatment on a single fresh D128als_v7 Spot in westus3, flushes the
page cache between paired runs, captures enum-only wall (merge wall separately,
not part of the speedup metric), and emits a JSON block that pastes directly
into a new entry. Multi-scale: 1B / 1T / 11.2T selectable via `--scale`.

Why this matters: the project narrative — "v1 → v2 → v2+PGO speedup over time,
which changes mattered, which regressed" — is a presentation deliverable. Each
change's contribution (improvement OR regression) needs an empirical
measurement at ship time. Without uniform records, the cumulative-speedup
chart cannot be reconstructed honestly later.

The log captures regressions too: see the `#71 C2 lookahead` entry for the
canonical "instructive loss" example. Failed experiments are first-class
records, not omissions.

### Build reproducibility — toolchain manifest and cross-build verification

A reproducible-from-the-same-binary sha is not the same as a reproducible-from-the-same-commit sha. The 2026-05-12 investigation
(see HISTORY.md "May 11–12 — canonical c34390c0 found irreproducible from git history")
established that the d3 5.6T canonical `c34390c0…` is not reproducible from any committed code state — the same `solve.c` rebuilt on
current hardware produces sha `f66920c1…`. The most likely cause is a build-environment difference (gcc/glibc/libgomp/CPU-microarchitecture)
between the canonical-generation host and today's hosts, possibly amplified by a then-present stack-bounds bug since fixed in `f42f2ae`.

Going forward, every canonical `solutions.bin` archive **must** capture both the source identity and the build-environment identity. Two
shas with matching `solve.c` commit but mismatching build-environment manifest are NOT contradictions — they're a flag that the toolchain
or CPU microarchitecture changed between builds.

#### What to capture per build (mandatory)

Include this block in every canonical run's `metadata.txt` (next to the existing source-commit and env-var fields):

```bash
# Build environment manifest
echo "=== source ==="
echo "solve.c commit:    $(cd <repo> && git rev-parse HEAD)"
echo "solve.c sha256:    $(sha256sum solve.c | cut -d' ' -f1)"
echo "build flags:       <exact gcc command line used>"
echo ""
echo "=== toolchain ==="
gcc --version | head -1
ldd --version | head -1               # glibc
gcc -print-prog-name=libgomp.so.1     # path → confirms libgomp linkage
echo ""
echo "=== host ==="
uname -srvmpio
grep "model name" /proc/cpuinfo | head -1
grep "flags" /proc/cpuinfo | head -1 | tr ' ' '\n' | grep -E "avx|sse|fma|bmi" | tr '\n' ' '; echo
echo ""
echo "=== os image ==="
. /etc/os-release; echo "$NAME $VERSION_ID $VERSION_CODENAME"
[ -r /etc/cloud/build.info ] && cat /etc/cloud/build.info        # Azure image SKU + date
```

The manifest is captured once at build time and embedded in the same `metadata.txt` shipped with `solutions.bin.gz` to cold storage.

#### Drop `-march=native` for canonical builds

`-march=native` emits CPU-specific instructions tuned to the build host. A binary built on Zen 4 may differ from one built on Zen 5 even
with identical source. Replace with a fixed baseline:

- `-march=x86-64-v3` — AVX2 baseline. Works on every Intel Haswell+ / AMD Excavator+. Ubiquitous since 2013. **Default for canonical builds.**
- `-march=x86-64-v4` — AVX-512 baseline. Use if AVX-512 is empirically a measurable speedup AND you're willing to lock yourself to
  Skylake-X / Zen 4+ silicon.

Performance impact of dropping `-march=native` to `-march=x86-64-v3`: typically 5–15% slower for HPC-ish workloads. Acceptable for the
reproducibility guarantee. (Internal performance tuning runs can still use `-march=native`; the rule is only for canonical builds.)

#### Cross-build regression gate

Before adding any new sha to [CANONICAL_HASHES.md](CANONICAL_HASHES.md), the canonical must reproduce on a **second independent binary build**:

1. Build A on VM-A (e.g., westus3 Spot D128, day 1). Capture full manifest. Run canonical workload. Record sha.
2. Build B on VM-B (different day, different host or region, ideally different CPU generation if available). Capture full manifest. Run
   the same canonical workload. Record sha.
3. Sha A must equal sha B. Both manifests are committed to the archive directory alongside the canonical.
4. If shas diverge: the canonical is not yet eligible. Investigate the manifest delta; track down whatever non-determinism the divergence
   reveals (toolchain, microarchitecture, latent UB).

Cost: ~$5–15 of extra VM-hour per canonical for the second build. Negligible relative to the cost of an unreproducible canonical entering
the public record.

The intra-day 4-equivalence test (full-enum L1, deterministic re-run L2, `--merge-layers` of full-enum, `--merge-layers` of 56-branch
reconstruction) remains useful but is **insufficient on its own** — it proves intra-day binary determinism, not cross-build reproducibility.
Use 4-equivalence inside a single VM, then cross-build verify across VMs.

#### Container-pinned toolchain (target state for 1120T+ canonicals; not used by 560T)

The 560T canonical (`9a968fa2…`, 2026-06-08) shipped on the stock D128als_v7 Ubuntu 24.04 image (gcc-13.x, glibc 2.39) without container pinning — the host-fingerprint sidecar + Tier 1 hardening (`solve --validate-canonical`) was deemed sufficient for that scale. For the 1120T extension and any post-2026-Q3 canonical, container pinning remains the **target state** but is **operator-deferred** (Tier 2.1 per `project_tier1_shipped_2026_05_28`). The image would contain:

- An explicit gcc version (e.g., `gcc-13.2.0-23ubuntu4` — pinned by apt version pin or by base-image digest)
- An explicit glibc version (frozen with the base image)
- An explicit libgomp version
- A fixed `-march=` baseline

Build `solve.c` inside the container; the same container + same source → bit-identical binary on any host. Publish the container image digest alongside `CANONICAL_HASHES.md`. This is the gold standard for scientific reproducibility (used by Nature/Cell/CodeOcean submissions, Bitcoin Core, Debian package builds).

Effort: ~2–4 hours of one-time Dockerfile setup, then zero ongoing cost. Status: deferred pending operator authorization; if shipped, the 1120T pre-launch checklist gains a "build container image digest" gate.

#### Canonical pipeline runbook (added 2026-05-17, post-#81 v2 saga)

For the operational mechanics of running a canonical enumeration ≥11.2T — pre-launch checklist, recovery procedures, trap discipline, three-tier storage redundancy, the specific failure modes that have actually occurred in practice — see **`roae-private/CANONICAL_PIPELINE_RUNBOOK.md`** (private staging repo). The cross-build regression gate above is the build-side reproducibility guarantee; the runbook is the run-side operational guarantee. The runbook was forced into existence by the v2 11.2T re-derivation saga (2026-05-16/17, ~$18 across four attempts vs ~$5 first-shot expected) — every failure mode it documents corresponds to a real overrun.

The runbook's mandatory invariants for canonical runs:

- Enum OS disk: explicit `--storage-sku StandardSSD_LRS` (Azure defaults `s`-suffix VMs to Premium_LRS otherwise)
- Shards on attached managed disk (`solver-data-westus3`), not the enum VM's OS disk
- ERR trap preserves the enum VM (never auto-`teardown_enum`); recovery from Phase 2 errors is then a $0.50 Phase-2-only re-run instead of a $4 enum redo
- Cold-archive upload via streaming `curl -T file` (NEVER `--data-binary @file` — OOMs at 2 GB+)
- Mount logic handles existing-ext4 (operator data on solver-data); write canonical outputs to `$ARCHIVE_PREFIX/` subdirectory
- Mandatory $0.02 D2 pre-flight test of the critical-path commands before committing to a 4h+ canonical enum
- Triple-redundancy archival: managed disk + cold archive + claude `/tmp` (size-permitting)

The corresponding operator-memory entry at `feedback_canonical_pipeline_pattern.md` codifies the same rules for Claude.

### Resume-path defense in depth (added 2026-05-14, post-Phase E.2)

The c34390c0 / f7b8c4fb undercount investigation (Phase B re-derivation + Phase E mechanism validation, May 12–14 2026) demonstrated empirically that pre-`c3ad271` solve.c code had at least **two distinct resume-path bugs** that produce silent or noisy data loss: `c3ad271` bug 2 (in-process merge cross-ref rejection in v1 recursive path → loud abort) and `c3ad271` bug 3 (off-by-one frame budget in v2 iterative path → silent record loss). Both fixes are in `main` since May 1 2026. This section documents the five defense-in-depth measures that protect against future regressions of this class.

| # | Item | Status | Where |
|---|---|---|---|
| 1 | SIGTERM-then-resume cycle in selftest | **DONE** 2026-05-14 (verified PASS on post-fix code) | `solve.c` `--selftest-resume` subcommand |
| 2 | Build provenance + resume history in `.sha256` metadata | **DONE** 2026-05-14 (verified emits all fields) | `solve.c` — auto-merge sha-write site + `write_sha256_with_metadata` + `SOLVE_RESUME_HISTORY` env var |
| 3 | Resume-state invariant assertions | **DONE** 2026-05-14 | `solve.c` — DFS resume entry in `backtrack` |
| 4 | Canonical merges off Spot priority | **DONE** (standing operational policy, codified here 2026-05-14) | this doc + operational practice |
| 5 | Differential per-sub-branch checksum during resume | **DONE** 2026-05-14 (4/4 test cases PASS) | `solve.c` `--emit-shard-manifest` + `--verify-shard-manifest` subcommands |

#### Item 1: SIGTERM-then-resume in selftest (`--selftest-resume`) — DONE

**Goal:** convert the c34390c0-class failure mode from "discovered weeks later via cross-build" to "caught at CI time before any canonical work."

**Implementation:** subcommand `./solve --selftest-resume` (solve.c, near the existing `--selftest` block). Three `system()` invocations: (1) PHASE_A `SOLVE_NODE_LIMIT=50000000` in a tempdir, (2) PHASE_B `SOLVE_NODE_LIMIT=200000000` in the same tempdir (resumes from PHASE_A's checkpoint), (3) single-shot `SOLVE_NODE_LIMIT=200000000` in a fresh tempdir. All four runs use `SOLVE_THREADS=4 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1`. Compares the two solutions.bin shas. Match → PASS; mismatch → FAIL with diagnostic citing Phase E.2.

**Verified 2026-05-14:** on post-fix code (current main), `--selftest-resume` produces sha `e43f2905ba8f2cb64a4f0691baae78cadd709058bf8f7c0ada6bcbc6058f34e9` for both the resume and single-shot paths (PASS). This sha matches the reference value in the `c3ad271` commit body, confirming the test targets the historically-buggy code path.

**Wall time:** 3 min 3 sec on a 2-ARM-core / 4-thread `claude` orchestrator. Faster on more-core boxes. Acceptable for a daily / pre-merge CI step; too slow for every-push pre-commit on small boxes. Recommended cadence: include in `make check` or weekly CI, not every commit.

**Future:** add to pre-commit hook (alongside `--selftest`) once a faster scale (e.g., 20M → 50M) is empirically tuned. Phase E.2 used 50M → 200M because that's the exact ratio the c3ad271 fix commit validated at; smaller scales may not exercise enough BUDGETED sub-branches.

#### Item 2: Build provenance + resume history in `.sha256` metadata

**What changed 2026-05-14:** `write_sha256_with_metadata` (solve.c:~3537) now records `SOLVE_DFS_ITERATIVE`, `SOLVE_DFS_CHECKPOINT`, `SOLVE_PER_SUB_BRANCH_LIMIT`, and a `SOLVE_RESUME_HISTORY` line populated from the env var of the same name. Existing fields (date, build, git hash, record count, node count, branches done, `SOLVE_NODE_LIMIT`, time limit, threads) are preserved.

**Operator responsibility:** when restarting a canonical run after Spot eviction or any other interruption, set `SOLVE_RESUME_HISTORY` before the restart. The value is free-form text — recommended format: a comma-separated list of resume events with UTC timestamps and trigger. Examples:

```bash
# After Spot eviction at 90%
SOLVE_RESUME_HISTORY="2026-05-14T18:23:00Z=spot-eviction-at-90%" \
    ./solve 0 64

# After two interruptions
SOLVE_RESUME_HISTORY="2026-05-14T18:23:00Z=spot-eviction-at-90%, 2026-05-14T20:11:00Z=oom-kill-during-merge-stage" \
    ./solve --merge
```

**Schema captured in `.sha256` sidecar (post-2026-05-14):**

```
# Date: <UTC ISO8601>
# Build: <gcc date> <gcc time> (git: <hash>)
# Record format: 32 bytes packed (pair_index<<2 | orient<<1)
# Unique orderings: <count>
# Nodes explored: <count>
# Branches: <total> total, <completed> completed
# SOLVE_NODE_LIMIT=<N>
# Time limit: <seconds> (or absent for time-unlimited)
# SOLVE_THREADS: any (output is thread-independent with node limit)
# SOLVE_DFS_ITERATIVE=<0|1>
# SOLVE_DFS_CHECKPOINT=<0|1>
# SOLVE_PER_SUB_BRANCH_LIMIT=<N>   (only if > 0)
# SOLVE_RESUME_HISTORY: <free-form, "(none — clean single-shot run)" if env var not set>
```

**Future extensions (Item 2 follow-ups, not yet landed):** host fingerprint (CPU model + microcode + kernel version), per-sub-branch checksum manifest reference (see Item 5), VM provider + region + Spot/Regular priority. None of these block landing the schema above.

#### Item 3: Resume-state invariant assertions

**What landed 2026-05-14 (solve.c:`backtrack`, around the DFS-state-resume entry point):**

- Assert `dfs_resume_partition_prefix_len > 0` whenever `dfs_resume_active` is set. A zero value here would silently mis-index `dfs_resume_frames` — exactly the failure-class behind c34390c0/f7b8c4fb's silent data loss.
- Assert each consumed frame's `(pair_idx, orient)` is in valid range `[0, 31] × [0, 1]`. A malformed frame would mis-encode the saved iterator and skip work.

Violation → `_exit(21)` with diagnostic to stderr (distinct from existing exit codes; identifies this rule). Refuses to continue rather than producing a silently-corrupted solutions.bin.

**Future invariant additions (not yet landed):** post-`load_sub_checkpoint` assertion that `branch_nodes ≤ stored_budget` (catches the bug 3 mechanism class at load time, not just at use time); cross-check that the number of `dfs_state` files matches the expected per-thread count after a PHASE_A→PHASE_B handoff.

#### Item 4: Canonical merges off Spot priority

**Standing policy (codified 2026-05-14, was de facto since Phase B):**

- **Enumeration phase** (sub-branch DFS, parallel, OK to evict mid-walk): Spot priority is required (CLAUDE.md cost-control rule). The mid-walk checkpoint capability (`SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1`) handles eviction-recovery safely on post-`c3ad271` code.
- **Merge phase** (`solve --merge`, single-threaded, eviction-fragile): **Standard (non-Spot) priority is required.** A merge that is evicted leaves a partial solutions.bin and re-running it costs 60+ minutes per attempt. The cost difference between Spot D32 ($0.30/hr) and Standard D32 ($1.30/hr) for a 60-minute merge is $1 — trivial vs the risk of corrupting a canonical artifact.

**Operator pre-flight gate (manual, mandatory):** before launching any canonical-scale `solve --merge`, run `az vm show --query priority -o tsv` on the target VM. If output is anything other than `null` or `Regular`, stop and switch to a non-Spot VM.

**Past incidents this rule exists to prevent:** the 2026-04-29 cascade-build-a Spot eviction during the c34390c0 generation's merge phase (one of several contributing factors to the +1,030 record deficit). Pre-Phase-E, this was a soft preference; post-Phase-E it's a hard policy.

#### Item 5: Differential per-sub-branch checksum during resume — DONE

**Implementation:** two subcommands in solve.c:
- `./solve --emit-shard-manifest [path]` — scans `sub_*.bin` in CWD, computes sha256 + size per shard, writes a tab-separated manifest (default `shard_manifest.txt`): `<filename>\t<size>\t<sha256_hex>` per line.
- `./solve --verify-shard-manifest [path]` — reads the manifest and, for each entry, asserts: (1) shard exists, (2) current size ≥ stored size (legitimate resume only grows shards), (3) sha256 of the first `<stored_size>` bytes matches the stored sha256 (catches mid-write corruption + bug-2-class cross-ref divergence). Any failure → `_exit(22)` with diagnostic.

**Workflow for resume-protected canonical runs:**
1. After PHASE_A enum completes: `solve --emit-shard-manifest shards.manifest`
2. (Optional Spot eviction + reallocation. Or asymmetric-extension PHASE_B at higher budget.)
3. Before PHASE_B merge: `solve --verify-shard-manifest shards.manifest`. Aborts loudly if any shard was silently modified by the resume path.

**Verified 2026-05-14, four test cases:**

| Case | Action | Result |
|---|---|---|
| Positive | No corruption | PASS — 1097 entries, 0 missing/shrunk/diverged |
| Negative 1 | Append bytes to a shard (legitimate "resume extended this shard" pattern) | PASS — append accepted (size grew, original content unchanged) |
| Negative 2 | Truncate a shard to 10 bytes | FAIL — `1 shrunk` detected, exit 22 |
| Negative 3 | Modify the first 4 bytes of a shard | FAIL — `1 diverged` detected, exit 22, diagnostic prints both shas |

**Coverage semantics:** the byte-prefix manifest verifier accepts legitimate resume (shard grew) but rejects all bit-level corruption modes of PHASE_A's content (disappeared, shrunk, first-N-bytes diverged). Byte-prefix sha256 over N bytes of a 32-byte-record file IS mathematically a record-level integrity check for those records — sha256 of the byte-prefix and the chain-hash of the individual records are equivalent. So PHASE_A's recorded content is integrity-protected at the record level by this scheme.

**The class byte-prefix CANNOT catch by itself** is semantic: PHASE_B emitting INVALID extra records (records that don't satisfy C1-C5) in the region beyond PHASE_A's boundary. No checksum scheme catches that without a reference to what the "correct" extra content should be (which would require re-running the canonical). This is closed at a different layer: **`solve --verify solutions.bin`** runs C1-C5 structural verification on every record, catching any invalid record emitted anywhere in the file — including the PHASE_B-new region.

**Recommended post-merge integrity gate for any canonical run that went through interruption + recovery** — the two-step sequence:

```bash
solve --verify-shard-manifest shards.manifest   # bit-level integrity of PHASE_A's content
solve --verify solutions.bin                    # C1-C5 structural check of all records
```

Run both; both must pass. The first catches any corruption of PHASE_A's recorded content; the second catches any invalid record emitted anywhere in solutions.bin, including the PHASE_B-new region. (An earlier draft added a `--verify-resume` coordinator subcommand wrapping both; removed 2026-05-15 as redundant — the two-step recipe here is the same thing without adding a maintained subcommand.)

**Cost:** zero at canonical time. Manifest write is O(shard count); manifest verify is O(shard count × shard size) with streaming sha256; structural verify is O(record count) running the same C1-C5 logic as the existing `solve --verify` mode.

### Phase 1 speedup benchmarking methodology (2026-05-15)

Each Phase 1 sha-preserver gets two gates: (a) **sha preservation** at canonical params (the existing plan), and (b) **quantified speedup** vs the v1 baseline (operator request 2026-05-15). Sha preservation is binary (PASS/FAIL); speedup is a measured ratio with confidence interval.

#### Benchmark protocol — codified in `v2_bench_d64.sh` (private repo)

The full protocol lives in the private operational repo at `petersm3/roae-private:v2_bench_d64.sh`. It runs as `./v2_bench_d64.sh <binary> <node_limit> <output_tsv>`. Per-trial discipline encoded into the script (so any future session running it inherits the same rigor):

| Element | Choice / Encoded in script |
|---|---|
| Workload | `SOLVE_THREADS=N SOLVE_NODE_LIMIT=B` at default depth-2; B picked per scale tier (see "Phase 1 scale tiering" below); N defaults to 64 (D64), overridable via env var |
| Trials | 4 per binary minimum (raised from 3 on 2026-05-15 — three trials had insufficient resolution to distinguish a cold-cache outlier from real variance); raise to 6-8 if speedup is suspected close to noise floor |
| Warmup | 1 discarded run per binary at 1/10 the trial budget |
| **Pre-flight: CPU throttling** | **MANDATORY.** Read `cpu MHz` from `/proc/cpuinfo`; abort if below `MIN_FREQ_MHZ` (default 2000). AMD Genoa healthy baseline is 3000-3700 MHz; throttled Spot hosts run at ~600 MHz (observed 3× during v1 Phase B in westus3 May 13-14). Re-checked before every trial — Spot evictions / co-tenant pressure can throttle mid-run. |
| **Pre-flight: no stale processes** | **MANDATORY.** `pgrep -af "solve\|bench"` must return empty (excluding the bench script itself + systemd-resolved). Stale orphan processes from prior work consume cores and bias the benchmark. (Lesson 2026-05-15 — see HISTORY.md §"Methodology lesson learned (and contamination correction)".) |
| **Between trials of same binary** | `sync; echo 3 > /proc/sys/vm/drop_caches` (needs sudo) + `sleep ${COOLDOWN_SEC}` (default 60s). Clears page cache and lets thermal/frequency state settle to a comparable starting point for each trial. |
| **Between binaries** | Operator-driven: **reboot the VM** between binaries (`sudo reboot`; ~60-90 sec to SSH-ready). Each binary's 4-trial sequence then starts from full cold-state, so cross-binary comparison is fair. The bench script handles per-trial state within one binary; reboot orchestration is operator-managed (or could be wrapped by a higher-level script). |
| **Host fingerprint** | Captured per run: kernel, CPU model, microcode, core count, AVX-512 feature presence, binary sha + size, run params, CPU MHz at start. Written as `# ` comments at the top of the output TSV. Lets retrospective analysis correlate weird numbers with the specific physical Spot host. |
| Metric | wall time from `/usr/bin/time -f "%e"`; speedup = `mean(baseline_time) / mean(optimized_time)` |
| Reporting | TSV with per-trial wall time + cpu_freq_mhz at trial start; mean ± stddev computed offline. Confidence interval = `stddev / mean`; speedup ratios within that floor reported as "within noise" rather than as a positive result. |

#### Phase 1 scale tiering on D64als_v7 64-thread

| Scale | Wall/trial | 4-trial × 3-binary cycle wall | Cost (Spot $0.50/hr) | Purpose |
|---|---|---|---|---|
| 100M | ~5-10s | <2 min | ~$0.02 | sha preservation only (selftest scale); too short for speedup signal |
| 10B | ~10-15s | ~3-4 min | ~$0.03 | quick sanity sweep |
| **100B** | **~1-2 min** | **~30-40 min** | **~$0.25-0.33** | **default Phase 1 speedup measurement** — long enough to escape startup-dispatch noise, fast enough for iterative AVX-512 dev |
| 1T | ~12-15 min | ~3 hr | ~$1.50 | canonical-correlation confirmation (run once per Phase 1 task after the 100B numbers settle) |
| 11.2T canonical | ~77 min | ~15 hr | ~$7.50 | mandatory sha-preservation regression — operator-gate, not iterative |

Recommended workflow during AVX-512 dev (Phase 1a, 3-5 days engineering): provision one D64 Spot VM, leave it running for the session, iterate at 100B between code changes (~30-40 min per cycle), then run 1T once at the end of each binary's tuning to confirm canonical-scale behavior. ~$5-15 in compute for the whole Phase 1a depending on session length.

Reboot-between-binaries operator pattern:

```bash
# On D64 VM, post-provisioning:
./v2_bench_d64.sh /path/to/solve_baseline 100000000000 baseline.tsv
sudo reboot
# wait ~60-90 sec, SSH back in
./v2_bench_d64.sh /path/to/solve_avx512 100000000000 avx512.tsv
sudo reboot
./v2_bench_d64.sh /path/to/solve_pgo 100000000000 pgo.tsv
# offline analysis: compute mean/stddev/speedup from the three TSV files
```

#### Host strategy

- **`claude` orchestrator (D2as_v6, AMD EPYC Zen 4, 2 cores, x86_64):** has **full AVX-512** instruction support (F/DQ/BW/VL/VNNI/BF16/VBMI/VBMI2/BITALG/VPOPCNTDQ — the complete Zen 4 stack), plus AVX2, FMA, BMI1/2, popcount. Suitable for **all sha-preservation regression at selftest scale** AND **AVX-512 development + selftest-scale speedup measurement**. The "scalar fallback path for ARM" plan element from the original V2_IMPLEMENTATION_PLAN_2026_05_06.md is still relevant for actual Cobalt ARM hosts (D-ps-v6 / Cobalt 100 family) — but claude is not one of those; its 2 cores run the full AVX-512 path natively. Wall time on claude is ~45–50s per 200M-node depth-2 trial (after correcting for benchmark contamination 2026-05-15); a full Phase 1 4-trial benchmark completes in ~3-4 minutes.
- **x86 Spot D-series in westus3 (D32 or D64als_v7):** required for **canonical-scale (11.2T) sha-preservation regression** (claude has only 2 cores, can't realistically complete 11.2T in operator-friendly time) and for **AVX-512 actual canonical-scale speedup measurement** (Genoa AVX-512 throughput varies by core count + boost behavior; the 11.2T pilot is the operator-meaningful number). Cost: ~$1.50 per pilot run.
- **Cobalt ARM Spot (Dpsv6 family) in westus3:** required for cross-arch validation that the AVX-512-or-scalar fallback path produces identical sha on ARM. The plan's "validate scalar fallback on ARM" task lives here, not on claude (which is x86 and would never exercise the scalar fallback).

#### Per-Phase-1 task — what gets measured

- **#46 AVX-512:** baseline scalar vs AVX-512-enabled. Speedup expected 1.4–2.0× per the implementation plan; will validate empirically. Development + selftest-scale benchmarks happen on `claude` directly (full AVX-512 stack supported). Canonical-scale speedup measurement on D64als_v7 Spot in westus3 ($1.50, 1.5h). Scalar-fallback cross-arch validation on Cobalt ARM (Dpsv6) — that's the "did the fallback regress when we added the AVX-512 path?" check, not the speedup measurement.
- **#47 LTO:** baseline `-O3 -march=native` vs `-O3 -flto -march=native`. Speedup expected 0–5% (LTO mostly helps cross-translation-unit optimization; single-file project gets modest gains from extra dead-code elimination + cross-function inlining beyond `-O3`'s defaults). On claude.
- **#47 PGO (profile-guided optimization):** baseline `-O3` vs `-O3 -fprofile-generate` → run profile workload → `-O3 -fprofile-use`. Speedup expected 5–15%. On claude. **Build invariant (added 2026-05-24 after the silent no-PGO incident):** use `scripts/build_pgo.sh` for all PGO builds. Under `-flto`, GCC keys the `.gcda` lookup on the output binary's name; if Pass 1 and Pass 2 use different output names (e.g., `solve_inst` vs `solve_U`), Pass 2 silently misses the profile data and falls back to no-PGO with a one-line warning. The helper enforces three rules: (1) same output name in both passes (rename after), (2) `-Werror=missing-profile` on Pass 2 so any future regression fails the build loud, (3) assert `.gcda` count > 0 between passes. Past incident: the v1-vs-v3 paired bench 2026-05-24 measured only +4.38% v3 advantage (vs predicted +9.2%) because PGO silently didn't apply. See `roae-private/V1_V3_PAIRED_BENCH_RESULTS_2026_05_24.md`.
- **#47 huge pages + NUMA:** runtime-environment changes (transparent huge pages, NUMA pinning); benchmarked on the host where they actually apply (D-series VM with NUMA-aware OS).

#### Reporting template (one row per Phase 1 task)

```
| Task | Host | Workload | Baseline (s) | Optimized (s) | Speedup | Notes |
|---|---|---|---|---|---|---|
| #47 LTO | claude D2as_v6 2-thread | 200M nodes depth-2 | <mean ± stddev> | <mean ± stddev> | <ratio> | sha preserved at selftest (403f7202) and at 11.2T regression: <PASS/FAIL/pending> |
```

Each row is appended to a "Phase 1 speedup measurements" table in `HISTORY.md` as each task's data lands.

#### What's measured vs what's claimed

- **Measured:** end-to-end wall-clock speedup on the specific benchmark workload on the specific host.
- **Not claimed without further work:** speedup at canonical 11.2T scale (different memory profile, different per-sub-branch budget, may differ); speedup on hardware not tested (need separate runs per CPU family for AVX-512).

Multi-task composition (e.g., AVX-512 + LTO + PGO together) gets its own line in the table — not assumed multiplicative until measured.

### v1 vs v2 search-space efficiency measurement (planned 2026-05-15, implemented alongside v2)

When v2 lands (after the K-pilot decision and v2 bundled re-baseline), the operator will want to compare v1 and v2 search efficiency — specifically: *given a v1 canonical at budget B finding N records, what is the smallest v2 budget B′ that produces the same N (or a superset of v1's exact records)?* This section documents the design for that measurement so the tooling can land alongside v2 implementation rather than be retrofitted later.

#### Two reasonable questions, two precision levels

1. **Count-matching K (cheaper):** what v2 budget B′ yields the same *number* of unique valid records as v1 at budget B? Answer: K = B / B′.
2. **Set-matching K (stricter):** what v2 budget B′ yields a *superset* of v1's exact records at budget B?

For pure-pruning v2 (skips only doomed subtrees, preserves DFS order), set-matching and count-matching converge — v2's leaf set at any budget is a superset of v1's at the same budget. For v2 that *also* changes DFS order (e.g., #69 variable ordering heuristic), set-matching is strictly harder than count-matching; the two can give different K values at small budgets. Both are useful to measure.

#### Recommended approach: opt-in leaf-rate logger in both binaries

Add an opt-in env var `SOLVE_LEAF_RATE_LOG_INTERVAL_NODES` (default `0` = disabled, sha-preserving) to both v1 and v2 solve.c. When set to a positive integer N, the existing `update_progress()` callsite at solve.c:~2560 also appends one line to `leaf_rate.log`:

```
<elapsed_seconds>\t<total_nodes_walked>\t<sub_branches_done>\t<solutions_c3_so_far>\t<UTC_timestamp>
```

Implementation: a few LoC of additions to `update_progress()` gated on the env var being non-zero. Both v1 and v2 binaries produce comparably-formatted logs. Reuse the existing periodic-checkpoint cadence (every sub-branch completion → progress + checkpoint update); the log just gets one extra append.

#### Post-processor (`solve.py --compare-leaf-rates v1.log v2.log`)

Reads both logs, builds two interpolation curves `leaf_count_v1(nodes)` and `leaf_count_v2(nodes)`. Outputs:

- **K(N) for each leaf count threshold N:** the v1 node count to reach N leaves divided by the v2 node count to reach N leaves
- **Targeted answer for canonical comparison:** "v1 at 11.2T finds 759,608,573 records; v2 reaches that count at B′ ≈ X.XX T" (interpolated from v2's log)
- **Per-leaf-count K curve plot:** ASCII / matplotlib if available

#### What this measures and what it doesn't

**Measures:** count-matching K from instrumented v1 and v2 runs at the same scale. With pure-pruning v2 (no DFS-order change), this is also the set-matching K because v2's coverage is a strict superset of v1's at the same budget.

**Doesn't measure (without further instrumentation):** set-matching K when v2 changes DFS order. For that, v2 would need to emit per-record timestamps (`solutions.bin` companion: `solutions.timestamps.bin`, one int64 per record = node count at which v2 first produced this record). Lookup each v1 canonical record in v2's timestamp map, take the max — that's the set-matching B′. This is heavier instrumentation (~30 GB sidecar at 11.2T scale) but exact.

#### Sequencing

- **Now (free):** design captured here.
- **When v2 work starts:** implement the leaf-rate logger in both v1 and v2 simultaneously (~50 LoC each, opt-in, sha-preserving). One pre-K-pilot v1 baseline run with the env var set produces the v1 reference log.
- **Post-K-pilot:** run v2 with the same env var, run the comparator. Output is the K curve and the "v2 budget to match 11.2T v1" answer.
- **If set-matching precision is needed:** add per-record timestamp emission to v2 only (~50 LoC + a lookup utility in solve.py).

#### Pre-implementation cheaper proxy — "shadow v2" predicate evaluation

An even cheaper *pre-v2* tool would implement only the *predicates* of each v2 pruning rule (#67 mid-walk C3, #68 C5 feasibility, #70 C3 optimistic-completion bound, #71 C2 lookahead) in v1, evaluate them at each DFS step without applying them, and count how many subtrees v2 would have pruned. This gives a K estimate *before* committing to full v2 implementation. ~100 LoC per predicate, one instrumented v1 run at 1B nodes (~$0.50). Recommended as a decision input *before* v2 K-pilot if the v2 implementation cost is significant; skip it if operator is committed to v2 regardless. Captured here for completeness; not the recommended primary measurement.

### Layered enumeration (extension-friendly run organization)

A "layer" is a single `(scope, per-sub-branch budget)` enumeration result.
Layers compose: a later layer can extend an earlier one with higher budget
(or different scope) without destroying the earlier layer's data. This is
how to organize runs that may need to be extended later.

**Layer = directory.** Each layer lives in its own subdirectory under a
`<run_root>/`. Convention: name layers so lexical sort = intended order.

```
<run_root>/
  01_full_5T_2026_04_29/        # layer 0: full enumeration, 5.6T budget
    sub_*.bin                   #   ~158K shards
    checkpoint.txt
  02_extend_dead_50T_2026_04_30/  # layer 1: extension, higher budget on subset
    sub_*.bin                   #   shards only for the extended sub-branches
    checkpoint.txt
  _merged_/                     # produced by --merge-layers
    sub_*.bin                   #   symlinks to winning layer's shards
    solutions.bin
    MANIFEST.txt                #   records which layer won per shard
```

**Eviction recovery is NOT a new layer.** A spot-VM eviction → restart →
checkpoint resume continues writing into the same layer dir. Same scope,
same budget, same data continuation. New layer only when the operator
intentionally chooses a new `(scope, budget)` pair.

**Merge:** `solve --merge-layers <run_root>` walks the layer subdirs in
sort order; for each sub-branch tuple, the LAST layer to contain a shard
wins. Winners are symlinked into `<run_root>/_merged_/`, the standard
merge runs in that dir, and produces `<run_root>/_merged_/solutions.bin`
plus a `MANIFEST.txt` recording each shard's source layer. The result is
deterministic — given the same set of layers, the merged sha is stable.

**Extending a run:** to raise the per-sub-branch budget on some subset of
sub-branches, create a new layer dir and run `solve --branch <p1> <o1>` (or
the full enum scoped to a subset) with `SOLVE_PER_SUB_BRANCH_LIMIT=<higher>`.
The new layer will only contain shards for the extended sub-branches; the
earlier layer's shards remain authoritative for everything else.

**Rollback** is `rm -rf <new_layer>` (and `_merged_/`); the prior state is
intact. Compared to in-place extension (which would overwrite the earlier
shards), this is non-destructive.

### Storage strategy: parallel redundancy and long-term archival

> **Status: OPTIONAL / ASPIRATIONAL — not currently in use.**
> The entire Azure Blob Archive flow below is a designed-but-undeployed
> backup tier. We are not confident enough in the current `solutions.bin`
> outputs to archive them, and no automated process has been chosen for
> the upload/sha-verify pipeline. The working copy on the `solver-data`
> managed disk is currently the only redundancy tier. Treat this section
> as a reference for a future archival workflow, not current policy.

The managed disk is the *working* copy of large artifacts, not the *durable*
copy. Two things would motivate a separate backup tier:

1. **Accidental deletion or corruption.** A disk wipe, a rogue `az disk delete`,
   or a mount-point bug can lose the primary copy in seconds. Managed disks
   have Azure's 11-9s durability guarantee, but the operator (me or a future
   session) is the real risk.
2. **Cost during long pauses.** At 23.7 GB (10T) or 80-260 GB (1000T), keeping
   a managed disk idle between sessions costs $0.04-0.40/GB/month. For a
   multi-month pause, that adds up fast. Blob Archive tier is ~40× cheaper
   per GB.

**Proposed parallel-backup policy (would run after any canonical run, once
we establish a canonical run and choose an automation mechanism):**

For every canonical enumeration (10T, 100T, 1000T, or any run that produces a
sha256 referenced in committed docs):

1. After sha256 verification of `solutions.bin` on the working disk,
   upload to Azure Blob Storage with the Archive access tier:
   ```
   az storage blob upload \
     --account-name <storage-account> \
     --container-name roae-archives \
     --name <run-id>/solutions.bin \
     --file /data/solutions.bin \
     --tier Archive
   ```
2. Alongside `solutions.bin`, upload (Archive tier for all):
   - `solutions.sha256` — validates any future download
   - `solve_results.json` — run metadata
   - The compiled `solve` binary used for the run (~100 KB)
   - `git rev-parse HEAD` written to a `git_hash.txt` (~50 bytes)
   - `checkpoint.txt` — per-sub-branch yield data (needed for saturation
     analysis at any future scale)
   - A README documenting run date, `SOLVE_NODE_LIMIT`, VM SKU, total cost
3. Sha-verify the upload by downloading the blob's sha256 file and comparing.
4. Once verified: the managed disk remains authoritative for active work;
   the blob is the durable backup.

The 10T canonical run (`aa1415174c...b719b`, 23.7 GB) was the original
candidate, but that sha is now known to be an undercount (see HISTORY.md Day
8). No run has yet been archived. A future canonical 10T (once the d3 and d2
reference shas land) would be the first candidate. At Archive-tier pricing
(~$0.00099/GB/month) a 10T backup would be ~$0.02/month — essentially free
insurance, once we are confident in the output.

**Validation-first approach for major solver refactors.** When significant
enumeration-path refactoring occurs (e.g., the Option B depth-3 work-unit
rewrite for 100T), re-run the 10T enumeration with the new solve.c *before*
archiving and *before* deploying 100T. If the retooled solve.c produces the
same `solutions.bin` sha256 (`aa1415174c...b719b`), that proves the refactor
did not alter enumeration semantics. Only after this sha-identity check
passes should the 10T output be archived and the 100T run deployed. The
refactor might touch infrastructure (checkpointing granularity, work-unit
partitioning) without changing the enumeration output; the sha-identity
check distinguishes these cases.

**Archive folder taxonomy.** For auditability and retrieval:
- Folder name: `<run-name>_<YYYYMMDD>_<sha8>/` where `sha8` is the first 8 hex
  chars of solutions.bin's sha256. Example: `10T_20260414_aa141517/`.
- The sha8 in the folder name self-describes the run identity without opening
  blobs. Multiple runs with identical sha8 (deterministic re-validation) are
  distinguishable by date.
- Inside each folder: `solutions.bin`, `solutions.sha256`, `solve_results.json`,
  `checkpoint.txt`, `solve` binary, `git_hash.txt`, `README.txt`.

**Long-term pause procedure (when stepping away for weeks-to-months):**

1. Ensure the parallel backup above exists and has been sha-verified.
2. Optionally download a local copy to operator-controlled hardware (external
   SSD, home server) as a third tier of redundancy. Cost: one-time transfer.
3. **Delete the managed disk** (only after both blob backup and, if chosen,
   local backup are verified). Drops ongoing storage cost from
   ~$0.04/GB/month to ~$0.001/GB/month. For 260 GB over 6 months this is
   ~$64 saved.
4. Delete all VMs. Full idle state.

**Rehydration procedure (resuming work):**

1. Request rehydration from Archive to Hot tier:
   ```
   az storage blob set-tier \
     --account-name <storage-account> \
     --container-name roae-archives \
     --name <run-id>/solutions.bin \
     --tier Hot --rehydrate-priority Standard
   ```
   Standard priority: 1-15 hour wait, cheapest. High priority: <1 hour, costs
   a few dollars for multi-GB blobs.
2. Poll rehydration status: `az storage blob show --query properties.rehydrationStatus`
3. Create a new managed disk sized for the run (see "Running on cloud"
   section for sizing), provision merge VM, attach disk.
4. Download blob to disk inside the VM (free within-region egress, ~10-30 min
   at spot VM network speeds for 260 GB).
5. Sha-verify against the preserved `solutions.sha256`.
6. Resume.

**Cost-tier reference (westus2, April 2026 approximate):**

| Tier | $/GB/month | Min retention | Restore time |
|---|---|---|---|
| Managed Disk (Standard HDD) | $0.041 | none | instant (attach) |
| Blob Hot | $0.018 | none | instant |
| Blob Cool | $0.010 | 30 days | seconds |
| Blob Cold | $0.0036 | 90 days | hours |
| **Blob Archive** | **$0.00099** | **180 days** | **1-15 hours** |

Archive tier's 180-day minimum retention matches the "several months pause"
use case naturally. Shorter pauses may prefer Cold (90-day minimum) or even
keeping the managed disk.

**What we do NOT back up to archive:**

- The `claude` orchestration VM's OS disk (trivially reproducible via
  `git clone` and standard setup).
- Intermediate `sub_*.bin` shards when a merged `solutions.bin` exists. The
  merged bin is the canonical derived artifact; shards can be regenerated
  only by re-running the enumeration, which the sha256 of `solutions.bin`
  still anchors against.
- Analysis output text files (`analyze_*_742M.txt`) — these are committed to
  the git repo and live there.

---

## Canonical run discipline (added 2026-05-25 after the v3.1 hardening audit)

Every canonical-scale enumeration (≥1T `SOLVE_NODE_LIMIT`) MUST run in a clean, dedicated run directory. The solver enforces this in part with startup gates (LOCK file, `build.sha` check, `.budget` sidecar verification) — but those guard against subsets of the failure modes documented in the audit (`petersm3/roae-private:V3_1_HARDENING_AUDIT_2026_05_25.md`). One mode (Outlier #6: filename-pattern false-positive from foreign `sub_*.bin` files in the run dir) is intentionally NOT enforced in code, because a hard "empty cwd" gate would be too operator-unfriendly. Instead, follow this convention:

**One canonical campaign → one fresh subdirectory.** Pattern: `solver-data-westus3:/<YYYYMMDD>_<lineage>_<scale>_<campaign_id>/` (e.g., `20260521_v2_100T_buildA/`).

What goes in the run dir:
- The solver binary `solve` (or a build-recipe script that produces it)
- `solutions.bin` and `solutions.bin.sha256` (after the merge)
- Shard files `sub_*.bin` and `sub_*.bin.budget` (during enum; the `.budget` sidecars are MANDATORY post-2026-05-25 — `promote_orphaned_shards` refuses to promote a sub-branch without a matching-budget sidecar by default, since strict-default is the post-hardening behavior. Backward-compat escape via `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR=1`. Both `.bin` and `.budget` can be deleted post-archive at operator discretion, except for v3 lineage where the convention is "preserve shards" per `project_v2_100T_precedes_560T` memory.)
- `checkpoint.txt` (always)
- `solve.lock` (during run only; auto-cleaned on normal exit)
- `build.sha` (always; first run creates it)
- Run-metadata file (operator-written, e.g., `RUN_METADATA.txt`, `WITNESS.md`)

What MUST NOT go in the run dir:
- Files matching `sub_*.bin` from another campaign. Even at a different scale, a manually-copied shard from another campaign with the same filename pattern would be picked up by `promote_orphaned_shards()` and merged into the final output, producing wrong-but-deterministic canonical bytes. The `.budget` sidecar partially mitigates (sidecar mismatch → refuse promotion), but a foreign shard with a coincidentally-matching budget would still slip through.
- Build artifacts or staging files matching the shard naming pattern.

If you're recovering from a failed run and need to combine partial shards from multiple attempts: do so in a freshly-created run dir, not in either source dir. The `solve --merge` step is meant to be the single point where shards meet `solutions.bin`; do the assembly explicitly.

For the 560T campaign specifically (per `project_560T_review_gate`): the run-dir convention is mandatory pre-launch and the dir must be created on `solver-data-westus3` immediately before the enum VM is provisioned — no shared / reused dirs. The strict-default `.budget` sidecar check means a fresh 560T enum doesn't need an explicit env var to opt into strict mode — strict is the default. Don't set `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR=1` for 560T; let any missing-sidecar shard re-walk via the LOAD path.

### Auto-protect gates that fire on canonical-enum startup (added 2026-05-26)

Beyond the LOCK / `build.sha` / `.budget` gates above, six more dummy-proof gates fire automatically on every canonical-enum dispatch (no `--xxx` subcommand). Each has an explicit env-var escape; setting the escape is operator-acknowledgment of the failure mode being bypassed. See [SOLVE_C_CLI.md](SOLVE_C_CLI.md) "Hardening overrides" + "EXIT STATUS" for the full env-var / exit-code table.

| Gate | What it checks | Exit | Escape |
|---|---|---|---|
| Auto-selftest | Binary reproduces `--selftest` sha `403f7202…` | 24 | `SOLVE_SKIP_AUTO_SELFTEST=1` |
| Disk-space pre-check | `cwd` filesystem has projected required bytes free | 29 | `SOLVE_SKIP_DISK_CHECK=1` |
| Binary snapshot | Copies running binary to `solve.binary.snapshot` for forensics | (warn) | `SOLVE_SKIP_BINARY_SNAPSHOT=1` |
| Sub-canonical hard-gate | Refuses `SOLVE_NODE_LIMIT < 1T` without `SOLVE_PER_SUB_BRANCH_LIMIT` | 25 | `SOLVE_ALLOW_SUB_CANONICAL=1` |
| Shard manifest auto-verify | Existing `shard_manifest.txt` matches current shards | 22 | `SOLVE_SKIP_AUTO_MANIFEST=1` |
| Auto-emit shard manifest | Writes `shard_manifest.txt` after each flush + promote | — | `SOLVE_SKIP_AUTO_MANIFEST=1` |

Two more fire on the merge path:
| Stack raise | `setrlimit(RLIMIT_STACK, RLIM_INFINITY)` at `--merge` | 28 | `SOLVE_SKIP_STACK_RAISE=1` |
| Auto-verify-solutions | Runs `solve --verify solutions.bin` after `--merge` completes | 30 | `SOLVE_SKIP_AUTO_VERIFY=1` |

`SOLVE_DFS_ITERATIVE=1` and `SOLVE_DFS_CHECKPOINT=1` also default to ON at canonical scale (`SOLVE_NODE_LIMIT >= 1T`) since 2026-05-26 — the operator does not need to set these explicitly for any 11.2T+ run.

For 560T specifically: do NOT set any of the skip-* escapes. The whole point of these gates is to catch silent failures on the ~$50 single-shot 3.5-day enum where forensic recovery cost exceeds the gate-implementation cost by 100×.

### build.sha invariant (Outlier #4)

The `build.sha` file in the run directory holds `sha256(/proc/self/exe)` from the first solve invocation that ran there. Every subsequent invocation re-computes its own `/proc/self/exe` sha and compares — on mismatch, exit 26 with a "build provenance mismatch" error. Purpose: prevent resuming a checkpointed enumeration across two different binaries. The on-disk `.dfs_state` checkpoint encodes search-tree state computed by binary X's prune-stack logic; a different binary Y interpreting that resumed state can produce wrong-but-deterministic canonical bytes — a sha that looks valid but doesn't match any reference and is hard to bisect.

**When the guard fires in practice:**

1. **Same VM, same OS disk across `az vm deallocate` + `az vm start`** — guard passes naturally; `/proc/self/exe` is byte-identical (OS disk preserved). No override needed.
2. **Fresh VM rebuild** (campaign failure-recovery deleted the OS disk; new provision rebuilds solve) — the rebuilt binary has a different sha than `build.sha` on the persistent Premium SSD. The canonical launchers handle this by preserving the stale `build.sha` as `parent_build.sha.<timestamp>` for archival, then deleting it so the new binary writes fresh. No override needed in the launcher's env.
3. **Cross-campaign extension** (e.g., 1120T binary touching 560T's RUN_DIR) — same hygiene step in the launcher's `build()` preserves the parent campaign's `build.sha` and lets the new binary write fresh.
4. **Mid-campaign manual rebuild** (operator ssh's into the enum VM and rebuilds solve directly, bypassing `build()`) — guard correctly fires. Operator must explicitly delete `build.sha` (audited decision) or set `SOLVE_ALLOW_BUILD_MISMATCH=1` for one invocation (audited decision).

**Why solve binaries vary across rebuilds:** `solve.c` embeds `__DATE__`/`__TIME__` macros in diagnostic strings (~6 sites). Every fresh `gcc` invocation stamps a different build time → different binary sha — even from byte-identical source. `glibc`/`libgomp` patches between rebuilds add further divergence. The `build.sha` invariant is therefore host-fragile by construction; it's a strict cross-binary guard, not a cross-source-version guard. A future improvement is `-DSOURCE_SHA=…` deterministic builds that strip the timestamp dependency.

**Override semantics:** `SOLVE_ALLOW_BUILD_MISMATCH=1` lets solve continue on mismatch and overwrites `build.sha` with the current binary's sha so subsequent runs match. The flag has historically been baked into canonical launchers' env as defense; that's no longer the default as of 2026-06-13 — launchers handle legitimate rebuild scenarios via post-rebuild hygiene instead. See [SOLVE_C_CLI.md ENVIRONMENT table](SOLVE_C_CLI.md#environment) for the env-var entry.

### Metadata equivalence across enumeration paths (task #102, 2026-05-26)

Every canonical-scale run now ships with **`solutions.provenance.json`** alongside `solutions.bin` + `solutions.sha256` + `solutions.meta.json`. The provenance file aggregates per-shard `.provenance.json` sidecars (written automatically by `flush_sub_solutions[_d3]` and the orphan-promotion path) into a campaign-level rollup: shard count by status (EXHAUSTED / BUDGETED / INTERRUPTED), final budget distribution, extensions observed, binary / git / host fingerprint sets, cumulative node + record counts, earliest + latest write UTCs.

**Equivalence guarantee.** A single-shot 11.2T enum and a (56 × 100B + 56 × 100B-extension)-merged 11.2T composition produce byte-identical `solutions.bin` (partition invariance) AND structurally-equivalent `solutions.provenance.json` (verified via `solve --compare-provenance`). Same guarantee scales to 560T.

`--compare-provenance` normalizes away timestamps, host fingerprints, and merge-invocation metadata. Must-match fields: `solutions_bin_sha256`, `solutions_bin_record_count`, `shard_count`, `shards_by_final_status` (the EXHAUSTED/BUDGETED/INTERRUPTED counts), `final_budget_distribution`, `cumulative.total_nodes_explored`, `cumulative.total_records_emitted`.

For full schema + design rationale see `roae-private/METADATA_EQUIVALENCE_DESIGN_2026_05_26.md`. For per-cli reference see [SOLVE_C_CLI.md](SOLVE_C_CLI.md) `--compare-provenance` + Files section.

## Known gotchas

### Compile

- Build flags: `gcc -O3 -pthread -fopenmp -march=native -o solve solve.c -lm -lz` (minimum to reproduce canonical sha); `gcc -O3 -flto -pthread -fopenmp -march=native -o solve solve.c -lm -lz` (recommended — sha-preserving, ~2% faster at 100B-node canonical-correlation scale on AMD Zen 4 D64, Phase 1c validated 2026-05-15). The `-lz` (zlib) link flag is required since #169 (native-gzip live compression); it is the only build change and is sha-neutral (gzip is a non-sha-determining storage layer).
- `-fopenmp` parallelizes the `--analyze` hot loops. Without it, pragmas are
  no-ops and everything still compiles + runs single-threaded. `libgomp`
  (gcc's OpenMP runtime) ships with gcc under the GCC Runtime Library
  Exception, so no LICENSE.md change is needed.
- `-march=native` enables popcount / AVX intrinsics. Required for the
  `__builtin_popcountll` paths to hit hardware popcount.

### Reproducible-build recipe (task #110, 2026-05-27)

For canonical-grade reproducibility, use the **deterministic recipe**:

```bash
SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct -- solve.c) \
gcc -O3 -g -march=native -flto -pthread -fopenmp \
    -fno-record-gcc-switches \
    -Wl,--build-id=sha256 \
    -ffile-prefix-map="$(pwd)=." \
    -fdebug-prefix-map="$(pwd)=." \
    -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" \
    solve.c -lm -lz -o solve
```

Compared to the bare `-O3 -flto -pthread -fopenmp -march=native`, these flags add:

| Flag | What it does | Why it matters for reproducibility |
|---|---|---|
| `SOURCE_DATE_EPOCH=<unix-ts>` | Pins `__DATE__` and `__TIME__` to a deterministic value | Eliminates the `.rodata` cosmetic non-determinism documented in `roae-private/TASK_108_SUMMARY_FOR_OPERATOR_2026_05_27.md` Q10 |
| `-fno-record-gcc-switches` | Removes embedded build command line from `.GCC.command_line` section | Builds without referencing the build directory |
| `-Wl,--build-id=sha256` | Derives the ELF build-id deterministically from binary content (instead of random hash) | Two builds of same source on same host produce identical build-ids |
| `-ffile-prefix-map="$(pwd)=."` | Strips the absolute build path from any embedded references | Same source compiled in different directories produces identical binary |
| `-fdebug-prefix-map="$(pwd)=."` | Same for debug info (DWARF section) | Debug builds across hosts have identical DWARF paths |

**Result**: two builds of the same source on the same host produce **byte-identical binaries** (the same `.text`, same `.rodata`, same build-id). The empirical Q10 finding showed that without these flags, two builds had byte-identical `.text` but differing `.rodata` and build-id — cosmetic but messy. The deterministic recipe eliminates the mess.

**Caveat — cross-host reproducibility**: even with this recipe, builds across different physical hosts (different gcc patch, glibc patch, kernel, CPU revision) can produce DIFFERENT binaries — and may produce different canonical sha at BUDGETED-cell-density-sensitive scales like 1T. See the structured `validation_history` block in `CANONICAL_HASHES.md` and the `feedback_canonical_sha_drift_management` memory for the operational discipline.

For canonical campaigns at 11.2T+, this isn't a concern (drift mechanism does not fire at higher scales per Item 4 empirical evidence 2026-05-27).

### Solver

- **Independent verifier**: `roae/verify.py` is a pure-Python (stdlib-only)
  implementation of the verifier recipe in
  [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md) (originally ~160 lines; it has
  since grown the independent re-counting and artifact-check surfaces —
  `--recount`, `--check-certificate` — documented in [VERIFY.md](VERIFY.md),
  alongside the C-side sibling `verify.c`). Reads any format-v1
  `solutions.bin`, reconstructs each 64-hexagram sequence, and checks
  **C1 (pair structure), C2 (no 5-line transitions), C3 (complement
  distance ≤ 776, added 2026-04-19), C4 (starts with
  Creative/Receptive), C5 (exact distance distribution)** plus sort
  order and dedup. No shared code with solve.c — genuine second opinion.
  Usage: `python3 verify.py [--jobs N] /path/to/solutions.bin`. Exit 0
  on PASS, 1 on constraint failures, 2 on header/format errors. Runs in
  ~1-5 minutes on a 10T solutions.bin (single-thread); ~3 hours on a
  100T solutions.bin with `--jobs 16` (CPU-bound at ~19k records/sec
  per Python worker after the 2026-05-08 streaming-reads patch).

- **Independent completeness reference** (added 2026-05-28):
  `python3 verify.py --enumerate-reference NPAIRS` (2 ≤ NPAIRS ≤ 9).
  Does NOT read solutions.bin. Brute-forces the reduced NPAIRS-pair
  problem under the cleanly-reducible structural constraints (C1 + C2 +
  C4; C3/C5 are global over the full 64-sequence and excluded) **two
  ways** — exhaustive generate-then-filter (ground truth) vs
  prune-as-you-go DFS (mirrors solve.c's incremental pruning) — and
  asserts the two produce the identical valid set. A mismatch means a
  pruning step is unsound/incomplete (dropped or added a valid sequence)
  — the "did an optimization silently drop a real solution" failure
  class, checked in independent code. **Scope/limit (honest):** this
  grounds the structural-constraint enumeration *semantics* on a reduced
  problem; it does NOT differential-test solve.c's full enumeration —
  that is infeasible (solve.c never exhausts any cell; global C3/C5
  don't reduce; solve.c has no reduced-pair mode). solve.c prune
  completeness at canonical scale is covered empirically by the K-pilots
  (v1 ⊆ v1+prunes at every tested scale). Exit 0 PASS / 1 mismatch / 2
  bad-arg.

  **Streaming-reads memory model (added 2026-05-08, task #84 follow-up):**
  Each worker uses bounded memory (32 MB streaming batch) regardless of
  input size. Total memory at `--jobs N` is `N × 32 MB`, not `file_size`
  as in the original design. The pre-2026-05-08 verify.py loaded the
  full per-worker chunk via `f.read(chunk_size * 32)` — at 100T scale
  on a 32 GB VM that thrashed the page cache (13× re-read multiplier;
  OOM-killed at 5h 5min). Streaming pattern is the project standard
  for any chunk-based parallel verifier. Banned pattern: `chunk =
  f.read(N * record_size)` for unbounded `N` in a parallel context.

- **Two-tier solver selftest**:
  - `./solve --selftest` (~5 sec on 4 threads): runs a bounded
    enumeration with a fixed budget and checks the resulting
    `solutions.bin` sha256 against the canonical baseline `403f7202…`.
    Catches gross regressions in the constraint logic, partition
    structure, or merge code. Use as a build smoke-test.
  - `python3 solve.py --extended-selftest <path-to-solve-binary>`
    (~10 min on 4 threads, added 2026-04-30): a CI-grade regression
    suite that drives the supplied binary through three subtests +
    a cross-check:
      1. Single-shot 3-way @ 100M nodes (recursive vs iterative vs
         iterative+v2). Catches regressions in the iterative DFS,
         v2 capture, or fork-merge dispatch.
      2. v2 resume @ 50M → 200M (PHASE_A captures, PHASE_B resumes,
         resumed sha must match single-shot 200M sha `e43f2905…`).
         Catches regressions in the off-by-one capture-frame fix
         and the resume gate.
      3. v1 resume @ 50M → 200M (recursive path with the "walk-fresh
         on resume + load_prior_shard" policy). Same sha check.
      Cross-check: recursive single-shot 200M sha == iterative
      single-shot 200M sha (DFS-engine independence).
    Returns 0 on full PASS, 1 on any failure. Suitable as a CI gate
    before commits that touch `backtrack`, the v2 capture/resume
    fields, the bitmap key encoding, or the merge dispatch.

- **Never assume `fwrite` succeeded without checking.** The 2026-04-14
  `solutions.bin` was silently truncated from 23.7 GB to 8 GB because the disk
  filled up mid-write. The solver's sha256 still matched the truncated file
  (sha was computed post-write from what landed on disk). Every `fwrite`,
  `fopen`, `fclose`, `fflush`, `fsync`, `rename`, `fseek`, `ftell`, and
  `fread` now has its return checked at every call site (enumeration flush,
  external-sort chunks, both merge paths). Short reads are hard errors, not
  warnings. Post-write `stat()` verifies size at every file write.
- **Preflight disk space**: `free_disk >= estimated_output × 1.5`. At 10T the
  sub_*.bin shards total ~23 GB AND the final solutions.bin is ~24 GB —
  together they exceed a naive 32 GB disk.
- **Preflight sha256 tool.** `solve.c` shells to `sha256sum` (GNU coreutils)
  or `shasum -a 256` (BSD/macOS) for output digests. The solver walks `$PATH`
  at startup and exits 10 with install hints if neither is available —
  prevents a successful multi-hour enumeration from producing an empty
  `.sha256` file at the end. Modes that don't write digests
  (`--verify`, `--validate`, `--analyze`, `--prove-*`, `--list-branches`)
  skip the preflight.
- **time_limit and reproducibility are incompatible.** For any canonical
  run whose sha256 needs to be reproducible across machines or
  re-enumerations, set `SOLVE_NODE_LIMIT` only and pass `0` for the
  CLI time_limit arg. Per-sub-branch node budgets are deterministic;
  wall-clock interrupts are not. If time_limit fires first, whatever
  sub-branches happened to be running at the N-second mark are tagged
  INTERRUPTED with their partial solutions preserved — and which
  sub-branches those are depends on thread scheduling. Two identical
  invocations of `./solve 60` on the same inputs will produce different
  solutions.bin sha256 under load. The solver prints a WARNING at
  startup when both limits are set together.
  Use time_limit alone for "run N minutes, take what we got"
  exploratory workflows only. The --selftest harness previously passed
  a 60-second time_limit as a safety net; under load, that caused
  spurious sha-mismatch failures. Fixed 2026-04-18 — selftest now uses
  node_limit only.
- **Per-sub-branch filenames include the full (p1, o1, p2, o2) key**. Earlier
  versions keyed only on (p2, o2), causing silent overwrites. Never narrow the
  file-naming key without proving no collisions can occur.
- **Status taxonomy: EXHAUSTED / BUDGETED / INTERRUPTED.** Each sub-branch
  records one of three end states. EXHAUSTED means the search completed
  naturally (no more solutions possible). BUDGETED means the per-sub-branch
  node budget was hit (deterministic under the same budget; re-run at a
  higher budget may find more solutions). INTERRUPTED means a signal or
  process kill cut it short. Resume: always re-run INTERRUPTED, re-run
  BUDGETED only if the new budget exceeds the stored one, skip EXHAUSTED.
- **Hash table auto-resizes; zero silent drops.** Per-thread tables start
  at 2^24 slots (configurable via `SOLVE_HASH_LOG2`) and double when load
  exceeds 75%. Probe is over the full table with no cap. OOM during resize
  triggers FATAL abort. The earlier 64-probe cap that silently dropped 241M
  records at 10T depth-2 no longer exists.
- **solve.c uses pthreads; solve.c's `--analyze`, `--validate`, `--prove-*`
  use OpenMP.** Don't mix both in the same phase of execution — they compete
  for cores. The main enumeration uses pthreads only; OpenMP is confined to
  post-enumeration modes.
- **Enumeration and merge have very different resource profiles — run them
  on separate VMs.** Enumeration is core-bound (64 pthreads, ~10 GB RAM flat);
  merge is RAM-bound (`malloc(unique_records × 32)`). At 100T the merge needs
  ≥128 GB RAM, at 1000T ≥256 GB — far more than the enumeration VM needs.
  Splitting the phases keeps enumeration on a lean F-series SKU and only pays
  for a memory-dense E/M-series VM during the brief merge. See
  [DEPLOYMENT.md §Two-phase deployment](DEPLOYMENT.md#two-phase-deployment-enumeration-vm-vs-merge-vm)
  for the full pattern, cost table, and orchestration requirements.
- **`--analyze` has shared state with lifetime boundaries that bite new
  sections.** `bmask[]` (~2.9 GB per-boundary match bitmaps) is allocated
  before section [3] and freed at the end of analyze_mode. Any new section
  that reads `bmask[]` must be inserted before the free, OR rebuild it
  internally via a fresh streaming pass. A prior edit freed `bmask[]` between
  sections [13] and [14] to make room for [14]'s ~24 GB sort buffer on
  tight-RAM VMs; adding sections [16]-[19] after [15] then silently
  use-after-freed that memory and segfaulted mid-run (output truncated at
  [17]'s header). Fix: keep `bmask[]` alive to the end; the combined working
  set (~27 GB) fits on any VM with ≥ 32 GB RAM, and the F32als_v6 we use
  has 64 GB. Verify with `free -g` remotely during a full run if ever moving
  this boundary. The same pattern may arise with other shared buffers —
  whenever the solver code has a comment asserting a memory constraint,
  verify with `free -g` rather than trust the comment.

### Monitor / orchestrator

- **`ps -o pcpu` is cumulative-averaged, not instantaneous.** `ps` reports
  CPU% as `total_CPU_seconds / elapsed_wall × 100` since process start. For a
  process whose first phase ran at low CPU (e.g. solve's resume "fast-skip"
  phase loading shards into the hash table at ~32% utilization), `ps pcpu`
  will appear to "ramp" for hours after the process actually saturates,
  because the slow startup is baked into the lifetime average. To check
  whether solve is **actually** saturating cores right now, use
  `top -bn2 -d 1` (two samples 1 second apart) and read the second %CPU
  value — that's the true instantaneous utilization. On D128 at steady-state
  real-walking, this should be near 12,800% (100% × 128 cores). Caught
  during 100T v2 recovery2 monitoring 2026-05-22: `ps pcpu` was reading
  ~5600% (interpreted as "still ramping up") while `top` confirmed actual
  steady-state of 12,800% (full saturation). The lifetime average had
  another ~6h of accumulation before it would asymptote to the true rate.
- **Separate launcher and monitor processes.** If the launcher script crashes
  during setup, the monitor should survive. Auto-teardown via `trap cleanup
  EXIT INT TERM` is how we guarantee VMs don't linger on error.
- **Use `set -uo pipefail`, NOT `set -euo pipefail`.** A transient scp failure
  should not kill the monitor loop. Guard individual risky commands with
  explicit `if ! cmd; then log; fi` instead of relying on `-e`.
- **Never redirect orchestrator stderr to `/dev/null`.** Silent death is the
  worst failure mode.
- **Monitor completion-detection must match solver's actual output.** Earlier
  the monitor grepped for `"SEARCH COMPLETE"` while the solver writes
  `"SEARCH_COMPLETE"` (underscore) to solve_results.json. Match a stable
  machine-readable marker, not stderr prose whose exact wording evolves.
- **Don't grep-hide SSH host-key warnings.** Use `ssh -o
  UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o StrictHostKeyChecking=no`
  for VMs whose IPs get reused across recreation cycles. Historically we had
  grep chains filtering out WARNING lines; that's hygiene, not a fix.
- **Solver-launch SSH must be belt-and-suspenders detached.** The naive form
  `ssh host "nohup ~/solve > out 2>&1 &"` hangs the local SSH client even
  with `ssh -n` and remote `< /dev/null` — observed empirically 2026-04-16.
  The remote `bash -c` lingered for minutes after backgrounding `nohup`,
  because some fd inheritance path kept the SSH channel open. Solve was
  happily running but the launching monitor never returned from `ssh`,
  stuck in `do_wait`, missing spot evictions. **Required form:**
  `timeout 15 ssh -n … "cd /data && setsid nohup ~/solve … > out 2>&1 < /dev/null &" < /dev/null`.
  - `setsid` puts solve in its own session, fully detached from SSH's
    process group / controlling tty
  - `timeout 15` guarantees the local ssh dies even if the remote shell
    refuses to release the channel; the nohup+setsid'd solve survives
  - The next monitor step probes `pgrep -x solve` via a fresh SSH so a
    forced-killed launch SSH doesn't false-fail launch detection.
- **A stuck monitor is blind to spot eviction.** If the monitor's main
  poll loop never starts (hung in launch SSH, hung in setup), the VM can
  evict undetected. Every long-blocking call in the launch path needs a
  hard timeout for this reason.
- **Supervisor → monitor takeover: kill monitor FIRST, then touch /data.**
  When a supervisor wraps a monitor (e.g., to chain runs or re-archive
  after the monitor finishes), kill the monitor *before* doing any
  `/data` operations or VM teardown. Otherwise the monitor's own
  archive/teardown flow races with the supervisor — observed scenario:
  monitor's `az vm delete` runs while supervisor's `scp solver@host:/data/...`
  is in flight, and the scp dies with no route to host mid-pull.
- **Pattern-based wipes preserve everything outside the patterns.** The
  monitor's stale-data clear is `rm -f /data/sub_*.bin /data/solutions.bin
  /data/checkpoint.txt …` (enumerated patterns), not `rm -rf /data/*`. To
  carry a file across runs on the shared managed disk, give it a name
  outside the pattern set — e.g., `solutions_d3_<sha8>.bin` survives a
  depth-2 wipe because no pattern matches it. (This is also the reason
  we say "clear stale run artifacts," not "wipe the disk" — see
  `Asset preservation` for terminology.)
- **Chained runs: supervisor owns VM teardown, not the inner monitors.**
  When the supervisor takes over completion handling, the monitor
  shouldn't auto-teardown — the supervisor decides when the VM goes away
  (typically: pull metadata via SSH first, then delete VM). The
  managed data disk auto-detaches and survives VM deletion.
- **Chained runs: prefer sequential monitors over a supervisor.** The
  supervisor pattern (kill monitor mid-merge, take over /data) has race
  conditions. The sequential pattern (let each monitor run to natural
  completion, then start the next) is simpler and correct. Between runs,
  a temp VM can rename files on the managed disk if needed.
- **Write run_id.txt BEFORE the wipe, not after.** The monitor's
  `sync_files` function checks `/data/run_id.txt` to detect stale data.
  If `run_id.txt` is written after the wipe, there's a race window where
  a concurrent sync reads the old ID and skips the sync. Writing the new
  ID first closes this window. (Observed 2026-04-17: "Run ID mismatch on
  sync" warnings from this race — cosmetic, but confused diagnostics.)
- **Solver correctness is independent of monitor state.** The monitor's
  sync warnings, log errors, or even crashes don't affect the solver
  process running on the VM. The solver reads no state from the monitor.
  Monitor failures are observability problems, not data problems.
- **Post-completion gate: --verify + hash-drop check.** After solver
  writes solutions.bin, the monitor runs `./solve --verify solutions.bin`
  on the VM (independent C1-C5 check on every record) and greps
  solve_output.txt for nonzero hash-table drops. Either failure aborts
  before archiving — no invalid output is ever accepted as a completed run.
- **Progress-stall watchdog must exempt the merge phase.** The watchdog
  checks `progress.txt` staleness to detect hung solvers. But the merge
  phase (reading 158K files, sorting billions of records, writing
  solutions.bin) legitimately takes 15-30+ minutes without updating
  progress.txt. The watchdog must check `solve_output.txt` for merge
  indicators ("Reading sub-branch", "Sorting", "Writing", "Computing
  sha256") before declaring a stall. Observed 2026-04-17: watchdog killed
  a healthy solver mid-merge on a 10T depth-3 run, losing the merge
  output while all sub_*.bin files were intact on disk.
- **Merge is not checkpoint-protected — use on-demand VMs.** The merge
  phase (malloc + qsort + write) is a single uninterruptible operation.
  If spot-evicted mid-sort, all work is lost and must restart from the
  sub_*.bin files. For production merges, use an on-demand VM (~$2 for
  30 min on F64). This is the two-phase pattern: spot for enumeration
  (checkpoint-protected), on-demand for merge (must complete in one shot).
- **Progress rate + ETA in sync logs.** Each checkpoint sync computes
  sub-branches/hour and estimated time remaining. Essential for overnight
  100T+ runs where "is it still progressing?" can't be answered by a
  single checkpoint count.
- **Disk usage per poll cycle.** Logged as "Disk: 45% (54GB / 121GB)"
  at each sync. Shows growth rate and predicts whether the dynamic
  expansion watchdog will trigger before completion.
- **Sub_*.bin integrity check on eviction resume.** After spot eviction
  and redeploy, the monitor checks every existing sub_*.bin for
  `size % 32 == 0`. Truncated files (eviction killed the flush mid-write
  before fsync) are removed so the solver re-runs those sub-branches
  from checkpoint rather than merging corrupt data.
- **All merge code paths must use canonical dedup.** The solver's normal-
  mode merge and the standalone `--merge` flag must both use
  `compare_canonical` (orient bits masked) for dedup — not
  `compare_solutions` (full-byte). A mismatch means `--merge` on the
  same sub_*.bin files produces a different sha than the solver would
  have. This was a bug through commit 872a861; fixed afterward.
- **External merge-sort for memory-independent merging.** At 10T depth-3,
  the merge buffer is 82 GB (2.77B records × 32 bytes). For larger runs
  or smaller VMs, `SOLVE_MERGE_MODE=external` uses disk-based sorted
  chunks + k-way heap merge. Produces identical output to in-memory merge.
  Default (`auto`) selects external when needed RAM exceeds 70% of
  physical. `SOLVE_MERGE_CHUNK_GB` controls chunk size (default 4 GB).
- **Disk tier dominates external merge time.** Lesson from the 2026-04-18
  10T depth-3 production-scale external merge test on Standard_LRS
  (HDD-tier): rate was ~6-7 min per 4 GB chunk × 20+ chunks in phase 1,
  projecting to ~3-4 hours total wall and ~$12-15 at F64 on-demand. That
  is **~6× the time and ~6× the cost** of the same merge in-memory on the
  same F64 (fits in 128 GB RAM comfortably). The HDD is the bottleneck,
  not the code. Implication: never do an external merge on Standard HDD
  at > 10T scale without a very good reason. At 100T the numbers become
  untenable (extrapolated 30+ hours on HDD vs ~3 hours on Premium SSD).
- **Use `SOLVE_TEMP_DIR` to keep temp chunks on Premium SSD while keeping
  shards and final output on cheap archival storage.** External merge
  does ~2× chunk-size worth of I/O to the temp directory
  (write chunks in phase 1, read chunks in phase 2). Pointing
  `SOLVE_TEMP_DIR` at a Premium SSD attached only for the merge runs
  that I/O at SSD speeds (~200 MB/s on P20/P30, ~3-4× HDD). The SSD gets
  destroyed after the merge — no long-term Premium-storage cost, only
  the prorated hourly rate during the merge (pennies). Shards stay on
  `solver-data` (Standard HDD, ~$3/month). Final `solutions.bin` also
  lands on `solver-data` since CWD during merge is unchanged. See
  [DEPLOYMENT.md §Premium-SSD-attach-for-merge](DEPLOYMENT.md)
  for the concrete az CLI workflow.
- **Standing rule: never provision `solver-data` as Premium SSD.** It
  holds cold shards 99% of the time. Standard_LRS ($3/month for 300 GB,
  $10/month for 1 TB) is the right tier for archival. The factor-10
  cost jump to Premium is only justified during active merges, and those
  are better served by attach-a-temp-Premium-SSD-just-for-the-merge.
- **External merge has a hard pre-dedup size ceiling.** `MAX_SORTED_CHUNKS
  = 4096` in solve.c × default `SOLVE_MERGE_CHUNK_GB=4` = **16 TB of
  pre-dedup input**. At observed d3 rates (~8.3 GB per 1T nodes) that's
  ~2,000T of enumeration. Comfortable for 10T-1,000T; restrictive only
  at ~1,500T+. Mitigation is env-var (`SOLVE_MERGE_CHUNK_GB=16` buys 4×
  headroom, 32 buys 8×) with no code change; or bump the constant as a
  one-line source change. Solver emits a clear error with the mitigation
  if the limit is hit. Before this bites: `ulimit -n` default of 1024
  open FDs is hit around 500T (the k-way merge opens every chunk
  simultaneously). `ulimit -n 16384` before running fixes it.

- **Stack `ulimit -s`.** Production builds run cleanly at the default
  Linux stack limit (8 MB on every distro tested: Ubuntu 24.04 cloud-
  init, Cobalt ARM, the orchestrator VM). main()'s peak stack usage
  is ~4-6 MB after the 2026-05-05 #54 fix, leaving comfortable
  headroom. **No `ulimit -s` adjustment needed for production runs.**

  **AddressSanitizer / sanitizer-instrumented builds DO require
  `ulimit -s unlimited`.** ASan adds redzones around every stack-
  allocated array, which inflates main()'s frame from ~6 MB to
  ~16 MB. Without the bump, ASan binaries SIGSEGV at main() entry
  with a misleading "stack-overflow" report before any user code
  runs. Build flags `-fsanitize=address -no-pie -fno-pie -O1 -g`
  combined with `ulimit -s unlimited` produce the right
  diagnostic environment.

  solve.c includes a startup constructor (`check_stack_ulimit()`,
  added 2026-05-05 task #75) that prints a stderr warning if the
  running process's `RLIMIT_STACK` is below the build's
  recommended threshold (8 MB production, 64 MB ASan). Surfaces
  the requirement loudly before any code-path-specific failure.

### Accumulating ground truth — single-branch exhaustion workflow

Long-horizon enumeration strategy: exhaust individual first-level branches
over time, accumulate their shards on a shared archive disk, and concentrate
new-run compute budgets on the remaining un-exhausted branches. This is
formally justified by the partition-invariance theorem — see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) for the proof that
merging shards from independent single-branch runs produces identical
output to a full-parallel run (under exhaustive enumeration).

Operational procedure:

1. Run `./solve --branch P O 0` (no node limit → exhaustive) for a
   targeted first-level branch. Sub-branches within that branch complete
   as EXHAUSTED; shards land in the CWD as `sub_P_O_*.bin`.
2. Archive those shards + the branch's checkpoint entries onto a
   shared disk (e.g., `solver-data` or a dedicated `solver-ground-truth`
   disk). Retain the checkpoint lines marking EXHAUSTED status.
3. Next full run: `cp` (or symlink) the archived shards + concatenated
   checkpoint into the working directory before launching. `solve.c`
   reads the checkpoint on startup, sees EXHAUSTED entries, skips those
   sub-branches entirely. Enumeration only runs on the remaining branches.
4. Merge at end reads all shards in CWD — pre-existing and freshly-written
   alike — producing a `solutions.bin` that combines exhausted-ground-truth
   with budgeted-partial for the remainder.

**Budget distribution option**: by default, the per-sub-branch node limit
is `SOLVE_NODE_LIMIT / total_partition_size`, which preserves reproducibility
across fresh vs. resumed runs at the same node limit. For the accumulation
workflow where you want the remaining node budget concentrated on
un-exhausted branches, opt-in via `SOLVE_CONCENTRATE_BUDGET=1`. This
divides by the *remaining* sub-branch count instead. Trade-off: output
sha256 depends on how many branches were pre-completed; NOT reproducible
by `SOLVE_NODE_LIMIT` alone. The solver prints a WARNING when this
env var is active.

**Workaround without the env var**: if you want concentration semantics
under the default reproducible path, compute the target total manually:

```bash
TARGET_PER_BRANCH=$(( 10000000000000 / TOTAL_SUB_BRANCHES ))
SCALED_TOTAL=$(( TARGET_PER_BRANCH * REMAINING_SUB_BRANCHES ))
SOLVE_NODE_LIMIT=$SCALED_TOTAL ./solve 0
```

Same effective per-sub-branch depth on remaining, full reproducibility
of the pass.

### `--sub-branch` CLI mode (targeted depth-3 sub-branch exhaustion)

Added 2026-04-19. Runs a single depth-3 sub-branch `(p1, o1, p2, o2, p3, o3)`
to exhaustion (or node-limit budget). Usage:

```bash
SOLVE_NODE_LIMIT=0 ./solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3>
```

Writes a single `sub_P1_O1_P2_O2.bin` shard and a single checkpoint line
with status EXHAUSTED (if the tree finishes) or BUDGETED (if a node limit
is set and hit first). Designed for the stratified-sample exhaustion study
— each run produces one data point of (wall time, node count, solution
count, status) for cost-extrapolation analysis.

Unlike `--branch` (which runs ALL sub-branches of a first-level branch),
`--sub-branch` targets exactly one. It bypasses checkpoint.txt loading so
that a fresh run is a fresh run — no accidental resume from stale state.

Pair this mode with small parallel VMs (D2als_v7 or D4als_v7 spot, one
per sub-branch). The workload is single-threaded inside a sub-branch, so
D128 is 99% wasted. See `DSERIES_ROI_REPORT.md` (outside repo) for SKU
sizing rationale.

Validation guarantee: if you later exhaust a sub-branch via `--sub-branch`
AND separately compute a full `--merge`'d canonical from independent
whole-partition enumeration, merging the single-exhausted-sub-branch
shard into a fuller dataset (following the accumulation workflow above)
is byte-identical to running everything in one invocation, per
partition invariance.

### `--kde-score-stream` CLI mode (native KDE scorer for distributional analysis)

Added 2026-04-24 alongside the consolidation-hang postmortem and bug fix.
Companion subcommand for the `solve.py --joint-density-v2` distributional
analysis pipeline. Reads fit points from a binary file, streams query
points from stdin (float64 packed), writes count-below-threshold to stdout.
Implements Gaussian kernel KDE log-density via log-sum-exp, parallelized
via OpenMP.

```bash
./solve --kde-score-stream --fit-file FIT.bin --d N --bandwidth BW --threshold T
```

~10× faster than sklearn's pure-Python `KernelDensity.score_samples` on
typical inputs (validated bit-identical on a 500-point synthetic test).
Makes exhaustive distributional analysis on the 100T canonical (3.43B
records) tractable in ~2 hours on D64 (vs ~9 days pure-Python).

See `roae-private/DISTRIBUTIONAL_V2_SPEC.md` (private staging repo)
for the analysis pipeline + Python integration.

### `solve.py --sat-encode` (DIMACS / OPB encoder for #SAT model counting)

Added 2026-04-24. Emits propositional encoding of C1+C2 (optionally +C3
as Pseudo-Boolean linear constraint, +C4 unit) for input to exact #SAT
solvers (`ganak`, `d4`, `sharpSAT-TD`).

```bash
solve.py --sat-encode kw.cnf [--sat-c3 pb] [--sat-c4]
```

Produces:
- `kw.cnf` — DIMACS CNF (4,096 vars / 272,128 clauses for C1+C2)
- `kw.cnf.opb` — Pseudo-Boolean OPB format with C3 PB constraint added
  (266,240 vars / 1,058,560 clauses; C3 sum has 258,048 terms)
- `kw.cnf.meta.json` — variable/clause counts, sha256 of clauses for
  reproducibility

See `roae-private/SAT_EXPERIMENT_SPEC.md` (private staging repo)
for the experimental protocol and validation strategy.

### Infrastructure

- **Spot-VM evictions in westus2 under F64 averaged ~1 per 3 hours during
  April 2026 testing.** Sub-branch-granularity recovery is too coarse at
  large per-sub-branch budgets (100T+). Depth-3 work units (Option B,
  shipped via `SOLVE_DEPTH=3`) make the recovery granularity affordable.
- **Non-zonal managed disks cannot attach to zonal VMs.** If your data disk
  was created without a zone but the VM you want to attach it to is zonal,
  Azure returns `BadRequest`. Provision analysis VMs as non-zonal when they
  need the data disk.
- **Teardown is dependency-ordered.** VM → NIC → public-IP → NSG → vnet,
  sequential. Parallel deletes return spurious exit-1 because dependents
  hold references.

### Solver-VM network topology: private IP only

Solver VMs live on the shared `claude-vnet/default` subnet alongside the
orchestrator (`claude` VM at `$ORCH_IP`). Each new solver VM is created with
a private IP (e.g., the next free private IP on the subnet) and **no public IP, no NSG rule**. The
orchestrator SSHes to the private IP directly.

**Why:** zero external attack surface (no port 22 reachable from the
internet), no public-IP cost (~$0.005/hr per VM), simpler resource
inventory.

**How `monitor_canonical.sh` does it:**
- `az network nic create --vnet-name claude-vnet --subnet default`
  (no `--public-ip-address`, no `--network-security-group`)
- `get_ip()` queries the NIC's `privateIPAddress` instead of a public-IP
  resource

**Pre-2026-04-16 monitor scripts** created public IPs and NSG rules per
run; their cleanup paths still attempt to delete those resources for
backward compatibility but new runs don't create them.

**Caveat:** since both VMs must share `claude-vnet`, an analyst running
this from a laptop (not from the orchestrator VM) needs a different
SSH path — either keep the public IP, or set up vnet peering / a jump
host. The orchestrator-on-vnet pattern is the simplest local case.

### Dynamic disk expansion (online resize while solver runs)

Azure managed disks support online expansion while attached to a running
Linux VM with ext4. `monitor_canonical.sh` watches `/data` usage every poll
cycle and grows the disk + filesystem if usage crosses a threshold.

**Settings (env vars, defaults shown):**
- `DISK_EXPAND_THRESHOLD_PCT=75` — trigger expansion when /data is 75% full
- `DISK_EXPAND_INCREMENT_GB=100` — grow by 100 GB per trigger
- `MAX_DISK_GB=1024` — hard ceiling (don't grow beyond 1 TB)

**Mechanism:**
1. `df -BG /data` on the solver VM measures usage
2. If pct ≥ threshold and current disk size < `MAX_DISK_GB`:
   - Orchestrator: `az disk update -g RG-CLAUDE -n solver-data --size-gb (cur + INCREMENT)`
   - Inside VM: `sudo resize2fs $(mount | grep /data | cut -d" " -f1)`
3. Telemetry CSV gets a `disk_expanded` row.

The solver continues writing throughout — no unmount, no reboot, no
disruption. Online expansion typically takes ~30 sec (azure provisioning)
+ ~1 sec (resize2fs).

**Why:** for runs whose final size exceeds initial sizing (especially
100T/1000T where the unique-count projection has wide uncertainty), this
prevents disk-full mid-merge — the failure mode that produced the
2026-04-14 8 GB / 23.7 GB truncation incident. Combined with the static
preflight check (in `solve.c` merge mode and the monitor's launch-time
check), this is defense in depth: preflight rejects obviously-undersized
starts; watchdog handles unexpected mid-run growth.

**Disks can grow but not shrink.** If 100T finishes with the disk grown
to 500 GB but only 200 GB used, the disk stays at 500 GB until manually
shrunk via snapshot + recreate. Cost continues at the larger size until
then.

---

## Reproduce from scratch

1. **Build the solver.**
   ```
   gcc -O3 -pthread -fopenmp -march=native \
       -DGIT_HASH=\"$(git rev-parse --short HEAD)\" -o solve solve.c -lm -lz
   ```

2. **Run a canonical enumeration.** On a machine with ≥64 cores and ≥64 GB
   free disk (128 cores and 1.5 TB for 100T). Use the exact parameter row from
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Reproducibility parameters:
   ```
   SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=10000000000000 \
   SOLVE_PER_SUB_BRANCH_LIMIT=63146557 \
   SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 \
   SOLVE_THREADS=128 ./solve 0    # 10T d3 canonical (SOLVE_THREADS=64 gives the same sha)
   ```
   `SOLVE_PER_SUB_BRANCH_LIMIT=63146557` is required: it is the empirical
   per-cell budget the canonical was generated under. If left unset, solve
   auto-divides `node_limit/158364` = 63,146,544 (−13 per cell), which
   produces a valid but different, non-canonical sha — see the recipe-table
   comment in solve.c and CANONICAL_HASHES.md §Reproducibility parameters.
   Pass `0` as the wall-clock argument for the reproducibility rule — each
   sub-branch runs to its full per-branch node budget, producing byte-identical
   output regardless of thread count or hardware. Empirical timing: 10T d3
   completes in ~83 min on D128als_v7 (Zen 5) or ~5 h on F64als_v6 (Zen 4).
   Produces 158,364 `sub_*.bin` shards, a merged `solutions.bin` (~22.6 GB),
   and `solutions.sha256`.

3. **Verify the output.** The expected sha is the current canonical, not
   any legacy file in `enumeration/`:
   ```
   sha256sum solutions.bin
   # must equal b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc  (10T d3, 706,427,594 records)
   # or        a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2  (10T d2)
   # (the older f7b8c4fb… 10T d3 sha is DEPRECATED — pre-resume-fix undercount;
   #  see CANONICAL_HASHES.md §Deprecated)
   ./solve --validate solutions.bin            # ALL CONSTRAINTS VERIFIED
   ```

4. **Reproduce the scientific analyses.**
   ```
   ./solve --analyze solutions.bin > analyze_output.txt
   zcat runs/20260418_10T_d3_fresh/analyze_output.log.gz > expected.txt
   diff analyze_output.txt expected.txt        # headers/timings differ, numbers don't
   ```
   Note: the archived `20260418_10T_d3_fresh` run predates the resume fixes
   (it is the deprecated `f7b8c4fb…` file, 4,607 records fewer), so
   count-dependent lines may differ slightly from a fresh `b85c8871…` run;
   structural findings are unchanged.

5. **Cross-check downstream doc claims** against `analyze_output.txt`. Every
   numerical claim in HISTORY.md / SOLVE_SUMMARY.md / CRITIQUE.md / LEADERBOARD.md
   has a corresponding section in the analyze output.

The canonical archival artifacts live under `runs/<date>_<scale>_<depth>_<runtag>/`
(e.g., `runs/20260418_10T_d3_fresh/` for the 10T d3 canonical). Each
per-run directory contains `solutions.sha256`, `solutions.meta.json`, compressed
enum + merge logs, and a compressed `analyze_output.log.gz` — these are the
reference against which reproduction is checked.

The older `enumeration/solutions.sha256` and `enumeration/analyze_c_742M.txt`
files hold the invalidated 742M-era sha and analyze outputs (see HISTORY.md
for forensics). They are kept for audit trail only and should NOT be used as
a reproduction reference.

## Running on cloud (high-level)

The repo intentionally does not ship cloud-provider-specific scripts. Running
the solver on a cloud VM (Azure, AWS, GCP) follows an architecture-agnostic
recipe; adapt to your provider of choice. The pattern we used in April 2026
(Azure spot F64als_v6) is documented in
[DEPLOYMENT.md](DEPLOYMENT.md) Appendix A as a reference example — translate
to `aws ec2`, `gcloud compute`, etc. as appropriate.

Architecture-agnostic rules (all in [DEPLOYMENT.md](DEPLOYMENT.md)):

- **Persistent data volume separate from the compute VM.** Attach a durable
  disk for solver output; VMs come and go, disk persists across evictions
  and recreates.
- **Orchestrator script provisions VM + disk + networking, launches solver
  under `nohup`, exits.**
- **Separate long-running monitor** periodically syncs state from the VM to
  local / archives, detects eviction, handles restart with exponential
  backoff.
- **Completion detection** on a stable marker (JSON status field, not
  stderr text).
- **Teardown** is trap-guaranteed: the VM dies even if the monitor crashes.
  Never delete the data disk.

A new Claude session (or any new contributor) should read DEPLOYMENT.md to
understand the rules, then write provider-specific scripts matching those
rules. Concrete commands vary by provider; the architecture does not.

## Cost expectations (April 2026 baseline)

- Solver run (10T on Azure F64 spot): ~$1.70 uninterrupted, ~$3-5 with 1-2
  evictions.
- Analysis session (F32 spot, `--analyze` on 742M): ~$0.10-0.15 per session.
- Persistent data disk (64 GB Standard HDD): ~$3/mo.
- User's informal budget cap: ~$50/month for an ongoing project at this scale.

Future 100T: projected ~$50-100 on spot with Option B (depth-3 work units)
reducing eviction recovery cost. Without Option B, spot is infeasible (first
attempt projected 30+ days).

Future 1000T: would need architectural changes — solutions.bin at ~2.2 TB
exceeds single-disk capacity; requires chunked output + sharded analysis,
possibly M-series VM for analysis step. Queued, not scoped.

---

## What's pending / open

Beyond the current committed state, the following work is known to be useful
but not yet done. A fresh session wanting to continue the project should
consider these in rough priority order. This section was last refreshed
2026-04-19; see [HISTORY.md](HISTORY.md) "Current state" for the canonical
up-to-date status.

### Operational (in-flight or near-term)

1. **100T d3 enumeration on D128als_v7 westus3.** Launched 2026-04-19
   ~08:00 UTC; at the time of this doc refresh, enumeration is in flight.
   Expected outcome: a 100T-budget canonical sha that supersedes the 10T d3
   sha as the deepest partial dataset. Per PARTITION_INVARIANCE.md the
   100T sha is distinct from 10T (different `SOLVE_NODE_LIMIT`) but still
   reproducible. Post-run: update LEADERBOARD.md with the new sha +
   canonical count, refresh `--analyze` outputs for the deeper dataset,
   reassess {25, 27} interchangeable-pairs structure at 10× budget.
2. **4-corners validation at 100T.** The 10T d3 canonical has been
   validated across {F64 Zen 4 westus2, D128 Zen 5 westus3} × {external,
   heap-sort merge} (all four produce byte-identical output, see
   HISTORY.md). 100T has only been run via the D128+external corner so
   far; running the other three corners at 100T would tighten the
   partition-invariance empirical claim — but is not required for the
   canonical sha, which is theorem-guaranteed reproducible.

### Scientific / analysis extensions (longer horizon)

Tracked in detail in `LONG_TERM_PLAN.md` (project-local staging in
`~/github/roae-private/`, not committed to this repo). Highlights:

3. **~~Formal proof of forced-orientation (Theorem 6)~~ — CLOSED BY
   RETRACTION (2026-07-26).** The claim was false (complementation is an
   exact symmetry of C1∩C2∩C3∩C5; only oriented C4 breaks it). The true
   replacement statement — the Complement Z₂ symmetry theorem — is
   machine-checked in `lean/KingWen.lean`; C4's orientation is
   definitional (Xugua-attested), needing no theorem. See
   SPECIFICATION.md §Theorems and CLAIMS_DECIDED's corrections ledger.
4. **Bootstrap confidence intervals** on percentile claims (complement
   distance at 3.9th percentile, shift pattern percentages on the current
   canonical datasets, per-position entropies). Report `X% [Y%, Z%]`
   instead of point estimates.
5. **Null-model comparison against structured permutations** (de Bruijn
   sequences, Costas arrays). Currently CRITIQUE.md compares only to
   random permutations and to pair-constrained random permutations —
   structured-permutation nulls are absent.
6. **Partition-stability re-check on 100T data.** The 4-boundary
   structure `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}` is established on
   the d3 10T canonical; the mandatory-{25, 27} sub-claim is partition-
   stable (holds on both d2 and d3 10T). A 100T dataset will either
   confirm the full 4-boundary structure or refine it — partition
   dependence is expected for the 2 non-stable boundaries.
7. **Connection to known combinatorial structures** (block designs, error-
   correcting codes, group actions). Would elevate empirical findings
   to mathematical connections. Exploratory notes in `INSIGHTS.md` and
   `BREAKTHROUGH_REQUIREMENTS.md` (operator staging in
   `~/github/roae-private/`, not committed to this repo).

### Infrastructure / archival (deferred)

Not planned at this time per operator direction (2026-04-18), but worth
noting so a future session understands the scope they were declined from:

- CI/CD automation (GitHub Actions) for buildability over time.
- Linux-path portability (`/proc/self/exe` fallback for non-Linux).
- Archival deposits (Zenodo + Software Heritage) for 20-year preservation.

All three are discussed in `SCIENTIFIC_REVIEW.md` (project-local).

See [HISTORY.md](HISTORY.md) "Current state" for the latest status, and the
missteps table for worked examples of how the project self-corrects. Items
that were previously in this list and are now complete:

- Hash-table silent-drop fix → commit `585880f` (auto-resizing hash table, zero silent drops).
- Status-label taxonomy → commit `3f0167f` (EXHAUSTED/BUDGETED/INTERRUPTED).
- Option B depth-3 work units → commit `ac5a9ba`; 10T d3 enumeration completed 2026-04-17 with all 158,364 sub-branches processed.
