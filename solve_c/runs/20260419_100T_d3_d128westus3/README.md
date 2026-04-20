# 100T depth-3 D128als_v7 westus3 canonical enumeration — archive

*Completed run 2026-04-20 00:45 UTC.*

**Date:** 2026-04-19
**SKU:** Standard_D128als_v7 (spot, westus3)
**Purpose:** First partial enumeration at 10× budget over the canonical
10T d3 run. Establishes a deeper partial sha, supersedes 10T as the
richest partial enumeration dataset.
**Solver commit at enumeration launch:** `edccb16` / `adf1505` (docs-only
follow-ups after; enumeration and merge semantics unchanged since the
10T d3 canonical was established — partition invariance guarantees
the 100T sha depends only on solver + inputs, not subsequent doc edits).

## Canonical sha (100T partition, 2026-04-19)

- **sha256**: `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`
- **Records (canonical unique orderings)**: **3,432,399,297** (~3.43 billion)
- **Solutions.bin size**: 109,836,777,536 bytes (102.3 GB)
- **Pre-dedup records processed**: 13,832,832,979
- **Merge chunks produced**: 60,533 (external merge via P40 Premium SSD scratch)
- **Distinct from 10T sha** `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` because 100T has a different `SOLVE_NODE_LIMIT` parameter. Both are valid canonical references at their respective budgets (per PARTITION_INVARIANCE.md, sha is a function of solver + inputs).

## Relationship to 10T canonical

100T d3 solution set is a **proper superset** of 10T d3's. Every ordering found in 10T (706,422,987) is also in 100T (because each sub-branch at 100T has 10× the budget and explores strictly more of its tree before hitting the node-budget ceiling). The increment over 10T reflects sub-branch trees that needed >63M but ≤631M nodes to surface their C3-valid configurations.

**Count comparison:**
- 10T d3: 706,422,987 canonical orderings
- 100T d3: **3,432,399,297** canonical orderings
- Ratio: **~4.86×** at 10× the node budget (diminishing-returns scaling — expected, since early sub-branches saturate quickly while deep/hard sub-branches need proportionally more budget to surface more orderings).

Expected count at launch was 1-2B; actual 3.43B exceeded the estimate.

## Run parameters

- Format version: 1
- Header size: 32 bytes
- Record size: 32 bytes
- `SOLVE_DEPTH=3`, 158,364 sub-branches
- `SOLVE_NODE_LIMIT=100000000000000` (100T)
- `SOLVE_THREADS=128` (full D128als_v7)
- External merge: `SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/merge-scratch` (P40 Premium SSD 2 TB attached for merge duration, destroyed after per standing pattern)

## Timings

| Phase | Wall time | Wall seconds |
|---|---|---|
| Enumeration (158,364 sub-branches × 631M-node budget each, 128 threads) | **11h 22m 07s** | **40,927** |
| External merge (P40 Premium SSD temp, 2 TB) | **5h 25m 38s** | **19,538** |
| **Total (enum + merge)** | **16h 47m 45s** | **60,465** |

Projected at launch (2026-04-19 08:00 UTC): enum ~11h (**actual 11h 22m 07s ✓ on target**), merge ~2-3h (**actual 5h 25m** — longer than projected; the 2-3h estimate was a rough guess, not a rigorous projection; 100T pre-dedup input at 13.8B records is ~10× the 10T input so ~10× merge time is realistic in retrospect), total ~13-14h (**actual 16h 48m** — a bit long but within tolerances).

**Enumeration complete (ENUMDONE fired 2026-04-19 ~19:20 UTC)**. Sustained ~2,445 M nodes/s peak rate across 127-128 active threads. Total nodes processed: 100,000,000,000,000 (100 T per parameter). Final sub-branch (158,364/158,364, pair1=31 orient1=1 pair2=30 orient2=0) completed at 40,925s wall. All 158,364 sub-branches BUDGETED (hit per-branch node ceiling rather than exhausted).

## What's in this directory

| File | Size | Purpose |
|---|---|---|
| `solutions.sha256` | 80 B | sha256 digest (primary integrity check) |
| `solutions.meta.json` | ~710 B | format version, record count, generator, timestamp |
| `enum_output.log.gz` | ~MB | compressed enumeration stdout |
| `external_merge.log.gz` | ~KB | compressed external-merge stdout with chunk progression |
| `README.md` | this file | run narrative + placeholders filled in |

## What's NOT in this directory (and why)

`solutions.bin` (actual 102.3 GB at 100T depth — exceeded the 30-65 GB estimate) is NOT archived here. It lives on the `solver-data-westus3` managed disk (westus3, 1.5 TB Standard_LRS). The sha is the reproducibility anchor; regenerating the bytes is a 13-hour / ~$30 compute task if ever needed (partition invariance guarantees byte-identical reproduction).

## How to re-obtain `solutions.bin`

Option 1 — re-enumerate from scratch (~$30, ~13 hrs on D128 spot):
```
ssh solver@<a D128als_v7 westus3 VM with 1.5 TB disk>
SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=100000000000000 SOLVE_THREADS=128 ./solve 0
SOLVE_MERGE_MODE=external SOLVE_TEMP_DIR=/mnt/merge-scratch ./solve --merge
sha256sum solutions.bin  # must equal [[TBD from solutions.sha256]]
```

Option 2 — mount `solver-data-westus3` disk on any westus3 VM and read directly.

## Verification status at archive time

- `./solve --merge` internal post-validation: **PASS** ("ALL CONSTRAINTS VERIFIED" in merge log; 0 errors)
- King Wen present: YES (in merge-stage validation)
- All records C1-C5 valid: YES (0 errors across all 3,432,399,297 records)
- Sort order + dedup: OK (no duplicates, strict sort order)
- Independent `--verify` pass: **PASS** — *"VERIFY PASS: all 3432399297 records satisfy C1-C5, sorted, no duplicates"*, KW present. See `verify_output.log` in this directory.
- `--analyze` output: **COMPLETE** (wall 4156s = 69m 16s). Headline findings:
  - **5-boundary minimum at 100T d3** (SUPERSEDES earlier "4-boundary minimum" finding from d2/d3 10T). Section [8] exhaustive test: 0 working 4-subsets. Greedy-optimal 5-set: **{1, 4, 21, 25, 27}**. Boundaries {25, 27} still mandatory (present in the 5-set).
  - **Shift-pattern conformance: 2,635,756 / 3.43B = 0.077%** (vs 0.062% at d3 10T and 2.69% at d2 10T). Trajectory: d2 → d3 10T → d3 100T is not monotonically decreasing — 100T slight increase over 10T suggests some rare shift-conforming orderings surface only at deeper budget.
  - **Mean per-position Shannon entropy: 2.37 bits** (out of 5.0 max). Position 3 highest (4.52 bits / 31 distinct pairs). Positions 5-6 near-zero (0.49, 0.78 bits — highly constrained).
  - **Complement closure: 0 records** have their complement also in the set (matches d2/d3 10T finding; structural property).
  - **Edit-distance distribution: heavily right-skewed**, mode at distance 30 (867M records = 25.3% of canonical). KW's 15-nearest-neighbor region is sparse: only 10.87% of records within edit distance 25 of KW. KW sits in a sparsely-populated neighborhood of the solution manifold.
  - **C3 distribution (from section [3]/[20])**: KW C3 = 776 is the ceiling; 9.91% of records tie at C3=776; minimum C3 = 424 (221 records). See `c3_min_output.log` for the dedicated analysis.
  - Full output in `analyze_output.log.gz` (17.7 KB compressed, 1,224 lines).
- `--c3-min` (Open Question #7 Phase A Day 1 MVP): **COMPLETE** (wall 227s first pass, 518s second pass with max-counting).
  - **Minimum C3 observed: 424** (221 records at min)
  - **Maximum C3 observed: 776** (= KW's value, the constraint ceiling)
  - **Count at maximum: 340,179,649 records** (9.9108% of all canonical orderings — nearly 10% of the canonical set ties with KW at exactly 776)
  - KW verified present at C3 = 776
  - **Histogram bottom 10**: 424:221, 432:6378, 440:12283, 448:47606, 456:83077, 464:201693, 472:293340, 480:540141, 488:702851, 496:1155122
  - **Histogram top 10**: 776:340M, 768:328M, 760:290M, 752:278M, 744:245M, 736:234M, 728:206M, 720:194M, 712:170M, 704:158M — heavy concentration near the ceiling
  - **Finding (Phase A MVP, decisively negative for both directions)**:
    - "Minimize C3" does NOT pick KW (picks 221 records at C3=424)
    - "Maximize C3" does NOT uniquely pick KW (picks ~340M records, ~10% of canonical set)
    - KW is in a **large equivalence cohort of 340M records** all at C3=776 — NOT a distinguished extremum
    - The distribution is heavily right-skewed toward the C3 ceiling (9.91% at max vs 0.0000064% at min)
    - **KW's 776 is the mode of the distribution, not the tail** — a substantial re-framing of the "KW keeps complements close" narrative
  - **Implication for derivability**: simple C3 extremality cannot derive KW. The search for a "natural axiom set" now needs to consider either (a) non-scalar properties or (b) the specific position of KW within the 340M-cohort at the C3 ceiling.
  - See `c3_min_output.log` in this directory for the full output and [DERIVABILITY_STRATEGY.md](../../../x/roae/DERIVABILITY_STRATEGY.md) context.

## 4-corners validation context

This run was generated on D128als_v7 (Zen 5 Turin) westus3 using external-merge mode. The 10T d3 companion run (see `../20260419_10T_d3_d128westus3/`) empirically validated that this hardware + merge-mode combo produces byte-identical output to F64 westus2 via both external and in-memory paths. The 100T sha here is expected to be reproducible via the same 4 corners (Zen 4 F64 + external merge, Zen 4 F64 + heap-sort, Zen 5 D128 + external, Zen 5 D128 + heap-sort — though only the D128-external path has been run at 100T scale so far).
